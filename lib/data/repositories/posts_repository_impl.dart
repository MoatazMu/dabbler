import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../services/supabase_service.dart';
import '../models/post.dart';
import 'base_repository.dart';
import 'posts_repository.dart';

class PostsRepositoryImpl extends BaseRepository implements PostsRepository {
  PostsRepositoryImpl(this.service) : super(service);

  final SupabaseService service;

  SupabaseClient get client => service.client;

  static const _postCols =
      'id,author_user_id,visibility,squad_id,content,media_url,created_at';

  @override
  Future<Result<Post>> createPost({
    required String visibility,
    String? content,
    String? mediaUrl,
    String? squadId,
  }) {
    return guard(() async {
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        throw AuthFailure('Not signed in');
      }

      final payload = <String, dynamic>{
        'author_user_id': uid,
        'visibility': visibility,
        'squad_id': squadId,
        'content': content,
        'media_url': mediaUrl,
      }..removeWhere((_, value) => value == null);

      final row = await client
          .from('posts')
          .insert(payload)
          .select(_postCols)
          .single();

      return Post.fromJson(Map<String, dynamic>.from(row as Map));
    });
  }

  @override
  Future<Result<Post?>> getPost(String id) {
    return guard(() async {
      final row = await client
          .from('posts')
          .select(_postCols)
          .eq('id', id)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return Post.fromJson(Map<String, dynamic>.from(row as Map));
    });
  }

  @override
  Future<Result<List<Post>>> listMyPosts({
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) {
    return guard(() async {
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        throw AuthFailure('Not signed in');
      }

      final query = client
          .from('posts')
          .select(_postCols)
          .eq('author_user_id', uid)
          .order('created_at', ascending: false);

      if (from != null) {
        query.gte('created_at', from.toUtc().toIso8601String());
      }
      if (to != null) {
        query.lt('created_at', to.toUtc().toIso8601String());
      }
      if (offset != null) {
        final end = offset + (limit ?? 50) - 1;
        query.range(offset, end);
      } else if (limit != null) {
        query.limit(limit);
      }

      final rows = await query;
      return (rows as List)
          .map((row) => Post.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    });
  }

  @override
  Future<Result<List<Post>>> listUserPosts(
    String userId, {
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) {
    return guard(() async {
      final query = client
          .from('posts')
          .select(_postCols)
          .eq('author_user_id', userId)
          .order('created_at', ascending: false);

      if (from != null) {
        query.gte('created_at', from.toUtc().toIso8601String());
      }
      if (to != null) {
        query.lt('created_at', to.toUtc().toIso8601String());
      }
      if (offset != null) {
        final end = offset + (limit ?? 50) - 1;
        query.range(offset, end);
      } else if (limit != null) {
        query.limit(limit);
      }

      final rows = await query;
      return (rows as List)
          .map((row) => Post.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    });
  }

  @override
  Future<Result<List<Post>>> listSquadPosts(
    String squadId, {
    int? limit,
    int? offset,
  }) {
    return guard(() async {
      final query = client
          .from('posts')
          .select(_postCols)
          .eq('squad_id', squadId)
          .order('created_at', ascending: false);

      if (offset != null) {
        final end = offset + (limit ?? 50) - 1;
        query.range(offset, end);
      } else if (limit != null) {
        query.limit(limit);
      }

      final rows = await query;
      return (rows as List)
          .map((row) => Post.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    });
  }

  @override
  Future<Result<Post>> updatePost(
    String postId, {
    String? content,
    String? visibility,
    String? mediaUrl,
    String? squadId,
  }) {
    return guard(() async {
      final updates = <String, dynamic>{
        if (content != null) 'content': content,
        if (visibility != null) 'visibility': visibility,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (squadId != null) 'squad_id': squadId,
      };

      if (updates.isEmpty) {
        final current = await client
            .from('posts')
            .select(_postCols)
            .eq('id', postId)
            .single();
        return Post.fromJson(Map<String, dynamic>.from(current as Map));
      }

      final row = await client
          .from('posts')
          .update(updates)
          .eq('id', postId)
          .select(_postCols)
          .single();

      return Post.fromJson(Map<String, dynamic>.from(row as Map));
    });
  }
}
