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

class Failure {
  final FailureCode code;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const Failure(this.code, {this.message = '', this.cause, this.stackTrace});

  @override
  String toString() => 'Failure($code, "$message")';

  static Failure from(Object error, [StackTrace? st]) {
    // Add your project-specific exception mapping here.
    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return Failure(FailureCode.network, message: msg, cause: error, stackTrace: st);
    }
    if (msg.contains('Timeout')) {
      return Failure(FailureCode.timeout, message: msg, cause: error, stackTrace: st);
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return Failure(FailureCode.unauthorized, message: msg, cause: error, stackTrace: st);
    }
    if (msg.contains('403') || msg.contains('forbidden')) {
      return Failure(FailureCode.forbidden, message: msg, cause: error, stackTrace: st);
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return Failure(FailureCode.notFound, message: msg, cause: error, stackTrace: st);
    }
    if (msg.contains('409') || msg.contains('conflict')) {
      return Failure(FailureCode.conflict, message: msg, cause: error, stackTrace: st);
    }
    if (msg.contains('validation')) {
      return Failure(FailureCode.validation, message: msg, cause: error, stackTrace: st);
    }
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      return Failure(FailureCode.cancelled, message: msg, cause: error, stackTrace: st);
    }
    return Failure(FailureCode.unknown, message: msg, cause: error, stackTrace: st);
  }
}
