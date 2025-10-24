/// Base contract for failures surfaced by the data layer.
abstract class Failure {
  /// Creates a new [Failure] with an optional machine readable [code].
  const Failure(this.message, {this.code});

  /// Human readable description of the failure.
  final String message;

  /// Optional machine readable error code.
  final String? code;
}

/// Represents a connectivity related failure.
class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure] with an optional [code].
  const NetworkFailure(String message, {String? code})
      : super(message, code: code);
}

/// Represents an authentication failure.
class AuthFailure extends Failure {
  /// Creates an [AuthFailure] with an optional [code].
  const AuthFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents an authorization/permission failure.
class PermissionFailure extends Failure {
  /// Creates a [PermissionFailure] with an optional [code].
  const PermissionFailure(String message, {String? code})
      : super(message, code: code);
}

/// Represents a not found failure.
class NotFoundFailure extends Failure {
  /// Creates a [NotFoundFailure] with an optional [code].
  const NotFoundFailure(String message, {String? code})
      : super(message, code: code);
}

/// Represents a conflict failure.
class ConflictFailure extends Failure {
  /// Creates a [ConflictFailure] with an optional [code].
  const ConflictFailure(String message, {String? code})
      : super(message, code: code);
}

/// Represents a validation failure.
class ValidationFailure extends Failure {
  /// Creates a [ValidationFailure] with an optional [code].
  const ValidationFailure(String message, {String? code})
      : super(message, code: code);
}

/// Represents an unknown failure.
class UnknownFailure extends Failure {
  /// Creates an [UnknownFailure] with an optional [code].
  const UnknownFailure(String message, {String? code})
      : super(message, code: code);
}
