
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/badge_tier.dart';

class TierProgressData {
  final BadgeTier currentTier;
  final BadgeTier? nextTier;
  final int currentPoints;
  final int tierMinPoints;
  final int tierMaxPoints;
  final int totalPoints;
  final List<int> milestonePoints;
  final DateTime? expectedUpgradeDate;

  const TierProgressData({
    required this.currentTier,
    this.nextTier,
    required this.currentPoints,
    required this.tierMinPoints,
    required this.tierMaxPoints,
    required this.totalPoints,
    this.milestonePoints = const [],
    this.expectedUpgradeDate,
  });

  double get progress {
    if (tierMaxPoints <= tierMinPoints) return 1.0;
    return ((currentPoints - tierMinPoints) / (tierMaxPoints - tierMinPoints))
        .clamp(0.0, 1.0);
  }

  int get pointsToNext => (tierMaxPoints - currentPoints).clamp(0, tierMaxPoints);

  double get overallProgress => (currentPoints / totalPoints).clamp(0.0, 1.0);
}

class TierProgressIndicator extends StatefulWidget {
  final TierProgressData progressData;
  final double size;
  final bool showPercentage;
  final bool showPoints;
  final bool showTimeEstimate;
  final bool showMilestones;
  final bool enableAnimations;
  final bool enableInteractions;
  final Duration animationDuration;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TierProgressIndicator({
    super.key,
    required this.progressData,
    this.size = 120,
    this.showPercentage = true,
    this.showPoints = true,
    this.showTimeEstimate = false,
    this.showMilestones = true,
    this.enableAnimations = true,
    this.enableInteractions = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.onTap,
    this.onLongPress,
  });

  @override
  State<TierProgressIndicator> createState() => _TierProgressIndicatorState();
}

