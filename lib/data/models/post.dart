class Post {
  final String id;
  final String authorUserId;
  final String visibility;
  final String? squadId;
  final String? content;
  final String? mediaUrl;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.authorUserId,
    required this.visibility,
    required this.createdAt,
    this.squadId,
    this.content,
    this.mediaUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorUserId: json['author_user_id'] as String,
      visibility: json['visibility'] as String,
      squadId: json['squad_id'] as String?,
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_user_id': authorUserId,
        'visibility': visibility,
        'squad_id': squadId,
        'content': content,
        'media_url': mediaUrl,
        'created_at': createdAt.toIso8601String(),
      };
}
