/// Comprehensive validation classes for profile data
library;

/// Type definition for form field validators
typedef FormFieldValidator<T> = String? Function(T? value);

/// Profile validation utilities for user data
class ProfileValidators {
  // Regular expressions for validation
  static final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
  static final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final nameRegex = RegExp(r'^[a-zA-Z\s\-]{2,50}$');
  
  // Reserved usernames that cannot be used
  static const List<String> reservedUsernames = [
    'admin', 'administrator', 'system', 'support', 'api', 'root', 'user',
    'guest', 'test', 'demo', 'help', 'info', 'contact', 'service', 'staff',
    'mod', 'moderator', 'null', 'undefined', 'delete', 'remove', 'ban',
    'dabbler', 'app', 'mobile', 'android', 'ios', 'web', 'www', 'ftp',
    'mail', 'email', 'news', 'blog', 'forum', 'chat', 'game', 'play'
  ];
  
  // Inappropriate content keywords for bio validation
  static const List<String> inappropriateKeywords = [
    'spam', 'advertisement', 'buy now', 'click here', 'free money',
    'get rich', 'work from home', 'make money', 'casino', 'gambling',
    'adult', 'porn', 'sex', 'dating', 'hookup', 'escort', 'drug',
    'viagra', 'pharmacy', 'loan', 'credit', 'debt', 'insurance'
  ];
  
