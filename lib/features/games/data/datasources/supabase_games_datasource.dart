import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'games_remote_data_source.dart';
import '../models/game_model.dart';
import '../models/player_model.dart';

class SupabaseGamesDataSource implements GamesRemoteDataSource {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _gamesSubscription;
  
  // Real-time controllers
  final StreamController<GameModel> _gameUpdatesController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerEventsController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _gameStatusController = StreamController.broadcast();

  SupabaseGamesDataSource(this._supabaseClient) {
    _initializeRealTimeSubscriptions();
  }

  // Real-time streams
  Stream<GameModel> get gameUpdates => _gameUpdatesController.stream;
  Stream<Map<String, dynamic>> get playerEvents => _playerEventsController.stream;
  Stream<Map<String, dynamic>> get gameStatusChanges => _gameStatusController.stream;

  void _initializeRealTimeSubscriptions() {
    // Subscribe to games table changes
    _gamesSubscription = _supabaseClient
        .from('games')
        .stream(primaryKey: ['id'])
        .listen((data) {
          for (final record in data) {
            try {
              final gameModel = GameModel.fromJson(record);
              _gameUpdatesController.add(gameModel);
            } catch (e) {
              print('Error parsing game update: $e');
            }
          }
        });
  }

  @override
  Future<GameModel> createGame(Map<String, dynamic> gameData) async {
    try {
      print('📤 [Datasource] Inserting game with data: $gameData');
      
      // Insert game
      final gameResponse = await _supabaseClient
          .from('games')
          .insert(gameData)
          .select()
          .single();

      print('✅ [Datasource] Game inserted successfully: ${gameResponse['id']}');

      // Add organizer as first player
      await _supabaseClient.from('game_players').insert({
        'game_id': gameResponse['id'],
        'player_id': gameData['organizer_id'],
        'status': 'confirmed',
        'joined_at': DateTime.now().toIso8601String(),
      });

      print('✅ [Datasource] Organizer added to game_players');

      return GameModel.fromJson(gameResponse);
    } on PostgrestException catch (e) {
      print('❌ [Datasource] PostgrestException: ${e.message}');
      print('❌ [Datasource] Error code: ${e.code}');
      print('❌ [Datasource] Error details: ${e.details}');
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      print('❌ [Datasource] General exception: ${e.toString()}');
      throw GameServerException('Failed to create game: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getGames({
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      print('🔍 [DEBUG] getGames called with filters: $filters');
      
      // JOIN with venues table to get venue name
      var query = _supabaseClient
          .from('games')
          .select('*, venues!games_venue_id_fkey(name)');

      // Apply basic filters
      if (filters != null) {
        if (filters['start_date'] != null) {
          query = query.gte('scheduled_date', filters['start_date']);
        }
        if (filters['end_date'] != null) {
          query = query.lte('scheduled_date', filters['end_date']);
        }
        if (filters['sport'] != null) {
          query = query.eq('sport', filters['sport']);
        }
        if (filters['status'] != null) {
          query = query.eq('status', filters['status']);
        }
        if (filters['is_public'] != null) {
          query = query.eq('is_public', filters['is_public']);
        }
      }

      print('🔍 [DEBUG] Executing getGames query...');
      // Apply sorting and pagination
      final response = await query
          .order(sortBy ?? 'scheduled_date', ascending: ascending)
          .range((page - 1) * limit, page * limit - 1);
      
      print('🔍 [DEBUG] getGames response: ${response.length} games found');
      if (response.isNotEmpty) {
        print('🔍 [DEBUG] First public game: ${response.first}');
      }
      
      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      print('❌ [ERROR] getGames PostgrestException: ${e.message}');
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      print('❌ [ERROR] getGames failed: $e');
      throw GameServerException('Failed to get games: ${e.toString()}');
    }
  }

  @override
  Future<bool> joinGame(String gameId, String playerId) async {
    try {
      // Check if game exists and get current player count
      final gameResponse = await _supabaseClient
          .from('games')
          .select('*, game_players(count)')
          .eq('id', gameId)
          .single();

      final game = GameModel.fromJson(gameResponse);
      final currentPlayerCount = gameResponse['game_players'][0]['count'] as int;
      
      // Check if game is full
      if (currentPlayerCount >= game.maxPlayers) {
        throw GameFullException('Game is full');
      }

      // Check if game has already started
      final now = DateTime.now();
      final gameDateTime = DateTime.parse('${game.scheduledDate} ${game.startTime}');
      if (gameDateTime.isBefore(now)) {
        throw GameAlreadyStartedException('Cannot join a game that has already started');
      }

      // Add player to game
      await _supabaseClient.from('game_players').insert({
        'game_id': gameId,
        'player_id': playerId,
        'status': 'confirmed',
        'joined_at': DateTime.now().toIso8601String(),
      });

      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique violation - already joined
        throw GameServerException('Player is already in this game');
      }
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      if (e is GameFullException || e is GameAlreadyStartedException) {
        rethrow;
      }
      throw GameServerException('Failed to join game: ${e.toString()}');
    }
  }

