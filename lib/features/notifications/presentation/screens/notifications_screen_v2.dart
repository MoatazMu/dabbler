import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../data/notifications_repository.dart';
import '../providers/notifications_providers.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/features/activities/presentation/providers/activity_providers.dart';
import 'package:dabbler/features/activities/data/models/activity_feed_event.dart';
import 'package:dabbler/core/design_system/layouts/two_section_layout.dart';
import 'package:dabbler/core/design_system/tokens/design_tokens.dart';
import '../providers/notification_center_badge_providers.dart';

class NotificationsScreenV2 extends ConsumerStatefulWidget {
  const NotificationsScreenV2({super.key});

  @override
  ConsumerState<NotificationsScreenV2> createState() =>
      _NotificationsScreenV2State();
}

class _NotificationsScreenV2State extends ConsumerState<NotificationsScreenV2> {
  final AuthService _authService = AuthService();
  String _selectedFilter = 'All';
  String _selectedTab = 'Notifications'; // 'Notifications' or 'Activity'

  @override
  void initState() {
    super.initState();

    // Load initial activity feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityFeedControllerProvider.notifier).loadActivities('all');
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.getCurrentUserId();

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view notifications')),
      );
    }

    final notificationState = ref.watch(
      notificationsControllerProvider(userId),
    );
    final activityState = ref.watch(activityFeedControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TwoSectionLayout(
        category: 'activities',
        topSection: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: const Icon(Iconsax.home_copy),
                    style: IconButton.styleFrom(
                      backgroundColor: context.colorScheme.categoryActivities
                          .withValues(alpha: 0.0),
                      foregroundColor: context.colorScheme.onSurface,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTab == 'Notifications'
                              ? 'Notifications'
                              : 'Activity',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        _selectedTab = _selectedTab == 'Notifications'
                            ? 'Activity'
                            : 'Notifications';
                        _selectedFilter = 'All'; // Reset filter when switching
                      });

                      if (_selectedTab == 'Activity') {
                        ref.read(lastSeenActivityAtProvider.notifier).markNow();
                      }
                    },
                    icon: Icon(
                      _selectedTab == 'Notifications'
                          ? Iconsax.activity_copy
                          : Iconsax.notification_copy,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: context.colorScheme.categoryActivities
                          .withValues(alpha: 0.0),
                      foregroundColor: context.colorScheme.onSurface,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildFilterSection(
              _selectedTab == 'Notifications' ? notificationState : null,
              activityState,
            ),
          ],
        ),
        bottomSection: Column(
          children: [
            if (_selectedTab == 'Notifications')
              _buildStatsBar(notificationState),
            _selectedTab == 'Notifications'
                ? _buildNotificationsList(userId, notificationState)
                : _buildActivityList(activityState),
          ],
        ),
        onRefresh: () => _selectedTab == 'Notifications'
            ? _refresh(userId)
            : _refreshActivity(),
      ),
    );
  }

  Widget _buildFilterSection(notificationState, activityState) {
    final activitiesScheme = context.getCategoryTheme('activities');

    final filters = _selectedTab == 'Notifications'
        ? [
            {'label': 'All', 'icon': Iconsax.archive_copy},
            {'label': 'Games', 'icon': Iconsax.game_copy},
            {'label': 'Bookings', 'icon': Iconsax.calendar_copy},
            {'label': 'Social', 'icon': Iconsax.people_copy},
            {'label': 'Achievements', 'icon': Iconsax.medal_copy},
          ]
        : [
            {'label': 'All', 'icon': Iconsax.archive_copy},
            {'label': 'Games', 'icon': Iconsax.game_copy},
            {'label': 'Booking', 'icon': Iconsax.calendar_copy},
            {'label': 'Community', 'icon': Iconsax.people_copy},
            {'label': 'Payment', 'icon': Iconsax.card_copy},
            {'label': 'Rewards', 'icon': Iconsax.star_1_copy},
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(color: Colors.transparent),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 24),
            ...filters.map((filter) {
              final isSelected = _selectedFilter == filter['label'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['label'] as String;
                  });

                  // Update activity category filter if on Activity tab
                  if (_selectedTab == 'Activity') {
                    final category = filter['label'] == 'All'
                        ? null
                        : filter['label'] as String;
                    ref
                        .read(activityFeedControllerProvider.notifier)
                        .changeCategory(category);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activitiesScheme.primary
                        : activitiesScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? activitiesScheme.onPrimary
                            : activitiesScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter['label'] as String,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? activitiesScheme.onPrimary
                              : activitiesScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(state) {
    final activitiesScheme = context.getCategoryTheme('activities');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: context.colorTokens.stroke)),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.notification_status_copy,
            size: 16,
            color: activitiesScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${state.unreadCount} unread',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorTokens.neutral,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${state.notifications.length} total',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorTokens.neutralOpacity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String userId, state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState();
    }

    // Filter notifications based on selected filter
    List<NotificationItem> filteredNotifications = state.notifications;
    if (_selectedFilter != 'All') {
      filteredNotifications = state.notifications.where((n) {
        switch (_selectedFilter) {
          case 'Games':
            return n.type == NotificationType.gameInvite ||
                n.type == NotificationType.gameUpdate;
          case 'Bookings':
            return n.type == NotificationType.bookingConfirmation ||
                n.type == NotificationType.bookingReminder;
          case 'Social':
            return n.type == NotificationType.friendRequest;
          case 'Achievements':
            return n.type == NotificationType.achievement ||
                n.type == NotificationType.loyaltyPoints;
          default:
            return true;
        }
      }).toList();
    }

    return Column(
      children: [
        ...filteredNotifications.map((notification) {
          return _buildNotificationCard(userId, notification);
        }),
        if (state.hasMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(String userId, NotificationItem notification) {
    final activitiesScheme = context.getCategoryTheme('activities');

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref
            .read(notificationsControllerProvider(userId).notifier)
            .deleteNotification(notification.id);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(6),
            leading: _getNotificationIcon(
              notification.type,
              notification.priority,
            ),
            title: Text(
              notification.title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: notification.isRead
                    ? FontWeight.normal
                    : FontWeight.bold,
                color: context.colorTokens.neutral,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorTokens.neutralOpacity,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorTokens.neutralOpacity,
                  ),
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activitiesScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () => _handleNotificationTap(userId, notification),
          ),
          Divider(height: 1, thickness: 1, color: context.colorTokens.stroke),
        ],
      ),
    );
  }

  Widget _getNotificationIcon(
    NotificationType type,
    NotificationPriority priority,
  ) {
    IconData icon;
    final activitiesScheme = context.getCategoryTheme('activities');
    final Color color = activitiesScheme.primary;

    final double bgAlpha = switch (priority) {
      NotificationPriority.urgent => 0.24,
      NotificationPriority.high => 0.18,
      _ => 0.12,
    };

    switch (type) {
      case NotificationType.gameInvite:
      case NotificationType.gameUpdate:
        icon = Iconsax.game_copy;
        break;
      case NotificationType.bookingConfirmation:
      case NotificationType.bookingReminder:
        icon = Iconsax.calendar_copy;
        break;
      case NotificationType.friendRequest:
        icon = Iconsax.user_add_copy;
        break;
      case NotificationType.achievement:
        icon = Iconsax.medal_copy;
        break;
      case NotificationType.loyaltyPoints:
        icon = Iconsax.card_copy;
        break;
      case NotificationType.systemAlert:
        icon = Iconsax.warning_2_copy;
        break;
      default:
        icon = Iconsax.notification_copy;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.notification_bing_copy,
            size: 64,
            color: context.colorTokens.neutralOpacity,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colorTokens.neutral,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something happens',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorTokens.neutralOpacity,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(
    String userId,
    NotificationItem notification,
  ) async {
    // Mark as read
    if (!notification.isRead) {
      await ref
          .read(notificationsControllerProvider(userId).notifier)
          .markAsRead(notification.id);
    }

    final route = _resolveNotificationRoute(notification);
    if (route != null && mounted) {
      context.push(route);
    }
  }

  String? _resolveNotificationRoute(NotificationItem notification) {
    final direct = notification.actionRoute;
    if (direct != null && direct.trim().isNotEmpty) return direct;

    final data = notification.data;
    if (data == null || data.isEmpty) return null;

    final dataRoute = data['action_route'];
    if (dataRoute is String && dataRoute.trim().isNotEmpty) {
      return dataRoute;
    }

    switch (notification.type) {
      case NotificationType.friendRequest:
        final fromUserId = _firstStringValue(
          data,
          const <String>[
            'from_user_id',
            'fromUserId',
            'sender_user_id',
            'senderUserId',
            'requester_user_id',
            'requesterUserId',
            'requested_by',
            'peer_user_id',
            'peerUserId',
            'user_id',
          ],
        );

        if (fromUserId != null) {
          return '/user-profile/$fromUserId';
        }

        return null;
      default:
        return null;
    }
  }

  String? _firstStringValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<void> _refresh(String userId) async {
    await ref.read(notificationsControllerProvider(userId).notifier).refresh();
  }

  Future<void> _refreshActivity() async {
    await ref.read(activityFeedControllerProvider.notifier).refresh();
  }

  Widget _buildActivityList(activityState) {
    if (activityState.isLoading && activityState.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activityState.activities.isEmpty) {
      return _buildEmptyActivityState();
    }

    final activities = activityState.filteredActivities;

    return Column(
      children: [
        ...activities.map((activity) {
          return _buildActivityCard(activity);
        }),
        if (activityState.hasMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityFeedEvent activity) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: _getActivityIcon(activity.subjectType),
          title: Text(
            _getActivityTitle(activity),
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorTokens.neutral,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _getActivityDescription(activity),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorTokens.neutralOpacity,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatTime(activity.happenedAt),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorTokens.neutralOpacity,
                    ),
                  ),
                  if (activity.timeBucket != 'past') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTimeBucketColor(
                          activity.timeBucket,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity.timeBucket.toUpperCase(),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: _getTimeBucketColor(activity.timeBucket),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          onTap: () => _handleActivityTap(activity),
        ),
        Divider(height: 1, thickness: 1, color: context.colorTokens.stroke),
      ],
    );
  }

  Widget _getActivityIcon(String subjectType) {
    IconData icon;
    final activitiesScheme = context.getCategoryTheme('activities');
    final color = activitiesScheme.primary;

    switch (subjectType) {
      case 'game':
        icon = Iconsax.game_copy;
        break;
      case 'booking':
        icon = Iconsax.calendar_copy;
        break;
      case 'social':
        icon = Iconsax.people_copy;
        break;
      case 'payment':
        icon = Iconsax.card_copy;
        break;
      case 'reward':
        icon = Iconsax.star_1_copy;
        break;
      default:
        icon = Iconsax.info_circle_copy;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getActivityTitle(ActivityFeedEvent activity) {
    final payload = activity.payload ?? {};

    // Try to get a meaningful title from payload
    if (payload.containsKey('game_name')) {
      return payload['game_name'] as String;
    } else if (payload.containsKey('venue_name')) {
      return payload['venue_name'] as String;
    } else if (payload.containsKey('user_name')) {
      return payload['user_name'] as String;
    }

    // Fallback to subject type and verb
    return '${activity.subjectType.toUpperCase()} ${activity.verb}';
  }

  String _getActivityDescription(ActivityFeedEvent activity) {
    final payload = activity.payload ?? {};

    // Construct description from payload data
    final parts = <String>[];

    if (payload.containsKey('description')) {
      parts.add(payload['description'] as String);
    } else {
      // Build description from verb and subject
      parts.add(
        '${activity.verb.replaceAll('_', ' ')} ${activity.subjectType}',
      );
    }

    if (payload.containsKey('location')) {
      parts.add('at ${payload['location']}');
    }

    if (payload.containsKey('participants_count')) {
      parts.add('${payload['participants_count']} participants');
    }

    return parts.join(' • ');
  }

  Color _getTimeBucketColor(String timeBucket) {
    final activitiesScheme = context.getCategoryTheme('activities');
    switch (timeBucket) {
      case 'present':
      case 'upcoming':
        return activitiesScheme.primary;
      default:
        return context.colorTokens.neutralOpacity;
    }
  }

  void _handleActivityTap(ActivityFeedEvent activity) {
    final payload = activity.payload ?? {};

    // Navigate based on activity type
    if (payload.containsKey('action_route')) {
      context.push(payload['action_route'] as String);
    } else {
      // Default navigation based on subject type
      switch (activity.subjectType) {
        case 'game':
          context.push('/games/${activity.subjectId}');
          break;
        case 'booking':
          context.push('/bookings/${activity.subjectId}');
          break;
        case 'social':
          context.push('/profile');
          break;
      }
    }
  }

  Widget _buildEmptyActivityState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.activity_copy,
            size: 64,
            color: context.colorTokens.neutralOpacity,
          ),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colorTokens.neutral,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activity will appear here',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorTokens.neutralOpacity,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
