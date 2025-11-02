import 'package:dabbler/core/fp/result.dart';

import '../models/squad.dart';
import '../models/squad_invite.dart';
import '../models/squad_join_request.dart';
import '../models/squad_member.dart';

/// Repository contract for Squad management.
///
/// RLS expectations:
/// - Creation uses `squads_insert_self`.
/// - Reads go through `squads_read` / `squads_read_public`.
/// - Member mutations rely on `squad_members_owner_captain_write`.
/// - Invite operations use `squad_invites_owner_write` and reads via `squad_invites_read`.
abstract class SquadsRepository {
  Future<Result<String>> createSquad({
    required String sport,
    required String name,
    String? bio,
    String? logoUrl,
    String listingVisibility = 'public',
    String joinPolicy = 'request',
    int? maxMembers,
    String? city,
  });

  Future<Result<Squad>> getSquadById(String id);

  Future<Result<List<Squad>>> listDiscoverableSquads({
    String? sport,
    String? city,
    String? search,
    int limit = 20,
    int offset = 0,
  });

  Stream<Result<List<SquadMember>>> membersStream(String squadId);

  Future<Result<String>> inviteToSquad({
    required String squadId,
    required String toProfileId,
    DateTime? expiresAt,
  });

  Future<Result<String>> respondToInvite({
    required String inviteId,
    required String action,
    required String profileId,
  });

  Future<Result<String>> requestJoin({
    required String squadId,
    required String profileId,
    String? message,
    String? linkToken,
  });

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

  Future<Result<List<SquadInvite>>> mySquadInvites();

  Future<Result<List<SquadInvite>>> squadInvites(String squadId);

  Future<Result<List<SquadJoinRequest>>> squadJoinRequests(String squadId);

  Future<Result<List<Squad>>> mySquads();

  Stream<Result<List<Squad>>> mySquadsStream();
}
