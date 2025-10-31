import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import '../../core/types/result.dart';
import '../../core/utils/json.dart';
import '../models/post.dart';
import 'base_repository.dart';
import 'posts_repository.dart';

@immutable
class PostsRepositoryImpl extends BaseRepository implements PostsRepository {
  const PostsRepositoryImpl(super.svc);

  SupabaseClient get _db => svc.client;
  String? get _uid => _db.auth.currentUser?.id;

  static const _table = 'posts';

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  @override
  Future<Result<List<Post>>> listRecent({
    int limit = 50,
    DateTime? before,
  }) async {
    return guard<List<Post>>(() async {
      final q = _db
          .from(_table)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      if (before != null) {
        q.lt('created_at', before.toUtc().toIso8601String());
      }

      // RLS ensures only can_view_post rows are returned.
      final rows = await q;
      return rows.map((m) => Post.fromMap(asMap(m))).toList();
    });
  }

  @override
  Future<Result<List<Post>>> listByAuthor(
    String authorUserId, {
    int limit = 50,
    DateTime? before,
  }) async {
    return guard<List<Post>>(() async {
      final q = _db
          .from(_table)
          .select()
          .eq('author_user_id', authorUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (before != null) {
        q.lt('created_at', before.toUtc().toIso8601String());
      }

      final rows = await q;
      return rows.map((m) => Post.fromMap(asMap(m))).toList();
    });
  }

  @override
  Future<Result<Post?>> getById(String id) async {
    return guard<Post?>(() async {
      final row = await _db
          .from(_table)
          .select<Map<String, dynamic>>()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return Post.fromMap(row);
    });
  }

  // ---------------------------------------------------------------------------
  // Writes (insert/update only; delete intentionally omitted)
  // ---------------------------------------------------------------------------

  @override
  Future<Result<Post>> create({
    required String visibility,
    String? body,
    String? mediaUrl,
    String? squadId,
    Map<String, dynamic>? meta,
  }) async {
    return guard<Post>(() async {
      final uid = _uid;
      if (uid == null) throw Failure.unauthorized('Not signed in');

      final insert = Post(
        id: 'tmp',
        authorUserId: uid,
        visibility: visibility,
        body: body,
        mediaUrl: mediaUrl,
        squadId: squadId,
        meta: meta,
        createdAt: DateTime.now().toUtc(),
      ).toInsert();

      // RLS: WITH CHECK enforces author_user_id = auth.uid() and freeze state.
      final row = await _db
          .from(_table)
          .insert(insert)
          .select<Map<String, dynamic>>()
          .single();

      return Post.fromMap(row);
    });
  }

  @override
  Future<Result<Post>> update(
    String id, {
    String? visibility,
    String? body,
    String? mediaUrl,
    String? squadId,
    Map<String, dynamic>? meta,
  }) async {
    return guard<Post>(() async {
      final uid = _uid;
      if (uid == null) throw Failure.unauthorized('Not signed in');

      final patch = <String, dynamic>{}
        ..addAll(
          Post(
            id: id,
            authorUserId: uid,
            visibility: visibility ?? 'public',
            createdAt: DateTime.now().toUtc(),
          ).toUpdate(
            newVisibility: visibility,
            newBody: body,
            newMediaUrl: mediaUrl,
            newSquadId: squadId,
            newMeta: meta,
          ),
        );

      if (patch.isEmpty) {
        // No-op: return current row
        final current = await _db
            .from(_table)
            .select<Map<String, dynamic>>()
            .eq('id', id)
            .single();
        return Post.fromMap(current);
      }

      // RLS: owner (or admin) can update; freeze policy may block.
      final row = await _db
          .from(_table)
          .update(patch)
          .eq('id', id)
          .select<Map<String, dynamic>>()
          .single();

      return Post.fromMap(row);
    });
  }
}
