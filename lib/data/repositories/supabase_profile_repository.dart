import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dabbler/core/fp/failure.dart';
import '../models/profile_model.dart';
import 'profile_repository.dart';
import '../../services/supabase/supabase_error_mapper.dart';
import '../../services/supabase/supabase_service.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({
    required SupabaseService service,
    required SupabaseErrorMapper errorMapper,
  }) : _service = service,
       _errorMapper = errorMapper;

  final SupabaseService _service;
  final SupabaseErrorMapper _errorMapper;

  static const String _table = 'profiles';

  @override
  Future<Either<Failure, ProfileModel>> fetchProfile(String userId) async {
    try {
      final response = await _service.maybeSingle(
        _service.from(_table).select().eq('user_id', userId),
      );

      if (response == null) {
        return left(
          SupabaseNotFoundFailure(
            message: 'Profile not found for user $userId',
          ),
        );
      }

      return right(ProfileModel.fromJson(response));
    } catch (error, stackTrace) {
      return left(_errorMapper.map(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, ProfileModel>> upsertProfile(
    ProfileModel profile,
  ) async {
    try {
      final response = await _service.maybeSingle(
        _service
            .from(_table)
            .upsert(profile.toSupabaseJson(), onConflict: 'user_id')
            .select(),
      );

      if (response == null) {
        return left(
          UnexpectedFailure(
            message: 'Supabase did not return the updated profile',
          ),
        );
      }

      return right(ProfileModel.fromJson(response));
    } catch (error, stackTrace) {
      return left(_errorMapper.map(error, stackTrace: stackTrace));
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  final mapper = ref.watch(supabaseErrorMapperProvider);
  return SupabaseProfileRepository(service: service, errorMapper: mapper);
});
