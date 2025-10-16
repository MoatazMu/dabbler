import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tier Management Tab
class TierManagementTab extends ConsumerStatefulWidget {
  const TierManagementTab({super.key});

  @override
  ConsumerState<TierManagementTab> createState() => _TierManagementTabState();
}

class _TierManagementTabState extends ConsumerState<TierManagementTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tier Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Tier Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tier Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildTierConfigs(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Tier Analytics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tier Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTierDistribution(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTierConfigs() {
    final tiers = [
      {'name': 'Bronze', 'min': 0, 'max': 999, 'multiplier': 1.0, 'color': Colors.brown},
      {'name': 'Silver', 'min': 1000, 'max': 4999, 'multiplier': 1.2, 'color': Colors.grey},
      {'name': 'Gold', 'min': 5000, 'max': 14999, 'multiplier': 1.5, 'color': Colors.amber},
      {'name': 'Platinum', 'min': 15000, 'max': 49999, 'multiplier': 1.8, 'color': Colors.blue[200]!},
      {'name': 'Diamond', 'min': 50000, 'max': -1, 'multiplier': 2.0, 'color': Colors.cyan},
    ];

    return tiers.map((tier) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tier['color'] as Color,
          child: Text(
            tier['name'].toString().substring(0, 1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(tier['name'].toString()),
        subtitle: Text(
          '${tier['min']} - ${tier['max'] == -1 ? '∞' : tier['max']} points',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${tier['multiplier']}x',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTier(tier),
            ),
          ],
        ),
      ),
    )).toList();
  }

  Widget _buildTierDistribution() {
    return Column(
      children: [
        _buildTierBar('Bronze', 0.35, Colors.brown),
        _buildTierBar('Silver', 0.28, Colors.grey),
        _buildTierBar('Gold', 0.22, Colors.amber),
        _buildTierBar('Platinum', 0.12, Colors.blue[200]!),
        _buildTierBar('Diamond', 0.03, Colors.cyan),
      ],
    );
  }

  Widget _buildTierBar(String name, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name),
              Text('${(percentage * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  void _editTier(Map<String, dynamic> tier) {
    // Edit tier dialog
  }
}

// Special Rewards Tab
class SpecialRewardsTab extends ConsumerStatefulWidget {
  const SpecialRewardsTab({super.key});

  @override
  ConsumerState<SpecialRewardsTab> createState() => _SpecialRewardsTabState();
}

class _SpecialRewardsTabState extends ConsumerState<SpecialRewardsTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _codeController = TextEditingController();
  final _pointsController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Rewards & Codes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Create Special Reward
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Special Reward',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Reward Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Redemption Code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _generateCode,
                        child: const Text('Generate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Points Value',
                      border: OutlineInputBorder(),
                      suffixText: 'pts',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createReward,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Special Reward'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Active Special Rewards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Special Rewards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.card_giftcard, color: Colors.white),
                        ),
                        title: const Text('Welcome Bonus'),
                        subtitle: const Text('WELCOME2024 • 500 points • Active'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleRewardAction(value),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'disable', child: Text('Disable')),
                            PopupMenuItem(value: 'stats', child: Text('View Stats')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateCode() {
    // Generate unique code
    _codeController.text = 'REWARD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  void _createReward() {
    // Create reward logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Special reward created successfully!')),
    );
    _clearForm();
  }

  void _handleRewardAction(String action) {
    // Handle reward actions
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _codeController.clear();
    _pointsController.clear();
  }
}

// Event Creation Tab
class EventCreationTab extends ConsumerStatefulWidget {
  const EventCreationTab({super.key});

  @override
  ConsumerState<EventCreationTab> createState() => _EventCreationTabState();
}

