import 'dart:async';
import 'package:flutter/foundation.dart';

// Comprehensive game notification scheduling and delivery service
class GameNotificationsService {
  final NotificationRepository _notificationRepository;
  final PushNotificationService _pushNotificationService;
  final EmailNotificationService _emailNotificationService;
  final SMSNotificationService _smsNotificationService;
  final InAppNotificationService _inAppNotificationService;
  final UserPreferencesRepository _userPreferencesRepository;
  final GamesService _gamesService;

  GameNotificationsService({
    required NotificationRepository notificationRepository,
    required PushNotificationService pushNotificationService,
    required EmailNotificationService emailNotificationService,
    required SMSNotificationService smsNotificationService,
    required InAppNotificationService inAppNotificationService,
    required UserPreferencesRepository userPreferencesRepository,
    required GamesService gamesService,
  }) : _notificationRepository = notificationRepository,
       _pushNotificationService = pushNotificationService,
       _emailNotificationService = emailNotificationService,
       _smsNotificationService = smsNotificationService,
       _inAppNotificationService = inAppNotificationService,
       _userPreferencesRepository = userPreferencesRepository,
       _gamesService = gamesService;

  // COMPREHENSIVE NOTIFICATION SCHEDULING
  Future<NotificationScheduleResult> scheduleGameNotifications({
    required String gameId,
    required List<String> playerIds,
    required String organizerId,
  }) async {
    try {
      final game = await _gamesService.getGameById(gameId);
      if (game == null) {
        return NotificationScheduleResult.failure('Game not found');
      }

      final scheduledNotifications = <ScheduledNotification>[];
      
      // Get all users involved (players + organizer)
      final allUserIds = [...playerIds, organizerId];

      for (final userId in allUserIds) {
        // Get user notification preferences
        final preferences = await _getUserNotificationPreferences(userId);
        
        // Skip if user has disabled game notifications
        if (!preferences.gameNotificationsEnabled) continue;

        // Schedule pre-game notifications
        final preGameNotifications = await _schedulePreGameNotifications(
          game: game,
          userId: userId,
          preferences: preferences,
          isOrganizer: userId == organizerId,
        );
        scheduledNotifications.addAll(preGameNotifications);

        // Schedule check-in notifications
        final checkinNotifications = await _scheduleCheckinNotifications(
          game: game,
          userId: userId,
          preferences: preferences,
        );
        scheduledNotifications.addAll(checkinNotifications);

        // Schedule post-game notifications (for organizer)
        if (userId == organizerId) {
          final postGameNotifications = await _schedulePostGameNotifications(
            game: game,
            organizerId: organizerId,
            preferences: preferences,
          );
          scheduledNotifications.addAll(postGameNotifications);
        }
      }

      // Save all scheduled notifications
      for (final notification in scheduledNotifications) {
        await _notificationRepository.saveScheduledNotification(notification);
      }

      return NotificationScheduleResult.success(
        scheduledCount: scheduledNotifications.length,
        notifications: scheduledNotifications,
      );

    } catch (e, stackTrace) {
      debugPrint('Error scheduling game notifications: $e\n$stackTrace');
      return NotificationScheduleResult.failure('Failed to schedule notifications: $e');
    }
  }

