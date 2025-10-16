import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// State for notifications
class NotificationsState {
  final List<Notification> notifications;
  final List<Notification> unreadNotifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadNotifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<Notification>? notifications,
    List<Notification>? unreadNotifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => unreadNotifications.length;
}

/// Controller for notifications
class NotificationsController extends StateNotifier<NotificationsState> {
  final NotificationsRepository repository;
  final String userId;

  NotificationsController({
    required this.repository,
    required this.userId,
  }) : super(const NotificationsState());

  /// Load all notifications for the user
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await repository.getNotifications(userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (notifications) {
        final unread = notifications.where((n) => !n.isRead).toList();
        state = state.copyWith(
          notifications: notifications,
          unreadNotifications: unread,
          isLoading: false,
          error: null,
        );
      },
    );
  }

  /// Load only unread notifications
  Future<void> loadUnreadNotifications() async {
    final result = await repository.getUnreadNotifications(userId);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (unread) => state = state.copyWith(
        unreadNotifications: unread,
        error: null,
      ),
    );
  }

  /// Get notifications by type
  Future<List<Notification>> getNotificationsByType(NotificationType type) async {
    final result = await repository.getNotificationsByType(userId, type);

    return result.fold(
      (failure) => [],
      (notifications) => notifications,
    );
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    final result = await repository.markAsRead(notificationId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Update local state
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList();

        final updatedUnread = updatedNotifications.where((n) => !n.isRead).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadNotifications: updatedUnread,
        );
        return true;
      },
    );
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final result = await repository.markAllAsRead(userId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Update local state
        final updatedNotifications = state.notifications.map((n) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadNotifications: [],
        );
        return true;
      },
    );
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    final result = await repository.deleteNotification(notificationId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Update local state
        final updatedNotifications = state.notifications
            .where((n) => n.id != notificationId)
            .toList();
        final updatedUnread = updatedNotifications.where((n) => !n.isRead).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadNotifications: updatedUnread,
        );
        return true;
      },
    );
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications() async {
    final result = await repository.deleteAllNotifications(userId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          notifications: [],
          unreadNotifications: [],
        );
        return true;
      },
    );
  }

  /// Create a new notification (for testing/admin purposes)
  Future<bool> createNotification(Notification notification) async {
    final result = await repository.createNotification(notification);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (newNotification) {
        final updatedNotifications = [newNotification, ...state.notifications];
        final updatedUnread = updatedNotifications.where((n) => !n.isRead).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadNotifications: updatedUnread,
        );
        return true;
      },
    );
  }
}
