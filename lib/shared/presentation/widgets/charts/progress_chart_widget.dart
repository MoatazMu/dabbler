/// Circular progress chart widget with advanced features for profile completion
library;
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Progress ring data model
class ProgressRing {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color? backgroundColor;
  final double strokeWidth;
  final String label;
  final String? description;
  final IconData? icon;
  final Gradient? gradient;
  
  const ProgressRing({
    required this.progress,
    required this.color,
    this.backgroundColor,
    this.strokeWidth = 8.0,
    required this.label,
    this.description,
    this.icon,
    this.gradient,
  });
  
  ProgressRing copyWith({
    double? progress,
    Color? color,
    Color? backgroundColor,
    double? strokeWidth,
    String? label,
    String? description,
    IconData? icon,
    Gradient? gradient,
  }) {
    return ProgressRing(
      progress: progress ?? this.progress,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      label: label ?? this.label,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      gradient: gradient ?? this.gradient,
    );
  }
}

/// Progress breakdown for detailed view
class ProgressBreakdown {
  final String title;
  final List<ProgressItem> items;
  
  const ProgressBreakdown({
    required this.title,
    required this.items,
  });
}

class ProgressItem {
  final String label;
  final double progress;
  final Color color;
  final bool isComplete;
  
  const ProgressItem({
    required this.label,
    required this.progress,
    required this.color,
    this.isComplete = false,
  });
}

/// Circular progress chart widget with multiple rings and animations
class ProgressChartWidget extends StatefulWidget {
  final List<ProgressRing> rings;
  final double size;
  final Widget? centerChild;
  final String? centerText;
  final TextStyle? centerTextStyle;
  final IconData? centerIcon;
  final Color? centerIconColor;
  final double? centerIconSize;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback? onTap;
  final ProgressBreakdown? breakdown;
  final bool showPercentage;
  final bool enableGlow;
  final double glowRadius;
  final Color? glowColor;
  final bool animateOnMount;
  final String? semanticLabel;
  final bool enableHapticFeedback;
  
  const ProgressChartWidget({
    super.key,
    required this.rings,
    this.size = 200.0,
    this.centerChild,
    this.centerText,
    this.centerTextStyle,
    this.centerIcon,
    this.centerIconColor,
    this.centerIconSize,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.animationCurve = Curves.easeOutCubic,
    this.onTap,
    this.breakdown,
    this.showPercentage = true,
    this.enableGlow = false,
    this.glowRadius = 10.0,
    this.glowColor,
    this.animateOnMount = true,
    this.semanticLabel,
    this.enableHapticFeedback = true,
  });
  
  @override
  State<ProgressChartWidget> createState() => _ProgressChartWidgetState();
}

class _ProgressChartWidgetState extends State<ProgressChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _animation;
  late Animation<double> _glowAnimation;
  late List<Animation<double>> _ringAnimations;
  
  bool _showBreakdown = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    if (widget.animateOnMount) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Create staggered animations for each ring
    _ringAnimations = List.generate(widget.rings.length, (index) {
      final delay = index * 0.2;
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          delay,
          math.min(1.0, delay + 0.8),
          curve: widget.animationCurve,
        ),
      ));
    });
    
    if (widget.enableGlow) {
      _glowController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(ProgressChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.rings != oldWidget.rings) {
      _animationController.reset();
      _setupAnimations();
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? _getDefaultSemanticLabel(),
      child: GestureDetector(
        onTap: _handleTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress rings
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ProgressChartPainter(
                      rings: widget.rings,
                      ringAnimations: _ringAnimations,
                      enableGlow: widget.enableGlow,
                      glowRadius: widget.glowRadius,
                      glowColor: widget.glowColor ?? Theme.of(context).primaryColor,
                      glowAnimation: _glowAnimation,
                    ),
                  );
                },
              ),
              
              // Center content
              _buildCenterContent(),
              
              // Breakdown overlay
              if (_showBreakdown && widget.breakdown != null)
                _buildBreakdownOverlay(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCenterContent() {
    if (widget.centerChild != null) {
      return widget.centerChild!;
    }
    
    final primaryRing = widget.rings.isNotEmpty ? widget.rings.first : null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.centerIcon != null) ...[
          Icon(
            widget.centerIcon,
            size: widget.centerIconSize ?? 32,
            color: widget.centerIconColor ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 4),
        ],
        
        if (widget.centerText != null)
          Text(
            widget.centerText!,
            style: widget.centerTextStyle ?? 
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          )
        else if (widget.showPercentage && primaryRing != null)
          AnimatedBuilder(
            animation: _ringAnimations.isNotEmpty ? _ringAnimations.first : _animation,
            builder: (context, child) {
              final progress = primaryRing.progress * 
                  (_ringAnimations.isNotEmpty ? _ringAnimations.first.value : 1.0);
              return Text(
                '${(progress * 100).toInt()}%',
                style: widget.centerTextStyle ?? 
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryRing.color,
                    ),
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildBreakdownOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.breakdown!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: ListView.separated(
                  itemCount: widget.breakdown!.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = widget.breakdown!.items[index];
                    return _buildBreakdownItem(item);
                  },
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                'Tap to close',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBreakdownItem(ProgressItem item) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        
        if (item.isComplete)
          const Icon(
            Icons.check,
            color: Colors.green,
            size: 12,
          )
        else
          Text(
            '${(item.progress * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
      ],
    );
  }
  
  void _handleTap() {
    if (widget.enableHapticFeedback) {
      // HapticFeedback.lightImpact();
    }
    
    if (widget.breakdown != null) {
      setState(() {
        _showBreakdown = !_showBreakdown;
      });
    }
    
    widget.onTap?.call();
  }
  
  String _getDefaultSemanticLabel() {
    if (widget.rings.isEmpty) return 'Progress chart';
    
    final primaryRing = widget.rings.first;
    final percentage = (primaryRing.progress * 100).toInt();
    
    return '${primaryRing.label}: $percentage% complete';
  }
}