  // PRE-GAME NOTIFICATION SCHEDULING
  Future<List<ScheduledNotification>> _schedulePreGameNotifications({
    required Game game,
    required String userId,
    required NotificationPreferences preferences,
    required bool isOrganizer,
  }) async {
    final notifications = <ScheduledNotification>[];
    final gameDateTime = game.dateTime;

    // 24-hour reminder (if enabled)
    if (preferences.reminderTiming.contains(ReminderTiming.hours24)) {
      final reminderTime = gameDateTime.subtract(const Duration(hours: 24));
      if (reminderTime.isAfter(DateTime.now())) {
        notifications.add(ScheduledNotification(
          id: _generateNotificationId(),
          gameId: game.id,
          userId: userId,
          type: NotificationType.gameReminder24h,
          scheduledFor: reminderTime,
          title: isOrganizer 
              ? 'Your game is tomorrow!'
              : 'Game reminder - Tomorrow',
          body: _buildGameReminderMessage(game, const Duration(hours: 24)),
          channels: _getChannelsForType(NotificationType.gameReminder24h, preferences),
          status: NotificationStatus.scheduled,
          metadata: {
            'gameId': game.id,
            'venueId': game.venue.id,
            'isOrganizer': isOrganizer.toString(),
          },
        ));
      }
    }

    // 4-hour reminder (if enabled)
    if (preferences.reminderTiming.contains(ReminderTiming.hours4)) {
      final reminderTime = gameDateTime.subtract(const Duration(hours: 4));
      if (reminderTime.isAfter(DateTime.now())) {
        notifications.add(ScheduledNotification(
          id: _generateNotificationId(),
          gameId: game.id,
          userId: userId,
          type: NotificationType.gameReminder4h,
          scheduledFor: reminderTime,
          title: 'Game in 4 hours!',
          body: _buildGameReminderMessage(game, const Duration(hours: 4)),
          channels: _getChannelsForType(NotificationType.gameReminder4h, preferences),
          status: NotificationStatus.scheduled,
          metadata: {
            'gameId': game.id,
            'venueId': game.venue.id,
            'weatherAlert': 'true', // Enable weather checks
          },
        ));
      }
    }

    // 1-hour reminder (if enabled)
    if (preferences.reminderTiming.contains(ReminderTiming.hour1)) {
      final reminderTime = gameDateTime.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        notifications.add(ScheduledNotification(
          id: _generateNotificationId(),
          gameId: game.id,
          userId: userId,
          type: NotificationType.gameReminder1h,
          scheduledFor: reminderTime,
          title: 'Game starting soon!',
          body: _buildGameReminderMessage(game, const Duration(hours: 1)),
          channels: _getChannelsForType(NotificationType.gameReminder1h, preferences),
          status: NotificationStatus.scheduled,
          priority: NotificationPriority.high,
          metadata: {
            'gameId': game.id,
            'venueId': game.venue.id,
            'trafficAlert': 'true', // Enable traffic checks
          },
        ));
      }
    }

    // 15-minute final reminder (push only)
    if (preferences.finalReminderEnabled) {
      final reminderTime = gameDateTime.subtract(const Duration(minutes: 15));
      if (reminderTime.isAfter(DateTime.now())) {
        notifications.add(ScheduledNotification(
          id: _generateNotificationId(),
          gameId: game.id,
          userId: userId,
          type: NotificationType.gameFinalReminder,
          scheduledFor: reminderTime,
          title: 'Game starts in 15 minutes!',
          body: 'Time to head to ${game.venue.name}. Safe travels! 🏃‍♂️',
          channels: [NotificationChannel.push], // Push notification only
          status: NotificationStatus.scheduled,
          priority: NotificationPriority.high,
        ));
      }
    }

