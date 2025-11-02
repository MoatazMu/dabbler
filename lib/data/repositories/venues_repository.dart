import 'package:fpdart/fpdart.dart';

import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/data/models/venue.dart';
import 'package:dabbler/data/models/venue_space.dart';

typedef Result<T> = Either<Failure, T>;

abstract class VenuesRepository {
  /// Public venues listing relying on the `venues_public_read` policy.
  Future<Result<List<Venue>>> listVenues({
    bool activeOnly = true,
    String? city,
    String? district,
    String? q,
  });

  /// Fetches a single venue using the `venues_public_read` policy.
  Future<Result<Venue>> getVenueById(String venueId);

  /// Lists spaces for a venue using the `spaces_public_read` policy.
  Future<Result<List<VenueSpace>>> listSpacesByVenue(
    String venueId, {
    bool activeOnly = true,
  });

  /// Fetches a single space using the `spaces_public_read` policy.
  Future<Result<VenueSpace>> getSpaceById(String spaceId);

  /// Approximates nearby venues via a bounding box using `venues_public_read`.
  Future<Result<List<Venue>>> nearbyVenues({
    required double lat,
    required double lng,
    double withinKm = 10,
    bool activeOnly = true,
  });

  /// Watches spaces for a venue; RLS ensures manage access server-side.
  Stream<Result<List<VenueSpace>>> watchSpacesByVenue(String venueId);
}
