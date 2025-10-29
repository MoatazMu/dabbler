import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failure.dart';
import 'supabase_client.dart';
import 'supabase_error_mapper.dart';

/// Thin wrapper around [SupabaseClient] to centralize access helpers.
class SupabaseService {
  SupabaseService(this._client, this._errorMapper);

  final SupabaseClient _client;
  final SupabaseErrorMapper _errorMapper;

  SupabaseClient get client => _client;

  /// Returns the authenticated user's id if available.
  String? authUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Maps Supabase/PostgREST errors into domain specific failures.
  Failure mapPostgrest(
    PostgrestException exception, {
    String? overrideMessage,
    StackTrace? stackTrace,
  }) {
    final mapped = _errorMapper.map(
      exception,
      overrideMessage: overrideMessage,
      stackTrace: stackTrace,
    );

    final message = mapped.message;
    final status = exception.statusCode;
    final code = exception.code;

    if (status == 401) {
      return UnauthenticatedFailure(
        message: message,
        cause: mapped.cause,
        stackTrace: mapped.stackTrace,
        code: mapped.code ?? code,
        details: mapped.details,
      );
    }

    if (status == 403) {
      return ForbiddenFailure(
        message: message,
        cause: mapped.cause,
        stackTrace: mapped.stackTrace,
        code: mapped.code ?? code,
        details: mapped.details,
      );
    }

    if (status == 404) {
      return NotFoundFailure(
        message: message,
        cause: mapped.cause,
        stackTrace: mapped.stackTrace,
        code: mapped.code ?? code,
        details: mapped.details,
      );
    }

    if (status == 409 || status == 422 || code == 'PGRST116' || code == 'PGRST204') {
      return ValidationFailure(
        message: message,
        fieldErrors: _extractFieldErrors(exception),
        cause: mapped.cause,
        stackTrace: mapped.stackTrace,
        code: mapped.code ?? code,
        details: mapped.details,
      );
    }

    return mapped;
  }

  /// Maps Supabase/PostgREST errors from arbitrary throwables.
  Failure mapPostgrestError(
    Object error, {
    String? overrideMessage,
    StackTrace? stackTrace,
  }) {
    if (error is PostgrestException) {
      return mapPostgrest(
        error,
        overrideMessage: overrideMessage,
        stackTrace: stackTrace,
      );
    }
    return _errorMapper.map(
      error,
      overrideMessage: overrideMessage,
      stackTrace: stackTrace,
    );
  }

  /// Returns a query builder for the provided [table].
  PostgrestFilterBuilder<Map<String, dynamic>> from(String table) {
    return _client.from(table);
  }

  /// Calls a Postgres function and returns the query builder for further chaining.
  PostgrestFunctionBuilder<Map<String, dynamic>> rpc(
    String fn, {
    Map<String, dynamic>? params,
  }) {
    return _client.rpc(fn, params: params ?? const <String, dynamic>{});
  }

  /// Executes the provided query and attempts to return a single row.
  Future<PostgrestMap?> maybeSingle(
    PostgrestFilterBuilder<Map<String, dynamic>> query,
  ) async {
    final result = await query.maybeSingle();
    if (result == null) {
      return null;
    }
    return Map<String, dynamic>.from(result);
  }

  /// Executes the provided query and returns all rows as a typed list.
  Future<List<PostgrestMap>> getList(
    PostgrestFilterBuilder<Map<String, dynamic>> query,
  ) async {
    final response = await query;
    final data = List<dynamic>.from(response as List);
    return data
        .map(
          (dynamic item) => Map<String, dynamic>.from(
            item as Map<dynamic, dynamic>,
          ),
        )
        .toList();
  }

  /// Fallback mapper for unexpected errors.
  Failure mapGeneric(
    Object error,
    StackTrace stackTrace, {
    String? overrideMessage,
  }) {
    return _errorMapper.map(
      error,
      overrideMessage: overrideMessage,
      stackTrace: stackTrace,
    );
  }

  Map<String, List<String>>? _extractFieldErrors(PostgrestException exception) {
    try {
      final details = exception.details;
      if (details is Map && details['errors'] is Map) {
        final rawErrors = Map<String, dynamic>.from(
          Map<dynamic, dynamic>.from(details['errors'] as Map),
        );
        return rawErrors.map(
          (key, value) => MapEntry(
            key,
            value is Iterable
                ? value.map((entry) => entry.toString()).toList()
                : [value.toString()],
          ),
        );
      }
    } catch (_) {
      // Ignore parsing issues and fall back to generic validation failure
    }
    return null;
  }
}

/// Provides an instance of [SupabaseService] backed by the global client.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final errorMapper = ref.watch(supabaseErrorMapperProvider);
  return SupabaseService(client, errorMapper);
});
