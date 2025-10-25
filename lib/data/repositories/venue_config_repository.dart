import '../../core/types/result.dart';
import '../models/venue_space.dart';

abstract class VenueConfigRepository {
  /// List active spaces; optionally filter by venue.
  Future<Result<List<VenueSpace>>> listActiveSpaces({String? venueId, int limit = 100});

  /// Get opening hours for a space.
  Future<Result<List<OpeningHour>>> getOpeningHours(String venueSpaceId);

  /// Get active prices for a space.
  Future<Result<List<SpacePrice>>> getActivePrices(String venueSpaceId);

  /// Admin/Manager: create or update a space.
  Future<Result<VenueSpace>> upsertSpace(VenueSpace space);

  /// Admin/Manager: create/update opening hour.
  Future<Result<OpeningHour>> upsertOpeningHour(OpeningHour hour);

  /// Admin/Manager: create/update price.
  Future<Result<SpacePrice>> upsertSpacePrice(SpacePrice price);

  /// Admin/Manager: soft-toggle a space to active/inactive.
  Future<Result<VenueSpace>> setSpaceActive({
    required String spaceId,
    required bool isActive,
  });
}

