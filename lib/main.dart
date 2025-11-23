import 'dart:async';
import 'package:dabbler/core/config/environment.dart';
import 'package:dabbler/core/config/feature_flags.dart';
import 'package:dabbler/core/services/analytics/analytics_service.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/core/services/theme_service.dart';
import 'package:dabbler/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'app/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/responsive_app_shell.dart';
import 'services/notifications/push_notification_service.dart';

// Feature flags for future functionality
class AppFeatures {
  static const bool enableReferralProgram = false; // ✅ Toggle for future use
  static const bool enableDeepLinks =
      enableReferralProgram; // Links to referral feature
}

// Guard to send flags snapshot only once per session
bool _flagsLogged = false;

void _logFlagsOnce() {
  if (_flagsLogged) return;
  _flagsLogged = true;
  AnalyticsService.trackEvent('flags_snapshot', {
    'multiSport': FeatureFlags.multiSport,
    'organiserProfile': FeatureFlags.organiserProfile,
    'playerGameCreation': FeatureFlags.enablePlayerGameCreation,
    'organiserGameCreation': FeatureFlags.enableOrganiserGameCreation,
    'playerGameJoining': FeatureFlags.enablePlayerGameJoining,
    'organiserGameJoining': FeatureFlags.enableOrganiserGameJoining,
    'socialFeed': FeatureFlags.socialFeed,
    'messaging': FeatureFlags.messaging,
    'notifications': FeatureFlags.notifications,
    'squads': FeatureFlags.squads,
    'venuesBooking': FeatureFlags.venuesBooking,
    'payments': FeatureFlags.enablePayments,
    'bookingFlow': FeatureFlags.enableBookingFlow,
    'rewards': FeatureFlags.enableRewards,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable inspector features for web debugging
  if (kIsWeb && kDebugMode) {
    debugProfileBuildsEnabled = false;
  }

  try {
    await Environment.load();

    // Initialize theme and location services before running the app
    await ThemeService().init();
    await LocationService().init();

    final anonKey = Environment.supabaseAnonKey;

    // Initialize Supabase with deep-link detection enabled for auth flows
    // This is required so that OAuth providers (e.g. Google) can return
    // to the app and have the session detected from the redirect URL.
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // Must be true for Google sign-in to work correctly (PKCE flow).
        // Referral deep links can still be controlled separately via feature flags.
        detectSessionInUri: true,
        autoRefreshToken: true,
      ),
    );

    // Initialize push notifications & request OS permissions if enabled
    // On web, this will be a no-op to avoid Firebase Messaging web compatibility issues
    if (FeatureFlags.enablePushNotifications) {
      await PushNotificationService.instance.init();
    }

    // Log the Supabase authorization token (JWT) after initialization and sign-in
    final authService = Supabase.instance.client.auth;
    final session = authService.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken != null) {
      // Use debugPrint for logging in development
      debugPrint('Supabase Authorization Token: $accessToken');
    } else {
      debugPrint(
        'No Supabase Authorization Token found. User may not be signed in.',
      );
    }

    // Log feature flags snapshot once per session
    _logFlagsOnce();

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    // Log minimal error information without excessive debug output
    // ignore: avoid_print
    // ...existing code...
    // Still try to run the app even if there's an error
    runApp(const ProviderScope(child: MyApp()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Use a single ThemeService instance to avoid recreating listeners on rebuilds
  static final ThemeService _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Dabbler',
          routerConfig: appRouter,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeService.effectiveThemeMode,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            return ResponsiveAppShell(maxContentWidth: 500, child: child);
          },
        );
      },
    );
  }
}
