import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'games_remote_data_source.dart';
import 'package:dabbler/data/models/games/game_model.dart';
import 'package:dabbler/data/models/games/player_model.dart';

class SupabaseGamesDataSource implements GamesRemoteDataSource {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _gamesSubscription;

  // Real-time controllers
  final StreamController<GameModel> _gameUpdatesController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _playerEventsController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _gameStatusController =
      StreamController.broadcast();

  SupabaseGamesDataSource(this._supabaseClient) {
    _initializeRealTimeSubscriptions();
  }

  // Real-time streams
  Stream<GameModel> get gameUpdates => _gameUpdatesController.stream;
  Stream<Map<String, dynamic>> get playerEvents =>
      _playerEventsController.stream;
  Stream<Map<String, dynamic>> get gameStatusChanges =>
      _gameStatusController.stream;

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

  /// Helper method to get profile_id from user_id
  /// Returns the first active profile's id for the user
  Future<String> _getProfileId(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        throw GameServerException(
          'No active profile found for user. Please create a profile first.',
        );
      }

      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw GameServerException('Failed to get profile: ${e.message}');
    } catch (e) {
      if (e is GameServerException) rethrow;
      throw GameServerException('Failed to get profile: ${e.toString()}');
    }
  }

  /// Helper method to get current confirmed player count for a game
  Future<int> _getCurrentPlayerCount(String gameId) async {
    try {
      final response = await _supabaseClient
          .from('game_roster')
          // Table has no 'id' column; use profile_id just to count rows
          .select('profile_id')
          .eq('game_id', gameId)
          .eq('status', 'active'); // Database uses 'active' not 'confirmed'

      return response.length;
    } catch (e) {
      print('⚠️ [Datasource] _getCurrentPlayerCount: Error: $e');
      return 0;
    }
  }

  /// Helper method to check if player is already in game
  Future<bool> _isPlayerInGame(String gameId, String userId) async {
    try {
      final response = await _supabaseClient
          .from('game_roster')
          // Table has no 'id' column; use game_id just to check existence
          .select('game_id')
          .eq('game_id', gameId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('⚠️ [Datasource] _isPlayerInGame: Error: $e');
      return false;
    }
  }

  /// Helper method to get parent venue_id from venue_space_id
  /// Returns null if venue_space_id is null or space not found
  Future<String?> _getVenueIdFromSpaceId(String? venueSpaceId) async {
    if (venueSpaceId == null) return null;
    
    try {
      final response = await _supabaseClient
          .from('venue_spaces')
          .select('venue_id')
          .eq('id', venueSpaceId)
          .maybeSingle();
      
      if (response == null) return null;
      return response['venue_id'] as String?;
    } catch (e) {
      print('⚠️ [Datasource] _getVenueIdFromSpaceId: Error: $e');
      return null;
    }
  }

  /// Helper method to get waitlist position for a player
  /// Note: Database doesn't have 'waitlisted' status, so we determine waitlist
  /// by checking if player joined after maxPlayers was reached
  Future<int?> _getWaitlistPosition(String gameId, String userId) async {
    try {
      // Get game details to check maxPlayers (capacity in DB)
      final gameResponse = await _supabaseClient
          .from('games')
          .select('capacity')
          .eq('id', gameId)
          .single();
      
      final maxPlayers = gameResponse['capacity'] as int;
      
      // Get the player's joined_at timestamp
      final playerResponse = await _supabaseClient
          .from('game_roster')
          .select('joined_at')
          .eq('game_id', gameId)
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (playerResponse == null) {
        return null; // Not in game
      }

      final playerJoinedAt = playerResponse['joined_at'] as String;

      // Count active players who joined before this player
      final playersBefore = await _supabaseClient
          .from('game_roster')
          // Table has no 'id' column; use profile_id just to count rows
          .select('profile_id')
          .eq('game_id', gameId)
          .eq('status', 'active')
          .lt('joined_at', playerJoinedAt);

      final position = playersBefore.length + 1;
      
      // If position is greater than maxPlayers, they're on waitlist
      if (position > maxPlayers) {
        return position - maxPlayers; // Waitlist position (1-indexed)
      }
      
      return null; // Not on waitlist, they're a confirmed player
    } catch (e) {
      print('⚠️ [Datasource] _getWaitlistPosition: Error: $e');
      return null;
    }
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
      await _supabaseClient.from('game_roster').insert({
        'game_id': gameResponse['id'],
        'profile_id': gameData['host_profile_id'],
        'user_id': gameData['host_user_id'],
        'role': 'host',
        'status': 'active', // Database uses 'active' not 'confirmed'
        'joined_at': DateTime.now().toIso8601String(),
      });

      print('✅ [Datasource] Organizer added to game_roster');

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

      // MVP: Simplified query without venue join to avoid relationship errors
      // TODO: Re-enable venue join once database relationship is fixed
      var query = _supabaseClient.from('games').select('*');

      // Apply basic filters
      if (filters != null) {
        if (filters['start_date'] != null) {
          query = query.gte('start_at', filters['start_date']);
        }
        if (filters['end_date'] != null) {
          query = query.lte('start_at', filters['end_date']);
        }
        if (filters['sport'] != null) {
          query = query.eq('sport', filters['sport']);
        }
        // MVP Fix: Database uses 'is_cancelled' not 'status'
        if (filters['status'] != null) {
          // Map status to is_cancelled (status=='upcoming' means not cancelled)
          if (filters['status'] == 'upcoming' ||
              filters['status'] == 'active') {
            query = query.eq('is_cancelled', false);
          } else if (filters['status'] == 'cancelled') {
            query = query.eq('is_cancelled', true);
          }
        }
        // Database uses 'listing_visibility' not 'is_public'
        if (filters['is_public'] != null) {
          if (filters['is_public'] == true) {
            query = query.eq('listing_visibility', 'public');
          } else {
            query = query.neq('listing_visibility', 'public');
          }
        }
      }

      print('🔍 [DEBUG] Executing getGames query...');
      // Apply sorting and pagination
      // MVP Fix: Use 'start_at' instead of 'scheduled_date'
      final response = await query
          .order(sortBy ?? 'start_at', ascending: ascending)
          .range((page - 1) * limit, page * limit - 1);

      print('🔍 [DEBUG] getGames response: ${response.length} games found');
      if (response.isNotEmpty) {
        print('🔍 [DEBUG] First public game: ${response.first}');
      }

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
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
    String? joinPolicy; // Store for error handling
    try {
      print('🔄 [Datasource] joinGame: gameId=$gameId, playerId=$playerId');

      // IDEMPOTENT CHECK: First check if player is already in the game
      final isAlreadyInGame = await _isPlayerInGame(gameId, playerId);
      if (isAlreadyInGame) {
        print(
          '✅ [Datasource] joinGame: Player already in game (idempotent success)',
        );
        return true; // Already joined - idempotent success
      }

      // Get game details
      final gameResponse = await _supabaseClient
          .from('games')
          .select('*')
          .eq('id', gameId)
          .single();

      final game = GameModel.fromJson(gameResponse);
      joinPolicy = gameResponse['join_policy'] as String?;
      
      // Handle different join policies
      if (joinPolicy != null && joinPolicy == 'request') {
        // For "request" policy, create a join request instead of directly joining
        print('🔄 [Datasource] joinGame: Game requires request policy, creating join request');
        final requestId = await requestToJoinGame(gameId, playerId);
        print('✅ [Datasource] joinGame: Join request created with ID: $requestId');
        return true; // Return success - request was created
      } else if (joinPolicy != null && joinPolicy != 'open') {
        throw GameServerException(
          'This game requires "$joinPolicy" join policy. Please use the appropriate method to join.',
        );
      }

      // Get accurate current player count (only confirmed players)
      final currentPlayerCount = await _getCurrentPlayerCount(gameId);

      // Check if game has already started
      final now = DateTime.now();
      // Use model helper to avoid string parsing/timezone issues
      final gameDateTime = game.getScheduledStartDateTime();
      if (gameDateTime.isBefore(now)) {
        print('❌ [Datasource] joinGame: Game already started');
        throw GameAlreadyStartedException(
          'Cannot join a game that has already started',
        );
      }

      // Get profile_id from user_id
      final profileId = await _getProfileId(playerId);

      // Determine player status based on game capacity
      // Note: Database constraint only allows 'active', 'left', 'kicked'
      // All players are added with 'active' status, waitlist is determined by position
      final String playerStatus = 'active'; // Database uses 'active' not 'confirmed'
      
      if (currentPlayerCount >= game.maxPlayers) {
        if (!game.allowsWaitlist) {
          print(
            '❌ [Datasource] joinGame: Game is full and waitlist not allowed',
          );
          throw GameFullException('Game is full');
        }
        // Game is full but allows waitlist - player will be added as 'active'
        // but their position will determine if they're waitlisted
        print('⚠️ [Datasource] joinGame: Game is full, adding as active (will be waitlisted by position)');
      }

      // Add player to game
      await _supabaseClient.from('game_roster').insert({
        'game_id': gameId,
        'profile_id': profileId,
        'user_id': playerId,
        'role': 'player',
        'status': playerStatus,
        'joined_at': DateTime.now().toIso8601String(),
      });

      print(
        '✅ [Datasource] joinGame: Successfully joined game with status: $playerStatus',
      );
      return true;
    } on PostgrestException catch (e) {
      print(
        '❌ [Datasource] joinGame: PostgrestException code=${e.code}, message=${e.message}',
      );
      if (e.code == '23505') {
        // Unique violation - race condition, player got added between check and insert
        // This is still a success (idempotent)
        print(
          '✅ [Datasource] joinGame: Unique violation (race condition), treating as success',
        );
        return true;
      }
      if (e.code == '23503') {
        // Foreign key violation - profile_id doesn't exist
        throw GameServerException(
          'Profile not found. Please ensure your profile is active.',
        );
      }
      // Handle RLS policy violations (permission denied)
      if (e.message.contains('permission denied') || 
          e.message.contains('new row violates row-level security policy')) {
        // Check join_policy - if not 'open', user needs to use different method
        if (joinPolicy != null && joinPolicy != 'open') {
          throw GameServerException(
            'This game requires "$joinPolicy" join policy. Please use the appropriate method to join.',
          );
        }
        throw GameServerException(
          'Unable to join game. Please ensure the game is public and you meet all requirements.',
        );
      }
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      if (e is GameFullException || e is GameAlreadyStartedException) {
        rethrow;
      }
      if (e is GameServerException) {
        rethrow;
      }
      print('❌ [Datasource] joinGame: Unexpected error: $e');
      throw GameServerException('Failed to join game: ${e.toString()}');
    }
  }

  @override
  Future<bool> leaveGame(String gameId, String playerId) async {
    try {
      print('🔄 [Datasource] leaveGame: gameId=$gameId, playerId=$playerId');

      // IDEMPOTENT CHECK: First check if player is in the game
      final existingPlayerResponse = await _supabaseClient
          .from('game_roster')
          .select('game_id')
          .eq('game_id', gameId)
          .eq('user_id', playerId)
          .maybeSingle();

      if (existingPlayerResponse == null) {
        print(
          '✅ [Datasource] leaveGame: Player not in game (idempotent success)',
        );
        return true; // Not in game - idempotent success
      }

      // Remove player from game
      await _supabaseClient
          .from('game_roster')
          .delete()
          .eq('game_id', gameId)
          .eq('user_id', playerId);

      print('✅ [Datasource] leaveGame: Successfully left game');
      return true;
    } on PostgrestException catch (e) {
      print(
        '❌ [Datasource] leaveGame: PostgrestException code=${e.code}, message=${e.message}',
      );
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      print('❌ [Datasource] leaveGame: Unexpected error: $e');
      throw GameServerException('Failed to leave game: ${e.toString()}');
    }
  }

  @override
  Future<GameModel> updateGame(
    String gameId,
    Map<String, dynamic> updates,
  ) async {
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
      // Get game data with player count
      final response = await _supabaseClient
          .from('games')
          .select('*')
          .eq('id', gameId)
          .single();

      // Get current player count (only confirmed players)
      final currentPlayerCount = await _getCurrentPlayerCount(gameId);

      // Resolve venue_space_id to parent venue_id
      final venueSpaceId = response['venue_space_id'] as String?;
      final venueId = await _getVenueIdFromSpaceId(venueSpaceId);

      // Add currentPlayers and venue_id to response for GameModel parsing
      final responseWithCount = Map<String, dynamic>.from(response);
      responseWithCount['current_players'] = currentPlayerCount;
      if (venueId != null) {
        responseWithCount['venue_id'] = venueId;
      }

      return GameModel.fromJson(responseWithCount);
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
      print(
        '🔍 [DEBUG] getMyGames called with userId: $userId, status: $status',
      );

      // Get game IDs where user is either host OR joined as player
      // First, get games where user is host
      final hostedGamesQuery = _supabaseClient
          .from('games')
          .select('id')
          .eq('host_user_id', userId);

      // Also get games where user is in game_roster
      final joinedGamesResponse = await _supabaseClient
          .from('game_roster')
          .select('game_id')
          .eq('user_id', userId)
          .eq('status', 'active');

      final joinedGameIds = (joinedGamesResponse as List)
          .map((r) => r['game_id'] as String)
          .toSet();

      // Get hosted game IDs
      final hostedGamesResponse = await hostedGamesQuery;
      final hostedGameIds = (hostedGamesResponse as List)
          .map((r) => r['id'] as String)
          .toSet();

      // Combine both sets
      final allGameIds = {...hostedGameIds, ...joinedGameIds};

      if (allGameIds.isEmpty) {
        print('🔍 [DEBUG] No games found for user');
        return [];
      }

      // Query games by IDs
      var query = _supabaseClient
          .from('games')
          .select('*')
          .inFilter('id', allGameIds.toList());

      // MVP Fix: Map status to is_cancelled and filter by date
      if (status != null) {
        if (status == 'upcoming' || status == 'active') {
          query = query
              .eq('is_cancelled', false)
              .gte('start_at', DateTime.now().toUtc().toIso8601String());
        } else if (status == 'completed' || status == 'past') {
          query = query
              .eq('is_cancelled', false)
              .lt('start_at', DateTime.now().toUtc().toIso8601String());
        } else if (status == 'cancelled') {
          query = query.eq('is_cancelled', true);
        }
      }

      print('🔍 [DEBUG] Executing query for ${allGameIds.length} game IDs...');
      // Use 'start_at' instead of legacy scheduled_date
      final response = await query
          .order('start_at', ascending: true)
          .range((page - 1) * limit, page * limit - 1);

      print('🔍 [DEBUG] Query response: ${response.length} games found');
      if (response.isNotEmpty) {
        print('🔍 [DEBUG] First game: ${response.first}');
      }

      // For each game, compute current active player count from game_roster
      // and inject it as current_players so GameModel can map correctly.
      final List<GameModel> games = [];
      for (final json in response) {
        final gameId = json['id'] as String?;
        if (gameId == null) {
          continue;
        }

        final currentPlayerCount = await _getCurrentPlayerCount(gameId);
        final jsonWithCount = Map<String, dynamic>.from(json);
        jsonWithCount['current_players'] = currentPlayerCount;
        games.add(GameModel.fromJson(jsonWithCount));
      }

      print('🔍 [DEBUG] Parsed ${games.length} games successfully (with player counts)');

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
      // MVP: Simplified query without venue join
      var searchQuery = _supabaseClient
          .from('games')
          .select('*')
          .textSearch('title', query);

      if (filters != null) {
        if (filters['sport'] != null) {
          searchQuery = searchQuery.eq('sport', filters['sport']);
        }
        if (filters['skill_level'] != null) {
          searchQuery = searchQuery.eq('skill_level', filters['skill_level']);
        }
      }

      // MVP Fix: Use 'start_at' instead of 'scheduled_date'
      final response = await searchQuery
          .order('start_at', ascending: true)
          .range((page - 1) * limit, page * limit - 1);

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
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
      final response = await _supabaseClient.rpc(
        'get_nearby_games',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
          'page_offset': (page - 1) * limit,
          'page_limit': limit,
        },
      );

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
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
            'cancelled_at': DateTime.now().toIso8601String(),
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
          .eq('is_cancelled', false) // Changed from status to is_cancelled
          .order('start_at') // Changed from scheduled_date to start_at
          .range((page - 1) * limit, page * limit - 1);

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
    } catch (e) {
      throw GameServerException(
        'Failed to get games by sport: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<GameModel>> getTrendingGames({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseClient.rpc(
        'get_trending_games',
        params: {'page_offset': (page - 1) * limit, 'page_limit': limit},
      );

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
    } catch (e) {
      throw GameServerException(
        'Failed to get trending games: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<GameModel>> getRecommendedGames(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseClient.rpc(
        'get_recommended_games',
        params: {
          'user_id': userId,
          'page_offset': (page - 1) * limit,
          'page_limit': limit,
        },
      );

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
    } catch (e) {
      throw GameServerException(
        'Failed to get recommended games: ${e.toString()}',
      );
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
  Future<bool> invitePlayersToGame(
    String gameId,
    List<String> playerIds,
    String? message,
  ) async {
    try {
      await _supabaseClient.rpc(
        'invite_players_to_game',
        params: {
          'game_id': gameId,
          'player_ids': playerIds,
          'invitation_message': message,
        },
      );
      return true;
    } catch (e) {
      throw GameServerException('Failed to invite players: ${e.toString()}');
    }
  }

  @override
  Future<bool> respondToGameInvitation(
    String gameId,
    String playerId,
    bool accepted,
  ) async {
    try {
      if (accepted) {
        return await joinGame(gameId, playerId);
      } else {
        // Just decline the invitation - no need to join
        return true;
      }
    } catch (e) {
      throw GameServerException(
        'Failed to respond to invitation: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getUserGameStats(String userId) async {
    try {
      final response = await _supabaseClient.rpc(
        'get_user_game_stats',
        params: {'user_id': userId},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw GameServerException('Failed to get user stats: ${e.toString()}');
    }
  }

  @override
  Future<bool> reportGame(
    String gameId,
    String reason,
    String? description,
  ) async {
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
      await _supabaseClient.rpc(
        'toggle_game_favorite',
        params: {'game_id': gameId, 'user_id': userId},
      );
      return true;
    } catch (e) {
      throw GameServerException('Failed to toggle favorite: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> getFavoriteGames(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseClient
          .from('games')
          .select('*, game_favorites!inner(user_id)')
          .eq('game_favorites.user_id', userId)
          .order('start_at') // Changed from scheduled_date to start_at
          .range((page - 1) * limit, page * limit - 1);

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
    } catch (e) {
      throw GameServerException(
        'Failed to get favorite games: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> canUserJoinGame(String gameId, String userId) async {
    try {
      final response = await _supabaseClient.rpc(
        'can_user_join_game',
        params: {'game_id': gameId, 'user_id': userId},
      );
      return response as bool;
    } catch (e) {
      return false; // Default to false if check fails
    }
  }

  @override
  Future<List<GameModel>> getGameHistory(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseClient
          .from('games')
          .select('*, game_roster!inner(user_id)')
          .eq('game_roster.user_id', userId)
          .eq(
            'is_cancelled',
            true,
          ) // Changed from status filter to is_cancelled
          .order(
            'start_at',
            ascending: false,
          ) // Changed from scheduled_date to start_at
          .range((page - 1) * limit, page * limit - 1);

      return response
          .map<GameModel>((json) => GameModel.fromJson(json))
          .toList();
    } catch (e) {
      throw GameServerException('Failed to get game history: ${e.toString()}');
    }
  }

  @override
  Future<GameModel> duplicateGame(
    String gameId,
    String newDate,
    String newStartTime,
    String newEndTime,
  ) async {
    try {
      final response = await _supabaseClient.rpc(
        'duplicate_game',
        params: {
          'original_game_id': gameId,
          'new_date': newDate,
          'new_start_time': newStartTime,
          'new_end_time': newEndTime,
        },
      );

      return GameModel.fromJson(response);
    } catch (e) {
      throw GameServerException('Failed to duplicate game: ${e.toString()}');
    }
  }

  @override
  Future<List<PlayerModel>> getGamePlayers(String gameId) async {
    try {
      // First get game capacity to determine waitlist
      final gameResponse = await _supabaseClient
          .from('games')
          .select('capacity')
          .eq('id', gameId)
          .maybeSingle();

      final capacity = gameResponse?['capacity'] as int? ?? 0;

      // Get roster with profile data joined
      final response = await _supabaseClient
          .from('game_roster')
          .select('''
            *,
            profile:profiles(
              id,
              user_id,
              display_name,
              avatar_url
            )
          ''')
          .eq('game_id', gameId)
          .eq('status', 'active')
          .order('joined_at', ascending: true);

      // Process players and determine waitlist status
      final List<PlayerModel> players = [];
      for (int i = 0; i < response.length; i++) {
        final rosterData = Map<String, dynamic>.from(response[i]);
        final profileData = rosterData['profile'] as Map<String, dynamic>?;

        // Determine if player is waitlisted based on position
        final isWaitlisted = i >= capacity;
        final playerStatus = isWaitlisted
            ? 'waitlisted'
            : 'confirmed';

        // Handle profile data - it might be a list or single object
        Map<String, dynamic>? profile;
        if (profileData != null) {
          if (profileData is List && profileData.isNotEmpty) {
            profile = Map<String, dynamic>.from(profileData[0]);
          } else {
            profile = Map<String, dynamic>.from(profileData);
          }
        }

        // Build player data with profile info
        final playerData = {
          'id': rosterData['profile_id'] as String,
          'player_id': rosterData['user_id'] as String,
          'game_id': gameId,
          'status': playerStatus,
          'team_assignment': 'unassigned',
          'position': null,
          'player_name': profile?['display_name'] as String? ?? 'Unknown Player',
          'player_avatar': profile?['avatar_url'] as String?,
          'player_phone': null,
          'player_email': null,
          'joined_at': (rosterData['joined_at'] as String),
          'checked_in_at': null,
          'cancelled_at': rosterData['left_at'] != null
              ? (rosterData['left_at'] as String)
              : null,
          'check_in_code': null,
          'is_organizer': (rosterData['role'] as String?) == 'host',
          'player_rating': null,
          'rated_at': null,
          'rating_comment': null,
          'has_paid': false,
          'amount_paid': null,
          'paid_at': null,
          'created_at': (rosterData['joined_at'] as String),
          'updated_at': (rosterData['joined_at'] as String),
        };

        players.add(PlayerModel.fromJson(playerData));
      }

      return players;
    } on PostgrestException catch (e) {
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to get game players: ${e.toString()}');
    }
  }

  @override
  Future<void> submitGameRating(
    String gameId,
    int rating, {
    String? note,
  }) async {
    // TODO: implement supabase.from('game_ratings').upsert(...) when backend table exists
    // Stubbed for now to succeed without throwing
    print(
      '⭐ [Datasource] submitGameRating: gameId=$gameId, rating=$rating, note=$note (STUB)',
    );
    // Simulate brief delay
    await Future.delayed(const Duration(milliseconds: 100));
    // Success - no throw
  }

  @override
  Future<double> fetchMyAverageRating() async {
    // TODO: implement supabase RPC or select avg(rating) when backend exists
    // Stubbed for now to return 0.0
    print('⭐ [Datasource] fetchMyAverageRating: returning 0.0 (STUB)');
    return 0.0;
  }

  @override
  Future<bool> isPlayerInGame(String gameId, String userId) async {
    return await _isPlayerInGame(gameId, userId);
  }

  @override
  Future<int?> getWaitlistPosition(String gameId, String userId) async {
    return await _getWaitlistPosition(gameId, userId);
  }

  @override
  Future<String> requestToJoinGame(String gameId, String playerId, {String? message}) async {
    try {
      print('🔄 [Datasource] requestToJoinGame: gameId=$gameId, playerId=$playerId');

      // Get profile_id from user_id
      final profileId = await _getProfileId(playerId);

      // Check if request already exists
      final existingRequest = await _supabaseClient
          .from('game_join_requests')
          .select('id, status')
          .eq('game_id', gameId)
          .eq('from_user_id', playerId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        print('⚠️ [Datasource] requestToJoinGame: Pending request already exists');
        return existingRequest['id'] as String;
      }

      // Create new join request
      final response = await _supabaseClient
          .from('game_join_requests')
          .insert({
            'game_id': gameId,
            'from_profile_id': profileId,
            'from_user_id': playerId,
            'status': 'pending',
          })
          .select('id')
          .single();

      final requestId = response['id'] as String;
      print('✅ [Datasource] requestToJoinGame: Join request created with ID: $requestId');
      return requestId;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique violation - request already exists (race condition)
        print('✅ [Datasource] requestToJoinGame: Request already exists (race condition)');
        final existingRequest = await _supabaseClient
            .from('game_join_requests')
            .select('id')
            .eq('game_id', gameId)
            .eq('from_user_id', playerId)
            .eq('status', 'pending')
            .maybeSingle();
        if (existingRequest != null) {
          return existingRequest['id'] as String;
        }
      }
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      throw GameServerException('Failed to create join request: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasPendingJoinRequest(String gameId, String userId) async {
    try {
      final response = await _supabaseClient
          .from('game_join_requests')
          .select('id')
          .eq('game_id', gameId)
          .eq('from_user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('⚠️ [Datasource] hasPendingJoinRequest: Error: $e');
      return false;
    }
  }

  @override
  Future<bool> cancelJoinRequest(String gameId, String userId) async {
    try {
      print('🔄 [Datasource] cancelJoinRequest: gameId=$gameId, userId=$userId');

      // First check if a pending request exists
      final existingRequest = await _supabaseClient
          .from('game_join_requests')
          .select('id, status')
          .eq('game_id', gameId)
          .eq('from_user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest == null) {
        print('⚠️ [Datasource] cancelJoinRequest: No pending request found (might have been processed already)');
        return false; // No request to cancel - idempotent success
      }

      // Update the request status to 'cancelled' instead of deleting
      // RLS policy allows requester to update their own request to 'cancelled'
      final response = await _supabaseClient
          .from('game_join_requests')
          .update({
            'status': 'cancelled',
            'decided_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('from_user_id', userId)
          .eq('status', 'pending')
          .select();

      // Check if any rows were updated
      final updated = (response as List).isNotEmpty;
      
      if (updated) {
        print('✅ [Datasource] cancelJoinRequest: Successfully cancelled join request');
      } else {
        print('⚠️ [Datasource] cancelJoinRequest: Request was not updated (might have been processed already)');
      }

      return updated;
    } on PostgrestException catch (e) {
      print('❌ [Datasource] cancelJoinRequest: PostgrestException: ${e.message}, code: ${e.code}');
      throw GameServerException('Database error: ${e.message}');
    } catch (e) {
      print('❌ [Datasource] cancelJoinRequest: Error: $e');
      throw GameServerException('Failed to cancel join request: ${e.toString()}');
    }
  }

  void dispose() {
    _gamesSubscription?.cancel();
    _gameUpdatesController.close();
    _playerEventsController.close();
    _gameStatusController.close();
  }
}
