/// Helper class for privacy management, access control, and settings validation
library;
import '../enums/privacy_level_enums.dart';
import '../constants/privacy_constants.dart';

/// Temporary model classes for privacy helper
/// TODO: Replace with actual models from features/profile/data/models/
class PrivacySettings {
  final String profileVisibility;
  final bool showRealName;
  final bool showEmail;
  final bool showPhone;
  final bool showLocation;
  final bool showAge;
  final bool showGender;
  final bool showSportsStats;
  final bool showGameHistory;
  final bool showOnlineStatus;
  final bool showLastActive;
  final bool showAchievements;
  final bool showFriendsList;
  final bool allowMessages;
  final bool allowFriendRequests;
  final bool allowGameInvites;
  final bool allowGroupInvites;
  final bool allowMessagesFromStrangers;
  final bool appearInSearch;
  final bool showInSuggestions;
  final bool allowDiscoveryByEmail;
  final bool allowDiscoveryByPhone;
  final bool analyticsEnabled;
  final bool personalizationEnabled;
  final bool marketingEmails;
  final bool crashReporting;
  final bool locationServices;
  final bool preciseLocation;
  final bool locationHistory;
  final bool nearbyUsers;
  
  const PrivacySettings({
    this.profileVisibility = 'friends',
    this.showRealName = true,
    this.showEmail = false,
    this.showPhone = false,
    this.showLocation = false,
    this.showAge = true,
    this.showGender = false,
    this.showSportsStats = true,
    this.showGameHistory = true,
    this.showOnlineStatus = true,
    this.showLastActive = false,
    this.showAchievements = true,
    this.showFriendsList = false,
    this.allowMessages = true,
    this.allowFriendRequests = true,
    this.allowGameInvites = true,
    this.allowGroupInvites = true,
    this.allowMessagesFromStrangers = false,
    this.appearInSearch = true,
    this.showInSuggestions = true,
    this.allowDiscoveryByEmail = false,
    this.allowDiscoveryByPhone = false,
    this.analyticsEnabled = true,
    this.personalizationEnabled = true,
    this.marketingEmails = false,
    this.crashReporting = true,
    this.locationServices = false,
    this.preciseLocation = false,
    this.locationHistory = false,
    this.nearbyUsers = false,
  });

  PrivacySettings copyWith({
    String? profileVisibility,
    bool? showRealName,
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showAge,
    bool? showGender,
    bool? showSportsStats,
    bool? showGameHistory,
    bool? showOnlineStatus,
    bool? showLastActive,
    bool? showAchievements,
    bool? showFriendsList,
    bool? allowMessages,
    bool? allowFriendRequests,
    bool? allowGameInvites,
    bool? allowGroupInvites,
    bool? allowMessagesFromStrangers,
    bool? appearInSearch,
    bool? showInSuggestions,
    bool? allowDiscoveryByEmail,
    bool? allowDiscoveryByPhone,
    bool? analyticsEnabled,
    bool? personalizationEnabled,
    bool? marketingEmails,
    bool? crashReporting,
    bool? locationServices,
    bool? preciseLocation,
    bool? locationHistory,
    bool? nearbyUsers,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showRealName: showRealName ?? this.showRealName,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showLocation: showLocation ?? this.showLocation,
      showAge: showAge ?? this.showAge,
      showGender: showGender ?? this.showGender,
      showSportsStats: showSportsStats ?? this.showSportsStats,
      showGameHistory: showGameHistory ?? this.showGameHistory,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastActive: showLastActive ?? this.showLastActive,
      showAchievements: showAchievements ?? this.showAchievements,
      showFriendsList: showFriendsList ?? this.showFriendsList,
      allowMessages: allowMessages ?? this.allowMessages,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowGameInvites: allowGameInvites ?? this.allowGameInvites,
      allowGroupInvites: allowGroupInvites ?? this.allowGroupInvites,
      allowMessagesFromStrangers: allowMessagesFromStrangers ?? this.allowMessagesFromStrangers,
      appearInSearch: appearInSearch ?? this.appearInSearch,
      showInSuggestions: showInSuggestions ?? this.showInSuggestions,
      allowDiscoveryByEmail: allowDiscoveryByEmail ?? this.allowDiscoveryByEmail,
      allowDiscoveryByPhone: allowDiscoveryByPhone ?? this.allowDiscoveryByPhone,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      personalizationEnabled: personalizationEnabled ?? this.personalizationEnabled,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      crashReporting: crashReporting ?? this.crashReporting,
      locationServices: locationServices ?? this.locationServices,
      preciseLocation: preciseLocation ?? this.preciseLocation,
      locationHistory: locationHistory ?? this.locationHistory,
      nearbyUsers: nearbyUsers ?? this.nearbyUsers,
    );
  }
}

