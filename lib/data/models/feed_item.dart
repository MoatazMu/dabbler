import 'post.dart';

class FeedItem {
  final Post post;

  // Optional enrichments if the view provides them (safe defaults if absent).
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final int likeCount;
  final int commentCount;

  const FeedItem({
    required this.post,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // View-first mapping: if the relation already names post columns at top-level,
    // we build Post directly from the same map.
    final post = Post.fromJson(json);

    return FeedItem(
      post: post,
      authorDisplayName: json['author_display_name'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        ...post.toJson(),
        'author_display_name': authorDisplayName,
        'author_avatar_url': authorAvatarUrl,
        'like_count': likeCount,
        'comment_count': commentCount,
      };
}
