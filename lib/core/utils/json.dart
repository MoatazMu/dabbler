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
