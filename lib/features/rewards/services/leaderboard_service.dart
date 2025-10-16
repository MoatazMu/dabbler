import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/badge_tier.dart';

/// Leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int points;
  final int rank;
  final BadgeTier tier;
  final int achievementsCount;
  final DateTime lastActiveAt;
  final bool isFriend;
  final Map<String, dynamic>? metadata;

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.points,
    required this.rank,
    required this.tier,
    required this.achievementsCount,
    required this.lastActiveAt,
    this.isFriend = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'points': points,
      'rank': rank,
      'tier': tier.name,
      'achievementsCount': achievementsCount,
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isFriend': isFriend,
      'metadata': metadata,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'],
      userName: map['userName'],
      avatarUrl: map['avatarUrl'],
      points: map['points'],
      rank: map['rank'],
      tier: BadgeTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => BadgeTier.bronze,
      ),
      achievementsCount: map['achievementsCount'] ?? 0,
      lastActiveAt: DateTime.parse(map['lastActiveAt']),
      isFriend: map['isFriend'] ?? false,
      metadata: map['metadata'],
    );
  }

  LeaderboardEntry copyWith({
    String? userId,
    String? userName,
    String? avatarUrl,
    int? points,
    int? rank,
    BadgeTier? tier,
    int? achievementsCount,
    DateTime? lastActiveAt,
    bool? isFriend,
    Map<String, dynamic>? metadata,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      tier: tier ?? this.tier,
      achievementsCount: achievementsCount ?? this.achievementsCount,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isFriend: isFriend ?? this.isFriend,
      metadata: metadata ?? this.metadata,
    );
  }

  String get formattedPoints {
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String get timeAgoString {
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Leaderboard filter options
class LeaderboardFilter {
  final LeaderboardType type;
  final LeaderboardScope scope;
  final TimeRange timeRange;
  final BadgeTier? tierFilter;
  final bool friendsOnly;
  final int limit;
  final int offset;

  const LeaderboardFilter({
    this.type = LeaderboardType.points,
    this.scope = LeaderboardScope.global,
    this.timeRange = TimeRange.allTime,
    this.tierFilter,
    this.friendsOnly = false,
    this.limit = 50,
    this.offset = 0,
  });

  LeaderboardFilter copyWith({
    LeaderboardType? type,
    LeaderboardScope? scope,
    TimeRange? timeRange,
    BadgeTier? tierFilter,
    bool? friendsOnly,
    int? limit,
    int? offset,
  }) {
    return LeaderboardFilter(
      type: type ?? this.type,
      scope: scope ?? this.scope,
      timeRange: timeRange ?? this.timeRange,
      tierFilter: tierFilter ?? this.tierFilter,
      friendsOnly: friendsOnly ?? this.friendsOnly,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'scope': scope.name,
      'timeRange': timeRange.name,
      'tierFilter': tierFilter?.name,
      'friendsOnly': friendsOnly,
      'limit': limit,
      'offset': offset,
    };
  }
}

/// Leaderboard types
enum LeaderboardType {
  points,
  achievements,
  streaks,
  weeklyPoints,
  monthlyPoints,
}

/// Leaderboard scopes
enum LeaderboardScope {
  global,
  friends,
  local,
  tier,
}

/// Time ranges for leaderboards
enum TimeRange {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  allTime,
}

/// Leaderboard data container
class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentUserEntry;
  final LeaderboardFilter filter;
  final int totalCount;
  final DateTime lastUpdated;
  final bool hasMore;

  const LeaderboardData({
    required this.entries,
    this.currentUserEntry,
    required this.filter,
    required this.totalCount,
    required this.lastUpdated,
    this.hasMore = false,
  });

  LeaderboardData copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardEntry? currentUserEntry,
    LeaderboardFilter? filter,
    int? totalCount,
    DateTime? lastUpdated,
    bool? hasMore,
  }) {
    return LeaderboardData(
      entries: entries ?? this.entries,
      currentUserEntry: currentUserEntry ?? this.currentUserEntry,
      filter: filter ?? this.filter,
      totalCount: totalCount ?? this.totalCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entries': entries.map((e) => e.toMap()).toList(),
      'currentUserEntry': currentUserEntry?.toMap(),
      'filter': filter.toMap(),
      'totalCount': totalCount,
      'lastUpdated': lastUpdated.toIso8601String(),
      'hasMore': hasMore,
    };
  }
}

