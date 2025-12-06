import 'package:flutter/material.dart';

/// Material 3 ColorScheme extension for app-specific category colors
///
/// This extension adds category colors (main, social, sports, activities, profile)
/// to the Material 3 ColorScheme, allowing them to be accessed via theme.
extension AppColorSchemeExtension on ColorScheme {
  // Category colors for dark theme
  static const Color _mainDark = Color(0xFF4A148C);
  static const Color _socialDark = Color(0xFF023D99);
  static const Color _sportsDark = Color(0xFF235826);
  static const Color _activitiesDark = Color(0xFF9C2464);
  static const Color _profileDark = Color(0xFFFCF8EA);

  // Category colors for light theme
  static const Color _mainLight = Color(0xFFE0C7FF);
  static const Color _socialLight = Color(0xFFD1EAFA);
  static const Color _sportsLight = Color(0xFFB1FBDA);
  static const Color _activitiesLight = Color(0xFFFCDEE8);
  static const Color _profileLight = Color(0xFFEC8F1E);

  /// Main category color (purple)
  Color get categoryMain =>
      brightness == Brightness.dark ? _mainDark : _mainLight;

  /// Social category color (blue)
  Color get categorySocial =>
      brightness == Brightness.dark ? _socialDark : _socialLight;

  /// Sports category color (green)
  Color get categorySports =>
      brightness == Brightness.dark ? _sportsDark : _sportsLight;

  /// Activities category color (pink)
  Color get categoryActivities =>
      brightness == Brightness.dark ? _activitiesDark : _activitiesLight;

  /// Profile category color (orange)
  Color get categoryProfile =>
      brightness == Brightness.dark ? _profileDark : _profileLight;

  /// Get category color by name
  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'main':
        return categoryMain;
      case 'social':
        return categorySocial;
      case 'sports':
        return categorySports;
      case 'activities':
        return categoryActivities;
      case 'profile':
        return categoryProfile;
      default:
        return primary;
    }
  }
}

/// Material 3 Theme extension for app-specific design tokens
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  /// Success color for success states
  final Color success;

  /// Warning color for warning states
  final Color warning;

  /// Info/Link color for informational states and links
  final Color infoLink;

  /// Danger color for error/danger states (uses ColorScheme.error by default)
  final Color? danger;

  const AppThemeExtension({
    required this.success,
    required this.warning,
    required this.infoLink,
    this.danger,
  });

  @override
  AppThemeExtension copyWith({
    Color? success,
    Color? warning,
    Color? infoLink,
    Color? danger,
    bool? dangerNull,
  }) {
    return AppThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      infoLink: infoLink ?? this.infoLink,
      danger: dangerNull == true ? null : (danger ?? this.danger),
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      infoLink: Color.lerp(infoLink, other.infoLink, t)!,
      danger: danger != null && other.danger != null
          ? Color.lerp(danger!, other.danger!, t)
          : (danger ?? other.danger),
    );
  }
}

/// Extension to easily access AppThemeExtension from BuildContext
extension AppThemeExtensionContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ??
      const AppThemeExtension(
        success: Color(0xFF00A63E),
        warning: Color(0xFFEC8F1E),
        infoLink: Color(0xFF155DFC),
      );

  /// Success color
  Color get successColor => appTheme.success;

  /// Warning color
  Color get warningColor => appTheme.warning;

  /// Info/Link color
  Color get infoLinkColor => appTheme.infoLink;

  /// Danger color (falls back to ColorScheme.error)
  Color get dangerColor => appTheme.danger ?? Theme.of(this).colorScheme.error;
}
