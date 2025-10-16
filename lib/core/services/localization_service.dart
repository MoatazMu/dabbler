import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'app_language';
  static const String _defaultLanguage = 'en';
  
  Locale _currentLocale = const Locale('en');
  bool _isInitialized = false;

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ar'), // Arabic
  ];

  // Language names for UI
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
  };

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;
  bool get isRTL => _currentLocale.languageCode == 'ar';

  /// Initialize localization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to get saved language preference
      String? savedLanguage = await _getSavedLanguage();
      
      if (savedLanguage != null) {
        // Use saved preference
        _currentLocale = Locale(savedLanguage);
      } else {
        // Detect device locale
        final deviceLocale = PlatformDispatcher.instance.locale;
        final deviceLanguage = deviceLocale.languageCode;
        
        // Check if device language is supported
        if (supportedLocales.any((locale) => locale.languageCode == deviceLanguage)) {
          _currentLocale = Locale(deviceLanguage);
        } else {
          // Default to English
          _currentLocale = const Locale(_defaultLanguage);
        }
        
        // Save the detected language
        await _saveLanguage(_currentLocale.languageCode);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing localization: $e');
      // Fallback to default
      _currentLocale = const Locale(_defaultLanguage);
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change app language
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLocales.any((locale) => locale.languageCode == languageCode)) {
      throw Exception('Unsupported language: $languageCode');
    }

    if (_currentLocale.languageCode == languageCode) return;

    _currentLocale = Locale(languageCode);
    
    // Save language preference
    await _saveLanguage(languageCode);
    
    notifyListeners();
  }

  /// Get saved language from local storage
  Future<String?> _getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      print('Error getting saved language: $e');
      return null;
    }
  }

  /// Save language to local storage
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  /// Get current language name
  String getCurrentLanguageName() {
    return languageNames[_currentLocale.languageCode] ?? 'Unknown';
  }

  /// Get all available languages
  Map<String, String> getAvailableLanguages() {
    return languageNames;
  }

  /// Check if a language is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLocales.any((locale) => locale.languageCode == languageCode);
  }

  /// Reset to default language
  Future<void> resetToDefault() async {
    await changeLanguage(_defaultLanguage);
  }
} 