import 'dart:async';
import 'package:flutter/foundation.dart';

// Core game orchestration service
class GamesService {
  final GamesRepository _gamesRepository;
  final VenuesService _venuesService;
  final BookingsService _bookingsService;
  final GameNotificationsService _notificationsService;
  final CheckinService _checkinService;
  final WeatherIntegrationService _weatherService;
  
  final StreamController<GameLifecycleEvent> _lifecycleController = 
      StreamController<GameLifecycleEvent>.broadcast();

  GamesService({
    required GamesRepository gamesRepository,
    required VenuesService venuesService,
    required BookingsService bookingsService,
    required GameNotificationsService notificationsService,
    required CheckinService checkinService,
    required WeatherIntegrationService weatherService,
  }) : _gamesRepository = gamesRepository,
       _venuesService = venuesService,
       _bookingsService = bookingsService,
       _notificationsService = notificationsService,
       _checkinService = checkinService,
       _weatherService = weatherService;

  Stream<GameLifecycleEvent> get lifecycleEvents => _lifecycleController.stream;

  // GAME CREATION FLOW
  Future<CreateGameResult> createGame(CreateGameRequest request) async {
    try {
      // 1. Validate all inputs
      final validationResult = await _validateGameCreation(request);
      if (!validationResult.isValid) {
        return CreateGameResult.failure(
          error: 'Validation failed: ${validationResult.errors.join(', ')}',
          validationErrors: validationResult.errors,
        );
      }

      // 2. Check venue availability if venue is specified
      String? bookingId;
      if (request.venueId != null) {
        final availabilityResult = await _venuesService.checkAvailability(
          venueId: request.venueId!,
          dateTime: request.dateTime,
          duration: request.duration,
        );
        
        if (!availabilityResult.isAvailable) {
          return CreateGameResult.failure(
            error: 'Venue not available at requested time',
            suggestedTimes: availabilityResult.suggestedTimes,
          );
        }

        // 3. Create booking if venue requires it
        if (availabilityResult.requiresBooking) {
          final bookingResult = await _bookingsService.createBooking(
            CreateBookingRequest(
              venueId: request.venueId!,
              dateTime: request.dateTime,
              duration: request.duration,
              organizerId: request.organizerId,
              gameTitle: request.title,
              maxPlayers: request.maxPlayers,
            ),
          );
          
          if (!bookingResult.isSuccess) {
            return CreateGameResult.failure(
              error: 'Failed to book venue: ${bookingResult.error}',
            );
          }
          bookingId = bookingResult.bookingId;
        }
      }

      // 4. Create game record
      final game = Game(
        id: _generateGameId(),
        title: request.title,
        description: request.description,
        sport: request.sport,
        dateTime: request.dateTime,
        duration: request.duration,
        venueId: request.venueId,
        bookingId: bookingId,
        organizerId: request.organizerId,
        maxPlayers: request.maxPlayers,
        skillLevel: request.skillLevel,
        isPrivate: request.isPrivate,
        price: request.price,
        equipmentProvided: request.equipmentProvided,
        rules: request.rules,
        status: GameStatus.open,
        players: [request.organizerId], // Organizer is automatically added
        waitlist: [],
        createdAt: DateTime.now(),
      );

      final createdGame = await _gamesRepository.createGame(game);

      // 5. Generate QR code for check-ins
      await _checkinService.generateGameQRCode(createdGame.id);

      // 6. Send invitations if specified
      if (request.invitedPlayerIds?.isNotEmpty == true) {
        await _sendGameInvitations(createdGame, request.invitedPlayerIds!);
      }

      // 7. Set up notifications
      await _setupGameNotifications(createdGame);

      // 8. Schedule weather monitoring
      await _weatherService.scheduleWeatherMonitoring(createdGame);

      // Emit lifecycle event
      _lifecycleController.add(GameLifecycleEvent(
        gameId: createdGame.id,
        type: GameLifecycleEventType.created,
        timestamp: DateTime.now(),
      ));

      return CreateGameResult.success(
        game: createdGame,
        bookingId: bookingId,
      );

    } catch (e, stackTrace) {
      debugPrint('Error creating game: $e\n$stackTrace');
      return CreateGameResult.failure(
        error: 'Failed to create game: $e',
      );
    }
  }

