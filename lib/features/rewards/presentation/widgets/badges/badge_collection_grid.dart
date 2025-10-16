import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/badge_tier.dart';
import 'badge_display.dart';

enum GridLayoutType {
  traditional,
  hexagonal,
}

enum SortOption {
  name,
  tier,
  rarity,
  dateEarned,
  category,
  points,
}

class BadgeCollectionGrid extends StatefulWidget {
  final List<Achievement> achievements;
  final Map<String, BadgeRarity> badgeRarities;
  final GridLayoutType layoutType;
  final int crossAxisCount;
  final double badgeSize;
  final bool showEmptySlots;
  final bool showProgress;
  final bool enableSearch;
  final bool enableSorting;
  final bool enableTierGrouping;
  final bool enableExport;
  final int maxBadges;
  final String searchQuery;
  final SortOption sortBy;
  final bool sortAscending;
  final BadgeTier? selectedTier;
  final Function(String)? onSearchChanged;
  final Function(SortOption, bool)? onSortChanged;
  final Function(BadgeTier?)? onTierFilterChanged;
  final Function(Achievement)? onBadgeTap;
  final Function(Achievement)? onBadgeLongPress;
  final VoidCallback? onExportCollection;

  const BadgeCollectionGrid({
    super.key,
    required this.achievements,
    this.badgeRarities = const {},
    this.layoutType = GridLayoutType.traditional,
    this.crossAxisCount = 3,
    this.badgeSize = 100,
    this.showEmptySlots = true,
    this.showProgress = true,
    this.enableSearch = true,
    this.enableSorting = true,
    this.enableTierGrouping = false,
    this.enableExport = true,
    this.maxBadges = 50,
    this.searchQuery = '',
    this.sortBy = SortOption.name,
    this.sortAscending = true,
    this.selectedTier,
    this.onSearchChanged,
    this.onSortChanged,
    this.onTierFilterChanged,
    this.onBadgeTap,
    this.onBadgeLongPress,
    this.onExportCollection,
  });

  @override
  State<BadgeCollectionGrid> createState() => _BadgeCollectionGridState();
}

