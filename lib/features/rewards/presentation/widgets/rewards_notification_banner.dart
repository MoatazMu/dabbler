import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';

enum NotificationBannerType { info, success, warning, error }

class RewardsNotificationBanner extends StatelessWidget {
  final String? message;
  final NotificationBannerType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const RewardsNotificationBanner({
    super.key,
    this.message,
    this.type = NotificationBannerType.info,
    this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? _getDefaultMessage();
    
    if (displayMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            color: _getIconColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: _getTextColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (displayMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayMessage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getTextColor(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _getIconColor(),
              ),
              child: Text(actionText!),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: _getTextColor().withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: -0.2, end: 0, duration: 600.ms);
  }

  String _getDefaultMessage() {
    // Mock recent achievement or notification
    return 'You just earned the "Social Butterfly" achievement! 🎉';
  }

  String _getTitle() {
    switch (type) {
      case NotificationBannerType.info:
        return 'Achievement Unlocked!';
      case NotificationBannerType.success:
        return 'Success!';
      case NotificationBannerType.warning:
        return 'Warning';
      case NotificationBannerType.error:
        return 'Error';
    }
  }

  IconData _getIcon() {
    switch (type) {
      case NotificationBannerType.info:
        return Icons.emoji_events;
      case NotificationBannerType.success:
        return Icons.check_circle;
      case NotificationBannerType.warning:
        return Icons.warning;
      case NotificationBannerType.error:
        return Icons.error;
    }
  }

  Color _getBackgroundColor() {
    switch (type) {
      case NotificationBannerType.info:
        return Colors.blue.shade50;
      case NotificationBannerType.success:
        return Colors.green.shade50;
      case NotificationBannerType.warning:
        return Colors.orange.shade50;
      case NotificationBannerType.error:
        return Colors.red.shade50;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case NotificationBannerType.info:
        return Colors.blue;
      case NotificationBannerType.success:
        return Colors.green;
      case NotificationBannerType.warning:
        return Colors.orange;
      case NotificationBannerType.error:
        return Colors.red;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case NotificationBannerType.info:
        return Colors.blue.shade800;
      case NotificationBannerType.success:
        return Colors.green.shade800;
      case NotificationBannerType.warning:
        return Colors.orange.shade800;
      case NotificationBannerType.error:
        return Colors.red.shade800;
    }
  }
}