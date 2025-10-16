import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  
  List<NotificationModel> get todayNotifications => _notifications.where((n) {
    final today = DateTime.now();
    final notificationDate = n.createdAt;
    return today.year == notificationDate.year &&
           today.month == notificationDate.month &&
           today.day == notificationDate.day;
  }).toList();

  // Initialize with sample data
  void initializeNotifications() {
    if (_notifications.isEmpty) {
      _notifications = _getSampleNotifications();
      // Defer notifyListeners to avoid build-time issues
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> refreshNotifications() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, this would fetch from an API
    _notifications = _getSampleNotifications();
    
    _isLoading = false;
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAsUnread(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Method to reset service state for testing
  void resetForTesting() {
    _notifications.clear();
    _isLoading = false;
    notifyListeners();
  }

  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<NotificationModel> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification); // Add to beginning
    notifyListeners();
  }

  // Group notifications by date
  Map<String, List<NotificationModel>> getGroupedNotifications() {
    final Map<String, List<NotificationModel>> grouped = {};
    
    for (final notification in _notifications) {
      final dateKey = notification.formattedDate;
      grouped[dateKey] ??= [];
      grouped[dateKey]!.add(notification);
    }
    
    return grouped;
  }

  List<NotificationModel> _getSampleNotifications() {
    final now = DateTime.now();
    
    return [
      NotificationModel(
        id: '1',
        title: 'Game Invitation',
        message: 'Carlos invited you to join a padel match at Elite Padel Center',
        type: NotificationType.gameInvite,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(minutes: 5)),
        actionText: 'View Game',
        actionRoute: '/game-details',
        data: {'gameId': 'game_123'},
      ),
      NotificationModel(
        id: '2',
        title: 'Booking Confirmed',
        message: 'Your padel court booking for tomorrow at 7:00 PM has been confirmed',
        type: NotificationType.bookingConfirmation,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 2)),
        actionText: 'View Booking',
        actionRoute: '/booking-details',
        data: {'bookingId': 'booking_456'},
      ),
      NotificationModel(
        id: '3',
        title: 'Friend Request',
        message: 'Sarah wants to connect with you on Dabbler',
        type: NotificationType.friendRequest,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 4)),
        isRead: true,
        actionText: 'View Profile',
        actionRoute: '/user-profile',
        data: {'userId': 'user_789'},
      ),
      NotificationModel(
        id: '4',
        title: 'Achievement Unlocked!',
        message: 'Congratulations! You\'ve earned the "Team Player" badge',
        type: NotificationType.achievement,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(hours: 6)),
        actionText: 'View Achievements',
        actionRoute: '/achievements',
        data: {'achievementId': 'team_player'},
      ),
      NotificationModel(
        id: '5',
        title: 'Game Starting Soon',
        message: 'Your basketball game starts in 30 minutes at Downtown Court',
        type: NotificationType.gameUpdate,
        priority: NotificationPriority.urgent,
        createdAt: now.subtract(const Duration(hours: 8)),
        isRead: true,
        actionText: 'Get Directions',
        actionRoute: '/navigation',
        data: {'gameId': 'game_999', 'venueId': 'venue_111'},
      ),
      NotificationModel(
        id: '6',
        title: 'Points Earned',
        message: 'You earned 50 loyalty points for completing your last game!',
        type: NotificationType.loyaltyPoints,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
        actionText: 'View Points',
        actionRoute: '/loyalty-points',
        data: {'points': 50},
      ),
      NotificationModel(
        id: '7',
        title: 'Game Cancelled',
        message: 'The football match scheduled for today has been cancelled due to weather',
        type: NotificationType.gameUpdate,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        actionText: 'Find Alternative',
        actionRoute: '/explore',
        data: {'gameId': 'game_cancelled_123'},
      ),
      NotificationModel(
        id: '8',
        title: 'Booking Reminder',
        message: 'Don\'t forget your tennis court booking tomorrow at 5:00 PM',
        type: NotificationType.bookingReminder,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        actionText: 'View Details',
        actionRoute: '/booking-details',
        data: {'bookingId': 'booking_reminder_456'},
      ),
      NotificationModel(
        id: '9',
        title: 'App Update Available',
        message: 'A new version of Dabbler is available with exciting new features!',
        type: NotificationType.systemAlert,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
        actionText: 'Update Now',
        actionRoute: '/app-update',
      ),
      NotificationModel(
        id: '10',
        title: 'Welcome to Dabbler!',
        message: 'Thanks for joining! Start by exploring games near you or creating your first booking.',
        type: NotificationType.generalUpdate,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 7)),
        isRead: true,
        actionText: 'Get Started',
        actionRoute: '/explore',
      ),
    ];
  }
}
