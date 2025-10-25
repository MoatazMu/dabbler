import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../services/supabase_service.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/venue.dart';
import 'base_repository.dart';
import 'search_repository.dart';

class SearchRepositoryImpl extends BaseRepository implements SearchRepository {
  SearchRepositoryImpl(SupabaseService service) : super(service);

  void _ensureAuthenticated() {
    if (svc.authUserId() == null) {
      throw const _UnauthorizedFailure();
    }
  }

  @override
  Future<Result<List<Post>>> searchPosts(
    String q, {
    int limit = 20,
    int offset = 0,
  }) {
    return guard(() async {
      _ensureAuthenticated();

      final response = await svc.client.rpc(
        'search_posts_trgm',
        params: <String, dynamic>{
          'q': q,
          'limit': limit,
          'offset': offset,
        },
      ) as List<dynamic>?;

      final rows = response ?? const <dynamic>[];

      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .map(Post.fromJson)
          .toList(growable: false);
    });
  }

  @override
  Future<Result<List<Venue>>> searchVenues(
    String q, {
    int limit = 20,
    int offset = 0,
  }) {
    return guard(() async {
      _ensureAuthenticated();

      final response = await svc.client.rpc(
        'search_venues_trgm',
        params: <String, dynamic>{
          'q': q,
          'limit': limit,
          'offset': offset,
        },
      ) as List<dynamic>?;

      final rows = response ?? const <dynamic>[];

      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .map(Venue.fromJson)
          .toList(growable: false);
    });
  }

  @override
  Future<Result<List<Profile>>> searchProfiles(
    String q, {
    int limit = 20,
    int offset = 0,
  }) {
    return guard(() async {
      _ensureAuthenticated();

      final response = await svc.client.rpc(
        'search_profiles_trgm',
        params: <String, dynamic>{
          'q': q,
          'limit': limit,
          'offset': offset,
        },
      ) as List<dynamic>?;

      final rows = response ?? const <dynamic>[];

      return rows
          .map((row) => Map<String, dynamic>.from(row as Map))
          .map(Profile.fromJson)
          .toList(growable: false);
    });
  }
}

class _UnauthorizedFailure extends Failure {
  const _UnauthorizedFailure() : super('Not signed in');
}