  // GAME LIFECYCLE MANAGEMENT
  Future<void> handlePreGameReminders() async {
    final now = DateTime.now();
    final upcoming24Hours = now.add(const Duration(hours: 24));
    final upcoming1Hour = now.add(const Duration(hours: 1));

    // Get games in reminder windows
    final games24h = await _gamesRepository.getGamesByDateRange(
      start: upcoming24Hours.subtract(const Duration(minutes: 5)),
      end: upcoming24Hours.add(const Duration(minutes: 5)),
    );

    final games1h = await _gamesRepository.getGamesByDateRange(
      start: upcoming1Hour.subtract(const Duration(minutes: 5)),
      end: upcoming1Hour.add(const Duration(minutes: 5)),
    );

    // Send 24-hour reminders
    for (final game in games24h) {
      await _notificationsService.send24HourReminder(game);
      _lifecycleController.add(GameLifecycleEvent(
        gameId: game.id,
        type: GameLifecycleEventType.reminder24h,
        timestamp: now,
      ));
    }

    // Send 1-hour reminders
    for (final game in games1h) {
      await _notificationsService.send1HourReminder(game);
      _lifecycleController.add(GameLifecycleEvent(
        gameId: game.id,
        type: GameLifecycleEventType.reminder1h,
        timestamp: now,
      ));
    }
  }

  Future<void> manageCheckinWindows() async {
    final now = DateTime.now();
    
    // Open check-in windows (30 minutes before game)
    final gamesStartingSoon = await _gamesRepository.getGamesByDateRange(
      start: now.add(const Duration(minutes: 25)),
      end: now.add(const Duration(minutes: 35)),
    );

    for (final game in gamesStartingSoon) {
      if (game.checkinWindowOpen != true) {
        await _gamesRepository.updateGame(
          game.copyWith(checkinWindowOpen: true),
        );
        
        await _notificationsService.sendCheckinWindowAlert(game);
        
        _lifecycleController.add(GameLifecycleEvent(
          gameId: game.id,
          type: GameLifecycleEventType.checkinOpened,
          timestamp: now,
        ));
      }
    }

    // Close check-in windows (game start time)
    final gamesStartingNow = await _gamesRepository.getGamesByDateRange(
      start: now.subtract(const Duration(minutes: 5)),
      end: now.add(const Duration(minutes: 5)),
    );

    for (final game in gamesStartingNow) {
      if (game.checkinWindowOpen == true) {
        await _gamesRepository.updateGame(
          game.copyWith(
            checkinWindowOpen: false,
            status: GameStatus.inProgress,
          ),
        );

        _lifecycleController.add(GameLifecycleEvent(
          gameId: game.id,
          type: GameLifecycleEventType.gameStarted,
          timestamp: now,
        ));
      }
    }
  }

  Future<void> handlePostGameRatings() async {
    final now = DateTime.now();
    final recentlyCompleted = now.subtract(const Duration(hours: 2));

    // Get games completed 2 hours ago
    final completedGames = await _gamesRepository.getGamesByDateRange(
      start: recentlyCompleted.subtract(const Duration(minutes: 5)),
      end: recentlyCompleted.add(const Duration(minutes: 5)),
    );

    for (final game in completedGames.where((g) => g.status == GameStatus.completed)) {
      await _notificationsService.sendRatingReminder(game);
      
      _lifecycleController.add(GameLifecycleEvent(
        gameId: game.id,
        type: GameLifecycleEventType.ratingReminder,
        timestamp: now,
      ));
    }
  }

  Future<void> archiveOldGames() async {
    final archiveDate = DateTime.now().subtract(const Duration(days: 90));
    
    final oldGames = await _gamesRepository.getGamesOlderThan(archiveDate);
    
    for (final game in oldGames) {
      await _gamesRepository.archiveGame(game.id);
      
      _lifecycleController.add(GameLifecycleEvent(
        gameId: game.id,
        type: GameLifecycleEventType.archived,
        timestamp: DateTime.now(),
      ));
    }
  }

