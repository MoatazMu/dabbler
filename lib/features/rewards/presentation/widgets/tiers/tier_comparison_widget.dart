import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/badge_tier.dart';

/// Data class for tier comparison
class TierComparisonData {
  final BadgeTier currentTier;
  final BadgeTier comparedTier;
  final List<ComparisonBenefit> benefits;
  final int currentPoints;
  final int comparedMinPoints;
  final int comparedMaxPoints;
  final String currentTierDescription;
  final String comparedTierDescription;
  final DateTime? currentTierUnlockedAt;
  final Duration? upgradeTimeEstimate;
  final List<String> upgradeRequirements;

  const TierComparisonData({
    required this.currentTier,
    required this.comparedTier,
    required this.benefits,
    required this.currentPoints,
    required this.comparedMinPoints,
    required this.comparedMaxPoints,
    this.currentTierDescription = '',
    this.comparedTierDescription = '',
    this.currentTierUnlockedAt,
    this.upgradeTimeEstimate,
    this.upgradeRequirements = const [],
  });

  bool get isUpgrade => comparedTier.index > currentTier.index;
  bool get isDowngrade => comparedTier.index < currentTier.index;
  bool get isSameTier => comparedTier == currentTier;
  
  int get pointsToUpgrade => comparedMinPoints - currentPoints;
  double get upgradeProgress => 
      currentPoints >= comparedMinPoints ? 1.0 : currentPoints / comparedMinPoints;

  List<ComparisonBenefit> get uniqueBenefits => 
      benefits.where((b) => b.availability == BenefitAvailability.comparedOnly).toList();

  List<ComparisonBenefit> get sharedBenefits => 
      benefits.where((b) => b.availability == BenefitAvailability.both).toList();

  List<ComparisonBenefit> get lostBenefits => 
      benefits.where((b) => b.availability == BenefitAvailability.currentOnly).toList();
}

/// Individual benefit comparison data
class ComparisonBenefit {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final BenefitAvailability availability;
  final BenefitImportance importance;
  final String? currentValue;
  final String? comparedValue;
  final bool isImproved;
  final ComparisonCategory category;

  const ComparisonBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.availability,
    this.importance = BenefitImportance.normal,
    this.currentValue,
    this.comparedValue,
    this.isImproved = false,
    this.category = ComparisonCategory.general,
  });
}

enum BenefitAvailability {
  currentOnly,
  comparedOnly,
  both,
}

enum BenefitImportance {
  low,
  normal,
  high,
  critical,
}

enum ComparisonCategory {
  general,
  social,
  gameplay,
  rewards,
  privileges,
  exclusive,
}

/// Interactive tier comparison widget with animations
class TierComparisonWidget extends StatefulWidget {
  final List<TierComparisonData> comparisons;
  final int initialIndex;
  final Function(BadgeTier tierId)? onTierSelected;
  final Function(dynamic)? onBenefitTap;
  final VoidCallback? onUpgrade;
  final bool enableAnimations;
  final bool enableSwipe;
  final bool enableHaptics;
  final bool showUpgradeButton;
  final bool showDifferences;
  final EdgeInsets? padding;
  final double? spacing;

  const TierComparisonWidget({
    super.key,
    required this.comparisons,
    this.initialIndex = 0,
    this.onTierSelected,
    this.onBenefitTap,
    this.onUpgrade,
    this.enableAnimations = true,
    this.enableSwipe = true,
    this.enableHaptics = true,
    this.showUpgradeButton = true,
    this.showDifferences = true,
    this.padding,
    this.spacing,
  });

  @override
  State<TierComparisonWidget> createState() => _TierComparisonWidgetState();
}

