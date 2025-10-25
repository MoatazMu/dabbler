import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/failure.dart';

final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService());

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  /// Map PostgREST errors into domain Failures.
  Failure mapPostgrest(PostgrestException e) {
    // Not all versions expose statusCode; use dynamic guard.
    int? status;
    try {
      final dyn = e as dynamic;
      if (dyn.statusCode is int) status = dyn.statusCode as int;
    } catch (_) {/* ignore */}

    final String msg = e.message ?? 'Request failed';
    final String? code = e.code;

    if (status == 401) return UnauthenticatedFailure(message: msg);
    if (status == 403) return ForbiddenFailure(message: msg);
    if (status == 404) return NotFoundFailure(message: msg);

    // Treat common validation shapes as ValidationFailure
    if (status == 409 || status == 422 || code == 'PGRST116' || code == 'PGRST204') {
      Map<String, List<String>>? fields;
      try {
        final details = e.details;
        if (details is Map && details['errors'] is Map) {
          fields = (details['errors'] as Map).map<String, List<String>>(
            (k, v) => MapEntry(k.toString(), List<String>.from(v ?? const [])),
          );
        }
      } catch (_) {/* ignore */}
      return ValidationFailure(message: msg, fieldErrors: fields);
    }

    return NetworkFailure(message: msg, status: status);
  }

  /// Generic fallback mapper for any thrown error.
  Failure mapGeneric(Object error, StackTrace st) {
    if (error is AuthException) {
      // Supabase auth exceptions: often 401/400; treat as unauthenticated by default.
      return UnauthenticatedFailure(message: error.message);
    }
    if (error is PostgrestException) {
      return mapPostgrest(error);
    }
    if (error is SocketException || error is TimeoutException) {
      return NetworkFailure(message: error.toString());
    }
    return UnknownFailure(message: error.toString(), error: error, stackTrace: st);
  }
}

