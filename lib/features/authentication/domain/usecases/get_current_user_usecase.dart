import 'package:fpdart/fpdart.dart';
import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/data/models/authentication/user.dart';
import '../repositories/auth_repository.dart';
import 'usecase.dart';

class GetCurrentUserUseCase extends UseCase<Either<Failure, User>, NoParams> {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return repository.getCurrentUser();
  }
}