    return notifications;
  }

  // CHECK-IN NOTIFICATION SCHEDULING
  Future<List<ScheduledNotification>> _scheduleCheckinNotifications({
    required Game game,
    required String userId,
    required NotificationPreferences preferences,
  }) async {
    final notifications = <ScheduledNotification>[];
    
    // Check-in opening notification (2 hours before game)
    if (preferences.checkinNotificationsEnabled) {
      final checkinOpenTime = game.dateTime.subtract(const Duration(hours: 2));
      if (checkinOpenTime.isAfter(DateTime.now())) {
        notifications.add(ScheduledNotification(
          id: _generateNotificationId(),
          gameId: game.id,
          userId: userId,
          type: NotificationType.checkinOpened,
          scheduledFor: checkinOpenTime,
          title: 'Check-in is now open!',
          body: 'You can now check in for your game at ${game.venue.name}.',
          channels: _getChannelsForType(NotificationType.checkinOpened, preferences),
          status: NotificationStatus.scheduled,
        ));
      }
    }

    // Check-in reminder (30 minutes before game - for non-checked-in players)
    final checkinReminderTime = game.dateTime.subtract(const Duration(minutes: 30));
    if (checkinReminderTime.isAfter(DateTime.now())) {
      notifications.add(ScheduledNotification(
        id: _generateNotificationId(),
        gameId: game.id,
        userId: userId,
        type: NotificationType.checkinReminder,
        scheduledFor: checkinReminderTime,
        title: 'Don\'t forget to check in!',
        body: 'Game starts soon. Make sure to check in when you arrive.',
        channels: [NotificationChannel.push],
        status: NotificationStatus.scheduled,
        conditional: true, // Only send if user hasn't checked in
        metadata: {
          'condition': 'not_checked_in',
        },
      ));
    }

    return notifications;
  }

  // POST-GAME NOTIFICATION SCHEDULING
  Future<List<ScheduledNotification>> _schedulePostGameNotifications({
    required Game game,
    required String organizerId,
    required NotificationPreferences preferences,
  }) async {
    final notifications = <ScheduledNotification>[];
    final gameEndTime = game.dateTime.add(game.duration);

    // Post-game rating reminder (30 minutes after game ends)
    if (preferences.ratingRemindersEnabled) {
      final ratingReminderTime = gameEndTime.add(const Duration(minutes: 30));
      notifications.add(ScheduledNotification(
        id: _generateNotificationId(),
        gameId: game.id,
        userId: organizerId,
        type: NotificationType.postGameRatingReminder,
        scheduledFor: ratingReminderTime,
        title: 'How was the game?',
        body: 'Rate your players and venue to help improve future games.',
        channels: _getChannelsForType(NotificationType.postGameRatingReminder, preferences),
        status: NotificationStatus.scheduled,
        actionButtons: [
          NotificationAction(
            id: 'rate_now',
            title: 'Rate Now',
            action: 'open_rating_screen',
          ),
          NotificationAction(
            id: 'rate_later',
            title: 'Later',
            action: 'snooze_1hour',
          ),
        ],
      ));
    }

    // Game summary notification (1 hour after game ends)
    final summaryTime = gameEndTime.add(const Duration(hours: 1));
    notifications.add(ScheduledNotification(
      id: _generateNotificationId(),
      gameId: game.id,
      userId: organizerId,
      type: NotificationType.gameSummary,
      scheduledFor: summaryTime,
      title: 'Game Summary Available',
      body: 'View stats and highlights from your recent game.',
      channels: [NotificationChannel.push, NotificationChannel.inApp],
      status: NotificationStatus.scheduled,
    ));

    return notifications;
  }

  // IMMEDIATE NOTIFICATION SENDING
  Future<NotificationResult> sendImmediateNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? gameId,
    Map<String, String>? metadata,
    List<NotificationAction>? actionButtons,
  }) async {
    try {
      // Get user preferences
      final preferences = await _getUserNotificationPreferences(userId);
      
      // Create notification
      final notification = GameNotification(
        id: _generateNotificationId(),
        userId: userId,
        gameId: gameId,
        type: type,
        title: title,
        body: body,
        channels: _getChannelsForType(type, preferences),
        priority: _getPriorityForType(type),
        metadata: metadata ?? {},
        actionButtons: actionButtons,
        createdAt: DateTime.now(),
      );

      // Send via enabled channels
      final results = <NotificationChannel, bool>{};

      for (final channel in notification.channels) {
        final success = await _sendViaChannel(notification, channel);
        results[channel] = success;
      }

      // Save notification history
      await _notificationRepository.saveNotificationHistory(
        NotificationHistory(
          id: notification.id,
          userId: userId,
          type: type,
          title: title,
          body: body,
          sentAt: DateTime.now(),
          channels: results,
          gameId: gameId,
        ),
      );

      return NotificationResult.success(
        notification: notification,
        channelResults: results,
      );

    } catch (e, stackTrace) {
      debugPrint('Error sending immediate notification: $e\n$stackTrace');
      return NotificationResult.failure('Failed to send notification: $e');
    }
  }

  // NOTIFICATION DELIVERY ENGINE
  Future<bool> _sendViaChannel(
    GameNotification notification,
    NotificationChannel channel,
  ) async {
    try {
      switch (channel) {
        case NotificationChannel.push:
          return await _pushNotificationService.sendPushNotification(
            userId: notification.userId,
            title: notification.title,
            body: notification.body,
            data: notification.metadata,
            actionButtons: notification.actionButtons,
          );

        case NotificationChannel.email:
          return await _emailNotificationService.sendEmail(
            userId: notification.userId,
            subject: notification.title,
            body: _buildEmailBody(notification),
            gameId: notification.gameId,
          );

        case NotificationChannel.sms:
          return await _smsNotificationService.sendSMS(
            userId: notification.userId,
            message: '${notification.title}: ${notification.body}',
          );

        case NotificationChannel.inApp:
          return await _inAppNotificationService.addInAppNotification(
            userId: notification.userId,
            notification: notification,
          );
      }
    } catch (e) {
      debugPrint('Error sending notification via $channel: $e');
      return false;
    }
  }

  // SCHEDULED NOTIFICATION PROCESSING
  Future<void> processScheduledNotifications() async {
    try {
      final now = DateTime.now();
      
      // Get notifications due for delivery
      final dueNotifications = await _notificationRepository.getDueNotifications(now);
      
      for (final scheduledNotification in dueNotifications) {
        await _processScheduledNotification(scheduledNotification);
      }

    } catch (e) {
      debugPrint('Error processing scheduled notifications: $e');
    }
  }

  Future<void> _processScheduledNotification(ScheduledNotification scheduled) async {
    try {
      // Check conditional notifications
      if (scheduled.conditional) {
        final shouldSend = await _evaluateNotificationCondition(scheduled);
        if (!shouldSend) {
          // Mark as skipped
          await _notificationRepository.updateNotificationStatus(
            scheduled.id,
            NotificationStatus.skipped,
          );
          return;
        }
      }

      // Create notification from scheduled data
      final notification = GameNotification(
        id: scheduled.id,
        userId: scheduled.userId,
        gameId: scheduled.gameId,
        type: scheduled.type,
        title: scheduled.title,
        body: scheduled.body,
        channels: scheduled.channels,
        priority: scheduled.priority,
        metadata: scheduled.metadata,
        actionButtons: scheduled.actionButtons,
        createdAt: DateTime.now(),
      );

      // Send notification
      final results = <NotificationChannel, bool>{};
      for (final channel in notification.channels) {
        final success = await _sendViaChannel(notification, channel);
        results[channel] = success;
      }

      // Update status
      await _notificationRepository.updateNotificationStatus(
        scheduled.id,
        results.values.any((success) => success) 
            ? NotificationStatus.sent
            : NotificationStatus.failed,
      );

      // Save to history
      await _notificationRepository.saveNotificationHistory(
        NotificationHistory(
          id: notification.id,
          userId: notification.userId,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          sentAt: DateTime.now(),
          channels: results,
          gameId: notification.gameId,
        ),
      );

    } catch (e) {
      debugPrint('Error processing scheduled notification ${scheduled.id}: $e');
      await _notificationRepository.updateNotificationStatus(
        scheduled.id,
        NotificationStatus.failed,
      );
    }
  }

  // CONDITIONAL NOTIFICATION EVALUATION
  Future<bool> _evaluateNotificationCondition(ScheduledNotification notification) async {
    final condition = notification.metadata['condition'];
    
    switch (condition) {
      case 'not_checked_in':
        // Check if user has checked in for the game
        final hasCheckedIn = await _gamesService.hasPlayerCheckedIn(
          gameId: notification.gameId,
          playerId: notification.userId,
        );
        return !hasCheckedIn;

      case 'game_not_cancelled':
        // Check if game is still active
        final game = await _gamesService.getGameById(notification.gameId);
        return game != null && game.status != GameStatus.cancelled;

      case 'weather_dependent':
        // Check weather conditions
        return await _shouldSendWeatherDependentNotification(notification);

      default:
        return true; // Send by default if condition is unknown
    }
  }

  Future<bool> _shouldSendWeatherDependentNotification(ScheduledNotification notification) async {
    // This would integrate with weather service to check conditions
    // For now, return true (always send)
    return true;
  }

  // BULK NOTIFICATION OPERATIONS
  Future<BulkNotificationResult> sendBulkNotification({
    required List<String> userIds,
    required NotificationType type,
    required String title,
    required String body,
    String? gameId,
    Map<String, String>? metadata,
  }) async {
    final results = <String, NotificationResult>{};
    
    for (final userId in userIds) {
      final result = await sendImmediateNotification(
        userId: userId,
        type: type,
        title: title,
        body: body,
        gameId: gameId,
        metadata: metadata,
      );
      results[userId] = result;
    }

    final successCount = results.values.where((r) => r.isSuccess).length;
    
    return BulkNotificationResult(
      totalSent: userIds.length,
      successCount: successCount,
      failureCount: userIds.length - successCount,
      individualResults: results,
    );
  }

  // NOTIFICATION MANAGEMENT
  Future<void> cancelScheduledNotification(String notificationId) async {
    await _notificationRepository.updateNotificationStatus(
      notificationId,
      NotificationStatus.cancelled,
    );
  }

  Future<void> cancelGameNotifications(String gameId) async {
    await _notificationRepository.cancelGameNotifications(gameId);
  }

  Future<List<NotificationHistory>> getUserNotificationHistory({
    required String userId,
    int? limit,
    DateTime? since,
  }) async {
    return await _notificationRepository.getUserNotificationHistory(
      userId: userId,
      limit: limit,
      since: since,
    );
  }

  // HELPER METHODS
  Future<NotificationPreferences> _getUserNotificationPreferences(String userId) async {
    try {
      final preferences = await _userPreferencesRepository.getNotificationPreferences(userId);
      return preferences ?? NotificationPreferences.defaultPreferences();
    } catch (e) {
      debugPrint('Error fetching notification preferences for $userId: $e');
      return NotificationPreferences.defaultPreferences();
    }
  }

  List<NotificationChannel> _getChannelsForType(
    NotificationType type,
    NotificationPreferences preferences,
  ) {
    final channels = <NotificationChannel>[];

    // Push notifications (always enabled for important types)
    if (preferences.pushNotificationsEnabled || _isUrgentType(type)) {
      channels.add(NotificationChannel.push);
    }

    // Email notifications
    if (preferences.emailNotificationsEnabled && _supportsEmail(type)) {
      channels.add(NotificationChannel.email);
    }

    // SMS notifications (only for urgent types)
    if (preferences.smsNotificationsEnabled && _isUrgentType(type)) {
      channels.add(NotificationChannel.sms);
    }

    // In-app notifications
    if (preferences.inAppNotificationsEnabled) {
      channels.add(NotificationChannel.inApp);
    }

    // Fallback to push if no channels enabled
    if (channels.isEmpty) {
      channels.add(NotificationChannel.push);
    }

    return channels;
  }

  NotificationPriority _getPriorityForType(NotificationType type) {
    switch (type) {
      case NotificationType.gameCancelled:
      case NotificationType.gameFinalReminder:
      case NotificationType.emergencyMessage:
        return NotificationPriority.high;
        
      case NotificationType.gameReminder1h:
      case NotificationType.checkinReminder:
      case NotificationType.gameStartingSoon:
        return NotificationPriority.medium;
        
      default:
        return NotificationPriority.normal;
    }
  }

  bool _isUrgentType(NotificationType type) {
    return [
      NotificationType.gameCancelled,
      NotificationType.emergencyMessage,
      NotificationType.gameFinalReminder,
      NotificationType.gameReminder1h,
    ].contains(type);
  }

  bool _supportsEmail(NotificationType type) {
    return [
      NotificationType.gameReminder24h,
      NotificationType.gameReminder4h,
      NotificationType.gameSummary,
      NotificationType.postGameRatingReminder,
    ].contains(type);
  }

  String _buildGameReminderMessage(Game game, Duration timeUntil) {
    final timeText = timeUntil.inHours >= 24 
        ? '${timeUntil.inDays} day${timeUntil.inDays == 1 ? '' : 's'}'
        : '${timeUntil.inHours} hour${timeUntil.inHours == 1 ? '' : 's'}';
        
    return 'Your ${game.sport} game at ${game.venue.name} starts in $timeText. See you there! 🏀';
  }

  String _buildEmailBody(GameNotification notification) {
    // Build HTML email body based on notification type
    return '''
    <html>
      <body>
        <h2>${notification.title}</h2>
        <p>${notification.body}</p>
        ${notification.gameId != null ? '<p><a href="app://game/${notification.gameId}">View Game Details</a></p>' : ''}
      </body>
    </html>
    ''';
  }

  String _generateNotificationId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}