/// Custom painter for drawing progress rings
class _ProgressChartPainter extends CustomPainter {
  final List<ProgressRing> rings;
  final List<Animation<double>> ringAnimations;
  final bool enableGlow;
  final double glowRadius;
  final Color glowColor;
  final Animation<double> glowAnimation;
  
  _ProgressChartPainter({
    required this.rings,
    required this.ringAnimations,
    this.enableGlow = false,
    this.glowRadius = 10.0,
    required this.glowColor,
    required this.glowAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 20;
    
    for (int i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final animation = ringAnimations.length > i ? ringAnimations[i] : null;
      final ringRadius = baseRadius - (i * (ring.strokeWidth + 8));
      
      _drawRing(
        canvas,
        center,
        ringRadius,
        ring,
        animation?.value ?? 1.0,
      );
    }
  }
  
  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    ProgressRing ring,
    double animationValue,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * ring.progress * animationValue;
    
    // Draw background circle
    if (ring.backgroundColor != null) {
      final backgroundPaint = Paint()
        ..color = ring.backgroundColor!
        ..strokeWidth = ring.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawCircle(center, radius, backgroundPaint);
    }
    
    // Draw glow effect
    if (enableGlow && ring.progress > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(0.3 * glowAnimation.value)
        ..strokeWidth = ring.strokeWidth + glowRadius
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius / 2);
      
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    }
    
    // Draw progress arc
    if (ring.progress > 0 && animationValue > 0) {
      final progressPaint = Paint()
        ..strokeWidth = ring.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      if (ring.gradient != null) {
        // Apply gradient
        final gradientRect = Rect.fromCircle(center: center, radius: radius);
        progressPaint.shader = ring.gradient!.createShader(gradientRect);
      } else {
        progressPaint.color = ring.color;
      }
      
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return rings != oldDelegate.rings ||
           enableGlow != oldDelegate.enableGlow ||
           glowRadius != oldDelegate.glowRadius ||
           glowColor != oldDelegate.glowColor;
  }
}

