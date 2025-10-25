import 'dart:async';

import 'package:dabbler/core/error/failures.dart';
import 'package:dabbler/core/result.dart';
import 'package:dabbler/core/utils/either.dart';
import 'package:dabbler/data/models/sport_profile.dart';
import 'package:dabbler/data/repositories/base_repository.dart';
import 'package:dabbler/data/repositories/sport_profiles_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SportProfilesRepositoryImpl extends BaseRepository
    implements SportProfilesRepository {
  SportProfilesRepositoryImpl(super.svc);

  static const String _table = 'sport_profiles';

  bool _isValidSkillLevel(int value) => value >= 1 && value <= 10;

  @override
  Future<Result<List<SportProfile>>> getMySports() async {
    const table = _table;
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    try {
      final response = await svc.client
          .from(table)
          .select()
          .eq('user_id', uid)
          .order('sport_key');

      final rows = (response as List<dynamic>)
          .map((dynamic row) => Map<String, dynamic>.from(row as Map))
          .map(SportProfile.fromJson)
          .toList(growable: false);

      return Right(rows);
    } catch (e) {
      return Left(svc.mapPostgrestError(e));
    }
  }

  @override
  Future<Result<SportProfile?>> getMySportByKey(String sportKey) async {
    const table = _table;
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    try {
      final response = await svc.client
          .from(table)
          .select()
          .eq('user_id', uid)
          .eq('sport_key', sportKey)
          .maybeSingle();

      if (response == null) {
        return const Right(null);
      }

      final map = Map<String, dynamic>.from(response as Map);
      return Right(SportProfile.fromJson(map));
    } catch (e) {
      return Left(svc.mapPostgrestError(e));
    }
  }

  @override
  Future<Result<void>> addMySport({
    required String sportKey,
    required int skillLevel,
  }) async {
    const table = _table;
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    if (!_isValidSkillLevel(skillLevel)) {
      return const Left(
        ValidationFailure(message: 'Skill level must be between 1 and 10'),
      );
    }

    try {
      await svc.client.from(table).insert({
            'user_id': uid,
            'sport_key': sportKey,
            'skill_level': skillLevel,
          });
      return const Right(null);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Left(ConflictFailure(message: 'Already added'));
      }
      return Left(svc.mapPostgrestError(e));
    } catch (e) {
      return Left(svc.mapPostgrestError(e));
    }
  }

  @override
  Future<Result<void>> updateMySport({
    required String sportKey,
    required int skillLevel,
  }) async {
    const table = _table;
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    if (!_isValidSkillLevel(skillLevel)) {
      return const Left(
        ValidationFailure(message: 'Skill level must be between 1 and 10'),
      );
    }

    try {
      await svc.client
          .from(table)
          .update({'skill_level': skillLevel})
          .eq('user_id', uid)
          .eq('sport_key', sportKey);
      return const Right(null);
    } catch (e) {
      return Left(svc.mapPostgrestError(e));
    }
  }

  @override
  Future<Result<void>> removeMySport({required String sportKey}) async {
    const table = _table;
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    try {
      await svc.client
          .from(table)
          .delete()
          .eq('user_id', uid)
          .eq('sport_key', sportKey);
      return const Right(null);
    } catch (e) {
      return Left(svc.mapPostgrestError(e));
    }
  }

  @override
  Stream<Result<List<SportProfile>>> watchMySports() {
    const table = _table;
    final controller = StreamController<Result<List<SportProfile>>>.broadcast();
    RealtimeChannel? channel;

    Future<void> emitCurrent() async {
      final result = await getMySports();
      if (!controller.isClosed) {
        controller.add(result);
      }
    }

    controller.onListen = () async {
      final uid = svc.authUserId();
      if (uid == null) {
        if (!controller.isClosed) {
          controller.add(const Left(AuthFailure(message: 'Not signed in')));
        }
        return;
      }

      try {
        await emitCurrent();
      } catch (e) {
        if (!controller.isClosed) {
          controller.add(Left(svc.mapPostgrestError(e)));
        }
      }

      channel = svc.client
          .channel('public:$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: uid,
            ),
            callback: (_) => unawaited(emitCurrent()),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: uid,
            ),
            callback: (_) => unawaited(emitCurrent()),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: uid,
            ),
            callback: (_) => unawaited(emitCurrent()),
          )
          .subscribe();
    };

    controller.onCancel = () async {
      await channel?.unsubscribe();
      channel = null;
    };

    return controller.stream;
  }
}
