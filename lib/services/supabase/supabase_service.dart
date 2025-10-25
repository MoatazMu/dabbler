import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import 'supabase_client.dart';
import 'supabase_error_mapper.dart';

/// Thin wrapper around [SupabaseClient] to centralize access helpers.
class SupabaseService {
  SupabaseService(this._client, this._errorMapper);

  final SupabaseClient _client;
  final SupabaseErrorMapper _errorMapper;

  SupabaseClient get client => _client;

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

  /// Maps PostgREST or network errors to a [Failure] using the shared mapper.
  Failure mapPostgrestError(Object error) {
    return _errorMapper.map(error);
  }
}

/// Provides an instance of [SupabaseService] backed by the global client.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final errorMapper = ref.watch(supabaseErrorMapperProvider);
  return SupabaseService(client, errorMapper);
});
