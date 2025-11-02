import 'package:flutter/material.dart';

/// Semantic colors for consistent usage across the app
class SemanticColors {
  // Revised semantic colors for accessibility compliance
  static const Color success = Color(0xFF059669); // Light mode success
  static const Color warning = Color(0xFFF59E0B); // Light mode warning
  static const Color destructive = Color(
    0xFFD91A1A,
  ); // Light mode error (revised)

  // Status colors with proper contrast - Light Mode
  static const Color successBackground = Color(0xFFF0FDF4);
  static const Color successForeground = Color(
    0xFF059669,
  ); // Revised for contrast
  static const Color warningBackground = Color(0xFFFEFCE8);
  static const Color warningForeground = Color(0xFF92400E);
  static const Color destructiveBackground = Color(0xFFFEF2F2);
  static const Color destructiveForeground = Color(
    0xFFD91A1A,
  ); // Revised for contrast

  // Dark mode equivalents - Revised for accessibility
  static const Color successBackgroundDark = Color(0xFF14532D);
  static const Color successForegroundDark = Color(
    0xFF67E8F9,
  ); // Revised bright cyan
  static const Color warningBackgroundDark = Color(0xFF92400E);
  static const Color warningForegroundDark = Color(
    0xFFFBBF24,
  ); // Revised bright amber
  static const Color destructiveBackgroundDark = Color(0xFF991B1B);
  static const Color destructiveForegroundDark = Color(
    0xFFFFA1A1,
  ); // Revised bright red
}

/// Violet Fusion Color System - Complete accessibility-compliant palette
class VioletShades {
  // Light theme - Violet Fusion palette
  static const Color lightCardBackground = Color(
    0xFFF3F0FF,
  ); // Card backgrounds
  static const Color lightWidgetBackground = Color(
    0xFFEBE7FF,
  ); // Widget backgrounds
  static const Color lightSurfaceVariant = Color(
    0xFFFFFFFF,
  ); // Surface/modal backgrounds
  static const Color lightAccent = Color(0xFFDDD6FE); // Accent elements
  static const Color lightHover = Color(0xFFC4B5FD); // Hover states
  static const Color lightBackground = Color(0xFFFAF9FF); // App background

  // Dark theme - Enhanced rich violet palette
  static const Color darkCardBackground = Color(
    0xFF1A1625,
  ); // Rich dark violet cards
  static const Color darkWidgetBackground = Color(
    0xFF241F35,
  ); // Medium dark violet widgets
  static const Color darkSurfaceVariant = Color(
    0xFF2D2142,
  ); // Lighter dark violet surfaces
  static const Color darkAccent = Color(0xFF3E3354); // Rich violet accent
  static const Color darkHover = Color(
    0xFF4A3D61,
  ); // Vibrant violet interactions
  static const Color darkBackground = Color(
    0xFF15111F,
  ); // Deep violet background

  // Additional dark theme shades for enhanced hierarchy
  static const Color darkElevated = Color(0xFF332847); // Elevated elements
  static const Color darkHighlight = Color(0xFF5B4C73); // Highlights and focus
  static const Color darkSubtle = Color(0xFF15111F); // Subtle backgrounds

  // Text colors - Accessibility compliant
  static const Color lightTextPrimary = Color(0xFF1A202C);
  static const Color lightTextMuted = Color(0xFF575366); // Revised for contrast
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFFA1A1AA);

  // Border colors (minimal use)
  static const Color lightBorder = Color(0xFFEBE7FF);
  static const Color darkBorder = Color(0xFF332847);
}

/// Enhanced theme implementation following Ant Design best practices with Violet Fusion Color System
class AppTheme {
  // Violet Fusion primary colors - accessibility compliant
  static const Color _violetPrimary = Color(0xFF8B5CF6); // Light mode primary
  static const Color _violetPrimaryDark = Color(
    0xFF7C3AED,
  ); // Light mode variant
  static const Color _violetPrimaryDarkMode = Color(
    0xFFA78BFA,
  ); // Dark mode primary
  static const Color _violetPrimaryVariantDarkMode = Color(
    0xFFC4B5FD,
  ); // Dark mode variant

