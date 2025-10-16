import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Filter configuration for leaderboards
class LeaderboardFilter {
  final String id;
  final String label;
  final String category;
  final FilterType type;
  final dynamic value;
  final bool isActive;
  final IconData? icon;

  const LeaderboardFilter({
    required this.id,
    required this.label,
    required this.category,
    required this.type,
    required this.value,
    this.isActive = false,
    this.icon,
  });

  LeaderboardFilter copyWith({
    String? id,
    String? label,
    String? category,
    FilterType? type,
    dynamic value,
    bool? isActive,
    IconData? icon,
  }) {
    return LeaderboardFilter(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      type: type ?? this.type,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
    );
  }
}

/// Saved filter set
class FilterSet {
  final String id;
  final String name;
  final List<LeaderboardFilter> filters;
  final bool isDefault;
  final DateTime createdAt;

  const FilterSet({
    required this.id,
    required this.name,
    required this.filters,
    this.isDefault = false,
    required this.createdAt,
  });

  int get activeFilterCount => filters.where((f) => f.isActive).length;
}

enum FilterType {
  timeRange,
  category,
  tier,
  country,
  friends,
  custom,
}

/// Filter tabs widget for leaderboards
class LeaderboardFilterTabs extends StatefulWidget {
  final List<LeaderboardFilter> availableFilters;
  final List<FilterSet> savedFilterSets;
  final Function(List<LeaderboardFilter>)? onFiltersChanged;
  final Function(FilterSet)? onFilterSetSelected;
  final Function(String, List<LeaderboardFilter>)? onFilterSetSaved;
  final Function(String)? onFilterSetDeleted;
  final VoidCallback? onResetFilters;
  final bool showSavedSets;
  final bool showQuickFilters;
  final bool enableHaptics;
  final EdgeInsets? padding;
  final double? height;

  const LeaderboardFilterTabs({
    super.key,
    required this.availableFilters,
    this.savedFilterSets = const [],
    this.onFiltersChanged,
    this.onFilterSetSelected,
    this.onFilterSetSaved,
    this.onFilterSetDeleted,
    this.onResetFilters,
    this.showSavedSets = true,
    this.showQuickFilters = true,
    this.enableHaptics = true,
    this.padding,
    this.height,
  });

  @override
  State<LeaderboardFilterTabs> createState() => _LeaderboardFilterTabsState();
}

