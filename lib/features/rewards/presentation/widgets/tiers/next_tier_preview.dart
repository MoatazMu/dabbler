import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/badge_tier.dart';

/// Data class for next tier preview
class NextTierPreviewData {
  final BadgeTier currentTier;
  final BadgeTier nextTier;
  final int currentPoints;
  final int nextTierMinPoints;
  final int nextTierMaxPoints;
  final List<NextTierBenefit> upcomingBenefits;
  final List<NextTierBenefit> exclusiveBenefits;
  final double progressPercentage;
  final int pointsNeeded;
  final Duration? estimatedTimeToUpgrade;
  final List<String> upgradeRequirements;
  final List<MotivationalMessage> motivationalMessages;
  final String nextTierDescription;
  final int dailyPointsAverage;
  final int weeklyPointsAverage;

  const NextTierPreviewData({
    required this.currentTier,
    required this.nextTier,
    required this.currentPoints,
    required this.nextTierMinPoints,
    required this.nextTierMaxPoints,
    required this.upcomingBenefits,
    required this.exclusiveBenefits,
    required this.progressPercentage,
    required this.pointsNeeded,
    this.estimatedTimeToUpgrade,
    this.upgradeRequirements = const [],
    this.motivationalMessages = const [],
    this.nextTierDescription = '',
    this.dailyPointsAverage = 0,
    this.weeklyPointsAverage = 0,
  });

  bool get canUpgradeNow => pointsNeeded <= 0;
  bool get isCloseToUpgrade => progressPercentage >= 0.8;
  
  List<NextTierBenefit> get topBenefits => 
      upcomingBenefits.where((b) => b.importance == BenefitImportance.high || 
                                    b.importance == BenefitImportance.critical).toList();

  MotivationalMessage? get currentMessage {
    if (motivationalMessages.isEmpty) return null;
    
    if (canUpgradeNow) {
      return motivationalMessages.firstWhere(
        (m) => m.type == MessageType.ready,
        orElse: () => motivationalMessages.first,
      );
    } else if (isCloseToUpgrade) {
      return motivationalMessages.firstWhere(
        (m) => m.type == MessageType.almostThere,
        orElse: () => motivationalMessages.first,
      );
    } else {
      return motivationalMessages.firstWhere(
        (m) => m.type == MessageType.encourage,
        orElse: () => motivationalMessages.first,
      );
    }
  }
}

/// Individual benefit for next tier
class NextTierBenefit {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final BenefitImportance importance;
  final BenefitCategory category;
  final String? valueIncrease;
  final bool isNewFeature;
  final String? comparisonText;

  const NextTierBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.importance = BenefitImportance.normal,
    this.category = BenefitCategory.general,
    this.valueIncrease,
    this.isNewFeature = false,
    this.comparisonText,
  });
}

enum BenefitImportance {
  low,
  normal,
  high,
  critical,
}

enum BenefitCategory {
  general,
  social,
  gameplay,
  rewards,
  privileges,
  exclusive,
}

/// Motivational message data
class MotivationalMessage {
  final String id;
  final String message;
  final String? subtitle;
  final IconData icon;
  final MessageType type;
  final Color? color;

  const MotivationalMessage({
    required this.id,
    required this.message,
    this.subtitle,
    required this.icon,
    required this.type,
    this.color,
  });
}

enum MessageType {
  encourage,
  almostThere,
  ready,
  celebration,
}

/// Interactive next tier preview widget
class NextTierPreview extends StatefulWidget {
  final NextTierPreviewData data;
  final VoidCallback? onUpgrade;
  final VoidCallback? onShare;
  final Function(NextTierBenefit)? onBenefitTap;
  final VoidCallback? onProgressTap;
  final bool showMotivationalMessage;
  final bool showTimeEstimates;
  final bool showDetailedBenefits;
  final bool enableAnimations;
  final bool enableHaptics;
  final EdgeInsets? padding;
  final double? elevation;

  const NextTierPreview({
    super.key,
    required this.data,
    this.onUpgrade,
    this.onShare,
    this.onBenefitTap,
    this.onProgressTap,
    this.showMotivationalMessage = true,
    this.showTimeEstimates = true,
    this.showDetailedBenefits = true,
    this.enableAnimations = true,
    this.enableHaptics = true,
    this.padding,
    this.elevation,
  });

  @override
  State<NextTierPreview> createState() => _NextTierPreviewState();
}

