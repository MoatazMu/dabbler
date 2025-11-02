import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/post_model.dart';
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

      // Get user profile information (for validation - profile should exist)
      await _supabase
          .from('profiles')
          .select('display_name')
          .eq('user_id', user.id)
          .single();

      // Check for duplicate posts to prevent spam/reposting
      await _checkForDuplicatePost(user.id, content, mediaUrls);

      // Map to actual database schema
      final postData = {
        // Required fields - author_user_id and author_profile_id handled by RLS/triggers
        'kind': 'moment', // Default post type
        'visibility': visibility.name,
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

      // Fetch the author profile from the profiles table separately
      final profile = await _supabase
          .from('profiles')
          .select('user_id, display_name, avatar_url, verified')
          .eq('user_id', user.id)
          .maybeSingle();

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
        'profiles': profile != null
            ? {
                'id': profile['user_id'],
                'display_name': profile['display_name'],
                'avatar_url': profile['avatar_url'],
                'verified': profile['verified'],
              }
            : null,
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
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike: Remove the like
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);

        // Decrement likes count
        await _supabase.rpc(
          'decrement_likes_count',
          params: {'post_id': postId},
        );
      } else {
        // Like: Add the like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Increment likes count
        await _supabase.rpc(
          'increment_likes_count',
          params: {'post_id': postId},
        );
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
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
