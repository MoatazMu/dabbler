import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Check-in QR code generation and validation service
class CheckinService {
  final CheckinRepository _checkinRepository;
  final LocationService _locationService;
  final QRCodeService _qrCodeService;
  final NotificationService _notificationService;
  final GamesService _gamesService;

  CheckinService({
    required CheckinRepository checkinRepository,
    required LocationService locationService,
    required QRCodeService qrCodeService,
    required NotificationService notificationService,
    required GamesService gamesService,
  }) : _checkinRepository = checkinRepository,
       _locationService = locationService,
       _qrCodeService = qrCodeService,
       _notificationService = notificationService,
       _gamesService = gamesService;

  // QR CODE GENERATION FOR CHECK-IN
  Future<CheckinQRResult> generateCheckinQR({
    required String gameId,
    required String organizerId,
  }) async {
    try {
      // Verify organizer permissions
      final game = await _gamesService.getGameById(gameId);
      if (game == null) {
        return CheckinQRResult.failure('Game not found');
      }

      if (game.organizerId != organizerId) {
        return CheckinQRResult.failure('Not authorized to generate QR code');
      }

      // Check if check-in window is open
      final windowCheck = _isCheckinWindowOpen(game);
      if (!windowCheck.isOpen) {
        return CheckinQRResult.failure(windowCheck.reason!);
      }

      // Generate unique check-in token
      final checkinToken = _generateCheckinToken(gameId);
      
      // Create QR code data
      final qrData = CheckinQRData(
        gameId: gameId,
        token: checkinToken,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        venueLocation: game.venue.location,
        requiredRadius: game.venue.checkinRadius ?? 100, // meters
      );

      // Generate QR code image
      final qrCodeImage = await _qrCodeService.generateQRCode(
        data: jsonEncode(qrData.toJson()),
        size: 300,
      );

      // Save check-in session
      final checkinSession = CheckinSession(
        id: _generateSessionId(),
        gameId: gameId,
        organizerId: organizerId,
        token: checkinToken,
        qrData: qrData,
        status: CheckinSessionStatus.active,
        createdAt: DateTime.now(),
        expiresAt: qrData.expiresAt,
      );

      await _checkinRepository.saveCheckinSession(checkinSession);

      return CheckinQRResult.success(
        qrCodeImage: qrCodeImage,
        qrData: qrData,
        session: checkinSession,
      );

    } catch (e, stackTrace) {
      debugPrint('Error generating check-in QR: $e\n$stackTrace');
      return CheckinQRResult.failure('Failed to generate QR code: $e');
    }
  }

  // QR CODE VALIDATION AND CHECK-IN PROCESSING
  Future<CheckinResult> processCheckin({
    required String qrToken,
    required String playerId,
    Location? playerLocation,
  }) async {
    try {
      // Validate QR token
      final session = await _checkinRepository.getCheckinSessionByToken(qrToken);
      if (session == null) {
        return CheckinResult.failure(
          'Invalid QR code',
          CheckinFailureReason.invalidToken,
        );
      }

      // Check if session is still valid
      if (session.status != CheckinSessionStatus.active) {
        return CheckinResult.failure(
          'Check-in session is no longer active',
          CheckinFailureReason.sessionExpired,
        );
      }

      if (DateTime.now().isAfter(session.expiresAt)) {
        await _expireCheckinSession(session.id);
        return CheckinResult.failure(
          'QR code has expired',
          CheckinFailureReason.sessionExpired,
        );
      }

      // Get game details
      final game = await _gamesService.getGameById(session.gameId);
      if (game == null) {
        return CheckinResult.failure(
          'Game not found',
          CheckinFailureReason.gameNotFound,
        );
      }

      // Verify check-in window
      final windowCheck = _isCheckinWindowOpen(game);
      if (!windowCheck.isOpen) {
        return CheckinResult.failure(
          windowCheck.reason!,
          CheckinFailureReason.windowClosed,
        );
      }

      // Verify player is registered for game
      if (!game.registeredPlayerIds.contains(playerId)) {
        return CheckinResult.failure(
          'You are not registered for this game',
          CheckinFailureReason.notRegistered,
        );
      }

      // Check if player is already checked in
      final existingCheckin = await _checkinRepository.getPlayerCheckin(
        gameId: session.gameId,
        playerId: playerId,
      );

      if (existingCheckin != null) {
        return CheckinResult.failure(
          'You have already checked in for this game',
          CheckinFailureReason.alreadyCheckedIn,
        );
      }

      // Location verification
      if (game.venue.requiresLocationVerification) {
        final locationResult = await _verifyLocationForCheckin(
          playerLocation: playerLocation,
          venueLocation: session.qrData.venueLocation,
          requiredRadius: session.qrData.requiredRadius,
        );

        if (!locationResult.isValid) {
          return CheckinResult.failure(
            locationResult.reason!,
            CheckinFailureReason.locationVerificationFailed,
          );
        }
      }

      // Process the check-in
      final checkin = PlayerCheckin(
        id: _generateCheckinId(),
        gameId: session.gameId,
        playerId: playerId,
        sessionId: session.id,
        checkedInAt: DateTime.now(),
        location: playerLocation,
        status: CheckinStatus.checkedIn,
      );

      await _checkinRepository.savePlayerCheckin(checkin);

      // Update game status if needed
      await _updateGameCheckinStatus(session.gameId);

      // Send success notification
      await _notificationService.sendCheckinConfirmation(
        playerId: playerId,
        game: game,
        checkinTime: checkin.checkedInAt,
      );

      return CheckinResult.success(
        checkin: checkin,
        game: game,
      );

    } catch (e, stackTrace) {
      debugPrint('Error processing check-in: $e\n$stackTrace');
      return CheckinResult.failure(
        'Check-in failed: $e',
        CheckinFailureReason.systemError,
      );
    }
  }

