import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../../core/types/result.dart';
import '../../core/utils/json.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/slot.dart';
import 'availability_repository.dart';
import 'base_repository.dart';

@immutable
class AvailabilityRepositoryImpl extends BaseRepository
    implements AvailabilityRepository {
  const AvailabilityRepositoryImpl(super.svc);

  SupabaseClient get _db => svc.client;
  String? get _userId => _db.auth.currentUser?.id;

  @override
  Future<Result<List<Slot>>> listSlots({
    required String venueSpaceId,
    required DateTime from,
    required DateTime to,
    bool onlyAvailable = true,
    int limit = 500,
  }) async {
    return guard<List<Slot>>(() async {
      final query = _db
          .from('space_slot_grid')
          .select<List<Map<String, dynamic>>>()
          .eq('venue_space_id', venueSpaceId)
          .gte('start_ts', from.toUtc().toIso8601String())
          .lt('end_ts', to.toUtc().toIso8601String())
          .order('start_ts', ascending: true)
          .limit(limit);

      if (onlyAvailable) {
        // Be tolerant: check any of these columns if present.
        // Supabase will ignore .eq on missing columns, so we add OR logic via server expressions if needed.
        // Here we use simple filters that common grid views expose.
        query.eq('is_open', true);
        query.eq('is_booked', false);
        query.eq('is_held', false);
      }

      // RLS: grid_public_read permits SELECT for everyone.
      final rows = await query;
      return rows.map((r) => Slot.fromMap(asMap(r))).toList();
    });
  }

  @override
  Future<Result<List<SlotHold>>> listMyHolds({
    String? venueSpaceId,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    return guard<List<SlotHold>>(() async {
      final uid = _userId;
      if (uid == null) {
        throw Failure.unauthorized('Not signed in');
      }

      final q = _db
          .from('space_slot_holds')
          .select<List<Map<String, dynamic>>>()
          .eq('created_by', uid)
          .order('start_ts', ascending: true)
          .limit(limit);

      if (venueSpaceId != null && venueSpaceId.isNotEmpty) {
        q.eq('venue_space_id', venueSpaceId);
      }
      if (from != null) q.gte('start_ts', from.toUtc().toIso8601String());
      if (to != null) q.lt('end_ts', to.toUtc().toIso8601String());

      // RLS: holds_read allows creator/admin/venue staff to read.
      final rows = await q;
      return rows.map((m) => SlotHold.fromMap(asMap(m))).toList();
    });
  }

  @override
  Future<Result<SlotHold>> createHold({
    required String venueSpaceId,
    required DateTime start,
    required DateTime end,
    String? note,
  }) async {
    return guard<SlotHold>(() async {
      final uid = _userId;
      if (uid == null) {
        throw Failure.unauthorized('Not signed in');
      }

      final insert = SlotHold(
        id: '',
        venueSpaceId: venueSpaceId,
        start: start.toUtc(),
        end: end.toUtc(),
        createdBy: uid,
        note: note,
      ).toInsertMap(createdBy: uid);

      // RLS: holds_write requires created_by = auth.uid() (or admin). We set it explicitly.
      final row = await _db
          .from('space_slot_holds')
          .insert(insert)
          .select<Map<String, dynamic>>()
          .single();

      return SlotHold.fromMap(row);
    });
  }

  @override
  Future<Result<void>> releaseHold(String holdId) async {
    return guard<void>(() async {
      // RLS: holds_write lets creator delete their own holds.
      final _ = await _db.from('space_slot_holds').delete().eq('id', holdId);
    });
  }
}
