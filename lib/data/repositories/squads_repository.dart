import '../../core/result.dart';
import '../models/squad.dart';
import '../models/squad_member.dart';
import '../models/squad_invite.dart';
import '../models/squad_join_request.dart';
import '../models/squad_link_token.dart';

/// Squads domain repository.
///
/// RLS expectations:
/// - Create via RPC `rpc_squad_create` (checks actor auth.uid()).
/// - Update/delete squads: `squads_owner_write` (owner_user_id == auth.uid()).
/// - Read squads: `squads_read` (scope) and `squads_read_public` (is_active).
/// - Members: owner/admin/captain writes; members can read own membership.
/// - Invites: owner write, owner & recipient can read.
/// - Link tokens: select allowed for creator/owner/admin; writes are service-only (no insert path here).
abstract class SquadsRepository {
  // ----- Squads -----
  Future<Result<String>> createSquad({
    required String createdByProfileId,
    required String sport,
    required String name,
    String? bio,
    String listingVisibility = 'public',
    String joinPolicy = 'request',
    int? maxMembers,
    String? captainUserId,
  });

  Future<Result<Squad>> getSquadById(String id);

  Future<Result<List<Squad>>> listMyOwnedSquads();

  Future<Result<List<Squad>>> searchSquads({
    String? sport,
    String? city,
    String? nameIlike, // best-effort ilike on name
    int limit = 30,
    int offset = 0,
  });

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
  });

  // ----- Members -----
  Future<Result<List<SquadMember>>> listMembers(String squadId);
  Future<Result<String>> addMember({
    required String squadId,
    required String profileId,
    bool asCaptain = false,
  });
  Future<Result<String>> removeMember({
    required String squadId,
    required String profileId,
  });
  Future<Result<String>> setCaptain({
    required String squadId,
    required String profileId,
    required bool isCaptain,
  });

  // ----- Invites & Join Requests -----
  Future<Result<String>> inviteProfile({
    required String squadId,
    required String toProfileId,
    DateTime? expiresAt,
  });

  Future<Result<List<SquadInvite>>> listMyInvites(); // as recipient
  Future<Result<List<SquadInvite>>> listSquadInvites(String squadId); // as owner

  Future<Result<String>> requestJoin({
    required String squadId,
    required String profileId,
    String? message,
  });

  Future<Result<String>> requestJoinWithLink({
    required String squadId,
    required String profileId,
    required String linkTokenUuid,
    String? message,
  });

  Future<Result<List<SquadJoinRequest>>> listJoinRequestsForSquad(String squadId);
  Future<Result<List<SquadJoinRequest>>> listMyJoinRequests();

  // ----- Link tokens (read-only here due to RLS) -----
  Future<Result<List<SquadLinkToken>>> activeLinkTokensForSquad(String squadId);

  // ----- Views (unknown shapes → maps) -----
  Future<Result<List<Map<String, dynamic>>>> squadCards({String? squadId, int? limit, int? offset});
  Future<Result<List<Map<String, dynamic>>>> squadDetail(String squadId);

  // ----- Streams -----
  Stream<Result<List<SquadMember>>> membersStream(String squadId);
  Stream<Result<Squad>> squadStream(String id);
}
