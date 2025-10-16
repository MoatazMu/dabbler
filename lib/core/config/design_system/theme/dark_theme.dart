import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Dark theme implementation
class DabblerDarkTheme {
  static ThemeData get theme => DabblerTheme.dark;

  // Dark Theme Specific Colors
  static const Color primary = Color(0xFF8B5CF6);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color background = Color(0xFF121212);
  
  // Status Colors
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFFD1D5DB);
  
  // Border Colors
  static const Color border = Color(0xFF374151);
  static const Color divider = Color(0xFF374151);
  
  // Overlay Colors
  static Color overlay = Colors.black.withValues(alpha: 0.7);
  
  // Shadow Colors
  static List<BoxShadow> get shadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      offset: const Offset(0, 1),
      blurRadius: 4,
    ),
  ];
}
