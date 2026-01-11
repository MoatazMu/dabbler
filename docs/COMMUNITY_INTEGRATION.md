# Community Features Integration Guide

## Overview
This document explains how the community/social features are connected through the repository layer in the Dabbler app.

## Architecture Layers

### 1. **Repository Layer** (`lib/data/repositories/`)
The repository layer provides clean abstractions for data access:

#### Friends Repository
- **File**: `friends_repository.dart` & `friends_repository_impl.dart`
- **Purpose**: Manages friend relationships, requests, and blocking
- **Methods**:
  - `sendFriendRequest(peerUserId)` - Send a friend request
  - `acceptFriendRequest(peerUserId)` - Accept incoming request
  - `rejectFriendRequest(peerUserId)` - Reject incoming request
  - `removeFriend(peerUserId)` - Remove an existing friend
  - `listFriendships()` - Get all friendships
  - `inbox()` - Get incoming friend requests
  - `outbox()` - Get outgoing friend requests
  - `listFriendEdges()` - Get bidirectional friend view
  - `blockUser(peerUserId)` - Block a user
  - `unblockUser(peerUserId)` - Unblock a user

#### Feed Repository
- **File**: `feed_repository.dart` & `feed_repository_impl.dart`
- **Purpose**: Manages social feed and activity timeline
- **Methods**:
  - `listRecent(limit, afterCursor, beforeCursor)` - Get recent feed items
  - `nextCursorFrom(page)` - Get pagination cursor

#### Posts Repository
- **File**: `posts_repository_impl.dart`
- **Purpose**: Manages post creation, likes, comments, and shares
- **Implementation**: Uses Supabase `posts` table with RLS policies

### 2. **Provider Layer** (`lib/features/social/providers/`)

#### Community Providers (`community_providers.dart`)
Connects repositories to the UI through Riverpod providers:

**Repository Providers:**
```dart
final friendsRepositoryProvider // Access to FriendsRepository
final feedRepositoryProvider    // Access to FeedRepository
```

**Friends & Connections:**
```dart
final friendshipsProvider              // All friendships
final friendEdgesProvider              // Bidirectional friend view
final incomingFriendRequestsProvider   // Inbox
final outgoingFriendRequestsProvider   // Outbox
final friendsCountProvider             // Total friends count
final hasPendingRequestsProvider       // Check for pending requests
```

**Friend Actions:**
```dart
final sendFriendRequestProvider(userId)    // Send request
final acceptFriendRequestProvider(userId)  // Accept request
final rejectFriendRequestProvider(userId)  // Reject request
final removeFriendProvider(userId)         // Remove friend
final blockUserProvider(userId)            // Block user
final unblockUserProvider(userId)          // Unblock user
```

**Social Feed:**
```dart
final socialFeedProvider      // Main feed
final userPostsProvider       // User-specific posts
final feedRefreshProvider     // Refresh trigger
final communityStatsProvider  // Engagement stats
```

### 3. **Service Layer** (`lib/features/social/services/`)

#### Social Service (`social_service.dart`)
High-level service for social operations:
- Post creation and management
- Like/unlike functionality
- Comment handling
- Media uploads
- Duplicate post detection

#### Social Rewards Handler (`social_rewards_handler.dart`)
Tracks social interactions for gamification:
- Like rewards
- Comment rewards
- Post creation rewards
- Engagement tracking

### 4. **UI Layer** (`lib/screens/social/` & `lib/features/social/presentation/`)

#### Social Screen (`social_screen.dart`)
Main community feed interface:
- Displays posts from friends and community
- Handles likes and comments
- Integrates with rewards system
- Pull-to-refresh functionality

#### Widgets
- `PostCard` - Individual post display
- `ThoughtsInput` - Create new posts
- Various social interaction widgets

## Data Flow

### Example: Sending a Friend Request

1. **UI Action**: User taps "Add Friend" button
```dart
// In widget
ElevatedButton(
  onPressed: () async {
    try {
      await ref.sendFriendRequest(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent!')),
      );
    } catch (e) {
      // Handle error
    }
  },
  child: Text('Add Friend'),
)
```

2. **Provider Layer**: Extension method calls provider
```dart
// In community_providers.dart
Future<void> sendFriendRequest(String userId) async {
  final result = await read(sendFriendRequestProvider(userId).future);
  result.fold(
    (failure) => throw Exception(failure.message),
    (_) => invalidate(outgoingFriendRequestsProvider),
  );
}
```

3. **Repository Layer**: Executes RPC call
```dart
// In friends_repository_impl.dart
Future<Result<void>> sendFriendRequest(String peerUserId) async {
  try {
    await _db.rpc('rpc_friend_request_send', params: {'p_peer_profile_id': peerProfileId});
    return right(null);
  } catch (error) {
    return left(svc.mapPostgrestError(error));
  }
}
```

4. **Database**: Supabase RPC handles business logic with RLS policies

5. **UI Update**: Provider automatically refreshes affected data

### Example: Loading Social Feed

