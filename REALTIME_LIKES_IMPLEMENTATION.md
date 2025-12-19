# Real-Time Likes System Implementation

## Overview
Complete professional-grade real-time likes system for Dabbler social features. Like updates are instantly synchronized across all connected clients, similar to Instagram/Twitter.

## Architecture

### Database Layer (PostgreSQL + Supabase)
- **Triggers**: Automatic `like_count` maintenance on `posts` and `post_comments` tables
  - `increment_post_like_count()` - Fires on INSERT to `post_likes`
  - `decrement_post_like_count()` - Fires on DELETE from `post_likes`
  - `increment_comment_like_count()` - Fires on INSERT to `comment_likes`
  - `decrement_comment_like_count()` - Fires on DELETE from `comment_likes`

- **Realtime Publication**: Enabled for `post_likes`, `comment_likes`, `posts`, `post_comments`
  - Broadcasts INSERT/DELETE/UPDATE events to all subscribed clients
  - Used Supabase's `supabase_realtime` publication

- **Indexes**: Performance optimization
  - `idx_post_likes_user_id` on `post_likes(user_id)`
  - `idx_post_likes_post_id` on `post_likes(post_id)`
  - `idx_comment_likes_user_id` on `comment_likes(user_id)`
  - `idx_comment_likes_comment_id` on `comment_likes(comment_id)`

### Flutter Layer

#### 1. RealtimeLikesService (Singleton)
**File**: `lib/features/social/services/realtime_likes_service.dart`

**Purpose**: Centralized real-time subscription manager for all like events across the app

**Key Components**:
- 4 RealtimeChannel subscriptions:
  - `_postLikesChannel`: Listens to INSERT/DELETE on `post_likes` table
  - `_postsChannel`: Listens to UPDATE on `posts` table (like_count changes)
  - `_commentLikesChannel`: Listens to INSERT/DELETE on `comment_likes` table
  - `_commentsChannel`: Listens to UPDATE on `post_comments` table

- Broadcast StreamControllers:
  - `_postLikeController`: Emits `PostLikeUpdate` events
  - `_commentLikeController`: Emits `CommentLikeUpdate` events

**Models**:
```dart
class PostLikeUpdate {
  final String postId;
  final String userId;
  final bool isLiked;  // true = liked, false = unliked
  final DateTime timestamp;
  final int newLikeCount;
}

class CommentLikeUpdate {
  final String commentId;
  final String userId;
  final bool isLiked;
  final DateTime timestamp;
  final int newLikeCount;
}
```

**API Methods**:
- `initialize()` - Start all subscriptions (called in main.dart)
- `postUpdates(String postId)` - Subscribe to likes for specific post
- `commentUpdates(String commentId)` - Subscribe to likes for specific comment
- `isPostLikedByUser(String postId, String userId)` - Check local cache
- `getPostLikeCount(String postId)` - Get cached count
- `dispose()` - Cleanup subscriptions

#### 2. SocialService Updates
**File**: `lib/features/social/services/social_service.dart`

**Changes**:
- Simplified `toggleLike()` method - no longer manually queries `like_count`
- Database triggers handle count updates automatically
- Added 50ms delay after insert/delete to ensure trigger completes
- Maintains `_likesInProgress` map for concurrency control
- Returns `{'isLiked': bool, 'likesCount': int}` for optimistic UI updates

#### 3. UI Screen Updates

**social_screen.dart** (Main Feed):
- Added `_likeSubscriptions` map to track subscriptions per post
- `_subscribeToPostLikes()` method subscribes to realtime updates
- Subscribes to each post when feed loads
- Updates local `_posts` list when any user likes/unlikes
- Cancels all subscriptions in `dispose()`

**post_detail_screen.dart** (Single Post View):
- Added `_likeSubscription` for the displayed post
- Subscribes in `initState()` after loading post details
- Invalidates `postDetailsProvider` on updates to refresh UI
- Cancels subscription in `dispose()`

**thread_screen.dart** (Thread View):
- Same pattern as post_detail_screen.dart
- Subscribes to post likes for thread context
- Invalidates provider on realtime updates

#### 4. App Initialization
**File**: `lib/main.dart`

