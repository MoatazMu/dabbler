import '../../core/result.dart';

abstract class LocalizationRepository {
  /// Get a localized message by key with optional interpolation.
  /// If not found, returns [defaultValue] when provided, otherwise the key.
  Future<Result<String>> message(
    String key, {
    String? locale,
    Map<String, String>? params,
    String? defaultValue,
  });

  /// Batch lookup of localized messages; missing keys map to the key itself.
  Future<Result<Map<String, String>>> messages(
    List<String> keys, {
    String? locale,
  });

  /// List supported locales as exposed by the server.
  Future<Result<List<String>>> supportedLocales();
}
