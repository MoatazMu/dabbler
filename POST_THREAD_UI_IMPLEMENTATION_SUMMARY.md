# Post and Thread UI Enhancement - Implementation Summary

## ✅ COMPLETED

### 1. Database Schema Analysis
- Reviewed complete schema for posts, comments, vibes, reactions, mentions, likes
- Identified all FK relationships and composite keys
- Created comprehensive RLS policy SQL file (`MISSING_RLS_POLICIES.sql`)

### 2. Enhanced Data Models Created

#### **New Models:**
- `lib/data/models/social/vibe_model.dart` - VibeModel, PostVibeModel, PostReactionModel
- `lib/data/models/social/mention_model.dart` - PostMentionModel, CommentMentionModel  
- `lib/data/models/social/location_tag_model.dart` - LocationTagModel

#### **Updated Models:**
- **Post** base class (`lib/data/models/social/post.dart`):
  - Added `authorProfileId`, `venueId`, `locationTagId`
  - Added `postVibes` (List of assigned vibes from post_vibes)
  - Added `reactions` (List from post_reactions)
  - Added `mentions` (List from post_mentions)
  - Added `locationTag` (joined location_tags data)
  - Added `mediaMetadata` (full media jsonb array)

- **PostModel** (`lib/data/models/social/post_model.dart`):
  - Updated constructor to accept all new fields
  - Enhanced `fromJson` to parse vibes, reactions, mentions, location tags
  - Parses `post_vibes`, `post_reactions`, `post_mentions` arrays
  - Handles location_tag joins
  - Processes media metadata array

- **CommentModel** (`lib/data/models/social/comment_model.dart`):
  - Added `authorProfileId`, `authorVerified`
  - Added `likeCount`, `isLiked`
  - Added `commentMentions` (joined data)
  - Added `replies` (nested comments)
  - Updated `fromJson` to handle all new fields
  - Now supports threaded replies

### 3. RLS Policies SQL
Created comprehensive SQL file with policies for:
- `posts` - read/write based on visibility
- `post_comments` - read/write with post visibility checks
- `post_likes`, `comment_likes` - like/unlike permissions
- `post_vibes` - author can manage vibes
- `post_reactions` - users can react
- `post_mentions`, `comment_mentions` - mention permissions
- `post_hides` - user can hide posts
- `vibes`, `location_tags` - read-only reference data

**Location:** `/Users/moatazmustapha/Desktop/dabbler/MISSING_RLS_POLICIES.sql`

---

## 🚧 TODO: Enhance SocialService

### Required Supabase Query Updates

#### For `getPost(String postId)`:
```dart
final postResponse = await _supabase
  .from('posts')
  .select('''
    *,
    profiles!author_profile_id(id, user_id, display_name, avatar_url, verified),
    vibe:vibes!primary_vibe_id(id, key, label_en, emoji, color_hex),
    location_tag:location_tags!location_tag_id(id, name, city, country, address),
    post_vibes(
      vibe_id,
      assigned_at,
      vibes:vibe_id(id, key, label_en, emoji, color_hex)
    ),
    post_reactions(
      actor_profile_id,
      vibe_id,
      created_at,
      vibes:vibe_id(id, key, label_en, emoji),
      profiles:actor_profile_id(id, display_name, avatar_url)
    ),
    post_mentions(
      mentioned_profile_id,
      created_at,
      profiles:mentioned_profile_id(id, display_name, username, avatar_url)
    )
  ''')
  .eq('id', postId)
  .maybeSingle();
```

#### For `getComments(String postId)`:
```dart
final allComments = await _supabase
  .from('post_comments')
  .select('''
    *,
    profiles:author_profile_id(user_id, display_name, avatar_url, verified),
    comment_mentions(
      mentioned_profile_id,
      created_at,
      profiles:mentioned_profile_id(id, display_name, username, avatar_url)
    )
  ''')
  .eq('post_id', postId)
  .eq('is_deleted', false)
  .eq('is_hidden_admin', false)
  .order('created_at', ascending: true);
```

---

## 🎨 TODO: Update ThreadScreen UI

### Display Components Needed:

#### 1. **Primary Vibe Badge**
```dart
if (post.vibeEmoji != null)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _getVibeColor(post.primaryVibeId),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(post.vibeEmoji!, style: TextStyle(fontSize: 16)),
        SizedBox(width: 4),
        Text(post.vibeLabel ?? '', style: TextStyle(fontSize: 12)),
      ],
    ),
  )
```

#### 2. **All Vibes List** (from post_vibes)
```dart
if (post.postVibes.isNotEmpty)
  Wrap(
    spacing: 8,
    children: post.postVibes.map((pv) {
      final vibe = pv['vibes'];
      return Chip(
        avatar: Text(vibe['emoji'] ?? ''),
        label: Text(vibe['label_en'] ?? ''),
      );
    }).toList(),
  )
```

#### 3. **Reactions Display** (from post_reactions)
```dart
if (post.reactions.isNotEmpty)
  _buildReactionsSection(post.reactions)

Widget _buildReactionsSection(List<Map<String, dynamic>> reactions) {
  // Group reactions by vibe
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final r in reactions) {
    final vibeId = r['vibe_id'];
    grouped.putIfAbsent(vibeId, () => []).add(r);
  }
  
  return Wrap(
    spacing: 8,
    children: grouped.entries.map((entry) {
      final vibe = entry.value.first['vibes'];
      final count = entry.value.length;
      return GestureDetector(
        onTap: () => _showReactionDetails(entry.value),
        child: Chip(
          avatar: Text(vibe['emoji'] ?? ''),
          label: Text('$count'),
        ),
      );
    }).toList(),
  );
}
```

