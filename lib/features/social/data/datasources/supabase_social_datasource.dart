import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;

import 'friends_datasource.dart';
import 'posts_datasource.dart';
import 'chat_datasource.dart';
import '../models/friend_model.dart';
import '../models/post_model.dart';
import '../models/social_feed_model.dart';
import '../models/reaction_model.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/post.dart';
// Import the missing enums from the correct sources
import '../../../../utils/enums/social_enums.dart' show PostVisibility, ReactionType, MessageType;
import '../../domain/entities/post.dart' show ConversationType;

// Missing exception classes
class RateLimitException implements Exception {
  final String message;
  final int retryAfterSeconds;
  
  const RateLimitException({
    required this.message,
    required this.retryAfterSeconds,
  });
  
  @override
  String toString() => 'RateLimitException: $message';
}

class DataNotFoundException implements Exception {
  final String message;
  
  const DataNotFoundException({required this.message});
  
  @override
  String toString() => 'DataNotFoundException: $message';
}

class ConversationNotExistsException implements Exception {
  final String message;
  
  const ConversationNotExistsException({required this.message});
  
  @override
  String toString() => 'ConversationNotExistsException: $message';
}

class UserAccessException implements Exception {
  final String message;
  
  const UserAccessException({required this.message});
  
  @override
  String toString() => 'UserAccessException: $message';
}

class RateLimitExceededException implements Exception {
  final String message;
  
  const RateLimitExceededException({required this.message});
  
  @override
  String toString() => 'RateLimitExceededException: $message';
}

class DuplicatePostException implements Exception {
  final String message;
  
  const DuplicatePostException({required this.message});
  
  @override
  String toString() => 'DuplicatePostException: $message';
}

class DuplicateChatMessageException implements Exception {
  final String message;
  
  const DuplicateChatMessageException({required this.message});
  
  @override
  String toString() => 'DuplicateChatMessageException: $message';
}

class UserNotFoundException implements Exception {
  final String message;
  
  const UserNotFoundException({required this.message});
  
  @override
  String toString() => 'UserNotFoundException: $message';
}

class SocialDataException implements Exception {
  final String message;
  
  const SocialDataException({required this.message});
  
  @override
  String toString() => 'SocialDataException: $message';
}

class PostMediaUploadException implements Exception {
  final String message;
  
  const PostMediaUploadException({required this.message});
  
  @override
  String toString() => 'PostMediaUploadException: $message';
}

/// Comprehensive Supabase implementation for all social operations
class SupabaseSocialDataSource implements FriendsDataSource, PostsDataSource, ChatDataSource {
  // ignore: unused_field
  final SupabaseClient _client;

  SupabaseSocialDataSource(this._client);

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  // =============================================================================
  // FRIENDS DATA SOURCE IMPLEMENTATION
  // =============================================================================

  @override
  Future<List<FriendModel>> getFriends({
    required String userId,
    FriendshipStatus? status,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    List<String>? gameIds,
    bool includeProfile = true,
  }) async {
    throw UnimplementedError('getFriends not implemented');
  }

