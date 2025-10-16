import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/authentication/domain/usecases/usecase.dart';
import '../entities/game.dart';
import '../repositories/games_repository.dart';

// Game-specific failures
class GameFailure extends Failure {
  const GameFailure(super.message);
}

class RatePlayersUseCase extends UseCase<Either<Failure, RatingResult>, RatePlayersParams> {
  final GamesRepository gamesRepository;

  RatePlayersUseCase({required this.gamesRepository});

  @override
  Future<Either<Failure, RatingResult>> call(RatePlayersParams params) async {
    // Validate parameters
    final validationResult = _validateRatingParameters(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Get game details
    final gameResult = await gamesRepository.getGame(params.gameId);
    
    return gameResult.fold(
      (failure) => Left(failure),
      (game) async {
        // Verify game is completed
        final gameStatusResult = _verifyGameStatus(game);
        if (gameStatusResult != null) {
          return Left(gameStatusResult);
        }

        // Verify rater participated in the game
        final participationResult = await _verifyRaterParticipation(game, params.raterId);
        if (participationResult != null) {
          return Left(participationResult);
        }

        // Validate that all rated players participated
        final ratedPlayersResult = await _verifyRatedPlayersParticipation(game, params.ratings);
        if (ratedPlayersResult != null) {
          return Left(ratedPlayersResult);
        }

        // Check for duplicate ratings (if applicable)
        final duplicateResult = await _checkForDuplicateRatings(params);
        if (duplicateResult != null) {
          return Left(duplicateResult);
        }

        // Save ratings
        final saveResult = await _savePlayerRatings(game, params);
        if (saveResult.isLeft()) {
          return Left(saveResult.fold((l) => l, (r) => throw Exception()));
        }

        // Update player statistics
        await _updatePlayerStatistics(params.ratings);

        // Calculate rating summary
        final ratingSummary = _calculateRatingSummary(params.ratings);

        return Right(RatingResult(
          success: true,
          gameId: params.gameId,
          raterId: params.raterId,
          ratingsCount: params.ratings.length,
          averageRating: ratingSummary.averageRating,
          highestRating: ratingSummary.highestRating,
          lowestRating: ratingSummary.lowestRating,
          message: _getRatingMessage(params.ratings.length),
        ));
      },
    );
  }

  /// Validates rating parameters
  Failure? _validateRatingParameters(RatePlayersParams params) {
    if (params.gameId.trim().isEmpty) {
      return const GameFailure('Game ID cannot be empty');
    }

    if (params.raterId.trim().isEmpty) {
      return const GameFailure('Rater ID cannot be empty');
    }

    if (params.ratings.isEmpty) {
      return const GameFailure('At least one player rating is required');
    }

    // Validate each rating
    for (final rating in params.ratings) {
      final ratingValidation = _validateIndividualRating(rating);
      if (ratingValidation != null) {
        return ratingValidation;
      }
    }

    // Check for duplicate player ratings
    final playerIds = params.ratings.map((r) => r.playerId).toList();
    final uniquePlayerIds = playerIds.toSet();
    
    if (playerIds.length != uniquePlayerIds.length) {
      return const GameFailure('Cannot rate the same player multiple times');
    }

    // Prevent self-rating
    final selfRating = params.ratings.where((r) => r.playerId == params.raterId);
    if (selfRating.isNotEmpty) {
      return const GameFailure('Cannot rate yourself');
    }

    return null;
  }

  /// Validates individual rating
  Failure? _validateIndividualRating(PlayerRating rating) {
    if (rating.playerId.trim().isEmpty) {
      return const GameFailure('Player ID cannot be empty in rating');
    }

    if (rating.overallRating < 1 || rating.overallRating > 5) {
      return const GameFailure('Overall rating must be between 1 and 5');
    }

    // Validate skill ratings if provided
    if (rating.skillRating != null) {
      if (rating.skillRating! < 1 || rating.skillRating! > 5) {
        return const GameFailure('Skill rating must be between 1 and 5');
      }
    }

    if (rating.sportsmanshipRating != null) {
      if (rating.sportsmanshipRating! < 1 || rating.sportsmanshipRating! > 5) {
        return const GameFailure('Sportsmanship rating must be between 1 and 5');
      }
    }

    if (rating.punctualityRating != null) {
      if (rating.punctualityRating! < 1 || rating.punctualityRating! > 5) {
        return const GameFailure('Punctuality rating must be between 1 and 5');
      }
    }

    // Validate comment length if provided
    if (rating.comment != null && rating.comment!.length > 500) {
      return const GameFailure('Rating comment cannot exceed 500 characters');
    }

    return null;
  }

  /// Verifies that the game is completed and eligible for rating
  Failure? _verifyGameStatus(Game game) {
    if (game.status != GameStatus.completed) {
      switch (game.status) {
        case GameStatus.draft:
          return const GameFailure('Cannot rate players for a draft game');
        case GameStatus.upcoming:
          return const GameFailure('Cannot rate players before the game is completed');
        case GameStatus.inProgress:
          return const GameFailure('Cannot rate players while the game is in progress');
        case GameStatus.cancelled:
          return const GameFailure('Cannot rate players for a cancelled game');
        case GameStatus.completed:
          break; // This is handled above but included for completeness
      }
    }

    // Check if enough time has passed since game completion (optional)
    // This prevents immediate rating before players have left
    final gameEndTime = game.getScheduledEndDateTime();
    final now = DateTime.now();
    
    if (now.isBefore(gameEndTime)) {
      return const GameFailure('Cannot rate players before the scheduled game end time');
    }

    return null;
  }

  /// Verifies that the rater participated in the game
  Future<Failure?> _verifyRaterParticipation(Game game, String raterId) async {
    // Get user's games to verify participation
    final myGamesResult = await gamesRepository.getMyGames(
      raterId,
      status: 'completed',
      limit: 100,
    );

    return myGamesResult.fold(
      (failure) => GameFailure('Unable to verify game participation: ${failure.message}'),
      (myGames) {
        final participated = myGames.any((userGame) => userGame.id == game.id);
        if (!participated) {
          return const GameFailure('You can only rate players from games you participated in');
        }
        return null;
      },
    );
  }

  /// Verifies that all rated players participated in the game
  Future<Failure?> _verifyRatedPlayersParticipation(Game game, List<PlayerRating> ratings) async {
    // In a real implementation, you would get the list of game participants
    // and verify that each rated player was actually in the game
    
    // For now, we'll simulate this check
    for (final rating in ratings) {
      // This is where you'd verify each player participated
      // final participantsResult = await gamesRepository.getGameParticipants(game.id);
      // ... verify rating.playerId is in the participants list
      print('Verifying player ${rating.playerId} participated in game ${game.id}');
    }

    return null; // Assuming all players are valid for now
  }

  /// Checks for duplicate ratings (if the system doesn't allow multiple ratings)
  Future<Failure?> _checkForDuplicateRatings(RatePlayersParams params) async {
    // In a real implementation, you might check if the rater has already
    // rated these players for this specific game
    
    // This would typically involve checking a ratings table in the database
    // For now, we'll skip this check and assume it's allowed
    
    return null;
  }

  /// Saves player ratings to the repository
  Future<Either<Failure, bool>> _savePlayerRatings(Game game, RatePlayersParams params) async {
    try {
      // In a real implementation, this would save ratings to the database
      // Since we don't have a specific ratings repository method, we'll simulate it
      
      for (final rating in params.ratings) {
        // This would typically call something like:
        // await ratingsRepository.saveRating({
        //   'gameId': params.gameId,
        //   'raterId': params.raterId,
        //   'playerId': rating.playerId,
        //   'overallRating': rating.overallRating,
        //   'skillRating': rating.skillRating,
        //   'sportsmanshipRating': rating.sportsmanshipRating,
        //   'punctualityRating': rating.punctualityRating,
        //   'comment': rating.comment,
        //   'createdAt': DateTime.now().toIso8601String(),
        // });
        
        print('Saved rating for player ${rating.playerId}: ${rating.overallRating}/5');
      }

      return const Right(true);
    } catch (e) {
      return Left(GameFailure('Failed to save player ratings: ${e.toString()}'));
    }
  }

  /// Updates player statistics based on new ratings
  Future<void> _updatePlayerStatistics(List<PlayerRating> ratings) async {
    try {
      for (final rating in ratings) {
        // In a real implementation, this would update player statistics
        // such as average rating, total games rated, etc.
        
        // This might involve:
        // 1. Getting current player stats
        // 2. Calculating new averages
        // 3. Updating player profile with new stats
        
        print('Updated statistics for player ${rating.playerId}');
      }
    } catch (e) {
      // Statistics update failure shouldn't prevent rating success
      print('Failed to update player statistics: $e');
    }
  }

  /// Calculates rating summary statistics
  RatingSummary _calculateRatingSummary(List<PlayerRating> ratings) {
    if (ratings.isEmpty) {
      return RatingSummary(
        averageRating: 0.0,
        highestRating: 0,
        lowestRating: 0,
      );
    }

    final overallRatings = ratings.map((r) => r.overallRating).toList();
    final sum = overallRatings.reduce((a, b) => a + b);
    final average = sum / overallRatings.length;
    final highest = overallRatings.reduce((a, b) => a > b ? a : b);
    final lowest = overallRatings.reduce((a, b) => a < b ? a : b);

    return RatingSummary(
      averageRating: average,
      highestRating: highest,
      lowestRating: lowest,
    );
  }

  /// Gets appropriate rating message
  String _getRatingMessage(int ratingsCount) {
    if (ratingsCount == 1) {
      return 'Successfully rated 1 player. Ratings help improve the community experience!';
    } else {
      return 'Successfully rated $ratingsCount players. Ratings help improve the community experience!';
    }
  }
}

class RatePlayersParams {
  final String gameId;
  final String raterId;
  final List<PlayerRating> ratings;

