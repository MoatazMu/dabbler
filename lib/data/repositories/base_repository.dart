import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/fp/result.dart' as core;
import 'package:dabbler/core/fp/failure.dart';
import '../../services/supabase/supabase_service.dart';

typedef Result<T> = core.Result<T, Failure>;

abstract class BaseRepository {
  final SupabaseService svc;
  const BaseRepository(this.svc);

  /// Wrap an async operation and map common Supabase exceptions.
  Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return core.Ok(value);
    } on PostgrestException catch (e) {
      return core.Err(svc.mapPostgrest(e));
    } catch (e, st) {
      return core.Err(svc.mapGeneric(e, st));
    }
  }
}
