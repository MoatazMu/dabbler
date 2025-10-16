import 'package:supabase_flutter/supabase_flutter.dart';
 

/// Exception types for analytics data source operations
class AnalyticsDataSourceException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  const AnalyticsDataSourceException({
    required this.message,
    required this.code,
    this.details,
  });

  @override
  String toString() => 'AnalyticsDataSourceException: $message (Code: $code)';
}

/// Analytics event types
enum AnalyticsEventType {
  profileView,
  profileUpdate,
  avatarUpload,
  sportProfileAdd,
  sportProfileUpdate,
  sportProfileRemove,
  settingsUpdate,
  preferencesUpdate,
  availabilityUpdate,
  search,
  matchmakingRequest,
  gameInvite,
  friendRequest,
  profileCompletion,
  engagement,
}

/// Analytics event model
class AnalyticsEvent {
  final String eventId;
  final String userId;
  final AnalyticsEventType eventType;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? sessionId;
  final String? deviceId;
  final String? platform;
  final Map<String, dynamic>? metadata;

  const AnalyticsEvent({
    required this.eventId,
    required this.userId,
    required this.eventType,
    required this.properties,
    required this.timestamp,
    this.sessionId,
    this.deviceId,
    this.platform,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'user_id': userId,
      'event_type': eventType.name,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
      'session_id': sessionId,
      'device_id': deviceId,
      'platform': platform,
      'metadata': metadata,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventId: json['event_id'],
      userId: json['user_id'],
      eventType: AnalyticsEventType.values.firstWhere(
        (e) => e.name == json['event_type'],
      ),
      properties: json['properties'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['session_id'],
      deviceId: json['device_id'],
      platform: json['platform'],
      metadata: json['metadata'],
    );
  }
}

/// Profile completion tracking model
class ProfileCompletionMetrics {
  final String userId;
  final double completionPercentage;
  final Map<String, bool> completedSections;
  final List<String> missingSections;
  final Map<String, DateTime> sectionCompletionDates;
  final DateTime lastUpdated;

