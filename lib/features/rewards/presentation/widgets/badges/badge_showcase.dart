import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/achievement.dart';
import 'badge_display.dart';
import 'badge_tier_indicator.dart';

enum ShowcaseLayout {
  grid,
  carousel,
  highlight,
  compact,
}

enum ShowcaseMode {
  visitor,
  owner,
  edit,
}

class BadgeShowcase extends StatefulWidget {
  final List<Achievement> featuredBadges;
  final Map<String, BadgeRarity> badgeRarities;
  final Map<String, DateTime> earnedDates;
  final ShowcaseLayout layout;
  final ShowcaseMode mode;
  final int maxBadges;
  final bool showRarityHighlights;
  final bool showEarnedDates;
  final bool enableDragReorder;
  final bool enableLayoutPreview;
  final bool enableSharing;
  final String? ownerName;
  final Function(List<Achievement>)? onBadgesReordered;
  final Function(ShowcaseLayout)? onLayoutChanged;
  final VoidCallback? onShare;
  final Function(Achievement)? onBadgeTap;
  final Function(Achievement)? onBadgeLongPress;

  const BadgeShowcase({
    super.key,
    required this.featuredBadges,
    this.badgeRarities = const {},
    this.earnedDates = const {},
    this.layout = ShowcaseLayout.grid,
    this.mode = ShowcaseMode.visitor,
    this.maxBadges = 6,
    this.showRarityHighlights = true,
    this.showEarnedDates = false,
    this.enableDragReorder = true,
    this.enableLayoutPreview = false,
    this.enableSharing = true,
    this.ownerName,
    this.onBadgesReordered,
    this.onLayoutChanged,
    this.onShare,
    this.onBadgeTap,
    this.onBadgeLongPress,
  });

  @override
  State<BadgeShowcase> createState() => _BadgeShowcaseState();
}