// Result classes and data structures would continue here...
// (I'll include the key classes but truncate for brevity)

// Result classes
abstract class NotificationScheduleResult {
  final bool isSuccess;
  final String? error;

  NotificationScheduleResult._(this.isSuccess, this.error);

  factory NotificationScheduleResult.success({
    required int scheduledCount,
    required List<ScheduledNotification> notifications,
  }) = NotificationScheduleSuccess;

  factory NotificationScheduleResult.failure(String error) = NotificationScheduleFailure;
}

class NotificationScheduleSuccess extends NotificationScheduleResult {
  final int scheduledCount;
  final List<ScheduledNotification> notifications;

  NotificationScheduleSuccess({
    required this.scheduledCount,
    required this.notifications,
  }) : super._(true, null);
}

class NotificationScheduleFailure extends NotificationScheduleResult {
  NotificationScheduleFailure(String error) : super._(false, error);
}

abstract class NotificationResult {
  final bool isSuccess;
  final String? error;

  NotificationResult._(this.isSuccess, this.error);

  factory NotificationResult.success({
    required GameNotification notification,
    required Map<NotificationChannel, bool> channelResults,
  }) = NotificationSuccess;

  factory NotificationResult.failure(String error) = NotificationFailure;
}

class NotificationSuccess extends NotificationResult {
  final GameNotification notification;
  final Map<NotificationChannel, bool> channelResults;

