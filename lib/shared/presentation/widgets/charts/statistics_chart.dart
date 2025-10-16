/// Statistics chart widget with bar, line, and pie chart support
library;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Chart types
enum ChartType {
  bar,
  line,
  pie,
}

/// Data point for charts
class ChartDataPoint {
  final String label;
  final double value;
  final Color? color;
  final Map<String, dynamic>? metadata;
  
  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.metadata,
  });
}

/// Chart series for multiple data sets
class ChartSeries {
  final String name;
  final List<ChartDataPoint> data;
  final Color color;
  final bool isVisible;
  final double strokeWidth;
  final bool showPoints;
  
  const ChartSeries({
    required this.name,
    required this.data,
    required this.color,
    this.isVisible = true,
    this.strokeWidth = 2.0,
    this.showPoints = true,
  });
  
  ChartSeries copyWith({
    String? name,
    List<ChartDataPoint>? data,
    Color? color,
    bool? isVisible,
    double? strokeWidth,
    bool? showPoints,
  }) {
    return ChartSeries(
      name: name ?? this.name,
      data: data ?? this.data,
      color: color ?? this.color,
      isVisible: isVisible ?? this.isVisible,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      showPoints: showPoints ?? this.showPoints,
    );
  }
}

/// Tooltip data
class TooltipData {
  final Offset position;
  final ChartDataPoint dataPoint;
  final String seriesName;
  final Color seriesColor;
  
  const TooltipData({
    required this.position,
    required this.dataPoint,
    required this.seriesName,
    required this.seriesColor,
  });
}

/// Legend configuration
class LegendConfig {
  final bool show;
  final LegendPosition position;
  final bool toggleable;
  final TextStyle? textStyle;
  final double iconSize;
  final EdgeInsets padding;
  
  const LegendConfig({
    this.show = true,
    this.position = LegendPosition.bottom,
    this.toggleable = true,
    this.textStyle,
    this.iconSize = 12,
    this.padding = const EdgeInsets.all(8),
  });
}

enum LegendPosition {
  top,
  bottom,
  left,
  right,
}

/// Advanced statistics chart widget
class StatisticsChart extends StatefulWidget {
  final ChartType chartType;
  final List<ChartSeries> series;
  final String? title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final LegendConfig? legendConfig;
  final bool enableTooltips;
  final bool enableZoom;
  final bool enablePan;
  final double? minValue;
  final double? maxValue;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback? onExport;
  final Function(TooltipData)? onTooltip;
  final Function(ChartSeries, bool)? onSeriesToggle;
  final Color backgroundColor;
  final Color gridColor;
  final bool showGrid;
  final EdgeInsets padding;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final GlobalKey? chartKey;
  
  const StatisticsChart({
    super.key,
    required this.chartType,
    required this.series,
    this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.legendConfig,
    this.enableTooltips = true,
    this.enableZoom = false,
    this.enablePan = false,
    this.minValue,
    this.maxValue,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.animationCurve = Curves.easeOutCubic,
    this.onExport,
    this.onTooltip,
    this.onSeriesToggle,
    this.backgroundColor = Colors.transparent,
    this.gridColor = Colors.grey,
    this.showGrid = true,
    this.padding = const EdgeInsets.all(16),
    this.xAxisLabel,
    this.yAxisLabel,
    this.chartKey,
  });
  
  @override
  State<StatisticsChart> createState() => _StatisticsChartState();
}

