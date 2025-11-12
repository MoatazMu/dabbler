import 'package:fpdart/fpdart.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dabbler/core/fp/failure.dart';
import '../models/profile/user_profile.dart';
import 'profile_repository.dart';
import '../../features/misc/data/datasources/supabase_error_mapper.dart';
import '../../features/misc/data/datasources/supabase_remote_data_source.dart';

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
  Future<Either<Failure, UserProfile>> fetchProfile(String userId) async {
    try {
      final response = await _service
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return left(
          SupabaseNotFoundFailure(
            message: 'Profile not found for user $userId',
          ),
        );
      }

      return right(UserProfile.fromJson(response));
    } catch (error, stackTrace) {
      return left(_errorMapper.map(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> upsertProfile(
    UserProfile profile,
  ) async {
    try {
      final response = await _service
          .from(_table)
          .upsert(profile.toJson(), onConflict: 'user_id')
          .select()
          .single();

      return right(UserProfile.fromJson(response));
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
