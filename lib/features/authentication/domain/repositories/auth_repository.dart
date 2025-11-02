
import 'package:fpdart/fpdart.dart';
import '../entities/user.dart';
import '../entities/auth_session.dart';
import 'package:dabbler/core/fp/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> signInWithEmail({required String email, required String password});
  Future<Either<Failure, AuthSession>> signInWithPhone({required String phone});
  Future<Either<Failure, AuthSession>> signUp({required String email, required String password});
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, AuthSession>> getCurrentSession();
  Future<Either<Failure, void>> resetPassword({required String email});
  Future<Either<Failure, void>> updatePassword({required String newPassword});
  Future<Either<Failure, AuthSession>> verifyOTP({required String phone, required String token});
}
