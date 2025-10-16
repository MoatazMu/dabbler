import 'social_constants.dart';

/// Helper functions for social privacy and content filtering
class PrivacyHelpersSocial {
  /// Check if user can view a post based on privacy settings
  static bool canViewPost(
    String currentUserId,
    String postAuthorId,
    PostPrivacySettings privacySettings,
    UserRelationshipData relationship,
    List<String> blockedUsers,
  ) {
    // Check if blocked
    if (blockedUsers.contains(postAuthorId) || blockedUsers.contains(currentUserId)) {
      return false;
    }
    
    // Author can always see their own posts
    if (currentUserId == postAuthorId) {
      return true;
    }
    
    // Check privacy level
    switch (privacySettings.level) {
      case PrivacyLevel.public:
        return true;
        
      case PrivacyLevel.friends:
        return relationship.isFriend;
        
      case PrivacyLevel.friendsOfFriends:
        return relationship.isFriend || relationship.mutualFriendsCount > 0;
        
      case PrivacyLevel.private:
        return false;
        
      case PrivacyLevel.custom:
        return _checkCustomPrivacy(currentUserId, privacySettings.customSettings);
    }
  }

  /// Filter content list based on privacy permissions
  static List<T> filterContentByPrivacy<T>(
    List<T> content,
    String currentUserId,
    T Function(T) getItem,
    String Function(T) getAuthorId,
    PostPrivacySettings Function(T) getPrivacySettings,
    UserRelationshipData Function(String) getRelationship,
    List<String> blockedUsers,
  ) {
    return content.where((item) {
      final authorId = getAuthorId(item);
      final privacy = getPrivacySettings(item);
      final relationship = getRelationship(authorId);
      
      return canViewPost(currentUserId, authorId, privacy, relationship, blockedUsers);
    }).toList();
  }

