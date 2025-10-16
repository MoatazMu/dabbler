import 'social_helpers.dart';

/// Helper functions for social notifications management
class NotificationHelpers {
  /// Generate notification title based on type and context
  static String generateNotificationTitle(NotificationType type, NotificationContext context) {
    switch (type) {
      case NotificationType.friendRequest:
        return 'New friend request';
        
      case NotificationType.friendAccepted:
        return 'Friend request accepted';
        
      case NotificationType.postLike:
        return context.count > 1 
            ? '${SocialHelpers.formatLargeNumber(context.count)} people liked your post'
            : '${context.actorName} liked your post';
            
      case NotificationType.postComment:
        return context.count > 1
            ? '${SocialHelpers.formatLargeNumber(context.count)} comments on your post'
            : '${context.actorName} commented on your post';
            
      case NotificationType.commentReply:
        return '${context.actorName} replied to your comment';
        
      case NotificationType.mention:
        return '${context.actorName} mentioned you';
        
      case NotificationType.message:
        return context.count > 1
            ? '${SocialHelpers.formatLargeNumber(context.count)} new messages'
            : 'New message from ${context.actorName}';
            
      case NotificationType.groupInvite:
        return 'Group invitation';
        
      case NotificationType.eventInvite:
        return 'Event invitation';
        
      case NotificationType.postShare:
        return context.count > 1
            ? '${SocialHelpers.formatLargeNumber(context.count)} people shared your post'
            : '${context.actorName} shared your post';
            
      case NotificationType.achievement:
        return 'Achievement unlocked!';
        
      case NotificationType.reminder:
        return 'Reminder';
        
      case NotificationType.system:
        return 'System notification';
    }
  }

  /// Generate notification body text
  static String generateNotificationBody(NotificationType type, NotificationContext context) {
    switch (type) {
      case NotificationType.friendRequest:
        return '${context.actorName} wants to be friends with you';
        
      case NotificationType.friendAccepted:
        return '${context.actorName} accepted your friend request';
        
      case NotificationType.postLike:
        if (context.count > 1) {
          return 'Your post "${_truncateText(context.contentPreview)}" is getting attention!';
        }
        return 'Your post "${_truncateText(context.contentPreview)}"';
        
      case NotificationType.postComment:
        if (context.count > 1) {
          return 'People are discussing your post "${_truncateText(context.contentPreview)}"';
        }
        return '"${_truncateText(context.commentText)}"';
        
      case NotificationType.commentReply:
        return '"${_truncateText(context.commentText)}"';
        
      case NotificationType.mention:
        return context.contentPreview.isNotEmpty 
            ? '"${_truncateText(context.contentPreview)}"'
            : 'in a post';
            
      case NotificationType.message:
        if (context.count > 1) {
          return 'You have unread messages';
        }
        return context.contentPreview.isNotEmpty 
            ? '"${_truncateText(context.contentPreview)}"'
            : 'sent you a message';
            
      case NotificationType.groupInvite:
        return '${context.actorName} invited you to join "${context.groupName}"';
        
      case NotificationType.eventInvite:
        return '${context.actorName} invited you to "${context.eventName}"';
        
      case NotificationType.postShare:
        if (context.count > 1) {
          return 'Your post is being shared!';
        }
        return 'Your post "${_truncateText(context.contentPreview)}"';
        
      case NotificationType.achievement:
        return context.achievementDescription ?? 'You\'ve reached a new milestone!';
        
      case NotificationType.reminder:
        return context.reminderText ?? 'Don\'t forget!';
        
      case NotificationType.system:
        return context.systemMessage ?? 'System update';
    }
  }

