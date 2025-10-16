import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/friend.dart';
import '../../domain/repositories/friends_repository.dart';
import '../models/friend_model.dart';
import '../datasources/friends_remote_data_source.dart';

/// Custom exceptions for friends operations
class FriendsServerException implements Exception {
  final String message;
  FriendsServerException(this.message);
}

class FriendsCacheException implements Exception {
  final String message;
  FriendsCacheException(this.message);
}

class FriendRequestNotFoundException implements Exception {
  final String message;
  FriendRequestNotFoundException(this.message);
}

class DuplicateFriendRequestException implements Exception {
  final String message;
  DuplicateFriendRequestException(this.message);
}

class SelfFriendRequestException implements Exception {
  final String message;
  SelfFriendRequestException(this.message);
}

/// Custom failure types for friends
abstract class FriendsFailure extends Failure {
  const FriendsFailure({required super.message, super.code, super.details});
}

class FriendsServerFailure extends FriendsFailure {
  const FriendsServerFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Friends server error');
}

class FriendsCacheFailure extends FriendsFailure {
  const FriendsCacheFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Friends cache error');
}

class FriendRequestNotFoundFailure extends FriendsFailure {
  const FriendRequestNotFoundFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Friend request not found');
}

class DuplicateFriendRequestFailure extends FriendsFailure {
  const DuplicateFriendRequestFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Friend request already exists');
}

class SelfFriendRequestFailure extends FriendsFailure {
  const SelfFriendRequestFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Cannot send friend request to yourself');
}

class UnknownFriendsFailure extends FriendsFailure {
  const UnknownFriendsFailure({String? message, super.code, super.details}) 
      : super(message: message ?? 'Unknown friends error');
}

