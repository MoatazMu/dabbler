import 'package:dabbler/core/errors/failure.dart';
import 'package:dabbler/core/result.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/services/supabase/supabase_service.dart';

import '../models/friend_edge.dart';
import '../models/friendship.dart';
import 'friends_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl(this.svc);

  final SupabaseService svc;

  PostgrestClient get _db => svc.client;

  /// Relies on RLS policy `friendships_insert_requester`.
  @override
  Future<Result<void>> sendFriendRequest(String peerUserId) async {
    try {
      await _db.rpc('rpc_friend_request_send', params: {'p_peer': peerUserId});
      return right(null);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_update_parties`.
  @override
  Future<Result<void>> acceptFriendRequest(String peerUserId) async {
    try {
      await _db.rpc('rpc_friend_request_accept', params: {'p_peer': peerUserId});
      return right(null);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_update_parties`.
  @override
  Future<Result<void>> rejectFriendRequest(String peerUserId) async {
    try {
      await _db.rpc('rpc_friend_request_reject', params: {'p_peer': peerUserId});
      return right(null);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_update_parties`.
  @override
  Future<Result<void>> removeFriend(String peerUserId) async {
    try {
      await _db.rpc('rpc_friend_remove', params: {'p_peer': peerUserId});
      return right(null);
    } on PostgrestException catch (error) {
      if ((error.code == '42883') ||
          ((error.details as String?)?.toLowerCase().contains('rpc_friend_remove') ?? false)) {
        try {
          await _db.rpc('rpc_friend_unfriend', params: {'p_peer': peerUserId});
          return right(null);
        } catch (fallbackError) {
          return left(svc.mapPostgrestError(fallbackError));
        }
      }
      return left(svc.mapPostgrestError(error));
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_select_parties`.
  @override
  Future<Result<List<Friendship>>> listFriendships() async {
    try {
      final rows = await _db.from('friendships').select().order('updated_at', ascending: false);
      final friendships = rows
          .map((dynamic row) => Friendship.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      return right(friendships);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on stored procedure RLS visibility (typically `friendships_select_parties`).
  @override
  Future<Result<List<Map<String, dynamic>>>> inbox() async {
    try {
      final rows = await _db.rpc('rpc_friend_requests_inbox');
      if (rows is List) {
        final payload = rows
            .map((dynamic row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        return right(payload);
      }
      return left(const ServerFailure(message: 'Unexpected inbox payload'));
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on stored procedure RLS visibility (typically `friendships_select_parties`).
  @override
  Future<Result<List<Map<String, dynamic>>>> outbox() async {
    try {
      final rows = await _db.rpc('rpc_friend_requests_outbox');
      if (rows is List) {
        final payload = rows
            .map((dynamic row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        return right(payload);
      }
      return left(const ServerFailure(message: 'Unexpected outbox payload'));
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friend_edges_read`.
  @override
  Future<Result<List<FriendEdge>>> listFriendEdges() async {
    try {
      final rows = await _db.from('friend_edges').select().order('created_at', ascending: false);
      final edges = rows
          .map((dynamic row) => FriendEdge.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      return right(edges);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Attempts `rpc_block_user` variants (`target_user` first, fallback to `(p_peer, p_block)`).
  @override
  Future<Result<void>> blockUser(String peerUserId) async {
    try {
      await _db.rpc('rpc_block_user', params: {'target_user': peerUserId});
      return right(null);
    } on PostgrestException catch (error) {
      final details = (error.details as String?)?.toLowerCase() ?? '';
      if (error.code == '42883' ||
          error.code == 'PGRST116' ||
          details.contains('ambiguous') ||
          details.contains('function rpc_block_user')) {
        try {
          await _db.rpc('rpc_block_user', params: {'p_peer': peerUserId, 'p_block': true});
          return right(null);
        } catch (fallbackError) {
          return left(svc.mapPostgrestError(fallbackError));
        }
      }
      return left(svc.mapPostgrestError(error));
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on the RPC enforcing appropriate RLS.
  @override
  Future<Result<void>> unblockUser(String peerUserId) async {
    try {
      await _db.rpc('rpc_unblock_user', params: {'target_user': peerUserId});
      return right(null);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }
}
