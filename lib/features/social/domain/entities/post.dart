import '../../../../utils/enums/social_enums.dart';

/// Domain entity for social posts
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final PostVisibility visibility;
  final String? gameId;
  final String? locationName;
  final bool isLiked;
  final bool isBookmarked;
  final String? authorBio;
  final bool authorVerified;
  final List<String> tags;
  final List<String> mentionedUsers;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToPostId;
  final String? shareOriginalId;
  // Activity-specific fields for unified activity feed
  final String? activityType;
  final Map<String, dynamic>? activityData;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.mediaUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.visibility,
    this.gameId,
    this.locationName,
    this.isLiked = false,
    this.isBookmarked = false,
    this.authorBio,
    this.authorVerified = false,
    this.tags = const [],
    this.mentionedUsers = const [],
    this.isEdited = false,
    this.editedAt,
    this.replyToPostId,
    this.shareOriginalId,
    this.activityType,
    this.activityData,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Enum for conversation types
enum ConversationType { direct, group, game, support }
