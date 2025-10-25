import 'package:dabbler/core/result.dart';
import 'package:dabbler/data/repositories/base_repository.dart';
import 'package:dabbler/data/repositories/schema_meta_repository.dart';
import 'package:dabbler/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchemaMetaRepositoryImpl extends BaseRepository
    implements SchemaMetaRepository {
  SchemaMetaRepositoryImpl(SupabaseService service) : super(service);

  SupabaseClient get _client => svc.client;

  @override
  Future<Result<String>> version() {
    return guard(() async {
      final meta = await _fetchMeta();
      return meta.version ?? '0.0.0';
    });
  }

  @override
  Future<Result<bool>> isServerCompatible({
    required String clientMin,
    required String clientMax,
  }) {
    return guard(() async {
      final meta = await _fetchMeta();
      final serverVersion = meta.version;
      if (serverVersion == null || serverVersion.isEmpty) {
        return true;
      }

      final looksSemverish = _looksLikeSemverish(serverVersion) &&
          _looksLikeSemverish(clientMin) &&
          _looksLikeSemverish(clientMax);
      if (looksSemverish) {
        final cmpMin = _compareSemverish(serverVersion, clientMin);
        final cmpMax = _compareSemverish(serverVersion, clientMax);
        return cmpMin >= 0 && cmpMax <= 0;
      }

      final looksDate = _looksLikeDate(serverVersion) &&
          _looksLikeDate(clientMin) &&
          _looksLikeDate(clientMax);
      if (looksDate) {
        return serverVersion.compareTo(clientMin) >= 0 &&
            serverVersion.compareTo(clientMax) <= 0;
      }

      // Unknown style -> be permissive; expose raw data through info() so UI can warn.
      return true;
    });
  }

  @override
  Future<Result<Map<String, dynamic>>> info() {
    return guard(() async {
      final meta = await _fetchMeta();
      return {
        'version': meta.version,
        'minClient': meta.minClient,
        'maxClient': meta.maxClient,
        'gitSha': meta.gitSha,
        'generatedAt': meta.generatedAt,
      };
    });
  }

  Future<_Meta> _fetchMeta() async {
    final rpcInfo = await _safeRpc('schema_meta_info');
    final mapInfo = _extractMap(rpcInfo);
    if (mapInfo != null) {
      return _Meta(
        version: _asNonEmptyString(mapInfo['version']) ?? '0.0.0',
        minClient:
            _asString(mapInfo['min_client']) ?? _asString(mapInfo['minClient']),
        maxClient:
            _asString(mapInfo['max_client']) ?? _asString(mapInfo['maxClient']),
        gitSha: _asString(mapInfo['git_sha']) ?? _asString(mapInfo['gitSha']),
        generatedAt: mapInfo['generated_at'] ?? mapInfo['generatedAt'],
      );
    }

    final rpcSchemaVersion = await _safeRpc('schema_version');
    final schemaVersion = _asNonEmptyString(rpcSchemaVersion);
    if (schemaVersion != null) {
      return _Meta(version: schemaVersion);
    }

    final rpcGetSchemaVersion = await _safeRpc('get_schema_version');
    final getSchemaVersion = _asNonEmptyString(rpcGetSchemaVersion);
    if (getSchemaVersion != null) {
      return _Meta(version: getSchemaVersion);
    }

    for (final table in const ['schema_meta', 'schema_meta_view']) {
      try {
        final rows = await _client.from(table).select('*').limit(1);
        if (rows is List && rows.isNotEmpty) {
          final map = _extractMap(rows.first);
          if (map != null) {
            return _Meta(
              version: _asNonEmptyString(map['version']) ?? '0.0.0',
              minClient: _asString(map['min_client']) ??
                  _asString(map['minClient']),
              maxClient: _asString(map['max_client']) ??
                  _asString(map['maxClient']),
              gitSha: _asString(map['git_sha']) ?? _asString(map['gitSha']),
              generatedAt: map['generated_at'] ?? map['generatedAt'],
            );
          }
        }
      } catch (_) {
        // ignore and try the next fallback
      }
    }

    return const _Meta(version: '0.0.0');
  }

  Future<dynamic> _safeRpc(String fn, {Map<String, dynamic>? params}) async {
    try {
      return await _client.rpc(fn, params: params ?? const {});
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value as Map);
    }
    if (value is List && value.isNotEmpty) {
      for (final element in value) {
        final map = _extractMap(element);
        if (map != null) {
          return map;
        }
      }
    }
    return null;
  }

  String? _asString(dynamic value) => value == null ? null : value.toString();

  String? _asNonEmptyString(dynamic value) {
    final stringValue = _asString(value);
    if (stringValue == null || stringValue.isEmpty) {
      return null;
    }
    return stringValue;
  }

  bool _looksLikeSemverish(String value) {
    final head = _numericPrefix(value);
    if (head.isEmpty) {
      return false;
    }
    final segments = head.split('.');
    if (segments.isEmpty) {
      return false;
    }
    for (final segment in segments) {
      if (segment.isEmpty) {
        return false;
      }
      if (int.tryParse(segment) == null) {
        return false;
      }
    }
    return true;
  }

  int _compareSemverish(String a, String b) {
    final partsA = _semverParts(a);
    final partsB = _semverParts(b);
    for (var i = 0; i < 3; i++) {
      final comparison = partsA[i].compareTo(partsB[i]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  List<int> _semverParts(String value) {
    final head = _numericPrefix(value);
    final segments =
        head.split('.').where((segment) => segment.isNotEmpty).toList();
    while (segments.length < 3) {
      segments.add('0');
    }
    return segments
        .take(3)
        .map((segment) => int.tryParse(segment) ?? 0)
        .toList();
  }

  String _numericPrefix(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      final code = char.codeUnitAt(0);
      final isDigit = code >= 48 && code <= 57;
      if (isDigit || char == '.') {
        buffer.write(char);
      } else {
        break;
      }
    }
    return buffer.toString();
  }

  bool _looksLikeDate(String value) {
    if (value.length != 10) {
      return false;
    }
    if (value[4] != '-' || value[7] != '-') {
      return false;
    }
    final year = value.substring(0, 4);
    final month = value.substring(5, 7);
    final day = value.substring(8, 10);
    return int.tryParse(year) != null &&
        int.tryParse(month) != null &&
        int.tryParse(day) != null;
  }
}

class _Meta {
  const _Meta({
    this.version,
    this.minClient,
    this.maxClient,
    this.gitSha,
    this.generatedAt,
  });

  final String? version;
  final String? minClient;
  final String? maxClient;
  final String? gitSha;
  final dynamic generatedAt;
}
