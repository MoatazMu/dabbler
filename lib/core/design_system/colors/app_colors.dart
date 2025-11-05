import 'package:flutter/material.dart';

/// Design System Colors
/// Central color definitions for the entire app
class AppColors {
  // ========== Primary Colors ==========
  /// Primary purple for top sections and key UI elements
  static const Color primaryPurple = Color(0xFF6B2D9E);

  /// Light purple variant
  static const Color primaryPurpleLight = Color(0xFFE8E3FF);

  // ========== Background Colors ==========
  /// Main dark background
  static const Color backgroundDark = Color(0xFF1A1A1A);

  /// Secondary dark background for cards
  static const Color backgroundCardDark = Color(0xFF2D2D2D);

  /// Light background for light theme
  static const Color backgroundLight = Color(0xFFF5F5F5);

  /// Light purple background for light theme
  static const Color backgroundLightPurple = Color(0xFFE8E3FF);

  // ========== Border Colors ==========
  /// Dark border color
  static const Color borderDark = Color(0xFF404040);

  /// Light border color
  static const Color borderLight = Color(0xFFE0E0E0);

  // ========== Text Colors ==========
  /// Primary text color (white for dark theme)
  static const Color textPrimary = Colors.white;

  /// Secondary text color (light gray)
  static const Color textSecondary = Color(0xFFAAAAAA);

  /// Tertiary text color (medium gray)
  static const Color textTertiary = Color(0xFFCCCCCC);

  /// Dark text for light backgrounds
  static const Color textDark = Color(0xFF1A1A1A);

  // ========== Semantic Colors ==========
  /// Error/danger color
  static const Color error = Color(0xFFFF4444);

  /// Success color
  static const Color success = Color(0xFF4CAF50);

  /// Warning color
  static const Color warning = Color(0xFFFFA726);

  /// Info color
  static const Color info = Color(0xFF29B6F6);
}