  /// Group similar notifications together
  static List<NotificationGroup> groupSimilarNotifications(
    List<NotificationData> notifications,
    {Duration groupingWindow = const Duration(hours: 24)}
  ) {
    final groups = <String, List<NotificationData>>{};
    final now = DateTime.now();
    
    for (final notification in notifications) {
      // Only group recent notifications
      if (now.difference(notification.timestamp) > groupingWindow) {
        continue;
      }
      
      final groupKey = _generateGroupKey(notification);
      groups.putIfAbsent(groupKey, () => []).add(notification);
    }
    
    final result = <NotificationGroup>[];
    
    for (final entry in groups.entries) {
      final notificationsList = entry.value;
      if (notificationsList.length == 1) {
        // Single notification - don't group
        result.add(NotificationGroup(
          id: notificationsList.first.id,
          type: notificationsList.first.type,
          notifications: notificationsList,
          isGrouped: false,
          timestamp: notificationsList.first.timestamp,
        ));
      } else {
        // Multiple similar notifications - group them
        notificationsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        result.add(NotificationGroup(
          id: 'group_${entry.key}',
          type: notificationsList.first.type,
          notifications: notificationsList,
          isGrouped: true,
          timestamp: notificationsList.first.timestamp,
        ));
      }
    }
    
    // Sort groups by most recent timestamp
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  /// Create action buttons for notifications
  static List<NotificationAction> createActionButtons(NotificationType type, String notificationId) {
    switch (type) {
      case NotificationType.friendRequest:
        return [
          NotificationAction(
            id: 'accept',
            label: 'Accept',
            isPrimary: true,
            action: NotificationActionType.acceptFriendRequest,
          ),
          NotificationAction(
            id: 'decline',
            label: 'Decline',
            isPrimary: false,
            action: NotificationActionType.declineFriendRequest,
          ),
        ];
        
      case NotificationType.message:
        return [
          NotificationAction(
            id: 'reply',
            label: 'Reply',
            isPrimary: true,
            action: NotificationActionType.openChat,
          ),
          NotificationAction(
            id: 'mark_read',
            label: 'Mark Read',
            isPrimary: false,
            action: NotificationActionType.markAsRead,
          ),
        ];
        
      case NotificationType.postLike:
      case NotificationType.postComment:
        return [
          NotificationAction(
            id: 'view_post',
            label: 'View Post',
            isPrimary: true,
            action: NotificationActionType.openPost,
          ),
        ];
        
      case NotificationType.groupInvite:
        return [
          NotificationAction(
            id: 'accept_invite',
            label: 'Join',
            isPrimary: true,
            action: NotificationActionType.acceptGroupInvite,
          ),
          NotificationAction(
            id: 'decline_invite',
            label: 'Decline',
            isPrimary: false,
            action: NotificationActionType.declineGroupInvite,
          ),
        ];
        
      case NotificationType.eventInvite:
        return [
          NotificationAction(
            id: 'view_event',
            label: 'View Event',
            isPrimary: true,
            action: NotificationActionType.openEvent,
          ),
        ];
        
      default:
        return [
          NotificationAction(
            id: 'view',
            label: 'View',
            isPrimary: true,
            action: NotificationActionType.openDetails,
          ),
        ];
    }
  }

  /// Handle notification tap actions
  static NotificationTapResult handleNotificationTap(
    NotificationType type,
    String targetId,
    Map<String, dynamic> data,
  ) {
    switch (type) {
      case NotificationType.friendRequest:
        return NotificationTapResult(
          action: NotificationActionType.openProfile,
          targetId: data['senderId'] ?? targetId,
          additionalData: data,
        );
        
      case NotificationType.friendAccepted:
        return NotificationTapResult(
          action: NotificationActionType.openProfile,
          targetId: data['userId'] ?? targetId,
          additionalData: data,
        );
        
      case NotificationType.postLike:
      case NotificationType.postComment:
      case NotificationType.postShare:
        return NotificationTapResult(
          action: NotificationActionType.openPost,
          targetId: data['postId'] ?? targetId,
          additionalData: data,
        );
        
      case NotificationType.commentReply:
        return NotificationTapResult(
          action: NotificationActionType.openPost,
          targetId: data['postId'] ?? targetId,
          additionalData: {'scrollToComment': data['commentId']},
        );
        
      case NotificationType.mention:
        final postId = data['postId'];
        final commentId = data['commentId'];
        if (postId != null) {
          return NotificationTapResult(
            action: NotificationActionType.openPost,
            targetId: postId,
            additionalData: commentId != null ? {'scrollToComment': commentId} : {},
          );
        }
        break;
        
      case NotificationType.message:
        return NotificationTapResult(
          action: NotificationActionType.openChat,
          targetId: data['conversationId'] ?? targetId,
          additionalData: data,
        );
        
      case NotificationType.groupInvite:
        return NotificationTapResult(
          action: NotificationActionType.openGroup,
          targetId: data['groupId'] ?? targetId,
          additionalData: data,
        );
        
      case NotificationType.eventInvite:
        return NotificationTapResult(
          action: NotificationActionType.openEvent,
          targetId: data['eventId'] ?? targetId,
          additionalData: data,
        );
        
      case NotificationType.achievement:
        return NotificationTapResult(
          action: NotificationActionType.openProfile,
          targetId: data['userId'] ?? targetId,
          additionalData: {'tab': 'achievements'},
        );
        
      case NotificationType.system:
        return NotificationTapResult(
          action: NotificationActionType.openSettings,
          targetId: targetId,
          additionalData: data,
        );
        
      case NotificationType.reminder:
        return NotificationTapResult(
          action: NotificationActionType.openReminder,
          targetId: targetId,
          additionalData: data,
        );
    }
    
    return NotificationTapResult(
      action: NotificationActionType.openDetails,
      targetId: targetId,
      additionalData: data,
    );
  }

  /// Clear notification groups by type or ID
  static Future<void> clearNotificationGroups(
    List<String> groupIds,
    Future<void> Function(List<String>) clearFunction,
  ) async {
    if (groupIds.isEmpty) return;
    
    // Batch clear operations for efficiency
    const batchSize = 10;
    for (int i = 0; i < groupIds.length; i += batchSize) {
      final batch = groupIds.skip(i).take(batchSize).toList();
      await clearFunction(batch);
    }
  }

  /// Calculate notification priority
  static NotificationPriority calculateNotificationPriority(
    NotificationType type,
    String senderId,
    List<String> closeFriends,
    Map<String, int> userInteractionScores,
  ) {
    // Base priority by type
    int basePriority = _getBasePriorityByType(type);
    
    // Boost for close friends
    if (closeFriends.contains(senderId)) {
      basePriority += 20;
    }
    
    // Boost for high interaction users
    final interactionScore = userInteractionScores[senderId] ?? 0;
    if (interactionScore > 100) {
      basePriority += 15;
    } else if (interactionScore > 50) {
      basePriority += 10;
    } else if (interactionScore > 10) {
      basePriority += 5;
    }
    
    // Return priority level
    if (basePriority >= 80) return NotificationPriority.critical;
    if (basePriority >= 60) return NotificationPriority.high;
    if (basePriority >= 40) return NotificationPriority.medium;
    return NotificationPriority.low;
  }

  /// Format notification timestamp
  static String formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    
    // For older notifications, show actual date
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Check if notification should be muted based on user preferences
  static bool shouldMuteNotification(
    NotificationType type,
    DateTime timestamp,
    NotificationPreferences preferences,
  ) {
    // Check do not disturb
    if (preferences.isDoNotDisturbEnabled && _isInDoNotDisturbTime(timestamp, preferences)) {
      return true;
    }
    
    // Check type-specific muting
    if (preferences.mutedNotificationTypes.contains(type)) {
      return true;
    }
    
    // Check rate limiting
    if (_exceedsRateLimit(type, timestamp, preferences)) {
      return true;
    }
    
    return false;
  }

  // Private helper methods
  static String _truncateText(String? text, {int maxLength = 50}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String _generateGroupKey(NotificationData notification) {
    // Group similar notifications by type and related entity
    switch (notification.type) {
      case NotificationType.postLike:
        return 'like_${notification.data['postId']}';
      case NotificationType.postComment:
        return 'comment_${notification.data['postId']}';
      case NotificationType.postShare:
        return 'share_${notification.data['postId']}';
      case NotificationType.message:
        return 'message_${notification.data['conversationId']}';
      case NotificationType.friendRequest:
        return 'friend_request';
      default:
        return '${notification.type.name}_${notification.id}';
    }
  }

  static int _getBasePriorityByType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 70;
      case NotificationType.friendRequest:
        return 60;
      case NotificationType.friendAccepted:
        return 50;
      case NotificationType.mention:
        return 65;
      case NotificationType.commentReply:
        return 55;
      case NotificationType.postComment:
        return 45;
      case NotificationType.postLike:
        return 35;
      case NotificationType.postShare:
        return 40;
      case NotificationType.groupInvite:
        return 50;
      case NotificationType.eventInvite:
        return 45;
      case NotificationType.achievement:
        return 30;
      case NotificationType.reminder:
        return 60;
      case NotificationType.system:
        return 25;
    }
  }

