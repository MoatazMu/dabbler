import 'package:flutter/foundation.dart';

/// Analytics service for tracking user events and behaviors
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Initialize analytics service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('Analytics service initialized');
    }
    // Initialize your analytics providers here (Firebase Analytics, Mixpanel, etc.)
  }

  /// Track game creation funnel events
  Future<void> trackGameCreationStep({
    required String step,
    required String sportType,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('game_creation_step', {
      'step': step,
      'sport_type': sportType,
      ...?additionalData,
    });
  }

  /// Track when game creation is completed
  Future<void> trackGameCreated({
    required String gameId,
    required String sportType,
    required int playerCount,
    required double? price,
    required String venueType,
    required String duration,
  }) async {
    await _trackEvent('game_created', {
      'game_id': gameId,
      'sport_type': sportType,
      'player_count': playerCount,
      'price': price ?? 0.0,
      'is_free': price == null,
      'venue_type': venueType,
      'duration': duration,
    });
  }

  /// Track game join events
  Future<void> trackGameJoined({
    required String gameId,
    required String sportType,
    required String joinMethod, // 'direct', 'search', 'recommendation'
    required int timeToJoin, // seconds from viewing to joining
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('game_joined', {
      'game_id': gameId,
      'sport_type': sportType,
      'join_method': joinMethod,
      'time_to_join_seconds': timeToJoin,
      ...?additionalData,
    });
  }

  /// Track game join attempts that failed
  Future<void> trackGameJoinFailed({
    required String gameId,
    required String sportType,
    required String reason, // 'full', 'payment_failed', 'cancelled'
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('game_join_failed', {
      'game_id': gameId,
      'sport_type': sportType,
      'failure_reason': reason,
      ...?additionalData,
    });
  }

  /// Track search queries and results
  Future<void> trackGameSearch({
    required String query,
    required int resultsCount,
    required String sportType,
    required Map<String, dynamic> filters,
    String? location,
  }) async {
    await _trackEvent('game_search', {
      'search_query': query,
      'results_count': resultsCount,
      'sport_type': sportType,
      'filters': filters,
      'location': location,
      'search_timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track search result interactions
  Future<void> trackSearchResultClicked({
    required String gameId,
    required String query,
    required int resultPosition,
    required String sportType,
  }) async {
    await _trackEvent('search_result_clicked', {
      'game_id': gameId,
      'search_query': query,
      'result_position': resultPosition,
      'sport_type': sportType,
    });
  }

  /// Track filter usage
  Future<void> trackFilterUsed({
    required String filterType, // 'sport', 'date', 'price', 'location', 'skill'
    required dynamic filterValue,
    required int resultsCount,
  }) async {
    await _trackEvent('filter_used', {
      'filter_type': filterType,
      'filter_value': filterValue.toString(),
      'results_count': resultsCount,
    });
  }

  /// Track check-in events
  Future<void> trackGameCheckIn({
    required String gameId,
    required String sportType,
    required String checkInMethod, // 'qr', 'location', 'manual'
    required bool successful,
    String? errorReason,
  }) async {
    await _trackEvent('game_checkin', {
      'game_id': gameId,
      'sport_type': sportType,
      'checkin_method': checkInMethod,
      'successful': successful,
      'error_reason': errorReason,
      'checkin_timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track check-in success rate
  Future<void> trackCheckInAttempt({
    required String gameId,
    required String method,
    required bool success,
    int? attemptNumber,
  }) async {
    await _trackEvent('checkin_attempt', {
      'game_id': gameId,
      'method': method,
      'success': success,
      'attempt_number': attemptNumber ?? 1,
    });
  }

  /// Track venue selection patterns
  Future<void> trackVenueSelected({
    required String venueId,
    required String venueName,
    required String sportType,
    required double distanceKm,
    required double? price,
    required String selectionSource, // 'search', 'recommendation', 'map'
  }) async {
    await _trackEvent('venue_selected', {
      'venue_id': venueId,
      'venue_name': venueName,
      'sport_type': sportType,
      'distance_km': distanceKm,
      'price': price,
      'selection_source': selectionSource,
    });
  }

  /// Track venue booking attempts
  Future<void> trackVenueBookingAttempt({
    required String venueId,
    required String gameId,
    required DateTime requestedTime,
    required int durationMinutes,
    required bool successful,
    String? errorReason,
  }) async {
    await _trackEvent('venue_booking_attempt', {
      'venue_id': venueId,
      'game_id': gameId,
      'requested_time': requestedTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'successful': successful,
      'error_reason': errorReason,
    });
  }

  /// Track user engagement with games
  Future<void> trackGameEngagement({
    required String gameId,
    required String action, // 'viewed', 'shared', 'saved', 'reported'
    required Duration timeSpent,
    String? source, // 'search', 'feed', 'notification'
  }) async {
    await _trackEvent('game_engagement', {
      'game_id': gameId,
      'action': action,
      'time_spent_seconds': timeSpent.inSeconds,
      'source': source,
    });
  }

  /// Track payment events
  Future<void> trackPaymentEvent({
    required String gameId,
    required double amount,
    required String currency,
    required String status, // 'initiated', 'completed', 'failed', 'cancelled'
    String? paymentMethod,
    String? errorCode,
  }) async {
    await _trackEvent('payment_event', {
      'game_id': gameId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'error_code': errorCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track notification interactions
  Future<void> trackNotificationEvent({
    required String notificationType, // 'game_reminder', 'game_cancelled', 'new_game'
    required String action, // 'received', 'opened', 'dismissed'
    String? gameId,
  }) async {
    await _trackEvent('notification_event', {
      'notification_type': notificationType,
      'action': action,
      'game_id': gameId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track app performance metrics
  Future<void> trackPerformanceMetric({
    required String metricName, // 'screen_load_time', 'api_response_time'
    required double value,
    required String unit, // 'ms', 'seconds'
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('performance_metric', {
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track user retention and lifecycle events
  Future<void> trackUserLifecycleEvent({
    required String event, // 'app_opened', 'first_game_created', 'retention_day_7'
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('user_lifecycle', {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track error events
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? screen,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('error_occurred', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Set user properties for segmentation
  Future<void> setUserProperties({
    String? userId,
    int? gamesCreated,
    int? gamesJoined,
    List<String>? favoriteSports,
    String? skillLevel,
    String? preferredLocation,
    double? averageSpending,
  }) async {
    final properties = <String, dynamic>{};
    
    if (userId != null) properties['user_id'] = userId;
    if (gamesCreated != null) properties['games_created'] = gamesCreated;
    if (gamesJoined != null) properties['games_joined'] = gamesJoined;
    if (favoriteSports != null) properties['favorite_sports'] = favoriteSports;
    if (skillLevel != null) properties['skill_level'] = skillLevel;
    if (preferredLocation != null) properties['preferred_location'] = preferredLocation;
    if (averageSpending != null) properties['average_spending'] = averageSpending;
    
    await _setUserProperties(properties);
  }

  /// Internal method to track events
  Future<void> _trackEvent(String eventName, Map<String, dynamic> parameters) async {
    if (kDebugMode) {
      print('Analytics Event: $eventName');
      print('Parameters: $parameters');
    }
    
    // Implement your analytics provider tracking here
    // Examples:
    // - Firebase Analytics: FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
    // - Mixpanel: mixpanel.track(eventName, parameters);
    // - Custom analytics endpoint: httpClient.post('/analytics', body: {...});
  }

  /// Public wrapper to track arbitrary events
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    await _trackEvent(eventName, parameters);
  }

  /// Internal method to set user properties
  Future<void> _setUserProperties(Map<String, dynamic> properties) async {
    if (kDebugMode) {
      print('Analytics User Properties: $properties');
    }
    
    // Implement your analytics provider user properties here
    // Examples:
    // - Firebase Analytics: FirebaseAnalytics.instance.setUserProperty(name: key, value: value);
    // - Mixpanel: mixpanel.getPeople().set(properties);
  }

  /// Track screen views
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? additionalData,
  }) async {
    await _trackEvent('screen_view', {
      'screen_name': screenName,
      'screen_class': screenClass ?? screenName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track feature usage
  Future<void> trackFeatureUsed({
    required String featureName,
    Map<String, dynamic>? context,
  }) async {
    await _trackEvent('feature_used', {
      'feature_name': featureName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    });
  }
}

/// Analytics event names constants
class AnalyticsEvents {
  // Game creation funnel
  static const gameCreationStarted = 'game_creation_started';
  static const gameCreationSportSelected = 'game_creation_sport_selected';
  static const gameCreationVenueSelected = 'game_creation_venue_selected';
  static const gameCreationCompleted = 'game_creation_completed';
  static const gameCreationAbandoned = 'game_creation_abandoned';
  
  // Game joining
  static const gameViewed = 'game_viewed';
  static const gameJoined = 'game_joined';
  static const gameJoinFailed = 'game_join_failed';
  static const gameWaitlisted = 'game_waitlisted';
  
  // Search and discovery
  static const gamesSearched = 'games_searched';
  static const searchResultClicked = 'search_result_clicked';
  static const filterApplied = 'filter_applied';
  
  // Check-in process
  static const checkInStarted = 'checkin_started';
  static const checkInCompleted = 'checkin_completed';
  static const checkInFailed = 'checkin_failed';
  
  // Venue selection
  static const venueViewed = 'venue_viewed';
  static const venueSelected = 'venue_selected';
  static const venueBookingRequested = 'venue_booking_requested';
  
  // Engagement
  static const gameShared = 'game_shared';
  static const gameBookmarked = 'game_bookmarked';
  static const gameReported = 'game_reported';
  static const gameRated = 'game_rated';
  
  // User lifecycle
  static const userSignedUp = 'user_signed_up';
  static const userOnboardingCompleted = 'user_onboarding_completed';
  static const userReturnedDay1 = 'user_returned_day_1';
  static const userReturnedDay7 = 'user_returned_day_7';
  static const userReturnedDay30 = 'user_returned_day_30';
}

/// User properties constants
class AnalyticsUserProperties {
  static const userId = 'user_id';
  static const gamesCreated = 'games_created';
  static const gamesJoined = 'games_joined';
  static const favoritesSports = 'favorite_sports';
  static const skillLevel = 'skill_level';
  static const preferredLocation = 'preferred_location';
  static const averageSpending = 'average_spending';
  static const accountAge = 'account_age_days';
  static const lastActiveDate = 'last_active_date';
}
