import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Onboarding screens
import 'package:dabbler/features/misc/presentation/screens/phone_input_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/email_input_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/otp_verification_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/create_user_information.dart';
import 'package:dabbler/features/misc/presentation/screens/sports_selection_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/intent_selection_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/set_password_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/set_username_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/welcome_screen.dart';

// Authentication screens
import 'package:dabbler/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:dabbler/features/authentication/presentation/screens/enter_password_screen.dart';
import 'package:dabbler/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:dabbler/features/authentication/presentation/screens/register_screen.dart';

// Core screens
import 'package:dabbler/features/error/presentation/pages/error_page.dart';
import 'package:dabbler/features/home/presentation/screens/home_screen.dart';
import 'package:dabbler/features/social/presentation/screens/social_screen.dart';
import 'package:dabbler/features/explore/presentation/screens/explore_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/activities_screen_v2.dart';
import 'package:dabbler/features/misc/presentation/screens/rewards_screen.dart';

// Profile screens
import 'package:dabbler/features/profile/presentation/screens/profile/profile_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/settings/settings_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/settings/profile_avatar_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/settings/profile_sports_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/settings/account_management_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/settings/privacy_settings_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/settings/notification_settings_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/preferences/game_preferences_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/preferences/availability_preferences_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/theme_settings_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/language_selection_screen.dart';
import 'package:dabbler/features/misc/presentation/screens/help_center_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/support/contact_support_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/support/bug_report_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/about/terms_of_service_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/about/privacy_policy_screen.dart';
import 'package:dabbler/features/profile/presentation/screens/about/licenses_screen.dart';

// Transactions screens
import 'package:dabbler/features/misc/presentation/screens/transactions_screen.dart';

// Notifications screens
import 'package:dabbler/features/notifications/presentation/screens/notifications_screen_v2.dart';

// Game screens
import 'package:dabbler/features/misc/presentation/screens/create_game_screen.dart';

// Social screens
import 'package:dabbler/features/misc/presentation/screens/add_post_screen.dart';
import 'package:dabbler/features/social/presentation/screens/social_feed_screen.dart';
import 'package:dabbler/features/social/presentation/screens/social_search_screen.dart';
import 'package:dabbler/features/social/presentation/screens/placeholders/social_profile_screen.dart';
import 'package:dabbler/features/social/presentation/screens/social_feed/post_detail_screen.dart';
import 'package:dabbler/features/social/presentation/screens/onboarding/social_onboarding_welcome_screen.dart';
import 'package:dabbler/features/social/presentation/screens/onboarding/social_onboarding_friends_screen.dart';
import 'package:dabbler/features/social/presentation/screens/onboarding/social_onboarding_privacy_screen.dart';
import 'package:dabbler/features/social/presentation/screens/onboarding/social_onboarding_notifications_screen.dart';
import 'package:dabbler/features/social/presentation/screens/onboarding/social_onboarding_complete_screen.dart';

// Utilities
import '../utils/constants/route_constants.dart';
import 'package:dabbler/features/authentication/presentation/providers/auth_providers.dart';
import '../utils/transitions/page_transitions.dart';
import '../routes/route_arguments.dart';

// Import RegistrationData from the correct location

