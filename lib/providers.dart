library providers;

export 'features/app_boot/providers.dart';
export 'features/app_boot/schema_guard.dart';
export 'features/profile/providers.dart';
export 'features/sport_profiles/providers.dart';
export 'features/venues/providers.dart';
export 'services/supabase_service.dart';
export 'features/profile/providers.dart';
export 'features/social/circles_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dabbler/services/supabase_service.dart';

/// Root provider for the shared [SupabaseService] instance.
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);

// Feature specific repositories can expose additional providers here.
export 'features/social/providers.dart';
