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
  }
}
