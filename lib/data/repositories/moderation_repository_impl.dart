import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/fp/failure.dart';
import '../../core/types/result.dart' show Result;
import '../repositories/base_repository.dart';
import 'moderation_repository.dart' hide Result;

class ModerationRepositoryImpl extends BaseRepository
    implements ModerationRepository {
  ModerationRepositoryImpl(super.svc);

  SupabaseClient get _db => svc.client;

  @override
  Future<Result<bool>> isAdmin() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return left(AuthFailure(message: 'No auth user'));
      }
      final res = await _db.rpc('is_admin', params: {'u': uid});
      // unwrap the response
      final data = res as bool?;
      return right(data == true);
    } on PostgrestException catch (e) {
      return left(svc.mapPostgrestError(e));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  // ---------- helpers ----------
  Future<Result<void>> _requireAdmin() async {
    final admin = await isAdmin();
    return admin.fold(
      (f) => left(f),
      (ok) => ok ? right(null) : left(PermissionFailure(message: 'Admin only')),
    );
  }

  Future<Result<T>> _guardAdmin<T>(Future<Result<T>> Function() action) async {
    final gate = await _requireAdmin();
    return gate.fold((f) => Future.value(left<Failure, T>(f)), (_) => action());
  }

  PostgrestFilterBuilder _applyWhere(
    PostgrestFilterBuilder q,
    Map<String, dynamic>? where,
  ) {
    if (where == null) return q;
    // Minimalistic filter application: equals only.
    where.forEach((k, v) {
      if (v == null) return;
      q = q.eq(k, v);
    });
    return q;
  }

  // ---------- Flags ----------
  @override
  Future<Result<List<Map<String, dynamic>>>> listFlags({
    int limit = 50,
    int offset = 0,
    Map<String, dynamic>? where,
  }) async {
    return _guardAdmin(() async {
      try {
        var q = _db.from('moderation_flags').select();
        q = _applyWhere(q, where).range(offset, offset + limit - 1);
        final rows = await q;
        return right(List<Map<String, dynamic>>.from(rows));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  // ---------- Tickets ----------
  @override
  Future<Result<List<Map<String, dynamic>>>> listTickets({
    int limit = 50,
    int offset = 0,
    Map<String, dynamic>? where,
  }) async {
    return _guardAdmin(() async {
      try {
        var q = _db.from('moderation_tickets').select();
        q = _applyWhere(q, where).range(offset, offset + limit - 1);
        final rows = await q;
        return right(List<Map<String, dynamic>>.from(rows));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> createTicket(
    Map<String, dynamic> values,
  ) async {
    return _guardAdmin(() async {
      try {
        final rows = await _db
            .from('moderation_tickets')
            .insert(values)
            .select()
            .single();
        return right(Map<String, dynamic>.from(rows));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> updateTicket(
    String id,
    Map<String, dynamic> patch,
  ) async {
    return _guardAdmin(() async {
      try {
        final rows = await _db
            .from('moderation_tickets')
            .update(patch)
            .eq('id', id)
            .select()
            .maybeSingle();

        if (rows == null) {
          return left(NotFoundFailure(message: 'Ticket not found'));
        }
        return right(Map<String, dynamic>.from(rows));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Result<int>> setTicketStatus(String id, String status) async {
    return _guardAdmin(() async {
      try {
        final res = await _db
            .from('moderation_tickets')
            .update({'status': status})
            .eq('id', id);
        // PostgREST update returns affected rows count only in newer clients; fallback to select check:
        if (res is int) return right(res);
        return right(1); // assume one row updated if no error thrown
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  // ---------- Actions ----------
  @override
  Future<Result<List<Map<String, dynamic>>>> listActions({
    int limit = 50,
    int offset = 0,
    Map<String, dynamic>? where,
  }) async {
    return _guardAdmin(() async {
      try {
        var q = _db.from('moderation_actions').select();
        q = _applyWhere(q, where).range(offset, offset + limit - 1);
        final rows = await q;
        return right(List<Map<String, dynamic>>.from(rows));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> recordAction(
    Map<String, dynamic> values,
  ) async {
    return _guardAdmin(() async {
      try {
        final row = await _db
            .from('moderation_actions')
            .insert(values)
            .select()
            .single();
        return right(Map<String, dynamic>.from(row));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  // ---------- Ban terms ----------
  @override
  Future<Result<List<Map<String, dynamic>>>> listBanTerms({
    int limit = 100,
    int offset = 0,
    Map<String, dynamic>? where,
  }) async {
    return _guardAdmin(() async {
      try {
        var q = _db.from('moderation_ban_terms').select();
        q = _applyWhere(q, where).range(offset, offset + limit - 1);
        final rows = await q;
        return right(List<Map<String, dynamic>>.from(rows));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> upsertBanTerm(
    Map<String, dynamic> values,
  ) async {
    return _guardAdmin(() async {
      try {
        final row = await _db
            .from('moderation_ban_terms')
            .upsert(values)
            .select()
            .single();
        return right(Map<String, dynamic>.from(row));
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }

  @override
  Future<Result<int>> deleteBanTerm(String id) async {
    return _guardAdmin(() async {
      try {
        final res = await _db
            .from('moderation_ban_terms')
            .delete()
            .eq('id', id);
        if (res is int) return right(res);
        return right(1);
      } on PostgrestException catch (e) {
        return left(svc.mapPostgrestError(e));
      } catch (e) {
        return left(UnknownFailure(message: e.toString()));
      }
    });
  }
}
