import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game.dart';
import '../../data/repositories/games_repository.dart';
import '../../data/repositories/games_repository_impl.dart';
import '../../services/supabase/supabase_service.dart';

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return GamesRepositoryImpl(svc);
});

/// Public discovery feed (filterable)
@immutable
class GamesDiscoverParams {
  const GamesDiscoverParams({
    this.sport,
    this.from,
    this.to,
    this.visibility,
    this.includeCancelled = false,
    this.q,
    this.limit = 50,
    this.offset = 0,
  });

  final String? sport;
  final DateTime? from;
  final DateTime? to;
  final String? visibility;
  final bool includeCancelled;
  final String? q;
  final int limit;
  final int offset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamesDiscoverParams &&
        other.sport == sport &&
        other.from == from &&
        other.to == to &&
        other.visibility == visibility &&
        other.includeCancelled == includeCancelled &&
        other.q == q &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(
        sport,
        from,
        to,
        visibility,
        includeCancelled,
        q,
        limit,
        offset,
      );
}

final gamesDiscoverProvider =
    FutureProvider.family<Result<List<Game>>, GamesDiscoverParams>((ref, p) {
  return ref.watch(gamesRepositoryProvider).listDiscoverableGames(
        sport: p.sport,
        from: p.from,
        to: p.to,
        visibility: p.visibility,
        includeCancelled: p.includeCancelled,
        q: p.q,
        limit: p.limit,
        offset: p.offset,
      );
});

/// My hosted games
@immutable
class MyGamesParams {
  const MyGamesParams({
    this.from,
    this.to,
    this.includeCancelled = false,
    this.limit = 50,
    this.offset = 0,
  });

  final DateTime? from;
  final DateTime? to;
  final bool includeCancelled;
  final int limit;
  final int offset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MyGamesParams &&
        other.from == from &&
        other.to == to &&
        other.includeCancelled == includeCancelled &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode =>
      Object.hash(from, to, includeCancelled, limit, offset);
}

final myHostedGamesProvider =
    FutureProvider.family<Result<List<Game>>, MyGamesParams>((ref, p) {
  return ref.watch(gamesRepositoryProvider).listMyHostedGames(
        from: p.from,
        to: p.to,
        includeCancelled: p.includeCancelled,
        limit: p.limit,
        offset: p.offset,
      );
});

/// Watch a single game
final gameWatchProvider =
    StreamProvider.family<Result<Game>, String>((ref, gameId) {
  return ref.watch(gamesRepositoryProvider).watchGame(gameId);
});
