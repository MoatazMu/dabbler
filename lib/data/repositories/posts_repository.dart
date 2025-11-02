import 'package:dabbler/core/fp/result.dart';
import '../models/post.dart';

abstract class PostsRepository {
  /// The user's home feed (recent, RLS-visible to the viewer).
  Future<Result<List<Post>>> listRecent({int limit = 50, DateTime? before});

  /// All posts authored by a specific user (still RLS-checked for viewer).
  Future<Result<List<Post>>> listByAuthor(
    String authorUserId, {
    int limit = 50,
    DateTime? before,
  });

  /// Load a single post by id (RLS decides if the viewer can see it).
  Future<Result<Post?>> getById(String id);

  /// Create a post as the current user.
  /// `visibility` must be one of 'public' | 'circle' | 'hidden'.
  Future<Result<Post>> create({
    required String visibility,
    String? body,
    String? mediaUrl,
    String? squadId,
    Map<String, dynamic>? meta,
  });

  /// Update a post the current user owns (or admin). Returns updated row.
  Future<Result<Post>> update(
    String id, {
    String? visibility,
    String? body,
    String? mediaUrl,
    String? squadId,
    Map<String, dynamic>? meta,
  });
}
