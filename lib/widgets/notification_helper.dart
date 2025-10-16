import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/models/notification_model.dart';

class NotificationHelper {
  static void showNotificationSnackBar(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.generalUpdate,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    final colorScheme = _getColorSchemeForType(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForType(type),
                size: 20,
                color: colorScheme.iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.backgroundColor.withValues(alpha: 0.9),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: onActionPressed != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onActionPressed,
            )
          : null,
      ),
    );
  }

  static void showGameInviteNotification(
    BuildContext context, {
    required String playerName,
    required String gameName,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.userPlus,
                  size: 20,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Game Invitation',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$playerName invited you to join:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gameName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to join this game?',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDecline?.call();
              },
              child: Text(
                'Decline',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAccept?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget buildNotificationBadge({
    required Widget child,
    required int count,
    Color badgeColor = Colors.red,
    Color textColor = Colors.white,
    double size = 16,
  }) {
    if (count <= 0) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(size / 2),
            ),
            constraints: BoxConstraints(
              minWidth: size,
              minHeight: size,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildNotificationDot({
    required Widget child,
    bool show = true,
    Color dotColor = Colors.red,
    double size = 8,
  }) {
    if (!show) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static _NotificationColorScheme _getColorSchemeForType(NotificationType type) {
    switch (type) {
      case NotificationType.gameInvite:
        return _NotificationColorScheme(
          backgroundColor: Colors.green,
          iconColor: Colors.white,
        );
      case NotificationType.gameUpdate:
        return _NotificationColorScheme(
          backgroundColor: Colors.blue,
          iconColor: Colors.white,
        );
      case NotificationType.bookingConfirmation:
      case NotificationType.bookingReminder:
        return _NotificationColorScheme(
          backgroundColor: Colors.purple,
          iconColor: Colors.white,
        );
      case NotificationType.friendRequest:
        return _NotificationColorScheme(
          backgroundColor: Colors.teal,
          iconColor: Colors.white,
        );
      case NotificationType.achievement:
        return _NotificationColorScheme(
          backgroundColor: Colors.amber,
          iconColor: Colors.white,
        );
      case NotificationType.loyaltyPoints:
        return _NotificationColorScheme(
          backgroundColor: Colors.orange,
          iconColor: Colors.white,
        );
      case NotificationType.systemAlert:
        return _NotificationColorScheme(
          backgroundColor: Colors.red,
          iconColor: Colors.white,
        );
      default:
        return _NotificationColorScheme(
          backgroundColor: Colors.grey,
          iconColor: Colors.white,
        );
    }
  }

  static IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.gameInvite:
        return LucideIcons.userPlus;
      case NotificationType.gameUpdate:
        return LucideIcons.gamepad2;
      case NotificationType.bookingConfirmation:
      case NotificationType.bookingReminder:
        return LucideIcons.calendar;
      case NotificationType.friendRequest:
        return LucideIcons.users;
      case NotificationType.achievement:
        return LucideIcons.award;
      case NotificationType.loyaltyPoints:
        return LucideIcons.gift;
      case NotificationType.systemAlert:
        return Icons.warning; // Using standard warning icon instead of triangleAlert
      default:
        return LucideIcons.bell;
    }
  }
}

class _NotificationColorScheme {
  final Color backgroundColor;
  final Color iconColor;

  const _NotificationColorScheme({
    required this.backgroundColor,
    required this.iconColor,
  });
} 