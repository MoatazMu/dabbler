import 'package:flutter/material.dart';

enum SkillLevel {
  beginner,
  novice,
  intermediate,
  advanced,
  expert,
}

enum SkillIndicatorStyle {
  stars,
  bars,
  dots,
  custom,
}

class SkillLevelIndicator extends StatelessWidget {
  final SkillLevel level;
  final SkillIndicatorStyle style;
  final bool showLabel;
  final bool showTooltip;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool compact;

  const SkillLevelIndicator({
    super.key,
    required this.level,
    this.style = SkillIndicatorStyle.stars,
    this.showLabel = true,
    this.showTooltip = true,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCol = activeColor ?? _getDefaultActiveColor(level);
    final inactiveCol = inactiveColor ?? Colors.grey[300]!;

    Widget indicator = _buildIndicator(activeCol, inactiveCol);

    if (compact) {
      return indicator;
    }

    Widget result = showLabel
        ? _buildWithLabel(indicator, theme)
        : indicator;

    if (showTooltip) {
      result = Tooltip(
        message: _getTooltipText(),
        child: result,
      );
    }

    return result;
  }

  Widget _buildIndicator(Color activeColor, Color inactiveColor) {
    final levelValue = _getLevelValue();

    switch (style) {
      case SkillIndicatorStyle.stars:
        return _buildStarIndicator(levelValue, activeColor, inactiveColor);
      case SkillIndicatorStyle.bars:
        return _buildBarIndicator(levelValue, activeColor, inactiveColor);
      case SkillIndicatorStyle.dots:
        return _buildDotIndicator(levelValue, activeColor, inactiveColor);
      case SkillIndicatorStyle.custom:
        return _buildCustomIndicator(levelValue, activeColor, inactiveColor);
    }
  }

  Widget _buildStarIndicator(int levelValue, Color activeColor, Color inactiveColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < levelValue;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
          child: Icon(
            isActive ? Icons.star : Icons.star_border,
            color: isActive ? activeColor : inactiveColor,
            size: size,
          ),
        );
      }),
    );
  }

  Widget _buildBarIndicator(int levelValue, Color activeColor, Color inactiveColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < levelValue;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
          child: Container(
            width: size * 0.6,
            height: size,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDotIndicator(int levelValue, Color activeColor, Color inactiveColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < levelValue;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
          child: Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? activeColor : inactiveColor,
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCustomIndicator(int levelValue, Color activeColor, Color inactiveColor) {
    // Custom skill indicator with gradient fill
    return Container(
      width: compact ? size * 3 : size * 4,
      height: compact ? size * 0.6 : size * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: inactiveColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: LinearProgressIndicator(
          value: levelValue / 5,
          backgroundColor: inactiveColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
        ),
      ),
    );
  }

  Widget _buildWithLabel(Widget indicator, ThemeData theme) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(width: 4),
          Text(
            _getLevelName(),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w500,
              color: _getDefaultActiveColor(level),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        indicator,
        const SizedBox(height: 4),
        Text(
          _getLevelName(),
          style: TextStyle(
            fontSize: size * 0.9,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  int _getLevelValue() {
    switch (level) {
      case SkillLevel.beginner:
        return 1;
      case SkillLevel.novice:
        return 2;
      case SkillLevel.intermediate:
        return 3;
      case SkillLevel.advanced:
        return 4;
      case SkillLevel.expert:
        return 5;
    }
  }

  String _getLevelName() {
    switch (level) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.novice:
        return 'Novice';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
      case SkillLevel.expert:
        return 'Expert';
    }
  }

  Color _getDefaultActiveColor(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return Colors.green;
      case SkillLevel.novice:
        return Colors.lightGreen;
      case SkillLevel.intermediate:
        return Colors.orange;
      case SkillLevel.advanced:
        return Colors.red;
      case SkillLevel.expert:
        return Colors.purple;
    }
  }

  String _getTooltipText() {
    switch (level) {
      case SkillLevel.beginner:
        return 'Beginner - Just starting out, learning the basics';
      case SkillLevel.novice:
        return 'Novice - Some experience, comfortable with fundamentals';
      case SkillLevel.intermediate:
        return 'Intermediate - Solid skills, plays regularly';
      case SkillLevel.advanced:
        return 'Advanced - Highly skilled, competitive player';
      case SkillLevel.expert:
        return 'Expert - Professional level skills and experience';
    }
  }
}

// Utility function to convert string to SkillLevel enum
SkillLevel skillLevelFromString(String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return SkillLevel.beginner;
    case 'novice':
      return SkillLevel.novice;
    case 'intermediate':
      return SkillLevel.intermediate;
    case 'advanced':
      return SkillLevel.advanced;
    case 'expert':
      return SkillLevel.expert;
    default:
      return SkillLevel.beginner;
  }
}

// Utility function to convert SkillLevel enum to string
String skillLevelToString(SkillLevel level) {
  switch (level) {
    case SkillLevel.beginner:
      return 'beginner';
    case SkillLevel.novice:
      return 'novice';
    case SkillLevel.intermediate:
      return 'intermediate';
    case SkillLevel.advanced:
      return 'advanced';
    case SkillLevel.expert:
      return 'expert';
  }
}
