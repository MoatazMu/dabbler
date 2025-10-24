import 'package:dabbler/services/supabase_service.dart';

/// Base class for repositories backed by Supabase.
abstract class BaseRepository {
  const BaseRepository(this.svc);

  /// Shared Supabase service.
  final SupabaseService svc;
}
