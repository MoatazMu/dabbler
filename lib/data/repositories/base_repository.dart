import '../../core/errors/failures.dart';
import '../../services/supabase/supabase_service.dart';

/// Common base for repositories backed by [SupabaseService].
abstract class BaseRepository {
  BaseRepository(this.svc);

  /// Shared Supabase service for performing queries and realtime operations.
  final SupabaseService svc;

  /// Maps [error] into a typed [Failure] using the service mapper.
  Failure mapError(
    Object error, {
    StackTrace? stackTrace,
  }) {
    return svc.mapPostgrestError(
      error,
      stackTrace: stackTrace,
    );
  }
}
