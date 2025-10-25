import 'package:dabbler/core/result.dart';
import 'package:dabbler/data/models/notification.dart';

typedef AppNotificationResult<T> = Result<T>;

abstract class NotificationsRepository {
  Future<AppNotificationResult<List<AppNotification>>> list({
    int limit = 50,
    DateTime? before,
  });

  Future<AppNotificationResult<void>> markRead({required String id});

  /// Set read_at = now() for all unread notifications for current user.
  Future<AppNotificationResult<int>> markAllRead();

  /// Stream live changes (insert/update) for current user.
  Stream<List<AppNotification>> watch({
    int limit = 50,
  });
}
