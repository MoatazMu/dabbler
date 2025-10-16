import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../../utils/enums/social_enums.dart'; // For ReactionType enum
import '../repositories/posts_repository.dart';
import '../../data/models/post_model.dart';
import '../../data/models/reaction_model.dart';

/// Parameters for reacting to a post
class ReactToPostParams {
  final String userId;
  final String postId;
  final ReactionType reactionType;
  final bool isToggle; // If true, removes reaction if already exists
  final bool sendNotification;
  final bool enableAnimation;
  final Map<String, dynamic>? metadata;

  const ReactToPostParams({
    required this.userId,
    required this.postId,
    required this.reactionType,
    this.isToggle = true,
    this.sendNotification = true,
    this.enableAnimation = true,
    this.metadata,
  });
}

/// Result of react to post operation
class ReactToPostResult {
  final ReactionModel? reaction;
  final PostModel updatedPost;
  final ReactionAction action; // added, removed, changed
  final ReactionType? previousReaction;
  final bool notificationSent;
  final bool animationTriggered;
  final Map<String, int> updatedCounts;
  final List<String> warnings;

  const ReactToPostResult({
    this.reaction,
    required this.updatedPost,
    required this.action,
    this.previousReaction,
    this.notificationSent = false,
    this.animationTriggered = false,
    this.updatedCounts = const {},
    this.warnings = const [],
  });
}

/// Batch parameters for multiple reactions
class BatchReactToPostsParams {
  final String userId;
  final List<PostReactionRequest> reactions;
  final bool sendNotifications;
  final int maxBatchSize;

  const BatchReactToPostsParams({
    required this.userId,
    required this.reactions,
    this.sendNotifications = true,
    this.maxBatchSize = 50,
  });
}

/// Single post reaction request for batch operations
class PostReactionRequest {
  final String postId;
  final ReactionType reactionType;
  final bool isToggle;

  const PostReactionRequest({
    required this.postId,
    required this.reactionType,
    this.isToggle = true,
  });
}

/// Batch reaction result
class BatchReactToPostsResult {
  final List<ReactToPostResult> results;
  final List<String> errors;
  final int successCount;
  final int failureCount;
  final Map<String, dynamic> batchMetadata;

  const BatchReactToPostsResult({
    required this.results,
    required this.errors,
    required this.successCount,
    required this.failureCount,
    this.batchMetadata = const {},
  });
}

/// Use case for reacting to posts with comprehensive logic
class ReactToPostUseCase {
  final PostsRepository _postsRepository;

  ReactToPostUseCase(this._postsRepository);

