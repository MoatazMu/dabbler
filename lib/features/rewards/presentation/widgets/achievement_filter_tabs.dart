import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/achievement.dart';

class AchievementFilterTabs extends StatefulWidget {
  final AchievementCategory? selectedCategory;
  final ValueChanged<AchievementCategory?> onCategoryChanged;
  final List<AchievementCategory> availableCategories;
  final ScrollController? scrollController;

  const AchievementFilterTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.availableCategories,
    this.scrollController,
  });

  @override
  State<AchievementFilterTabs> createState() => _AchievementFilterTabsState();
}

class _AchievementFilterTabsState extends State<AchievementFilterTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final tabCount = widget.availableCategories.length + 1; // +1 for "All"
    _tabController = TabController(
      length: tabCount,
      vsync: this,
    );
    
    // Set initial selection
    final initialIndex = widget.selectedCategory == null 
        ? 0 
        : widget.availableCategories.indexOf(widget.selectedCategory!) + 1;
    _tabController.index = initialIndex;
    
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    final selectedIndex = _tabController.index;
    final category = selectedIndex == 0 
        ? null 
        : widget.availableCategories[selectedIndex - 1];
    
    widget.onCategoryChanged(category);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apps, size: 16),
                const SizedBox(width: 8),
                const Text('All'),
                if (widget.selectedCategory == null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '∞',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...widget.availableCategories.map((category) {
            final isSelected = widget.selectedCategory == category;
            
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(_getCategoryName(category)),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ).animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        duration: 200.ms,
                      ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gaming:
        return Icons.sports_esports;
      case AchievementCategory.gameParticipation:
        return Icons.sports_esports;
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.profile:
        return Icons.person;
      case AchievementCategory.venue:
        return Icons.location_on;
      case AchievementCategory.engagement:
        return Icons.favorite;
      case AchievementCategory.skillPerformance:
        return Icons.school;
      case AchievementCategory.milestone:
        return Icons.flag_outlined;
      case AchievementCategory.special:
        return Icons.star_outline;
    }
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
}