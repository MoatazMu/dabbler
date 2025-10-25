import '../../services/supabase/supabase_service.dart';
import '../models/abuse_flag.dart';
import '../models/ban_term.dart';
import '../models/moderation_action.dart';
import '../models/moderation_ticket.dart';
import 'audit_safety_repository.dart';
import 'base_repository.dart';

class AuditSafetyRepositoryImpl extends BaseRepository
    implements AuditSafetyRepository {
  AuditSafetyRepositoryImpl(SupabaseService svc) : super(svc);

  static const _flagsTable = 'moderation_flags';
  static const _ticketsTable = 'moderation_tickets';
  static const _actionsTable = 'moderation_actions';
  static const _banTermsTable = 'moderation_ban_terms';

  static const _flagColumns =
      'id,subject_type,subject_id,reason,reporter_user_id,status,created_at';
  static const _ticketColumns =
      'id,flag_id,category,notes,status,created_at';
  static const _actionColumns =
      'id,ticket_id,subject_type,subject_id,action,reason,meta,created_at';
  static const _banTermColumns = 'id,term,kind,enabled,created_at';

  @override
  Future<Result<List<AbuseFlag>>> listFlags({
    String? status,
    String? subjectType,
    int limit = 50,
    DateTime? before,
  }) {
    return guard(() async {
      var query = svc
          .from(_flagsTable)
          .select(_flagColumns)
          .order('created_at', ascending: false)
          .limit(limit);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (subjectType != null) {
        query = query.eq('subject_type', subjectType);
      }
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }

      final response = await query;
      final data = (response as List<dynamic>)
          .map((dynamic item) => AbuseFlag.fromJson(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList();

      return data;
    });
  }

  @override
  Future<Result<AbuseFlag>> getFlag(String id) {
    return guard(() async {
      final response = await svc
          .from(_flagsTable)
          .select(_flagColumns)
          .eq('id', id)
          .single();

      return AbuseFlag.fromJson(
        Map<String, dynamic>.from(response as Map<dynamic, dynamic>),
      );
    });
  }

  @override
  Future<Result<AbuseFlag>> setFlagStatus({
    required String id,
    required String status,
  }) {
    return guard(() async {
      final response = await svc
          .from(_flagsTable)
          .update({'status': status})
          .eq('id', id)
          .select(_flagColumns)
          .single();

      return AbuseFlag.fromJson(
        Map<String, dynamic>.from(response as Map<dynamic, dynamic>),
      );
    });
  }

  @override
  Future<Result<ModerationTicket>> createTicket({
    required String flagId,
    required String category,
    String? notes,
  }) {
    return guard(() async {
      final payload = <String, dynamic>{
        'flag_id': flagId,
        'category': category,
        'status': 'open',
        if (notes != null) 'notes': notes,
      };

      final response = await svc
          .from(_ticketsTable)
          .insert(payload)
          .select(_ticketColumns)
          .single();

      return ModerationTicket.fromJson(
        Map<String, dynamic>.from(response as Map<dynamic, dynamic>),
      );
    });
  }

  @override
  Future<Result<List<ModerationTicket>>> listTickets({
    String? status,
    int limit = 50,
    DateTime? before,
  }) {
    return guard(() async {
      var query = svc
          .from(_ticketsTable)
          .select(_ticketColumns)
          .order('created_at', ascending: false)
          .limit(limit);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }

      final response = await query;
      final data = (response as List<dynamic>)
          .map((dynamic item) => ModerationTicket.fromJson(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList();

      return data;
    });
  }

  @override
  Future<Result<ModerationAction>> createAction({
    String? ticketId,
    required String subjectType,
    required String subjectId,
    required String action,
    String? reason,
    Map<String, dynamic>? meta,
  }) {
    return guard(() async {
      final payload = <String, dynamic>{
        'subject_type': subjectType,
        'subject_id': subjectId,
        'action': action,
        if (ticketId != null) 'ticket_id': ticketId,
        if (reason != null) 'reason': reason,
        if (meta != null) 'meta': meta,
      };

      final response = await svc
          .from(_actionsTable)
          .insert(payload)
          .select(_actionColumns)
          .single();

      return ModerationAction.fromJson(
        Map<String, dynamic>.from(response as Map<dynamic, dynamic>),
      );
    });
  }

  @override
  Future<Result<List<ModerationAction>>> listActions({
    String? subjectType,
    String? subjectId,
    int limit = 50,
    DateTime? before,
  }) {
    return guard(() async {
      var query = svc
          .from(_actionsTable)
          .select(_actionColumns)
          .order('created_at', ascending: false)
          .limit(limit);

      if (subjectType != null) {
        query = query.eq('subject_type', subjectType);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }

      final response = await query;
      final data = (response as List<dynamic>)
          .map((dynamic item) => ModerationAction.fromJson(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList();

      return data;
    });
  }

  @override
  Future<Result<List<BanTerm>>> listBanTerms({bool? enabled}) {
    return guard(() async {
      var query = svc
          .from(_banTermsTable)
          .select(_banTermColumns)
          .order('created_at', ascending: false);

      if (enabled != null) {
        query = query.eq('enabled', enabled);
      }

      final response = await query;
      final data = (response as List<dynamic>)
          .map((dynamic item) => BanTerm.fromJson(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList();

      return data;
    });
  }

  @override
  Future<Result<BanTerm>> upsertBanTerm(BanTerm term) {
    return guard(() async {
      final payload = Map<String, dynamic>.from(term.toJson())
        ..remove('created_at');

      final response = await svc
          .from(_banTermsTable)
          .upsert(payload, onConflict: 'id')
          .select(_banTermColumns)
          .single();

      return BanTerm.fromJson(
        Map<String, dynamic>.from(response as Map<dynamic, dynamic>),
      );
    });
  }

  @override
  Future<Result<void>> deleteBanTerm(String id) {
    return guard(() async {
      await svc.from(_banTermsTable).delete().eq('id', id);
    });
  }
}
