import 'dart:async';
import 'dart:io';

import '../../../core/utils/either.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/analytics/analytics_service.dart';

/// Service for tracking and analyzing errors in social features
class SocialErrorTrackingService {
  final AnalyticsService _analytics;
  final StorageService _storage;

  // Error tracking data
  final Map<String, List<SocialError>> _errorBuffer = {};
  final Map<String, ErrorStatistics> _errorStats = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  // Error monitoring timers
  Timer? _errorProcessingTimer;
  Timer? _errorReportTimer;
  Timer? _errorCleanupTimer;

  // Configuration
  static const int _maxBufferSize = 1000;
  static const Duration _processingInterval = Duration(minutes: 5);
  static const Duration _reportInterval = Duration(hours: 1);
  static const Duration _cleanupInterval = Duration(days: 1);
  static const Duration _errorRetentionPeriod = Duration(days: 30);

  // Critical error thresholds
  static const int _criticalErrorThreshold = 10; // per minute

  SocialErrorTrackingService({
    required AnalyticsService analytics,
    required StorageService storage,
  })  : _analytics = analytics,
        _storage = storage {
    _initializeErrorTracking();
  }

  /// Initialize error tracking system
  void _initializeErrorTracking() {
    // Process errors every 5 minutes
    _errorProcessingTimer = Timer.periodic(_processingInterval, (_) async {
      await _processErrorBuffer();
    });

    // Generate reports every hour
    _errorReportTimer = Timer.periodic(_reportInterval, (_) async {
      await _generateErrorReport();
    });

    // Cleanup old errors daily
    _errorCleanupTimer = Timer.periodic(_cleanupInterval, (_) async {
      await _cleanupOldErrors();
    });
  }

