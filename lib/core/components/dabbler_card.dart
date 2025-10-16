import 'package:flutter/material.dart';
import '../config/design_system/design_tokens/spacing.dart';
import '../config/design_system/design_tokens/typography.dart';

/// Example ForUI-style card component using the new design system
class DabblerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;

  const DabblerCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: margin ?? DabblerSpacing.all16,
      elevation: elevation ?? 1,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      color: backgroundColor ?? theme.cardColor,
      child: Padding(
        padding: padding ?? DabblerSpacing.all16,
        child: child,
      ),
    );
  }
}

/// Example usage of DabblerCard with a content template
class DabblerContentCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget>? actions;

  const DabblerContentCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DabblerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: DabblerTypography.headline5(),
          ),
          if (subtitle != null) ...[
            SizedBox(height: DabblerSpacing.spacing8),
            Text(
              subtitle!,
              style: DabblerTypography.body2().copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
          SizedBox(height: DabblerSpacing.spacing16),
          content,
          if (actions != null) ...[
            SizedBox(height: DabblerSpacing.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
