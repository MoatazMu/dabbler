import 'dart:async';
import 'dart:math' as math;
import '../../../core/utils/either.dart';

/// Comprehensive analytics service for social features
class SocialAnalyticsService {
  
  // Event tracking
  final Map<String, List<SocialEvent>> _eventBuffer = {};
  final Map<String, SocialMetrics> _metricsCache = {};
  
  // Timers for periodic operations
  Timer? _flushTimer;
  Timer? _metricsCalculationTimer;
  
  // Configuration
  static const Duration _flushInterval = Duration(minutes: 5);
  static const Duration _metricsCalculationInterval = Duration(hours: 1);
  static const int _maxEventBufferSize = 1000;

  SocialAnalyticsService() {
    _initializeService();
  }

  /// Initialize the analytics service
  void _initializeService() {
    // Start periodic event flushing
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushEvents());
    
    // Start periodic metrics calculation
    _metricsCalculationTimer = Timer.periodic(_metricsCalculationInterval, (_) => _calculateMetrics());
    
    // Load cached metrics
    _loadCachedMetrics();
  }

  /// Track social events
  Future<void> trackEvent(SocialEvent event) async {
    try {
      final userId = event.userId;
      _eventBuffer.putIfAbsent(userId, () => []).add(event);
      
      // Flush if buffer is getting too large
      if (_eventBuffer[userId]!.length >= _maxEventBufferSize) {
        await _flushUserEvents(userId);
      }
      
      // Update real-time metrics for critical events
      if (_isCriticalEvent(event)) {
        await _updateRealTimeMetrics(event);
      }
    } catch (e) {
      // Log error but don't throw to avoid disrupting user experience
      print('Failed to track social event: $e');
    }
  }

  /// Track post creation
  Future<void> trackPostCreated(String userId, String postId, String postType, {
    int? characterCount,
    int? mediaCount,
    List<String>? hashtags,
    List<String>? mentions,
  }) async {
    final event = SocialEvent(
      id: _generateEventId(),
      userId: userId,
      type: SocialEventType.postCreated,
      timestamp: DateTime.now(),
      data: {
        'postId': postId,
        'postType': postType,
        'characterCount': characterCount ?? 0,
        'mediaCount': mediaCount ?? 0,
        'hashtagCount': hashtags?.length ?? 0,
        'mentionCount': mentions?.length ?? 0,
        'hashtags': hashtags ?? [],
        'mentions': mentions ?? [],
      },
    );
    
    await trackEvent(event);
  }

  /// Track post interaction
  Future<void> trackPostInteraction(String userId, String postId, String interactionType, {
    String? authorId,
    String? commentText,
  }) async {
    final event = SocialEvent(
      id: _generateEventId(),
      userId: userId,
      type: _getInteractionEventType(interactionType),
      timestamp: DateTime.now(),
      data: {
        'postId': postId,
        'authorId': authorId,
        'interactionType': interactionType,
        'commentText': commentText,
      },
    );
    
    await trackEvent(event);
  }

  /// Track friend activity
  Future<void> trackFriendActivity(String userId, String targetUserId, String activityType, {
    Map<String, dynamic>? additionalData,
  }) async {
    final event = SocialEvent(
      id: _generateEventId(),
      userId: userId,
      type: _getFriendEventType(activityType),
      timestamp: DateTime.now(),
      data: {
        'targetUserId': targetUserId,
        'activityType': activityType,
        ...?additionalData,
      },
    );
    
    await trackEvent(event);
  }

  /// Track messaging activity
  Future<void> trackMessageActivity(String userId, String conversationId, String activityType, {
    String? messageType,
    int? messageLength,
    bool? hasAttachments,
  }) async {
    final event = SocialEvent(
      id: _generateEventId(),
      userId: userId,
      type: _getMessageEventType(activityType),
      timestamp: DateTime.now(),
      data: {
        'conversationId': conversationId,
        'activityType': activityType,
        'messageType': messageType,
        'messageLength': messageLength ?? 0,
        'hasAttachments': hasAttachments ?? false,
      },
    );
    
    await trackEvent(event);
  }

  /// Track profile interactions
  Future<void> trackProfileActivity(String viewerId, String profileOwnerId, String activityType, {
    String? section,
    Duration? viewDuration,
  }) async {
    final event = SocialEvent(
      id: _generateEventId(),
      userId: viewerId,
      type: SocialEventType.profileViewed,
      timestamp: DateTime.now(),
      data: {
        'profileOwnerId': profileOwnerId,
        'activityType': activityType,
        'section': section,
        'viewDuration': viewDuration?.inSeconds,
      },
    );
    
    await trackEvent(event);
  }

  /// Calculate user engagement metrics
  Future<Either<String, UserEngagementMetrics>> calculateUserEngagement(
    String userId, {
    Duration period = const Duration(days: 30),
  }) async {
    try {
      final events = await _getUserEvents(userId, period);
      
      if (events.isEmpty) {
        return Right(UserEngagementMetrics.empty(userId));
      }
      
      // Calculate post metrics
      final postEvents = events.where((e) => _isPostEvent(e.type)).toList();
      final postMetrics = await _calculatePostMetrics(postEvents);
      
      // Calculate friend metrics
      final friendEvents = events.where((e) => _isFriendEvent(e.type)).toList();
      final friendMetrics = await _calculateFriendMetrics(friendEvents);
      
      // Calculate message metrics
      final messageEvents = events.where((e) => _isMessageEvent(e.type)).toList();
      final messageMetrics = await _calculateMessageMetrics(messageEvents);
      
      // Calculate interaction patterns
      final interactionPatterns = await _calculateInteractionPatterns(events);
      
      // Calculate activity timeline
      final activityTimeline = await _calculateActivityTimeline(events, period);
      
      final metrics = UserEngagementMetrics(
        userId: userId,
        period: period,
        calculatedAt: DateTime.now(),
        postMetrics: postMetrics,
        friendMetrics: friendMetrics,
        messageMetrics: messageMetrics,
        interactionPatterns: interactionPatterns,
        activityTimeline: activityTimeline,
        totalEvents: events.length,
        averageEventsPerDay: events.length / period.inDays,
      );
      
      // Cache the metrics
      _metricsCache[userId] = SocialMetrics.fromEngagement(metrics);
      
      return Right(metrics);
    } catch (e) {
      return Left('Failed to calculate user engagement: $e');
    }
  }

  /// Get post performance analytics
  Future<Either<String, PostAnalytics>> getPostAnalytics(
    String postId, {
    Duration period = const Duration(days: 7),
  }) async {
    try {
      final events = await _getPostEvents(postId, period);
      
      final likes = events.where((e) => e.type == SocialEventType.postLiked).length;
      final comments = events.where((e) => e.type == SocialEventType.postCommented).length;
      final shares = events.where((e) => e.type == SocialEventType.postShared).length;
      final views = events.where((e) => e.type == SocialEventType.postViewed).length;
      
      // Calculate engagement rate
      final engagementRate = views > 0 ? ((likes + comments + shares) / views) * 100 : 0.0;
      
      // Calculate viral score
      final viralScore = _calculateViralScore(likes, comments, shares, views, period);
      
      // Get interaction timeline
      final interactionTimeline = _getInteractionTimeline(events, period);
      
      // Get demographic breakdown
      final demographics = await _getPostDemographics(events);
      
      final analytics = PostAnalytics(
        postId: postId,
        period: period,
        calculatedAt: DateTime.now(),
        totalLikes: likes,
        totalComments: comments,
        totalShares: shares,
        totalViews: views,
        engagementRate: engagementRate,
        viralScore: viralScore,
        interactionTimeline: interactionTimeline,
        demographics: demographics,
        peakInteractionHour: _getPeakInteractionHour(events),
        averageEngagementVelocity: _calculateEngagementVelocity(events, period),
      );
      
      return Right(analytics);
    } catch (e) {
      return Left('Failed to get post analytics: $e');
    }
  }

  /// Get friendship analytics
  Future<Either<String, FriendshipAnalytics>> getFriendshipAnalytics(
    String userId, {
    Duration period = const Duration(days: 30),
  }) async {
    try {
      final events = await _getUserEvents(userId, period);
      final friendEvents = events.where((e) => _isFriendEvent(e.type)).toList();
      
      final friendRequestsSent = friendEvents.where((e) => e.type == SocialEventType.friendRequestSent).length;
      final friendRequestsReceived = friendEvents.where((e) => e.type == SocialEventType.friendRequestReceived).length;
      final friendsAdded = friendEvents.where((e) => e.type == SocialEventType.friendAdded).length;
      final friendsRemoved = friendEvents.where((e) => e.type == SocialEventType.friendRemoved).length;
      
      // Calculate acceptance rate
      final acceptanceRate = friendRequestsSent > 0 ? (friendsAdded / friendRequestsSent) * 100 : 0.0;
      
      // Get friendship growth timeline
      final growthTimeline = _getFriendshipGrowthTimeline(friendEvents, period);
      
      // Calculate mutual connections impact
      final mutualConnectionsImpact = await _calculateMutualConnectionsImpact(userId, friendEvents);
      
      final analytics = FriendshipAnalytics(
        userId: userId,
        period: period,
        calculatedAt: DateTime.now(),
        friendRequestsSent: friendRequestsSent,
        friendRequestsReceived: friendRequestsReceived,
        friendsAdded: friendsAdded,
        friendsRemoved: friendsRemoved,
        acceptanceRate: acceptanceRate,
        netFriendGrowth: friendsAdded - friendsRemoved,
        growthTimeline: growthTimeline,
        mutualConnectionsImpact: mutualConnectionsImpact,
        mostActiveFriendshipDay: _getMostActiveFriendshipDay(friendEvents),
      );
      
      return Right(analytics);
    } catch (e) {
      return Left('Failed to get friendship analytics: $e');
    }
  }

  /// Get messaging analytics
  Future<Either<String, MessagingAnalytics>> getMessagingAnalytics(
    String userId, {
    Duration period = const Duration(days: 30),
  }) async {
    try {
      final events = await _getUserEvents(userId, period);
      final messageEvents = events.where((e) => _isMessageEvent(e.type)).toList();
      
      final messagesSent = messageEvents.where((e) => e.type == SocialEventType.messageSent).length;
      final messagesReceived = messageEvents.where((e) => e.type == SocialEventType.messageReceived).length;
      final messagesRead = messageEvents.where((e) => e.type == SocialEventType.messageRead).length;
      
      // Calculate response metrics
      final responseTime = await _calculateAverageResponseTime(userId, messageEvents);
      final responseRate = messagesReceived > 0 ? (messagesSent / messagesReceived) * 100 : 0.0;
      
      // Get messaging patterns
      final messagingPatterns = _getMessagingPatterns(messageEvents);
      
      // Calculate conversation metrics
      final conversationMetrics = await _calculateConversationMetrics(userId, messageEvents);
      
      final analytics = MessagingAnalytics(
        userId: userId,
        period: period,
        calculatedAt: DateTime.now(),
        messagesSent: messagesSent,
        messagesReceived: messagesReceived,
        messagesRead: messagesRead,
        averageResponseTime: responseTime,
        responseRate: responseRate,
        messagingPatterns: messagingPatterns,
        conversationMetrics: conversationMetrics,
        mostActiveMessagingHour: _getMostActiveMessagingHour(messageEvents),
        averageMessageLength: _calculateAverageMessageLength(messageEvents),
      );
      
      return Right(analytics);
    } catch (e) {
      return Left('Failed to get messaging analytics: $e');
    }
  }

  /// Get social dashboard summary
  Future<Either<String, SocialDashboardSummary>> getDashboardSummary(
    String userId, {
    Duration period = const Duration(days: 7),
  }) async {
    try {
      // Get all analytics in parallel
      final results = await Future.wait([
        calculateUserEngagement(userId, period: period),
        getFriendshipAnalytics(userId, period: period),
        getMessagingAnalytics(userId, period: period),
      ]);
      
      final engagementResult = results[0] as Either<String, UserEngagementMetrics>;
      final friendshipResult = results[1] as Either<String, FriendshipAnalytics>;
      final messagingResult = results[2] as Either<String, MessagingAnalytics>;
      
      // Check for errors
      if (engagementResult.isLeft) return Left(engagementResult.leftOrNull()!);
      if (friendshipResult.isLeft) return Left(friendshipResult.leftOrNull()!);
      if (messagingResult.isLeft) return Left(messagingResult.leftOrNull()!);
      
      final engagement = engagementResult.rightOrNull()!;
      final friendship = friendshipResult.rightOrNull()!;
      final messaging = messagingResult.rightOrNull()!;
      
      // Get top performing content
      final topPosts = await _getTopPerformingPosts(userId, period);
      
      // Calculate overall social score
      final socialScore = _calculateOverallSocialScore(engagement, friendship, messaging);
      
      // Get activity trends
      final activityTrends = await _getActivityTrends(userId, period);
      
      // Get reach statistics
      final reachStats = await _getReachStatistics(userId, period);
      
      final summary = SocialDashboardSummary(
        userId: userId,
        period: period,
        generatedAt: DateTime.now(),
        engagementMetrics: engagement,
        friendshipAnalytics: friendship,
        messagingAnalytics: messaging,
        topPerformingPosts: topPosts,
        overallSocialScore: socialScore,
        activityTrends: activityTrends,
        reachStatistics: reachStats,
        keyInsights: _generateKeyInsights(engagement, friendship, messaging),
        recommendations: _generateRecommendations(engagement, friendship, messaging),
      );
      
      return Right(summary);
    } catch (e) {
      return Left('Failed to generate dashboard summary: $e');
    }
  }

  /// Detect viral content
  Future<List<ViralContent>> detectViralContent({
    Duration period = const Duration(days: 7),
    double viralThreshold = 10.0,
  }) async {
    try {
      final allEvents = await _getAllEvents(period);
      final postEvents = allEvents.where((e) => _isPostEvent(e.type)).toList();
      
      // Group events by post
      final postGroups = <String, List<SocialEvent>>{};
      for (final event in postEvents) {
        final postId = event.data['postId'] as String?;
        if (postId != null) {
          postGroups.putIfAbsent(postId, () => []).add(event);
        }
      }
      
      final viralPosts = <ViralContent>[];
      
      for (final entry in postGroups.entries) {
        final postId = entry.key;
        final events = entry.value;
        
        final viralScore = _calculateViralScore(
          events.where((e) => e.type == SocialEventType.postLiked).length,
          events.where((e) => e.type == SocialEventType.postCommented).length,
          events.where((e) => e.type == SocialEventType.postShared).length,
          events.where((e) => e.type == SocialEventType.postViewed).length,
          period,
        );
        
        if (viralScore >= viralThreshold) {
          viralPosts.add(ViralContent(
            postId: postId,
            viralScore: viralScore,
            detectedAt: DateTime.now(),
            metrics: await _getViralContentMetrics(postId, events),
          ));
        }
      }
      
      // Sort by viral score
      viralPosts.sort((a, b) => b.viralScore.compareTo(a.viralScore));
      
      return viralPosts;
    } catch (e) {
      return [];
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    _flushTimer?.cancel();
    _metricsCalculationTimer?.cancel();
    await _flushEvents();
  }

  // Private helper methods
  String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  bool _isCriticalEvent(SocialEvent event) {
    const criticalEvents = {
      SocialEventType.postCreated,
      SocialEventType.friendAdded,
      SocialEventType.friendRemoved,
    };
    return criticalEvents.contains(event.type);
  }

  SocialEventType _getInteractionEventType(String interactionType) {
    switch (interactionType.toLowerCase()) {
      case 'like': return SocialEventType.postLiked;
      case 'comment': return SocialEventType.postCommented;
      case 'share': return SocialEventType.postShared;
      case 'view': return SocialEventType.postViewed;
      default: return SocialEventType.postViewed;
    }
  }

  SocialEventType _getFriendEventType(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'request_sent': return SocialEventType.friendRequestSent;
      case 'request_received': return SocialEventType.friendRequestReceived;
      case 'added': return SocialEventType.friendAdded;
      case 'removed': return SocialEventType.friendRemoved;
      default: return SocialEventType.friendAdded;
    }
  }

  SocialEventType _getMessageEventType(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'sent': return SocialEventType.messageSent;
      case 'received': return SocialEventType.messageReceived;
      case 'read': return SocialEventType.messageRead;
      default: return SocialEventType.messageSent;
    }
  }

  bool _isPostEvent(SocialEventType type) {
    const postEvents = {
      SocialEventType.postCreated,
      SocialEventType.postViewed,
      SocialEventType.postLiked,
      SocialEventType.postCommented,
      SocialEventType.postShared,
    };
    return postEvents.contains(type);
  }

  bool _isFriendEvent(SocialEventType type) {
    const friendEvents = {
      SocialEventType.friendRequestSent,
      SocialEventType.friendRequestReceived,
      SocialEventType.friendAdded,
      SocialEventType.friendRemoved,
    };
    return friendEvents.contains(type);
  }

  bool _isMessageEvent(SocialEventType type) {
    const messageEvents = {
      SocialEventType.messageSent,
      SocialEventType.messageReceived,
      SocialEventType.messageRead,
    };
    return messageEvents.contains(type);
  }

  double _calculateViralScore(int likes, int comments, int shares, int views, Duration period) {
    if (views == 0) return 0.0;
    
    // Weighted engagement score
    final engagementScore = (likes * 1.0) + (comments * 2.0) + (shares * 3.0);
    final engagementRate = engagementScore / views;
    
    // Time decay factor (newer content gets higher scores)
    final ageHours = period.inHours.toDouble();
    final timeBoost = math.max(1.0, 48.0 / ageHours); // Boost for content less than 48 hours old
    
    // Viral velocity (engagement per hour)
    final velocity = engagementScore / ageHours;
    
    return (engagementRate * 100) * timeBoost * math.log(velocity + 1);
  }

  Future<void> _flushEvents() async {
    for (final userId in _eventBuffer.keys.toList()) {
      await _flushUserEvents(userId);
    }
  }

  Future<void> _flushUserEvents(String userId) async {
    final events = _eventBuffer[userId];
    if (events == null || events.isEmpty) return;
    
    try {
      // Store events to persistent storage
      // await _storageService.storeList('social_events_$userId', 
      //     events.map((e) => e.toJson()).toList());
      
      // Clear buffer
      _eventBuffer[userId]?.clear();
    } catch (e) {
      print('Failed to flush events for user $userId: $e');
    }
  }

  Future<void> _updateRealTimeMetrics(SocialEvent event) async {
    // Update real-time metrics for critical events
    // This would typically update a real-time dashboard or send notifications
  }

  Future<void> _calculateMetrics() async {
    // Periodic calculation of aggregated metrics
    // This would run complex calculations and update cached metrics
  }

  Future<void> _loadCachedMetrics() async {
    // Load previously calculated metrics from storage
  }

  Future<List<SocialEvent>> _getUserEvents(String userId, Duration period) async {
    // Implementation would fetch events from storage
    return [];
  }

  Future<List<SocialEvent>> _getPostEvents(String postId, Duration period) async {
    // Implementation would fetch post-specific events from storage
    return [];
  }

  Future<List<SocialEvent>> _getAllEvents(Duration period) async {
    // Implementation would fetch all events from storage
    return [];
  }

  // Additional helper methods would be implemented here...
  Future<PostMetrics> _calculatePostMetrics(List<SocialEvent> events) async {
    return PostMetrics.empty();
  }

  Future<FriendMetrics> _calculateFriendMetrics(List<SocialEvent> events) async {
    return FriendMetrics.empty();
  }

  Future<MessageMetrics> _calculateMessageMetrics(List<SocialEvent> events) async {
    return MessageMetrics.empty();
  }

  Future<InteractionPatterns> _calculateInteractionPatterns(List<SocialEvent> events) async {
    return InteractionPatterns.empty();
  }

  Future<ActivityTimeline> _calculateActivityTimeline(List<SocialEvent> events, Duration period) async {
    return ActivityTimeline.empty();
  }

  Map<DateTime, int> _getInteractionTimeline(List<SocialEvent> events, Duration period) {
    return {};
  }

  Future<PostDemographics> _getPostDemographics(List<SocialEvent> events) async {
    return PostDemographics.empty();
  }

  int _getPeakInteractionHour(List<SocialEvent> events) {
    return 12; // Default to noon
  }

  double _calculateEngagementVelocity(List<SocialEvent> events, Duration period) {
    return 0.0;
  }

  Map<DateTime, int> _getFriendshipGrowthTimeline(List<SocialEvent> events, Duration period) {
    return {};
  }

  Future<double> _calculateMutualConnectionsImpact(String userId, List<SocialEvent> events) async {
    return 0.0;
  }

  DateTime? _getMostActiveFriendshipDay(List<SocialEvent> events) {
    return null;
  }

  Future<Duration> _calculateAverageResponseTime(String userId, List<SocialEvent> events) async {
    return Duration.zero;
  }

  MessagingPatterns _getMessagingPatterns(List<SocialEvent> events) {
    return MessagingPatterns.empty();
  }

  Future<ConversationMetrics> _calculateConversationMetrics(String userId, List<SocialEvent> events) async {
    return ConversationMetrics.empty();
  }

  int _getMostActiveMessagingHour(List<SocialEvent> events) {
    return 18; // Default to 6 PM
  }

  double _calculateAverageMessageLength(List<SocialEvent> events) {
    return 0.0;
  }

  Future<List<TopPerformingPost>> _getTopPerformingPosts(String userId, Duration period) async {
    return [];
  }

  double _calculateOverallSocialScore(UserEngagementMetrics engagement, 
      FriendshipAnalytics friendship, MessagingAnalytics messaging) {
    return 75.0; // Placeholder calculation
  }

  Future<ActivityTrends> _getActivityTrends(String userId, Duration period) async {
    return ActivityTrends.empty();
  }

  Future<ReachStatistics> _getReachStatistics(String userId, Duration period) async {
    return ReachStatistics.empty();
  }

  List<String> _generateKeyInsights(UserEngagementMetrics engagement, 
      FriendshipAnalytics friendship, MessagingAnalytics messaging) {
    return [];
  }

  List<String> _generateRecommendations(UserEngagementMetrics engagement, 
      FriendshipAnalytics friendship, MessagingAnalytics messaging) {
    return [];
  }

  Future<ViralContentMetrics> _getViralContentMetrics(String postId, List<SocialEvent> events) async {
    return ViralContentMetrics.empty();
  }
}

