import 'package:flutter/material.dart';
import '../screens/explore/match_detail_screen.dart';
import '../features/venues/presentation/screens/venue_detail_screen.dart';
import '../screens/explore/booking_flow_screen.dart';
import '../screens/explore/booking_success_screen.dart';
import '../features/profile/presentation/screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/payment_methods_screen.dart';
import '../screens/game/create_game_screen.dart';
import '../features/games/presentation/screens/join_game/game_detail_screen.dart';
import '../screens/game/invite_players_screen.dart';
import '../screens/onboarding/phone_input_screen.dart';
import '../screens/onboarding/otp_verification_screen.dart';
import '../screens/onboarding/create_user_information.dart';
import '../screens/onboarding/sports_selection_screen.dart';
import '../screens/onboarding/intent_selection_screen.dart';
import '../screens/onboarding/language_selection_screen.dart';
import '../screens/onboarding/change_phone_screen.dart';
import '../screens/support/help_center_screen.dart';
import '../screens/support/contact_support_screen.dart';
import '../screens/support/faq_screen.dart';
import '../screens/loyalty/rewards_center_screen.dart';
import '../screens/loyalty/points_detail_screen.dart';
import '../screens/loyalty/badge_detail_screen.dart';
import '../screens/bookings/checkin_screen.dart';
import '../screens/bookings/rate_game_screen.dart';
import '../screens/bookings/rebook_flow.dart';
import '../screens/notifications/notifications_screen_v2.dart';
import '../screens/notifications/notification_settings_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/social/social_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/activities/activities_screen_v2.dart';

import '../features/profile/presentation/screens/onboarding/onboarding_welcome_screen.dart';
import '../features/profile/presentation/screens/onboarding/onboarding_basic_info_screen.dart';
import '../features/profile/presentation/screens/onboarding/onboarding_sports_screen.dart';
import '../features/profile/presentation/screens/onboarding/onboarding_preferences_screen.dart';
import '../features/profile/presentation/screens/onboarding/onboarding_privacy_screen.dart';
import '../features/profile/presentation/screens/onboarding/onboarding_completion_screen.dart';

// Page transition types
enum PageTransitionType {
  slideUp,
  slideLeft,
  slideRight,
  fadeIn,
  scale,
}

class AppRoutes {
  // Main navigation routes (handled by GoRouter)
  static const String home = '/';
  static const String explore = '/explore';
  static const String bookings = '/bookings';
  
  // Game routes
  static const String gameCreate = '/gameCreate';
  static const String gameDetail = '/gameDetail';
  static const String invitePlayers = '/invitePlayers';
  static const String matchDetail = '/matchDetail';
  static const String venueDetail = '/venueDetail';
  
  // Booking routes
  static const String booking = '/booking';
  static const String bookingFlow = '/bookingFlow';
  static const String bookingSuccess = '/bookingSuccess';
  static const String checkin = '/checkin';
  static const String rateGame = '/rateGame';
  static const String rebook = '/rebook';
  static const String confirmation = '/confirmation';
  
  // Profile routes
  static const String profile = '/profile';
  static const String editProfile = '/editProfile';
  static const String settingsScreen = '/settingsScreen';
  static const String paymentMethods = '/paymentMethods';
  static const String themeSettings = '/themeSettings';
  
  // Enhanced profile routes
  static const String profileCompletion = '/profileCompletion';
  static const String profileOnboarding = '/profileOnboarding';
  static const String profileSettings = '/profileSettings';
  static const String profilePrivacy = '/profilePrivacy';
  static const String profileSports = '/profileSports';
  static const String profileStats = '/profileStats';
  static const String profileAvatar = '/profileAvatar';
  static const String profileDataExport = '/profileDataExport';
  static const String profileAccountDeletion = '/profileAccountDeletion';
  static const String profileViewProfile = '/profileViewProfile'; // View another user's profile
  
  // Comprehensive onboarding routes
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingBasicInfo = '/onboarding/basic-info';
  static const String onboardingSports = '/onboarding/sports';
  static const String onboardingPreferences = '/onboarding/preferences';
  static const String onboardingPrivacy = '/onboarding/privacy';
  static const String onboardingCompletion = '/onboarding/completion';
  
