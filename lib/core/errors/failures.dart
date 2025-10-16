abstract class Failure {
  final String message;
  const Failure(this.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([super.message = 'Invalid credentials']);
}

class EmailAlreadyExistsFailure extends AuthFailure {
  const EmailAlreadyExistsFailure([super.message = 'Email already exists']);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([super.message = 'Weak password']);
}

class UnverifiedEmailFailure extends AuthFailure {
  const UnverifiedEmailFailure([super.message = 'Email not verified']);
}
