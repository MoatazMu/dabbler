
import 'dart:async';
import 'dart:math' as math;
import '../../../core/utils/either.dart';
import '../../../core/analytics/analytics_service.dart';





/// Service for monitoring performance of social features
class SocialPerformanceMonitoringService {
  final AnalyticsService _analytics;

  // Performance monitoring timers
  Timer? _performanceCheckTimer;
  Timer? _performanceAggregationTimer;
  Timer? _performanceReportTimer;

  // Performance data caches
  final Map<String, dynamic> _metricsCache = {};
  final Map<String, List<PerformanceSnapshot>> _snapshotHistory = {};
  final Map<String, DateTime> _lastMeasurements = {};

  // Active measurements
  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, List<int>> _responseTimeBuffers = {};
  final Map<String, int> _requestCounts = {};

  // Configuration
  static const Duration _checkInterval = Duration(minutes: 1);
  static const Duration _aggregationInterval = Duration(minutes: 15);
  static const Duration _reportInterval = Duration(hours: 1);
  static const int _maxBufferSize = 1000;
  static const int _maxHistoryDays = 30;

  SocialPerformanceMonitoringService({
    required AnalyticsService analytics,
  })  : _analytics = analytics {
    _initializeMonitoring();
  }

  /// Initialize performance monitoring
  void _initializeMonitoring() {
    // Real-time performance checks every minute
    _performanceCheckTimer = Timer.periodic(_checkInterval, (_) async {
      await _performPerformanceCheck();
    });

    // Aggregation every 15 minutes
    _performanceAggregationTimer = Timer.periodic(_aggregationInterval, (_) async {
      await _aggregatePerformanceData();
    });

    // Reports every hour
    _performanceReportTimer = Timer.periodic(_reportInterval, (_) async {
      await _generatePerformanceReport();
    });
  }

  /// Start measuring an operation
  String startMeasurement(String operationType, {Map<String, dynamic>? metadata}) {
    final measurementId = '${operationType}_${DateTime.now().millisecondsSinceEpoch}';
    final stopwatch = Stopwatch()..start();
    _activeTimers[measurementId] = stopwatch;

    // Track the operation start
    _analytics.trackEvent('performance_measurement_started', {
      'operation_type': operationType,
      'measurement_id': measurementId,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });

    return measurementId;
  }

