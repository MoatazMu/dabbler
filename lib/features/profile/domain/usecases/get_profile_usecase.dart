import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<UserProfile?> call(String userId) async {
    final result = await repository.getProfile(userId);
    return result.fold((_) => null, (profile) => profile);
  }
}
