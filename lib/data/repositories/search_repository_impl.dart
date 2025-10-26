import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../core/utils/json.dart';
import '../../services/supabase_service.dart';
import '../models/profile.dart';
import '../models/venue.dart';
import '../models/post.dart';
import 'base_repository.dart';
import 'search_repository.dart';

@immutable
class SearchRepositoryImpl extends BaseRepository implements SearchRepository {
  const SearchRepositoryImpl(super.svc);

  SupabaseClient get _db => svc.client;

  // --- helpers ---------------------------------------------------------------

  /// Builds a simple OR filter like:
  /// or(username.ilike.%foo%,display_name.ilike.%foo%)
  String _orIlike(List<String> fields, String query) {
    final q = query.trim();
    final needle = '%${q.replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    final parts = fields.map((f) => '$f.ilike.$needle').join(',');
    return 'or($parts)';
  }

  // --- profiles --------------------------------------------------------------

  @override
  Future<Result<List<Profile>>> searchProfiles({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    return guard<List<Profile>>(() async {
      if (query.trim().isEmpty) return <Profile>[];

      final rows = await _db
          .from('profiles')
          // choose the columns your Profile.fromMap expects
          .select<List<Map<String, dynamic>>>()
          .or(_orIlike(const ['username', 'display_name'], query))
          .order('display_name', ascending: true, nullsLast: true)
          .limit(limit)
          .range(offset, offset + limit - 1);

      return rows.map((m) => Profile.fromMap(asMap(m))).toList();
    });
  }

  // --- venues ---------------------------------------------------------------

  @override
  Future<Result<List<Venue>>> searchVenues({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    return guard<List<Venue>>(() async {
      if (query.trim().isEmpty) return <Venue>[];

      final rows = await _db
          .from('venues')
          .select<List<Map<String, dynamic>>>()
          .or(_orIlike(const ['name'], query))
          .order('name', ascending: true, nullsLast: true)
          .limit(limit)
          .range(offset, offset + limit - 1);

      return rows.map((m) => Venue.fromMap(asMap(m))).toList();
    });
  }

  // --- posts ----------------------------------------------------------------

  @override
  Future<Result<List<Post>>> searchPosts({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    return guard<List<Post>>(() async {
      if (query.trim().isEmpty) return <Post>[];

      // If your schema uses 'text' instead of 'caption', swap the field name.
      final rows = await _db
          .from('posts')
          .select<List<Map<String, dynamic>>>()
          .or(_orIlike(const ['caption'], query))
          // RLS should ensure can_view_post; if you have a dedicated view for
          // visible posts, point to it instead for safety/perf.
          .order('created_at', ascending: false, nullsLast: true)
          .limit(limit)
          .range(offset, offset + limit - 1);

      return rows.map((m) => Post.fromMap(asMap(m))).toList();
    });
  }
}
