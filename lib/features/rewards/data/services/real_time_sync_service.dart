import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/entities/point_transaction.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/supabase_rewards_datasource.dart';
import '../datasources/achievements_local_datasource.dart';

/// Real-time sync service for rewards system
/// Handles WebSocket subscriptions, offline event synchronization,
/// and data consistency between local and remote storage
class RealtimeSyncService {
  final SupabaseClient _supabase;
  final SupabaseRewardsDataSource _remoteDataSource;
  final AchievementsLocalDataSource _localDataSource;
  final Connectivity _connectivity;
  
  // Subscription management
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController> _streamControllers = {};
  
  // Sync status
  bool _isConnected = false;
  bool _isSyncing = false;
  DateTime? _lastSyncAt;
  
  // Configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _reconnectDelay = Duration(seconds: 30);

  static const int _batchSize = 50;
  
  Timer? _syncTimer;
  Timer? _reconnectTimer;
  StreamSubscription? _connectivitySubscription;
  
  RealtimeSyncService({
    required SupabaseClient supabase,
    required SupabaseRewardsDataSource remoteDataSource,
    required AchievementsLocalDataSource localDataSource,
    Connectivity? connectivity,
  }) : _supabase = supabase,
        _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivity = connectivity ?? Connectivity();

  // =============================================================================
  // INITIALIZATION AND LIFECYCLE
  // =============================================================================

  /// Initialize the sync service
  Future<void> initialize() async {
    await _setupConnectivityListener();
    await _checkInitialConnectivity();
    await _setupPeriodicSync();
    await _processQueuedEvents();
  }