  NotificationSuccess({
    required this.notification,
    required this.channelResults,
  }) : super._(true, null);
}

class NotificationFailure extends NotificationResult {
  NotificationFailure(String error) : super._(false, error);
}

class BulkNotificationResult {
  final int totalSent;
  final int successCount;
  final int failureCount;
  final Map<String, NotificationResult> individualResults;

  BulkNotificationResult({
    required this.totalSent,
    required this.successCount,
    required this.failureCount,
    required this.individualResults,
  });
}

// Data classes
class ScheduledNotification {
  final String id;
  final String gameId;
  final String userId;
  final NotificationType type;
  final DateTime scheduledFor;
  final String title;
  final String body;
  final List<NotificationChannel> channels;
  final NotificationStatus status;
  final NotificationPriority priority;
  final Map<String, String> metadata;
  final List<NotificationAction>? actionButtons;
  final bool conditional;

  ScheduledNotification({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.type,
    required this.scheduledFor,
    required this.title,
    required this.body,
    required this.channels,
    required this.status,
    this.priority = NotificationPriority.normal,
    this.metadata = const {},
    this.actionButtons,
    this.conditional = false,
  });
}

class GameNotification {
  final String id;
  final String userId;
  final String? gameId;
  final NotificationType type;
  final String title;
  final String body;
  final List<NotificationChannel> channels;
  final NotificationPriority priority;
  final Map<String, String> metadata;
  final List<NotificationAction>? actionButtons;
  final DateTime createdAt;