  // GAME MANAGEMENT
  Future<JoinGameResult> joinGame(String gameId, String playerId) async {
    try {
      final game = await _gamesRepository.getGameById(gameId);
      if (game == null) {
        return JoinGameResult.failure('Game not found');
      }

      // Check if game is joinable
      if (game.status != GameStatus.open) {
        return JoinGameResult.failure('Game is not open for joining');
      }

      // Check if player is already in game
      if (game.players.contains(playerId)) {
        return JoinGameResult.failure('You are already in this game');
      }

      // Check capacity
      if (game.players.length >= game.maxPlayers) {
        // Add to waitlist
        final updatedWaitlist = [...game.waitlist, playerId];
        await _gamesRepository.updateGame(
          game.copyWith(waitlist: updatedWaitlist),
        );

        await _notificationsService.sendWaitlistConfirmation(game, playerId);
        
        return JoinGameResult.waitlisted();
      }

      // Add player to game
      final updatedPlayers = [...game.players, playerId];
      final updatedGame = game.copyWith(players: updatedPlayers);
      
      await _gamesRepository.updateGame(updatedGame);

      // Send notifications
      await _notificationsService.sendJoinConfirmation(updatedGame, playerId);
      await _notificationsService.notifyOrganizerOfJoin(updatedGame, playerId);

      // Check if game is now full
      if (updatedPlayers.length >= game.maxPlayers) {
        await _gamesRepository.updateGame(
          updatedGame.copyWith(status: GameStatus.full),
        );
        await _notificationsService.sendGameFullNotification(updatedGame);
      }

      _lifecycleController.add(GameLifecycleEvent(
        gameId: gameId,
        type: GameLifecycleEventType.playerJoined,
        timestamp: DateTime.now(),
        playerId: playerId,
      ));

      return JoinGameResult.success();

    } catch (e) {
      return JoinGameResult.failure('Failed to join game: $e');
    }
  }

  Future<LeaveGameResult> leaveGame(String gameId, String playerId) async {
    try {
      final game = await _gamesRepository.getGameById(gameId);
      if (game == null) {
        return LeaveGameResult.failure('Game not found');
      }

      // Check if player is in game
      if (!game.players.contains(playerId) && !game.waitlist.contains(playerId)) {
        return LeaveGameResult.failure('You are not in this game');
      }

      // Handle cancellation policy if game is close to start time
      final hoursUntilGame = game.dateTime.difference(DateTime.now()).inHours;
      if (hoursUntilGame < 24 && game.players.contains(playerId)) {
        final cancellationResult = await _bookingsService.handleCancellation(
          gameId: gameId,
          playerId: playerId,
          hoursUntilGame: hoursUntilGame,
        );

        if (!cancellationResult.allowed) {
          return LeaveGameResult.failure(cancellationResult.reason ?? 'Cancellation not allowed');
        }
      }

      // Remove player
      final updatedPlayers = game.players.where((id) => id != playerId).toList();
      final updatedWaitlist = game.waitlist.where((id) => id != playerId).toList();

      // Move waitlisted player to main list if there's space
      String? promotedPlayerId;
      if (game.players.contains(playerId) && updatedWaitlist.isNotEmpty) {
        promotedPlayerId = updatedWaitlist.first;
        updatedPlayers.add(promotedPlayerId);
        updatedWaitlist.removeAt(0);
      }

      final updatedGame = game.copyWith(
        players: updatedPlayers,
        waitlist: updatedWaitlist,
        status: updatedPlayers.isEmpty 
            ? GameStatus.cancelled 
            : updatedPlayers.length < game.maxPlayers 
                ? GameStatus.open 
                : GameStatus.full,
      );

      await _gamesRepository.updateGame(updatedGame);

      // Send notifications
      if (promotedPlayerId != null) {
        await _notificationsService.sendWaitlistPromotion(updatedGame, promotedPlayerId);
      }

      await _notificationsService.notifyOrganizerOfLeave(updatedGame, playerId);

      _lifecycleController.add(GameLifecycleEvent(
        gameId: gameId,
        type: GameLifecycleEventType.playerLeft,
        timestamp: DateTime.now(),
        playerId: playerId,
      ));

      return LeaveGameResult.success();

    } catch (e) {
      return LeaveGameResult.failure('Failed to leave game: $e');
    }
  }

