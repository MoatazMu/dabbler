import 'package:meta/meta.dart';

@immutable
abstract class Failure {
  final String? message;
  const Failure([this.message]);

  /// A human-friendly message with a fallback.
  String get displayMessage => message ?? 'Something went wrong';

  @override
  String toString() => '$runtimeType(${displayMessage})';
}

class UnauthenticatedFailure extends Failure {
  const UnauthenticatedFailure({String? message}) : super(message);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({String? message}) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String? message}) : super(message);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;
  const ValidationFailure({String? message, this.fieldErrors}) : super(message);
}

class NetworkFailure extends Failure {
  final int? status;
  const NetworkFailure({String? message, this.status}) : super(message);
}

class UnknownFailure extends Failure {
  final Object? error;
  final StackTrace? stackTrace;
  const UnknownFailure({String? message, this.error, this.stackTrace})
      : super(message);
}
