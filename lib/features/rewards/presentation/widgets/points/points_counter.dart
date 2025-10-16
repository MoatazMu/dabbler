import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Points data for display and tracking
class PointsData {
  final int currentPoints;
  final int previousPoints;
  final List<PointsHistoryPoint> history;
  final Duration animationDuration;
  final String label;
  final String currency;
  final bool showSign;
  final bool showGlow;

  const PointsData({
    required this.currentPoints,
    this.previousPoints = 0,
    this.history = const [],
    this.animationDuration = const Duration(milliseconds: 2000),
    this.label = 'Points',
    this.currency = '',
    this.showSign = true,
    this.showGlow = true,
  });

  int get pointsDifference => currentPoints - previousPoints;
  bool get hasIncrease => pointsDifference > 0;
  bool get hasDecrease => pointsDifference < 0;
  bool get hasChanged => pointsDifference != 0;

  String get changeIndicator {
    if (hasIncrease) return '+${_formatNumber(pointsDifference)}';
    if (hasDecrease) return _formatNumber(pointsDifference);
    return '';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String get formattedCurrentPoints => _formatNumber(currentPoints);
}

/// Historical points data
class PointsHistoryPoint {
  final int points;
  final DateTime timestamp;

  const PointsHistoryPoint({
    required this.points,
    required this.timestamp,
  });
}

/// Animated points counter widget
class PointsCounter extends StatefulWidget {
  final PointsData data;
  final VoidCallback? onTap;
  final Function(String)? onBreakdown;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final bool showSparkline;
  final bool enableInteraction;
  final bool enableHaptics;
  final double? size;
  final EdgeInsets? padding;

  const PointsCounter({
    super.key,
    required this.data,
    this.onTap,
    this.onBreakdown,
    this.textStyle,
    this.labelStyle,
    this.showSparkline = true,
    this.enableInteraction = true,
    this.enableHaptics = true,
    this.size,
    this.padding,
  });

  @override
  State<PointsCounter> createState() => _PointsCounterState();
}

class _PointsCounterState extends State<PointsCounter>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _glowController;
  late AnimationController _changeController;
  late AnimationController _sparklineController;

