import '../../../../utils/enums/social_enums.dart';

/// Domain entity for social posts.
///
/// This is the UI/domain representation built on top of the canonical
/// `public.posts` schema and joined profile data.
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  // Core content
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Aggregated stats
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  // Visibility & routing
  final PostVisibility visibility;
  // Game / location context (optional)
  final String? gameId;
  final String? cityName;
  // Per-user state
  final bool isLiked;
  final bool isBookmarked;
  // Author profile details
  final String? authorBio;
  final bool authorVerified;
  // Content metadata
  final List<String> tags;
  final List<String> mentionedUsers;
  // Editing state
  final bool isEdited;
  final DateTime? editedAt;
  // Conversation / sharing
  final String? replyToPostId;
  final String? shareOriginalId;
  // Activity-specific fields for unified activity feed
  final String? activityType;
  final Map<String, dynamic>? activityData;

  /// Post kind maps directly to `public.posts.kind` (e.g. 'moment', 'dab', 'kickin').
  final String kind;

  /// Primary vibe ID maps to `public.posts.primary_vibe_id` (nullable).
  final String? primaryVibeId;

  /// Vibe emoji for display (joined from vibes table)
  final String? vibeEmoji;

  /// Vibe label for display (joined from vibes table)
  final String? vibeLabel;

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
    this.cityName,
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
    this.kind = 'moment',
    this.primaryVibeId,
    this.vibeEmoji,
    this.vibeLabel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Enum for conversation types
enum ConversationType { direct, group, game, support }
