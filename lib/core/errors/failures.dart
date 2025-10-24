import 'package:equatable/equatable.dart';

/// Base failure type used across the application.
abstract class Failure extends Equatable {
  /// A human readable description of the error.
  final String message;

  /// Optional root cause used for logging/debugging.
  final Object? cause;

  /// Optional stack trace associated with the error.
  final StackTrace? stackTrace;

  const Failure(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, cause];
}

class AuthFailure extends Failure {
  const AuthFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Invalid credentials',
  ]);
}

class EmailAlreadyExistsFailure extends AuthFailure {
  const EmailAlreadyExistsFailure([
    super.message = 'Email already exists',
  ]);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message = 'Weak password',
  ]);
}

class UnverifiedEmailFailure extends AuthFailure {
  const UnverifiedEmailFailure([
    super.message = 'Email not verified',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'You are not allowed to perform this action',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'Requested resource was not found',
  ]);
}

class ConflictFailure extends Failure {
  const ConflictFailure([
    super.message = 'Resource already exists',
  ]);
}

class ValidationFailure extends Failure {
  final Map<String, dynamic>? details;

  const ValidationFailure(
    super.message, {
    this.details,
    super.cause,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, cause, details];
}

class SupabaseFailure extends Failure {
  final String? code;
  final Map<String, dynamic>? details;

  const SupabaseFailure(
    super.message, {
    this.code,
    this.details,
    super.cause,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, cause, code, details];
}

class SupabaseAuthFailure extends SupabaseFailure {
  const SupabaseAuthFailure(
    super.message, {
    super.code,
    super.details,
    super.cause,
    super.stackTrace,
  });
}

class SupabaseAuthorizationFailure extends SupabaseFailure {
  const SupabaseAuthorizationFailure({
    String message = 'You do not have access to this resource',
    String? code,
    Map<String, dynamic>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          details: details,
          cause: cause,
          stackTrace: stackTrace,
        );
}

class SupabaseNotFoundFailure extends SupabaseFailure {
  const SupabaseNotFoundFailure({
    String message = 'Supabase resource not found',
    String? code,
    Map<String, dynamic>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          details: details,
          cause: cause,
          stackTrace: stackTrace,
        );
}

class SupabaseConflictFailure extends SupabaseFailure {
  const SupabaseConflictFailure({
    String message = 'Resource conflict detected',
    String? code,
    Map<String, dynamic>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          details: details,
          cause: cause,
          stackTrace: stackTrace,
        );
}

class SupabaseValidationFailure extends SupabaseFailure {
  const SupabaseValidationFailure({
    String message = 'Supabase validation error',
    Map<String, dynamic>? details,
    String? code,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message,
          details: details,
          code: code,
          cause: cause,
          stackTrace: stackTrace,
        );
}