  // LOCATION VERIFICATION
  Future<LocationVerificationResult> _verifyLocationForCheckin({
    Location? playerLocation,
    required Location venueLocation,
    required double requiredRadius,
  }) async {
    // If player location is not available, try to get it
    final location = playerLocation ?? await _locationService.getCurrentLocation();
    
    if (location == null) {
      return LocationVerificationResult(
        isValid: false,
        reason: 'Unable to verify your location. Please enable location services.',
        distance: null,
      );
    }

    // Calculate distance to venue
    final distance = _calculateDistance(location, venueLocation);

    if (distance > requiredRadius) {
      return LocationVerificationResult(
        isValid: false,
        reason: 'You must be within ${requiredRadius}m of the venue to check in. You are ${distance.round()}m away.',
        distance: distance,
      );
    }

    return LocationVerificationResult(
      isValid: true,
      distance: distance,
    );
  }

  double _calculateDistance(Location from, Location to) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double lat1Rad = from.latitude * pi / 180;
    final double lat2Rad = to.latitude * pi / 180;
    final double deltaLatRad = (to.latitude - from.latitude) * pi / 180;
    final double deltaLngRad = (to.longitude - from.longitude) * pi / 180;

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // LATE ARRIVAL HANDLING
  Future<LateArrivalResult> handleLateArrival({
    required String gameId,
    required String playerId,
    required String reason,
  }) async {
    try {
      final game = await _gamesService.getGameById(gameId);
      if (game == null) {
        return LateArrivalResult.failure('Game not found');
      }

      // Check if player is registered
      if (!game.registeredPlayerIds.contains(playerId)) {
        return LateArrivalResult.failure('Player not registered for this game');
      }

      // Check if game has started but not ended
      final now = DateTime.now();
      final gameStartTime = game.dateTime;
      final gameEndTime = game.dateTime.add(game.duration);

      if (now.isBefore(gameStartTime)) {
        return LateArrivalResult.failure('Game has not started yet');
      }

      if (now.isAfter(gameEndTime)) {
        return LateArrivalResult.failure('Game has already ended');
      }

      // Calculate how late the player is
      final latenessMinutes = now.difference(gameStartTime).inMinutes;
      
      // Check if late arrival is acceptable (within 30 minutes of start)
      const maxLateArrivalMinutes = 30;
      if (latenessMinutes > maxLateArrivalMinutes) {
        await _markPlayerAsNoShow(gameId, playerId);
        return LateArrivalResult.failure(
          'Too late to join. Maximum late arrival is $maxLateArrivalMinutes minutes.',
        );
      }

      // Create late arrival record
      final lateArrival = LateArrival(
        id: _generateLateArrivalId(),
        gameId: gameId,
        playerId: playerId,
        reason: reason,
        latenessMinutes: latenessMinutes,
        arrivedAt: now,
        status: LateArrivalStatus.approved, // Auto-approve within time limit
      );

      await _checkinRepository.saveLateArrival(lateArrival);

      // Create check-in record for late arrival
      final checkin = PlayerCheckin(
        id: _generateCheckinId(),
        gameId: gameId,
        playerId: playerId,
        sessionId: null, // No QR session for late arrivals
        checkedInAt: now,
        location: null,
        status: CheckinStatus.lateArrival,
        lateArrivalId: lateArrival.id,
      );

      await _checkinRepository.savePlayerCheckin(checkin);

      // Notify game organizer of late arrival
      await _notificationService.sendLateArrivalNotification(
        gameId: gameId,
        organizerId: game.organizerId,
        playerId: playerId,
        latenessMinutes: latenessMinutes,
        reason: reason,
      );

      return LateArrivalResult.success(
        lateArrival: lateArrival,
        checkin: checkin,
      );

    } catch (e, stackTrace) {
      debugPrint('Error handling late arrival: $e\n$stackTrace');
      return LateArrivalResult.failure('Failed to process late arrival: $e');
    }
  }

