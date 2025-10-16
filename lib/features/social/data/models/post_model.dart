import '../../domain/entities/post.dart';
import '../../../../utils/enums/social_enums.dart';

/// Data model for social posts with JSON serialization
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.authorId,
    required super.authorName,
    required super.authorAvatar,
    required super.content,
    required super.mediaUrls,
    required super.createdAt,
    required super.updatedAt,
    required super.likesCount,
    required super.commentsCount,
    required super.sharesCount,
    required super.visibility,
    super.gameId,
    super.locationName,
    super.isLiked,
    super.isBookmarked,
    super.authorBio,
    super.authorVerified,
    super.tags,
    super.mentionedUsers,
    super.isEdited,
    super.editedAt,
    super.replyToPostId,
    super.shareOriginalId,
    super.activityType,
    super.activityData,
  });

  /// Create PostModel from Supabase JSON response
  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Parse author data from nested profiles table
    final authorData = json['profiles'] ?? json['author'] ?? {};
    
    // Parse media URLs - handle both string and array formats
    List<String> mediaUrls = [];
    if (json['media_urls'] != null) {
      if (json['media_urls'] is String) {
        // Single URL stored as string
        final urlString = json['media_urls'] as String;
        if (urlString.isNotEmpty) {
          mediaUrls = [urlString];
        }
      } else if (json['media_urls'] is List) {
        // Multiple URLs stored as array
        mediaUrls = (json['media_urls'] as List)
            .map((url) => url.toString())
            .where((url) => url.isNotEmpty)
            .toList();
      }
    }

    // Parse tags from string or array
    List<String> tags = [];
    if (json['tags'] != null) {
      if (json['tags'] is String) {
        // Tags stored as comma-separated string
        final tagString = json['tags'] as String;
        if (tagString.isNotEmpty) {
          tags = tagString.split(',').map((tag) => tag.trim()).toList();
        }
      } else if (json['tags'] is List) {
        // Tags stored as array
        tags = (json['tags'] as List)
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
      }
    }

    // Parse mentioned users
    List<String> mentionedUsers = [];
    if (json['mentioned_users'] != null && json['mentioned_users'] is List) {
      mentionedUsers = (json['mentioned_users'] as List)
          .map((userId) => userId.toString())
          .toList();
    }

    // Parse visibility enum
    PostVisibility visibility = PostVisibility.public;
    if (json['visibility'] != null) {
      switch (json['visibility'].toString().toLowerCase()) {
        case 'public':
          visibility = PostVisibility.public;
          break;
        case 'friends':
          visibility = PostVisibility.friends;
          break;
        case 'private':
          visibility = PostVisibility.private;
          break;
        case 'game_participants':
          visibility = PostVisibility.gameParticipants;
          break;
        default:
          visibility = PostVisibility.public;
      }
    }

    return PostModel(
      id: json['id'] ?? '',
      authorId: json['author_id'] ?? json['user_id'] ?? '',
      authorName: authorData['full_name'] ?? 
                  authorData['display_name'] ?? 
                  authorData['username'] ?? 
                  'Unknown User',
      authorAvatar: authorData['avatar_url'] ?? 
                    authorData['profile_picture'] ?? 
                    '',
      content: json['content'] ?? '',
      mediaUrls: mediaUrls,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      likesCount: _parseInt(json['likes_count'] ?? json['like_count'] ?? 0),
      commentsCount: _parseInt(json['comments_count'] ?? json['comment_count'] ?? 0),
      sharesCount: _parseInt(json['shares_count'] ?? json['share_count'] ?? 0),
      visibility: visibility,
      gameId: json['game_id'],
      locationName: json['location_name'],
      isLiked: json['is_liked'] == true || json['user_has_liked'] == true,
      isBookmarked: json['is_bookmarked'] == true || json['user_has_bookmarked'] == true,
      authorBio: authorData['bio'] ?? authorData['description'],
      authorVerified: authorData['verified'] == true || authorData['is_verified'] == true,
      tags: tags,
      mentionedUsers: mentionedUsers,
      isEdited: json['is_edited'] == true,
      editedAt: json['edited_at'] != null ? _parseDateTime(json['edited_at']) : null,
      replyToPostId: json['reply_to_post_id'],
      shareOriginalId: json['share_original_id'],
      activityType: json['activity_type'],
      activityData: json['activity_data'] != null 
          ? Map<String, dynamic>.from(json['activity_data']) 
          : null,
    );
  }

  /// Convert PostModel to JSON for API requests
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'author_id': authorId,
      'content': content,
      'media_urls': mediaUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'visibility': _visibilityToString(visibility),
    };

    // Add optional fields only if they have values
    if (gameId != null) json['game_id'] = gameId;
    if (locationName != null) json['location_name'] = locationName;
    if (tags.isNotEmpty) json['tags'] = tags;
    if (mentionedUsers.isNotEmpty) {
      json['mentioned_users'] = mentionedUsers;
    }
    if (isEdited == true) {
      json['is_edited'] = true;
      if (editedAt != null) {
        json['edited_at'] = editedAt!.toIso8601String();
      }
    }
    if (replyToPostId != null) json['reply_to_post_id'] = replyToPostId;
    if (shareOriginalId != null) json['share_original_id'] = shareOriginalId;
    if (activityType != null) json['activity_type'] = activityType;
    if (activityData != null) json['activity_data'] = activityData;

    return json;
  }

  /// Create JSON for creating a new post (excludes read-only fields)
  Map<String, dynamic> toCreateJson() {
    final json = <String, dynamic>{
      'author_id': authorId,
      'content': content,
      'visibility': _visibilityToString(visibility),
    };

    // Add optional fields
    if (mediaUrls.isNotEmpty) json['media_urls'] = mediaUrls;
    if (gameId != null) json['game_id'] = gameId;
    if (locationName != null) json['location_name'] = locationName;
    if (tags.isNotEmpty) json['tags'] = tags;
    if (mentionedUsers.isNotEmpty) {
      json['mentioned_users'] = mentionedUsers;
    }
    if (replyToPostId != null) json['reply_to_post_id'] = replyToPostId;
    if (shareOriginalId != null) json['share_original_id'] = shareOriginalId;
    if (activityType != null) json['activity_type'] = activityType;
    if (activityData != null) json['activity_data'] = activityData;

    return json;
  }

  /// Create JSON for updating a post (only editable fields)
  Map<String, dynamic> toUpdateJson() {
    final json = <String, dynamic>{
      'content': content,
      'visibility': _visibilityToString(visibility),
      'is_edited': true,
      'edited_at': DateTime.now().toIso8601String(),
    };

    // Add optional fields
    if (mediaUrls.isNotEmpty) json['media_urls'] = mediaUrls;
    if (locationName != null) json['location_name'] = locationName;
    if (tags.isNotEmpty) json['tags'] = tags;
    if (mentionedUsers.isNotEmpty) {
      json['mentioned_users'] = mentionedUsers;
    }

    return json;
  }

  /// Create a copy with updated fields
  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    List<String>? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    PostVisibility? visibility,
    String? gameId,
    String? locationName,
    bool? isLiked,
    bool? isBookmarked,
    String? authorBio,
    bool? authorVerified,
    List<String>? tags,
    List<String>? mentionedUsers,
    bool? isEdited,
    DateTime? editedAt,
    String? replyToPostId,
    String? shareOriginalId,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      visibility: visibility ?? this.visibility,
      gameId: gameId ?? this.gameId,
      locationName: locationName ?? this.locationName,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      authorBio: authorBio ?? this.authorBio,
      authorVerified: authorVerified ?? this.authorVerified,
      tags: tags ?? this.tags,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replyToPostId: replyToPostId ?? this.replyToPostId,
      shareOriginalId: shareOriginalId ?? this.shareOriginalId,
    );
  }

  // Helper methods for parsing
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.round();
    return 0;
  }

  static String _visibilityToString(PostVisibility visibility) {
    switch (visibility) {
      case PostVisibility.public:
        return 'public';
      case PostVisibility.friends:
        return 'friends';
      case PostVisibility.private:
        return 'private';
      case PostVisibility.gameParticipants:
        return 'game_participants';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PostModel{id: $id, authorName: $authorName, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}}';
  }
}

