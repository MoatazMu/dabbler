import 'package:flutter/material.dart';

/// Material Design 3 button component matching Figma design specifications
/// Built on top of Material 3 button components (FilledButton, OutlinedButton, TextButton)
/// Implements 60 button variants from Figma DS (12 variants × 5 types)
///
/// **5 Button Styles:**
/// 1. **Filled** - Solid background with primary color
/// 2. **Outline** - Transparent background with border
/// 3. **Ghost** - Transparent background, no border, colored text
/// 4. **Ghost-Outline** - Surface background with subtle border
/// 5. **Subtle** - Light tinted background with matching text color
///
/// **3 Size Variants:**
/// - **Small**: 24px height, 6px radius, 13px text
/// - **Default**: 36px height, 12px radius, 15px text
/// - **Large**: 48px height, 18px radius, 17px text
///
/// **4 Icon Configurations:**
/// - No icons
/// - Left icon only
/// - Right icon only
/// - Both left and right icons
///
/// **Color Token Mapping:**
/// - Filled: background = tokens.button, text = tokens.onBtn
/// - Outline: border = tokens.stroke, text = tokens.button
/// - Ghost: text = tokens.button, no background/border
/// - Ghost-Outline: background = tokens.base, border = tokens.stroke, text = tokens.neutral
/// - Subtle: background = tokens.button @ 12%, text = tokens.button
enum AppButtonType {
  /// Filled button with solid background (uses FilledButton)
  filled,

  /// Outline button with border, no background (uses OutlinedButton)
  outline,

  /// Ghost button - colored text, no background/border (uses TextButton)
  ghost,

  /// Ghost-Outline - surface background with subtle border (uses OutlinedButton)
  ghostOutline,

  /// Subtle button - light tinted background with matching text (uses FilledButton)
  subtle,
}

enum AppButtonSize {
  /// Small: 24px height
  sm,

  /// Default: 36px height
  defaultSize,

  /// Large: 48px height
  lg,
}

