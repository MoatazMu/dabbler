import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/leaderboard.dart';
import '../models/leaderboard_model.dart';
import 'achievements_local_datasource.dart';

/// Leaderboard data source handling leaderboard operations
/// Combines both remote (Supabase) and local (SQLite) data access
/// with real-time subscriptions, caching, and offline support
class LeaderboardDataSource {
  final SupabaseClient _supabase;
  final AchievementsLocalDataSource _localDataSource;
  
  // Real-time subscription controllers
  final Map<String, RealtimeChannel> _subscriptions = {};
  final Map<String, StreamController<List<LeaderboardEntry>>> _leaderboardControllers = {};
  final Map<String, StreamController<UserRank>> _rankControllers = {};
  
  // Cache configuration
  static const Duration _cacheExpiration = Duration(minutes: 15);
  static const int _maxCachePages = 5;
  
  // Local database tables
  static const String _leaderboardTable = 'leaderboard_cache';
  static const String _userRanksTable = 'user_ranks_cache';
  static const String _leaderboardMetaTable = 'leaderboard_metadata';
  
  LeaderboardDataSource({
    required SupabaseClient supabase,
    required AchievementsLocalDataSource localDataSource,
  }) : _supabase = supabase, _localDataSource = localDataSource;

  // =============================================================================
  // LEADERBOARD OPERATIONS
  // =============================================================================

