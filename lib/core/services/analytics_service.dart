import 'package:flutter/foundation.dart';

/// Core analytics service for tracking app-wide events and metrics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Initialized');
    }
  }
  
  /// Track an event with properties
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Event: $eventName, Properties: $properties');
    }
  }
  
  /// Track user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: User Properties: $properties');
    }
  }
  
  /// Track screen view
  Future<void> trackScreen(String screenName) async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Screen: $screenName');
    }
  }
  
  /// Track timing event
  Future<void> trackTiming(String category, String variable, int value) async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Timing: $category/$variable = ${value}ms');
    }
  }
  
  /// Track error
  Future<void> trackError(String error, {String? stackTrace}) async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Error: $error, Stack: $stackTrace');
    }
  }
  
  /// Flush analytics data
  Future<void> flush() async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Flushed');
    }
  }
  
  /// Reset analytics data
  Future<void> reset() async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Reset');
    }
  }
  
  /// Set user ID
  Future<void> setUserId(String userId) async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: User ID: $userId');
    }
  }
  
  /// Enable/disable analytics
  Future<void> setEnabled(bool enabled) async {
    if (kDebugMode) {
      debugPrint('AnalyticsService: Enabled: $enabled');
    }
  }
  
  /// Get achievement analytics data
  Future<AchievementAnalyticsData> getAchievementAnalytics() async {
    // Mock data for now
    return AchievementAnalyticsData(
      totalAchievements: 100,
      completedAchievements: 75,
      completionRate: 0.75,
      averageTimeToComplete: const Duration(days: 7),
      categoryBreakdown: {'gaming': 40, 'social': 35},
      difficultyDistribution: {'easy': 30, 'medium': 25, 'hard': 20},
    );
  }
  
  /// Get engagement analytics data
  Future<EngagementAnalyticsData> getEngagementAnalytics() async {
    // Mock data for now
    return EngagementAnalyticsData(
      dailyActiveUsers: 1000,
      weeklyActiveUsers: 5000,
      monthlyActiveUsers: 15000,
      averageSessionDuration: const Duration(minutes: 15),
      retentionRate: 0.65,
      churnRate: 0.12,
    );
  }
  
  /// Get points analytics data
  Future<PointsAnalyticsData> getPointsAnalytics() async {
    // Mock data for now
    return PointsAnalyticsData(
      totalPointsAwarded: 500000,
      averagePointsPerUser: 850,
      dailyPointsRate: 1200.0,
      inflationRate: 0.02,
      distributionBuckets: {'0-100': 200, '101-500': 300, '501+': 100},
      pointsSources: {'achievements': 60, 'daily': 25, 'social': 15},
    );
  }
}

/// Analytics data classes
class AchievementAnalyticsData {
  final int totalAchievements;
  final int completedAchievements;
  final double completionRate;
  final Duration averageTimeToComplete;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> difficultyDistribution;
  
  AchievementAnalyticsData({
    required this.totalAchievements,
    required this.completedAchievements,
    required this.completionRate,
    required this.averageTimeToComplete,
    required this.categoryBreakdown,
    required this.difficultyDistribution,
  });
}

class EngagementAnalyticsData {
  final int dailyActiveUsers;
  final int weeklyActiveUsers;
  final int monthlyActiveUsers;
  final Duration averageSessionDuration;
  final double retentionRate;
  final double churnRate;
  
  EngagementAnalyticsData({
    required this.dailyActiveUsers,
    required this.weeklyActiveUsers,
    required this.monthlyActiveUsers,
    required this.averageSessionDuration,
    required this.retentionRate,
    required this.churnRate,
  });
}

class PointsAnalyticsData {
  final int totalPointsAwarded;
  final int averagePointsPerUser;
  final double dailyPointsRate;
  final double inflationRate;
  final Map<String, int> distributionBuckets;
  final Map<String, int> pointsSources;

  PointsAnalyticsData({
    required this.totalPointsAwarded,
    required this.averagePointsPerUser,
    required this.dailyPointsRate,
    required this.inflationRate,
    required this.distributionBuckets,
    required this.pointsSources,
  });
}