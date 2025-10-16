import 'package:flutter/material.dart';
import '../../features/games/presentation/widgets/empty_states/no_upcoming_games_widget.dart';
import '../../utils/constants/route_constants.dart';
import 'package:go_router/go_router.dart';

/// Temporary Games screen placeholder for bottom navigation
/// This will be replaced with the full games implementation
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NoUpcomingGamesWidget(
      onCreateGame: () {
        context.push(RoutePaths.createGame);
      },
      onBrowseGames: () {
        context.push(RoutePaths.games);
      },
      onJoinedGames: () {
        context.push('${RoutePaths.games}?filter=joined');
      },
      onPastGames: () {
        context.push('${RoutePaths.games}?filter=past');
      },
      hasJoinedGames: false,
      hasPastGames: false,
    );
  }
}
