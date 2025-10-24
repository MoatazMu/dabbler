import 'package:dabbler/services/supabase_service.dart';

/// Base contract for repositories requiring Supabase access.
abstract class BaseRepository {
  /// Shared Supabase service reference.
  final SupabaseService svc;

  /// Creates a repository with the provided [SupabaseService].
  const BaseRepository(this.svc);
}