/// Comprehensive privacy helper for access control and settings management
class PrivacyHelper {
  /// Check if a user can view another user's profile
  static bool canViewProfile({
    required PrivacyLevel privacyLevel,
    required String viewerId,
    required String profileOwnerId,
    required bool isFriend,
    bool isBlocked = false,
    bool isFollowing = false,
  }) {
    // Owner can always view their own profile
    if (viewerId == profileOwnerId) return true;
    
    // Blocked users cannot view profile
    if (isBlocked) return false;
    
    return privacyLevel.canView(isFriend, false);
  }

  /// Check if a user can view another user's profile with string privacy level
  static bool canViewProfileByLevel({
    required String privacyLevel,
    required String viewerId,
    required String profileOwnerId,
    required bool isFriend,
    bool isBlocked = false,
  }) {
    final level = PrivacyLevel.fromString(privacyLevel);
    return canViewProfile(
      privacyLevel: level,
      viewerId: viewerId,
      profileOwnerId: profileOwnerId,
      isFriend: isFriend,
      isBlocked: isBlocked,
    );
  }

  /// Get map of visible profile fields based on privacy settings
  static Map<String, bool> getVisibleFields(
    PrivacySettings settings, {
    required bool isOwner,
    required bool isFriend,
    bool isBlocked = false,
  }) {
    // If blocked, show minimal information
    if (isBlocked && !isOwner) {
      return {
        'username': true,
        'fullName': false,
        'email': false,
        'phone': false,
        'location': false,
        'age': false,
        'gender': false,
        'bio': false,
        'sportsStats': false,
        'gameHistory': false,
        'onlineStatus': false,
        'lastActive': false,
        'achievements': false,
        'friendsList': false,
      };
    }

    // Owner sees everything
    if (isOwner) {
      return {
        'username': true,
        'fullName': true,
        'email': true,
        'phone': true,
        'location': true,
        'age': true,
        'gender': true,
        'bio': true,
        'sportsStats': true,
        'gameHistory': true,
        'onlineStatus': true,
        'lastActive': true,
        'achievements': true,
        'friendsList': true,
      };
    }

    final profileLevel = PrivacyLevel.fromString(settings.profileVisibility);
    final canViewProfile = profileLevel.canView(isFriend, isOwner);
    
    if (!canViewProfile) {
      return {
        'username': true,
        'fullName': false,
        'email': false,
        'phone': false,
        'location': false,
        'age': false,
        'gender': false,
        'bio': false,
        'sportsStats': false,
        'gameHistory': false,
        'onlineStatus': false,
        'lastActive': false,
        'achievements': false,
        'friendsList': false,
      };
    }

    return {
      'username': true,
      'fullName': settings.showRealName,
      'email': settings.showEmail,
      'phone': settings.showPhone,
      'location': settings.showLocation,
      'age': settings.showAge,
      'gender': settings.showGender,
      'bio': true, // Bio visibility follows profile visibility
      'sportsStats': settings.showSportsStats,
      'gameHistory': settings.showGameHistory,
      'onlineStatus': settings.showOnlineStatus,
      'lastActive': settings.showLastActive,
      'achievements': settings.showAchievements,
      'friendsList': settings.showFriendsList,
    };
  }

