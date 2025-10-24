abstract class Failure {
  final String message;
  final int? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code &&
        other.details == details;
  }

  @override
  int get hashCode => Object.hash(message, code, details);

  @override
  String toString() => 'Failure(message: $message, code: $code, details: $details)';
}

// Network failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Data failures
class DataFailure extends Failure {
  const DataFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Simple auth failure used by repositories when a user is not authenticated.
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// File handling failures
class FileUploadFailure extends Failure {
  const FileUploadFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class FileDownloadFailure extends Failure {
  const FileDownloadFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Business logic failures
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.details,
  });
}