  /// Get leaderboard with pagination and filtering
  Future<LeaderboardModel> getLeaderboard({
    LeaderboardType type = LeaderboardType.global,
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
    String? categoryFilter,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(type, period, categoryFilter, page, limit);
    
    // Try cache first unless force refresh
    if (!forceRefresh) {
      final cached = await _getCachedLeaderboard(cacheKey);
      if (cached != null) return cached;
    }

    try {
      // Build query parameters
      final params = {
        'leaderboard_type': type.name,
        'period': period.name,
        if (categoryFilter != null) 'category': categoryFilter,
        'page': page,
        'limit': limit,
      };

      // Call Supabase RPC function
      final response = await _supabase.rpc('get_leaderboard', params: params);
      
      final data = response as Map<String, dynamic>;
      final leaderboard = LeaderboardModel.fromJson(data);
      
      // Cache the result
      await _cacheLeaderboard(cacheKey, leaderboard);
      
      return leaderboard;
      
    } catch (error) {
      // Fallback to cache on error
      final cached = await _getCachedLeaderboard(cacheKey);
      if (cached != null) return cached;
      
      rethrow;
    }
  }

  /// Get user's rank across different leaderboards
  Future<Map<String, UserRank>> getUserRanks(
    String userId, {
    List<LeaderboardType>? types,
    List<LeaderboardPeriod>? periods,
    bool forceRefresh = false,
  }) async {
    final targetTypes = types ?? LeaderboardType.values;
    final targetPeriods = periods ?? [LeaderboardPeriod.allTime, LeaderboardPeriod.monthly];
    
    final ranks = <String, UserRank>{};
    
    for (final type in targetTypes) {
      for (final period in targetPeriods) {
        final rankKey = '${type.name}_${period.name}';
        
        try {
          final rank = await _getUserRankForLeaderboard(
            userId, 
            type, 
            period, 
            forceRefresh: forceRefresh
          );
          
          if (rank != null) {
            ranks[rankKey] = rank;
          }
        } catch (error) {
          // Continue with other ranks on individual failures
          continue;
        }
      }
    }
    
    return ranks;
  }

  /// Get user's specific rank for a leaderboard
  Future<UserRank?> _getUserRankForLeaderboard(
    String userId,
    LeaderboardType type,
    LeaderboardPeriod period, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'rank_${userId}_${type.name}_${period.name}';
    
    // Try cache first
    if (!forceRefresh) {
      final cached = await _getCachedUserRank(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final response = await _supabase.rpc('get_user_rank', params: {
        'target_user_id': userId,
        'leaderboard_type': type.name,
        'period': period.name,
      });
      
      if (response == null) return null;
      
      final rank = UserRank.fromJson(response as Map<String, dynamic>);
      
      // Cache the result
      await _cacheUserRank(cacheKey, rank);
      
      return rank;
      
    } catch (error) {
      // Fallback to cache
      final cached = await _getCachedUserRank(cacheKey);
      if (cached != null) return cached;
      
      return null;
    }
  }

  /// Get leaderboard statistics
  Future<LeaderboardStats> getLeaderboardStats(
    LeaderboardType type,
    LeaderboardPeriod period,
  ) async {
    try {
      final response = await _supabase.rpc('get_leaderboard_stats', params: {
        'leaderboard_type': type.name,
        'period': period.name,
      });
      
      return LeaderboardStats.fromJson(response as Map<String, dynamic>);
      
    } catch (error) {
      // Return default stats on error
      return LeaderboardStats(
        totalParticipants: 0,
        averageScore: 0.0,
        topScore: 0.0,
        lastUpdated: DateTime.now(),
        type: type,
        period: period,
      );
    }
  }

  /// Get user's historical rankings
  Future<List<UserRankHistory>> getUserRankHistory(
    String userId, {
    LeaderboardType? type,
    int limit = 50,
  }) async {
    try {
      final query = _supabase
          .from('user_rank_history')
          .select()
          .eq('user_id', userId);
      
      final response = await (type != null 
          ? query.eq('leaderboard_type', type.name)
          : query)
          .order('recorded_at', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((item) => UserRankHistory.fromJson(item as Map<String, dynamic>))
          .toList();
          
    } catch (error) {
      return [];
    }
  }

  // =============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // =============================================================================

  /// Subscribe to leaderboard updates
  Stream<List<LeaderboardEntry>> subscribeToLeaderboard({
    LeaderboardType type = LeaderboardType.global,
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
    String? categoryFilter,
    int limit = 20,
  }) {
    final subscriptionKey = 'leaderboard_${type.name}_${period.name}_$categoryFilter';
    
    // Return existing stream if already subscribed
    if (_leaderboardControllers.containsKey(subscriptionKey)) {
      return _leaderboardControllers[subscriptionKey]!.stream;
    }
    
    // Create new stream controller
    final controller = StreamController<List<LeaderboardEntry>>();
    _leaderboardControllers[subscriptionKey] = controller;
    
    // Set up Supabase real-time subscription
    final subscription = _supabase
        .channel('leaderboard_$subscriptionKey')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_points',
          callback: (payload) => _handleLeaderboardUpdate(
            subscriptionKey,
            type,
            period,
            categoryFilter,
            limit,
          ),
        )
        .subscribe();
    
    _subscriptions[subscriptionKey] = subscription;
    
    // Emit initial data
    _emitInitialLeaderboardData(subscriptionKey, type, period, categoryFilter, limit);
    
    // Handle controller close
    controller.onCancel = () {
      _cleanupLeaderboardSubscription(subscriptionKey);
    };
    
    return controller.stream;
  }

  /// Subscribe to user rank updates
  Stream<UserRank> subscribeToUserRank(
    String userId, {
    LeaderboardType type = LeaderboardType.global,
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
  }) {
    final subscriptionKey = 'rank_${userId}_${type.name}_${period.name}';
    
    // Return existing stream if already subscribed
    if (_rankControllers.containsKey(subscriptionKey)) {
      return _rankControllers[subscriptionKey]!.stream;
    }
    
    // Create new stream controller
    final controller = StreamController<UserRank>();
    _rankControllers[subscriptionKey] = controller;
    
    // Set up Supabase real-time subscription
    final subscription = _supabase
        .channel('rank_$subscriptionKey')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_points',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleUserRankUpdate(subscriptionKey, userId, type, period),
        )
        .subscribe();
    
    _subscriptions[subscriptionKey] = subscription;
    
    // Emit initial data
    _emitInitialUserRankData(subscriptionKey, userId, type, period);
    
    // Handle controller close
    controller.onCancel = () {
      _cleanupRankSubscription(subscriptionKey);
    };
    
    return controller.stream;
  }

  /// Handle leaderboard update from real-time subscription
  Future<void> _handleLeaderboardUpdate(
    String subscriptionKey,
    LeaderboardType type,
    LeaderboardPeriod period,
    String? categoryFilter,
    int limit,
  ) async {
    try {
      final leaderboard = await getLeaderboard(
        type: type,
        period: period,
        categoryFilter: categoryFilter,
        limit: limit,
        forceRefresh: true,
      );
      
      final controller = _leaderboardControllers[subscriptionKey];
      if (controller != null && !controller.isClosed) {
        controller.add(leaderboard.entries.map((model) => LeaderboardEntry(
          userId: model.userId,
          displayName: model.displayName,
          avatarUrl: model.avatarUrl,
          rank: model.rank,
          previousRank: model.previousRank,
          score: model.score,
          previousScore: model.previousScore,
          stats: model.stats,
          lastUpdated: model.lastUpdated,
          isCurrentUser: model.isCurrentUser,
          badges: model.badges,
        )).toList());
      }
    } catch (error) {
      // Handle error silently to avoid breaking stream
    }
  }

  /// Handle user rank update from real-time subscription
  Future<void> _handleUserRankUpdate(
    String subscriptionKey,
    String userId,
    LeaderboardType type,
    LeaderboardPeriod period,
  ) async {
    try {
      final rank = await _getUserRankForLeaderboard(
        userId,
        type,
        period,
        forceRefresh: true,
      );
      
      if (rank != null) {
        final controller = _rankControllers[subscriptionKey];
        if (controller != null && !controller.isClosed) {
          controller.add(rank);
        }
      }
    } catch (error) {
      // Handle error silently
    }
  }

  /// Emit initial leaderboard data
  Future<void> _emitInitialLeaderboardData(
    String subscriptionKey,
    LeaderboardType type,
    LeaderboardPeriod period,
    String? categoryFilter,
    int limit,
  ) async {
    try {
      final leaderboard = await getLeaderboard(
        type: type,
        period: period,
        categoryFilter: categoryFilter,
        limit: limit,
      );
      
      final controller = _leaderboardControllers[subscriptionKey];
      if (controller != null && !controller.isClosed) {
        controller.add(leaderboard.entries.map((model) => LeaderboardEntry(
          userId: model.userId,
          displayName: model.displayName,
          avatarUrl: model.avatarUrl,
          rank: model.rank,
          previousRank: model.previousRank,
          score: model.score,
          previousScore: model.previousScore,
          stats: model.stats,
          lastUpdated: model.lastUpdated,
          isCurrentUser: model.isCurrentUser,
          badges: model.badges,
        )).toList());
      }
    } catch (error) {
      // Emit empty list on error
      final controller = _leaderboardControllers[subscriptionKey];
      if (controller != null && !controller.isClosed) {
        controller.add([]);
      }
    }
  }

  /// Emit initial user rank data
  Future<void> _emitInitialUserRankData(
    String subscriptionKey,
    String userId,
    LeaderboardType type,
    LeaderboardPeriod period,
  ) async {
    try {
      final rank = await _getUserRankForLeaderboard(userId, type, period);
      
      if (rank != null) {
        final controller = _rankControllers[subscriptionKey];
        if (controller != null && !controller.isClosed) {
          controller.add(rank);
        }
      }
    } catch (error) {
      // Handle error silently
    }
  }

  // =============================================================================
  // CACHE OPERATIONS
  // =============================================================================

  /// Get cached leaderboard data
  Future<LeaderboardModel?> _getCachedLeaderboard(String cacheKey) async {
    try {
      final db = await _localDataSource.database;
      
      final result = await db.query(
        _leaderboardTable,
        where: 'cache_key = ? AND expires_at > ?',
        whereArgs: [cacheKey, DateTime.now().toIso8601String()],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      final cached = result.first;
      final leaderboardData = jsonDecode(cached['leaderboard_data'] as String);
      
      return LeaderboardModel.fromJson(leaderboardData as Map<String, dynamic>);
      
    } catch (error) {
      return null;
    }
  }

  /// Cache leaderboard data
  Future<void> _cacheLeaderboard(String cacheKey, LeaderboardModel leaderboard) async {
    try {
      final db = await _localDataSource.database;
      
      await db.insert(
        _leaderboardTable,
        {
          'cache_key': cacheKey,
          'leaderboard_data': jsonEncode(leaderboard.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(_cacheExpiration).toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Clean up old cache entries
      await _cleanupLeaderboardCache();
      
    } catch (error) {
      // Ignore cache errors
    }
  }

  /// Get cached user rank
  Future<UserRank?> _getCachedUserRank(String cacheKey) async {
    try {
      final db = await _localDataSource.database;
      
      final result = await db.query(
        _userRanksTable,
        where: 'cache_key = ? AND expires_at > ?',
        whereArgs: [cacheKey, DateTime.now().toIso8601String()],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      final cached = result.first;
      final rankData = jsonDecode(cached['rank_data'] as String);
      
      return UserRank.fromJson(rankData as Map<String, dynamic>);
      
    } catch (error) {
      return null;
    }
  }

  /// Cache user rank
  Future<void> _cacheUserRank(String cacheKey, UserRank rank) async {
    try {
      final db = await _localDataSource.database;
      
      await db.insert(
        _userRanksTable,
        {
          'cache_key': cacheKey,
          'rank_data': jsonEncode(rank.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(_cacheExpiration).toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (error) {
      // Ignore cache errors
    }
  }

  /// Clean up old leaderboard cache entries
  Future<void> _cleanupLeaderboardCache() async {
    try {
      final db = await _localDataSource.database;
      
      // Remove expired entries
      await db.delete(
        _leaderboardTable,
        where: 'expires_at < ?',
        whereArgs: [DateTime.now().toIso8601String()],
      );
      
      // Keep only recent entries to limit cache size
      final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_leaderboardTable'
      )) ?? 0;
      
      if (count > _maxCachePages * 10) {
        await db.delete(
          _leaderboardTable,
          where: 'cache_key NOT IN (SELECT cache_key FROM $_leaderboardTable ORDER BY cached_at DESC LIMIT ?)',
          whereArgs: [_maxCachePages * 5],
        );
      }
      
    } catch (error) {
      // Ignore cleanup errors
    }
  }

  // =============================================================================
  // PAGINATION AND BATCHING
  // =============================================================================

  /// Get multiple pages of leaderboard data
  Future<List<LeaderboardEntry>> getLeaderboardPages(
    LeaderboardType type,
    LeaderboardPeriod period, {
    String? categoryFilter,
    int startPage = 1,
    int endPage = 3,
    int pageSize = 20,
  }) async {
    final allEntries = <LeaderboardEntry>[];
    
    for (int page = startPage; page <= endPage; page++) {
      try {
        final leaderboard = await getLeaderboard(
          type: type,
          period: period,
          categoryFilter: categoryFilter,
          page: page,
          limit: pageSize,
        );
        
        allEntries.addAll(leaderboard.entries.map((model) => LeaderboardEntry(
          userId: model.userId,
          displayName: model.displayName,
          avatarUrl: model.avatarUrl,
          rank: model.rank,
          previousRank: model.previousRank,
          score: model.score,
          previousScore: model.previousScore,
          stats: model.stats,
          lastUpdated: model.lastUpdated,
          isCurrentUser: model.isCurrentUser,
          badges: model.badges,
        )).toList());
        
        // Stop if we got fewer entries than requested (reached end)
        if (leaderboard.entries.length < pageSize) {
          break;
        }
        
      } catch (error) {
        // Stop on error to avoid partial data
        break;
      }
    }
    
    return allEntries;
  }

  /// Get leaderboard around specific user
  Future<LeaderboardModel> getLeaderboardAroundUser(
    String userId, {
    LeaderboardType type = LeaderboardType.global,
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
    int contextSize = 5,
  }) async {
    try {
      final response = await _supabase.rpc('get_leaderboard_around_user', params: {
        'target_user_id': userId,
        'leaderboard_type': type.name,
        'period': period.name,
        'context_size': contextSize,
      });
      
      return LeaderboardModel.fromJson(response as Map<String, dynamic>);
      
    } catch (error) {
      // Fallback to regular leaderboard
      return getLeaderboard(type: type, period: period, limit: contextSize * 2);
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Build cache key for leaderboard data
  String _buildCacheKey(
    LeaderboardType type,
    LeaderboardPeriod period,
    String? categoryFilter,
    int page,
    int limit,
  ) {
    return 'leaderboard_${type.name}_${period.name}_${categoryFilter ?? 'all'}_${page}_$limit';
  }

  /// Cleanup leaderboard subscription
  void _cleanupLeaderboardSubscription(String subscriptionKey) {
    // Close subscription
    _subscriptions[subscriptionKey]?.unsubscribe();
    _subscriptions.remove(subscriptionKey);
    
    // Close and remove controller
    _leaderboardControllers[subscriptionKey]?.close();
    _leaderboardControllers.remove(subscriptionKey);
  }

  /// Cleanup rank subscription
  void _cleanupRankSubscription(String subscriptionKey) {
    // Close subscription
    _subscriptions[subscriptionKey]?.unsubscribe();
    _subscriptions.remove(subscriptionKey);
    
    // Close and remove controller
    _rankControllers[subscriptionKey]?.close();
    _rankControllers.remove(subscriptionKey);
  }

  /// Clear all leaderboard caches
  Future<void> clearCache() async {
    try {
      final db = await _localDataSource.database;
      await db.delete(_leaderboardTable);
      await db.delete(_userRanksTable);
    } catch (error) {
      // Ignore cache clear errors
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await _localDataSource.database;
      
      final leaderboardCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_leaderboardTable'
      )) ?? 0;
      
      final ranksCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_userRanksTable'
      )) ?? 0;
      
      final expiredCount = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM (
          SELECT 1 FROM $_leaderboardTable WHERE expires_at < ?
          UNION ALL
          SELECT 1 FROM $_userRanksTable WHERE expires_at < ?
        )
      ''', [DateTime.now().toIso8601String(), DateTime.now().toIso8601String()])) ?? 0;
      
      return {
        'leaderboardCacheCount': leaderboardCount,
        'ranksCacheCount': ranksCount,
        'expiredCacheCount': expiredCount,
        'totalCacheItems': leaderboardCount + ranksCount,
      };
      
    } catch (error) {
      return {};
    }
  }

  /// Setup local database tables for leaderboard caching
  Future<void> setupLocalTables() async {
    try {
      final db = await _localDataSource.database;
      
      // Leaderboard cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_leaderboardTable (
          cache_key TEXT PRIMARY KEY,
          leaderboard_data TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          expires_at TEXT NOT NULL
        )
      ''');
      
      // User ranks cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_userRanksTable (
          cache_key TEXT PRIMARY KEY,
          rank_data TEXT NOT NULL,
          cached_at TEXT NOT NULL,
          expires_at TEXT NOT NULL
        )
      ''');
      
      // Leaderboard metadata table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_leaderboardMetaTable (
          leaderboard_type TEXT,
          period TEXT,
          last_updated TEXT NOT NULL,
          total_participants INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (leaderboard_type, period)
        )
      ''');
      
      // Create indexes for better performance
      await db.execute('CREATE INDEX IF NOT EXISTS idx_leaderboard_expires ON $_leaderboardTable(expires_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ranks_expires ON $_userRanksTable(expires_at)');
      
    } catch (error) {
      // Ignore table creation errors
    }
  }

  /// Dispose and cleanup all subscriptions
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.unsubscribe();
    }
    _subscriptions.clear();
    
    // Close all controllers
    for (final controller in _leaderboardControllers.values) {
      controller.close();
    }
    _leaderboardControllers.clear();
    
    for (final controller in _rankControllers.values) {
      controller.close();
    }
    _rankControllers.clear();
  }
}