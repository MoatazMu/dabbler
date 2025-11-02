import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dabbler/core/fp/result.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/profiles_repository.dart';
import '../../data/repositories/profiles_repository_impl.dart';
import '../../services/supabase/supabase_service.dart';

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return ProfilesRepositoryImpl(svc);
});

final myProfileStreamProvider = StreamProvider<Result<Profile?>>((ref) {
  return ref.watch(profilesRepositoryProvider).watchMyProfile();
});
