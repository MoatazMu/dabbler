import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../core/utils/json.dart';
import '../../services/supabase_service.dart';
import '../models/vibe.dart';
import 'base_repository.dart';
import 'vibes_repository.dart';

@immutable
class VibesRepositoryImpl extends BaseRepository implements VibesRepository {
  const VibesRepositoryImpl(super.svc);

  SupabaseClient get _db => svc.client;

  static const _table = 'post_vibes';

  @override
  Future<Result<Vibe?>> getForPost(String postId) async {
    return guard<Vibe?>(() async {
      final rows = await _db
          .from(_table)
          .select<List<Map<String, dynamic>>>()
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return null;
      return Vibe.fromMap(asMap(rows.first));
    });
  }

  @override
  Future<Result<Map<String, int>>> countsForPost(String postId) async {
    return guard<Map<String, int>>(() async {
      final rows = await _db
          .from(_table)
          .select<List<Map<String, dynamic>>>('vibe')
          .eq('post_id', postId);

      final Map<String, int> counts = {};
      for (final r in rows) {
        final k = asString(r['vibe']);
        counts[k] = (counts[k] ?? 0) + 1;
      }
      return counts;
    });
  }

  @override
  Future<Result<void>> setVibe({
    required String postId,
    required String vibe,
  }) async {
    return guard<void>(() async {
      if (postId.isEmpty || vibe.isEmpty) {
        throw Failure.badRequest('postId and vibe are required');
      }

      // Conservative, RLS-safe approach:
      // 1) delete existing rows for this post_id (author only)
      // 2) insert the new vibe
      await _db.from(_table).delete().eq('post_id', postId);

      await _db.from(_table).insert({
        'post_id': postId,
        'vibe': vibe,
        // created_at defaults server-side; omit to let DB fill it
      });
    });
  }

  @override
  Future<Result<void>> clearVibe(String postId) async {
    return guard<void>(() async {
      if (postId.isEmpty) throw Failure.badRequest('postId is required');
      await _db.from(_table).delete().eq('post_id', postId);
    });
  }
}