  /// Light Violet Ant Design Theme - Violet Fusion System
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.purple,
    primaryColor: _violetPrimary,
    // Make scaffold transparent to reveal global background gradient
    scaffoldBackgroundColor: Colors.transparent,

    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: _violetPrimary,
      secondary: _violetPrimaryDark,
      surface: VioletShades.lightSurfaceVariant,
      surfaceContainerHighest: VioletShades.lightSurfaceVariant,
      error: SemanticColors.destructive,
      outline: VioletShades.lightBorder,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: VioletShades.lightTextPrimary,
      onError: Colors.white,
    ),

    // App bar theme
    appBarTheme: const AppBarTheme(
      // Transparent so the global background can softly bleed through if needed
      backgroundColor: Colors.transparent,
      foregroundColor: VioletShades.lightTextPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: VioletShades.lightCardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _violetPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: VioletShades.lightCardBackground,
        foregroundColor: VioletShades.lightTextPrimary,
        side: const BorderSide(color: VioletShades.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VioletShades.lightTextPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VioletShades.lightWidgetBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VioletShades.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VioletShades.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _violetPrimary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SemanticColors.destructive),
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: VioletShades.lightSurfaceVariant,
      selectedItemColor: _violetPrimary,
      unselectedItemColor: VioletShades.lightTextMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: VioletShades.lightTextPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: VioletShades.lightTextPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: VioletShades.lightTextPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: VioletShades.lightTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: VioletShades.lightTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: VioletShades.lightTextPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: VioletShades.lightTextPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: VioletShades.lightTextPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: VioletShades.lightTextPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: VioletShades.lightTextPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: VioletShades.lightTextPrimary),
      bodySmall: TextStyle(fontSize: 12, color: VioletShades.lightTextMuted),
    ),
  );

  /// Dark Violet Ant Design Theme - Violet Fusion System
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.purple,
    primaryColor: _violetPrimaryDarkMode,
    // Make scaffold transparent to reveal global background gradient
    scaffoldBackgroundColor: Colors.transparent,

    // Color scheme
    colorScheme: const ColorScheme.dark(
      primary: _violetPrimaryDarkMode,
      secondary: _violetPrimaryVariantDarkMode,
      surface: VioletShades.darkSurfaceVariant,
      surfaceContainerHighest: VioletShades.darkSurfaceVariant,
      error: SemanticColors.destructiveForegroundDark,
      outline: VioletShades.darkBorder,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: VioletShades.darkTextPrimary,
      onError: Colors.black,
    ),

    // App bar theme
    appBarTheme: const AppBarTheme(
      // Transparent so the global background can softly bleed through if needed
      backgroundColor: Colors.transparent,
      foregroundColor: VioletShades.darkTextPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: VioletShades.darkCardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _violetPrimaryDarkMode,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: VioletShades.darkCardBackground,
        foregroundColor: VioletShades.darkTextPrimary,
        side: const BorderSide(color: VioletShades.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VioletShades.darkTextPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VioletShades.darkWidgetBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VioletShades.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: VioletShades.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _violetPrimaryDarkMode),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: SemanticColors.destructiveForegroundDark,
        ),
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: VioletShades.darkSurfaceVariant,
      selectedItemColor: _violetPrimaryDarkMode,
      unselectedItemColor: VioletShades.darkTextMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: VioletShades.darkTextPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: VioletShades.darkTextPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: VioletShades.darkTextPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: VioletShades.darkTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: VioletShades.darkTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: VioletShades.darkTextPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: VioletShades.darkTextPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: VioletShades.darkTextPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: VioletShades.darkTextPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: VioletShades.darkTextPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: VioletShades.darkTextPrimary),
      bodySmall: TextStyle(fontSize: 12, color: VioletShades.darkTextMuted),
    ),
  );

  /// Helper method to get semantic colors based on theme mode
  static Color getSemanticBackground(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case 'success':
        return isDark
            ? SemanticColors.successBackgroundDark
            : SemanticColors.successBackground;
      case 'warning':
        return isDark
            ? SemanticColors.warningBackgroundDark
            : SemanticColors.warningBackground;
      case 'destructive':
        return isDark
            ? SemanticColors.destructiveBackgroundDark
            : SemanticColors.destructiveBackground;
      default:
        return Theme.of(context).colorScheme.surface;
    }
  }

  static Color getSemanticForeground(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case 'success':
        return isDark
            ? SemanticColors.successForegroundDark
            : SemanticColors.successForeground;
      case 'warning':
        return isDark
            ? SemanticColors.warningForegroundDark
            : SemanticColors.warningForeground;
      case 'destructive':
        return isDark
            ? SemanticColors.destructiveForegroundDark
            : SemanticColors.destructiveForeground;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  /// Get violet shade for cards based on theme mode
  static Color getCardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? VioletShades.darkCardBackground
        : VioletShades.lightCardBackground;
  }

  /// Get violet shade for widgets based on theme mode
  static Color getWidgetBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? VioletShades.darkWidgetBackground
        : VioletShades.lightWidgetBackground;
  }

  /// Get violet surface variant based on theme mode
  static Color getSurfaceVariant(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? VioletShades.darkSurfaceVariant
        : VioletShades.lightSurfaceVariant;
  }

  /// Get violet accent color based on theme mode
  static Color getAccentColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkAccent : VioletShades.lightAccent;
  }

  /// Get violet hover color based on theme mode
  static Color getHoverColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkHover : VioletShades.lightHover;
  }

  /// Get elevated background for dark theme enhancement
  static Color getElevatedBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkElevated : VioletShades.lightAccent;
  }

  /// Get highlight color for focus states and emphasis
  static Color getHighlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkHighlight : VioletShades.lightHover;
  }

  /// Get subtle background for minimal elements
  static Color getSubtleBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkSubtle : VioletShades.lightBackground;
  }

  /// Get app background based on theme mode
  static Color getAppBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkBackground : VioletShades.lightBackground;
  }

  /// Get text colors based on theme mode
  static Color getTextPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? VioletShades.darkTextPrimary
        : VioletShades.lightTextPrimary;
  }

  static Color getTextMuted(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkTextMuted : VioletShades.lightTextMuted;
  }

  /// Get border color based on theme mode
  static Color getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? VioletShades.darkBorder : VioletShades.lightBorder;
  }
}

