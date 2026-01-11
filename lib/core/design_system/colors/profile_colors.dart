import 'package:flutter/material.dart';

/// Profile category color tokens from design system
/// Extracted from lib/design_system/tokens/profile-light-theme.json
/// and lib/design_system/tokens/profile-dark-theme.json
class ProfileColors {
  ProfileColors._(); // Private constructor to prevent instantiation

  // Primary colors
  static const Color primaryLight = Color(0xFFF6AA4F);
  static const Color primaryDark = Color(0xFFFFF4CC);

  // On Primary colors
  static const Color onPrimaryLight = Color(0xFF3F2600);
  static const Color onPrimaryDark = Color(0xFF452B00);

  // Primary Container colors
  static const Color primaryContainerLight = Color(0xFFFFF4CC);
  static const Color primaryContainerDark = Color(0xFFD48628);

  // On Primary Container colors
  static const Color onPrimaryContainerLight = Color(0xFF2A1700);
  static const Color onPrimaryContainerDark = Color(0xFF2A1700);

  // Secondary colors
  static const Color secondaryLight = Color(0xFF703900);
  static const Color secondaryDark = Color(0xFFF2954B);

  // On Secondary colors
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF3E2000);

  // Secondary Container colors
  static const Color secondaryContainerLight = Color(0xFFFFFBEE);
  static const Color secondaryContainerDark = Color(0xFF5A3200);

  // On Secondary Container colors
  static const Color onSecondaryContainerLight = Color(0xFF251100);
  static const Color onSecondaryContainerDark = Color(0xFFFFDDBC);

  // Tertiary colors
  static const Color tertiaryLight = Color(0xFFAD8A67);
  static const Color tertiaryDark = Color(0xFF9B6D4B);

  // Error colors
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFBFF);
  static const Color surfaceDark = Color(0xFF17130E);

  // Outline colors
  static const Color outlineLight = Color(0xFF7F7667);
  static const Color outlineDark = Color(0xFF999080);

  /// Get primary color based on brightness
  static Color getPrimaryColor(Brightness brightness) {
    return brightness == Brightness.dark ? primaryDark : primaryLight;
  }

  /// Get on-primary color based on brightness
  static Color getOnPrimaryColor(Brightness brightness) {
    return brightness == Brightness.dark ? onPrimaryDark : onPrimaryLight;
  }

  /// Get primary container color based on brightness
  static Color getPrimaryContainerColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? primaryContainerDark
        : primaryContainerLight;
  }
}
