import 'dart:async';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/chat_message.dart';

import '../../domain/repositories/social_repository.dart';
import '../../domain/repositories/friends_repository.dart';
import '../../domain/repositories/posts_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../utils/enums/social_enums.dart' show PostVisibility;

/// Network information interface for checking connectivity
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Simple network info implementation
class SimpleNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true; // Always true for now
}

/// Unified social repository that coordinates all social features
class SocialRepositoryImpl implements SocialRepository {
  final FriendsRepository _friendsRepository;
  final PostsRepository _postsRepository;
  final ChatRepository _chatRepository;
  final NetworkInfo _networkInfo;

  // Sync state management
  final Map<String, DateTime> _lastSyncTimes = {};
  bool _isOnline = true;
  Timer? _syncTimer;
  final List<Function> _pendingSyncOperations = [];

  // Cross-feature cache invalidation
  final Set<String> _invalidatedCaches = {};

  // Real-time coordination
  final Map<String, StreamController> _crossFeatureStreams = {};

  SocialRepositoryImpl({
    required FriendsRepository friendsRepository,
    required PostsRepository postsRepository,
    required ChatRepository chatRepository,
    required NetworkInfo networkInfo,
  })  : _friendsRepository = friendsRepository,
        _postsRepository = postsRepository,
        _chatRepository = chatRepository,
        _networkInfo = networkInfo {
    _initializeNetworkMonitoring();
    _startPeriodicSync();
  }

  /// Initialize network monitoring for offline/online sync
  void _initializeNetworkMonitoring() {
    _networkInfo.isConnected.then((isConnected) {
      _isOnline = isConnected;
      if (isConnected) {
        _processPendingSyncOperations();
      }
    });

    // Monitor network changes
    _monitorNetworkChanges();
  }

  void _monitorNetworkChanges() {
    Timer.periodic(Duration(seconds: 5), (timer) async {
      final isConnected = await _networkInfo.isConnected;
      if (isConnected != _isOnline) {
        _isOnline = isConnected;
        if (isConnected) {
          await _syncWhenBackOnline();
        }
      }
    });
  }

