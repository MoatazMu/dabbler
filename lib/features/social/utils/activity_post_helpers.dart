import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/enums/social_enums.dart';
import '../services/activity_post_service.dart';

/// Helper functions to automatically create activity posts from existing workflows
/// These functions should be called whenever users perform actions in the app
class ActivityPostHelpers {
  static ActivityPostService? _activityService;
  
  /// Initialize the helper with an activity service instance
  static void initialize(ActivityPostService activityService) {
    _activityService = activityService;
  }
  
  /// Helper for comment actions - creates activity post when user comments
  static Future<void> onUserComment({
    required String commentContent,
    required String originalPostId,
    ActivityPrivacyLevel privacy = ActivityPrivacyLevel.thread,
    bool createActivityPost = true,
  }) async {
    if (!createActivityPost || _activityService == null) return;
    
    try {
      await _activityService!.createCommentPost(
        commentContent: commentContent,
        originalPostId: originalPostId,
        privacy: privacy,
      );
    } catch (e) {
      // Log error but don't fail the original comment action
      print('Failed to create comment activity post: $e');
    }
  }
  
  /// Helper for venue rating actions
  static Future<void> onVenueRated({
    required String venueName,
    required double rating,
    String? review,
    List<String> mediaUrls = const [],
    ActivityPrivacyLevel privacy = ActivityPrivacyLevel.public,
    bool createActivityPost = true,
  }) async {
    if (!createActivityPost || _activityService == null) return;
    
    try {
      await _activityService!.createVenueRatingPost(
        venueName: venueName,
        rating: rating,
        review: review,
        mediaUrls: mediaUrls,
        privacy: privacy,
      );
    } catch (e) {
      print('Failed to create venue rating activity post: $e');
    }
  }
  
  /// Helper for game creation actions
  static Future<void> onGameCreated({
    required String gameType,
    required String gameId,
    required String venueName,
    ActivityPrivacyLevel privacy = ActivityPrivacyLevel.public,
    bool createActivityPost = true,
  }) async {
    if (!createActivityPost || _activityService == null) return;
    
    try {
      await _activityService!.createGameCreationPost(
        gameType: gameType,
        gameId: gameId,
        venueName: venueName,
        privacy: privacy,
      );
    } catch (e) {
      print('Failed to create game creation activity post: $e');
    }
  }
  
  /// Helper for check-in actions
  static Future<void> onVenueCheckIn({
    required String venueName,
    String? note,
    List<String> mediaUrls = const [],
    List<String> taggedFriends = const [],
    ActivityPrivacyLevel privacy = ActivityPrivacyLevel.public,
    bool createActivityPost = true,
  }) async {
    if (!createActivityPost || _activityService == null) return;
    
    try {
      await _activityService!.createCheckInPost(
        venueName: venueName,
        note: note,
        mediaUrls: mediaUrls,
        taggedFriends: taggedFriends,
        privacy: privacy,
      );
    } catch (e) {
      print('Failed to create check-in activity post: $e');
    }
  }
  
  /// Helper for venue booking actions
  static Future<void> onVenueBooked({
    required String venueName,
    required DateTime bookingDate,
    ActivityPrivacyLevel privacy = ActivityPrivacyLevel.friends,
    bool createActivityPost = true,
  }) async {
    if (!createActivityPost || _activityService == null) return;
    
    try {
      await _activityService!.createVenueBookingPost(
        venueName: venueName,
        bookingDate: bookingDate,
        privacy: privacy,
      );
    } catch (e) {
      print('Failed to create venue booking activity post: $e');
    }
  }
  
  /// Helper for game join actions
  static Future<void> onGameJoined({
    required String gameType,
    required String gameId,
    required String venueName,
    ActivityPrivacyLevel privacy = ActivityPrivacyLevel.public,
    bool createActivityPost = true,
  }) async {
    if (!createActivityPost || _activityService == null) return;
    
    try {
      await _activityService!.createGameJoinPost(
        gameType: gameType,
        gameId: gameId,
        venueName: venueName,
        privacy: privacy,
      );
    } catch (e) {
      print('Failed to create game join activity post: $e');
    }
  }
  
  /// Helper for achievement earned actions
  static Future<void> onAchievementEarned({
    required String achievementName,
    String? achievementDescription,
    List<String> mediaUrls = const [],
    ActivityPrivacyLevel privacy = ActivityPrivacyLevel.public,
    bool createActivityPost = true,
  }) async {
    if (!createActivityPost || _activityService == null) return;
    
    try {
      await _activityService!.createAchievementPost(
        achievementName: achievementName,
        achievementDescription: achievementDescription,
        mediaUrls: mediaUrls,
        privacy: privacy,
      );
    } catch (e) {
      print('Failed to create achievement activity post: $e');
    }
  }
}

