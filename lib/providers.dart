library providers;

export 'features/app_boot/providers.dart';
export 'features/app_boot/schema_guard.dart';
export 'features/profile/providers.dart';
export 'features/sport_profiles/providers.dart';
export 'features/venues/providers.dart';
export 'services/supabase_service.dart';

// In your app root (e.g., main.dart or App widget), wrap MaterialApp:
/// ...
/// return ProviderScope(
///   child: SchemaGuard(
///     child: MaterialApp(
///       // existing config
///     ),
///   ),
/// );