class _EventCreationTabState extends ConsumerState<EventCreationTab> {
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _multiplierController = TextEditingController(text: '2.0');
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _eventType = 'points_multiplier';
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Creation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _eventNameController,
                    decoration: const InputDecoration(
                      labelText: 'Event Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Event Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _eventType,
                    decoration: const InputDecoration(
                      labelText: 'Event Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'points_multiplier', child: Text('Points Multiplier')),
                      DropdownMenuItem(value: 'special_achievement', child: Text('Special Achievement')),
                      DropdownMenuItem(value: 'daily_bonus', child: Text('Enhanced Daily Bonus')),
                      DropdownMenuItem(value: 'tournament', child: Text('Tournament')),
                    ],
                    onChanged: (value) => setState(() => _eventType = value!),
                  ),
                  const SizedBox(height: 16),
                  if (_eventType == 'points_multiplier')
                    TextField(
                      controller: _multiplierController,
                      decoration: const InputDecoration(
                        labelText: 'Points Multiplier',
                        border: OutlineInputBorder(),
                        suffixText: 'x',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start Date'),
                          subtitle: Text(_startDate?.toString().split(' ')[0] ?? 'Not selected'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _selectStartDate,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End Date'),
                          subtitle: Text(_endDate?.toString().split(' ')[0] ?? 'Not selected'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _selectEndDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _createEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Create Event'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previewEvent,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Preview Event'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Active Events
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.event, color: Colors.white),
                        ),
                        title: const Text('Double Points Weekend'),
                        subtitle: const Text('2.0x multiplier • Ends in 2 days'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) => _handleEventAction(value),
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'end', child: Text('End Early')),
                                PopupMenuItem(value: 'stats', child: Text('View Stats')),
                                PopupMenuItem(value: 'extend', child: Text('Extend')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  void _createEvent() {
    if (_eventNameController.text.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Create event logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event created successfully!')),
    );
    _clearEventForm();
  }

  void _previewEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_eventNameController.text.isEmpty ? 'Event Preview' : _eventNameController.text),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_eventType.replaceAll('_', ' ').toUpperCase()}'),
            if (_eventType == 'points_multiplier')
              Text('Multiplier: ${_multiplierController.text}x'),
            Text('Start: ${_startDate?.toString().split(' ')[0] ?? 'Not set'}'),
            Text('End: ${_endDate?.toString().split(' ')[0] ?? 'Not set'}'),
            const SizedBox(height: 8),
            Text(_descriptionController.text.isEmpty ? 'No description' : _descriptionController.text),
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

  void _handleEventAction(String action) {
    // Handle event actions
  }

  void _clearEventForm() {
    _eventNameController.clear();
    _descriptionController.clear();
    _multiplierController.text = '2.0';
    _startDate = null;
    _endDate = null;
    _eventType = 'points_multiplier';
    setState(() {});
  }
}

// User Progress Viewer Tab
class UserProgressViewerTab extends ConsumerStatefulWidget {
  const UserProgressViewerTab({super.key});

  @override
  ConsumerState<UserProgressViewerTab> createState() => _UserProgressViewerTabState();
}

class _UserProgressViewerTabState extends ConsumerState<UserProgressViewerTab> {
  final _searchController = TextEditingController();
  String? _selectedUserId;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Progress Viewer',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // User Search
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search User',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      hintText: 'Enter username or email',
                    ),
                    onChanged: (value) {
                      // Implement user search
                    },
                  ),
                  if (_selectedUserId != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            child: Icon(Icons.person, size: 30),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'John Doe',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text('john.doe@email.com'),
                                Text('Member since: Jan 2024'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '2,450 pts',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              Text('Gold Tier'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (_selectedUserId != null) ...[
            const SizedBox(height: 24),
            // Progress Overview
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard('Achievements Unlocked', '23/50', Icons.emoji_events, Colors.amber),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressCard('Current Streak', '12 days', Icons.local_fire_department, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard('Badges Earned', '8', Icons.stars, Colors.purple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressCard('Leaderboard Rank', '#42', Icons.leaderboard, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Recent Activity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                        title: const Text('Completed achievement: First Win'),
                        subtitle: const Text('Earned 100 points • 2 hours ago'),
                        trailing: const Text(
                          '+100',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Achievement Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievement Progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.hourglass_empty, color: Colors.white),
                          ),
                          title: const Text('Social Butterfly'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Make friends with 10 users'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: 0.7,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            ],
                          ),
                          trailing: const Text('7/10'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}