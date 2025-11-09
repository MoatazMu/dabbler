import 'package:flutter/material.dart';
// Colors are intentionally not referenced here to keep styles const and
// theme-agnostic; set colors at usage sites when needed.

/// Design System Typography
/// Standard text styles for the entire app
class AppTypography {
  // ========== Display Text (Large Headers) ==========

  /// Extra large display text (e.g., "Moataz!")
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  /// Medium display text
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // ========== Headings ==========

  /// Large heading (20px)
  static const TextStyle headingLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  /// Medium heading (18px)
  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// Small heading (16px)
  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ========== Body Text ==========

  /// Regular body text (15px)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  /// Medium body text (14px)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Small body text (13px)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // ========== Labels & Captions ==========

  /// Label text (12px)
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Caption text (11px)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // ========== Special Purpose ==========

  /// Greeting text (e.g., "Good morning,")
  static const TextStyle greeting = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Button text
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
}
