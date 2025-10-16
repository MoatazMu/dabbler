import 'package:flutter/material.dart';
import '../config/design_system/design_tokens/colors.dart';
import '../config/design_system/design_tokens/spacing.dart';
import '../config/design_system/design_tokens/typography.dart';

/// Example ForUI-style button component using the new design system
class DabblerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;

  const DabblerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: _getPadding(),
          decoration: _getDecoration(),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary ? Colors.white : DabblerColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: _getTextStyle(),
        ),
      ],
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: DabblerSpacing.spacing12,
          vertical: DabblerSpacing.spacing8,
        );
      case ButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: DabblerSpacing.spacing24,
          vertical: DabblerSpacing.spacing16,
        );
      case ButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: DabblerSpacing.spacing16,
          vertical: DabblerSpacing.spacing12,
        );
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = DabblerTypography.button();
    final color = variant == ButtonVariant.primary
        ? Colors.white
        : variant == ButtonVariant.secondary
            ? DabblerColors.primary
            : DabblerColors.textPrimaryLight;

    double fontSize;
    switch (size) {
      case ButtonSize.small:
        fontSize = 12;
        break;
      case ButtonSize.large:
        fontSize = 16;
        break;
      case ButtonSize.medium:
        fontSize = 14;
    }

    return baseStyle.copyWith(
      color: onPressed == null ? color.withValues(alpha: 0.5) : color,
      fontSize: fontSize,
    );
  }

  BoxDecoration _getDecoration() {
    Color backgroundColor;
    Border? border;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = onPressed == null
            ? DabblerColors.primary.withValues(alpha: 0.5)
            : DabblerColors.primary;
        break;
      case ButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        border = Border.all(
          color: onPressed == null
              ? DabblerColors.primary.withValues(alpha: 0.5)
              : DabblerColors.primary,
          width: 1,
        );
        break;
      case ButtonVariant.text:
        backgroundColor = Colors.transparent;
        break;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: border,
    );
  }
}

enum ButtonVariant {
  primary,
  secondary,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}