  /// Apply blocked user filters to content
  static List<T> applyBlockedUserFilters<T>(
    List<T> content,
    String currentUserId,
    String Function(T) getAuthorId,
    List<String> Function(T) getMentionedUsers,
    List<String> blockedByCurrentUser,
    List<String> blockedByUsers,
  ) {
    return content.where((item) {
      final authorId = getAuthorId(item);
      final mentionedUsers = getMentionedUsers(item);
      
      // Filter out content from blocked users
      if (blockedByCurrentUser.contains(authorId) || blockedByUsers.contains(currentUserId)) {
        return false;
      }
      
      // Filter out content that mentions blocked users
      if (mentionedUsers.any((userId) => 
          blockedByCurrentUser.contains(userId) || blockedByUsers.contains(userId))) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Check if user can send messages to another user
  static MessagePermissionResult checkMessagingPermissions(
    String senderId,
    String receiverId,
    UserRelationshipData relationship,
    MessagingPrivacySettings receiverSettings,
    List<String> blockedUsers,
    List<String> mutedUsers,
  ) {
    // Check if blocked
    if (blockedUsers.contains(senderId) || blockedUsers.contains(receiverId)) {
      return MessagePermissionResult.blocked('User is blocked');
    }
    
    // Can't message yourself
    if (senderId == receiverId) {
      return MessagePermissionResult.denied('Cannot message yourself');
    }
    
    // Check if muted (can still receive but notifications are silenced)
    final isMuted = mutedUsers.contains(senderId);
    
    // Check messaging privacy settings
    switch (receiverSettings.whoCanMessage) {
      case MessagingPrivacy.everyone:
        return MessagePermissionResult.allowed(isMuted: isMuted);
        
      case MessagingPrivacy.friends:
        if (!relationship.isFriend) {
          return MessagePermissionResult.denied('Only friends can send messages');
        }
        return MessagePermissionResult.allowed(isMuted: isMuted);
        
      case MessagingPrivacy.friendsOfFriends:
        if (!relationship.isFriend && relationship.mutualFriendsCount == 0) {
          return MessagePermissionResult.denied('Only friends and friends of friends can send messages');
        }
        return MessagePermissionResult.allowed(isMuted: isMuted);
        
      case MessagingPrivacy.nobody:
        return MessagePermissionResult.denied('User is not accepting messages');
        
      case MessagingPrivacy.custom:
        final isAllowed = receiverSettings.customAllowedUsers?.contains(senderId) ?? false;
        if (!isAllowed) {
          return MessagePermissionResult.denied('Not in allowed users list');
        }
        return MessagePermissionResult.allowed(isMuted: isMuted);
    }
  }

  /// Validate friend request permissions
  static FriendRequestPermissionResult checkFriendRequestPermissions(
    String requesterId,
    String targetUserId,
    UserRelationshipData currentRelationship,
    FriendRequestPrivacySettings targetSettings,
    List<String> blockedUsers,
    UserAccountInfo requesterAccount,
  ) {
    // Check if blocked
    if (blockedUsers.contains(requesterId) || blockedUsers.contains(targetUserId)) {
      return FriendRequestPermissionResult.blocked('User is blocked');
    }
    
    // Can't friend yourself
    if (requesterId == targetUserId) {
      return FriendRequestPermissionResult.denied('Cannot send friend request to yourself');
    }
    
    // Check existing relationship
    if (currentRelationship.isFriend) {
      return FriendRequestPermissionResult.denied('Already friends');
    }
    
    if (currentRelationship.hasPendingRequestFrom) {
      return FriendRequestPermissionResult.denied('Friend request already received');
    }
    
    if (currentRelationship.hasPendingRequestTo) {
      return FriendRequestPermissionResult.denied('Friend request already sent');
    }
    
    // Check account age requirement
    if (targetSettings.requireMinimumAccountAge) {
      final accountAge = DateTime.now().difference(requesterAccount.createdAt);
      if (accountAge.inHours < SocialConstants.minAccountAgeForPosting) {
        return FriendRequestPermissionResult.denied('Account too new to send friend requests');
      }
    }
    
    // Check friend request privacy settings
    switch (targetSettings.whoCanSendRequests) {
      case FriendRequestPrivacy.everyone:
        return FriendRequestPermissionResult.allowed();
        
      case FriendRequestPrivacy.friendsOfFriends:
        if (currentRelationship.mutualFriendsCount == 0) {
          return FriendRequestPermissionResult.denied('Only friends of friends can send requests');
        }
        return FriendRequestPermissionResult.allowed();
        
      case FriendRequestPrivacy.nobody:
        return FriendRequestPermissionResult.denied('User is not accepting friend requests');
        
      case FriendRequestPrivacy.custom:
        final isAllowed = targetSettings.customAllowedUsers?.contains(requesterId) ?? false;
        if (!isAllowed) {
          return FriendRequestPermissionResult.denied('Not in allowed users list');
        }
        return FriendRequestPermissionResult.allowed();
    }
  }

  /// Check if user can see another user's profile
  static bool canViewProfile(
    String viewerId,
    String profileOwnerId,
    UserRelationshipData relationship,
    ProfilePrivacySettings profileSettings,
    List<String> blockedUsers,
  ) {
    // Check if blocked
    if (blockedUsers.contains(viewerId) || blockedUsers.contains(profileOwnerId)) {
      return false;
    }
    
    // Owner can always see their own profile
    if (viewerId == profileOwnerId) {
      return true;
    }
    
    // Check profile privacy
    switch (profileSettings.visibility) {
      case ProfileVisibility.public:
        return true;
        
      case ProfileVisibility.friends:
        return relationship.isFriend;
        
      case ProfileVisibility.friendsOfFriends:
        return relationship.isFriend || relationship.mutualFriendsCount > 0;
        
      case ProfileVisibility.private:
        return false;
        
      case ProfileVisibility.custom:
        return profileSettings.customAllowedUsers?.contains(viewerId) ?? false;
    }
  }

  /// Get visible profile sections based on privacy settings
  static Set<ProfileSection> getVisibleProfileSections(
    String viewerId,
    String profileOwnerId,
    UserRelationshipData relationship,
    Map<ProfileSection, ProfileSectionPrivacy> sectionPrivacy,
    List<String> blockedUsers,
  ) {
    final visibleSections = <ProfileSection>{};
    
    // Check if blocked
    if (blockedUsers.contains(viewerId) || blockedUsers.contains(profileOwnerId)) {
      return visibleSections;
    }
    
    // Owner can see all sections
    if (viewerId == profileOwnerId) {
      return ProfileSection.values.toSet();
    }
    
    for (final entry in sectionPrivacy.entries) {
      final section = entry.key;
      final privacy = entry.value;
      
      final canView = _checkSectionPrivacy(viewerId, relationship, privacy);
      if (canView) {
        visibleSections.add(section);
      }
    }
    
    return visibleSections;
  }

  /// Filter user search results based on privacy
  static List<UserSearchResult> filterSearchResults(
    List<UserSearchResult> results,
    String searcherId,
    UserRelationshipData Function(String) getRelationship,
    ProfilePrivacySettings Function(String) getPrivacySettings,
    List<String> blockedUsers,
  ) {
    return results.where((result) {
      final relationship = getRelationship(result.userId);
      final privacySettings = getPrivacySettings(result.userId);
      
      return canViewProfile(searcherId, result.userId, relationship, privacySettings, blockedUsers);
    }).toList();
  }

  /// Check content moderation status
  static ContentModerationResult checkContentModeration(
    String content,
    List<String> images,
    String authorId,
    UserAccountInfo authorAccount,
    ContentModerationSettings settings,
  ) {
    final issues = <ModerationIssue>[];
    
    // Check for inappropriate language
    if (settings.enableProfanityFilter && _containsProfanity(content)) {
      issues.add(ModerationIssue.profanity);
    }
    
    // Check for spam patterns
    if (_isSpamContent(content, authorAccount)) {
      issues.add(ModerationIssue.spam);
    }
    
    // Check for excessive caps
    if (_hasExcessiveCaps(content)) {
      issues.add(ModerationIssue.excessiveCaps);
    }
    
    // Check for too many links
    if (_hasTooManyLinks(content)) {
      issues.add(ModerationIssue.tooManyLinks);
    }
    
    // Check account restrictions
    if (authorAccount.isNewAccount && settings.restrictNewAccounts) {
      issues.add(ModerationIssue.newAccountRestriction);
    }
    
    if (issues.isEmpty) {
      return ContentModerationResult.approved();
    }
    
    final severity = _calculateModerationSeverity(issues);
    return ContentModerationResult.flagged(issues, severity);
  }

  /// Apply age-appropriate content filtering
  static List<T> filterAgeAppropriateContent<T>(
    List<T> content,
    int viewerAge,
    ContentRating Function(T) getContentRating,
  ) {
    return content.where((item) {
      final rating = getContentRating(item);
      return _isAgeAppropriate(rating, viewerAge);
    }).toList();
  }

  // Private helper methods
  static bool _checkCustomPrivacy(String userId, CustomPrivacySettings? settings) {
    if (settings == null) return false;
    
    if (settings.allowedUsers.contains(userId)) return true;
    if (settings.blockedUsers.contains(userId)) return false;
    
    // Check group memberships, mutual friends, etc.
    // This would be more complex in a real implementation
    return false;
  }

  static bool _checkSectionPrivacy(
    String viewerId,
    UserRelationshipData relationship,
    ProfileSectionPrivacy privacy,
  ) {
    switch (privacy) {
      case ProfileSectionPrivacy.public:
        return true;
      case ProfileSectionPrivacy.friends:
        return relationship.isFriend;
      case ProfileSectionPrivacy.private:
        return false;
    }
  }

  static bool _containsProfanity(String content) {
    // Simple profanity check - in production use proper content moderation service
    final profanityWords = ['badword1', 'badword2']; // Placeholder
    final lowerContent = content.toLowerCase();
    return profanityWords.any((word) => lowerContent.contains(word));
  }

  static bool _isSpamContent(String content, UserAccountInfo account) {
    // Simple spam detection
    final urlCount = RegExp(SocialConstants.urlPattern).allMatches(content).length;
    if (urlCount > 3) return true;
    
    // Check if new account posting many links
    if (account.isNewAccount && urlCount > 0) return true;
    
    return false;
  }

  static bool _hasExcessiveCaps(String content) {
    if (content.length < 10) return false;
    final capsCount = content.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
    return (capsCount / content.length) > 0.7;
  }

  static bool _hasTooManyLinks(String content) {
    final urlCount = RegExp(SocialConstants.urlPattern).allMatches(content).length;
    return urlCount > SocialConstants.maxLinksPerPost;
  }

  static ModerationSeverity _calculateModerationSeverity(List<ModerationIssue> issues) {
    if (issues.contains(ModerationIssue.profanity)) return ModerationSeverity.high;
    if (issues.contains(ModerationIssue.spam)) return ModerationSeverity.medium;
    return ModerationSeverity.low;
  }

  static bool _isAgeAppropriate(ContentRating rating, int viewerAge) {
    switch (rating) {
      case ContentRating.general:
        return true;
      case ContentRating.teen:
        return viewerAge >= 13;
      case ContentRating.mature:
        return viewerAge >= 17;
      case ContentRating.adult:
        return viewerAge >= 18;
    }
  }
}

// Data classes and enums for privacy helpers
class PostPrivacySettings {
  final PrivacyLevel level;
  final CustomPrivacySettings? customSettings;

  const PostPrivacySettings({
    required this.level,
    this.customSettings,
  });
}

class CustomPrivacySettings {
  final List<String> allowedUsers;
  final List<String> blockedUsers;
  final List<String> allowedGroups;

  const CustomPrivacySettings({
    this.allowedUsers = const [],
    this.blockedUsers = const [],
    this.allowedGroups = const [],
  });
}

class UserRelationshipData {
  final bool isFriend;
  final bool hasPendingRequestFrom;
  final bool hasPendingRequestTo;
  final int mutualFriendsCount;

  const UserRelationshipData({
    required this.isFriend,
    required this.hasPendingRequestFrom,
    required this.hasPendingRequestTo,
    required this.mutualFriendsCount,
  });
}

class MessagingPrivacySettings {
  final MessagingPrivacy whoCanMessage;
  final List<String>? customAllowedUsers;

  const MessagingPrivacySettings({
    required this.whoCanMessage,
    this.customAllowedUsers,
  });
}

class FriendRequestPrivacySettings {
  final FriendRequestPrivacy whoCanSendRequests;
  final bool requireMinimumAccountAge;
  final List<String>? customAllowedUsers;

  const FriendRequestPrivacySettings({
    required this.whoCanSendRequests,
    this.requireMinimumAccountAge = true,
    this.customAllowedUsers,
  });
}

class ProfilePrivacySettings {
  final ProfileVisibility visibility;
  final List<String>? customAllowedUsers;

  const ProfilePrivacySettings({
    required this.visibility,
    this.customAllowedUsers,
  });
}

class MessagePermissionResult {
  final bool isAllowed;
  final bool isMuted;
  final String? reason;

  const MessagePermissionResult._({
    required this.isAllowed,
    this.isMuted = false,
    this.reason,
  });

  factory MessagePermissionResult.allowed({bool isMuted = false}) =>
      MessagePermissionResult._(isAllowed: true, isMuted: isMuted);

  factory MessagePermissionResult.denied(String reason) =>
      MessagePermissionResult._(isAllowed: false, reason: reason);

  factory MessagePermissionResult.blocked(String reason) =>
      MessagePermissionResult._(isAllowed: false, reason: reason);
}

class FriendRequestPermissionResult {
  final bool isAllowed;
  final String? reason;

  const FriendRequestPermissionResult._({required this.isAllowed, this.reason});

  factory FriendRequestPermissionResult.allowed() =>
      const FriendRequestPermissionResult._(isAllowed: true);

  factory FriendRequestPermissionResult.denied(String reason) =>
      FriendRequestPermissionResult._(isAllowed: false, reason: reason);

  factory FriendRequestPermissionResult.blocked(String reason) =>
      FriendRequestPermissionResult._(isAllowed: false, reason: reason);
}

class UserAccountInfo {
  final DateTime createdAt;
  final bool isVerified;
  final int trustScore;

  const UserAccountInfo({
    required this.createdAt,
    this.isVerified = false,
    this.trustScore = 0,
  });

  bool get isNewAccount => DateTime.now().difference(createdAt).inDays < 30;
}

class UserSearchResult {
  final String userId;
  final String displayName;
  final String? profileImage;

  const UserSearchResult({
    required this.userId,
    required this.displayName,
    this.profileImage,
  });
}

class ContentModerationSettings {
  final bool enableProfanityFilter;
  final bool restrictNewAccounts;
  final bool autoModerateSpam;

  const ContentModerationSettings({
    this.enableProfanityFilter = true,
    this.restrictNewAccounts = true,
    this.autoModerateSpam = true,
  });
}

class ContentModerationResult {
  final bool isApproved;
  final List<ModerationIssue> issues;
  final ModerationSeverity severity;

  const ContentModerationResult._({
    required this.isApproved,
    required this.issues,
    required this.severity,
  });

  factory ContentModerationResult.approved() =>
      const ContentModerationResult._(
        isApproved: true,
        issues: [],
        severity: ModerationSeverity.none,
      );

  factory ContentModerationResult.flagged(List<ModerationIssue> issues, ModerationSeverity severity) =>
      ContentModerationResult._(
        isApproved: false,
        issues: issues,
        severity: severity,
      );
}

enum PrivacyLevel {
  public,
  friends,
  friendsOfFriends,
  private,
  custom,
}

enum MessagingPrivacy {
  everyone,
  friends,
  friendsOfFriends,
  nobody,
  custom,
}

enum FriendRequestPrivacy {
  everyone,
  friendsOfFriends,
  nobody,
  custom,
}

enum ProfileVisibility {
  public,
  friends,
  friendsOfFriends,
  private,
  custom,
}

enum ProfileSection {
  basicInfo,
  contactInfo,
  friends,
  posts,
  photos,
  activities,
  interests,
  workEducation,
}

enum ProfileSectionPrivacy {
  public,
  friends,
  private,
}

enum ModerationIssue {
  profanity,
  spam,
  excessiveCaps,
  tooManyLinks,
  newAccountRestriction,
}

enum ModerationSeverity {
  none,
  low,
  medium,
  high,
}

enum ContentRating {
  general,
  teen,
  mature,
  adult,
}
