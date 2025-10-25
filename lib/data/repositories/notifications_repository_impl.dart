import 'dart:async';

import 'package:dabbler/core/result.dart';
import 'package:dabbler/core/utils/either.dart';
import 'package:dabbler/data/models/notification.dart';
import 'package:dabbler/data/repositories/base_repository.dart';
import 'package:dabbler/data/repositories/notifications_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRepositoryImpl extends BaseRepository
    implements NotificationsRepository {
  NotificationsRepositoryImpl(super.svc);

  static const _table = 'notifications';
  static const _selectColumns =
      'id,user_id,type,payload,created_at,read_at';

  @override
  Future<Result<List<AppNotification>>> list({
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = svc.client
          .from(_table)
          .select(_selectColumns)
          .order('created_at', ascending: false)
          .limit(limit);

      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }

      final response = await query;

      final rows = (response as List<dynamic>)
          .map((dynamic row) => Map<String, dynamic>.from(row as Map))
          .map(AppNotification.fromJson)
          .toList(growable: false);

      return Right(rows);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<void>> markRead({required String id}) async {
    try {
      await svc.client
          .from(_table)
          .update({
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);

      return const Right(null);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<int>> markAllRead() async {
    try {
      final response = await svc.client
          .from(_table)
          .update({
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .is_('read_at', null)
          .select('id');

      if (response is List) {
        return Right(response.length);
      }

      return const Right(0);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Stream<List<AppNotification>> watch({int limit = 50}) {
    final controller = StreamController<List<AppNotification>>.broadcast();
    final channel = svc.client.channel('realtime:$_table');

    Future<void> emitLatest() async {
      final result = await list(limit: limit);
      result.fold(
        (failure) {
          if (!controller.isClosed) {
            controller.addError(failure);
          }
        },
        (notifications) {
          if (!controller.isClosed) {
            controller.add(notifications);
          }
        },
      );
    }

    channel.on(
      RealtimeListenTypes.postgresChanges,
      const ChannelFilter(
        event: '*',
        schema: 'public',
        table: _table,
      ),
      (payload, [ref]) {
        unawaited(emitLatest());
      },
    );

    controller.onListen = () async {
      await emitLatest();
      try {
        await channel.subscribe();
      } catch (error) {
        final failure = svc.mapPostgrestError(error);
        if (!controller.isClosed) {
          controller.addError(failure);
        }
      }
    };

    controller.onCancel = () async {
      await channel.unsubscribe();
      await svc.client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }
}