Added realtime service initialization:
```dart
// Initialize realtime likes service for social features
if (FeatureFlags.socialFeed) {
  await RealtimeLikesService().initialize();
}
```

## Data Flow

### User Likes a Post:
1. User taps like button
2. **Optimistic Update**: UI immediately shows liked state (instant feedback)
3. `SocialService.toggleLike()` called
4. INSERT to `post_likes` table (with RLS check)
5. **Database Trigger**: `increment_post_like_count()` fires, updates `posts.like_count`
6. **Realtime Broadcast**: Supabase broadcasts INSERT event to all clients
7. **RealtimeLikesService**: Receives event, emits `PostLikeUpdate` via stream
8. **All Subscribed UIs**: Update their local state with new count
9. **Current User**: Reconciles optimistic update with server response

### User Unlikes a Post:
Same flow but DELETE from `post_likes` and `decrement_post_like_count()` trigger

### Other User Likes/Unlikes:
1. Realtime broadcast received by all clients
2. UI updates automatically without refresh
3. Current user sees other users' likes in real-time

## Key Features

✅ **Real-Time Synchronization**: All users see likes instantly
✅ **Optimistic Updates**: Instant UI feedback before server confirms
✅ **Race Condition Prevention**: Lock mechanisms prevent double-clicks
✅ **Automatic Count Maintenance**: Database triggers ensure accuracy
✅ **Efficient Subscriptions**: Per-post/comment granular subscriptions
✅ **Memory Management**: Proper cleanup in dispose() methods
✅ **Error Handling**: Rollback optimistic updates on failure
✅ **Scalability**: Broadcast streams distribute updates efficiently

## Performance Optimizations

1. **Database Indexes**: Fast lookups on user_id and post_id
2. **Composite Keys**: `(post_id, user_id)` prevents duplicate likes
3. **Granular Subscriptions**: Subscribe only to visible posts
4. **Stream Caching**: RealtimeLikesService caches counts/states
5. **Broadcast Streams**: Multiple listeners without duplication

## Testing Checklist

- [ ] Single user: Like/unlike button toggles correctly
- [ ] Single user: Counter updates immediately
- [ ] Multiple users: User A likes, User B sees update in real-time
- [ ] Multiple users: User A unlikes, User B sees counter decrement
- [ ] Double-click prevention: Rapid clicks don't cause incorrect counts
- [ ] Network delay: Optimistic updates work, reconcile when online
- [ ] Refresh: Like state persists after app restart
- [ ] Memory leaks: No subscription leaks after navigating away

## Files Modified

### Created:
- `lib/features/social/services/realtime_likes_service.dart` (268 lines)

### Updated:
- `lib/features/social/services/social_service.dart` - Simplified toggleLike()
- `lib/features/social/presentation/screens/social_screen.dart` - Added realtime subscriptions
- `lib/features/social/presentation/screens/social_feed/post_detail_screen.dart` - Added subscription
- `lib/features/social/presentation/screens/social_feed/thread_screen.dart` - Added subscription
- `lib/main.dart` - Initialize realtime service on app startup

### Database (SQL executed):
- Created 4 triggers for automatic like_count maintenance
- Configured realtime publication for 4 tables
- Added 4 performance indexes
- Repaired inconsistent like counts

## Future Enhancements

- [ ] Batch like notifications for performance
- [ ] Websocket connection pooling
- [ ] Offline queue for likes when no connection
- [ ] Animation when like count updates from other users
- [ ] Haptic feedback on like/unlike
- [ ] Analytics tracking for like engagement

## Troubleshooting

**Issue**: Likes not updating in real-time
- Check: Realtime service initialized in main.dart?
- Check: Supabase realtime subscription active?
- Check: Database triggers created successfully?

**Issue**: Counter showing wrong values
- Fix: Run data repair SQL to fix inconsistent counts
- Check: Ensure no manual count updates in code

**Issue**: Double-click causing wrong counts
- Check: `_likesInProgress` locks in place?
- Check: 50ms delay after insert/delete?

## Related Documentation
- [SQL Migration Script](./docs/realtime_likes_migration.sql)
- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [Architecture Instructions](.github/copilot-instructions.md)