class _BadgeCollectionGridState extends State<BadgeCollectionGrid>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _loadingController;
  late Animation<double> _progressAnimation;
  late Animation<double> _loadingAnimation;

  List<Achievement> _filteredAchievements = [];
  final GlobalKey _gridKey = GlobalKey();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _filterAndSortBadges();
    _progressController.forward();
  }

  @override
  void didUpdateWidget(BadgeCollectionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.achievements != widget.achievements ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.sortBy != widget.sortBy ||
        oldWidget.sortAscending != widget.sortAscending ||
        oldWidget.selectedTier != widget.selectedTier) {
      _filterAndSortBadges();
    }
  }

  void _filterAndSortBadges() {
    List<Achievement> filtered = List.from(widget.achievements);

    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered.where((achievement) {
        final query = widget.searchQuery.toLowerCase();
        return achievement.name.toLowerCase().contains(query) ||
               achievement.description.toLowerCase().contains(query) ||
               achievement.category.toString().toLowerCase().contains(query);
      }).toList();
    }

    // Apply tier filter
    if (widget.selectedTier != null) {
      filtered = filtered.where((achievement) {
        return achievement.tier == widget.selectedTier;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (widget.sortBy) {
        case SortOption.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortOption.tier:
          comparison = a.tier.index.compareTo(b.tier.index);
          break;
        case SortOption.rarity:
          final rarityA = widget.badgeRarities[a.id]?.index ?? 0;
          final rarityB = widget.badgeRarities[b.id]?.index ?? 0;
          comparison = rarityA.compareTo(rarityB);
          break;
        case SortOption.dateEarned:
          // This would typically come from UserProgress
          comparison = a.id.compareTo(b.id); // Placeholder
          break;
        case SortOption.category:
          comparison = a.category.index.compareTo(b.category.index);
          break;
        case SortOption.points:
          comparison = a.points.compareTo(b.points);
          break;
      }

      return widget.sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredAchievements = filtered;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with progress and controls
        if (widget.showProgress || widget.enableSearch || widget.enableSorting)
          _buildHeader(),

        // Main grid content
        Expanded(
          child: widget.enableTierGrouping
              ? _buildTierGroupedGrid()
              : _buildRegularGrid(),
        ),

        // Export button
        if (widget.enableExport && !_isExporting)
          _buildExportButton(),

        if (_isExporting)
          _buildExportProgress(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Collection progress
          if (widget.showProgress)
            _buildCollectionProgress(),

          if (widget.showProgress && 
              (widget.enableSearch || widget.enableSorting))
            const SizedBox(height: 16),

          // Search and sort controls
          if (widget.enableSearch || widget.enableSorting)
            _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCollectionProgress() {
    final totalBadges = widget.maxBadges;
    final earnedBadges = widget.achievements.length;
    final progress = earnedBadges / totalBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Badge Collection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$earnedBadges/$totalBadges',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (progress * _progressAnimation.value).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[400]!,
                        Colors.blue[600]!,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% Complete',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        // Search
        if (widget.enableSearch)
          Expanded(
            child: TextField(
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search badges...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => widget.onSearchChanged?.call(''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

        if (widget.enableSearch && widget.enableSorting)
          const SizedBox(width: 8),

        // Sort and layout controls
        if (widget.enableSorting)
          Row(
            children: [
              // Sort dropdown
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort),
                onSelected: (sortBy) {
                  widget.onSortChanged?.call(sortBy, widget.sortAscending);
                },
                itemBuilder: (context) => SortOption.values.map((sort) {
                  return PopupMenuItem(
                    value: sort,
                    child: Row(
                      children: [
                        Icon(_getSortIcon(sort), size: 18),
                        const SizedBox(width: 8),
                        Text(_getSortDisplayName(sort)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Sort direction
              IconButton(
                onPressed: () {
                  widget.onSortChanged?.call(widget.sortBy, !widget.sortAscending);
                },
                icon: Icon(
                  widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRegularGrid() {
    return RepaintBoundary(
      key: _gridKey,
      child: widget.layoutType == GridLayoutType.hexagonal
          ? _buildHexagonalGrid()
          : _buildTraditionalGrid(),
    );
  }

  Widget _buildTraditionalGrid() {
    final totalSlots = widget.showEmptySlots ? widget.maxBadges : _filteredAchievements.length;
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < _filteredAchievements.length) {
          return _buildBadgeItem(_filteredAchievements[index], index);
        } else {
          return _buildEmptySlot(index);
        }
      },
    );
  }

  Widget _buildHexagonalGrid() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: HexagonalGridDelegate(
              crossAxisCount: widget.crossAxisCount,
              badgeSize: widget.badgeSize,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final totalSlots = widget.showEmptySlots 
                    ? widget.maxBadges 
                    : _filteredAchievements.length;

                if (index < _filteredAchievements.length) {
                  return _buildBadgeItem(_filteredAchievements[index], index);
                } else if (index < totalSlots) {
                  return _buildEmptySlot(index);
                } else {
                  return null;
                }
              },
              childCount: widget.showEmptySlots 
                  ? widget.maxBadges 
                  : _filteredAchievements.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierGroupedGrid() {
    final groupedBadges = _groupBadgesByTier();
    
    return ListView.builder(
      itemCount: groupedBadges.length,
      itemBuilder: (context, index) {
        final tier = groupedBadges.keys.elementAt(index);
        final badges = groupedBadges[tier]!;
        
        return _buildTierSection(tier, badges);
      },
    );
  }

  Widget _buildTierSection(BadgeTier tier, List<Achievement> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${badges.first.getTierColorHex().substring(1)}')),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tier.toString().split('.').last.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${badges.first.getTierColorHex().substring(1)}')).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${badges.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(int.parse('0xFF${badges.first.getTierColorHex().substring(1)}')),
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            return _buildBadgeItem(badges[index], index);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBadgeItem(Achievement achievement, int index) {
    final rarity = widget.badgeRarities[achievement.id] ?? BadgeRarity.common;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index % 9) * 50),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: BadgeDisplay(
              achievement: achievement,
              rarity: rarity,
              size: widget.badgeSize,
              onTap: widget.onBadgeTap != null
                  ? () => widget.onBadgeTap!(achievement)
                  : null,
              onLongPress: widget.onBadgeLongPress != null
                  ? () => widget.onBadgeLongPress!(achievement)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySlot(int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index % 9) * 50),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation)),
          child: Opacity(
            opacity: animation * 0.3,
            child: Container(
              width: widget.badgeSize,
              height: widget.badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                color: Colors.grey[50],
              ),
              child: Icon(
                Icons.add,
                size: widget.badgeSize * 0.3,
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _exportCollection,
        icon: const Icon(Icons.download),
        label: const Text('Export Collection'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildExportProgress() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, child) {
          return Column(
            children: [
              CircularProgressIndicator(
                value: _loadingAnimation.value,
                strokeWidth: 3,
              ),
              const SizedBox(height: 8),
              Text(
                'Exporting collection...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<BadgeTier, List<Achievement>> _groupBadgesByTier() {
    final Map<BadgeTier, List<Achievement>> grouped = {};
    
    for (final achievement in _filteredAchievements) {
      if (!grouped.containsKey(achievement.tier)) {
        grouped[achievement.tier] = [];
      }
      grouped[achievement.tier]!.add(achievement);
    }

    // Sort tiers by index
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    
    final Map<BadgeTier, List<Achievement>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  void _exportCollection() async {
    setState(() {
      _isExporting = true;
    });

    _loadingController.reset();
    _loadingController.forward();

    try {
      // Capture the grid as an image
      final RenderRepaintBoundary boundary = 
          _gridKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // In a real app, you would save or share the image here
        HapticFeedback.mediumImpact();
        widget.onExportCollection?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collection exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        _loadingController.reset();
      }
    }
  }

  String _getSortDisplayName(SortOption sort) {
    switch (sort) {
      case SortOption.name:
        return 'Name';
      case SortOption.tier:
        return 'Tier';
      case SortOption.rarity:
        return 'Rarity';
      case SortOption.dateEarned:
        return 'Date Earned';
      case SortOption.category:
        return 'Category';
      case SortOption.points:
        return 'Points';
    }
  }

  IconData _getSortIcon(SortOption sort) {
    switch (sort) {
      case SortOption.name:
        return Icons.sort_by_alpha;
      case SortOption.tier:
        return Icons.military_tech;
      case SortOption.rarity:
        return Icons.diamond;
      case SortOption.dateEarned:
        return Icons.schedule;
      case SortOption.category:
        return Icons.category;
      case SortOption.points:
        return Icons.star;
    }
  }
}

class HexagonalGridDelegate extends SliverGridDelegate {
  final int crossAxisCount;
  final double badgeSize;

  HexagonalGridDelegate({
    required this.crossAxisCount,
    required this.badgeSize,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double crossAxisSpacing = 8;
    final double mainAxisSpacing = 4;
    
    final double usableWidth = constraints.crossAxisExtent - 
        (crossAxisCount - 1) * crossAxisSpacing;
    final double childWidth = usableWidth / crossAxisCount;
    final double childHeight = badgeSize + mainAxisSpacing;

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childHeight,
      crossAxisStride: childWidth + crossAxisSpacing,
      childMainAxisExtent: badgeSize,
      childCrossAxisExtent: childWidth,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(HexagonalGridDelegate oldDelegate) {
    return crossAxisCount != oldDelegate.crossAxisCount ||
           badgeSize != oldDelegate.badgeSize;
  }
}