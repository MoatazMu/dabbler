import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import '../../core/utils/json.dart';
import '../models/feed_item.dart';
import 'base_repository.dart';
import 'feed_repository.dart';

@immutable
class FeedRepositoryImpl extends BaseRepository implements FeedRepository {
  const FeedRepositoryImpl(super.svc);

  SupabaseClient get _db => svc.client;

  static const _posts = 'posts';

  @override
  Future<Result<List<FeedItem>>> listRecent({
    int limit = 50,
    String? afterCursor,
    String? beforeCursor,
  }) async {
    return guard<List<FeedItem>>(() async {
      if (limit <= 0) throw Failure.badRequest('limit must be > 0');

      final q = _db
          .from(_posts)
          .select()
          .order('created_at', ascending: false) // DESC timeline
          .order('id', ascending: false) // tie-breaker for stable order
          .limit(limit);

      final before = FeedItem.decodeCursor(beforeCursor);
      if (before != null) {
        // Fetch strictly older-than cursor (created_at DESC, id DESC)
        // For composite key pagination, we need (created_at, id) lexicographic condition.
        // Supabase client lacks tuple compare; emulate:
        //   (created_at < cursor.created_at) OR
        //   (created_at = cursor.created_at AND id < cursor.id)
        q.or(
          'and(created_at.lt.${before.createdAt.toIso8601String()}),'
          'and(created_at.eq.${before.createdAt.toIso8601String()},id.lt.${before.id})',
        );
      }

      // Note: afterCursor is reserved (for asc pagination). Not used now.

      final rows = await q;
      return rows.map((m) => FeedItem.fromPostRow(asMap(m))).toList();
    });
  }

  @override
  String? nextCursorFrom(List<FeedItem> page) {
    if (page.isEmpty) return null;
    // With DESC sort, the last item is the "oldest" in this page,
    // so the next page should start strictly before it.
    return page.last.toCursor();
  }
}
