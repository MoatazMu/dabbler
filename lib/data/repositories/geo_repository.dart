import 'package:dabbler/core/types/result.dart';
import 'package:dabbler/data/models/game.dart';
import 'package:dabbler/data/models/venue.dart';

abstract class GeoRepository {
  Future<Result<List<Venue>>> nearbyVenues({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int limit = 20,
    int offset = 0,
  });

  Future<Result<List<Game>>> nearbyGames({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int limit = 20,
    int offset = 0,
  });
}