// Data models for analytics
class SocialEvent {
  final String id;
  final String userId;
  final SocialEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const SocialEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  factory SocialEvent.fromJson(Map<String, dynamic> json) {
    return SocialEvent(
      id: json['id'],
      userId: json['userId'],
      type: SocialEventType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'] ?? {},
    );
  }
}

enum SocialEventType {
  // Post events
  postCreated,
  postViewed,
  postLiked,
  postCommented,
  postShared,
  
  // Friend events
  friendRequestSent,
  friendRequestReceived,
  friendAdded,
  friendRemoved,
  
  // Message events
  messageSent,
  messageReceived,
  messageRead,
  
  // Profile events
  profileViewed,
  profileUpdated,
}

class UserEngagementMetrics {
  final String userId;
  final Duration period;
  final DateTime calculatedAt;
  final PostMetrics postMetrics;
  final FriendMetrics friendMetrics;
  final MessageMetrics messageMetrics;
  final InteractionPatterns interactionPatterns;
  final ActivityTimeline activityTimeline;
  final int totalEvents;
  final double averageEventsPerDay;

  const UserEngagementMetrics({
    required this.userId,
    required this.period,
    required this.calculatedAt,
    required this.postMetrics,
    required this.friendMetrics,
    required this.messageMetrics,
    required this.interactionPatterns,
    required this.activityTimeline,
    required this.totalEvents,
    required this.averageEventsPerDay,
  });

