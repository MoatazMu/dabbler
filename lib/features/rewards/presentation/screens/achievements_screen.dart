import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_progress.dart';
import '../controllers/achievements_controller.dart';
import '../providers/rewards_providers.dart';
import '../widgets/achievement_card.dart';
import 'achievement_detail_screen.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    // Load achievements when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementsControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievementsState = ref.watch(achievementsControllerProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: _buildAchievementsList(achievementsState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final achievementsState = ref.watch(achievementsControllerProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Category filter tabs
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', null),
                ...AchievementCategory.values.map((category) {
                  return _buildCategoryChip(_getCategoryName(category), category);
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Status filter chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatusChip('All', AchievementFilter.all),
                _buildStatusChip('Completed', AchievementFilter.completed),
                _buildStatusChip('In Progress', AchievementFilter.inProgress),
                _buildStatusChip('Not Started', AchievementFilter.notStarted),
              ],
            ),
          ),
          
          if (achievementsState.searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Search: "${achievementsState.searchQuery}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => ref.read(achievementsControllerProvider.notifier).setSearchQuery(''),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).primaryColor,
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

  Widget _buildCategoryChip(String label, AchievementCategory? category) {
    final achievementsState = ref.watch(achievementsControllerProvider);
    final isSelected = achievementsState.selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          ref.read(achievementsControllerProvider.notifier).setCategory(
            selected ? category : null,
          );
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, AchievementFilter filter) {
    final achievementsState = ref.watch(achievementsControllerProvider);
    final isSelected = achievementsState.filter == filter;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          ref.read(achievementsControllerProvider.notifier).setFilter(
            selected ? filter : AchievementFilter.all,
          );
        },
        selectedColor: _getFilterColor(filter).withOpacity(0.2),
        checkmarkColor: _getFilterColor(filter),
        labelStyle: TextStyle(
          color: isSelected ? _getFilterColor(filter) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAchievementsList(AchievementsState state) {
    if (state.isLoading && state.achievements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading achievements...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(achievementsControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredAchievements = state.filteredAchievements;

    if (filteredAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return _isGridView ? _buildGridView(filteredAchievements) : _buildListView(filteredAchievements);
  }

  Widget _buildGridView(List<AchievementWithProgress> achievements) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievementWithProgress = achievements[index];
        return AchievementCard(
          achievement: achievementWithProgress.achievement,
          userProgress: achievementWithProgress.progress,
          onTap: () => _navigateToDetail(
            achievementWithProgress.achievement,
            achievementWithProgress.progress,
          ),
        );
      },
    );
  }

  Widget _buildListView(List<AchievementWithProgress> achievements) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievementWithProgress = achievements[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AchievementCard(
            achievement: achievementWithProgress.achievement,
            userProgress: achievementWithProgress.progress,
            onTap: () => _navigateToDetail(
              achievementWithProgress.achievement,
              achievementWithProgress.progress,
            ),
          ),
        );
      },
    );
  }

  void _navigateToDetail(Achievement achievement, UserProgress progress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementDetailScreen(
          achievement: achievement,
          userProgress: progress,
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(
      text: ref.read(achievementsControllerProvider).searchQuery,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Achievements'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter achievement name or description...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(achievementsControllerProvider.notifier).setSearchQuery('');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(achievementsControllerProvider.notifier).setSearchQuery(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    await ref.read(achievementsControllerProvider.notifier).refresh();
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gaming:
        return 'Gaming';
      case AchievementCategory.gameParticipation:
        return 'Gaming';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.profile:
        return 'Profile';
      case AchievementCategory.venue:
        return 'Venue';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.skillPerformance:
        return 'Skill';
      case AchievementCategory.milestone:
        return 'Milestone';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  Color _getFilterColor(AchievementFilter filter) {
    switch (filter) {
      case AchievementFilter.all:
        return Theme.of(context).primaryColor;
      case AchievementFilter.completed:
        return Colors.green;
      case AchievementFilter.inProgress:
        return Colors.orange;
      case AchievementFilter.notStarted:
        return Colors.grey;
      case AchievementFilter.available:
        return Colors.blue;
      case AchievementFilter.locked:
        return Colors.red;
    }
  }
}