/// Post comment model for nested comment data
class PostCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final bool isLiked;
  final String? replyToCommentId;
  final List<PostCommentModel> replies;

  const PostCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.isLiked,
    this.replyToCommentId,
    this.replies = const [],
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    final authorData = json['profiles'] ?? json['author'] ?? {};

    // Parse replies if present
    List<PostCommentModel> replies = [];
    if (json['replies'] != null && json['replies'] is List) {
      replies = (json['replies'] as List)
          .map((reply) => PostCommentModel.fromJson(reply))
          .toList();
    }

    return PostCommentModel(
      id: json['id'] ?? '',
      postId: json['post_id'] ?? '',
      authorId: json['author_id'] ?? json['user_id'] ?? '',
      authorName: authorData['full_name'] ?? 
                  authorData['display_name'] ?? 
                  authorData['username'] ?? 
                  'Unknown User',
      authorAvatar: authorData['avatar_url'] ?? 
                    authorData['profile_picture'] ?? 
                    '',
      content: json['content'] ?? '',
      createdAt: PostModel._parseDateTime(json['created_at']),
      updatedAt: PostModel._parseDateTime(json['updated_at']),
      likesCount: PostModel._parseInt(json['likes_count'] ?? 0),
      isLiked: json['is_liked'] == true || json['user_has_liked'] == true,
      replyToCommentId: json['reply_to_comment_id'],
      replies: replies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'likes_count': likesCount,
      if (replyToCommentId != null) 'reply_to_comment_id': replyToCommentId,
    };
  }
}