  /// Apply privacy preset (public, friends, private)
  static PrivacySettings applyPrivacyPreset(String preset) {
    switch (preset.toLowerCase()) {
      case 'public':
        return const PrivacySettings(
          profileVisibility: PrivacyLevels.publicPrivacy,
          showRealName: true,
          showLocation: true,
          showAge: true,
          showSportsStats: true,
          showGameHistory: true,
          showOnlineStatus: true,
          showAchievements: true,
          allowMessages: true,
          allowFriendRequests: true,
          allowGameInvites: true,
          allowMessagesFromStrangers: false,
          appearInSearch: true,
          showInSuggestions: true,
        );
        
      case 'friends':
        return const PrivacySettings(
          profileVisibility: PrivacyLevels.friendsPrivacy,
          showRealName: true,
          showLocation: false,
          showAge: true,
          showSportsStats: true,
          showGameHistory: false,
          showOnlineStatus: true,
          showLastActive: false,
          showAchievements: true,
          allowMessages: true,
          allowFriendRequests: true,
          allowGameInvites: true,
          allowMessagesFromStrangers: false,
          appearInSearch: false,
          showInSuggestions: true,
        );
        
      case 'private':
        return const PrivacySettings(
          profileVisibility: PrivacyLevels.privatePrivacy,
          showRealName: false,
          showLocation: false,
          showAge: false,
          showSportsStats: false,
          showGameHistory: false,
          showOnlineStatus: false,
          showLastActive: false,
          showAchievements: false,
          showFriendsList: false,
          allowMessages: false,
          allowFriendRequests: false,
          allowGameInvites: false,
          allowMessagesFromStrangers: false,
          appearInSearch: false,
          showInSuggestions: false,
        );
        
      default:
        return const PrivacySettings(); // Default friends settings
    }
  }

  /// Get privacy warnings when changing settings
  static List<String> getPrivacyWarnings(
    PrivacySettings oldSettings,
    PrivacySettings newSettings,
  ) {
    final warnings = <String>[];
    
    // Profile visibility warnings
    if (oldSettings.profileVisibility == PrivacyLevels.privatePrivacy && 
        newSettings.profileVisibility != PrivacyLevels.privatePrivacy) {
      warnings.add(PrivacyMessages.publicProfileWarning);
    }
    
    // Location sharing warnings
    if (!oldSettings.showLocation && newSettings.showLocation) {
      warnings.add(PrivacyMessages.locationSharingWarning);
    }
    
    // Location services warnings
    if (!oldSettings.locationServices && newSettings.locationServices) {
      warnings.add('Location services will access your device location');
    }
    
    // Messaging warnings
    if (!oldSettings.allowMessages && newSettings.allowMessages) {
      warnings.add('Other users will be able to message you');
    }
    
    // Stranger messaging warnings
    if (!oldSettings.allowMessagesFromStrangers && newSettings.allowMessagesFromStrangers) {
      warnings.add('Anyone will be able to send you messages, even if you\'re not friends');
    }
    
    // Search visibility warnings
    if (!oldSettings.appearInSearch && newSettings.appearInSearch) {
      warnings.add('Your profile will appear in search results');
    }
    
    // Email discovery warnings
    if (!oldSettings.allowDiscoveryByEmail && newSettings.allowDiscoveryByEmail) {
      warnings.add('People who have your email address can find your profile');
    }
    
    // Phone discovery warnings
    if (!oldSettings.allowDiscoveryByPhone && newSettings.allowDiscoveryByPhone) {
      warnings.add('People who have your phone number can find your profile');
    }
    
    // Marketing email warnings
    if (!oldSettings.marketingEmails && newSettings.marketingEmails) {
      warnings.add('You will receive promotional emails and offers');
    }
    
    return warnings;
  }

