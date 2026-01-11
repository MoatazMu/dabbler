import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Utility to load a ColorScheme from a JSON file in design-system/tokens
class DynamicColorSchemeLoader {
  static const String _tokenBasePath = 'lib/design_system/tokens';

  /// Loads a ColorScheme for the given category and brightness (light/dark)
  static Future<ColorScheme> load({
    required String category,
    required Brightness brightness,
  }) async {
    final theme = brightness == Brightness.dark ? 'dark' : 'light';
    final normalizedCategory = _normalizeCategory(category);

    // Token files use "activity-*-theme.json" (singular) but the app often
    // refers to the category as "activities". Keep this tolerant.
    final candidates = <String>{
      '$_tokenBasePath/${normalizedCategory.toLowerCase()}-$theme-theme.json',
      // Back-compat fallbacks
      '$_tokenBasePath/${category.toLowerCase()}-$theme-theme.json',
    }.toList();

    String? jsonString;
    String? lastError;
    for (final assetPath in candidates) {
      try {
        if (kDebugMode) {
          debugPrint('🎨 [ColorScheme] Attempting to load: $assetPath');
        }
        jsonString = await rootBundle.loadString(assetPath);
        if (kDebugMode) {
          debugPrint('✅ [ColorScheme] Successfully loaded: $assetPath');
        }
        break;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ [ColorScheme] Failed to load $assetPath: $e');
        }
        lastError = e.toString();
      }
    }

    if (jsonString == null) {
      throw FlutterError(
        'Unable to load color scheme tokens for category="$category" theme="$theme".\n'
        'Tried: ${candidates.join(', ')}\n'
        'Last error: $lastError',
      );
    }

    final Map<String, dynamic> data = json.decode(jsonString);
    return _colorSchemeFromJson(data, brightness);
  }

  static String _normalizeCategory(String category) {
    switch (category.toLowerCase()) {
      case 'activities':
        return 'activity';
      default:
        return category;
    }
  }

  static ColorScheme _colorSchemeFromJson(
    Map<String, dynamic> json,
    Brightness brightness,
  ) {
    // Token files are stored as { "socialDark": { ...colors... } }.
    // Normalize to the inner map so the parser can read keys like "primary".
    if (json.length == 1 && json.values.first is Map<String, dynamic>) {
      json = json.values.first as Map<String, dynamic>;
    }

    Color parse(String key) {
      final value = json[key];
      if (value is! String) {
        throw FlutterError('Missing/invalid color token "$key"');
      }
      return Color(int.parse(value.replaceFirst('#', '0xff')));
    }

    return ColorScheme(
      brightness: brightness,
      primary: parse('primary'),
      onPrimary: parse('onPrimary'),
      primaryContainer: parse('primaryContainer'),
      onPrimaryContainer: parse('onPrimaryContainer'),
      secondary: parse('secondary'),
      onSecondary: parse('onSecondary'),
      secondaryContainer: parse('secondaryContainer'),
      onSecondaryContainer: parse('onSecondaryContainer'),
      tertiary: parse('tertiary'),
      onTertiary: parse('onTertiary'),
      tertiaryContainer: parse('tertiaryContainer'),
      onTertiaryContainer: parse('onTertiaryContainer'),
      error: parse('error'),
      onError: parse('onError'),
      errorContainer: parse('errorContainer'),
      onErrorContainer: parse('onErrorContainer'),
      surface: parse('surface'),
      onSurface: parse('onSurface'),
      surfaceContainerHighest: parse('surfaceContainerHighest'),
      surfaceContainerHigh: parse('surfaceContainerHigh'),
      surfaceContainer: parse('surfaceContainer'),
      surfaceContainerLow: parse('surfaceContainerLow'),
      surfaceContainerLowest: parse('surfaceContainerLowest'),
      onSurfaceVariant: parse('onSurfaceVariant'),
      outline: parse('outline'),
      outlineVariant: parse('outlineVariant'),
      shadow: parse('shadow'),
      scrim: parse('scrim'),
      inverseSurface: parse('inverseSurface'),
      // Token json uses "inverseOnSurface"; normalize.
      onInverseSurface: json.containsKey('onInverseSurface')
          ? parse('onInverseSurface')
          : parse('inverseOnSurface'),
      inversePrimary: parse('inversePrimary'),
      surfaceTint: parse('surfaceTint'),
      primaryFixed: parse('primaryFixed'),
      onPrimaryFixed: parse('onPrimaryFixed'),
      primaryFixedDim: parse('primaryFixedDim'),
      onPrimaryFixedVariant: parse('onPrimaryFixedVariant'),
      secondaryFixed: parse('secondaryFixed'),
      onSecondaryFixed: parse('onSecondaryFixed'),
      secondaryFixedDim: parse('secondaryFixedDim'),
      onSecondaryFixedVariant: parse('onSecondaryFixedVariant'),
      tertiaryFixed: parse('tertiaryFixed'),
      onTertiaryFixed: parse('onTertiaryFixed'),
      tertiaryFixedDim: parse('tertiaryFixedDim'),
      onTertiaryFixedVariant: parse('onTertiaryFixedVariant'),
      surfaceDim: parse('surfaceDim'),
      surfaceBright: parse('surfaceBright'),
    );
  }
}
