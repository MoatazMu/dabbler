import 'package:flutter/material.dart';

/// Horizontal step indicator widget for multi-step processes
class ProgressStepIndicator extends StatelessWidget {
  /// Current active step (0-based index)
  final int currentStep;
  
  /// Total number of steps
  final int totalSteps;
  
  /// Labels for each step
  final List<String> stepLabels;
  
  /// Whether completed steps should show a checkmark
  final bool showCheckmarks;
  
  /// Custom colors for different step states
  final ProgressStepColors? colors;
  
  /// Size of the step indicators
  final double stepSize;
  
  /// Width of the connecting lines
  final double lineWidth;
  
  /// Function called when a step is tapped
  final Function(int stepIndex)? onStepTapped;
  
  /// Whether tapping on completed steps is allowed
  final bool allowTapOnCompletedSteps;
  
  /// Custom step content builder
  final Widget Function(BuildContext context, int stepIndex, ProgressStepState state)? stepBuilder;

  const ProgressStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.showCheckmarks = true,
    this.colors,
    this.stepSize = 32.0,
    this.lineWidth = 2.0,
    this.onStepTapped,
    this.allowTapOnCompletedSteps = true,
    this.stepBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColors = colors ?? ProgressStepColors.fromTheme(theme);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Step indicators and connecting lines
          SizedBox(
            height: stepSize,
            child: Row(
              children: _buildStepIndicators(context, effectiveColors),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Step labels
          Row(
            children: _buildStepLabels(theme, effectiveColors),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepIndicators(BuildContext context, ProgressStepColors colors) {
    final indicators = <Widget>[];
    
    for (int i = 0; i < totalSteps; i++) {
      final state = _getStepState(i);
      
      // Add step indicator
      indicators.add(
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _canTapStep(i) ? () => onStepTapped?.call(i) : null,
              child: stepBuilder?.call(context, i, state) ?? 
                     _buildDefaultStepIndicator(i, state, colors),
            ),
          ),
        ),
      );
      
      // Add connecting line (except for last step)
      if (i < totalSteps - 1) {
        indicators.add(
          Expanded(
            child: Container(
              height: lineWidth,
              color: state == ProgressStepState.completed
                  ? colors.completedColor
                  : colors.inactiveColor,
            ),
          ),
        );
      }
    }
    
    return indicators;
  }

  Widget _buildDefaultStepIndicator(int stepIndex, ProgressStepState state, ProgressStepColors colors) {
    Widget content;
    Color backgroundColor;
    Color contentColor;
    
    switch (state) {
      case ProgressStepState.completed:
        backgroundColor = colors.completedColor;
        contentColor = colors.completedContentColor;
        content = showCheckmarks
            ? Icon(
                Icons.check_rounded,
                size: stepSize * 0.6,
                color: contentColor,
              )
            : Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: stepSize * 0.4,
                ),
              );
        break;
        
      case ProgressStepState.current:
        backgroundColor = colors.currentColor;
        contentColor = colors.currentContentColor;
        content = Text(
          '${stepIndex + 1}',
          style: TextStyle(
            color: contentColor,
            fontWeight: FontWeight.w600,
            fontSize: stepSize * 0.4,
          ),
        );
        break;
        
