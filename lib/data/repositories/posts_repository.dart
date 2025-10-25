import '../../core/types/result.dart';
import '../models/post.dart';

abstract class PostsRepository {
  /// Create a post as the current user (RLS requires auth.uid() to match author_user_id).
  Future<Result<Post>> createPost({
    required String visibility, // 'public' | 'circle' | 'hidden'
    String? content,
    String? mediaUrl,
    String? squadId,
  });

  /// Fetch a single post by id (null if not visible to viewer).
  Future<Result<Post?>> getPost(String id);

  /// List posts authored by the current user (DESC created_at).
  Future<Result<List<Post>>> listMyPosts({
    DateTime? from, // inclusive
    DateTime? to, // exclusive
    int? limit,
    int? offset,
  });

  /// List posts by a specific author (viewer must have visibility via RLS).
  Future<Result<List<Post>>> listUserPosts(
    String userId, {
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  });

  /// List posts scoped to a squad (viewer must have visibility via RLS).
  Future<Result<List<Post>>> listSquadPosts(
    String squadId, {
    int? limit,
    int? offset,
  });

  /// Update allowed fields on a post you own (or admin).
  Future<Result<Post>> updatePost(
    String postId, {
    String? content,
    String? visibility,
    String? mediaUrl,
    String? squadId,
  });
}
