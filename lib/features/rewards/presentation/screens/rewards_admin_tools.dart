import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dabbler/features/rewards/domain/entities/achievement.dart';
import 'package:dabbler/features/rewards/domain/entities/badge_tier.dart';
import 'package:dabbler/features/rewards/domain/entities/achievement_criteria.dart';

class RewardsAdminTools extends ConsumerStatefulWidget {
  const RewardsAdminTools({super.key});

  @override
  ConsumerState<RewardsAdminTools> createState() => _RewardsAdminToolsState();
}

class _RewardsAdminToolsState extends ConsumerState<RewardsAdminTools>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        title: const Text('Rewards Admin Tools'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
            Tab(icon: Icon(Icons.stars), text: 'Points'),
            Tab(icon: Icon(Icons.military_tech), text: 'Tiers'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Special Rewards'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.person_search), text: 'User Progress'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AchievementEditorTab(),
          PointsAdjustmentTab(),
          TierManagementTab(),
          SpecialRewardsTab(),
          EventCreationTab(),
          UserProgressViewerTab(),
        ],
      ),
    );
  }
}

// Achievement Editor Tab
class AchievementEditorTab extends ConsumerStatefulWidget {
  const AchievementEditorTab({super.key});

  @override
  ConsumerState<AchievementEditorTab> createState() => _AchievementEditorTabState();
}

