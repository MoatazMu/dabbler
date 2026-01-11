import 'package:flutter/material.dart';
import 'design_tokens.dart';
import '../../theme/color_token_extensions.dart';

/// Extension to access ThemeColorTokens from BuildContext
/// Maps the current theme brightness and category to the correct token set
extension ThemeColorTokensExtension on BuildContext {
  /// Get the current theme's color tokens
  /// Derived from the active Material 3 ColorScheme (design-system/tokens source-of-truth)
  ThemeColorTokens get colorTokens {
    return ThemeColorTokensFromScheme.from(Theme.of(this).colorScheme);
  }
}

/// Extension to get category-specific color tokens
extension CategoryColorTokensExtension on BuildContext {
  /// Get color tokens for a specific category
  ThemeColorTokens getCategoryColorTokens(String category, {bool? isDark}) {
    final brightness = isDark ?? (Theme.of(this).brightness == Brightness.dark);
    final scheme = ThemeColorTokensFromScheme._schemeForCategory(
      context: this,
      category: category,
      brightness: brightness ? Brightness.dark : Brightness.light,
    );
    return ThemeColorTokensFromScheme.from(scheme);
  }
}

/// Maps a Material 3 ColorScheme (design tokens) into the legacy ThemeColorTokens
/// shape used by a few older widgets/layouts.
class ThemeColorTokensFromScheme {
  static ThemeColorTokens from(ColorScheme scheme) {
    return ThemeColorTokens(
      header: scheme.primaryContainer,
      section: scheme.primaryContainer.withValues(alpha: 0.18),
      secondaryContainer: scheme.secondaryContainer,
      button: scheme.primary,
      btnBase: scheme.primaryContainer,
      tabActive: scheme.primary,
      app: scheme.surfaceContainerLowest,
      base: scheme.surface,
      card: scheme.surfaceContainer,
      stroke: scheme.outlineVariant,
      titleOnSec: scheme.onSecondaryContainer,
      titleOnHead: scheme.onPrimaryContainer,
      neutral: scheme.onSurface,
      neutralOpacity: scheme.onSurfaceVariant,
      neutralDisabled: scheme.onSurface.withValues(alpha: 0.38),
      onBtn: scheme.onPrimary,
      onBtnIcon: scheme.onPrimary,
    );
  }

  static ColorScheme _schemeForCategory({
    required BuildContext context,
    required String category,
    required Brightness brightness,
  }) {
    // Uses static token-backed schemes via AppTheme.*ColorScheme.
    // Keeps this sync for build methods.
    return context.getCategoryTheme(category);
  }
}