class _TierProgressIndicatorState extends State<TierProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _countController;
  late AnimationController _scaleController;

  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<int> _pointsCountAnimation;
  late Animation<double> _scaleAnimation;

  bool _showingDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _countController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progressData.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pointsCountAnimation = IntTween(
      begin: 0,
      end: widget.progressData.currentPoints,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    if (widget.enableAnimations) {
      _progressController.forward();
      _countController.forward();
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TierProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progressData.currentPoints != widget.progressData.currentPoints ||
        oldWidget.progressData.progress != widget.progressData.progress) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    // Update progress animation
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: widget.progressData.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Update points counter animation
    _pointsCountAnimation = IntTween(
      begin: _pointsCountAnimation.value,
      end: widget.progressData.currentPoints,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    ));

    _progressController.reset();
    _progressController.forward();
    _countController.reset();
    _countController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _countController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enableInteractions ? _onTap : null,
      onLongPress: widget.enableInteractions ? _onLongPress : null,
      onTapDown: widget.enableInteractions ? (_) => _onTapDown() : null,
      onTapUp: widget.enableInteractions ? (_) => _onTapUp() : null,
      onTapCancel: widget.enableInteractions ? _onTapUp : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _pulseAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  if (widget.enableAnimations)
                    _buildGlowEffect(),

                  // Background circle
                  _buildBackgroundCircle(),

                  // Progress arc
                  _buildProgressArc(),

                  // Milestone markers
                  if (widget.showMilestones)
                    _buildMilestoneMarkers(),

                  // Center content
                  _buildCenterContent(),

                  // Next tier preview
                  if (widget.progressData.nextTier != null)
                    _buildNextTierPreview(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size + 20,
          height: widget.size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getTierColor().withOpacity(0.3 * _glowAnimation.value),
                blurRadius: 15 + (10 * _glowAnimation.value),
                spreadRadius: 5 + (5 * _glowAnimation.value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundCircle() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[100],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressArc() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: ProgressArcPainter(
            progress: _progressAnimation.value,
            strokeWidth: 8,
            backgroundColor: Colors.grey[200]!,
            progressGradient: _getTierGradient(),
            milestones: widget.showMilestones ? _getMilestonePositions() : [],
          ),
        );
      },
    );
  }

  Widget _buildMilestoneMarkers() {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: MilestoneMarkerPainter(
        milestones: _getMilestonePositions(),
        currentProgress: _progressAnimation.value,
        size: widget.size,
        tierColor: _getTierColor(),
      ),
    );
  }

  Widget _buildCenterContent() {
    return SizedBox(
      width: widget.size * 0.7,
      height: widget.size * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tier icon
          _buildTierIcon(),

          const SizedBox(height: 4),

          // Points or percentage
          if (widget.showPoints && !_showingDetails)
            _buildPointsDisplay(),

          if (widget.showPercentage && _showingDetails)
            _buildPercentageDisplay(),

          // Time estimate
          if (widget.showTimeEstimate && _showingDetails)
            _buildTimeEstimate(),
        ],
      ),
    );
  }

  Widget _buildTierIcon() {
    return Container(
      width: widget.size * 0.25,
      height: widget.size * 0.25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getTierColor(),
        boxShadow: [
          BoxShadow(
            color: _getTierColor().withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getTierIcon(),
        size: widget.size * 0.12,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPointsDisplay() {
    return AnimatedBuilder(
      animation: _pointsCountAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              '${_pointsCountAnimation.value}',
              style: TextStyle(
                fontSize: widget.size * 0.1,
                fontWeight: FontWeight.bold,
                color: _getTierColor(),
              ),
            ),
            Text(
              'points',
              style: TextStyle(
                fontSize: widget.size * 0.05,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPercentageDisplay() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final percentage = (_progressAnimation.value * 100).toInt();
        return Column(
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: widget.size * 0.08,
                fontWeight: FontWeight.bold,
                color: _getTierColor(),
              ),
            ),
            Text(
              'to next tier',
              style: TextStyle(
                fontSize: widget.size * 0.04,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeEstimate() {
    if (widget.progressData.expectedUpgradeDate == null) {
      return const SizedBox.shrink();
    }

    return Text(
      _formatTimeEstimate(widget.progressData.expectedUpgradeDate!),
      style: TextStyle(
        fontSize: widget.size * 0.04,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNextTierPreview() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: widget.size * 0.2,
        height: widget.size * 0.2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getNextTierColor().withOpacity(0.9),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getNextTierIcon(),
          size: widget.size * 0.08,
          color: Colors.white,
        ),
      ),
    );
  }

  void _onTap() {
    setState(() {
      _showingDetails = !_showingDetails;
    });

    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onLongPress() {
    HapticFeedback.heavyImpact();
    widget.onLongPress?.call();
  }

  void _onTapDown() {
    _scaleController.forward();
  }

  void _onTapUp() {
    _scaleController.reverse();
  }

  List<double> _getMilestonePositions() {
    if (widget.progressData.milestonePoints.isEmpty) {
      // Default milestones at 25%, 50%, 75%
      return [0.25, 0.50, 0.75];
    }

    final tierRange = widget.progressData.tierMaxPoints - widget.progressData.tierMinPoints;
    if (tierRange <= 0) return [];

    return widget.progressData.milestonePoints
        .where((points) => 
            points > widget.progressData.tierMinPoints && 
            points < widget.progressData.tierMaxPoints)
        .map((points) => 
            (points - widget.progressData.tierMinPoints) / tierRange)
        .toList();
  }

  Color _getTierColor() {
    switch (widget.progressData.currentTier) {
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

  Color _getNextTierColor() {
    if (widget.progressData.nextTier == null) return _getTierColor();
    
    switch (widget.progressData.nextTier!) {
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

  LinearGradient _getTierGradient() {
    final baseColor = _getTierColor();
    return LinearGradient(
      colors: [
        baseColor.withOpacity(0.7),
        baseColor,
        baseColor.withOpacity(0.9),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  IconData _getTierIcon() {
    switch (widget.progressData.currentTier) {
      case BadgeTier.bronze:
        return Icons.military_tech;
      case BadgeTier.silver:
        return Icons.stars;
      case BadgeTier.gold:
        return Icons.workspace_premium;
      case BadgeTier.platinum:
        return Icons.diamond;
      case BadgeTier.diamond:
        return Icons.auto_awesome;
    }
  }

  IconData _getNextTierIcon() {
    if (widget.progressData.nextTier == null) return _getTierIcon();
    
    switch (widget.progressData.nextTier!) {
      case BadgeTier.bronze:
        return Icons.military_tech;
      case BadgeTier.silver:
        return Icons.stars;
      case BadgeTier.gold:
        return Icons.workspace_premium;
      case BadgeTier.platinum:
        return Icons.diamond;
      case BadgeTier.diamond:
        return Icons.auto_awesome;
    }
  }

  String _formatTimeEstimate(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative) {
      return 'Complete!';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else {
      return 'Almost there!';
    }
  }
}

class ProgressArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final LinearGradient progressGradient;
  final List<double> milestones;

  ProgressArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressGradient,
    required this.milestones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = progressGradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ProgressArcPainter oldDelegate) {
    return progress != oldDelegate.progress ||
           strokeWidth != oldDelegate.strokeWidth ||
           backgroundColor != oldDelegate.backgroundColor ||
           progressGradient != oldDelegate.progressGradient;
  }
}

class MilestoneMarkerPainter extends CustomPainter {
  final List<double> milestones;
  final double currentProgress;
  final double size;
  final Color tierColor;

  MilestoneMarkerPainter({
    required this.milestones,
    required this.currentProgress,
    required this.size,
    required this.tierColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size / 2 - 8;

    for (final milestone in milestones) {
      final angle = -math.pi / 2 + (2 * math.pi * milestone);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final isReached = currentProgress >= milestone;
      final paint = Paint()
        ..color = isReached ? tierColor : Colors.grey[400]!
        ..style = PaintingStyle.fill;

      // Draw milestone marker
      canvas.drawCircle(
        Offset(x, y),
        isReached ? 4 : 3,
        paint,
      );

      // Add border for reached milestones
      if (isReached) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawCircle(Offset(x, y), 4, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(MilestoneMarkerPainter oldDelegate) {
    return currentProgress != oldDelegate.currentProgress ||
           tierColor != oldDelegate.tierColor;
  }
}