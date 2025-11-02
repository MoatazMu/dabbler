import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class Failure extends Equatable {
  const Failure({
    required this.message,
    this.cause,
    this.stackTrace,
    this.code,
    this.details,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  final String? code;
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [message, code, details, cause];
}

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class UnauthenticatedFailure extends AuthFailure {
  const UnauthenticatedFailure({
    super.message = 'User not authenticated',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message = 'You do not have permission to perform this action',
    super.cause,
    super.stackTrace,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Requested resource was not found',
    super.cause,
    super.stackTrace,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Validation failed',
    this.fieldErrors,
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });

  final Map<String, List<String>>? fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network request failed',
    this.status,
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });

  final int? status;

  @override
  List<Object?> get props => [...super.props, status];
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure({
    super.message = 'The request timed out',
    super.status,
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class DataFailure extends Failure {
  const DataFailure({
    super.message = 'Data operation failed',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache operation failed',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database operation failed',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to perform this action',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure({
    super.message = 'Business rule validation failed',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class ConflictFailure extends Failure {
  const ConflictFailure({
    super.message = 'Resource conflict detected',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class FileUploadFailure extends Failure {
  const FileUploadFailure({
    super.message = 'Failed to upload file',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class FileDownloadFailure extends Failure {
  const FileDownloadFailure({
    super.message = 'Failed to download file',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure({
    super.message = 'File not found',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred',
    super.cause,
    super.stackTrace,
    super.code,
    super.details,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    this.error,
    super.stackTrace,
    super.code,
    super.details,
  }) : super(cause: error);

  final Object? error;

  @override
  List<Object?> get props => [...super.props, error];
}

class SupabaseFailure extends Failure {
  const SupabaseFailure({
    super.message = 'Supabase request failed',
    super.code,
    super.details,
    super.cause,
    super.stackTrace,
  });
}

class SupabaseAuthFailure extends SupabaseFailure {
  const SupabaseAuthFailure({
    super.message = 'Supabase authentication failed',
    super.code,
    super.details,
    super.cause,
    super.stackTrace,
  });
}

class SupabaseAuthorizationFailure extends SupabaseFailure {
  const SupabaseAuthorizationFailure({
    super.message = 'You do not have access to this resource',
    super.code,
    super.details,
    super.cause,
    super.stackTrace,
  });
}

class SupabaseNotFoundFailure extends SupabaseFailure {
  const SupabaseNotFoundFailure({
    super.message = 'Supabase resource not found',
    super.code,
    super.details,
    super.cause,
    super.stackTrace,
  });
}

class SupabaseConflictFailure extends SupabaseFailure {
  const SupabaseConflictFailure({
    super.message = 'Supabase resource conflict',
    super.code,
    super.details,
    super.cause,
    super.stackTrace,
  });
}

class SupabaseValidationFailure extends SupabaseFailure {
  const SupabaseValidationFailure({
    super.message = 'Supabase validation error',
    super.details,
    super.code,
    super.cause,
    super.stackTrace,
  });
}
