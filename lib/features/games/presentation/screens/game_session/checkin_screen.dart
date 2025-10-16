import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CheckInScreen extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final bool isOrganizer;

  const CheckInScreen({
    super.key,
    required this.gameData,
    this.isOrganizer = false,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  
  bool _isScanning = false;
  bool _canStartGame = false;
  
  final List<Map<String, dynamic>> _players = [
    {
      'id': '1',
      'name': 'John Smith',
      'avatar': 'male-1.png',
      'isCheckedIn': true,
      'checkInTime': DateTime.now().subtract(const Duration(minutes: 15)),
      'isOrganizer': true,
    },
    {
      'id': '2',
      'name': 'Sarah Johnson',
      'avatar': 'female-1.png',
      'isCheckedIn': true,
      'checkInTime': DateTime.now().subtract(const Duration(minutes: 10)),
      'isOrganizer': false,
    },
    {
      'id': '3',
      'name': 'Mike Wilson',
      'avatar': 'male-2.png',
      'isCheckedIn': false,
      'checkInTime': null,
      'isOrganizer': false,
    },
    {
      'id': '4',
      'name': 'Emily Davis',
      'avatar': 'female-2.png',
      'isCheckedIn': true,
      'checkInTime': DateTime.now().subtract(const Duration(minutes: 5)),
      'isOrganizer': false,
      'isLate': true,
    },
    {
      'id': '5',
      'name': 'Alex Brown',
      'avatar': 'male-3.png',
      'isCheckedIn': false,
      'checkInTime': null,
      'isOrganizer': false,
    },
    {
      'id': '6',
      'name': 'Lisa Chen',
      'avatar': 'female-3.png',
      'isCheckedIn': false,
      'checkInTime': null,
      'isOrganizer': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateGameStartStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _updateGameStartStatus() {
    final checkedInCount = _players.where((p) => p['isCheckedIn']).length;
    final minPlayers = widget.gameData['minPlayers'] ?? 2;
    setState(() {
      _canStartGame = widget.isOrganizer && checkedInCount >= minPlayers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkedInCount = _players.where((p) => p['isCheckedIn']).length;
    final totalPlayers = _players.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code_scanner),
              text: 'Scan Code',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Player List',
            ),
          ],
        ),
        actions: [
          if (widget.isOrganizer)
            IconButton(
              onPressed: _showManualCheckInDialog,
              icon: const Icon(Icons.person_add),
              tooltip: 'Manual Check-in',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildGameHeader(checkedInCount, totalPlayers),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScannerTab(),
                _buildPlayerListTab(),
              ],
            ),
          ),
          if (widget.isOrganizer) _buildOrganizerActions(),
        ],
      ),
    );
  }

  Widget _buildGameHeader(int checkedIn, int total) {
    final gameTime = widget.gameData['time'] ?? 'Time TBD';
    final venue = widget.gameData['venue']?['name'] ?? 'Venue TBD';
    final now = DateTime.now();
    final gameDateTime = widget.gameData['date'] as DateTime?;
    
    bool isLate = false;
    if (gameDateTime != null) {
      final gameStart = DateTime(
        gameDateTime.year,
        gameDateTime.month,
        gameDateTime.day,
        int.parse(gameTime.split(':')[0]),
        int.parse(gameTime.split(':')[1].split(' ')[0]),
      );
      isLate = now.isAfter(gameStart);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.gameData['title'] ?? 'Game Session',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Game Started',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(gameTime, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(venue, style: TextStyle(color: Colors.grey[700])),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$checkedIn/$total',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Checked In'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getTimeUntilGame(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isLate ? 'Since Start' : 'Until Start',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
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

  Widget _buildScannerTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isScanning) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Position QR code in the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Scanner will automatically detect the code',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isScanning = false;
                });
              },
              child: const Text('Stop Scanning'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan Game QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask the organizer for the game QR code or check-in code',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isScanning = true;
                  });
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Start QR Scanner'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Check-in Code',
                hintText: 'e.g., GAME123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _codeController.text.isNotEmpty ? _submitCode : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Check In with Code'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerListTab() {
    final checkedInPlayers = _players.where((p) => p['isCheckedIn']).toList();
    final waitingPlayers = _players.where((p) => !p['isCheckedIn']).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (checkedInPlayers.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                'Checked In (${checkedInPlayers.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...checkedInPlayers.map((player) => _buildPlayerCard(player)),
          const SizedBox(height: 24),
        ],
        
        if (waitingPlayers.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                'Waiting (${waitingPlayers.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...waitingPlayers.map((player) => _buildPlayerCard(player)),
        ],
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final isCheckedIn = player['isCheckedIn'] as bool;
    final checkInTime = player['checkInTime'] as DateTime?;
    final isLate = player['isLate'] ?? false;

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
            if (isCheckedIn)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
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
            if (player['isOrganizer'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
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
            if (isLate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LATE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
          ],
        ),
        subtitle: isCheckedIn && checkInTime != null
            ? Text('Checked in at ${_formatTime(checkInTime)}')
            : const Text('Not checked in'),
        trailing: isCheckedIn
            ? Icon(Icons.check_circle, color: Colors.green[600])
            : widget.isOrganizer
                ? TextButton(
                    onPressed: () => _checkInPlayer(player['id']),
                    child: const Text('Check In'),
                  )
                : Icon(Icons.schedule, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildOrganizerActions() {
    final minPlayers = widget.gameData['minPlayers'] ?? 2;

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
      child: Column(
        children: [
          if (!_canStartGame)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need at least $minPlayers players to start the game',
                      style: TextStyle(color: Colors.orange[600]),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showGameCodeDialog,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Show Game Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canStartGame ? _startGame : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Game'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _canStartGame ? Colors.green : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeUntilGame() {
    final gameDateTime = widget.gameData['date'] as DateTime?;
    final gameTime = widget.gameData['time'] ?? '00:00';
    
    if (gameDateTime == null) return 'TBD';
    
    final timeParts = gameTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1].split(' ')[0]);
    
    final gameStart = DateTime(
      gameDateTime.year,
      gameDateTime.month,
      gameDateTime.day,
      hour,
      minute,
    );
    
    final now = DateTime.now();
    final difference = gameStart.difference(now);
    
    if (difference.isNegative) {
      final elapsed = now.difference(gameStart);
      if (elapsed.inHours > 0) {
        return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
      } else {
        return '${elapsed.inMinutes}m';
      }
    } else {
      if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else {
        return '${difference.inMinutes}m';
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _submitCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      // Simulate successful check-in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully checked in!'),
          backgroundColor: Colors.green,
        ),
      );
      _codeController.clear();
    }
  }

  void _checkInPlayer(String playerId) {
    setState(() {
      final playerIndex = _players.indexWhere((p) => p['id'] == playerId);
      if (playerIndex != -1) {
        _players[playerIndex]['isCheckedIn'] = true;
        _players[playerIndex]['checkInTime'] = DateTime.now();
      }
    });
    _updateGameStartStatus();
  }

  void _showManualCheckInDialog() {
    final waitingPlayers = _players.where((p) => !p['isCheckedIn']).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Check-In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: waitingPlayers.map((player) => ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/Avatar/${player['avatar']}'),
            ),
            title: Text(player['name']),
            trailing: ElevatedButton(
              onPressed: () {
                _checkInPlayer(player['id']);
                Navigator.pop(context);
              },
              child: const Text('Check In'),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showGameCodeDialog() {
    final gameCode = 'GAME${widget.gameData['id'] ?? '123'}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Check-In Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    gameCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Share this code with players'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: gameCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Game?'),
        content: const Text('Are you ready to start the game? This will move all players to the game lobby.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to game lobby
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Game started! Moving to lobby...'),
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
