import '../models/abuse_flag.dart';
import '../models/moderation_ticket.dart';
import '../models/moderation_action.dart';
import '../models/ban_term.dart';
import '../../core/types/result.dart';

abstract class AuditSafetyRepository {
  // Flags
  Future<Result<List<AbuseFlag>>> listFlags({
    String? status,
    String? subjectType,
    int limit = 50,
    DateTime? before,
  });

  Future<Result<AbuseFlag>> getFlag(String id);

  Future<Result<AbuseFlag>> setFlagStatus({
    required String id,
    required String status,
  });

  // Tickets
  Future<Result<ModerationTicket>> createTicket({
    required String flagId,
    required String category,
    String? notes,
  });

  Future<Result<List<ModerationTicket>>> listTickets({
    String? status,
    int limit = 50,
    DateTime? before,
  });

  // Actions
  Future<Result<ModerationAction>> createAction({
    String? ticketId,
    required String subjectType,
    required String subjectId,
    required String action,
    String? reason,
    Map<String, dynamic>? meta,
  });

  Future<Result<List<ModerationAction>>> listActions({
    String? subjectType,
    String? subjectId,
    int limit = 50,
    DateTime? before,
  });

  // Ban terms
  Future<Result<List<BanTerm>>> listBanTerms({bool? enabled});
  Future<Result<BanTerm>> upsertBanTerm(BanTerm term);
  Future<Result<void>> deleteBanTerm(String id);
}