  /// Get privacy recommendations based on user behavior
  static List<String> getPrivacyRecommendations(
    PrivacySettings settings,
    Map<String, dynamic> userContext,
  ) {
    final recommendations = <String>[];
    
    // Age-based recommendations
    final age = userContext['age'] as int?;
    if (age != null && age < 18) {
      if (settings.profileVisibility == PrivacyLevels.publicPrivacy) {
        recommendations.add('Consider setting your profile to "Friends Only" for better privacy');
      }
      if (settings.showLocation) {
        recommendations.add('We recommend hiding your location for safety');
      }
    }
    
    // New user recommendations
    final accountAge = userContext['accountAgeInDays'] as int?;
    if (accountAge != null && accountAge < 30) {
      recommendations.add('Review your privacy settings as you get familiar with the app');
      if (settings.allowMessagesFromStrangers) {
        recommendations.add('Consider restricting messages to friends only while you\'re new');
      }
    }
    
    // Activity-based recommendations
    final gamesPlayed = userContext['totalGamesPlayed'] as int?;
    if (gamesPlayed != null && gamesPlayed > 50) {
      if (!settings.showSportsStats) {
        recommendations.add('Consider showing your sports stats to help others find suitable game partners');
      }
    }
    
    // Location-based recommendations
    final hasLocationEnabled = userContext['hasLocationEnabled'] as bool? ?? false;
    if (hasLocationEnabled && !settings.showLocation) {
      recommendations.add('Consider showing your general location to find nearby games');
    }
    
    return recommendations;
  }

  /// Check if user can perform specific actions
  static bool canSendMessage({
    required PrivacySettings recipientSettings,
    required bool isFriend,
    required bool isBlocked,
  }) {
    if (isBlocked) return false;
    if (!recipientSettings.allowMessages) return false;
    if (!isFriend && !recipientSettings.allowMessagesFromStrangers) return false;
    
    return true;
  }

  static bool canSendFriendRequest({
    required PrivacySettings recipientSettings,
    required bool isBlocked,
    required bool alreadyFriends,
  }) {
    if (isBlocked || alreadyFriends) return false;
    return recipientSettings.allowFriendRequests;
  }

  static bool canInviteToGame({
    required PrivacySettings recipientSettings,
    required bool isFriend,
    required bool isBlocked,
  }) {
    if (isBlocked) return false;
    if (!recipientSettings.allowGameInvites) return false;
    
    // Game invites typically require friendship or public profile
    final profileLevel = PrivacyLevel.fromString(recipientSettings.profileVisibility);
    return profileLevel == PrivacyLevel.public || isFriend;
  }

  /// Validate privacy settings for consistency
  static Map<String, String> validatePrivacySettings(PrivacySettings settings) {
    final errors = <String, String>{};
    
    // Location consistency checks
    if (settings.preciseLocation && !settings.locationServices) {
      errors['preciseLocation'] = 'Precise location requires location services to be enabled';
    }
    
    if (settings.locationHistory && !settings.locationServices) {
      errors['locationHistory'] = 'Location history requires location services to be enabled';
    }
    
    if (settings.nearbyUsers && !settings.showLocation) {
      errors['nearbyUsers'] = 'Showing nearby users requires location visibility to be enabled';
    }
    
    // Discovery consistency checks
    if (settings.allowDiscoveryByEmail && !settings.appearInSearch) {
      errors['allowDiscoveryByEmail'] = 'Email discovery works best with search visibility enabled';
    }
    
    // Private profile consistency
    if (settings.profileVisibility == PrivacyLevels.privatePrivacy) {
      if (settings.allowMessagesFromStrangers) {
        errors['allowMessagesFromStrangers'] = 'Private profiles cannot receive messages from strangers';
      }
      if (settings.appearInSearch) {
        errors['appearInSearch'] = 'Private profiles should not appear in search results';
      }
    }
    
    return errors;
  }

