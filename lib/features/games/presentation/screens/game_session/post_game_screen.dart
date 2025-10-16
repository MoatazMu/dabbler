import 'package:flutter/material.dart';
import '../../../services/game_completion_rewards_handler.dart';
import '../../../../../core/services/auth_service.dart';

class PostGameScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Map<String, dynamic> gameResults;
  final bool isOrganizer;

  const PostGameScreen({
    super.key,
    required this.gameData,
    required this.gameResults,
    this.isOrganizer = false,
  });

  @override
  State<PostGameScreen> createState() => _PostGameScreenState();
}

class _PostGameScreenState extends State<PostGameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GameCompletionRewardsHandler _rewardsHandler;
  
  final Map<String, Map<String, int>> _playerRatings = {};
  bool _hasRated = false;
  bool _showQuickRating = true;
  bool _rewardsProcessed = false;
  
  final List<Map<String, dynamic>> _players = [
    {
      'id': '1',
      'name': 'John Smith',
      'avatar': 'male-1.png',
      'team': 'A',
      'isOrganizer': true,
    },
    {
      'id': '2',
      'name': 'Sarah Johnson',
      'avatar': 'female-1.png',
      'team': 'A',
      'isOrganizer': false,
    },
    {
      'id': '3',
      'name': 'Mike Wilson',
      'avatar': 'male-2.png',
      'team': 'B',
      'isOrganizer': false,
    },
    {
      'id': '4',
      'name': 'Emily Davis',
      'avatar': 'female-2.png',
      'team': 'B',
      'isOrganizer': false,
    },
    {
      'id': '5',
      'name': 'Alex Brown',
      'avatar': 'male-3.png',
      'team': 'A',
      'isOrganizer': false,
    },
    {
      'id': '6',
      'name': 'Lisa Chen',
      'avatar': 'female-3.png',
      'team': 'B',
      'isOrganizer': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _rewardsHandler = GameCompletionRewardsHandler();
    _initializeRatings();
    _processGameRewards();
  }

  void _initializeRatings() {
    for (final player in _players) {
      _playerRatings[player['id']] = {
        'skill': 0,
        'sportsmanship': 0,
      };
    }
  }

  /// Process rewards for game completion
  Future<void> _processGameRewards() async {
    if (_rewardsProcessed) return;
    
    try {
      final authService = AuthService();
      final currentUser = authService.getCurrentUser();
      
      if (currentUser == null || !mounted) return;

      // Extract game data
      final gameId = widget.gameData['id'] ?? 'unknown';
      final sport = widget.gameData['sport'] ?? 'unknown';
      final teamAScore = widget.gameResults['teamAScore'] ?? 0;
      final teamBScore = widget.gameResults['teamBScore'] ?? 0;
      final gameDuration = Duration(minutes: widget.gameResults['duration'] ?? 60);
      
      // Determine if current user won (simplified logic)
      final isWinner = _determineIfWinner(currentUser.id, teamAScore, teamBScore);
      
      // Prepare game stats
      final gameStats = {
        'score': isWinner ? (teamAScore > teamBScore ? teamAScore : teamBScore) : (teamAScore < teamBScore ? teamAScore : teamBScore),
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'mvp': widget.gameResults['mvpId'] == currentUser.id,
        'goals': widget.gameResults['playerStats']?[currentUser.id]?['goals'] ?? 0,
        'assists': widget.gameResults['playerStats']?[currentUser.id]?['assists'] ?? 0,
        'points': widget.gameResults['playerStats']?[currentUser.id]?['points'] ?? 0,
        'rebounds': widget.gameResults['playerStats']?[currentUser.id]?['rebounds'] ?? 0,
      };

      // Process rewards
      await _rewardsHandler.handleGameCompletion(
        userId: currentUser.id,
        gameId: gameId,
        sport: sport,
        isWinner: isWinner,
        gameDuration: gameDuration,
        gameStats: gameStats,
        context: context,
      );

      _rewardsProcessed = true;
    } catch (e) {
      debugPrint('Error processing game rewards: $e');
    }
  }

  /// Determine if the current user won (simplified logic)
  bool _determineIfWinner(String userId, int teamAScore, int teamBScore) {
    // In a real implementation, you would check which team the user was on
    // For now, assuming user was on Team A if they're the first player
    final userPlayer = _players.firstWhere(
      (player) => player['id'] == userId,
      orElse: () => _players.first,
    );
    
    final userTeam = userPlayer['team'] ?? 'A';
    
    if (teamAScore == teamBScore) return false; // Tie
    
    return (userTeam == 'A' && teamAScore > teamBScore) ||
           (userTeam == 'B' && teamBScore > teamAScore);
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
        title: const Text('Game Complete'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Results'),
            Tab(icon: Icon(Icons.star_rate), text: 'Rate Players'),
            Tab(icon: Icon(Icons.share), text: 'Share'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResultsTab(),
          _buildRatingTab(),
          _buildShareTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildResultsTab() {
    final teamAScore = widget.gameResults['teamAScore'] ?? 0;
    final teamBScore = widget.gameResults['teamBScore'] ?? 0;
    final gameDuration = widget.gameResults['duration'] ?? 0;
    final winner = teamAScore > teamBScore ? 'Team A' : 
                   teamBScore > teamAScore ? 'Team B' : 'Tie';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFinalScoreCard(teamAScore, teamBScore, winner),
          const SizedBox(height: 16),
          _buildGameStatsCard(gameDuration),
          const SizedBox(height: 16),
          _buildMVPCard(),
          const SizedBox(height: 16),
          _buildGameHighlights(),
        ],
      ),
    );
  }

  Widget _buildFinalScoreCard(int teamAScore, int teamBScore, String winner) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: winner == 'Tie' 
                ? [Colors.grey[400]!, Colors.grey[600]!]
                : [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            
            Text(
              winner == 'Tie' ? 'Game Tied!' : '$winner Wins!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text(
                      'Team A',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      teamAScore.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                
                Column(
                  children: [
                    const Text(
                      'Team B',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      teamBScore.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatsCard(int duration) {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Duration',
                    '${minutes}m ${seconds}s',
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Players',
                    _players.length.toString(),
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Sport',
                    widget.gameData['sport'] ?? 'Game',
                    Icons.sports_soccer,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Venue',
                    widget.gameData['venue']?['name'] ?? 'TBD',
                    Icons.location_on,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[600]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildMVPCard() {
    // Mock MVP selection (would be based on ratings)
    final mvp = _players.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Player of the Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/Avatar/${mvp['avatar']}'),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.yellow[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mvp['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Team ${mvp['team']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow[600], size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8 avg rating',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHighlights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Highlights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            const ListTile(
              dense: true,
              leading: Icon(Icons.sports_score, color: Colors.green),
              title: Text('Close match with great teamwork'),
              subtitle: Text('Both teams showed excellent sportsmanship'),
            ),
            
            const ListTile(
              dense: true,
              leading: Icon(Icons.emoji_people, color: Colors.blue),
              title: Text('Everyone participated actively'),
              subtitle: Text('High engagement from all players'),
            ),
            
            const ListTile(
              dense: true,
              leading: Icon(Icons.celebration, color: Colors.orange),
              title: Text('Fun and competitive atmosphere'),
              subtitle: Text('Perfect game for skill development'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_showQuickRating) ...[
            _buildQuickRatingSection(),
            const SizedBox(height: 24),
            
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showQuickRating = false;
                      });
                    },
                    child: const Text('Detailed Rating'),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          if (!_showQuickRating) ...[
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showQuickRating = true;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quick Rating'),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          if (!_showQuickRating) _buildDetailedRatingSection(),
        ],
      ),
    );
  }

  Widget _buildQuickRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Quick Rating',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              'Rate all players with one click',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickRatingButton(
                    '👍',
                    'Great Game',
                    'Rate all players 4-5 stars',
                    () => _applyQuickRating(4.5),
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: _buildQuickRatingButton(
                    '👌',
                    'Good Game',
                    'Rate all players 3-4 stars',
                    () => _applyQuickRating(3.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickRatingButton(
                    '🤔',
                    'Mixed Game',
                    'Rate individually',
                    () {
                      setState(() {
                        _showQuickRating = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: _buildQuickRatingButton(
                    '👎',
                    'Issues',
                    'Rate players 1-2 stars',
                    () => _applyQuickRating(1.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRatingButton(String emoji, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatingSection() {
    // Don't rate yourself
    final playersToRate = _players.where((p) => p['id'] != 'current_user_id').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Each Player',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...playersToRate.map((player) => _buildPlayerRatingCard(player)),
      ],
    );
  }

  Widget _buildPlayerRatingCard(Map<String, dynamic> player) {
    final playerId = player['id'];
    final skillRating = _playerRatings[playerId]?['skill'] ?? 0;
    final sportsmanshipRating = _playerRatings[playerId]?['sportsmanship'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/Avatar/${player['avatar']}'),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Team ${player['team']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Skill Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skill Level',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: List.generate(5, (index) => GestureDetector(
                    onTap: () => _updateRating(playerId, 'skill', index + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        index < skillRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sportsmanship Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sportsmanship',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: List.generate(5, (index) => GestureDetector(
                    onTap: () => _updateRating(playerId, 'sportsmanship', index + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        index < sportsmanshipRating ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGameSummaryCard(),
          const SizedBox(height: 16),
          _buildShareOptionsCard(),
          const SizedBox(height: 16),
          _buildRematchCard(),
          const SizedBox(height: 16),
          _buildVenueReviewCard(),
        ],
      ),
    );
  }

  Widget _buildGameSummaryCard() {
    final teamAScore = widget.gameResults['teamAScore'] ?? 0;
    final teamBScore = widget.gameResults['teamBScore'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              '${widget.gameData['title'] ?? 'Game'}\n'
              'Final Score: Team A $teamAScore - $teamBScore Team B\n'
              'Sport: ${widget.gameData['sport'] ?? 'Game'}\n'
              'Players: ${_players.length}\n'
              'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Game Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareButton(
                  Icons.message,
                  'Message',
                  Colors.green,
                  () => _shareResults('message'),
                ),
                _buildShareButton(
                  Icons.email,
                  'Email',
                  Colors.blue,
                  () => _shareResults('email'),
                ),
                _buildShareButton(
                  Icons.share,
                  'Social',
                  Colors.purple,
                  () => _shareResults('social'),
                ),
                _buildShareButton(
                  Icons.copy,
                  'Copy',
                  Colors.grey,
                  () => _shareResults('copy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRematchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Want a Rematch?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Schedule another game with the same players',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scheduleRematch,
                icon: const Icon(Icons.refresh),
                label: const Text('Schedule Rematch'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueReviewCard() {
    final venue = widget.gameData['venue'];
    if (venue == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate the Venue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Help other players by rating ${venue['name']}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _rateVenue,
                icon: const Icon(Icons.star_rate),
                label: const Text('Rate Venue'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home),
              label: const Text('Home'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _hasRated ? null : _submitRatings,
              icon: Icon(_hasRated ? Icons.check : Icons.star),
              label: Text(_hasRated ? 'Rated' : 'Submit Ratings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _hasRated ? Colors.green : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyQuickRating(double rating) {
    setState(() {
      for (final playerId in _playerRatings.keys) {
        if (playerId != 'current_user_id') { // Don't rate yourself
          _playerRatings[playerId]!['skill'] = rating.round();
          _playerRatings[playerId]!['sportsmanship'] = rating.round();
        }
      }
      _showQuickRating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick rating applied to all players!')),
    );
  }

  void _updateRating(String playerId, String type, int rating) {
    setState(() {
      _playerRatings[playerId]![type] = rating;
    });
  }

  void _submitRatings() {
    setState(() {
      _hasRated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Player ratings submitted! Thank you for your feedback.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareResults(String platform) {
    final teamAScore = widget.gameResults['teamAScore'] ?? 0;
    final teamBScore = widget.gameResults['teamBScore'] ?? 0;
    final message = 'Just finished a great ${widget.gameData['sport']} game! '
        'Final score: Team A $teamAScore - $teamBScore Team B. '
        'Thanks to all players for a fun match! 🏆';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing via $platform: $message')),
    );
  }

  void _scheduleRematch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Rematch'),
        content: const Text(
          'This will create a new game with the same players and settings. '
          'You can modify the date, time, and venue in the next step.',
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
                  content: Text('Creating rematch game...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create Rematch'),
          ),
        ],
      ),
    );
  }

  void _rateVenue() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate ${widget.gameData['venue']['name']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 16),
            
            const TextField(
              decoration: InputDecoration(
                labelText: 'Leave a review (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Venue review submitted!')),
                  );
                },
                child: const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
