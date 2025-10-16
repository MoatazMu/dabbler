/// Helper class for validating profile data and ensuring data integrity
library;
import '../../constants/profile_constants.dart';

/// Temporary model class for profile validation
/// TODO: Replace with actual model from features/profile/data/models/
class UserProfile {
  final String? username;
  final String? fullName;
  final String? bio;
  final String? email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? location;
  final String? avatarUrl;
  final List<SportProfile> sportsProfiles;
  
  const UserProfile({
    this.username,
    this.fullName,
    this.bio,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.avatarUrl,
    this.sportsProfiles = const [],
  });
}

class SportProfile {
  final String sport;
  final int skillLevel;
  final int yearsPlaying;
  
  const SportProfile({
    required this.sport,
    required this.skillLevel,
    required this.yearsPlaying,
  });
}

/// Helper class for validating profile data and ensuring data integrity
class ProfileValidationHelper {
  /// Validate username with comprehensive checks
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }
    
    final trimmedUsername = username.trim();
    
    if (trimmedUsername.length < ProfileLimits.minUsernameLength) {
      return 'Username must be at least ${ProfileLimits.minUsernameLength} characters';
    }
    
    if (trimmedUsername.length > ProfileLimits.maxUsernameLength) {
      return 'Username must be less than ${ProfileLimits.maxUsernameLength} characters';
    }
    
    if (!RegExp(ProfileValidation.usernamePattern).hasMatch(trimmedUsername)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    // Check for reserved usernames
    final reservedUsernames = [
      'admin', 'root', 'system', 'support', 'help', 'info', 'contact',
      'api', 'www', 'mail', 'ftp', 'null', 'undefined', 'test', 'demo'
    ];
    
    if (reservedUsernames.contains(trimmedUsername.toLowerCase())) {
      return 'This username is reserved and cannot be used';
    }
    
    return null;
  }

  /// Validate full name
  static String? validateFullName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Full name is required';
    }
    
    final trimmedName = fullName.trim();
    
    if (trimmedName.length < ProfileLimits.minNameLength) {
      return 'Full name must be at least ${ProfileLimits.minNameLength} characters';
    }
    
    if (trimmedName.length > ProfileLimits.maxNameLength) {
      return 'Full name must be less than ${ProfileLimits.maxNameLength} characters';
    }
    
    if (!RegExp(ProfileValidation.namePattern).hasMatch(trimmedName)) {
      return 'Full name contains invalid characters';
    }
    
    return null;
  }

  /// Validate bio content
  static String? validateBio(String? bio) {
    if (bio == null) return null; // Bio is optional
    
    final trimmedBio = bio.trim();
    
    if (trimmedBio.isEmpty) return null; // Empty bio is valid
    
    if (trimmedBio.length > ProfileLimits.maxBioLength) {
      return 'Bio must be less than ${ProfileLimits.maxBioLength} characters';
    }
    
    if (trimmedBio.length < ProfileLimits.minBioLength) {
      return 'Bio must be at least ${ProfileLimits.minBioLength} characters';
    }
    
    // Check for inappropriate content patterns (basic)
    final inappropriatePatterns = [
      r'\b(spam|scam|fraud)\b',
      r'\b(contact me at|call me|email me)\b',
      r'(https?://|www\.)',
    ];
    
    for (final pattern in inappropriatePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(trimmedBio)) {
        return 'Bio contains inappropriate content or links';
      }
    }
    
    return null;
  }

  /// Validate email address
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    
    final trimmedEmail = email.trim().toLowerCase();
    
    if (!RegExp(ProfileValidation.emailPattern).hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return null; // Phone number is optional
    }
    
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    
    if (cleanedPhone.length < 10 || cleanedPhone.length > 15) {
      return 'Please enter a valid phone number';
    }
    
    if (!RegExp(ProfileValidation.phonePattern).hasMatch(cleanedPhone)) {
      return 'Phone number contains invalid characters';
    }
    
    return null;
  }

  /// Validate date of birth and calculate age
  static String? validateDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return 'Date of birth is required';
    }
    
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    final hasHadBirthdayThisYear = now.month > dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    
    final actualAge = hasHadBirthdayThisYear ? age : age - 1;
    
    if (actualAge < ProfileLimits.minAge) {
      return 'You must be at least ${ProfileLimits.minAge} years old to use this app';
    }
    
    if (actualAge > ProfileLimits.maxAge) {
      return 'Please enter a valid date of birth';
    }
    
    if (dateOfBirth.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    
    return null;
  }

  /// Check if age is valid (alternative method without error message)
  static bool isValidAge(DateTime? dateOfBirth) {
    return validateDateOfBirth(dateOfBirth) == null;
  }

  /// Calculate age from date of birth
  static int calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Validate location
  static String? validateLocation(String? location) {
    if (location == null || location.trim().isEmpty) {
      return null; // Location is optional
    }
    
    final trimmedLocation = location.trim();
    
    if (trimmedLocation.length > ProfileLimits.maxLocationLength) {
      return 'Location must be less than ${ProfileLimits.maxLocationLength} characters';
    }
    
    if (!RegExp(ProfileValidation.locationPattern).hasMatch(trimmedLocation)) {
      return 'Location contains invalid characters';
    }
    
    return null;
  }

  /// Validate sports profile
  static String? validateSportProfile(SportProfile sport) {
    if (sport.sport.isEmpty) {
      return 'Sport name is required';
    }
    
    if (sport.sport.length > 50) {
      return 'Sport name is too long';
    }
    
    if (sport.skillLevel < 1 || sport.skillLevel > 5) {
      return 'Skill level must be between 1 and 5';
    }
    
    if (sport.yearsPlaying < 0 || sport.yearsPlaying > 80) {
      return 'Years playing must be between 0 and 80';
    }
    
    return null;
  }

  /// Comprehensive profile validation
  static Map<String, String?> validateProfile(UserProfile profile) {
    final validationResults = <String, String?>{};
    
    validationResults['username'] = validateUsername(profile.username);
    validationResults['fullName'] = validateFullName(profile.fullName);
    validationResults['bio'] = validateBio(profile.bio);
    validationResults['email'] = validateEmail(profile.email);
    validationResults['phoneNumber'] = validatePhoneNumber(profile.phoneNumber);
    validationResults['dateOfBirth'] = validateDateOfBirth(profile.dateOfBirth);
    validationResults['location'] = validateLocation(profile.location);
    
    // Validate sports profiles
    for (int i = 0; i < profile.sportsProfiles.length; i++) {
      final sportError = validateSportProfile(profile.sportsProfiles[i]);
      if (sportError != null) {
        validationResults['sport_$i'] = sportError;
      }
    }
    
    return validationResults;
  }

  /// Get only validation errors (non-null values)
  static Map<String, String> getValidationErrors(UserProfile profile) {
    final allResults = validateProfile(profile);
    final errors = <String, String>{};
    
    allResults.forEach((key, value) {
      if (value != null) {
        errors[key] = value;
      }
    });
    
    return errors;
  }

  /// Check if profile passes basic validation
  static bool isProfileValid(UserProfile profile) {
    final errors = getValidationErrors(profile);
    return errors.isEmpty;
  }

  /// Check if profile is ready for specific features
  static bool isReadyForMessaging(UserProfile profile) {
    final requiredFields = [
      validateUsername(profile.username),
      validateFullName(profile.fullName),
      validateEmail(profile.email),
      validateDateOfBirth(profile.dateOfBirth),
    ];
    
    return requiredFields.every((error) => error == null);
  }

  static bool isReadyForGameCreation(UserProfile profile) {
    final isBasicValid = isReadyForMessaging(profile);
    final hasSports = profile.sportsProfiles.isNotEmpty;
    final sportsValid = profile.sportsProfiles.every(
      (sport) => validateSportProfile(sport) == null
    );
    
    return isBasicValid && hasSports && sportsValid;
  }

  /// Get validation progress
  static Map<String, dynamic> getValidationProgress(UserProfile profile) {
    final allFields = [
      'username', 'fullName', 'bio', 'email', 
      'phoneNumber', 'dateOfBirth', 'location'
    ];
    
    final validationResults = validateProfile(profile);
    final validFields = allFields.where(
      (field) => validationResults[field] == null && 
                 _hasValue(profile, field)
    ).length;
    
    final totalFields = allFields.length;
    final progressPercentage = (validFields / totalFields * 100).round();
    
    return {
      'valid_fields': validFields,
      'total_fields': totalFields,
      'progress_percentage': progressPercentage,
      'is_complete': validFields == totalFields,
      'missing_fields': _getMissingRequiredFields(profile),
    };
  }

  /// Get field-specific validation with suggestions
  static Map<String, dynamic> getFieldValidation(String field, String? value) {
    String? error;
    List<String> suggestions = [];
    
    switch (field) {
      case 'username':
        error = validateUsername(value);
        if (error != null) {
          suggestions = [
            'Use 3-30 characters',
            'Only letters, numbers, and underscores',
            'Choose something unique and memorable'
          ];
        }
        break;
      case 'fullName':
        error = validateFullName(value);
        if (error != null) {
          suggestions = [
            'Enter your real first and last name',
            'Use 2-50 characters',
            'Only letters, spaces, hyphens, and apostrophes'
          ];
        }
        break;
      case 'bio':
        error = validateBio(value);
        if (error != null) {
          suggestions = [
            'Tell others about yourself',
            'Keep it under ${ProfileLimits.maxBioLength} characters',
            'Avoid links and contact information'
          ];
        }
        break;
      case 'email':
        error = validateEmail(value);
        if (error != null) {
          suggestions = [
            'Use a valid email format (e.g., user@example.com)',
            'Make sure you can access this email',
            'This will be used for important notifications'
          ];
        }
        break;
    }
    
    return {
      'is_valid': error == null,
      'error': error,
      'suggestions': suggestions,
    };
  }

  /// Private helper methods
  static bool _hasValue(UserProfile profile, String field) {
    switch (field) {
      case 'username': return profile.username?.isNotEmpty ?? false;
      case 'fullName': return profile.fullName?.isNotEmpty ?? false;
      case 'bio': return profile.bio?.isNotEmpty ?? false;
      case 'email': return profile.email?.isNotEmpty ?? false;
      case 'phoneNumber': return profile.phoneNumber?.isNotEmpty ?? false;
      case 'dateOfBirth': return profile.dateOfBirth != null;
      case 'location': return profile.location?.isNotEmpty ?? false;
      default: return false;
    }
  }

  static List<String> _getMissingRequiredFields(UserProfile profile) {
    final missing = <String>[];
    
    if (validateUsername(profile.username) != null || profile.username?.isEmpty == true) {
      missing.add('username');
    }
    if (validateFullName(profile.fullName) != null || profile.fullName?.isEmpty == true) {
      missing.add('full name');
    }
    if (validateEmail(profile.email) != null || profile.email?.isEmpty == true) {
      missing.add('email');
    }
    if (validateDateOfBirth(profile.dateOfBirth) != null) {
      missing.add('date of birth');
    }
    
    return missing;
  }

  /// Validate avatar URL
  static String? validateAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null; // Optional
    
    // Basic URL validation
    if (!RegExp(r'^https?://').hasMatch(avatarUrl)) {
      return 'Avatar URL must start with http:// or https://';
    }
    
    // Check for common image extensions
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasValidExtension = imageExtensions.any((ext) => 
        avatarUrl.toLowerCase().contains(ext));
    
    if (!hasValidExtension) {
      return 'Avatar must be an image file (jpg, png, gif, webp)';
    }
    
    return null;
  }

  /// Check if username is available (placeholder for API call)
  static Future<bool> isUsernameAvailable(String username) async {
    // TODO: Implement actual API call to check username availability
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate some unavailable usernames
    final unavailableUsernames = ['admin', 'user', 'test', 'demo', 'john', 'jane'];
    return !unavailableUsernames.contains(username.toLowerCase());
  }

  /// Validate and suggest alternative usernames
  static Future<Map<String, dynamic>> validateUsernameWithSuggestions(String username) async {
    final basicValidation = validateUsername(username);
    
    if (basicValidation != null) {
      return {
        'is_valid': false,
        'error': basicValidation,
        'suggestions': []
      };
    }
    
    final isAvailable = await isUsernameAvailable(username);
    
    if (isAvailable) {
      return {
        'is_valid': true,
        'error': null,
        'suggestions': []
      };
    }
    
    // Generate alternative suggestions
    final suggestions = <String>[];
    for (int i = 1; i <= 5; i++) {
      final suggestion = '$username$i';
      if (await isUsernameAvailable(suggestion)) {
        suggestions.add(suggestion);
      }
    }
    
    return {
      'is_valid': false,
      'error': 'Username is already taken',
      'suggestions': suggestions
    };
  }
}
