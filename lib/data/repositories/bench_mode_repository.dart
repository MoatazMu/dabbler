import '../../core/result.dart';
import '../models/profile.dart';

/// Bench-mode operations on `profiles`.
///
/// RLS expectations:
/// - Read: owner rows via `profiles_select_owner`; public rows via `profiles_select_public (is_active=true)`.
/// - Update: owner-only via `profiles_update_owner` (auth.uid() == user_id).
abstract class BenchModeRepository {
  /// Get the caller's profile for a given type ('player'|'organiser').
  Future<Result<Profile>> getMyProfileByType(String profileType);

  /// Is the caller's profile active (i.e., NOT benched)?
  Future<Result<bool>> isMyProfileActive(String profileType);

  /// Set is_active = false for the caller's profile (bench).
  Future<Result<Profile>> benchMyProfile(String profileType);

  /// Set is_active = true for the caller's profile (unbench).
  Future<Result<Profile>> unbenchMyProfile(String profileType);

  /// Stream the caller's profile by type so UI can react to bench state.
  Stream<Result<Profile>> myProfileStream(String profileType);
}
