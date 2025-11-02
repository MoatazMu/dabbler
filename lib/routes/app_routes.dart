import 'package:flutter/material.dart';

import '../routes/route_arguments.dart';
import 'package:dabbler/features/misc/presentation/screens/activities_screen_v2.dart';
import 'package:dabbler/features/misc/presentation/screens/create_game_screen.dart';
import 'package:dabbler/features/home/presentation/screens/home_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Primary entry points still backed by Navigator routes.
  static const String home = '/';
  static const String bookings = '/bookings';
  static const String gameCreate = '/gameCreate';

  /// Static routes that don't require arguments.
  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomeScreen(),
    bookings: (_) => const ActivitiesScreenV2(),
  };

  /// Route factory used by legacy Navigator.pushNamed flows.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case bookings:
        return MaterialPageRoute(builder: (_) => const ActivitiesScreenV2());
      case gameCreate:
        final args = settings.arguments;
        final typedArgs = args is CreateGameRouteArgs
            ? args
            : const CreateGameRouteArgs();
        return MaterialPageRoute(
          builder: (_) => CreateGameScreen(initialData: typedArgs),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }

  static void goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
  }

  static void goToBookings(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(bookings, (route) => false);
  }

  static void openCreateGame(
    BuildContext context, {
    CreateGameRouteArgs? args,
    bool clearStack = false,
  }) {
    final resolvedArgs = args ?? const CreateGameRouteArgs();
    if (clearStack) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        gameCreate,
        (route) => false,
        arguments: resolvedArgs,
      );
    } else {
      Navigator.of(context).pushNamed(gameCreate, arguments: resolvedArgs);
    }
  }
}
