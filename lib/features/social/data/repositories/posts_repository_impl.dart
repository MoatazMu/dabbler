import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../utils/enums/social_enums.dart'; // For PostVisibility and ReactionType
import '../../domain/entities/reaction.dart';
import '../../domain/repositories/posts_repository.dart';
import '../models/post_model.dart';
import '../models/social_feed_model.dart';
import '../models/reaction_model.dart';
import '../datasources/posts_remote_data_source.dart';

/// Custom exceptions for posts operations
class PostsServerException implements Exception {
  final String message;
  PostsServerException(this.message);
}

class PostsCacheException implements Exception {
  final String message;
  PostsCacheException(this.message);
}

class PostNotFoundException implements Exception {
  final String message;
  PostNotFoundException(this.message);
}

class PostValidationException implements Exception {
  final String message;
  PostValidationException(this.message);
}

class MediaUploadException implements Exception {
  final String message;
  MediaUploadException(this.message);
}

class UnauthorizedPostActionException implements Exception {
  final String message;
  UnauthorizedPostActionException(this.message);
}

/// Custom failure types for posts
abstract class PostsFailure extends Failure {
  const PostsFailure({required super.message, super.code, super.details});
}

class PostsServerFailure extends PostsFailure {
  const PostsServerFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Posts server error');
}

class PostsCacheFailure extends PostsFailure {
  const PostsCacheFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Posts cache error');
}

class PostNotFoundFailure extends PostsFailure {
  const PostNotFoundFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Post not found');
}

class PostValidationFailure extends PostsFailure {
  const PostValidationFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Post validation error');
}

class MediaUploadFailure extends PostsFailure {
  const MediaUploadFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Media upload error');
}

class UnauthorizedPostActionFailure extends PostsFailure {
  const UnauthorizedPostActionFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Unauthorized post action');
}

class UnknownPostsFailure extends PostsFailure {
  const UnknownPostsFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Unknown posts error');
}

/// Implementation of PostsRepository with caching and optimistic updates
class PostsRepositoryImpl implements PostsRepository {
  final PostsRemoteDataSource remoteDataSource;

  // In-memory caching
  final Map<String, SocialFeedModel> _feedCache = {};
  final Map<String, PostModel> _postsCache = {};
  final Map<String, List<PostModel>> _userPostsCache = {};
  final Map<String, List<PostModel>> _gamePostsCache = {};
  final Map<String, List<PostModel>> _commentsCache = {};
  final Map<String, List<ReactionModel>> _reactionsCache = {};
  final Map<String, List<PostModel>> _bookmarksCache = {};
  
  // Cache TTL
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _feedCacheDuration = Duration(minutes: 3);
  static const Duration _postCacheDuration = Duration(minutes: 10);
  static const Duration _reactionsCacheDuration = Duration(minutes: 1);

  // Optimistic updates
  final Map<String, PostModel> _optimisticPosts = {};
  final Map<String, ReactionModel> _optimisticReactions = {};
  final Set<String> _optimisticBookmarks = {};
  final Set<String> _optimisticLikes = {};

  PostsRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, SocialFeedModel>> getSocialFeed({
    FeedType feedType = FeedType.home,
    String? gameId,
    String? authorId,
    PostVisibility? visibility,
    int page = 1,
    int limit = 20,
    SortField sortBy = SortField.createdAt,
    SortDirection sortDirection = SortDirection.desc,
    Duration? maxAge,
  }) async {
    try {
      // Generate cache key
      final cacheKey = _generateFeedCacheKey(
        feedType: feedType,
        gameId: gameId,
        authorId: authorId,
        visibility: visibility,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortDirection: sortDirection,
        maxAge: maxAge,
      );

      // Check cache first
      if (_isCacheValid(cacheKey, _feedCacheDuration)) {
        final cached = _feedCache[cacheKey];
        if (cached != null && cached.isCacheValid()) {
          return Right(_applyFeedOptimizations(cached));
        }
      }

      // Fetch from remote
      final feed = await remoteDataSource.getSocialFeed(
        feedType: feedType,
        gameId: gameId,
        authorId: authorId,
        visibility: visibility,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortDirection: sortDirection,
        maxAge: maxAge,
      );

      // Update cache
      _feedCache[cacheKey] = feed;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Cache individual posts
      for (final post in feed.posts) {
        _postsCache[post.id] = post;
      }

      return Right(_applyFeedOptimizations(feed));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } on PostsCacheException catch (e) {
      return Left(PostsCacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get social feed: $e'));
    }
  }

  @override
  Future<Either<Failure, PostModel>> createPost({
    required String content,
    List<String>? mediaUrls,
    PostVisibility visibility = PostVisibility.public,
    String? gameId,
    String? locationName,
    List<String>? tags,
    List<String>? mentionedUsers,
    String? replyToPostId,
    String? shareOriginalId,
  }) async {
    try {
      // Validate input
      if (content.trim().isEmpty && (mediaUrls?.isEmpty ?? true)) {
        return Left(PostValidationFailure(message: 'Post content or media is required'));
      }

      // Create optimistic post
      final optimisticPost = PostModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        authorId: await _getCurrentUserId(),
        authorName: await _getCurrentUserName(),
        authorAvatar: await _getCurrentUserAvatar(),
        content: content,
        mediaUrls: mediaUrls ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        visibility: visibility,
        gameId: gameId,
        locationName: locationName,
        tags: tags ?? [],
        mentionedUsers: mentionedUsers ?? [],
        replyToPostId: replyToPostId,
        shareOriginalId: shareOriginalId,
      );

      _optimisticPosts[optimisticPost.id] = optimisticPost;

      // Create post remotely
      final post = await remoteDataSource.createPost(
        content: content,
        mediaUrls: mediaUrls,
        visibility: visibility,
        gameId: gameId,
        locationName: locationName,
        tags: tags,
        mentionedUsers: mentionedUsers,
        replyToPostId: replyToPostId,
        shareOriginalId: shareOriginalId,
      );

      // Remove optimistic update and update cache
      _optimisticPosts.remove(optimisticPost.id);
      _postsCache[post.id] = post;
      _invalidateFeedCaches();

      return Right(post);
    } on PostValidationException catch (e) {
      return Left(PostValidationFailure(message: e.message));
    } on MediaUploadException catch (e) {
      return Left(MediaUploadFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to create post: $e'));
    }
  }

  @override
  Future<Either<Failure, PostModel>> getPost(String postId) async {
    try {
      // Check cache first
      if (_postsCache.containsKey(postId)) {
        final cached = _postsCache[postId];
        if (cached != null) {
          return Right(cached);
        }
      }

      // Fetch from remote
      final post = await remoteDataSource.getPost(postId);
      
      // Update cache
      _postsCache[postId] = post;

      return Right(post);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get post: $e'));
    }
  }

  @override
  Future<Either<Failure, PostModel>> updatePost({
    required String postId,
    String? content,
    List<String>? mediaUrls,
    PostVisibility? visibility,
    List<String>? tags,
    List<String>? mentionedUsers,
  }) async {
    try {
      final post = await remoteDataSource.updatePost(
        postId: postId,
        content: content,
        mediaUrls: mediaUrls,
        visibility: visibility,
        tags: tags,
        mentionedUsers: mentionedUsers,
      );

      // Update cache
      _postsCache[postId] = post;
      _invalidateFeedCaches();

      return Right(post);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on UnauthorizedPostActionException catch (e) {
      return Left(UnauthorizedPostActionFailure(message: e.message));
    } on PostValidationException catch (e) {
      return Left(PostValidationFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to update post: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePost(String postId) async {
    try {
      final success = await remoteDataSource.deletePost(postId);
      
      if (success) {
        _postsCache.remove(postId);
        _invalidateFeedCaches();
      }

      return Right(success);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on UnauthorizedPostActionException catch (e) {
      return Left(UnauthorizedPostActionFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to delete post: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
    PostVisibility? visibility,
  }) async {
    try {
      final cacheKey = 'user_posts_${userId}_${page}_${limit}_${visibility?.toString() ?? 'all'}';
      
      if (_isCacheValid(cacheKey, _postCacheDuration)) {
        final cached = _userPostsCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final posts = await remoteDataSource.getUserPosts(
        userId,
        page: page,
        limit: limit,
        visibility: visibility,
      );

      _userPostsCache[cacheKey] = posts;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Cache individual posts
      for (final post in posts) {
        _postsCache[post.id] = post;
      }

      return Right(posts);
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get user posts: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getGamePosts(
    String gameId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final cacheKey = 'game_posts_${gameId}_${page}_$limit';
      
      if (_isCacheValid(cacheKey, _postCacheDuration)) {
        final cached = _gamePostsCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final posts = await remoteDataSource.getGamePosts(
        gameId,
        page: page,
        limit: limit,
      );

      _gamePostsCache[cacheKey] = posts;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(posts);
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get game posts: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> searchPosts(
    String query, {
    int page = 1,
    int limit = 20,
    PostVisibility? visibility,
    String? gameId,
    List<String>? tags,
  }) async {
    try {
      final posts = await remoteDataSource.searchPosts(
        query,
        page: page,
        limit: limit,
        visibility: visibility,
        gameId: gameId,
        tags: tags,
      );

      return Right(posts);
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to search posts: $e'));
    }
  }

  @override
  Future<Either<Failure, ReactionModel>> reactToPost({
    required String postId,
    required ReactionType reactionType,
  }) async {
    try {
      // Optimistic update
      final optimisticReaction = ReactionModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: await _getCurrentUserId(),
        targetId: postId,
        targetType: ReactionTargetType.post,
        reactionType: reactionType,
        createdAt: DateTime.now(),
        userName: await _getCurrentUserName(),
      );

      _optimisticReactions[postId] = optimisticReaction;
      _optimisticLikes.add(postId);

      // Update cached post optimistically
      if (_postsCache.containsKey(postId)) {
        final post = _postsCache[postId]!;
        _postsCache[postId] = PostModel(
          id: post.id,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          content: post.content,
          mediaUrls: post.mediaUrls,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          likesCount: post.likesCount + 1,
          commentsCount: post.commentsCount,
          sharesCount: post.sharesCount,
          visibility: post.visibility,
          isLiked: true,
          gameId: post.gameId,
          locationName: post.locationName,
          isBookmarked: post.isBookmarked,
          authorBio: post.authorBio,
          authorVerified: post.authorVerified,
          tags: post.tags,
          mentionedUsers: post.mentionedUsers,
          isEdited: post.isEdited,
          editedAt: post.editedAt,
          replyToPostId: post.replyToPostId,
          shareOriginalId: post.shareOriginalId,
        );
      }

      final reaction = await remoteDataSource.reactToPost(
        postId: postId,
        reactionType: reactionType,
      );

      // Remove optimistic update
      _optimisticReactions.remove(postId);
      _optimisticLikes.remove(postId);

      // Invalidate reactions cache
      _invalidateReactionsCache(postId);

      return Right(reaction);
    } on PostNotFoundException catch (e) {
      _optimisticReactions.remove(postId);
      _optimisticLikes.remove(postId);
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      _optimisticReactions.remove(postId);
      _optimisticLikes.remove(postId);
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      _optimisticReactions.remove(postId);
      _optimisticLikes.remove(postId);
      return Left(UnknownPostsFailure(message: 'Failed to react to post: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeReactionFromPost(String postId) async {
    try {
      final success = await remoteDataSource.removeReactionFromPost(postId);
      
      if (success) {
        _optimisticReactions.remove(postId);
        _optimisticLikes.remove(postId);
        _invalidateReactionsCache(postId);

        // Update cached post
        if (_postsCache.containsKey(postId)) {
          final post = _postsCache[postId]!;
          _postsCache[postId] = PostModel(
            id: post.id,
            authorId: post.authorId,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            content: post.content,
            mediaUrls: post.mediaUrls,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            likesCount: (post.likesCount - 1).clamp(0, double.infinity).toInt(),
            commentsCount: post.commentsCount,
            sharesCount: post.sharesCount,
            visibility: post.visibility,
            isLiked: false,
            gameId: post.gameId,
            locationName: post.locationName,
            isBookmarked: post.isBookmarked,
            authorBio: post.authorBio,
            authorVerified: post.authorVerified,
            tags: post.tags,
            mentionedUsers: post.mentionedUsers,
            isEdited: post.isEdited,
            editedAt: post.editedAt,
            replyToPostId: post.replyToPostId,
            shareOriginalId: post.shareOriginalId,
          );
        }
      }

      return Right(success);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to remove reaction from post: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ReactionModel>>> getPostReactions(
    String postId, {
    ReactionType? reactionType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final cacheKey = 'reactions_${postId}_${reactionType?.toString() ?? 'all'}_${page}_$limit';
      
      if (_isCacheValid(cacheKey, _reactionsCacheDuration)) {
        final cached = _reactionsCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final reactions = await remoteDataSource.getPostReactions(
        postId,
        reactionType: reactionType,
        page: page,
        limit: limit,
      );

      _reactionsCache[cacheKey] = reactions;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(reactions);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get post reactions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GroupedReaction>>> getGroupedPostReactions(
    String postId,
  ) async {
    try {
      final groupedReactions = await remoteDataSource.getGroupedPostReactions(postId);
      return Right(groupedReactions);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get grouped post reactions: $e'));
    }
  }

  @override
  Future<Either<Failure, PostModel>> commentOnPost({
    required String postId,
    required String content,
    List<String>? mediaUrls,
    List<String>? mentionedUsers,
  }) async {
    try {
      final comment = await remoteDataSource.commentOnPost(
        postId: postId,
        content: content,
        mediaUrls: mediaUrls,
        mentionedUsers: mentionedUsers,
      );

      // Invalidate comments cache
      _invalidateCommentsCache(postId);

      // Update post comments count in cache
      if (_postsCache.containsKey(postId)) {
        final post = _postsCache[postId]!;
        _postsCache[postId] = PostModel(
          id: post.id,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          content: post.content,
          mediaUrls: post.mediaUrls,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount + 1,
          sharesCount: post.sharesCount,
          visibility: post.visibility,
          isLiked: post.isLiked,
          gameId: post.gameId,
          locationName: post.locationName,
          isBookmarked: post.isBookmarked,
          authorBio: post.authorBio,
          authorVerified: post.authorVerified,
          tags: post.tags,
          mentionedUsers: post.mentionedUsers,
          isEdited: post.isEdited,
          editedAt: post.editedAt,
          replyToPostId: post.replyToPostId,
          shareOriginalId: post.shareOriginalId,
        );
      }

      return Right(comment);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostValidationException catch (e) {
      return Left(PostValidationFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to comment on post: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getPostComments(
    String postId, {
    int page = 1,
    int limit = 20,
    SortDirection sortDirection = SortDirection.asc,
  }) async {
    try {
      final cacheKey = 'comments_${postId}_${page}_${limit}_${sortDirection.toString()}';
      
      if (_isCacheValid(cacheKey, _postCacheDuration)) {
        final cached = _commentsCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final comments = await remoteDataSource.getPostComments(
        postId,
        page: page,
        limit: limit,
        sortDirection: sortDirection,
      );

      _commentsCache[cacheKey] = comments;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(comments);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get post comments: $e'));
    }
  }

  @override
  Future<Either<Failure, ReactionModel>> reactToComment({
    required String commentId,
    required ReactionType reactionType,
  }) async {
    try {
      final reaction = await remoteDataSource.reactToComment(
        commentId: commentId,
        reactionType: reactionType,
      );

      return Right(reaction);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to react to comment: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeReactionFromComment(String commentId) async {
    try {
      final success = await remoteDataSource.removeReactionFromComment(commentId);
      return Right(success);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to remove reaction from comment: $e'));
    }
  }

  @override
  Future<Either<Failure, PostModel>> sharePost({
    required String originalPostId,
    String? content,
    PostVisibility visibility = PostVisibility.public,
  }) async {
    try {
      final sharedPost = await remoteDataSource.sharePost(
        originalPostId: originalPostId,
        content: content,
        visibility: visibility,
      );

      // Update shares count in cached post
      if (_postsCache.containsKey(originalPostId)) {
        final post = _postsCache[originalPostId]!;
        _postsCache[originalPostId] = PostModel(
          id: post.id,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          content: post.content,
          mediaUrls: post.mediaUrls,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount,
          sharesCount: post.sharesCount + 1,
          visibility: post.visibility,
          isLiked: post.isLiked,
          gameId: post.gameId,
          locationName: post.locationName,
          isBookmarked: post.isBookmarked,
          authorBio: post.authorBio,
          authorVerified: post.authorVerified,
          tags: post.tags,
          mentionedUsers: post.mentionedUsers,
          isEdited: post.isEdited,
          editedAt: post.editedAt,
          replyToPostId: post.replyToPostId,
          shareOriginalId: post.shareOriginalId,
        );
      }

      _invalidateFeedCaches();

      return Right(sharedPost);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to share post: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> bookmarkPost(String postId) async {
    try {
      // Optimistic update
      _optimisticBookmarks.add(postId);

      final success = await remoteDataSource.bookmarkPost(postId);
      
      if (!success) {
        _optimisticBookmarks.remove(postId);
      }

      return Right(success);
    } on PostNotFoundException catch (e) {
      _optimisticBookmarks.remove(postId);
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      _optimisticBookmarks.remove(postId);
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      _optimisticBookmarks.remove(postId);
      return Left(UnknownPostsFailure(message: 'Failed to bookmark post: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeBookmark(String postId) async {
    try {
      final success = await remoteDataSource.removeBookmark(postId);
      
      if (success) {
        _optimisticBookmarks.remove(postId);
        _invalidateBookmarksCache();
      }

      return Right(success);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to remove bookmark: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getBookmarkedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final cacheKey = 'bookmarks_${page}_$limit';
      
      if (_isCacheValid(cacheKey, _postCacheDuration)) {
        final cached = _bookmarksCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final bookmarks = await remoteDataSource.getBookmarkedPosts(
        page: page,
        limit: limit,
      );

      _bookmarksCache[cacheKey] = bookmarks;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(bookmarks);
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get bookmarked posts: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    try {
      final success = await remoteDataSource.reportPost(
        postId: postId,
        reason: reason,
        details: details,
      );

      return Right(success);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to report post: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> reportComment({
    required String commentId,
    required String reason,
    String? details,
  }) async {
    try {
      final success = await remoteDataSource.reportComment(
        commentId: commentId,
        reason: reason,
        details: details,
      );

      return Right(success);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to report comment: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getTrendingPosts({
    Duration timeframe = const Duration(days: 7),
    int page = 1,
    int limit = 20,
    String? gameId,
  }) async {
    try {
      final trending = await remoteDataSource.getTrendingPosts(
        timeframe: timeframe,
        page: page,
        limit: limit,
        gameId: gameId,
      );

      return Right(trending);
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get trending posts: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getPostsByTags(
    List<String> tags, {
    int page = 1,
    int limit = 20,
    PostVisibility? visibility,
  }) async {
    try {
      final posts = await remoteDataSource.getPostsByTags(
        tags,
        page: page,
        limit: limit,
        visibility: visibility,
      );

      return Right(posts);
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get posts by tags: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getPostsMentioningUser(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final posts = await remoteDataSource.getPostsMentioningUser(
        userId,
        page: page,
        limit: limit,
      );

      return Right(posts);
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get posts mentioning user: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPostAnalytics(
    String postId,
  ) async {
    try {
      final analytics = await remoteDataSource.getPostAnalytics(postId);
      return Right(analytics);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on UnauthorizedPostActionException catch (e) {
      return Left(UnauthorizedPostActionFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to get post analytics: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadPostMedia(
    List<String> filePaths,
  ) async {
    try {
      final urls = await remoteDataSource.uploadPostMedia(filePaths);
      return Right(urls);
    } on MediaUploadException catch (e) {
      return Left(MediaUploadFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to upload media: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteComment(String commentId) async {
    try {
      final success = await remoteDataSource.deleteComment(commentId);
      
      if (success) {
        _invalidateAllCommentsCache();
      }

      return Right(success);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on UnauthorizedPostActionException catch (e) {
      return Left(UnauthorizedPostActionFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to delete comment: $e'));
    }
  }

  @override
  Future<Either<Failure, PostModel>> updateComment({
    required String commentId,
    required String content,
    List<String>? mediaUrls,
    List<String>? mentionedUsers,
  }) async {
    try {
      final comment = await remoteDataSource.updateComment(
        commentId: commentId,
        content: content,
        mediaUrls: mediaUrls,
        mentionedUsers: mentionedUsers,
      );

      _invalidateAllCommentsCache();

      return Right(comment);
    } on PostNotFoundException catch (e) {
      return Left(PostNotFoundFailure(message: e.message));
    } on UnauthorizedPostActionException catch (e) {
      return Left(UnauthorizedPostActionFailure(message: e.message));
    } on PostValidationException catch (e) {
      return Left(PostValidationFailure(message: e.message));
    } on PostsServerException catch (e) {
      return Left(PostsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownPostsFailure(message: 'Failed to update comment: $e'));
    }
  }

  // Helper methods

  /// Check if cache is valid based on timestamp and duration
  bool _isCacheValid(String key, Duration duration) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) <= duration;
  }

  /// Generate cache key for feed requests
  String _generateFeedCacheKey({
    required FeedType feedType,
    String? gameId,
    String? authorId,
    PostVisibility? visibility,
    required int page,
    required int limit,
    required SortField sortBy,
    required SortDirection sortDirection,
    Duration? maxAge,
  }) {
    return 'feed_${feedType.toString()}_${gameId ?? 'all'}_${authorId ?? 'all'}_${visibility?.toString() ?? 'all'}_${page}_${limit}_${sortBy.toString()}_${sortDirection.toString()}_${maxAge?.inHours ?? 'all'}';
  }

  /// Apply optimistic updates to feed
  SocialFeedModel _applyFeedOptimizations(SocialFeedModel feed) {
    final optimizedPosts = List<PostModel>.from(feed.posts);
    
    // Add optimistic posts
    _optimisticPosts.forEach((id, post) {
      if (!optimizedPosts.any((p) => p.id == id)) {
        optimizedPosts.insert(0, post);
      }
    });

    // Apply optimistic reactions
    for (int i = 0; i < optimizedPosts.length; i++) {
      final post = optimizedPosts[i];
      if (_optimisticLikes.contains(post.id)) {
        optimizedPosts[i] = PostModel(
          id: post.id,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          content: post.content,
          mediaUrls: post.mediaUrls,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          likesCount: post.likesCount + 1,
          commentsCount: post.commentsCount,
          sharesCount: post.sharesCount,
          visibility: post.visibility,
          isLiked: true,
          gameId: post.gameId,
          locationName: post.locationName,
          isBookmarked: _optimisticBookmarks.contains(post.id) ? true : post.isBookmarked,
          authorBio: post.authorBio,
          authorVerified: post.authorVerified,
          tags: post.tags,
          mentionedUsers: post.mentionedUsers,
          isEdited: post.isEdited,
          editedAt: post.editedAt,
          replyToPostId: post.replyToPostId,
          shareOriginalId: post.shareOriginalId,
        );
      }
    }

    return feed.copyWith(posts: optimizedPosts);
  }

  /// Invalidate feed caches
  void _invalidateFeedCaches() {
    _feedCache.clear();
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('feed_'));
  }

  /// Invalidate reactions cache for specific post
  void _invalidateReactionsCache(String postId) {
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('reactions_$postId'));
    _reactionsCache.removeWhere((key, _) => key.startsWith('reactions_$postId'));
  }

  /// Invalidate comments cache for specific post
  void _invalidateCommentsCache(String postId) {
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('comments_$postId'));
    _commentsCache.removeWhere((key, _) => key.startsWith('comments_$postId'));
  }

  /// Invalidate all comments cache
  void _invalidateAllCommentsCache() {
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('comments_'));
    _commentsCache.clear();
  }

  /// Invalidate bookmarks cache
  void _invalidateBookmarksCache() {
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('bookmarks_'));
    _bookmarksCache.clear();
  }

  /// Get current user ID - placeholder for actual implementation
  Future<String> _getCurrentUserId() async {
    // TODO: Implement with actual auth service
    return 'current_user_id';
  }

  /// Get current user name - placeholder for actual implementation
  Future<String> _getCurrentUserName() async {
    // TODO: Implement with actual auth service
    return 'Current User';
  }

  /// Get current user avatar - placeholder for actual implementation
  Future<String> _getCurrentUserAvatar() async {
    // TODO: Implement with actual auth service
    return '';
  }

  /// Clear all caches
  void clearCache() {
    _feedCache.clear();
    _postsCache.clear();
    _userPostsCache.clear();
    _gamePostsCache.clear();
    _commentsCache.clear();
    _reactionsCache.clear();
    _bookmarksCache.clear();
    _cacheTimestamps.clear();
    _optimisticPosts.clear();
    _optimisticReactions.clear();
    _optimisticBookmarks.clear();
    _optimisticLikes.clear();
  }
}
