import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/result.dart';
import '../../services/supabase_service.dart';
import 'base_repository.dart';
import 'localization_repository.dart';

class LocalizationRepositoryImpl extends BaseRepository
    implements LocalizationRepository {
  LocalizationRepositoryImpl(SupabaseService svc) : super(svc);

  SupabaseClient get _client => svc.client;

  @override
  Future<Result<String>> message(
    String key, {
    String? locale,
    Map<String, String>? params,
    String? defaultValue,
  }) {
    return guard(() async {
      final normalized = _normalizeLocale(locale);
      final candidates = _fallbackLocales(normalized);
      String? resolved;

      for (final candidate in candidates) {
        final response = await _client.rpc(
          'i18n_message',
          params: {
            'locale': candidate,
            'key': key,
          },
        );

        if (response is String && response.isNotEmpty) {
          resolved = response;
          break;
        }
      }

      resolved ??= defaultValue ?? key;

      if (params != null && params.isNotEmpty) {
        resolved = _interpolate(resolved, params);
      }

      return resolved;
    });
  }

  @override
  Future<Result<Map<String, String>>> messages(
    List<String> keys, {
    String? locale,
  }) {
    return guard(() async {
      if (keys.isEmpty) {
        return <String, String>{};
      }

      final normalized = _normalizeLocale(locale);
      final candidates = _fallbackLocales(normalized);
      final Map<String, String> resolved = {};

      for (final candidate in candidates) {
        final response = await _client.rpc(
          'i18n_messages_by_locale',
          params: {
            'locale': candidate,
            'keys': keys,
          },
        );

        if (response is List) {
          for (final row in response) {
            if (row is Map) {
              final map = Map<String, dynamic>.from(row);
              final keyValue = map['key']?.toString();
              final value = map['value']?.toString();
              if (keyValue != null && value != null && !resolved.containsKey(keyValue)) {
                resolved[keyValue] = value;
              }
            }
          }
        }

        if (resolved.length == keys.length) {
          break;
        }
      }

      for (final key in keys) {
        resolved.putIfAbsent(key, () => key);
      }

      return resolved;
    });
  }

  @override
  Future<Result<List<String>>> supportedLocales() {
    return guard(() async {
      final response = await _client.rpc('i18n_supported_locales');
      if (response is List) {
        return response.map((e) => e.toString()).toList();
      }
      return <String>['en'];
    });
  }

  String _normalizeLocale(String? locale) {
    final value = (locale ?? 'en').trim();
    if (value.isEmpty) {
      return 'en';
    }
    return value.replaceAll('_', '-');
  }

  List<String> _fallbackLocales(String locale) {
    final fallbacks = <String>{};
    final normalized = _normalizeLocale(locale);
    fallbacks.add(normalized);

    final parts = normalized.split('-');
    if (parts.length > 1) {
      fallbacks.add(parts.first);
    }

    fallbacks.add('en');

    return fallbacks.toList();
  }

  String _interpolate(String template, Map<String, String> params) {
    var output = template;
    params.forEach((key, value) {
      output = output.replaceAll('{$key}', value);
    });
    return output;
  }
}
