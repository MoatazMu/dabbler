import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/types/result.dart';
import '../../services/supabase_service.dart';
import '../models/rating.dart';
import 'base_repository.dart';
import 'ratings_repository.dart';

class RatingsRepositoryImpl extends BaseRepository implements RatingsRepository {
  RatingsRepositoryImpl(SupabaseService service) : super(service);

  SupabaseClient get _client => svc.client;

  static const _ratingsProjection =
      'id,rater_user_id,target_user_id,target_game_id,target_venue_id,context_id,score,comment,created_at';
  static const _gameAggregateProjection =
      'game_id,avg_score,ratings_count,updated_at';
  static const _venueAggregateProjection =
      'venue_id,avg_score,ratings_count,updated_at';
  static const _reportProjection =
      'id,reporter_user_id,rating_id,reason,created_at';

  PostgrestFilterBuilder<PostgrestList> _applyTimeFilters(
    PostgrestFilterBuilder<PostgrestList> query, {
    DateTime? from,
    DateTime? to,
  }) {
    if (from != null) {
      query = query.gte('created_at', from.toUtc().toIso8601String());
    }
    if (to != null) {
      query = query.lt('created_at', to.toUtc().toIso8601String());
    }
    return query;
  }

  PostgrestFilterBuilder<PostgrestList> _applyPagination(
    PostgrestFilterBuilder<PostgrestList> query, {
    int? limit,
    int? offset,
  }) {
    if (limit != null) {
      query = query.limit(limit);
    }
    if (offset != null) {
      final effectiveLimit = limit ?? 50;
      query = query.range(offset, offset + effectiveLimit - 1);
    }
    return query;
  }

  List<Rating> _mapRatings(List<dynamic> rows) {
    return rows
        .map(
          (row) => Rating.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<Result<List<Rating>>> listMyRatings({
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) {
    return guard(() async {
      var query = _client
          .from('ratings')
          .select(_ratingsProjection)
          .order('created_at', ascending: false);

      query = _applyTimeFilters(query, from: from, to: to);
      query = _applyPagination(query, limit: limit, offset: offset);

      final rows = await query as List<dynamic>;
      return _mapRatings(rows);
    });
  }

  @override
  Future<Result<List<Rating>>> listRatingsForUser(
    String userId, {
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) {
    return guard(() async {
      var query = _client
          .from('ratings')
          .select(_ratingsProjection)
          .eq('target_user_id', userId)
          .order('created_at', ascending: false);

      query = _applyTimeFilters(query, from: from, to: to);
      query = _applyPagination(query, limit: limit, offset: offset);

      final rows = await query as List<dynamic>;
      return _mapRatings(rows);
    });
  }

  @override
  Future<Result<List<Rating>>> listRatingsForGame(
    String gameId, {
    int? limit,
    int? offset,
  }) {
    return guard(() async {
      var query = _client
          .from('ratings')
          .select(_ratingsProjection)
          .eq('target_game_id', gameId)
          .order('created_at', ascending: false);

      query = _applyPagination(query, limit: limit, offset: offset);

      final rows = await query as List<dynamic>;
      return _mapRatings(rows);
    });
  }

  @override
  Future<Result<List<Rating>>> listRatingsForVenue(
    String venueId, {
    int? limit,
    int? offset,
  }) {
    return guard(() async {
      var query = _client
          .from('ratings')
          .select(_ratingsProjection)
          .eq('target_venue_id', venueId)
          .order('created_at', ascending: false);

      query = _applyPagination(query, limit: limit, offset: offset);

      final rows = await query as List<dynamic>;
      return _mapRatings(rows);
    });
  }

  Map<String, dynamic> _mapAggregate(Map<String, dynamic> data) {
    final map = <String, dynamic>{};
    if (data.containsKey('game_id')) {
      map['game_id'] = data['game_id'] as String;
    }
    if (data.containsKey('venue_id')) {
      map['venue_id'] = data['venue_id'] as String;
    }
    map['avg_score'] = (data['avg_score'] as num?)?.toDouble();
    map['ratings_count'] = data['ratings_count'] is int
        ? data['ratings_count'] as int
        : (data['ratings_count'] as num?)?.toInt();
    final updatedAt = data['updated_at'];
    if (updatedAt is String) {
      map['updated_at'] = DateTime.parse(updatedAt).toUtc();
    } else {
      map['updated_at'] = updatedAt;
    }
    return map;
  }

  @override
  Future<Result<Map<String, dynamic>?>> getGameAggregate(String gameId) {
    return guard(() async {
      final response = await _client
          .from('game_rating_aggregate')
          .select(_gameAggregateProjection)
          .eq('game_id', gameId)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return _mapAggregate(Map<String, dynamic>.from(response));
    });
  }

  @override
  Future<Result<Map<String, dynamic>?>> getVenueAggregate(String venueId) {
    return guard(() async {
      final response = await _client
          .from('venue_rating_aggregate')
          .select(_venueAggregateProjection)
          .eq('venue_id', venueId)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return _mapAggregate(Map<String, dynamic>.from(response));
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> reportRating({
    required String ratingId,
    required String reason,
  }) {
    return guard(() async {
      final payload = {
        'rating_id': ratingId,
        'reason': reason,
      };
      final response = await _client
          .from('rating_reports')
          .insert(payload)
          .select(_reportProjection)
          .single();
      final map = Map<String, dynamic>.from(response as Map);
      final createdAt = map['created_at'];
      if (createdAt is String) {
        map['created_at'] = DateTime.parse(createdAt).toUtc();
      }
      return map;
    });
  }
}
