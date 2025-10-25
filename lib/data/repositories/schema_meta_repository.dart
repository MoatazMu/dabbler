import '../../core/types/result.dart';
import '../models/schema_meta.dart';

abstract class SchemaMetaRepository {
  Future<Result<bool>> isCompatible({List<String>? acceptedDbHashes});

  Future<Result<SchemaMeta>> getDbMeta();

  Future<Result<String>> getAppSchemaHash();
}