1. **UI**: Widget watches socialFeedProvider
```dart
// In social_screen.dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final feedAsync = ref.watch(socialFeedProvider);
  
  return feedAsync.when(
    data: (feedItems) => ListView.builder(
      itemCount: feedItems.length,
      itemBuilder: (context, index) => PostCard(post: feedItems[index]),
    ),
    loading: () => CircularProgressIndicator(),
    error: (error, stack) => ErrorWidget(error),
  );
}
```

2. **Provider**: Fetches from repository
```dart
final socialFeedProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(feedRefreshProvider); // Refresh trigger
  final repo = ref.watch(feedRepositoryProvider);
  final result = await repo.listRecent(limit: 50);
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (feedItems) => feedItems,
  );
});
```

3. **Repository**: Queries Supabase with RLS
```dart
Future<Result<List<FeedItem>>> listRecent({int limit = 50}) async {
  // RLS policies automatically filter based on current user
  final response = await _db.from('feed_items')
    .select()
    .order('created_at', ascending: false)
    .limit(limit);
  
  return right(response.map(FeedItem.fromJson).toList());
}
```

## Security & Permissions

### Row Level Security (RLS)
All database operations are protected by Supabase RLS policies:

**Friends Table Policies:**
- `friendships_insert_requester` - Only allow inserting friend requests
- `friendships_update_parties` - Only parties involved can update
- `friendships_select_parties` - Only view your own friendships

**Posts Table Policies:**
- Users can only edit/delete their own posts
- Visibility controlled by `visibility` field (public/friends/private)
- Comments respect post visibility

**Feed Table Policies:**
- Users only see feed items relevant to them
- Server-side filtering based on friend relationships

## Feature Flags (MVP Control)

```dart
// In lib/core/config/feature_flags.dart
class FeatureFlags {
  // Social features
  static const bool enableSocialFeed = false;      // MVP: Disabled
  static const bool enableFriendRequests = true;   // MVP: Enabled
  static const bool enableMessaging = false;       // MVP: Disabled
  static const bool enableSquads = false;          // MVP: Disabled
  static const bool enableComments = true;         // MVP: Enabled
  static const bool enablePostSharing = false;     // MVP: Disabled
}
```

## Testing the Integration

### 1. Test Friend Operations
```dart
// In tests or debug mode
final ref = ProviderContainer();

// Send friend request
await ref.read(sendFriendRequestProvider('user-id-123').future);

// Check friends count
final count = ref.read(friendsCountProvider);
print('Total friends: $count');

// Get pending requests
final pending = await ref.read(incomingFriendRequestsProvider.future);
print('Pending requests: ${pending.length}');
```

### 2. Test Feed Operations
```dart
// Refresh feed
ref.read(feedRefreshProvider.notifier).refresh();

// Get feed items
final feed = await ref.read(socialFeedProvider.future);
print('Feed items: ${feed.length}');

// Get community stats
final stats = await ref.read(communityStatsProvider.future);
print('Stats: $stats');
```

## Usage in Screens

### Adding Friend Request Button
```dart
Consumer(
  builder: (context, ref, child) {
    final hasPending = ref.watch(hasPendingRequestsProvider);
    
    return IconButton(
      icon: Badge(
        isLabelVisible: hasPending,
        child: Icon(Icons.person_add),
      ),
      onPressed: () async {
        // Show friend requests dialog
      },
    );
  },
)
```

### Displaying Friends Count
```dart
Consumer(
  builder: (context, ref, child) {
    final count = ref.watch(friendsCountProvider);
    
    return Text('$count Friends');
  },
)
```

### Refreshing Feed
```dart
RefreshIndicator(
  onRefresh: () async {
    ref.read(feedRefreshProvider.notifier).refresh();
    await ref.read(socialFeedProvider.future);
  },
  child: FeedList(),
)
```

## Troubleshooting

### Common Issues

**1. "FriendsRepository not found"**
- Ensure `supabaseServiceProvider` is properly initialized
- Check that repository providers are accessible in widget tree

**2. "RLS Policy Error"**
- Verify user is authenticated: `Supabase.instance.client.auth.currentUser`
- Check database policies in Supabase dashboard
- Ensure RPC functions have proper permissions

**3. "Provider disposed too early"**
- Use `.autoDispose` for providers that should clean up
- Don't use `.autoDispose` for providers needed globally

**4. "Feed not refreshing"**
- Call `ref.read(feedRefreshProvider.notifier).refresh()`
- Invalidate providers: `ref.invalidate(socialFeedProvider)`

## Future Enhancements

- [ ] Real-time friend status updates (online/offline)
- [ ] Push notifications for friend requests
- [ ] Advanced feed filtering (by sport, date, location)
- [ ] Friend suggestions based on mutual connections
- [ ] Group chat/squad messaging
- [ ] Post analytics and insights
- [ ] Content moderation tools
- [ ] Report and block improvements

## Related Files

- `/lib/data/repositories/friends_repository.dart` - Repository interface
- `/lib/data/repositories/friends_repository_impl.dart` - Implementation
- `/lib/features/social/providers/community_providers.dart` - Providers
- `/lib/screens/social/social_screen.dart` - Main UI
- `/lib/features/social/services/social_service.dart` - Business logic
- `/lib/core/config/feature_flags.dart` - Feature toggles