  // NO-SHOW MANAGEMENT
  Future<void> processNoShows(String gameId) async {
    try {
      final game = await _gamesService.getGameById(gameId);
      if (game == null) return;

      // Check if game has started
      if (DateTime.now().isBefore(game.dateTime)) {
        return; // Game hasn't started yet
      }

      // Get all checked-in players
      final checkins = await _checkinRepository.getGameCheckins(gameId);
      final checkedInPlayerIds = checkins.map((c) => c.playerId).toSet();

      // Find players who didn't check in
      final noShowPlayerIds = game.registeredPlayerIds
          .where((playerId) => !checkedInPlayerIds.contains(playerId))
          .toList();

      // Mark players as no-show
      for (final playerId in noShowPlayerIds) {
        await _markPlayerAsNoShow(gameId, playerId);
      }

      // Update game status
      await _updateGameCheckinStatus(gameId);

    } catch (e) {
      debugPrint('Error processing no-shows: $e');
    }
  }

  Future<void> _markPlayerAsNoShow(String gameId, String playerId) async {
    final noShow = PlayerNoShow(
      id: _generateNoShowId(),
      gameId: gameId,
      playerId: playerId,
      markedAt: DateTime.now(),
      reason: NoShowReason.didNotCheckIn,
    );

    await _checkinRepository.savePlayerNoShow(noShow);

    // Send no-show notification
    await _notificationService.sendNoShowNotification(
      playerId: playerId,
      gameId: gameId,
    );
  }

  // CHECK-IN WINDOW MANAGEMENT
  CheckinWindowStatus _isCheckinWindowOpen(Game game) {
    final now = DateTime.now();
    final gameStartTime = game.dateTime;
    
    // Check-in opens 2 hours before game
    final checkinOpenTime = gameStartTime.subtract(const Duration(hours: 2));
    
    // Check-in closes 30 minutes after game starts
    final checkinCloseTime = gameStartTime.add(const Duration(minutes: 30));

    if (now.isBefore(checkinOpenTime)) {
      final hoursUntilOpen = checkinOpenTime.difference(now).inHours;
      return CheckinWindowStatus(
        isOpen: false,
        reason: 'Check-in opens $hoursUntilOpen hours before the game',
      );
    }

    if (now.isAfter(checkinCloseTime)) {
      return CheckinWindowStatus(
        isOpen: false,
        reason: 'Check-in window has closed',
      );
    }

    return CheckinWindowStatus(isOpen: true);
  }

  // GAME STATUS UPDATES
  Future<void> _updateGameCheckinStatus(String gameId) async {
    try {
      final game = await _gamesService.getGameById(gameId);
      if (game == null) return;

      final checkins = await _checkinRepository.getGameCheckins(gameId);
      final checkedInCount = checkins.length;
      final registeredCount = game.registeredPlayerIds.length;

      // Update game with check-in statistics
      await _gamesService.updateGameCheckinStats(
        gameId: gameId,
        checkedInCount: checkedInCount,
        registeredCount: registeredCount,
      );

      // Check if enough players have checked in to start the game
      final minPlayersToStart = game.minPlayers ?? (registeredCount * 0.5).ceil();
      
      if (checkedInCount >= minPlayersToStart && 
          DateTime.now().isAfter(game.dateTime)) {
        await _gamesService.startGame(gameId);
      }

    } catch (e) {
      debugPrint('Error updating game check-in status: $e');
    }
  }

