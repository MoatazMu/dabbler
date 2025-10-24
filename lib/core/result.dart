import 'package:dabbler/core/error/failures.dart';
import 'package:dabbler/core/utils/either.dart';

/// Alias for functions returning either a [Failure] or a successful [T] value.
typedef Result<T> = Either<Failure, T>;
