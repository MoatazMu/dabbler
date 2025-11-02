import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/sport_profile.dart';
import 'package:dabbler/data/repositories/sport_profiles_repository.dart';
import 'package:dabbler/data/repositories/sport_profiles_repository_impl.dart';
import 'package:dabbler/services/supabase/supabase_service.dart';

final sportProfilesRepositoryProvider = Provider<SportProfilesRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return SportProfilesRepositoryImpl(svc);
});

final mySportProfilesStreamProvider =
    StreamProvider<Result<List<SportProfile>>>((ref) {
  return ref.watch(sportProfilesRepositoryProvider).watchMySports();
});

final mySportProfilesProvider =
    FutureProvider<Result<List<SportProfile>>>((ref) async {
  return ref.watch(sportProfilesRepositoryProvider).getMySports();
});
