import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import 'supabase_client.dart';
import 'supabase_error_mapper.dart';

/// Thin wrapper around [SupabaseClient] to centralize access helpers.
class SupabaseService {
  SupabaseService(
    this._client, {
    SupabaseErrorMapper? errorMapper,
  }) : _errorMapper = errorMapper ?? const SupabaseErrorMapper();

  final SupabaseClient _client;
  final SupabaseErrorMapper _errorMapper;

  SupabaseClient get client => _client;

  /// Returns the authenticated user's id if available.
  String? authUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Maps Supabase/Postgrest errors into domain specific failures.
  Failure mapPostgrestError(
    Object error, {
    StackTrace? stackTrace,
  }) {
    return _errorMapper.map(
      error,
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
}

/// Provides an instance of [SupabaseService] backed by the global client.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final mapper = ref.watch(supabaseErrorMapperProvider);
  return SupabaseService(
    client,
    errorMapper: mapper,
  );
});