  // SESSION MANAGEMENT
  Future<void> _expireCheckinSession(String sessionId) async {
    await _checkinRepository.updateCheckinSessionStatus(
      sessionId,
      CheckinSessionStatus.expired,
    );
  }

  Future<void> expireOldSessions() async {
    final expiredSessions = await _checkinRepository.getExpiredSessions();
    
    for (final session in expiredSessions) {
      await _expireCheckinSession(session.id);
    }
  }

  // QUERY METHODS
  Future<List<PlayerCheckin>> getGameCheckins(String gameId) async {
    return await _checkinRepository.getGameCheckins(gameId);
  }

  Future<PlayerCheckin?> getPlayerCheckin({
    required String gameId,
    required String playerId,
  }) async {
    return await _checkinRepository.getPlayerCheckin(
      gameId: gameId,
      playerId: playerId,
    );
  }

  Future<CheckinSession?> getActiveSession(String gameId) async {
    return await _checkinRepository.getActiveCheckinSession(gameId);
  }

  // HELPER METHODS
  String _generateCheckinToken(String gameId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${gameId}_${timestamp}_$random';
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  String _generateCheckinId() {
    return 'checkin_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  String _generateLateArrivalId() {
    return 'late_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  String _generateNoShowId() {
    return 'noshow_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }
}

// Result classes
abstract class CheckinQRResult {
  final bool isSuccess;
  final String? error;

  CheckinQRResult._(this.isSuccess, this.error);

  factory CheckinQRResult.success({
    required Uint8List qrCodeImage,
    required CheckinQRData qrData,
    required CheckinSession session,
  }) = CheckinQRSuccess;

  factory CheckinQRResult.failure(String error) = CheckinQRFailure;
}

class CheckinQRSuccess extends CheckinQRResult {
  final Uint8List qrCodeImage;
  final CheckinQRData qrData;
  final CheckinSession session;

  CheckinQRSuccess({
    required this.qrCodeImage,
    required this.qrData,
    required this.session,
  }) : super._(true, null);
}

class CheckinQRFailure extends CheckinQRResult {
  CheckinQRFailure(String error) : super._(false, error);
}

abstract class CheckinResult {
  final bool isSuccess;
  final String? error;
  final CheckinFailureReason? failureReason;

  CheckinResult._(this.isSuccess, this.error, this.failureReason);

  factory CheckinResult.success({
    required PlayerCheckin checkin,
    required Game game,
  }) = CheckinSuccess;

  factory CheckinResult.failure(
    String error,
    CheckinFailureReason reason,
  ) = CheckinFailure;
}

class CheckinSuccess extends CheckinResult {
  final PlayerCheckin checkin;
  final Game game;

  CheckinSuccess({
    required this.checkin,
    required this.game,
  }) : super._(true, null, null);
}

class CheckinFailure extends CheckinResult {
  CheckinFailure(String error, CheckinFailureReason reason) 
      : super._(false, error, reason);
}

abstract class LateArrivalResult {
  final bool isSuccess;
  final String? error;

  LateArrivalResult._(this.isSuccess, this.error);

  factory LateArrivalResult.success({
    required LateArrival lateArrival,
    required PlayerCheckin checkin,
  }) = LateArrivalSuccess;

  factory LateArrivalResult.failure(String error) = LateArrivalFailure;
}

class LateArrivalSuccess extends LateArrivalResult {
  final LateArrival lateArrival;
  final PlayerCheckin checkin;

  LateArrivalSuccess({
    required this.lateArrival,
    required this.checkin,
  }) : super._(true, null);
}

class LateArrivalFailure extends LateArrivalResult {
  LateArrivalFailure(String error) : super._(false, error);
}

class LocationVerificationResult {
  final bool isValid;
  final String? reason;
  final double? distance;

  LocationVerificationResult({
    required this.isValid,
    this.reason,
    this.distance,
  });
}

class CheckinWindowStatus {
  final bool isOpen;
  final String? reason;

  CheckinWindowStatus({
    required this.isOpen,
    this.reason,
  });
}

// Data classes
class CheckinQRData {
  final String gameId;
  final String token;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final Location venueLocation;
  final double requiredRadius;

  CheckinQRData({
    required this.gameId,
    required this.token,
    required this.generatedAt,
    required this.expiresAt,
    required this.venueLocation,
    required this.requiredRadius,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'token': token,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'venueLocation': {
        'lat': venueLocation.latitude,
        'lng': venueLocation.longitude,
      },
      'requiredRadius': requiredRadius,
    };
  }
}

class CheckinSession {
  final String id;
  final String gameId;
  final String organizerId;
  final String token;
  final CheckinQRData qrData;
  final CheckinSessionStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  CheckinSession({
    required this.id,
    required this.gameId,
    required this.organizerId,
    required this.token,
    required this.qrData,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });
}

class PlayerCheckin {
  final String id;
  final String gameId;
  final String playerId;
  final String? sessionId;
  final DateTime checkedInAt;
  final Location? location;
  final CheckinStatus status;
  final String? lateArrivalId;

  PlayerCheckin({
    required this.id,
    required this.gameId,
    required this.playerId,
    this.sessionId,
    required this.checkedInAt,
    this.location,
    required this.status,
    this.lateArrivalId,
  });
}

class LateArrival {
  final String id;
  final String gameId;
  final String playerId;
  final String reason;
  final int latenessMinutes;
  final DateTime arrivedAt;
  final LateArrivalStatus status;

  LateArrival({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.reason,
    required this.latenessMinutes,
    required this.arrivedAt,
    required this.status,
  });
}

class PlayerNoShow {
  final String id;
  final String gameId;
  final String playerId;
  final DateTime markedAt;
  final NoShowReason reason;

  PlayerNoShow({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.markedAt,
    required this.reason,
  });
}

// Enums
enum CheckinSessionStatus {
  active,
  expired,
  cancelled,
}

enum CheckinStatus {
  checkedIn,
  lateArrival,
  noShow,
}

enum CheckinFailureReason {
  invalidToken,
  sessionExpired,
  gameNotFound,
  windowClosed,
  notRegistered,
  alreadyCheckedIn,
  locationVerificationFailed,
  systemError,
}

enum LateArrivalStatus {
  pending,
  approved,
  rejected,
}

enum NoShowReason {
  didNotCheckIn,
  tooLateToArrive,
  cancelledLastMinute,
}

// Placeholder classes
class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});
}

