import '../models/venue_space.dart';
import '../../core/types/result.dart';

abstract class VenueConfigRepository {
  // Spaces
  Future<Result<List<VenueSpace>>> listSpaces({
    required String venueId,
    bool onlyActive = true,
    int limit = 100,
    String? nameLike,
  });

  Future<Result<VenueSpace>> getSpace(String id);

  /// Insert or update by id (if id provided).
  Future<Result<VenueSpace>> upsertSpace({
    String? id,
    required String venueId,
    required String name,
    String? description,
    bool? isActive,
  });

  /// Soft archive if supported (is_active=false), otherwise delete.
  Future<Result<void>> archiveOrDeleteSpace(String id);

  // Opening hours (space-level)
  Future<Result<List<Map<String, dynamic>>>> listOpeningHours({
    required String venueSpaceId,
  });

  /// Replace weekly schedule atomically (best-effort):
  /// clears existing rows for the space, inserts provided rows.
  /// Each row: {dayOfWeek:int, opensAt:String(HH:mm), closesAt:String(HH:mm)}
  Future<Result<void>> replaceOpeningHours({
    required String venueSpaceId,
    required List<Map<String, dynamic>> hours,
  });

  // Prices (space-level)
  Future<Result<List<Map<String, dynamic>>>> listPrices({
    required String venueSpaceId,
    bool onlyActive = true,
    int? limit,
  });

  /// Upsert single price row. If id is null, insert.
  Future<Result<Map<String, dynamic>>> upsertPrice({
    String? id,
    required String venueSpaceId,
    required String label,
    required int amountCents,
    required String currency,
    required String unit,
    bool? isActive,
  });

  Future<Result<void>> deletePrice(String id);
}
