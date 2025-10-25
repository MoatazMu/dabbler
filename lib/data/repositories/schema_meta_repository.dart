import 'package:dabbler/core/result.dart';

/// Contract for retrieving schema metadata exposed by the Supabase backend.
abstract class SchemaMetaRepository {
  /// Raw server schema version string (e.g., "1.12.3" or "2025-01-13.r5").
  Future<Result<String>> version();

  /// Returns true if the server version is within [clientMin, clientMax]
  /// per the comparison rules. Unknown version => true (fail-soft).
  Future<Result<bool>> isServerCompatible({
    required String clientMin,
    required String clientMax,
  });

  /// A structured map of meta fields that the backend might expose.
  /// Keys: version, minClient, maxClient, gitSha, generatedAt
  Future<Result<Map<String, dynamic>>> info();
}
