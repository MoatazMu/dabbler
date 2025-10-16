import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/logger.dart';
import 'environment.dart';

class AppInitializer {
  static AppInitializer? _instance;
  static AppInitializer get instance => _instance ??= AppInitializer._();

  AppInitializer._();

  final _initializationSteps = <String, bool>{
    'environment': false,
    'preferences': false,
    'supabase': false,
    'theme': false,
  };

  late final SharedPreferences prefs;
  double get initializationProgress {
    if (_initializationSteps.isEmpty) return 1.0;
    final completed = _initializationSteps.values.where((v) => v).length;
    return completed / _initializationSteps.length;
  }

  Future<void> initializeApp() async {
    try {
      // Setup error handling
      setupErrorHandling();

      // Initialize environment
      await _initializeEnvironment();
      _initializationSteps['environment'] = true;

      // Initialize SharedPreferences
      await _initializePreferences();
      _initializationSteps['preferences'] = true;

      // Initialize Supabase
      await _initializeSupabase();
      _initializationSteps['supabase'] = true;

      // Initialize theme
      await _initializeTheme();
      _initializationSteps['theme'] = true;

      Logger.info('App initialization completed successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize app', e, stackTrace);
      rethrow;
    }
  }

  void setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      Logger.error('Flutter error', details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      Logger.error('Platform error', error, stack);
      return true;
    };
  }

  Future<void> _initializeEnvironment() async {
    try {
      await Environment.load();
      Logger.info('Environment initialized: ${Environment.environment}');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize environment', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _initializePreferences() async {
    try {
      prefs = await SharedPreferences.getInstance();
      Logger.info('SharedPreferences initialized');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize SharedPreferences', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
      );
      Logger.info('Supabase initialized');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize Supabase', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeTheme() async {
    try {
      // Initialize theme service or load saved theme
      final savedTheme = prefs.getString('app_theme');
      Logger.info('Theme initialized: $savedTheme');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize theme', e, stackTrace);
      rethrow;
    }
  }

  Future<void> resetApp() async {
    try {
      await prefs.clear();
      _initializationSteps.updateAll((key, value) => false);
      Logger.info('App reset completed');
    } catch (e, stackTrace) {
      Logger.error('Failed to reset app', e, stackTrace);
      rethrow;
    }
  }
}
