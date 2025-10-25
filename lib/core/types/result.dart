import 'package:dartz/dartz.dart';
import '../error/failure.dart';

typedef Result<T> = Either<Failure, T>;
