import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/widgets/custom_app_bar.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/services/analytics/analytics_service.dart';
import 'package:dabbler/features/games/providers/games_providers.dart';
import 'package:dabbler/data/models/games/game.dart';
import 'package:dabbler/data/models/games/booking.dart';
import 'package:dabbler/data/models/activities/activity_log.dart';
import 'package:dabbler/features/activities/presentation/providers/activity_log_providers.dart';
import 'package:dabbler/core/fp/failure.dart';

// Guard to log core loop completion only once per session
bool _coreLoopLogged = false;

void _logCoreLoopOnceIfEligible(List<Game> items) {
  if (_coreLoopLogged) return;
  if (items.isNotEmpty) {
    _coreLoopLogged = true;
    AnalyticsService.trackEvent('mvp.core_loop_completed', {
      'count': items.length,
    });
  }
}

/// **Activities Screen V2** - Polished & Restructured
///
/// **Features:**
/// - 2 Tabs: Upcoming, Stats
/// - History accessible via app bar icon (opens full-screen view)
/// - Clean, modern Material Design 3
/// - Integrates comprehensive audit log system
/// - Real Supabase data with error handling
/// - Pull-to-refresh on all tabs
/// - Smart empty states
class ActivitiesScreenV2 extends ConsumerStatefulWidget {
  const ActivitiesScreenV2({super.key});

  @override
  ConsumerState<ActivitiesScreenV2> createState() => _ActivitiesScreenV2State();
}