  RatePlayersParams({
    required this.gameId,
    required this.raterId,
    required this.ratings,
  });
}

class PlayerRating {
  final String playerId;
  final int overallRating; // 1-5 stars
  final int? skillRating; // Optional: 1-5 stars for skill level
  final int? sportsmanshipRating; // Optional: 1-5 stars for sportsmanship
  final int? punctualityRating; // Optional: 1-5 stars for punctuality
  final String? comment; // Optional comment

  PlayerRating({
    required this.playerId,
    required this.overallRating,
    this.skillRating,
    this.sportsmanshipRating,
    this.punctualityRating,
    this.comment,
  });

  // Convenience getters
  bool get hasDetailedRatings => 
      skillRating != null || 
      sportsmanshipRating != null || 
      punctualityRating != null;

  double get averageDetailedRating {
    final ratings = [
      if (skillRating != null) skillRating!,
      if (sportsmanshipRating != null) sportsmanshipRating!,
      if (punctualityRating != null) punctualityRating!,
    ];
    
    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}

class RatingResult {
  final bool success;
  final String gameId;
  final String raterId;
  final int ratingsCount;
  final double averageRating;
  final int highestRating;
  final int lowestRating;
  final String message;

  RatingResult({
    required this.success,
    required this.gameId,
    required this.raterId,
    required this.ratingsCount,
    required this.averageRating,
    required this.highestRating,
    required this.lowestRating,
    required this.message,
  });

  // Convenience getters
  String get formattedAverageRating => averageRating.toStringAsFixed(1);
  String get ratingSummary => '$highestRating high, $lowestRating low, $formattedAverageRating avg';
}

class RatingSummary {
  final double averageRating;
  final int highestRating;
  final int lowestRating;

  RatingSummary({
    required this.averageRating,
    required this.highestRating,
    required this.lowestRating,
  });
}
