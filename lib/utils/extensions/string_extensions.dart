import '../constants/app_constants.dart';

/// Extension methods for String manipulation
extension StringExtensions on String {
  /// Capitalizes the first letter of the string
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of each word
  String capitalizeEachWord() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.capitalizeFirst())
        .join(' ');
  }

  /// Checks if string is a valid email
  bool get isValidEmail => AppConstants.emailRegex.hasMatch(this);

  /// Checks if string is a valid URL
  bool get isValidUrl => AppConstants.urlRegex.hasMatch(this);

  /// Truncates text with ellipsis if longer than maxLength
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Removes extra whitespace from string
  String removeExtraSpaces() {
    return trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Converts string to snake_case
  String toSnakeCase() {
    final result = replaceAllMapped(
      RegExp(r'[A-Z]'),
      (Match m) => '_${m.group(0)?.toLowerCase()}',
    );
    return result
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'^_'), '');
  }

  /// Converts string to camelCase
  String toCamelCase() {
    final words = split(RegExp(r'[_\s-]'));
    if (words.isEmpty) return this;
    
    return words.first.toLowerCase() +
        words.skip(1).map((word) => word.capitalizeFirst()).join('');
  }

  /// Converts string to kebab-case
  String toKebabCase() {
    final result = replaceAllMapped(
      RegExp(r'[A-Z]'),
      (Match m) => '-${m.group(0)?.toLowerCase()}',
    );
    return result
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'^-'), '');
  }

  /// Extracts only numbers from string
  String extractNumbers() {
    return replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Extracts only letters from string
  String extractLetters() {
    return replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }

  /// Checks if string contains only numbers
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Checks if string contains only letters
  bool get isAlpha => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  /// Checks if string contains letters and numbers only
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  /// Reverses the string
  String reverse() {
    return split('').reversed.join();
  }

  /// Counts occurrences of a substring
  int countOccurrences(String substring) {
    if (substring.isEmpty) return 0;
    return RegExp(RegExp.escape(substring)).allMatches(this).length;
  }

  /// Removes all HTML tags from string
  String stripHtml() {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Converts markdown-style bold to plain text
  String stripMarkdown() {
    return replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')  // Bold
        .replaceAll(RegExp(r'_(.*?)_'), r'$1')         // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')         // Code
        .replaceAll(RegExp(r'\[(.*?)\]\((.*?)\)'), r'$1'); // Links
  }

  /// Masks a portion of the string (useful for sensitive data)
  String mask({
    int? visibleChars,
    int? visibleEndChars,
    String maskChar = '*',
  }) {
    if (isEmpty) return this;
    
    final start = visibleChars ?? 4;
    final end = visibleEndChars ?? 4;
    
    if (length <= start + end) return this;
    
    final maskedLength = length - start - end;
    final masked = maskChar * maskedLength;
    
    return '${substring(0, start)}$masked${substring(length - end)}';
  }
}
