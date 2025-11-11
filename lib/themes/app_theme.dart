import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'material3_extensions.dart' as material3_extensions;
export 'material3_extensions.dart';

/// Category-specific colors for different app sections
/// @deprecated Use ColorScheme extension methods instead: colorScheme.categoryMain
@Deprecated('Use ColorScheme extension methods instead')
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

  // App-specific color tokens
  static const Color _successColor = Color(0xFF00A63E);
  static const Color _warningColor = Color(0xFFEC8F1E);
  static const Color _infoLinkColor = Color(0xFF155DFC);

  /// Light Material Design 3 Theme
  static ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    seedColor: _primarySeed,
  );

  /// Dark Material Design 3 Theme
  static ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    seedColor: _primarySeed,
  );

  /// Build Material 3 theme with comprehensive tokens
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final textTheme = GoogleFonts.robotoTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    );

    // Material 3 shape system - using rounded corners
    const shapeSmall = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
    const shapeMedium = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    const shapeLarge = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme - Material 3 uses elevation 0 and surface containers
      cardTheme: CardThemeData(
        elevation: 0,
        shape: shapeMedium,
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(4),
      ),

      // Button Themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: shapeMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(64, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: shapeMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(64, 40),
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: shapeMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(64, 40),
          side: BorderSide(color: colorScheme.outline),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: shapeMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(64, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: shapeSmall,
          minimumSize: const Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Chip Theme - Material 3 chip styling
      chipTheme: ChipThemeData(
        shape: shapeSmall,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        deleteIconColor: colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        side: BorderSide.none,
        checkmarkColor: colorScheme.onPrimaryContainer,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        brightness: brightness,
      ),

      // Navigation Themes
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: shapeMedium,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onSecondaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        indicatorColor: colorScheme.secondaryContainer,
      ),
      drawerTheme: DrawerThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
      ),

      // Segmented Button Theme
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(shapeSmall),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),

      // Search Bar Theme
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest,
        ),
        shape: WidgetStateProperty.all(shapeMedium),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textStyle: WidgetStateProperty.all(textTheme.bodyLarge),
        hintStyle: WidgetStateProperty.all(
          textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: shapeMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.secondaryContainer,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: shapeSmall,
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Badge Theme
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: shapeLarge,
        backgroundColor: colorScheme.surfaceContainer,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        backgroundColor: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        shape: shapeMedium,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        shape: const CircleBorder(),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      // App-specific theme extensions
      extensions: <ThemeExtension<dynamic>>[
        material3_extensions.AppThemeExtension(
          success: _successColor,
          warning: _warningColor,
          infoLink: _infoLinkColor,
          danger: null, // Use ColorScheme.error
        ),
      ],
    );
  }

  /// Helper to get category color based on theme brightness
  /// @deprecated Use colorScheme.getCategoryColor() instead
  @Deprecated('Use colorScheme.getCategoryColor() instead')
  static Color getCategoryColor(BuildContext context, String category) {
    return Theme.of(context).colorScheme.getCategoryColor(category);
  }

  // Compatibility methods for legacy code
  /// @deprecated Use colorScheme.surfaceContainer instead
  @Deprecated('Use colorScheme.surfaceContainer instead')
  static Color getCardBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  /// @deprecated Use colorScheme.onSurface instead
  @Deprecated('Use colorScheme.onSurface instead')
  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// @deprecated Use colorScheme.outline instead
  @Deprecated('Use colorScheme.outline instead')
  static Color getBorderColor(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
}

/// Extension for easy theme access
///
/// This extension provides convenient access to Material 3 theme properties.
/// For app-specific theme extensions (success, warning, etc.), use the
/// AppThemeExtensionContext from material3_extensions.dart.
extension ThemeContextExtension on BuildContext {
  /// Material 3 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Alias for compatibility
  ColorScheme get colors => colorScheme;

  /// Material 3 TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Check if dark mode is active
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Quick access to common Material 3 colors
  Color get primaryColor => colorScheme.primary;
  Color get surfaceColor => colorScheme.surface;
  Color get backgroundColor => colorScheme.surface;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onSurfaceColor => colorScheme.onSurface;

  // Material 3 surface container variants
  Color get surfaceContainer => colorScheme.surfaceContainer;
  Color get surfaceContainerLow => colorScheme.surfaceContainerLow;
  Color get surfaceContainerLowest => colorScheme.surfaceContainerLowest;
  Color get surfaceContainerHigh => colorScheme.surfaceContainerHigh;
  Color get surfaceContainerHighest => colorScheme.surfaceContainerHighest;

  // Legacy compatibility helpers (deprecated but maintained for backward compatibility)
  /// @deprecated Use surfaceContainerHighest instead
  @Deprecated('Use surfaceContainerHighest instead')
  Color get violetCardBg => colorScheme.surfaceContainerHighest;

  /// @deprecated Use surfaceContainer instead
  @Deprecated('Use surfaceContainer instead')
  Color get violetWidgetBg => colorScheme.surfaceContainer;

  /// @deprecated Use surface instead
  @Deprecated('Use surface instead')
  Color get violetSurface => colorScheme.surface;

  /// Category colors using Material 3 extension
  Color categoryColor(String category) {
    return colorScheme.getCategoryColor(category);
  }
}