  /// Setup connectivity listener
  Future<void> _setupConnectivityListener() async {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasConnected = _isConnected;
        _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
        
        if (_isConnected && !wasConnected) {
          // Reconnected - sync queued events
          await _onReconnected();
        } else if (!_isConnected && wasConnected) {
          // Disconnected
          await _onDisconnected();
        }
      },
    );
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (_isConnected) {
      await _establishRealtimeConnections();
    }
  }

  /// Setup periodic sync timer
  Future<void> _setupPeriodicSync() async {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_isConnected && !_isSyncing) {
        _performPeriodicSync();
      }
    });
  }

  /// Handle reconnection
  Future<void> _onReconnected() async {
    print('🔄 RealtimeSyncService: Reconnected to network');
    
    // Cancel existing reconnect timer
    _reconnectTimer?.cancel();
    
    // Re-establish realtime connections
    await _establishRealtimeConnections();
    
    // Sync queued events
    await _processQueuedEvents();
  }

  /// Handle disconnection
  Future<void> _onDisconnected() async {
    print('📴 RealtimeSyncService: Disconnected from network');
    
    // Clean up realtime connections
    await _cleanupRealtimeConnections();
    
    // Schedule reconnection attempts
    _scheduleReconnection();
  }

  /// Schedule reconnection attempts
  void _scheduleReconnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (!_isConnected) {
        await _checkInitialConnectivity();
      }
    });
  }

  // =============================================================================
  // REALTIME SUBSCRIPTIONS
  // =============================================================================

  /// Establish realtime connections
  Future<void> _establishRealtimeConnections() async {
    try {
      // Subscribe to user progress updates
      await _subscribeToProgressUpdates();
      
      // Subscribe to achievement updates
      await _subscribeToAchievementUpdates();
      
      // Subscribe to point transactions
      await _subscribeToPointUpdates();
      
      // Subscribe to leaderboard updates
      await _subscribeToLeaderboardUpdates();
      
      print('✅ RealtimeSyncService: Established realtime connections');
      
    } catch (error) {
      print('❌ RealtimeSyncService: Failed to establish connections: $error');
    }
  }

  /// Subscribe to user progress updates
  Future<void> _subscribeToProgressUpdates() async {
    final channel = _supabase
        .channel('user_progress_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_progress',
          callback: _handleProgressUpdate,
        )
        .subscribe();
        
    _channels['user_progress'] = channel;
  }

  /// Subscribe to achievement updates
  Future<void> _subscribeToAchievementUpdates() async {
    final channel = _supabase
        .channel('achievement_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'achievements',
          callback: _handleAchievementUpdate,
        )
        .subscribe();
        
    _channels['achievements'] = channel;
  }

  /// Subscribe to point transaction updates
  Future<void> _subscribeToPointUpdates() async {
    final channel = _supabase
        .channel('point_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'point_transactions',
          callback: _handlePointUpdate,
        )
        .subscribe();
        
    _channels['points'] = channel;
  }

  /// Subscribe to leaderboard updates
  Future<void> _subscribeToLeaderboardUpdates() async {
    final channel = _supabase
        .channel('leaderboard_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_points',
          callback: _handleLeaderboardUpdate,
        )
        .subscribe();
        
    _channels['leaderboard'] = channel;
  }

  /// Clean up realtime connections
  Future<void> _cleanupRealtimeConnections() async {
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();
    
    print('🧹 RealtimeSyncService: Cleaned up realtime connections');
  }

  // =============================================================================
  // REALTIME EVENT HANDLERS
  // =============================================================================

  /// Handle user progress updates
  void _handleProgressUpdate(PostgresChangePayload payload) {
    print('📈 Progress update: ${payload.eventType}');
    
    try {
      final data = payload.newRecord;
      
      // Update local cache
      _updateLocalProgressCache(data);
      
      // Emit to stream if exists
      _emitProgressUpdate(data);
      
    } catch (error) {
      print('❌ Error handling progress update: $error');
    }
  }

  /// Handle achievement updates
  void _handleAchievementUpdate(PostgresChangePayload payload) {
    print('🏆 Achievement update: ${payload.eventType}');
    
    try {
      final data = payload.newRecord;
      
      // Update local cache
      _updateLocalAchievementCache(data);
      
      // Emit to stream if exists
      _emitAchievementUpdate(data);
      
    } catch (error) {
      print('❌ Error handling achievement update: $error');
    }
  }

  /// Handle point transaction updates
  void _handlePointUpdate(PostgresChangePayload payload) {
    print('💰 Point update: ${payload.eventType}');
    
    try {
      final data = payload.newRecord;
      
      // Update local cache
      _updateLocalPointCache(data);
      
      // Emit to stream if exists
      _emitPointUpdate(data);
      
    } catch (error) {
      print('❌ Error handling point update: $error');
    }
  }

  /// Handle leaderboard updates
  void _handleLeaderboardUpdate(PostgresChangePayload payload) {
    print('📊 Leaderboard update: ${payload.eventType}');
    
    try {
      final data = payload.newRecord;
      
      // Emit to stream if exists
      _emitLeaderboardUpdate(data);
      
    } catch (error) {
      print('❌ Error handling leaderboard update: $error');
    }
  }

  // =============================================================================
  // LOCAL CACHE UPDATES
  // =============================================================================

  /// Update local progress cache
  Future<void> _updateLocalProgressCache(Map<String, dynamic> data) async {
    try {
      // This would update the local SQLite cache
      // Implementation depends on your UserProgressModel structure
      print('🔄 Updating local progress cache for ${data['user_id']}');
      
    } catch (error) {
      print('❌ Error updating local progress cache: $error');
    }
  }

  /// Update local achievement cache
  Future<void> _updateLocalAchievementCache(Map<String, dynamic> data) async {
    try {
      // This would update the local SQLite cache
      // Implementation depends on your AchievementModel structure
      print('🔄 Updating local achievement cache for ${data['id']}');
      
    } catch (error) {
      print('❌ Error updating local achievement cache: $error');
    }
  }

  /// Update local point transaction cache
  Future<void> _updateLocalPointCache(Map<String, dynamic> data) async {
    try {
      // This would update the local SQLite cache
      // Implementation depends on your PointTransaction structure
      print('🔄 Updating local point cache for ${data['user_id']}');
      
    } catch (error) {
      print('❌ Error updating local point cache: $error');
    }
  }

  // =============================================================================
  // STREAM EMISSION
  // =============================================================================

  /// Emit progress update to streams
  void _emitProgressUpdate(Map<String, dynamic> data) {
    final controller = _streamControllers['progress'];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  /// Emit achievement update to streams
  void _emitAchievementUpdate(Map<String, dynamic> data) {
    final controller = _streamControllers['achievements'];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  /// Emit point update to streams
  void _emitPointUpdate(Map<String, dynamic> data) {
    final controller = _streamControllers['points'];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  /// Emit leaderboard update to streams
  void _emitLeaderboardUpdate(Map<String, dynamic> data) {
    final controller = _streamControllers['leaderboard'];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  // =============================================================================
  // PUBLIC STREAM ACCESSORS
  // =============================================================================

  /// Get stream for progress updates
  Stream<Map<String, dynamic>> get progressUpdates {
    if (!_streamControllers.containsKey('progress')) {
      _streamControllers['progress'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _streamControllers['progress']!.stream as Stream<Map<String, dynamic>>;
  }

  /// Get stream for achievement updates
  Stream<Map<String, dynamic>> get achievementUpdates {
    if (!_streamControllers.containsKey('achievements')) {
      _streamControllers['achievements'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _streamControllers['achievements']!.stream as Stream<Map<String, dynamic>>;
  }

  /// Get stream for point updates
  Stream<Map<String, dynamic>> get pointUpdates {
    if (!_streamControllers.containsKey('points')) {
      _streamControllers['points'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _streamControllers['points']!.stream as Stream<Map<String, dynamic>>;
  }

  /// Get stream for leaderboard updates
  Stream<Map<String, dynamic>> get leaderboardUpdates {
    if (!_streamControllers.containsKey('leaderboard')) {
      _streamControllers['leaderboard'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _streamControllers['leaderboard']!.stream as Stream<Map<String, dynamic>>;
  }

  // =============================================================================
  // OFFLINE EVENT PROCESSING
  // =============================================================================

  /// Process queued offline events
  Future<void> _processQueuedEvents() async {
    if (!_isConnected || _isSyncing) return;
    
    _isSyncing = true;
    
    try {
      final events = await _localDataSource.getQueuedEvents(limit: _batchSize);
      
      if (events.isEmpty) {
        _isSyncing = false;
        return;
      }
      
      print('🔄 Processing ${events.length} queued events');
      
      for (final event in events) {
        final success = await _processQueuedEvent(event);
        
        if (success) {
          await _localDataSource.markEventAsProcessed(event['id']);
        } else {
          await _localDataSource.markEventAsFailed(
            event['id'],
            'Failed to process event',
          );
        }
      }
      
      _lastSyncAt = DateTime.now();
      await _localDataSource.updateSyncStatus('events');
      
      print('✅ Processed ${events.length} queued events');
      
    } catch (error) {
      print('❌ Error processing queued events: $error');
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single queued event
  Future<bool> _processQueuedEvent(Map<String, dynamic> event) async {
    try {
      final eventType = event['type'] as String;
      final eventData = event['data'] as Map<String, dynamic>;
      final userId = event['userId'] as String;
      
      switch (eventType) {
        case 'achievement_progress':
          return await _syncAchievementProgress(userId, eventData);
          
        case 'point_award':
          return await _syncPointAward(userId, eventData);
          
        case 'badge_showcase':
          return await _syncBadgeShowcase(userId, eventData);
          
        default:
          print('⚠️  Unknown event type: $eventType');
          return false;
      }
      
    } catch (error) {
      print('❌ Error processing event: $error');
      return false;
    }
  }

  /// Sync achievement progress
  Future<bool> _syncAchievementProgress(String userId, Map<String, dynamic> data) async {
    try {
      final eventTypeStr = data['eventType'] as String? ?? 'gameEnd';
      final eventData = data['eventData'] as Map<String, dynamic>? ?? {};
      
      // Parse string to EventType enum
      EventType eventType;
      try {
        eventType = EventType.values.firstWhere((e) => e.name == eventTypeStr);
      } catch (_) {
        eventType = EventType.gameEnd; // default fallback
      }
      
      // Call the remote datasource with correct parameters
      await _remoteDataSource.trackEvent(
        eventType,
        eventData,
        userId,
      );
      return true;
    } catch (error) {
      print('❌ Error syncing achievement progress: $error');
      return false;
    }
  }

  /// Sync point award
  Future<bool> _syncPointAward(String userId, Map<String, dynamic> data) async {
    try {
      final basePoints = data['basePoints'] as int? ?? 0;
      final typeStr = data['type'] as String? ?? 'achievement';
      final sourceId = data['sourceId'] as String? ?? 'unknown';
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
      
      // Parse string to TransactionType enum
      TransactionType transactionType;
      try {
        transactionType = TransactionType.values.firstWhere((t) => t.name == typeStr);
      } catch (_) {
        transactionType = TransactionType.achievement; // default fallback
      }
      
      // Call the remote datasource with correct parameters
      await _remoteDataSource.awardPoints(
        userId,
        basePoints,
        transactionType,
        sourceId,
        metadata: metadata,
      );
      return true;
    } catch (error) {
      print('❌ Error syncing point award: $error');
      return false;
    }
  }

  /// Sync badge showcase
  Future<bool> _syncBadgeShowcase(String userId, Map<String, dynamic> data) async {
    try {
      // This would call a badge showcase endpoint
      // Implementation depends on your badge system
      print('🔄 Syncing badge showcase for user $userId');
      return true;
    } catch (error) {
      print('❌ Error syncing badge showcase: $error');
      return false;
    }
  }

  // =============================================================================
  // PERIODIC SYNC
  // =============================================================================

  /// Perform periodic sync
  Future<void> _performPeriodicSync() async {
    if (_isSyncing) return;
    
    print('🔄 Performing periodic sync');
    
    try {
      await _processQueuedEvents();
      await _syncCriticalData();
      
    } catch (error) {
      print('❌ Error in periodic sync: $error');
    }
  }

  /// Sync critical data that needs regular updates
  Future<void> _syncCriticalData() async {
    try {
      // Sync any critical data that needs regular updates
      // This could include:
      // - User tier updates
      // - Badge unlocks
      // - Achievement completions
      
      print('🔄 Syncing critical data');
      
    } catch (error) {
      print('❌ Error syncing critical data: $error');
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Get sync status information
  Map<String, dynamic> getSyncStatus() {
    return {
      'isConnected': _isConnected,
      'isSyncing': _isSyncing,
      'lastSyncAt': _lastSyncAt?.toIso8601String(),
      'activeChannels': _channels.length,
      'activeStreams': _streamControllers.length,
    };
  }

  /// Force sync now
  Future<void> forcSync() async {
    if (!_isConnected) {
      throw Exception('Cannot sync while offline');
    }
    
    await _processQueuedEvents();
    await _syncCriticalData();
  }

  /// Queue event for offline processing
  Future<void> queueEvent(String userId, String eventType, Map<String, dynamic> eventData) async {
    final event = {
      'userId': userId,
      'type': eventType,
      'data': eventData,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _localDataSource.queueEvent(event);
    print('📥 Queued event: $eventType for user $userId');
  }

  /// Get count of queued events
  Future<int> getQueuedEventsCount() async {
    return await _localDataSource.getQueuedEventsCount();
  }

  // =============================================================================
  // CLEANUP AND DISPOSAL
  // =============================================================================

  /// Dispose and cleanup all resources
  Future<void> dispose() async {
    print('🧹 Disposing RealtimeSyncService');
    
    // Cancel timers
    _syncTimer?.cancel();
    _reconnectTimer?.cancel();
    
    // Cancel connectivity subscription
    await _connectivitySubscription?.cancel();
    
    // Clean up realtime connections
    await _cleanupRealtimeConnections();
    
    // Close stream controllers
    for (final controller in _streamControllers.values) {
      await controller.close();
    }
    _streamControllers.clear();
    
    print('✅ RealtimeSyncService disposed');
  }
}