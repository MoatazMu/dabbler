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
          .from('users')
          .select('display_name')
          .eq('id', user.id)
          .single();

      // Check for duplicate posts to prevent spam/reposting
      await _checkForDuplicatePost(user.id, content, mediaUrls);

      final postData = {
        'author_id': user.id,
        'content': content,
        'media_urls': mediaUrls,
        'location_name': locationName,
        'visibility': visibility.name,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'likes_count': 0,
        'comments_count': 0,
        'shares_count': 0,
      };
      // Insert the post (don't try to join to a view via FK — views don't have FK constraints)
      final inserted = await _supabase
          .from('posts')
          .insert(postData)
          .select()
          .single();

      // Fetch the author profile from the users table separately
      final profile = await _supabase
          .from('users')
          .select('display_name, avatar_url, id')
          .eq('id', user.id)
          .maybeSingle();

      // Merge the inserted post and the profile into the shape expected by PostModel
      final insertedMap = Map<String, dynamic>.from(inserted as Map);
      insertedMap['profiles'] = profile;

      final response = insertedMap;

      return PostModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get posts for the social feed
  Future<List<PostModel>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // First, get posts without joins
      final postsResponse = await _supabase
          .from('posts')
          .select('*')
          .eq('visibility', 'public')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Get unique author IDs
      final authorIds = postsResponse
          .map((post) => post['author_id'] as String)
          .toSet()
          .toList();

      // Fetch all required profiles in batch
      final profilesResponse = await _supabase
          .from('users')
          .select('id, display_name, avatar_url')
          .inFilter('id', authorIds);

      // Create a map for quick profile lookup
      final profilesMap = <String, Map<String, dynamic>>{};
      for (final profile in profilesResponse) {
        profilesMap[profile['id']] = profile;
      }

      // Merge posts with their profiles
      final enrichedPosts = postsResponse.map((post) {
        final authorId = post['author_id'] as String;
        final profile = profilesMap[authorId];
        
        return {
          ...post,
          'profiles': profile,
        };
      }).toList();

      return enrichedPosts.map<PostModel>((json) => PostModel.fromJson(json)).toList();
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
      // First, get posts without joins
      final postsResponse = await _supabase
          .from('posts')
          .select('*')
          .eq('author_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Get the user profile
      final profileResponse = await _supabase
          .from('users')
          .select('id, display_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      // Merge posts with profile
      final enrichedPosts = postsResponse.map((post) {
        return {
          ...post,
          'profiles': profileResponse,
        };
      }).toList();

      return enrichedPosts.map<PostModel>((json) => PostModel.fromJson(json)).toList();
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
        await _supabase.rpc('decrement_likes_count', params: {
          'post_id': postId,
        });
      } else {
        // Like: Add the like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Increment likes count
        await _supabase.rpc('increment_likes_count', params: {
          'post_id': postId,
        });
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
        final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        
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
    List<String> mediaUrls
  ) async {
    try {
      // Define time window for duplicate checking (e.g., 5 minutes)
      final timeWindow = DateTime.now().subtract(const Duration(minutes: 5));
      
      // Check for exact content duplicates from the same user in recent time
      final duplicateContentCheck = await _supabase
          .from('posts')
          .select('id, created_at')
          .eq('author_id', userId)
          .eq('content', content)
          .gte('created_at', timeWindow.toIso8601String())
          .limit(1);

      if (duplicateContentCheck.isNotEmpty) {
        throw Exception('You recently posted the same content. Please wait before posting again.');
      }

      // Check for rapid posting from the same user (rate limiting)
      final recentPostsCheck = await _supabase
          .from('posts')
          .select('id, created_at')
          .eq('author_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String())
          .limit(3); // Allow max 3 posts per minute

      if (recentPostsCheck.length >= 3) {
        throw Exception('You are posting too frequently. Please wait a moment before posting again.');
      }

      // If content is very short and no media, check for identical recent posts
      if (content.trim().length < 10 && mediaUrls.isEmpty) {
        final shortContentCheck = await _supabase
            .from('posts')
            .select('id')
            .eq('author_id', userId)
            .eq('content', content.trim())
            .gte('created_at', DateTime.now().subtract(const Duration(hours: 1)).toIso8601String())
            .limit(1);

        if (shortContentCheck.isNotEmpty) {
          throw Exception('You already posted this content recently. Please create a new post with different content.');
        }
      }

    } catch (e) {
      // Re-throw the exception to be handled by the calling method
      rethrow;
    }
  }
}