class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool enabled;

  const AppButton({
    super.key,
    this.label,
    required this.onPressed,
    this.type = AppButtonType.filled,
    this.size = AppButtonSize.defaultSize,
    this.leftIcon,
    this.rightIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.enabled = true,
  });

  // Factory constructors for common button types
  factory AppButton.primary({
    Key? key,
    String? label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.defaultSize,
    Widget? leftIcon,
    Widget? rightIcon,
    bool enabled = true,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      type: AppButtonType.filled,
      size: size,
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      enabled: enabled,
    );
  }

  factory AppButton.outlined({
    Key? key,
    String? label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.defaultSize,
    Widget? leftIcon,
    Widget? rightIcon,
    bool enabled = true,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      type: AppButtonType.outline,
      size: size,
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      enabled: enabled,
    );
  }

  factory AppButton.ghost({
    Key? key,
    String? label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.defaultSize,
    Widget? leftIcon,
    Widget? rightIcon,
    bool enabled = true,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      type: AppButtonType.ghost,
      size: size,
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      enabled: enabled,
    );
  }

  factory AppButton.ghostOutline({
    Key? key,
    String? label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.defaultSize,
    Widget? leftIcon,
    Widget? rightIcon,
    bool enabled = true,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      type: AppButtonType.ghostOutline,
      size: size,
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      enabled: enabled,
    );
  }

  factory AppButton.subtle({
    Key? key,
    String? label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.defaultSize,
    Widget? leftIcon,
    Widget? rightIcon,
    bool enabled = true,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      type: AppButtonType.subtle,
      size: size,
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final specs = _getButtonSpecs();
    final theme = Theme.of(context);
    final isDisabled = !enabled || onPressed == null;

    // Build button content with icons
    final buttonContent = _buildButtonContent(specs, theme);

    // Create button style based on specs and type
    final buttonStyle = _createButtonStyle(context, specs);

    // Select appropriate Material 3 button based on type
    Widget button;
    switch (type) {
      case AppButtonType.filled:
        // FilledButton for primary filled buttons
        button = FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
        break;
      case AppButtonType.outline:
        // OutlinedButton for outlined buttons
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
        break;
      case AppButtonType.ghost:
        // TextButton for ghost buttons (no background, no border)
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
        break;
      case AppButtonType.ghostOutline:
        // OutlinedButton with surface background for ghost-outline
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
        break;
      case AppButtonType.subtle:
        // FilledButton with light tinted background for subtle
        button = FilledButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: buttonContent,
        );
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: specs.height,
      child: button,
    );
  }

  /// Build button content with icons and label
  Widget _buildButtonContent(_ButtonSpecs specs, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left icon
        if (leftIcon != null) ...[
          SizedBox(
            width: specs.iconSize,
            height: specs.iconSize,
            child: IconTheme(
              data: IconThemeData(size: specs.iconSize),
              child: leftIcon!,
            ),
          ),
          if (label != null) SizedBox(width: specs.iconSpacing),
        ],

        // Label
        if (label != null)
          Flexible(
            child: Text(label!, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),

        // Right icon
        if (rightIcon != null) ...[
          if (label != null) SizedBox(width: specs.iconSpacing),
          SizedBox(
            width: specs.iconSize,
            height: specs.iconSize,
            child: IconTheme(
              data: IconThemeData(size: specs.iconSize),
              child: rightIcon!,
            ),
          ),
        ],
      ],
    );
  }

  /// Create Material 3 button style matching Figma specs
  ButtonStyle _createButtonStyle(BuildContext context, _ButtonSpecs specs) {
    final theme = Theme.of(context);
    final primary = backgroundColor ?? theme.colorScheme.primary;
    final onPrimary = foregroundColor ?? theme.colorScheme.onPrimary;
    final neutralColor = theme.colorScheme.onSurface.withValues(alpha: 0.92);
    final baseColor = theme.colorScheme.surface;
    final strokeColor = borderColor ?? primary.withValues(alpha: 0.18);

    // Base style common to all buttons
    ButtonStyle baseStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(64, specs.height)),
      maximumSize: WidgetStateProperty.all(Size(double.infinity, specs.height)),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(specs.borderRadius),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 15, // body medium size
          fontWeight: FontWeight.w600,
          height: 1.172,
        ),
      ),
      elevation: WidgetStateProperty.all(0),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return primary.withValues(alpha: 0.08);
        }
        return null;
      }),
    );

    // Type-specific styles
    switch (type) {
      case AppButtonType.filled:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primary.withValues(alpha: 0.38);
            }
            return primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return onPrimary.withValues(alpha: 0.38);
            }
            return onPrimary;
          }),
        );
      case AppButtonType.outline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primary.withValues(alpha: 0.38);
            }
            return borderColor ?? primary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: strokeColor.withValues(alpha: 0.38));
            }
            return BorderSide(color: strokeColor);
          }),
        );
      case AppButtonType.ghost:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return (foregroundColor ?? primary).withValues(alpha: 0.38);
            }
            return foregroundColor ?? primary;
          }),
        );
      case AppButtonType.ghostOutline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(baseColor),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return neutralColor.withValues(alpha: 0.38);
            }
            return foregroundColor ?? neutralColor;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: strokeColor.withValues(alpha: 0.38));
            }
            return BorderSide(color: strokeColor);
          }),
        );
      case AppButtonType.subtle:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primary.withValues(alpha: 0.06);
            }
            return primary.withValues(alpha: 0.12);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primary.withValues(alpha: 0.38);
            }
            return foregroundColor ?? primary;
          }),
        );
    }
  }

  _ButtonSpecs _getButtonSpecs() {
    switch (size) {
      case AppButtonSize.sm:
        return const _ButtonSpecs(
          height: 24.0,
          borderRadius: 6.0,
          fontSize: 13.0,
          iconSize: 18.0,
          horizontalPadding: 12.0,
          iconSpacing: 6.0,
        );
      case AppButtonSize.defaultSize:
        return const _ButtonSpecs(
          height: 36.0,
          borderRadius: 12.0,
          fontSize: 17.0,
          iconSize: 24.0,
          horizontalPadding: 18.0,
          iconSpacing: 6.0,
        );
      case AppButtonSize.lg:
        return const _ButtonSpecs(
          height: 48.0,
          borderRadius: 18.0,
          fontSize: 21.0,
          iconSize: 24.0,
          horizontalPadding: 24.0,
          iconSpacing: 6.0,
        );
    }
  }
}

class _ButtonSpecs {
  final double height;
  final double borderRadius;
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;
  final double iconSpacing;

  const _ButtonSpecs({
    required this.height,
    required this.borderRadius,
    required this.fontSize,
    required this.iconSize,
    required this.horizontalPadding,
    required this.iconSpacing,
  });
}
