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
