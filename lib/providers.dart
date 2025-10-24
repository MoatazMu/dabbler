import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dabbler/services/supabase_service.dart';

/// Root provider for the shared [SupabaseService] instance.
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);

// Feature specific repositories can expose additional providers here.
