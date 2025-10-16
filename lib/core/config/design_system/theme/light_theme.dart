import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Light theme implementation
class DabblerLightTheme {
  static ThemeData get theme => DabblerTheme.light;

  // Light Theme Specific Colors
  static const Color primary = Color(0xFF8B5CF6);
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFFAFAFA);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  
  // Overlay Colors
  static Color overlay = Colors.black.withValues(alpha: 0.5);
  
  // Shadow Colors
  static List<BoxShadow> get shadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];
}
