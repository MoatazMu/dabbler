import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/notification.dart';

abstract class NotificationsRepository {
  /// Latest notifications for the current user (RLS will still protect).
  Future<Result<List<AppNotification>>> getLatest({
    int limit = 50,
    DateTime? since, // optional filter by created_at >= since
  });

  /// Load a single notification by id (must belong to current user via RLS).
  Future<Result<AppNotification?>> getById(String id);

  /// Mark one notification read, returns number of rows updated (0/1).
  Future<Result<int>> markAsRead(String id);

  /// Mark all notifications read for the current user, optionally up to [before].
  Future<Result<int>> markAllAsRead({DateTime? before});

  /// Realtime stream for the current user's notifications (ordered desc).
  Stream<List<AppNotification>> watchUserNotifications({int limit = 50});
}
