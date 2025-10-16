/// Skill radar chart widget for multi-sport skill visualization
library;
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Skill data point for radar chart
class SkillDataPoint {
  final String skillName;
  final double value;
  final double maxValue;
  final Color? color;
  final IconData? icon;
  
  const SkillDataPoint({
    required this.skillName,
    required this.value,
    required this.maxValue,
    this.color,
    this.icon,
  });
  
  double get normalizedValue => maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
  
  SkillDataPoint copyWith({
    String? skillName,
    double? value,
    double? maxValue,
    Color? color,
    IconData? icon,
  }) {
    return SkillDataPoint(
      skillName: skillName ?? this.skillName,
      value: value ?? this.value,
      maxValue: maxValue ?? this.maxValue,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

/// Skill set for radar chart (represents one player/entity)
class SkillSet {
  final String name;
  final List<SkillDataPoint> skills;
  final Color color;
  final double opacity;
  final bool isVisible;
  final double strokeWidth;
  final bool filled;
  
  const SkillSet({
    required this.name,
    required this.skills,
    required this.color,
    this.opacity = 0.3,
    this.isVisible = true,
    this.strokeWidth = 2.0,
    this.filled = true,
  });
  
  SkillSet copyWith({
    String? name,
    List<SkillDataPoint>? skills,
    Color? color,
    double? opacity,
    bool? isVisible,
    double? strokeWidth,
    bool? filled,
  }) {
    return SkillSet(
      name: name ?? this.name,
      skills: skills ?? this.skills,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      filled: filled ?? this.filled,
    );
  }
}

/// Scale configuration for radar chart
class RadarScale {
  final double minValue;
  final double maxValue;
  final int numberOfRings;
  final bool showLabels;
  final Color ringColor;
  final double ringStrokeWidth;
  final List<String>? customLabels;
  
  const RadarScale({
    this.minValue = 0.0,
    this.maxValue = 10.0,
    this.numberOfRings = 5,
    this.showLabels = true,
    this.ringColor = Colors.grey,
    this.ringStrokeWidth = 1.0,
    this.customLabels,
  });
  
  List<String> get scaleLabels {
    if (customLabels != null) return customLabels!;
    
    final labels = <String>[];
    final step = (maxValue - minValue) / numberOfRings;
    
    for (int i = 0; i <= numberOfRings; i++) {
      final value = minValue + (step * i);
      labels.add(value.toStringAsFixed(value == value.toInt() ? 0 : 1));
    }
    
    return labels;
  }
}

/// Interactive point data for touch interactions
class InteractivePoint {
  final Offset position;
  final SkillDataPoint skillData;
  final SkillSet skillSet;
  final double distance;
  
  const InteractivePoint({
    required this.position,
    required this.skillData,
    required this.skillSet,
    required this.distance,
  });
}

/// Advanced skill radar chart widget
class SkillRadarChart extends StatefulWidget {
  final List<SkillSet> skillSets;
  final RadarScale scale;
  final double size;
  final bool enableComparison;
  final bool enableInteraction;
  final Function(InteractivePoint)? onPointTap;
  final Function(SkillSet, SkillDataPoint)? onSkillTap;
  final Duration animationDuration;
  final Curve animationCurve;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color backgroundColor;
  final EdgeInsets padding;
  final bool showSkillIcons;
  final double iconSize;
  final bool animateOnMount;
  final String? title;
  final TextStyle? titleStyle;
  final Widget? centerWidget;
  final bool showCenterPoint;
  final double centerPointRadius;
  final Color? centerPointColor;
  
  const SkillRadarChart({
    super.key,
    required this.skillSets,
    this.scale = const RadarScale(),
    this.size = 300.0,
    this.enableComparison = true,
    this.enableInteraction = true,
    this.onPointTap,
    this.onSkillTap,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationCurve = Curves.easeOutCubic,
    this.labelStyle,
    this.valueStyle,
    this.backgroundColor = Colors.transparent,
    this.padding = const EdgeInsets.all(20),
    this.showSkillIcons = true,
    this.iconSize = 20,
    this.animateOnMount = true,
    this.title,
    this.titleStyle,
    this.centerWidget,
    this.showCenterPoint = true,
    this.centerPointRadius = 4.0,
    this.centerPointColor,
  });
  
  @override
  State<SkillRadarChart> createState() => _SkillRadarChartState();
}

class _SkillRadarChartState extends State<SkillRadarChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;
  
  InteractivePoint? _selectedPoint;
  List<InteractivePoint> _interactivePoints = [];
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    if (widget.animateOnMount) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
    
    _pulseController.repeat(reverse: true);
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void didUpdateWidget(SkillRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.skillSets != oldWidget.skillSets) {
      _animationController.reset();
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size + (widget.title != null ? 40 : 0),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: widget.titleStyle ?? 
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
          ],
          
          Expanded(
            child: GestureDetector(
              onTapDown: widget.enableInteraction ? _handleTapDown : null,
              child: AnimatedBuilder(
                animation: Listenable.merge([_animation, _pulseAnimation]),
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size - widget.padding.horizontal, 
                              widget.size - widget.padding.vertical),
                    painter: _RadarChartPainter(
                      skillSets: widget.skillSets,
                      scale: widget.scale,
                      animation: _animation,
                      pulseAnimation: _pulseAnimation,
                      selectedPoint: _selectedPoint,
                      showCenterPoint: widget.showCenterPoint,
                      centerPointRadius: widget.centerPointRadius,
                      centerPointColor: widget.centerPointColor ?? 
                                       Theme.of(context).primaryColor,
                      onInteractivePointsCalculated: (points) {
                        _interactivePoints = points;
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          if (widget.centerWidget != null) ...[
            const SizedBox(height: 16),
            widget.centerWidget!,
          ],
        ],
      ),
    );
  }
  
  void _handleTapDown(TapDownDetails details) {
    final localPosition = details.localPosition;
    // Find closest interactive point
    InteractivePoint? closestPoint;
    double minDistance = double.infinity;
    
    for (final point in _interactivePoints) {
      final distance = (point.position - localPosition).distance;
      if (distance < 20 && distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }
    
    if (closestPoint != null) {
      setState(() {
        _selectedPoint = _selectedPoint == closestPoint ? null : closestPoint;
      });
      
      widget.onPointTap?.call(closestPoint);
      widget.onSkillTap?.call(closestPoint.skillSet, closestPoint.skillData);
    } else {
      setState(() {
        _selectedPoint = null;
      });
    }
  }
}

/// Custom painter for radar chart
class _RadarChartPainter extends CustomPainter {
  final List<SkillSet> skillSets;
  final RadarScale scale;
  final Animation<double> animation;
  final Animation<double> pulseAnimation;
  final InteractivePoint? selectedPoint;
  final bool showCenterPoint;
  final double centerPointRadius;
  final Color centerPointColor;
  final Function(List<InteractivePoint>) onInteractivePointsCalculated;
  
  _RadarChartPainter({
    required this.skillSets,
    required this.scale,
    required this.animation,
    required this.pulseAnimation,
    this.selectedPoint,
    required this.showCenterPoint,
    required this.centerPointRadius,
    required this.centerPointColor,
    required this.onInteractivePointsCalculated,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (skillSets.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    
    // Get skill names from first skill set (assuming all sets have same skills)
    final skillNames = skillSets.first.skills.map((s) => s.skillName).toList();
    final skillCount = skillNames.length;
    
    if (skillCount == 0) return;
    
    // Draw background rings
    _drawBackgroundRings(canvas, center, radius);
    
    // Draw axis lines and labels
    _drawAxisLines(canvas, center, radius, skillNames);
    
    // Calculate interactive points
    final interactivePoints = <InteractivePoint>[];
    
    // Draw skill sets
    for (final skillSet in skillSets) {
      if (!skillSet.isVisible) continue;
      
      final points = _calculateSkillPoints(skillSet, center, radius, skillCount);
      interactivePoints.addAll(_createInteractivePoints(skillSet, points));
      
      // Draw filled area
      if (skillSet.filled) {
        _drawFilledArea(canvas, points, skillSet);
      }
      
      // Draw outline
      _drawOutline(canvas, points, skillSet);
      
      // Draw skill points
      _drawSkillPoints(canvas, points, skillSet);
    }
    
    // Draw center point
    if (showCenterPoint) {
      _drawCenterPoint(canvas, center);
    }
    
    // Draw selected point highlight
    if (selectedPoint != null) {
      _drawSelectedPointHighlight(canvas, selectedPoint!);
    }
    
    // Update interactive points
    onInteractivePointsCalculated(interactivePoints);
  }
  
  void _drawBackgroundRings(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..color = scale.ringColor.withOpacity(0.3)
      ..strokeWidth = scale.ringStrokeWidth
      ..style = PaintingStyle.stroke;
    
    for (int i = 1; i <= scale.numberOfRings; i++) {
      final ringRadius = radius * (i / scale.numberOfRings);
      canvas.drawCircle(center, ringRadius, ringPaint);
      
      // Draw scale labels
      if (scale.showLabels) {
        final labelValue = scale.minValue + 
                          ((scale.maxValue - scale.minValue) * i / scale.numberOfRings);
        final labelText = labelValue.toStringAsFixed(labelValue == labelValue.toInt() ? 0 : 1);
        
        _drawText(
          canvas,
          labelText,
          Offset(center.dx + ringRadius + 5, center.dy - 8),
          const TextStyle(fontSize: 10, color: Colors.grey),
        );
      }
    }
  }
  
  void _drawAxisLines(Canvas canvas, Offset center, double radius, List<String> skillNames) {
    final axisPaint = Paint()
      ..color = scale.ringColor
      ..strokeWidth = 1;
    
    final skillCount = skillNames.length;
    
    for (int i = 0; i < skillCount; i++) {
      final angle = (2 * math.pi * i / skillCount) - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      // Draw axis line
      canvas.drawLine(center, endPoint, axisPaint);
      
      // Draw skill label
      final labelOffset = Offset(
        center.dx + (radius + 25) * math.cos(angle),
        center.dy + (radius + 25) * math.sin(angle),
      );
      
      _drawText(
        canvas,
        skillNames[i],
        labelOffset,
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        textAlign: _getTextAlign(angle),
      );
    }
  }
  
  List<Offset> _calculateSkillPoints(
    SkillSet skillSet,
    Offset center,
    double radius,
    int skillCount,
  ) {
    final points = <Offset>[];
    
    for (int i = 0; i < skillSet.skills.length; i++) {
      final skill = skillSet.skills[i];
      final angle = (2 * math.pi * i / skillCount) - math.pi / 2;
      final normalizedValue = skill.normalizedValue * animation.value;
      final pointRadius = radius * normalizedValue;
      
      final point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );
      
      points.add(point);
    }
    
    return points;
  }
  
  List<InteractivePoint> _createInteractivePoints(
    SkillSet skillSet,
    List<Offset> points,
  ) {
    final interactivePoints = <InteractivePoint>[];
    
    for (int i = 0; i < points.length && i < skillSet.skills.length; i++) {
      interactivePoints.add(InteractivePoint(
        position: points[i],
        skillData: skillSet.skills[i],
        skillSet: skillSet,
        distance: 0,
      ));
    }
    
    return interactivePoints;
  }
  
  void _drawFilledArea(Canvas canvas, List<Offset> points, SkillSet skillSet) {
    if (points.length < 3) return;
    
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    
    final fillPaint = Paint()
      ..color = skillSet.color.withOpacity(skillSet.opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, fillPaint);
  }
  
  void _drawOutline(Canvas canvas, List<Offset> points, SkillSet skillSet) {
    if (points.length < 2) return;
    
    final outlinePaint = Paint()
      ..color = skillSet.color
      ..strokeWidth = skillSet.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    
    canvas.drawPath(path, outlinePaint);
  }
  
  void _drawSkillPoints(Canvas canvas, List<Offset> points, SkillSet skillSet) {
    final pointPaint = Paint()
      ..color = skillSet.color
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (final point in points) {
      // Draw outer stroke
      canvas.drawCircle(point, 5, strokePaint);
      // Draw inner fill
      canvas.drawCircle(point, 4, pointPaint);
    }
  }
  
  void _drawCenterPoint(Canvas canvas, Offset center) {
    final centerPaint = Paint()
      ..color = centerPointColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = centerPointColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final animatedRadius = centerPointRadius * pulseAnimation.value;
    
    canvas.drawCircle(center, animatedRadius + 2, strokePaint);
    canvas.drawCircle(center, animatedRadius, centerPaint);
  }
  
  void _drawSelectedPointHighlight(Canvas canvas, InteractivePoint point) {
    final highlightPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final animatedRadius = 8 * pulseAnimation.value;
    
    canvas.drawCircle(point.position, animatedRadius + 2, strokePaint);
    canvas.drawCircle(point.position, animatedRadius, highlightPaint);
    
    // Draw value label
    _drawValueLabel(canvas, point);
  }
  
  void _drawValueLabel(Canvas canvas, InteractivePoint point) {
    final labelText = '${point.skillData.skillName}\n${point.skillData.value.toStringAsFixed(1)}';
    
    // Create a background for the label
    final labelPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final labelSize = _measureText(labelText, const TextStyle(fontSize: 12, color: Colors.white));
    final labelRect = Rect.fromCenter(
      center: Offset(point.position.dx, point.position.dy - 30),
      width: labelSize.width + 16,
      height: labelSize.height + 8,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
      labelPaint,
    );
    
    _drawText(
      canvas,
      labelText,
      labelRect.center,
      const TextStyle(fontSize: 12, color: Colors.white),
      textAlign: TextAlign.center,
    );
  }
  
  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    TextAlign textAlign = TextAlign.start,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    
    textPainter.layout();
    
    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, offset);
  }
  
  Size _measureText(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    return textPainter.size;
  }
  
  TextAlign _getTextAlign(double angle) {
    // Adjust text alignment based on angle
    final normalizedAngle = angle % (2 * math.pi);
    
    if (normalizedAngle < math.pi / 4 || normalizedAngle > 7 * math.pi / 4) {
      return TextAlign.left;
    } else if (normalizedAngle > 3 * math.pi / 4 && normalizedAngle < 5 * math.pi / 4) {
      return TextAlign.right;
    } else {
      return TextAlign.center;
    }
  }
  
  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return skillSets != oldDelegate.skillSets ||
           animation != oldDelegate.animation ||
           pulseAnimation != oldDelegate.pulseAnimation ||
           selectedPoint != oldDelegate.selectedPoint;
  }
}

/// Predefined skill radar chart configurations
class SkillRadarPresets {
  /// Multi-sport skill comparison
  static SkillRadarChart multiSportSkills({
    required List<SkillSet> players,
    String? title,
    bool enableComparison = true,
  }) {
    return SkillRadarChart(
      skillSets: players,
      title: title ?? 'Multi-Sport Skills',
      enableComparison: enableComparison,
      scale: const RadarScale(
        minValue: 0,
        maxValue: 10,
        numberOfRings: 5,
      ),
    );
  }
  