  /// End a measurement and record performance data
  void endMeasurement(
    String measurementId, 
    String operationType,
    {bool wasSuccessful = true, String? errorType, Map<String, dynamic>? metadata}
  ) {
    final stopwatch = _activeTimers.remove(measurementId);
    if (stopwatch == null) return;

    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;

    // Add to response time buffer
    _responseTimeBuffers.putIfAbsent(operationType, () => <int>[]);
    final buffer = _responseTimeBuffers[operationType]!;
    
    if (buffer.length >= _maxBufferSize) {
      buffer.removeAt(0);
    }
    buffer.add(duration);

    // Increment request count
    _requestCounts[operationType] = (_requestCounts[operationType] ?? 0) + 1;

    // Record performance data
    _recordPerformanceData(PerformanceDataPoint(
      operationType: operationType,
      measurementId: measurementId,
      timestamp: DateTime.now(),
      responseTime: Duration(milliseconds: duration),
      wasSuccessful: wasSuccessful,
      errorType: errorType,
      metadata: metadata ?? {},
    ));

    // Track the operation completion
    _analytics.trackEvent('performance_measurement_completed', {
      'operation_type': operationType,
      'measurement_id': measurementId,
      'duration_ms': duration,
      'was_successful': wasSuccessful,
      'error_type': errorType,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get comprehensive performance metrics
  Future<Either<String, SocialPerformanceMetrics>> getPerformanceMetrics({
    Duration period = const Duration(hours: 24),
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'performance_${period.inHours}';
      final now = DateTime.now();

      // Check cache validity
      if (!forceRefresh && 
          _metricsCache.containsKey(cacheKey) &&
          _lastMeasurements[cacheKey] != null &&
          now.difference(_lastMeasurements[cacheKey]!).inMinutes < 5) {
        return Right(_metricsCache[cacheKey] as SocialPerformanceMetrics);
      }

      // Calculate fresh metrics
      final feedPerformance = await _calculateFeedPerformance(period);
      final messagingPerformance = await _calculateMessagingPerformance(period);
      final searchPerformance = await _calculateSearchPerformance(period);
      final mediaPerformance = await _calculateMediaPerformance(period);
      final connectionPerformance = await _calculateConnectionPerformance(period);
      final cachePerformance = await _calculateCachePerformance(period);
      final systemHealth = await _calculateSystemHealth();

      final metrics = SocialPerformanceMetrics(
        period: period,
        calculatedAt: now,
        feedPerformance: feedPerformance,
        messagingPerformance: messagingPerformance,
        searchPerformance: searchPerformance,
        mediaPerformance: mediaPerformance,
        connectionPerformance: connectionPerformance,
        cachePerformance: cachePerformance,
        systemHealth: systemHealth,
        alerts: await _generatePerformanceAlerts(),
      );

      // Cache the metrics
      _metricsCache[cacheKey] = metrics;
      _lastMeasurements[cacheKey] = now;

      return Right(metrics);
    } catch (e) {
      return Left('Failed to get performance metrics: $e');
    }
  }

  /// Calculate feed loading performance
  Future<FeedPerformanceMetrics> _calculateFeedPerformance(Duration period) async {
    final feedResponseTimes = _responseTimeBuffers['feed_load'] ?? [];
    final feedRequests = _requestCounts['feed_load'] ?? 0;

    // Basic statistics
    final averageLoadTime = feedResponseTimes.isEmpty ? 0 : 
        feedResponseTimes.reduce((a, b) => a + b) / feedResponseTimes.length;

    final medianLoadTime = _calculateMedian(feedResponseTimes);
    final p95LoadTime = _calculatePercentile(feedResponseTimes, 95);
    final p99LoadTime = _calculatePercentile(feedResponseTimes, 99);

    // Performance ratings
  final loadTimeScore = _calculateLoadTimeScore(averageLoadTime.toDouble());
    final consistencyScore = _calculateConsistencyScore(feedResponseTimes);

    // Feed-specific metrics
    final postsPerSecond = await _calculatePostsPerSecond(period);
    final scrollPerformance = await _calculateScrollPerformance(period);
    final refreshSuccess = await _calculateRefreshSuccessRate(period);

    return FeedPerformanceMetrics(
      averageLoadTime: Duration(milliseconds: averageLoadTime.round()),
      medianLoadTime: Duration(milliseconds: medianLoadTime.round()),
      p95LoadTime: Duration(milliseconds: p95LoadTime.round()),
      p99LoadTime: Duration(milliseconds: p99LoadTime.round()),
      totalRequests: feedRequests,
      loadTimeScore: loadTimeScore,
      consistencyScore: consistencyScore,
      postsPerSecond: postsPerSecond,
  scrollPerformance: scrollPerformance,
      refreshSuccessRate: refreshSuccess,
  trends: await _calculateFeedTrends(period),
    );
  }

  /// Calculate messaging performance
  Future<MessagingPerformanceMetrics> _calculateMessagingPerformance(Duration period) async {
  final messageLatencies = _responseTimeBuffers['message_send'] ?? [];
    final connectionUptime = await _calculateConnectionUptime(period);

    return MessagingPerformanceMetrics(
      averageMessageLatency: _calculateAverage(messageLatencies),
      messageDeliverySuccess: await _calculateDeliverySuccessRate(period),
      connectionStability: connectionUptime,
  websocketPerformance: await _calculateWebSocketPerformance(period),
  messageQueueHealth: await _calculateMessageQueueHealth(period),
  realTimeSync: await _calculateRealTimeSyncMetrics(period),
    );
  }

  /// Calculate search performance
  Future<SearchPerformanceMetrics> _calculateSearchPerformance(Duration period) async {
    final searchResponseTimes = _responseTimeBuffers['search_query'] ?? [];
    final userSearchTimes = _responseTimeBuffers['user_search'] ?? [];
    final contentSearchTimes = _responseTimeBuffers['content_search'] ?? [];

    return SearchPerformanceMetrics(
      averageSearchTime: _calculateAverage(searchResponseTimes),
      userSearchTime: _calculateAverage(userSearchTimes),
      contentSearchTime: _calculateAverage(contentSearchTimes),
      searchAccuracy: await _calculateSearchAccuracy(period),
  indexingPerformance: await _calculateIndexingPerformance(period),
      searchCacheHitRate: await _calculateSearchCacheHitRate(period),
    );
  }

  /// Calculate media upload/processing performance
  Future<MediaPerformanceMetrics> _calculateMediaPerformance(Duration period) async {
    final uploadTimes = _responseTimeBuffers['media_upload'] ?? [];
    final processingTimes = _responseTimeBuffers['media_processing'] ?? [];

    return MediaPerformanceMetrics(
      averageUploadTime: _calculateAverage(uploadTimes),
      averageProcessingTime: _calculateAverage(processingTimes),
      uploadSuccessRate: await _calculateUploadSuccessRate(period),
      compressionEfficiency: await _calculateCompressionEfficiency(period),
      thumbnailGenerationTime: await _calculateThumbnailGenerationTime(period),
      storagePerformance: await _calculateStoragePerformance(period),
    );
  }

  /// Calculate connection and network performance
  Future<ConnectionPerformanceMetrics> _calculateConnectionPerformance(Duration period) async {
    return ConnectionPerformanceMetrics(
      websocketStability: await _calculateWebSocketStability(period),
      apiLatency: await _calculateApiLatency(period),
      networkReliability: await _calculateNetworkReliability(period),
      reconnectionMetrics: await _calculateReconnectionMetrics(period),
      bandwidthUtilization: await _calculateBandwidthUtilization(period),
    );
  }

  /// Calculate cache performance metrics
  Future<CachePerformanceMetrics> _calculateCachePerformance(Duration period) async {
    final cacheHits = await _getCacheHits(period);
    final cacheMisses = await _getCacheMisses(period);
    final totalRequests = cacheHits + cacheMisses;

    final hitRate = totalRequests == 0 ? 0.0 : cacheHits / totalRequests;
    
    return CachePerformanceMetrics(
      hitRate: hitRate,
      missRate: 1.0 - hitRate,
      averageRetrievalTime: await _calculateCacheRetrievalTime(period),
      evictionRate: await _calculateEvictionRate(period),
      memoryUtilization: await _calculateCacheMemoryUtilization(),
      distributionEfficiency: await _calculateCacheDistributionEfficiency(period),
    );
  }

  /// Calculate overall system health
  Future<SystemHealthMetrics> _calculateSystemHealth() async {
    final memoryUsage = await _getMemoryUsage();
    final cpuUsage = await _getCpuUsage();
    final diskUsage = await _getDiskUsage();
    final networkHealth = await _getNetworkHealth();

    final healthScore = _calculateOverallHealthScore(
      memoryUsage, cpuUsage, diskUsage, networkHealth);

    return SystemHealthMetrics(
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage,
      diskUsage: diskUsage,
      networkHealth: networkHealth,
      overallHealthScore: healthScore,
      systemLoad: await _getSystemLoad(),
      errorRates: await _getSystemErrorRates(),
    );
  }

  /// Record performance data point
  void _recordPerformanceData(PerformanceDataPoint dataPoint) {
    final key = dataPoint.operationType;
    _snapshotHistory.putIfAbsent(key, () => <PerformanceSnapshot>[]);
    
    final history = _snapshotHistory[key]!;
    history.add(PerformanceSnapshot(
  timestamp: dataPoint.timestamp,
  responseTime: dataPoint.responseTime,
  wasSuccessful: dataPoint.wasSuccessful,
  errorType: dataPoint.errorType,
    ));

    // Limit history size
    final cutoffDate = DateTime.now().subtract(Duration(days: _maxHistoryDays));
  history.removeWhere((snapshot) => snapshot.timestamp.isBefore(cutoffDate));
  }

  /// Perform regular performance checks
  Future<void> _performPerformanceCheck() async {
    try {
      // Check for performance degradation
      final issues = await _detectPerformanceIssues();
      
      if (issues.isNotEmpty) {
        await _handlePerformanceIssues(issues);
      }

      // Update real-time metrics
      await _updateRealTimeMetrics();

    } catch (e) {
      print('Performance check failed: $e');
    }
  }

  /// Aggregate performance data
  Future<void> _aggregatePerformanceData() async {
    try {
      for (final operationType in _responseTimeBuffers.keys) {
        final buffer = _responseTimeBuffers[operationType]!;
        if (buffer.isNotEmpty) {
          await _storeAggregatedData(operationType, buffer);
        }
      }
    } catch (e) {
      print('Performance aggregation failed: $e');
    }
  }

  /// Generate performance reports
  Future<void> _generatePerformanceReport() async {
    try {
      final metrics = await getPerformanceMetrics(
        period: const Duration(hours: 1),
        forceRefresh: true,
      );

      if (metrics.isRight) {
        if (metrics.rightOrNull() != null) {
          await _storePerformanceReport(metrics.rightOrNull()!);
          await _checkPerformanceThresholds(metrics.rightOrNull()!);
        }
      }
    } catch (e) {
      print('Performance report generation failed: $e');
    }
  }

  // Helper calculation methods
  double _calculateAverage(List<int> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateMedian(List<int> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    } else {
      return sorted[middle].toDouble();
    }
  }

  double _calculatePercentile(List<int> values, int percentile) {
    if (values.isEmpty) return 0.0;
    final sorted = List<int>.from(values)..sort();
    final index = (percentile / 100.0 * sorted.length).ceil() - 1;
    return sorted[math.max(0, math.min(index, sorted.length - 1))].toDouble();
  }

  double _calculateLoadTimeScore(double averageLoadTime) {
    // Score based on load time thresholds
    if (averageLoadTime <= 1000) return 100.0; // Excellent < 1s
    if (averageLoadTime <= 2000) return 80.0;  // Good < 2s
    if (averageLoadTime <= 3000) return 60.0;  // Fair < 3s
    if (averageLoadTime <= 5000) return 40.0;  // Poor < 5s
    return 20.0; // Very poor >= 5s
  }

  double _calculateConsistencyScore(List<int> values) {
    if (values.length < 2) return 100.0;
    
    final mean = _calculateAverage(values);
    final variance = values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final coefficient = mean == 0 ? 0 : stdDev / mean;
    
    // Lower coefficient of variation = higher consistency score
    return math.max(0, 100 - (coefficient * 100));
  }

  double _calculateOverallHealthScore(
    double memoryUsage, double cpuUsage, double diskUsage, double networkHealth) {
    final memoryScore = math.max(0, 100 - (memoryUsage * 100));
    final cpuScore = math.max(0, 100 - (cpuUsage * 100));
    final diskScore = math.max(0, 100 - (diskUsage * 100));
    
    return (memoryScore + cpuScore + diskScore + networkHealth) / 4;
  }

  // Placeholder methods for detailed calculations
  Future<double> _calculatePostsPerSecond(Duration period) async => 0.0;
  Future<ScrollPerformanceMetrics> _calculateScrollPerformance(Duration period) async => ScrollPerformanceMetrics.empty();
  Future<double> _calculateRefreshSuccessRate(Duration period) async => 0.95;
  Future<FeedTrends> _calculateFeedTrends(Duration period) async => FeedTrends.empty();
  Future<double> _calculateConnectionUptime(Duration period) async => 0.99;
  Future<double> _calculateDeliverySuccessRate(Duration period) async => 0.98;
  Future<WebSocketPerformanceMetrics> _calculateWebSocketPerformance(Duration period) async => WebSocketPerformanceMetrics.empty();
  Future<MessageQueueHealthMetrics> _calculateMessageQueueHealth(Duration period) async => MessageQueueHealthMetrics.empty();
  Future<RealTimeSyncMetrics> _calculateRealTimeSyncMetrics(Duration period) async => RealTimeSyncMetrics.empty();
  Future<double> _calculateSearchAccuracy(Duration period) async => 0.85;
  Future<IndexingPerformanceMetrics> _calculateIndexingPerformance(Duration period) async => IndexingPerformanceMetrics.empty();
  Future<double> _calculateSearchCacheHitRate(Duration period) async => 0.70;
  Future<double> _calculateUploadSuccessRate(Duration period) async => 0.95;
  Future<double> _calculateCompressionEfficiency(Duration period) async => 0.70;
  Future<Duration> _calculateThumbnailGenerationTime(Duration period) async => const Duration(milliseconds: 500);
  Future<StoragePerformanceMetrics> _calculateStoragePerformance(Duration period) async => StoragePerformanceMetrics.empty();
  Future<double> _calculateWebSocketStability(Duration period) async => 0.95;
  Future<Duration> _calculateApiLatency(Duration period) async => const Duration(milliseconds: 200);
  Future<double> _calculateNetworkReliability(Duration period) async => 0.99;
  Future<ReconnectionMetrics> _calculateReconnectionMetrics(Duration period) async => ReconnectionMetrics.empty();
  Future<BandwidthMetrics> _calculateBandwidthUtilization(Duration period) async => BandwidthMetrics.empty();
  Future<int> _getCacheHits(Duration period) async => 1000;
  Future<int> _getCacheMisses(Duration period) async => 200;
  Future<Duration> _calculateCacheRetrievalTime(Duration period) async => const Duration(milliseconds: 50);
  Future<double> _calculateEvictionRate(Duration period) async => 0.05;
  Future<double> _calculateCacheMemoryUtilization() async => 0.70;
  Future<double> _calculateCacheDistributionEfficiency(Duration period) async => 0.85;
  Future<double> _getMemoryUsage() async => 0.60;
  Future<double> _getCpuUsage() async => 0.40;
  Future<double> _getDiskUsage() async => 0.30;
  Future<double> _getNetworkHealth() async => 85.0;
  Future<double> _getSystemLoad() async => 1.5;
  Future<Map<String, double>> _getSystemErrorRates() async => {'api': 0.01, 'database': 0.005};
  Future<List<PerformanceIssue>> _detectPerformanceIssues() async => [];
  Future<void> _handlePerformanceIssues(List<PerformanceIssue> issues) async {}
  Future<void> _updateRealTimeMetrics() async {}
  Future<void> _storeAggregatedData(String operationType, List<int> buffer) async {}
  Future<void> _storePerformanceReport(SocialPerformanceMetrics metrics) async {}
  Future<void> _checkPerformanceThresholds(SocialPerformanceMetrics metrics) async {}
  Future<List<PerformanceAlert>> _generatePerformanceAlerts() async => [];

  /// Dispose resources
  void dispose() {
    _performanceCheckTimer?.cancel();
    _performanceAggregationTimer?.cancel();
    _performanceReportTimer?.cancel();
    
    // Stop any active timers
    for (final stopwatch in _activeTimers.values) {
      stopwatch.stop();
    }
    _activeTimers.clear();
  }
}

// Data models for performance monitoring
class SocialPerformanceMetrics {
  final Duration period;
  final DateTime calculatedAt;
  final FeedPerformanceMetrics feedPerformance;
  final MessagingPerformanceMetrics messagingPerformance;
  final SearchPerformanceMetrics searchPerformance;
  final MediaPerformanceMetrics mediaPerformance;
  final ConnectionPerformanceMetrics connectionPerformance;
  final CachePerformanceMetrics cachePerformance;
  final SystemHealthMetrics systemHealth;
  final List<PerformanceAlert> alerts;

  const SocialPerformanceMetrics({
    required this.period,
    required this.calculatedAt,
    required this.feedPerformance,
    required this.messagingPerformance,
    required this.searchPerformance,
    required this.mediaPerformance,
    required this.connectionPerformance,
    required this.cachePerformance,
    required this.systemHealth,
    required this.alerts,
  });
}

class FeedPerformanceMetrics {
  final Duration averageLoadTime;
  final Duration medianLoadTime;
  final Duration p95LoadTime;
  final Duration p99LoadTime;
  final int totalRequests;
  final double loadTimeScore;
  final double consistencyScore;
  final double postsPerSecond;
  final ScrollPerformanceMetrics scrollPerformance;
  final double refreshSuccessRate;
  final FeedTrends trends;

  const FeedPerformanceMetrics({
    required this.averageLoadTime,
    required this.medianLoadTime,
    required this.p95LoadTime,
    required this.p99LoadTime,
    required this.totalRequests,
    required this.loadTimeScore,
    required this.consistencyScore,
    required this.postsPerSecond,
    required this.scrollPerformance,
    required this.refreshSuccessRate,
    required this.trends,
  });
}

class MessagingPerformanceMetrics {
  final double averageMessageLatency;
  final double messageDeliverySuccess;
  final double connectionStability;
  final WebSocketPerformanceMetrics websocketPerformance;
  final MessageQueueHealthMetrics messageQueueHealth;
  final RealTimeSyncMetrics realTimeSync;

  const MessagingPerformanceMetrics({
    required this.averageMessageLatency,
    required this.messageDeliverySuccess,
    required this.connectionStability,
    required this.websocketPerformance,
    required this.messageQueueHealth,
    required this.realTimeSync,
  });
}

class SearchPerformanceMetrics {
  final double averageSearchTime;
  final double userSearchTime;
  final double contentSearchTime;
  final double searchAccuracy;
  final IndexingPerformanceMetrics indexingPerformance;
  final double searchCacheHitRate;

  const SearchPerformanceMetrics({
    required this.averageSearchTime,
    required this.userSearchTime,
    required this.contentSearchTime,
    required this.searchAccuracy,
    required this.indexingPerformance,
    required this.searchCacheHitRate,
  });
}

class MediaPerformanceMetrics {
  final double averageUploadTime;
  final double averageProcessingTime;
  final double uploadSuccessRate;
  final double compressionEfficiency;
  final Duration thumbnailGenerationTime;
  final StoragePerformanceMetrics storagePerformance;

  const MediaPerformanceMetrics({
    required this.averageUploadTime,
    required this.averageProcessingTime,
    required this.uploadSuccessRate,
    required this.compressionEfficiency,
    required this.thumbnailGenerationTime,
    required this.storagePerformance,
  });
}

class ConnectionPerformanceMetrics {
  final double websocketStability;
  final Duration apiLatency;
  final double networkReliability;
  final ReconnectionMetrics reconnectionMetrics;
  final BandwidthMetrics bandwidthUtilization;

  const ConnectionPerformanceMetrics({
    required this.websocketStability,
    required this.apiLatency,
    required this.networkReliability,
    required this.reconnectionMetrics,
    required this.bandwidthUtilization,
  });
}

class CachePerformanceMetrics {
  final double hitRate;
  final double missRate;
  final Duration averageRetrievalTime;
  final double evictionRate;
  final double memoryUtilization;
  final double distributionEfficiency;

  const CachePerformanceMetrics({
    required this.hitRate,
    required this.missRate,
    required this.averageRetrievalTime,
    required this.evictionRate,
    required this.memoryUtilization,
    required this.distributionEfficiency,
  });
}

class SystemHealthMetrics {
  final double memoryUsage;
  final double cpuUsage;
  final double diskUsage;
  final double networkHealth;
  final double overallHealthScore;
  final double systemLoad;
  final Map<String, double> errorRates;

  const SystemHealthMetrics({
    required this.memoryUsage,
    required this.cpuUsage,
    required this.diskUsage,
    required this.networkHealth,
    required this.overallHealthScore,
    required this.systemLoad,
    required this.errorRates,
  });
}

// Additional data classes
class PerformanceDataPoint {
  final String operationType;
  final String measurementId;
  final DateTime timestamp;
  final Duration responseTime;
  final bool wasSuccessful;
  final String? errorType;
  final Map<String, dynamic> metadata;

  const PerformanceDataPoint({
    required this.operationType,
    required this.measurementId,
    required this.timestamp,
    required this.responseTime,
    required this.wasSuccessful,
    this.errorType,
    required this.metadata,
  });
}

class PerformanceSnapshot {
  final DateTime timestamp;
  final Duration responseTime;
  final bool wasSuccessful;
  final String? errorType;

  const PerformanceSnapshot({
    required this.timestamp,
    required this.responseTime,
    required this.wasSuccessful,
    this.errorType,
  });
}

class PerformanceAlert {
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const PerformanceAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.data,
  });
}

class PerformanceIssue {
  final String type;
  final String severity;
  final String description;
  final DateTime detectedAt;
  final Map<String, dynamic> data;