  Future<Either<Failure, ReactToPostResult>> call(ReactToPostParams params) async {
    try {
      // Validate input parameters
      final validationResult = await _validateParams(params);
      if (validationResult.isLeft) {
        return Left(validationResult.leftOrNull()!);
      }

      // Check if user can react to this post
      final permissionResult = await _checkReactionPermissions(params);
      if (permissionResult.isLeft) {
        return Left(permissionResult.leftOrNull()!);
      }

      // Get current post and user's existing reaction
      final postAndReactionResult = await _getPostAndExistingReaction(params);
      if (postAndReactionResult.isLeft) {
        return Left(postAndReactionResult.leftOrNull()!);
      }
      
      final postData = postAndReactionResult.rightOrNull()!;
      final currentPost = postData.post;
      final existingReaction = postData.existingReaction;

      // Determine the action to take
      final actionResult = _determineReactionAction(
        params,
        existingReaction,
      );

      ReactionModel? newReaction;
      ReactionAction action;
      ReactionType? previousReaction;

      switch (actionResult.action) {
        case ReactionAction.added:
          // Add new reaction
          final addResult = await _addReaction(params);
          if (addResult.isLeft) {
            return Left(addResult.leftOrNull()!);
          }
          newReaction = addResult.rightOrNull()!;
          action = ReactionAction.added;
          break;

        case ReactionAction.removed:
          // Remove existing reaction
          final removeResult = await _removeReaction(existingReaction!.id);
          if (removeResult.isLeft) {
            return Left(removeResult.leftOrNull()!);
          }
          newReaction = null;
          action = ReactionAction.removed;
          previousReaction = existingReaction.reactionType;
          break;

        case ReactionAction.changed:
          // Change existing reaction type
          final changeResult = await _changeReaction(
            existingReaction!.id,
            params.reactionType,
          );
          if (changeResult.isLeft) {
            return Left(changeResult.leftOrNull()!);
          }
          newReaction = changeResult.rightOrNull()!;
          action = ReactionAction.changed;
          previousReaction = existingReaction.reactionType;
          break;
      }

      // Get updated post with new reaction counts
      final updatedPostResult = await _postsRepository.getPost(params.postId);
      
      final updatedPost = updatedPostResult.fold(
        (failure) => throw Exception(failure.message),
        (post) => post,
      );

      // Calculate updated reaction counts
      final updatedCounts = _calculateReactionCounts(currentPost, updatedPost);

      // Send notification to post owner if enabled
      bool notificationSent = false;
      if (params.sendNotification && 
          action != ReactionAction.removed &&
          params.userId != currentPost.authorId) {
        notificationSent = await _sendReactionNotification(
          params,
          newReaction,
          currentPost,
        );
      }

      // Trigger reaction animation if enabled
      bool animationTriggered = false;
      if (params.enableAnimation && action == ReactionAction.added) {
        animationTriggered = await _triggerReactionAnimation(
          params.postId,
          params.reactionType,
        );
      }

      // Update user activity metrics
      await _updateUserMetrics(params.userId, action, params.reactionType);

      // Log reaction for analytics
      await _logReactionActivity(params, action, previousReaction);

      return Right(ReactToPostResult(
        reaction: newReaction,
        updatedPost: updatedPost,
        action: action,
        previousReaction: previousReaction,
        notificationSent: notificationSent,
        animationTriggered: animationTriggered,
        updatedCounts: updatedCounts,
      ));

    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to react to post: ${e.toString()}',
      ));
    }
  }

  /// Batch reaction to multiple posts
  Future<Either<Failure, BatchReactToPostsResult>> batchReact(
    BatchReactToPostsParams params,
  ) async {
    try {
      // Validate batch parameters
      if (params.reactions.isEmpty) {
        return Left(ValidationFailure(
          message: 'No reactions provided in batch request',
        ));
      }

      if (params.reactions.length > params.maxBatchSize) {
        return Left(ValidationFailure(
          message: 'Batch size exceeds maximum of ${params.maxBatchSize}',
        ));
      }

      final results = <ReactToPostResult>[];
      final errors = <String>[];
      int successCount = 0;
      int failureCount = 0;

      // Process reactions in batches
      for (final reactionRequest in params.reactions) {
        try {
          final reactionParams = ReactToPostParams(
            userId: params.userId,
            postId: reactionRequest.postId,
            reactionType: reactionRequest.reactionType,
            isToggle: reactionRequest.isToggle,
            sendNotification: params.sendNotifications,
          );

          final result = await call(reactionParams);
          
          if (result.isRight) {
            results.add(result.rightOrNull()!);
            successCount++;
          } else {
            errors.add('Failed to react to post ${reactionRequest.postId}: ${result.leftOrNull()!.message}');
            failureCount++;
          }
        } catch (e) {
          errors.add('Error processing reaction for post ${reactionRequest.postId}: ${e.toString()}');
          failureCount++;
        }
      }

      return Right(BatchReactToPostsResult(
        results: results,
        errors: errors,
        successCount: successCount,
        failureCount: failureCount,
        batchMetadata: {
          'processed_at': DateTime.now().toIso8601String(),
          'total_requests': params.reactions.length,
          'success_rate': successCount / params.reactions.length,
        },
      ));

    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to process batch reactions: ${e.toString()}',
      ));
    }
  }

  /// Validates input parameters
  Future<Either<Failure, void>> _validateParams(ReactToPostParams params) async {
    // Validate user ID format
    if (!_isValidId(params.userId)) {
      return Left(ValidationFailure(
        message: 'Invalid user ID format',
      ));
    }

    // Validate post ID format
    if (!_isValidId(params.postId)) {
      return Left(ValidationFailure(
        message: 'Invalid post ID format',
      ));
    }

    // Validate reaction type
    if (!ReactionType.values.contains(params.reactionType)) {
      return Left(ValidationFailure(
        message: 'Invalid reaction type',
      ));
    }

    return const Right(null);
  }

  /// Checks if user can react to the post
  Future<Either<Failure, void>> _checkReactionPermissions(ReactToPostParams params) async {
    try {
      // Check if post exists and is accessible to user
      final postResult = await _postsRepository.getPost(params.postId);
      
      final post = postResult.fold(
        (failure) => throw Exception(failure.message),
        (post) => post,
      );

      // Check if user is blocked by post author
      if (post.authorId != params.userId) {
        final isBlockedResult = await _postsRepository.isUserBlockedByAuthor(
          params.userId,
          post.authorId,
        );
        
        final isBlocked = isBlockedResult.fold(
          (failure) => false,
          (blocked) => blocked,
        );
        
        if (isBlocked) {
          return Left(AuthorizationFailure(
            message: 'Cannot react to posts from users who have blocked you',
          ));
        }
      }

      // Check rate limiting for reactions
      final rateLimitResult = await _checkReactionRateLimit(params.userId);
      if (rateLimitResult.isLeft) {
        return Left(rateLimitResult.fold(
          (failure) => failure,
          (_) => throw Exception('Unexpected success'),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to check reaction permissions: ${e.toString()}',
      ));
    }
  }

  /// Gets post and user's existing reaction
  Future<Either<Failure, PostAndReactionData>> _getPostAndExistingReaction(
    ReactToPostParams params,
  ) async {
    try {
      // Get post
      final postResult = await _postsRepository.getPost(params.postId);
      final post = postResult.fold(
        (failure) => throw Exception(failure.message),
        (post) => post,
      );

      // Get existing reaction if any
      final reactionResult = await _postsRepository.getUserReactionToPost(
        params.postId,
        params.userId,
      );

      ReactionModel? existingReaction;
      if (reactionResult.isRight) {
        existingReaction = reactionResult.fold(
          (failure) => null,
          (reaction) => reaction,
        );
      }

      return Right(PostAndReactionData(
        post: post,
        existingReaction: existingReaction,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to get post and reaction data: ${e.toString()}',
      ));
    }
  }

  /// Determines what action to take based on existing reaction
  ReactionActionResult _determineReactionAction(
    ReactToPostParams params,
    ReactionModel? existingReaction,
  ) {
    if (existingReaction == null) {
      // No existing reaction, add new one
      return const ReactionActionResult(action: ReactionAction.added);
    }

    if (existingReaction.reactionType == params.reactionType) {
      // Same reaction type
      if (params.isToggle) {
        // Remove existing reaction
        return const ReactionActionResult(action: ReactionAction.removed);
      } else {
        // Keep existing reaction (no change)
        return const ReactionActionResult(action: ReactionAction.added);
      }
    } else {
      // Different reaction type, change it
      return const ReactionActionResult(action: ReactionAction.changed);
    }
  }

  /// Adds a new reaction
  Future<Either<Failure, ReactionModel>> _addReaction(ReactToPostParams params) async {
    try {
      final reactionData = {
        'post_id': params.postId,
        'user_id': params.userId,
        'reaction_type': params.reactionType.name,
        'metadata': params.metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      };

      return await _postsRepository.addReaction(reactionData);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to add reaction: ${e.toString()}',
      ));
    }
  }

  /// Removes an existing reaction
  Future<Either<Failure, bool>> _removeReaction(String reactionId) async {
    try {
      return await _postsRepository.removeReaction(reactionId);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to remove reaction: ${e.toString()}',
      ));
    }
  }

  /// Changes an existing reaction type
  Future<Either<Failure, ReactionModel>> _changeReaction(
    String reactionId,
    ReactionType newType,
  ) async {
    try {
      return await _postsRepository.updateReaction(reactionId, {
        'reaction_type': newType.name,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to change reaction: ${e.toString()}',
      ));
    }
  }

  /// Checks rate limiting for reactions
  Future<Either<Failure, void>> _checkReactionRateLimit(String userId) async {
    try {
      final recentReactions = await _postsRepository.getRecentReactionsCount(
        userId,
        const Duration(minutes: 1),
      );

      if (recentReactions.isRight) {
        final count = recentReactions.fold(
          (failure) => 0,
          (count) => count,
        );
        
        if (count > 60) {
          return Left(ServerFailure(
            message: 'Reaction rate limit exceeded. Please slow down.',
          ));
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to check reaction rate limit: ${e.toString()}',
      ));
    }
  }

  /// Calculates updated reaction counts
  Map<String, int> _calculateReactionCounts(PostModel oldPost, PostModel newPost) {
    final counts = <String, int>{};
    
    // Compare like counts
    if (oldPost.likesCount != newPost.likesCount) {
      counts['likes'] = newPost.likesCount;
    }

    // Add other reaction types if they exist
    // This would depend on how reactions are stored in the post model
    
    return counts;
  }

  /// Sends notification to post owner
  Future<bool> _sendReactionNotification(
    ReactToPostParams params,
    ReactionModel? reaction,
    PostModel post,
  ) async {
    try {
      // Don't notify if user is reacting to their own post
      if (params.userId == post.authorId) {
        return false;
      }

      // This would typically call a notification service with reaction data
      // final notificationData = {
      //   'type': 'post_reaction',
      //   'actor_id': params.userId,
      //   'recipient_id': post.authorId,
      //   'post_id': params.postId,
      //   'reaction_type': params.reactionType.name,
      //   'reaction_id': reaction?.id,
      //   'created_at': DateTime.now().toIso8601String(),
      // };
      // await _notificationService.sendNotification(notificationData);
      
      return true;
    } catch (e) {
      print('Failed to send reaction notification: $e');
      return false;
    }
  }

  /// Triggers reaction animation
  Future<bool> _triggerReactionAnimation(String postId, ReactionType reactionType) async {
    try {
      // This would typically trigger UI animation
      // For now, just simulate success
      return true;
    } catch (e) {
      print('Failed to trigger reaction animation: $e');
      return false;
    }
  }

  /// Updates user activity metrics
  Future<void> _updateUserMetrics(
    String userId,
    ReactionAction action,
    ReactionType reactionType,
  ) async {
    try {
      // This would typically call a metrics service with user activity data
      // final metricData = {
      //   'user_id': userId,
      //   'action': 'reaction_${action.name}',
      //   'reaction_type': reactionType.name,
      //   'timestamp': DateTime.now().toIso8601String(),
      // };
      // await _metricsService.recordEvent(metricData);
    } catch (e) {
      print('Failed to update user metrics: $e');
    }
  }

  /// Logs reaction activity for analytics
  Future<void> _logReactionActivity(
    ReactToPostParams params,
    ReactionAction action,
    ReactionType? previousReaction,
  ) async {
    try {
      // This would typically call an analytics service with reaction activity data
      // final logData = {
      //   'event': 'post_reaction',
      //   'user_id': params.userId,
      //   'post_id': params.postId,
      //   'action': action.name,
      //   'reaction_type': params.reactionType.name,
      //   'previous_reaction': previousReaction?.name,
      //   'is_toggle': params.isToggle,
      //   'notification_sent': params.sendNotification,
      //   'animation_enabled': params.enableAnimation,
      //   'timestamp': DateTime.now().toIso8601String(),
      // };
      // await _analyticsService.logEvent('post_reaction', logData);
    } catch (e) {
      print('Failed to log reaction activity: $e');
    }
  }

  /// Validates ID format (assuming UUID)
  bool _isValidId(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(id);
  }
}