  static bool _isInDoNotDisturbTime(DateTime timestamp, NotificationPreferences preferences) {
    if (preferences.dndStartTime == null || preferences.dndEndTime == null) {
      return false;
    }
    
    final time = TimeOfDay.fromDateTime(timestamp);
    final start = preferences.dndStartTime!;
    final end = preferences.dndEndTime!;
    
    if (start.hour < end.hour) {
      return _timeOfDayCompareTo(time, start) >= 0 && _timeOfDayCompareTo(time, end) <= 0;
    } else {
      // Overnight DND (e.g., 22:00 to 07:00)
      return _timeOfDayCompareTo(time, start) >= 0 || _timeOfDayCompareTo(time, end) <= 0;
    }
  }

  static int _timeOfDayCompareTo(TimeOfDay a, TimeOfDay b) {
    final aMinutes = a.hour * 60 + a.minute;
    final bMinutes = b.hour * 60 + b.minute;
    return aMinutes.compareTo(bMinutes);
  }

  static bool _exceedsRateLimit(NotificationType type, DateTime timestamp, NotificationPreferences preferences) {
    // Simple rate limiting - in production, this would be more sophisticated
    final rateLimits = preferences.rateLimits[type];
    if (rateLimits == null) return false;
    
    // This would check against stored notification history
    // For now, just return false
    return false;
  }
}