class _TierComparisonWidgetState extends State<TierComparisonWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _slideController;
  late AnimationController _highlightController;
  late AnimationController _pulseController;

  late Animation<double> _highlightAnimation;
  late Animation<double> _pulseAnimation;

  int _currentIndex = 0;
  ComparisonCategory _selectedCategory = ComparisonCategory.general;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.comparisons.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideController.forward();
    _highlightController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _highlightController.dispose();
    _pulseController.dispose();
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

  Color _getBenefitColor(BenefitAvailability availability, BadgeTier currentTier, BadgeTier comparedTier) {
    switch (availability) {
      case BenefitAvailability.currentOnly:
        return Colors.red[400]!;
      case BenefitAvailability.comparedOnly:
        return _getTierColor(comparedTier);
      case BenefitAvailability.both:
        return Colors.grey[600]!;
    }
  }

  IconData _getBenefitIcon(BenefitAvailability availability) {
    switch (availability) {
      case BenefitAvailability.currentOnly:
        return Icons.remove_circle_outline;
      case BenefitAvailability.comparedOnly:
        return Icons.add_circle_outline;
      case BenefitAvailability.both:
        return Icons.check_circle_outline;
    }
  }

  String _getCategoryName(ComparisonCategory category) {
    switch (category) {
      case ComparisonCategory.general:
        return 'General';
      case ComparisonCategory.social:
        return 'Social';
      case ComparisonCategory.gameplay:
        return 'Gameplay';
      case ComparisonCategory.rewards:
        return 'Rewards';
      case ComparisonCategory.privileges:
        return 'Privileges';
      case ComparisonCategory.exclusive:
        return 'Exclusive';
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }

    if (widget.comparisons.isNotEmpty && index < widget.comparisons.length) {
      widget.onTierSelected?.call(widget.comparisons[index].comparedTier);
    }

    // Restart highlight animation for new comparison
    _highlightController.reset();
    _highlightController.repeat(reverse: true);
  }

  void _handleBenefitTap(ComparisonBenefit benefit) {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onBenefitTap?.call(benefit);
  }

  void _handleUpgrade() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    widget.onUpgrade?.call();
  }

  List<ComparisonBenefit> _getFilteredBenefits() {
    if (widget.comparisons.isEmpty || _currentIndex >= widget.comparisons.length) {
      return [];
    }

    final comparison = widget.comparisons[_currentIndex];
    return comparison.benefits
        .where((benefit) => benefit.category == _selectedCategory)
        .toList();
  }

  List<ComparisonCategory> _getAvailableCategories() {
    if (widget.comparisons.isEmpty || _currentIndex >= widget.comparisons.length) {
      return [ComparisonCategory.general];
    }

    final comparison = widget.comparisons[_currentIndex];
    return comparison.benefits
        .map((b) => b.category)
        .toSet()
        .toList()
        ..sort((a, b) => a.index.compareTo(b.index));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comparisons.isEmpty) {
      return const Center(
        child: Text('No tier comparisons available'),
      );
    }

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: widget.enableSwipe ? _onPageChanged : null,
              physics: widget.enableSwipe 
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: widget.comparisons.length,
              itemBuilder: (context, index) {
                return _buildComparisonPage(widget.comparisons[index]);
              },
            ),
          ),
          if (widget.comparisons.length > 1) _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final comparison = widget.comparisons[_currentIndex];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTierInfo(
                  tier: comparison.currentTier,
                  title: 'Current Tier',
                  isActive: true,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: comparison.isUpgrade 
                        ? Colors.green[100]
                        : comparison.isDowngrade
                        ? Colors.red[100]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    comparison.isUpgrade 
                        ? Icons.arrow_upward
                        : comparison.isDowngrade
                        ? Icons.arrow_downward
                        : Icons.compare_arrows,
                    color: comparison.isUpgrade 
                        ? Colors.green[600]
                        : comparison.isDowngrade
                        ? Colors.red[600]
                        : Colors.grey[600],
                  ),
                ),
                _buildTierInfo(
                  tier: comparison.comparedTier,
                  title: 'Compare With',
                  isActive: false,
                ),
              ],
            ),
            if (comparison.isUpgrade) ...[
              const SizedBox(height: 16),
              _buildUpgradeProgress(comparison),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTierInfo({
    required BadgeTier tier,
    required String title,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(tier);
    final tierName = _getTierName(tier);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tierColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: isActive 
                ? Border.all(color: tierColor, width: 2)
                : Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Icon(
            _getTierIcon(tier),
            color: tierColor,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tierName,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isActive ? tierColor : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeProgress(TierComparisonData comparison) {
    final theme = Theme.of(context);
    final comparedColor = _getTierColor(comparison.comparedTier);

    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: comparedColor, size: 16),
            const SizedBox(width: 8),
            Text(
              'Upgrade Progress',
              style: theme.textTheme.titleSmall?.copyWith(
                color: comparedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: comparison.upgradeProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(comparedColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(comparison.upgradeProgress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: comparedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Points: ${comparison.currentPoints}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Need: ${comparison.pointsToUpgrade > 0 ? comparison.pointsToUpgrade : 0}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: comparedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonPage(TierComparisonData comparison) {
    return Column(
      children: [
        _buildCategoryTabs(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildBenefitComparison(comparison),
        ),
        if (widget.showUpgradeButton && comparison.isUpgrade)
          _buildUpgradeButton(comparison),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final categories = _getAvailableCategories();
    if (categories.length <= 1) return const SizedBox.shrink();

    final comparison = widget.comparisons[_currentIndex];
    final comparedColor = _getTierColor(comparison.comparedTier);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getCategoryName(category)),
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
              selectedColor: comparedColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : comparedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitComparison(TierComparisonData comparison) {
    final benefits = _getFilteredBenefits();
    
    if (benefits.isEmpty) {
      return const Center(
        child: Text('No benefits in this category'),
      );
    }

    return ListView.builder(
      itemCount: benefits.length,
      itemBuilder: (context, index) {
        return _buildBenefitItem(benefits[index], comparison);
      },
    );
  }

  Widget _buildBenefitItem(ComparisonBenefit benefit, TierComparisonData comparison) {
    final theme = Theme.of(context);
    final benefitColor = _getBenefitColor(
      benefit.availability,
      comparison.currentTier,
      comparison.comparedTier,
    );
    final benefitIcon = _getBenefitIcon(benefit.availability);

    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: benefit.availability == BenefitAvailability.comparedOnly
                ? benefitColor.withOpacity(0.05 + 0.05 * _highlightAnimation.value)
                : Colors.grey[50],
            border: benefit.availability == BenefitAvailability.comparedOnly
                ? Border.all(
                    color: benefitColor.withOpacity(0.3 + 0.2 * _highlightAnimation.value),
                    width: 1,
                  )
                : null,
          ),
          child: ListTile(
            onTap: () => _handleBenefitTap(benefit),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  benefitIcon,
                  color: benefitColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(
                  benefit.icon,
                  color: benefitColor,
                  size: 20,
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    benefit.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: benefit.availability == BenefitAvailability.comparedOnly
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: benefit.availability == BenefitAvailability.currentOnly
                          ? Colors.grey[500]
                          : theme.colorScheme.onSurface,
                      decoration: benefit.availability == BenefitAvailability.currentOnly
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (benefit.importance == BenefitImportance.high ||
                    benefit.importance == BenefitImportance.critical)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: benefit.importance == BenefitImportance.critical
                          ? Colors.red[600]
                          : Colors.orange[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      benefit.importance == BenefitImportance.critical ? 'CRITICAL' : 'HIGH',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (benefit.description.isNotEmpty)
                  Text(
                    benefit.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: benefit.availability == BenefitAvailability.currentOnly
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                if (widget.showDifferences && 
                    (benefit.currentValue != null || benefit.comparedValue != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildValueComparison(benefit),
                  ),
              ],
            ),
            trailing: _buildAvailabilityBadge(benefit.availability),
          ),
        );
      },
    );
  }

  Widget _buildValueComparison(ComparisonBenefit benefit) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (benefit.currentValue != null) ...[
          Text(
            benefit.currentValue!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              decoration: benefit.availability == BenefitAvailability.currentOnly
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ],
        if (benefit.currentValue != null && benefit.comparedValue != null) ...[
          const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
        ],
        if (benefit.comparedValue != null) ...[
          Text(
            benefit.comparedValue!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: benefit.isImproved ? Colors.green[600] : Colors.grey[600],
              fontWeight: benefit.isImproved ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (benefit.isImproved)
            Icon(Icons.trending_up, size: 14, color: Colors.green[600]),
        ],
      ],
    );
  }

  Widget _buildAvailabilityBadge(BenefitAvailability availability) {
    switch (availability) {
      case BenefitAvailability.currentOnly:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'LOST',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case BenefitAvailability.comparedOnly:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'NEW',
            style: TextStyle(
              color: Colors.green[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case BenefitAvailability.both:
        return const Icon(
          Icons.check_circle,
          color: Colors.grey,
          size: 16,
        );
    }
  }

  Widget _buildUpgradeButton(TierComparisonData comparison) {
    final comparedColor = _getTierColor(comparison.comparedTier);
    final canUpgrade = comparison.pointsToUpgrade <= 0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Transform.scale(
            scale: canUpgrade ? _pulseAnimation.value : 1.0,
            child: ElevatedButton.icon(
              onPressed: canUpgrade ? _handleUpgrade : null,
              icon: Icon(
                canUpgrade ? Icons.upgrade : Icons.lock,
                color: Colors.white,
              ),
              label: Text(
                canUpgrade 
                    ? 'UPGRADE TO ${_getTierName(comparison.comparedTier)}'
                    : 'NEED ${comparison.pointsToUpgrade} POINTS',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canUpgrade ? comparedColor : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: canUpgrade ? 8 : 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.comparisons.length, (index) {
          final isActive = index == _currentIndex;
          final comparison = widget.comparisons[index];
          final tierColor = _getTierColor(comparison.comparedTier);

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isActive ? 24 : 8,
              decoration: BoxDecoration(
                color: isActive ? tierColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}