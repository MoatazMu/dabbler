import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/result.dart';
import '../../core/error/failures.dart';
import '../../core/utils/either.dart';
import '../../services/supabase_service.dart';
import '../models/squad.dart';
import '../models/squad_invite.dart';
import '../models/squad_join_request.dart';
import '../models/squad_link_token.dart';
import '../models/squad_member.dart';
import 'squads_repository.dart';

class SquadsRepositoryImpl implements SquadsRepository {
  SquadsRepositoryImpl(this.svc);

  final SupabaseService svc;

  PostgrestClient get _db => svc.client;

  // ----- Squads -----
  @override
  Future<Result<String>> createSquad({
    required String createdByProfileId,
    required String sport,
    required String name,
    String? bio,
    String listingVisibility = 'public',
    String joinPolicy = 'request',
    int? maxMembers,
    String? captainUserId,
  }) async {
    try {
      final id = await _db.rpc('rpc_squad_create', params: {
        'p_created_by_profile_id': createdByProfileId,
        'p_sport': sport,
        'p_name': name,
        'p_bio': bio,
        'p_listing_visibility': listingVisibility,
        'p_join_policy': joinPolicy,
        'p_max_members': maxMembers,
        'p_captain_user_id': captainUserId,
      });
      if (id is String) {
        return Right(id);
      }
      return const Left(
        ServerFailure(
          message: 'rpc_squad_create returned unexpected shape',
        ),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<Squad>> getSquadById(String id) async {
    try {
      final data = await _db
          .from('squads')
          .select<Map<String, dynamic>>()
          .eq('id', id)
          .maybeSingle();
      if (data == null) {
        return const Left(NotFoundFailure(message: 'Squad not found'));
      }
      return Right(Squad.fromJson(Map<String, dynamic>.from(data)));
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<Squad>>> listMyOwnedSquads() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    try {
      final rows = await _db
          .from('squads')
          .select<Map<String, dynamic>>()
          .eq('owner_user_id', uid)
          .order('created_at', ascending: false);
      final squads = rows
          .map((row) => Squad.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(squads);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<Squad>>> searchSquads({
    String? sport,
    String? city,
    String? nameIlike,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      PostgrestFilterBuilder<Map<String, dynamic>> query =
          _db.from('squads').select<Map<String, dynamic>>();
      if (sport != null) {
        query = query.eq('sport', sport);
      }
      if (city != null) {
        query = query.eq('city', city);
      }
      if (nameIlike != null && nameIlike.trim().isNotEmpty) {
        query = query.ilike('name', '%${nameIlike.trim()}%');
      }
      query = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final rows = await query;
      final squads = rows
          .map((row) => Squad.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(squads);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<Squad>> updateSquad(
    String id, {
    String? name,
    String? bio,
    String? logoUrl,
    bool? isActive,
    String? listingVisibility,
    String? joinPolicy,
    int? maxMembers,
    String? city,
    Map<String, dynamic>? meta,
  }) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (bio != null) patch['bio'] = bio;
    if (logoUrl != null) patch['logo_url'] = logoUrl;
    if (isActive != null) patch['is_active'] = isActive;
    if (listingVisibility != null) {
      patch['listing_visibility'] = listingVisibility;
    }
    if (joinPolicy != null) patch['join_policy'] = joinPolicy;
    if (maxMembers != null) patch['max_members'] = maxMembers;
    if (city != null) patch['city'] = city;
    if (meta != null) patch['meta'] = meta;

    if (patch.isEmpty) {
      return getSquadById(id);
    }

    try {
      final data = await _db
          .from('squads')
          .update(patch)
          .eq('id', id)
          .select<Map<String, dynamic>>()
          .maybeSingle();
      if (data == null) {
        return const Left(
          NotFoundFailure(message: 'Squad not found after update'),
        );
      }
      return Right(Squad.fromJson(Map<String, dynamic>.from(data)));
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  // ----- Members -----
  @override
  Future<Result<List<SquadMember>>> listMembers(String squadId) async {
    try {
      final rows = await _db
          .from('squad_members')
          .select<Map<String, dynamic>>()
          .eq('squad_id', squadId)
          .order('joined_at', ascending: false);
      final members = rows
          .map((row) => SquadMember.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(members);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<String>> addMember({
    required String squadId,
    required String profileId,
    bool asCaptain = false,
  }) async {
    try {
      final response = await _db.rpc('rpc_squad_add_member', params: {
        'p_squad_id': squadId,
        'p_profile_id': profileId,
        'p_as_captain': asCaptain,
      });
      if (response is String) {
        return Right(response);
      }
      return const Left(
        ServerFailure(
          message: 'rpc_squad_add_member returned unexpected shape',
        ),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<String>> removeMember({
    required String squadId,
    required String profileId,
  }) async {
    try {
      final response = await _db.rpc('rpc_squad_remove_member', params: {
        'p_squad_id': squadId,
        'p_profile_id': profileId,
      });
      if (response is String) {
        return Right(response);
      }
      return const Left(
        ServerFailure(
          message: 'rpc_squad_remove_member returned unexpected shape',
        ),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<String>> setCaptain({
    required String squadId,
    required String profileId,
    required bool isCaptain,
  }) async {
    try {
      final response = await _db.rpc('rpc_squad_set_captain', params: {
        'p_squad_id': squadId,
        'p_profile_id': profileId,
        'p_is_captain': isCaptain,
      });
      if (response is String) {
        return Right(response);
      }
      return const Left(
        ServerFailure(
          message: 'rpc_squad_set_captain returned unexpected shape',
        ),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  // ----- Invites & Join Requests -----
  @override
  Future<Result<String>> inviteProfile({
    required String squadId,
    required String toProfileId,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _db.rpc('rpc_squad_invite', params: {
        'p_squad_id': squadId,
        'p_to_profile_id': toProfileId,
        'p_expires_at': expiresAt?.toIso8601String(),
      });
      if (response is String) {
        return Right(response);
      }
      return const Left(
        ServerFailure(
          message: 'rpc_squad_invite returned unexpected shape',
        ),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<SquadInvite>>> listMyInvites() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    try {
      final rows = await _db
          .from('squad_invites')
          .select<Map<String, dynamic>>()
          .eq('to_user_id', uid)
          .order('created_at', ascending: false);
      final invites = rows
          .map((row) => SquadInvite.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(invites);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<SquadInvite>>> listSquadInvites(String squadId) async {
    try {
      final rows = await _db
          .from('squad_invites')
          .select<Map<String, dynamic>>()
          .eq('squad_id', squadId)
          .order('created_at', ascending: false);
      final invites = rows
          .map((row) => SquadInvite.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(invites);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<String>> requestJoin({
    required String squadId,
    required String profileId,
    String? message,
  }) async {
    try {
      final response = await _db.rpc('rpc_squad_request_join', params: {
        'p_squad_id': squadId,
        'p_profile_id': profileId,
        'p_message': message,
      });
      if (response is String) {
        return Right(response);
      }
      return const Left(
        ServerFailure(
          message: 'rpc_squad_request_join returned unexpected shape',
        ),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<String>> requestJoinWithLink({
    required String squadId,
    required String profileId,
    required String linkTokenUuid,
    String? message,
  }) async {
    try {
      final response = await _db.rpc('rpc_squad_request_join', params: {
        'p_squad_id': squadId,
        'p_profile_id': profileId,
        'p_message': message,
        'p_link_token': linkTokenUuid,
      });
      if (response is String) {
        return Right(response);
      }
      return const Left(
        ServerFailure(
          message: 'rpc_squad_request_join (link) unexpected shape',
        ),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<SquadJoinRequest>>> listJoinRequestsForSquad(
      String squadId) async {
    try {
      final rows = await _db
          .from('squad_join_requests')
          .select<Map<String, dynamic>>()
          .eq('squad_id', squadId)
          .order('created_at', ascending: false);
      final requests = rows
          .map((row) =>
              SquadJoinRequest.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(requests);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<SquadJoinRequest>>> listMyJoinRequests() async {
    final uid = svc.authUserId();
    if (uid == null) {
      return const Left(AuthFailure(message: 'Not signed in'));
    }

    try {
      final rows = await _db
          .from('squad_join_requests')
          .select<Map<String, dynamic>>()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final requests = rows
          .map((row) =>
              SquadJoinRequest.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(requests);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  // ----- Link tokens (read-only) -----
  @override
  Future<Result<List<SquadLinkToken>>> activeLinkTokensForSquad(
      String squadId) async {
    try {
      final rows = await _db
          .from('squad_link_tokens')
          .select<Map<String, dynamic>>()
          .eq('squad_id', squadId)
          .eq('active', true)
          .order('created_at', ascending: false);
      final tokens = rows
          .map((row) =>
              SquadLinkToken.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      return Right(tokens);
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  // ----- Views (unknown shapes) -----
  @override
  Future<Result<List<Map<String, dynamic>>>> squadCards({
    String? squadId,
    int? limit,
    int? offset,
  }) async {
    try {
      PostgrestFilterBuilder<Map<String, dynamic>> query =
          _db.from('v_squad_card').select<Map<String, dynamic>>();
      if (squadId != null) {
        query = query.eq('id', squadId);
      }
      if (limit != null && offset != null) {
        query = query.range(offset, offset + limit - 1);
      }
      final rows = await query;
      return Right(
        rows
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> squadDetail(String squadId) async {
    try {
      final rows = await _db
          .from('v_squad_detail')
          .select<Map<String, dynamic>>()
          .eq('id', squadId);
      return Right(
        rows
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false),
      );
    } catch (error) {
      return Left(svc.mapPostgrestError(error));
    }
  }

  // ----- Streams -----
  @override
  Stream<Result<List<SquadMember>>> membersStream(String squadId) async* {
    try {
      yield await listMembers(squadId);

      final stream = _db
          .from('squad_members')
          .stream(primaryKey: ['squad_id', 'profile_id'])
          .eq('squad_id', squadId);

      await for (final _ in stream) {
        yield await listMembers(squadId);
      }
    } catch (error) {
      yield Left(svc.mapPostgrestError(error));
    }
  }

  @override
  Stream<Result<Squad>> squadStream(String id) async* {
    try {
      yield await getSquadById(id);

      final stream =
          _db.from('squads').stream(primaryKey: ['id']).eq('id', id);

      await for (final _ in stream) {
        yield await getSquadById(id);
      }
    } catch (error) {
      yield Left(svc.mapPostgrestError(error));
    }
  }
}
