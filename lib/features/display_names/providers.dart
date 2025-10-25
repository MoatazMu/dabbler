import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/display_name_repository.dart';
import '../../data/repositories/display_name_repository_impl.dart';
import '../../services/supabase_service.dart';

final displayNameRepositoryProvider =
    Provider.autoDispose<DisplayNameRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return DisplayNameRepositoryImpl(svc);
});

final displayNameAvailabilityProvider =
    FutureProvider.autoDispose.family<Result<bool>, String>((ref, name) {
  final repo = ref.watch(displayNameRepositoryProvider);
  return repo.isAvailable(name);
});

final displayNameSearchProvider = FutureProvider.autoDispose
    .family<Result<List<Profile>>, ({String query, int limit, int offset})>(
        (ref, args) {
  final repo = ref.watch(displayNameRepositoryProvider);
  return repo.search(
    query: args.query,
    limit: args.limit,
    offset: args.offset,
  );
});

final setDisplayNameForProfileProvider = FutureProvider.autoDispose
    .family<Result<Profile>, ({String profileId, String displayName})>(
        (ref, args) {
  final repo = ref.watch(displayNameRepositoryProvider);
  return repo.setDisplayNameForProfile(
    profileId: args.profileId,
    displayName: args.displayName,
  );
});

final setMyDisplayNameForTypeProvider = FutureProvider.autoDispose
    .family<Result<Profile>, ({String profileType, String displayName})>(
        (ref, args) {
  final repo = ref.watch(displayNameRepositoryProvider);
  return repo.setMyDisplayNameForType(
    profileType: args.profileType,
    displayName: args.displayName,
  );
});

final myProfileDisplayStreamProvider =
    StreamProvider.autoDispose.family<Result<Profile>, String>((ref, type) {
  final repo = ref.watch(displayNameRepositoryProvider);
  return repo.myProfileTypeStream(type);
});
