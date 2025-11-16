import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/data/models/social/post_model.dart';
import '../../../utils/enums/social_enums.dart';

class SocialService {
  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;
  SocialService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new post
  Future<PostModel> createPost({
    required String content,
    List<String> mediaUrls = const [],
    String? locationName,
    PostVisibility visibility = PostVisibility.public,
    List<String> tags = const [],
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile information (for validation and to get profile ID)
      final userProfile = await _supabase
          .from('profiles')
          .select('id, user_id, display_name, avatar_url, verified')
          .eq('user_id', user.id)
          .single();

      // Check for duplicate posts to prevent spam/reposting
      await _checkForDuplicatePost(user.id, content, mediaUrls);

      // Map domain visibility enum to DB `posts.visibility` values.
      // DB allowed values: 'public', 'circle', 'link', 'private'.
      String dbVisibility;
      switch (visibility) {
        case PostVisibility.public:
          dbVisibility = 'public';
          break;
        case PostVisibility.friends:
          dbVisibility = 'circle';
          break;
        case PostVisibility.private:
          dbVisibility = 'private';
          break;
        case PostVisibility.gameParticipants:
          // For now, map to 'link' (shareable-by-link style posts).
          dbVisibility = 'link';
          break;
      }

      // Map to actual database schema
      final postData = {
        // Required fields - must be set explicitly
        'author_user_id': user.id, // REQUIRED: Set the user ID
        'author_profile_id': userProfile['id'], // REQUIRED: Set the profile ID
        'kind': 'moment', // Default post type
        'visibility': dbVisibility,
        'body': content, // Map content -> body
        'media': mediaUrls
            .map((url) => {'url': url})
            .toList(), // Map to media array format
        // Optional fields
        if (locationName != null) 'venue_id': locationName,
        // Stats fields default on server side
        // Timestamps handled by server
      };

      // Insert the post using actual database schema
      final inserted = await _supabase
          .from('posts')
          .insert(postData)
          .select()
          .single();

      // Transform database response to PostModel format
      final transformedPost = {
        'id': inserted['id'],
        'author_id':
            inserted['author_user_id'], // Map author_user_id -> author_id
        'content': inserted['body'] ?? '', // Map body -> content
        'media_urls': inserted['media'] ?? [], // Map media array -> media_urls
        'visibility': inserted['visibility'],
        'created_at': inserted['created_at'],
        'updated_at': inserted['updated_at'],
        'likes_count': inserted['like_count'] ?? 0,
        'comments_count': inserted['comment_count'] ?? 0,
        'shares_count': 0,
        'location_name': inserted['venue_id'],
        'tags': tags,
        'profiles': {
          'id': userProfile['user_id'],
          'display_name': userProfile['display_name'],
          'avatar_url': userProfile['avatar_url'],
          'verified': userProfile['verified'],
        },
      };

      return PostModel.fromJson(transformedPost);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get posts for the social feed
  Future<List<PostModel>> getFeedPosts({int limit = 20, int offset = 0}) async {
    try {
      // Query posts using actual database schema
      final postsResponse = await _supabase
          .from('posts')
          .select('*')
          .eq('visibility', 'public')
          .eq('is_deleted', false)
          .eq('is_hidden_admin', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Get unique author IDs from actual field name
      final authorIds = postsResponse
          .map((post) => post['author_user_id'] as String)
          .toSet()
          .toList();

      // Fetch all required profiles in batch
      final profilesResponse = await _supabase
          .from('profiles')
          .select('user_id, display_name, avatar_url, verified')
          .inFilter('user_id', authorIds);

      // Create a map for quick profile lookup
      final profilesMap = <String, Map<String, dynamic>>{};
      for (final profile in profilesResponse) {
        profilesMap[profile['user_id']] = profile;
      }

      // Transform database posts to match PostModel expectations
      final enrichedPosts = postsResponse.map((post) {
        final authorId = post['author_user_id'] as String;
        final profile = profilesMap[authorId];

        // Extract media URLs from media array
        List<String> mediaUrls = [];
        final mediaArray = post['media'];
        if (mediaArray is List) {
          for (var mediaItem in mediaArray) {
            if (mediaItem is Map && mediaItem['url'] != null) {
              mediaUrls.add(mediaItem['url'].toString());
            } else if (mediaItem is String) {
              mediaUrls.add(mediaItem);
            }
          }
        }

        // Transform database schema to PostModel schema
        return {
          'id': post['id'],
          'author_id':
              post['author_user_id'], // Map author_user_id -> author_id
          'content': post['body'] ?? '', // Map body -> content
          'media_urls': mediaUrls, // Extract URLs from media array
          'visibility': post['visibility'],
           // Pass through kind and primary_vibe_id so PostModel can surface them.
          'kind': post['kind'],
          'primary_vibe_id': post['primary_vibe_id'],
          'created_at': post['created_at'],
          'updated_at': post['updated_at'],
          'likes_count':
              post['like_count'] ?? 0, // Map like_count -> likes_count
          'comments_count':
              post['comment_count'] ?? 0, // Map comment_count -> comments_count
          'shares_count': 0, // Not in database, default to 0
          'location_name': post['venue_id'], // Could be mapped differently
          'tags': [], // Not directly in schema
          'profiles': profile != null
              ? {
                  'id': profile['user_id'],
                  'display_name': profile['display_name'],
                  'avatar_url': profile['avatar_url'],
                  'verified': profile['verified'],
                }
              : null,
        };
      }).toList();

      return enrichedPosts
          .map<PostModel>((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load feed posts: $e');
    }
  }

  /// Get posts by a specific user
  Future<List<PostModel>> getUserPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Query posts using actual database schema
      final postsResponse = await _supabase
          .from('posts')
          .select('*')
          .eq('author_user_id', userId) // Use correct field name
          .eq('is_deleted', false)
          .eq('is_hidden_admin', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Get the user profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('user_id, display_name, avatar_url, verified')
          .eq('user_id', userId)
          .maybeSingle();

      // Transform database posts to match PostModel expectations
      final enrichedPosts = postsResponse.map((post) {
        // Extract media URLs from media array
        List<String> mediaUrls = [];
        final mediaArray = post['media'];
        if (mediaArray is List) {
          for (var mediaItem in mediaArray) {
            if (mediaItem is Map && mediaItem['url'] != null) {
              mediaUrls.add(mediaItem['url'].toString());
            } else if (mediaItem is String) {
              mediaUrls.add(mediaItem);
            }
          }
        }

        return {
          'id': post['id'],
          'author_id':
              post['author_user_id'], // Map author_user_id -> author_id
          'content': post['body'] ?? '', // Map body -> content
          'media_urls': mediaUrls, // Extract URLs from media array
          'visibility': post['visibility'],
          'kind': post['kind'],
          'primary_vibe_id': post['primary_vibe_id'],
          'created_at': post['created_at'],
          'updated_at': post['updated_at'],
          'likes_count':
              post['like_count'] ?? 0, // Map like_count -> likes_count
          'comments_count':
              post['comment_count'] ?? 0, // Map comment_count -> comments_count
          'shares_count': 0, // Not in database, default to 0
          'location_name': post['venue_id'], // Could be mapped differently
          'tags': [], // Not directly in schema
          'profiles': profileResponse != null
              ? {
                  'id': profileResponse['user_id'],
                  'display_name': profileResponse['display_name'],
                  'avatar_url': profileResponse['avatar_url'],
                  'verified': profileResponse['verified'],
                }
              : null,
        };
      }).toList();

      return enrichedPosts
          .map<PostModel>((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user posts: $e');
    }
  }

  /// Get a single post by ID with joined profile data.
  Future<PostModel> getPostById(String postId) async {
    try {
      // Fetch the post row
      final post = await _supabase
          .from('posts')
          .select('*')
          .eq('id', postId)
          .eq('is_deleted', false)
          .eq('is_hidden_admin', false)
          .maybeSingle();

      if (post == null) {
        throw Exception('Post not found');
      }

      final authorId = post['author_user_id'] as String;

      // Fetch author profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('user_id, display_name, avatar_url, verified')
          .eq('user_id', authorId)
          .maybeSingle();

      // Extract media URLs from media array
      List<String> mediaUrls = [];
      final mediaArray = post['media'];
      if (mediaArray is List) {
        for (var mediaItem in mediaArray) {
          if (mediaItem is Map && mediaItem['url'] != null) {
            mediaUrls.add(mediaItem['url'].toString());
          } else if (mediaItem is String) {
            mediaUrls.add(mediaItem);
          }
        }
      }

      final enriched = {
        'id': post['id'],
        'author_id': post['author_user_id'],
        'content': post['body'] ?? '',
        'media_urls': mediaUrls,
        'visibility': post['visibility'],
        'kind': post['kind'],
        'primary_vibe_id': post['primary_vibe_id'],
        'created_at': post['created_at'],
        'updated_at': post['updated_at'],
        'likes_count': post['like_count'] ?? 0,
        'comments_count': post['comment_count'] ?? 0,
        'shares_count': 0,
        'location_name': post['venue_id'],
        'tags': [],
        'profiles': profileResponse != null
            ? {
                'id': profileResponse['user_id'],
                'display_name': profileResponse['display_name'],
                'avatar_url': profileResponse['avatar_url'],
                'verified': profileResponse['verified'],
              }
            : null,
      };

      return PostModel.fromJson(enriched);
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }

  /// Like/unlike a post
  Future<void> toggleLike(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already liked
      final existingLike = await _supabase
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike: Remove the like (trigger will decrement like_count automatically)
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        // Like: Add the like (trigger will increment like_count automatically)
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Hide a post for the current user (post_hides).
  Future<void> hidePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('post_hides').upsert({
        'post_id': postId,
        'owner_user_id': user.id,
      });
    } catch (e) {
      throw Exception('Failed to hide post: $e');
    }
  }

  /// Unhide a post for the current user.
  Future<void> unhidePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('post_hides')
          .delete()
          .eq('post_id', postId)
          .eq('owner_user_id', user.id);
    } catch (e) {
      throw Exception('Failed to unhide post: $e');
    }
  }

  /// Get IDs of posts hidden by the current user.
  Future<Set<String>> getHiddenPostIdsForCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return <String>{};
      }

      final rows = await _supabase
          .from('post_hides')
          .select('post_id')
          .eq('owner_user_id', user.id);

      return rows
          .map((row) => row['post_id']?.toString())
          .whereType<String>()
          .toSet();
    } catch (e) {
      throw Exception('Failed to load hidden posts: $e');
    }
  }

  /// Add a comment to a post
  Future<Map<String, dynamic>> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      // Insert comment (trigger will increment comment_count automatically)
      final comment = await _supabase
          .from('post_comments')
          .insert({
            'post_id': postId,
            'author_user_id': user.id,
            'author_profile_id': profile['id'],
            'body': body,
            if (parentCommentId != null) 'parent_comment_id': parentCommentId,
          })
          .select()
          .single();

      return comment;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a post with nested replies
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      // Fetch all comments for the post (including replies)
      final allComments = await _supabase
          .from('post_comments')
          .select(
            '*, profiles:author_profile_id(user_id, display_name, avatar_url, verified)',
          )
          .eq('post_id', postId)
          .eq('is_deleted', false)
          .eq('is_hidden_admin', false)
          .order('created_at', ascending: true);

      final commentsList = List<Map<String, dynamic>>.from(allComments);
      
      // Build nested structure: separate top-level comments from replies
      final topLevelComments = <Map<String, dynamic>>[];
      final repliesMap = <String, List<Map<String, dynamic>>>{};
      
      for (final comment in commentsList) {
        final parentId = comment['parent_comment_id'] as String?;
        
        if (parentId == null) {
          // Top-level comment
          topLevelComments.add(comment);
        } else {
          // Reply - add to replies map
          repliesMap.putIfAbsent(parentId, () => []).add(comment);
        }
      }
      
      // Attach replies to their parent comments
      for (final comment in topLevelComments) {
        final commentId = comment['id'] as String;
        if (repliesMap.containsKey(commentId)) {
          comment['replies'] = repliesMap[commentId]!;
        } else {
          comment['replies'] = <Map<String, dynamic>>[];
        }
      }
      
      return topLevelComments;
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Soft delete (trigger will decrement comment_count automatically)
      await _supabase
          .from('post_comments')
          .update({'is_deleted': true})
          .eq('id', commentId)
          .eq('author_user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Report a post (post_reports).
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final trimmedReason = reason.trim();
      if (trimmedReason.length < 3 || trimmedReason.length > 140) {
        throw Exception('Reason must be between 3 and 140 characters');
      }

      await _supabase.from('post_reports').insert({
        'post_id': postId,
        'reporter_user_id': user.id,
        'reason': trimmedReason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
        'status': 'open',
      });
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  /// Upload images to Supabase Storage
  Future<List<String>> uploadImages(List<String> imagePaths) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final List<String> uploadedUrls = [];

      for (final imagePath in imagePaths) {
        final fileName =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        await _supabase.storage
            .from('post-images')
            .upload(fileName, File(imagePath));

        final publicUrl = _supabase.storage
            .from('post-images')
            .getPublicUrl(fileName);

        uploadedUrls.add(publicUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // -----------------------------------------------------------------------------
  // VIBES
  // -----------------------------------------------------------------------------

  /// Get all active vibes (basic catalog).
  Future<List<Map<String, dynamic>>> getVibes() async {
    try {
      final rows = await _supabase
          .from('vibes')
          .select('id, key, label, emoji, color, is_active')
          .eq('is_active', true)
          .order('label');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      throw Exception('Failed to load vibes: $e');
    }
  }

  /// Get vibes assigned to a post (via post_vibes).
  Future<List<Map<String, dynamic>>> getPostVibes(String postId) async {
    try {
      final rows = await _supabase
          .from('post_vibes')
          .select('vibe_id, assigned_at, vibes:vibe_id(id, key, label, emoji, color)')
          .eq('post_id', postId)
          .order('assigned_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      throw Exception('Failed to load post vibes: $e');
    }
  }

  /// Set primary vibe on posts.primary_vibe_id.
  Future<void> setPrimaryVibe({
    required String postId,
    required String vibeId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      await _supabase
          .from('posts')
          .update({'primary_vibe_id': vibeId})
          .eq('id', postId)
          .eq('author_user_id', user.id);
    } catch (e) {
      throw Exception('Failed to set primary vibe: $e');
    }
  }

  /// Toggle a vibe membership in post_vibes (add/remove).
  Future<void> togglePostVibe({
    required String postId,
    required String vibeId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      // Check if exists
      final existing = await _supabase
          .from('post_vibes')
          .select('post_id, vibe_id')
          .eq('post_id', postId)
          .eq('vibe_id', vibeId)
          .maybeSingle();
      if (existing != null) {
        await _supabase
            .from('post_vibes')
            .delete()
            .eq('post_id', postId)
            .eq('vibe_id', vibeId);
      } else {
        await _supabase.from('post_vibes').insert({
          'post_id': postId,
          'vibe_id': vibeId,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle post vibe: $e');
    }
  }
  /// Check for duplicate posts to prevent spam/reposting
  Future<void> _checkForDuplicatePost(
    String userId,
    String content,
    List<String> mediaUrls,
  ) async {
    try {
      // Define time window for duplicate checking (e.g., 5 minutes)
      final timeWindow = DateTime.now().subtract(const Duration(minutes: 5));

      // Check for exact content duplicates from the same user in recent time
      // Using correct field names: author_user_id and body
      final duplicateContentCheck = await _supabase
          .from('posts')
          .select('id, created_at')
          .eq('author_user_id', userId) // Correct field name
          .eq('body', content) // Correct field name
          .gte('created_at', timeWindow.toIso8601String())
          .limit(1);

      if (duplicateContentCheck.isNotEmpty) {
        throw Exception(
          'You recently posted the same content. Please wait before posting again.',
        );
      }

      // Check for rapid posting from the same user (rate limiting)
      final recentPostsCheck = await _supabase
          .from('posts')
          .select('id, created_at')
          .eq('author_user_id', userId) // Correct field name
          .gte(
            'created_at',
            DateTime.now()
                .subtract(const Duration(minutes: 1))
                .toIso8601String(),
          )
          .limit(3); // Allow max 3 posts per minute

      if (recentPostsCheck.length >= 3) {
        throw Exception(
          'You are posting too frequently. Please wait a moment before posting again.',
        );
      }

      // If content is very short and no media, check for identical recent posts
      if (content.trim().length < 10 && mediaUrls.isEmpty) {
        final shortContentCheck = await _supabase
            .from('posts')
            .select('id')
            .eq('author_user_id', userId) // Correct field name
            .eq('body', content.trim()) // Correct field name
            .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
            )
            .limit(1);

        if (shortContentCheck.isNotEmpty) {
          throw Exception(
            'You already posted this content recently. Please create a new post with different content.',
          );
        }
      }
    } catch (e) {
      // Re-throw the exception to be handled by the calling method
      rethrow;
    }
  }
}