class _StatisticsChartState extends State<StatisticsChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  List<ChartSeries> _visibleSeries = [];
  TooltipData? _tooltipData;
  Offset? _tapPosition;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  
  @override
  void initState() {
    super.initState();
    _visibleSeries = List.from(widget.series);
    _setupAnimation();
    _animationController.forward();
  }
  
  void _setupAnimation() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
  }
  
  @override
  void didUpdateWidget(StatisticsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.series != oldWidget.series) {
      _visibleSeries = List.from(widget.series);
      _animationController.reset();
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || widget.subtitle != null || widget.onExport != null)
            _buildHeader(),
          
          if (widget.legendConfig?.show == true && 
              widget.legendConfig?.position == LegendPosition.top)
            _buildLegend(),
          
          Expanded(
            child: Row(
              children: [
                if (widget.legendConfig?.show == true && 
                    widget.legendConfig?.position == LegendPosition.left)
                  _buildLegend(),
                
                Expanded(child: _buildChart()),
                
                if (widget.legendConfig?.show == true && 
                    widget.legendConfig?.position == LegendPosition.right)
                  _buildLegend(),
              ],
            ),
          ),
          
          if (widget.legendConfig?.show == true && 
              widget.legendConfig?.position == LegendPosition.bottom)
            _buildLegend(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: widget.titleStyle ?? 
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    style: widget.subtitleStyle ?? 
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ],
            ),
          ),
          
          if (widget.onExport != null)
            IconButton(
              onPressed: _exportChart,
              icon: const Icon(Icons.download),
              tooltip: 'Export Chart',
            ),
        ],
      ),
    );
  }
  
  Widget _buildLegend() {
    final config = widget.legendConfig!;
    final isHorizontal = config.position == LegendPosition.top || 
                        config.position == LegendPosition.bottom;
    
    return Container(
      padding: config.padding,
      child: Wrap(
        direction: isHorizontal ? Axis.horizontal : Axis.vertical,
        spacing: 8,
        runSpacing: 4,
        children: widget.series.map((series) {
          final isVisible = _visibleSeries.any((s) => s.name == series.name);
          
          return GestureDetector(
            onTap: config.toggleable ? () => _toggleSeries(series) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isVisible ? Colors.transparent : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: config.iconSize,
                    height: config.iconSize,
                    decoration: BoxDecoration(
                      color: isVisible ? series.color : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  
                  Text(
                    series.name,
                    style: config.textStyle ?? 
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isVisible ? null : Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildChart() {
    Widget chart = RepaintBoundary(
      key: widget.chartKey ?? _repaintBoundaryKey,
      child: GestureDetector(
        onTapDown: widget.enableTooltips ? _handleTapDown : null,
        onTap: widget.enableTooltips ? _handleTap : null,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: _getChartPainter(),
              child: Container(),
            );
          },
        ),
      ),
    );
    
    if (widget.enableZoom || widget.enablePan) {
      chart = InteractiveViewer(
        panEnabled: widget.enablePan,
        scaleEnabled: widget.enableZoom,
        minScale: 0.5,
        maxScale: 3.0,
        child: chart,
      );
    }
    
    return Stack(
      children: [
        chart,
        if (_tooltipData != null) _buildTooltip(),
      ],
    );
  }
  
  CustomPainter _getChartPainter() {
    switch (widget.chartType) {
      case ChartType.bar:
        return _BarChartPainter(
          series: _visibleSeries,
          animation: _animation,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
          showGrid: widget.showGrid,
          gridColor: widget.gridColor,
        );
      case ChartType.line:
        return _LineChartPainter(
          series: _visibleSeries,
          animation: _animation,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
          showGrid: widget.showGrid,
          gridColor: widget.gridColor,
        );
      case ChartType.pie:
        return _PieChartPainter(
          series: _visibleSeries,
          animation: _animation,
        );
    }
  }
  
  Widget _buildTooltip() {
    return Positioned(
      left: _tooltipData!.position.dx,
      top: _tooltipData!.position.dy,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tooltipData!.seriesName,
              style: TextStyle(
                color: _tooltipData!.seriesColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              '${_tooltipData!.dataPoint.label}: ${_tooltipData!.dataPoint.value.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleTapDown(TapDownDetails details) {
    _tapPosition = details.localPosition;
  }
  
  void _handleTap() {
    if (_tapPosition == null) return;
    
    // Find data point at tap position
    final tooltipData = _findDataPointAt(_tapPosition!);
    
    setState(() {
      _tooltipData = tooltipData;
    });
    
    if (tooltipData != null) {
      widget.onTooltip?.call(tooltipData);
      
      // Hide tooltip after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _tooltipData = null;
          });
        }
      });
    }
  }
  
  TooltipData? _findDataPointAt(Offset position) {
    // This would need to be implemented based on chart type and layout
    // For now, return null
    return null;
  }
  
  void _toggleSeries(ChartSeries series) {
    setState(() {
      final index = _visibleSeries.indexWhere((s) => s.name == series.name);
      if (index >= 0) {
        _visibleSeries.removeAt(index);
        widget.onSeriesToggle?.call(series, false);
      } else {
        _visibleSeries.add(series);
        widget.onSeriesToggle?.call(series, true);
      }
    });
    
    _animationController.reset();
    _animationController.forward();
  }
  
  Future<void> _exportChart() async {
    try {
      final boundary = (widget.chartKey ?? _repaintBoundaryKey).currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      
      // Use the bytes to avoid unused variable warnings and aid debugging
      debugPrint('Exported chart size: \'${pngBytes.length}\' bytes');
      
      // In a real app, you would save the file or share it
      // For now, just call the callback
      widget.onExport?.call();
      
    } catch (e) {
      // Handle export error
      debugPrint('Failed to export chart: $e');
    }
  }
}

/// Bar chart painter
class _BarChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final Animation<double> animation;
  final double? minValue;
  final double? maxValue;
  final bool showGrid;
  final Color gridColor;
  
  _BarChartPainter({
    required this.series,
    required this.animation,
    this.minValue,
    this.maxValue,
    required this.showGrid,
    required this.gridColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    
    final padding = 40.0;
    final chartArea = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    
    // Calculate value range
    double minVal = minValue ?? 0;
    double maxVal = maxValue ?? _getMaxValue();
    
    if (minVal == maxVal) maxVal = minVal + 1;
    
    // Draw grid
    if (showGrid) {
      _drawGrid(canvas, chartArea, minVal, maxVal);
    }
    
    // Draw bars
    _drawBars(canvas, chartArea, minVal, maxVal);
    
    // Draw axes
    _drawAxes(canvas, chartArea);
  }
  
  void _drawGrid(Canvas canvas, Rect area, double minVal, double maxVal) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1;
    
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = area.bottom - (area.height * i / gridLines);
      canvas.drawLine(
        Offset(area.left, y),
        Offset(area.right, y),
        gridPaint,
      );
    }
  }
  
  void _drawBars(Canvas canvas, Rect area, double minVal, double maxVal) {
    if (series.isEmpty || series.first.data.isEmpty) return;
    
    final barCount = series.first.data.length;
    final seriesCount = series.length;
    final barGroupWidth = area.width / barCount;
    final barWidth = barGroupWidth / seriesCount * 0.8;
    final spacing = barGroupWidth / seriesCount * 0.2;
    
    for (int seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final currentSeries = series[seriesIndex];
      
      for (int dataIndex = 0; dataIndex < currentSeries.data.length; dataIndex++) {
        final dataPoint = currentSeries.data[dataIndex];
        final normalizedValue = (dataPoint.value - minVal) / (maxVal - minVal);
        final barHeight = area.height * normalizedValue * animation.value;
        
        final x = area.left + 
                 dataIndex * barGroupWidth + 
                 seriesIndex * (barWidth + spacing) + 
                 spacing / 2;
        
        final barRect = Rect.fromLTWH(
          x,
          area.bottom - barHeight,
          barWidth,
          barHeight,
        );
        
        final barPaint = Paint()
          ..color = dataPoint.color ?? currentSeries.color
          ..style = PaintingStyle.fill;
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
          barPaint,
        );
      }
    }
  }
  
  void _drawAxes(Canvas canvas, Rect area) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    
    // X-axis
    canvas.drawLine(
      Offset(area.left, area.bottom),
      Offset(area.right, area.bottom),
      axisPaint,
    );
    
    // Y-axis
    canvas.drawLine(
      Offset(area.left, area.top),
      Offset(area.left, area.bottom),
      axisPaint,
    );
  }
  
  double _getMaxValue() {
    double max = 0;
    for (final series in series) {
      for (final point in series.data) {
        if (point.value > max) max = point.value;
      }
    }
    return max;
  }
  
  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return series != oldDelegate.series || animation != oldDelegate.animation;
  }
}

