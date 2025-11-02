import '../../core/utils/json.dart';

/// Canonical client model for rows in `public.posts`.
/// Tolerant to minor schema drift: tries multiple keys when mapping.
class Post {
  final String id;
  final String authorUserId;
  final String visibility; // 'public' | 'circle' | 'hidden'
  final String? squadId;

  /// Optional content fields (your schema may have any subset)
  final String? body;       // text content
  final String? mediaUrl;   // single media pointer if present
  final Map<String, dynamic>? meta; // any extra JSON

  final DateTime createdAt;
  final DateTime? updatedAt;

  const Post({
    required this.id,
    required this.authorUserId,
    required this.visibility,
    required this.createdAt,
    this.updatedAt,
    this.squadId,
    this.body,
    this.mediaUrl,
    this.meta,
  });

  factory Post.fromMap(Map<String, dynamic> row) {
    final m = asMap(row);
    return Post(
      id: (m['id'] ?? '').toString(),
      authorUserId: (m['author_user_id'] ?? m['authorId'] ?? '').toString(),
      visibility: (m['visibility'] ?? 'public').toString(),
      squadId: m['squad_id']?.toString(),
      body: m['body']?.toString() ?? m['text']?.toString(),
      mediaUrl: m['media_url']?.toString() ?? m['image_url']?.toString(),
      meta: asMapOrNull(m['meta']) ?? asMapOrNull(m['extra']),
      createdAt: asDateTime(m['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: asDateTime(m['updated_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'visibility': visibility,
      if (squadId != null) 'squad_id': squadId,
      if (body != null) 'body': body,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (meta != null) 'meta': meta,
      // author_user_id is enforced server-side (auth.uid()) via RLS WITH CHECK
    };
  }

  Map<String, dynamic> toUpdate({
    String? newVisibility,
    String? newBody,
    String? newMediaUrl,
    String? newSquadId,
    Map<String, dynamic>? newMeta,
  }) {
    return {
      if (newVisibility != null) 'visibility': newVisibility,
      if (newSquadId != null) 'squad_id': newSquadId,
      if (newBody != null) 'body': newBody,
      if (newMediaUrl != null) 'media_url': newMediaUrl,
      if (newMeta != null) 'meta': newMeta,
    };
  }
}

