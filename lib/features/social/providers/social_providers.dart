import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/controllers/chat_controller.dart';
import '../presentation/controllers/friends_controller.dart';
import '../presentation/controllers/posts_controller.dart';
import '../presentation/controllers/social_feed_controller.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/conversation_model.dart';
import '../../../../utils/enums/social_enums.dart'; // Import MessageType

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
    this.location,
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
  // Mock implementation - in real app, this would fetch from repository
  await Future.delayed(const Duration(milliseconds: 300));
  return _MockPost(
    id: postId,
    content: 'This is a sample post content for testing purposes.',
    author: _MockUser(
      id: 'user1',
      name: 'John Doe',
      username: 'johndoe',
      avatar: null,
      isVerified: true,
    ),
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    location: 'Dubai, UAE',
    isEdited: false,
    media: [
      {'type': 'image', 'url': 'https://example.com/image1.jpg'},
    ],
    sports: ['Football', 'Basketball'],
    mentions: ['@janesmith', '@bobwilson'],
    hashtags: ['#sports', '#dubai'],
    likesCount: 42,
    commentsCount: 12,
    sharesCount: 5,
    isLiked: false,
  );
});

/// Provider for post comments
final postCommentsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  postId,
) async {
  // Mock implementation - in real app, this would fetch from repository
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    _MockComment(
      id: 'comment1',
      content: 'Great post! Love the energy.',
      author: _MockUser(
        id: 'user2',
        name: 'Jane Smith',
        username: 'janesmith',
        avatar: null,
        isVerified: false,
      ),
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      likesCount: 5,
      isLiked: false,
      replies: [
        _MockComment(
          id: 'reply1',
          content: 'Totally agree!',
          author: _MockUser(
            id: 'user3',
            name: 'Bob Wilson',
            username: 'bobwilson',
            avatar: null,
            isVerified: false,
          ),
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          likesCount: 2,
          isLiked: false,
        ),
      ],
    ),
    _MockComment(
      id: 'comment2',
      content: 'Looking forward to the next game!',
      author: _MockUser(
        id: 'user4',
        name: 'Alice Johnson',
        username: 'alicejohnson',
        avatar: null,
        isVerified: false,
      ),
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      likesCount: 3,
      isLiked: false,
    ),
  ];
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

/// Provider for post likes
final postLikesProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  postId,
) async {
  // Mock implementation - in real app, this would fetch from repository
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    _MockLike(
      user: _MockUser(
        id: 'user1',
        name: 'John Doe',
        username: 'johndoe',
        avatar: null,
        isVerified: true,
      ),
      reactionType: ReactionType.like,
    ),
    _MockLike(
      user: _MockUser(
        id: 'user2',
        name: 'Jane Smith',
        username: 'janesmith',
        avatar: null,
        isVerified: false,
      ),
      reactionType: ReactionType.love,
    ),
  ];
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String>((ref) {
  // Mock implementation - in real app, this would come from auth service
  return 'current_user_id';
});

// =============================================================================
// MOCK DATA CLASSES
// =============================================================================

class _MockUser {
  final String id;
  final String name;
  final String username;
  final String? avatar;
  final bool isVerified;

  const _MockUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.isVerified = false,
  });
}

class _MockPost {
  final String id;
  final String content;
  final _MockUser author;
  final DateTime createdAt;
  final String? location;
  final bool isEdited;
  final List<dynamic> media;
  final List<String> sports;
  final List<String> mentions;
  final List<String> hashtags;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;

  const _MockPost({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.location,
    this.isEdited = false,
    this.media = const [],
    this.sports = const [],
    this.mentions = const [],
    this.hashtags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
  });
}

class _MockComment {
  final String id;
  final String content;
  final _MockUser author;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;
  final List<_MockComment>? replies;

  const _MockComment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies,
  });
}

class _MockLike {
  final _MockUser user;
  final ReactionType reactionType;

  const _MockLike({required this.user, required this.reactionType});
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
