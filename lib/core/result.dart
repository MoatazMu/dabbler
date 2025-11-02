import 'package:fpdart/fpdart.dart';
import 'errors/failure.dart';

/// Alias for functions returning either a [Failure] or a successful [T] value.
/// Uses fpdart's Either type for functional error handling.
typedef Result<T> = Either<Failure, T>;
