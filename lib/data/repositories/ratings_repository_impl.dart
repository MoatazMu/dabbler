import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../core/utils/json.dart';
import '../../services/supabase_service.dart';
import '../models/rating.dart';
import 'base_repository.dart';
import 'ratings_repository.dart';

@immutable
class RatingsRepositoryImpl extends BaseRepository
    implements RatingsRepository {
  const RatingsRepositoryImpl(super.svc);

  SupabaseClient get _db => svc.client;
  String? get _uid => _db.auth.currentUser?.id;

  // --- lists ---------------------------------------------------------------

  @override
  Future<Result<List<Rating>>> listGiven({
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    return guard<List<Rating>>(() async {
      final uid = _uid;
      if (uid == null) throw Failure.unauthorized('Not signed in');

      final q = _db
          .from('ratings')
          .select<List<Map<String, dynamic>>>()
          .eq('rater_user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);

      if (from != null) q.gte('created_at', from.toUtc().toIso8601String());
      if (to != null) q.lte('created_at', to.toUtc().toIso8601String());

      // RLS: allowed when rater_user_id = auth.uid() (and for admins).
      final rows = await q;
      return rows.map((m) => Rating.fromMap(asMap(m))).toList();
    });
  }

  @override
  Future<Result<List<Rating>>> listAboutMe({
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    return guard<List<Rating>>(() async {
      final uid = _uid;
      if (uid == null) throw Failure.unauthorized('Not signed in');

      final q = _db
          .from('ratings')
          .select<List<Map<String, dynamic>>>()
          .eq('target_user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);

      if (from != null) q.gte('created_at', from.toUtc().toIso8601String());
      if (to != null) q.lte('created_at', to.toUtc().toIso8601String());

      // RLS: allowed when target_user_id = auth.uid() (and for admins).
      final rows = await q;
      return rows.map((m) => Rating.fromMap(asMap(m))).toList();
    });
  }

  @override
  Future<Result<List<Rating>>> listForGame(
    String gameId, {
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    return guard<List<Rating>>(() async {
      final q = _db
          .from('ratings')
          .select<List<Map<String, dynamic>>>()
          .eq('target_game_id', gameId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (from != null) q.gte('created_at', from.toUtc().toIso8601String());
      if (to != null) q.lte('created_at', to.toUtc().toIso8601String());

      // RLS: allowed for the game's host via policy, or admin.
      final rows = await q;
      return rows.map((m) => Rating.fromMap(asMap(m))).toList();
    });
  }

  @override
  Future<Result<List<Rating>>> listForVenue(
    String venueId, {
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    return guard<List<Rating>>(() async {
      final q = _db
          .from('ratings')
          .select<List<Map<String, dynamic>>>()
          .eq('target_venue_id', venueId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (from != null) q.gte('created_at', from.toUtc().toIso8601String());
      if (to != null) q.lte('created_at', to.toUtc().toIso8601String());

      // RLS: allowed for venue owners/managers via policy, or admin.
      final rows = await q;
      return rows.map((m) => Rating.fromMap(asMap(m))).toList();
    });
  }

  // --- aggregates ----------------------------------------------------------

  @override
  Future<Result<RatingAggregate?>> getUserAggregate(String userId) async {
    return guard<RatingAggregate?>(() async {
      final row = await _db
          .from('user_reputation_aggregate')
          .select<Map<String, dynamic>>()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return RatingAggregate.fromMap(row);
    });
  }

  @override
  Future<Result<RatingAggregate?>> getGameAggregate(String gameId) async {
    return guard<RatingAggregate?>(() async {
      final row = await _db
          .from('game_rating_aggregate')
          .select<Map<String, dynamic>>()
          .eq('game_id', gameId)
          .maybeSingle();
      if (row == null) return null;
      return RatingAggregate.fromMap(row);
    });
  }

  @override
  Future<Result<RatingAggregate?>> getVenueAggregate(String venueId) async {
    return guard<RatingAggregate?>(() async {
      final row = await _db
          .from('venue_rating_aggregate')
          .select<Map<String, dynamic>>()
          .eq('venue_id', venueId)
          .maybeSingle();
      if (row == null) return null;
      return RatingAggregate.fromMap(row);
    });
  }
}
