import 'social_constants.dart';
import 'social_helpers.dart';

/// Helper functions for friend management and social connections
class FriendHelpers {
  /// Calculate friendship duration and format it nicely
  static String calculateFriendshipDuration(DateTime friendsSince) {
    final now = DateTime.now();
    final difference = now.difference(friendsSince);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return 'Just became friends';
      }
      return 'Friends for ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inDays < 30) {
      return 'Friends for ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Friends for $months month${months == 1 ? '' : 's'}';
    } else {
      final years = (difference.inDays / 365).floor();
      final remainingMonths = ((difference.inDays % 365) / 30).floor();
      
      String result = 'Friends for $years year${years == 1 ? '' : 's'}';
      if (remainingMonths > 0) {
        result += ' and $remainingMonths month${remainingMonths == 1 ? '' : 's'}';
      }
      return result;
    }
  }

  /// Format mutual friends text (e.g., "5 mutual friends", "John and 3 others")
  static String formatMutualFriendsText(List<String> mutualFriendNames, int totalMutualCount) {
    if (totalMutualCount == 0) return 'No mutual friends';
    if (totalMutualCount == 1) return '1 mutual friend';
    
    if (mutualFriendNames.isEmpty) {
      return '$totalMutualCount mutual friends';
    }
    
    if (mutualFriendNames.length == 1) {
      if (totalMutualCount == 1) {
        return '${mutualFriendNames[0]} is a mutual friend';
      } else {
        return '${mutualFriendNames[0]} and ${totalMutualCount - 1} other${totalMutualCount - 1 == 1 ? '' : 's'}';
      }
    }
    
    if (mutualFriendNames.length == 2) {
      if (totalMutualCount == 2) {
        return '${mutualFriendNames[0]} and ${mutualFriendNames[1]} are mutual friends';
      } else {
        return '${mutualFriendNames[0]}, ${mutualFriendNames[1]} and ${totalMutualCount - 2} other${totalMutualCount - 2 == 1 ? '' : 's'}';
      }
    }
    
    // For 3+ displayed names
    final othersCount = totalMutualCount - mutualFriendNames.length;
    if (othersCount > 0) {
      return '${mutualFriendNames.take(2).join(', ')} and $othersCount other${othersCount == 1 ? '' : 's'}';
    } else {
      return '${mutualFriendNames.join(', ')} are mutual friends';
    }
  }

  /// Generate friend request message based on connection context
  static String generateFriendRequestMessage(FriendRequestContext context) {
    switch (context.type) {
      case FriendRequestType.mutualFriend:
        return 'Hi! I noticed we have ${context.mutualFriendsCount} mutual friends. Would you like to connect?';
      
      case FriendRequestType.sameInterest:
        return 'Hi! I saw we both enjoy ${context.sharedInterest}. Would you like to be friends?';
      
      case FriendRequestType.sameLocation:
        return 'Hi! I see you\'re also in ${context.location}. Would you like to connect?';
      
      case FriendRequestType.fromGroup:
        return 'Hi! We\'re both part of ${context.groupName}. Would you like to be friends?';
      
      case FriendRequestType.fromEvent:
        return 'Hi! We both attended ${context.eventName}. Would you like to connect?';
      
      case FriendRequestType.suggestion:
        return 'Hi! You appeared in my friend suggestions. Would you like to connect?';
      
      case FriendRequestType.manual:
        return 'Hi! Would you like to be friends?';
    }
  }

  /// Check if user can send friend request (not blocked, not already friends, etc.)
  static FriendRequestEligibility canSendFriendRequest(
    String targetUserId,
    String currentUserId,
    UserRelationshipStatus currentStatus,
    List<String> blockedUsers,
    List<String> blockedByUsers,
    int requestsSentToday,
  ) {
    // Check if blocked
    if (blockedUsers.contains(targetUserId)) {
      return FriendRequestEligibility.blocked('You have blocked this user');
    }
    
    if (blockedByUsers.contains(targetUserId)) {
      return FriendRequestEligibility.blocked('This user has blocked you');
    }
    
    // Check current relationship status
    switch (currentStatus) {
      case UserRelationshipStatus.friends:
        return FriendRequestEligibility.invalid('You are already friends');
      
      case UserRelationshipStatus.requestSent:
        return FriendRequestEligibility.invalid('Friend request already sent');
      
      case UserRelationshipStatus.requestReceived:
        return FriendRequestEligibility.invalid('You have a pending request from this user');
      
      case UserRelationshipStatus.none:
        break; // Continue with other checks
    }
    
    // Check daily limit
    if (requestsSentToday >= SocialConstants.maxFriendRequestsPerDay) {
      return FriendRequestEligibility.rateLimited('Daily friend request limit reached');
    }
    
    // Check if it's the same user
    if (targetUserId == currentUserId) {
      return FriendRequestEligibility.invalid('Cannot send request to yourself');
    }
    
    return FriendRequestEligibility.eligible();
  }

  /// Sort friends by various criteria
  static List<FriendData> sortFriendsByCriteria(
    List<FriendData> friends,
    FriendSortCriteria criteria, {
    bool ascending = true,
  }) {
    final sorted = List<FriendData>.from(friends);
    
    switch (criteria) {
      case FriendSortCriteria.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
        
      case FriendSortCriteria.friendshipDate:
        sorted.sort((a, b) => a.friendshipDate.compareTo(b.friendshipDate));
        break;
        
      case FriendSortCriteria.lastActive:
        sorted.sort((a, b) => (a.lastActiveAt ?? DateTime(0)).compareTo(b.lastActiveAt ?? DateTime(0)));
        break;
        
      case FriendSortCriteria.mutualFriends:
        sorted.sort((a, b) => a.mutualFriendsCount.compareTo(b.mutualFriendsCount));
        break;
        
      case FriendSortCriteria.interaction:
        sorted.sort((a, b) => a.interactionScore.compareTo(b.interactionScore));
        break;
        
      case FriendSortCriteria.location:
        sorted.sort((a, b) => (a.location ?? '').compareTo(b.location ?? ''));
        break;
    }
    
    if (!ascending) {
      return sorted.reversed.toList();
    }
    
    return sorted;
  }

  /// Calculate friend compatibility score based on interests, location, etc.
  static double calculateCompatibilityScore(UserProfile user1, UserProfile user2) {
    double score = 0.0;
    double maxScore = 0.0;
    
    // Shared interests (40% weight)
    final sharedInterests = user1.interests.toSet().intersection(user2.interests.toSet());
    final totalInterests = user1.interests.toSet().union(user2.interests.toSet()).length;
    if (totalInterests > 0) {
      score += (sharedInterests.length / totalInterests) * 40;
    }
    maxScore += 40;
    
    // Location proximity (20% weight)
    if (user1.location != null && user2.location != null) {
      final distance = _calculateDistance(user1.location!, user2.location!);
      final locationScore = (distance < 50) ? 20 : (distance < 100) ? 15 : (distance < 200) ? 10 : 5;
      score += locationScore;
    }
    maxScore += 20;
    
    // Age similarity (15% weight)
    if (user1.age != null && user2.age != null) {
      final ageDiff = (user1.age! - user2.age!).abs();
      final ageScore = ageDiff <= 2 ? 15 : ageDiff <= 5 ? 12 : ageDiff <= 10 ? 8 : 3;
      score += ageScore;
    }
    maxScore += 15;
    
    // Activity level similarity (15% weight)
    if (user1.activityLevel != null && user2.activityLevel != null) {
      final activityDiff = (user1.activityLevel! - user2.activityLevel!).abs();
      final activityScore = activityDiff <= 1 ? 15 : activityDiff <= 2 ? 10 : 5;
      score += activityScore;
    }
    maxScore += 15;
    
    // Mutual friends (10% weight)
    final mutualCount = user1.friendIds.toSet().intersection(user2.friendIds.toSet()).length;
    final mutualScore = mutualCount > 10 ? 10 : mutualCount > 5 ? 8 : mutualCount > 0 ? 5 : 0;
    score += mutualScore;
    maxScore += 10;
    
    return maxScore > 0 ? (score / maxScore) * 100 : 0.0;
  }

  /// Get friend suggestions based on mutual connections and interests
  static List<FriendSuggestion> generateFriendSuggestions(
    String currentUserId,
    List<String> currentFriendIds,
    List<UserProfile> allUsers,
    List<String> blockedUsers,
    int maxSuggestions,
  ) {
    final suggestions = <FriendSuggestion>[];
    
    for (final user in allUsers) {
      if (user.id == currentUserId) continue;
      if (currentFriendIds.contains(user.id)) continue;
      if (blockedUsers.contains(user.id)) continue;
      
      final mutualFriends = currentFriendIds.toSet().intersection(user.friendIds.toSet()).length;
      final compatibilityScore = calculateCompatibilityScore(
        UserProfile(
          id: currentUserId,
          interests: [], // Would need to pass current user's profile
          location: null,
          age: null,
          activityLevel: null,
          friendIds: currentFriendIds,
        ),
        user,
      );
      
      // Determine suggestion reason
      FriendSuggestionReason reason;
      if (mutualFriends > 5) {
        reason = FriendSuggestionReason.manyMutualFriends;
      } else if (mutualFriends > 0) {
        reason = FriendSuggestionReason.mutualFriends;
      } else if (compatibilityScore > 70) {
        reason = FriendSuggestionReason.similarInterests;
      } else {
        reason = FriendSuggestionReason.general;
      }
      
      suggestions.add(FriendSuggestion(
        user: user,
        mutualFriendsCount: mutualFriends,
        compatibilityScore: compatibilityScore,
        reason: reason,
      ));
    }
    
    // Sort by compatibility score and mutual friends
    suggestions.sort((a, b) {
      final scoreComparison = b.compatibilityScore.compareTo(a.compatibilityScore);
      if (scoreComparison != 0) return scoreComparison;
      return b.mutualFriendsCount.compareTo(a.mutualFriendsCount);
    });
    
    return suggestions.take(maxSuggestions).toList();
  }

  /// Format friend activity status
  static String formatActivityStatus(DateTime? lastActiveAt, bool isOnline) {
    if (isOnline) return 'Online';
    if (lastActiveAt == null) return 'Unknown';
    
    return 'Last seen ${SocialHelpers.formatPostTime(lastActiveAt)}';
  }

  /// Calculate interaction frequency between friends
  static FriendInteractionLevel calculateInteractionLevel(
    int messagesExchanged,
    int postsLiked,
    int commentsExchanged,
    Duration friendshipDuration,
  ) {
    final daysAsFriends = friendshipDuration.inDays.clamp(1, double.infinity).toInt();
    final totalInteractions = messagesExchanged + postsLiked + commentsExchanged;
    final interactionsPerDay = totalInteractions / daysAsFriends;
    
    if (interactionsPerDay > 5) return FriendInteractionLevel.high;
    if (interactionsPerDay > 1) return FriendInteractionLevel.medium;
    if (interactionsPerDay > 0.1) return FriendInteractionLevel.low;
    return FriendInteractionLevel.minimal;
  }

  // Private helper methods
  static double _calculateDistance(LocationData location1, LocationData location2) {
    // Simple distance calculation - in production, use proper geo libraries
    final latDiff = location1.latitude - location2.latitude;
    final lonDiff = location1.longitude - location2.longitude;
    return (latDiff * latDiff + lonDiff * lonDiff) * 111; // Rough km conversion
  }
}

