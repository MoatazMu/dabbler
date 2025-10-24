import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/failures.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = Supabase.instance.client;
  return SupabaseService(client);
});

class SupabaseService {
  SupabaseService(this.client);

  final SupabaseClient client;

  String? authUserId() => client.auth.currentUser?.id;

  Failure mapPostgrestError(Object error) {
    if (error is Failure) {
      return error;
    }

    if (error is SocketException) {
      return NetworkFailure(
        message: 'No internet connection',
        details: error,
      );
    }

    if (error is AuthException) {
      return AuthFailure(
        message: error.message,
        code: error.statusCode,
        details: error,
      );
    }

    if (error is PostgrestException) {
      final message = error.message ?? 'Unexpected database error';
      if (error.code == 'PGRST116') {
        return NotFoundFailure(
          message: message,
          code: error.code != null ? int.tryParse(error.code!) : null,
          details: error,
        );
      }
      if (error.code == '23505') {
        return ConflictFailure(
          message: message,
          code: error.code != null ? int.tryParse(error.code!) : null,
          details: error,
        );
      }
      return ServerFailure(
        message: message,
        code: error.code != null ? int.tryParse(error.code!) : null,
        details: error,
      );
    }

    if (error is RealtimeException) {
      return ServerFailure(
        message: error.message,
        details: error,
      );
    }

    return UnknownFailure(
      message: error.toString(),
      details: error,
    );
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