  GameNotification({
    required this.id,
    required this.userId,
    this.gameId,
    required this.type,
    required this.title,
    required this.body,
    required this.channels,
    this.priority = NotificationPriority.normal,
    this.metadata = const {},
    this.actionButtons,
    required this.createdAt,
  });
}

class NotificationHistory {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime sentAt;
  final Map<NotificationChannel, bool> channels;
  final String? gameId;

  NotificationHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.channels,
    this.gameId,
  });
}

class NotificationPreferences {
  final bool gameNotificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool smsNotificationsEnabled;
  final bool inAppNotificationsEnabled;
  final bool checkinNotificationsEnabled;
  final bool ratingRemindersEnabled;
  final bool finalReminderEnabled;
  final List<ReminderTiming> reminderTiming;

  NotificationPreferences({
    required this.gameNotificationsEnabled,
    required this.pushNotificationsEnabled,
    required this.emailNotificationsEnabled,
    required this.smsNotificationsEnabled,
    required this.inAppNotificationsEnabled,
    required this.checkinNotificationsEnabled,
    required this.ratingRemindersEnabled,
    required this.finalReminderEnabled,
    required this.reminderTiming,
  });

  factory NotificationPreferences.defaultPreferences() {
    return NotificationPreferences(
      gameNotificationsEnabled: true,
      pushNotificationsEnabled: true,
      emailNotificationsEnabled: false,
      smsNotificationsEnabled: false,
      inAppNotificationsEnabled: true,
      checkinNotificationsEnabled: true,
      ratingRemindersEnabled: true,
      finalReminderEnabled: true,
      reminderTiming: [
        ReminderTiming.hours24,
        ReminderTiming.hours4,
        ReminderTiming.hour1,
      ],
    );
  }
}

