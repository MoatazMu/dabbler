import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/badge_tier.dart';

/// Data class for tier benefits
class TierBenefit {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final bool isNew;
  final DateTime? unlockedAt;
  final String? privilegeDetails;
  final TierBenefitCategory category;

  const TierBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.isNew = false,
    this.unlockedAt,
    this.privilegeDetails,
    this.category = TierBenefitCategory.general,
  });

  TierBenefit copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    bool? isUnlocked,
    bool? isNew,
    DateTime? unlockedAt,
    String? privilegeDetails,
    TierBenefitCategory? category,
  }) {
    return TierBenefit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isNew: isNew ?? this.isNew,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      privilegeDetails: privilegeDetails ?? this.privilegeDetails,
      category: category ?? this.category,
    );
  }
}

enum TierBenefitCategory {
  general,
  social,
  gameplay,
  rewards,
  privileges,
  exclusive,
}

/// Data class for tier benefits configuration
class TierBenefitsData {
  final BadgeTier tier;
  final List<TierBenefit> benefits;
  final int totalBenefits;
  final int unlockedBenefits;
  final BadgeTier? previousTier;
  final BadgeTier? nextTier;
  final List<TierBenefit> newBenefits;
  final List<TierBenefit> comingSoonBenefits;
  final DateTime? tierUnlockedAt;
  final String tierDescription;

  const TierBenefitsData({
    required this.tier,
    required this.benefits,
    required this.totalBenefits,
    required this.unlockedBenefits,
    this.previousTier,
    this.nextTier,
    this.newBenefits = const [],
    this.comingSoonBenefits = const [],
    this.tierUnlockedAt,
    this.tierDescription = '',
  });

  double get progressPercentage => 
      totalBenefits > 0 ? (unlockedBenefits / totalBenefits) : 0.0;

  List<TierBenefit> getBenefitsByCategory(TierBenefitCategory category) {
    return benefits.where((benefit) => benefit.category == category).toList();
  }

  List<TierBenefitCategory> get availableCategories {
    return benefits.map((b) => b.category).toSet().toList()
        ..sort((a, b) => a.index.compareTo(b.index));
  }
}

/// Interactive tier benefits card widget
class TierBenefitsCard extends StatefulWidget {
  final TierBenefitsData data;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  final VoidCallback? onShare;
  final Function(TierBenefit)? onBenefitTap;
  final Function(TierBenefit)? onBenefitLongPress;
  final bool showComparison;
  final bool showNewBadges;
  final bool enableHaptics;
  final EdgeInsets? padding;
  final double? elevation;

  const TierBenefitsCard({
    super.key,
    required this.data,
    this.isExpanded = false,
    this.onTap,
    this.onExpandToggle,
    this.onShare,
    this.onBenefitTap,
    this.onBenefitLongPress,
    this.showComparison = true,
    this.showNewBadges = true,
    this.enableHaptics = true,
    this.padding,
    this.elevation,
  });

  @override
  State<TierBenefitsCard> createState() => _TierBenefitsCardState();
}