/// Implementation of FriendsRepository with caching and real-time updates
class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsRemoteDataSource remoteDataSource;

  // In-memory caching
  final Map<String, List<FriendModel>> _friendsCache = {};
  final Map<String, List<FriendModel>> _suggestionsCache = {};
  final Map<String, List<FriendModel>> _pendingRequestsCache = {};
  final Map<String, List<FriendModel>> _sentRequestsCache = {};
  final Map<String, List<FriendModel>> _blockedUsersCache = {};
  final Map<String, Map<String, int>> _statisticsCache = {};
  
  // Cache TTL - 5 minutes for friends, 2 minutes for suggestions
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _friendsCacheDuration = Duration(minutes: 5);
  static const Duration _suggestionsCacheDuration = Duration(minutes: 2);
  static const Duration _requestsCacheDuration = Duration(minutes: 1);

  // Optimistic updates storage
  final Map<String, FriendModel> _optimisticFriends = {};
  final Set<String> _optimisticRequests = {};
  final Set<String> _optimisticBlocks = {};

  FriendsRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<FriendModel>>> getFriends(
    String userId, {
    FriendshipStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      // Check cache first
      final cacheKey = 'friends_${userId}_${status?.toString() ?? 'all'}_${limit ?? 'all'}_${offset ?? 0}';
      if (_isCacheValid(cacheKey, _friendsCacheDuration)) {
        final cached = _friendsCache[cacheKey];
        if (cached != null) {
          return Right(_applyCacheOptimizations(cached));
        }
      }

      // Fetch from remote
      final friends = await remoteDataSource.getFriends(
        userId,
        status: status,
        limit: limit,
        offset: offset,
      );

      // Update cache
      _friendsCache[cacheKey] = friends;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(_applyCacheOptimizations(friends));
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } on FriendsCacheException catch (e) {
      return Left(FriendsCacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get friends: $e'));
    }
  }

  @override
  Future<Either<Failure, FriendModel>> sendFriendRequest(
    String toUserId, {
    String? message,
  }) async {
    try {
      // Optimistic update
      final optimisticFriend = FriendModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: await _getCurrentUserId(),
        friendId: toUserId,
        friendName: 'Loading...',
        friendUsername: '',
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        friendRequestSentAt: DateTime.now(),
      );

      _optimisticFriends[toUserId] = optimisticFriend;
      _optimisticRequests.add(toUserId);

      // Send request
      final friend = await remoteDataSource.sendFriendRequest(
        toUserId,
        message: message,
      );

      // Remove optimistic update and update cache
      _optimisticFriends.remove(toUserId);
      _optimisticRequests.remove(toUserId);
      _invalidateUserCaches(await _getCurrentUserId());

      return Right(friend);
    } on SelfFriendRequestException catch (e) {
      _optimisticFriends.remove(toUserId);
      _optimisticRequests.remove(toUserId);
      return Left(SelfFriendRequestFailure(message: e.message));
    } on DuplicateFriendRequestException catch (e) {
      _optimisticFriends.remove(toUserId);
      _optimisticRequests.remove(toUserId);
      return Left(DuplicateFriendRequestFailure(message: e.message));
    } on FriendsServerException catch (e) {
      _optimisticFriends.remove(toUserId);
      _optimisticRequests.remove(toUserId);
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      _optimisticFriends.remove(toUserId);
      _optimisticRequests.remove(toUserId);
      return Left(UnknownFriendsFailure(message: 'Failed to send friend request: $e'));
    }
  }

  @override
  Future<Either<Failure, FriendModel>> acceptFriendRequest(String requestId) async {
    try {
      final friend = await remoteDataSource.acceptFriendRequest(requestId);
      
      // Update cache optimistically
      _invalidateUserCaches(await _getCurrentUserId());
      
      return Right(friend);
    } on FriendRequestNotFoundException catch (e) {
      return Left(FriendRequestNotFoundFailure(message: e.message));
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to accept friend request: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> declineFriendRequest(String requestId) async {
    try {
      final success = await remoteDataSource.declineFriendRequest(requestId);
      
      if (success) {
        _invalidateUserCaches(await _getCurrentUserId());
      }
      
      return Right(success);
    } on FriendRequestNotFoundException catch (e) {
      return Left(FriendRequestNotFoundFailure(message: e.message));
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to decline friend request: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> blockUser(String userId) async {
    try {
      // Optimistic update
      _optimisticBlocks.add(userId);
      
      final success = await remoteDataSource.blockUser(userId);
      
      if (success) {
        _invalidateUserCaches(await _getCurrentUserId());
      } else {
        _optimisticBlocks.remove(userId);
      }
      
      return Right(success);
    } on FriendsServerException catch (e) {
      _optimisticBlocks.remove(userId);
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      _optimisticBlocks.remove(userId);
      return Left(UnknownFriendsFailure(message: 'Failed to block user: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> unblockUser(String userId) async {
    try {
      final success = await remoteDataSource.unblockUser(userId);
      
      if (success) {
        _optimisticBlocks.remove(userId);
        _invalidateUserCaches(await _getCurrentUserId());
      }
      
      return Right(success);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to unblock user: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FriendModel>>> getFriendSuggestions({
    int? limit,
    int? offset,
  }) async {
    try {
      final cacheKey = 'suggestions_${limit ?? 'all'}_${offset ?? 0}';
      if (_isCacheValid(cacheKey, _suggestionsCacheDuration)) {
        final cached = _suggestionsCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final suggestions = await remoteDataSource.getFriendSuggestions(
        limit: limit,
        offset: offset,
      );

      _suggestionsCache[cacheKey] = suggestions;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(suggestions);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get friend suggestions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FriendModel>>> getMutualFriends(
    String userId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final mutualFriends = await remoteDataSource.getMutualFriends(
        userId,
        limit: limit,
        offset: offset,
      );

      return Right(mutualFriends);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get mutual friends: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FriendModel>>> searchUsers(
    String query, {
    int? limit,
    int? offset,
  }) async {
    try {
      final users = await remoteDataSource.searchUsers(
        query,
        limit: limit,
        offset: offset,
      );

      return Right(users);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to search users: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FriendModel>>> getPendingRequests({
    int? limit,
    int? offset,
  }) async {
    try {
      final cacheKey = 'pending_${limit ?? 'all'}_${offset ?? 0}';
      if (_isCacheValid(cacheKey, _requestsCacheDuration)) {
        final cached = _pendingRequestsCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final requests = await remoteDataSource.getPendingRequests(
        limit: limit,
        offset: offset,
      );

      _pendingRequestsCache[cacheKey] = requests;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(requests);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get pending requests: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FriendModel>>> getSentRequests({
    int? limit,
    int? offset,
  }) async {
    try {
      final cacheKey = 'sent_${limit ?? 'all'}_${offset ?? 0}';
      if (_isCacheValid(cacheKey, _requestsCacheDuration)) {
        final cached = _sentRequestsCache[cacheKey];
        if (cached != null) {
          return Right(_applySentRequestsOptimizations(cached));
        }
      }

      final requests = await remoteDataSource.getSentRequests(
        limit: limit,
        offset: offset,
      );

      _sentRequestsCache[cacheKey] = requests;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(_applySentRequestsOptimizations(requests));
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get sent requests: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FriendModel>>> getBlockedUsers({
    int? limit,
    int? offset,
  }) async {
    try {
      final cacheKey = 'blocked_${limit ?? 'all'}_${offset ?? 0}';
      if (_isCacheValid(cacheKey, _friendsCacheDuration)) {
        final cached = _blockedUsersCache[cacheKey];
        if (cached != null) {
          return Right(cached);
        }
      }

      final blocked = await remoteDataSource.getBlockedUsers(
        limit: limit,
        offset: offset,
      );

      _blockedUsersCache[cacheKey] = blocked;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return Right(blocked);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get blocked users: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelFriendRequest(String requestId) async {
    try {
      final success = await remoteDataSource.cancelFriendRequest(requestId);
      
      if (success) {
        _invalidateUserCaches(await _getCurrentUserId());
      }
      
      return Right(success);
    } on FriendRequestNotFoundException catch (e) {
      return Left(FriendRequestNotFoundFailure(message: e.message));
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to cancel friend request: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeFriend(String friendId) async {
    try {
      final success = await remoteDataSource.removeFriend(friendId);
      
      if (success) {
        _invalidateUserCaches(await _getCurrentUserId());
      }
      
      return Right(success);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to remove friend: $e'));
    }
  }

  @override
  Future<Either<Failure, FriendshipStatus?>> getFriendshipStatus(
    String userId,
    String otherUserId,
  ) async {
    try {
      final status = await remoteDataSource.getFriendshipStatus(userId, otherUserId);
      return Right(status);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get friendship status: $e'));
    }
  }

  @override
  Future<Either<Failure, List<FriendModel>>> getOnlineFriends({
    int? limit,
    int? offset,
  }) async {
    try {
      final onlineFriends = await remoteDataSource.getOnlineFriends(
        limit: limit,
        offset: offset,
      );

      return Right(onlineFriends);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get online friends: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateFriendRequestMessage(
    String requestId,
    String message,
  ) async {
    try {
      final success = await remoteDataSource.updateFriendRequestMessage(requestId, message);
      return Right(success);
    } on FriendRequestNotFoundException catch (e) {
      return Left(FriendRequestNotFoundFailure(message: e.message));
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to update friend request message: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getFriendStatistics(String userId) async {
    try {
      if (_statisticsCache.containsKey(userId)) {
        final cached = _statisticsCache[userId];
        if (cached != null) {
          return Right(cached);
        }
      }

      final statistics = await remoteDataSource.getFriendStatistics(userId);
      _statisticsCache[userId] = statistics;

      return Right(statistics);
    } on FriendsServerException catch (e) {
      return Left(FriendsServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFriendsFailure(message: 'Failed to get friend statistics: $e'));
    }
  }

  // Helper methods

  /// Check if cache is valid based on timestamp and duration
  bool _isCacheValid(String key, Duration duration) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) <= duration;
  }

  /// Apply optimistic updates to cached friends list
  List<FriendModel> _applyCacheOptimizations(List<FriendModel> friends) {
    final optimized = List<FriendModel>.from(friends);
    
    // Add optimistic friends
    _optimisticFriends.forEach((userId, friend) {
      if (!optimized.any((f) => f.friendId == userId)) {
        optimized.add(friend);
      }
    });

    return optimized;
  }

  /// Apply optimistic updates to sent requests
  List<FriendModel> _applySentRequestsOptimizations(List<FriendModel> requests) {
    final optimized = List<FriendModel>.from(requests);
    
    // Add optimistic requests
    _optimisticFriends.forEach((userId, friend) {
      if (_optimisticRequests.contains(userId) && 
          !optimized.any((r) => r.friendId == userId)) {
        optimized.add(friend);
      }
    });

    return optimized;
  }

  /// Invalidate all caches for a specific user
  void _invalidateUserCaches(String userId) {
    _cacheTimestamps.removeWhere((key, _) => key.contains(userId));
    _friendsCache.removeWhere((key, _) => key.contains(userId));
    _pendingRequestsCache.clear();
    _sentRequestsCache.clear();
    _suggestionsCache.clear();
    _statisticsCache.remove(userId);
  }

  /// Get current user ID - placeholder for actual implementation
  Future<String> _getCurrentUserId() async {
    return 'current_user_id';
  }

  /// Clear all caches
  void clearCache() {
    _friendsCache.clear();
    _suggestionsCache.clear();
    _pendingRequestsCache.clear();
    _sentRequestsCache.clear();
    _blockedUsersCache.clear();
    _statisticsCache.clear();
    _cacheTimestamps.clear();
    _optimisticFriends.clear();
    _optimisticRequests.clear();
    _optimisticBlocks.clear();
  }

  /// Force refresh cache for specific operation
  Future<Either<Failure, List<FriendModel>>> refreshFriends(String userId) async {
    _invalidateUserCaches(userId);
    return getFriends(userId);
  }
}
