import '../constants/app_constants.dart';

/// Helper class for common validation scenarios
class ValidationHelper {
  /// Validates email addresses
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return AppConstants.emailRegex.hasMatch(email);
  }

  /// Validates phone numbers
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    return AppConstants.phoneRegex.hasMatch(phone);
  }

  /// Validates URLs
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    return AppConstants.urlRegex.hasMatch(url);
  }

  /// Validates required fields
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validates password strength
  /// Returns a map with validation results and a message
  static Map<String, dynamic> validatePassword(String password) {
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    int strength = 0;
    if (hasMinLength) strength++;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialCharacters) strength++;

    String message = '';
    bool isValid = false;

    switch (strength) {
      case 0:
      case 1:
        message = 'Very weak password';
        break;
      case 2:
        message = 'Weak password';
        break;
      case 3:
        message = 'Medium strength password';
        break;
      case 4:
        message = 'Strong password';
        isValid = true;
        break;
      case 5:
        message = 'Very strong password';
        isValid = true;
        break;
    }

    return {
      'isValid': isValid,
      'message': message,
      'strength': strength,
      'requirements': {
        'minLength': hasMinLength,
        'uppercase': hasUppercase,
        'lowercase': hasLowercase,
        'digits': hasDigits,
        'specialCharacters': hasSpecialCharacters,
      },
    };
  }

  /// Validates date format
  static bool isValidDate(String date) {
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates age (must be over minimum age)
  static bool isValidAge(DateTime birthDate, {int minimumAge = 13}) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final age = difference.inDays ~/ 365;
    return age >= minimumAge;
  }

  /// Validates file size
  static bool isValidFileSize(int sizeInBytes, int maxSizeInBytes) {
    return sizeInBytes <= maxSizeInBytes;
  }

  /// Validates file type
  static bool isValidFileType(String fileName, List<String> allowedExtensions) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Validates credit card number using Luhn algorithm
  static bool isValidCreditCard(String cardNumber) {
    // Remove any spaces or dashes
    cardNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(cardNumber)) {
      return false;
    }

    int sum = 0;
    bool alternate = false;
    
    // Loop through values starting from the rightmost digit
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validates username format
  static bool isValidUsername(String username) {
    // Alphanumeric with underscores and dots, 3-30 characters
    return RegExp(r'^[a-zA-Z0-9._]{3,30}$').hasMatch(username);
  }

  /// Validates postal code format
  static bool isValidPostalCode(String postalCode, {String country = 'US'}) {
    final patterns = {
      'US': r'^\d{5}(-\d{4})?$',
      'UK': r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$',
      'CA': r'^[A-Z]\d[A-Z] ?\d[A-Z]\d$',
    };

    final pattern = patterns[country] ?? patterns['US']!;
    return RegExp(pattern, caseSensitive: false).hasMatch(postalCode);
  }
}
