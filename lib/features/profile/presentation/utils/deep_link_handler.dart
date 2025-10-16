import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../utils/constants/route_constants.dart';

/// Comprehensive deep link handler for profile and settings routes
class DeepLinkHandler {
  static const String _logTag = 'DeepLinkHandler';
  
  /// Handle incoming deep links
  static void handleDeepLink(BuildContext context, String deepLink) {
    try {
      debugPrint('$_logTag: Processing deep link: $deepLink');
      
      final uri = Uri.parse(deepLink);
      final path = uri.path;
      final queryParams = uri.queryParameters;
      
      // Remove leading slash if present
      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      final segments = normalizedPath.split('/');
      
      if (segments.isEmpty || segments.first.isEmpty) {
        _navigateToHome(context);
        return;
      }
      
      switch (segments[0].toLowerCase()) {
        case 'profile':
          _handleProfileDeepLink(context, segments, queryParams);
          break;
          
        case 'settings':
          _handleSettingsDeepLink(context, segments, queryParams);
          break;
          
        case 'games':
          _handleGameDeepLink(context, segments, queryParams);
          break;
          
        case 'share':
          _handleShareDeepLink(context, segments, queryParams);
          break;
          
        default:
          debugPrint('$_logTag: Unknown deep link path: ${segments[0]}');
          _navigateToHome(context);
      }
    } catch (e) {
      debugPrint('$_logTag: Error handling deep link: $e');
      _navigateToHome(context);
    }
  }
  
  /// Handle profile deep links
  static void _handleProfileDeepLink(
    BuildContext context,
    List<String> segments,
    Map<String, String> queryParams,
  ) {
    try {
      if (segments.length == 1) {
        // /profile - navigate to own profile
        context.goNamed(RouteNames.profile);
      } else if (segments.length == 2) {
        final secondSegment = segments[1].toLowerCase();
        
        if (secondSegment == 'edit') {
          // /profile/edit - navigate to profile edit
          context.goNamed(RouteNames.profileEdit);
        } else {
          // /profile/userId - navigate to user's profile
          context.goNamed(
            RouteNames.profileUser,
            pathParameters: {'userId': segments[1]},
          );
        }
      } else if (segments.length == 3 && segments[1].toLowerCase() == 'edit') {
        // /profile/edit/* - navigate to specific edit screens
        switch (segments[2].toLowerCase()) {
          case 'photo':
            context.goNamed(RouteNames.profileEditPhoto);
            break;
          case 'sports':
            context.goNamed(RouteNames.profileEditSports);
            break;
          default:
            context.goNamed(RouteNames.profileEdit);
        }
      } else {
        // Invalid profile path, default to main profile
        context.goNamed(RouteNames.profile);
      }
    } catch (e) {
      debugPrint('$_logTag: Error handling profile deep link: $e');
      context.goNamed(RouteNames.profile);
    }
  }
  
  /// Handle settings deep links
  static void _handleSettingsDeepLink(
    BuildContext context,
    List<String> segments,
    Map<String, String> queryParams,
  ) {
    try {
      if (segments.length == 1) {
        // /settings - navigate to main settings
        context.goNamed(RouteNames.settings);
      } else if (segments.length == 2) {
        // /settings/* - navigate to specific setting screens
        switch (segments[1].toLowerCase()) {
          case 'privacy':
            context.goNamed(RouteNames.settingsPrivacy);
            break;
          case 'notifications':
            context.goNamed(RouteNames.settingsNotifications);
            break;
          case 'account':
            context.goNamed(RouteNames.settingsAccount);
            break;
          default:
            context.goNamed(RouteNames.settings);
        }
      } else {
        // Invalid settings path, default to main settings
        context.goNamed(RouteNames.settings);
      }
    } catch (e) {
      debugPrint('$_logTag: Error handling settings deep link: $e');
      context.goNamed(RouteNames.settings);
    }
  }
  