// Export GoRouter instance for use in main.dart
final appRouter = AppRouter.router;

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Analytics Observer
  static final _routeObserver = RouteObserver<ModalRoute<void>>();
  static RouteObserver<ModalRoute<void>> get routeObserver => _routeObserver;

  // Router Instance
  // Toggle for verbose route logging (only active in debug mode)
  static const bool _routeLogging =
      true; // set false to silence even debug prints

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.phoneInput, // Start with phone input screen
    debugLogDiagnostics: true, // Enable debug logging to see what's happening
    observers: [_routeObserver],
    errorBuilder: (context, state) => ErrorPage(message: state.error?.message),
    // Restore redirects for proper navigation flow
    redirect: _handleRedirect,
    // Refresh router when auth state changes
    refreshListenable: routerRefreshNotifier,
    routes: _routes,
  );

  // Auth Redirect Logic
  static FutureOr<String?> _handleRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    if (kDebugMode && _routeLogging) {
      // Compact single-line log
      debugPrint('🔍 [ROUTER] redirect check -> ${state.matchedLocation}');
    }

    try {
      // Access Riverpod container to read auth/guest state
      final container = ProviderScope.containerOf(context, listen: false);
      final isAuthenticated = container.read(isAuthenticatedProvider);
      final isGuest = container.read(isGuestProvider);

      // Also read the full auth state for debugging
      final authState = container.read(simpleAuthProvider);

      if (kDebugMode && _routeLogging) {
        debugPrint(
          '🔍 [ROUTER] auth=$isAuthenticated guest=$isGuest loading=${authState.isLoading} error=${authState.error}',
        );
      }

      // Auth paths: Routes that unauthenticated users can access
      // Includes onboarding screens because email users are unauthenticated during onboarding
      // Phone users become authenticated before onboarding, so we handle them separately
      const authPaths = <String>{
        RoutePaths.register,
        RoutePaths.enterPassword,
        RoutePaths.forgotPassword,
        RoutePaths.resetPassword,
        RoutePaths.phoneInput,
        RoutePaths.emailInput,
        RoutePaths.otpVerification,
        RoutePaths.createUserInfo,
        RoutePaths.intentSelection,
        RoutePaths.sportsSelection,
        RoutePaths.setPassword,
        RoutePaths.setUsername,
      };

      // Onboarding paths that both authenticated and unauthenticated users can access
      // Phone users: authenticated via OTP, completing profile
      // Email users: unauthenticated, will create account in final step
      const onboardingPaths = <String>{
        RoutePaths.otpVerification,
        RoutePaths.createUserInfo,
        RoutePaths.intentSelection,
        RoutePaths.sportsSelection,
        RoutePaths.setPassword,
        RoutePaths.setUsername,
      };

      final loc = state.matchedLocation;
      final isOnAuthPage = authPaths.contains(loc);
      final isOnboardingPage = onboardingPaths.contains(loc);

      if (kDebugMode && _routeLogging) {
        debugPrint(
          '🔍 [ROUTER] loc=$loc, isOnAuthPage=$isOnAuthPage, authPaths contains: ${authPaths.contains(loc)}',
        );
      }

      // Don't redirect while auth state is loading
      if (authState.isLoading) {
        if (kDebugMode && _routeLogging) {
          debugPrint('🔍 [ROUTER] Auth state loading, staying on current page');
        }
        return null;
      }

      // If not authenticated, always stay on onboarding/auth screens
      if (!isAuthenticated) {
        // If not on an auth page, redirect to phone input
        if (!isOnAuthPage) {
          if (kDebugMode && _routeLogging) {
            debugPrint('🔁 [ROUTER] redirect -> ${RoutePaths.phoneInput}');
          }
          return RoutePaths.phoneInput;
        }
        // Stay on auth page
        if (kDebugMode && _routeLogging) {
          debugPrint('🔍 [ROUTER] Staying on auth page: $loc');
        }
        return null;
      }

      // If authenticated and on an auth page (except welcome and onboarding), go home
      // Allow authenticated users to access onboarding (for phone users completing profile)
      if (isAuthenticated &&
          isOnAuthPage &&
          loc != '/welcome' &&
          !isOnboardingPage) {
        if (kDebugMode && _routeLogging) {
          debugPrint(
            '🔁 [ROUTER] ✅ Authenticated user on auth page, redirect -> home',
          );
        }
        return RoutePaths.home;
      }

      if (kDebugMode && _routeLogging) {
        debugPrint('🔍 [ROUTER] No redirect needed for: $loc');
      }
      return null;
    } catch (e) {
      if (kDebugMode && _routeLogging) {
        debugPrint('❌ [ROUTER] Error in redirect logic: $e');
      }
      return null;
    }
  }

  // Route Definitions - Minimal working set
  static List<RouteBase> get _routes => [
    GoRoute(
      path: RoutePaths.phoneInput,
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const PhoneInputScreen(),
      ),
    ),

    // Email input route
    GoRoute(
      path: RoutePaths.emailInput,
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const EmailInputScreen(),
      ),
    ),

    // OTP verification route
    GoRoute(
      path: RoutePaths.otpVerification,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final phone = extra is Map
            ? extra['phone'] as String?
            : extra as String?;
        final userExistsBeforeOtp = extra is Map
            ? extra['userExistsBeforeOtp'] as bool?
            : null;
        return FadeTransitionPage(
          key: state.pageKey,
          child: OtpVerificationScreen(
            phoneNumber: phone,
            userExistsBeforeOtp: userExistsBeforeOtp,
          ),
        );
      },
    ),

    // Enter password route
    GoRoute(
      path: RoutePaths.enterPassword,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final email = extra is Map
            ? extra['email'] as String?
            : extra as String?;
        return FadeTransitionPage(
          key: state.pageKey,
          child: EnterPasswordScreen(email: email ?? ''),
        );
      },
    ),

    // Forgot password route
    GoRoute(
      path: RoutePaths.forgotPassword,
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const ForgotPasswordScreen(),
      ),
    ),

    // Reset password route
    GoRoute(
      path: RoutePaths.resetPassword,
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const ResetPasswordScreen(),
      ),
    ),

    // Register route
    GoRoute(
      path: RoutePaths.register,
      pageBuilder: (context, state) =>
          FadeTransitionPage(key: state.pageKey, child: const RegisterScreen()),
    ),

    // Create user information route
    GoRoute(
      path: RoutePaths.createUserInfo,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final email = extra is Map
            ? extra['email'] as String?
            : (extra is String ? extra : null);
        final phone = extra is Map ? extra['phone'] as String? : null;
        final forceNew = extra is Map ? extra['forceNew'] as bool? : false;
        return SlideTransitionPage(
          key: state.pageKey,
          child: CreateUserInformation(
            email: email,
            phone: phone,
            forceNew: forceNew ?? false,
          ),
          direction: SlideDirection.fromLeft,
        );
      },
    ),

    // Language selection route (placeholder)
    GoRoute(
      path: '/language_selection',
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const Scaffold(
          body: Center(child: Text('Language Selection - Coming Soon')),
        ),
      ),
    ),

    // Sports selection route
    GoRoute(
      path: RoutePaths.sportsSelection,
      pageBuilder: (context, state) {
        return SlideTransitionPage(
          key: state.pageKey,
          child: const SportsSelectionScreen(),
          direction: SlideDirection.fromLeft,
        );
      },
    ),

    // Intent selection route
    GoRoute(
      path: RoutePaths.intentSelection,
      pageBuilder: (context, state) {
        return SlideTransitionPage(
          key: state.pageKey,
          child: const IntentSelectionScreen(),
          direction: SlideDirection.fromLeft,
        );
      },
    ),

    // Set password route (for email users)
    GoRoute(
      path: RoutePaths.setPassword,
      pageBuilder: (context, state) {
        return SlideTransitionPage(
          key: state.pageKey,
          child: const SetPasswordScreen(),
          direction: SlideDirection.fromLeft,
        );
      },
    ),

    // Set username route (for phone users)
    GoRoute(
      path: RoutePaths.setUsername,
      pageBuilder: (context, state) {
        return SlideTransitionPage(
          key: state.pageKey,
          child: const SetUsernameScreen(),
          direction: SlideDirection.fromLeft,
        );
      },
    ),

    // Welcome route
    GoRoute(
      path: RoutePaths.welcome,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final displayName = extra is Map
            ? extra['displayName'] as String?
            : 'Player';
        return ScaleTransitionPage(
          key: state.pageKey,
          child: WelcomeScreen(displayName: displayName ?? 'Player'),
        );
      },
    ),

    // Home route
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
      ),
    ),

    // Social/Community route
    GoRoute(
      path: RoutePaths.social,
      name: RouteNames.social,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const SocialScreen(),
      ),
    ),

    // Explore/Sports route
    GoRoute(
      path: RoutePaths.explore,
      name: RouteNames.explore,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const ExploreScreen(),
      ),
    ),

    // Activities route
    GoRoute(
      path: RoutePaths.activities,
      name: RouteNames.activities,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const ActivitiesScreenV2(),
      ),
    ),

    // Rewards route
    GoRoute(
      path: RoutePaths.rewards,
      name: RouteNames.rewards,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const RewardsScreen(),
      ),
    ),

    // Profile route
    GoRoute(
      path: RoutePaths.profile,
      name: RouteNames.profile,
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const ProfileScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    // Notifications route
    GoRoute(
      path: RoutePaths.notifications,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const NotificationsScreenV2(),
      ),
    ),

    // Profile Edit route
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) => BottomSheetTransitionPage(
        key: state.pageKey,
        child: const ProfileEditScreen(),
      ),
    ),

    // Profile Photo route
    GoRoute(
      path: '/profile/photo',
      pageBuilder: (context, state) => ScaleTransitionPage(
        key: state.pageKey,
        child: const ProfileAvatarScreen(),
      ),
    ),

    // Profile Sports Preferences route
    GoRoute(
      path: '/profile/sports-preferences',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const ProfileSportsScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    // Settings route
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    // Transactions route
    GoRoute(
      path: '/transactions',
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const TransactionsScreen(),
      ),
    ),

    // Game Creation Routes
    GoRoute(
      path: RoutePaths.createGame,
      name: RouteNames.createGame,
      pageBuilder: (context, state) => BottomSheetTransitionPage(
        key: state.pageKey,
        child: CreateGameScreen(
          initialData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
    ),

    GoRoute(
      path: RoutePaths.createGameBasicInfo,
      name: RouteNames.createGameBasicInfo,
      pageBuilder: (context, state) => BottomSheetTransitionPage(
        key: state.pageKey,
        child: CreateGameScreen(
          initialData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
    ),

    // Settings sub-routes
    GoRoute(
      path: '/settings/account',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const AccountManagementScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    GoRoute(
      path: '/settings/privacy',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const PrivacySettingsScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    GoRoute(
      path: '/settings/notifications',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const NotificationSettingsScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    GoRoute(
      path: '/settings/theme',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const ThemeSettingsScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    GoRoute(
      path: '/settings/language',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const LanguageSelectionScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    // Preferences routes
    GoRoute(
      path: '/preferences/games',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const GamePreferencesScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    GoRoute(
      path: '/preferences/availability',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const AvailabilityPreferencesScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    // Help & Support routes
    GoRoute(
      path: '/help/center',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const HelpCenterScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    GoRoute(
      path: '/help/contact',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const ContactSupportScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    GoRoute(
      path: '/help/bug-report',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const BugReportScreen(),
        type: SharedAxisType.horizontal,
      ),
    ),

    // About routes
    GoRoute(
      path: '/about/terms',
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const TermsOfServiceScreen(),
      ),
    ),

    GoRoute(
      path: '/about/privacy',
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const PrivacyPolicyScreen(),
      ),
    ),

    GoRoute(
      path: '/about/licenses',
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const LicensesScreen(),
      ),
    ),

    // Add Post route
    GoRoute(
      path: RoutePaths.addPost,
      name: 'add-post',
      pageBuilder: (context, state) => BottomSheetTransitionPage(
        key: state.pageKey,
        child: const AddPostScreen(),
      ),
    ),

    // Social Create Post route (alias for add post)
    GoRoute(
      path: RoutePaths.socialCreatePost,
      name: RouteNames.socialCreatePost,
      pageBuilder: (context, state) => BottomSheetTransitionPage(
        key: state.pageKey,
        child: const AddPostScreen(),
      ),
    ),

    // Social Routes
    GoRoute(
      path: RoutePaths.socialFeed,
      name: RouteNames.socialFeed,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const SocialFeedScreen(),
      ),
    ),

    GoRoute(
      path: RoutePaths.socialSearch,
      name: RouteNames.socialSearch,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const SocialSearchScreen(),
      ),
    ),

    GoRoute(
      path: '${RoutePaths.socialPostDetail}/:postId',
      name: RouteNames.socialPostDetail,
      pageBuilder: (context, state) {
        final postId = state.pathParameters['postId'] ?? '';
        return ScaleTransitionPage(
          key: state.pageKey,
          child: PostDetailScreen(postId: postId),
        );
      },
    ),

    GoRoute(
      path: '${RoutePaths.socialProfile}/:userId',
      name: RouteNames.socialProfile,
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId'] ?? '';
        return SharedAxisTransitionPage(
          key: state.pageKey,
          child: SocialProfileScreen(userId: userId),
          type: SharedAxisType.horizontal,
        );
      },
    ),

    // Social Onboarding Routes
    GoRoute(
      path: RoutePaths.socialOnboardingWelcome,
      name: RouteNames.socialOnboardingWelcome,
      pageBuilder: (context, state) => SlideTransitionPage(
        key: state.pageKey,
        child: const SocialOnboardingWelcomeScreen(),
        direction: SlideDirection.fromLeft,
      ),
    ),

    GoRoute(
      path: RoutePaths.socialOnboardingFriends,
      name: RouteNames.socialOnboardingFriends,
      pageBuilder: (context, state) => SlideTransitionPage(
        key: state.pageKey,
        child: const SocialOnboardingFriendsScreen(),
        direction: SlideDirection.fromLeft,
      ),
    ),

    GoRoute(
      path: RoutePaths.socialOnboardingPrivacy,
      name: RouteNames.socialOnboardingPrivacy,
      pageBuilder: (context, state) => SlideTransitionPage(
        key: state.pageKey,
        child: const SocialOnboardingPrivacyScreen(),
        direction: SlideDirection.fromLeft,
      ),
    ),

    GoRoute(
      path: RoutePaths.socialOnboardingNotifications,
      name: RouteNames.socialOnboardingNotifications,
      pageBuilder: (context, state) => SlideTransitionPage(
        key: state.pageKey,
        child: const SocialOnboardingNotificationsScreen(),
        direction: SlideDirection.fromLeft,
      ),
    ),

    GoRoute(
      path: RoutePaths.socialOnboardingComplete,
      name: RouteNames.socialOnboardingComplete,
      pageBuilder: (context, state) => ScaleTransitionPage(
        key: state.pageKey,
        child: const SocialOnboardingCompleteScreen(),
      ),
    ),

    // Placeholder Social Routes (for routes referenced in code but screens don't exist yet)
    GoRoute(
      path: RoutePaths.socialChatList,
      name: RouteNames.socialChatList,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const _PlaceholderScreen(title: 'Chat List'),
      ),
    ),

    GoRoute(
      path: RoutePaths.socialFriends,
      name: RouteNames.socialFriends,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const _PlaceholderScreen(title: 'Friends'),
      ),
    ),

    GoRoute(
      path: RoutePaths.socialNotifications,
      name: RouteNames.socialNotifications,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const _PlaceholderScreen(title: 'Social Notifications'),
      ),
    ),

    GoRoute(
      path: RoutePaths.socialMessages,
      name: RouteNames.socialMessages,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const _PlaceholderScreen(title: 'Messages'),
      ),
    ),

    GoRoute(
      path: RoutePaths.socialChat,
      name: RouteNames.socialChat,
      pageBuilder: (context, state) => FadeThroughTransitionPage(
        key: state.pageKey,
        child: const _PlaceholderScreen(title: 'Chat'),
      ),
    ),

    GoRoute(
      path: RoutePaths.socialEditPost,
      name: RouteNames.socialEditPost,
      pageBuilder: (context, state) => BottomSheetTransitionPage(
        key: state.pageKey,
        child: const _PlaceholderScreen(title: 'Edit Post'),
      ),
    ),

    GoRoute(
      path: RoutePaths.socialAnalytics,
      name: RouteNames.socialAnalytics,
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        child: const _PlaceholderScreen(title: 'Social Analytics'),
        type: SharedAxisType.horizontal,
      ),
    ),

    // Error route
    GoRoute(
      path: '${RoutePaths.error}:message',
      name: RouteNames.error,
      pageBuilder: (context, state) {
        final message = state.pathParameters['message'];
        return FadeTransitionPage(
          key: state.pageKey,
          child: ErrorPage(message: message),
        );
      },
    ),
  ];
}

/// Placeholder screen for routes that don't have screens implemented yet
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$title\nComing Soon',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
