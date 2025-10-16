import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../repositories/profile_stats_repository.dart';

/// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  // TODO: Replace with actual implementation
  return ProfileRepository(); // Placeholder implementation
});

/// Profile stats repository provider
final profileStatsRepositoryProvider = Provider<ProfileStatsRepository>((ref) {
  // TODO: Replace with actual implementation
  return ProfileStatsRepository(); // Placeholder implementation
});
