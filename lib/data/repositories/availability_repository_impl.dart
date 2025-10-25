import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../core/types/result.dart';
import '../../services/supabase_service.dart';
import '../models/slot.dart';
import 'availability_repository.dart';
import 'base_repository.dart';

class AvailabilityRepositoryImpl extends BaseRepository
    implements AvailabilityRepository {
  AvailabilityRepositoryImpl(SupabaseService svc) : super(svc);

  static const String _gridTable = 'space_slot_grid';
  static const String _holdsTable = 'space_slot_holds';
  static const String _gridColumns =
      'id,venue_space_id,slot_start,slot_end';
  static const String _holdColumns =
      'id,venue_space_id,slot_start,slot_end,created_by,created_at,expires_at';

  @override
  Future<Result<List<Slot>>> listGrid({
    required String venueSpaceId,
    required DateTime from,
    required DateTime to,
    int? limit,
  }) {
    if (limit != null && limit <= 0) {
      return success(const <Slot>[]);
    }
    return guard(() async {
      final rows = await _fetchGrid(
        venueSpaceId: venueSpaceId,
        from: from,
        to: to,
        limit: limit,
      );
      return rows.map(Slot.fromJson).toList(growable: false);
    });
  }

  @override
  Future<Result<List<Slot>>> listAvailability({
    required String venueSpaceId,
    required DateTime from,
    required DateTime to,
    int? limit,
  }) {
    if (limit != null && limit <= 0) {
      return success(const <Slot>[]);
    }
    return guard(() async {
      final gridRows = await _fetchGrid(
        venueSpaceId: venueSpaceId,
        from: from,
        to: to,
        limit: null,
      );
      final slots = gridRows.map(Slot.fromJson).toList(growable: false);

      final holds = await _fetchHolds(
        venueSpaceId: venueSpaceId,
        from: from,
        to: to,
      );

      if (holds.isEmpty) {
        return _applyLimit(slots, limit);
      }

      final nowUtc = DateTime.now().toUtc();
      final activeHolds = holds.where((hold) {
        final expiresAt = hold['expires_at'] as DateTime?;
        if (expiresAt == null) {
          return true;
        }
        return expiresAt.isAfter(nowUtc);
      }).toList(growable: false);

      if (activeHolds.isEmpty) {
        return _applyLimit(slots, limit);
      }

      final available = <Slot>[];
      for (final slot in slots) {
        final hasOverlap = activeHolds.any((hold) => _overlaps(slot, hold));
        if (!hasOverlap) {
          available.add(slot);
          if (limit != null && available.length >= limit) {
            break;
          }
        }
      }

      return available;
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> placeHold({
    required String venueSpaceId,
    required DateTime start,
    required DateTime end,
    Duration ttl = const Duration(minutes: 10),
  }) {
    return guard(() async {
      final expiresAt = DateTime.now().toUtc().add(ttl);
      final payload = <String, dynamic>{
        'venue_space_id': venueSpaceId,
        'slot_start': start.toUtc().toIso8601String(),
        'slot_end': end.toUtc().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };

      try {
        final response = await svc.client
            .from(_holdsTable)
            .insert(payload)
            .select(_holdColumns)
            .single();

        return _parseHold(Map<String, dynamic>.from(response));
      } on PostgrestException catch (error) {
        final status = error.statusCode;
        final code = error.code;
        if (status == 409 || code == '23505') {
          throw const ConflictFailure(message: 'Slot is no longer available');
        }
        rethrow;
      }
    });
  }

  @override
  Future<Result<void>> releaseHold(String holdId) {
    return guard(() async {
      await svc.client
          .from(_holdsTable)
          .delete()
          .eq('id', holdId);
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> extendHold({
    required String holdId,
    required Duration by,
  }) {
    return guard(() async {
      final newExpiry = DateTime.now().toUtc().add(by);
      try {
        final response = await svc.client
            .from(_holdsTable)
            .update(<String, dynamic>{
              'expires_at': newExpiry.toIso8601String(),
            })
            .eq('id', holdId)
            .select(_holdColumns)
            .single();

        return _parseHold(Map<String, dynamic>.from(response));
      } on PostgrestException catch (error) {
        final status = error.statusCode;
        if (status == 404) {
          throw const NotFoundFailure(message: 'Hold not found');
        }
        rethrow;
      }
    });
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> listMyHolds({
    required String venueSpaceId,
    DateTime? nowUtc,
  }) {
    final uid = svc.authUserId();
    if (uid == null) {
      return failure(const AuthFailure(message: 'Not signed in'));
    }

    final effectiveNow = (nowUtc ?? DateTime.now()).toUtc();
    return guard(() async {
      final response = await svc.client
          .from(_holdsTable)
          .select(_holdColumns)
          .eq('venue_space_id', venueSpaceId)
          .eq('created_by', uid)
          .order('slot_start', ascending: true);

      final holds = _parseHoldList(response);
      final active = holds.where((hold) {
        final expiresAt = hold['expires_at'] as DateTime?;
        if (expiresAt == null) {
          return true;
        }
        return expiresAt.isAfter(effectiveNow);
      }).toList(growable: false);

      return active;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchGrid({
    required String venueSpaceId,
    required DateTime from,
    required DateTime to,
    int? limit,
  }) async {
    var query = svc.client
        .from(_gridTable)
        .select(_gridColumns)
        .eq('venue_space_id', venueSpaceId)
        .gte('slot_start', from.toUtc().toIso8601String())
        .lte('slot_end', to.toUtc().toIso8601String())
        .order('slot_start', ascending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return _decodeList(response);
  }

  Future<List<Map<String, dynamic>>> _fetchHolds({
    required String venueSpaceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final query = svc.client
        .from(_holdsTable)
        .select(_holdColumns)
        .eq('venue_space_id', venueSpaceId)
        .gte('slot_end', from.toUtc().toIso8601String())
        .lte('slot_start', to.toUtc().toIso8601String())
        .order('slot_start', ascending: true);

    try {
      final response = await query;
      return _parseHoldList(response);
    } on PostgrestException catch (error) {
      final status = error.statusCode;
      if (status == 401 || status == 403 || error.code == 'PGRST301') {
        return const <Map<String, dynamic>>[];
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _decodeList(dynamic response) {
    final list = List<dynamic>.from(response as List);
    return list
        .map((dynamic row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _parseHoldList(dynamic response) {
    final decoded = _decodeList(response);
    return decoded.map(_parseHold).toList(growable: false);
  }

  Map<String, dynamic> _parseHold(Map<String, dynamic> row) {
    DateTime? parseTimestamp(String key) {
      final value = row[key];
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value.toUtc();
      }
      return DateTime.parse(value as String).toUtc();
    }

    return <String, dynamic>{
      'id': row['id'] as String,
      'venue_space_id': row['venue_space_id'] as String,
      'slot_start': parseTimestamp('slot_start'),
      'slot_end': parseTimestamp('slot_end'),
      'created_by': row['created_by'] as String?,
      'created_at': parseTimestamp('created_at'),
      'expires_at': parseTimestamp('expires_at'),
    };
  }

  bool _overlaps(Slot slot, Map<String, dynamic> hold) {
    final holdStart = hold['slot_start'] as DateTime?;
    final holdEnd = hold['slot_end'] as DateTime?;
    if (holdStart == null || holdEnd == null) {
      return false;
    }

    final slotEndsBeforeOrAtHoldStart =
        slot.end.isBefore(holdStart) || slot.end.isAtSameMomentAs(holdStart);
    final slotStartsAfterOrAtHoldEnd =
        slot.start.isAfter(holdEnd) || slot.start.isAtSameMomentAs(holdEnd);

    return !(slotEndsBeforeOrAtHoldStart || slotStartsAfterOrAtHoldEnd);
  }

  List<Slot> _applyLimit(List<Slot> slots, int? limit) {
    if (limit == null || limit >= slots.length) {
      return slots;
    }
    return slots.sublist(0, limit);
  }
}
