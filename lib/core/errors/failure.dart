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
    String message = 'Authentication failed',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class UnauthenticatedFailure extends AuthFailure {
  const UnauthenticatedFailure({
    String message = 'User not authenticated',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    String message = 'You do not have permission to perform this action',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message: message, cause: cause, stackTrace: stackTrace);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = 'Requested resource was not found',
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message: message, cause: cause, stackTrace: stackTrace);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    String message = 'Validation failed',
    this.fieldErrors,
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );

  final Map<String, List<String>>? fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'Network request failed',
    this.status,
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );

  final int? status;

  @override
  List<Object?> get props => [...super.props, status];
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure({
    String message = 'The request timed out',
    int? status,
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          status: status,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Server error',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class DataFailure extends Failure {
  const DataFailure({
    String message = 'Data operation failed',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Cache operation failed',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    String message = 'Database operation failed',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    String message = 'You do not have permission to perform this action',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure({
    String message = 'Business rule validation failed',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class ConflictFailure extends Failure {
  const ConflictFailure({
    String message = 'Resource conflict detected',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class FileUploadFailure extends Failure {
  const FileUploadFailure({
    String message = 'Failed to upload file',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class FileDownloadFailure extends Failure {
  const FileDownloadFailure({
    String message = 'Failed to download file',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure({
    String message = 'File not found',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    String message = 'An unexpected error occurred',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    String message = 'An unknown error occurred',
    this.error,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          message: message,
          cause: error,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );

  final Object? error;

  @override
  List<Object?> get props => [...super.props, error];
}

class SupabaseFailure extends Failure {
  const SupabaseFailure({
    String message = 'Supabase request failed',
    String? code,
    Map<String, dynamic>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class SupabaseAuthFailure extends SupabaseFailure {
  const SupabaseAuthFailure({
    String message = 'Supabase authentication failed',
    String? code,
    Map<String, dynamic>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          details: details,
          cause: cause,
          stackTrace: stackTrace,
        );
}

class SupabaseAuthorizationFailure extends SupabaseFailure {
  const SupabaseAuthorizationFailure({
    String message = 'You do not have access to this resource',
    String? code,
    Map<String, dynamic>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message: message,
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
          message: message,
          code: code,
          details: details,
          cause: cause,
          stackTrace: stackTrace,
        );
}

class SupabaseConflictFailure extends SupabaseFailure {
  const SupabaseConflictFailure({
    String message = 'Supabase resource conflict',
    String? code,
    Map<String, dynamic>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message: message,
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
          message: message,
          code: code,
          details: details,
          cause: cause,
          stackTrace: stackTrace,
        );
}
