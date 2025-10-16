import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/authentication/domain/usecases/usecase.dart';
import '../entities/game.dart';
import '../repositories/games_repository.dart';

// Game-specific failures
class GameFailure extends Failure {
  const GameFailure(super.message);
}

enum CheckInMethod {
  qrCode,
  manual,
  location,
}

class CheckInGameUseCase extends UseCase<Either<Failure, CheckInResult>, CheckInGameParams> {
  final GamesRepository gamesRepository;

  CheckInGameUseCase({required this.gamesRepository});

  @override
  Future<Either<Failure, CheckInResult>> call(CheckInGameParams params) async {
    // Validate parameters
    final validationResult = _validateCheckInParameters(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Get game details
    final gameResult = await gamesRepository.getGame(params.gameId);
    
    return gameResult.fold(
      (failure) => Left(failure),
      (game) async {
        // Validate check-in eligibility
        final eligibilityResult = await _validateCheckInEligibility(game, params);
        if (eligibilityResult != null) {
          return Left(eligibilityResult);
        }

        // Verify player is registered for this game
        final registrationResult = await _verifyPlayerRegistration(game, params.playerId);
        if (registrationResult != null) {
          return Left(registrationResult);
        }

        // Validate check-in time window
        final timeWindowResult = _validateCheckInTimeWindow(game);
        if (timeWindowResult != null) {
          return Left(timeWindowResult);
        }

        // Process check-in based on method
        final checkInResult = await _processCheckIn(game, params);
        if (checkInResult.isLeft()) {
          return Left(checkInResult.fold((l) => l, (r) => throw Exception()));
        }

        // Update game and player check-in status
        final updateResult = await _updateCheckInStatus(game, params);
        if (updateResult != null) {
          return Left(updateResult);
        }

        // Notify organizer of check-in
        await _notifyGameOrganizer(game, params);

        // Check if minimum players requirement is met
        final updatedGameResult = await gamesRepository.getGame(params.gameId);
        final canStartGame = updatedGameResult.fold(
          (failure) => false,
          (updatedGame) => _canGameStart(updatedGame),
        );

        return Right(CheckInResult(
          success: true,
          checkInTime: DateTime.now(),
          method: params.method,
          gameCanStart: canStartGame,
          message: _getCheckInMessage(game, canStartGame),
        ));
      },
    );
  }

  /// Validates check-in parameters
  Failure? _validateCheckInParameters(CheckInGameParams params) {
    if (params.gameId.trim().isEmpty) {
      return const GameFailure('Game ID cannot be empty');
    }

    if (params.playerId.trim().isEmpty) {
      return const GameFailure('Player ID cannot be empty');
    }

    // Validate QR code if method is QR
    if (params.method == CheckInMethod.qrCode) {
      if (params.qrCodeData == null || params.qrCodeData!.trim().isEmpty) {
        return const GameFailure('QR code data is required for QR check-in');
      }
    }

    // Validate location if method is location-based
    if (params.method == CheckInMethod.location) {
      if (params.playerLatitude == null || params.playerLongitude == null) {
        return const GameFailure('Location coordinates are required for location-based check-in');
      }
    }

    return null;
  }

  /// Validates if check-in is allowed for this game and player
  Future<Failure?> _validateCheckInEligibility(Game game, CheckInGameParams params) async {
    // Check if game allows check-in
    if (!game.checkInEnabled) {
      return const GameFailure('Check-in is not enabled for this game');
    }

    // Check game status
    if (game.status != GameStatus.upcoming) {
      switch (game.status) {
        case GameStatus.draft:
          return const GameFailure('Cannot check in to a draft game');
        case GameStatus.inProgress:
          return const GameFailure('Game is already in progress. Check-in is no longer available');
        case GameStatus.completed:
          return const GameFailure('Game has been completed');
        case GameStatus.cancelled:
          return const GameFailure('Game has been cancelled');
        case GameStatus.upcoming:
          break; // This is handled above but included for completeness
      }
    }

    return null;
  }

  /// Verifies that the player is registered for this game
  Future<Failure?> _verifyPlayerRegistration(Game game, String playerId) async {
    // Get user's games to verify registration
    final myGamesResult = await gamesRepository.getMyGames(
      playerId,
      status: 'upcoming',
      limit: 100,
    );

    return myGamesResult.fold(
      (failure) => GameFailure('Unable to verify game registration: ${failure.message}'),
      (myGames) {
        final isRegistered = myGames.any((userGame) => userGame.id == game.id);
        if (!isRegistered) {
          return const GameFailure('You are not registered for this game');
        }
        return null;
      },
    );
  }

  /// Validates check-in time window
  Failure? _validateCheckInTimeWindow(Game game) {
    final now = DateTime.now();
    final gameStartTime = game.getScheduledStartDateTime();
    
    // Check if game has passed
    if (now.isAfter(gameStartTime)) {
      return const GameFailure('Check-in period has ended. Game start time has passed');
    }
    
    // Check if check-in window is open (typically 30 minutes before)
    final checkInWindowStart = gameStartTime.subtract(const Duration(minutes: 30));
    
    if (now.isBefore(checkInWindowStart)) {
      final minutesUntilCheckIn = checkInWindowStart.difference(now).inMinutes;
      return GameFailure('Check-in opens in $minutesUntilCheckIn minutes (30 minutes before game start)');
    }
    
    return null;
  }

  /// Processes check-in based on the specified method
  Future<Either<Failure, bool>> _processCheckIn(Game game, CheckInGameParams params) async {
    switch (params.method) {
      case CheckInMethod.qrCode:
        return _processQrCodeCheckIn(game, params);
      case CheckInMethod.manual:
        return _processManualCheckIn(game, params);
      case CheckInMethod.location:
        return _processLocationCheckIn(game, params);
    }
  }

  /// Processes QR code check-in
  Future<Either<Failure, bool>> _processQrCodeCheckIn(Game game, CheckInGameParams params) async {
    try {
      // Validate QR code format and content
      final qrData = params.qrCodeData!;
      
      // Expected format: "DABBLER_CHECKIN:{gameId}:{timestamp}:{hash}"
      if (!qrData.startsWith('DABBLER_CHECKIN:')) {
        return const Left(GameFailure('Invalid QR code format'));
      }

      final parts = qrData.split(':');
      if (parts.length != 4) {
        return const Left(GameFailure('Invalid QR code structure'));
      }

      final qrGameId = parts[1];
      final timestamp = parts[2];
      // final hash = parts[3]; // Used for security verification in real implementation

      // Verify game ID matches
      if (qrGameId != game.id) {
        return const Left(GameFailure('QR code is for a different game'));
      }

      // Verify QR code is not expired (valid for 5 minutes)
      final qrTimestamp = int.tryParse(timestamp);
      if (qrTimestamp == null) {
        return const Left(GameFailure('Invalid QR code timestamp'));
      }

      final qrTime = DateTime.fromMillisecondsSinceEpoch(qrTimestamp);
      final now = DateTime.now();
      
      if (now.difference(qrTime).inMinutes > 5) {
        return const Left(GameFailure('QR code has expired. Please request a new one'));
      }

      // In a real implementation, you would verify the hash for security
      // This prevents tampering with QR codes
      
      return const Right(true);
    } catch (e) {
      return Left(GameFailure('QR code processing error: ${e.toString()}'));
    }
  }

  /// Processes manual check-in (by organizer or admin)
  Future<Either<Failure, bool>> _processManualCheckIn(Game game, CheckInGameParams params) async {
    // Verify that the person doing manual check-in has authority
    if (params.checkedInBy == null) {
      return const Left(GameFailure('Manual check-in requires operator identification'));
    }

    // Verify operator is game organizer or has admin privileges
    if (params.checkedInBy != game.organizerId) {
      // In a real implementation, you would check for admin privileges
      // For now, only allow game organizer
      return const Left(GameFailure('Only the game organizer can perform manual check-in'));
    }

    return const Right(true);
  }

  /// Processes location-based check-in
  Future<Either<Failure, bool>> _processLocationCheckIn(Game game, CheckInGameParams params) async {
    // This would require venue location data
    // For now, this is a simplified implementation
    
    if (game.venueId == null) {
      return const Left(GameFailure('Location-based check-in requires a venue'));
    }

    // In a real implementation, you would:
    // 1. Get venue coordinates from VenuesRepository
    // 2. Calculate distance between player and venue
    // 3. Allow check-in if within acceptable range (e.g., 100 meters)
    
    // Simplified validation - just check coordinates are provided
    if (params.playerLatitude == null || params.playerLongitude == null) {
      return const Left(GameFailure('Player location is required for location-based check-in'));
    }

    // TODO: Implement actual distance calculation with venue coordinates
    return const Right(true);
  }

  /// Updates check-in status for the player in the game
  Future<Failure?> _updateCheckInStatus(Game game, CheckInGameParams params) async {
    // This would typically call a repository method to update check-in status
    // Since this specific method doesn't exist in our current repository,
    // we'll simulate the update
    
    try {
      // In a real implementation, you would update the game_players table
      // with check-in timestamp and method
      print('Updated check-in status for player ${params.playerId} in game ${game.id}');
      return null;
    } catch (e) {
      return GameFailure('Failed to update check-in status: ${e.toString()}');
    }
  }

  /// Notifies game organizer of player check-in
  Future<void> _notifyGameOrganizer(Game game, CheckInGameParams params) async {
    try {
      // This would integrate with notification service
      print('Notifying organizer ${game.organizerId}: Player ${params.playerId} checked in to ${game.title}');
    } catch (e) {
      // Notification failure shouldn't prevent check-in
      print('Failed to notify organizer: $e');
    }
  }

  /// Determines if the game can start based on current check-ins
  bool _canGameStart(Game game) {
    // In a real implementation, you would count checked-in players
    // For now, we'll use a simple check based on current players
    return game.currentPlayers >= game.minPlayers;
  }

  /// Gets appropriate check-in message
  String _getCheckInMessage(Game game, bool canGameStart) {
    if (canGameStart) {
      return 'Check-in successful! The game has minimum players and can start on time.';
    } else {
      final needed = game.minPlayers - game.currentPlayers;
      return 'Check-in successful! Waiting for $needed more player(s) to reach minimum.';
    }
  }
}

class CheckInGameParams {
  final String gameId;
  final String playerId;
  final CheckInMethod method;
  final String? qrCodeData; // Required for QR code check-in
  final double? playerLatitude; // Required for location check-in
  final double? playerLongitude; // Required for location check-in
  final String? checkedInBy; // Required for manual check-in

  CheckInGameParams({
    required this.gameId,
    required this.playerId,
    required this.method,
    this.qrCodeData,
    this.playerLatitude,
    this.playerLongitude,
    this.checkedInBy,
  });
}

class CheckInResult {
  final bool success;
  final DateTime checkInTime;
  final CheckInMethod method;
  final bool gameCanStart;
  final String message;

  CheckInResult({
    required this.success,
    required this.checkInTime,
    required this.method,
    required this.gameCanStart,
    required this.message,
  });

  // Convenience getters
  String get formattedTime => '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
  String get methodDisplay => method.name.toUpperCase().replaceAll('_', ' ');
}
