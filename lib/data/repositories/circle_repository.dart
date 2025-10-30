import '../../core/types/result.dart';
import '../models/circle_contact.dart';

/// Circle/Feed repository (views + RPCs).
/// RLS expectations:
/// - Reads from views: `SELECT` only; underlying table RLS applies.
/// - Stream invalidation listens to `friend_edges` via `friend_edges_read`.
/// - Inbox/Outbox via RPCs.
abstract class CircleRepository {
  /// Typed list from RPC with known shape.
  Future<Result<List<CircleContact>>> circleList();

  /// Raw rows from the v_circle view (unknown shape -> maps).
  Future<Result<List<Map<String, dynamic>>>> circleView({
    int? limit,
    int? offset,
  });

  /// Raw rows from v_feed_circle (unknown shape -> maps).
  Future<Result<List<Map<String, dynamic>>>> circleFeed({
    int limit,
    int offset,
  });

  /// Emits updated feed whenever friend_edges for the current user changes.
  Stream<Result<List<Map<String, dynamic>>>> circleFeedStream({
    int limit,
    int offset,
  });

  /// Inbox/Outbox friend requests via RPCs (unknown exact row structure).
  Future<Result<List<Map<String, dynamic>>>> friendRequestsInbox();
  Future<Result<List<Map<String, dynamic>>>> friendRequestsOutbox();

  /// Optional helper reads (unknown view columns).
  Future<Result<List<Map<String, dynamic>>>> squadCards({
    String? squadId,
    int? limit,
    int? offset,
  });

  Future<Result<List<Map<String, dynamic>>>> squadDetail(String squadId);
}
