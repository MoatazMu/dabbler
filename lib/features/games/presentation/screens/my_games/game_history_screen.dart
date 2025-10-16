import 'package:flutter/material.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _selectedSport = 'All';
  String _selectedTimeRange = 'All Time';
  
  final List<String> _sports = ['All', 'Soccer', 'Basketball', 'Tennis', 'Volleyball', 'Other'];
  final List<String> _timeRanges = ['All Time', 'This Month', 'Last 3 Months', 'Last Year'];
  
  final List<Map<String, dynamic>> _gameHistory = [
    {
      'id': '1',
      'title': 'Soccer Championship Final',
      'sport': 'Soccer',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'venue': 'Central Stadium',
      'result': 'Team A won 3-2',
      'yourTeam': 'Team A',
      'won': true,
      'rating': 4.8,
      'players': 12,
      'duration': 90,
      'goals': 2,
      'assists': 1,
    },
    {
      'id': '2',
      'title': 'Basketball Pickup',
      'sport': 'Basketball',
      'date': DateTime.now().subtract(const Duration(days: 12)),
      'venue': 'Sports Center Court 1',
      'result': 'Team B won 85-78',
      'yourTeam': 'Team B',
      'won': true,
      'rating': 4.5,
      'players': 10,
      'duration': 60,
      'points': 18,
      'rebounds': 6,
    },
    {
      'id': '3',
      'title': 'Tennis Doubles Tournament',
      'sport': 'Tennis',
      'date': DateTime.now().subtract(const Duration(days: 20)),
      'venue': 'Tennis Club Court 3',
      'result': 'Lost 6-4, 3-6, 4-6',
      'yourTeam': 'Team 1',
      'won': false,
      'rating': 4.2,
      'players': 4,
      'duration': 120,
      'aces': 8,
      'winners': 15,
    },
    {
      'id': '4',
      'title': 'Volleyball Beach Fun',
      'sport': 'Volleyball',
      'date': DateTime.now().subtract(const Duration(days: 30)),
      'venue': 'Sunset Beach Courts',
      'result': 'Team A won 25-18, 25-22',
      'yourTeam': 'Team A',
      'won': true,
      'rating': 4.7,
      'players': 8,
      'duration': 75,
      'spikes': 12,
      'blocks': 5,
    },
    {
      'id': '5',
      'title': 'Morning Soccer Game',
      'sport': 'Soccer',
      'date': DateTime.now().subtract(const Duration(days: 45)),
      'venue': 'Park Fields',
      'result': 'Tie game 2-2',
      'yourTeam': 'Team B',
      'won': null, // tie
      'rating': 4.1,
      'players': 14,
      'duration': 90,
      'goals': 1,
      'assists': 0,
    },
  ];

  final List<Map<String, dynamic>> _favoritePlayers = [
    {
      'id': '1',
      'name': 'Alex Johnson',
      'avatar': 'male-1.png',
      'gamesPlayed': 8,
      'avgRating': 4.6,
      'sports': ['Soccer', 'Basketball'],
    },
    {
      'id': '2',
      'name': 'Sarah Wilson',
      'avatar': 'female-1.png',
      'gamesPlayed': 5,
      'avgRating': 4.8,
      'sports': ['Tennis', 'Volleyball'],
    },
    {
      'id': '3',
      'name': 'Mike Davis',
      'avatar': 'male-2.png',
      'gamesPlayed': 12,
      'avgRating': 4.4,
      'sports': ['Soccer', 'Volleyball'],
    },
  ];

  List<Map<String, dynamic>> get _filteredGames {
    return _gameHistory.where((game) {
      final sportMatch = _selectedSport == 'All' || game['sport'] == _selectedSport;
      final timeMatch = _isInTimeRange(game['date']);
      return sportMatch && timeMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Games'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            Tab(icon: Icon(Icons.people), text: 'Players'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGamesTab(),
                _buildStatsTab(),
                _buildPlayersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSport,
              decoration: const InputDecoration(
                labelText: 'Sport',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _sports.map((sport) => DropdownMenuItem(
                value: sport,
                child: Text(sport),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSport = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedTimeRange,
              decoration: const InputDecoration(
                labelText: 'Time Range',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _timeRanges.map((range) => DropdownMenuItem(
                value: range,
                child: Text(range),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTimeRange = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesTab() {
    final games = _filteredGames;
    
    if (games.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No games found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameHistoryCard(game);
      },
    );
  }

  Widget _buildGameHistoryCard(Map<String, dynamic> game) {
    final won = game['won'];
    Color resultColor;
    IconData resultIcon;
    String resultText;
    
    if (won == true) {
      resultColor = Colors.green;
      resultIcon = Icons.emoji_events;
      resultText = 'WON';
    } else if (won == false) {
      resultColor = Colors.red;
      resultIcon = Icons.close;
      resultText = 'LOST';
    } else {
      resultColor = Colors.orange;
      resultIcon = Icons.remove;
      resultText = 'TIE';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewGameDetails(game),
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
                          _formatDate(game['date']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: resultColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(resultIcon, size: 14, color: resultColor),
                        const SizedBox(width: 4),
                        Text(
                          resultText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['venue'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['result'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  if (game['rating'] != null) ...[
                    Icon(Icons.star, color: Colors.amber[600], size: 16),
                    const SizedBox(width: 2),
                    Text(
                      game['rating'].toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _buildStatChip(Icons.people, '${game['players']} players'),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.timer, '${game['duration']}min'),
                  
                  if (game['goals'] != null)
                    ...[
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.sports_soccer, '${game['goals']} goals'),
                    ]
                  else if (game['points'] != null)
                    ...[
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.sports_basketball, '${game['points']} pts'),
                    ]
                  else if (game['aces'] != null)
                    ...[
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.sports_tennis, '${game['aces']} aces'),
                    ]
                  else if (game['spikes'] != null)
                    ...[
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.sports_volleyball, '${game['spikes']} spikes'),
                    ],
                ],
              ),
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

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final games = _filteredGames;
    final totalGames = games.length;
    final wins = games.where((g) => g['won'] == true).length;
    final losses = games.where((g) => g['won'] == false).length;
    final ties = games.where((g) => g['won'] == null).length;
    final avgRating = games.isEmpty ? 0.0 : 
        games.map((g) => g['rating'] as double).reduce((a, b) => a + b) / games.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverviewStats(totalGames, wins, losses, ties, avgRating),
          const SizedBox(height: 16),
          _buildSportBreakdown(games),
          const SizedBox(height: 16),
          _buildMonthlyTrend(games),
          const SizedBox(height: 16),
          _buildAchievements(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats(int total, int wins, int losses, int ties, double avgRating) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Games', total.toString(), Icons.sports),
                ),
                Expanded(
                  child: _buildStatItem('Wins', wins.toString(), Icons.emoji_events, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Losses', losses.toString(), Icons.close, Colors.red),
                ),
                Expanded(
                  child: _buildStatItem('Ties', ties.toString(), Icons.remove, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Win Rate', total > 0 ? '${(wins / total * 100).round()}%' : '0%', Icons.trending_up),
                ),
                Expanded(
                  child: _buildStatItem('Avg Rating', avgRating.toStringAsFixed(1), Icons.star, Colors.amber),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
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

  Widget _buildSportBreakdown(List<Map<String, dynamic>> games) {
    final sportCounts = <String, int>{};
    for (final game in games) {
      final sport = game['sport'] as String;
      sportCounts[sport] = (sportCounts[sport] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sport Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (sportCounts.isEmpty)
              const Center(
                child: Text(
                  'No games found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...sportCounts.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _buildSportIcon(entry.key),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${entry.value} game${entry.value == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Text(
                      '${(entry.value / games.length * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrend(List<Map<String, dynamic>> games) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Monthly trend chart would be displayed here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildAchievementItem(
              '🏆',
              'First Victory',
              'Won your first game',
              true,
            ),
            
            _buildAchievementItem(
              '🔥',
              'Hat Trick',
              'Score 3 goals in a soccer game',
              true,
            ),
            
            _buildAchievementItem(
              '⭐',
              'Perfect Rating',
              'Receive a 5-star rating',
              false,
            ),
            
            _buildAchievementItem(
              '🏅',
              'Team Player',
              'Play 10 games in a month',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String emoji, String title, String description, bool earned) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: earned ? Colors.yellow[50] : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(
                color: earned ? Colors.yellow[300]! : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 20,
                  color: earned ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: earned ? null : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          if (earned)
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        ],
      ),
    );
  }

  Widget _buildPlayersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Favorite Players',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._favoritePlayers.map((player) => _buildPlayerCard(player)),
        
        const SizedBox(height: 24),
        
        ElevatedButton.icon(
          onPressed: _viewAllPlayers,
          icon: const Icon(Icons.people),
          label: const Text('View All Players'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage('assets/Avatar/${player['avatar']}'),
          onBackgroundImageError: (_, __) {},
          child: player['avatar'] == null
              ? Text(player['name'][0].toUpperCase())
              : null,
        ),
        title: Text(
          player['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${player['gamesPlayed']} games played'),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                const SizedBox(width: 4),
                Text('${player['avgRating']} avg rating'),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: (player['sports'] as List<String>)
              .take(2)
              .map((sport) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sport,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                  ),
                ),
              ))
              .toList(),
        ),
        isThreeLine: true,
      ),
    );
  }

  bool _isInTimeRange(DateTime date) {
    final now = DateTime.now();
    
    switch (_selectedTimeRange) {
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      case 'Last 3 Months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return date.isAfter(threeMonthsAgo);
      case 'Last Year':
        final lastYear = DateTime(now.year - 1, now.month, now.day);
        return date.isAfter(lastYear);
      default:
        return true;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _viewGameDetails(Map<String, dynamic> game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                game['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Game Details:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Text('Sport: ${game['sport']}'),
              Text('Date: ${_formatDate(game['date'])}'),
              Text('Venue: ${game['venue']}'),
              Text('Result: ${game['result']}'),
              Text('Your Team: ${game['yourTeam']}'),
              Text('Players: ${game['players']}'),
              Text('Duration: ${game['duration']} minutes'),
              if (game['rating'] != null)
                Text('Rating: ${game['rating']} ⭐'),
              
              const SizedBox(height: 16),
              
              if (game['goals'] != null) ...[
                Text(
                  'Your Performance:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Goals: ${game['goals']}'),
                if (game['assists'] != null)
                  Text('Assists: ${game['assists']}'),
              ],
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        // Filter dialog would be shown here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filter options would open here')),
        );
        break;
      case 'export':
        _exportGameHistory();
        break;
    }
  }

  void _exportGameHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Game History'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose export format:'),
            SizedBox(height: 16),
            Text('• PDF Report'),
            Text('• CSV Spreadsheet'),
            Text('• Email Summary'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Game history exported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _viewAllPlayers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening all players list...')),
    );
  }
}
