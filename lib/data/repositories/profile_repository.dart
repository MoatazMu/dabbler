import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileModel>> fetchProfile(String userId);

  Future<Either<Failure, ProfileModel>> upsertProfile(ProfileModel profile);
}
