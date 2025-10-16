import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/constants/route_constants.dart';

/// Service for handling profile navigation with analytics and error handling
class ProfileNavigationService {
  static const String _logTag = 'ProfileNavigationService';

  /// Navigate to any user's profile
  static Future<void> navigateToProfile(
    BuildContext context, {
    String? userId,
    Map<String, dynamic>? extra,
    bool trackAnalytics = true,
  }) async {
    try {
      if (trackAnalytics) {
        await _trackNavigation('profile_view', {'userId': userId});
      }

      if (userId != null) {
        context.pushNamed(
          RouteNames.profileUser,
          pathParameters: {'userId': userId},
          extra: extra,
        );
      } else {
        context.pushNamed(RouteNames.profile, extra: extra);
      }
    } catch (e) {
      debugPrint('$_logTag: Error navigating to profile: $e');
      _handleNavigationError(context, 'profile');
    }
  }

  /// Navigate to profile edit screen (requires authentication)
  static Future<void> navigateToEditProfile(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      final isAuthenticated = await _checkAuthentication(ref);
      if (!isAuthenticated) {
        _redirectToLogin(context);
        return;
      }

      await _trackNavigation('profile_edit_view', {});
      
      if (context.mounted) {
        context.pushNamed(RouteNames.profileEdit, extra: extra);
      }
    } catch (e) {
      debugPrint('$_logTag: Error navigating to edit profile: $e');
      _handleNavigationError(context, 'edit_profile');
    }
  }

  /// Navigate to photo management screen
  static Future<void> navigateToPhotoEdit(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      final isAuthenticated = await _checkAuthentication(ref);
      if (!isAuthenticated) {
        _redirectToLogin(context);
        return;
      }

      await _trackNavigation('profile_photo_edit', {});
      
      if (context.mounted) {
        context.pushNamed(RouteNames.profileEditPhoto, extra: extra);
      }
    } catch (e) {
      debugPrint('$_logTag: Error navigating to photo edit: $e');
      _handleNavigationError(context, 'photo_edit');
    }
  }

  /// Navigate to sports preferences screen
  static Future<void> navigateToSportsEdit(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      final isAuthenticated = await _checkAuthentication(ref);
      if (!isAuthenticated) {
        _redirectToLogin(context);
        return;
      }

      await _trackNavigation('profile_sports_edit', {});
      
      if (context.mounted) {
        context.pushNamed(RouteNames.profileEditSports, extra: extra);
      }
    } catch (e) {
      debugPrint('$_logTag: Error navigating to sports edit: $e');
      _handleNavigationError(context, 'sports_edit');
    }
  }

  /// Navigate to settings screen
  static Future<void> navigateToSettings(
    BuildContext context, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _trackNavigation('settings_view', {});
      context.pushNamed(RouteNames.settings, extra: extra);
    } catch (e) {
      debugPrint('$_logTag: Error navigating to settings: $e');
      _handleNavigationError(context, 'settings');
    }
  }

  /// Navigate to privacy settings
  static Future<void> navigateToPrivacySettings(
    BuildContext context, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _trackNavigation('privacy_settings_view', {});
      context.pushNamed(RouteNames.settingsPrivacy, extra: extra);
    } catch (e) {
      debugPrint('$_logTag: Error navigating to privacy settings: $e');
      _handleNavigationError(context, 'privacy_settings');
    }
  }

  /// Navigate to notification settings
  static Future<void> navigateToNotificationSettings(
    BuildContext context, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _trackNavigation('notification_settings_view', {});
      context.pushNamed(RouteNames.settingsNotifications, extra: extra);
    } catch (e) {
      debugPrint('$_logTag: Error navigating to notification settings: $e');
      _handleNavigationError(context, 'notification_settings');
    }
  }

  /// Navigate to account settings
  static Future<void> navigateToAccountSettings(
    BuildContext context, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _trackNavigation('account_settings_view', {});
      context.pushNamed(RouteNames.settingsAccount, extra: extra);
    } catch (e) {
      debugPrint('$_logTag: Error navigating to account settings: $e');
      _handleNavigationError(context, 'account_settings');
    }
  }

  /// Navigate back with proper stack preservation
  static void navigateBack(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(RouteNames.home);
      }
    } catch (e) {
      debugPrint('$_logTag: Error navigating back: $e');
      context.goNamed(RouteNames.home);
    }
  }

  /// Check if user is viewing their own profile
  static bool isOwnProfile(String? userId, WidgetRef ref) {
    try {
      // final user = ref.read(authNotifierProvider).value;
      // return userId == null || userId == user?.id;
      return userId == null; // Mock implementation
    } catch (e) {
      debugPrint('$_logTag: Error checking own profile: $e');
      return false;
    }
  }

  /// Private helper methods
  
  static Future<bool> _checkAuthentication(WidgetRef ref) async {
    try {
      // final authState = ref.read(authNotifierProvider);
      // return authState.hasValue && authState.value != null;
      return true; // Mock implementation - assume authenticated
    } catch (e) {
      debugPrint('$_logTag: Error checking authentication: $e');
      return false;
    }
  }

  static void _redirectToLogin(BuildContext context) {
    try {
      context.goNamed(RouteNames.login);
    } catch (e) {
      debugPrint('$_logTag: Error redirecting to login: $e');
    }
  }

  static Future<void> _trackNavigation(String event, Map<String, dynamic> parameters) async {
    try {
      debugPrint('$_logTag: Navigation event: $event, params: $parameters');
    } catch (e) {
      debugPrint('$_logTag: Error tracking navigation: $e');
    }
  }

  static void _handleNavigationError(BuildContext context, String route) {
    try {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to navigate to $route. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('$_logTag: Error showing navigation error: $e');
    }
  }
}

/// Extension methods for easy navigation
extension ProfileNavigationExtension on BuildContext {
  /// Navigate to profile
  Future<void> navigateToProfile([String? userId]) async {
    await ProfileNavigationService.navigateToProfile(this, userId: userId);
  }

  /// Navigate to settings
  Future<void> navigateToSettings() async {
    await ProfileNavigationService.navigateToSettings(this);
  }
}

/// Provider for the navigation service
final profileNavigationServiceProvider = Provider<ProfileNavigationService>((ref) {
  return ProfileNavigationService();
});
