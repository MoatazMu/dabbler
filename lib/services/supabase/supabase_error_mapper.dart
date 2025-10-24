import 'dart:async';
import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';

final supabaseErrorMapperProvider = Provider<SupabaseErrorMapper>((ref) {
  return const SupabaseErrorMapper();
});

class SupabaseErrorMapper {
  const SupabaseErrorMapper();

  Failure map(
    Object error, {
    String? overrideMessage,
    StackTrace? stackTrace,
  }) {
    if (error is PostgrestException) {
      return _mapPostgrest(
        error,
        overrideMessage: overrideMessage,
        stackTrace: stackTrace,
      );
    }
    if (error is AuthException) {
      return _mapAuth(
        error,
        overrideMessage: overrideMessage,
        stackTrace: stackTrace,
      );
    }
    if (error is StorageException) {
      return SupabaseFailure(
        overrideMessage ?? error.message,
        code: error.statusCode?.toString(),
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is TimeoutException || error is SocketException) {
      return NetworkFailure(
        overrideMessage ?? 'Network connection failed',
        stackTrace: stackTrace,
      );
    }

    return UnexpectedFailure(
      overrideMessage ?? error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  Failure _mapAuth(
    AuthException exception, {
    String? overrideMessage,
    StackTrace? stackTrace,
  }) {
    final message = overrideMessage ?? exception.message;
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('invalid login credentials')) {
      return InvalidCredentialsFailure(message);
    }
    if (lowerMessage.contains('email') && lowerMessage.contains('exists')) {
      return EmailAlreadyExistsFailure(message);
    }
    if (lowerMessage.contains('password')) {
      return WeakPasswordFailure(message);
    }
    if (lowerMessage.contains('verify') || lowerMessage.contains('confirmation')) {
      return UnverifiedEmailFailure(message);
    }

    return SupabaseAuthFailure(
      message,
      code: exception.code,
      cause: exception,
      stackTrace: stackTrace,
    );
  }

  Failure _mapPostgrest(
    PostgrestException exception, {
    String? overrideMessage,
    StackTrace? stackTrace,
  }) {
    final message = overrideMessage ?? exception.message ?? 'Unexpected Supabase error';
    final code = exception.code;
    final details = _detailsToMap(exception.details);
    final status = exception.statusCode;

    if (status == 401 || status == 403) {
      return SupabaseAuthorizationFailure(
        message: message,
        code: code,
        details: details,
        cause: exception,
        stackTrace: stackTrace,
      );
    }

    if (status == 404) {
      return SupabaseNotFoundFailure(
        message: message,
        code: code,
        details: details,
        cause: exception,
        stackTrace: stackTrace,
      );
    }

    if (status == 409 || code == '23505') {
      return SupabaseConflictFailure(
        message: message,
        code: code,
        details: details,
        cause: exception,
        stackTrace: stackTrace,
      );
    }

    if (status == 400 || status == 422 || code == 'PGRST301' || code == 'PGRST303') {
      return SupabaseValidationFailure(
        message: message,
        details: details,
        code: code,
        cause: exception,
        stackTrace: stackTrace,
      );
    }

    if (status != null && status >= 500) {
      return ServerFailure(
        message,
        cause: exception,
        stackTrace: stackTrace,
      );
    }

    return SupabaseFailure(
      message,
      code: code,
      details: details,
      cause: exception,
      stackTrace: stackTrace,
    );
  }

  Map<String, dynamic>? _detailsToMap(dynamic details) {
    if (details == null) {
      return null;
    }
    if (details is Map<String, dynamic>) {
      return details;
    }
    if (details is Map) {
      return Map<String, dynamic>.from(details.cast<Object?, Object?>());
    }
    return {'details': details};
  }
}
