import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/data/models/activities/activity_log.dart';
import 'package:dabbler/features/activities/presentation/providers/activity_log_providers.dart';

class AllHistoryScreen extends ConsumerStatefulWidget {
  const AllHistoryScreen({super.key});

  @override
  ConsumerState<AllHistoryScreen> createState() => _AllHistoryScreenState();
}

class _AllHistoryScreenState extends ConsumerState<AllHistoryScreen> {
  String selectedFilter = 'All';
  final AuthService _authService = AuthService();

  // All available filters
  static const List<String> filters = [
    'All',
    'Games',
    'Bookings',
    'Teams',
    'Challenges',
    'Payments',
    'Community',
    'Groups',
    'Events',
    'Rewards',
  ];

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view activities')),
      );
    }

    final activityState = ref.watch(activityLogControllerProvider(user.id));
    final categoryStats = ref.watch(categoryStatsProvider(user.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(actionIcon: Iconsax.calendar_copy),
      body: Column(
        children: [
          const SizedBox(height: 100),
          _buildFilterSection(context, categoryStats),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshHistoryData(context, user.id),
              child: activityState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : activityState.error != null
                  ? _buildErrorState(context, activityState.error!)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHistoryStats(context, categoryStats),
                          const SizedBox(height: 24),
                          _buildHistoryList(context, user.id),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            final count = stats[filter] ?? 0;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
                final user = _authService.getCurrentUser();
                if (user != null) {
                  ref
                      .read(activityLogControllerProvider(user.id).notifier)
                      .filterByCategory(filter, user.id);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryStats(BuildContext context, Map<String, int> stats) {
    final totalActivities = stats['All'] ?? 0;
    final gamesCount = stats['Games'] ?? 0;
    final bookingsCount = stats['Bookings'] ?? 0;
    final communityCount = stats['Community'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Activities',
                  totalActivities.toString(),
                  LucideIcons.activity,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Games',
                  gamesCount.toString(),
                  LucideIcons.users,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Bookings',
                  bookingsCount.toString(),
                  LucideIcons.mapPin,
                  Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Community',
                  communityCount.toString(),
                  LucideIcons.messageSquare,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, String userId) {
    final state = ref.watch(activityLogControllerProvider(userId));

    // Group activities by date
    final groupedActivities = <String, List<ActivityLog>>{};
    for (var activity in state.activities) {
      String dateGroup;
      if (activity.isToday) {
        dateGroup = 'Today';
      } else if (activity.isYesterday) {
        dateGroup = 'Yesterday';
      } else if (activity.isThisWeek) {
        dateGroup = 'This Week';
      } else if (activity.createdAt.isAfter(
        DateTime.now().subtract(const Duration(days: 30)),
      )) {
        dateGroup = 'This Month';
      } else {
        dateGroup = 'Older';
      }

      if (!groupedActivities.containsKey(dateGroup)) {
        groupedActivities[dateGroup] = [];
      }
      groupedActivities[dateGroup]!.add(activity);
    }

    // Check if we have any activities
    bool hasActivities = groupedActivities.values.any(
      (list) => list.isNotEmpty,
    );

    if (!hasActivities) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Timeline',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        // Show each date group
        ...groupedActivities.entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (activity) => _buildActivityCard(context, activity),
                  ),
                ],
              );
            }),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, ActivityLog activity) {
    final icon = _getActivityIcon(activity.type);
    final color = _getActivityColor(activity.type);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: activity.actionRoute != null
              ? () {
                  // Navigate to action route
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔗 Navigate to: ${activity.actionRoute}'),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                // Activity details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            dateFormat.format(activity.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                      if (activity.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          activity.description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (activity.venue != null)
                            _buildInfoChip(
                              context,
                              LucideIcons.mapPin,
                              activity.venue!,
                            ),
                          if (activity.amount != null)
                            _buildInfoChip(
                              context,
                              LucideIcons.dollarSign,
                              '${activity.amount!.toStringAsFixed(0)} ${activity.currency ?? 'AED'}',
                            ),
                          if (activity.points != null)
                            _buildInfoChip(
                              context,
                              LucideIcons.gift,
                              '${activity.points! > 0 ? '+' : ''}${activity.points} pts',
                            ),
                          if (activity.count != null)
                            _buildInfoChip(
                              context,
                              LucideIcons.heart,
                              '${activity.count}',
                            ),
                          if (activity.targetUserName != null)
                            _buildInfoChip(
                              context,
                              LucideIcons.user,
                              activity.targetUserName!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.game:
      case ActivityType.gameJoin:
      case ActivityType.gameComplete:
        return LucideIcons.users;
      case ActivityType.booking:
      case ActivityType.bookingConfirm:
        return LucideIcons.mapPin;
      case ActivityType.post:
        return LucideIcons.messageSquare;
      case ActivityType.like:
        return LucideIcons.heart;
      case ActivityType.comment:
        return LucideIcons.messageCircle;
      case ActivityType.share:
        return LucideIcons.share2;
      case ActivityType.team:
        return LucideIcons.shield;
      case ActivityType.challenge:
        return LucideIcons.target;
      case ActivityType.payment:
        return LucideIcons.creditCard;
      case ActivityType.achievement:
      case ActivityType.badge:
        return LucideIcons.award;
      case ActivityType.loyaltyPoints:
      case ActivityType.reward:
        return LucideIcons.gift;
      case ActivityType.friendRequest:
      case ActivityType.follow:
        return LucideIcons.userPlus;
      case ActivityType.message:
        return LucideIcons.mail;
      case ActivityType.group:
        return LucideIcons.users;
      case ActivityType.event:
        return LucideIcons.calendar;
      case ActivityType.checkIn:
        return LucideIcons.mapPin;
      default:
        return LucideIcons.activity;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.game:
      case ActivityType.gameJoin:
      case ActivityType.gameComplete:
        return Colors.green;
      case ActivityType.booking:
      case ActivityType.bookingConfirm:
        return Colors.blue;
      case ActivityType.post:
      case ActivityType.comment:
        return Colors.purple;
      case ActivityType.like:
      case ActivityType.follow:
        return Colors.pink;
      case ActivityType.share:
        return Colors.indigo;
      case ActivityType.team:
        return Colors.teal;
      case ActivityType.challenge:
        return Colors.orange;
      case ActivityType.payment:
      case ActivityType.refund:
        return Colors.red;
      case ActivityType.achievement:
      case ActivityType.badge:
        return Colors.amber;
      case ActivityType.loyaltyPoints:
      case ActivityType.reward:
        return Colors.deepOrange;
      case ActivityType.friendRequest:
        return Colors.cyan;
      case ActivityType.message:
        return Colors.blueGrey;
      case ActivityType.group:
        return Colors.deepPurple;
      case ActivityType.event:
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.history, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${selectedFilter.toLowerCase()} activities',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${selectedFilter.toLowerCase()} activities will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load activities',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final user = _authService.getCurrentUser();
              if (user != null) {
                ref
                    .read(activityLogControllerProvider(user.id).notifier)
                    .refresh(user.id);
              }
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshHistoryData(BuildContext context, String userId) async {
    await ref
        .read(activityLogControllerProvider(userId).notifier)
        .refresh(userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📊 Activity history refreshed successfully!'),
          backgroundColor: Colors.indigo,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
