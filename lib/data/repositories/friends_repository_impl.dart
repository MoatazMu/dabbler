import 'dart:async';

import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/features/misc/data/datasources/supabase_remote_data_source.dart';

import '../models/friend_edge.dart';
import '../models/friendship.dart';
import 'friends_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl(this.svc);

  final SupabaseService svc;

  SupabaseClient get _db => svc.client;

  /// Relies on RLS policy `friendships_insert_requester`.
  @override
  Future<Result<void, Failure>> sendFriendRequest(String peerUserId) async {
    try {
      await _db.rpc(
        'rpc_friend_request_send',
        params: {'p_peer_profile_id': peerUserId},
      );
      return Ok(null);
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_update_parties`.
  @override
  Future<Result<void, Failure>> acceptFriendRequest(String peerUserId) async {
    try {
      await _db.rpc(
        'rpc_friend_request_accept',
        params: {'p_peer_profile_id': peerUserId},
      );
      return Ok(null);
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_update_parties`.
  @override
  Future<Result<void, Failure>> rejectFriendRequest(String peerUserId) async {
    try {
      await _db.rpc(
        'rpc_friend_request_reject',
        params: {'p_peer_profile_id': peerUserId},
      );
      return Ok(null);
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_update_parties`.
  @override
  Future<Result<void, Failure>> removeFriend(String peerUserId) async {
    try {
      await _db.rpc(
        'rpc_friend_remove',
        params: {'p_peer_profile_id': peerUserId},
      );
      return Ok(null);
    } on PostgrestException catch (error) {
      if ((error.code == '42883') ||
          ((error.details as String?)?.toLowerCase().contains(
                'rpc_friend_remove',
              ) ??
              false)) {
        try {
          await _db.rpc(
            'rpc_friend_unfriend',
            params: {'p_peer_profile_id': peerUserId},
          );
          return Ok(null);
        } catch (fallbackError) {
          return Err(svc.mapPostgrestError(fallbackError));
        }
      }
      return Err(svc.mapPostgrestError(error));
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friendships_select_parties`.
  @override
  Future<Result<List<Friendship>, Failure>> listFriendships() async {
    try {
      final rows = await _db
          .from('friendships')
          .select()
          .order('updated_at', ascending: false);
      final friendships = rows
          .map(
            (dynamic row) =>
                Friendship.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
      return Ok(friendships);
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on stored procedure RLS visibility (typically `friendships_select_parties`).
  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> inbox() async {
    try {
      final rows = await _db.rpc('rpc_friend_requests_inbox');
      if (rows is List) {
        final payload = rows
            .map((dynamic row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        return Ok(payload);
      }
      return Err(const ServerFailure(message: 'Unexpected inbox payload'));
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on stored procedure RLS visibility (typically `friendships_select_parties`).
  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> outbox() async {
    try {
      final rows = await _db.rpc('rpc_friend_requests_outbox');
      if (rows is List) {
        final payload = rows
            .map((dynamic row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        return Ok(payload);
      }
      return Err(const ServerFailure(message: 'Unexpected outbox payload'));
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `friend_edges_read`.
  @override
  Future<Result<List<FriendEdge>, Failure>> listFriendEdges() async {
    try {
      final rows = await _db
          .from('friend_edges')
          .select()
          .order('created_at', ascending: false);
      final edges = rows
          .map(
            (dynamic row) =>
                FriendEdge.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
      return Ok(edges);
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Attempts `rpc_block_user` variants (`target_user` first, fallback to `(p_peer, p_block)`).
  @override
  Future<Result<void, Failure>> blockUser(String peerUserId) async {
    try {
      await _db.rpc(
        'rpc_block_user',
        params: {'p_peer_profile_id': peerUserId},
      );
      return Ok(null);
    } on PostgrestException catch (error) {
      final details = (error.details as String?)?.toLowerCase() ?? '';
      if (error.code == '42883' ||
          error.code == 'PGRST116' ||
          details.contains('ambiguous') ||
          details.contains('function rpc_block_user')) {
        try {
          await _db.rpc('rpc_block_user', params: {'target_user': peerUserId});
          return Ok(null);
        } catch (fallbackError) {
          return Err(svc.mapPostgrestError(fallbackError));
        }
      }
      return Err(svc.mapPostgrestError(error));
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Relies on the RPC enforcing appropriate RLS.
  @override
  Future<Result<void, Failure>> unblockUser(String peerUserId) async {
    try {
      await _db.rpc(
        'rpc_unblock_user',
        params: {'p_peer_profile_id': peerUserId},
      );
      return Ok(null);
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Get friendship status with a user
  @override
  Future<Result<String, Failure>> getFriendshipStatus(String peerUserId) async {
    try {
      final status = await _db.rpc(
        'rpc_get_friendship_status',
        params: {'p_peer_profile_id': peerUserId},
      );
      return Ok(status as String);
    } catch (error) {
      return Err(svc.mapPostgrestError(error));
    }
  }

  /// Get friendship status as stream with Supabase realtime
  @override
  Stream<Result<String, Failure>> getFriendshipStatusStream(
    String peerUserId,
  ) async* {
    final currentUserId = _db.auth.currentUser?.id;
    if (currentUserId == null) {
      yield Err(const ServerFailure(message: 'User not authenticated'));
      return;
    }

    final controller = StreamController<Result<String, Failure>>();

    // Emit initial status
    final initialStatus = await getFriendshipStatus(peerUserId);
    controller.add(initialStatus);

    // Create unique channel name
    final channelName = 'friendship_$currentUserId\_$peerUserId';

    // Subscribe to realtime changes
    final subscription = _db
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          callback: (payload) async {
            // Refetch status on any change
            final newStatus = await getFriendshipStatus(peerUserId);
            if (!controller.isClosed) {
              controller.add(newStatus);
            }
          },
        )
        .subscribe();

    // Handle cleanup
    controller.onCancel = () async {
      await _db.removeChannel(subscription);
      await controller.close();
    };

    yield* controller.stream;
  }

  /// Get list of friends
  @override
  Future<Result<List<Map<String, dynamic>>, Failure>> getFriends() async {
    try {
      print('DEBUG: Calling rpc_get_friends...');
      final rows = await _db.rpc('rpc_get_friends');
      print('DEBUG: RPC returned: $rows');
      if (rows is List) {
        final friends = rows
            .map((dynamic row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        print('DEBUG: Mapped ${friends.length} friends');
        return Ok(friends);
      }
      print('DEBUG: Unexpected payload type: ${rows.runtimeType}');
      return Err(const ServerFailure(message: 'Unexpected friends payload'));
    } catch (error) {
      print('DEBUG: Error in getFriends: $error');
      return Err(svc.mapPostgrestError(error));
    }
  }
}