  Future<CancelGameResult> cancelGame(String gameId, String organizerId) async {
    try {
      final game = await _gamesRepository.getGameById(gameId);
      if (game == null) {
        return CancelGameResult.failure('Game not found');
      }

      if (game.organizerId != organizerId) {
        return CancelGameResult.failure('Only the organizer can cancel the game');
      }

      // Handle refunds if there are payments
      if (game.price > 0) {
        await _bookingsService.processGameCancellationRefunds(game);
      }

      // Cancel venue booking if exists
      if (game.bookingId != null) {
        await _bookingsService.cancelBooking(game.bookingId!);
      }

      // Update game status
      final cancelledGame = game.copyWith(
        status: GameStatus.cancelled,
        cancelledAt: DateTime.now(),
      );

      await _gamesRepository.updateGame(cancelledGame);

      // Notify all players
      await _notificationsService.sendGameCancellationNotification(cancelledGame);

      _lifecycleController.add(GameLifecycleEvent(
        gameId: gameId,
        type: GameLifecycleEventType.cancelled,
        timestamp: DateTime.now(),
      ));

      return CancelGameResult.success();

    } catch (e) {
      return CancelGameResult.failure('Failed to cancel game: $e');
    }
  }

  // PRIVATE HELPER METHODS
  Future<GameValidationResult> _validateGameCreation(CreateGameRequest request) async {
    final errors = <String>[];

    // Basic validation
    if (request.title.trim().isEmpty) {
      errors.add('Game title is required');
    }

    if (request.dateTime.isBefore(DateTime.now())) {
      errors.add('Game date must be in the future');
    }

    if (request.maxPlayers < 2) {
      errors.add('Game must allow at least 2 players');
    }

    if (request.duration.inMinutes < 30) {
      errors.add('Game duration must be at least 30 minutes');
    }

    if (request.price < 0) {
      errors.add('Game price cannot be negative');
    }

    // Venue validation
    if (request.venueId != null) {
      final venue = await _venuesService.getVenueById(request.venueId!);
      if (venue == null) {
        errors.add('Selected venue not found');
      } else {
        if (!venue.supportedSports.contains(request.sport)) {
          errors.add('Venue does not support ${request.sport}');
        }
      }
    }

    return GameValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  Future<void> _sendGameInvitations(Game game, List<String> playerIds) async {
    for (final playerId in playerIds) {
      await _notificationsService.sendGameInvitation(game, playerId);
    }
  }

  Future<void> _setupGameNotifications(Game game) async {
    await _notificationsService.scheduleGameNotifications(game);
  }

  String _generateGameId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void dispose() {
    _lifecycleController.close();
  }
}

// Data classes
class CreateGameRequest {
  final String title;
  final String description;
  final String sport;
  final DateTime dateTime;
  final Duration duration;
  final String? venueId;
  final String organizerId;
  final int maxPlayers;
  final String skillLevel;
  final bool isPrivate;
  final double price;
  final List<String> equipmentProvided;
  final Map<String, String> rules;
  final List<String>? invitedPlayerIds;

  CreateGameRequest({
    required this.title,
    required this.description,
    required this.sport,
    required this.dateTime,
    required this.duration,
    this.venueId,
    required this.organizerId,
    required this.maxPlayers,
    required this.skillLevel,
    this.isPrivate = false,
    this.price = 0.0,
    this.equipmentProvided = const [],
    this.rules = const {},
    this.invitedPlayerIds,
  });
}

class CreateGameResult {
  final bool isSuccess;
  final Game? game;
  final String? bookingId;
  final String? error;
  final List<String> validationErrors;
  final List<DateTime>? suggestedTimes;

  CreateGameResult._({
    required this.isSuccess,
    this.game,
    this.bookingId,
    this.error,
    this.validationErrors = const [],
    this.suggestedTimes,
  });

  factory CreateGameResult.success({
    required Game game,
    String? bookingId,
  }) {
    return CreateGameResult._(
      isSuccess: true,
      game: game,
      bookingId: bookingId,
    );
  }

