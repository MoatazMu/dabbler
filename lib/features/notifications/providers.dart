import 'package:dabbler/data/models/notification.dart';
import 'package:dabbler/data/repositories/notifications_repository.dart';
import 'package:dabbler/data/repositories/notifications_repository_impl.dart';
import 'package:dabbler/services/supabase/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return NotificationsRepositoryImpl(svc);
});

class NotificationsListArgs {
  const NotificationsListArgs({
    this.limit = 50,
    this.before,
  });

  final int limit;
  final DateTime? before;
}

final notificationsListProvider = FutureProvider.family<List<AppNotification>, NotificationsListArgs>(
  (ref, args) async {
    final repository = ref.watch(notificationsRepositoryProvider);
    final result = await repository.list(
      limit: args.limit,
      before: args.before,
    );

    return result.fold((failure) => throw failure, (notifications) => notifications);
  },
);

final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.watch(limit: 50);
});
