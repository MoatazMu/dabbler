import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dabbler/themes/app_theme.dart';
import 'package:dabbler/utils/ui_constants.dart';

/// Consistent app button widget with multiple variants
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = ButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine colors based on variant
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = isDark ? Colors.black : Colors.white;
        borderColor = null;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppTheme.getCardBackground(context);
        foregroundColor = AppTheme.getTextPrimary(context);
        borderColor = null;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.getTextPrimary(context);
        borderColor = AppTheme.getBorderColor(context);
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppTheme.getTextPrimary(context);
        borderColor = null;
        break;
    }

    // Determine sizing
    EdgeInsets padding;
    double height;
    double fontSize;
    double iconSize;

    switch (size) {
      case ButtonSize.small:
        padding = AppButtonSize.smallPadding;
        height = AppButtonSize.smallHeight;
        fontSize = 14;
        iconSize = AppIconSize.xs;
        break;
      case ButtonSize.medium:
        padding = AppButtonSize.mediumPadding;
        height = AppButtonSize.mediumHeight;
        fontSize = 15;
        iconSize = AppIconSize.sm;
        break;
      case ButtonSize.large:
        padding = AppButtonSize.largePadding;
        height = AppButtonSize.largeHeight;
        fontSize = 16;
        iconSize = AppIconSize.sm;
        break;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: iconSize),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    SizedBox(width: AppSpacing.sm),
                    Icon(trailingIcon, size: iconSize),
                  ],
                ],
              ),
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, outline, ghost }

enum ButtonSize { small, medium, large }