  factory CreateGameResult.failure({
    required String error,
    List<String> validationErrors = const [],
    List<DateTime>? suggestedTimes,
  }) {
    return CreateGameResult._(
      isSuccess: false,
      error: error,
      validationErrors: validationErrors,
      suggestedTimes: suggestedTimes,
    );
  }
}

class GameValidationResult {
  final bool isValid;
  final List<String> errors;

  GameValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class JoinGameResult {
  final bool isSuccess;
  final bool isWaitlisted;
  final String? error;

  JoinGameResult._({
    required this.isSuccess,
    this.isWaitlisted = false,
    this.error,
  });

  factory JoinGameResult.success() {
    return JoinGameResult._(isSuccess: true);
  }

  factory JoinGameResult.waitlisted() {
    return JoinGameResult._(isSuccess: true, isWaitlisted: true);
  }

  factory JoinGameResult.failure(String error) {
    return JoinGameResult._(isSuccess: false, error: error);
  }
}

class LeaveGameResult {
  final bool isSuccess;
  final String? error;

  LeaveGameResult._({
    required this.isSuccess,
    this.error,
  });

  factory LeaveGameResult.success() {
    return LeaveGameResult._(isSuccess: true);
  }

  factory LeaveGameResult.failure(String error) {
    return LeaveGameResult._(isSuccess: false, error: error);
  }
}

class CancelGameResult {
  final bool isSuccess;
  final String? error;

  CancelGameResult._({
    required this.isSuccess,
    this.error,
  });

  factory CancelGameResult.success() {
    return CancelGameResult._(isSuccess: true);
  }

  factory CancelGameResult.failure(String error) {
    return CancelGameResult._(isSuccess: false, error: error);
  }
}

class GameLifecycleEvent {
  final String gameId;
  final GameLifecycleEventType type;
  final DateTime timestamp;
  final String? playerId;

  GameLifecycleEvent({
    required this.gameId,
    required this.type,
    required this.timestamp,
    this.playerId,
  });
}

enum GameLifecycleEventType {
  created,
  playerJoined,
  playerLeft,
  cancelled,
  reminder24h,
  reminder1h,
  checkinOpened,
  gameStarted,
  ratingReminder,
  archived,
}

// Placeholder imports - would be actual dependencies
abstract class GamesRepository {
  Future<Game> createGame(Game game);
  Future<Game?> getGameById(String id);
  Future<List<Game>> getGamesByDateRange({required DateTime start, required DateTime end});
  Future<List<Game>> getGamesOlderThan(DateTime date);
  Future<void> updateGame(Game game);
  Future<void> archiveGame(String gameId);
}

abstract class VenuesService {
  Future<VenueAvailabilityResult> checkAvailability({
    required String venueId,
    required DateTime dateTime,
    required Duration duration,
  });
  
  Future<Venue?> getVenueById(String venueId);
}

abstract class BookingsService {
  Future<CreateBookingResult> createBooking(CreateBookingRequest request);
  Future<CancellationResult> handleCancellation({
    required String gameId,
    required String playerId,
    required int hoursUntilGame,
  });
  Future<void> processGameCancellationRefunds(Game game);
  Future<void> cancelBooking(String bookingId);
}

abstract class GameNotificationsService {
  Future<void> send24HourReminder(Game game);
  Future<void> send1HourReminder(Game game);
  Future<void> sendCheckinWindowAlert(Game game);
  Future<void> sendRatingReminder(Game game);
  Future<void> sendWaitlistConfirmation(Game game, String playerId);
  Future<void> sendJoinConfirmation(Game game, String playerId);
  Future<void> notifyOrganizerOfJoin(Game game, String playerId);
  Future<void> sendGameFullNotification(Game game);
  Future<void> sendWaitlistPromotion(Game game, String playerId);
  Future<void> notifyOrganizerOfLeave(Game game, String playerId);
  Future<void> sendGameCancellationNotification(Game game);
  Future<void> sendGameInvitation(Game game, String playerId);
  Future<void> scheduleGameNotifications(Game game);
}

abstract class CheckinService {
  Future<void> generateGameQRCode(String gameId);
}

abstract class WeatherIntegrationService {
  Future<void> scheduleWeatherMonitoring(Game game);
}

// Data classes for service responses
class VenueAvailabilityResult {
  final bool isAvailable;
  final bool requiresBooking;
  final List<DateTime> suggestedTimes;

