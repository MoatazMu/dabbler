/// Custom slider field with advanced features and accessibility
library;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Slider field mode
enum SliderMode {
  /// Single value slider
  single,
  /// Range slider with min/max values
  range,
}

/// Step indicator configuration
class StepConfig {
  final bool showSteps;
  final List<double>? customSteps;
  final bool snapToSteps;
  final Color stepColor;
  final double stepSize;
  
  const StepConfig({
    this.showSteps = false,
    this.customSteps,
    this.snapToSteps = false,
    this.stepColor = Colors.grey,
    this.stepSize = 4.0,
  });
}

/// Tooltip configuration for slider
class SliderTooltipConfig {
  final bool showTooltip;
  final String Function(double)? formatter;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Duration showDuration;
  
  const SliderTooltipConfig({
    this.showTooltip = true,
    this.formatter,
    this.textStyle,
    this.backgroundColor,
    this.showDuration = const Duration(seconds: 2),
  });
  
  String formatValue(double value) {
    return formatter?.call(value) ?? value.toStringAsFixed(1);
  }
}

/// Icon configuration for slider endpoints
class SliderIconConfig {
  final IconData? minIcon;
  final IconData? maxIcon;
  final Color? iconColor;
  final double iconSize;
  final String? minLabel;
  final String? maxLabel;
  
  const SliderIconConfig({
    this.minIcon,
    this.maxIcon,
    this.iconColor,
    this.iconSize = 24.0,
    this.minLabel,
    this.maxLabel,
  });
}

/// Advanced slider field widget
class SliderField extends StatefulWidget {
  final SliderMode mode;
  final double? value;
  final RangeValues? rangeValues;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<RangeValues>? onRangeChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final ValueChanged<RangeValues>? onRangeChangeStart;
  final ValueChanged<RangeValues>? onRangeChangeEnd;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final StepConfig stepConfig;
  final SliderTooltipConfig tooltipConfig;
  final SliderIconConfig iconConfig;
  final EdgeInsets padding;
  final bool showValueLabels;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final bool enableHapticFeedback;
  final List<String>? valueLabels;
  final bool logarithmic;
  
  const SliderField({
    super.key,
    this.mode = SliderMode.single,
    this.value,
    this.rangeValues,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.onChanged,
    this.onRangeChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.onRangeChangeStart,
    this.onRangeChangeEnd,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.stepConfig = const StepConfig(),
    this.tooltipConfig = const SliderTooltipConfig(),
    this.iconConfig = const SliderIconConfig(),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showValueLabels = true,
    this.labelStyle,
    this.valueStyle,
    this.enableHapticFeedback = true,
    this.valueLabels,
    this.logarithmic = false,
  }) : assert(
         mode == SliderMode.single ? value != null : rangeValues != null,
         'Value must be provided for single mode, rangeValues for range mode',
       );
  
  @override
  State<SliderField> createState() => _SliderFieldState();
}