/// Leaderboard service
class LeaderboardService extends ChangeNotifier {
  final SupabaseClient _supabase;

  // Cache management
  final Map<String, LeaderboardData> _leaderboardCache = {};
  final Map<String, DateTime> _lastCacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const Duration _realTimeThrottle = Duration(seconds: 30);

  // Real-time subscriptions
  final Map<String, RealtimeChannel> _activeSubscriptions = {};
  
  // State management
  bool _isInitialized = false;
  String? _currentUserId;
  Set<String> _friendIds = {};
  
  // Processing state
  final Map<LeaderboardFilter, bool> _isUpdating = {};
  Timer? _periodicUpdateTimer;
  DateTime? _lastRealTimeUpdate;

  LeaderboardService({
    required SupabaseClient supabase,
  })  : _supabase = supabase;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
  int get cacheSize => _leaderboardCache.length;

  /// Initialize the service
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      _currentUserId = userId;
      
      // Load user's friends
      await _loadUserFriends();
      
      // Setup real-time subscriptions
      await _setupRealtimeSubscriptions();
      
      // Start periodic updates
      _startPeriodicUpdates();
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('LeaderboardService initialized for user: $userId');
      
    } catch (e) {
      debugPrint('Error initializing LeaderboardService: $e');
      rethrow;
    }
  }

  /// Dispose of the service
  @override
  void dispose() {
    _periodicUpdateTimer?.cancel();
    _clearAllSubscriptions();
    super.dispose();
  }

  /// Get leaderboard data
  Future<LeaderboardData> getLeaderboard(LeaderboardFilter filter) async {
    final cacheKey = _generateCacheKey(filter);
    
    // Check if update is already in progress
    if (_isUpdating[filter] == true) {
      // Return cached data if available
      if (_leaderboardCache.containsKey(cacheKey)) {
        return _leaderboardCache[cacheKey]!;
      }
      // Wait for update to complete
      while (_isUpdating[filter] == true) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _leaderboardCache[cacheKey]!;
    }

    return await _fetchLeaderboard(filter);
  }

  /// Update leaderboard data
  Future<LeaderboardData> updateLeaderboard(LeaderboardFilter filter) async {
    return await _fetchLeaderboard(filter, forceUpdate: true);
  }

  /// Get user's rank in leaderboard
  Future<LeaderboardEntry?> getUserRank(
    String userId, 
    LeaderboardFilter filter,
  ) async {
    try {
      final leaderboard = await getLeaderboard(filter);
      
      // Check if user is in the leaderboard entries
      for (final entry in leaderboard.entries) {
        if (entry.userId == userId) {
          return entry;
        }
      }
      
      // If not in entries, check current user entry
      if (leaderboard.currentUserEntry?.userId == userId) {
        return leaderboard.currentUserEntry;
      }
      
      // Fetch user rank separately
      return await _fetchUserRank(userId, filter);
      
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return null;
    }
  }

  /// Get friends leaderboard
  Future<LeaderboardData> getFriendsLeaderboard(LeaderboardFilter filter) async {
    final friendsFilter = filter.copyWith(
      scope: LeaderboardScope.friends,
      friendsOnly: true,
    );
    
    return await getLeaderboard(friendsFilter);
  }

  /// Get tier-based leaderboard
  Future<LeaderboardData> getTierLeaderboard(
    BadgeTier tier,
    LeaderboardFilter filter,
  ) async {
    final tierFilter = filter.copyWith(
      scope: LeaderboardScope.tier,
      tierFilter: tier,
    );
    
    return await getLeaderboard(tierFilter);
  }

  /// Search users in leaderboard
  Future<List<LeaderboardEntry>> searchUsers(
    String query, {
    LeaderboardFilter? filter,
  }) async {
    try {
      final searchFilter = filter ?? const LeaderboardFilter();
      
      // Get leaderboard data
      final leaderboard = await getLeaderboard(searchFilter);
      
      // Filter entries by query
      return leaderboard.entries.where((entry) {
        return entry.userName.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Get leaderboard statistics
  Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      return {
        'totalUsers': await _getTotalUsersCount(),
        'totalPoints': await _getTotalPointsSum(),
        'averagePoints': await _getAveragePoints(),
        'topTier': await _getTopTier(),
        'mostActiveDay': await _getMostActiveDay(),
        'cacheHitRate': _calculateCacheHitRate(),
      };
    } catch (e) {
      debugPrint('Error getting leaderboard stats: $e');
      return {};
    }
  }

  /// Clear cache
  void clearCache() {
    _leaderboardCache.clear();
    _lastCacheTime.clear();
    notifyListeners();
  }

  /// Clear cache for specific filter
  void clearCacheForFilter(LeaderboardFilter filter) {
    final cacheKey = _generateCacheKey(filter);
    _leaderboardCache.remove(cacheKey);
    _lastCacheTime.remove(cacheKey);
    notifyListeners();
  }

  /// Preload common leaderboards
  Future<void> preloadCommonLeaderboards() async {
    if (_currentUserId == null) return;
    
    try {
      final commonFilters = [
        const LeaderboardFilter(type: LeaderboardType.points, scope: LeaderboardScope.global),
        const LeaderboardFilter(type: LeaderboardType.points, scope: LeaderboardScope.friends),
        const LeaderboardFilter(type: LeaderboardType.achievements, scope: LeaderboardScope.global),
        const LeaderboardFilter(type: LeaderboardType.weeklyPoints, scope: LeaderboardScope.global),
      ];
      
      await Future.wait(
        commonFilters.map((filter) => getLeaderboard(filter)),
      );
      
      debugPrint('Preloaded ${commonFilters.length} common leaderboards');
      
    } catch (e) {
      debugPrint('Error preloading leaderboards: $e');
    }
  }

  // Private methods

  Future<LeaderboardData> _fetchLeaderboard(
    LeaderboardFilter filter, {
    bool forceUpdate = false,
  }) async {
    final cacheKey = _generateCacheKey(filter);
    
    if (!forceUpdate && _isUpdating[filter] == true) {
      // Wait for ongoing update
      while (_isUpdating[filter] == true) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _leaderboardCache[cacheKey] ?? 
             LeaderboardData(entries: [], filter: filter, totalCount: 0, lastUpdated: DateTime.now());
    }

    _isUpdating[filter] = true;

    try {
      List<LeaderboardEntry> entries;
      LeaderboardEntry? currentUserEntry;
      int totalCount = 0;

      switch (filter.type) {
        case LeaderboardType.points:
          entries = await _fetchPointsLeaderboard(filter);
          break;
        case LeaderboardType.achievements:
          entries = await _fetchAchievementsLeaderboard(filter);
          break;
        case LeaderboardType.streaks:
          entries = await _fetchStreaksLeaderboard(filter);
          break;
        case LeaderboardType.weeklyPoints:
          entries = await _fetchWeeklyPointsLeaderboard(filter);
          break;
        case LeaderboardType.monthlyPoints:
          entries = await _fetchMonthlyPointsLeaderboard(filter);
          break;
      }

      // Apply filters
      entries = _applyFilters(entries, filter);
      
      // Calculate ranks
      entries = _calculateRanks(entries);
      
      // Get current user entry if not in top entries
      if (_currentUserId != null && !entries.any((e) => e.userId == _currentUserId)) {
        currentUserEntry = await _fetchUserRank(_currentUserId!, filter);
      }

      totalCount = await _getTotalCountForFilter(filter);
      
      final leaderboardData = LeaderboardData(
        entries: entries,
        currentUserEntry: currentUserEntry,
        filter: filter,
        totalCount: totalCount,
        lastUpdated: DateTime.now(),
        hasMore: totalCount > filter.offset + entries.length,
      );

      // Cache the result
      _leaderboardCache[cacheKey] = leaderboardData;
      _lastCacheTime[cacheKey] = DateTime.now();
      
      notifyListeners();
      
      return leaderboardData;

    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      rethrow;
    } finally {
      _isUpdating[filter] = false;
    }
  }

  Future<List<LeaderboardEntry>> _fetchPointsLeaderboard(LeaderboardFilter filter) async {
    // This would typically make a database query
    // For now, returning mock data
    return await _mockLeaderboardEntries(filter);
  }

  Future<List<LeaderboardEntry>> _fetchAchievementsLeaderboard(LeaderboardFilter filter) async {
    // This would typically make a database query for achievement counts
    return await _mockLeaderboardEntries(filter);
  }

  Future<List<LeaderboardEntry>> _fetchStreaksLeaderboard(LeaderboardFilter filter) async {
    // This would typically make a database query for streaks
    return await _mockLeaderboardEntries(filter);
  }

  Future<List<LeaderboardEntry>> _fetchWeeklyPointsLeaderboard(LeaderboardFilter filter) async {
    // This would typically make a database query for weekly points
    return await _mockLeaderboardEntries(filter);
  }

  Future<List<LeaderboardEntry>> _fetchMonthlyPointsLeaderboard(LeaderboardFilter filter) async {
    // This would typically make a database query for monthly points
    return await _mockLeaderboardEntries(filter);
  }

  Future<List<LeaderboardEntry>> _mockLeaderboardEntries(LeaderboardFilter filter) async {
    // Mock data generation for demonstration
    final random = math.Random(42); // Fixed seed for consistent results
    final entries = <LeaderboardEntry>[];
    
    for (int i = 0; i < filter.limit; i++) {
      entries.add(LeaderboardEntry(
        userId: 'user_${i + filter.offset + 1}',
        userName: 'User ${i + filter.offset + 1}',
        avatarUrl: null,
        points: 10000 - (i + filter.offset) * 100 + random.nextInt(100),
        rank: i + filter.offset + 1,
        tier: BadgeTier.values[random.nextInt(BadgeTier.values.length)],
        achievementsCount: random.nextInt(50),
        lastActiveAt: DateTime.now().subtract(Duration(hours: random.nextInt(48))),
        isFriend: _friendIds.contains('user_${i + filter.offset + 1}'),
      ));
    }
    
    return entries;
  }

  List<LeaderboardEntry> _applyFilters(List<LeaderboardEntry> entries, LeaderboardFilter filter) {
    var filtered = entries;

    if (filter.friendsOnly) {
      filtered = filtered.where((e) => e.isFriend).toList();
    }

    if (filter.tierFilter != null) {
      filtered = filtered.where((e) => e.tier == filter.tierFilter).toList();
    }

    return filtered;
  }

  List<LeaderboardEntry> _calculateRanks(List<LeaderboardEntry> entries) {
    // Sort by points (or other criteria) and assign ranks
    entries.sort((a, b) => b.points.compareTo(a.points));
    
    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }
    
    return entries;
  }

  Future<LeaderboardEntry?> _fetchUserRank(String userId, LeaderboardFilter filter) async {
    try {
      // This would typically query the database for the specific user's rank
      // For now, returning mock data
      return LeaderboardEntry(
        userId: userId,
        userName: 'Current User',
        points: 5000,
        rank: 150,
        tier: BadgeTier.silver,
        achievementsCount: 25,
        lastActiveAt: DateTime.now(),
        isFriend: false,
      );
    } catch (e) {
      debugPrint('Error fetching user rank: $e');
      return null;
    }
  }

  Future<int> _getTotalCountForFilter(LeaderboardFilter filter) async {
    // This would typically query the database for total count
    return 1000; // Mock value
  }

  Future<void> _loadUserFriends() async {
    if (_currentUserId == null) return;
    
    try {
      // This would typically load from friends/social service
      _friendIds = {'user_2', 'user_5', 'user_8', 'user_12'}; // Mock friends
    } catch (e) {
      debugPrint('Error loading user friends: $e');
    }
  }

  Future<void> _setupRealtimeSubscriptions() async {
    if (_currentUserId == null) return;

    try {
      // Subscribe to points updates
      final pointsChannel = _supabase
          .channel('leaderboard_points')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_points',
            callback: (payload) => _handleRealtimeUpdate({
              'table': payload.table,
              'eventType': payload.eventType.name,
              'new': payload.newRecord,
              'old': payload.oldRecord,
            }),
          );

      pointsChannel.subscribe();
      _activeSubscriptions['points'] = pointsChannel;

      // Subscribe to achievement updates
      final achievementsChannel = _supabase
          .channel('leaderboard_achievements')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'user_achievements',
            callback: (payload) => _handleRealtimeUpdate({
              'table': payload.table,
              'eventType': payload.eventType.name,
              'new': payload.newRecord,
              'old': payload.oldRecord,
            }),
          );

      achievementsChannel.subscribe();
      _activeSubscriptions['achievements'] = achievementsChannel;

    } catch (e) {
      debugPrint('Error setting up real-time subscriptions: $e');
    }
  }

  void _handleRealtimeUpdate(Map<String, dynamic> payload) {
    final now = DateTime.now();
    
    // Throttle updates to prevent excessive rebuilds
    if (_lastRealTimeUpdate != null && 
        now.difference(_lastRealTimeUpdate!) < _realTimeThrottle) {
      return;
    }
    
    _lastRealTimeUpdate = now;
    
    // Invalidate relevant caches
    _invalidateRelevantCaches(payload);
    
    notifyListeners();
  }

  void _invalidateRelevantCaches(Map<String, dynamic> payload) {
    // Clear cache for leaderboards that might be affected by this update
    final keysToRemove = <String>[];
    
    for (final cacheKey in _leaderboardCache.keys) {
      // For simplicity, clear all caches on any update
      // In production, this could be more selective
      keysToRemove.add(cacheKey);
    }
    
    for (final key in keysToRemove) {
      _leaderboardCache.remove(key);
      _lastCacheTime.remove(key);
    }
  }

  void _clearAllSubscriptions() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.unsubscribe();
    }
    _activeSubscriptions.clear();
  }

  void _startPeriodicUpdates() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _performPeriodicUpdates(),
    );
  }

  Future<void> _performPeriodicUpdates() async {
    try {
      // Update commonly accessed leaderboards
      await preloadCommonLeaderboards();
      
      // Clean up expired cache entries
      _cleanupExpiredCache();
      
    } catch (e) {
      debugPrint('Error in periodic updates: $e');
    }
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _lastCacheTime.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _leaderboardCache.remove(key);
      _lastCacheTime.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('Cleaned up ${keysToRemove.length} expired cache entries');
    }
  }

  String _generateCacheKey(LeaderboardFilter filter) {
    return '${filter.type.name}_${filter.scope.name}_${filter.timeRange.name}_'
           '${filter.tierFilter?.name ?? 'all'}_${filter.friendsOnly}_'
           '${filter.limit}_${filter.offset}';
  }

  bool _isCacheValid(String cacheKey) {
    if (!_leaderboardCache.containsKey(cacheKey)) return false;
    
    final cacheTime = _lastCacheTime[cacheKey];
    if (cacheTime == null) return false;
    
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }

  // Statistics methods
  Future<int> _getTotalUsersCount() async {
    // Mock implementation
    return 10000;
  }

  Future<int> _getTotalPointsSum() async {
    // Mock implementation
    return 50000000;
  }

  Future<double> _getAveragePoints() async {
    // Mock implementation
    return 5000.0;
  }

  Future<BadgeTier> _getTopTier() async {
    // Mock implementation
    return BadgeTier.diamond;
  }

  Future<String> _getMostActiveDay() async {
    // Mock implementation
    return 'Saturday';
  }

  double _calculateCacheHitRate() {
    // Mock implementation
    return 0.85;
  }
}