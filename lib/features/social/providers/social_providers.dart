import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/controllers/chat_controller.dart';
import '../presentation/controllers/friends_controller.dart';
import '../presentation/controllers/posts_controller.dart';
import '../presentation/controllers/social_feed_controller.dart';
import 'package:dabbler/data/models/social/chat_message_model.dart';
import 'package:dabbler/data/models/social/conversation_model.dart';
import '../../../../utils/enums/social_enums.dart'; // Import MessageType
import '../services/social_service.dart';
import '../../authentication/presentation/providers/auth_providers.dart';

// =============================================================================
// POSTS CONTROLLER PROVIDER
// =============================================================================

/// Provider for PostsController
final postsControllerProvider =
    StateNotifierProvider<PostsController, PostsState>((ref) {
      // Placeholder implementation - in real app, inject proper use cases
      throw UnimplementedError('PostsController dependencies not implemented');
    });

// =============================================================================
// SOCIAL FEED CONTROLLER PROVIDER
// =============================================================================

/// Provider for SocialFeedController
final socialFeedControllerProvider =
    StateNotifierProvider<SocialFeedController, SocialFeedState>((ref) {
      return SocialFeedController();
    });

// =============================================================================
// FRIENDS CONTROLLER PROVIDER
// =============================================================================

/// Provider for FriendsController
final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
      // Placeholder implementation - in real app, inject proper use cases
      throw UnimplementedError(
        'FriendsController dependencies not implemented',
      );
    });

// =============================================================================
// FRIENDS COMPUTED PROVIDERS
// =============================================================================

/// Total friends count
final totalFriendsCountProvider = Provider<int>((ref) {
  final friendsState = ref.watch(friendsControllerProvider);
  return friendsState.totalFriendsCount;
});

/// Online friends count
final onlineFriendsCountProvider = Provider<int>((ref) {
  final friendsState = ref.watch(friendsControllerProvider);
  return friendsState.onlineFriendsCount;
});

/// Blocked users count
final blockedUsersCountProvider = Provider<int>((ref) {
  final friendsState = ref.watch(friendsControllerProvider);
  return friendsState.blockedUsers.length;
});

/// Has pending friend requests
final hasPendingFriendRequestsProvider = Provider<bool>((ref) {
  final friendsState = ref.watch(friendsControllerProvider);
  return friendsState.incomingRequests.isNotEmpty;
});

// =============================================================================
// FRIEND PROFILE + RELATED DATA PROVIDERS (PLACEHOLDERS)
// =============================================================================

/// Friend profile provider
final friendProfileProvider = FutureProvider.family<dynamic, String>((
  ref,
  friendId,
) async {
  // Mock friend profile object using a simple map-like dynamic with fields used in widgets
  await Future.delayed(const Duration(milliseconds: 200));
  return _MockFriend(
    id: friendId,
    name: 'User $friendId',
    username: 'user_$friendId',
    avatarUrl: null,
    friendsCount: 42,
    activitiesCount: 12,
    level: 3,
  );
});

/// Mutual friends provider
final mutualFriendsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  friendId,
) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return List.generate(
    6,
    (i) => _MockFriend(
      id: 'mutual_$i',
      name: 'Mutual Friend $i',
      username: 'mutual_$i',
      avatarUrl: null,
    ),
  );
});

/// Shared activities provider
final sharedActivitiesProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  friendId,
) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return List.generate(
    4,
    (i) => _MockActivity(
      id: 'activity_$i',
      title: 'Pickup Game $i',
      description: 'Friendly match at the park',
      type: i % 2 == 0 ? 'soccer' : 'basketball',
      date: DateTime.now().subtract(Duration(days: i)),
      location: 'City Park',
    ),
  );
});

/// Common interests provider
final commonInterestsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  friendId,
) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    _MockInterest(name: 'Football', type: 'sports'),
    _MockInterest(name: 'Running', type: 'fitness'),
    _MockInterest(name: 'Music', type: 'music'),
  ];
});

