import 'package:dabbler/core/error/failures.dart';
import 'package:dabbler/services/supabase/supabase_service.dart';

abstract class BaseRepository {
  BaseRepository(this.svc);

  final SupabaseService svc;

  Failure mapPostgrestError(Object error) {
    return svc.mapPostgrestError(error);
  }
}