/// Reaction action types
enum ReactionAction {
  added,
  removed,
  changed,
}

/// Data class for post and existing reaction
class PostAndReactionData {
  final PostModel post;
  final ReactionModel? existingReaction;

  const PostAndReactionData({
    required this.post,
    this.existingReaction,
  });
}

/// Reaction action determination result
class ReactionActionResult {
  final ReactionAction action;

  const ReactionActionResult({
    required this.action,
  });
}

/// Extended methods for PostsRepository
extension ReactToPostRepositoryMethods on PostsRepository {
  Future<Either<Failure, bool>> isUserBlockedByAuthor(String userId, String authorId) {
    throw UnimplementedError('isUserBlockedByAuthor not implemented');
  }

  Future<Either<Failure, ReactionModel?>> getUserReactionToPost(String postId, String userId) {
    throw UnimplementedError('getUserReactionToPost not implemented');
  }

  Future<Either<Failure, int>> getRecentReactionsCount(String userId, Duration timeWindow) {
    throw UnimplementedError('getRecentReactionsCount not implemented');
  }

  Future<Either<Failure, ReactionModel>> addReaction(Map<String, dynamic> reactionData) {
    throw UnimplementedError('addReaction not implemented');
  }

  Future<Either<Failure, bool>> removeReaction(String reactionId) {
    throw UnimplementedError('removeReaction not implemented');
  }

  Future<Either<Failure, ReactionModel>> updateReaction(
    String reactionId,
    Map<String, dynamic> updateData,
  ) {
    throw UnimplementedError('updateReaction not implemented');
  }

  Future<Either<Failure, PostModel>> getPost(String postId) {
    throw UnimplementedError('getPost not implemented');
  }
}