  @override
  Future<bool> leaveGame(String gameId, String playerId) async {
    try {
      await _supabaseClient
          .from('game_players')
          .delete()
          .eq('game_id', gameId)
          .eq('player_id', playerId);

      return true;
    } on PostgrestException catch (e) {
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to leave game: ${e.toString()}');
    }
  }

  @override
  Future<GameModel> updateGame(String gameId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabaseClient
          .from('games')
          .update(updates)
          .eq('id', gameId)
          .select()
          .single();

      final updatedGame = GameModel.fromJson(response);
      _gameUpdatesController.add(updatedGame);

      return updatedGame;
    } on PostgrestException catch (e) {
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to update game: ${e.toString()}');
    }
  }

  @override
  Future<GameModel> getGame(String gameId) async {
    try {
      final response = await _supabaseClient
          .from('games')
          .select('*, venues!games_venue_id_fkey(name)')
          .eq('id', gameId)
          .single();

      return GameModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw GameNotFoundException('Game not found');
      }
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to get game: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getMyGames(
    String userId, {
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 [DEBUG] getMyGames called with userId: $userId, status: $status');
      
      // Get games where user is organizer, JOIN with venues
      var query = _supabaseClient
          .from('games')
          .select('*, venues!games_venue_id_fkey(name)')
          .eq('organizer_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      print('🔍 [DEBUG] Executing query...');
      final response = await query
          .order('scheduled_date', ascending: true)
          .range((page - 1) * limit, page * limit - 1);
      
      print('🔍 [DEBUG] Query response: ${response.length} games found');
      if (response.isNotEmpty) {
        print('🔍 [DEBUG] First game: ${response.first}');
      }
      
      final games = response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
      print('🔍 [DEBUG] Parsed ${games.length} games successfully');
      
      return games;
    } on PostgrestException catch (e) {
      print('❌ [ERROR] PostgrestException: ${e.message}, code: ${e.code}');
      throw GameServerException('Database error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ [ERROR] Failed to get user games: $e');
      print('Stack trace: $stackTrace');
      throw GameServerException('Failed to get user games: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> searchGames(
    String query, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var searchQuery = _supabaseClient
          .from('games')
          .select('*, venues!games_venue_id_fkey(name)')
          .textSearch('title', query);

      if (filters != null) {
        if (filters['sport'] != null) {
          searchQuery = searchQuery.eq('sport', filters['sport']);
        }
        if (filters['skill_level'] != null) {
          searchQuery = searchQuery.eq('skill_level', filters['skill_level']);
        }
      }

      final response = await searchQuery
          .order('scheduled_date', ascending: true)
          .range((page - 1) * limit, page * limit - 1);
      
      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to search games: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getNearbyGames(
    double latitude,
    double longitude,
    double radiusKm, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Use RPC function for location-based queries
      final response = await _supabaseClient.rpc('get_nearby_games', params: {
        'lat': latitude,
        'lng': longitude,
        'radius_km': radiusKm,
        'page_offset': (page - 1) * limit,
        'page_limit': limit,
      });

      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to get nearby games: ${e.toString()}');
    }
  }

  // Simplified implementations for remaining methods
  @override
  Future<bool> cancelGame(String gameId) async {
    try {
      await _supabaseClient
          .from('games')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String()
          })
          .eq('id', gameId);
      return true;
    } catch (e) {
      throw GameServerException('Failed to cancel game: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getGamesBySport(
    String sportType, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseClient
          .from('games')
          .select('*')
          .eq('sport', sportType)
          .eq('status', 'active')
          .order('scheduled_date')
          .range((page - 1) * limit, page * limit - 1);
      
      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } catch (e) {
      throw GameServerException('Failed to get games by sport: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getTrendingGames({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseClient
          .rpc('get_trending_games', params: {
            'page_offset': (page - 1) * limit,
            'page_limit': limit,
          });
      
      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } catch (e) {
      throw GameServerException('Failed to get trending games: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getRecommendedGames(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseClient
          .rpc('get_recommended_games', params: {
            'user_id': userId,
            'page_offset': (page - 1) * limit,
            'page_limit': limit,
          });
      
      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } catch (e) {
      throw GameServerException('Failed to get recommended games: ${e.toString()}');
    }
  }

  // Implement remaining abstract methods with basic functionality
  @override
  Future<bool> updateGameStatus(String gameId, String status) async {
    try {
      await updateGame(gameId, {'status': status});
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> invitePlayersToGame(String gameId, List<String> playerIds, String? message) async {
    try {
      await _supabaseClient.rpc('invite_players_to_game', params: {
        'game_id': gameId,
        'player_ids': playerIds,
        'invitation_message': message,
      });
      return true;
    } catch (e) {
      throw GameServerException('Failed to invite players: ${e.toString()}');
    }
  }

  @override
  Future<bool> respondToGameInvitation(String gameId, String playerId, bool accepted) async {
    try {
      if (accepted) {
        return await joinGame(gameId, playerId);
      } else {
        // Just decline the invitation - no need to join
        return true;
      }
    } catch (e) {
      throw GameServerException('Failed to respond to invitation: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserGameStats(String userId) async {
    try {
      final response = await _supabaseClient.rpc('get_user_game_stats', params: {
        'user_id': userId,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      throw GameServerException('Failed to get user stats: ${e.toString()}');
    }
  }

  @override
  Future<bool> reportGame(String gameId, String reason, String? description) async {
    try {
      await _supabaseClient.from('game_reports').insert({
        'game_id': gameId,
        'reason': reason,
        'description': description,
        'reported_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      throw GameServerException('Failed to report game: ${e.toString()}');
    }
  }

  @override
  Future<bool> toggleGameFavorite(String gameId, String userId) async {
    try {
      await _supabaseClient.rpc('toggle_game_favorite', params: {
        'game_id': gameId,
        'user_id': userId,
      });
      return true;
    } catch (e) {
      throw GameServerException('Failed to toggle favorite: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getFavoriteGames(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _supabaseClient
          .from('games')
          .select('*, game_favorites!inner(user_id)')
          .eq('game_favorites.user_id', userId)
          .order('scheduled_date')
          .range((page - 1) * limit, page * limit - 1);
      
      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } catch (e) {
      throw GameServerException('Failed to get favorite games: ${e.toString()}');
    }
  }

  @override
  Future<bool> canUserJoinGame(String gameId, String userId) async {
    try {
      final response = await _supabaseClient.rpc('can_user_join_game', params: {
        'game_id': gameId,
        'user_id': userId,
      });
      return response as bool;
    } catch (e) {
      return false; // Default to false if check fails
    }
  }

  @override
  Future<List<GameModel>> getGameHistory(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _supabaseClient
          .from('games')
          .select('*, game_players!inner(player_id)')
          .eq('game_players.player_id', userId)
          .inFilter('status', ['completed', 'cancelled'])
          .order('scheduled_date', ascending: false)
          .range((page - 1) * limit, page * limit - 1);
      
      return response.map<GameModel>((json) => GameModel.fromJson(json)).toList();
    } catch (e) {
      throw GameServerException('Failed to get game history: ${e.toString()}');
    }
  }

  @override
  Future<GameModel> duplicateGame(String gameId, String newDate, String newStartTime, String newEndTime) async {
    try {
      final response = await _supabaseClient.rpc('duplicate_game', params: {
        'original_game_id': gameId,
        'new_date': newDate,
        'new_start_time': newStartTime,
        'new_end_time': newEndTime,
      });

      return GameModel.fromJson(response);
    } catch (e) {
      throw GameServerException('Failed to duplicate game: ${e.toString()}');
    }
  }

  @override
  Future<List<PlayerModel>> getGamePlayers(String gameId) async {
    try {
      final response = await _supabaseClient
          .from('game_players')
          .select('*')
          .eq('game_id', gameId)
          .order('joined_at', ascending: true);
      
      return response.map<PlayerModel>((json) => PlayerModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to get game players: ${e.toString()}');
    }
  }

  void dispose() {
    _gamesSubscription?.cancel();
    _gameUpdatesController.close();
    _playerEventsController.close();
    _gameStatusController.close();
  }
}
