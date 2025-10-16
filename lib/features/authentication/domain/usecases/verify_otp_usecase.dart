import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import 'usecase.dart';

class VerifyOtpUseCase extends UseCase<Either<Failure, AuthSession>, VerifyOtpParams> {
  final AuthRepository repository;
  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthSession>> call(VerifyOtpParams params) async {
    if (params.phone.isEmpty || params.token.isEmpty) {
      return Left(AuthFailure('Phone and token must not be empty'));
    }
    return repository.verifyOTP(phone: params.phone, token: params.token);
  }
}

class VerifyOtpParams {
  final String phone;
  final String token;
  VerifyOtpParams({required this.phone, required this.token});
}
