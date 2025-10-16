import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Social statistics display mode
enum StatsDisplayMode {
  compact,
  expanded,
  comparison,
}

/// Stat item configuration
class StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color? color;
  final String? suffix;
  final String? trend; // '+5%', '-2%', etc.
  final VoidCallback? onTap;

  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.suffix,
    this.trend,
    this.onTap,
  });
}

/// Mini chart data point
class ChartDataPoint {
  final double value;
  final DateTime timestamp;
  final String? label;

  const ChartDataPoint({
    required this.value,
    required this.timestamp,
    this.label,
  });
}

/// Chart configuration
class ChartConfig {
  final Color primaryColor;
  final Color backgroundColor;
  final double height;
  final bool showGrid;
  final bool showDots;
  final bool animate;

  const ChartConfig({
    required this.primaryColor,
    required this.backgroundColor,
    this.height = 60,
    this.showGrid = false,
    this.showDots = true,
    this.animate = true,
  });
}

/// Comprehensive social statistics widget
class SocialStatsWidget extends StatefulWidget {
  /// List of stat items to display
  final List<StatItem> stats;
  
  /// Display mode
  final StatsDisplayMode displayMode;
  
  /// Enable refresh functionality
  final bool enableRefresh;
  
  /// Refresh callback
  final Future<void> Function()? onRefresh;
  
  /// Chart data for mini previews
  final Map<String, List<ChartDataPoint>>? chartData;
  
  /// Chart configuration
  final ChartConfig? chartConfig;
  
  /// Show comparison with previous period
  final bool showComparison;
  
  /// Comparison data (previous period)
  final List<StatItem>? comparisonStats;
  
  /// Custom background color
  final Color? backgroundColor;
  
  /// Custom padding
  final EdgeInsetsGeometry? padding;
  
  /// Border radius
  final BorderRadius? borderRadius;
  
  /// Enable animations
  final bool enableAnimations;
  
  /// Animation duration
  final Duration animationDuration;
  
  /// Loading state
  final bool isLoading;
  
  /// Error state
  final String? errorMessage;
  
  /// Retry callback for error state
  final VoidCallback? onRetry;
  
  /// Show as card
  final bool showAsCard;
  
  /// Card elevation
  final double cardElevation;
  
  /// Custom title
  final String? title;
  
  /// Title style
  final TextStyle? titleStyle;

  const SocialStatsWidget({
    super.key,
    required this.stats,
    this.displayMode = StatsDisplayMode.compact,
    this.enableRefresh = true,
    this.onRefresh,
    this.chartData,
    this.chartConfig,
    this.showComparison = false,
    this.comparisonStats,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.enableAnimations = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.showAsCard = true,
    this.cardElevation = 2,
    this.title,
    this.titleStyle,
  });

  /// Factory for common user stats
  factory SocialStatsWidget.userProfile({
    required int friendsCount,
    required int postsCount,
    required double engagementRate,
    required DateTime joinDate,
    Map<String, List<ChartDataPoint>>? chartData,
    VoidCallback? onFriendsView,
    VoidCallback? onPostsView,
    bool enableRefresh = true,
    Future<void> Function()? onRefresh,
  }) {
    final daysSinceJoin = DateTime.now().difference(joinDate).inDays;
    
    return SocialStatsWidget(
      title: 'Profile Stats',
      stats: [
        StatItem(
          label: 'Friends',
          value: friendsCount,
          icon: Icons.people,
          color: Colors.blue[600],
          onTap: onFriendsView,
        ),
        StatItem(
          label: 'Posts',
          value: postsCount,
          icon: Icons.article,
          color: Colors.green[600],
          onTap: onPostsView,
        ),
        StatItem(
          label: 'Engagement',
          value: (engagementRate * 100).round(),
          icon: Icons.favorite,
          color: Colors.red[600],
          suffix: '%',
        ),
        StatItem(
          label: 'Days Active',
          value: daysSinceJoin,
          icon: Icons.calendar_today,
          color: Colors.orange[600],
        ),
      ],
      chartData: chartData,
      enableRefresh: enableRefresh,
      onRefresh: onRefresh,
    );
  }

  /// Factory for post engagement stats
  factory SocialStatsWidget.postEngagement({
    required int likesCount,
    required int commentsCount,
    required int sharesCount,
    required int viewsCount,
    Map<String, List<ChartDataPoint>>? chartData,
    bool showComparison = false,
    List<StatItem>? previousStats,
  }) {
    return SocialStatsWidget(
      title: 'Engagement',
      displayMode: StatsDisplayMode.compact,
      stats: [
        StatItem(
          label: 'Likes',
          value: likesCount,
          icon: Icons.favorite,
          color: Colors.red[600],
        ),
        StatItem(
          label: 'Comments',
          value: commentsCount,
          icon: Icons.comment,
          color: Colors.blue[600],
        ),
        StatItem(
          label: 'Shares',
          value: sharesCount,
          icon: Icons.share,
          color: Colors.green[600],
        ),
        StatItem(
          label: 'Views',
          value: viewsCount,
          icon: Icons.visibility,
          color: Colors.orange[600],
        ),
      ],
      chartData: chartData,
      showComparison: showComparison,
      comparisonStats: previousStats,
    );
  }

  @override
  State<SocialStatsWidget> createState() => _SocialStatsWidgetState();
}