  factory UserEngagementMetrics.empty(String userId) {
    return UserEngagementMetrics(
      userId: userId,
      period: const Duration(days: 30),
      calculatedAt: DateTime.now(),
      postMetrics: PostMetrics.empty(),
      friendMetrics: FriendMetrics.empty(),
      messageMetrics: MessageMetrics.empty(),
      interactionPatterns: InteractionPatterns.empty(),
      activityTimeline: ActivityTimeline.empty(),
      totalEvents: 0,
      averageEventsPerDay: 0.0,
    );
  }
}

// Additional data classes would be defined here...
class SocialMetrics {
  static SocialMetrics fromEngagement(UserEngagementMetrics metrics) {
    return SocialMetrics();
  }
}

class PostMetrics {
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  
  const PostMetrics({
    this.totalPosts = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
  });
  
  factory PostMetrics.empty() => const PostMetrics();
}

class FriendMetrics {
  final int totalFriends;
  final int newFriends;
  final int mutualConnections;
  
  const FriendMetrics({
    this.totalFriends = 0,
    this.newFriends = 0,
    this.mutualConnections = 0,
  });
  
  factory FriendMetrics.empty() => const FriendMetrics();
}

class MessageMetrics {
  final int totalMessages;
  final int totalConversations;
  final int averageResponseTime;
  
