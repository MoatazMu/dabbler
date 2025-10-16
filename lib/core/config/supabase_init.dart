import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseInit {
  /// Initialize Supabase with your project credentials
  /// 
  /// To get your credentials:
  /// 1. Go to your Supabase project dashboard
  /// 2. Navigate to Settings > API
  /// 3. Copy the Project URL and anon/public key
  /// 4. Update the values in lib/core/config/supabase_config.dart
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      print('📝 Please check your Supabase configuration in lib/core/config/supabase_config.dart');
      rethrow;
    }
  }

  /// Check if Supabase is properly configured
  static bool isConfigured() {
    return SupabaseConfig.url != 'https://your-project-ref.supabase.co' &&
           SupabaseConfig.anonKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrbWhyeGR3Z2VneGtka2R1a2dxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjcyNjIsImV4cCI6MjA2OTgwMzI2Mn0.xzE24mCrAJsZk58Hni4TfXvbHYgf-LHJjCzpgCmuaFA';
  }

  /// Get configuration status message
  static String getConfigStatus() {
    if (!isConfigured()) {
      return '''
⚠️  Supabase not configured!

To connect to your Supabase database:

1. Go to your Supabase project dashboard
2. Navigate to Settings > API
3. Copy the Project URL and anon/public key
4. Update the values in lib/core/config/supabase_config.dart:

   static const String url = 'YOUR_ACTUAL_PROJECT_URL';
   static const String anonKey = 'YOUR_ACTUAL_ANON_KEY';

5. Restart the app
''';
    }
    return '✅ Supabase configured correctly';
  }
} 