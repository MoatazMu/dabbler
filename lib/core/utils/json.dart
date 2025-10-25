/// Safely parses a [DateTime] value from dynamic JSON input.
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Safely parses a [double] from dynamic JSON input.
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Safely parses a [String] from dynamic JSON input.
String? parseString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

/// Casts dynamic map-like objects into a [Map<String, dynamic>].
Map<String, dynamic> asMap(dynamic value) {
  if (value == null) return <String, dynamic>{};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic v) => MapEntry(key.toString(), v),
    );
  }
  throw ArgumentError('Expected Map but got ${value.runtimeType}');
}
