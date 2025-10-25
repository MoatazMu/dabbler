import '../../core/types/result.dart';
import '../models/schema_meta.dart';

abstract class SchemaMetaRepository {
  /// Returns DB-declared meta (or null if table/view absent).
  Future<Result<SchemaMeta?>> getDbMeta();

  /// Returns DB-declared schema hash (or null).
  Future<Result<String?>> getDbSchemaHash();

  /// Computes app’s local schema hash from bundled asset (or null if missing).
  Future<Result<String?>> getAppSchemaHash();

  /// Compares app vs DB; optional allowlist of accepted DB hashes.
  Future<Result<bool>> isCompatible({
    List<String> acceptedDbHashes = const [],
  });
}
