import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../features/app_boot/schema_snapshot.dart';
import '../../services/supabase_service.dart';
import '../models/schema_meta.dart';
import 'schema_meta_repository.dart';

class SchemaMetaRepositoryImpl implements SchemaMetaRepository {
  SchemaMetaRepositoryImpl(this._svc);

  final SupabaseService _svc;

  static const _table = 'schema_meta';

  @override
  Future<Result<bool>> isCompatible({List<String>? acceptedDbHashes}) async {
    final dbMetaResult = await getDbMeta();

    return dbMetaResult.fold<Future<Result<bool>>>(
      (failure) async => left(failure),
      (dbMeta) async {
        final appHashResult = await getAppSchemaHash();
        return appHashResult.fold<Result<bool>>(
          (failure) => left(failure),
          (appHash) {
            final matches = dbMeta.schemaHash == appHash;
            final allowlisted = (acceptedDbHashes ?? const [])
                .contains(dbMeta.schemaHash);
            return right(matches || allowlisted);
          },
        );
      },
    );
  }

  @override
  Future<Result<SchemaMeta>> getDbMeta() async {
    try {
      final response = await _svc.client
          .from(_table)
          .select<Map<String, dynamic>>('schema_hash, notes')
          .maybeSingle();

      if (response == null) {
        return left(
          UnknownFailure('schema_meta table is empty or unavailable.'),
        );
      }

      return right(SchemaMeta.fromJson(response));
    } catch (error) {
      return left(_svc.mapPostgrestError(error));
    }
  }

  @override
  Future<Result<String>> getAppSchemaHash() async {
    try {
      if (kAppSchemaHash.isEmpty) {
        return left(
          UnknownFailure('App schema hash has not been bundled.'),
        );
      }
      return right(kAppSchemaHash);
    } catch (error) {
      return left(
        UnknownFailure('Failed to load bundled schema hash: $error'),
      );
    }
  }
}