      case ProgressStepState.inactive:
        backgroundColor = colors.inactiveColor;
        contentColor = colors.inactiveContentColor;
        content = Text(
          '${stepIndex + 1}',
          style: TextStyle(
            color: contentColor,
            fontWeight: FontWeight.w500,
            fontSize: stepSize * 0.4,
          ),
        );
        break;
    }
    
    return Container(
      width: stepSize,
      height: stepSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: state == ProgressStepState.current
            ? Border.all(
                color: colors.currentBorderColor,
                width: 2,
              )
            : null,
      ),
      child: Center(child: content),
    );
  }

  List<Widget> _buildStepLabels(ThemeData theme, ProgressStepColors colors) {
    return List.generate(totalSteps, (index) {
      final state = _getStepState(index);
      final label = index < stepLabels.length ? stepLabels[index] : '';
      
      Color textColor;
      switch (state) {
        case ProgressStepState.completed:
          textColor = colors.completedColor;
          break;
        case ProgressStepState.current:
          textColor = colors.currentColor;
          break;
        case ProgressStepState.inactive:
          textColor = colors.inactiveContentColor;
          break;
      }
      
      return Expanded(
        child: GestureDetector(
          onTap: _canTapStep(index) ? () => onStepTapped?.call(index) : null,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: state == ProgressStepState.current
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }

  ProgressStepState _getStepState(int stepIndex) {
    if (stepIndex < currentStep) {
      return ProgressStepState.completed;
    } else if (stepIndex == currentStep) {
      return ProgressStepState.current;
    } else {
      return ProgressStepState.inactive;
    }
  }

  bool _canTapStep(int stepIndex) {
    if (onStepTapped == null) return false;
    
    if (stepIndex == currentStep) return true;
    
    if (stepIndex < currentStep && allowTapOnCompletedSteps) {
      return true;
    }
    
    return false;
  }
}

/// Vertical step indicator variant
class VerticalProgressStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final List<String>? stepDescriptions;
  final bool showCheckmarks;
  final ProgressStepColors? colors;
  final double stepSize;
  final double lineWidth;
  final Function(int stepIndex)? onStepTapped;
  final bool allowTapOnCompletedSteps;

  const VerticalProgressStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.stepDescriptions,
    this.showCheckmarks = true,
    this.colors,
    this.stepSize = 32.0,
    this.lineWidth = 2.0,
    this.onStepTapped,
    this.allowTapOnCompletedSteps = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColors = colors ?? ProgressStepColors.fromTheme(theme);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(totalSteps, (index) {
        return _buildVerticalStep(
          context,
          index,
          theme,
          effectiveColors,
          isLast: index == totalSteps - 1,
        );
      }),
    );
  }

  Widget _buildVerticalStep(
    BuildContext context,
    int stepIndex,
    ThemeData theme,
    ProgressStepColors colors,
    {required bool isLast}
  ) {
    final state = _getStepState(stepIndex);
    final label = stepIndex < stepLabels.length ? stepLabels[stepIndex] : '';
    final description = stepDescriptions != null && stepIndex < stepDescriptions!.length
        ? stepDescriptions![stepIndex]
        : null;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator column
          Column(
            children: [
              GestureDetector(
                onTap: _canTapStep(stepIndex) ? () => onStepTapped?.call(stepIndex) : null,
                child: _buildStepIndicator(stepIndex, state, colors),
              ),
              if (!isLast)
                Container(
                  width: lineWidth,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: state == ProgressStepState.completed
                      ? colors.completedColor
                      : colors.inactiveColor,
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Content column
          Expanded(
            child: GestureDetector(
              onTap: _canTapStep(stepIndex) ? () => onStepTapped?.call(stepIndex) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _getTextColor(state, colors),
                      fontWeight: state == ProgressStepState.current
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.inactiveContentColor,
                      ),
                    ),
                  ],
                  if (!isLast) const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, ProgressStepState state, ProgressStepColors colors) {
    Widget content;
    Color backgroundColor;
    Color contentColor;
    
    switch (state) {
      case ProgressStepState.completed:
        backgroundColor = colors.completedColor;
        contentColor = colors.completedContentColor;
        content = showCheckmarks
            ? Icon(
                Icons.check_rounded,
                size: stepSize * 0.6,
                color: contentColor,
              )
            : Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: stepSize * 0.4,
                ),
              );
        break;
        
      case ProgressStepState.current:
        backgroundColor = colors.currentColor;
        contentColor = colors.currentContentColor;
        content = Text(
          '${stepIndex + 1}',
          style: TextStyle(
            color: contentColor,
            fontWeight: FontWeight.w600,
            fontSize: stepSize * 0.4,
          ),
        );
        break;
        
      case ProgressStepState.inactive:
        backgroundColor = colors.inactiveColor;
        contentColor = colors.inactiveContentColor;
        content = Text(
          '${stepIndex + 1}',
          style: TextStyle(
            color: contentColor,
            fontWeight: FontWeight.w500,
            fontSize: stepSize * 0.4,
          ),
        );
        break;
    }
    
    return Container(
      width: stepSize,
      height: stepSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: state == ProgressStepState.current
            ? Border.all(
                color: colors.currentBorderColor,
                width: 2,
              )
            : null,
      ),
      child: Center(child: content),
    );
  }

  ProgressStepState _getStepState(int stepIndex) {
    if (stepIndex < currentStep) {
      return ProgressStepState.completed;
    } else if (stepIndex == currentStep) {
      return ProgressStepState.current;
    } else {
      return ProgressStepState.inactive;
    }
  }

  bool _canTapStep(int stepIndex) {
    if (onStepTapped == null) return false;
    
    if (stepIndex == currentStep) return true;
    
    if (stepIndex < currentStep && allowTapOnCompletedSteps) {
      return true;
    }
    
    return false;
  }

  Color _getTextColor(ProgressStepState state, ProgressStepColors colors) {
    switch (state) {
      case ProgressStepState.completed:
        return colors.completedColor;
      case ProgressStepState.current:
        return colors.currentColor;
      case ProgressStepState.inactive:
        return colors.inactiveContentColor;
    }
  }
}

/// Step state enumeration
enum ProgressStepState {
  completed,
  current,
  inactive,
}

/// Color configuration for step indicators
class ProgressStepColors {
  final Color completedColor;
  final Color completedContentColor;
  final Color currentColor;
  final Color currentContentColor;
  final Color currentBorderColor;
  final Color inactiveColor;
  final Color inactiveContentColor;

  const ProgressStepColors({
    required this.completedColor,
    required this.completedContentColor,
    required this.currentColor,
    required this.currentContentColor,
    required this.currentBorderColor,
    required this.inactiveColor,
    required this.inactiveContentColor,
  });

  factory ProgressStepColors.fromTheme(ThemeData theme) {
    return ProgressStepColors(
      completedColor: theme.colorScheme.primary,
      completedContentColor: theme.colorScheme.onPrimary,
      currentColor: theme.colorScheme.primary,
      currentContentColor: theme.colorScheme.onPrimary,
      currentBorderColor: theme.colorScheme.primary.withOpacity(0.3),
      inactiveColor: theme.colorScheme.surfaceContainerHighest,
      inactiveContentColor: theme.colorScheme.onSurfaceVariant,
    );
  }
}
