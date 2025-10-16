import 'package:equatable/equatable.dart';

/// Abstract failure class for error handling
abstract class Failure extends Equatable {
  /// Error message
  final String message;
  
  /// Optional error code
  final String? code;
  
  /// Optional error details
  final Map<String, dynamic>? details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Authorization-related failures
class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Data not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Generic failures for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// File system-related failures
class FileSystemFailure extends Failure {
  const FileSystemFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Parsing-related failures
class ParsingFailure extends Failure {
  const ParsingFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Extension for common failure messages
extension FailureExtensions on Failure {
  /// Get user-friendly error message
  String get userMessage {
    switch (runtimeType) {
      case NetworkFailure:
        return 'Please check your internet connection and try again.';
      case ServerFailure:
        return 'Something went wrong on our end. Please try again later.';
      case AuthFailure:
        return 'Authentication failed. Please log in again.';
      case AuthorizationFailure:
        return 'You don\'t have permission to perform this action.';
      case ValidationFailure:
        return message; // Validation messages are usually user-friendly
      case NotFoundFailure:
        return 'The requested data could not be found.';
      case CacheFailure:
        return 'There was an issue accessing cached data.';
      case DatabaseFailure:
        return 'There was an issue accessing the database.';
      case FileSystemFailure:
        return 'There was an issue accessing files.';
      case ParsingFailure:
        return 'There was an issue processing the data.';
      case PermissionFailure:
        return 'Permission denied. Please grant the required permissions.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if this is a retryable error
  bool get isRetryable {
    switch (runtimeType) {
      case NetworkFailure:
      case ServerFailure:
      case CacheFailure:
      case DatabaseFailure:
        return true;
      case AuthFailure:
      case AuthorizationFailure:
      case ValidationFailure:
      case NotFoundFailure:
      case FileSystemFailure:
      case ParsingFailure:
      case PermissionFailure:
        return false;
      default:
        return false;
    }
  }
}