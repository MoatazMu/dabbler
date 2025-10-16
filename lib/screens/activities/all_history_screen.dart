import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/services/auth_service.dart';
import '../../features/games/providers/games_providers.dart';

class AllHistoryScreen extends ConsumerStatefulWidget {
  const AllHistoryScreen({super.key});

  @override
  ConsumerState<AllHistoryScreen> createState() => _AllHistoryScreenState();
}

class _AllHistoryScreenState extends ConsumerState<AllHistoryScreen> {
  String selectedFilter = 'All';
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        actionIcon: Iconsax.calendar_copy,
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          _buildFilterSection(context),
                     Expanded(
             child: RefreshIndicator(
               onRefresh: () => _refreshHistoryData(context),
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(20),
                 physics: const AlwaysScrollableScrollPhysics(),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildHistoryStats(context),
                     const SizedBox(height: 24),
                     _buildHistoryList(context),
                   ],
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final filters = ['All', 'Games', 'Bookings'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Text(
                filter,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryStats(BuildContext context) {
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Total Activities',
              '20',
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
              'Games Played',
              '12',
              LucideIcons.users,
              Colors.green,
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
              'Venues Booked',
              '8',
              LucideIcons.mapPin,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
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

  Widget _buildHistoryList(BuildContext context) {
    final allHistory = _getFilteredHistory();
    
    if (allHistory.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allHistory.length,
          itemBuilder: (context, index) {
            final activity = allHistory[index];
            return _buildHistoryCard(context, activity);
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    final user = _authService.getCurrentUser();
    if (user == null) return [];

    final myGamesState = ref.watch(myGamesControllerProvider(user.id));
    final bookingsState = ref.watch(bookingsControllerProvider(user.id));

    // Load data if not already loaded
    if (myGamesState.pastGames.isEmpty && !myGamesState.isLoading) {
      Future.microtask(() {
        // Load past games - we'll need to add this method
        ref.read(myGamesControllerProvider(user.id).notifier).refresh();
      });
    }

    if (bookingsState.pastBookings.isEmpty && !bookingsState.isLoading) {
      Future.microtask(() {
        ref.read(bookingsControllerProvider(user.id).notifier).loadPastBookings(user.id);
      });
    }

    // Combine games and bookings into unified history
    final List<Map<String, dynamic>> allHistory = [];

    // Add past games (already filtered for past in the controller)
    for (final game in myGamesState.pastGames) {
      final dateFormat = DateFormat('MMM d');
      final timeFormat = DateFormat('h:mm a');
      
      allHistory.add({
        'type': 'game',
        'id': game.id,
        'title': game.title,
        'venue': game.venueName ?? 'Unknown Venue',
        'date': game.scheduledDate.toIso8601String(),
        'displayDate': dateFormat.format(game.scheduledDate),
        'time': timeFormat.format(game.getScheduledStartDateTime()),
        'price': '${game.pricePerPlayer.toStringAsFixed(0)} ${game.currency}',
        'rating': '0.0',
        'status': 'completed',
        'players': '${game.currentPlayers}/${game.maxPlayers}',
      });
    }

    // Add past bookings
    for (final booking in bookingsState.pastBookings) {
      final dateFormat = DateFormat('MMM d');
      
      allHistory.add({
        'type': 'booking',
        'id': booking.id,
        'title': booking.venueName,
        'venue': booking.venueName,
        'date': booking.bookingDate.toIso8601String(),
        'displayDate': dateFormat.format(booking.bookingDate),
        'time': '${booking.startTime} - ${booking.endTime}',
        'price': '${booking.totalAmount.toStringAsFixed(0)} ${booking.currency}',
        'sport': booking.courtNumber != null ? 'Court ${booking.courtNumber}' : '',
        'status': booking.status.toString().split('.').last,
      });
    }

    // Filter based on selected filter
    List<Map<String, dynamic>> filtered;
    if (selectedFilter == 'Games') {
      filtered = allHistory.where((item) => item['type'] == 'game').toList();
    } else if (selectedFilter == 'Bookings') {
      filtered = allHistory.where((item) => item['type'] == 'booking').toList();
    } else {
      filtered = allHistory;
    }

    // Sort by date (most recent first)
    filtered.sort((a, b) => b['date'].compareTo(a['date']));
    
    return filtered;
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> activity) {
    final isGame = activity['type'] == 'game';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Activity type tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGame 
                        ? Colors.green.shade50 
                        : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isGame 
                          ? Colors.green.shade200 
                          : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGame ? LucideIcons.users : LucideIcons.mapPin,
                          size: 12,
                          color: isGame 
                            ? Colors.green.shade700 
                            : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGame ? 'Game' : 'Booking',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isGame 
                              ? Colors.green.shade700 
                              : Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    activity['displayDate'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'],
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              activity['venue'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        activity['price'],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (isGame && activity['rating'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.star, size: 12, color: Colors.amber[600]),
                            const SizedBox(width: 2),
                            Text(
                              activity['rating'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(context, LucideIcons.clock, activity['time']),
                  if (isGame) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(context, LucideIcons.users, activity['players']),
                  ] else ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(context, LucideIcons.target, activity['sport']),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isGame 
                            ? '🔄 Book similar game - Coming soon!'
                            : '🔄 Book venue again - Coming soon!'),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    },
                    child: Text(isGame ? 'Book Similar' : 'Book Again'),
                  ),
                ],
              ),
            ],
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
            child: Icon(
              LucideIcons.history,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${selectedFilter.toLowerCase()} history',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${selectedFilter.toLowerCase()} activities will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshHistoryData(BuildContext context) async {
    final user = _authService.getCurrentUser();
    if (user == null) return;
    
    // Refresh both games and bookings
    await Future.wait([
      ref.read(myGamesControllerProvider(user.id).notifier).refresh(),
      ref.read(bookingsControllerProvider(user.id).notifier).loadPastBookings(user.id),
    ]);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📊 History refreshed successfully!'),
          backgroundColor: Colors.indigo,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
} 