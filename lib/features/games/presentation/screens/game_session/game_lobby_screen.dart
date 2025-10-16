import 'package:flutter/material.dart';

class GameLobbyScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final bool isOrganizer;

  const GameLobbyScreen({
    super.key,
    required this.gameData,
    this.isOrganizer = false,
  });

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  DateTime? _gameStartTime;
  int _countdownSeconds = 0;
  
  final List<Map<String, dynamic>> _checkedInPlayers = [
    {
      'id': '1',
      'name': 'John Smith',
      'avatar': 'male-1.png',
      'isOrganizer': true,
      'team': 'A',
      'skillLevel': 'Advanced',
    },
    {
      'id': '2',
      'name': 'Sarah Johnson',
      'avatar': 'female-1.png',
      'isOrganizer': false,
      'team': 'A',
      'skillLevel': 'Intermediate',
    },
    {
      'id': '3',
      'name': 'Mike Wilson',
      'avatar': 'male-2.png',
      'isOrganizer': false,
      'team': 'B',
      'skillLevel': 'Beginner',
    },
    {
      'id': '4',
      'name': 'Emily Davis',
      'avatar': 'female-2.png',
      'isOrganizer': false,
      'team': 'B',
      'skillLevel': 'Intermediate',
    },
    {
      'id': '5',
      'name': 'Alex Brown',
      'avatar': 'male-3.png',
      'isOrganizer': false,
      'team': 'A',
      'skillLevel': 'Advanced',
    },
    {
      'id': '6',
      'name': 'Lisa Chen',
      'avatar': 'female-3.png',
      'isOrganizer': false,
      'team': 'B',
      'skillLevel': 'Intermediate',
    },
  ];

  final Map<String, dynamic> _weatherData = {
    'temperature': 22,
    'condition': 'Partly Cloudy',
    'icon': Icons.cloud,
    'humidity': 65,
    'windSpeed': 8,
    'feelsLike': 24,
  };

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeCountdown();
  }

  void _initializeCountdown() {
    final gameTime = widget.gameData['time'] ?? '00:00';
    final gameDate = widget.gameData['date'] as DateTime?;
    
    if (gameDate != null) {
      final timeParts = gameTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1].split(' ')[0]);
      
      _gameStartTime = DateTime(
        gameDate.year,
        gameDate.month,
        gameDate.day,
        hour,
        minute,
      );
      
      _updateCountdown();
      
      // Update countdown every second
      Stream.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
        if (mounted) {
          _updateCountdown();
        }
      });
    }
  }

  void _updateCountdown() {
    if (_gameStartTime != null) {
      final now = DateTime.now();
      final difference = _gameStartTime!.difference(now);
      
      setState(() {
        _countdownSeconds = difference.inSeconds > 0 ? difference.inSeconds : 0;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
        actions: [
          IconButton(
            onPressed: _showGameRules,
            icon: const Icon(Icons.rule),
            tooltip: 'Game Rules',
          ),
          if (widget.isOrganizer)
            IconButton(
              onPressed: _showTeamAssignment,
              icon: const Icon(Icons.groups),
              tooltip: 'Assign Teams',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCountdownHeader(),
            _buildWeatherInfo(),
            _buildPlayerGrid(),
            if (_needsTeamAssignment()) _buildTeamSection(),
            _buildQuickActions(),
            const SizedBox(height: 100), // Space for bottom actions
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildCountdownHeader() {
    final minutes = _countdownSeconds ~/ 60;
    final seconds = _countdownSeconds % 60;
    final isStartingSoon = _countdownSeconds <= 300 && _countdownSeconds > 0; // 5 minutes
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isStartingSoon 
              ? [Colors.orange[400]!, Colors.orange[600]!]
              : [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.gameData['title'] ?? 'Game Session',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_countdownSeconds > 0) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: isStartingSoon ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isStartingSoon ? 'Game starting soon!' : 'Until game starts',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Game Time!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _weatherData['icon'],
            size: 40,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weatherData['temperature']}°C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _weatherData['condition'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Feels like ${_weatherData['feelsLike']}°C',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Humidity ${_weatherData['humidity']}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Wind ${_weatherData['windSpeed']} km/h',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Players (${_checkedInPlayers.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _checkedInPlayers.length,
            itemBuilder: (context, index) {
              final player = _checkedInPlayers[index];
              return _buildPlayerCard(player);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final teamColor = player['team'] == 'A' ? Colors.blue : Colors.red;
    
    return GestureDetector(
      onTap: () => _showPlayerDetails(player),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: teamColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/Avatar/${player['avatar']}'),
                  onBackgroundImageError: (_, __) {},
                  child: player['avatar'] == null
                      ? Text(player['name'][0].toUpperCase())
                      : null,
                ),
                if (player['isOrganizer'])
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.yellow[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              player['name'].split(' ')[0], // First name only
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            if (_needsTeamAssignment())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Team ${player['team']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: teamColor,
                  ),
                ),
              ),
            
            const SizedBox(height: 4),
            
            _buildSkillBadge(player['skillLevel']),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBadge(String skill) {
    Color color;
    switch (skill) {
      case 'Beginner':
        color = Colors.green;
        break;
      case 'Intermediate':
        color = Colors.orange;
        break;
      case 'Advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        skill.substring(0, 3).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    final teamA = _checkedInPlayers.where((p) => p['team'] == 'A').toList();
    final teamB = _checkedInPlayers.where((p) => p['team'] == 'B').toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Team Assignment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.isOrganizer)
                TextButton(
                  onPressed: _showTeamAssignment,
                  child: const Text('Edit Teams'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Team A (${teamA.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...teamA.map((player) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          player['name'].split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Team B (${teamB.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...teamB.map((player) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          player['name'].split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final venue = widget.gameData['venue'];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.directions,
                  title: 'Directions',
                  subtitle: venue != null ? 'to ${venue['name']}' : 'to venue',
                  onTap: _getDirections,
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildActionCard(
                  icon: Icons.rule,
                  title: 'Game Rules',
                  subtitle: 'Review rules',
                  onTap: _showGameRules,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
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

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.isOrganizer) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showGameSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Game Settings'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _countdownSeconds <= 0 ? _startGame : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(_countdownSeconds <= 0 ? 'Start Game' : 'Wait'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _countdownSeconds <= 0 ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Waiting for organizer to start the game...'),
                    ),
                  );
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Ready to Play'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _needsTeamAssignment() {
    final sport = widget.gameData['sport']?.toLowerCase() ?? '';
    return ['football', 'soccer', 'basketball', 'volleyball', 'hockey'].contains(sport);
  }

  void _showPlayerDetails(Map<String, dynamic> player) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/Avatar/${player['avatar']}'),
            ),
            const SizedBox(height: 16),
            
            Text(
              player['name'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (player['isOrganizer'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'GAME ORGANIZER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Skill Level',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player['skillLevel'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (_needsTeamAssignment())
                  Column(
                    children: [
                      Text(
                        'Team',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Team ${player['team']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
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
    );
  }

  void _showGameRules() {
    final sport = widget.gameData['sport'] ?? 'Game';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$sport Rules'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General Rules:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Respect all players and maintain good sportsmanship'),
              Text('• Follow the organizer\'s instructions'),
              Text('• Play fair and avoid dangerous plays'),
              Text('• Report any injuries immediately'),
              SizedBox(height: 16),
              Text('Game-Specific Rules:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Standard sport rules apply'),
              Text('• Substitutions allowed at any time'),
              Text('• Game duration as specified'),
              Text('• Have fun and stay safe!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showTeamAssignment() {
    if (!widget.isOrganizer) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Teams'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Drag players between teams:'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Team A', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('Team assignment UI would go here')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      children: [
                        Text('Team B', style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('Team assignment UI would go here')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _getDirections() {
    final venue = widget.gameData['venue'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${venue?['name'] ?? 'venue'}...'),
      ),
    );
  }

  void _showGameSettings() {
    if (!widget.isOrganizer) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Game Duration'),
              subtitle: Text('${widget.gameData['duration'] ?? 60} minutes'),
              trailing: const Icon(Icons.edit),
              onTap: () {},
            ),
            
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Team Assignment'),
              subtitle: const Text('Auto-balanced teams'),
              trailing: const Icon(Icons.edit),
              onTap: _showTeamAssignment,
            ),
            
            ListTile(
              leading: const Icon(Icons.notification_important),
              title: const Text('Late Policy'),
              subtitle: const Text('15 minutes grace period'),
              trailing: const Icon(Icons.edit),
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            
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
    );
  }

  void _startGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Game?'),
        content: const Text('This will begin the live game session. All players will be moved to the active game screen.'),
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
                  content: Text('Game started! Moving to live game...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }
}
