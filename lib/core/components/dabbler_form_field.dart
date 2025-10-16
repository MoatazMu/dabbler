import 'package:flutter/material.dart';
import '../config/design_system/design_tokens/colors.dart';
import '../config/design_system/design_tokens/spacing.dart';
import '../config/design_system/design_tokens/typography.dart';

/// Example ForUI-style form field component using the new design system
class DabblerFormField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;

  const DabblerFormField({
    super.key,
    required this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: DabblerTypography.caption().copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        SizedBox(height: DabblerSpacing.spacing8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          style: DabblerTypography.body1(),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: DabblerTypography.body1().copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            errorText: errorText,
            helperText: helperText,
            helperStyle: DabblerTypography.caption().copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            errorStyle: DabblerTypography.caption().copyWith(
              color: DabblerColors.error,
            ),
            prefixIcon: prefix,
            suffixIcon: suffix,
            contentPadding: DabblerSpacing.all16,
            border: _getBorder(theme),
            enabledBorder: _getBorder(theme),
            focusedBorder: _getBorder(theme, isFocused: true),
            errorBorder: _getBorder(theme, hasError: true),
            focusedErrorBorder: _getBorder(theme, hasError: true, isFocused: true),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _getBorder(ThemeData theme, {
    bool isFocused = false,
    bool hasError = false,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: hasError
            ? DabblerColors.error
            : isFocused
                ? DabblerColors.primary
                : theme.dividerColor,
        width: isFocused ? 2 : 1,
      ),
    );
  }
}
