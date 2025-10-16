import '../models/game_model.dart';
import '../models/player_model.dart';

// Custom exceptions for game operations
class GameServerException implements Exception {
  final String message;
  GameServerException(this.message);
  
  @override
  String toString() => message;
}

class GameNotFoundException implements Exception {
  final String message;
  GameNotFoundException(this.message);
  
  @override
  String toString() => message;
}

class GameFullException implements Exception {
  final String message;
  GameFullException(this.message);
  
  @override
  String toString() => message;
}

class InsufficientPlayersException implements Exception {
  final String message;
  InsufficientPlayersException(this.message);
  
  @override
  String toString() => message;
}

class GameAlreadyStartedException implements Exception {
  final String message;
  GameAlreadyStartedException(this.message);
  
  @override
  String toString() => message;
}

class UnauthorizedGameActionException implements Exception {
  final String message;
  UnauthorizedGameActionException(this.message);
}

abstract class GamesRemoteDataSource {
  /// Creates a new game in the remote server
  Future<GameModel> createGame(Map<String, dynamic> gameData);

  /// Updates an existing game in the remote server
  Future<GameModel> updateGame(String gameId, Map<String, dynamic> updates);

  /// Retrieves a single game from the remote server
  Future<GameModel> getGame(String gameId);

  /// Retrieves a list of games from the remote server
  Future<List<GameModel>> getGames({
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
    String? sortBy,
    bool ascending = true,
  });

  /// Allows a player to join a game
  Future<bool> joinGame(String gameId, String playerId);

  /// Allows a player to leave a game
  Future<bool> leaveGame(String gameId, String playerId);

  /// Cancels a game
  Future<bool> cancelGame(String gameId);

  /// Retrieves games for a specific user
  Future<List<GameModel>> getMyGames(
    String userId, {
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Searches games based on query and filters
  Future<List<GameModel>> searchGames(
    String query, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  });

  /// Gets games near a specific location
  Future<List<GameModel>> getNearbyGames(
    double latitude,
    double longitude,
    double radiusKm, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  });

  /// Gets games by sport type
  Future<List<GameModel>> getGamesBySport(
    String sportType, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  });

  /// Gets popular/trending games
  Future<List<GameModel>> getTrendingGames({
    int page = 1,
    int limit = 20,
  });

  /// Gets games recommended for a user
  Future<List<GameModel>> getRecommendedGames(
    String userId, {
    int page = 1,
    int limit = 20,
  });

  /// Updates game status
  Future<bool> updateGameStatus(String gameId, String status);

  /// Invites players to a game
  Future<bool> invitePlayersToGame(
    String gameId,
    List<String> playerIds,
    String? message,
  );

  /// Responds to a game invitation
  Future<bool> respondToGameInvitation(
    String gameId,
    String playerId,
    bool accepted,
  );

  /// Gets game statistics for a user
  Future<Map<String, dynamic>> getUserGameStats(String userId);

  /// Reports a game
  Future<bool> reportGame(String gameId, String reason, String? description);

  /// Toggles game favorite status
  Future<bool> toggleGameFavorite(String gameId, String userId);

  /// Gets user's favorite games
  Future<List<GameModel>> getFavoriteGames(
    String userId, {
    int page = 1,
    int limit = 20,
  });

  /// Checks if a user can join a specific game
  Future<bool> canUserJoinGame(String gameId, String userId);

  /// Gets game history for a user
  Future<List<GameModel>> getGameHistory(
    String userId, {
    int page = 1,
    int limit = 20,
  });

  /// Duplicates a game with new date/time
  Future<GameModel> duplicateGame(
    String gameId,
    String newDate,
    String newStartTime,
    String newEndTime,
  );

  /// Gets all players for a specific game
  Future<List<PlayerModel>> getGamePlayers(String gameId);
}
