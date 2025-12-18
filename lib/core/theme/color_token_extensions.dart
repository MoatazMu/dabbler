import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';

/// Extension to get category-specific ColorSchemes from context
/// All colors come from Material 3 design tokens - no custom color definitions
extension CategoryThemeExtension on BuildContext {
  /// Get ColorScheme for a specific category (sync, static only)
  /// Usage:
  ///   final socialTheme = context.getCategoryTheme('social');
  ///   Container(color: socialTheme.primary);
  ColorScheme getCategoryTheme(String category) {
    final brightness = Theme.of(this).brightness;
    // Use static fallback only (sync)
    final isDark = brightness == Brightness.dark;
    switch (category.toLowerCase()) {
      case 'social':
        return isDark
            ? AppTheme.socialDarkColorScheme
            : AppTheme.socialLightColorScheme;
      case 'sports':
        return isDark
            ? AppTheme.sportsDarkColorScheme
            : AppTheme.sportsLightColorScheme;
      case 'activities':
      case 'activity':
        return isDark
            ? AppTheme.activitiesDarkColorScheme
            : AppTheme.activitiesLightColorScheme;
      case 'profile':
        return isDark
            ? AppTheme.profileDarkColorScheme
            : AppTheme.profileLightColorScheme;
      case 'main':
      default:
        return isDark
            ? AppTheme.mainDarkColorScheme
            : AppTheme.mainLightColorScheme;
    }
  }

  /// Check if current theme is for a specific category (sync, static only)
  bool isCategoryTheme(String category) {
    final currentPrimary = Theme.of(this).colorScheme.primary;
    final brightness = Theme.of(this).brightness;
    final isDark = brightness == Brightness.dark;
    ColorScheme categoryScheme;
    switch (category.toLowerCase()) {
      case 'social':
        categoryScheme = isDark
            ? AppTheme.socialDarkColorScheme
            : AppTheme.socialLightColorScheme;
        break;
      case 'sports':
        categoryScheme = isDark
            ? AppTheme.sportsDarkColorScheme
            : AppTheme.sportsLightColorScheme;
        break;
      case 'activities':
      case 'activity':
        categoryScheme = isDark
            ? AppTheme.activitiesDarkColorScheme
            : AppTheme.activitiesLightColorScheme;
        break;
      case 'profile':
        categoryScheme = isDark
            ? AppTheme.profileDarkColorScheme
            : AppTheme.profileLightColorScheme;
        break;
      case 'main':
      default:
        categoryScheme = isDark
            ? AppTheme.mainDarkColorScheme
            : AppTheme.mainLightColorScheme;
        break;
    }
    return currentPrimary == categoryScheme.primary;
  }
}