// Simple mock classes to provide the minimal shape used in UI widgets
class _MockFriend {
  final String id;
  final String? name;
  final String? username;
  final String? avatarUrl;
  final int? friendsCount;
  final int? activitiesCount;
  final int? level;
  _MockFriend({
    required this.id,
    this.name,
    this.username,
    this.avatarUrl,
    this.friendsCount,
    this.activitiesCount,
    this.level,
  });
}

class _MockActivity {
  final String id;
  final String? title;
  final String? description;
  final String? type;
  final DateTime? date;
  final String? location;
  _MockActivity({
    required this.id,
    this.title,
    this.description,
    this.type,
    this.date,
    this.city,
  });
}

class _MockInterest {
  final String? name;
  final String? type;
  _MockInterest({this.name, this.type});
}

// =============================================================================
// CHAT CONTROLLER PROVIDER
// =============================================================================

/// Provider for ChatController
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    // In real implementation, inject use case dependency
    throw UnimplementedError('ChatController use case dependency not provided');
  },
);

// =============================================================================
// COMPUTED PROVIDERS (DERIVED STATE)
// =============================================================================

/// Total unread messages count across all conversations
final totalUnreadMessagesProvider = Provider<int>((ref) {
  final chatState = ref.watch(chatControllerProvider);
  return chatState.totalUnreadCount;
});

/// Current active conversation
final activeConversationProvider = Provider<ConversationModel?>((ref) {
  final chatState = ref.watch(chatControllerProvider);
  return chatState.activeConversation;
});

/// Is currently typing in active conversation
final isTypingProvider = Provider<bool>((ref) {
  final chatState = ref.watch(chatControllerProvider);
  return chatState.isTypingSomeone;
});

// =============================================================================
// STREAM PROVIDERS (REAL-TIME DATA)
// =============================================================================

/// Stream of new messages
final newMessagesStreamProvider = StreamProvider<List<ChatMessageModel>>((ref) {
  // Mock stream - replace with actual real-time implementation
  return Stream.periodic(
    const Duration(minutes: 2),
    (index) => [
      ChatMessageModel(
        id: 'stream_message_$index',
        conversationId: 'stream_conversation_$index',
        senderId: 'stream_sender_$index',
        content: 'Stream message $index',
        sentAt: DateTime.now(),
        messageType: MessageType.text,
      ),
    ],
  );
});

// =============================================================================
// NOTIFICATION PROVIDERS
// =============================================================================

/// Provider for notification badges
final notificationBadgesProvider = Provider<Map<String, int>>((ref) {
  final unreadMessages = ref.watch(totalUnreadMessagesProvider);

  return {'messages': unreadMessages};
});

/// Provider for checking if there are any notifications
final hasNotificationsProvider = Provider<bool>((ref) {
  final badges = ref.watch(notificationBadgesProvider);
  return badges.values.any((count) => count > 0);
});

// =============================================================================
// CHAT-RELATED PROVIDERS
// =============================================================================

/// Provider for conversation participants
final conversationParticipantsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, conversationId) async {
      // Mock implementation - in real app, this would fetch from repository
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        {'id': 'user1', 'name': 'John Doe', 'avatarUrl': null, 'isAdmin': true},
        {
          'id': 'user2',
          'name': 'Jane Smith',
          'avatarUrl': null,
          'isAdmin': false,
        },
      ];
    });

/// Provider for conversation media
final conversationMediaProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  conversationId,
) async {
  // Mock implementation - in real app, this would fetch from repository
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    {
      'id': 'media1',
      'type': 'image',
      'url': 'https://example.com/image1.jpg',
      'thumbnail': 'https://example.com/thumb1.jpg',
      'size': 1024000,
      'name': 'image1.jpg',
    },
    {
      'id': 'media2',
      'type': 'video',
      'url': 'https://example.com/video1.mp4',
      'thumbnail': 'https://example.com/thumb2.jpg',
      'size': 5120000,
      'name': 'video1.mp4',
    },
  ];
});

/// Provider for archived chats count
final archivedChatsCountProvider = Provider<int>((ref) {
  // In a real implementation, this would count archived conversations
  // For now, return 0
  return 0;
});