class _NextTierPreviewState extends State<NextTierPreview>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _progressController;

  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.data.progressPercentage,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.enableAnimations) {
      _shimmerController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
      _progressController.forward();
    } else {
      _progressController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _progressController.dispose();
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

  Color _getImportanceColor(BenefitImportance importance) {
    switch (importance) {
      case BenefitImportance.low:
        return Colors.grey[600]!;
      case BenefitImportance.normal:
        return Colors.blue[600]!;
      case BenefitImportance.high:
        return Colors.orange[600]!;
      case BenefitImportance.critical:
        return Colors.red[600]!;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _handleUpgrade() {
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }
    widget.onUpgrade?.call();
  }

  void _handleShare() {
    final nextTierName = _getTierName(widget.data.nextTier);
    final currentProgress = (widget.data.progressPercentage * 100).toInt();
    final pointsNeeded = widget.data.pointsNeeded;
    
    final message = widget.data.canUpgradeNow
        ? 'I\'m ready to upgrade to $nextTierName tier! 🚀\n'
          'Join me and unlock exclusive benefits!'
        : 'I\'m $currentProgress% towards $nextTierName tier! 📈\n'
          'Only $pointsNeeded points to go!\n'
          'Join me on this journey!';

    Share.share(message, subject: 'Tier Upgrade Progress');
    
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    
    widget.onShare?.call();
  }

  void _handleBenefitTap(NextTierBenefit benefit) {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onBenefitTap?.call(benefit);
  }

  void _handleProgressTap() {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    widget.onProgressTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNextTierCard(),
          const SizedBox(height: 16),
          if (widget.showMotivationalMessage && widget.data.currentMessage != null)
            _buildMotivationalMessage(),
          if (widget.showMotivationalMessage && widget.data.currentMessage != null)
            const SizedBox(height: 16),
          _buildProgressSection(),
          const SizedBox(height: 16),
          if (widget.showDetailedBenefits)
            _buildBenefitsPreview(),
          if (widget.showTimeEstimates && widget.data.estimatedTimeToUpgrade != null)
            _buildTimeEstimate(),
        ],
      ),
    );
  }

  Widget _buildNextTierCard() {
    final theme = Theme.of(context);
    final nextTierColor = _getTierColor(widget.data.nextTier);
    final nextTierName = _getTierName(widget.data.nextTier);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: nextTierColor.withOpacity(0.3 * _glowAnimation.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Card(
            elevation: widget.elevation ?? 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    nextTierColor.withOpacity(0.1),
                    nextTierColor.withOpacity(0.05),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: nextTierColor.withOpacity(
                                  0.2 + 0.1 * _shimmerAnimation.value,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: nextTierColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getTierIcon(widget.data.nextTier),
                                color: nextTierColor,
                                size: 32,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'NEXT TIER',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_upward,
                                    color: nextTierColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextTierName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: nextTierColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.data.nextTierDescription.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.data.nextTierDescription,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onShare != null ? _handleShare : null,
                          icon: const Icon(Icons.share),
                          tooltip: 'Share Progress',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildUpgradeButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotivationalMessage() {
    final message = widget.data.currentMessage!;
    final theme = Theme.of(context);
    final messageColor = message.color ?? _getTierColor(widget.data.nextTier);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: messageColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: messageColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  message.icon,
                  color: messageColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: messageColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (message.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          message.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: messageColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    final theme = Theme.of(context);
    final nextTierColor = _getTierColor(widget.data.nextTier);

    return GestureDetector(
      onTap: _handleProgressTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to Next Tier',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: nextTierColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(widget.data.progressPercentage * 100).toInt()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: nextTierColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(nextTierColor),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Points',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${widget.data.currentPoints}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.data.canUpgradeNow 
                                    ? 'Ready to Upgrade!'
                                    : 'Points Needed',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: widget.data.canUpgradeNow
                                      ? nextTierColor
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                widget.data.canUpgradeNow
                                    ? '🎉'
                                    : '${widget.data.pointsNeeded}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.data.canUpgradeNow
                                      ? nextTierColor
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeButton() {
    final nextTierColor = _getTierColor(widget.data.nextTier);
    final nextTierName = _getTierName(widget.data.nextTier);
    final canUpgrade = widget.data.canUpgradeNow;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
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
                    ? 'UPGRADE TO $nextTierName'
                    : '${widget.data.pointsNeeded} POINTS NEEDED',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canUpgrade ? nextTierColor : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: canUpgrade ? 8 : 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitsPreview() {
    final theme = Theme.of(context);
    final nextTierColor = _getTierColor(widget.data.nextTier);
    final topBenefits = widget.data.topBenefits.take(3).toList();
    
    if (topBenefits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: nextTierColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Benefits Awaiting',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: nextTierColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topBenefits.map((benefit) => _buildBenefitItem(benefit)),
            if (widget.data.upcomingBenefits.length > 3) ...[
              const SizedBox(height: 12),
              Text(
                '+${widget.data.upcomingBenefits.length - 3} more exclusive benefits',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: nextTierColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(NextTierBenefit benefit) {
    final theme = Theme.of(context);
    final importanceColor = _getImportanceColor(benefit.importance);
    final nextTierColor = _getTierColor(widget.data.nextTier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleBenefitTap(benefit),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: nextTierColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: nextTierColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: importanceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  benefit.icon,
                  color: importanceColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            benefit.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (benefit.isNewFeature)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (benefit.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        benefit.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (benefit.valueIncrease != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        benefit.valueIncrease!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: nextTierColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeEstimate() {
    final theme = Theme.of(context);
    final nextTierColor = _getTierColor(widget.data.nextTier);
    final estimatedTime = widget.data.estimatedTimeToUpgrade!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: nextTierColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time to Next Tier',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDuration(estimatedTime),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: nextTierColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: nextTierColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: nextTierColor,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on\naverage',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: nextTierColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.data.dailyPointsAverage > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Average: ${widget.data.dailyPointsAverage} pts',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Weekly Average: ${widget.data.weeklyPointsAverage} pts',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}