/// Line chart painter
class _LineChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final Animation<double> animation;
  final double? minValue;
  final double? maxValue;
  final bool showGrid;
  final Color gridColor;
  
  _LineChartPainter({
    required this.series,
    required this.animation,
    this.minValue,
    this.maxValue,
    required this.showGrid,
    required this.gridColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    
    final padding = 40.0;
    final chartArea = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    
    // Calculate value range
    double minVal = minValue ?? _getMinValue();
    double maxVal = maxValue ?? _getMaxValue();
    
    if (minVal == maxVal) maxVal = minVal + 1;
    
    // Draw grid
    if (showGrid) {
      _drawGrid(canvas, chartArea, minVal, maxVal);
    }
    
    // Draw lines
    _drawLines(canvas, chartArea, minVal, maxVal);
    
    // Draw axes
    _drawAxes(canvas, chartArea);
  }
  
  void _drawGrid(Canvas canvas, Rect area, double minVal, double maxVal) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1;
    
    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = area.bottom - (area.height * i / gridLines);
      canvas.drawLine(
        Offset(area.left, y),
        Offset(area.right, y),
        gridPaint,
      );
    }
  }
  
  void _drawLines(Canvas canvas, Rect area, double minVal, double maxVal) {
    for (final currentSeries in series) {
      if (currentSeries.data.isEmpty) continue;
      
      final linePaint = Paint()
        ..color = currentSeries.color
        ..strokeWidth = currentSeries.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      final path = Path();
      final points = <Offset>[];
      
      for (int i = 0; i < currentSeries.data.length; i++) {
        final dataPoint = currentSeries.data[i];
        final x = area.left + (area.width * i / (currentSeries.data.length - 1));
        final normalizedValue = (dataPoint.value - minVal) / (maxVal - minVal);
        final y = area.bottom - (area.height * normalizedValue);
        
        final point = Offset(x, y);
        points.add(point);
        
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      
      // Animate path drawing
      final animatedPath = _createAnimatedPath(path, animation.value);
      canvas.drawPath(animatedPath, linePaint);
      
      // Draw points if enabled
      if (currentSeries.showPoints) {
        final pointPaint = Paint()
          ..color = currentSeries.color
          ..style = PaintingStyle.fill;
        
        for (int i = 0; i < (points.length * animation.value).round(); i++) {
          canvas.drawCircle(points[i], 4, pointPaint);
        }
      }
    }
  }
  
  Path _createAnimatedPath(Path originalPath, double progress) {
    final pathMetrics = originalPath.computeMetrics().toList();
    final animatedPath = Path();
    
    for (final pathMetric in pathMetrics) {
      final extractPath = pathMetric.extractPath(
        0,
        pathMetric.length * progress,
      );
      animatedPath.addPath(extractPath, Offset.zero);
    }
    
    return animatedPath;
  }
  
  void _drawAxes(Canvas canvas, Rect area) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    
    // X-axis
    canvas.drawLine(
      Offset(area.left, area.bottom),
      Offset(area.right, area.bottom),
      axisPaint,
    );
    
    // Y-axis
    canvas.drawLine(
      Offset(area.left, area.top),
      Offset(area.left, area.bottom),
      axisPaint,
    );
  }
  
  double _getMinValue() {
    double min = double.infinity;
    for (final series in series) {
      for (final point in series.data) {
        if (point.value < min) min = point.value;
      }
    }
    return min == double.infinity ? 0 : min;
  }
  
  double _getMaxValue() {
    double max = double.negativeInfinity;
    for (final series in series) {
      for (final point in series.data) {
        if (point.value > max) max = point.value;
      }
    }
    return max == double.negativeInfinity ? 1 : max;
  }
  
  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return series != oldDelegate.series || animation != oldDelegate.animation;
  }
}

