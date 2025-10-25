import '../../core/types/result.dart';
import '../models/feed_item.dart';

abstract class FeedRepository {
  /// Home feed for the signed-in user (RLS determines visibility).
  /// Returns items ordered by created_at DESC, id DESC.
  /// If `cursor` is provided, keyset paginate after that cursor.
  Future<Result<List<FeedItem>>> getHomeFeed({
    String? cursor,
    int limit = 20,
  });

  /// Posts authored by a specific user, still RLS-filtered for viewer.
  Future<Result<List<FeedItem>>> getUserFeed(
    String userId, {
    String? cursor,
    int limit = 20,
  });

  /// Posts scoped to a squad, still RLS-filtered for viewer.
  Future<Result<List<FeedItem>>> getSquadFeed(
    String squadId, {
    String? cursor,
    int limit = 20,
  });

  /// Utility to build a cursor from a feed item.
  String makeCursor(FeedItem item);
}