class _BadgeShowcaseState extends State<BadgeShowcase>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late AnimationController _carouselController;
  late AnimationController _editController;
  
  late Animation<double> _highlightAnimation;
  late Animation<double> _carouselAnimation;
  late Animation<double> _editAnimation;

  PageController? _pageController;
  int _currentPage = 0;
  bool _isInEditMode = false;
  List<Achievement> _reorderableBadges = [];

  @override
  void initState() {
    super.initState();
    _reorderableBadges = List.from(widget.featuredBadges);
    _initializeAnimations();
    _setupPageController();
  }

  void _initializeAnimations() {
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _carouselController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _editController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOutBack,
    ));

    _carouselAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _carouselController,
      curve: Curves.easeInOut,
    ));

    _editAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _editController,
      curve: Curves.easeInOut,
    ));

    _highlightController.forward();
  }

  void _setupPageController() {
    if (widget.layout == ShowcaseLayout.carousel) {
      _pageController = PageController(viewportFraction: 0.8);
      _carouselController.forward();
    }
  }

  @override
  void didUpdateWidget(BadgeShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.layout != widget.layout) {
      _setupPageController();
    }
    
    if (oldWidget.featuredBadges != widget.featuredBadges) {
      _reorderableBadges = List.from(widget.featuredBadges);
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _carouselController.dispose();
    _editController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        
        const SizedBox(height: 16),
        
        // Main showcase content
        _buildShowcaseContent(),
        
        // Layout preview controls
        if (widget.enableLayoutPreview && widget.mode == ShowcaseMode.owner)
          _buildLayoutPreview(),
        
        // Edit mode controls
        if (_isInEditMode && widget.mode == ShowcaseMode.owner)
          _buildEditControls(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mode == ShowcaseMode.visitor && widget.ownerName != null
                  ? '${widget.ownerName}\'s Badge Showcase'
                  : 'Featured Badges',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_reorderableBadges.isNotEmpty)
              Text(
                '${_reorderableBadges.length} featured badge${_reorderableBadges.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
        
        const Spacer(),
        
        // Action buttons
        if (widget.mode == ShowcaseMode.owner) ...[
          // Edit toggle
          IconButton(
            onPressed: _toggleEditMode,
            icon: AnimatedBuilder(
              animation: _editAnimation,
              builder: (context, child) {
                return Icon(
                  _isInEditMode ? Icons.done : Icons.edit,
                  color: _isInEditMode 
                      ? Colors.green 
                      : Theme.of(context).primaryColor,
                );
              },
            ),
            tooltip: _isInEditMode ? 'Finish editing' : 'Edit showcase',
          ),
          
          // Share button
          if (widget.enableSharing)
            IconButton(
              onPressed: widget.onShare,
              icon: const Icon(Icons.share),
              tooltip: 'Share showcase',
            ),
        ],
      ],
    );
  }

  Widget _buildShowcaseContent() {
    if (_reorderableBadges.isEmpty) {
      return _buildEmptyShowcase();
    }

    switch (widget.layout) {
      case ShowcaseLayout.grid:
        return _buildGridLayout();
      case ShowcaseLayout.carousel:
        return _buildCarouselLayout();
      case ShowcaseLayout.highlight:
        return _buildHighlightLayout();
      case ShowcaseLayout.compact:
        return _buildCompactLayout();
    }
  }

  Widget _buildEmptyShowcase() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              widget.mode == ShowcaseMode.visitor
                  ? 'No badges to showcase yet'
                  : 'Add badges to your showcase',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            if (widget.mode == ShowcaseMode.owner)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap edit to select your featured badges',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout() {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _reorderableBadges.length,
          itemBuilder: (context, index) {
            return _buildBadgeItem(_reorderableBadges[index], index);
          },
        );
      },
    );
  }

  Widget _buildCarouselLayout() {
    return AnimatedBuilder(
      animation: _carouselAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _reorderableBadges.length,
            itemBuilder: (context, index) {
              final scale = index == _currentPage ? 1.0 : 0.85;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform: Matrix4.identity()..scale(scale),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildBadgeItem(_reorderableBadges[index], index),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHighlightLayout() {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Featured badge (largest)
            if (_reorderableBadges.isNotEmpty)
              _buildFeaturedBadge(_reorderableBadges[0]),
            
            const SizedBox(height: 16),
            
            // Supporting badges (smaller)
            if (_reorderableBadges.length > 1)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _reorderableBadges.length - 1,
                  itemBuilder: (context, index) {
                    final badgeIndex = index + 1;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildBadgeItem(
                        _reorderableBadges[badgeIndex], 
                        badgeIndex,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCompactLayout() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: _reorderableBadges.asMap().entries.map((entry) {
          final index = entry.key;
          final badge = entry.value;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _reorderableBadges.length - 1 ? 8 : 0),
              child: _buildBadgeItem(badge, index, size: 50, showDetails: false),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedBadge(Achievement badge) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animation),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.badgeRarities[badge.id] != BadgeRarity.common
                      ? _getRarityColor(widget.badgeRarities[badge.id]!).withOpacity(0.1)
                      : Colors.grey[100]!,
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                BadgeDisplay(
                  achievement: badge,
                  rarity: widget.badgeRarities[badge.id] ?? BadgeRarity.common,
                  size: 120,
                  onTap: widget.onBadgeTap != null
                      ? () => widget.onBadgeTap!(badge)
                      : null,
                  onLongPress: widget.onBadgeLongPress != null
                      ? () => widget.onBadgeLongPress!(badge)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  badge.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.showEarnedDates && widget.earnedDates[badge.id] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Earned ${_formatDate(widget.earnedDates[badge.id]!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeItem(
    Achievement badge, 
    int index, {
    double size = 100,
    bool showDetails = true,
  }) {
    final rarity = widget.badgeRarities[badge.id] ?? BadgeRarity.common;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rarity highlight background
                if (widget.showRarityHighlights && rarity != BadgeRarity.common)
                  _buildRarityHighlight(rarity, size),

                // Main badge
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isInEditMode
                        ? _buildDraggableBadge(badge, index, size)
                        : BadgeDisplay(
                            achievement: badge,
                            rarity: rarity,
                            size: size,
                            onTap: widget.onBadgeTap != null
                                ? () => widget.onBadgeTap!(badge)
                                : null,
                            onLongPress: widget.onBadgeLongPress != null
                                ? () => widget.onBadgeLongPress!(badge)
                                : null,
                          ),
                    
                    if (showDetails) ...[
                      const SizedBox(height: 8),
                      
                      // Badge tier indicator
                      BadgeTierIndicator(
                        currentTier: badge.tier,
                        displayMode: TierDisplayMode.badge,
                        size: 20,
                        enableAnimations: false,
                      ),
                      
                      if (widget.showEarnedDates && widget.earnedDates[badge.id] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatDate(widget.earnedDates[badge.id]!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ],
                ),

                // Edit mode overlay
                if (_isInEditMode)
                  _buildEditOverlay(index),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRarityHighlight(BadgeRarity rarity, double size) {
    return Container(
      width: size + 20,
      height: size + 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _getRarityColor(rarity).withOpacity(0.3),
            _getRarityColor(rarity).withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableBadge(Achievement badge, int index, double size) {
    return Draggable<Achievement>(
      data: badge,
      feedback: BadgeDisplay(
        achievement: badge,
        rarity: widget.badgeRarities[badge.id] ?? BadgeRarity.common,
        size: size * 0.8,
        enableInteractions: false,
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: BadgeDisplay(
          achievement: badge,
          rarity: widget.badgeRarities[badge.id] ?? BadgeRarity.common,
          size: size,
          enableInteractions: false,
        ),
      ),
      child: DragTarget<Achievement>(
        onAcceptWithDetails: (details) {
          _reorderBadges(badge, details.data);
        },
        builder: (context, candidateData, rejectedData) {
          return BadgeDisplay(
            achievement: badge,
            rarity: widget.badgeRarities[badge.id] ?? BadgeRarity.common,
            size: size,
            onTap: widget.onBadgeTap != null
                ? () => widget.onBadgeTap!(badge)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEditOverlay(int index) {
    return Positioned(
      top: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => _removeBadge(index),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layout Options',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ShowcaseLayout.values.map((layout) {
                final isSelected = layout == widget.layout;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => widget.onLayoutChanged?.call(layout),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getLayoutIcon(layout),
                            size: 24,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLayoutDisplayName(layout),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditControls() {
    return AnimatedBuilder(
      animation: _editAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Drag badges to reorder • Tap ✕ to remove',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _resetShowcase,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[700],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isInEditMode = !_isInEditMode;
    });

    if (_isInEditMode) {
      _editController.forward();
    } else {
      _editController.reverse();
    }

    HapticFeedback.lightImpact();
  }

  void _reorderBadges(Achievement target, Achievement dragged) {
    final targetIndex = _reorderableBadges.indexOf(target);
    final draggedIndex = _reorderableBadges.indexOf(dragged);

    if (targetIndex != -1 && draggedIndex != -1) {
      setState(() {
        final draggedItem = _reorderableBadges.removeAt(draggedIndex);
        _reorderableBadges.insert(targetIndex, draggedItem);
      });

      HapticFeedback.lightImpact();
    }
  }

  void _removeBadge(int index) {
    if (index >= 0 && index < _reorderableBadges.length) {
      setState(() {
        _reorderableBadges.removeAt(index);
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _resetShowcase() {
    setState(() {
      _reorderableBadges = List.from(widget.featuredBadges);
    });
    HapticFeedback.lightImpact();
  }

  void _saveChanges() {
    widget.onBadgesReordered?.call(_reorderableBadges);
    _toggleEditMode();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showcase updated successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
      case BadgeRarity.mythic:
        return Colors.red;
    }
  }

  IconData _getLayoutIcon(ShowcaseLayout layout) {
    switch (layout) {
      case ShowcaseLayout.grid:
        return Icons.grid_view;
      case ShowcaseLayout.carousel:
        return Icons.view_carousel;
      case ShowcaseLayout.highlight:
        return Icons.star;
      case ShowcaseLayout.compact:
        return Icons.view_agenda;
    }
  }

  String _getLayoutDisplayName(ShowcaseLayout layout) {
    switch (layout) {
      case ShowcaseLayout.grid:
        return 'Grid';
      case ShowcaseLayout.carousel:
        return 'Carousel';
      case ShowcaseLayout.highlight:
        return 'Highlight';
      case ShowcaseLayout.compact:
        return 'Compact';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).ceil();
      return '$weeks week${weeks != 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).ceil();
      return '$months month${months != 1 ? 's' : ''} ago';
    }
  }
}