  VenueAvailabilityResult({
    required this.isAvailable,
    required this.requiresBooking,
    this.suggestedTimes = const [],
  });
}

class CreateBookingResult {
  final bool isSuccess;
  final String? bookingId;
  final String? error;

  CreateBookingResult._({
    required this.isSuccess,
    this.bookingId,
    this.error,
  });

  factory CreateBookingResult.success({required String bookingId}) {
    return CreateBookingResult._(isSuccess: true, bookingId: bookingId);
  }

  factory CreateBookingResult.failure(String error) {
    return CreateBookingResult._(isSuccess: false, error: error);
  }
}

class CancellationResult {
  final bool allowed;
  final String? reason;

  CancellationResult._({
    required this.allowed,
    this.reason,
  });

  factory CancellationResult.allowed() {
    return CancellationResult._(allowed: true);
  }

  factory CancellationResult.notAllowed(String reason) {
    return CancellationResult._(allowed: false, reason: reason);
  }
}

class Venue {
  final String id;
  final String name;
  final List<String> supportedSports;

  Venue({
    required this.id,
    required this.name,
    required this.supportedSports,
  });
}

// Placeholder for Game model
class Game {
  final String id;
  final String title;
  final String description;
  final String sport;
  final DateTime dateTime;
  final Duration duration;
  final String? venueId;
  final String? bookingId;
  final String organizerId;
  final int maxPlayers;
  final String skillLevel;
  final bool isPrivate;
  final double price;
  final List<String> equipmentProvided;
  final Map<String, String> rules;
  final GameStatus status;
  final List<String> players;
  final List<String> waitlist;
  final DateTime createdAt;
  final bool? checkinWindowOpen;
  final DateTime? cancelledAt;

  Game({
    required this.id,
    required this.title,
    required this.description,
    required this.sport,
    required this.dateTime,
    required this.duration,
    this.venueId,
    this.bookingId,
    required this.organizerId,
    required this.maxPlayers,
    required this.skillLevel,
    this.isPrivate = false,
    this.price = 0.0,
    this.equipmentProvided = const [],
    this.rules = const {},
    required this.status,
    required this.players,
    required this.waitlist,
    required this.createdAt,
    this.checkinWindowOpen,
    this.cancelledAt,
  });

  Game copyWith({
    String? id,
    String? title,
    String? description,
    String? sport,
    DateTime? dateTime,
    Duration? duration,
    String? venueId,
    String? bookingId,
    String? organizerId,
    int? maxPlayers,
    String? skillLevel,
    bool? isPrivate,
    double? price,
    List<String>? equipmentProvided,
    Map<String, String>? rules,
    GameStatus? status,
    List<String>? players,
    List<String>? waitlist,
    DateTime? createdAt,
    bool? checkinWindowOpen,
    DateTime? cancelledAt,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sport: sport ?? this.sport,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      venueId: venueId ?? this.venueId,
      bookingId: bookingId ?? this.bookingId,
      organizerId: organizerId ?? this.organizerId,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      skillLevel: skillLevel ?? this.skillLevel,
      isPrivate: isPrivate ?? this.isPrivate,
      price: price ?? this.price,
      equipmentProvided: equipmentProvided ?? this.equipmentProvided,
      rules: rules ?? this.rules,
      status: status ?? this.status,
      players: players ?? this.players,
      waitlist: waitlist ?? this.waitlist,
      createdAt: createdAt ?? this.createdAt,
      checkinWindowOpen: checkinWindowOpen ?? this.checkinWindowOpen,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

enum GameStatus { open, full, inProgress, completed, cancelled }

// Placeholder for additional dependencies
class CreateBookingRequest {
  final String venueId;
  final DateTime dateTime;
  final Duration duration;
  final String organizerId;
  final String gameTitle;
  final int maxPlayers;

  CreateBookingRequest({
    required this.venueId,
    required this.dateTime,
    required this.duration,
    required this.organizerId,
    required this.gameTitle,
    required this.maxPlayers,
  });
}
