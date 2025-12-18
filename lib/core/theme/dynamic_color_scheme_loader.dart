import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Utility to load a ColorScheme from a JSON file in design-system/tokens
class DynamicColorSchemeLoader {
  /// Loads a ColorScheme for the given category and brightness (light/dark)
  static Future<ColorScheme> load({
    required String category,
    required Brightness brightness,
  }) async {
    final theme = brightness == Brightness.dark ? 'dark' : 'light';
    final assetPath =
        'design-system/tokens/${category.toLowerCase()}-$theme-theme.json';
    final jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(jsonString);
    return _colorSchemeFromJson(data, brightness);
  }

  static ColorScheme _colorSchemeFromJson(
    Map<String, dynamic> json,
    Brightness brightness,
  ) {
    Color parse(String key) =>
        Color(int.parse(json[key].replaceFirst('#', '0xff')));
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
      onInverseSurface: parse('onInverseSurface'),
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