  const MessageMetrics({
    this.totalMessages = 0,
    this.totalConversations = 0,
    this.averageResponseTime = 0,
  });
  
  factory MessageMetrics.empty() => const MessageMetrics();
}

class InteractionPatterns {
  final Map<String, int> activityByHour;
  final Map<String, int> interactionTypes;
  
  const InteractionPatterns({
    this.activityByHour = const {},
    this.interactionTypes = const {},
  });
  
  factory InteractionPatterns.empty() => const InteractionPatterns();
}

class ActivityTimeline {
  final List<DateTime> activities;
  final Map<String, int> dailyActivity;
  
  const ActivityTimeline({
    this.activities = const [],
    this.dailyActivity = const {},
  });
  
  factory ActivityTimeline.empty() => const ActivityTimeline();
}

class PostAnalytics {
  final String postId;
  final Duration period;
  final DateTime calculatedAt;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalViews;
  final double engagementRate;
  final double viralScore;
  final Map<DateTime, int> interactionTimeline;
  final PostDemographics demographics;
  final int peakInteractionHour;
  final double averageEngagementVelocity;

  const PostAnalytics({
    required this.postId,
    required this.period,
    required this.calculatedAt,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalViews,
    required this.engagementRate,
    required this.viralScore,
    required this.interactionTimeline,
    required this.demographics,
    required this.peakInteractionHour,
    required this.averageEngagementVelocity,
  });
}