  /// Start periodic sync for data consistency
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) async {
      if (_isOnline) {
        await _performPeriodicSync();
      }
    });
  }

  /// Sync all features when back online
  Future<void> _syncWhenBackOnline() async {
    try {
      // Process pending operations first
      await _processPendingSyncOperations();

      // Sync critical data
      await Future.wait([
        _syncFriendsData(),
        _syncPostsData(),
        _syncChatData(),
      ]);

      // Invalidate affected caches
      await _processInvalidatedCaches();

      developer.log('Successfully synced data after coming back online', name: 'SocialRepository');
    } catch (e) {
      developer.log('Error syncing data when back online: $e', name: 'SocialRepository', level: 1000);
    }
  }

  /// Process pending sync operations
  Future<void> _processPendingSyncOperations() async {
    final operations = List<Function>.from(_pendingSyncOperations);
    _pendingSyncOperations.clear();

    for (final operation in operations) {
      try {
        await operation();
      } catch (e) {
        developer.log('Error processing pending sync operation: $e', name: 'SocialRepository', level: 1000);
      }
    }
  }

  /// Perform periodic sync of all features
  Future<void> _performPeriodicSync() async {
    try {
      await Future.wait([
        _syncFriendsData(),
        _syncPostsData(),
        _syncChatData(),
      ]);

      _lastSyncTimes['full'] = DateTime.now();
    } catch (e) {
      developer.log('Error during periodic sync: $e', name: 'SocialRepository', level: 1000);
    }
  }

  /// Sync friends data
  Future<void> _syncFriendsData() async {
    try {
      final lastSync = _lastSyncTimes['friends'];
      if (lastSync != null && DateTime.now().difference(lastSync) < Duration(minutes: 2)) {
        return; // Skip if recently synced
      }

      // Refresh friends list - using current user ID placeholder
      await _friendsRepository.getFriends('current_user');
      
      // Refresh friend requests
      await _friendsRepository.getPendingRequests();

      _lastSyncTimes['friends'] = DateTime.now();
    } catch (e) {
      developer.log('Error syncing friends data: $e', name: 'SocialRepository', level: 1000);
    }
  }

  /// Sync posts data
  Future<void> _syncPostsData() async {
    try {
      final lastSync = _lastSyncTimes['posts'];
      if (lastSync != null && DateTime.now().difference(lastSync) < Duration(minutes: 1)) {
        return; // Skip if recently synced
      }

      // Refresh social feed
      await _postsRepository.getSocialFeed();

      _lastSyncTimes['posts'] = DateTime.now();
    } catch (e) {
      developer.log('Error syncing posts data: $e', name: 'SocialRepository', level: 1000);
    }
  }

  /// Sync chat data
  Future<void> _syncChatData() async {
    try {
      final lastSync = _lastSyncTimes['chat'];
      if (lastSync != null && DateTime.now().difference(lastSync) < Duration(minutes: 1)) {
        return; // Skip if recently synced
      }

      // Refresh conversations
      await _chatRepository.getConversations();

      _lastSyncTimes['chat'] = DateTime.now();
    } catch (e) {
      developer.log('Error syncing chat data: $e', name: 'SocialRepository', level: 1000);
    }
  }

  /// Process invalidated caches across features
  Future<void> _processInvalidatedCaches() async {
    final caches = Set<String>.from(_invalidatedCaches);
    _invalidatedCaches.clear();

    for (final cache in caches) {
      try {
        await _invalidateSpecificCache(cache);
      } catch (e) {
        developer.log('Error invalidating cache $cache: $e', name: 'SocialRepository', level: 1000);
      }
    }
  }

  /// Invalidate specific cache
  Future<void> _invalidateSpecificCache(String cacheType) async {
    switch (cacheType) {
      case 'social_feed':
        await _postsRepository.getSocialFeed();
        break;
      case 'friends':
        await _friendsRepository.getFriends('current_user');
        break;
      case 'conversations':
        await _chatRepository.getConversations();
        break;
      default:
        developer.log('Unknown cache type: $cacheType', name: 'SocialRepository', level: 900);
    }
  }

  /// Cross-feature operations

  /// Get comprehensive social dashboard data
  Future<Either<Failure, Map<String, dynamic>>> getSocialDashboard() async {
    try {
      final results = await Future.wait([
        _friendsRepository.getFriends('current_user').then((result) => result.fold(
          (failure) => null,
          (friends) => friends,
        )),
        _postsRepository.getSocialFeed().then((result) => result.fold(
          (failure) => null,
          (feed) => feed.posts.take(10).toList(),
        )),
        _chatRepository.getConversations().then((result) => result.fold(
          (failure) => null,
          (conversations) => conversations.take(5).toList(),
        )),
        _chatRepository.getTotalUnreadCount().then((result) => result.fold(
          (failure) => 0,
          (count) => count,
        )),
      ]);

      final dashboard = {
        'friends': results[0] ?? [],
        'recent_posts': results[1] ?? [],
        'recent_conversations': results[2] ?? [],
        'unread_count': results[3] ?? 0,
        'last_updated': DateTime.now().toIso8601String(),
      };

      return Right(dashboard);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get social dashboard: $e'));
    }
  }

  /// Get social activity summary
  Future<Either<Failure, Map<String, dynamic>>> getSocialActivitySummary({
    Duration period = const Duration(days: 7),
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(period);

      // Note: These would need to be implemented in individual repositories
      final results = await Future.wait([
        _getPostsActivity(startDate, endDate),
        _getFriendsActivity(startDate, endDate),
        _getChatActivity(startDate, endDate),
      ]);

      final summary = {
        'posts_activity': results[0],
        'friends_activity': results[1],
        'chat_activity': results[2],
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };

      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get activity summary: $e'));
    }
  }

  /// Share post to chat
  Future<Either<Failure, ChatMessage>> sharePostToChat({
    required String postId,
    required String conversationId,
    String? message,
  }) async {
    try {
      // Get post details
      final postResult = await _postsRepository.getPost(postId);
      if (postResult.isLeft()) {
        return Left(postResult.fold((failure) => failure, (_) => throw Exception()));
      }

      final post = postResult.fold((_) => throw Exception(), (post) => post);

      // Create share message content
      final shareContent = message != null 
          ? '$message\n\nShared post: ${post.content}'
          : 'Shared post: ${post.content}';

      // Send message to chat
      final messageResult = await _chatRepository.sendMessage(
        conversationId: conversationId,
        content: shareContent,
      );

      // Invalidate related caches
      _invalidatedCaches.add('conversations');

      return messageResult;
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to share post to chat: $e'));
    }
  }

  /// Create post from chat message
  Future<Either<Failure, Post>> createPostFromMessage({
    required String messageId,
    String? additionalContent,
    PostVisibility visibility = PostVisibility.public,
  }) async {
    try {
      // Note: This would need a method to get message by ID in ChatRepository
      // For now, we'll create a placeholder implementation

      final content = additionalContent ?? 'Shared from chat';

      final postResult = await _postsRepository.createPost(
        content: content,
        visibility: visibility,
      );

      // Invalidate related caches
      _invalidatedCaches.add('social_feed');

      return postResult;
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create post from message: $e'));
    }
  }

  /// Get mutual friends in conversation
  Future<Either<Failure, List<Friend>>> getMutualFriendsInConversation(
    String conversationId,
  ) async {
    try {
      // Get conversation participants
      final conversationResult = await _chatRepository.getConversation(conversationId);
      if (conversationResult.isLeft()) {
        return Left(conversationResult.fold((failure) => failure, (_) => throw Exception()));
      }

      final conversation = conversationResult.fold((_) => throw Exception(), (conv) => conv);

      // Get mutual friends for each participant
      final mutualFriends = <Friend>[];
      for (final participant in conversation.participants) {
        if (participant.id != 'current_user') { // Replace with actual current user ID
          final mutualResult = await _friendsRepository.getMutualFriends(participant.id);
          mutualResult.fold(
            (_) => {},
            (friends) => mutualFriends.addAll(friends),
          );
        }
      }

      // Remove duplicates
      final uniqueFriends = <String, Friend>{};
      for (final friend in mutualFriends) {
        uniqueFriends[friend.id] = friend;
      }

      return Right(uniqueFriends.values.toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get mutual friends: $e'));
    }
  }

  /// Sync user social status across features
  Future<Either<Failure, bool>> syncUserSocialStatus({
    required String userId,
    required Map<String, dynamic> statusData,
  }) async {
    try {
      if (!_isOnline) {
        // Queue for later sync
        _pendingSyncOperations.add(() => syncUserSocialStatus(
          userId: userId,
          statusData: statusData,
        ));
        return Right(true);
      }

      // Update status across all features
      final futures = <Future>[];

      // Update in posts if user creates content
      if (statusData.containsKey('activity_status')) {
        // This would need implementation in PostsRepository
      }

      // Update in chat for presence
      if (statusData.containsKey('online_status')) {
        // This would need implementation in ChatRepository
      }

      // Update in friends for availability
      if (statusData.containsKey('availability')) {
        // This would need implementation in FriendsRepository
      }

      await Future.wait(futures);

      // Invalidate related caches
      _invalidatedCaches.addAll(['friends', 'conversations', 'social_feed']);

      return Right(true);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to sync user status: $e'));
    }
  }

  /// Get comprehensive notification data
  Future<Either<Failure, Map<String, dynamic>>> getNotificationSummary() async {
    try {
      final results = await Future.wait([
        _friendsRepository.getPendingRequests().then((result) => result.fold(
          (_) => 0,
          (requests) => requests.length,
        )),
        _chatRepository.getTotalUnreadCount().then((result) => result.fold(
          (_) => 0,
          (count) => count,
        )),
        // Posts mentions/reactions would need implementation
        Future.value(0), // Placeholder for post notifications
      ]);

      final summary = {
        'friend_requests': results[0],
        'unread_messages': results[1],
        'post_notifications': results[2],
        'total': results[0] + results[1] + results[2],
        'last_updated': DateTime.now().toIso8601String(),
      };

      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get notification summary: $e'));
    }
  }

  /// Cache management strategy
  Future<void> optimizeCacheUsage() async {
    try {
      // Get cache sizes and last access times
      final cacheStats = await _getCacheStatistics();

      // Clear old or unused caches
      await _clearOldCaches(cacheStats);

      // Preload important data
      await _preloadCriticalData();

    } catch (e) {
      developer.log('Error optimizing cache usage: $e', name: 'SocialRepository', level: 1000);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> _getCacheStatistics() async {
    // This would need implementation in individual repositories
    return {
      'friends_cache_size': 0,
      'posts_cache_size': 0,
      'chat_cache_size': 0,
      'last_access_times': {},
    };
  }

  /// Clear old caches
  Future<void> _clearOldCaches(Map<String, dynamic> stats) async {
    // Implementation would depend on cache access from repositories
  }

  /// Preload critical data
  Future<void> _preloadCriticalData() async {
    if (_isOnline) {
      // Preload most important data
      await Future.wait([
        _friendsRepository.getFriends('current_user'),
        _chatRepository.getConversations(),
        // Don't preload full social feed to save bandwidth
      ]);
    }
  }

  /// Helper methods for activity tracking

  Future<Map<String, dynamic>> _getPostsActivity(DateTime start, DateTime end) async {
    // Placeholder - would need implementation in PostsRepository
    return {
      'posts_created': 0,
      'posts_liked': 0,
      'comments_made': 0,
    };
  }

  Future<Map<String, dynamic>> _getFriendsActivity(DateTime start, DateTime end) async {
    // Placeholder - would need implementation in FriendsRepository
    return {
      'friends_added': 0,
      'friend_requests_sent': 0,
      'friend_requests_received': 0,
    };
  }

  Future<Map<String, dynamic>> _getChatActivity(DateTime start, DateTime end) async {
    // Placeholder - would need implementation in ChatRepository
    return {
      'messages_sent': 0,
      'conversations_started': 0,
      'groups_joined': 0,
    };
  }

  /// Real-time cross-feature coordination
  Stream<Map<String, dynamic>> getSocialUpdatesStream() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Combine streams from all features
    final subscriptions = <StreamSubscription>[];

    // Friends updates - would need implementation
    // subscriptions.add(
    //   _friendsRepository.getFriendsStream().listen((friends) {
    //     controller.add({
    //       'type': 'friends_update',
    //       'data': friends,
    //       'timestamp': DateTime.now().toIso8601String(),
    //     });
    //   }),
    // );

    // Posts updates (would need implementation)
    // subscriptions.add(
    //   _postsRepository.getPostsStream().listen((posts) {
    //     controller.add({
    //       'type': 'posts_update',
    //       'data': posts,
    //       'timestamp': DateTime.now().toIso8601String(),
    //     });
    //   }),
    // );

    // Chat updates - would need implementation
    // subscriptions.add(
    //   _chatRepository.getConversationStream().listen((conversations) {
    //     controller.add({
    //       'type': 'conversations_update',
    //       'data': conversations,
    //       'timestamp': DateTime.now().toIso8601String(),
    //     });
    //   }),
    // );

    // Clean up subscriptions when stream is cancelled
    controller.onCancel = () {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    };

    return controller.stream;
  }

  /// Cleanup resources
  @override
  void dispose() {
    _syncTimer?.cancel();

    // Close cross-feature streams
    for (final controller in _crossFeatureStreams.values) {
      controller.close();
    }

    // Clear caches
    _lastSyncTimes.clear();
    _pendingSyncOperations.clear();
    _invalidatedCaches.clear();
    _crossFeatureStreams.clear();

    developer.log('SocialRepositoryImpl disposed', name: 'SocialRepository');
  }

  // ============ SOCIAL REPOSITORY INTERFACE IMPLEMENTATION ============

  @override
  Future<Either<Failure, Post>> createPost({
    required String content,
    List<String>? mediaUrls,
    String? gameResultId,
    String? location,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _postsRepository.createPost(
        content: content,
        // Note: Individual repository might need updates to support all parameters
      );
      
      if (result.isRight()) {
        _invalidatedCaches.add('social_feed');
      }
      
      return result;
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create post: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getFeed({
    String feedType = 'home',
    int? limit,
    String? cursor,
  }) async {
    try {
      final result = await _postsRepository.getSocialFeed();
      
      return result.fold(
        (failure) => Left(failure),
        (feed) => Right({
          'posts': feed.posts,
          'next_cursor': null, // Would need cursor support in posts repository
        }),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get feed: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> getPost(String postId) async {
    return await _postsRepository.getPost(postId);
  }

  @override
  Future<Either<Failure, dynamic>> reactToPost({
    required String postId,
    required String reactionType,
    Map<String, dynamic>? metadata,
  }) async {
    // Would need implementation in PostsRepository
    return Left(ServerFailure(message: 'React to post not implemented'));
  }

  @override
  Future<Either<Failure, dynamic>> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
    List<String>? mentions,
  }) async {
    // Would need implementation in PostsRepository
    return Left(ServerFailure(message: 'Add comment not implemented'));
  }

  @override
  Future<Either<Failure, List<Post>>> getTrendingPosts({
    Duration? timeframe,
    int? limit,
  }) async {
    // Would need implementation in PostsRepository
    return Left(ServerFailure(message: 'Get trending posts not implemented'));
  }

  @override
  Future<Either<Failure, bool>> deletePost(String postId) async {
    // Would need implementation in PostsRepository
    return Left(ServerFailure(message: 'Delete post not implemented'));
  }

  @override
  Future<Either<Failure, Post>> updatePost({
    required String postId,
    required String content,
    List<String>? mediaUrls,
    Map<String, dynamic>? metadata,
  }) async {
    // Would need implementation in PostsRepository
    return Left(ServerFailure(message: 'Update post not implemented'));
  }

  @override
  Future<Either<Failure, dynamic>> sendFriendRequest({
    required String targetUserId,
    String? message,
  }) async {
    final result = await _friendsRepository.sendFriendRequest(targetUserId);
    
    if (result.isRight()) {
      _invalidatedCaches.add('friends');
    }
    
    return result;
  }

  @override
  Future<Either<Failure, bool>> acceptFriendRequest(String requestId) async {
    final result = await _friendsRepository.acceptFriendRequest(requestId);
    
    if (result.isRight()) {
      _invalidatedCaches.add('friends');
      return const Right(true);
    }
    
    return Left(result.fold((failure) => failure, (_) => throw Exception('Should not reach here')));
  }

  @override
  Future<Either<Failure, bool>> declineFriendRequest(String requestId) async {
    return await _friendsRepository.declineFriendRequest(requestId);
  }

  @override
  Future<Either<Failure, List<dynamic>>> getFriends({String? userId}) async {
    final result = await _friendsRepository.getFriends(userId ?? 'current_user');
    return result.fold(
      (failure) => Left(failure),
      (friends) => Right(friends.cast<dynamic>()),
    );
  }

  @override
  Future<Either<Failure, Map<String, List<dynamic>>>> getFriendRequests() async {
    final result = await _friendsRepository.getPendingRequests();
    return result.fold(
      (failure) => Left(failure),
      (requests) => Right({
        'received': requests.cast<dynamic>(),
        'sent': <dynamic>[], // Would need separate method for sent requests
      }),
    );
  }

  @override
  Future<Either<Failure, List<dynamic>>> getMutualFriends({
    required String userId,
  }) async {
    final result = await _friendsRepository.getMutualFriends(userId);
    return result.fold(
      (failure) => Left(failure),
      (friends) => Right(friends.cast<dynamic>()),
    );
  }

  @override
  Future<Either<Failure, bool>> removeFriend(String friendId) async {
    final result = await _friendsRepository.removeFriend(friendId);
    
    if (result.isRight()) {
      _invalidatedCaches.add('friends');
    }
    
    return result;
  }

  @override
  Future<Either<Failure, bool>> blockUser(String userId) async {
    final result = await _friendsRepository.blockUser(userId);
    
    if (result.isRight()) {
      _invalidatedCaches.addAll(['friends', 'social_feed']);
    }
    
    return result;
  }

  @override
  Future<Either<Failure, List<dynamic>>> getBlockedUsers() async {
    // Would need implementation in FriendsRepository
    return Left(ServerFailure(message: 'Get blocked users not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> getPotentialFriends({
    int? limit,
  }) async {
    // Would need implementation in FriendsRepository
    return Left(ServerFailure(message: 'Get potential friends not implemented'));
  }

  @override
  Future<Either<Failure, dynamic>> getCurrentUser() async {
    // Would need implementation in a UserRepository or similar
    return Left(ServerFailure(message: 'Get current user not implemented'));
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    List<String>? attachments,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _chatRepository.sendMessage(
      conversationId: conversationId,
      content: content,
    );
    
    if (result.isRight()) {
      _invalidatedCaches.add('conversations');
    }
    
    return result;
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required String conversationId,
    int? limit,
    String? beforeMessageId,
  }) async {
    return await _chatRepository.getMessages(
      conversationId: conversationId,
      limit: limit ?? 50,
      beforeMessageId: beforeMessageId,
    );
  }

  @override
  Future<Either<Failure, bool>> markAsRead({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    try {
      // Mark each message as read individually
      for (final messageId in messageIds) {
        final result = await _chatRepository.markMessageAsRead(
          messageId: messageId,
          userId: 'current_user',
        );
        
        // If any message fails to mark as read, return the failure
        if (result.isLeft()) {
          return result;
        }
      }
      
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark messages as read: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    // Would need implementation in ChatRepository
    return Left(ServerFailure(message: 'Update typing status not implemented'));
  }

  @override
  Future<Either<Failure, bool>> deleteMessage({
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    // Would need implementation in ChatRepository
    return Left(ServerFailure(message: 'Delete message not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> getConversations({
    int? limit,
    String? cursor,
  }) async {
    final result = await _chatRepository.getConversations();
    return result.fold(
      (failure) => Left(failure),
      (conversations) => Right(conversations.cast<dynamic>()),
    );
  }

  @override
  Future<Either<Failure, dynamic>> getOrCreateConversation({
    required List<String> participantIds,
    String? conversationType,
  }) async {
    // Would need implementation in ChatRepository
    return Left(ServerFailure(message: 'Get or create conversation not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> searchUsers({
    required String query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    // Would need implementation in UserRepository
    return Left(ServerFailure(message: 'Search users not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> getUsersNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int? limit,
  }) async {
    // Would need implementation in UserRepository
    return Left(ServerFailure(message: 'Get users near location not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> getUsersBySportsInterests({
    required List<String> sportsInterests,
    String? skillLevelFilter,
    int? limit,
  }) async {
    // Would need implementation in UserRepository
    return Left(ServerFailure(message: 'Get users by sports interests not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> getUsersBySkillLevel({
    required String sport,
    required String skillLevel,
    bool includeSimilarLevels = true,
    int? limit,
  }) async {
    // Would need implementation in UserRepository
    return Left(ServerFailure(message: 'Get users by skill level not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> getUsersByActivityLevel({
    required String activityLevel,
    int? limit,
  }) async {
    // Would need implementation in UserRepository
    return Left(ServerFailure(message: 'Get users by activity level not implemented'));
  }

  @override
  Future<Either<Failure, List<dynamic>>> getMutualConnections(
    String userId1,
    String userId2,
  ) async {
    // Would need implementation in UserRepository
    return Left(ServerFailure(message: 'Get mutual connections not implemented'));
  }

  @override
  Future<Either<Failure, List<String>>> getTrendingInterests() async {
    // Would need implementation in UserRepository
    return Left(ServerFailure(message: 'Get trending interests not implemented'));
  }

  @override
  Future<Either<Failure, bool>> syncData({
    List<String>? features,
  }) async {
    try {
      if (features == null || features.isEmpty) {
        await _performPeriodicSync();
      } else {
        if (features.contains('friends')) await _syncFriendsData();
        if (features.contains('posts')) await _syncPostsData();
        if (features.contains('chat')) await _syncChatData();
      }
      
      return Right(true);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to sync data: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSyncStatus() async {
    return Right({
      'is_online': _isOnline,
      'last_sync_times': _lastSyncTimes,
      'pending_operations': _pendingSyncOperations.length,
      'invalidated_caches': _invalidatedCaches.toList(),
    });
  }

  @override
  Future<Either<Failure, bool>> forceSyncWhenOnline() async {
    try {
      await _syncWhenBackOnline();
      return Right(true);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to force sync: $e'));
    }
  }

  @override
  Future<bool> get isOnline async => _isOnline;

  @override
  Stream<dynamic> subscribeToUpdates(String channel) {
    if (!_crossFeatureStreams.containsKey(channel)) {
      _crossFeatureStreams[channel] = StreamController.broadcast();
    }
    return _crossFeatureStreams[channel]!.stream;
  }
}

/// Server failure for unified operations
class ServerFailure extends Failure {
  ServerFailure({required super.message});
}