  /// Username validator with optional current username for edit scenarios
  static FormFieldValidator<String> username({String? currentUsername}) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Username is required';
      }
      
      // If editing and value hasn't changed, skip validation
      if (value == currentUsername) {
        return null;
      }
      
      // Length validation
      if (value.length < 3) {
        return 'Username must be at least 3 characters';
      }
      
      if (value.length > 30) {
        return 'Username must be less than 30 characters';
      }
      
      // Format validation
      if (!usernameRegex.hasMatch(value)) {
        return 'Username can only contain letters, numbers, and underscores';
      }
      
      // Cannot start or end with underscore
      if (value.startsWith('_') || value.endsWith('_')) {
        return 'Username cannot start or end with underscore';
      }
      
      // Cannot have consecutive underscores
      if (value.contains('__')) {
        return 'Username cannot have consecutive underscores';
      }
      
      // Reserved usernames check
      if (reservedUsernames.contains(value.toLowerCase())) {
        return 'This username is reserved';
      }
      
      // Cannot be all numbers
      if (RegExp(r'^\d+$').hasMatch(value)) {
        return 'Username cannot be all numbers';
      }
      
      return null;
    };
  }
  
  /// Full name validator (optional field)
  static FormFieldValidator<String> fullName() {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Optional field
      }
      
      // Trim whitespace
      final trimmed = value.trim();
      
      if (trimmed.length < 2) {
        return 'Name must be at least 2 characters';
      }
      
      if (trimmed.length > 100) {
        return 'Name must be less than 100 characters';
      }
      
      // Check for valid characters (letters, spaces, hyphens, apostrophes)
      if (!nameRegex.hasMatch(trimmed)) {
        return 'Name can only contain letters, spaces, hyphens, and apostrophes';
      }
      
      // Cannot contain numbers
      if (RegExp(r'[0-9]').hasMatch(trimmed)) {
        return 'Name should not contain numbers';
      }
      
      // Cannot have consecutive spaces
      if (trimmed.contains('  ')) {
        return 'Name cannot have consecutive spaces';
      }
      
      // Cannot start or end with space (after trim this shouldn't happen, but safety check)
      if (trimmed != value) {
        return 'Name cannot start or end with spaces';
      }
      
      return null;
    };
  }
  
  /// Bio validator with content filtering
  static FormFieldValidator<String> bio() {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Optional field
      }
      
      final trimmed = value.trim();
      
      if (trimmed.length > 500) {
        return 'Bio must be less than 500 characters';
      }
      
      if (trimmed.length < 10) {
        return 'Bio must be at least 10 characters if provided';
      }
      
      // Check for inappropriate content
      final lowerValue = trimmed.toLowerCase();
      for (final keyword in inappropriateKeywords) {
        if (lowerValue.contains(keyword)) {
          return 'Bio contains inappropriate content';
        }
      }
      
      // Check for excessive capitalization
      final upperCaseCount = trimmed.split('').where((c) => c.toUpperCase() == c && c.toLowerCase() != c).length;
      if (upperCaseCount > trimmed.length * 0.5) {
        return 'Bio contains too much capitalization';
      }
      
      // Check for repeated characters (spam detection)
      if (RegExp(r'(.)\1{4,}').hasMatch(trimmed)) {
        return 'Bio contains too many repeated characters';
      }
      
      // Check for excessive punctuation
      final punctuationCount = trimmed.split('').where((c) => '!@#\$%^&*()_+-=[]{}|;:,.<>?'.contains(c)).length;
      if (punctuationCount > trimmed.length * 0.3) {
        return 'Bio contains too much punctuation';
      }
      
      return null;
    };
  }
  
  /// Date of birth validator with age restrictions
  static FormFieldValidator<DateTime> dateOfBirth() {
    return (value) {
      if (value == null) {
        return null; // Optional field
      }
      
      final now = DateTime.now();
      
      // Cannot be in the future
      if (value.isAfter(now)) {
        return 'Birth date cannot be in the future';
      }
      
      // Calculate age
      int age = now.year - value.year;
      if (now.month < value.month || (now.month == value.month && now.day < value.day)) {
        age--;
      }
      
      // Age restrictions
      if (age < 13) {
        return 'You must be at least 13 years old to use this app';
      }
      
      if (age > 120) {
        return 'Please enter a valid birth date';
      }
      
      // Cannot be too recent (likely mistake)
      if (age < 1) {
        return 'Birth date must be at least 1 year ago';
      }
      
      return null;
    };
  }
  
  /// Email validator
  static FormFieldValidator<String> email() {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Email is required';
      }
      
      final trimmed = value.trim().toLowerCase();
      
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Please enter a valid email address';
      }
      
      // Check for common typos
      final domain = trimmed.split('@').last;
      
      // Suggest corrections for common typos
      if (domain == 'gmai.com' || domain == 'gmial.com') {
        return 'Did you mean gmail.com?';
      }
      if (domain == 'yahooo.com' || domain == 'yaho.com') {
        return 'Did you mean yahoo.com?';
      }
      
      return null;
    };
  }
  
  /// Phone number validator with international support
  static FormFieldValidator<String> phoneNumber() {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Optional field
      }
      
      // Remove all non-digit characters except +
      final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (cleaned.isEmpty) {
        return 'Please enter a valid phone number';
      }
      
      if (!phoneRegex.hasMatch(cleaned)) {
        return 'Please enter a valid phone number';
      }
      
      // Check length after country code
      final withoutCountryCode = cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;
      
      if (withoutCountryCode.length < 7) {
        return 'Phone number is too short';
      }
      
      if (withoutCountryCode.length > 15) {
        return 'Phone number is too long';
      }
      
      return null;
    };
  }
  
  /// Height validator (in centimeters)
  static FormFieldValidator<int> height() {
    return (value) {
      if (value == null) {
        return null; // Optional field
      }
      
      if (value < 100) {
        return 'Height must be at least 100cm';
      }
      
      if (value > 250) {
        return 'Height must be less than 250cm';
      }
      
      return null;
    };
  }
  
  /// Weight validator (in kilograms)
  static FormFieldValidator<double> weight() {
    return (value) {
      if (value == null) {
        return null; // Optional field
      }
      
      if (value < 30.0) {
        return 'Weight must be at least 30kg';
      }
      
      if (value > 300.0) {
        return 'Weight must be less than 300kg';
      }
      
      return null;
    };
  }
  
  /// Location/address validator
  static FormFieldValidator<String> location() {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Optional field
      }
      
      final trimmed = value.trim();
      
      if (trimmed.length < 3) {
        return 'Location must be at least 3 characters';
      }
      
      if (trimmed.length > 200) {
        return 'Location must be less than 200 characters';
      }
      
      // Basic validation for address-like content
      if (!RegExp(r'^[a-zA-Z0-9\s,.-]+$').hasMatch(trimmed)) {
        return 'Location contains invalid characters';
      }
      
      return null;
    };
  }
  
  /// Sport experience validator (years)
  static FormFieldValidator<int> sportExperience() {
    return (value) {
      if (value == null) {
        return null; // Optional field
      }
      
      if (value < 0) {
        return 'Experience cannot be negative';
      }
      
      if (value > 80) {
        return 'Experience must be less than 80 years';
      }
      
      return null;
    };
  }
  
  /// Social media handle validator
  static FormFieldValidator<String> socialMediaHandle(String platform) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Optional field
      }
      
      final trimmed = value.trim();
      
      // Remove @ symbol if present
      final handle = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
      
      if (handle.isEmpty) {
        return 'Please enter a valid $platform handle';
      }
      
      // Platform-specific validation
      switch (platform.toLowerCase()) {
        case 'instagram':
        case 'twitter':
          if (handle.length > 30) {
            return '$platform handle must be less than 30 characters';
          }
          if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(handle)) {
            return '$platform handle can only contain letters, numbers, dots, and underscores';
          }
          break;
        case 'facebook':
          if (handle.length > 50) {
            return '$platform handle must be less than 50 characters';
          }
          break;
      }
      
      return null;
    };
  }
  
  /// Validate multiple profile fields at once
  static Map<String, String?> validateProfile({
    String? username,
    String? currentUsername,
    String? fullName,
    String? email,
    String? bio,
    DateTime? dateOfBirth,
    String? phoneNumber,
    int? height,
    double? weight,
    String? location,
  }) {
    final errors = <String, String?>{};
    
    errors['username'] = ProfileValidators.username(currentUsername: currentUsername)(username);
    errors['fullName'] = ProfileValidators.fullName()(fullName);
    errors['email'] = ProfileValidators.email()(email);
    errors['bio'] = ProfileValidators.bio()(bio);
    errors['dateOfBirth'] = ProfileValidators.dateOfBirth()(dateOfBirth);
    errors['phoneNumber'] = ProfileValidators.phoneNumber()(phoneNumber);
    errors['height'] = ProfileValidators.height()(height);
    errors['weight'] = ProfileValidators.weight()(weight);
    errors['location'] = ProfileValidators.location()(location);
    
    // Remove null entries (no errors)
    errors.removeWhere((key, value) => value == null);
    
    return errors;
  }
  
  /// Check if username is potentially available (client-side check)
  static bool isUsernamePotentiallyAvailable(String username) {
    if (username.length < 3 || username.length > 30) return false;
    if (!usernameRegex.hasMatch(username)) return false;
    if (reservedUsernames.contains(username.toLowerCase())) return false;
    return true;
  }
  
  /// Get username suggestions based on full name
  static List<String> generateUsernameSuggestions(String? fullName, {int count = 5}) {
    if (fullName == null || fullName.trim().isEmpty) return [];
    
    final suggestions = <String>[];
    final cleanName = fullName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '');
    final parts = cleanName.split(' ').where((part) => part.isNotEmpty).toList();
    
    if (parts.isEmpty) return [];
    
    // First name + last initial
    if (parts.length >= 2) {
      suggestions.add('${parts[0]}${parts[1][0]}');
    }
    
    // First initial + last name
    if (parts.length >= 2) {
      suggestions.add('${parts[0][0]}${parts[1]}');
    }
    
    // Full first name with numbers
    suggestions.add('${parts[0]}123');
    suggestions.add('${parts[0]}2024');
    
    // Concatenated names
    if (parts.length >= 2) {
      suggestions.add('${parts[0]}${parts[1]}');
    }
    
    // Add underscore variations
    if (parts.length >= 2) {
      suggestions.add('${parts[0]}_${parts[1]}');
    }
    
    // Filter valid suggestions and remove duplicates
    return suggestions
        .where((s) => s.length >= 3 && s.length <= 30 && usernameRegex.hasMatch(s))
        .take(count)
        .toList();
  }
}
