import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Category-specific colors for different app sections
class CategoryColors {
  // Main category - Purple
  static const Color main = Color(0xFF8B5CF6);
  static const Color mainLight = Color(0xFFE0C7FF);

  // Social category - Blue
  static const Color social = Color(0xFF3B82F6);
  static const Color socialLight = Color(0xFFD1EAFA);

  // Sports category - Green
  static const Color sports = Color(0xFF10B981);
  static const Color sportsLight = Color(0xFFB1FBDA);

  // Activities category - Pink
  static const Color activities = Color(0xFFEC4899);
  static const Color activitiesLight = Color(0xFFFCDEE8);

  // Profile category - Orange
  static const Color profile = Color(0xFFF59E0B);
  static const Color profileLight = Color(0xFFFCF8EA);
}

/// Material Design 3 theme implementation
class AppTheme {
  // Primary purple seed color for Material 3 ColorScheme generation
  static const Color _primarySeed = Color(0xFF8B5CF6);

  /// Light Material Design 3 Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: GoogleFonts.robotoTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primarySeed, width: 2),
      ),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  /// Dark Material Design 3 Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _primarySeed.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  /// Helper to get category color based on theme brightness
  static Color getCategoryColor(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (category.toLowerCase()) {
      case 'main':
        return isDark ? CategoryColors.main : CategoryColors.mainLight;
      case 'social':
        return isDark ? CategoryColors.social : CategoryColors.socialLight;
      case 'sports':
        return isDark ? CategoryColors.sports : CategoryColors.sportsLight;
      case 'activities':
        return isDark
            ? CategoryColors.activities
            : CategoryColors.activitiesLight;
      case 'profile':
        return isDark ? CategoryColors.profile : CategoryColors.profileLight;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  // Compatibility methods for legacy code
  static Color getCardBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color getBorderColor(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
}

/// Extension for easy theme access
extension AppThemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  ColorScheme get colors => colorScheme; // Alias for compatibility
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Quick access to common colors
  Color get primaryColor => colorScheme.primary;
  Color get surfaceColor => colorScheme.surface;
  Color get backgroundColor => colorScheme.surface;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onSurfaceColor => colorScheme.onSurface;

  // Legacy compatibility helpers
  Color get violetCardBg => colorScheme.surfaceContainerHighest;
  Color get violetWidgetBg => colorScheme.surfaceContainer;
  Color get violetSurface => colorScheme.surface;

  /// Category colors
  Color categoryColor(String category) =>
      AppTheme.getCategoryColor(this, category);
}
