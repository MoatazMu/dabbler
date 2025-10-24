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
import 'package:dartz/dartz.dart';
import 'package:dabbler/core/error/failures.dart';
import 'package:dabbler/data/models/profile.dart';

typedef Result<T> = Either<Failure, T>;

abstract class ProfilesRepository {
  Future<Result<Profile>> getMyProfile();
  Future<Result<Profile>> getByUserId(String userId);
  Future<Result<Profile?>> getPublicByUsername(String username);
  Future<Result<void>> upsert(Profile profile);
  Future<Result<void>> deleteSoft(String userId);
  Stream<Result<Profile?>> watchMyProfile();
}
