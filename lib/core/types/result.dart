import 'package:fpdart/fpdart.dart';

import 'package:dabbler/core/error/failure.dart';

/// Convenient alias for returning domain aware results from repositories.
typedef Result<T> = Either<Failure, T>;
