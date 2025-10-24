import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/error/failure.dart';

/// A thin wrapper around the global [Supabase] singleton.
class SupabaseService {
  /// Lazily retrieves the configured [SupabaseClient].
  SupabaseClient get client => Supabase.instance.client;

  /// Initializes the Supabase client for the application.
  static Future<void> init({
    required String url,
    required String anonKey,
  }) {
    return Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Returns the identifier of the currently authenticated user, if any.
  String? authUserId() => client.auth.currentUser?.id;

  /// Maps PostgREST and network errors into a domain level [Failure].
  Failure mapPostgrestError(Object error) {
    if (error is PostgrestException) {
      final statusSource = error.code ?? error.status;
      final statusCode = int.tryParse(statusSource ?? '');
      final message = error.message ?? 'An unexpected error occurred.';
      final code = error.code;

      if (statusCode == 401 || statusCode == 403) {
        return PermissionFailure(message, code: code);
      }
      if (statusCode == 404) {
        return NotFoundFailure(message, code: code);
      }
      if (statusCode == 409) {
        return ConflictFailure(message, code: code);
      }

      return UnknownFailure(message, code: code);
    }

    if (error is AuthException) {
      final code = error.statusCode?.toString();
      return AuthFailure(error.message, code: code);
    }

    if (error is SocketException) {
      return NetworkFailure(error.message, code: 'network');
    }

    return UnknownFailure(error.toString());
  }
}
