import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dabbler/data/models/venue.dart';
import 'package:dabbler/data/models/venue_space.dart';
import 'package:dabbler/data/repositories/venues_repository.dart';
import 'package:dabbler/data/repositories/venues_repository_impl.dart';
import 'package:dabbler/features/misc/data/datasources/supabase_remote_data_source.dart';

final venuesRepositoryProvider = Provider<VenuesRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return VenuesRepositoryImpl(svc);
});

final activeVenuesProvider =
    FutureProvider.family<
      Result<List<Venue>>,
      ({String? city, String? district, String? q})
    >((ref, params) async {
      return ref
          .watch(venuesRepositoryProvider)
          .listVenues(
            activeOnly: true,
            city: params.city,
            district: params.district,
            q: params.q,
          );
    });

final spacesByVenueStreamProvider =
    StreamProvider.family<Result<List<VenueSpace>>, String>((ref, venueId) {
      return ref.watch(venuesRepositoryProvider).watchSpacesByVenue(venueId);
    });
