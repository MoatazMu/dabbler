import 'dart:async';
import 'dart:math' as math;

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/errors/failure.dart';
import 'package:dabbler/data/models/venue.dart';
import 'package:dabbler/data/models/venue_space.dart';
import 'package:dabbler/data/repositories/base_repository.dart';
import 'package:dabbler/data/repositories/venues_repository.dart';

class VenuesRepositoryImpl extends BaseRepository implements VenuesRepository {
  VenuesRepositoryImpl(super.svc);

  static const String venuesTable = 'venues';
  static const String spacesTable = 'venue_spaces';

  @override
  Future<Result<List<Venue>>> listVenues({
    bool activeOnly = true,
    String? city,
    String? district,
    String? q,
  }) async {
    try {
      PostgrestFilterBuilder<Map<String, dynamic>> query =
          svc.from(venuesTable).select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      if (city != null) {
        query = query.eq('city', city);
      }
      if (district != null) {
        query = query.eq('district', district);
      }
      if (q != null && q.isNotEmpty) {
        query = query.ilike('name', '%$q%');
      }

      query = query.order('name');

      final data = await svc.getList(query);
      final venues = data.map(Venue.fromJson).toList(growable: false);
      return right(venues);
    } catch (error) {
      return left(mapPostgrestError(error));
    }
  }

  @override
  Future<Result<Venue>> getVenueById(String venueId) async {
    try {
      final query = svc.from(venuesTable).select().eq('id', venueId);
      final data = await svc.maybeSingle(query);
      if (data == null) {
        return left(
          NotFoundFailure(message: 'Venue $venueId not found'),
        );
      }
      return right(Venue.fromJson(data));
    } catch (error) {
      return left(mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<VenueSpace>>> listSpacesByVenue(
    String venueId, {
    bool activeOnly = true,
  }) async {
    try {
      PostgrestFilterBuilder<Map<String, dynamic>> query =
          svc.from(spacesTable).select().eq('venue_id', venueId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      query = query.order('name');

      final data = await svc.getList(query);
      final spaces = data.map(VenueSpace.fromJson).toList(growable: false);
      return right(spaces);
    } catch (error) {
      return left(mapPostgrestError(error));
    }
  }

  @override
  Future<Result<VenueSpace>> getSpaceById(String spaceId) async {
    try {
      final query = svc.from(spacesTable).select().eq('id', spaceId);
      final data = await svc.maybeSingle(query);
      if (data == null) {
        return left(
          NotFoundFailure(message: 'Venue space $spaceId not found'),
        );
      }
      return right(VenueSpace.fromJson(data));
    } catch (error) {
      return left(mapPostgrestError(error));
    }
  }

  @override
  Future<Result<List<Venue>>> nearbyVenues({
    required double lat,
    required double lng,
    double withinKm = 10,
    bool activeOnly = true,
  }) async {
    try {
      // Bounding-box approximation; a precise circular search can use an RPC with
      // haversine distance if needed in the future.
      final latInRadians = lat * math.pi / 180;
      final dLat = withinKm / 110.574;
      final cosLat = math.cos(latInRadians).abs();
      final lngDenominator = (111.320 * (cosLat < 1e-6 ? 1e-6 : cosLat));
      final dLng = withinKm / lngDenominator;

      PostgrestFilterBuilder<Map<String, dynamic>> query =
          svc.from(venuesTable).select()
            ..gte('lat', lat - dLat)
            ..lte('lat', lat + dLat)
            ..gte('lng', lng - dLng)
            ..lte('lng', lng + dLng);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      query = query.order('name');

      final data = await svc.getList(query);
      final venues = data.map(Venue.fromJson).toList(growable: false);
      return right(venues);
    } catch (error) {
      return left(mapPostgrestError(error));
    }
  }

  @override
  Stream<Result<List<VenueSpace>>> watchSpacesByVenue(String venueId) {
    final controller = StreamController<Result<List<VenueSpace>>>.broadcast();
    RealtimeChannel? channel;

    Future<void> emitCurrent() async {
      final result = await listSpacesByVenue(venueId);
      if (!controller.isClosed) {
        controller.add(result);
      }
    }

    void emitError(Object error, [StackTrace? stackTrace]) {
      if (!controller.isClosed) {
        controller.add(left(mapPostgrestError(error)));
      }
    }

    controller.onListen = () {
      channel = svc.client.channel('public:$spacesTable')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: spacesTable,
          filter: 'venue_id=eq.$venueId',
          callback: (payload) {
            unawaited(emitCurrent());
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: spacesTable,
          filter: 'venue_id=eq.$venueId',
          callback: (payload) {
            unawaited(emitCurrent());
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: spacesTable,
          filter: 'venue_id=eq.$venueId',
          callback: (payload) {
            unawaited(emitCurrent());
          },
        );

      channel!
        ..onError((error, {StackTrace? stackTrace}) {
          emitError(error, stackTrace);
        })
        ..subscribe();

      unawaited(emitCurrent());
    };

    controller.onCancel = () async {
      final currentChannel = channel;
      channel = null;
      if (currentChannel != null) {
        await currentChannel.unsubscribe();
        await svc.client.removeChannel(currentChannel);
      }
    };

    return controller.stream;
  }
}