/// Pie chart painter
class _PieChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final Animation<double> animation;
  
  _PieChartPainter({
    required this.series,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    
    // Calculate total value
    double totalValue = 0;
    for (final series in series) {
      for (final point in series.data) {
        totalValue += point.value;
      }
    }
    
    if (totalValue == 0) return;
    
    double startAngle = -math.pi / 2; // Start from top
    
    for (final currentSeries in series) {
      for (final dataPoint in currentSeries.data) {
        final sweepAngle = (2 * math.pi * dataPoint.value / totalValue) * animation.value;
        
        final paint = Paint()
          ..color = dataPoint.color ?? currentSeries.color
          ..style = PaintingStyle.fill;
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          true,
          paint,
        );
        
        startAngle += sweepAngle;
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return series != oldDelegate.series || animation != oldDelegate.animation;
  }
}

/// Predefined chart configurations
class StatisticsChartPresets {
  /// Sports performance bar chart
  static StatisticsChart sportsPerformance({
    required Map<String, double> sportsData,
    String title = 'Sports Performance',
  }) {
    final dataPoints = sportsData.entries
        .map((entry) => ChartDataPoint(
              label: entry.key,
              value: entry.value,
              color: _getRandomColor(entry.key.hashCode),
            ))
        .toList();
    
    return StatisticsChart(
      chartType: ChartType.bar,
      series: [
        ChartSeries(
          name: 'Performance',
          data: dataPoints,
          color: Colors.blue,
        ),
      ],
      title: title,
      showGrid: true,
      yAxisLabel: 'Score',
      xAxisLabel: 'Sports',
    );
  }
  
  /// Progress over time line chart
  static StatisticsChart progressOverTime({
    required List<ChartDataPoint> progressData,
    String title = 'Progress Over Time',
  }) {
    return StatisticsChart(
      chartType: ChartType.line,
      series: [
        ChartSeries(
          name: 'Progress',
          data: progressData,
          color: Colors.green,
          strokeWidth: 3,
        ),
      ],
      title: title,
      showGrid: true,
      enableZoom: true,
      enablePan: true,
    );
  }
  
  /// Game distribution pie chart
  static StatisticsChart gameDistribution({
    required Map<String, double> gameData,
    String title = 'Game Distribution',
  }) {
    final dataPoints = gameData.entries
        .map((entry) => ChartDataPoint(
              label: entry.key,
              value: entry.value,
              color: _getRandomColor(entry.key.hashCode),
            ))
        .toList();
    
    return StatisticsChart(
      chartType: ChartType.pie,
      series: [
        ChartSeries(
          name: 'Games',
          data: dataPoints,
          color: Colors.blue,
        ),
      ],
      title: title,
      legendConfig: const LegendConfig(
        position: LegendPosition.right,
        toggleable: false,
      ),
    );
  }
  
  static Color _getRandomColor(int seed) {
    final random = math.Random(seed);
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1,
    );
  }
}
