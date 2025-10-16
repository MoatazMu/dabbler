import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  User? _cachedUser;

  AuthRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, AuthSession>> signInWithEmail({required String email, required String password}) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkFailure('No internet connection'));
    }
    try {
      final response = await remoteDataSource.signInWithEmail(email: email, password: password);
      _cacheUser(response.user as User?);
      if (response.session == null) {
        return left(AuthFailure('No session returned from authentication'));
      }
      return right(response.session!);
    } on InvalidCredentialsException {
      return left(InvalidCredentialsFailure());
    } on UnverifiedEmailException {
      return left(UnverifiedEmailFailure());
    } on NetworkException {
      return left(NetworkFailure('Network error'));
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> signInWithPhone({required String phone}) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkFailure('No internet connection'));
    }
    try {
      final response = await remoteDataSource.signInWithPhone(phone: phone);
      _cacheUser(response.user as User?);
      return right(response.session!);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> signUp({required String email, required String password}) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkFailure('No internet connection'));
    }
    try {
      final response = await remoteDataSource.signUp(email: email, password: password);
      _cacheUser(response.user as User?);
      return right(response.session!);
    } on EmailAlreadyExistsException {
      return left(EmailAlreadyExistsFailure());
    } on WeakPasswordException {
      return left(WeakPasswordFailure());
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      _cachedUser = null;
      return right(null);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      if (_cachedUser != null) return right(_cachedUser!);
      final user = await remoteDataSource.getCurrentUser();
      _cacheUser(user as User);
      return right(user as User);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> getCurrentSession() async {
    try {
      final response = await remoteDataSource.getCurrentSession();
      return right(response.session!);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await remoteDataSource.resetPassword(email: email);
      return right(null);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({required String newPassword}) async {
    try {
      await remoteDataSource.updatePassword(newPassword: newPassword);
      return right(null);
    } on WeakPasswordException {
      return left(WeakPasswordFailure());
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> verifyOTP({required String phone, required String token}) async {
    try {
      final response = await remoteDataSource.verifyOTP(phone: phone, token: token);
      _cacheUser(response.user as User?);
      return right(response.session!);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(AuthFailure('Unknown error: $e'));
    }
  }

  void _cacheUser(User? user) {
    if (user != null) {
      _cachedUser = user;
    }
  }
}
