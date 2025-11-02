import 'package:dabbler/core/fp/result.dart';
import '../models/rating.dart';

abstract class RatingsRepository {
  /// Ratings authored by the current user.
  Future<Result<List<Rating>>> listGiven({
    DateTime? from,
    DateTime? to,
    int limit = 200,
  });

  /// Ratings where the current user is the target (about me).
  Future<Result<List<Rating>>> listAboutMe({
    DateTime? from,
    DateTime? to,
    int limit = 200,
  });

  /// Ratings attached to a specific game.
  Future<Result<List<Rating>>> listForGame(
    String gameId, {
    DateTime? from,
    DateTime? to,
    int limit = 200,
  });

  /// Ratings attached to a specific venue.
  Future<Result<List<Rating>>> listForVenue(
    String venueId, {
    DateTime? from,
    DateTime? to,
    int limit = 200,
  });

  /// Aggregates
  Future<Result<RatingAggregate?>> getUserAggregate(String userId);
  Future<Result<RatingAggregate?>> getGameAggregate(String gameId);
  Future<Result<RatingAggregate?>> getVenueAggregate(String venueId);
}
