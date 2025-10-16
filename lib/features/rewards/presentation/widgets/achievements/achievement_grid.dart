
import 'package:flutter/material.dart';

import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/user_progress.dart';
import 'achievement_card.dart';

enum GridLayout {
  compact,
  comfortable,
  detailed,
}

enum SortBy {
  name,
  points,
  progress,
  tier,
  category,
  dateUnlocked,
}

class AchievementGrid extends StatefulWidget {
  final List<Achievement> achievements;
  final Map<String, UserProgress> userProgressMap;
  final GridLayout layout;
  final bool showCategories;
  final bool enableSearch;
  final bool enableFiltering;
  final bool enableInfiniteScroll;
  final AchievementCategory? selectedCategory;
  final SortBy sortBy;
  final bool sortAscending;
  final String searchQuery;
  final int itemsPerPage;
  final ScrollController? scrollController;
  final Function(Achievement)? onAchievementTap;
  final Function(Achievement)? onAchievementLongPress;
  final Function(String)? onSearchChanged;
  final Function(AchievementCategory?)? onCategoryChanged;
  final Function(SortBy, bool)? onSortChanged;

  const AchievementGrid({
    super.key,
    required this.achievements,
    required this.userProgressMap,
    this.layout = GridLayout.comfortable,
    this.showCategories = true,
    this.enableSearch = true,
    this.enableFiltering = true,
    this.enableInfiniteScroll = false,
    this.selectedCategory,
    this.sortBy = SortBy.name,
    this.sortAscending = true,
    this.searchQuery = '',
    this.itemsPerPage = 20,
    this.scrollController,
    this.onAchievementTap,
    this.onAchievementLongPress,
    this.onSearchChanged,
    this.onCategoryChanged,
    this.onSortChanged,
  });

  @override
  State<AchievementGrid> createState() => _AchievementGridState();
}

