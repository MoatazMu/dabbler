/// Mixin for tracking user statistics and profile-related events
library;
import 'dart:async';
import 'dart:collection';

/// Event data structure for analytics
class AnalyticsEvent {
  final String eventName;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String sessionId;
  
  AnalyticsEvent({
    required this.eventName,
    required this.properties,
    DateTime? timestamp,
    String? sessionId,
  }) : timestamp = timestamp ?? DateTime.now(),
        sessionId = sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  Map<String, dynamic> toJson() => {
    'event': eventName,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
    'session_id': sessionId,
  };
}

/// Mixin for tracking statistics and user behavior analytics
mixin StatisticsTrackingMixin {
  final Queue<AnalyticsEvent> _eventQueue = Queue<AnalyticsEvent>();
  Timer? _flushTimer;
  String? _sessionId;
  bool _isInitialized = false;
  int _maxQueueSize = 100;
  Duration _flushInterval = const Duration(seconds: 30);
  
  /// Initialize statistics tracking with custom settings
  void initStatisticsTracking({
    Duration? flushInterval,
    int? maxQueueSize,
    String? sessionId,
  }) {
    if (_isInitialized) return;
    
    _flushInterval = flushInterval ?? _flushInterval;
    _maxQueueSize = maxQueueSize ?? _maxQueueSize;
    _sessionId = sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _isInitialized = true;
    
    // Start periodic flush timer
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushEvents());
    
    // Track session start
    _queueEvent('session_start', {
      'session_id': _sessionId,
      'platform': 'mobile',
      'app_version': '1.0.0', // Would come from package info
    });
  }
  
  /// Track profile view event
  void trackProfileView(
    String profileId, {
    String? source,
    String? referrer,
    Duration? viewDuration,
  }) {
    _queueEvent('profile_view', {
      'profile_id': profileId,
      'source': source ?? 'direct',
      'referrer': referrer,
      'view_duration_seconds': viewDuration?.inSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track profile edit event
  void trackProfileEdit(
    String field, {
    dynamic oldValue,
    dynamic newValue,
    String? editSource,
    bool isComplete = true,
  }) {
    _queueEvent('profile_edit', {
      'field': field,
      'old_value': _sanitizeValue(oldValue),
      'new_value': _sanitizeValue(newValue),
      'edit_source': editSource ?? 'manual',
      'is_complete': isComplete,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track sport addition event
  void trackSportAdded(
    String sportName,
    int skillLevel, {
    String? position,
    int? experience,
    String? source,
  }) {
    _queueEvent('sport_added', {
      'sport': sportName.toLowerCase(),
      'skill_level': skillLevel,
      'position': position,
      'experience_years': experience,
      'source': source ?? 'manual',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track sport removal event
  void trackSportRemoved(String sportName, {String? reason}) {
    _queueEvent('sport_removed', {
      'sport': sportName.toLowerCase(),
      'reason': reason ?? 'user_action',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track privacy setting change
  void trackPrivacyChange(
    String setting,
    bool enabled, {
    String? previousValue,
    String? changeReason,
  }) {
    _queueEvent('privacy_change', {
      'setting': setting,
      'enabled': enabled,
      'previous_value': previousValue,
      'change_reason': changeReason ?? 'user_preference',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track achievement unlocked event
  void trackAchievementUnlocked(
    String achievement, {
    String? category,
    int? points,
    Map<String, dynamic>? context,
  }) {
    _queueEvent('achievement_unlocked', {
      'achievement': achievement,
      'category': category ?? 'general',
      'points': points ?? 0,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track profile completion milestone
  void trackProfileCompletionMilestone(
    double completionPercentage, {
    List<String>? completedFields,
    List<String>? remainingFields,
  }) {
    _queueEvent('profile_completion_milestone', {
      'completion_percentage': completionPercentage,
      'completed_fields': completedFields,
      'remaining_fields': remainingFields,
      'milestone_tier': _getCompletionTier(completionPercentage),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track search/filter usage
  void trackSearchUsage(
    String searchType, {
    Map<String, dynamic>? filters,
    int? resultsCount,
    String? selectedResult,
  }) {
    _queueEvent('search_usage', {
      'search_type': searchType,
      'filters_applied': filters,
      'results_count': resultsCount,
      'selected_result': selectedResult,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track game creation or joining
  void trackGameInteraction(
    String action, // 'create', 'join', 'leave', 'cancel'
    String gameId, {
    String? sport,
    int? playerCount,
    String? reason,
  }) {
    _queueEvent('game_interaction', {
      'action': action,
      'game_id': gameId,
      'sport': sport,
      'player_count': playerCount,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track user engagement metrics
  void trackEngagementMetric(
    String metricType, {
    required dynamic value,
    Map<String, dynamic>? context,
  }) {
    _queueEvent('engagement_metric', {
      'metric_type': metricType,
      'value': value,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track feature usage
  void trackFeatureUsage(
    String featureName, {
    String? action,
    Map<String, dynamic>? parameters,
    bool? successful,
  }) {
    _queueEvent('feature_usage', {
      'feature': featureName,
      'action': action ?? 'used',
      'parameters': parameters,
      'successful': successful,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track error events
  void trackError(
    String errorType,
    String errorMessage, {
    String? stackTrace,
    String? context,
    bool isFatal = false,
  }) {
    _queueEvent('error_occurred', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context,
      'is_fatal': isFatal,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track performance metrics
  void trackPerformanceMetric(
    String metricName,
    Duration duration, {
    Map<String, dynamic>? additionalData,
  }) {
    _queueEvent('performance_metric', {
      'metric_name': metricName,
      'duration_ms': duration.inMilliseconds,
      'additional_data': additionalData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track onboarding progress
  void trackOnboardingStep(
    String stepName, {
    String? action, // 'start', 'complete', 'skip'
    int? stepNumber,
    Duration? timeSpent,
  }) {
    _queueEvent('onboarding_step', {
      'step_name': stepName,
      'action': action ?? 'complete',
      'step_number': stepNumber,
      'time_spent_seconds': timeSpent?.inSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track notification interactions
  void trackNotificationInteraction(
    String action, // 'received', 'opened', 'dismissed'
    String notificationType, {
    String? notificationId,
    Map<String, dynamic>? payload,
  }) {
    _queueEvent('notification_interaction', {
      'action': action,
      'notification_type': notificationType,
      'notification_id': notificationId,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Internal method to queue events
  void _queueEvent(String eventName, Map<String, dynamic> properties) {
    if (!_isInitialized) {
      initStatisticsTracking(); // Auto-initialize if not done
    }
    
    final event = AnalyticsEvent(
      eventName: eventName,
      properties: properties,
      sessionId: _sessionId,
    );
    
    _eventQueue.add(event);
    
    // Auto-flush if queue is getting large
    if (_eventQueue.length >= _maxQueueSize) {
      _flushEvents();
    }
  }
  
  /// Flush events to analytics service
  void _flushEvents() {
    if (_eventQueue.isEmpty) return;
    
    try {
      // Convert events to JSON for transmission
      final events = _eventQueue.map((event) => event.toJson()).toList();
      _eventQueue.clear();
      
      // Send to analytics service
      _sendToAnalyticsService(events);
      
      // Debug logging
      print('📊 Flushed ${events.length} analytics events');
      
    } catch (e) {
      print('❌ Error flushing analytics events: $e');
      // Could implement retry logic here
    }
  }
  
  /// Send events to analytics service (placeholder implementation)
  void _sendToAnalyticsService(List<Map<String, dynamic>> events) {
    // This would integrate with your analytics service:
    // - Firebase Analytics
    // - Mixpanel
    // - Amplitude
    // - Custom analytics backend
    
    // Example implementations:
    /*
    // Firebase Analytics
    for (final event in events) {
      FirebaseAnalytics.instance.logEvent(
        name: event['event'],
        parameters: event['properties'],
      );
    }
    
    // HTTP POST to custom backend
    final response = await http.post(
      Uri.parse('https://api.yourapp.com/analytics/events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'events': events}),
    );
    */
    
    // For now, just log events
    for (final event in events) {
      print('📈 Analytics: ${event['event']} - ${event['properties']}');
    }
  }
  
  /// Sanitize sensitive data before logging
  dynamic _sanitizeValue(dynamic value) {
    if (value == null) return null;
    
    final valueStr = value.toString();
    
    // Sanitize email addresses
    if (valueStr.contains('@')) {
      return valueStr.replaceAllMapped(
        RegExp(r'([^@\s]+)@([^@\s]+\.[^@\s]+)'),
        (match) => '${match.group(1)?.substring(0, 3)}***@${match.group(2)}',
      );
    }
    
    // Sanitize phone numbers
    if (RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(valueStr)) {
      return '***${valueStr.substring(valueStr.length - 4)}';
    }
    
    // Truncate very long values
    if (valueStr.length > 200) {
      return '${valueStr.substring(0, 200)}...';
    }
    
    return value;
  }
  
  /// Get completion tier for milestones
  String _getCompletionTier(double percentage) {
    if (percentage >= 95) return 'complete';
    if (percentage >= 85) return 'excellent';
    if (percentage >= 70) return 'good';
    if (percentage >= 50) return 'fair';
    if (percentage >= 25) return 'started';
    return 'minimal';
  }
  
  /// Force flush all pending events
  void flushEventsImmediate() {
    _flushEvents();
  }
  
  /// Get current queue size
  int get pendingEventsCount => _eventQueue.length;
  
  /// Check if tracking is initialized
  bool get isTrackingInitialized => _isInitialized;
  
  /// Get current session ID
  String? get currentSessionId => _sessionId;
  
  /// Update session ID (for new sessions)
  void updateSessionId(String newSessionId) {
    _sessionId = newSessionId;
    _queueEvent('session_renewed', {
      'new_session_id': newSessionId,
      'previous_session_id': _sessionId,
    });
  }
  
  /// Enable/disable tracking
  void setTrackingEnabled(bool enabled) {
    if (enabled && !_isInitialized) {
      initStatisticsTracking();
    } else if (!enabled && _isInitialized) {
      _flushEvents(); // Flush pending events before disabling
      _flushTimer?.cancel();
      _isInitialized = false;
    }
  }
  
  /// Track custom event with validation
  void trackCustomEvent(
    String eventName,
    Map<String, dynamic> properties, {
    bool validateEventName = true,
  }) {
    if (validateEventName && !_isValidEventName(eventName)) {
      print('⚠️ Invalid event name: $eventName');
      return;
    }
    
    _queueEvent(eventName, properties);
  }
  
  /// Validate event name format
  bool _isValidEventName(String eventName) {
    // Event names should be lowercase with underscores
    final validPattern = RegExp(r'^[a-z][a-z0-9_]*$');
    return validPattern.hasMatch(eventName) && eventName.length <= 50;
  }
  
  /// Clean up resources
  void disposeStatisticsTracking() {
    _flushEvents(); // Flush any pending events
    _flushTimer?.cancel();
    _eventQueue.clear();
    _isInitialized = false;
    
    // Track session end
    if (_sessionId != null) {
      _queueEvent('session_end', {
        'session_id': _sessionId,
        'session_duration_seconds': DateTime.now().millisecondsSinceEpoch,
      });
      _flushEvents(); // Immediate flush for session end
    }
  }
}
