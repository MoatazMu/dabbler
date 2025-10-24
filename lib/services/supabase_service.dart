import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dabbler/core/error/failures.dart';

/// Lightweight wrapper around [SupabaseClient] that centralizes
/// authentication helpers and error mapping for repositories.
class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  /// Exposes the raw Supabase client for advanced operations.
  SupabaseClient get client => _client;

  /// Returns the currently authenticated user's id or `null` when not signed in.
  String? authUserId() => _client.auth.currentUser?.id;

  /// Maps Supabase/Postgrest errors into domain [Failure] types.
  Failure mapPostgrestError(Object error) {
    if (error is TimeoutException) {
      return TimeoutFailure(message: error.message ?? 'Request timed out');
    }

    if (error is SocketException) {
      return NetworkFailure(message: error.message);
    }

    if (error is AuthException) {
      return AuthenticationFailure(message: error.message, details: error.details);
    }

    if (error is PostgrestException) {
      final code = error.code != null ? int.tryParse(error.code!) : null;
      final message = error.message.isNotEmpty
          ? error.message
          : 'Unexpected database error occurred';
      if (error.code == '23505') {
        return ConflictFailure(message: message, code: code, details: error.details);
      }
      return DatabaseFailure(message: message, code: code, details: error.details);
    }

    return ServerFailure(message: error.toString());
  }
}

/// Global provider exposing a singleton [SupabaseService] instance.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(Supabase.instance.client);
});