  late Animation<int> _countAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _changeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _countController = AnimationController(
      duration: widget.data.animationDuration,
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _changeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sparklineController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _countAnimation = IntTween(
      begin: widget.data.previousPoints,
      end: widget.data.currentPoints,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _changeAnimation = CurvedAnimation(
      parent: _changeController,
      curve: Curves.elasticOut,
    );

    // Start animations
    _countController.forward();

    if (widget.data.showGlow && widget.data.hasChanged) {
      _glowController.repeat(reverse: true);
      _changeController.forward();
    }

    if (widget.showSparkline && widget.data.history.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _sparklineController.forward();
      });
    }
  }

  @override
  void didUpdateWidget(PointsCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.data.currentPoints != widget.data.currentPoints) {
      _countAnimation = IntTween(
        begin: oldWidget.data.currentPoints,
        end: widget.data.currentPoints,
      ).animate(CurvedAnimation(
        parent: _countController,
        curve: Curves.easeOutCubic,
      ));
      
      _countController.reset();
      _countController.forward();
      
      if (widget.data.showGlow && widget.data.hasChanged) {
        _glowController.repeat(reverse: true);
        _changeController.forward();
      }
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _glowController.dispose();
    _changeController.dispose();
    _sparklineController.dispose();
    super.dispose();
  }

  Color _getChangeColor() {
    if (widget.data.hasIncrease) return Colors.green[600]!;
    if (widget.data.hasDecrease) return Colors.red[600]!;
    return Colors.grey[600]!;
  }

  void _handleTap() {
    if (!widget.enableInteraction) return;
    
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (!widget.enableInteraction) return;
    
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    
    widget.onBreakdown?.call('detailed');
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor = _getChangeColor();

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPointsDisplay(theme, changeColor),
            if (widget.data.hasChanged && widget.data.showSign) ...[
              const SizedBox(height: 8),
              _buildChangeIndicator(theme, changeColor),
            ],
            if (widget.showSparkline && widget.data.history.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSparkline(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPointsDisplay(ThemeData theme, Color changeColor) {
    return AnimatedBuilder(
      animation: widget.data.showGlow ? _glowAnimation : _countAnimation,
      builder: (context, child) {
        final glowOpacity = widget.data.showGlow && widget.data.hasChanged
            ? _glowAnimation.value
            : 0.0;

        return Container(
          decoration: widget.data.showGlow && glowOpacity > 0
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: changeColor.withOpacity(0.3 * glowOpacity),
                      blurRadius: 20 * glowOpacity,
                      spreadRadius: 5 * glowOpacity,
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.data.label.isNotEmpty) ...[
                Text(
                  widget.data.label,
                  style: widget.labelStyle ??
                      theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (widget.data.currency.isNotEmpty) ...[
                    Text(
                      widget.data.currency,
                      style: widget.textStyle?.copyWith(
                            fontSize: (widget.textStyle?.fontSize ?? 24) * 0.7,
                            color: Colors.grey[600],
                          ) ??
                          theme.textTheme.headlineMedium?.copyWith(
                            fontSize: (widget.size ?? 32) * 0.7,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedBuilder(
                    animation: _countAnimation,
                    builder: (context, child) {
                      return Text(
                        _formatNumber(_countAnimation.value),
                        style: widget.textStyle ??
                            theme.textTheme.headlineLarge?.copyWith(
                              fontSize: widget.size ?? 48,
                              fontWeight: FontWeight.bold,
                              color: widget.data.hasChanged
                                  ? changeColor
                                  : theme.colorScheme.onSurface,
                              shadows: glowOpacity > 0
                                  ? [
                                      Shadow(
                                        color: changeColor
                                            .withOpacity(0.5 * glowOpacity),
                                        blurRadius: 10 * glowOpacity,
                                      ),
                                    ]
                                  : null,
                            ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangeIndicator(ThemeData theme, Color changeColor) {
    return AnimatedBuilder(
      animation: _changeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _changeAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: changeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.data.hasIncrease
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: changeColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.data.changeIndicator,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparkline() {
    return AnimatedBuilder(
      animation: _sparklineController,
      builder: (context, child) {
        return Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: SparklinePainter(
                    history: widget.data.history,
                    animationProgress: _sparklineController.value,
                    color: _getChangeColor(),
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

/// Custom painter for points sparkline
class SparklinePainter extends CustomPainter {
  final List<PointsHistoryPoint> history;
  final double animationProgress;
  final Color color;

  SparklinePainter({
    required this.history,
    required this.animationProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty || animationProgress == 0) return;

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

    // Find min and max points for scaling
    final minPoints = history.map((p) => p.points).reduce(math.min).toDouble();
    final maxPoints = history.map((p) => p.points).reduce(math.max).toDouble();
    final pointsRange = maxPoints - minPoints;

    if (pointsRange == 0) {
      // Draw flat line if no variation
      final y = size.height * 0.5;
      final path = Path();
      path.moveTo(0, y);
      path.lineTo(size.width * animationProgress, y);
      canvas.drawPath(path, paint);
      return;
    }

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    // Calculate points
    for (int i = 0; i < history.length; i++) {
      final progress = i / (history.length - 1);
      final x = size.width * progress;
      final normalizedPoint = (history[i].points - minPoints) / pointsRange;
      final y = size.height * (1 - normalizedPoint);
      
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

    // Draw dots at key points
    for (int i = 0; i < visiblePath.length; i += math.max(1, visiblePath.length ~/ 5)) {
      canvas.drawCircle(visiblePath[i], 3, dotPaint);
    }

    // Highlight current point
    if (visiblePath.isNotEmpty) {
      final currentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(visiblePath.last, 4, currentPaint);
      
      // Glow effect for current point
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(visiblePath.last, 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) {
    return animationProgress != oldDelegate.animationProgress ||
           history != oldDelegate.history ||
           color != oldDelegate.color;
  }
}