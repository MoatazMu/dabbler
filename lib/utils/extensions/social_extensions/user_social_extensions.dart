import '../../../core/models/user_model.dart';
import '../../enums/social_enums.dart';

/// Social activity data class
class SocialActivitySummary {
  final int postsCount;
  final int likesGiven;
  final int commentsGiven;
  final int friendsAdded;
  final double engagementRate;
  final DateTime lastActivity;
  
  const SocialActivitySummary({
    required this.postsCount,
    required this.likesGiven,
    required this.commentsGiven,
    required this.friendsAdded,
    required this.engagementRate,
    required this.lastActivity,
  });
}

/// Social badge data class
class SocialBadge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final DateTime earnedAt;
  final int level;
  
  const SocialBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.earnedAt,
    this.level = 1,
  });
}

/// Friendship model for social connections
class FriendshipModel {
  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? blockedAt;
  
  const FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.blockedAt,
  });
}

/// Extension on UserModel for social features
extension UserSocialExtensions on UserModel {
  /// Gets friend count with caching
  int getFriendCount({bool useCache = true}) {
    // In a real implementation, this would check cache first
    // For now, return 0 as social features are being built
    return 0;
  }
  
  /// Checks if user is friend with another user
  bool isFriendWith(String otherUserId) {
    // In a real implementation, this would check the friendship status
    return false;
  }
  
  /// Gets mutual friends with another user
  List<UserModel> getMutualFriends(UserModel otherUser) {
    // In a real implementation, this would find mutual friends
    return [];
  }
  
  /// Calculates social influence score based on various factors
  double calculateSocialInfluenceScore() {
    double score = 0.0;
    
    // Base score from profile completeness (max 40 points)
    if (displayName.isNotEmpty) score += 10.0;
    if (bio != null && bio!.isNotEmpty) score += 10.0;
    if (profileImageUrl != null) score += 10.0;
    if (sports.isNotEmpty) score += 10.0;
    
    // Age verification (10 points)
    if (age != null) score += 10.0;
    
    // Account age bonus (max 30 points)
    final daysSinceJoined = DateTime.now().difference(createdAt).inDays;
    score += (daysSinceJoined * 0.1).clamp(0.0, 30.0);
    
    // Sports variety bonus (max 20 points)
    score += (sports.length * 5.0).clamp(0.0, 20.0);
    
    return score.clamp(0.0, 100.0);
  }
  
  /// Gets social activity summary for the user
  SocialActivitySummary getSocialActivitySummary({int daysPeriod = 30}) {
    // In a real implementation, this would calculate based on actual activity
    return SocialActivitySummary(
      postsCount: 0,
      likesGiven: 0,
      commentsGiven: 0,
      friendsAdded: 0,
      engagementRate: 0.0,
      lastActivity: createdAt,
    );
  }
  
  /// Checks if user can receive friend requests
  bool canReceiveFriendRequests() {
    // In a real implementation, check privacy settings
    return true;
  }
  
  /// Gets user's activity level as a string
  String getActivityLevel() {
    final daysSinceJoined = DateTime.now().difference(createdAt).inDays;
    
    if (daysSinceJoined < 7) return 'New User';
    if (daysSinceJoined < 30) return 'Getting Started';
    if (daysSinceJoined < 90) return 'Regular User';
    return 'Veteran User';
  }
  
  /// Gets list of activity insights
  List<String> getActivityInsights({int daysPeriod = 30}) {
    final insights = <String>[];
    
    // Profile completion insights
    if (bio == null || bio!.isEmpty) {
      insights.add('Add a bio to tell others about yourself');
    }
    
    if (sports.isEmpty) {
      insights.add('Add your favorite sports to find playing partners');
    }
    
    if (age == null) {
      insights.add('Add your age to connect with similar players');
    }
    
    if (profileImageUrl == null) {
      insights.add('Add a profile photo to make your profile more personal');
    }
    
    // Default insight if profile is complete
    if (insights.isEmpty) {
      insights.add('Your profile looks great! Ready to connect with other players.');
    }
    
    return insights;
  }
  
  /// Checks if user can send friend request to another user
  bool canSendFriendRequest(UserModel otherUser) {
    if (id == otherUser.id) return false;
    // In a real implementation, check if already friends or request pending
    return true;
  }
  
  /// Gets friendship status with another user
  FriendshipStatus getFriendshipStatus(String otherUserId) {
    if (id == otherUserId) {
      return FriendshipStatus.blocked; // Can't be friends with yourself
    }
    
    // In a real implementation, check actual friendship status
    return FriendshipStatus.pending;
  }
  
  /// Gets list of social badges earned by the user
  List<SocialBadge> getSocialBadges() {
    final badges = <SocialBadge>[];
    
    // Welcome badge for all users
    badges.add(SocialBadge(
      id: 'welcome',
      name: 'Welcome to Dabbler',
      description: 'Joined the Dabbler community',
      iconName: 'welcome',
      earnedAt: createdAt,
    ));
    
    // Profile completion badges
    if (bio != null && bio!.isNotEmpty) {
      badges.add(SocialBadge(
        id: 'storyteller',
        name: 'Storyteller',
        description: 'Added a personal bio',
        iconName: 'storyteller',
        earnedAt: updatedAt,
      ));
    }
    
    if (sports.isNotEmpty) {
      badges.add(SocialBadge(
        id: 'sports_enthusiast',
        name: 'Sports Enthusiast',
        description: 'Added favorite sports',
        iconName: 'sports_enthusiast',
        earnedAt: updatedAt,
      ));
    }
    
    if (sports.length >= 3) {
      badges.add(SocialBadge(
        id: 'multi_sport_athlete',
        name: 'Multi-Sport Athlete',
        description: 'Plays 3 or more sports',
        iconName: 'multi_sport_athlete',
        earnedAt: updatedAt,
      ));
    }
    
    // Time-based badges
    final daysSinceJoined = DateTime.now().difference(createdAt).inDays;
    if (daysSinceJoined >= 30) {
      badges.add(SocialBadge(
        id: 'one_month_member',
        name: 'One Month Member',
        description: 'Been with Dabbler for a month',
        iconName: 'one_month_member',
        earnedAt: createdAt.add(const Duration(days: 30)),
      ));
    }
    
    if (daysSinceJoined >= 365) {
      badges.add(SocialBadge(
        id: 'one_year_member',
        name: 'One Year Member',
        description: 'Been with Dabbler for a year',
        iconName: 'one_year_member',
        earnedAt: createdAt.add(const Duration(days: 365)),
      ));
    }
    
    return badges;
  }
  