class _AchievementEditorTabState extends ConsumerState<AchievementEditorTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _maxProgressController = TextEditingController();
  
  AchievementCategory _selectedCategory = AchievementCategory.gaming;
  BadgeTier _selectedTier = BadgeTier.bronze;
  String _selectedDifficulty = 'easy';
  AchievementType _selectedType = AchievementType.single;
  bool _isHidden = false;
  bool _isActive = true;
  
  List<AchievementCriteria> _criteria = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _maxProgressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(adminAchievementsProvider);
    
    return Row(
      children: [
        // Achievement List
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search achievements...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          // Implement search
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _createNewAchievement,
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: achievements.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (achievementList) => ListView.builder(
                    itemCount: achievementList.length,
                    itemBuilder: (context, index) {
                      final achievement = achievementList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTierColor(achievement.tier),
                            child: Icon(
                              _getCategoryIcon(achievement.category),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(achievement.name),
                          subtitle: Text(
                            '${achievement.category} • ${achievement.tier.name} • ${achievement.points} pts',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!achievement.isActive)
                                const Icon(Icons.pause_circle, color: Colors.orange),
                              if (achievement.isHidden)
                                const Icon(Icons.visibility_off, color: Colors.grey),
                              PopupMenuButton<String>(
                                onSelected: (value) => _handleAchievementAction(value, achievement),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                                  const PopupMenuItem(value: 'toggle', child: Text('Toggle Active')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _editAchievement(achievement),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Achievement Editor Form
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievement Editor',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Basic Information
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Achievement Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Category and Tier Selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<AchievementCategory>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: AchievementCategory.gaming, child: Text('Games')),
                              DropdownMenuItem(value: AchievementCategory.social, child: Text('Social')),
                              DropdownMenuItem(value: AchievementCategory.profile, child: Text('Profile')),
                              DropdownMenuItem(value: AchievementCategory.venue, child: Text('Venue')),
                            ],
                            onChanged: (value) => setState(() => _selectedCategory = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<BadgeTier>(
                            initialValue: _selectedTier,
                            decoration: const InputDecoration(
                              labelText: 'Tier',
                              border: OutlineInputBorder(),
                            ),
                            items: BadgeTier.values
                                .map((tier) => DropdownMenuItem(
                                      value: tier,
                                      child: Text(tier.name.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedTier = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Points and Difficulty
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pointsController,
                            decoration: const InputDecoration(
                              labelText: 'Points Reward',
                              border: OutlineInputBorder(),
                              suffixText: 'pts',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Points required';
                              if (int.tryParse(value!) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedDifficulty,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'easy', child: Text('Easy')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'hard', child: Text('Hard')),
                              DropdownMenuItem(value: 'expert', child: Text('Expert')),
                            ],
                            onChanged: (value) => setState(() => _selectedDifficulty = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Achievement Type and Settings
                    DropdownButtonFormField<AchievementType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Achievement Type',
                        border: OutlineInputBorder(),
                      ),
                      items: AchievementType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_selectedType != AchievementType.single)
                      TextFormField(
                        controller: _maxProgressController,
                        decoration: const InputDecoration(
                          labelText: 'Max Progress',
                          border: OutlineInputBorder(),
                          helperText: 'Required for streak/cumulative achievements',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 16),
                    
                    // Toggles
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Hidden Achievement'),
                            subtitle: const Text('Not visible until unlocked'),
                            value: _isHidden,
                            onChanged: (value) => setState(() => _isHidden = value!),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Active'),
                            subtitle: const Text('Available for completion'),
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Criteria Section
                    _buildSectionHeader('Achievement Criteria'),
                    const SizedBox(height: 16),
                    ..._criteria.asMap().entries.map((entry) {
                      final index = entry.key;
                      final criteria = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Criteria ${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeCriteria(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: criteria.key,
                                      decoration: const InputDecoration(
                                        labelText: 'Stat Key',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) =>
                                          _updateCriteria(index, key: value),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: criteria.value.toString(),
                                      decoration: const InputDecoration(
                                        labelText: 'Target Value',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => _updateCriteria(
                                        index,
                                        value: double.tryParse(value) ?? 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    ElevatedButton.icon(
                      onPressed: _addCriteria,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Criteria'),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveAchievement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text('Save Achievement'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetForm,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text('Reset Form'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Color _getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze: return Colors.brown;
      case BadgeTier.silver: return Colors.grey;
      case BadgeTier.gold: return Colors.amber;
      case BadgeTier.platinum: return Colors.blue[200]!;
      case BadgeTier.diamond: return Colors.cyan;
    }
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gaming: return Icons.sports_esports;
      case AchievementCategory.social: return Icons.people;
      case AchievementCategory.venue: return Icons.explore;
      case AchievementCategory.profile: return Icons.trending_up;
      case AchievementCategory.engagement: return Icons.favorite;
      case AchievementCategory.special: return Icons.star;
      case AchievementCategory.gameParticipation: return Icons.games;
      case AchievementCategory.skillPerformance: return Icons.speed;
      case AchievementCategory.milestone: return Icons.flag;
    }
  }

  void _createNewAchievement() {
    _resetForm();
  }

  void _editAchievement(Achievement achievement) {
    _nameController.text = achievement.name;
    _descriptionController.text = achievement.description;
    _pointsController.text = achievement.points.toString();
    _selectedCategory = achievement.category;
    _selectedTier = achievement.tier;
    _isHidden = achievement.isHidden;
    _isActive = achievement.isActive;
    _criteria = achievement.criteria.entries.map((entry) =>
        AchievementCriteria(
          key: entry.key,
          value: entry.value,
          comparator: CriteriaComparator.greaterThanOrEqual,
          description: '${entry.key} must be ${entry.value}',
        )).toList();
    setState(() {});
  }

  void _handleAchievementAction(String action, Achievement achievement) {
    switch (action) {
      case 'edit':
        _editAchievement(achievement);
        break;
      case 'duplicate':
        _editAchievement(achievement);
        _nameController.text = '${achievement.name} (Copy)';
        break;
      case 'toggle':
        ref.read(adminAchievementsProvider.notifier).toggleActive(achievement.id);
        break;
      case 'delete':
        _confirmDelete(achievement);
        break;
    }
  }

  void _confirmDelete(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Achievement'),
        content: Text('Are you sure you want to delete "${achievement.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminAchievementsProvider.notifier).delete(achievement.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addCriteria() {
    setState(() {
      _criteria.add(AchievementCriteria(
        key: '',
        value: 1.0,
        comparator: CriteriaComparator.greaterThanOrEqual,
        description: 'New criteria',
      ));
    });
  }

  void _removeCriteria(int index) {
    setState(() {
      _criteria.removeAt(index);
    });
  }

  void _updateCriteria(int index, {String? key, dynamic value}) {
    if (index < _criteria.length) {
      final criteria = _criteria[index];
      _criteria[index] = AchievementCriteria(
        key: key ?? criteria.key,
        value: value ?? criteria.value,
        comparator: criteria.comparator,
        description: criteria.description,
      );
    }
  }

  void _saveAchievement() {
    if (_formKey.currentState?.validate() ?? false) {
      final achievement = Achievement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        code: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        tier: _selectedTier,
        points: int.parse(_pointsController.text),
        criteria: Map.fromEntries(_criteria.map((c) => MapEntry(c.key, c.value))),
        type: _selectedType,
        isHidden: _isHidden,
        isActive: _isActive,
        maxProgress: _maxProgressController.text.isNotEmpty 
            ? int.parse(_maxProgressController.text) 
            : null,
        createdAt: DateTime.now(),
      );

      ref.read(adminAchievementsProvider.notifier).save(achievement);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievement saved successfully!')),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _pointsController.clear();
    _maxProgressController.clear();
    _selectedCategory = AchievementCategory.gaming;
    _selectedTier = BadgeTier.bronze;
    _selectedDifficulty = 'easy';
    _selectedType = AchievementType.single;
    _isHidden = false;
    _isActive = true;
    _criteria.clear();
    setState(() {});
  }
}

// Points Adjustment Tab
class PointsAdjustmentTab extends ConsumerStatefulWidget {
  const PointsAdjustmentTab({super.key});

  @override
  ConsumerState<PointsAdjustmentTab> createState() => _PointsAdjustmentTabState();
}

class _PointsAdjustmentTabState extends ConsumerState<PointsAdjustmentTab> {
  final _userSearchController = TextEditingController();
  final _pointsController = TextEditingController();
  final _reasonController = TextEditingController();
  
  String? _selectedUserId;
  String _adjustmentType = 'add';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Points Adjustment Tool',
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
                  const Text(
                    'Select User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _userSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by username or email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Implement user search
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedUserId != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected User',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Current Points: 1,250'),
                                Text('Tier: Gold'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Points Adjustment
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Points Adjustment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _adjustmentType,
                          decoration: const InputDecoration(
                            labelText: 'Adjustment Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'add', child: Text('Add Points')),
                            DropdownMenuItem(value: 'subtract', child: Text('Subtract Points')),
                            DropdownMenuItem(value: 'set', child: Text('Set Points')),
                          ],
                          onChanged: (value) => setState(() => _adjustmentType = value!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _pointsController,
                          decoration: const InputDecoration(
                            labelText: 'Points Amount',
                            border: OutlineInputBorder(),
                            suffixText: 'pts',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Adjustment',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Compensation for bug, Contest prize, etc.',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedUserId != null ? _applyAdjustment : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Apply Adjustment'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previewAdjustment,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Preview Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Recent Adjustments
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Adjustments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) => ListTile(
                      leading: Icon(
                        Icons.edit,
                        color: Colors.orange[600],
                      ),
                      title: const Text('Points adjustment for user123'),
                      subtitle: const Text('+500 points • Contest prize • 2 hours ago'),
                      trailing: const Text(
                        '+500',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
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

  void _applyAdjustment() {
    if (_pointsController.text.isEmpty || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Points Adjustment'),
        content: Text(
          'Are you sure you want to $_adjustmentType ${_pointsController.text} points?\n\n'
          'Reason: ${_reasonController.text}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply adjustment logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Points adjustment applied successfully!')),
              );
              _clearForm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _previewAdjustment() {
    if (_pointsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter points amount')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Adjustment'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Points: 1,250'),
            Text('Current Tier: Gold'),
            SizedBox(height: 16),
            Text('After Adjustment:'),
            Text('New Points: 1,750', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('New Tier: Gold', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Impact:'),
            Text('• No tier change'),
            Text('• Leaderboard position may change'),
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

  void _clearForm() {
    _pointsController.clear();
    _reasonController.clear();
    _adjustmentType = 'add';
    setState(() {});
  }
}

// Provider definitions and other tabs would continue here...
// TierManagementTab, SpecialRewardsTab, EventCreationTab, UserProgressViewerTab

// Missing Tab Classes - Placeholder implementations
class TierManagementTab extends ConsumerWidget {
  const TierManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Tier Management - Coming Soon'),
    );
  }
}

class SpecialRewardsTab extends ConsumerWidget {
  const SpecialRewardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Special Rewards - Coming Soon'),
    );
  }
}

class EventCreationTab extends ConsumerWidget {
  const EventCreationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Event Creation - Coming Soon'),
    );
  }
}

class UserProgressViewerTab extends ConsumerWidget {
  const UserProgressViewerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('User Progress Viewer - Coming Soon'),
    );
  }
}

// Mock provider for demonstration
final adminAchievementsProvider = StateNotifierProvider<AdminAchievementsNotifier, AsyncValue<List<Achievement>>>(
  (ref) => AdminAchievementsNotifier(),
);

class AdminAchievementsNotifier extends StateNotifier<AsyncValue<List<Achievement>>> {
  AdminAchievementsNotifier() : super(const AsyncValue.loading()) {
    _loadAchievements();
  }

  void _loadAchievements() async {
    try {
      // Mock loading achievements
      await Future.delayed(const Duration(seconds: 1));
      state = AsyncValue.data(_generateMockAchievements());
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  List<Achievement> _generateMockAchievements() {
    return [
      // Mock achievements would be generated here
    ];
  }

  void save(Achievement achievement) {
    // Save achievement logic
  }

  void delete(String id) {
    // Delete achievement logic
  }

  void toggleActive(String id) {
    // Toggle active state logic
  }
}