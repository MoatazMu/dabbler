import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/constants/route_constants.dart';

/// Route guard utility for protecting authenticated routes
class RouteGuard {
  static const String _logTag = 'RouteGuard';

  /// Check if user is authenticated for accessing protected routes
  static String? authGuard(BuildContext context, GoRouterState state, WidgetRef ref) {
    try {
      // final authState = ref.read(authNotifierProvider);
      
      // Temporary: always allow access until real auth is wired
      return null;
    } catch (e) {
      debugPrint('$_logTag: Error checking authentication: $e');
      return RoutePaths.phoneInput;
    }
  }

  /// Check if user can edit the specified profile (own profile only)
  static String? profileEditGuard(
    BuildContext context, 
    GoRouterState state, 
    WidgetRef ref,
  ) {
    try {
      // First check if user is authenticated
      final authRedirect = authGuard(context, state, ref);
      if (authRedirect != null) {
        return authRedirect;
      }

      final userId = state.pathParameters['userId'];
      // final currentUser = ref.read(authNotifierProvider).value;
      final currentUserId = 'mock-user-id'; // Mock current user ID

      // If viewing another user's profile, redirect to view-only profile
      if (userId != null && userId != currentUserId) {
        debugPrint('$_logTag: User cannot edit another user\'s profile');
        return '/profile/$userId';
      }

      // User can edit their own profile
      return null;
    } catch (e) {
      debugPrint('$_logTag: Error checking profile edit permission: $e');
      return RoutePaths.profile;
    }
  }

  /// Check if user can access admin features
  static String? adminGuard(BuildContext context, GoRouterState state, WidgetRef ref) {
    try {
      // First check if user is authenticated
      final authRedirect = authGuard(context, state, ref);
      if (authRedirect != null) {
        return authRedirect;
      }

      // Temporary: allow access; wire real admin logic later
      return null;
    } catch (e) {
      debugPrint('$_logTag: Error checking admin permission: $e');
      return RoutePaths.home;
    }
  }

  /// Get current user ID for route validation
  static String? getCurrentUserId(WidgetRef ref) {
    try {
      // final authState = ref.read(authNotifierProvider);
      // return authState.hasValue ? authState.value?.id : null;
      return 'mock-user-id'; // Mock implementation
    } catch (e) {
      debugPrint('$_logTag: Error getting current user ID: $e');
      return null;
    }
  }

  /// Check if user is viewing their own profile
  static bool isOwnProfile(String? profileUserId, WidgetRef ref) {
    try {
      final currentUserId = getCurrentUserId(ref);
      return profileUserId == null || profileUserId == currentUserId;
    } catch (e) {
      debugPrint('$_logTag: Error checking own profile: $e');
      return false;
    }
  }

  /// Validate route parameters
  static bool validateRouteParameters(GoRouterState state, List<String> requiredParams) {
    try {
      for (final param in requiredParams) {
        if (state.pathParameters[param] == null || 
            state.pathParameters[param]!.isEmpty) {
          debugPrint('$_logTag: Missing required parameter: $param');
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('$_logTag: Error validating route parameters: $e');
      return false;
    }
  }

  /// Handle route errors gracefully
  static void handleRouteError(BuildContext context, String error) {
    try {
      debugPrint('$_logTag: Route error: $error');
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('$_logTag: Error handling route error: $e');
    }
  }
}

/// Custom page transition builder for profile routes
class ProfilePageTransition {
  /// Slide transition from right
  static CustomTransitionPage<void> slideFromRight(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOutCubic)),
          ),
          child: child,
        );
      },
    );
  }

  /// Fade transition
  static CustomTransitionPage<void> fade(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Scale transition
  static CustomTransitionPage<void> scale(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.8, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOutCubic)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Slide from bottom (for modal-like screens)
  static CustomTransitionPage<void> slideFromBottom(
    Widget child, {
    String? name,
    Object? arguments,
    String? restorationId,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<void>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        );
      },
    );
  }
}

/// Custom transition page implementation
class CustomTransitionPage<T> extends Page<T> {
  final Widget child;
  final Duration transitionDuration;
  final RouteTransitionsBuilder transitionsBuilder;

  const CustomTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      transitionsBuilder: transitionsBuilder,
    );
  }
}
