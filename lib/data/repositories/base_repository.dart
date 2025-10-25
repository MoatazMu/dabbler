import 'package:dabbler/core/error/failures.dart';
import 'package:dabbler/services/supabase/supabase_service.dart';
import 'package:dabbler/services/supabase_service.dart';

/// Base class for repositories backed by Supabase.
abstract class BaseRepository {
  const BaseRepository(this.svc);

  /// Shared Supabase service.
  final SupabaseService svc;
import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../core/result.dart';
import '../../services/supabase_service.dart';

abstract class BaseRepository {
  BaseRepository(this.svc);

  final SupabaseService svc;

  Failure mapPostgrestError(Object error) {
    return svc.mapPostgrestError(error);
  }
  Result<T> success<T>(T value) => right(value);

  Result<T> failure<T>(Failure error) => left(error);

  Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return right(result);
    } catch (error) {
      return left(svc.mapPostgrestError(error));
    }
  }
import 'package:dabbler/services/supabase_service.dart';

/// Base contract for repositories requiring Supabase access.
abstract class BaseRepository {
  /// Shared Supabase service reference.
  final SupabaseService svc;

  /// Creates a repository with the provided [SupabaseService].
  const BaseRepository(this.svc);
}
