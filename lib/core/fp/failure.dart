import 'package:equatable/equatable.dart';

enum FailureCode {
  unknown,
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  capacityFull,
  waitlisted,
  rateLimited,
  server,
  cancelled,
}

class Failure extends Equatable {
  final FailureCode category;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  final String? code;
  final Map<String, dynamic>? details;

  const Failure({
    this.category = FailureCode.unknown,
    this.message = '',
    this.cause,
    this.stackTrace,
    this.code,
    this.details,
  });

  bool get isUnknown => category == FailureCode.unknown;
  bool get isNetwork => category == FailureCode.network;
  bool get isTimeout => category == FailureCode.timeout;
  bool get isUnauthorized => category == FailureCode.unauthorized;
  bool get isForbidden => category == FailureCode.forbidden;
  bool get isNotFound => category == FailureCode.notFound;
  bool get isConflict => category == FailureCode.conflict;
  bool get isValidation => category == FailureCode.validation;
  bool get isServer => category == FailureCode.server;
  bool get isCancelled => category == FailureCode.cancelled;

  @override
  List<Object?> get props => [category, message, code, details, cause];

  @override
  String toString() => 'Failure($category, "$message")';

  static Failure from(Object error, [StackTrace? st]) {
    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return Failure(
        category: FailureCode.network,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    if (msg.contains('Timeout')) {
      return Failure(
        category: FailureCode.timeout,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return Failure(
        category: FailureCode.unauthorized,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    if (msg.contains('403') || msg.contains('forbidden')) {
      return Failure(
        category: FailureCode.forbidden,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return Failure(
        category: FailureCode.notFound,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    if (msg.contains('409') || msg.contains('conflict')) {
      return Failure(
        category: FailureCode.conflict,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    if (msg.contains('validation')) {
      return Failure(
        category: FailureCode.validation,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      return Failure(
        category: FailureCode.cancelled,
        message: msg,
        cause: error,
        stackTrace: st,
      );
    }
    return Failure(
      category: FailureCode.unknown,
      message: msg,
      cause: error,
      stackTrace: st,
    );
  }
}

class AuthFailure extends Failure {
  const AuthFailure({
    String message = 'Authentication failed',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          category: FailureCode.unauthorized,
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
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          category: FailureCode.forbidden,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = 'Requested resource was not found',
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          category: FailureCode.notFound,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    String message = 'Validation failed',
    this.fieldErrors,
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          category: FailureCode.validation,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

class NetworkFailure extends Failure {
  final int? status;

  const NetworkFailure({
    String message = 'Network request failed',
    this.status,
    Object? cause,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          category: FailureCode.network,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );

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
          category: FailureCode.server,
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
          category: FailureCode.unknown,
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
          category: FailureCode.unknown,
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
          category: FailureCode.server,
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
          category: FailureCode.forbidden,
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
          category: FailureCode.validation,
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
          category: FailureCode.conflict,
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
          category: FailureCode.server,
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
          category: FailureCode.server,
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
          category: FailureCode.notFound,
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
          category: FailureCode.unknown,
          message: message,
          cause: cause,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );
}

class UnknownFailure extends Failure {
  final Object? error;

  const UnknownFailure({
    String message = 'An unknown error occurred',
    this.error,
    StackTrace? stackTrace,
    String? code,
    Map<String, dynamic>? details,
  }) : super(
          category: FailureCode.unknown,
          message: message,
          cause: error,
          stackTrace: stackTrace,
          code: code,
          details: details,
        );

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
          category: FailureCode.server,
          message: message,
          code: code,
          details: details,
          cause: cause,
          stackTrace: stackTrace,
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