class _SocialStatsWidgetState extends State<SocialStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _refreshRotation;
  
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    if (widget.enableAnimations) {
      _animationController.forward();
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _refreshAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _refreshRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_refreshAnimationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _buildContent();

    if (widget.enableAnimations && !widget.isLoading) {
      content = AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    if (widget.showAsCard) {
      content = Card(
        elevation: widget.cardElevation,
        color: widget.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: !widget.showAsCard ? BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) _buildTitle(),
          _buildStats(),
          if (widget.chartData != null) _buildCharts(),
          if (widget.showComparison && widget.comparisonStats != null)
            _buildComparison(),
          if (widget.enableRefresh) _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.title!,
          style: widget.titleStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.enableRefresh && !_isRefreshing)
          IconButton(
            icon: AnimatedBuilder(
              animation: _refreshRotation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshRotation.value,
                  child: const Icon(Icons.refresh, size: 20),
                );
              },
            ),
            onPressed: _handleRefresh,
            tooltip: 'Refresh',
          ),
      ],
    );
  }

  Widget _buildStats() {
    switch (widget.displayMode) {
      case StatsDisplayMode.compact:
        return _buildCompactStats();
      case StatsDisplayMode.expanded:
        return _buildExpandedStats();
      case StatsDisplayMode.comparison:
        return _buildComparisonStats();
    }
  }

  Widget _buildCompactStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widget.stats.map((stat) => _buildStatItem(stat, true)).toList(),
    );
  }

  Widget _buildExpandedStats() {
    return Column(
      children: widget.stats
          .map((stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildStatItem(stat, false),
              ))
          .toList(),
    );
  }

  Widget _buildComparisonStats() {
    return Column(
      children: widget.stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        final comparison = widget.comparisonStats != null &&
                index < widget.comparisonStats!.length
            ? widget.comparisonStats![index]
            : null;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildComparisonStatItem(stat, comparison),
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(StatItem stat, bool isCompact) {
    Widget content = isCompact
        ? Column(
            children: [
              Icon(
                stat.icon,
                color: stat.color ?? Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              _buildAnimatedNumber(stat.value, stat.suffix),
              Text(
                stat.label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (stat.trend != null) _buildTrendIndicator(stat.trend!),
            ],
          )
        : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (stat.color ?? Theme.of(context).primaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat.icon,
                  color: stat.color ?? Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Row(
                      children: [
                        _buildAnimatedNumber(stat.value, stat.suffix),
                        if (stat.trend != null) ...[
                          const SizedBox(width: 8),
                          _buildTrendIndicator(stat.trend!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

    if (stat.onTap != null) {
      content = InkWell(
        onTap: stat.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: content,
        ),
      );
    }

    return Expanded(child: content);
  }

  Widget _buildComparisonStatItem(StatItem stat, StatItem? comparison) {
    final difference = comparison != null ? stat.value - comparison.value : 0;
    final percentage = comparison != null && comparison.value > 0
        ? ((difference / comparison.value) * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (stat.color ?? Theme.of(context).primaryColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            stat.icon,
            color: stat.color ?? Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  _buildAnimatedNumber(stat.value, stat.suffix),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difference >= 0 ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          difference >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: difference >= 0 ? Colors.green[600] : Colors.red[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: difference >= 0 ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedNumber(int value, String? suffix) {
    return TweenAnimationBuilder<double>(
      duration: widget.animationDuration,
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      builder: (context, animatedValue, child) {
        return Text(
          '${_formatNumber(animatedValue.round())}${suffix ?? ''}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  Widget _buildTrendIndicator(String trend) {
    final isPositive = trend.startsWith('+');
    final color = isPositive ? Colors.green[600] : Colors.red[600];
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            trend,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: widget.chartData!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildMiniChart(entry.key, entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniChart(String label, List<ChartDataPoint> data) {
    final config = widget.chartConfig ?? ChartConfig(
      primaryColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[100]!,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: config.height,
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _MiniChart(
            data: data,
            config: config,
          ),
        ),
      ],
    );
  }

  Widget _buildComparison() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'vs Previous Period',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildComparisonStats(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.title != null) _buildShimmerTitle(),
          _buildShimmerStats(),
        ],
      ),
    );
  }

  Widget _buildShimmerTitle() {
    return Container(
      height: 20,
      width: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildShimmerStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.stats.length,
        (index) => Expanded(
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 40,
                height: 16,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ?? 'Please try again',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    if (widget.displayMode == StatsDisplayMode.compact) {
      return const SizedBox.shrink(); // Already shown in title
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: _isRefreshing ? null : _handleRefresh,
        icon: _isRefreshing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 16),
        label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh'),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshAnimationController.repeat();

    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}

/// Mini chart widget for displaying trends
class _MiniChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final ChartConfig config;

  const _MiniChart({
    required this.data,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _MiniChartPainter(data: data, config: config),
    );
  }
}

/// Custom painter for mini charts
class _MiniChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final ChartConfig config;

  _MiniChartPainter({
    required this.data,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = config.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = config.primaryColor
      ..style = PaintingStyle.fill;

    final maxValue = data.map((e) => e.value).reduce(math.max);
    final minValue = data.map((e) => e.value).reduce(math.min);
    final valueRange = maxValue - minValue;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = valueRange > 0 
          ? (data[i].value - minValue) / valueRange 
          : 0.5;
      final y = size.height - (normalizedValue * size.height);
      
      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots if enabled
    if (config.showDots) {
      for (final point in points) {
        canvas.drawCircle(point, 3, dotPaint);
      }
    }

    // Draw grid if enabled
    if (config.showGrid) {
      final gridPaint = Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = 0.5;

      // Horizontal grid lines
      for (int i = 1; i < 4; i++) {
        final y = (i / 4) * size.height;
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MiniChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.config != config;
  }
}