/// Settings for controlling activity post creation
class ActivityPostSettings {
  final bool enableCommentPosts;
  final bool enableVenueRatingPosts;
  final bool enableGameCreationPosts;
  final bool enableCheckInPosts;
  final bool enableVenueBookingPosts;
  final bool enableGameJoinPosts;
  final bool enableAchievementPosts;
  final ActivityPrivacyLevel defaultPrivacy;
  
  const ActivityPostSettings({
    this.enableCommentPosts = true,
    this.enableVenueRatingPosts = true,
    this.enableGameCreationPosts = true,
    this.enableCheckInPosts = true,
    this.enableVenueBookingPosts = false, // More private by default
    this.enableGameJoinPosts = true,
    this.enableAchievementPosts = true,
    this.defaultPrivacy = ActivityPrivacyLevel.public,
  });
  
  /// Create settings with all activity posts disabled
  factory ActivityPostSettings.disabled() {
    return const ActivityPostSettings(
      enableCommentPosts: false,
      enableVenueRatingPosts: false,
      enableGameCreationPosts: false,
      enableCheckInPosts: false,
      enableVenueBookingPosts: false,
      enableGameJoinPosts: false,
      enableAchievementPosts: false,
    );
  }
  
  /// Create settings with only essential activity posts enabled
  factory ActivityPostSettings.essential() {
    return const ActivityPostSettings(
      enableCommentPosts: false, // Comments shouldn't create separate posts
      enableVenueRatingPosts: true,
      enableGameCreationPosts: true,
      enableCheckInPosts: false,
      enableVenueBookingPosts: false,
      enableGameJoinPosts: true,
      enableAchievementPosts: true,
    );
  }
  
  /// Check if activity post creation is enabled for a specific type
  bool isEnabledForType(PostActivityType type) {
    switch (type) {
      case PostActivityType.comment:
        return enableCommentPosts;
      case PostActivityType.venueRating:
        return enableVenueRatingPosts;
      case PostActivityType.gameCreation:
        return enableGameCreationPosts;
      case PostActivityType.checkIn:
        return enableCheckInPosts;
      case PostActivityType.venueBooking:
        return enableVenueBookingPosts;
      case PostActivityType.gameJoin:
        return enableGameJoinPosts;
      case PostActivityType.achievement:
        return enableAchievementPosts;
      case PostActivityType.originalPost:
        return true; // Original posts are always enabled
    }
  }
}

/// Extension methods for integrating activity helpers into existing widgets
extension ActivityPostIntegration on ActivityPostHelpers {
  /// Integration helper for comment submission forms
  static Future<void> integrateCommentSubmission({
    required String commentContent,
    required String originalPostId,
    required ActivityPostSettings settings,
  }) async {
    if (settings.enableCommentPosts) {
      await ActivityPostHelpers.onUserComment(
        commentContent: commentContent,
        originalPostId: originalPostId,
        privacy: settings.defaultPrivacy,
      );
    }
  }
  
  /// Integration helper for venue rating forms
  static Future<void> integrateVenueRating({
    required String venueName,
    required double rating,
    String? review,
    List<String> mediaUrls = const [],
    required ActivityPostSettings settings,
  }) async {
    if (settings.enableVenueRatingPosts) {
      await ActivityPostHelpers.onVenueRated(
        venueName: venueName,
        rating: rating,
        review: review,
        mediaUrls: mediaUrls,
        privacy: settings.defaultPrivacy,
      );
    }
  }
  
  /// Integration helper for game creation flows
  static Future<void> integrateGameCreation({
    required String gameType,
    required String gameId,
    required String venueName,
    required ActivityPostSettings settings,
  }) async {
    if (settings.enableGameCreationPosts) {
      await ActivityPostHelpers.onGameCreated(
        gameType: gameType,
        gameId: gameId,
        venueName: venueName,
        privacy: settings.defaultPrivacy,
      );
    }
  }
}

/// Provider for activity post settings
final activityPostSettingsProvider = StateProvider<ActivityPostSettings>((ref) {
  return const ActivityPostSettings(); // Default settings
});

/// Provider that initializes ActivityPostHelpers with the service
final activityPostHelpersProvider = Provider<void>((ref) {
  final activityService = ref.watch(activityPostServiceProvider);
  ActivityPostHelpers.initialize(activityService);
  return;
});