  /// Track a social feature error
  void trackError({
    required String feature,
    required String operation,
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    final error = SocialError(
      id: _generateErrorId(),
      feature: feature,
      operation: operation,
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      context: context ?? {},
      userId: userId,
      severity: severity,
      timestamp: DateTime.now(),
      userAgent: _getUserAgent(),
      deviceInfo: _getDeviceInfo(),
    );

    // Add to buffer
    _errorBuffer.putIfAbsent(feature, () => <SocialError>[]);
    final featureBuffer = _errorBuffer[feature]!;
    
    if (featureBuffer.length >= _maxBufferSize) {
      featureBuffer.removeAt(0);
    }
    featureBuffer.add(error);

    // Update statistics
    _updateErrorStatistics(error);

    // Check for critical errors
    _checkCriticalErrorConditions(error);

    // Track in analytics
    _analytics.trackEvent('social_error_tracked', {
      'feature': feature,
      'operation': operation,
      'error_type': errorType,
      'severity': severity.toString(),
      'user_id': userId,
      'timestamp': error.timestamp.toIso8601String(),
    });

    // Log error for immediate debugging
    _logError(error);
  }

  /// Get comprehensive error metrics
  Future<Either<String, SocialErrorMetrics>> getErrorMetrics({
    Duration period = const Duration(hours: 24),
    List<String>? features,
    bool includeDetails = false,
  }) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(period);

      // Get errors for the specified period
      final errors = await _getErrorsInPeriod(startTime, now, features);

      // Calculate error statistics
      final overallStats = _calculateOverallErrorStats(errors, period);
      final featureBreakdown = _calculateFeatureBreakdown(errors);
      final operationBreakdown = _calculateOperationBreakdown(errors);
      final errorTypeBreakdown = _calculateErrorTypeBreakdown(errors);
      final severityBreakdown = _calculateSeverityBreakdown(errors);
      final trends = await _calculateErrorTrends(errors, period);
      final impactAnalysis = _calculateImpactAnalysis(errors);
      final recommendations = await _generateErrorRecommendations(errors);

      final metrics = SocialErrorMetrics(
        period: period,
        calculatedAt: now,
        overallStats: overallStats,
        featureBreakdown: featureBreakdown,
        operationBreakdown: operationBreakdown,
        errorTypeBreakdown: errorTypeBreakdown,
        severityBreakdown: severityBreakdown,
        trends: trends,
        impactAnalysis: impactAnalysis,
        recommendations: recommendations,
        criticalErrors: _getCriticalErrors(errors),
        errorDetails: includeDetails ? errors : null,
      );

      return Right(metrics);
    } catch (e) {
      return Left('Failed to get error metrics: $e');
    }
  }

  /// Get errors for specific features
  Future<Either<String, List<SocialError>>> getFeatureErrors({
    required String feature,
    Duration period = const Duration(hours: 24),
    ErrorSeverity? minSeverity,
    int? limit,
  }) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(period);
      
      final errors = await _getErrorsInPeriod(startTime, now, [feature]);
      
      // Filter by severity if specified
      var filteredErrors = errors;
      if (minSeverity != null) {
        filteredErrors = errors.where((error) => 
            error.severity.index >= minSeverity.index).toList();
      }

      // Sort by timestamp (most recent first)
      filteredErrors.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Apply limit if specified
      if (limit != null && filteredErrors.length > limit) {
        filteredErrors = filteredErrors.take(limit).toList();
      }

      return Right(filteredErrors);
    } catch (e) {
      return Left('Failed to get feature errors: $e');
    }
  }

  /// Get error patterns and anomalies
  Future<Either<String, ErrorPatternAnalysis>> getErrorPatterns({
    Duration period = const Duration(days: 7),
  }) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(period);
      
      final errors = await _getErrorsInPeriod(startTime, now);
      
      final patterns = ErrorPatternAnalysis(
        period: period,
        calculatedAt: now,
        frequentErrorPatterns: _identifyFrequentPatterns(errors),
        errorClusters: _identifyErrorClusters(errors),
        timeBasedPatterns: _analyzeTimeBasedPatterns(errors),
        userBasedPatterns: _analyzeUserBasedPatterns(errors),
        anomalies: _detectErrorAnomalies(errors),
        correlations: _findErrorCorrelations(errors),
      );

      return Right(patterns);
    } catch (e) {
      return Left('Failed to analyze error patterns: $e');
    }
  }

  /// Calculate overall error statistics
  OverallErrorStats _calculateOverallErrorStats(List<SocialError> errors, Duration period) {
    final totalErrors = errors.length;
    final uniqueErrors = errors.map((e) => '${e.feature}_${e.operation}_${e.errorType}').toSet().length;
    
    // Calculate error rate (errors per hour)
    final errorRate = totalErrors / period.inHours;
    
    // Calculate affected users
    final affectedUsers = errors.where((e) => e.userId != null)
        .map((e) => e.userId!).toSet().length;
    
    // Calculate severity distribution
    final severityCounts = <ErrorSeverity, int>{};
    for (final error in errors) {
      severityCounts[error.severity] = (severityCounts[error.severity] ?? 0) + 1;
    }

    // Calculate resolution time (placeholder - would need resolution data)
    const averageResolutionTime = Duration(hours: 4);

    return OverallErrorStats(
      totalErrors: totalErrors,
      uniqueErrors: uniqueErrors,
      errorRate: errorRate,
      affectedUsers: affectedUsers,
      severityDistribution: severityCounts,
      averageResolutionTime: averageResolutionTime,
      errorFreeTime: _calculateErrorFreeTime(errors),
      criticalErrorCount: severityCounts[ErrorSeverity.critical] ?? 0,
    );
  }

  /// Calculate feature-wise error breakdown
  Map<String, FeatureErrorStats> _calculateFeatureBreakdown(List<SocialError> errors) {
    final breakdown = <String, FeatureErrorStats>{};

    final errorsByFeature = <String, List<SocialError>>{};
    for (final error in errors) {
      errorsByFeature.putIfAbsent(error.feature, () => <SocialError>[]).add(error);
    }

    for (final entry in errorsByFeature.entries) {
      final feature = entry.key;
      final featureErrors = entry.value;

      final operationCounts = <String, int>{};
      final errorTypeCounts = <String, int>{};
      final severityCounts = <ErrorSeverity, int>{};

      for (final error in featureErrors) {
        operationCounts[error.operation] = (operationCounts[error.operation] ?? 0) + 1;
        errorTypeCounts[error.errorType] = (errorTypeCounts[error.errorType] ?? 0) + 1;
        severityCounts[error.severity] = (severityCounts[error.severity] ?? 0) + 1;
      }

      breakdown[feature] = FeatureErrorStats(
        totalErrors: featureErrors.length,
        errorRate: featureErrors.length / 24.0, // per hour over 24h
        topOperations: _getTopItems(operationCounts, 5),
        topErrorTypes: _getTopItems(errorTypeCounts, 5),
        severityDistribution: severityCounts,
        lastError: featureErrors.isNotEmpty 
            ? featureErrors.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b).timestamp
            : null,
      );
    }

    return breakdown;
  }

  /// Calculate operation-wise error breakdown
  Map<String, OperationErrorStats> _calculateOperationBreakdown(List<SocialError> errors) {
    final breakdown = <String, OperationErrorStats>{};

    final errorsByOperation = <String, List<SocialError>>{};
    for (final error in errors) {
      final operationKey = '${error.feature}.${error.operation}';
      errorsByOperation.putIfAbsent(operationKey, () => <SocialError>[]).add(error);
    }

    for (final entry in errorsByOperation.entries) {
      final operation = entry.key;
      final operationErrors = entry.value;

      final errorTypeCounts = <String, int>{};
      final severityCounts = <ErrorSeverity, int>{};

      for (final error in operationErrors) {
        errorTypeCounts[error.errorType] = (errorTypeCounts[error.errorType] ?? 0) + 1;
        severityCounts[error.severity] = (severityCounts[error.severity] ?? 0) + 1;
      }

      breakdown[operation] = OperationErrorStats(
        totalErrors: operationErrors.length,
        errorRate: operationErrors.length / 24.0,
        topErrorTypes: _getTopItems(errorTypeCounts, 3),
        severityDistribution: severityCounts,
        failureRate: _calculateFailureRate(operation, operationErrors.length),
      );
    }

    return breakdown;
  }

  /// Calculate error type breakdown
  Map<String, ErrorTypeStats> _calculateErrorTypeBreakdown(List<SocialError> errors) {
    final breakdown = <String, ErrorTypeStats>{};

    final errorsByType = <String, List<SocialError>>{};
    for (final error in errors) {
      errorsByType.putIfAbsent(error.errorType, () => <SocialError>[]).add(error);
    }

    for (final entry in errorsByType.entries) {
      final errorType = entry.key;
      final typeErrors = entry.value;

      final featureCounts = <String, int>{};
      final operationCounts = <String, int>{};

      for (final error in typeErrors) {
        featureCounts[error.feature] = (featureCounts[error.feature] ?? 0) + 1;
        operationCounts[error.operation] = (operationCounts[error.operation] ?? 0) + 1;
      }

      breakdown[errorType] = ErrorTypeStats(
        totalOccurrences: typeErrors.length,
        affectedFeatures: featureCounts.keys.toList(),
        topFeatures: _getTopItems(featureCounts, 3),
        topOperations: _getTopItems(operationCounts, 3),
        firstSeen: typeErrors.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
        lastSeen: typeErrors.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
      );
    }

    return breakdown;
  }

  /// Calculate severity breakdown
  Map<ErrorSeverity, SeverityStats> _calculateSeverityBreakdown(List<SocialError> errors) {
    final breakdown = <ErrorSeverity, SeverityStats>{};

    final errorsBySeverity = <ErrorSeverity, List<SocialError>>{};
    for (final error in errors) {
      errorsBySeverity.putIfAbsent(error.severity, () => <SocialError>[]).add(error);
    }

    for (final entry in errorsBySeverity.entries) {
      final severity = entry.key;
      final severityErrors = entry.value;

      final featureCounts = <String, int>{};
      for (final error in severityErrors) {
        featureCounts[error.feature] = (featureCounts[error.feature] ?? 0) + 1;
      }

      breakdown[severity] = SeverityStats(
        count: severityErrors.length,
        percentage: (severityErrors.length / errors.length) * 100,
        topFeatures: _getTopItems(featureCounts, 5),
        averageResolutionTime: _getAverageResolutionTime(severity),
      );
    }

    return breakdown;
  }

  /// Update error statistics for a new error
  void _updateErrorStatistics(SocialError error) {
    final key = error.feature;
    _errorStats.putIfAbsent(key, () => ErrorStatistics());
    
    final stats = _errorStats[key]!;
    stats.totalErrors++;
    stats.errorsByType[error.errorType] = (stats.errorsByType[error.errorType] ?? 0) + 1;
    stats.errorsByOperation[error.operation] = (stats.errorsByOperation[error.operation] ?? 0) + 1;
    stats.errorsBySeverity[error.severity] = (stats.errorsBySeverity[error.severity] ?? 0) + 1;
    stats.lastUpdated = DateTime.now();

    _lastErrorTimes[key] = error.timestamp;
  }

  /// Check for critical error conditions
  void _checkCriticalErrorConditions(SocialError error) {
    if (error.severity == ErrorSeverity.critical) {
      _handleCriticalError(error);
    }

    // Check error rate threshold
    final recentErrors = _getRecentErrors(error.feature, const Duration(minutes: 1));
    if (recentErrors.length >= _criticalErrorThreshold) {
      _handleErrorRateThreshold(error.feature, recentErrors);
    }
  }

  /// Handle critical errors
  void _handleCriticalError(SocialError error) {
    // Log critical error
    print('CRITICAL ERROR in ${error.feature}.${error.operation}: ${error.errorMessage}');

    // Track critical error event
    _analytics.trackEvent('critical_social_error', {
      'feature': error.feature,
      'operation': error.operation,
      'error_type': error.errorType,
      'error_message': error.errorMessage,
      'user_id': error.userId,
      'timestamp': error.timestamp.toIso8601String(),
    });

    // Could trigger alerts, notifications, etc.
  }

  /// Handle error rate threshold exceeded
  void _handleErrorRateThreshold(String feature, List<SocialError> recentErrors) {
    print('ERROR RATE THRESHOLD EXCEEDED for $feature: ${recentErrors.length} errors in 1 minute');

    _analytics.trackEvent('error_rate_threshold_exceeded', {
      'feature': feature,
      'error_count': recentErrors.length,
      'threshold': _criticalErrorThreshold,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Process error buffer
  Future<void> _processErrorBuffer() async {
    try {
      for (final entry in _errorBuffer.entries) {
        final feature = entry.key;
        final errors = entry.value;

        if (errors.isNotEmpty) {
          await _persistErrors(feature, errors);
          await _analyzeErrorPatterns(feature, errors);
          errors.clear();
        }
      }
    } catch (e) {
      print('Error processing failed: $e');
    }
  }

  /// Generate error report
  Future<void> _generateErrorReport() async {
    try {
      final metrics = await getErrorMetrics(
        period: const Duration(hours: 1),
        includeDetails: false,
      );

      if (metrics.isRight) {
        final metricsData = metrics.rightOrNull();
        if (metricsData != null) {
          await _storeErrorReport(metricsData);
          await _checkErrorThresholds(metricsData);
        }
      }
    } catch (e) {
      print('Error report generation failed: $e');
    }
  }

  /// Cleanup old errors
  Future<void> _cleanupOldErrors() async {
    try {
      final cutoffDate = DateTime.now().subtract(_errorRetentionPeriod);
      await _deleteErrorsOlderThan(cutoffDate);
    } catch (e) {
      print('Error cleanup failed: $e');
    }
  }

  // Helper methods
  String _generateErrorId() => '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  String _generateRandomString(int length) => 'abcdefghijklmnopqrstuvwxyz0123456789'[DateTime.now().millisecondsSinceEpoch % 36].toString() * length;
  String _getUserAgent() => 'DabblerApp/1.0'; // Would get actual user agent
  Map<String, String> _getDeviceInfo() => {'platform': Platform.operatingSystem}; // Would get actual device info
  
  void _logError(SocialError error) {
    print('Social Error [${error.severity.name.toUpperCase()}] ${error.feature}.${error.operation}: ${error.errorMessage}');
  }

  List<SocialError> _getRecentErrors(String feature, Duration duration) {
    final buffer = _errorBuffer[feature] ?? [];
    final cutoff = DateTime.now().subtract(duration);
    return buffer.where((error) => error.timestamp.isAfter(cutoff)).toList();
  }

  List<MapEntry<String, int>> _getTopItems(Map<String, int> items, int count) {
    final sorted = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  Duration _calculateErrorFreeTime(List<SocialError> errors) {
    if (errors.isEmpty) return const Duration(days: 30);
    
    errors.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return DateTime.now().difference(errors.first.timestamp);
  }

  double _calculateFailureRate(String operation, int errorCount) {
    // Would calculate based on total operations vs errors
    return errorCount / 1000.0; // Placeholder
  }

  Duration _getAverageResolutionTime(ErrorSeverity severity) {
    // Would calculate from historical resolution data
    switch (severity) {
      case ErrorSeverity.critical:
        return const Duration(minutes: 30);
      case ErrorSeverity.high:
        return const Duration(hours: 2);
      case ErrorSeverity.medium:
        return const Duration(hours: 8);
      case ErrorSeverity.low:
        return const Duration(days: 1);
    }
  }

  // Placeholder methods for detailed implementations
  Future<List<SocialError>> _getErrorsInPeriod(DateTime start, DateTime end, [List<String>? features]) async => [];
  Future<ErrorTrends> _calculateErrorTrends(List<SocialError> errors, Duration period) async => ErrorTrends.empty();
  ErrorImpactAnalysis _calculateImpactAnalysis(List<SocialError> errors) => ErrorImpactAnalysis.empty();
  Future<List<String>> _generateErrorRecommendations(List<SocialError> errors) async => [];
  List<SocialError> _getCriticalErrors(List<SocialError> errors) => errors.where((e) => e.severity == ErrorSeverity.critical).toList();
  List<ErrorPattern> _identifyFrequentPatterns(List<SocialError> errors) => [];
  List<ErrorCluster> _identifyErrorClusters(List<SocialError> errors) => [];
  Map<int, int> _analyzeTimeBasedPatterns(List<SocialError> errors) => {};
  Map<String, int> _analyzeUserBasedPatterns(List<SocialError> errors) => {};
  List<ErrorAnomaly> _detectErrorAnomalies(List<SocialError> errors) => [];
  List<ErrorCorrelation> _findErrorCorrelations(List<SocialError> errors) => [];
  Future<void> _persistErrors(String feature, List<SocialError> errors) async {
    // Minimal persistence: store a lightweight summary per feature
    try {
      await _storage.saveDraft(
        'social_errors_$feature',
        {
          'lastSaved': DateTime.now().toIso8601String(),
          'gameTitle': 'Social Errors ($feature)',
          'errorsCount': errors.length,
        },
      );
    } catch (_) {
      // Best-effort only
    }
  }
  Future<void> _analyzeErrorPatterns(String feature, List<SocialError> errors) async {}
  Future<void> _storeErrorReport(SocialErrorMetrics metrics) async {
    // Minimal persistence: store summary of the latest hourly report
    try {
      await _storage.saveDraft(
        'social_error_report_latest',
        {
          'lastSaved': metrics.calculatedAt.toIso8601String(),
          'gameTitle': 'Social Error Report',
          'totalErrors': metrics.overallStats.totalErrors,
          'criticalErrors': metrics.overallStats.criticalErrorCount,
        },
      );
    } catch (_) {
      // Best-effort only
    }
  }
  Future<void> _checkErrorThresholds(SocialErrorMetrics metrics) async {}
  Future<void> _deleteErrorsOlderThan(DateTime cutoffDate) async {}

  /// Dispose resources
  void dispose() {
    _errorProcessingTimer?.cancel();
    _errorReportTimer?.cancel();
    _errorCleanupTimer?.cancel();
  }
}

// Data models for error tracking
enum ErrorSeverity { low, medium, high, critical }

class SocialError {
  final String id;
  final String feature;
  final String operation;
  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final Map<String, dynamic> context;
  final String? userId;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String userAgent;
  final Map<String, String> deviceInfo;

  const SocialError({
    required this.id,
    required this.feature,
    required this.operation,
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    required this.context,
    this.userId,
    required this.severity,
    required this.timestamp,
    required this.userAgent,
    required this.deviceInfo,
  });
}

class SocialErrorMetrics {
  final Duration period;
  final DateTime calculatedAt;
  final OverallErrorStats overallStats;
  final Map<String, FeatureErrorStats> featureBreakdown;
  final Map<String, OperationErrorStats> operationBreakdown;
  final Map<String, ErrorTypeStats> errorTypeBreakdown;
  final Map<ErrorSeverity, SeverityStats> severityBreakdown;
  final ErrorTrends trends;
  final ErrorImpactAnalysis impactAnalysis;
  final List<String> recommendations;
  final List<SocialError> criticalErrors;
  final List<SocialError>? errorDetails;

  const SocialErrorMetrics({
    required this.period,
    required this.calculatedAt,
    required this.overallStats,
    required this.featureBreakdown,
    required this.operationBreakdown,
    required this.errorTypeBreakdown,
    required this.severityBreakdown,
    required this.trends,
    required this.impactAnalysis,
    required this.recommendations,
    required this.criticalErrors,
    this.errorDetails,
  });
}

class OverallErrorStats {
  final int totalErrors;
  final int uniqueErrors;
  final double errorRate;
  final int affectedUsers;
  final Map<ErrorSeverity, int> severityDistribution;
  final Duration averageResolutionTime;
  final Duration errorFreeTime;
  final int criticalErrorCount;

  const OverallErrorStats({
    required this.totalErrors,
    required this.uniqueErrors,
    required this.errorRate,
    required this.affectedUsers,
    required this.severityDistribution,
    required this.averageResolutionTime,
    required this.errorFreeTime,
    required this.criticalErrorCount,
  });
}

class FeatureErrorStats {
  final int totalErrors;
  final double errorRate;
  final List<MapEntry<String, int>> topOperations;
  final List<MapEntry<String, int>> topErrorTypes;
  final Map<ErrorSeverity, int> severityDistribution;
  final DateTime? lastError;

  const FeatureErrorStats({
    required this.totalErrors,
    required this.errorRate,
    required this.topOperations,
    required this.topErrorTypes,
    required this.severityDistribution,
    this.lastError,
  });
}

class OperationErrorStats {
  final int totalErrors;
  final double errorRate;
  final List<MapEntry<String, int>> topErrorTypes;
  final Map<ErrorSeverity, int> severityDistribution;
  final double failureRate;

  const OperationErrorStats({
    required this.totalErrors,
    required this.errorRate,
    required this.topErrorTypes,
    required this.severityDistribution,
    required this.failureRate,
  });
}

class ErrorTypeStats {
  final int totalOccurrences;
  final List<String> affectedFeatures;
  final List<MapEntry<String, int>> topFeatures;
  final List<MapEntry<String, int>> topOperations;
  final DateTime firstSeen;
  final DateTime lastSeen;

  const ErrorTypeStats({
    required this.totalOccurrences,
    required this.affectedFeatures,
    required this.topFeatures,
    required this.topOperations,
    required this.firstSeen,
    required this.lastSeen,
  });
}

class SeverityStats {
  final int count;
  final double percentage;
  final List<MapEntry<String, int>> topFeatures;
  final Duration averageResolutionTime;

  const SeverityStats({
    required this.count,
    required this.percentage,
    required this.topFeatures,
    required this.averageResolutionTime,
  });
}

class ErrorStatistics {
  int totalErrors = 0;
  final Map<String, int> errorsByType = {};
  final Map<String, int> errorsByOperation = {};
  final Map<ErrorSeverity, int> errorsBySeverity = {};
  DateTime? lastUpdated;
}

class ErrorPatternAnalysis {
  final Duration period;
  final DateTime calculatedAt;
  final List<ErrorPattern> frequentErrorPatterns;
  final List<ErrorCluster> errorClusters;
  final Map<int, int> timeBasedPatterns;
  final Map<String, int> userBasedPatterns;
  final List<ErrorAnomaly> anomalies;
  final List<ErrorCorrelation> correlations;

  const ErrorPatternAnalysis({
    required this.period,
    required this.calculatedAt,
    required this.frequentErrorPatterns,
    required this.errorClusters,
    required this.timeBasedPatterns,
    required this.userBasedPatterns,
    required this.anomalies,
    required this.correlations,
  });
}

// Additional data classes with empty factory methods
class ErrorTrends {
  static ErrorTrends empty() => const ErrorTrends();
  const ErrorTrends();
}

class ErrorImpactAnalysis {
  static ErrorImpactAnalysis empty() => const ErrorImpactAnalysis();
  const ErrorImpactAnalysis();
}

class ErrorPattern {
  final String pattern;
  final int frequency;
  final List<String> affectedFeatures;

  const ErrorPattern({
    required this.pattern,
    required this.frequency,
    required this.affectedFeatures,
  });
}

class ErrorCluster {
  final String clusterId;
  final List<SocialError> errors;
  final String commonality;

  const ErrorCluster({
    required this.clusterId,
    required this.errors,
    required this.commonality,
  });
}

class ErrorAnomaly {
  final String type;
  final String description;
  final DateTime detectedAt;
  final double severity;

  const ErrorAnomaly({
    required this.type,
    required this.description,
    required this.detectedAt,
    required this.severity,
  });
}

class ErrorCorrelation {
  final String feature1;
  final String feature2;
  final double correlation;
  final String description;

  const ErrorCorrelation({
    required this.feature1,
    required this.feature2,
    required this.correlation,
    required this.description,
  });
}