class _ActivitiesScreenV2State extends ConsumerState<ActivitiesScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  List<ActivityLog> _recentActivities = const [];
  bool _isLoadingRecentActivities = false;
  String? _recentActivitiesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _authService.getCurrentUser();
      if (user != null) {
        _loadRecentActivities(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshUpcoming() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    await Future.wait([
      ref.read(myGamesControllerProvider(user.id).notifier).refresh(),
      ref
          .read(bookingsControllerProvider(user.id).notifier)
          .loadUpcomingBookings(user.id),
    ]);

    // Log core loop completion once per session if user has games
    final gamesState = ref.read(myGamesControllerProvider(user.id));
    _logCoreLoopOnceIfEligible(gamesState.upcomingGames);

    // Check for post-game rating opportunities
    _checkForRatingPrompts(user.id);
  }

  Future<void> _refreshStats() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    final controller = ref.read(
      activityLogControllerProvider(user.id).notifier,
    );
    await controller.loadActivities(user.id);
    await controller.loadCategoryStats(user.id);
    await _loadRecentActivities(user.id);
  }

  Future<void> _loadRecentActivities(String userId) async {
    setState(() {
      _isLoadingRecentActivities = true;
      _recentActivitiesError = null;
    });

    final repository = ref.read(activityLogRepositoryProvider);
    final result = await repository.getRecentActivities(userId: userId);

    result.fold(
      (failure) {
        setState(() {
          _recentActivitiesError = failure.message;
          _recentActivities = const [];
          _isLoadingRecentActivities = false;
        });
      },
      (activities) {
        setState(() {
          _recentActivities = activities;
          _isLoadingRecentActivities = false;
        });
      },
    );
  }

  void _checkForRatingPrompts(String userId) {
    final gamesState = ref.read(myGamesControllerProvider(userId));
    final repository = ref.read(gamesRepositoryProvider);

    // Find the first completed game that hasn't been rated this session
    final finishedGames = gamesState.upcomingGames.where((game) {
      final gameEndTime = _getGameEndDateTime(game);
      return gameEndTime.isBefore(DateTime.now()) &&
          !repository.hasRatedInSession(game.id);
    }).toList();

    if (finishedGames.isNotEmpty) {
      // Show rating prompt for the first eligible game
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showRatingSheet(context, finishedGames.first);
        }
      });
    }
  }

  DateTime _getGameEndDateTime(Game game) {
    try {
      final endParts = game.endTime.split(':');
      if (endParts.length >= 2) {
        final hour = int.parse(endParts[0]);
        final minute = int.parse(endParts[1]);
        return DateTime(
          game.scheduledDate.year,
          game.scheduledDate.month,
          game.scheduledDate.day,
          hour,
          minute,
        );
      }
    } catch (e) {
      // Fallback: assume 2 hours after start
    }
    return game.scheduledDate.add(const Duration(hours: 2));
  }

  Future<void> _showRatingSheet(BuildContext context, Game game) async {
    int tempRating = 5; // default
    final rating = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rate this game',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.title,
                    style: Theme.of(
                      ctx,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final v = i + 1;
                      final sel = v <= tempRating;
                      return IconButton(
                        icon: Icon(
                          sel ? Icons.star : Icons.star_border,
                          color: sel ? Colors.amber : Colors.grey,
                          size: 32,
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempRating = v;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(tempRating),
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );

    if (rating == null || !mounted) return;

    final repository = ref.read(gamesRepositoryProvider);
    final r = await repository.rateGame(game.id, rating);

    if (r.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your rating!')),
        );
      }
    } else {
      final failure = r.requireError;
      final msg = failure.category == FailureCode.timeout
          ? 'Network timeout. Try again.'
          : 'Could not submit rating.';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        actionIcon: LucideIcons.history,
        onActionPressed: () {
          // Navigate to full-screen history view
          if (user != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _HistoryScreen(userId: user.id),
              ),
            );
          }
        },
      ),
      body: Column(
        children: [
          //const SizedBox(height: 100),
          _buildHeader(context),
          Expanded(
            child: user == null
                ? _buildSignInPrompt(context)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUpcomingTab(context, user.id),
                      _buildStatsTab(context, user.id),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER SECTION
  // ============================================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF813FD6),
            const Color(0xFF813FD6).withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activities',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track everything in one place',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendar, size: 18),
                        SizedBox(width: 8),
                        Text('Upcoming'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.barChart3, size: 18),
                        SizedBox(width: 8),
                        Text('Stats'),
                      ],
                    ),
                  ),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 1: UPCOMING ACTIVITIES
  // ============================================================================

  Widget _buildUpcomingTab(BuildContext context, String userId) {
    final gamesState = ref.watch(myGamesControllerProvider(userId));
    final bookingsState = ref.watch(bookingsControllerProvider(userId));

    final upcomingGames = gamesState.upcomingGames;
    final upcomingBookings = bookingsState.upcomingBookings;
    final isLoading = gamesState.isLoadingUpcoming || bookingsState.isLoading;

    final totalUpcoming = upcomingGames.length + upcomingBookings.length;

    return RefreshIndicator(
      onRefresh: _refreshUpcoming,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalUpcoming == 0
          ? _buildEmptyUpcoming(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  _buildUpcomingSummary(
                    context,
                    upcomingGames.length,
                    upcomingBookings.length,
                  ),
                  const SizedBox(height: 24),

                  // Upcoming Games
                  if (upcomingGames.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      'Games',
                      upcomingGames.length,
                      LucideIcons.gamepad2,
                    ),
                    const SizedBox(height: 12),
                    ...upcomingGames.map(
                      (game) => _buildGameCard(context, game),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Upcoming Bookings
                  if (upcomingBookings.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      'Venue Bookings',
                      upcomingBookings.length,
                      LucideIcons.mapPin,
                    ),
                    const SizedBox(height: 12),
                    ...upcomingBookings.map(
                      (booking) => _buildBookingCard(context, booking, userId),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildUpcomingSummary(
    BuildContext context,
    int gamesCount,
    int bookingsCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withValues(alpha: 0.1),
            context.colors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              gamesCount.toString(),
              'Games',
              LucideIcons.gamepad2,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: context.colors.primary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildSummaryItem(
              context,
              bookingsCount.toString(),
              'Bookings',
              LucideIcons.mapPin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String count,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: context.colors.primary),
        const SizedBox(height: 8),
        Text(
          count,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.primary,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyUpcoming(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.calendarOff,
                size: 64,
                color: context.colors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No upcoming activities',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join a game or book a venue to get started',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/sports'),
              icon: const Icon(LucideIcons.search),
              label: const Text('Find Sports Games'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 2: STATISTICS
  // ============================================================================

  Widget _buildStatsTab(BuildContext context, String userId) {
    final categoryStats = ref.watch(categoryStatsProvider(userId));
    final activityState = ref.watch(activityLogControllerProvider(userId));

    return RefreshIndicator(
      onRefresh: _refreshStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Overview',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _buildTotalActivitiesCard(context, activityState.activities.length),
            const SizedBox(height: 24),
            Text(
              'By Category',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryStatsGrid(context, categoryStats),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentActivitiesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalActivitiesCard(BuildContext context, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary,
            context.colors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.activity,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Total Activities',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStatsGrid(BuildContext context, Map<String, int> stats) {
    final categories = [
      {
        'name': 'Games',
        'icon': LucideIcons.gamepad2,
        'color': context.colors.primary,
      },
      {'name': 'Bookings', 'icon': LucideIcons.mapPin, 'color': Colors.green},
      {
        'name': 'Payments',
        'icon': LucideIcons.creditCard,
        'color': Colors.orange,
      },
      {'name': 'Social', 'icon': LucideIcons.users, 'color': Colors.blue},
      {'name': 'Rewards', 'icon': LucideIcons.award, 'color': Colors.amber},
      {
        'name': 'Community',
        'icon': LucideIcons.messageSquare,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = stats[category['name']] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.violetCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (category['color'] as Color).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category['icon'] as IconData,
                size: 28,
                color: category['color'] as Color,
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: category['color'] as Color,
                ),
              ),
              Text(
                category['name'] as String,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    if (_isLoadingRecentActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentActivitiesError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.alertCircle, color: context.colors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _recentActivitiesError!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_recentActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.hourglass, color: context.colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No recent activity in the last few days.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentActivities
          .map((activity) => _buildRecentActivityTile(context, activity))
          .toList(),
    );
  }

  Widget _buildRecentActivityTile(BuildContext context, ActivityLog activity) {
    final timestamp = DateFormat('MMM d • h:mm a').format(activity.createdAt);
    final subtitle = '${_formatActivityType(activity.type)} • $timestamp';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.primary.withValues(alpha: 0.1),
            child: Icon(
              _iconForActivity(activity.type),
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activity.description != null &&
                    activity.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.description!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForActivity(ActivityType type) {
    switch (type) {
      case ActivityType.game:
        return LucideIcons.gamepad2;
      case ActivityType.booking:
        return LucideIcons.mapPin;
      case ActivityType.payment:
      case ActivityType.refund:
        return LucideIcons.creditCard;
      case ActivityType.reward:
      case ActivityType.badge:
      case ActivityType.achievement:
        return LucideIcons.award;
      case ActivityType.post:
      case ActivityType.comment:
      case ActivityType.like:
      case ActivityType.share:
      case ActivityType.follow:
        return LucideIcons.users;
      default:
        return LucideIcons.activity;
    }
  }

  String _formatActivityType(ActivityType type) {
    final raw = type.name;
    final withSpaces = raw
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    final trimmed = withSpaces.trim();
    if (trimmed.isEmpty) {
      return raw;
    }
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  // ============================================================================
  // SHARED COMPONENTS
  // ============================================================================

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    int count,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(BuildContext context, Game game) {
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');
    final now = DateTime.now();
    final gameDateTime = game.scheduledDate;

    String dateDisplay;
    if (gameDateTime.year == now.year &&
        gameDateTime.month == now.month &&
        gameDateTime.day == now.day) {
      dateDisplay = 'Today';
    } else if (gameDateTime.year == now.year &&
        gameDateTime.month == now.month &&
        gameDateTime.day == now.day + 1) {
      dateDisplay = 'Tomorrow';
    } else {
      dateDisplay = dateFormat.format(gameDateTime);
    }

    final timeDisplay = timeFormat.format(gameDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.violetCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  game.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${game.currentPlayers}/${game.maxPlayers}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 14,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  game.venueName ?? 'Venue TBD',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.clock, size: 14, color: context.colors.primary),
              const SizedBox(width: 6),
              Text(
                '$dateDisplay, $timeDisplay',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    Booking booking,
    String userId,
  ) {
    final dateFormat = DateFormat('MMM d');
    final now = DateTime.now();

    final isToday =
        booking.bookingDate.year == now.year &&
        booking.bookingDate.month == now.month &&
        booking.bookingDate.day == now.day;
    final isTomorrow = booking.bookingDate.difference(now).inDays == 1;

    final dateStr = isToday
        ? 'Today'
        : isTomorrow
        ? 'Tomorrow'
        : dateFormat.format(booking.bookingDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.violetCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.venueName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${booking.currency} ${booking.totalAmount.toStringAsFixed(0)}',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 14,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.clock, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                '${booking.startTime} - ${booking.endTime}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.userX,
              size: 64,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to view activities',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your games, bookings, and more',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/phone-input'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FULL-SCREEN HISTORY VIEW
// ============================================================================

class _HistoryScreen extends ConsumerStatefulWidget {
  final String userId;

  const _HistoryScreen({required this.userId});

  @override
  ConsumerState<_HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<_HistoryScreen> {
  String _selectedHistoryFilter = 'All';

  Future<void> _refreshHistory() async {
    await ref
        .read(activityLogControllerProvider(widget.userId).notifier)
        .loadActivities(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(
      activityLogControllerProvider(widget.userId),
    );
    final categoryStats = ref.watch(categoryStatsProvider(widget.userId));

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: const Color(0xFF813FD6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: Column(
          children: [
            _buildHistoryFilters(context, categoryStats),
            Expanded(
              child: activityState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : activityState.error != null
                  ? _buildErrorState(context, activityState.error!)
                  : activityState.activities.isEmpty
                  ? _buildEmptyHistory(context)
                  : _buildHistoryList(context, activityState.activities),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilters(BuildContext context, Map<String, int> stats) {
    final filters = [
      'All',
      'Games',
      'Bookings',
      'Payments',
      'Social',
      'Rewards',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedHistoryFilter == filter;
            final count = stats[filter] ?? 0;

            return GestureDetector(
              onTap: () => setState(() => _selectedHistoryFilter = filter),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : context.colors.onSurface,
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
                              ? Colors.white.withValues(alpha: 0.3)
                              : context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : context.colors.primary,
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

  Widget _buildHistoryList(BuildContext context, List<ActivityLog> activities) {
    // Filter activities based on selected filter
    final filteredActivities = _selectedHistoryFilter == 'All'
        ? activities
        : activities.where((activity) {
            final type = activity.type.toString().split('.').last.toLowerCase();
            final filter = _selectedHistoryFilter.toLowerCase();

            if (filter == 'games') return type.contains('game');
            if (filter == 'bookings') return type.contains('booking');
            if (filter == 'payments') {
              return type.contains('payment') || type.contains('transaction');
            }
            if (filter == 'social') {
              return type.contains('post') ||
                  type.contains('friend') ||
                  type.contains('like') ||
                  type.contains('comment');
            }
            if (filter == 'rewards') {
              return type.contains('achievement') ||
                  type.contains('badge') ||
                  type.contains('reward');
            }

            return false;
          }).toList();

    if (filteredActivities.isEmpty) {
      return _buildEmptyFilteredHistory(context);
    }

    // Group by date
    final groupedActivities = <String, List<ActivityLog>>{};
    for (var activity in filteredActivities) {
      final dateGroup = _getDateGroup(activity.createdAt);
      groupedActivities[dateGroup] ??= [];
      groupedActivities[dateGroup]!.add(activity);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedActivities.length,
      itemBuilder: (context, index) {
        final dateGroup = groupedActivities.keys.elementAt(index);
        final items = groupedActivities[dateGroup]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
              child: Text(
                dateGroup,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
            ),
            // Activity Cards
            ...items.map((activity) => _buildActivityCard(context, activity)),
          ],
        );
      },
    );
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) return 'Today';
    if (activityDate == yesterday) return 'Yesterday';
    if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  Widget _buildActivityCard(BuildContext context, ActivityLog activity) {
    final icon = _getActivityIcon(activity.type.toString().split('.').last);
    final color = _getActivityColor(
      context,
      activity.type.toString().split('.').last,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.violetCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.description!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(activity.createdAt),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('game')) return LucideIcons.gamepad2;
    if (t.contains('booking')) return LucideIcons.mapPin;
    if (t.contains('payment')) return LucideIcons.creditCard;
    if (t.contains('friend')) return LucideIcons.userPlus;
    if (t.contains('post')) return LucideIcons.messageSquare;
    if (t.contains('achievement')) return LucideIcons.award;
    if (t.contains('badge')) return LucideIcons.shield;
    return LucideIcons.activity;
  }

  Color _getActivityColor(BuildContext context, String type) {
    final t = type.toLowerCase();
    if (t.contains('game')) return context.colors.primary;
    if (t.contains('booking')) return Colors.green;
    if (t.contains('payment')) return Colors.orange;
    if (t.contains('friend') || t.contains('post')) return Colors.blue;
    if (t.contains('achievement') || t.contains('badge')) return Colors.amber;
    return context.colors.onSurfaceVariant;
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return DateFormat('h:mm a').format(date);
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.history,
              size: 64,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No activity history yet',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your activity will appear here',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredHistory(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.filter,
              size: 64,
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $_selectedHistoryFilter activities',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different filter',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
