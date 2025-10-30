import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/types/result.dart';
import '../../services/supabase/supabase_service.dart';

abstract class BaseRepository {
  final SupabaseService svc;
  const BaseRepository(this.svc);

  /// Wrap an async operation and map common Supabase exceptions.
  Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Right(value);
    } on PostgrestException catch (e) {
      return Left(svc.mapPostgrest(e));
    } catch (e, st) {
      return Left(svc.mapGeneric(e, st));
    }
  }
}
