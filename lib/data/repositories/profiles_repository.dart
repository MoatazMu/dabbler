import '../../core/result.dart';
import '../models/profile.dart';

abstract class ProfilesRepository {
  /// Owner read: relies on policy `profiles_select_owner` (auth.uid() = user_id)
  Future<Result<Profile>> getMyProfile();

  /// Owner/public read by user_id (owner if same uid; otherwise requires is_active=true via public policy)
  Future<Result<Profile>> getByUserId(String userId);

  /// Public read by username (requires is_active = true)
  Future<Result<Profile?>> getPublicByUsername(String username);

  /// Owner upsert: user_id must equal auth.uid(); relies on `profiles_insert_self` or `profiles_update_owner`
  Future<Result<void>> upsert(Profile profile);

  /// Deactivate (bench) myself by setting is_active=false
  Future<Result<void>> deactivateMe();

  /// Reactivate (unbench) myself by setting is_active=true
  Future<Result<void>> reactivateMe();

  /// Realtime stream of my profile row (owner scope)
  Stream<Result<Profile?>> watchMyProfile();
}