  const PerformanceIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    required this.data,
  });
}

// Empty factory methods for additional classes
class ScrollPerformanceMetrics {
  static ScrollPerformanceMetrics empty() => const ScrollPerformanceMetrics();
  const ScrollPerformanceMetrics();
}

class FeedTrends {
  static FeedTrends empty() => const FeedTrends();
  const FeedTrends();
}

class WebSocketPerformanceMetrics {
  static WebSocketPerformanceMetrics empty() => const WebSocketPerformanceMetrics();
  const WebSocketPerformanceMetrics();
}

class MessageQueueHealthMetrics {
  static MessageQueueHealthMetrics empty() => const MessageQueueHealthMetrics();
  const MessageQueueHealthMetrics();
}

class RealTimeSyncMetrics {
  static RealTimeSyncMetrics empty() => const RealTimeSyncMetrics();
  const RealTimeSyncMetrics();
}

class IndexingPerformanceMetrics {
  static IndexingPerformanceMetrics empty() => const IndexingPerformanceMetrics();
  const IndexingPerformanceMetrics();
}

class StoragePerformanceMetrics {
  static StoragePerformanceMetrics empty() => const StoragePerformanceMetrics();
  const StoragePerformanceMetrics();
}

class ReconnectionMetrics {
  static ReconnectionMetrics empty() => const ReconnectionMetrics();
  const ReconnectionMetrics();
}

class BandwidthMetrics {
  static BandwidthMetrics empty() => const BandwidthMetrics();
  const BandwidthMetrics();
}
