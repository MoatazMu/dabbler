import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import '../../../domain/entities/badge_tier.dart';

/// Rank data for display
class RankData {
  final int currentRank;
  final int previousRank;
  final int totalUsers;
  final double percentile;
  final RankPerformance performance;
  final List<RankHistoryPoint> history;
  final int bestRank;
  final int worstRank;
  final Duration timeInCurrentRank;
  final String category;
  final int points;
  final BadgeTier tier;

  const RankData({
    required this.currentRank,
    required this.previousRank,
    required this.totalUsers,
    required this.percentile,
    required this.performance,
    this.history = const [],
    required this.bestRank,
    required this.worstRank,
    required this.timeInCurrentRank,
    this.category = 'Overall',
    required this.points,
    required this.tier,
  });

  int get rankMovement => previousRank - currentRank;
  bool get hasImproved => rankMovement > 0;
  bool get hasDeclined => rankMovement < 0;
  bool get isStable => rankMovement == 0;

  String get movementText {
    if (hasImproved) return '+$rankMovement';
    if (hasDeclined) return '$rankMovement';
    return '—';
  }

  String get percentileText {
    if (percentile >= 99.0) return 'Top 1%';
    if (percentile >= 95.0) return 'Top 5%';
    if (percentile >= 90.0) return 'Top 10%';
    if (percentile >= 75.0) return 'Top 25%';
    if (percentile >= 50.0) return 'Top 50%';
    return 'Bottom 50%';
  }
}

/// Historical rank point
class RankHistoryPoint {
  final int rank;
  final DateTime timestamp;
  final int points;

  const RankHistoryPoint({
    required this.rank,
    required this.timestamp,
    required this.points,
  });
}

enum RankPerformance {
  excellent, // Top 10%
  good, // Top 25%
  average, // Top 50%
  below_average, // Bottom 50%
  poor, // Bottom 25%
}

/// Large rank display widget with animations and analytics
class RankIndicator extends StatefulWidget {
  final RankData data;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final bool showMovement;
  final bool showPercentile;
  final bool showChart;
  final bool showTimeInRank;
  final bool enableAnimations;
  final bool enableHaptics;
  final EdgeInsets? padding;
  final double? size;

  const RankIndicator({
    super.key,
    required this.data,
    this.onTap,
    this.onShare,
    this.showMovement = true,
    this.showPercentile = true,
    this.showChart = true,
    this.showTimeInRank = true,
    this.enableAnimations = true,
    this.enableHaptics = true,
    this.padding,
    this.size,
  });

  @override
  State<RankIndicator> createState() => _RankIndicatorState();
}