  @override
  Future<List<FriendModel>> getFriendRequests({
    required String userId,
    bool sentRequests = false,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getFriendRequests not implemented');
  }

  @override
  Future<FriendModel> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
    String? message,
  }) async {
    throw UnimplementedError('sendFriendRequest not implemented');
  }

  @override
  Future<FriendModel> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    throw UnimplementedError('acceptFriendRequest not implemented');
  }

  @override
  Future<bool> declineFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    throw UnimplementedError('declineFriendRequest not implemented');
  }

  @override
  Future<bool> cancelFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    throw UnimplementedError('cancelFriendRequest not implemented');
  }

  @override
  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    throw UnimplementedError('removeFriend not implemented');
  }

  @override
  Future<bool> blockUser({
    required String userId,
    required String targetUserId,
    String? reason,
  }) async {
    throw UnimplementedError('blockUser not implemented');
  }

  @override
  Future<bool> unblockUser({
    required String userId,
    required String targetUserId,
  }) async {
    throw UnimplementedError('unblockUser not implemented');
  }

  @override
  Future<List<String>> getBlockedUsers({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getBlockedUsers not implemented');
  }

  @override
  Future<bool> isUserBlocked({
    required String userId,
    required String targetUserId,
  }) async {
    throw UnimplementedError('isUserBlocked not implemented');
  }

  @override
  Future<FriendshipStatus> getFriendshipStatus({
    required String userId,
    required String otherUserId,
  }) async {
    throw UnimplementedError('getFriendshipStatus not implemented');
  }

  @override
  Future<int> getFriendsCount({
    required String userId,
    FriendshipStatus? status,
  }) async {
    throw UnimplementedError('getFriendsCount not implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentFriendsActivity({
    required String userId,
    int limit = 10,
    Duration? timeRange,
  }) async {
    throw UnimplementedError('getRecentFriendsActivity not implemented');
  }

  @override
  Future<List<bool>> blockMultipleUsers({
    required String userId,
    required List<String> targetUserIds,
    String? reason,
  }) async {
    throw UnimplementedError('blockMultipleUsers not implemented');
  }

  @override
  Future<List<bool>> unblockMultipleUsers({
    required String userId,
    required List<String> targetUserIds,
  }) async {
    throw UnimplementedError('unblockMultipleUsers not implemented');
  }

  @override
  Future<Map<String, dynamic>> exportFriendsData({
    required String userId,
  }) async {
    throw UnimplementedError('exportFriendsData not implemented');
  }

  @override
  Future<List<FriendModel>> getFriendSuggestions({
    required String userId,
    int limit = 10,
    List<String>? excludeUserIds,
    Map<String, dynamic>? filters,
  }) async {
    throw UnimplementedError('getFriendSuggestions not implemented');
  }

  @override
  Future<List<FriendModel>> getMutualFriends({
    required String userId,
    required String otherUserId,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getMutualFriends not implemented');
  }

  @override
  Future<List<FriendModel>> searchUsers({
    required String query,
    required String currentUserId,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    throw UnimplementedError('searchUsers not implemented');
  }

  @override
  Future<List<FriendModel>> getFriendRecommendations({
    required String userId,
    int limit = 10,
    String? gameContext,
  }) async {
    throw UnimplementedError('getFriendRecommendations not implemented');
  }

  @override
  Future<bool> updateFriendPreferences({
    required String userId,
    required String friendId,
    required Map<String, dynamic> preferences,
  }) async {
    throw UnimplementedError('updateFriendPreferences not implemented');
  }

  @override
  Future<Map<String, dynamic>> getFriendPreferences({
    required String userId,
    required String friendId,
  }) async {
    throw UnimplementedError('getFriendPreferences not implemented');
  }

  @override
  Future<bool> canSendFriendRequest({
    required String userId,
    required String targetUserId,
  }) async {
    throw UnimplementedError('canSendFriendRequest not implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getFriendRequestHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getFriendRequestHistory not implemented');
  }

  // Real-time subscriptions for friends
  @override
  Stream<FriendModel> subscribeFriendRequests(String userId) {
    throw UnimplementedError('subscribeFriendRequests not implemented');
  }

  @override
  Stream<FriendModel> subscribeFriendsUpdates(String userId) {
    throw UnimplementedError('subscribeFriendsUpdates not implemented');
  }

  @override
  Stream<List<String>> subscribeBlockedUsersUpdates(String userId) {
    throw UnimplementedError('subscribeBlockedUsersUpdates not implemented');
  }

  // =============================================================================
  // POSTS DATA SOURCE IMPLEMENTATION
  // =============================================================================

  @override
  Future<PostModel> createPost({
    required String authorId,
    required String content,
    List<File>? mediaFiles,
    PostVisibility visibility = PostVisibility.public,
    String? gameId,
    String? locationName,
    List<String>? tags,
    List<String>? mentionedUsers,
    String? replyToPostId,
    String? shareOriginalId,
  }) async {
    throw UnimplementedError('createPost not implemented');
  }

  @override
  Future<List<String>> uploadMedia({
    required List<File> files,
    required String userId,
    String? postId,
    Function(double)? onProgress,
  }) async {
    throw UnimplementedError('uploadMedia not implemented');
  }

  @override
  Future<SocialFeedModel> getSocialFeed({
    required String userId,
    FeedType feedType = FeedType.home,
    String? gameId,
    String? authorId,
    PostVisibility? visibility,
    int page = 1,
    int limit = 20,
    SortField sortBy = SortField.createdAt,
    SortDirection sortDirection = SortDirection.desc,
    Duration? maxAge,
    List<String>? excludePostIds,
  }) async {
    throw UnimplementedError('getSocialFeed not implemented');
  }

  @override
  Future<PostModel> getPost({
    required String postId,
    required String viewerId,
    bool incrementViewCount = true,
  }) async {
    throw UnimplementedError('getPost not implemented');
  }

  @override
  Future<PostModel> updatePost({
    required String postId,
    required String userId,
    String? content,
    List<File>? newMediaFiles,
    List<String>? removeMediaUrls,
    PostVisibility? visibility,
    List<String>? tags,
    List<String>? mentionedUsers,
  }) async {
    throw UnimplementedError('updatePost not implemented');
  }

  @override
  Future<bool> deletePost({
    required String postId,
    required String userId,
    bool deleteMedia = true,
  }) async {
    throw UnimplementedError('deletePost not implemented');
  }

  @override
  Future<List<PostModel>> getUserPosts({
    required String userId,
    required String viewerId,
    int page = 1,
    int limit = 20,
    PostVisibility? visibility,
    bool includeReplies = false,
    bool includeShares = true,
  }) async {
    throw UnimplementedError('getUserPosts not implemented');
  }

  @override
  Future<List<PostModel>> getGamePosts({
    required String gameId,
    required String viewerId,
    int page = 1,
    int limit = 20,
    PostVisibility? maxVisibility,
  }) async {
    throw UnimplementedError('getGamePosts not implemented');
  }

  @override
  Future<List<PostModel>> searchPosts({
    required String query,
    required String viewerId,
    int page = 1,
    int limit = 20,
    PostVisibility? visibility,
    String? gameId,
    List<String>? tags,
    String? authorId,
    DateTime? fromDate,
    DateTime? toDate,
    bool includeComments = false,
  }) async {
    throw UnimplementedError('searchPosts not implemented');
  }

  @override
  Future<ReactionModel> reactToPost({
    required String postId,
    required String userId,
    required ReactionType reactionType,
  }) async {
    throw UnimplementedError('reactToPost not implemented');
  }

  @override
  Future<bool> removeReactionFromPost({
    required String postId,
    required String userId,
  }) async {
    throw UnimplementedError('removeReactionFromPost not implemented');
  }

  @override
  Future<List<ReactionModel>> getPostReactions({
    required String postId,
    ReactionType? reactionType,
    int page = 1,
    int limit = 50,
  }) async {
    throw UnimplementedError('getPostReactions not implemented');
  }

  @override
  Future<List<GroupedReaction>> getGroupedPostReactions(String postId) async {
    throw UnimplementedError('getGroupedPostReactions not implemented');
  }

  @override
  Future<PostModel> commentOnPost({
    required String postId,
    required String userId,
    required String content,
    List<File>? mediaFiles,
    List<String>? mentionedUsers,
  }) async {
    throw UnimplementedError('commentOnPost not implemented');
  }

  @override
  Future<List<PostModel>> getPostComments({
    required String postId,
    required String viewerId,
    int page = 1,
    int limit = 20,
    SortDirection sortDirection = SortDirection.asc,
    bool includeReplies = true,
  }) async {
    throw UnimplementedError('getPostComments not implemented');
  }

  @override
  Future<ReactionModel> reactToComment({
    required String commentId,
    required String userId,
    required ReactionType reactionType,
  }) async {
    throw UnimplementedError('reactToComment not implemented');
  }

  @override
  Future<bool> removeReactionFromComment({
    required String commentId,
    required String userId,
  }) async {
    throw UnimplementedError('removeReactionFromComment not implemented');
  }

  @override
  Future<PostModel> sharePost({
    required String originalPostId,
    required String userId,
    String? content,
    PostVisibility visibility = PostVisibility.public,
  }) async {
    throw UnimplementedError('sharePost not implemented');
  }

  @override
  Future<bool> bookmarkPost({
    required String postId,
    required String userId,
  }) async {
    throw UnimplementedError('bookmarkPost not implemented');
  }

  @override
  Future<bool> removeBookmark({
    required String postId,
    required String userId,
  }) async {
    throw UnimplementedError('removeBookmark not implemented');
  }

  @override
  Future<List<PostModel>> getBookmarkedPosts({
    required String userId,
    int page = 1,
    int limit = 20,
    String? gameId,
  }) async {
    throw UnimplementedError('getBookmarkedPosts not implemented');
  }

  @override
  Future<bool> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
    String? details,
    List<String>? evidenceUrls,
  }) async {
    throw UnimplementedError('reportPost not implemented');
  }

  @override
  Future<bool> reportComment({
    required String commentId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    throw UnimplementedError('reportComment not implemented');
  }

  @override
  Future<List<PostModel>> getTrendingPosts({
    required String viewerId,
    Duration timeframe = const Duration(days: 7),
    int page = 1,
    int limit = 20,
    String? gameId,
    PostVisibility? maxVisibility,
  }) async {
    throw UnimplementedError('getTrendingPosts not implemented');
  }

  @override
  Future<List<PostModel>> getPostsByTags({
    required List<String> tags,
    required String viewerId,
    int page = 1,
    int limit = 20,
    PostVisibility? visibility,
    String? gameId,
  }) async {
    throw UnimplementedError('getPostsByTags not implemented');
  }

  @override
  Future<List<PostModel>> getPostsMentioningUser({
    required String userId,
    required String viewerId,
    int page = 1,
    int limit = 20,
    bool includeComments = true,
  }) async {
    throw UnimplementedError('getPostsMentioningUser not implemented');
  }

  @override
  Future<Map<String, dynamic>> getPostAnalytics({
    required String postId,
    required String authorId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    throw UnimplementedError('getPostAnalytics not implemented');
  }

  @override
  Future<List<PostModel>> getMultiplePosts({
    required List<String> postIds,
    required String viewerId,
  }) async {
    throw UnimplementedError('getMultiplePosts not implemented');
  }

  @override
  Future<List<bool>> bookmarkMultiplePosts({
    required List<String> postIds,
    required String userId,
  }) async {
    throw UnimplementedError('bookmarkMultiplePosts not implemented');
  }

  @override
  Future<List<bool>> removeMultipleBookmarks({
    required List<String> postIds,
    required String userId,
  }) async {
    throw UnimplementedError('removeMultipleBookmarks not implemented');
  }

  @override
  Future<bool> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    throw UnimplementedError('deleteComment not implemented');
  }

  @override
  Future<PostModel> updateComment({
    required String commentId,
    required String userId,
    required String content,
    List<File>? newMediaFiles,
    List<String>? removeMediaUrls,
    List<String>? mentionedUsers,
  }) async {
    throw UnimplementedError('updateComment not implemented');
  }

  @override
  Future<bool> canUserViewPost({
    required String postId,
    required String viewerId,
  }) async {
    throw UnimplementedError('canUserViewPost not implemented');
  }

  @override
  Future<List<PostModel>> filterPostsByVisibility({
    required List<PostModel> posts,
    required String viewerId,
  }) async {
    throw UnimplementedError('filterPostsByVisibility not implemented');
  }

  @override
  Future<Map<String, dynamic>> getFeedPreferences(String userId) async {
    throw UnimplementedError('getFeedPreferences not implemented');
  }

  @override
  Future<bool> updateFeedPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    throw UnimplementedError('updateFeedPreferences not implemented');
  }

  @override
  Future<Map<String, dynamic>> getPostEngagement({
    required String postId,
    Duration? timeframe,
  }) async {
    throw UnimplementedError('getPostEngagement not implemented');
  }

  @override
  Future<bool> pinPost({
    required String postId,
    required String userId,
  }) async {
    throw UnimplementedError('pinPost not implemented');
  }

  @override
  Future<bool> unpinPost({
    required String postId,
    required String userId,
  }) async {
    throw UnimplementedError('unpinPost not implemented');
  }

  @override
  Future<List<PostModel>> getPinnedPosts({
    required String userId,
    required String viewerId,
  }) async {
    throw UnimplementedError('getPinnedPosts not implemented');
  }

  @override
  Future<bool> archivePost({
    required String postId,
    required String userId,
  }) async {
    throw UnimplementedError('archivePost not implemented');
  }

  @override
  Future<bool> unarchivePost({
    required String postId,
    required String userId,
  }) async {
    throw UnimplementedError('unarchivePost not implemented');
  }

  @override
  Future<List<PostModel>> getArchivedPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getArchivedPosts not implemented');
  }

  // Real-time subscriptions for posts
  @override
  Stream<PostModel> subscribeToFeedUpdates(String userId) {
    throw UnimplementedError('subscribeToFeedUpdates not implemented');
  }

  @override
  Stream<PostModel> subscribeToPostComments(String postId) {
    throw UnimplementedError('subscribeToPostComments not implemented');
  }

  @override
  Stream<ReactionModel> subscribeToPostReactions(String postId) {
    throw UnimplementedError('subscribeToPostReactions not implemented');
  }

  @override
  Stream<PostModel> subscribeToUserPosts(String userId) {
    throw UnimplementedError('subscribeToUserPosts not implemented');
  }

  // =============================================================================
  // CHAT DATA SOURCE IMPLEMENTATION
  // =============================================================================

  @override
  Future<ConversationModel> createConversation({
    required String creatorId,
    required String title,
    required List<String> participantIds,
    ConversationType type = ConversationType.group,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? settings,
  }) async {
    throw UnimplementedError('createConversation not implemented');
  }

  @override
  Future<List<ConversationModel>> getConversations({
    required String userId,
    int page = 1,
    int limit = 20,
    ConversationType? type,
    bool includeArchived = false,
    String? searchQuery,
  }) async {
    throw UnimplementedError('getConversations not implemented');
  }

  @override
  Future<ConversationModel> getConversation({
    required String conversationId,
    required String userId,
    bool includeParticipants = true,
  }) async {
    throw UnimplementedError('getConversation not implemented');
  }

  @override
  Future<ConversationModel> updateConversation({
    required String conversationId,
    required String userId,
    String? title,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? settings,
  }) async {
    throw UnimplementedError('updateConversation not implemented');
  }

  @override
  Future<bool> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('deleteConversation not implemented');
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    List<File>? mediaFiles,
    List<String>? mentionedUsers,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    int maxRetries = 3,
  }) async {
    try {
      // Upload media files first if any
      List<String> mediaUrls = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        mediaUrls = await uploadMessageMedia(
          files: mediaFiles,
          userId: senderId,
          conversationId: conversationId,
        );
      }

      // Create message data
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'message_type': type.name,
        'media_urls': mediaUrls,
        'mentioned_users': mentionedUsers ?? [],
        'reply_to_message_id': replyToMessageId,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert message into database
      final response = await _client
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      // Update conversation last message
      await _client
          .from('conversations')
          .update({
            'last_message_id': response['id'],
            'last_message_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      return ChatMessageModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('rate limit')) {
        throw RateLimitException(
          message: 'Rate limit exceeded. Please try again later.',
          retryAfterSeconds: 60,
        );
      }
      throw ChatDataSourceException(
        message: 'Failed to send message: ${e.toString()}',
        code: 'MESSAGE_SEND_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<ChatMessageModel> sendMessageWithMedia({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    List<String>? mediaUrls,
    List<String>? mentionedUsers,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'message_type': type.name,
        'media_urls': mediaUrls ?? [],
        'mentioned_users': mentionedUsers ?? [],
        'reply_to_message_id': replyToMessageId,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      // Update conversation
      await _client
          .from('conversations')
          .update({
            'last_message_id': response['id'],
            'last_message_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      return ChatMessageModel.fromJson(response);
    } catch (e) {
      throw ChatDataSourceException(
        message: 'Failed to send message with media: ${e.toString()}',
        code: 'MEDIA_MESSAGE_SEND_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<List<String>> uploadMessageMedia({
    required List<File> files,
    required String userId,
    String? conversationId,
    Function(double)? onProgress,
  }) async {
    try {
      final List<String> uploadedUrls = [];
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final filePath = 'chat_media/$userId/$fileName';
        
        // Upload file to Supabase Storage
        await _client.storage
            .from('chat_media')
            .upload(filePath, file);
        
        // Get public URL
        final publicUrl = _client.storage
            .from('chat_media')
            .getPublicUrl(filePath);
        
        uploadedUrls.add(publicUrl);
        
        // Report progress
        if (onProgress != null) {
          onProgress((i + 1) / files.length);
        }
      }
      
      return uploadedUrls;
    } catch (e) {
      throw ChatMediaUploadException(
        message: 'Failed to upload media: ${e.toString()}',
        code: 'MEDIA_UPLOAD_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages({
    required String conversationId,
    required String userId,
    int page = 1,
    int limit = 50,
    String? beforeMessageId,
    String? afterMessageId,
    DateTime? fromDate,
    DateTime? toDate,
    MessageType? messageType,
  }) async {
    try {
      // Verify user has access to conversation
      await getConversation(
        conversationId: conversationId,
        userId: userId,
      );

    // Build base filter query first (apply all filters), then apply transforms (order/range)
    var query = _client
      .from('chat_messages')
      .select('*, profiles!chat_messages_sender_id_fkey(*)')
      .eq('conversation_id', conversationId);

      if (beforeMessageId != null) {
        final beforeMessage = await _client
            .from('chat_messages')
            .select('created_at')
            .eq('id', beforeMessageId)
            .single();
  query = query.lt('created_at', beforeMessage['created_at']);
      }

      if (afterMessageId != null) {
        final afterMessage = await _client
            .from('chat_messages')
            .select('created_at')
            .eq('id', afterMessageId)
            .single();
  query = query.gt('created_at', afterMessage['created_at']);
      }

      if (fromDate != null) {
  query = query.gte('created_at', fromDate.toIso8601String());
      }

      if (toDate != null) {
  query = query.lte('created_at', toDate.toIso8601String());
      }

      if (messageType != null) {
        query = query.eq('message_type', messageType.name);
      }
      // Apply transforms after all filters are set
      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);
      return response
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e is ChatDataSourceException) rethrow;
      throw ChatDataSourceException(
        message: 'Failed to get messages: ${e.toString()}',
        code: 'GET_MESSAGES_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<ChatMessageModel> getMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select('*, profiles!chat_messages_sender_id_fkey(*)')
          .eq('id', messageId)
          .single();

      // Check if user has access to this message (throws if not allowed)
      await getConversation(
        conversationId: response['conversation_id'],
        userId: userId,
      );

      return ChatMessageModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        throw MessageNotFoundException(
          message: 'Message not found',
          code: 'MESSAGE_NOT_FOUND',
        );
      }
      throw ChatDataSourceException(
        message: 'Failed to get message: ${e.toString()}',
        code: 'GET_MESSAGE_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<ChatMessageModel> updateMessage({
    required String messageId,
    required String userId,
    required String content,
    List<File>? newMediaFiles,
    List<String>? removeMediaUrls,
    List<String>? mentionedUsers,
  }) async {
    try {
      // Get current message
      final currentMessage = await getMessage(
        messageId: messageId,
        userId: userId,
      );

      // Check if user is the sender
      if (currentMessage.senderId != userId) {
        throw ConversationAccessException(
          message: 'Only message sender can edit message',
          code: 'MESSAGE_EDIT_DENIED',
        );
      }

      // Handle media updates
  // Adapt to model: transform attachments to URL list for storage write
  List<String> mediaUrls = currentMessage.mediaAttachments.map((a) => a.url).toList();
      if (removeMediaUrls != null) {
        mediaUrls.removeWhere((url) => removeMediaUrls.contains(url));
      }
      
      if (newMediaFiles != null && newMediaFiles.isNotEmpty) {
        final newUrls = await uploadMessageMedia(
          files: newMediaFiles,
          userId: userId,
        );
        mediaUrls.addAll(newUrls);
      }

      // Update message
      final updateData = {
        'content': content,
        'media_urls': mediaUrls,
  // Store mentioned users in metadata to align with model
  'mentioned_users': mentionedUsers ?? (currentMessage.metadata?['mentioned_users'] as List<String>?) ?? [],
        'is_edited': true,
        'edited_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('chat_messages')
          .update(updateData)
          .eq('id', messageId)
          .select()
          .single();

      return ChatMessageModel.fromJson(response);
    } catch (e) {
      if (e is ChatDataSourceException) rethrow;
      throw ChatDataSourceException(
        message: 'Failed to update message: ${e.toString()}',
        code: 'UPDATE_MESSAGE_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<bool> deleteMessage({
    required String messageId,
    required String userId,
    bool deleteForEveryone = false,
  }) async {
    try {
      final message = await getMessage(
        messageId: messageId,
        userId: userId,
      );

      // Check permissions
      if (message.senderId != userId && !deleteForEveryone) {
        throw ConversationAccessException(
          message: 'Cannot delete message from other user',
          code: 'MESSAGE_DELETE_DENIED',
        );
      }

      if (deleteForEveryone) {
        // Soft delete for everyone
        await _client
            .from('chat_messages')
            .update({
              'is_deleted': true,
              'deleted_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', messageId);
      } else {
        // Hard delete for sender only
        await _client
            .from('chat_messages')
            .delete()
            .eq('id', messageId);
      }

      return true;
    } catch (e) {
      if (e is ChatDataSourceException) rethrow;
      throw ChatDataSourceException(
        message: 'Failed to delete message: ${e.toString()}',
        code: 'DELETE_MESSAGE_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<bool> markAsRead({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    try {
      // Verify user has access to conversation (throws if not allowed)
      await getConversation(
        conversationId: conversationId,
        userId: userId,
      );

      // Mark message as read
      await _client
          .from('chat_message_reads')
          .upsert({
            'message_id': messageId,
            'user_id': userId,
            'read_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      if (e is ChatDataSourceException) rethrow;
      throw ChatDataSourceException(
        message: 'Failed to mark message as read: ${e.toString()}',
        code: 'MARK_READ_ERROR',
        details: e,
      );
    }
  }

  @override
  Future<bool> markAllAsRead({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('markAllAsRead not implemented');
  }

  @override
  Future<bool> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    throw UnimplementedError('setTyping not implemented');
  }

  @override
  Future<List<String>> getTypingUsers({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('getTypingUsers not implemented');
  }

  @override
  Future<List<ChatMessageModel>> searchMessages({
    required String query,
    required String userId,
    String? conversationId,
    MessageType? messageType,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
    bool includeContent = true,
  }) async {
    throw UnimplementedError('searchMessages not implemented');
  }

  @override
  Future<List<ChatMessageModel>> searchMessagesAdvanced({
    required String userId,
    String? textQuery,
    List<String>? conversationIds,
    List<String>? senderIds,
    List<MessageType>? messageTypes,
    Map<String, dynamic>? metadataFilters,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('searchMessagesAdvanced not implemented');
  }

  @override
  Future<bool> addParticipant({
    required String conversationId,
    required String userId,
    required String newParticipantId,
  }) async {
    throw UnimplementedError('addParticipant not implemented');
  }

  @override
  Future<bool> removeParticipant({
    required String conversationId,
    required String userId,
    required String participantId,
  }) async {
    throw UnimplementedError('removeParticipant not implemented');
  }

  @override
  Future<bool> leaveConversation({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('leaveConversation not implemented');
  }

  @override
  Future<List<String>> getConversationParticipants({
    required String conversationId,
    required String userId,
    bool includeDetails = false,
  }) async {
    throw UnimplementedError('getConversationParticipants not implemented');
  }

  @override
  Future<bool> updateParticipantRole({
    required String conversationId,
    required String userId,
    required String participantId,
    required String role,
  }) async {
    throw UnimplementedError('updateParticipantRole not implemented');
  }

  @override
  Future<Map<String, int>> getUnreadCounts({
    required String userId,
    List<String>? conversationIds,
  }) async {
    throw UnimplementedError('getUnreadCounts not implemented');
  }

  @override
  Future<int> getTotalUnreadCount({
    required String userId,
  }) async {
    throw UnimplementedError('getTotalUnreadCount not implemented');
  }

  @override
  Future<bool> muteConversation({
    required String conversationId,
    required String userId,
    DateTime? muteUntil,
  }) async {
    throw UnimplementedError('muteConversation not implemented');
  }

  @override
  Future<bool> unmuteConversation({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('unmuteConversation not implemented');
  }

  @override
  Future<bool> archiveConversation({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('archiveConversation not implemented');
  }

  @override
  Future<bool> unarchiveConversation({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('unarchiveConversation not implemented');
  }

  @override
  Future<bool> pinConversation({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('pinConversation not implemented');
  }

  @override
  Future<bool> unpinConversation({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('unpinConversation not implemented');
  }

  @override
  Future<Map<String, bool>> getMessageDeliveryStatus({
    required List<String> messageIds,
    required String userId,
  }) async {
    throw UnimplementedError('getMessageDeliveryStatus not implemented');
  }

  @override
  Future<Map<String, dynamic>> getConversationSettings({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('getConversationSettings not implemented');
  }

  @override
  Future<bool> updateConversationSettings({
    required String conversationId,
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    throw UnimplementedError('updateConversationSettings not implemented');
  }

  @override
  Future<bool> blockUserInChat({
    required String userId,
    required String targetUserId,
  }) async {
    throw UnimplementedError('blockUserInChat not implemented');
  }

  @override
  Future<bool> unblockUserInChat({
    required String userId,
    required String targetUserId,
  }) async {
    throw UnimplementedError('unblockUserInChat not implemented');
  }

  @override
  Future<List<String>> getBlockedUsersInChat({
    required String userId,
  }) async {
    throw UnimplementedError('getBlockedUsersInChat not implemented');
  }

  @override
  Future<bool> reportMessage({
    required String messageId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    throw UnimplementedError('reportMessage not implemented');
  }

  @override
  Future<bool> reportConversation({
    required String conversationId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    throw UnimplementedError('reportConversation not implemented');
  }

  @override
  Future<Map<String, dynamic>> getConversationAnalytics({
    required String conversationId,
    required String userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    throw UnimplementedError('getConversationAnalytics not implemented');
  }

  @override
  Future<Map<String, dynamic>> exportConversationData({
    required String conversationId,
    required String userId,
    DateTime? fromDate,
    DateTime? toDate,
    List<MessageType>? messageTypes,
  }) async {
    throw UnimplementedError('exportConversationData not implemented');
  }

  @override
  Future<List<ChatMessageModel>> getConversationMedia({
    required String conversationId,
    required String userId,
    MessageType? mediaType,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getConversationMedia not implemented');
  }

  @override
  Future<List<ChatMessageModel>> getSharedFiles({
    required String conversationId,
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getSharedFiles not implemented');
  }

  @override
  Future<List<ChatMessageModel>> getConversationLinks({
    required String conversationId,
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getConversationLinks not implemented');
  }

  @override
  Future<bool> pinMessage({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    throw UnimplementedError('pinMessage not implemented');
  }

  @override
  Future<bool> unpinMessage({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    throw UnimplementedError('unpinMessage not implemented');
  }

  @override
  Future<List<ChatMessageModel>> getPinnedMessages({
    required String conversationId,
    required String userId,
  }) async {
    throw UnimplementedError('getPinnedMessages not implemented');
  }

  @override
  Future<bool> reactToMessage({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    throw UnimplementedError('reactToMessage not implemented');
  }

  @override
  Future<bool> removeReactionFromMessage({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    throw UnimplementedError('removeReactionFromMessage not implemented');
  }

  @override
  Future<Map<String, List<String>>> getMessageReactions({
    required String messageId,
    required String userId,
  }) async {
    throw UnimplementedError('getMessageReactions not implemented');
  }

  @override
  Future<List<ChatMessageModel>> forwardMessages({
    required List<String> messageIds,
    required List<String> conversationIds,
    required String userId,
    String? additionalContent,
  }) async {
    throw UnimplementedError('forwardMessages not implemented');
  }

  @override
  Future<ChatMessageModel> scheduleMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required DateTime scheduledTime,
    MessageType type = MessageType.text,
    List<String>? mediaUrls,
    List<String>? mentionedUsers,
  }) async {
    throw UnimplementedError('scheduleMessage not implemented');
  }

  @override
  Future<List<ChatMessageModel>> getScheduledMessages({
    required String userId,
    String? conversationId,
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError('getScheduledMessages not implemented');
  }

  @override
  Future<bool> cancelScheduledMessage({
    required String messageId,
    required String userId,
  }) async {
    throw UnimplementedError('cancelScheduledMessage not implemented');
  }

  @override
  Future<String> getConversationInviteLink({
    required String conversationId,
    required String userId,
    DateTime? expiresAt,
    int? maxUses,
  }) async {
    throw UnimplementedError('getConversationInviteLink not implemented');
  }

  @override
  Future<ConversationModel> joinConversationByInvite({
    required String inviteCode,
    required String userId,
  }) async {
    throw UnimplementedError('joinConversationByInvite not implemented');
  }

  @override
  Future<bool> revokeConversationInvite({
    required String conversationId,
    required String userId,
    String? inviteCode,
  }) async {
    throw UnimplementedError('revokeConversationInvite not implemented');
  }

  @override
  Future<Map<String, dynamic>> getConversationInviteInfo({
    required String inviteCode,
  }) async {
    throw UnimplementedError('getConversationInviteInfo not implemented');
  }

  @override
  Future<List<bool>> markMultipleAsRead({
    required List<String> messageIds,
    required String userId,
  }) async {
    throw UnimplementedError('markMultipleAsRead not implemented');
  }

  @override
  Future<List<bool>> deleteMultipleMessages({
    required List<String> messageIds,
    required String userId,
    bool deleteForEveryone = false,
  }) async {
    throw UnimplementedError('deleteMultipleMessages not implemented');
  }

  @override
  Stream<ChatMessageModel> subscribeToMessages(String conversationId) {
    throw UnimplementedError('subscribeToMessages not implemented');
  }

  @override
  Stream<ConversationModel> subscribeToConversations(String userId) {
    throw UnimplementedError('subscribeToConversations not implemented');
  }

  @override
  Stream<Map<String, bool>> subscribeToTyping(String conversationId) {
    throw UnimplementedError('subscribeToTyping not implemented');
  }

  @override
  Stream<Map<String, DateTime>> subscribeToReadReceipts(String conversationId) {
    throw UnimplementedError('subscribeToReadReceipts not implemented');
  }

  @override
  Stream<Map<String, int>> subscribeToUnreadCounts(String userId) {
    throw UnimplementedError('subscribeToUnreadCounts not implemented');
  }
}

