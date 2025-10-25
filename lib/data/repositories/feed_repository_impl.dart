import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../core/types/result.dart';
import '../../core/error/failure.dart';
import '../models/feed_item.dart';
import 'base_repository.dart';
import 'feed_repository.dart';

class FeedRepositoryImpl extends BaseRepository implements FeedRepository {
  final SupabaseService service;
  FeedRepositoryImpl(this.service) : super(service);

  SupabaseClient get client => service.client;

  static const _viewNames = ['vw_feed', 'feed_items'];
  static const _viewCols =
      'id,author_user_id,visibility,squad_id,content,media_url,created_at,author_display_name,author_avatar_url,like_count,comment_count';
  static const _postCols =
      'id,author_user_id,visibility,squad_id,content,media_url,created_at';

  @override
  Future<Result<List<FeedItem>>> getHomeFeed({
    String? cursor,
    int limit = 20,
  }) {
    return guard(() async {
      _assertSignedIn();

      final rows = await _tryViewThenPosts(
        build: (from, cols) {
          final query = client
              .from(from)
              .select(cols)
                ..order('created_at', ascending: false)
                ..order('id', ascending: false)
                ..limit(limit);
          _applyCursor(query, cursor);
          return query;
        },
      );

      return _mapRows(rows);
    });
  }

  @override
  Future<Result<List<FeedItem>>> getUserFeed(
    String userId, {
    String? cursor,
    int limit = 20,
  }) {
    return guard(() async {
      _assertSignedIn();

      final rows = await _tryViewThenPosts(
        build: (from, cols) {
          final query = client
              .from(from)
              .select(cols)
                ..eq('author_user_id', userId)
                ..order('created_at', ascending: false)
                ..order('id', ascending: false)
                ..limit(limit);
          _applyCursor(query, cursor);
          return query;
        },
      );

      return _mapRows(rows);
    });
  }

  @override
  Future<Result<List<FeedItem>>> getSquadFeed(
    String squadId, {
    String? cursor,
    int limit = 20,
  }) {
    return guard(() async {
      _assertSignedIn();

      final rows = await _tryViewThenPosts(
        build: (from, cols) {
          final query = client
              .from(from)
              .select(cols)
                ..eq('squad_id', squadId)
                ..order('created_at', ascending: false)
                ..order('id', ascending: false)
                ..limit(limit);
          _applyCursor(query, cursor);
          return query;
        },
      );

      return _mapRows(rows);
    });
  }

  @override
  String makeCursor(FeedItem item) {
    final ts = item.post.createdAt.toUtc().toIso8601String();
    return '$ts|${item.post.id}';
  }

  // ---------- helpers ----------

  void _assertSignedIn() {
    if (client.auth.currentUser?.id == null) {
      throw Failure.unauthorized(message: 'Not signed in');
    }
  }

  void _applyCursor(
    PostgrestFilterBuilder<Map<String, dynamic>> query,
    String? cursor,
  ) {
    if (cursor == null) return;
    final parts = cursor.split('|');
    if (parts.length != 2) return;

    final createdAt = DateTime.tryParse(parts[0])?.toUtc();
    final id = parts[1];

    if (createdAt != null) {
      query
        ..lte('created_at', createdAt.toIso8601String())
        ..neq('id', id);
    }
  }

  Future<List<dynamic>> _tryViewThenPosts({
    required PostgrestFilterBuilder<Map<String, dynamic>> Function(
            String from, String cols)
        build,
  }) async {
    for (final view in _viewNames) {
      try {
        final query = build(view, _viewCols);
        final rows = await query;
        return rows as List<dynamic>;
      } on PostgrestException catch (e) {
        if (_isRelationOrColumnMissing(e)) {
          continue;
        }
        rethrow;
      }
    }

    final fallbackQuery = build('posts', _postCols);
    final fallbackRows = await fallbackQuery;
    return fallbackRows as List<dynamic>;
  }

  bool _isRelationOrColumnMissing(PostgrestException e) {
    if (e.code == '42P01' || e.code == '42703') {
      return true;
    }
    final message = (e.message ?? '').toLowerCase();
    if (message.isEmpty) return false;
    if (message.contains('relation') && message.contains('does not exist')) {
      return true;
    }
    if (message.contains('column') && message.contains('does not exist')) {
      return true;
    }
    if (message.contains('pgrst') && message.contains('not found')) {
      return true;
    }
    return false;
  }

  List<FeedItem> _mapRows(List<dynamic> rows) {
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .map(FeedItem.fromJson)
        .toList(growable: false);
  }
}