class _RankIndicatorState extends State<RankIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rankController;
  late AnimationController _glowController;
  late AnimationController _movementController;
  late AnimationController _chartController;

  late Animation<int> _rankAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _movementAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _rankController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _movementController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _rankAnimation = IntTween(
      begin: math.max(1, widget.data.currentRank + 50),
      end: widget.data.currentRank,
    ).animate(CurvedAnimation(
      parent: _rankController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _movementAnimation = CurvedAnimation(
      parent: _movementController,
      curve: Curves.elasticOut,
    );

    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );

    if (widget.enableAnimations) {
      _rankController.forward();
      _glowController.repeat(reverse: true);
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _movementController.forward();
      });

      if (widget.showChart) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _chartController.forward();
        });
      }
    } else {
      _rankController.value = 1.0;
      _movementController.value = 1.0;
      _chartController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _rankController.dispose();
    _glowController.dispose();
    _movementController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Color _getPerformanceColor(RankPerformance performance) {
    switch (performance) {
      case RankPerformance.excellent:
        return Colors.green[600]!;
      case RankPerformance.good:
        return Colors.blue[600]!;
      case RankPerformance.average:
        return Colors.orange[600]!;
      case RankPerformance.below_average:
        return Colors.red[400]!;
      case RankPerformance.poor:
        return Colors.red[600]!;
    }
  }

  Color _getMovementColor() {
    if (widget.data.hasImproved) return Colors.green[600]!;
    if (widget.data.hasDeclined) return Colors.red[600]!;
    return Colors.grey[600]!;
  }

  IconData _getMovementIcon() {
    if (widget.data.hasImproved) return Icons.trending_up;
    if (widget.data.hasDeclined) return Icons.trending_down;
    return Icons.trending_flat;
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

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleShare() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }

    final rank = widget.data.currentRank;
    final percentile = widget.data.percentileText;
    final category = widget.data.category;
    
    final message = 'Check out my leaderboard ranking! 📊\n'
        '🏆 Rank #$rank in $category\n'
        '📈 $percentile performer\n'
        'Can you beat my score?';

    Share.share(message, subject: 'My Leaderboard Ranking');
    widget.onShare?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final performanceColor = _getPerformanceColor(widget.data.performance);
    final tierColor = _getTierColor(widget.data.tier);

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: performanceColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: performanceColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        performanceColor.withOpacity(0.1),
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
                        _buildHeader(theme, performanceColor),
                        const SizedBox(height: 24),
                        _buildRankDisplay(theme, performanceColor),
                        const SizedBox(height: 20),
                        _buildStatsRow(theme, performanceColor, tierColor),
                        if (widget.showChart &&
                            widget.data.history.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildMiniChart(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color performanceColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR RANK',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              widget.data.category,
              style: theme.textTheme.titleMedium?.copyWith(
                color: performanceColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (widget.onShare != null)
          IconButton(
            onPressed: _handleShare,
            icon: const Icon(Icons.share),
            tooltip: 'Share Rank',
          ),
      ],
    );
  }

  Widget _buildRankDisplay(ThemeData theme, Color performanceColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _rankAnimation,
                builder: (context, child) {
                  return Text(
                    '#${_rankAnimation.value}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: widget.size ?? 72,
                      fontWeight: FontWeight.bold,
                      color: performanceColor,
                      height: 1.0,
                    ),
                  );
                },
              ),
              Text(
                'out of ${widget.data.totalUsers.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (widget.showMovement) ...[
          const SizedBox(width: 20),
          _buildMovementIndicator(theme),
        ],
      ],
    );
  }

  Widget _buildMovementIndicator(ThemeData theme) {
    final movementColor = _getMovementColor();

    return AnimatedBuilder(
      animation: _movementAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _movementAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: movementColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: movementColor.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMovementIcon(),
                  color: movementColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.data.movementText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: movementColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'from last',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: movementColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(ThemeData theme, Color performanceColor, Color tierColor) {
    return Row(
      children: [
        if (widget.showPercentile)
          Expanded(child: _buildStatCard(
            title: 'PERCENTILE',
            value: widget.data.percentileText,
            color: performanceColor,
            theme: theme,
          )),
        if (widget.showPercentile && widget.showTimeInRank)
          const SizedBox(width: 12),
        if (widget.showTimeInRank)
          Expanded(child: _buildStatCard(
            title: 'TIME IN RANK',
            value: _formatDuration(widget.data.timeInCurrentRank),
            color: Colors.grey[600]!,
            theme: theme,
          )),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rank History',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Best: #${widget.data.bestRank}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: RankChartPainter(
                    history: widget.data.history,
                    animationProgress: _chartAnimation.value,
                    color: _getPerformanceColor(widget.data.performance),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for mini rank chart
class RankChartPainter extends CustomPainter {
  final List<RankHistoryPoint> history;
  final double animationProgress;
  final Color color;

  RankChartPainter({
    required this.history,
    required this.animationProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Find min and max ranks for scaling
    final minRank = history.map((p) => p.rank).reduce(math.min).toDouble();
    final maxRank = history.map((p) => p.rank).reduce(math.max).toDouble();
    final rankRange = maxRank - minRank;

    if (rankRange == 0) return;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    // Calculate points
    for (int i = 0; i < history.length; i++) {
      final progress = i / (history.length - 1);
      final x = size.width * progress;
      
      // Invert Y because lower rank is better
      final normalizedRank = (maxRank - history[i].rank) / rankRange;
      final y = size.height * (1 - normalizedRank);
      
      points.add(Offset(x, y));
    }

    // Only draw up to animation progress
    final visiblePoints = (points.length * animationProgress).round();
    if (visiblePoints < 2) return;

    final visiblePath = points.take(visiblePoints).toList();

    // Create line path
    path.moveTo(visiblePath[0].dx, visiblePath[0].dy);
    for (int i = 1; i < visiblePath.length; i++) {
      path.lineTo(visiblePath[i].dx, visiblePath[i].dy);
    }

    // Create fill path
    fillPath.moveTo(visiblePath[0].dx, size.height);
    fillPath.lineTo(visiblePath[0].dx, visiblePath[0].dy);
    for (int i = 1; i < visiblePath.length; i++) {
      fillPath.lineTo(visiblePath[i].dx, visiblePath[i].dy);
    }
    fillPath.lineTo(visiblePath.last.dx, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots
    for (final point in visiblePath) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(RankChartPainter oldDelegate) {
    return animationProgress != oldDelegate.animationProgress ||
           history != oldDelegate.history ||
           color != oldDelegate.color;
  }
}