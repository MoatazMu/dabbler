import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/services/auth_service.dart';
import '../../features/games/providers/games_providers.dart';
import '../../features/games/domain/entities/game.dart';
import '../../features/games/domain/entities/booking.dart';
import 'all_history_screen_new.dart' as audit_log;

/// Activities screen showing user's games and bookings with real Supabase data
class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshGames() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;
    
    // Refresh both games and bookings
    await Future.wait([
      ref.read(myGamesControllerProvider(user.id).notifier).refresh(),
      ref.read(bookingsControllerProvider(user.id).notifier).loadUpcomingBookings(user.id),
    ]);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎮 Activities refreshed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _refreshBookings() async {
    // TODO: Implement bookings refresh when BookingsRepository is ready
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 Bookings feature coming soon!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      color: const Color(0xFF813FD6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activities',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your games and bookings',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // IconButton(
                  //     icon: const Icon(LucideIcons.search, color: Colors.white),
                  //     onPressed: _startSearch,
                  //   ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.history, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const audit_log.AllHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Material(
              color: Colors.transparent,
              child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.gamepad2, size: 20),
                      SizedBox(width: 8),
                      Text('Games'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.mapPin, size: 20),
                      SizedBox(width: 8),
                      Text('Bookings'),
                    ],
                  ),
                ),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(
        actionIcon: Iconsax.calendar_copy,
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          _buildEnhancedHeader(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJoinedGamesTab(context),
                _buildBookingsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedGamesTab(BuildContext context) {
    final user = _authService.getCurrentUser();
    
    if (user == null) {
      return const Center(
        child: Text('Please log in to view your games'),
      );
    }
    
    final myGamesState = ref.watch(myGamesControllerProvider(user.id));
    final upcomingGames = myGamesState.upcomingGames;
    final isLoading = myGamesState.isLoadingUpcoming;
    final error = myGamesState.error;
    
    return RefreshIndicator(
      onRefresh: _refreshGames,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshGames,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : upcomingGames.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.calendar, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No upcoming games',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Join a game to see it here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context,
                            'Upcoming Games',
                            '${upcomingGames.length} ${upcomingGames.length == 1 ? "game" : "games"}',
                            Icons.schedule,
                          ),
                          const SizedBox(height: 16),
                          _buildUpcomingGamesList(context, upcomingGames),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildBookingsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Active Bookings',
              '2 venues booked',
              Icons.location_pin,
            ),
            const SizedBox(height: 16),
            _buildActiveBookingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingGamesList(BuildContext context, List<Game> upcomingGames) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: upcomingGames.length,
      itemBuilder: (context, index) {
        final game = upcomingGames[index];
        return _buildGameCardFromEntity(context, game);
      },
    );
  }



  /// Build game card from real Game entity (Supabase data)
  Widget _buildGameCardFromEntity(BuildContext context, Game game) {
    // Format date and time
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
    final playersDisplay = '${game.currentPlayers}/${game.maxPlayers}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.violetCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.violetAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    game.title,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
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
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$dateDisplay, $timeDisplay',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    playersDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Remove legacy _buildGameCard method - no longer needed as we use _buildGameCardFromEntity with real data

  Widget _buildActiveBookingsList(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return Center(
        child: Text(
          'Please log in to view bookings',
          style: context.textTheme.bodyLarge,
        ),
      );
    }

    final bookingsState = ref.watch(bookingsControllerProvider(user.id));

    // Load bookings on first build
    ref.listen(bookingsControllerProvider(user.id), (previous, next) {
      if (previous == null && next.upcomingBookings.isEmpty && !next.isLoading) {
        Future.microtask(() {
          ref.read(bookingsControllerProvider(user.id).notifier).loadUpcomingBookings(user.id);
        });
      }
    });

    if (bookingsState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (bookingsState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            bookingsState.error!,
            style: context.textTheme.bodyLarge?.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (bookingsState.upcomingBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No active bookings',
            style: context.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookingsState.upcomingBookings.length,
      itemBuilder: (context, index) {
        final booking = bookingsState.upcomingBookings[index];
        return _buildBookingCardFromEntity(context, booking);
      },
    );
  }



  Widget _buildBookingCardFromEntity(BuildContext context, Booking booking) {
    final dateFormat = DateFormat('MMM d');
    
    // Format booking date
    final isToday = booking.bookingDate.year == DateTime.now().year &&
                    booking.bookingDate.month == DateTime.now().month &&
                    booking.bookingDate.day == DateTime.now().day;
    final isTomorrow = booking.bookingDate.difference(DateTime.now()).inDays == 1;
    
    final dateStr = isToday ? 'Today' : 
                    isTomorrow ? 'Tomorrow' : 
                    dateFormat.format(booking.bookingDate);
    
    // Format time range
    final timeStr = '${booking.startTime} - ${booking.endTime}';
    
    // Format price
    final priceStr = '${booking.currency} ${booking.totalAmount.toStringAsFixed(0)}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.violetCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.venueName,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (booking.courtNumber != null)
                      Text(
                        'Court ${booking.courtNumber}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.onSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceStr,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.primary,
                    ),
                  ),
                  _buildStatusBadge(context, booking.status.toString().split('.').last),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(context, Icons.calendar_today, '$dateStr • $timeStr'),
            ],
          ),
          if (booking.status == BookingStatus.confirmed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('📍 View venue details - Coming soon!'),
                          backgroundColor: context.colors.primary,
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showCancelBookingDialog(context, booking);
                    },
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelBookingDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking?'),
          content: Text('Are you sure you want to cancel your booking at ${booking.venueName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Booking'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                final user = _authService.getCurrentUser();
                if (user != null) {
                  await ref.read(bookingsControllerProvider(user.id).notifier)
                      .cancelBooking(booking.id, 'User requested cancellation');
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = context.successColor(true);  // ✅ Semantic success color
        textColor = context.successColor();
        displayText = 'Confirmed';
        break;
      case 'waiting':
        backgroundColor = context.warningColor(true);   // ✅ Semantic warning color
        textColor = context.warningColor();
        displayText = 'Waiting';
        break;
      case 'completed':
        backgroundColor = context.violetAccent; // ✅ Violet accent shade
        textColor = context.colors.primary;
        displayText = 'Completed';
        break;
      default:
        backgroundColor = context.violetWidgetBg; // ✅ Violet widget background
        textColor = context.colors.onSurface;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16), // ✅ Larger radius for modern look
        // ✅ No borders - pure violet shade design
      ),
      child: Text(
        displayText.toUpperCase(),
        style: context.textTheme.bodySmall?.copyWith(  // ✅ ShadCN typography
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.violetWidgetBg,          // ✅ Violet widget background
        borderRadius: BorderRadius.circular(8), // ✅ Slightly larger radius
        // ✅ No borders - pure violet shade design
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.primary), // ✅ Primary color for icon
          const SizedBox(width: 6),
          Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(  // ✅ ShadCN typography
              color: context.colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

} 