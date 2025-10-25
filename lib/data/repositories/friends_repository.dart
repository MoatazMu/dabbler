import 'package:dabbler/core/result.dart';

import '../models/friend_edge.dart';
import '../models/friendship.dart';

/// Repository interface for managing friendships and related requests.
abstract class FriendsRepository {
  /// Uses RLS policy `friendships_insert_requester` via RPC.
  Future<Result<void>> sendFriendRequest(String peerUserId);

  /// Uses RLS policy `friendships_update_parties` via RPC.
  Future<Result<void>> acceptFriendRequest(String peerUserId);

  /// Uses RLS policy `friendships_update_parties` via RPC.
  Future<Result<void>> rejectFriendRequest(String peerUserId);

  /// Uses RLS policy `friendships_update_parties` via RPC.
  Future<Result<void>> removeFriend(String peerUserId);

  /// Uses RLS policy `friendships_select_parties`.
  Future<Result<List<Friendship>>> listFriendships();

  /// Shape defined by RPC; relies on requester visibility within stored procedure.
  Future<Result<List<Map<String, dynamic>>>> inbox();

  /// Shape defined by RPC; relies on requester visibility within stored procedure.
  Future<Result<List<Map<String, dynamic>>>> outbox();

  /// Uses RLS policy `friend_edges_read`.
  Future<Result<List<FriendEdge>>> listFriendEdges();

  /// Optional helper calling `rpc_block_user`.
  Future<Result<void>> blockUser(String peerUserId);

  /// Optional helper calling `rpc_unblock_user`.
  Future<Result<void>> unblockUser(String peerUserId);
}