class PostDemographics {
  final Map<String, int> ageGroups;
  final Map<String, int> genderDistribution;
  final Map<String, int> locationData;
  
  const PostDemographics({
    this.ageGroups = const {},
    this.genderDistribution = const {},
    this.locationData = const {},
  });
  
  factory PostDemographics.empty() => const PostDemographics();
}

class FriendshipAnalytics {
  final String userId;
  final Duration period;
  final DateTime calculatedAt;
  final int friendRequestsSent;
  final int friendRequestsReceived;
  final int friendsAdded;
  final int friendsRemoved;
  final double acceptanceRate;
  final int netFriendGrowth;
  final Map<DateTime, int> growthTimeline;
  final double mutualConnectionsImpact;
  final DateTime? mostActiveFriendshipDay;

  const FriendshipAnalytics({
    required this.userId,
    required this.period,
    required this.calculatedAt,
    required this.friendRequestsSent,
    required this.friendRequestsReceived,
    required this.friendsAdded,
    required this.friendsRemoved,
    required this.acceptanceRate,
    required this.netFriendGrowth,
    required this.growthTimeline,
    required this.mutualConnectionsImpact,
    this.mostActiveFriendshipDay,
  });
}

class MessagingAnalytics {
  final String userId;
  final Duration period;
  final DateTime calculatedAt;
  final int messagesSent;
  final int messagesReceived;
  final int messagesRead;
  final Duration averageResponseTime;
  final double responseRate;
  final MessagingPatterns messagingPatterns;
  final ConversationMetrics conversationMetrics;
  final int mostActiveMessagingHour;
  final double averageMessageLength;