  const ProfileCompletionMetrics({
    required this.userId,
    required this.completionPercentage,
    required this.completedSections,
    required this.missingSections,
    required this.sectionCompletionDates,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'completion_percentage': completionPercentage,
      'completed_sections': completedSections,
      'missing_sections': missingSections,
      'section_completion_dates': sectionCompletionDates.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory ProfileCompletionMetrics.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionMetrics(
      userId: json['user_id'],
      completionPercentage: (json['completion_percentage'] ?? 0.0).toDouble(),
      completedSections: Map<String, bool>.from(json['completed_sections'] ?? {}),
      missingSections: List<String>.from(json['missing_sections'] ?? []),
      sectionCompletionDates: (json['section_completion_dates'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, DateTime.parse(value))),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

/// User engagement metrics model
class EngagementMetrics {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int profileViews;
  final int profileUpdates;
  final int searchQueries;
  final int gameInvitesSent;
  final int gameInvitesReceived;
  final int friendRequestsSent;
  final int friendRequestsReceived;
  final double averageSessionDuration;
  final int totalSessions;
  final Map<String, int> featureUsage;
  final double engagementScore;

  const EngagementMetrics({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.profileViews,
    required this.profileUpdates,
    required this.searchQueries,
    required this.gameInvitesSent,
    required this.gameInvitesReceived,
    required this.friendRequestsSent,
    required this.friendRequestsReceived,
    required this.averageSessionDuration,
    required this.totalSessions,
    required this.featureUsage,
    required this.engagementScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'profile_views': profileViews,
      'profile_updates': profileUpdates,
      'search_queries': searchQueries,
      'game_invites_sent': gameInvitesSent,
      'game_invites_received': gameInvitesReceived,
      'friend_requests_sent': friendRequestsSent,
      'friend_requests_received': friendRequestsReceived,
      'average_session_duration': averageSessionDuration,
      'total_sessions': totalSessions,
      'feature_usage': featureUsage,
      'engagement_score': engagementScore,
    };
  }

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EngagementMetrics(
      userId: json['user_id'],
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      profileViews: json['profile_views'] ?? 0,
      profileUpdates: json['profile_updates'] ?? 0,
      searchQueries: json['search_queries'] ?? 0,
      gameInvitesSent: json['game_invites_sent'] ?? 0,
      gameInvitesReceived: json['game_invites_received'] ?? 0,
      friendRequestsSent: json['friend_requests_sent'] ?? 0,
      friendRequestsReceived: json['friend_requests_received'] ?? 0,
      averageSessionDuration: (json['average_session_duration'] ?? 0.0).toDouble(),
      totalSessions: json['total_sessions'] ?? 0,
      featureUsage: Map<String, int>.from(json['feature_usage'] ?? {}),
      engagementScore: (json['engagement_score'] ?? 0.0).toDouble(),
    );
  }
}

/// Abstract interface for profile analytics data operations
abstract class ProfileAnalyticsDataSource {
  // Event Tracking
  Future<void> trackEvent(AnalyticsEvent event);
  Future<void> trackBatchEvents(List<AnalyticsEvent> events);
  Future<void> trackProfileView(String viewerId, String profileUserId, {
    String? source,
    Map<String, dynamic>? context,
  });
  Future<void> trackProfileUpdate(String userId, String section, Map<String, dynamic> changes);
  Future<void> trackAvatarUpload(String userId, {String? fileName, int? fileSize});
  Future<void> trackSportProfileAction(String userId, String action, String sportId);
  Future<void> trackSettingsUpdate(String userId, String category, Map<String, dynamic> changes);
  Future<void> trackPreferencesUpdate(String userId, String category, dynamic newValue);
  Future<void> trackSearch(String userId, String query, int resultsCount);
  Future<void> trackMatchmakingRequest(String userId, Map<String, dynamic> criteria);

  // Profile Completion Tracking
  Future<ProfileCompletionMetrics> getProfileCompletion(String userId);
  Future<void> updateProfileCompletion(String userId, String section, bool completed);
  Future<Map<String, double>> getCompletionTrends(String userId, DateTime startDate, DateTime endDate);
  Future<List<String>> getIncompleteProfileSuggestions(String userId);

  // Engagement Metrics
  Future<EngagementMetrics> getEngagementMetrics(String userId, DateTime startDate, DateTime endDate);
  Future<Map<String, int>> getFeatureUsageStats(String userId, DateTime startDate, DateTime endDate);
  Future<double> calculateEngagementScore(String userId, DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getEngagementTrends(String userId, int days);

  // Session Tracking
  Future<void> startSession(String userId, String sessionId, {
    String? deviceId,
    String? platform,
    Map<String, dynamic>? context,
  });
  Future<void> endSession(String userId, String sessionId, Duration duration);
  Future<Map<String, dynamic>> getSessionStats(String userId, DateTime startDate, DateTime endDate);

  // Popular Content and Trends
  Future<List<Map<String, dynamic>>> getMostViewedProfiles(int limit, DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getPopularSports(int limit, DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getTrendingLocations(int limit, DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getSearchTrends(DateTime startDate, DateTime endDate);

  // User Behavior Analysis
  Future<Map<String, dynamic>> getUserBehaviorPattern(String userId);
  Future<List<String>> getPredictedInterests(String userId);
  Future<Map<String, dynamic>> getPersonalizationInsights(String userId);
  Future<double> calculateUserRetentionScore(String userId);

  // Reporting and Insights
  Future<Map<String, dynamic>> generateUserReport(String userId, DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getSystemWideMetrics(DateTime startDate, DateTime endDate);
  Future<List<Map<String, dynamic>>> getTopPerformingFeatures(DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getConversionFunnelData(DateTime startDate, DateTime endDate);

  // Data Export and Privacy
  Future<Map<String, dynamic>> exportUserAnalytics(String userId);
  Future<void> deleteUserAnalytics(String userId);
  Future<void> anonymizeUserData(String userId);
}

/// Supabase implementation of profile analytics data source
class SupabaseProfileAnalyticsDataSource implements ProfileAnalyticsDataSource {
  final SupabaseClient _client;
  final String _eventsTable = 'analytics_events';
  final String _sessionsTable = 'user_sessions';
  final String _profileCompletionTable = 'profile_completion';
  

  SupabaseProfileAnalyticsDataSource(this._client);

  @override
  Future<void> trackEvent(AnalyticsEvent event) async {
    try {
      await _client.from(_eventsTable).insert(event.toJson());
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to track event: $e',
        code: 'EVENT_TRACKING_ERROR',
      );
    }
  }

  @override
  Future<void> trackBatchEvents(List<AnalyticsEvent> events) async {
    try {
      if (events.isEmpty) return;
      
      final eventData = events.map((event) => event.toJson()).toList();
      await _client.from(_eventsTable).insert(eventData);
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to track batch events: $e',
        code: 'BATCH_EVENT_TRACKING_ERROR',
      );
    }
  }

  @override
  Future<void> trackProfileView(String viewerId, String profileUserId, {
    String? source,
    Map<String, dynamic>? context,
  }) async {
    try {
      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: viewerId,
        eventType: AnalyticsEventType.profileView,
        properties: {
          'viewed_user_id': profileUserId,
          'source': source ?? 'unknown',
          if (context != null) ...context,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);

      // Also update profile views counter
      await _client.rpc('increment_profile_views', params: {
        'profile_user_id': profileUserId,
      });
    } catch (e) {
      // Don't throw for analytics failures
      print('Failed to track profile view: $e');
    }
  }

  @override
  Future<void> trackProfileUpdate(String userId, String section, Map<String, dynamic> changes) async {
    try {
      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: userId,
        eventType: AnalyticsEventType.profileUpdate,
        properties: {
          'section': section,
          'changes': changes,
          'change_count': changes.length,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);
      
      // Update profile completion if needed
      await _checkAndUpdateProfileCompletion(userId, section);
    } catch (e) {
      print('Failed to track profile update: $e');
    }
  }

  @override
  Future<void> trackAvatarUpload(String userId, {String? fileName, int? fileSize}) async {
    try {
      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: userId,
        eventType: AnalyticsEventType.avatarUpload,
        properties: {
          'file_name': fileName,
          'file_size': fileSize,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);
      await updateProfileCompletion(userId, 'avatar', true);
    } catch (e) {
      print('Failed to track avatar upload: $e');
    }
  }

  @override
  Future<void> trackSportProfileAction(String userId, String action, String sportId) async {
    try {
      final eventType = switch (action) {
        'add' => AnalyticsEventType.sportProfileAdd,
        'update' => AnalyticsEventType.sportProfileUpdate,
        'remove' => AnalyticsEventType.sportProfileRemove,
        _ => AnalyticsEventType.sportProfileUpdate,
      };

      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: userId,
        eventType: eventType,
        properties: {
          'action': action,
          'sport_id': sportId,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);
    } catch (e) {
      print('Failed to track sport profile action: $e');
    }
  }

  @override
  Future<void> trackSettingsUpdate(String userId, String category, Map<String, dynamic> changes) async {
    try {
      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: userId,
        eventType: AnalyticsEventType.settingsUpdate,
        properties: {
          'category': category,
          'changes': changes,
          'change_count': changes.length,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);
    } catch (e) {
      print('Failed to track settings update: $e');
    }
  }

  @override
  Future<void> trackPreferencesUpdate(String userId, String category, dynamic newValue) async {
    try {
      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: userId,
        eventType: AnalyticsEventType.preferencesUpdate,
        properties: {
          'category': category,
          'new_value': newValue,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);
    } catch (e) {
      print('Failed to track preferences update: $e');
    }
  }

  @override
  Future<void> trackSearch(String userId, String query, int resultsCount) async {
    try {
      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: userId,
        eventType: AnalyticsEventType.search,
        properties: {
          'query': query,
          'results_count': resultsCount,
          'query_length': query.length,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);
    } catch (e) {
      print('Failed to track search: $e');
    }
  }

  @override
  Future<void> trackMatchmakingRequest(String userId, Map<String, dynamic> criteria) async {
    try {
      final event = AnalyticsEvent(
        eventId: _generateEventId(),
        userId: userId,
        eventType: AnalyticsEventType.matchmakingRequest,
        properties: {
          'criteria': criteria,
          'criteria_count': criteria.length,
        },
        timestamp: DateTime.now(),
      );
      
      await trackEvent(event);
    } catch (e) {
      print('Failed to track matchmaking request: $e');
    }
  }

  @override
  Future<ProfileCompletionMetrics> getProfileCompletion(String userId) async {
    try {
      final response = await _client
          .from(_profileCompletionTable)
          .select()
          .eq('user_id', userId)
          .single();

      return ProfileCompletionMetrics.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return await _calculateInitialProfileCompletion(userId);
      }
      throw AnalyticsDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to get profile completion: $e',
        code: 'PROFILE_COMPLETION_ERROR',
      );
    }
  }

  @override
  Future<void> updateProfileCompletion(String userId, String section, bool completed) async {
    try {
      await _client.rpc('update_profile_completion', params: {
        'user_id_param': userId,
        'section_param': section,
        'completed_param': completed,
      });
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to update profile completion: $e',
        code: 'PROFILE_COMPLETION_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<Map<String, double>> getCompletionTrends(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_completion_trends', params: {
        'user_id_param': userId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return Map<String, double>.from(response ?? {});
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to get completion trends: $e',
        code: 'COMPLETION_TRENDS_ERROR',
      );
    }
  }

  @override
  Future<List<String>> getIncompleteProfileSuggestions(String userId) async {
    try {
      final completion = await getProfileCompletion(userId);
      return completion.missingSections;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<EngagementMetrics> getEngagementMetrics(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_engagement_metrics', params: {
        'user_id_param': userId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return EngagementMetrics.fromJson(response);
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to get engagement metrics: $e',
        code: 'ENGAGEMENT_METRICS_ERROR',
      );
    }
  }

  @override
  Future<Map<String, int>> getFeatureUsageStats(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_feature_usage_stats', params: {
        'user_id_param': userId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return Map<String, int>.from(response ?? {});
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to get feature usage stats: $e',
        code: 'FEATURE_USAGE_ERROR',
      );
    }
  }

  @override
  Future<double> calculateEngagementScore(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final metrics = await getEngagementMetrics(userId, startDate, endDate);
      return metrics.engagementScore;
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to calculate engagement score: $e',
        code: 'ENGAGEMENT_SCORE_ERROR',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEngagementTrends(String userId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final response = await _client.rpc('get_engagement_trends', params: {
        'user_id_param': userId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
        'days_param': days,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to get engagement trends: $e',
        code: 'ENGAGEMENT_TRENDS_ERROR',
      );
    }
  }

  @override
  Future<void> startSession(String userId, String sessionId, {
    String? deviceId,
    String? platform,
    Map<String, dynamic>? context,
  }) async {
    try {
      await _client.from(_sessionsTable).insert({
        'session_id': sessionId,
        'user_id': userId,
        'device_id': deviceId,
        'platform': platform,
        'context': context,
        'start_time': DateTime.now().toIso8601String(),
        'is_active': true,
      });
    } catch (e) {
      print('Failed to start session: $e');
    }
  }

  @override
  Future<void> endSession(String userId, String sessionId, Duration duration) async {
    try {
      await _client
          .from(_sessionsTable)
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'duration_seconds': duration.inSeconds,
            'is_active': false,
          })
          .eq('session_id', sessionId)
          .eq('user_id', userId);
    } catch (e) {
      print('Failed to end session: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSessionStats(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_session_stats', params: {
        'user_id_param': userId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return response ?? {};
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to get session stats: $e',
        code: 'SESSION_STATS_ERROR',
      );
    }
  }

  // Additional implementation methods...
  @override
  Future<List<Map<String, dynamic>>> getMostViewedProfiles(int limit, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_most_viewed_profiles', params: {
        'limit_param': limit,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPopularSports(int limit, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_popular_sports', params: {
        'limit_param': limit,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTrendingLocations(int limit, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_trending_locations', params: {
        'limit_param': limit,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchTrends(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_search_trends', params: {
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getUserBehaviorPattern(String userId) async {
    try {
      final response = await _client.rpc('get_user_behavior_pattern', params: {
        'user_id_param': userId,
      });

      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<List<String>> getPredictedInterests(String userId) async {
    try {
      final response = await _client.rpc('get_predicted_interests', params: {
        'user_id_param': userId,
      });

      return List<String>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getPersonalizationInsights(String userId) async {
    try {
      final response = await _client.rpc('get_personalization_insights', params: {
        'user_id_param': userId,
      });

      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<double> calculateUserRetentionScore(String userId) async {
    try {
      final response = await _client.rpc('calculate_retention_score', params: {
        'user_id_param': userId,
      });

      return (response ?? 0.0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<Map<String, dynamic>> generateUserReport(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('generate_user_report', params: {
        'user_id_param': userId,
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return response ?? {};
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to generate user report: $e',
        code: 'USER_REPORT_ERROR',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemWideMetrics(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_system_wide_metrics', params: {
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTopPerformingFeatures(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_top_performing_features', params: {
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getConversionFunnelData(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_conversion_funnel_data', params: {
        'start_date_param': startDate.toIso8601String(),
        'end_date_param': endDate.toIso8601String(),
      });

      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> exportUserAnalytics(String userId) async {
    try {
      final response = await _client.rpc('export_user_analytics', params: {
        'user_id_param': userId,
      });

      return response ?? {};
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to export user analytics: $e',
        code: 'EXPORT_ERROR',
      );
    }
  }

  @override
  Future<void> deleteUserAnalytics(String userId) async {
    try {
      await _client.rpc('delete_user_analytics', params: {
        'user_id_param': userId,
      });
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to delete user analytics: $e',
        code: 'DELETE_ERROR',
      );
    }
  }

  @override
  Future<void> anonymizeUserData(String userId) async {
    try {
      await _client.rpc('anonymize_user_data', params: {
        'user_id_param': userId,
      });
    } catch (e) {
      throw AnalyticsDataSourceException(
        message: 'Failed to anonymize user data: $e',
        code: 'ANONYMIZE_ERROR',
      );
    }
  }

  // Helper methods
  String _generateEventId() {
    return 'evt_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt((DateTime.now().millisecondsSinceEpoch % chars.length))
    ));
  }

  Future<ProfileCompletionMetrics> _calculateInitialProfileCompletion(String userId) async {
    // This would calculate initial profile completion based on profile data
    final sections = {
      'basic_info': false,
      'avatar': false,
      'bio': false,
      'sports': false,
      'preferences': false,
      'availability': false,
    };

    const completionPercentage = 0.0;
    final missingSections = sections.keys.toList();

    final metrics = ProfileCompletionMetrics(
      userId: userId,
      completionPercentage: completionPercentage,
      completedSections: sections,
      missingSections: missingSections,
      sectionCompletionDates: {},
      lastUpdated: DateTime.now(),
    );

    // Save initial metrics
    await _client.from(_profileCompletionTable).insert(metrics.toJson());

    return metrics;
  }

  Future<void> _checkAndUpdateProfileCompletion(String userId, String section) async {
    // This would check if the section is now complete and update metrics
    await updateProfileCompletion(userId, section, true);
  }
}