  /// Handle game deep links
  static void _handleGameDeepLink(
    BuildContext context,
    List<String> segments,
    Map<String, String> queryParams,
  ) {
    try {
      if (segments.length == 1) {
        // /games - navigate to games home
        context.go('/games');
      } else if (segments.length == 2) {
        final gameId = segments[1];
        // /games/gameId - navigate to game detail
        context.goNamed(
          RouteNames.gameDetail,
          pathParameters: {'gameId': gameId},
        );
      } else if (segments.length == 3) {
        final gameId = segments[1];
        final action = segments[2].toLowerCase();
        
        // /games/gameId/action - navigate to game action
        switch (action) {
          case 'join':
            context.goNamed(
              RouteNames.joinGame,
              pathParameters: {'gameId': gameId},
            );
            break;
          case 'checkin':
            context.goNamed(
              RouteNames.gameCheckin,
              pathParameters: {'gameId': gameId},
            );
            break;
          case 'lobby':
            context.goNamed(
              RouteNames.gameLobby,
              pathParameters: {'gameId': gameId},
            );
            break;
          default:
            context.goNamed(
              RouteNames.gameDetail,
              pathParameters: {'gameId': gameId},
            );
        }
      } else {
        // Invalid game path, default to games home
        context.go('/games');
      }
    } catch (e) {
      debugPrint('$_logTag: Error handling game deep link: $e');
      context.go('/games');
    }
  }
  
  /// Handle share deep links (for tracking shared link clicks)
  static void _handleShareDeepLink(
    BuildContext context,
    List<String> segments,
    Map<String, String> queryParams,
  ) {
    try {
      if (segments.length >= 3 && segments[1].toLowerCase() == 'profile') {
        final userId = segments[2];
        
        // Track the shared link click
        _trackSharedLinkClick(userId, queryParams);
        
        // Navigate to the profile
        context.goNamed(
          RouteNames.profileUser,
          pathParameters: {'userId': userId},
        );
      } else {
        _navigateToHome(context);
      }
    } catch (e) {
      debugPrint('$_logTag: Error handling share deep link: $e');
      _navigateToHome(context);
    }
  }
  
  /// Navigate to home page
  static void _navigateToHome(BuildContext context) {
    try {
      context.goNamed(RouteNames.home);
    } catch (e) {
      debugPrint('$_logTag: Error navigating to home: $e');
    }
  }
  
  /// Track shared link clicks for analytics
  static void _trackSharedLinkClick(String userId, Map<String, String> queryParams) {
    try {
      final referrer = queryParams['ref'];
      final source = queryParams['src'];
      final campaign = queryParams['utm_campaign'];
      
      debugPrint('$_logTag: Tracking shared link click for user: $userId');
      debugPrint('$_logTag: Referrer: $referrer, Source: $source, Campaign: $campaign');
      
      // Analytics.track('shared_link_clicked', {
      //   'userId': userId,
      //   'referrer': referrer,
      //   'source': source,
      //   'campaign': campaign,
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      debugPrint('$_logTag: Error tracking shared link click: $e');
    }
  }
  
  /// Generate trackable deep link with analytics parameters
  static String generateTrackableLink(
    String basePath, {
    String? source,
    String? medium,
    String? campaign,
    Map<String, String>? additionalParams,
  }) {
    try {
      final uri = Uri.parse('${RoutePaths.deepLinkPrefix}$basePath');
      final queryParams = <String, String>{};
      
      if (source != null) queryParams['utm_source'] = source;
      if (medium != null) queryParams['utm_medium'] = medium;
      if (campaign != null) queryParams['utm_campaign'] = campaign;
      
      if (additionalParams != null) {
        queryParams.addAll(additionalParams);
      }
      
      if (queryParams.isNotEmpty) {
        return uri.replace(queryParameters: queryParams).toString();
      }
      
      return uri.toString();
    } catch (e) {
      debugPrint('$_logTag: Error generating trackable link: $e');
      return '${RoutePaths.deepLinkPrefix}$basePath';
    }
  }
  
  /// Validate deep link format
  static bool isValidDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.scheme == 'dabbler' || 
             (uri.scheme == 'https' && uri.host == 'dabbler.app');
    } catch (e) {
      debugPrint('$_logTag: Invalid deep link format: $link');
      return false;
    }
  }
  
  /// Extract user ID from profile deep link
  static String? extractUserIdFromProfileLink(String link) {
    try {
      final uri = Uri.parse(link);
      final segments = uri.pathSegments;
      
      if (segments.length >= 2 && segments[0] == 'profile') {
        return segments[1];
      }
      
      return null;
    } catch (e) {
      debugPrint('$_logTag: Error extracting user ID from link: $e');
      return null;
    }
  }
}

/// Extension for easy deep link handling
extension DeepLinkExtension on BuildContext {
  /// Handle deep link in current context
  void handleDeepLink(String link) {
    DeepLinkHandler.handleDeepLink(this, link);
  }
  
  /// Navigate using deep link path
  void navigateToDeepLinkPath(String path) {
    DeepLinkHandler.handleDeepLink(this, '${RoutePaths.deepLinkPrefix}$path');
  }
}