// Data classes and enums
class NotificationContext {
  final String actorName;
  final String contentPreview;
  final String commentText;
  final int count;
  final String? groupName;
  final String? eventName;
  final String? achievementDescription;
  final String? reminderText;
  final String? systemMessage;

  const NotificationContext({
    this.actorName = '',
    this.contentPreview = '',
    this.commentText = '',
    this.count = 1,
    this.groupName,
    this.eventName,
    this.achievementDescription,
    this.reminderText,
    this.systemMessage,
  });
}

class NotificationData {
  final String id;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const NotificationData({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class NotificationGroup {
  final String id;
  final NotificationType type;
  final List<NotificationData> notifications;
  final bool isGrouped;
  final DateTime timestamp;

  const NotificationGroup({
    required this.id,
    required this.type,
    required this.notifications,
    required this.isGrouped,
    required this.timestamp,
  });

  int get count => notifications.length;
  
  String get displayTitle {
    if (!isGrouped) {
      return NotificationHelpers.generateNotificationTitle(type, 
        NotificationContext(actorName: _getActorName()));
    }
    
    return NotificationHelpers.generateNotificationTitle(type, 
      NotificationContext(count: count));
  }

  String _getActorName() {
    final firstName = notifications.first.data['actorName'];
    return firstName ?? 'Someone';
  }
}

class NotificationAction {
  final String id;
  final String label;
  final bool isPrimary;
  final NotificationActionType action;

  const NotificationAction({
    required this.id,
    required this.label,
    required this.isPrimary,
    required this.action,
  });
}

class NotificationTapResult {
  final NotificationActionType action;
  final String targetId;
  final Map<String, dynamic> additionalData;

  const NotificationTapResult({
    required this.action,
    required this.targetId,
    this.additionalData = const {},
  });
}

class NotificationPreferences {
  final bool isDoNotDisturbEnabled;
  final TimeOfDay? dndStartTime;
  final TimeOfDay? dndEndTime;
  final Set<NotificationType> mutedNotificationTypes;
  final Map<NotificationType, int> rateLimits;

  const NotificationPreferences({
    this.isDoNotDisturbEnabled = false,
    this.dndStartTime,
    this.dndEndTime,
    this.mutedNotificationTypes = const {},
    this.rateLimits = const {},
  });
}

// Helper class for TimeOfDay since it's from Flutter
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}

enum NotificationType {
  friendRequest,
  friendAccepted,
  postLike,
  postComment,
  commentReply,
  mention,
  message,
  groupInvite,
  eventInvite,
  postShare,
  achievement,
  reminder,
  system,
}

enum NotificationActionType {
  acceptFriendRequest,
  declineFriendRequest,
  openChat,
  openPost,
  openProfile,
  openGroup,
  openEvent,
  openSettings,
  openReminder,
  openDetails,
  markAsRead,
  acceptGroupInvite,
  declineGroupInvite,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}