  /// Single player comprehensive skill view
  static SkillRadarChart playerSkillProfile({
    required String playerName,
    required Map<String, double> skills,
    Color? playerColor,
  }) {
    final skillPoints = skills.entries
        .map((entry) => SkillDataPoint(
              skillName: entry.key,
              value: entry.value,
              maxValue: 10,
            ))
        .toList();
    
    return SkillRadarChart(
      skillSets: [
        SkillSet(
          name: playerName,
          skills: skillPoints,
          color: playerColor ?? Colors.blue,
        ),
      ],
      title: '$playerName Skills',
      enableComparison: false,
    );
  }
  
  /// Team average vs individual comparison
  static SkillRadarChart teamComparison({
    required SkillSet individual,
    required SkillSet teamAverage,
    String? title,
  }) {
    return SkillRadarChart(
      skillSets: [
        teamAverage.copyWith(
          name: 'Team Average',
          color: Colors.grey,
          opacity: 0.2,
        ),
        individual,
      ],
      title: title ?? 'Individual vs Team',
      enableComparison: true,
      scale: const RadarScale(
        minValue: 0,
        maxValue: 10,
        numberOfRings: 5,
        showLabels: true,
      ),
    );
  }
  
  /// Skill level progression over time
  static SkillRadarChart skillProgression({
    required Map<String, double> previousSkills,
    required Map<String, double> currentSkills,
    String? title,
  }) {
    final previousPoints = previousSkills.entries
        .map((entry) => SkillDataPoint(
              skillName: entry.key,
              value: entry.value,
              maxValue: 10,
            ))
        .toList();
    
    final currentPoints = currentSkills.entries
        .map((entry) => SkillDataPoint(
              skillName: entry.key,
              value: entry.value,
              maxValue: 10,
            ))
        .toList();
    
    return SkillRadarChart(
      skillSets: [
        SkillSet(
          name: 'Previous',
          skills: previousPoints,
          color: Colors.grey,
          opacity: 0.3,
        ),
        SkillSet(
          name: 'Current',
          skills: currentPoints,
          color: Colors.green,
          opacity: 0.5,
        ),
      ],
      title: title ?? 'Skill Progression',
      enableComparison: true,
    );
  }
}

/// Helper extension for skill data
extension SkillDataExtensions on List<SkillDataPoint> {
  /// Calculate average skill level
  double get averageSkill {
    if (isEmpty) return 0;
    final total = fold<double>(0, (sum, skill) => sum + skill.normalizedValue);
    return total / length;
  }
  
  /// Find highest skill
  SkillDataPoint? get highestSkill {
    if (isEmpty) return null;
    return reduce((a, b) => a.normalizedValue > b.normalizedValue ? a : b);
  }
  
  /// Find lowest skill
  SkillDataPoint? get lowestSkill {
    if (isEmpty) return null;
    return reduce((a, b) => a.normalizedValue < b.normalizedValue ? a : b);
  }
  
  /// Get skills above threshold
  List<SkillDataPoint> skillsAbove(double threshold) {
    return where((skill) => skill.normalizedValue > threshold).toList();
  }
  
  /// Get skills below threshold
  List<SkillDataPoint> skillsBelow(double threshold) {
    return where((skill) => skill.normalizedValue < threshold).toList();
  }
}