class _SliderFieldState extends State<SliderField>
    with TickerProviderStateMixin {
  late AnimationController _tooltipController;
  OverlayEntry? _tooltipOverlay;
  final GlobalKey _sliderKey = GlobalKey();
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _tooltipController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _tooltipController.dispose();
    _hideTooltip();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      key: _sliderKey,
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: widget.labelStyle ?? 
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          
          _buildSliderRow(),
          
          if (widget.showValueLabels) ...[
            const SizedBox(height: 8),
            _buildValueLabels(),
          ],
          
          if (widget.stepConfig.showSteps) ...[
            const SizedBox(height: 4),
            _buildStepIndicators(),
          ],
          
          if (widget.helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSliderRow() {
    return Row(
      children: [
        if (widget.iconConfig.minIcon != null) ...[
          _buildEndpointIcon(true),
          const SizedBox(width: 8),
        ],
        
        Expanded(child: _buildSlider()),
        
        if (widget.iconConfig.maxIcon != null) ...[
          const SizedBox(width: 8),
          _buildEndpointIcon(false),
        ],
      ],
    );
  }
  
  Widget _buildEndpointIcon(bool isMin) {
    final icon = isMin ? widget.iconConfig.minIcon : widget.iconConfig.maxIcon;
    final label = isMin ? widget.iconConfig.minLabel : widget.iconConfig.maxLabel;
    
    return Column(
      children: [
        Icon(
          icon,
          size: widget.iconConfig.iconSize,
          color: widget.iconConfig.iconColor ?? Theme.of(context).primaryColor,
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
  
  Widget _buildSlider() {
    final theme = Theme.of(context);
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: widget.activeColor ?? theme.primaryColor,
      inactiveTrackColor: widget.inactiveColor ?? theme.primaryColor.withOpacity(0.3),
      thumbColor: widget.thumbColor ?? theme.primaryColor,
      overlayColor: (widget.thumbColor ?? theme.primaryColor).withOpacity(0.2),
      valueIndicatorColor: widget.activeColor ?? theme.primaryColor,
      showValueIndicator: widget.tooltipConfig.showTooltip 
          ? ShowValueIndicator.onDrag 
          : ShowValueIndicator.never,
    );
    
    return SliderTheme(
      data: sliderTheme,
      child: widget.mode == SliderMode.single
          ? _buildSingleSlider()
          : _buildRangeSlider(),
    );
  }
  
  Widget _buildSingleSlider() {
    return Slider(
      value: _normalizeValue(widget.value!),
      min: 0.0,
      max: 1.0,
      divisions: widget.divisions,
      label: widget.tooltipConfig.formatValue(_denormalizeValue(_normalizeValue(widget.value!))),
      onChanged: widget.enabled ? (value) {
        final actualValue = _denormalizeValue(value);
        _handleValueChange(actualValue);
        widget.onChanged?.call(actualValue);
      } : null,
      onChangeStart: widget.onChangeStart != null 
          ? (value) {
              setState(() => _isDragging = true);
              _showTooltip();
              widget.onChangeStart?.call(_denormalizeValue(value));
            }
          : null,
      onChangeEnd: widget.onChangeEnd != null 
          ? (value) {
              setState(() => _isDragging = false);
              _hideTooltipWithDelay();
              widget.onChangeEnd?.call(_denormalizeValue(value));
            }
          : null,
    );
  }
  
  Widget _buildRangeSlider() {
    final normalizedRange = RangeValues(
      _normalizeValue(widget.rangeValues!.start),
      _normalizeValue(widget.rangeValues!.end),
    );
    
    return RangeSlider(
      values: normalizedRange,
      min: 0.0,
      max: 1.0,
      divisions: widget.divisions,
      labels: RangeLabels(
        widget.tooltipConfig.formatValue(_denormalizeValue(normalizedRange.start)),
        widget.tooltipConfig.formatValue(_denormalizeValue(normalizedRange.end)),
      ),
      onChanged: widget.enabled ? (values) {
        final actualValues = RangeValues(
          _denormalizeValue(values.start),
          _denormalizeValue(values.end),
        );
        _handleRangeChange(actualValues);
        widget.onRangeChanged?.call(actualValues);
      } : null,
      onChangeStart: widget.onRangeChangeStart != null 
          ? (values) {
              setState(() => _isDragging = true);
              _showTooltip();
              final actualValues = RangeValues(
                _denormalizeValue(values.start),
                _denormalizeValue(values.end),
              );
              widget.onRangeChangeStart?.call(actualValues);
            }
          : null,
      onChangeEnd: widget.onRangeChangeEnd != null 
          ? (values) {
              setState(() => _isDragging = false);
              _hideTooltipWithDelay();
              final actualValues = RangeValues(
                _denormalizeValue(values.start),
                _denormalizeValue(values.end),
              );
              widget.onRangeChangeEnd?.call(actualValues);
            }
          : null,
    );
  }
  
  Widget _buildValueLabels() {
    if (widget.mode == SliderMode.single) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildValueText(widget.min),
          _buildValueText(widget.value!, isCurrentValue: true),
          _buildValueText(widget.max),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildValueText(widget.min),
          Row(
            children: [
              _buildValueText(widget.rangeValues!.start, isCurrentValue: true),
              const Text(' - '),
              _buildValueText(widget.rangeValues!.end, isCurrentValue: true),
            ],
          ),
          _buildValueText(widget.max),
        ],
      );
    }
  }
  
  Widget _buildValueText(double value, {bool isCurrentValue = false}) {
    String displayValue;
    
    if (widget.valueLabels != null) {
      final index = ((value - widget.min) / (widget.max - widget.min) * (widget.valueLabels!.length - 1)).round();
      displayValue = index < widget.valueLabels!.length ? widget.valueLabels![index] : value.toString();
    } else {
      displayValue = widget.tooltipConfig.formatValue(value);
    }
    
    return Text(
      displayValue,
      style: (widget.valueStyle ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
        fontWeight: isCurrentValue ? FontWeight.bold : null,
        color: isCurrentValue 
            ? widget.activeColor ?? Theme.of(context).primaryColor
            : null,
      ),
    );
  }
  
  Widget _buildStepIndicators() {
    final steps = widget.stepConfig.customSteps ?? _generateSteps();
    
    return SizedBox(
      height: widget.stepConfig.stepSize,
      child: Row(
        children: steps.map((step) {
          _normalizeValue(step); // Calculate normalized step position
          
          return Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Container(
                width: widget.stepConfig.stepSize,
                height: widget.stepConfig.stepSize,
                decoration: BoxDecoration(
                  color: widget.stepConfig.stepColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  List<double> _generateSteps() {
    if (widget.divisions == null) return [];
    
    final steps = <double>[];
    final stepSize = (widget.max - widget.min) / widget.divisions!;
    
    for (int i = 0; i <= widget.divisions!; i++) {
      steps.add(widget.min + (stepSize * i));
    }
    
    return steps;
  }
  
  double _normalizeValue(double value) {
    if (widget.logarithmic) {
      final logMin = widget.min == 0 ? 0.1 : widget.min;
      final logMax = widget.max;
      final logValue = value == 0 ? 0.1 : value;
      
      return (math.log(logValue) - math.log(logMin)) / (math.log(logMax) - math.log(logMin));
    }
    
    return (value - widget.min) / (widget.max - widget.min);
  }
  
  double _denormalizeValue(double normalizedValue) {
    if (widget.logarithmic) {
      final logMin = widget.min == 0 ? 0.1 : widget.min;
      final logMax = widget.max;
      
      final logValue = math.log(logMin) + normalizedValue * (math.log(logMax) - math.log(logMin));
      return math.exp(logValue);
    }
    
    return widget.min + normalizedValue * (widget.max - widget.min);
  }
  
  void _handleValueChange(double value) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    if (widget.stepConfig.snapToSteps && widget.divisions != null) {
      final stepSize = (widget.max - widget.min) / widget.divisions!;
      // Calculate snapped value
      ((value - widget.min) / stepSize).round() * stepSize + widget.min;
      // Update with snapped value if different
    }
  }
  
  void _handleRangeChange(RangeValues values) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }
  
  void _showTooltip() {
    if (!widget.tooltipConfig.showTooltip || _tooltipOverlay != null) return;
    
    _tooltipController.forward();
  }
  
  void _hideTooltip() {
    _tooltipController.reverse().then((_) {
      _tooltipOverlay?.remove();
      _tooltipOverlay = null;
    });
  }
  
  void _hideTooltipWithDelay() {
    Future.delayed(widget.tooltipConfig.showDuration, () {
      if (!_isDragging) {
        _hideTooltip();
      }
    });
  }
}

/// Extension methods for easy SliderField creation
extension SliderFieldExtensions on SliderField {
  /// Create a simple slider
  static SliderField simple({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 100.0,
    String? label,
    int? divisions,
  }) {
    return SliderField(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      label: label,
      divisions: divisions,
    );
  }
  
  /// Create a range slider
  static SliderField range({
    required RangeValues values,
    required ValueChanged<RangeValues> onChanged,
    double min = 0.0,
    double max = 100.0,
    String? label,
    int? divisions,
  }) {
    return SliderField(
      mode: SliderMode.range,
      rangeValues: values,
      onRangeChanged: onChanged,
      min: min,
      max: max,
      label: label,
      divisions: divisions,
    );
  }
  
  /// Create a slider with custom steps
  static SliderField stepped({
    required double value,
    required ValueChanged<double> onChanged,
    required List<double> steps,
    String? label,
  }) {
    return SliderField(
      value: value,
      onChanged: onChanged,
      min: steps.first,
      max: steps.last,
      label: label,
      divisions: steps.length - 1,
      stepConfig: StepConfig(
        showSteps: true,
        customSteps: steps,
        snapToSteps: true,
      ),
    );
  }
  
  /// Create a labeled slider with custom value labels
  static SliderField labeled({
    required double value,
    required ValueChanged<double> onChanged,
    required List<String> labels,
    String? label,
  }) {
    return SliderField(
      value: value,
      onChanged: onChanged,
      min: 0,
      max: (labels.length - 1).toDouble(),
      label: label,
      divisions: labels.length - 1,
      valueLabels: labels,
      tooltipConfig: SliderTooltipConfig(
        formatter: (value) {
          final index = value.round();
          return index < labels.length ? labels[index] : '';
        },
      ),
    );
  }
}

/// Predefined slider configurations
class SliderPresets {
  /// Age slider (0-100)
  static SliderField age({
    required double value,
    required ValueChanged<double> onChanged,
    String label = 'Age',
  }) {
    return SliderField(
      value: value,
      onChanged: onChanged,
      min: 0,
      max: 100,
      label: label,
      divisions: 100,
      iconConfig: const SliderIconConfig(
        minIcon: Icons.child_care,
        maxIcon: Icons.elderly,
        minLabel: 'Young',
        maxLabel: 'Senior',
      ),
      tooltipConfig: SliderTooltipConfig(
        formatter: (value) => '${value.round()} years',
      ),
    );
  }
  
  /// Experience level slider (1-10)
  static SliderField experienceLevel({
    required double value,
    required ValueChanged<double> onChanged,
    String label = 'Experience Level',
  }) {
    return SliderField(
      value: value,
      onChanged: onChanged,
      min: 1,
      max: 10,
      label: label,
      divisions: 9,
      valueLabels: const [
        'Beginner', 'Novice', 'Learning', 'Developing', 'Intermediate',
        'Skilled', 'Advanced', 'Expert', 'Master', 'Elite'
      ],
      iconConfig: const SliderIconConfig(
        minIcon: Icons.school,
        maxIcon: Icons.emoji_events,
        minLabel: 'Beginner',
        maxLabel: 'Expert',
      ),
      activeColor: Colors.blue,
    );
  }
  
  /// Distance range slider (0-50km)
  static SliderField distanceRange({
    required RangeValues values,
    required ValueChanged<RangeValues> onChanged,
    String label = 'Distance Range',
  }) {
    return SliderField(
      mode: SliderMode.range,
      rangeValues: values,
      onRangeChanged: onChanged,
      min: 0,
      max: 50,
      label: label,
      divisions: 50,
      iconConfig: const SliderIconConfig(
        minIcon: Icons.location_on,
        maxIcon: Icons.explore,
        minLabel: 'Nearby',
        maxLabel: 'Far',
      ),
      tooltipConfig: SliderTooltipConfig(
        formatter: (value) => '${value.round()} km',
      ),
      activeColor: Colors.green,
    );
  }
  
  /// Price range slider (0-1000)
  static SliderField priceRange({
    required RangeValues values,
    required ValueChanged<RangeValues> onChanged,
    String label = 'Price Range',
    String currency = '\$',
  }) {
    return SliderField(
      mode: SliderMode.range,
      rangeValues: values,
      onRangeChanged: onChanged,
      min: 0,
      max: 1000,
      label: label,
      divisions: 100,
      iconConfig: const SliderIconConfig(
        minIcon: Icons.attach_money,
        maxIcon: Icons.money_off,
        minLabel: 'Budget',
        maxLabel: 'Premium',
      ),
      tooltipConfig: SliderTooltipConfig(
        formatter: (value) => '$currency${value.round()}',
      ),
      activeColor: Colors.orange,
    );
  }
  
  /// Time duration slider (15min - 4hrs)
  static SliderField duration({
    required double value,
    required ValueChanged<double> onChanged,
    String label = 'Duration',
  }) {
    return SliderField(
      value: value,
      onChanged: onChanged,
      min: 15,
      max: 240,
      label: label,
      divisions: 45, // 5-minute increments
      iconConfig: const SliderIconConfig(
        minIcon: Icons.timer,
        maxIcon: Icons.schedule,
        minLabel: 'Quick',
        maxLabel: 'Long',
      ),
      tooltipConfig: SliderTooltipConfig(
        formatter: (value) {
          final minutes = value.round();
          if (minutes < 60) {
            return '${minutes}min';
          } else {
            final hours = minutes ~/ 60;
            final remainingMinutes = minutes % 60;
            return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
          }
        },
      ),
      activeColor: Colors.purple,
    );
  }
  
  /// Skill level with logarithmic scale
  static SliderField skillLevel({
    required double value,
    required ValueChanged<double> onChanged,
    String skillName = 'Skill Level',
  }) {
    return SliderField(
      value: value,
      onChanged: onChanged,
      min: 1,
      max: 100,
      label: skillName,
      logarithmic: true,
      tooltipConfig: SliderTooltipConfig(
        formatter: (value) => 'Level ${value.round()}',
      ),
      stepConfig: const StepConfig(
        showSteps: true,
        snapToSteps: true,
      ),
      activeColor: Colors.indigo,
    );
  }
}