class _AchievementGridState extends State<AchievementGrid>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  List<Achievement> _filteredAchievements = [];
  Map<AchievementCategory, List<Achievement>> _groupedAchievements = {};
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    
    _scrollController = widget.scrollController ?? ScrollController();
    if (widget.enableInfiniteScroll) {
      _scrollController.addListener(_onScroll);
    }

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _filterAndSortAchievements();
  }

  @override
  void didUpdateWidget(AchievementGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.achievements != widget.achievements ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.selectedCategory != widget.selectedCategory ||
        oldWidget.sortBy != widget.sortBy ||
        oldWidget.sortAscending != widget.sortAscending) {
      _filterAndSortAchievements();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      setState(() {
        _isLoading = true;
      });

      _loadingController.forward();

      // Simulate loading more data
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _currentPage++;
          _isLoading = false;
          
          // Check if there are more items to load
          final totalItems = widget.achievements.length;
          final loadedItems = _currentPage * widget.itemsPerPage;
          _hasMore = loadedItems < totalItems;
        });

        _loadingController.reset();
        _filterAndSortAchievements();
      });
    }
  }

  void _filterAndSortAchievements() {
    List<Achievement> filtered = List.from(widget.achievements);

    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered.where((achievement) {
        final query = widget.searchQuery.toLowerCase();
        return achievement.name.toLowerCase().contains(query) ||
               achievement.description.toLowerCase().contains(query) ||
               achievement.code.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (widget.selectedCategory != null) {
      filtered = filtered.where((achievement) {
        return achievement.category == widget.selectedCategory;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (widget.sortBy) {
        case SortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortBy.points:
          comparison = a.points.compareTo(b.points);
          break;
        case SortBy.progress:
          final progressA = widget.userProgressMap[a.id]?.calculateProgress() ?? 0;
          final progressB = widget.userProgressMap[b.id]?.calculateProgress() ?? 0;
          comparison = progressA.compareTo(progressB);
          break;
        case SortBy.tier:
          comparison = a.tier.index.compareTo(b.tier.index);
          break;
        case SortBy.category:
          comparison = a.category.index.compareTo(b.category.index);
          break;
        case SortBy.dateUnlocked:
          final progressA = widget.userProgressMap[a.id];
          final progressB = widget.userProgressMap[b.id];
          final completedA = progressA?.completedAt;
          final completedB = progressB?.completedAt;
          
          if (completedA == null && completedB == null) {
            comparison = 0;
          } else if (completedA == null) comparison = 1;
          else if (completedB == null) comparison = -1;
          else comparison = completedA.compareTo(completedB);
          break;
      }

      return widget.sortAscending ? comparison : -comparison;
    });

    // Apply pagination for infinite scroll
    if (widget.enableInfiniteScroll) {
      final itemsToShow = _currentPage * widget.itemsPerPage;
      filtered = filtered.take(itemsToShow).toList();
    }

    setState(() {
      _filteredAchievements = filtered;
      
      if (widget.showCategories) {
        _groupedAchievements = _groupByCategory(filtered);
      }
    });
  }

  Map<AchievementCategory, List<Achievement>> _groupByCategory(
    List<Achievement> achievements,
  ) {
    final Map<AchievementCategory, List<Achievement>> grouped = {};
    
    for (final achievement in achievements) {
      if (!grouped.containsKey(achievement.category)) {
        grouped[achievement.category] = [];
      }
      grouped[achievement.category]!.add(achievement);
    }

    return grouped;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filters
        if (widget.enableSearch || widget.enableFiltering)
          _buildSearchAndFilters(),

        // Content
        Expanded(
          child: _filteredAchievements.isEmpty
              ? _buildEmptyState()
              : widget.showCategories
                  ? _buildCategorizedGrid()
                  : _buildSimpleGrid(),
        ),

        // Loading indicator for infinite scroll
        if (widget.enableInfiniteScroll && _isLoading)
          _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          if (widget.enableSearch)
            TextField(
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search achievements...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => widget.onSearchChanged?.call(''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

          if (widget.enableSearch && widget.enableFiltering)
            const SizedBox(height: 12),

          // Sort and filter options
          if (widget.enableFiltering)
            Row(
              children: [
                // Sort dropdown
                Expanded(
                  child: DropdownButtonFormField<SortBy>(
                    initialValue: widget.sortBy,
                    onChanged: (sortBy) {
                      if (sortBy != null) {
                        widget.onSortChanged?.call(sortBy, widget.sortAscending);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: SortBy.values.map((sortBy) {
                      return DropdownMenuItem(
                        value: sortBy,
                        child: Text(_getSortByDisplayName(sortBy)),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(width: 8),

                // Sort direction
                IconButton(
                  onPressed: () {
                    widget.onSortChanged?.call(widget.sortBy, !widget.sortAscending);
                  },
                  icon: Icon(
                    widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),

                const SizedBox(width: 8),

                // Layout toggle
                PopupMenuButton<GridLayout>(
                  icon: const Icon(Icons.view_module),
                  onSelected: (layout) {
                    // This would typically be handled by parent widget
                  },
                  itemBuilder: (context) => GridLayout.values.map((layout) {
                    return PopupMenuItem(
                      value: layout,
                      child: Row(
                        children: [
                          Icon(_getLayoutIcon(layout)),
                          const SizedBox(width: 8),
                          Text(_getLayoutDisplayName(layout)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            widget.searchQuery.isNotEmpty
                ? 'No achievements found'
                : 'No achievements yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Start playing games to earn your first achievements!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(),
        childAspectRatio: _getChildAspectRatio(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _filteredAchievements[index];
        return _buildAchievementCard(achievement, index);
      },
    );
  }

  Widget _buildCategorizedGrid() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _groupedAchievements.length,
      itemBuilder: (context, index) {
        final category = _groupedAchievements.keys.elementAt(index);
        final achievements = _groupedAchievements[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryDisplayName(category),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${achievements.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(),
                childAspectRatio: _getChildAspectRatio(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, achievementIndex) {
                final achievement = achievements[achievementIndex];
                return _buildAchievementCard(achievement, achievementIndex);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, int index) {
    final userProgress = widget.userProgressMap[achievement.id];

    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index % 6) * 50),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, animation, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - animation)),
              child: Opacity(
                opacity: animation,
                child: AchievementCard(
                  achievement: achievement,
                  userProgress: userProgress,
                  mode: _getCardMode(),
                  onTap: widget.onAchievementTap != null
                      ? () => widget.onAchievementTap!(achievement)
                      : null,
                  onLongPress: widget.onAchievementLongPress != null
                      ? () => widget.onAchievementLongPress!(achievement)
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _loadingAnimation.value,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Loading more achievements...'),
            ],
          ),
        );
      },
    );
  }

  int _getCrossAxisCount() {
    switch (widget.layout) {
      case GridLayout.compact:
        return 3;
      case GridLayout.comfortable:
        return 2;
      case GridLayout.detailed:
        return 1;
    }
  }

  double _getChildAspectRatio() {
    switch (widget.layout) {
      case GridLayout.compact:
        return 0.8;
      case GridLayout.comfortable:
        return 1.0;
      case GridLayout.detailed:
        return 2.5;
    }
  }

  AchievementCardMode _getCardMode() {
    switch (widget.layout) {
      case GridLayout.compact:
      case GridLayout.comfortable:
        return AchievementCardMode.grid;
      case GridLayout.detailed:
        return AchievementCardMode.list;
    }
  }

  String _getSortByDisplayName(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.name:
        return 'Name';
      case SortBy.points:
        return 'Points';
      case SortBy.progress:
        return 'Progress';
      case SortBy.tier:
        return 'Tier';
      case SortBy.category:
        return 'Category';
      case SortBy.dateUnlocked:
        return 'Date Unlocked';
    }
  }

  String _getLayoutDisplayName(GridLayout layout) {
    switch (layout) {
      case GridLayout.compact:
        return 'Compact';
      case GridLayout.comfortable:
        return 'Comfortable';
      case GridLayout.detailed:
        return 'Detailed';
    }
  }

  IconData _getLayoutIcon(GridLayout layout) {
    switch (layout) {
      case GridLayout.compact:
        return Icons.grid_view;
      case GridLayout.comfortable:
        return Icons.view_module;
      case GridLayout.detailed:
        return Icons.view_list;
    }
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
        return Icons.trending_up;
      case AchievementCategory.milestone:
        return Icons.flag;
      case AchievementCategory.special:
        return Icons.star;
    }
  }

  String _getCategoryDisplayName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gaming:
        return 'Gaming';
      case AchievementCategory.gameParticipation:
        return 'Game Participation';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.profile:
        return 'Profile';
      case AchievementCategory.venue:
        return 'Venue';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.skillPerformance:
        return 'Skill Performance';
      case AchievementCategory.milestone:
        return 'Milestones';
      case AchievementCategory.special:
        return 'Special Events';
    }
  }
}