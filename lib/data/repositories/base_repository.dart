import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';
import '../../core/result.dart';
import '../../services/supabase_service.dart';

abstract class BaseRepository {
  BaseRepository(this.svc);

  final SupabaseService svc;

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
}