#### 4. **Mentions Display** (from post_mentions)
```dart
if (post.mentions.isNotEmpty)
  Wrap(
    spacing: 4,
    children: post.mentions.map((m) {
      final profile = m['profiles'];
      return GestureDetector(
        onTap: () => _navigateToProfile(m['mentioned_profile_id']),
        child: Chip(
          avatar: CircleAvatar(
            backgroundImage: NetworkImage(profile['avatar_url'] ?? ''),
          ),
          label: Text('@${profile['username'] ?? profile['display_name']}'),
        ),
      );
    }).toList(),
  )
```

#### 5. **Location Tag Display**
```dart
if (post.locationTag != null)
  Row(
    children: [
      Icon(Icons.location_on, size: 16),
      SizedBox(width: 4),
      Text(
        post.locationTag!['name'] ?? '',
        style: TextStyle(fontSize: 12),
      ),
      if (post.locationTag!['city'] != null)
        Text(' · ${post.locationTag!['city']}'),
    ],
  )
```

#### 6. **Enhanced Comments with Mentions**
```dart
Widget _buildComment(CommentModel comment) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Author info
      _buildCommentHeader(comment),
      // Body with mentions highlighted
      _buildCommentBody(comment),
      // Mentions list if any
      if (comment.commentMentions.isNotEmpty)
        _buildCommentMentions(comment.commentMentions),
      // Like count and reply button
      _buildCommentActions(comment),
      // Nested replies
      if (comment.replies.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(left: 32),
          child: Column(
            children: comment.replies.map(_buildComment).toList(),
          ),
        ),
    ],
  );
}
```

---

## 📝 Implementation Steps

### Step 1: Update SocialService (Priority: HIGH)
File: `lib/features/social/services/social_service.dart`

1. Update `getPost()` method to fetch all joins
2. Update `getComments()` to fetch comment_mentions and nested structure
3. Add helper methods for parsing reactions and vibes
4. Test with actual Supabase data

### Step 2: Create UI Widgets (Priority: HIGH)
Files to create:
- `lib/features/social/presentation/widgets/post/vibe_badge.dart`
- `lib/features/social/presentation/widgets/post/reactions_list.dart`
- `lib/features/social/presentation/widgets/post/mentions_list.dart`
- `lib/features/social/presentation/widgets/post/location_tag_widget.dart`

### Step 3: Update ThreadScreen (Priority: HIGH)
File: `lib/features/social/presentation/screens/social_feed/thread_screen.dart`

1. Add all new widgets to post display section
2. Update comments section to show mentions
3. Add interaction handlers for reactions
4. Test full flow

### Step 4: Apply RLS Policies (Priority: MEDIUM)
1. Review existing policies in Supabase dashboard
2. Apply missing policies from `MISSING_RLS_POLICIES.sql`
3. Test each policy with different user scenarios
4. Verify visibility rules work correctly

### Step 5: Testing (Priority: HIGH)
1. Test post display with all fields populated
2. Test with missing optional fields
3. Test comment threading
4. Test reactions grouping
5. Test mentions navigation

---

## 🔧 Quick Implementation Guide

### To continue implementation:

1. **Update SocialService first** - this is the data layer that feeds everything
2. **Create simple widgets** - start with vibe badge, then reactions
3. **Integrate into ThreadScreen** - add widgets one by one
4. **Test incrementally** - verify each feature works before moving to next

### Testing with Supabase MCP:
```dart
// You can use the Supabase MCP tools to:
// 1. Check existing RLS policies
// 2. Test queries directly
// 3. Verify data structure matches models
```

---

## 📊 Database Fields Reference

### posts table - All Fields Now Supported:
✅ id, author_user_id, author_profile_id  
✅ kind, visibility, link_token  
✅ body, lang, sport  
✅ venue_id, location_tag_id, game_id  
✅ geo_lat, geo_lng  
✅ media (jsonb array)  
✅ like_count, comment_count  
✅ is_deleted, is_hidden_admin  
✅ created_at, updated_at  
✅ primary_vibe_id  
✅ author_display_name  

### Joined Data Now Supported:
✅ post_vibes (all assigned vibes)  
✅ post_reactions (who reacted with what vibe)  
✅ post_mentions (who was mentioned)  
✅ location_tags (location info)  
✅ vibes (vibe details)  
✅ profiles (author & reactor info)  

### post_comments - All Fields Now Supported:
✅ id, post_id  
✅ author_profile_id, author_user_id  
✅ parent_comment_id (threading)  
✅ body  
✅ is_deleted, is_hidden_admin  
✅ created_at  
✅ like_count  

### Joined Comment Data:
✅ comment_mentions  
✅ comment_likes  
✅ profiles  

---

## 🎯 Next Actions

**Immediate (can be done now):**
1. Run `dart run build_runner build -d` to regenerate any generated code
2. Apply the RLS policies from `MISSING_RLS_POLICIES.sql` to your Supabase project
3. Update SocialService queries to fetch joined data
4. Create UI widgets for displaying new fields
5. Test with real data

**Future Enhancements:**
- Add reaction picker UI
- Add mention auto-complete when typing @
- Add location picker when creating posts
- Add vibe selector when creating posts
- Add analytics tracking for reactions
