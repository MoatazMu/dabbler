import '../../core/types/result.dart';
import '../models/slot.dart';

abstract class AvailabilityRepository {
  /// Raw grid (does not subtract holds).
  Future<Result<List<Slot>>> listGrid({
    required String venueSpaceId,
    required DateTime from,
    required DateTime to,
    int? limit,
  });

  /// Available slots (client-side subtracts visible holds; server will still
  /// enforce conflicts you can’t see due to RLS).
  Future<Result<List<Slot>>> listAvailability({
    required String venueSpaceId,
    required DateTime from,
    required DateTime to,
    int? limit,
  });

  /// Create a temporary hold. Server may reject overlapping holds with 409/constraint.
  /// Returns inserted row (at least: id, venue_space_id, slot_start, slot_end, expires_at).
  Future<Result<Map<String, dynamic>>> placeHold({
    required String venueSpaceId,
    required DateTime start,
    required DateTime end,
    Duration ttl = const Duration(minutes: 10),
  });

  /// Release a hold you created.
  Future<Result<void>> releaseHold(String holdId);

  /// Extend a hold’s expiry (best-effort, only your holds).
  Future<Result<Map<String, dynamic>>> extendHold({
    required String holdId,
    required Duration by,
  });

  /// Your holds for a space (filters out expired client-side).
  Future<Result<List<Map<String, dynamic>>>> listMyHolds({
    required String venueSpaceId,
    DateTime? nowUtc,
  });
}
