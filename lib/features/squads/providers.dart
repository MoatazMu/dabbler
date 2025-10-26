import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../services/supabase_service.dart';
import '../../data/models/squad.dart';
import '../../data/models/squad_invite.dart';
import '../../data/models/squad_join_request.dart';
import '../../data/models/squad_link_token.dart';
import '../../data/models/squad_member.dart';
import '../../data/repositories/squads_repository.dart';
import '../../data/repositories/squads_repository_impl.dart';

typedef SquadCardsArgs = ({String? squadId, int? limit, int? offset});

final squadsRepositoryProvider = Provider.autoDispose<SquadsRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return SquadsRepositoryImpl(svc);
});

// My owned squads
final myOwnedSquadsProvider = FutureProvider.autoDispose<Result<List<Squad>>>((
  ref,
) {
  final repo = ref.watch(squadsRepositoryProvider);
  return repo.listMyOwnedSquads();
});

// Squad by id
final squadByIdProvider = FutureProvider.autoDispose
    .family<Result<Squad>, String>((ref, id) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.getSquadById(id);
    });

// Members
final squadMembersProvider = FutureProvider.autoDispose
    .family<Result<List<SquadMember>>, String>((ref, squadId) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.listMembers(squadId);
    });

final squadMembersStreamProvider = StreamProvider.autoDispose
    .family<Result<List<SquadMember>>, String>((ref, squadId) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.membersStream(squadId);
    });

// Invites
final mySquadInvitesProvider =
    FutureProvider.autoDispose<Result<List<SquadInvite>>>((ref) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.listMyInvites();
    });

final squadInvitesProvider = FutureProvider.autoDispose
    .family<Result<List<SquadInvite>>, String>((ref, squadId) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.listSquadInvites(squadId);
    });

// Join requests
final myJoinRequestsProvider =
    FutureProvider.autoDispose<Result<List<SquadJoinRequest>>>((ref) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.listMyJoinRequests();
    });

final squadJoinRequestsProvider = FutureProvider.autoDispose
    .family<Result<List<SquadJoinRequest>>, String>((ref, squadId) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.listJoinRequestsForSquad(squadId);
    });

// Link tokens (read-only)
final activeLinkTokensProvider = FutureProvider.autoDispose
    .family<Result<List<SquadLinkToken>>, String>((ref, squadId) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.activeLinkTokensForSquad(squadId);
    });

// Views (maps)
final squadCardsProvider = FutureProvider.autoDispose
    .family<Result<List<Map<String, dynamic>>>, SquadCardsArgs>((ref, args) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.squadCards(
        squadId: args.squadId,
        limit: args.limit,
        offset: args.offset,
      );
    });

final squadDetailViewProvider = FutureProvider.autoDispose
    .family<Result<List<Map<String, dynamic>>>, String>((ref, squadId) {
      final repo = ref.watch(squadsRepositoryProvider);
      return repo.squadDetail(squadId);
    });
