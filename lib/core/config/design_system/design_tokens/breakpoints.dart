import 'package:flutter/material.dart';

/// Breakpoint system following Ant Design's responsive design principles
class DabblerBreakpoints {
  // Breakpoint Values (in pixels)
  static const double mobile = 0;
  static const double tablet = 576;
  static const double desktop = 992;

  // Max Widths for Content
  static const double mobileMaxWidth = 575;
  static const double tabletMaxWidth = 991;
  static const double desktopMaxWidth = 1440;

  // Helper Methods
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < tablet;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= desktop;
  }

  /// Returns a value based on the current breakpoint
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= DabblerBreakpoints.desktop) {
      return desktop ?? tablet ?? mobile;
    }

    if (width >= DabblerBreakpoints.tablet) {
      return tablet ?? mobile;
    }

    return mobile;
  }

  /// Get the current breakpoint name
  static String getCurrentBreakpoint(BuildContext context) {
    if (isDesktop(context)) return 'desktop';
    if (isTablet(context)) return 'tablet';
    return 'mobile';
  }

  /// Get the maximum content width for the current breakpoint
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return desktopMaxWidth;
    if (isTablet(context)) return tabletMaxWidth;
    return mobileMaxWidth;
  }

  /// Determine if the screen is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get a padding that increases with screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return responsiveValue<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get a width ratio based on screen size (useful for responsive widgets)
  static double getWidthRatio(BuildContext context) {
    return responsiveValue<double>(
      context: context,
      mobile: 0.9,    // 90% of screen width
      tablet: 0.8,    // 80% of screen width
      desktop: 0.7,   // 70% of screen width
    );
  }

  /// Calculate number of grid columns based on breakpoint
  static int getGridColumns(BuildContext context) {
    return responsiveValue<int>(
      context: context,
      mobile: 4,     // 4 columns for mobile
      tablet: 8,     // 8 columns for tablet
      desktop: 12,   // 12 columns for desktop
    );
  }
}
