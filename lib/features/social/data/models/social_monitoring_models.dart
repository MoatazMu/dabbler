/// Data models for social monitoring dashboard
library;

/// Main social monitoring dashboard data structure
class SocialMonitoringDashboardData {
  final MonitoringSystemStatus systemStatus;
  final List<MonitoringAlert> alerts;
  final List<MonitoringRecommendation> recommendations;
  final HealthMetrics healthMetrics;
  final PerformanceMetrics performanceMetrics;
  final ErrorMetrics errorMetrics;
  final AbuseMetrics abuseMetrics;
  final DashboardSummary summary;
  final DateTime lastUpdated;

  const SocialMonitoringDashboardData({
    required this.systemStatus,
    required this.alerts,
    required this.recommendations,
    required this.healthMetrics,
    required this.performanceMetrics,
    required this.errorMetrics,
    required this.abuseMetrics,
    required this.summary,
    required this.lastUpdated,
  });

  factory SocialMonitoringDashboardData.fromJson(Map<String, dynamic> json) {
    return SocialMonitoringDashboardData(
      systemStatus: MonitoringSystemStatus.fromJson(json['systemStatus'] ?? {}),
      alerts: (json['alerts'] as List<dynamic>? ?? [])
          .map((a) => MonitoringAlert.fromJson(a))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .map((r) => MonitoringRecommendation.fromJson(r))
          .toList(),
      healthMetrics: HealthMetrics.fromJson(json['healthMetrics'] ?? {}),
      performanceMetrics: PerformanceMetrics.fromJson(json['performanceMetrics'] ?? {}),
      errorMetrics: ErrorMetrics.fromJson(json['errorMetrics'] ?? {}),
      abuseMetrics: AbuseMetrics.fromJson(json['abuseMetrics'] ?? {}),
      summary: DashboardSummary.fromJson(json['summary'] ?? {}),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systemStatus': systemStatus.toJson(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'healthMetrics': healthMetrics.toJson(),
      'performanceMetrics': performanceMetrics.toJson(),
      'errorMetrics': errorMetrics.toJson(),
      'abuseMetrics': abuseMetrics.toJson(),
      'summary': summary.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Real-time monitoring status
class RealTimeMonitoringStatus {
  final String status;
  final DateTime timestamp;
  final Map<String, dynamic> metrics;
  final List<String> activeAlerts;

  const RealTimeMonitoringStatus({
    required this.status,
    required this.timestamp,
    required this.metrics,
    required this.activeAlerts,
  });

  factory RealTimeMonitoringStatus.fromJson(Map<String, dynamic> json) {
    return RealTimeMonitoringStatus(
      status: json['status'] ?? 'unknown',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metrics: json['metrics'] ?? {},
      activeAlerts: List<String>.from(json['activeAlerts'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics,
      'activeAlerts': activeAlerts,
    };
  }
}

/// System status information
class MonitoringSystemStatus {
  final String overall;
  final String feed;
  final String messaging;
  final String notifications;
  final String storage;
  final double uptime;

  const MonitoringSystemStatus({
    required this.overall,
    required this.feed,
    required this.messaging,
    required this.notifications,
    required this.storage,
    required this.uptime,
  });

  factory MonitoringSystemStatus.fromJson(Map<String, dynamic> json) {
    return MonitoringSystemStatus(
      overall: json['overall'] ?? 'unknown',
      feed: json['feed'] ?? 'unknown',
      messaging: json['messaging'] ?? 'unknown',
      notifications: json['notifications'] ?? 'unknown',
      storage: json['storage'] ?? 'unknown',
      uptime: (json['uptime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'feed': feed,
      'messaging': messaging,
      'notifications': notifications,
      'storage': storage,
      'uptime': uptime,
    };
  }
}

/// Monitoring alert
class MonitoringAlert {
  final String id;
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const MonitoringAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.metadata,
  });

  factory MonitoringAlert.fromJson(Map<String, dynamic> json) {
    return MonitoringAlert(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'info',
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Monitoring recommendation
class MonitoringRecommendation {
  final String id;
  final String category;
  final String priority;
  final String title;
  final String description;
  final List<String> actionItems;

  const MonitoringRecommendation({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionItems,
  });

  factory MonitoringRecommendation.fromJson(Map<String, dynamic> json) {
    return MonitoringRecommendation(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'low',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      actionItems: List<String>.from(json['actionItems'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'priority': priority,
      'title': title,
      'description': description,
      'actionItems': actionItems,
    };
  }
}

/// Dashboard summary
class DashboardSummary {
  final int totalUsers;
  final int activeUsers;
  final int totalPosts;
  final int totalInteractions;
  final double systemHealth;
  final int criticalAlerts;

  const DashboardSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPosts,
    required this.totalInteractions,
    required this.systemHealth,
    required this.criticalAlerts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalPosts: json['totalPosts'] ?? 0,
      totalInteractions: json['totalInteractions'] ?? 0,
      systemHealth: (json['systemHealth'] ?? 0.0).toDouble(),
      criticalAlerts: json['criticalAlerts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalPosts': totalPosts,
      'totalInteractions': totalInteractions,
      'systemHealth': systemHealth,
      'criticalAlerts': criticalAlerts,
    };
  }
}

// Health Metrics
class HealthMetrics {
  final HealthScores healthScores;
  final ActiveUserMetrics activeUserMetrics;
  final ContentMetrics contentMetrics;
  final EngagementMetrics engagementMetrics;

  const HealthMetrics({
    required this.healthScores,
    required this.activeUserMetrics,
    required this.contentMetrics,
    required this.engagementMetrics,
  });

  factory HealthMetrics.fromJson(Map<String, dynamic> json) {
    return HealthMetrics(
      healthScores: HealthScores.fromJson(json['healthScores'] ?? {}),
      activeUserMetrics: ActiveUserMetrics.fromJson(json['activeUserMetrics'] ?? {}),
      contentMetrics: ContentMetrics.fromJson(json['contentMetrics'] ?? {}),
      engagementMetrics: EngagementMetrics.fromJson(json['engagementMetrics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'healthScores': healthScores.toJson(),
      'activeUserMetrics': activeUserMetrics.toJson(),
      'contentMetrics': contentMetrics.toJson(),
      'engagementMetrics': engagementMetrics.toJson(),
    };
  }
}

class HealthScores {
  final double overall;
  final double feed;
  final double messaging;
  final double userEngagement;
  final double contentQuality;

  const HealthScores({
    required this.overall,
    required this.feed,
    required this.messaging,
    required this.userEngagement,
    required this.contentQuality,
  });

  factory HealthScores.fromJson(Map<String, dynamic> json) {
    return HealthScores(
      overall: (json['overall'] ?? 0.0).toDouble(),
      feed: (json['feed'] ?? 0.0).toDouble(),
      messaging: (json['messaging'] ?? 0.0).toDouble(),
      userEngagement: (json['userEngagement'] ?? 0.0).toDouble(),
      contentQuality: (json['contentQuality'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'feed': feed,
      'messaging': messaging,
      'userEngagement': userEngagement,
      'contentQuality': contentQuality,
    };
  }
}

class ActiveUserMetrics {
  final int totalActive;
  final int dailyActive;
  final int weeklyActive;
  final int monthlyActive;
  final double retentionRate;
  final double churnRate;

  const ActiveUserMetrics({
    required this.totalActive,
    required this.dailyActive,
    required this.weeklyActive,
    required this.monthlyActive,
    required this.retentionRate,
    required this.churnRate,
  });

  factory ActiveUserMetrics.fromJson(Map<String, dynamic> json) {
    return ActiveUserMetrics(
      totalActive: json['totalActive'] ?? 0,
      dailyActive: json['dailyActive'] ?? 0,
      weeklyActive: json['weeklyActive'] ?? 0,
      monthlyActive: json['monthlyActive'] ?? 0,
      retentionRate: (json['retentionRate'] ?? 0.0).toDouble(),
      churnRate: (json['churnRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalActive': totalActive,
      'dailyActive': dailyActive,
      'weeklyActive': weeklyActive,
      'monthlyActive': monthlyActive,
      'retentionRate': retentionRate,
      'churnRate': churnRate,
    };
  }
}

class ContentMetrics {
  final int totalPosts;
  final int postsToday;
  final int averagePostsPerUser;
  final double averagePostLength;
  final int mediaUploads;
  final double contentQualityScore;

  const ContentMetrics({
    required this.totalPosts,
    required this.postsToday,
    required this.averagePostsPerUser,
    required this.averagePostLength,
    required this.mediaUploads,
    required this.contentQualityScore,
  });

  factory ContentMetrics.fromJson(Map<String, dynamic> json) {
    return ContentMetrics(
      totalPosts: json['totalPosts'] ?? 0,
      postsToday: json['postsToday'] ?? 0,
      averagePostsPerUser: json['averagePostsPerUser'] ?? 0,
      averagePostLength: (json['averagePostLength'] ?? 0.0).toDouble(),
      mediaUploads: json['mediaUploads'] ?? 0,
      contentQualityScore: (json['contentQualityScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPosts': totalPosts,
      'postsToday': postsToday,
      'averagePostsPerUser': averagePostsPerUser,
      'averagePostLength': averagePostLength,
      'mediaUploads': mediaUploads,
      'contentQualityScore': contentQualityScore,
    };
  }
}

class EngagementMetrics {
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final double averageEngagementRate;
  final double peakEngagementTime;
  final Map<String, int> engagementByType;

  const EngagementMetrics({
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.averageEngagementRate,
    required this.peakEngagementTime,
    required this.engagementByType,
  });

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EngagementMetrics(
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      totalShares: json['totalShares'] ?? 0,
      averageEngagementRate: (json['averageEngagementRate'] ?? 0.0).toDouble(),
      peakEngagementTime: (json['peakEngagementTime'] ?? 0.0).toDouble(),
      engagementByType: Map<String, int>.from(json['engagementByType'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'totalShares': totalShares,
      'averageEngagementRate': averageEngagementRate,
      'peakEngagementTime': peakEngagementTime,
      'engagementByType': engagementByType,
    };
  }
}

// Performance Metrics
class PerformanceMetrics {
  final FeedPerformanceMetrics feedPerformance;
  final MessagingPerformanceMetrics messagingPerformance;
  final SystemHealthMetrics systemHealth;

  const PerformanceMetrics({
    required this.feedPerformance,
    required this.messagingPerformance,
    required this.systemHealth,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      feedPerformance: FeedPerformanceMetrics.fromJson(json['feedPerformance'] ?? {}),
      messagingPerformance: MessagingPerformanceMetrics.fromJson(json['messagingPerformance'] ?? {}),
      systemHealth: SystemHealthMetrics.fromJson(json['systemHealth'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedPerformance': feedPerformance.toJson(),
      'messagingPerformance': messagingPerformance.toJson(),
      'systemHealth': systemHealth.toJson(),
    };
  }
}

class FeedPerformanceMetrics {
  final double averageLoadTime;
  final double successRate;
  final int totalRequests;
  final int failedRequests;
  final double cacheHitRate;
  final int postsDisplayed;

  const FeedPerformanceMetrics({
    required this.averageLoadTime,
    required this.successRate,
    required this.totalRequests,
    required this.failedRequests,
    required this.cacheHitRate,
    required this.postsDisplayed,
  });

  factory FeedPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return FeedPerformanceMetrics(
      averageLoadTime: (json['averageLoadTime'] ?? 0.0).toDouble(),
      successRate: (json['successRate'] ?? 0.0).toDouble(),
      totalRequests: json['totalRequests'] ?? 0,
      failedRequests: json['failedRequests'] ?? 0,
      cacheHitRate: (json['cacheHitRate'] ?? 0.0).toDouble(),
      postsDisplayed: json['postsDisplayed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageLoadTime': averageLoadTime,
      'successRate': successRate,
      'totalRequests': totalRequests,
      'failedRequests': failedRequests,
      'cacheHitRate': cacheHitRate,
      'postsDisplayed': postsDisplayed,
    };
  }
}

class MessagingPerformanceMetrics {
  final double messageDeliveryRate;
  final double averageDeliveryTime;
  final int totalMessages;
  final int failedMessages;
  final double realTimeSuccessRate;

  const MessagingPerformanceMetrics({
    required this.messageDeliveryRate,
    required this.averageDeliveryTime,
    required this.totalMessages,
    required this.failedMessages,
    required this.realTimeSuccessRate,
  });

  factory MessagingPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return MessagingPerformanceMetrics(
      messageDeliveryRate: (json['messageDeliveryRate'] ?? 0.0).toDouble(),
      averageDeliveryTime: (json['averageDeliveryTime'] ?? 0.0).toDouble(),
      totalMessages: json['totalMessages'] ?? 0,
      failedMessages: json['failedMessages'] ?? 0,
      realTimeSuccessRate: (json['realTimeSuccessRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageDeliveryRate': messageDeliveryRate,
      'averageDeliveryTime': averageDeliveryTime,
      'totalMessages': totalMessages,
      'failedMessages': failedMessages,
      'realTimeSuccessRate': realTimeSuccessRate,
    };
  }
}

class SystemHealthMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double networkLatency;
  final double databaseResponseTime;
  final int activeConnections;

  const SystemHealthMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkLatency,
    required this.databaseResponseTime,
    required this.activeConnections,
  });

  factory SystemHealthMetrics.fromJson(Map<String, dynamic> json) {
    return SystemHealthMetrics(
      cpuUsage: (json['cpuUsage'] ?? 0.0).toDouble(),
      memoryUsage: (json['memoryUsage'] ?? 0.0).toDouble(),
      diskUsage: (json['diskUsage'] ?? 0.0).toDouble(),
      networkLatency: (json['networkLatency'] ?? 0.0).toDouble(),
      databaseResponseTime: (json['databaseResponseTime'] ?? 0.0).toDouble(),
      activeConnections: json['activeConnections'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'diskUsage': diskUsage,
      'networkLatency': networkLatency,
      'databaseResponseTime': databaseResponseTime,
      'activeConnections': activeConnections,
    };
  }
}

// Error Metrics
class ErrorMetrics {
  final OverallErrorStats overallStats;
  final SocialErrorMetrics socialErrors;
  final List<SocialError> criticalErrors;

  const ErrorMetrics({
    required this.overallStats,
    required this.socialErrors,
    required this.criticalErrors,
  });

  factory ErrorMetrics.fromJson(Map<String, dynamic> json) {
    return ErrorMetrics(
      overallStats: OverallErrorStats.fromJson(json['overallStats'] ?? {}),
      socialErrors: SocialErrorMetrics.fromJson(json['socialErrors'] ?? {}),
      criticalErrors: (json['criticalErrors'] as List<dynamic>? ?? [])
          .map((e) => SocialError.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallStats': overallStats.toJson(),
      'socialErrors': socialErrors.toJson(),
      'criticalErrors': criticalErrors.map((e) => e.toJson()).toList(),
    };
  }
}

class OverallErrorStats {
  final int totalErrors;
  final int errorsToday;
  final double errorRate;
  final Map<String, int> errorsByType;
  final Map<String, int> errorsByComponent;

  const OverallErrorStats({
    required this.totalErrors,
    required this.errorsToday,
    required this.errorRate,
    required this.errorsByType,
    required this.errorsByComponent,
  });

  factory OverallErrorStats.fromJson(Map<String, dynamic> json) {
    return OverallErrorStats(
      totalErrors: json['totalErrors'] ?? 0,
      errorsToday: json['errorsToday'] ?? 0,
      errorRate: (json['errorRate'] ?? 0.0).toDouble(),
      errorsByType: Map<String, int>.from(json['errorsByType'] ?? {}),
      errorsByComponent: Map<String, int>.from(json['errorsByComponent'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalErrors': totalErrors,
      'errorsToday': errorsToday,
      'errorRate': errorRate,
      'errorsByType': errorsByType,
      'errorsByComponent': errorsByComponent,
    };
  }
}

class SocialErrorMetrics {
  final int feedErrors;
  final int messagingErrors;
  final int notificationErrors;
  final int authErrors;
  final int storageErrors;
  final double averageResolutionTime;

  const SocialErrorMetrics({
    required this.feedErrors,
    required this.messagingErrors,
    required this.notificationErrors,
    required this.authErrors,
    required this.storageErrors,
    required this.averageResolutionTime,
  });

  factory SocialErrorMetrics.fromJson(Map<String, dynamic> json) {
    return SocialErrorMetrics(
      feedErrors: json['feedErrors'] ?? 0,
      messagingErrors: json['messagingErrors'] ?? 0,
      notificationErrors: json['notificationErrors'] ?? 0,
      authErrors: json['authErrors'] ?? 0,
      storageErrors: json['storageErrors'] ?? 0,
      averageResolutionTime: (json['averageResolutionTime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedErrors': feedErrors,
      'messagingErrors': messagingErrors,
      'notificationErrors': notificationErrors,
      'authErrors': authErrors,
      'storageErrors': storageErrors,
      'averageResolutionTime': averageResolutionTime,
    };
  }
}

class SocialError {
  final String id;
  final String type;
  final String severity;
  final String component;
  final String message;
  final String stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final bool resolved;

  const SocialError({
    required this.id,
    required this.type,
    required this.severity,
    required this.component,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    required this.context,
    required this.resolved,
  });

  factory SocialError.fromJson(Map<String, dynamic> json) {
    return SocialError(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'low',
      component: json['component'] ?? '',
      message: json['message'] ?? '',
      stackTrace: json['stackTrace'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      context: json['context'] ?? {},
      resolved: json['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'component': component,
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'resolved': resolved,
    };
  }
}

// Abuse Metrics
class AbuseMetrics {
  final SpamDetectionMetrics spamDetection;
  final HarassmentDetectionMetrics harassmentDetection;
  final BotDetectionMetrics botDetection;
  final ModerationMetrics moderation;

  const AbuseMetrics({
    required this.spamDetection,
    required this.harassmentDetection,
    required this.botDetection,
    required this.moderation,
  });

  factory AbuseMetrics.fromJson(Map<String, dynamic> json) {
    return AbuseMetrics(
      spamDetection: SpamDetectionMetrics.fromJson(json['spamDetection'] ?? {}),
      harassmentDetection: HarassmentDetectionMetrics.fromJson(json['harassmentDetection'] ?? {}),
      botDetection: BotDetectionMetrics.fromJson(json['botDetection'] ?? {}),
      moderation: ModerationMetrics.fromJson(json['moderation'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spamDetection': spamDetection.toJson(),
      'harassmentDetection': harassmentDetection.toJson(),
      'botDetection': botDetection.toJson(),
      'moderation': moderation.toJson(),
    };
  }
}

class SpamDetectionMetrics {
  final int totalChecked;
  final int spamDetected;
  final int falsePositives;
  final double accuracy;
  final double precision;
  final double recall;

  const SpamDetectionMetrics({
    required this.totalChecked,
    required this.spamDetected,
    required this.falsePositives,
    required this.accuracy,
    required this.precision,
    required this.recall,
  });

  factory SpamDetectionMetrics.fromJson(Map<String, dynamic> json) {
    return SpamDetectionMetrics(
      totalChecked: json['totalChecked'] ?? 0,
      spamDetected: json['spamDetected'] ?? 0,
      falsePositives: json['falsePositives'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      precision: (json['precision'] ?? 0.0).toDouble(),
      recall: (json['recall'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalChecked': totalChecked,
      'spamDetected': spamDetected,
      'falsePositives': falsePositives,
      'accuracy': accuracy,
      'precision': precision,
      'recall': recall,
    };
  }
}

class HarassmentDetectionMetrics {
  final int totalChecked;
  final int harassmentDetected;
  final int escalatedCases;
  final double detectionRate;
  final double averageResponseTime;

  const HarassmentDetectionMetrics({
    required this.totalChecked,
    required this.harassmentDetected,
    required this.escalatedCases,
    required this.detectionRate,
    required this.averageResponseTime,
  });

  factory HarassmentDetectionMetrics.fromJson(Map<String, dynamic> json) {
    return HarassmentDetectionMetrics(
      totalChecked: json['totalChecked'] ?? 0,
      harassmentDetected: json['harassmentDetected'] ?? 0,
      escalatedCases: json['escalatedCases'] ?? 0,
      detectionRate: (json['detectionRate'] ?? 0.0).toDouble(),
      averageResponseTime: (json['averageResponseTime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalChecked': totalChecked,
      'harassmentDetected': harassmentDetected,
      'escalatedCases': escalatedCases,
      'detectionRate': detectionRate,
      'averageResponseTime': averageResponseTime,
    };
  }
}

class BotDetectionMetrics {
  final int totalAnalyzed;
  final int botsDetected;
  final int suspiciousAccounts;
  final double detectionAccuracy;
  final Map<String, int> botTypesDetected;

  const BotDetectionMetrics({
    required this.totalAnalyzed,
    required this.botsDetected,
    required this.suspiciousAccounts,
    required this.detectionAccuracy,
    required this.botTypesDetected,
  });

  factory BotDetectionMetrics.fromJson(Map<String, dynamic> json) {
    return BotDetectionMetrics(
      totalAnalyzed: json['totalAnalyzed'] ?? 0,
      botsDetected: json['botsDetected'] ?? 0,
      suspiciousAccounts: json['suspiciousAccounts'] ?? 0,
      detectionAccuracy: (json['detectionAccuracy'] ?? 0.0).toDouble(),
      botTypesDetected: Map<String, int>.from(json['botTypesDetected'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAnalyzed': totalAnalyzed,
      'botsDetected': botsDetected,
      'suspiciousAccounts': suspiciousAccounts,
      'detectionAccuracy': detectionAccuracy,
      'botTypesDetected': botTypesDetected,
    };
  }
}

class ModerationMetrics {
  final int totalReports;
  final int actionsToday;
  final int contentRemoved;
  final int accountsSuspended;
  final double averageResponseTime;
  final Map<String, int> moderationActionsByType;

  const ModerationMetrics({
    required this.totalReports,
    required this.actionsToday,
    required this.contentRemoved,
    required this.accountsSuspended,
    required this.averageResponseTime,
    required this.moderationActionsByType,
  });

  factory ModerationMetrics.fromJson(Map<String, dynamic> json) {
    return ModerationMetrics(
      totalReports: json['totalReports'] ?? 0,
      actionsToday: json['actionsToday'] ?? 0,
      contentRemoved: json['contentRemoved'] ?? 0,
      accountsSuspended: json['accountsSuspended'] ?? 0,
      averageResponseTime: (json['averageResponseTime'] ?? 0.0).toDouble(),
      moderationActionsByType: Map<String, int>.from(json['moderationActionsByType'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReports': totalReports,
      'actionsToday': actionsToday,
      'contentRemoved': contentRemoved,
      'accountsSuspended': accountsSuspended,
      'averageResponseTime': averageResponseTime,
      'moderationActionsByType': moderationActionsByType,
    };
  }
}
