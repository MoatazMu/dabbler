import 'package:fpdart/fpdart.dart';
import 'package:dabbler/core/fp/failure.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import 'usecase.dart';

class RegisterUseCase
    extends UseCase<Either<Failure, AuthSession>, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, AuthSession>> call(RegisterParams params) async {
    if (params.email.isEmpty || params.password.isEmpty) {
      return Left(AuthFailure(message: 'Email and password must not be empty'));
    }
    return repository.signUp(email: params.email, password: params.password);
  }
}

class RegisterParams {
  final String email;
  final String password;
  RegisterParams({required this.email, required this.password});
}
