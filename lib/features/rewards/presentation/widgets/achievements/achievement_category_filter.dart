import 'package:flutter/material.dart';

import '../../../domain/entities/achievement.dart';

class AchievementCategoryFilter extends StatefulWidget {
  final List<AchievementCategory> categories;
  final AchievementCategory? selectedCategory;
  final Map<AchievementCategory, int>? categoryCounts;
  final Function(AchievementCategory?) onCategoryChanged;
  final bool showCounts;
  final bool enableMultiSelect;
  final bool showAllOption;
  final EdgeInsets padding;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final TextStyle? activeTextStyle;
  final TextStyle? inactiveTextStyle;

  const AchievementCategoryFilter({
    super.key,
    required this.categories,
    required this.onCategoryChanged,
    this.selectedCategory,
    this.categoryCounts,
    this.showCounts = true,
    this.enableMultiSelect = false,
    this.showAllOption = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 60,
    this.activeColor,
    this.inactiveColor,
    this.activeTextStyle,
    this.inactiveTextStyle,
  });

  @override
  State<AchievementCategoryFilter> createState() => _AchievementCategoryFilterState();
}

class _AchievementCategoryFilterState extends State<AchievementCategoryFilter>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  
  final Map<AchievementCategory, AnimationController> _chipAnimations = {};
  final Map<AchievementCategory, Animation<double>> _scaleAnimations = {};
  final Map<AchievementCategory, Animation<Color?>> _colorAnimations = {};

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scrollController = ScrollController();
    
    _initializeChipAnimations();
    _animationController.forward();
  }

  void _initializeChipAnimations() {
    for (final category in widget.categories) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      
      _chipAnimations[category] = controller;
      
      _scaleAnimations[category] = Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));

      _colorAnimations[category] = ColorTween(
        begin: widget.inactiveColor ?? Colors.grey[200],
        end: widget.activeColor ?? Theme.of(context).primaryColor,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }
  }

  @override
  void didUpdateWidget(AchievementCategoryFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    for (final entry in _chipAnimations.entries) {
      final category = entry.key;
      final controller = entry.value;
      
      if (category == widget.selectedCategory) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    
    for (final controller in _chipAnimations.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: widget.padding,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Row(
              children: [
                // "All" option
                if (widget.showAllOption)
                  _buildCategoryChip(
                    category: null,
                    label: 'All',
                    icon: Icons.apps,
                    isSelected: widget.selectedCategory == null,
                    count: widget.categoryCounts?.values.fold<int>(0, (a, b) => a + b),
                  ),

                if (widget.showAllOption)
                  const SizedBox(width: 8),

                // Category chips
                ...widget.categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < widget.categories.length - 1 ? 8 : 0,
                    ),
                    child: TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 200 + index * 50),
                      tween: Tween<double>(
                        begin: 0.0,
                        end: _animationController.value,
                      ),
                      builder: (context, animation, child) {
                        return Transform.translate(
                          offset: Offset(50 * (1 - animation), 0),
                          child: Opacity(
                            opacity: animation,
                            child: _buildCategoryChip(
                              category: category,
                              label: _getCategoryDisplayName(category),
                              icon: _getCategoryIcon(category),
                              isSelected: widget.selectedCategory == category,
                              count: widget.categoryCounts?[category],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required AchievementCategory? category,
    required String label,
    required IconData icon,
    required bool isSelected,
    int? count,
  }) {
    final theme = Theme.of(context);
    final activeColor = widget.activeColor ?? theme.primaryColor;
    final inactiveColor = widget.inactiveColor ?? Colors.grey[200]!;
    
    final activeTextColor = widget.activeTextStyle?.color ?? Colors.white;
    final inactiveTextColor = widget.inactiveTextStyle?.color ?? Colors.black87;

    return AnimatedBuilder(
      animation: category != null ? _chipAnimations[category]! : _animationController,
      builder: (context, child) {
        final scale = category != null 
            ? _scaleAnimations[category]!.value 
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => _onCategoryTap(category),
            onTapDown: (_) => _onChipPress(category, true),
            onTapUp: (_) => _onChipPress(category, false),
            onTapCancel: () => _onChipPress(category, false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? activeColor : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? activeTextColor : inactiveTextColor,
                    ),
                  ),
                  if (widget.showCounts && count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : activeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? activeTextColor 
                              : activeColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onCategoryTap(AchievementCategory? category) {
    widget.onCategoryChanged(category);
    
    // Scroll to center the selected chip
    if (category != null) {
      _scrollToCategory(category);
    }
  }

  void _onChipPress(AchievementCategory? category, bool isPressed) {
    if (category != null && _chipAnimations.containsKey(category)) {
      if (isPressed) {
        _chipAnimations[category]!.forward();
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && category != widget.selectedCategory) {
            _chipAnimations[category]!.reverse();
          }
        });
      }
    }
  }

  void _scrollToCategory(AchievementCategory category) {
    final index = widget.categories.indexOf(category);
    if (index == -1) return;

    // Estimate the position of the chip
    const chipWidth = 120.0; // Approximate width
    const spacing = 8.0;
    final offset = (chipWidth + spacing) * index;

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getCategoryDisplayName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gaming:
        return 'Gaming';
      case AchievementCategory.gameParticipation:
        return 'Games';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.profile:
        return 'Profile';
      case AchievementCategory.venue:
        return 'Venue';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.skillPerformance:
        return 'Skills';
      case AchievementCategory.milestone:
        return 'Milestones';
      case AchievementCategory.special:
        return 'Special';
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
}

// Extension to add count functionality
extension AchievementCategoryFilterExtension on List<Achievement> {
  Map<AchievementCategory, int> getCategoryCounts() {
    final Map<AchievementCategory, int> counts = {};
    
    for (final achievement in this) {
      counts[achievement.category] = (counts[achievement.category] ?? 0) + 1;
    }
    
    return counts;
  }
}