class _LeaderboardFilterTabsState extends State<LeaderboardFilterTabs>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _badgeController;
  late Animation<double> _badgeAnimation;

  List<LeaderboardFilter> _currentFilters = [];
  String _selectedCategory = 'All';

  // Predefined filter categories
  final List<String> _categories = [
    'All',
    'Time Range',
    'Type',
    'Tier',
    'Location',
    'Social',
  ];

  // Quick filter presets
  final List<LeaderboardFilter> _quickFilters = const [
    LeaderboardFilter(
      id: 'today',
      label: 'Today',
      category: 'Time Range',
      type: FilterType.timeRange,
      value: 'today',
      icon: Icons.today,
    ),
    LeaderboardFilter(
      id: 'week',
      label: 'This Week',
      category: 'Time Range',
      type: FilterType.timeRange,
      value: 'week',
      icon: Icons.date_range,
    ),
    LeaderboardFilter(
      id: 'friends',
      label: 'Friends Only',
      category: 'Social',
      type: FilterType.friends,
      value: true,
      icon: Icons.people,
    ),
    LeaderboardFilter(
      id: 'country',
      label: 'My Country',
      category: 'Location',
      type: FilterType.country,
      value: 'current',
      icon: Icons.flag,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentFilters = List.from(widget.availableFilters);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _badgeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    
    if (activeFilterCount > 0) {
      _badgeController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  int get activeFilterCount => _currentFilters.where((f) => f.isActive).length;

  List<LeaderboardFilter> get filteredFilters {
    if (_selectedCategory == 'All') return _currentFilters;
    return _currentFilters.where((f) => f.category == _selectedCategory).toList();
  }

  void _handleFilterToggle(LeaderboardFilter filter) {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      final index = _currentFilters.indexWhere((f) => f.id == filter.id);
      if (index != -1) {
        _currentFilters[index] = filter.copyWith(isActive: !filter.isActive);
      }
    });

    widget.onFiltersChanged?.call(_currentFilters);

    // Animate badge when filter count changes
    if (activeFilterCount > 0) {
      _badgeController.forward();
    } else {
      _badgeController.reverse();
    }
  }

  void _handleQuickFilter(LeaderboardFilter quickFilter) {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    // Toggle or add the quick filter
    setState(() {
      final existingIndex = _currentFilters.indexWhere(
        (f) => f.id == quickFilter.id,
      );
      
      if (existingIndex != -1) {
        _currentFilters[existingIndex] = _currentFilters[existingIndex].copyWith(
          isActive: !_currentFilters[existingIndex].isActive,
        );
      } else {
        _currentFilters.add(quickFilter.copyWith(isActive: true));
      }
    });

    widget.onFiltersChanged?.call(_currentFilters);
    _badgeController.forward();
  }

  void _handleResetFilters() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _currentFilters = _currentFilters.map((f) => f.copyWith(isActive: false)).toList();
    });

    widget.onFiltersChanged?.call(_currentFilters);
    widget.onResetFilters?.call();
    _badgeController.reverse();
  }

  void _handleFilterSetSelected(FilterSet filterSet) {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _currentFilters = List.from(filterSet.filters);
    });

    widget.onFilterSetSelected?.call(filterSet);
    widget.onFiltersChanged?.call(_currentFilters);
    
    if (activeFilterCount > 0) {
      _badgeController.forward();
    }
  }

  void _showSaveFilterDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Filter Set'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Filter Set Name',
            hintText: 'e.g., "Weekly Friends"',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onFilterSetSaved?.call(controller.text, _currentFilters);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 120,
      padding: widget.padding ?? const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                _buildCategoryTabs(),
                const SizedBox(width: 12),
                Expanded(child: _buildFilterContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Filters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        if (activeFilterCount > 0)
          AnimatedBuilder(
            animation: _badgeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _badgeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeFilterCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        const Spacer(),
        if (activeFilterCount > 0)
          TextButton.icon(
            onPressed: _handleResetFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
            ),
          ),
        if (activeFilterCount > 0 && widget.onFilterSetSaved != null)
          IconButton(
            onPressed: _showSaveFilterDialog,
            icon: const Icon(Icons.bookmark_add),
            tooltip: 'Save Filter Set',
          ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      width: 100,
      child: Column(
        children: _categories.map((category) {
          final isSelected = category == _selectedCategory;
          final categoryFilters = category == 'All' 
              ? _currentFilters 
              : _currentFilters.where((f) => f.category == category).toList();
          final activeCount = categoryFilters.where((f) => f.isActive).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.blue[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[600] : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  if (widget.enableHaptics) {
                    HapticFeedback.selectionClick();
                  }
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showQuickFilters && _selectedCategory == 'All')
          _buildQuickFilters(),
        if (widget.showSavedSets &&
            widget.savedFilterSets.isNotEmpty &&
            _selectedCategory == 'All') ...[
          const SizedBox(height: 8),
          _buildSavedFilterSets(),
        ],
        const SizedBox(height: 8),
        Expanded(child: _buildFilterTabs()),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: _quickFilters.map((filter) {
            final isActive = _currentFilters
                .any((f) => f.id == filter.id && f.isActive);
            
            return FilterChip(
              avatar: filter.icon != null
                  ? Icon(
                      filter.icon,
                      size: 16,
                      color: isActive ? Colors.white : Colors.grey[600],
                    )
                  : null,
              label: Text(filter.label),
              selected: isActive,
              onSelected: (_) => _handleQuickFilter(filter),
              selectedColor: Colors.blue[600],
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSavedFilterSets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Sets',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.savedFilterSets.map((filterSet) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(
                    filterSet.isDefault ? Icons.star : Icons.bookmark,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filterSet.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${filterSet.activeFilterCount} filters',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onPressed: () => _handleFilterSetSelected(filterSet),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = filteredFilters;
    
    if (filters.isEmpty) {
      return Center(
        child: Text(
          'No filters available in this category',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: filters.map((filter) {
          return FilterChip(
            avatar: filter.icon != null
                ? Icon(
                    filter.icon,
                    size: 16,
                    color: filter.isActive ? Colors.white : Colors.grey[600],
                  )
                : null,
            label: Text(filter.label),
            selected: filter.isActive,
            onSelected: (_) => _handleFilterToggle(filter),
            selectedColor: Colors.blue[600],
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: filter.isActive ? Colors.white : Colors.grey[700],
              fontWeight: filter.isActive ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}