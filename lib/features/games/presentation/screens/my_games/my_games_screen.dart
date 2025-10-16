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
}
