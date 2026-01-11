import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/features/activities/presentation/providers/activity_providers.dart';

class LastSeenActivityAtController extends StateNotifier<DateTime?> {
  static const _prefsKey = 'notification_center_last_seen_activity_at';

  LastSeenActivityAtController() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      state = DateTime.tryParse(raw);
    } catch (_) {
      // Ignore storage errors; badge will simply behave as "never seen".
    }
  }

  Future<void> markNow() async {
    final now = DateTime.now();
    state = now;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, now.toIso8601String());
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  Future<void> refreshFromStorage() => _load();
}

/// Tracks when the user last viewed the Activity tab.
final lastSeenActivityAtProvider =
    StateNotifierProvider<LastSeenActivityAtController, DateTime?>(
      (ref) => LastSeenActivityAtController(),
    );

/// Fetches the latest activity timestamp (cheap: limit 1) for badge purposes.
final latestActivityAtProvider = FutureProvider<DateTime?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final datasource = ref.watch(activityFeedDatasourceProvider);
    final activities = await datasource.getActivityFeed(
      period: 'all',
      limit: 1,
    );
    if (activities.isEmpty) return null;
    return activities.first.happenedAt;
  } catch (_) {
    return null;
  }
});
