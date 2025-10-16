import 'package:flutter/material.dart';
import '../../../../../utils/enums/game_enums.dart';

/// Widget for selecting skill level with descriptions and visual indicators
class SkillLevelSelector extends StatelessWidget {
  /// Currently selected skill level
  final SkillLevel? selectedLevel;
  
  /// Called when skill level changes
  final ValueChanged<SkillLevel?>? onChanged;
  
  /// Whether the selector is enabled
  final bool enabled;
  
  /// Whether to show descriptions
  final bool showDescriptions;
  
  /// Layout style for the selector
  final SkillLevelSelectorStyle style;
  
  /// Custom skill levels to show (if null, shows all)
  final List<SkillLevel>? skillLevels;

  const SkillLevelSelector({
    super.key,
    this.selectedLevel,
    this.onChanged,
    this.enabled = true,
    this.showDescriptions = true,
    this.style = SkillLevelSelectorStyle.cards,
    this.skillLevels,
  });

  @override
  Widget build(BuildContext context) {
    final levels = skillLevels ?? SkillLevel.values;
    
    switch (style) {
      case SkillLevelSelectorStyle.cards:
        return _buildCardStyle(context, levels);
      case SkillLevelSelectorStyle.chips:
        return _buildChipStyle(context, levels);
      case SkillLevelSelectorStyle.radio:
        return _buildRadioStyle(context, levels);
      case SkillLevelSelectorStyle.dropdown:
        return _buildDropdownStyle(context, levels);
    }
  }

  Widget _buildCardStyle(BuildContext context, List<SkillLevel> levels) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...levels.map((level) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildSkillLevelCard(context, level),
        )),
      ],
    );
  }

  Widget _buildSkillLevelCard(BuildContext context, SkillLevel level) {
    final theme = Theme.of(context);
    final isSelected = selectedLevel == level;
    
    return GestureDetector(
      onTap: enabled ? () => onChanged?.call(level) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Skill level indicator
            _buildSkillLevelIndicator(context, level, isSelected),
            
            const SizedBox(width: 16),
            
            // Level info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        level.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  if (showDescriptions) ...[
                    const SizedBox(height: 4),
                    Text(
                      level.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillLevelIndicator(
    BuildContext context,
    SkillLevel level,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final numericValue = level.numericValue;
    
    // Special case for mixed levels
    if (level == SkillLevel.mixed) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.group_rounded,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    
    // Skill dots indicator
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: index < numericValue
                    ? (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  width: 0.5,
                ),
              ),
            )),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: (index + 2) < numericValue
                    ? (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  width: 0.5,
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildChipStyle(BuildContext context, List<SkillLevel> levels) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((level) => FilterChip(
            label: Text(level.displayName),
            selected: selectedLevel == level,
            onSelected: enabled ? (selected) {
              if (selected) {
                onChanged?.call(level);
              }
            } : null,
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRadioStyle(BuildContext context, List<SkillLevel> levels) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        ...levels.map((level) => RadioListTile<SkillLevel>(
          value: level,
          groupValue: selectedLevel,
          onChanged: enabled ? (value) {
            if (value != null) {
              onChanged?.call(value);
            }
          } : null,
          title: Text(level.displayName),
          subtitle: showDescriptions ? Text(
            level.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ) : null,
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildDropdownStyle(BuildContext context, List<SkillLevel> levels) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Level',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        DropdownButtonFormField<SkillLevel>(
          initialValue: selectedLevel,
          onChanged: enabled ? (value) {
            if (value != null) {
              onChanged?.call(value);
            }
          } : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          items: levels.map((level) => DropdownMenuItem(
            value: level,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showDescriptions) ...[
                  const SizedBox(height: 2),
                  Text(
                    level.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          )).toList(),
          hint: const Text('Select skill level'),
        ),
      ],
    );
  }
}

/// Compact skill level badge
class SkillLevelBadge extends StatelessWidget {
  final SkillLevel skillLevel;
  final SkillLevelBadgeSize size;
  final bool showText;

  const SkillLevelBadge({
    super.key,
    required this.skillLevel,
    this.size = SkillLevelBadgeSize.medium,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final badgeSize = switch (size) {
      SkillLevelBadgeSize.small => 24.0,
      SkillLevelBadgeSize.medium => 32.0,
      SkillLevelBadgeSize.large => 40.0,
    };
    
    final iconSize = switch (size) {
      SkillLevelBadgeSize.small => 12.0,
      SkillLevelBadgeSize.medium => 16.0,
      SkillLevelBadgeSize.large => 20.0,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: _getSkillLevelColor(skillLevel, theme),
            borderRadius: BorderRadius.circular(6),
          ),
          child: skillLevel == SkillLevel.mixed
              ? Icon(
                  Icons.group_rounded,
                  size: iconSize,
                  color: theme.colorScheme.onPrimary,
                )
              : _buildSkillDots(skillLevel, iconSize, theme),
        ),
        
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            skillLevel.displayName,
            style: switch (size) {
              SkillLevelBadgeSize.small => theme.textTheme.bodySmall,
              SkillLevelBadgeSize.medium => theme.textTheme.bodyMedium,
              SkillLevelBadgeSize.large => theme.textTheme.titleSmall,
            }?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getSkillLevelColor(SkillLevel level, ThemeData theme) {
    switch (level) {
      case SkillLevel.beginner:
        return Colors.green;
      case SkillLevel.intermediate:
        return Colors.orange;
      case SkillLevel.advanced:
        return Colors.red;
      case SkillLevel.expert:
        return Colors.purple;
      case SkillLevel.mixed:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildSkillDots(SkillLevel level, double iconSize, ThemeData theme) {
    final numericValue = level.numericValue;
    
    return Center(
      child: Wrap(
        spacing: 1,
        runSpacing: 1,
        children: List.generate(4, (index) => Container(
          width: iconSize / 4,
          height: iconSize / 4,
          decoration: BoxDecoration(
            color: index < numericValue
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        )),
      ),
    );
  }
}

enum SkillLevelSelectorStyle {
  cards,
  chips,
  radio,
  dropdown,
}

enum SkillLevelBadgeSize {
  small,
  medium,
  large,
}
