import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../../core/types/result.dart';
import '../../core/utils/json.dart';
import '../models/abuse_flag.dart';
import '../../services/supabase/supabase_service.dart';
import 'audit_safety_repository.dart';
import 'base_repository.dart';

@immutable
class AuditSafetyRepositoryImpl extends BaseRepository
    implements AuditSafetyRepository {
  const AuditSafetyRepositoryImpl(SupabaseService svc) : super(svc);

  SupabaseClient get _db => svc.client;

  String? get _uid => _db.auth.currentUser?.id;

  @override
  Future<Result<AbuseFlag>> submitPostReport({
    required String postId,
    String? reason,
    String? details,
  }) async {
    return guard<AbuseFlag>(() async {
      final uid = _uid;
      if (uid == null) throw AuthException('Not authenticated');

      // RLS: INSERT allowed when reporter_user_id = auth.uid()
      final payload = {
        'reporter_user_id': uid,
        'post_id': postId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (details != null && details.isNotEmpty) 'details': details,
      };

      final inserted = await _db
          .from('post_reports')
          .insert(payload)
          .select()
          .single();

      return AbuseFlag.fromMap(inserted);
    });
  }

  @override
  Future<Result<List<AbuseFlag>>> getMyReports({int limit = 50}) async {
    return guard<List<AbuseFlag>>(() async {
      final uid = _uid;
      if (uid == null) throw AuthException('Not authenticated');

      // RLS: reporter_user_id = auth.uid() OR admin
      final rows =
          await _db
                  .from('post_reports')
                  .select()
                  .eq('reporter_user_id', uid)
                  .order('created_at', ascending: false)
                  .limit(limit)
              as List;

      return rows.map((r) => AbuseFlag.fromMap(r)).toList();
    });
  }

  @override
  Future<Result<List<AbuseFlag>>> getAllReports({
    int limit = 100,
    DateTime? since,
  }) async {
    return guard<List<AbuseFlag>>(() async {
      // If the caller isn't admin, RLS will naturally reduce the set to their own reports.
      var query = _db.from('post_reports').select();

      if (since != null) {
        query = query.gte('created_at', since.toIso8601String());
      }

      final rows =
          await query.order('created_at', ascending: false).limit(limit)
              as List;
      return rows.map((r) => AbuseFlag.fromMap(r)).toList();
    });
  }

  @override
  Stream<List<AbuseFlag>> watchMyReports({int limit = 50}) {
    final uid = _uid;
    if (uid == null) {
      return const Stream<List<AbuseFlag>>.empty();
    }

    // Realtime subscription scoped to the reporter via filter.
    return _db
        .from('post_reports')
        .stream(primaryKey: ['id'])
        .eq('reporter_user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit)
        .map(
          (rows) =>
              rows.map<AbuseFlag>((r) => AbuseFlag.fromMap(asMap(r))).toList(),
        );
  }
}