  const MessagingAnalytics({
    required this.userId,
    required this.period,
    required this.calculatedAt,
    required this.messagesSent,
    required this.messagesReceived,
    required this.messagesRead,
    required this.averageResponseTime,
    required this.responseRate,
    required this.messagingPatterns,
    required this.conversationMetrics,
    required this.mostActiveMessagingHour,
    required this.averageMessageLength,
  });
}

class MessagingPatterns {
  final Map<String, int> messageFrequency;
  final List<String> commonTopics;
  final double averageResponseTime;
  
  const MessagingPatterns({
    this.messageFrequency = const {},
    this.commonTopics = const [],
    this.averageResponseTime = 0.0,
  });
  
  factory MessagingPatterns.empty() => const MessagingPatterns();
}

class ConversationMetrics {
  final int totalConversations;
  final int activeConversations;
  final double averageLength;
  
  const ConversationMetrics({
    this.totalConversations = 0,
    this.activeConversations = 0,
    this.averageLength = 0.0,
  });
  
  factory ConversationMetrics.empty() => const ConversationMetrics();
}

class SocialDashboardSummary {
  final String userId;
  final Duration period;
  final DateTime generatedAt;
  final UserEngagementMetrics engagementMetrics;
  final FriendshipAnalytics friendshipAnalytics;
  final MessagingAnalytics messagingAnalytics;
  final List<TopPerformingPost> topPerformingPosts;
  final double overallSocialScore;
  final ActivityTrends activityTrends;
  final ReachStatistics reachStatistics;
  final List<String> keyInsights;
  final List<String> recommendations;