/// Extension for easy access to Violet Fusion Color System
extension ThemeExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Quick access to semantic colors
  Color successColor([bool isBackground = false]) => isBackground
      ? AppTheme.getSemanticBackground(this, 'success')
      : AppTheme.getSemanticForeground(this, 'success');

  Color warningColor([bool isBackground = false]) => isBackground
      ? AppTheme.getSemanticBackground(this, 'warning')
      : AppTheme.getSemanticForeground(this, 'warning');

  Color destructiveColor([bool isBackground = false]) => isBackground
      ? AppTheme.getSemanticBackground(this, 'destructive')
      : AppTheme.getSemanticForeground(this, 'destructive');

  /// Quick access to Violet Fusion violet shades
  Color get violetCardBg => AppTheme.getCardBackground(this);
  Color get violetWidgetBg => AppTheme.getWidgetBackground(this);
  Color get violetSurface => AppTheme.getSurfaceVariant(this);
  Color get violetAccent => AppTheme.getAccentColor(this);
  Color get violetHover => AppTheme.getHoverColor(this);

  /// Quick access to enhanced dark theme colors
  Color get elevatedBg => AppTheme.getElevatedBackground(this);
  Color get highlightColor => AppTheme.getHighlightColor(this);
  Color get subtleBg => AppTheme.getSubtleBackground(this);
  Color get appBackground => AppTheme.getAppBackground(this);

  /// Quick access to accessible text colors
  Color get textPrimary => AppTheme.getTextPrimary(this);
  Color get textMuted => AppTheme.getTextMuted(this);
  Color get borderColor => AppTheme.getBorderColor(this);
}
