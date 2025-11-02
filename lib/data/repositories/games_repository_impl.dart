import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../../features/games/data/models/game_model.dart';
import '../../features/games/domain/entities/game.dart' as domain;
import 'base_repository.dart';
import 'games_repository.dart';

class GamesRepositoryImpl extends BaseRepository implements GamesRepository {
  GamesRepositoryImpl(super.service);

  static const String table = 'games';

  @override
  Future<Result<domain.Game>> createGame({
    required String gameType,
    required String sport,
    String? title,
    required String hostProfileId,
    String? venueSpaceId,
    required DateTime startAt,
    required DateTime endAt,
    required int capacity,
    required String listingVisibility,
    required String joinPolicy,
    bool allowSpectators = false,
    int? minSkill,
    int? maxSkill,
    Map<String, dynamic> rules = const {},
    String? squadId,
  }) async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(const AuthFailure(message: 'Not signed in'));
    }

    if (capacity < 2 || capacity > 64) {
      return left(
        const ValidationFailure(message: 'Capacity must be between 2 and 64'),
      );
    }
    if (minSkill != null && (minSkill < 1 || minSkill > 10)) {
      return left(
        const ValidationFailure(
          message: 'Minimum skill must be between 1 and 10',
        ),
      );
    }
    if (maxSkill != null && (maxSkill < 1 || maxSkill > 10)) {
      return left(
        const ValidationFailure(
          message: 'Maximum skill must be between 1 and 10',
        ),
      );
    }
    if (minSkill != null && maxSkill != null && minSkill > maxSkill) {
      return left(
        const ValidationFailure(
          message: 'Minimum skill cannot exceed maximum skill',
        ),
      );
    }

    final payload = <String, dynamic>{
      'game_type': gameType,
      'sport': sport,
      if (title != null) 'title': title,
      'host_profile_id': hostProfileId,
      'host_user_id': uid,
      if (venueSpaceId != null) 'venue_space_id': venueSpaceId,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'capacity': capacity,
      'listing_visibility': listingVisibility,
      'join_policy': joinPolicy,
      'allow_spectators': allowSpectators,
      if (minSkill != null) 'min_skill': minSkill,
      if (maxSkill != null) 'max_skill': maxSkill,
      'rules': Map<String, dynamic>.from(rules),
      'is_cancelled': false,
      if (squadId != null) 'squad_id': squadId,
    };

    try {
      final response = await svc.maybeSingle(
        svc.from(table).insert(payload).select(),
      );

      if (response == null) {
        return left(const UnexpectedFailure(message: 'Failed to create game'));
      }

      return right(GameModel.fromJson(response));
    } catch (error, stackTrace) {
      return left(svc.mapGeneric(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> updateGame(
    String gameId, {
    String? title,
    String? venueSpaceId,
    DateTime? startAt,
    DateTime? endAt,
    int? capacity,
    String? listingVisibility,
    String? joinPolicy,
    bool? allowSpectators,
    int? minSkill,
    int? maxSkill,
    Map<String, dynamic>? rules,
  }) async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(const AuthFailure(message: 'Not signed in'));
    }

    if (capacity != null && (capacity < 2 || capacity > 64)) {
      return left(
        const ValidationFailure(message: 'Capacity must be between 2 and 64'),
      );
    }
    if (minSkill != null && (minSkill < 1 || minSkill > 10)) {
      return left(
        const ValidationFailure(
          message: 'Minimum skill must be between 1 and 10',
        ),
      );
    }
    if (maxSkill != null && (maxSkill < 1 || maxSkill > 10)) {
      return left(
        const ValidationFailure(
          message: 'Maximum skill must be between 1 and 10',
        ),
      );
    }
    if (minSkill != null && maxSkill != null && minSkill > maxSkill) {
      return left(
        const ValidationFailure(
          message: 'Minimum skill cannot exceed maximum skill',
        ),
      );
    }

    final patch = <String, dynamic>{};
    if (title != null) {
      patch['title'] = title;
    }
    if (venueSpaceId != null) {
      patch['venue_space_id'] = venueSpaceId;
    }
    if (startAt != null) {
      patch['start_at'] = startAt.toIso8601String();
    }
    if (endAt != null) {
      patch['end_at'] = endAt.toIso8601String();
    }
    if (capacity != null) {
      patch['capacity'] = capacity;
    }
    if (listingVisibility != null) {
      patch['listing_visibility'] = listingVisibility;
    }
    if (joinPolicy != null) {
      patch['join_policy'] = joinPolicy;
    }
    if (allowSpectators != null) {
      patch['allow_spectators'] = allowSpectators;
    }
    if (minSkill != null) {
      patch['min_skill'] = minSkill;
    }
    if (maxSkill != null) {
      patch['max_skill'] = maxSkill;
    }
    if (rules != null) {
      patch['rules'] = Map<String, dynamic>.from(rules);
    }

    if (patch.isEmpty) {
      return right(null);
    }

    try {
      await svc
          .from(table)
          .update(patch)
          .eq('id', gameId)
          .eq('host_user_id', uid);

      return right(null);
    } catch (error, stackTrace) {
      return left(svc.mapGeneric(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> cancelGame(String gameId, {String? reason}) async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(const AuthFailure(message: 'Not signed in'));
    }

    final payload = <String, dynamic>{
      'is_cancelled': true,
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancelled_reason': reason,
    };

    try {
      await svc
          .from(table)
          .update(payload)
          .eq('id', gameId)
          .eq('host_user_id', uid);

      return right(null);
    } catch (error, stackTrace) {
      return left(svc.mapGeneric(error, stackTrace));
    }
  }

  @override
  Future<Result<domain.Game>> getGameById(String gameId) async {
    try {
      final response = await svc.maybeSingle(
        svc.from(table).select().eq('id', gameId),
      );

      if (response == null) {
        return left(const NotFoundFailure(message: 'Game not found'));
      }

      return right(GameModel.fromJson(response));
    } catch (error, stackTrace) {
      return left(svc.mapGeneric(error, stackTrace));
    }
  }

  @override
  Future<Result<List<domain.Game>>> listDiscoverableGames({
    String? sport,
    DateTime? from,
    DateTime? to,
    String? visibility,
    bool includeCancelled = false,
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = svc.from(table).select();

      if (sport != null) {
        query = query.eq('sport', sport);
      }
      if (from != null) {
        query = query.gte('start_at', from.toIso8601String());
      }
      if (to != null) {
        query = query.lte('end_at', to.toIso8601String());
      }
      if (visibility != null) {
        query = query.eq('listing_visibility', visibility);
      }
      if (!includeCancelled) {
        query = query.eq('is_cancelled', false);
      }
      if (q != null && q.isNotEmpty) {
        query = query.ilike('title', '%$q%');
      }

      final rows = await svc.getList(
        query
            .order('start_at', ascending: true)
            .range(offset, offset + limit - 1),
      );

      final games = rows
          .map((row) => GameModel.fromJson(row) as domain.Game)
          .toList();
      return right(games);
    } catch (error, stackTrace) {
      return left(svc.mapGeneric(error, stackTrace));
    }
  }

  @override
  Future<Result<List<domain.Game>>> listMyHostedGames({
    DateTime? from,
    DateTime? to,
    bool includeCancelled = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(const AuthFailure(message: 'Not signed in'));
    }

    try {
      var query = svc.from(table).select().eq('host_user_id', uid);

      if (from != null) {
        query = query.gte('start_at', from.toIso8601String());
      }
      if (to != null) {
        query = query.lte('end_at', to.toIso8601String());
      }
      if (!includeCancelled) {
        query = query.eq('is_cancelled', false);
      }

      final rows = await svc.getList(
        query
            .order('start_at', ascending: false)
            .range(offset, offset + limit - 1),
      );

      final games = rows
          .map((row) => GameModel.fromJson(row) as domain.Game)
          .toList();
      return right(games);
    } catch (error, stackTrace) {
      return left(svc.mapGeneric(error, stackTrace));
    }
  }

  @override
  Stream<Result<domain.Game>> watchGame(String gameId) {
    final controller = StreamController<Result<domain.Game>>.broadcast();
    RealtimeChannel? channel;

    Future<void> emitCurrent() async {
      final result = await getGameById(gameId);
      controller.add(result);
    }

    void emitError(Object error, [StackTrace? stackTrace]) {
      controller.add(left(svc.mapGeneric(error, stackTrace)));
    }

    controller.onListen = () {
      try {
        channel = svc.client
            .channel('public:games')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: gameId,
              ),
              callback: (payload) async {
                try {
                  await emitCurrent();
                } catch (error, stackTrace) {
                  emitError(error, stackTrace);
                }
              },
            )
            .subscribe();

        unawaited(emitCurrent());
      } catch (error, stackTrace) {
        emitError(error, stackTrace);
      }
    };

    controller.onCancel = () async {
      if (channel != null) {
        await channel!.unsubscribe();
      }
    };

    return controller.stream;
  }
}