class _TierBenefitsCardState extends State<TierBenefitsCard>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _badgeController;

  late Animation<double> _expandAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _badgeAnimation;

  bool _isExpanded = false;
  TierBenefitCategory _selectedCategory = TierBenefitCategory.general;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    
    if (widget.data.availableCategories.isNotEmpty) {
      _selectedCategory = widget.data.availableCategories.first;
    }

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _badgeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    if (_isExpanded) {
      _expandController.forward();
    }

    _pulseController.repeat(reverse: true);
    _shimmerController.repeat(reverse: true);
    _badgeController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Color _getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  IconData _getTierIcon(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return Icons.looks_3;
      case BadgeTier.silver:
        return Icons.looks_4;
      case BadgeTier.gold:
        return Icons.looks_5;
      case BadgeTier.platinum:
        return Icons.diamond;
      case BadgeTier.diamond:
        return Icons.auto_awesome;
    }
  }

  String _getTierName(BadgeTier tier) {
    return tier.toString().split('.').last.toUpperCase();
  }

  String _getCategoryName(TierBenefitCategory category) {
    switch (category) {
      case TierBenefitCategory.general:
        return 'General';
      case TierBenefitCategory.social:
        return 'Social';
      case TierBenefitCategory.gameplay:
        return 'Gameplay';
      case TierBenefitCategory.rewards:
        return 'Rewards';
      case TierBenefitCategory.privileges:
        return 'Privileges';
      case TierBenefitCategory.exclusive:
        return 'Exclusive';
    }
  }

  IconData _getCategoryIcon(TierBenefitCategory category) {
    switch (category) {
      case TierBenefitCategory.general:
        return Icons.category;
      case TierBenefitCategory.social:
        return Icons.people;
      case TierBenefitCategory.gameplay:
        return Icons.games;
      case TierBenefitCategory.rewards:
        return Icons.card_giftcard;
      case TierBenefitCategory.privileges:
        return Icons.verified;
      case TierBenefitCategory.exclusive:
        return Icons.star;
    }
  }

  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    widget.onExpandToggle?.call();
    widget.onTap?.call();
  }

  void _handleBenefitTap(TierBenefit benefit) {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    widget.onBenefitTap?.call(benefit);
  }

  void _handleBenefitLongPress(TierBenefit benefit) {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    widget.onBenefitLongPress?.call(benefit);
    _showBenefitDetails(benefit);
  }

  void _showBenefitDetails(TierBenefit benefit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(benefit.icon, color: _getTierColor(widget.data.tier)),
            const SizedBox(width: 8),
            Expanded(child: Text(benefit.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(benefit.description),
            if (benefit.privilegeDetails != null) ...[
              const SizedBox(height: 16),
              Text(
                'Privilege Details',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(benefit.privilegeDetails!),
            ],
            if (benefit.unlockedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Unlocked: ${benefit.unlockedAt!.day}/${benefit.unlockedAt!.month}/${benefit.unlockedAt!.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleShare() {
    final tierName = _getTierName(widget.data.tier);
    final benefitsCount = widget.data.unlockedBenefits;
    final totalBenefits = widget.data.totalBenefits;
    
    final message = 'I just reached $tierName tier! 🎉\n'
        'Unlocked $benefitsCount/$totalBenefits exclusive benefits.\n'
        'Join me in the game and level up your tier too!';

    Share.share(message, subject: 'Tier Achievement Unlocked!');
    
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }
    
    widget.onShare?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(widget.data.tier);

    return Container(
      margin: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: widget.elevation ?? 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: tierColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _buildHeader(),
                    AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: _expandAnimation.value,
                            child: _buildExpandedContent(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(widget.data.tier);
    final tierName = _getTierName(widget.data.tier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [
            tierColor.withOpacity(0.1),
            tierColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTierIcon(widget.data.tier),
              color: tierColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$tierName BENEFITS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.data.newBenefits.isNotEmpty && widget.showNewBadges)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: AnimatedBuilder(
                          animation: _badgeAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _badgeAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'NEW',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.tierDescription.isEmpty
                      ? 'Exclusive benefits and privileges for $tierName members'
                      : widget.data.tierDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: widget.data.progressPercentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.data.unlockedBenefits}/${widget.data.totalBenefits}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onShare != null)
                IconButton(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Achievement',
                ),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: tierColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    if (!_isExpanded) return const SizedBox.shrink();

    return Column(
      children: [
        _buildCategoryTabs(),
        _buildBenefitsList(),
        if (widget.showComparison && widget.data.previousTier != null)
          _buildComparisonSection(),
        if (widget.data.comingSoonBenefits.isNotEmpty)
          _buildComingSoonSection(),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final tierColor = _getTierColor(widget.data.tier);
    final categories = widget.data.availableCategories;

    if (categories.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 16,
                    color: isSelected ? Colors.white : tierColor,
                  ),
                  const SizedBox(width: 4),
                  Text(_getCategoryName(category)),
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
              selectedColor: tierColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : tierColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = widget.data.getBenefitsByCategory(_selectedCategory);
    if (benefits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No benefits in this category yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: benefits.map((benefit) => _buildBenefitItem(benefit)).toList(),
      ),
    );
  }

  Widget _buildBenefitItem(TierBenefit benefit) {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(widget.data.tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: benefit.isUnlocked 
            ? tierColor.withOpacity(0.05)
            : Colors.grey[50],
      ),
      child: ListTile(
        onTap: () => _handleBenefitTap(benefit),
        onLongPress: () => _handleBenefitLongPress(benefit),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: benefit.isUnlocked
                ? tierColor.withOpacity(0.2)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            benefit.icon,
            color: benefit.isUnlocked ? tierColor : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                benefit.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: benefit.isUnlocked 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  color: benefit.isUnlocked 
                      ? theme.colorScheme.onSurface
                      : Colors.grey[600],
                ),
              ),
            ),
            if (benefit.isNew && widget.showNewBadges)
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(
                        0.8 + 0.2 * _shimmerAnimation.value,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NEW',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        subtitle: benefit.description.isNotEmpty
            ? Text(
                benefit.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: benefit.isUnlocked 
                      ? Colors.grey[700]
                      : Colors.grey[500],
                ),
              )
            : null,
        trailing: benefit.isUnlocked
            ? Icon(Icons.check_circle, color: tierColor, size: 20)
            : Icon(Icons.lock, color: Colors.grey[400], size: 20),
      ),
    );
  }

  Widget _buildComparisonSection() {
    if (widget.data.previousTier == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final currentColor = _getTierColor(widget.data.tier);
    final previousColor = _getTierColor(widget.data.previousTier!);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upgrade from ${_getTierName(widget.data.previousTier!)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: previousColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTierIcon(widget.data.previousTier!),
                        color: previousColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTierName(widget.data.previousTier!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTierIcon(widget.data.tier),
                        color: currentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTierName(widget.data.tier),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'New Benefits Unlocked: ${widget.data.newBenefits.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: currentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonSection() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Coming Soon',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.data.comingSoonBenefits.take(3).map((benefit) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    benefit.icon,
                    color: Colors.blue[400],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.data.comingSoonBenefits.length > 3)
            Text(
              '+${widget.data.comingSoonBenefits.length - 3} more benefits',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}