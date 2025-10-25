import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/error/failure.dart';
import 'package:dabbler/core/types/result.dart';
import 'package:dabbler/data/models/game.dart';
import 'package:dabbler/data/models/venue.dart';
import 'package:dabbler/data/repositories/base_repository.dart';
import 'package:dabbler/data/repositories/geo_repository.dart';
import 'package:dabbler/services/supabase_service.dart';

class GeoRepositoryImpl extends BaseRepository implements GeoRepository {
  GeoRepositoryImpl(this._service) : super(_service);

  final SupabaseService _service;

  SupabaseClient get _client => _service.client;

  void _assertSignedIn() {
    if (_client.auth.currentUser == null) {
      throw Failure.unauthorized(message: 'Not signed in');
    }
  }

  @override
  Future<Result<List<Venue>>> nearbyVenues({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int limit = 20,
    int offset = 0,
  }) {
    return guard(() async {
      _assertSignedIn();

      final response = await _client.rpc(
        'venues_nearby',
        params: <String, dynamic>{
          'lat': lat,
          'lng': lng,
          'radius_m': radiusMeters,
          'limit': limit,
          'offset': offset,
        },
      );

      final rows = response is List ? response : const <dynamic>[];

      return rows
          .map((dynamic row) => Venue.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList(growable: false);
    });
  }

  @override
  Future<Result<List<Game>>> nearbyGames({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int limit = 20,
    int offset = 0,
  }) {
    return guard(() async {
      _assertSignedIn();

      final response = await _client.rpc(
        'games_nearby',
        params: <String, dynamic>{
          'lat': lat,
          'lng': lng,
          'radius_m': radiusMeters,
          'limit': limit,
          'offset': offset,
        },
      );

      final rows = response is List ? response : const <dynamic>[];

      return rows
          .map((dynamic row) => Game.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList(growable: false);
    });
  }
}

extension _FailureUnauthorized on Failure {
  static Failure unauthorized({String message = 'Unauthorized'}) =>
      AuthFailure(message);
}
