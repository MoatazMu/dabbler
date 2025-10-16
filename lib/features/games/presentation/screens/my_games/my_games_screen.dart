import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/games_providers.dart';
import '../../../../../core/services/auth_service.dart';
import '../join_game/game_detail_screen.dart';

class MyGamesScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialNewGame;
  const MyGamesScreen({super.key, this.initialNewGame});

  @override
  ConsumerState<MyGamesScreen> createState() => _MyGamesScreenState();
}

class _MyGamesScreenState extends ConsumerState<MyGamesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCalendarView = false;
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

  @override
  Widget build(BuildContext context) {
    final userId = _authService.getCurrentUserId();
    
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Games')),
        body: const Center(
          child: Text('Please sign in to view your games'),
        ),
      );
    }

    final myGamesState = ref.watch(myGamesControllerProvider(userId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Games'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.upcoming),
              text: 'Upcoming (${myGamesState.upcomingGames.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Past (${myGamesState.pastGames.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            tooltip: _isCalendarView ? 'List View' : 'Calendar View',
          ),
        ],
      ),
      body: myGamesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : myGamesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${myGamesState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(myGamesControllerProvider(userId).notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildStatsHeader(myGamesState),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUpcomingTab(myGamesState.upcomingGames),
                          _buildPastTab(myGamesState.pastGames),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/create-game');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Game'),
      ),
    );
  }

  Widget _buildStatsHeader(myGamesState) {
    final totalGames = myGamesState.upcomingGames.length + myGamesState.pastGames.length;
    final organizerGames = [...myGamesState.upcomingGames, ...myGamesState.pastGames]
        .where((game) => game.organizerId == _authService.getCurrentUserId())
        .length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Games',
              totalGames.toString(),
              Icons.sports_soccer,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildStatCard(
              'Organized',
              organizerGames.toString(),
              Icons.star,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildStatCard(
              'This Month',
              '0',
              Icons.calendar_today,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab(List games) {
    if (_isCalendarView) {
      return _buildCalendarView(games);
    }

    if (games.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No upcoming games', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Create or join a game to get started!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildUpcomingGameCard(game);
      },
    );
  }

  Widget _buildPastTab(List games) {
    if (games.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No past games', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Your completed games will appear here', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildPastGameCard(game);
      },
    );
  }

  Widget _buildCalendarView(List games) {
    return const Center(
      child: Text('Calendar view coming soon'),
    );
  }
  
  Widget _buildUpcomingGameCard(dynamic game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(game.title),
        subtitle: Text('${game.scheduledDate.toString().split(' ')[0]} • ${game.startTime}'),
        trailing: Text('${game.currentPlayers}/${game.maxPlayers}'),
        onTap: () {
          // Navigate to game details
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GameDetailScreen(gameId: game.id),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPastGameCard(dynamic game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(game.title),
        subtitle: Text('${game.scheduledDate.toString().split(' ')[0]} • Completed'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
  
  /* ====================================================================
     OLD IMPLEMENTATION - Commented out for update to use Game entities
     ================================================================= */
  /* 
  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Calendar View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Interactive calendar would be implemented here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick day view for upcoming games
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Games',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ..._upcomingGames.map((game) => _buildUpcomingGameCard(game)),
            ],
          ),
        ],
      ),
    );
  }
  */  // End of old calendar view implementation
  
  Widget _buildUpcomingGameCard(dynamic game) {
    final isToday = _isToday(game.scheduledDate);
    final isTomorrow = _isTomorrow(game.scheduledDate);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
  onTap: () => _openGameDetailsScreen(game),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSportIcon(game['sport']),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (isToday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'TODAY',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    )
                                  else if (isTomorrow)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'TOMORROW',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      _formatDate(game['date']),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  Text(
                                    (game['time'] ?? '').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (game['isOrganizer'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'ORGANIZER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  _buildStatusBadge(game['status']),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['venue']['name'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  Text(
                    game['venue']['distance'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${game['players']['current']}/${game['players']['max']} players',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  _buildQuickActions(game),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastGameCard(Map<String, dynamic> game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
  onTap: () => _openGameDetailsScreen(game),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSportIcon(game['sport']),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        Text(
                          '${_formatDate(game['date'])} • ${game['time']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (game['rating'] != null) _buildRatingDisplay(game['rating']),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['venue']['name'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (game['result'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        game['result'],
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSportIcon(String sport) {
    IconData icon;
    Color color;
    
    switch (sport.toLowerCase()) {
      case 'soccer':
        icon = Icons.sports_soccer;
        color = Colors.green;
        break;
      case 'basketball':
        icon = Icons.sports_basketball;
        color = Colors.orange;
        break;
      case 'tennis':
        icon = Icons.sports_tennis;
        color = Colors.blue;
        break;
      case 'volleyball':
        icon = Icons.sports_volleyball;
        color = Colors.purple;
        break;
      default:
        icon = Icons.sports;
        color = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        text = 'CONFIRMED';
        break;
      case 'waitlist':
        color = Colors.orange;
        text = 'WAITLIST';
        break;
      case 'pending':
        color = Colors.grey;
        text = 'PENDING';
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRatingDisplay(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber[600], size: 16),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Map<String, dynamic> game) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleQuickAction(game, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'directions',
          child: Row(
            children: [
              Icon(Icons.directions, size: 20),
              SizedBox(width: 8),
              Text('Get Directions'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info, size: 20),
              SizedBox(width: 8),
              Text('View Details'),
            ],
          ),
        ),
        if (!game['isOrganizer'])
          const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Cancel Participation', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        if (game['isOrganizer'])
          const PopupMenuItem(
            value: 'manage',
            child: Row(
              children: [
                Icon(Icons.settings, size: 20),
                SizedBox(width: 8),
                Text('Manage Game'),
              ],
            ),
          ),
      ],
      child: const Icon(Icons.more_vert, color: Colors.grey),
    );
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    return [..._upcomingGames, ..._pastGames].where((game) {
      final gameDate = game['date'] as DateTime;
      return gameDate.year == now.year && gameDate.month == now.month;
    }).length;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  void _openGameDetailsScreen(Map<String, dynamic> game) {
    final id = (game['id'] ?? '').toString();
    context.push('/games/$id', extra: {'game': game});
  }

  // (Removed old bottom sheet helper widgets)

  void _handleQuickAction(Map<String, dynamic> game, String action) {
    switch (action) {
      case 'directions':
        _getDirections(game);
        break;
      case 'details':
  _openGameDetailsScreen(game);
        break;
      case 'cancel':
        _cancelParticipation(game);
        break;
      case 'manage':
        _manageGame(game);
        break;
    }
  }

  void _getDirections(Map<String, dynamic> game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${game['venue']['name']}...'),
      ),
    );
  }

  void _cancelParticipation(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Participation'),
        content: Text(
          'Are you sure you want to cancel your participation in "${game['title']}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Participation'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _upcomingGames.removeWhere((g) => g['id'] == game['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Participation cancelled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Participation'),
          ),
        ],
      ),
    );
  }

  void _manageGame(Map<String, dynamic> game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Managing game: ${game['title']}')),
    );
  }
  */  // End of commented out old implementation
}
