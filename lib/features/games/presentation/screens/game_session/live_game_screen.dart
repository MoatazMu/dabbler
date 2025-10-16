import 'package:flutter/material.dart';

class LiveGameScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final bool isOrganizer;

  const LiveGameScreen({
    super.key,
    required this.gameData,
    this.isOrganizer = false,
  });

  @override
  State<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends State<LiveGameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Game timer
  int _gameTimeSeconds = 0;
  bool _isGameActive = true;
  bool _isPaused = false;
  
  // Score tracking
  int _teamAScore = 0;
  int _teamBScore = 0;
  
  // Player management
  final List<Map<String, dynamic>> _players = [
    {
      'id': '1',
      'name': 'John Smith',
      'avatar': 'male-1.png',
      'team': 'A',
      'isActive': true,
      'isOrganizer': true,
    },
    {
      'id': '2',
      'name': 'Sarah Johnson',
      'avatar': 'female-1.png',
      'team': 'A',
      'isActive': true,
      'isOrganizer': false,
    },
    {
      'id': '3',
      'name': 'Mike Wilson',
      'avatar': 'male-2.png',
      'team': 'B',
      'isActive': true,
      'isOrganizer': false,
    },
    {
      'id': '4',
      'name': 'Emily Davis',
      'avatar': 'female-2.png',
      'team': 'B',
      'isActive': false,
      'isOrganizer': false,
    },
    {
      'id': '5',
      'name': 'Alex Brown',
      'avatar': 'male-3.png',
      'team': 'A',
      'isActive': true,
      'isOrganizer': false,
    },
    {
      'id': '6',
      'name': 'Lisa Chen',
      'avatar': 'female-3.png',
      'team': 'B',
      'isActive': true,
      'isOrganizer': false,
    },
  ];

  final List<Map<String, dynamic>> _gameEvents = [];
  final TextEditingController _notesController = TextEditingController();
  
  // Weather
  final Map<String, dynamic> _weatherData = {
    'temperature': 20,
    'condition': 'Light Rain',
    'icon': Icons.grain,
    'alert': 'Weather conditions may affect play',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startGameTimer();
  }

  void _startGameTimer() {
    Stream.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
      if (_isGameActive && !_isPaused && mounted) {
        setState(() {
          _gameTimeSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameData['title'] ?? 'Live Game'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer), text: 'Game'),
            Tab(icon: Icon(Icons.people), text: 'Players'),
            Tab(icon: Icon(Icons.note), text: 'Notes'),
          ],
        ),
        actions: [
          if (widget.isOrganizer)
            IconButton(
              onPressed: _showGameMenu,
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildGameHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGameTab(),
                _buildPlayersTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isOrganizer ? _buildOrganizerActions() : null,
    );
  }

  Widget _buildGameHeader() {
    final minutes = _gameTimeSeconds ~/ 60;
    final seconds = _gameTimeSeconds % 60;
    final maxDuration = widget.gameData['duration'] ?? 60;
    final isOvertime = minutes >= maxDuration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOvertime 
              ? [Colors.orange[400]!, Colors.orange[600]!]
              : [Colors.green[400]!, Colors.green[600]!],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Team A Score
              Column(
                children: [
                  Text(
                    'Team A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _teamAScore.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Timer
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isGameActive)
                        const Icon(Icons.pause, color: Colors.white, size: 16),
                      if (_isPaused)
                        const Icon(Icons.pause, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOvertime ? 'Overtime' : 'Game Time',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Team B Score
              Column(
                children: [
                  Text(
                    'Team B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _teamBScore.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          LinearProgressIndicator(
            value: minutes / maxDuration,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_weatherData['alert'] != null) _buildWeatherAlert(),
          const SizedBox(height: 16),
          
          if (widget.isOrganizer) ...[
            _buildScoreControls(),
            const SizedBox(height: 16),
          ],
          
          _buildGameEvents(),
          const SizedBox(height: 16),
          
          _buildQuickReporting(),
        ],
      ),
    );
  }

  Widget _buildWeatherAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        children: [
          Icon(_weatherData['icon'], color: Colors.amber[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weatherData['temperature']}°C - ${_weatherData['condition']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _weatherData['alert'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Score Control',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Team A', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _teamAScore > 0 ? () => _updateScore('A', -1) : null,
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                          ),
                          Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _teamAScore.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _updateScore('A', 1),
                            icon: const Icon(Icons.add_circle),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Column(
                    children: [
                      const Text('Team B', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _teamBScore > 0 ? () => _updateScore('B', -1) : null,
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                          ),
                          Container(
                            width: 50,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _teamBScore.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _updateScore('B', 1),
                            icon: const Icon(Icons.add_circle),
                            color: Colors.green,
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

  Widget _buildGameEvents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_gameEvents.isEmpty) 
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No events recorded yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gameEvents.length,
                itemBuilder: (context, index) {
                  final event = _gameEvents[_gameEvents.length - 1 - index]; // Reverse order
                  return _buildEventTile(event);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(Map<String, dynamic> event) {
    IconData icon;
    Color color;
    
    switch (event['type']) {
      case 'score':
        icon = Icons.sports_score;
        color = Colors.green;
        break;
      case 'injury':
        icon = Icons.local_hospital;
        color = Colors.red;
        break;
      case 'substitution':
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Text(event['description']),
      subtitle: Text(_formatEventTime(event['time'])),
    );
  }

  Widget _buildQuickReporting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showInjuryReport(),
                    icon: const Icon(Icons.local_hospital),
                    label: const Text('Injury'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showIssueReport(),
                    icon: const Icon(Icons.report_problem),
                    label: const Text('Issue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[100],
                      foregroundColor: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTab() {
    final activePlayers = _players.where((p) => p['isActive']).toList();
    final benchedPlayers = _players.where((p) => !p['isActive']).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (activePlayers.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.sports, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Active Players (${activePlayers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...activePlayers.map((player) => _buildPlayerCard(player, true)),
            const SizedBox(height: 24),
          ],
          
          if (benchedPlayers.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.event_seat, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Bench (${benchedPlayers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...benchedPlayers.map((player) => _buildPlayerCard(player, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, bool isActive) {
    final teamColor = player['team'] == 'A' ? Colors.blue : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/Avatar/${player['avatar']}'),
              onBackgroundImageError: (_, __) {},
              child: player['avatar'] == null
                  ? Text(player['name'][0].toUpperCase())
                  : null,
            ),
            if (!isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              player['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ],
        ),
        subtitle: Text(isActive ? 'Playing' : 'On bench'),
        trailing: widget.isOrganizer 
            ? PopupMenuButton<String>(
                onSelected: (value) => _handlePlayerAction(player, value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: isActive ? 'bench' : 'play',
                    child: Text(isActive ? 'Move to Bench' : 'Put in Game'),
                  ),
                  const PopupMenuItem(
                    value: 'report_injury',
                    child: Text('Report Injury'),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Notes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Add notes about the game, player performance, memorable moments, etc...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _notesController.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveNotes,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Notes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerActions() {
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isPaused ? _resumeGame : _pauseGame,
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(_isPaused ? 'Resume' : 'Pause'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _endGame,
              icon: const Icon(Icons.stop),
              label: const Text('End Game'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateScore(String team, int change) {
    setState(() {
      if (team == 'A') {
        _teamAScore += change;
      } else {
        _teamBScore += change;
      }
    });
    
    if (change > 0) {
      _addGameEvent({
        'type': 'score',
        'description': 'Team $team scored',
        'time': _gameTimeSeconds,
      });
    }
  }

  void _addGameEvent(Map<String, dynamic> event) {
    setState(() {
      _gameEvents.add(event);
    });
  }

  String _formatEventTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handlePlayerAction(Map<String, dynamic> player, String action) {
    switch (action) {
      case 'bench':
        setState(() {
          player['isActive'] = false;
        });
        _addGameEvent({
          'type': 'substitution',
          'description': '${player['name']} moved to bench',
          'time': _gameTimeSeconds,
        });
        break;
      case 'play':
        setState(() {
          player['isActive'] = true;
        });
        _addGameEvent({
          'type': 'substitution',
          'description': '${player['name']} entered the game',
          'time': _gameTimeSeconds,
        });
        break;
      case 'report_injury':
        _showInjuryReport(player);
        break;
    }
  }

  void _showInjuryReport([Map<String, dynamic>? player]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Injury'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player != null)
              Text('Player: ${player['name']}')
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Player'),
                items: _players.map((p) => DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Text(p['name'] as String),
                )).toList(),
                onChanged: (value) {},
              ),
            
            const SizedBox(height: 16),
            
            const TextField(
              decoration: InputDecoration(
                labelText: 'Describe the injury',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
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
              _addGameEvent({
                'type': 'injury',
                'description': 'Injury reported: ${player?['name'] ?? 'Player'}',
                'time': _gameTimeSeconds,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showIssueReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Describe the issue',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
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
                const SnackBar(content: Text('Issue reported')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showGameMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('Extend Game Time'),
              subtitle: const Text('Add 15 minutes'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game time extended by 15 minutes')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Mass Substitution'),
              subtitle: const Text('Swap multiple players'),
              onTap: () {
                Navigator.pop(context);
                // Show substitution interface
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Game Settings'),
              onTap: () {
                Navigator.pop(context);
                // Show game settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pauseGame() {
    setState(() {
      _isPaused = true;
    });
    _addGameEvent({
      'type': 'pause',
      'description': 'Game paused',
      'time': _gameTimeSeconds,
    });
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
    });
    _addGameEvent({
      'type': 'resume',
      'description': 'Game resumed',
      'time': _gameTimeSeconds,
    });
  }

  void _endGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Game?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to end the game?'),
            const SizedBox(height: 16),
            Text(
              'Final Score:\nTeam A: $_teamAScore\nTeam B: $_teamBScore',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isGameActive = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Game ended! Moving to post-game...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Game'),
          ),
        ],
      ),
    );
  }

  void _saveNotes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes saved!')),
    );
  }
}
