import 'dart:async';

import 'package:dabbler/core/errors/failure.dart';
import 'package:dabbler/core/types/result.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/services/supabase/supabase_service.dart';

import '../models/squad.dart';
import '../models/squad_invite.dart';
import '../models/squad_join_request.dart';
import '../models/squad_member.dart';
import 'squads_repository.dart';

class SquadsRepositoryImpl implements SquadsRepository {
  SquadsRepositoryImpl(this.svc);

  final SupabaseService svc;

  SupabaseClient get _db => svc.client;

  bool _isRpcMissing(PostgrestException error, String rpcName) {
    final message = (error.message as String?)?.toLowerCase() ?? '';
    return error.code == '42883' ||
        message.contains('function $rpcName') ||
        message.contains('rpc_$rpcName');
  }

  String? _extractId(dynamic payload) {
    if (payload is String) {
      return payload;
    }
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      return map['id'] as String? ?? map['data'] as String?;
    }
    return null;
  }

  Result<T> _unexpected<T>(String message) =>
      left(ServerFailure(message: message));

  /// Relies on RLS policy `squads_insert_self`.
  @override
  Future<Result<String>> createSquad({
    required String sport,
    required String name,
    String? bio,
    String? logoUrl,
    String listingVisibility = 'public',
    String joinPolicy = 'request',
    int? maxMembers,
    String? city,
  }) async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(const AuthFailure(message: 'Not authenticated'));
    }

    try {
      try {
        final response = await _db.rpc(
          'rpc_squad_create',
          params: {
            'p_sport': sport,
            'p_name': name,
            'p_bio': bio,
            'p_logo_url': logoUrl,
            'p_listing_visibility': listingVisibility,
            'p_join_policy': joinPolicy,
            'p_max_members': maxMembers,
            'p_city': city,
          },
        );

        final id = _extractId(response);
        if (id != null) {
          return right(id);
        }
        if (response is Map && response['data'] is Map) {
          final data = Map<String, dynamic>.from(response['data'] as Map);
          final nestedId = data['id'] as String?;
          if (nestedId != null) {
            return right(nestedId);
          }
        }
        return _unexpected('rpc_squad_create returned no identifier');
      } on PostgrestException catch (error) {
        if (!_isRpcMissing(error, 'squad_create')) {
          return left(svc.mapPostgrestError(error));
        }
        final payload = <String, dynamic>{
          'sport': sport,
          'name': name,
          'bio': bio,
          'logo_url': logoUrl,
          'listing_visibility': listingVisibility,
          'join_policy': joinPolicy,
          'max_members': maxMembers,
          'city': city,
          'created_by_user_id': uid,
          'owner_user_id': uid,
        }..removeWhere((_, value) => value == null);
        final insert = await _db
            .from('squads')
            .insert(payload)
            .select('id')
            .maybeSingle();
        if (insert == null) {
          return _unexpected('Failed to create squad via fallback insert');
        }
        final id = (insert['id'] ?? insert['data']) as String?;
        if (id == null) {
          return _unexpected('Insert squads returned no identifier');
        }
        return right(id);
      }
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squads_read`.
  @override
  Future<Result<Squad>> getSquadById(String id) async {
    try {
      final row = await _db.from('squads').select().eq('id', id).maybeSingle();
      if (row == null) {
        return left(const NotFoundFailure(message: 'Squad not found'));
      }
      return right(Squad.fromJson(Map<String, dynamic>.from(row as Map)));
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squads_read_public`.
  @override
  Future<Result<List<Squad>>> listDiscoverableSquads({
    String? sport,
    String? city,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      PostgrestFilterBuilder query = _db.from('squads').select();
      query = query.eq('is_active', true);
      if (sport != null && sport.isNotEmpty) {
        query = query.eq('sport', sport);
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      if (search != null && search.trim().isNotEmpty) {
        final term = '%${search.trim()}%';
        query = query.ilike('name', term);
      }
      final rows = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final squads = rows
          .map(
            (dynamic row) =>
                Squad.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
      return right(squads);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squad_members_read`.
  @override
  Stream<Result<List<SquadMember>>> membersStream(String squadId) {
    final controller = StreamController<Result<List<SquadMember>>>.broadcast();
    StreamSubscription<List<dynamic>>? subscription;

    void emitError(Object error) {
      if (!controller.isClosed) {
        controller.add(left(svc.mapPostgrestError(error)));
      }
    }

    controller.onListen = () {
      try {
        subscription = _db
            .from('squad_members')
            .stream(primaryKey: ['squad_id', 'profile_id'])
            .eq('squad_id', squadId)
            .listen((event) {
              final members = event
                  .map(
                    (dynamic row) => SquadMember.fromJson(
                      Map<String, dynamic>.from(row as Map),
                    ),
                  )
                  .toList(growable: false);
              if (!controller.isClosed) {
                controller.add(right(members));
              }
            }, onError: emitError);
      } catch (error) {
        emitError(error);
      }
    };

    controller.onCancel = () async {
      await subscription?.cancel();
    };

    return controller.stream;
  }

  /// Relies on RLS policy `squad_invites_owner_write` via RPC.
  @override
  Future<Result<String>> inviteToSquad({
    required String squadId,
    required String toProfileId,
    DateTime? expiresAt,
  }) async {
    try {
      try {
        final response = await _db.rpc(
          'rpc_squad_invite',
          params: {
            'p_squad_id': squadId,
            'p_to_profile_id': toProfileId,
            'p_expires_at': expiresAt?.toIso8601String(),
          },
        );
        final id = _extractId(response);
        if (id != null) {
          return right(id);
        }
        return _unexpected('rpc_squad_invite returned no identifier');
      } on PostgrestException catch (error) {
        if (!_isRpcMissing(error, 'squad_invite')) {
          return left(svc.mapPostgrestError(error));
        }
        final uid = svc.authUserId();
        if (uid == null) {
          return left(const AuthFailure(message: 'Not authenticated'));
        }
        final profileRow = await _db
            .from('profiles')
            .select('user_id')
            .eq('id', toProfileId)
            .maybeSingle();
        final profileMap = profileRow == null
            ? null
            : Map<String, dynamic>.from(profileRow as Map);
        final toUserId = profileMap?['user_id'] as String?;
        if (toUserId == null) {
          return _unexpected('Unable to resolve target user for invite');
        }
        final memberRow = await _db
            .from('squad_members')
            .select('profile_id')
            .eq('squad_id', squadId)
            .eq('user_id', uid)
            .eq('status', 'active')
            .maybeSingle();
        final memberMap = memberRow == null
            ? null
            : Map<String, dynamic>.from(memberRow as Map);
        String? creatorProfileId = memberMap?['profile_id'] as String?;
        if (creatorProfileId == null) {
          final squadRow = await _db
              .from('squads')
              .select('owner_profile_id')
              .eq('id', squadId)
              .maybeSingle();
          final squadMap = squadRow == null
              ? null
              : Map<String, dynamic>.from(squadRow as Map);
          creatorProfileId = squadMap?['owner_profile_id'] as String?;
        }
        if (creatorProfileId == null) {
          return _unexpected('Unable to resolve creator profile for invite');
        }
        final payload = <String, dynamic>{
          'squad_id': squadId,
          'to_profile_id': toProfileId,
          'to_user_id': toUserId,
          'created_by_profile_id': creatorProfileId,
          'expires_at': expiresAt?.toIso8601String(),
        };
        final insert = await _db
            .from('squad_invites')
            .insert(payload)
            .select('id')
            .maybeSingle();
        if (insert == null) {
          return _unexpected('Failed to insert squad invite');
        }
        final id = insert['id'] as String?;
        if (id == null) {
          return _unexpected('Insert squad_invites returned no identifier');
        }
        return right(id);
      }
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy enforced inside `rpc_squad_respond_invite`.
  @override
  Future<Result<String>> respondToInvite({
    required String inviteId,
    required String action,
    required String profileId,
  }) async {
    try {
      final response = await _db.rpc(
        'rpc_squad_respond_invite',
        params: {
          'p_invite_id': inviteId,
          'p_action': action,
          'p_profile_id': profileId,
        },
      );
      final message = response is String ? response : 'ok';
      return right(message);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy encapsulated within `rpc_squad_request_join`.
  @override
  Future<Result<String>> requestJoin({
    required String squadId,
    required String profileId,
    String? message,
    String? linkToken,
  }) async {
    try {
      final response = await _db.rpc(
        'rpc_squad_request_join',
        params: {
          'p_squad_id': squadId,
          'p_profile_id': profileId,
          'p_message': message,
          'p_link_token': linkToken,
        },
      );
      return right(response is String ? response : 'ok');
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squad_members_owner_captain_write` via RPC.
  @override
  Future<Result<String>> addMember({
    required String squadId,
    required String profileId,
    bool asCaptain = false,
  }) async {
    try {
      final response = await _db.rpc(
        'rpc_squad_add_member',
        params: {
          'p_squad_id': squadId,
          'p_profile_id': profileId,
          'p_as_captain': asCaptain,
        },
      );
      return right(response is String ? response : 'ok');
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squad_members_owner_captain_write` via RPC.
  @override
  Future<Result<String>> removeMember({
    required String squadId,
    required String profileId,
  }) async {
    try {
      final response = await _db.rpc(
        'rpc_squad_remove_member',
        params: {'p_squad_id': squadId, 'p_profile_id': profileId},
      );
      return right(response is String ? response : 'ok');
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squad_members_owner_captain_write` via RPC.
  @override
  Future<Result<String>> setCaptain({
    required String squadId,
    required String profileId,
    required bool isCaptain,
  }) async {
    try {
      final response = await _db.rpc(
        'rpc_squad_set_captain',
        params: {
          'p_squad_id': squadId,
          'p_profile_id': profileId,
          'p_is_captain': isCaptain,
        },
      );
      return right(response is String ? response : 'ok');
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squad_invites_read`.
  @override
  Future<Result<List<SquadInvite>>> mySquadInvites() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(const AuthFailure(message: 'Not authenticated'));
    }
    try {
      final rows = await _db
          .from('squad_invites')
          .select()
          .eq('to_user_id', uid)
          .order('created_at', ascending: false);
      final invites = rows
          .map(
            (dynamic row) =>
                SquadInvite.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
      return right(invites);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squad_invites_read`.
  @override
  Future<Result<List<SquadInvite>>> squadInvites(String squadId) async {
    try {
      final rows = await _db
          .from('squad_invites')
          .select()
          .eq('squad_id', squadId)
          .order('created_at', ascending: false);
      final invites = rows
          .map(
            (dynamic row) =>
                SquadInvite.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
      return right(invites);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policy `squad_members_owner_captain_write` for visibility via join request RPC/queries.
  @override
  Future<Result<List<SquadJoinRequest>>> squadJoinRequests(
    String squadId,
  ) async {
    try {
      final rows = await _db
          .from('squad_join_requests')
          .select()
          .eq('squad_id', squadId)
          .order('created_at', ascending: false);
      final requests = rows
          .map(
            (dynamic row) => SquadJoinRequest.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
      return right(requests);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policies `squads_read` and `squad_members_read`.
  @override
  Future<Result<List<Squad>>> mySquads() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return left(const AuthFailure(message: 'Not authenticated'));
    }
    try {
      final ownedResponse = await _db
          .from('squads')
          .select()
          .eq('owner_user_id', uid);
      final ownedMaps = ownedResponse
          .map((dynamic row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);

      final membershipRows = await _db
          .from('squad_members')
          .select('squad_id')
          .eq('user_id', uid)
          .eq('status', 'active');
      final memberIds = membershipRows
          .map(
            (dynamic row) =>
                Map<String, dynamic>.from(row as Map)['squad_id'] as String,
          )
          .toSet();
      for (final owned in ownedMaps) {
        final ownedId = owned['id'] as String?;
        if (ownedId != null) {
          memberIds.remove(ownedId);
        }
      }

      List<Map<String, dynamic>> memberSquads = [];
      if (memberIds.isNotEmpty) {
        final rows = await _db
            .from('squads')
            .select()
            .in_('id', memberIds.toList());
        memberSquads = rows
            .map((dynamic row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
      }

      final combined = <String, Map<String, dynamic>>{};
      for (final row in ownedMaps) {
        final id = row['id'] as String?;
        if (id != null) {
          combined[id] = row;
        }
      }
      for (final row in memberSquads) {
        final id = row['id'] as String?;
        if (id != null) {
          combined[id] = row;
        }
      }
      final squads = combined.values
          .map((row) => Squad.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return right(squads);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }

  /// Relies on RLS policies `squads_read` and `squad_members_read` for realtime updates.
  @override
  Stream<Result<List<Squad>>> mySquadsStream() {
    final controller = StreamController<Result<List<Squad>>>.broadcast();
    StreamSubscription<List<dynamic>>? ownerSubscription;
    StreamSubscription<List<dynamic>>? memberSubscription;

    Future<void> emitCurrent() async {
      final result = await mySquads();
      if (!controller.isClosed) {
        controller.add(result);
      }
    }

    void emitError(Object error) {
      if (!controller.isClosed) {
        controller.add(left(svc.mapPostgrestError(error)));
      }
    }

    controller.onListen = () {
      final uid = svc.authUserId();
      if (uid == null) {
        controller.add(left(const AuthFailure(message: 'Not authenticated')));
        return;
      }
      unawaited(emitCurrent());
      try {
        ownerSubscription = _db
            .from('squads')
            .stream(primaryKey: ['id'])
            .eq('owner_user_id', uid)
            .listen((_) => unawaited(emitCurrent()), onError: emitError);
        memberSubscription = _db
            .from('squad_members')
            .stream(primaryKey: ['squad_id', 'profile_id'])
            .eq('user_id', uid)
            .listen((_) => unawaited(emitCurrent()), onError: emitError);
      } catch (error) {
        emitError(error);
      }
    };

    controller.onCancel = () async {
      await ownerSubscription?.cancel();
      await memberSubscription?.cancel();
    };

    return controller.stream;
  }
}