  const SocialDashboardSummary({
    required this.userId,
    required this.period,
    required this.generatedAt,
    required this.engagementMetrics,
    required this.friendshipAnalytics,
    required this.messagingAnalytics,
    required this.topPerformingPosts,
    required this.overallSocialScore,
    required this.activityTrends,
    required this.reachStatistics,
    required this.keyInsights,
    required this.recommendations,
  });
}

class TopPerformingPost {
  final String postId;
  final String content;
  final int totalEngagement;
  final double engagementRate;

  const TopPerformingPost({
    required this.postId,
    required this.content,
    required this.totalEngagement,
    required this.engagementRate,
  });
}

class ActivityTrends {
  final Map<String, double> weeklyTrends;
  final Map<String, double> monthlyTrends;
  final List<String> peakHours;
  
  const ActivityTrends({
    this.weeklyTrends = const {},
    this.monthlyTrends = const {},
    this.peakHours = const [],
  });
  
  factory ActivityTrends.empty() => const ActivityTrends();
}

class ReachStatistics {
  final int totalReach;
  final int uniqueUsers;
  final double engagementRate;
  
  const ReachStatistics({
    this.totalReach = 0,
    this.uniqueUsers = 0,
    this.engagementRate = 0.0,
  });
  
  factory ReachStatistics.empty() => const ReachStatistics();
}

class ViralContent {
  final String postId;
  final double viralScore;
  final DateTime detectedAt;
  final ViralContentMetrics metrics;

  const ViralContent({
    required this.postId,
    required this.viralScore,
    required this.detectedAt,
    required this.metrics,
  });
}

class ViralContentMetrics {
  final int shareCount;
  final int viewCount;
  final double velocityScore;
  final double reachMultiplier;
  
  const ViralContentMetrics({
    this.shareCount = 0,
    this.viewCount = 0,
    this.velocityScore = 0.0,
    this.reachMultiplier = 0.0,
  });
  
  factory ViralContentMetrics.empty() => const ViralContentMetrics();
}