/// Provider for recent chat contacts
final recentChatContactsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  // Mock implementation - in real app, this would fetch recent contacts
  return [
    {
      'id': 'user1',
      'name': 'John Doe',
      'avatarUrl': null,
      'lastMessage': 'Hey, how are you?',
      'lastMessageTime': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      'id': 'user2',
      'name': 'Jane Smith',
      'avatarUrl': null,
      'lastMessage': 'See you tomorrow!',
      'lastMessageTime': DateTime.now().subtract(const Duration(hours: 2)),
    },
  ];
});

// =============================================================================
// POST DETAILS PROVIDERS
// =============================================================================

/// Provider for post details
final postDetailsProvider = FutureProvider.family<dynamic, String>((
  ref,
  postId,
) async {
  try {
    print('DEBUG: postDetailsProvider called with postId: $postId');
    final socialService = SocialService();

    // Fetch the post from the feed (in a real implementation, you'd have a getPostById method)
    // For now, we'll get from feed and filter, or you can add a new method to SocialService
    final posts = await socialService.getFeedPosts(limit: 100);
    print('DEBUG: Fetched ${posts.length} posts from service');
    print('DEBUG: Post IDs: ${posts.map((p) => p.id).toList()}');

    final post = posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => throw Exception('Post not found with id: $postId'),
    );

    print('DEBUG: Found post with content: "${post.content}"');
    return post;
  } catch (e) {
    print('ERROR in postDetailsProvider: $e');
    throw Exception('Failed to load post: $e');
  }
});

/// Provider for post comments
final postCommentsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  postId,
) async {
  try {
    final socialService = SocialService();
    final rawComments = await socialService.getComments(postId);

    // Transform database comments to UI-expected format
    return rawComments.map((comment) {
      final profile = comment['profiles'];
      return _CommentData(
        id: comment['id'],
        authorId: comment['author_user_id'],
        content: comment['body'] ?? '',
        createdAt: DateTime.parse(comment['created_at']),
        author: _UserViewModel(
          id: comment['author_user_id'],
          name: profile?['display_name'] ?? 'Unknown',
          username: profile?['display_name'] ?? 'unknown',
          avatar: profile?['avatar_url'],
          isVerified: profile?['verified'] ?? false,
        ),
        likesCount: 0, // Comment likes not implemented yet
        isLiked: false,
        replies: const [], // Nested replies not implemented yet
      );
    }).toList();
  } catch (e) {
    throw Exception('Failed to load comments: $e');
  }
});

/// Provider for post comments count
final postCommentsCountProvider = Provider.family<int, String>((ref, postId) {
  final commentsAsync = ref.watch(postCommentsProvider(postId));
  return commentsAsync.when(
    data: (comments) => comments.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for post likes - fetches from database
final postLikesProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  postId,
) async {
  // TODO: Implement actual database fetch for post likes
  // For now, return empty list (likes feature not in MVP phase)
  return [];
});

/// Provider for current user ID - connected to auth service
final currentUserIdProvider = Provider<String>((ref) {
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.getCurrentUser();
  return currentUser?.id ?? '';
});

// =============================================================================
// VIEW MODEL CLASSES (for UI data transformation)
// =============================================================================

/// User view model for displaying user info in comments/posts
class _UserViewModel {
  final String id;
  final String name;
  final String username;
  final String? avatar;
  final bool isVerified;

  const _UserViewModel({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.isVerified = false,
  });
}

/// Comment view model with author data from database
class _CommentData {
  final String id;
  final String authorId;
  final String content;
  final _UserViewModel author;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;
  final List<_CommentData> replies;

  const _CommentData({
    required this.id,
    required this.authorId,
    required this.content,
    required this.author,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });
}

// =============================================================================
// EXTENSION METHODS
// =============================================================================

/// Extension for easy provider access in widgets
extension SocialProvidersExtension on WidgetRef {
  // Controllers
  ChatController get chatController => read(chatControllerProvider.notifier);

  // States
  ChatState get chatState => watch(chatControllerProvider);

  // Computed values
  int get totalUnreadMessages => watch(totalUnreadMessagesProvider);
  bool get hasNotifications => watch(hasNotificationsProvider);
  Map<String, int> get notificationBadges => watch(notificationBadgesProvider);
}