class NotificationAction {
  final String id;
  final String title;
  final String action;

  NotificationAction({
    required this.id,
    required this.title,
    required this.action,
  });
}

// Enums
enum NotificationType {
  gameReminder24h,
  gameReminder4h,
  gameReminder1h,
  gameFinalReminder,
  checkinOpened,
  checkinReminder,
  gameStartingSoon,
  postGameRatingReminder,
  gameSummary,
  gameCancelled,
  gameUpdated,
  playerJoined,
  playerLeft,
  emergencyMessage,
}

enum NotificationChannel {
  push,
  email,
  sms,
  inApp,
}

enum NotificationStatus {
  scheduled,
  sent,
  failed,
  cancelled,
  skipped,
}

enum NotificationPriority {
  low,
  normal,
  medium,
  high,
}

enum ReminderTiming {
  hours24,
  hours4,
  hour1,
  minutes30,
  minutes15,
}

// Placeholder classes for dependencies
class Game {
  final String id;
  final String sport;
  final DateTime dateTime;
  final Duration duration;
  final Venue venue;
  final GameStatus status;

  Game({
    required this.id,
    required this.sport,
    required this.dateTime,
    required this.duration,
    required this.venue,
    required this.status,
  });
}

class Venue {
  final String id;
  final String name;

  Venue({required this.id, required this.name});
}

enum GameStatus {
  scheduled,
  active,
  completed,
  cancelled,
}

// Abstract dependencies
abstract class NotificationRepository {
  Future<void> saveScheduledNotification(ScheduledNotification notification);
  Future<List<ScheduledNotification>> getDueNotifications(DateTime now);
  Future<void> updateNotificationStatus(String id, NotificationStatus status);
  Future<void> saveNotificationHistory(NotificationHistory history);
  Future<void> cancelGameNotifications(String gameId);
  Future<List<NotificationHistory>> getUserNotificationHistory({
    required String userId,
    int? limit,
    DateTime? since,
  });
}

abstract class PushNotificationService {
  Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
    List<NotificationAction>? actionButtons,
  });
}

abstract class EmailNotificationService {
  Future<bool> sendEmail({
    required String userId,
    required String subject,
    required String body,
    String? gameId,
  });
}

abstract class SMSNotificationService {
  Future<bool> sendSMS({
    required String userId,
    required String message,
  });
}

abstract class InAppNotificationService {
  Future<bool> addInAppNotification({
    required String userId,
    required GameNotification notification,
  });
}

abstract class UserPreferencesRepository {
  Future<NotificationPreferences?> getNotificationPreferences(String userId);
}

abstract class GamesService {
  Future<Game?> getGameById(String gameId);
  Future<bool> hasPlayerCheckedIn({
    required String gameId,
    required String playerId,
  });
}
