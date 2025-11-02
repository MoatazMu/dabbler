
import 'package:dabbler/core/fp/result.dart';
import '../models/abuse_flag.dart';

abstract class AuditSafetyRepository {
  /// Submit a new report for the currently authenticated user.
  /// Returns the inserted AbuseFlag (if PostgREST returns it) or a minimal echo object.
  Future<Result<AbuseFlag>> submitPostReport({
    required String postId,
    String? reason,
    String? details,
  });

  /// Current user's reports (RLS: reporter or admin).
  Future<Result<List<AbuseFlag>>> getMyReports({int limit = 50});

  /// (Admin) List all recent reports. RLS will restrict non-admins automatically.
  Future<Result<List<AbuseFlag>>> getAllReports({
    int limit = 100,
    DateTime? since,
  });

  /// Watch current user's reports in realtime (ordered DESC).
  Stream<List<AbuseFlag>> watchMyReports({int limit = 50});
}