class Game {
  final String id;
  final String organizerId;
  final DateTime dateTime;
  final Duration duration;
  final List<String> registeredPlayerIds;
  final Venue venue;
  final int? minPlayers;

  Game({
    required this.id,
    required this.organizerId,
    required this.dateTime,
    required this.duration,
    required this.registeredPlayerIds,
    required this.venue,
    this.minPlayers,
  });
}

class Venue {
  final String id;
  final String name;
  final Location location;
  final bool requiresLocationVerification;
  final double? checkinRadius;

  Venue({
    required this.id,
    required this.name,
    required this.location,
    required this.requiresLocationVerification,
    this.checkinRadius,
  });
}

// Abstract dependencies
abstract class CheckinRepository {
  Future<void> saveCheckinSession(CheckinSession session);
  Future<CheckinSession?> getCheckinSessionByToken(String token);
  Future<CheckinSession?> getActiveCheckinSession(String gameId);
  Future<void> updateCheckinSessionStatus(String sessionId, CheckinSessionStatus status);
  Future<List<CheckinSession>> getExpiredSessions();
  
  Future<void> savePlayerCheckin(PlayerCheckin checkin);
  Future<PlayerCheckin?> getPlayerCheckin({required String gameId, required String playerId});
  Future<List<PlayerCheckin>> getGameCheckins(String gameId);
  
  Future<void> saveLateArrival(LateArrival lateArrival);
  Future<void> savePlayerNoShow(PlayerNoShow noShow);
}

abstract class LocationService {
  Future<Location?> getCurrentLocation();
}

abstract class QRCodeService {
  Future<Uint8List> generateQRCode({
    required String data,
    required int size,
  });
}

abstract class NotificationService {
  Future<void> sendCheckinConfirmation({
    required String playerId,
    required Game game,
    required DateTime checkinTime,
  });
  
  Future<void> sendLateArrivalNotification({
    required String gameId,
    required String organizerId,
    required String playerId,
    required int latenessMinutes,
    required String reason,
  });
  
  Future<void> sendNoShowNotification({
    required String playerId,
    required String gameId,
  });
}

abstract class GamesService {
  Future<Game?> getGameById(String gameId);
  Future<void> updateGameCheckinStats({
    required String gameId,
    required int checkedInCount,
    required int registeredCount,
  });
  Future<void> startGame(String gameId);
}
