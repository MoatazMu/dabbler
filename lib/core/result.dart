import 'package:fpdart/fpdart.dart';

import 'error/failures.dart';

typedef Result<T> = Either<Failure, T>;
