import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../data/models/game.dart';
import '../../data/repositories/games_repository.dart';
import 'providers.dart';

class GamesConsumer extends ConsumerWidget {
  const GamesConsumer({super.key});

  static const String _demoGameId = '00000000-0000-0000-0000-000000000000';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverAsync = ref.watch(
      gamesDiscoverProvider(const GamesDiscoverParams()),
    );
    final watchAsync = ref.watch(gameWatchProvider(_demoGameId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discover Games', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          discoverAsync.when(
            data: (result) => _buildDiscoverList(result),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Error: $error'),
          ),
          const SizedBox(height: 24),
          Text('Realtime Watch', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Listening for updates to a demo game id. '
            'TODO: Replace with a real game id from the UI.',
          ),
          const SizedBox(height: 8),
          watchAsync.when(
            data: (result) => result.match(
              (failure) => _FailureMessage(failure: failure),
              (game) => _WatchedGameCard(game: game),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverList(Result<List<Game>> result) {
    return result.match((failure) => _FailureMessage(failure: failure), (
      games,
    ) {
      if (games.isEmpty) {
        return const Text('No upcoming games found.');
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(game.title ?? game.sport),
              subtitle: Text(
                '${game.sport} • ${game.startAt.toLocal()} - ${game.endAt.toLocal()}',
              ),
              trailing: Text('${game.capacity} spots'),
            ),
          );
        },
      );
    });
  }
}

class _FailureMessage extends StatelessWidget {
  const _FailureMessage({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Text(
      failure.message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _WatchedGameCard extends StatelessWidget {
  const _WatchedGameCard({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(game.title ?? game.sport),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Visibility: ${game.listingVisibility}'),
            Text('Join policy: ${game.joinPolicy}'),
            if (game.isCancelled)
              Text(
                'Cancelled${game.cancelledReason != null ? ': ${game.cancelledReason}' : ''}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
