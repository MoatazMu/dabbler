import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dabbler/core/fp/result.dart';
import '../../services/supabase/supabase_service.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/bench_mode_repository.dart';
import '../../data/repositories/bench_mode_repository_impl.dart';

final benchModeRepositoryProvider =
    Provider.autoDispose<BenchModeRepository>((ref) {
  final svc = ref.watch(supabaseServiceProvider);
  return BenchModeRepositoryImpl(svc);
});

final myProfileByTypeProvider =
    FutureProvider.autoDispose.family<Result<Profile>, String>((ref, type) {
  final repo = ref.watch(benchModeRepositoryProvider);
  return repo.getMyProfileByType(type);
});

final myProfileActiveProvider =
    FutureProvider.autoDispose.family<Result<bool>, String>((ref, type) {
  final repo = ref.watch(benchModeRepositoryProvider);
  return repo.isMyProfileActive(type);
});

final benchMyProfileProvider =
    FutureProvider.autoDispose.family<Result<Profile>, String>((ref, type) {
  final repo = ref.watch(benchModeRepositoryProvider);
  return repo.benchMyProfile(type);
});

final unbenchMyProfileProvider =
    FutureProvider.autoDispose.family<Result<Profile>, String>((ref, type) {
  final repo = ref.watch(benchModeRepositoryProvider);
  return repo.unbenchMyProfile(type);
});

final myProfileStreamProvider =
    StreamProvider.autoDispose.family<Result<Profile>, String>((ref, type) {
  final repo = ref.watch(benchModeRepositoryProvider);
  return repo.myProfileStream(type);
});