  /// Checks if user is currently online
  bool get isOnline {
    // In a real implementation, check last seen timestamp
    return false; // Default to offline
  }
  
  /// Gets formatted last seen text
  String get lastSeenText {
    // In a real implementation, calculate from actual last seen data
    return 'Recently active';
  }
  
  /// Gets social statistics for display
  Map<String, int> getSocialStats() {
    // In a real implementation, calculate from actual social data
    return {
      'posts': 0,
      'friends': 0,
      'following': 0,
      'followers': 0,
      'games_played': 0,
      'sports_count': sports.length,
    };
  }
  
  /// Checks if user has common interests with another user
  bool hasCommonInterests(UserModel otherUser) {
    // Check for common sports
    final commonSports = sports.toSet().intersection(otherUser.sports.toSet());
    return commonSports.isNotEmpty;
  }
  
  /// Gets ice breaker suggestions for conversations
  List<String> getIceBreakerSuggestions(UserModel otherUser) {
    final suggestions = <String>[];
    
    // Common sports suggestions
    final commonSports = sports.toSet().intersection(otherUser.sports.toSet());
    if (commonSports.isNotEmpty) {
      suggestions.add('I see you also enjoy ${commonSports.first}!');
      suggestions.add('Want to play ${commonSports.first} together sometime?');
    }
    
    // Age-based suggestions
    if (age != null && otherUser.age != null) {
      final ageDiff = (age! - otherUser.age!).abs();
      if (ageDiff <= 5) {
        suggestions.add('We\'re around the same age, want to team up?');
      }
    }
    
    // Location-based suggestions (using default for now)
    suggestions.add('Are you based in Dubai too?');
    
    // Generic suggestions
    suggestions.addAll([
      'Hey! Your profile looks interesting!',
      'Looking for a sports partner?',
      'Want to connect and play together?',
      'Love your sport choices!',
      'Let\'s be sports buddies!',
    ]);
    
    return suggestions.take(5).toList(); // Limit to 5 suggestions
  }
  
  /// Formats user information for social display
  Map<String, String> getSocialDisplayInfo() {
    return {
      'name': displayName,
      'username': email?.split('@').first ?? id.substring(0, 8),
      'bio': bio ?? 'Sports enthusiast ready to play!',
      'avatar': profileImageUrl ?? 'assets/Avatar/default-avatar.svg',
      'location': 'Dubai, UAE', // Default location
      'sports': sports.isNotEmpty ? sports.join(', ') : 'Various sports',
      'age': age?.toString() ?? 'Age not specified',
      'member_since': 'Member since ${createdAt.year}',
      'activity_level': getActivityLevel(),
    };
  }
  
  /// Checks if social profile is complete
  bool get isSocialProfileComplete {
    return displayName.isNotEmpty &&
           sports.isNotEmpty &&
           age != null &&
           bio != null &&
           bio!.isNotEmpty;
  }
  
  /// Gets profile completion suggestions
  List<String> getProfileCompletionSuggestions() {
    final suggestions = <String>[];
    
    if (bio == null || bio!.isEmpty) {
      suggestions.add('Add a bio to tell others about yourself');
    }
    
    if (sports.isEmpty) {
      suggestions.add('Add your favorite sports to find playing partners');
    }
    
    if (age == null) {
      suggestions.add('Add your age to connect with similar players');
    }
    
    if (profileImageUrl == null) {
      suggestions.add('Add a profile photo to personalize your profile');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('Your profile is complete! Start connecting with other players.');
    }
    
    return suggestions;
  }
  
  /// Calculates compatibility score with another user (0-100)
  int calculateCompatibilityScore(UserModel otherUser) {
    int score = 0;
    
    // Common sports (40 points max)
    final commonSports = sports.toSet().intersection(otherUser.sports.toSet());
    score += (commonSports.length * 15).clamp(0, 40);
    
    // Age similarity (30 points max)
    if (age != null && otherUser.age != null) {
      final ageDiff = (age! - otherUser.age!).abs();
      if (ageDiff <= 2) {
        score += 30;
      } else if (ageDiff <= 5) {
        score += 20;
      } else if (ageDiff <= 10) {
        score += 10;
      }
    }
    
    // Profile completeness bonus (20 points max)
    int completenessScore = 0;
    if (bio != null && bio!.isNotEmpty && otherUser.bio != null && otherUser.bio!.isNotEmpty) {
      completenessScore += 10;
    }
    if (profileImageUrl != null && otherUser.profileImageUrl != null) {
      completenessScore += 10;
    }
    score += completenessScore;
    
    // Account age similarity (10 points max)
    final myAge = DateTime.now().difference(createdAt).inDays;
    final theirAge = DateTime.now().difference(otherUser.createdAt).inDays;
    final ageDiff = (myAge - theirAge).abs();
    if (ageDiff <= 30) {
      score += 10;
    } else if (ageDiff <= 90) {
      score += 5;
    }
    
    return score.clamp(0, 100);
  }
}