  // Onboarding routes
  static const String phoneInput = '/phoneInput';
  static const String otpVerification = '/otpVerification';
  static const String createUserInfo = '/createUserInfo';
  static const String sportsSelection = '/sportsSelection';
  static const String intentSelection = '/intentSelection';
  static const String languageSelection = '/languageSelection';
  static const String changePhone = '/changePhone';
  
  // Support routes
  static const String helpCenter = '/helpCenter';
  static const String contactSupport = '/contactSupport';
  static const String faq = '/faq';
  
  // Loyalty routes
  static const String rewardsCenter = '/rewardsCenter';
  static const String pointsDetail = '/pointsDetail';
  static const String badgeDetail = '/badgeDetail';
  
  // Other routes
  static const String yourMatches = '/yourMatches';
  static const String chat = '/chat';
  static const String social = '/social';
  static const String login = '/login';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notificationSettings';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    explore: (context) => const ExploreScreen(),
    bookings: (context) => const ActivitiesScreenV2(),
    social: (context) => const SocialScreen(),
  };

  // Navigation helper methods
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
  }

  static void navigateToExplore(BuildContext context) {
    Navigator.pushNamed(context, explore);
  }

  static void navigateToSocial(BuildContext context) {
    Navigator.pushNamed(context, social);
  }

  static void navigateToBookings(BuildContext context) {
    Navigator.pushNamed(context, bookings);
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, profile);
  }

  static void navigateToCreateGame(BuildContext context) {
    Navigator.pushNamed(context, gameCreate);
  }

  static void navigateToCreateGameWithDraft(BuildContext context, dynamic draft) {
    Navigator.pushNamed(context, gameCreate, arguments: draft);
  }

  static void navigateToGameDetail(BuildContext context, String gameId) {
    Navigator.pushNamed(context, gameDetail, arguments: {'gameId': gameId});
  }

  static void navigateToMatchDetail(BuildContext context, dynamic match) {
    Navigator.pushNamed(context, matchDetail, arguments: MatchDetailArgs(match: match));
  }

  static void navigateToVenueDetail(BuildContext context, dynamic venue) {
    Navigator.pushNamed(context, venueDetail, arguments: VenueDetailArgs(venue: venue));
  }

  static void navigateToBookingFlow(BuildContext context, Map<String, dynamic> venue) {
    Navigator.pushNamed(context, bookingFlow, arguments: BookingFlowArgs(venue: venue));
  }

  static void navigateToBookingSuccess(BuildContext context, BookingSuccessArgs args) {
    Navigator.pushNamed(context, bookingSuccess, arguments: args);
  }

  static void navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, editProfile);
  }

  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, settingsScreen);
  }

  static void navigateToPaymentMethods(BuildContext context) {
    Navigator.pushNamed(context, paymentMethods);
  }

  static void navigateToThemeSettings(BuildContext context) {
    Navigator.pushNamed(context, themeSettings);
  }

  static void navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(context, notifications);
  }

  static void navigateToNotificationSettings(BuildContext context) {
    Navigator.pushNamed(context, notificationSettings);
  }

  static void navigateToHelpCenter(BuildContext context) {
    Navigator.pushNamed(context, helpCenter);
  }

  static void navigateToContactSupport(BuildContext context) {
    Navigator.pushNamed(context, contactSupport);
  }

  static void navigateToFaq(BuildContext context) {
    Navigator.pushNamed(context, faq);
  }

  static void navigateToRewardsCenter(BuildContext context) {
    Navigator.pushNamed(context, rewardsCenter);
  }

  static void navigateToPointsDetail(BuildContext context) {
    Navigator.pushNamed(context, pointsDetail);
  }

  static void navigateToBadgeDetail(BuildContext context, String badgeId) {
    Navigator.pushNamed(context, badgeDetail, arguments: {'badgeId': badgeId});
  }

  static void navigateToCheckin(BuildContext context, String bookingId) {
    Navigator.pushNamed(context, checkin, arguments: {'bookingId': bookingId});
  }

  static void navigateToRateGame(BuildContext context, String gameId) {
    Navigator.pushNamed(context, rateGame, arguments: {'gameId': gameId});
  }

  static void navigateToRebook(BuildContext context, String gameId) {
    Navigator.pushNamed(context, rebook, arguments: {'gameId': gameId});
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  // Enhanced profile navigation methods
  static void navigateToProfileCompletion(BuildContext context, {Map<String, dynamic>? arguments}) {
    Navigator.pushNamed(context, profileCompletion, arguments: arguments);
  }

  static void navigateToProfileOnboarding(BuildContext context, {String? step}) {
    Navigator.pushNamed(context, profileOnboarding, arguments: {'step': step});
  }

  static void navigateToProfileSettings(BuildContext context, {String? section}) {
    Navigator.pushNamed(context, profileSettings, arguments: {'section': section});
  }

  static void navigateToProfilePrivacy(BuildContext context) {
    Navigator.pushNamed(context, profilePrivacy);
  }

  static void navigateToProfileSports(BuildContext context) {
    Navigator.pushNamed(context, profileSports);
  }

  static void navigateToProfileStats(BuildContext context, {String? userId}) {
    Navigator.pushNamed(context, profileStats, arguments: {'userId': userId});
  }

  static void navigateToProfileAvatar(BuildContext context) {
    Navigator.pushNamed(context, profileAvatar);
  }

  static void navigateToProfileDataExport(BuildContext context) {
    Navigator.pushNamed(context, profileDataExport);
  }

  static void navigateToProfileAccountDeletion(BuildContext context) {
    Navigator.pushNamed(context, profileAccountDeletion);
  }

  static void navigateToViewProfile(BuildContext context, String userId, {String? heroTag}) {
    Navigator.pushNamed(context, profileViewProfile, arguments: {
      'userId': userId,
      'heroTag': heroTag,
    });
  }

  // Navigation with custom transitions
  static void navigateToProfileWithTransition(
    BuildContext context, 
    String routeName, 
    {
      Map<String, dynamic>? arguments,
      PageTransitionType transition = PageTransitionType.slideUp,
    }
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return _getPageForRoute(routeName, arguments);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _buildTransition(transition, animation, child);
        },
        settings: RouteSettings(name: routeName, arguments: arguments),
      ),
    );
  }

  // Deep linking helpers
  static void handleProfileDeepLink(BuildContext context, Uri uri) {
    final path = uri.path;
    final queryParams = uri.queryParameters;
    
    if (path.startsWith('/profile/')) {
      final segments = path.split('/');
      if (segments.length >= 3) {
        final userId = segments[2];
        if (userId == 'me' || userId == 'current') {
          navigateToProfile(context);
        } else {
          navigateToViewProfile(context, userId);
        }
      }
    } else if (path == '/profile/completion') {
      navigateToProfileCompletion(context, arguments: queryParams);
    } else if (path == '/profile/onboarding') {
      navigateToProfileOnboarding(context, step: queryParams['step']);
    } else if (path == '/profile/settings') {
      navigateToProfileSettings(context, section: queryParams['section']);
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

      
      // Main navigation routes
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case explore:
        return MaterialPageRoute(builder: (_) => const ExploreScreen());
      case bookings:
        return MaterialPageRoute(builder: (_) => const ActivitiesScreenV2());
      
      // Profile routes
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case settingsScreen:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case paymentMethods:
        return MaterialPageRoute(builder: (_) => const PaymentMethodsScreen());
      
      // Enhanced profile routes
      case profileCompletion:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Profile Completion - Coming Soon'))
        ));
      case profileOnboarding:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Profile Onboarding - Coming Soon'))
        ));
      case profileSettings:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Profile Settings - Coming Soon'))
        ));
      case profilePrivacy:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Privacy Settings - Coming Soon'))
        ));
      case profileSports:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Sports Profile - Coming Soon'))
        ));
      case profileStats:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Profile Stats - Coming Soon'))
        ));
      case profileAvatar:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Avatar Upload - Coming Soon'))
        ));
      case profileDataExport:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Data Export - Coming Soon'))
        ));
      case profileAccountDeletion:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('Account Deletion - Coming Soon'))
        ));
      case profileViewProfile:
        return MaterialPageRoute(builder: (_) => const Scaffold(
          body: Center(child: Text('View Profile - Coming Soon'))
        ));
      
      // Game routes
      case gameCreate:
        final args = settings.arguments;
        if (args is CreateGameArguments) {
          // For now, just pass the draftId if available, or create a new game
          return MaterialPageRoute(builder: (_) => CreateGameScreen(
            draftId: args.bookingId, // Use bookingId as draftId for now
          ));
        } else if (args is Map<String, dynamic>) {
          return MaterialPageRoute(builder: (_) => CreateGameScreen(draftId: args['draftId']));
        } else {
          return MaterialPageRoute(builder: (_) => const CreateGameScreen());
        }
      case gameDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => GameDetailScreen(gameId: args['gameId']));
      case invitePlayers:
        return MaterialPageRoute(builder: (_) => const InvitePlayersScreen());
      case matchDetail:
        final args = settings.arguments as MatchDetailArgs;
        return MaterialPageRoute(builder: (_) => MatchDetailScreen(match: args.match));
      case venueDetail:
        final args = settings.arguments as VenueDetailArgs;
        return MaterialPageRoute(builder: (_) => VenueDetailScreen(venueId: args.venue['id'] ?? ''));
      
      // Booking routes
      case bookingFlow:
        final args = settings.arguments as BookingFlowArgs;
        return MaterialPageRoute(builder: (_) => BookingFlowScreen(venue: args.venue));
      case bookingSuccess:
        final args = settings.arguments as BookingSuccessArgs;
        return MaterialPageRoute(builder: (_) => BookingSuccessScreen(
          venue: args.venue,
          selectedDate: args.selectedDate,
          selectedTime: args.selectedTime,
          selectedSport: args.selectedSport,
          bookingId: args.bookingId,
        ));
      case checkin:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => CheckinScreen(bookingId: args['bookingId']));
      case rateGame:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => RateGameScreen(gameId: args['gameId']));
      case rebook:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => RebookFlow(gameId: args['gameId']));
      
      // Notification routes
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreenV2());
      case notificationSettings:
        return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());
      
      // Onboarding routes
      case phoneInput:
        return MaterialPageRoute(builder: (_) => const PhoneInputScreen());
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => OtpVerificationScreen(phoneNumber: args?['phoneNumber']));
      case createUserInfo:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => CreateUserInformation(email: args?['email'] ?? ''));
      case sportsSelection:
        return MaterialPageRoute(builder: (_) => const SportsSelectionScreen());
      case intentSelection:
        return MaterialPageRoute(builder: (_) => const IntentSelectionScreen());
      case languageSelection:
        return MaterialPageRoute(builder: (_) => const LanguageSelectionScreen());
      case changePhone:
        return MaterialPageRoute(builder: (_) => const ChangePhoneScreen());
      
      // Comprehensive onboarding routes
      case onboardingWelcome:
        return MaterialPageRoute(builder: (_) => const ProfileOnboardingWelcomeScreen());
      case onboardingBasicInfo:
        return MaterialPageRoute(builder: (_) => const OnboardingBasicInfoScreen());
      case onboardingSports:
        return MaterialPageRoute(builder: (_) => const OnboardingSportsScreen());
      case onboardingPreferences:
        return MaterialPageRoute(builder: (_) => const OnboardingPreferencesScreen());
      case onboardingPrivacy:
        return MaterialPageRoute(builder: (_) => const OnboardingPrivacyScreen());
      case onboardingCompletion:
        return MaterialPageRoute(builder: (_) => const OnboardingCompletionScreen());
      
      // Support routes
      case helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
      case contactSupport:
        return MaterialPageRoute(builder: (_) => const ContactSupportScreen());
      case faq:
        return MaterialPageRoute(builder: (_) => const FaqScreen());
      
      // Loyalty routes
      case rewardsCenter:
        return MaterialPageRoute(builder: (_) => const RewardsCenterScreen());
      case pointsDetail:
        return MaterialPageRoute(builder: (_) => const PointsDetailScreen());
      case badgeDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => BadgeDetailScreen(badgeId: args['badgeId']));
      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  // Helper methods for transitions and page building
  static Widget _getPageForRoute(String routeName, Map<String, dynamic>? arguments) {
    switch (routeName) {
      case profile:
        return const ProfileScreen();
      case editProfile:
        return const EditProfileScreen();
      case settingsScreen:
        return const SettingsScreen();
      case profileSettings:
        return const Scaffold(body: Center(child: Text('Profile Settings - Coming Soon')));
      case profilePrivacy:
        return const Scaffold(body: Center(child: Text('Privacy Settings - Coming Soon')));
      case profileSports:
        return const Scaffold(body: Center(child: Text('Sports Profile - Coming Soon')));
      case profileStats:
        return const Scaffold(body: Center(child: Text('Profile Stats - Coming Soon')));
      case profileAvatar:
        return const Scaffold(body: Center(child: Text('Avatar Upload - Coming Soon')));
      case profileDataExport:
        return const Scaffold(body: Center(child: Text('Data Export - Coming Soon')));
      case profileAccountDeletion:
        return const Scaffold(body: Center(child: Text('Account Deletion - Coming Soon')));
      case profileViewProfile:
        return const Scaffold(body: Center(child: Text('View Profile - Coming Soon')));
      case profileCompletion:
        return const Scaffold(body: Center(child: Text('Profile Completion - Coming Soon')));
      case profileOnboarding:
        return const Scaffold(body: Center(child: Text('Profile Onboarding - Coming Soon')));
      default:
        return const Scaffold(body: Center(child: Text('Page not found')));
    }
  }

  static Widget _buildTransition(PageTransitionType type, Animation<double> animation, Widget child) {
    switch (type) {
      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      case PageTransitionType.fadeIn:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
    }
  }

  // Route protection helpers
  static bool isProtectedRoute(String routeName) {
    const protectedRoutes = {
      profile,
      editProfile,
      settingsScreen,
      profileSettings,
      profilePrivacy,
      profileSports,
      profileStats,
      profileAvatar,
      profileDataExport,
      profileAccountDeletion,
      profileCompletion,
      profileOnboarding,
    };
    return protectedRoutes.contains(routeName);
  }

  static void navigateWithAuthCheck(BuildContext context, String routeName, {Map<String, dynamic>? arguments}) {
    if (isProtectedRoute(routeName)) {
      // For now, assume user is authenticated
      Navigator.pushNamed(context, routeName, arguments: arguments);
    } else {
      Navigator.pushNamed(context, routeName, arguments: arguments);
    }
  }
}

// Route argument classes
class ExploreArgs {
  final String? tab; // 'games' or 'venues'
  final Map<String, dynamic>? filters;
  ExploreArgs({this.tab, this.filters});
}

class MatchDetailArgs {
  final dynamic match;
  MatchDetailArgs({required this.match});
}

class VenueDetailArgs {
  final dynamic venue;
  VenueDetailArgs({required this.venue});
}

class BookingFlowArgs {
  final Map<String, dynamic> venue;
  BookingFlowArgs({required this.venue});
}

class BookingSuccessArgs {
  final Map<String, dynamic> venue;
  final DateTime selectedDate;
  final String selectedTime;
  final String selectedSport;
  final String bookingId;
  
  BookingSuccessArgs({
    required this.venue,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedSport,
    required this.bookingId,
  });
}

class CreateGameArguments {
  final Map<String, dynamic>? venue;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String? selectedSport;
  final bool isFromBooking;
  final String? bookingId;
  
  CreateGameArguments({
    this.venue,
    this.selectedDate,
    this.selectedTime,
    this.selectedSport,
    this.isFromBooking = false,
    this.bookingId,
  });
}