// Data classes and enums for friend helpers
class FriendRequestContext {
  final FriendRequestType type;
  final int mutualFriendsCount;
  final String? sharedInterest;
  final String? location;
  final String? groupName;
  final String? eventName;

  const FriendRequestContext({
    required this.type,
    this.mutualFriendsCount = 0,
    this.sharedInterest,
    this.location,
    this.groupName,
    this.eventName,
  });
}

class FriendRequestEligibility {
  final bool isEligible;
  final String? reason;
  final FriendRequestEligibilityType type;

  const FriendRequestEligibility._({
    required this.isEligible,
    required this.type,
    this.reason,
  });

  factory FriendRequestEligibility.eligible() => 
    const FriendRequestEligibility._(isEligible: true, type: FriendRequestEligibilityType.eligible);
  
  factory FriendRequestEligibility.blocked(String reason) =>
    FriendRequestEligibility._(isEligible: false, type: FriendRequestEligibilityType.blocked, reason: reason);
  
  factory FriendRequestEligibility.invalid(String reason) =>
    FriendRequestEligibility._(isEligible: false, type: FriendRequestEligibilityType.invalid, reason: reason);
  
  factory FriendRequestEligibility.rateLimited(String reason) =>
    FriendRequestEligibility._(isEligible: false, type: FriendRequestEligibilityType.rateLimited, reason: reason);
}

