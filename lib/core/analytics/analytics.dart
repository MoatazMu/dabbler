export 'analytics_service.dart';
export 'analytics_helpers.dart';
export 'analytics_widgets.dart';
export 'analytics_constants.dart';
export 'analytics_storage.dart';

/// Analytics system barrel file
/// 
/// This file exports all analytics-related classes and utilities
/// for easy importing throughout the application.
/// 
/// Usage:
/// ```dart
/// import 'package:dabbler/core/analytics/analytics.dart';
/// 
/// // Initialize analytics
/// await AnalyticsService().initialize();
/// 
/// // Track an event
/// await AnalyticsService().trackGameCreated(
///   gameId: 'game-123',
///   sportType: 'basketball',
///   playerCount: 8,
///   price: 25.0,
///   venueType: 'indoor',
///   duration: '90min',
/// );
/// 
/// // Use analytics mixin
/// class MyWidget extends StatefulWidget with AnalyticsTrackingMixin {
///   // Widget implementation
/// }
/// 
/// // Wrap screens with analytics tracking
/// AnalyticsScreenWrapper(
///   screenName: 'game_details',
///   child: GameDetailsScreen(),
/// )
/// ```
