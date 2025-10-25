import '../../core/types/result.dart';
import '../models/rating.dart';

abstract class RatingsRepository {
  /// Ratings authored by the current user (RLS also restricts rows).
  Future<Result<List<Rating>>> listMyRatings({
    DateTime? from, // inclusive
    DateTime? to, // exclusive
    int? limit,
    int? offset,
  });

  /// Ratings received by a user (viewer must be that user/admin/etc via RLS).
  Future<Result<List<Rating>>> listRatingsForUser(
    String userId, {
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  });

  /// Ratings for a game (viewer must be host/admin/etc via RLS).
  Future<Result<List<Rating>>> listRatingsForGame(
    String gameId, {
    int? limit,
    int? offset,
  });

  /// Ratings for a venue (viewer must be venue admin/admin via RLS).
  Future<Result<List<Rating>>> listRatingsForVenue(
    String venueId, {
    int? limit,
    int? offset,
  });

  /// Aggregates (public read).
  Future<Result<Map<String, dynamic>?>> getGameAggregate(String gameId);
  Future<Result<Map<String, dynamic>?>> getVenueAggregate(String venueId);

  /// File a report on a rating.
  Future<Result<Map<String, dynamic>>> reportRating({
    required String ratingId,
    required String reason,
  });
}