class FriendData {
  final String id;
  final String name;
  final DateTime friendshipDate;
  final DateTime? lastActiveAt;
  final int mutualFriendsCount;
  final double interactionScore;
  final String? location;

  const FriendData({
    required this.id,
    required this.name,
    required this.friendshipDate,
    this.lastActiveAt,
    required this.mutualFriendsCount,
    required this.interactionScore,
    this.location,
  });
}

class UserProfile {
  final String id;
  final List<String> interests;
  final LocationData? location;
  final int? age;
  final int? activityLevel;
  final List<String> friendIds;

  const UserProfile({
    required this.id,
    required this.interests,
    this.location,
    this.age,
    this.activityLevel,
    required this.friendIds,
  });
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });
}

class FriendSuggestion {
  final UserProfile user;
  final int mutualFriendsCount;
  final double compatibilityScore;
  final FriendSuggestionReason reason;

  const FriendSuggestion({
    required this.user,
    required this.mutualFriendsCount,
    required this.compatibilityScore,
    required this.reason,
  });
}

enum FriendRequestType {
  mutualFriend,
  sameInterest,
  sameLocation,
  fromGroup,
  fromEvent,
  suggestion,
  manual,
}

enum UserRelationshipStatus {
  none,
  friends,
  requestSent,
  requestReceived,
}

enum FriendRequestEligibilityType {
  eligible,
  blocked,
  invalid,
  rateLimited,
}

enum FriendSortCriteria {
  name,
  friendshipDate,
  lastActive,
  mutualFriends,
  interaction,
  location,
}

enum FriendSuggestionReason {
  mutualFriends,
  manyMutualFriends,
  similarInterests,
  sameLocation,
  general,
}

enum FriendInteractionLevel {
  minimal,
  low,
  medium,
  high,
}