/// Extension methods for easy ProgressRing creation
extension ProgressRingExtensions on ProgressRing {
  /// Create a ring with gradient colors
  static ProgressRing withGradient({
    required double progress,
    required List<Color> colors,
    List<double>? stops,
    double strokeWidth = 8.0,
    required String label,
    String? description,
    IconData? icon,
    Color? backgroundColor,
  }) {
    return ProgressRing(
      progress: progress,
      color: colors.first,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      label: label,
      description: description,
      icon: icon,
      gradient: LinearGradient(
        colors: colors,
        stops: stops,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
  
  /// Create a ring with success/warning/error styling
  static ProgressRing withStatus({
    required double progress,
    required String label,
    String? description,
    IconData? icon,
    ProgressStatus status = ProgressStatus.normal,
    double strokeWidth = 8.0,
  }) {
    Color color;
    Color backgroundColor;
    
    switch (status) {
      case ProgressStatus.success:
        color = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.2);
        break;
      case ProgressStatus.warning:
        color = Colors.orange;
        backgroundColor = Colors.orange.withOpacity(0.2);
        break;
      case ProgressStatus.error:
        color = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.2);
        break;
      case ProgressStatus.normal:
        color = Colors.blue;
        backgroundColor = Colors.blue.withOpacity(0.2);
        break;
    }
    
    return ProgressRing(
      progress: progress,
      color: color,
      backgroundColor: backgroundColor,
      strokeWidth: strokeWidth,
      label: label,
      description: description,
      icon: icon,
    );
  }
}

enum ProgressStatus {
  normal,
  success,
  warning,
  error,
}

/// Predefined progress chart configurations
class ProgressChartPresets {
  /// Profile completion chart with multiple metrics
  static ProgressChartWidget profileCompletion({
    required double personalInfo,
    required double sportsProfile,
    required double preferences,
    required double verification,
    VoidCallback? onTap,
  }) {
    return ProgressChartWidget(
      rings: [
        ProgressRing(
          progress: (personalInfo + sportsProfile + preferences + verification) / 4,
          color: Colors.blue,
          backgroundColor: Colors.blue.withOpacity(0.1),
          strokeWidth: 12,
          label: 'Overall Progress',
        ),
        ProgressRing(
          progress: personalInfo,
          color: Colors.green,
          backgroundColor: Colors.green.withOpacity(0.1),
          strokeWidth: 8,
          label: 'Personal Info',
        ),
        ProgressRing(
          progress: sportsProfile,
          color: Colors.orange,
          backgroundColor: Colors.orange.withOpacity(0.1),
          strokeWidth: 8,
          label: 'Sports Profile',
        ),
        ProgressRing(
          progress: preferences,
          color: Colors.purple,
          backgroundColor: Colors.purple.withOpacity(0.1),
          strokeWidth: 6,
          label: 'Preferences',
        ),
      ],
      centerIcon: Icons.person,
      breakdown: ProgressBreakdown(
        title: 'Profile Completion',
        items: [
          ProgressItem(
            label: 'Personal Information',
            progress: personalInfo,
            color: Colors.green,
            isComplete: personalInfo >= 1.0,
          ),
          ProgressItem(
            label: 'Sports Profile',
            progress: sportsProfile,
            color: Colors.orange,
            isComplete: sportsProfile >= 1.0,
          ),
          ProgressItem(
            label: 'Preferences',
            progress: preferences,
            color: Colors.purple,
            isComplete: preferences >= 1.0,
          ),
          ProgressItem(
            label: 'Verification',
            progress: verification,
            color: Colors.red,
            isComplete: verification >= 1.0,
          ),
        ],
      ),
      onTap: onTap,
      enableGlow: true,
    );
  }
  
  /// Single metric with animated progress
  static ProgressChartWidget singleMetric({
    required double progress,
    required String label,
    required Color color,
    IconData? icon,
    VoidCallback? onTap,
    bool enableGlow = false,
  }) {
    return ProgressChartWidget(
      rings: [
        ProgressRingExtensions.withGradient(
          progress: progress,
          colors: [color, color.withOpacity(0.6)],
          label: label,
          strokeWidth: 16,
        ),
      ],
      centerIcon: icon,
      centerText: label,
      onTap: onTap,
      enableGlow: enableGlow,
    );
  }
  
  /// Skill level progress with color coding
  static ProgressChartWidget skillLevel({
    required double skillLevel, // 0.0 to 1.0 (representing 1-5 or 1-10 scale)
    required String sportName,
    VoidCallback? onTap,
  }) {
    Color color;
    if (skillLevel < 0.2) {
      color = Colors.red;
    } else if (skillLevel < 0.4) {
      color = Colors.orange;
    } else if (skillLevel < 0.6) {
      color = Colors.yellow[700]!;
    } else if (skillLevel < 0.8) {
      color = Colors.lightGreen;
    } else {
      color = Colors.green;
    }
    
    return ProgressChartWidget(
      rings: [
        ProgressRingExtensions.withGradient(
          progress: skillLevel,
          colors: [color, color.withOpacity(0.7)],
          label: '$sportName Skill',
          strokeWidth: 14,
        ),
      ],
      centerIcon: Icons.sports,
      centerText: sportName,
      onTap: onTap,
      enableGlow: skillLevel > 0.8,
    );
  }
}
