import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    this.label,
    this.placeholder,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (prefixIcon != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  prefixIcon!,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onTap: onTap,
                obscureText: obscureText,
                readOnly: readOnly,
                enabled: enabled,
                keyboardType: keyboardType,
                maxLines: maxLines,
                minLines: minLines,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: placeholder ?? hintText,
                  helperText: helperText,
                  errorText: errorText,
                  prefixIcon: null, // Handled separately above
                  suffixIcon: suffixIcon,
                  // Material 3 uses InputDecorationTheme from theme
                  // Only override specific properties if needed
                ).applyDefaults(Theme.of(context).inputDecorationTheme),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CustomTextArea extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enabled;
  final int minLines;
  final int maxLines;

  const CustomTextArea({
    super.key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.minLines = 3,
    this.maxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            helperText: helperText,
            errorText: errorText,
            // Material 3 uses InputDecorationTheme from theme
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
      ],
    );
  }
}