  /// Get privacy level description for users
  static String getPrivacyLevelDescription(String privacyLevel) {
    final level = PrivacyLevel.fromString(privacyLevel);
    return level.description;
  }

  /// Get privacy impact summary
  static Map<String, dynamic> getPrivacyImpactSummary(PrivacySettings settings) {
    final level = PrivacyLevel.fromString(settings.profileVisibility);
    
    return {
      'privacy_level': level.displayName,
      'visibility': level.description,
      'can_be_discovered': settings.appearInSearch,
      'allows_messages': settings.allowMessages,
      'allows_stranger_messages': settings.allowMessagesFromStrangers,
      'shows_location': settings.showLocation,
      'shows_activity': settings.showOnlineStatus,
      'data_collection': {
        'analytics': settings.analyticsEnabled,
        'personalization': settings.personalizationEnabled,
        'marketing': settings.marketingEmails,
        'crash_reports': settings.crashReporting,
      },
      'location_tracking': {
        'basic': settings.locationServices,
        'precise': settings.preciseLocation,
        'history': settings.locationHistory,
      },
    };
  }

  /// Generate privacy audit report
  static Map<String, dynamic> generatePrivacyAudit(
    PrivacySettings settings,
    DateTime lastUpdated,
  ) {
    final daysSinceUpdate = DateTime.now().difference(lastUpdated).inDays;
    final recommendations = <String>[];
    
    // Check for outdated settings
    if (daysSinceUpdate > 90) {
      recommendations.add('Review your privacy settings (last updated $daysSinceUpdate days ago)');
    }
    
    // Check for high-risk settings
    if (settings.profileVisibility == PrivacyLevels.publicPrivacy && 
        settings.showLocation && 
        settings.allowMessagesFromStrangers) {
      recommendations.add('Consider increasing your privacy level due to multiple public settings');
    }
    
    return {
      'last_updated_days_ago': daysSinceUpdate,
      'privacy_score': _calculatePrivacyScore(settings),
      'recommendations': recommendations,
      'high_risk_settings': _getHighRiskSettings(settings),
      'data_sharing_summary': _getDataSharingSummary(settings),
    };
  }

  /// Private helper methods
  static double _calculatePrivacyScore(PrivacySettings settings) {
    double score = 100.0; // Start with max privacy
    
    // Deduct points for public settings
    if (settings.profileVisibility == PrivacyLevels.publicPrivacy) score -= 20;
    if (settings.showLocation) score -= 15;
    if (settings.allowMessagesFromStrangers) score -= 10;
    if (settings.appearInSearch) score -= 10;
    if (settings.showOnlineStatus) score -= 5;
    if (settings.allowDiscoveryByEmail) score -= 10;
    if (settings.allowDiscoveryByPhone) score -= 10;
    if (settings.marketingEmails) score -= 5;
    if (settings.locationHistory) score -= 10;
    if (settings.preciseLocation) score -= 5;
    
    return score.clamp(0, 100);
  }

  static List<String> _getHighRiskSettings(PrivacySettings settings) {
    final risks = <String>[];
    
    if (settings.profileVisibility == PrivacyLevels.publicPrivacy && 
        settings.showLocation) {
      risks.add('Public profile with location visible');
    }
    
    if (settings.allowMessagesFromStrangers && settings.showLocation) {
      risks.add('Strangers can message you and see your location');
    }
    
    if (settings.preciseLocation && settings.locationHistory) {
      risks.add('Detailed location tracking enabled');
    }
    
    return risks;
  }

  static Map<String, bool> _getDataSharingSummary(PrivacySettings settings) {
    return {
      'profile_data': settings.profileVisibility != PrivacyLevels.privatePrivacy,
      'location_data': settings.locationServices,
      'usage_analytics': settings.analyticsEnabled,
      'personalization_data': settings.personalizationEnabled,
      'marketing_data': settings.marketingEmails,
      'crash_data': settings.crashReporting,
    };
  }
}
