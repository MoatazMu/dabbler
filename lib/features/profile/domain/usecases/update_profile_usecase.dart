import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

/// Parameters for updating profile
class UpdateProfileParams {
  final String userId;
  final String? displayName;
  final String? bio;
  final String? email;
  final String? phoneNumber;
  final String? location;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final DateTime? dateOfBirth;

  const UpdateProfileParams({
    required this.userId,
    this.displayName,
    this.bio,
    this.email,
    this.phoneNumber,
    this.location,
    this.firstName,
    this.lastName,
    this.gender,
    this.dateOfBirth,
  });

  bool get hasUpdates => displayName != null ||
      bio != null ||
      email != null ||
      phoneNumber != null ||
      location != null ||
      firstName != null ||
      lastName != null ||
      gender != null ||
      dateOfBirth != null;
}

/// Result of profile update operation
class UpdateProfileResult {
  final UserProfile updatedProfile;
  final List<String> warnings;
  final Map<String, dynamic> changedFields;
  final double completionPercentage;

  const UpdateProfileResult({
    required this.updatedProfile,
    required this.warnings,
    required this.changedFields,
    required this.completionPercentage,
  });
}

/// Use case for updating user profile with comprehensive validation and business logic
class UpdateProfileUseCase {
  final ProfileRepository _profileRepository;

  UpdateProfileUseCase(this._profileRepository);

  Future<Either<Failure, UpdateProfileResult>> call(UpdateProfileParams params) async {
    try {
      // Validate input parameters
      final validationResult = _validateParams(params);
      if (validationResult.isLeft) {
        return Left(validationResult.leftOrNull()!);
      }

      // Get current profile for comparison
      final currentProfileResult = await _profileRepository.getProfile(params.userId);
      if (currentProfileResult.isLeft) {
        return Left(currentProfileResult.leftOrNull()!);
      }
      
      final currentProfile = currentProfileResult.rightOrNull()!;

      // Sanitize input data
      final sanitizedParams = _sanitizeParams(params);
      
      // Apply business rules and constraints
      final processedParams = _applyBusinessRules(sanitizedParams, currentProfile);
      if (processedParams.isLeft) {
        return Left(processedParams.leftOrNull()!);
      }

      final finalParams = processedParams.rightOrNull()!;

      // Create updated profile with new values
      final updatedProfile = UserProfile(
        id: currentProfile.id,
        email: finalParams.email ?? currentProfile.email,
        displayName: finalParams.displayName ?? currentProfile.displayName,
        avatarUrl: currentProfile.avatarUrl,
        createdAt: currentProfile.createdAt,
        updatedAt: DateTime.now(),
        bio: finalParams.bio ?? currentProfile.bio,
        dateOfBirth: finalParams.dateOfBirth ?? currentProfile.dateOfBirth,
        location: finalParams.location ?? currentProfile.location,
        phoneNumber: finalParams.phoneNumber ?? currentProfile.phoneNumber,
        firstName: finalParams.firstName ?? currentProfile.firstName,
        lastName: finalParams.lastName ?? currentProfile.lastName,
        gender: finalParams.gender ?? currentProfile.gender,
        profileCompletionPercentage: currentProfile.profileCompletionPercentage,
        isVerified: currentProfile.isVerified,
        lastActiveAt: currentProfile.lastActiveAt,
        sportsProfiles: currentProfile.sportsProfiles,
        statistics: currentProfile.statistics,
        privacySettings: currentProfile.privacySettings,
        preferences: currentProfile.preferences,
        settings: currentProfile.settings,
      );

      // Perform the update
      final updateResult = await _profileRepository.updateProfile(updatedProfile);
      if (updateResult.isLeft) {
        return Left(updateResult.leftOrNull()!);
      }

      final finalUpdatedProfile = updateResult.rightOrNull()!;

      // Calculate changed fields
      final changedFields = _calculateChangedFields(currentProfile, finalUpdatedProfile);

      // Calculate completion percentage
      final completionPercentage = _calculateCompletionPercentage(finalUpdatedProfile);

      // Generate warnings
      final warnings = _generateWarnings(finalUpdatedProfile, changedFields);

      return Right(UpdateProfileResult(
        updatedProfile: finalUpdatedProfile,
        warnings: warnings,
        changedFields: changedFields,
        completionPercentage: completionPercentage,
      ));

    } catch (e) {
      return Left(DataFailure(message: 'Profile update failed: $e'));
    }
  }

  /// Validate input parameters
  Either<Failure, void> _validateParams(UpdateProfileParams params) {
    final errors = <String>[];

    // Validate display name
    if (params.displayName != null) {
      if (params.displayName!.trim().isEmpty) {
        errors.add('Display name cannot be empty');
      } else if (params.displayName!.length < 2) {
        errors.add('Display name must be at least 2 characters');
      } else if (params.displayName!.length > 50) {
        errors.add('Display name cannot exceed 50 characters');
      } else if (!_isValidDisplayName(params.displayName!)) {
        errors.add('Display name contains invalid characters');
      }
    }

    // Validate email
    if (params.email != null && params.email!.isNotEmpty) {
      if (!_isValidEmail(params.email!)) {
        errors.add('Invalid email format');
      }
    }

    // Validate phone number
    if (params.phoneNumber != null && params.phoneNumber!.isNotEmpty) {
      if (!_isValidPhoneNumber(params.phoneNumber!)) {
        errors.add('Invalid phone number format');
      }
    }

    // Validate bio
    if (params.bio != null && params.bio!.length > 500) {
      errors.add('Bio cannot exceed 500 characters');
    }

    // Validate location
    if (params.location != null && params.location!.length > 100) {
      errors.add('Location cannot exceed 100 characters');
    }

    // Validate first name
    if (params.firstName != null && params.firstName!.length > 50) {
      errors.add('First name cannot exceed 50 characters');
    }

    // Validate last name
    if (params.lastName != null && params.lastName!.length > 50) {
      errors.add('Last name cannot exceed 50 characters');
    }

    // Validate gender
    if (params.gender != null && params.gender!.isNotEmpty) {
      const validGenders = ['male', 'female', 'non-binary', 'prefer_not_to_say', 'other'];
      if (!validGenders.contains(params.gender!.toLowerCase())) {
        errors.add('Invalid gender value');
      }
    }

    // Validate date of birth
    if (params.dateOfBirth != null) {
      final now = DateTime.now();
      final minAge = Duration(days: 13 * 365); // 13 years
      if (now.difference(params.dateOfBirth!) < minAge) {
        errors.add('Minimum age requirement is 13 years');
      }
    }

    if (errors.isNotEmpty) {
      return Left(ValidationFailure(message: errors.join(', ')));
    }

    return const Right(null);
  }

  /// Sanitize input parameters
  UpdateProfileParams _sanitizeParams(UpdateProfileParams params) {
    return UpdateProfileParams(
      userId: params.userId,
      displayName: params.displayName?.trim(),
      bio: params.bio?.trim(),
      email: params.email?.trim().toLowerCase(),
      phoneNumber: params.phoneNumber?.trim(),
      location: params.location?.trim(),
      firstName: params.firstName?.trim(),
      lastName: params.lastName?.trim(),
      gender: params.gender?.trim().toLowerCase(),
      dateOfBirth: params.dateOfBirth,
    );
  }

  /// Apply business rules and constraints
  Either<Failure, UpdateProfileParams> _applyBusinessRules(
    UpdateProfileParams params,
    UserProfile currentProfile,
  ) {
    var processedParams = params;

    // Business Rule: Display name profanity filter
    if (params.displayName != null) {
      final cleanDisplayName = _filterProfanity(params.displayName!);
      if (cleanDisplayName != params.displayName) {
        processedParams = UpdateProfileParams(
          userId: params.userId,
          displayName: cleanDisplayName,
          bio: params.bio,
          email: params.email,
          phoneNumber: params.phoneNumber,
          location: params.location,
          firstName: params.firstName,
          lastName: params.lastName,
          gender: params.gender,
          dateOfBirth: params.dateOfBirth,
        );
      }
    }

    // Business Rule: Bio profanity filter
    if (params.bio != null) {
      final cleanBio = _filterProfanity(params.bio!);
      if (cleanBio != params.bio) {
        processedParams = UpdateProfileParams(
          userId: processedParams.userId,
          displayName: processedParams.displayName,
          bio: cleanBio,
          email: processedParams.email,
          phoneNumber: processedParams.phoneNumber,
          location: processedParams.location,
          firstName: processedParams.firstName,
          lastName: processedParams.lastName,
          gender: processedParams.gender,
          dateOfBirth: processedParams.dateOfBirth,
        );
      }
    }

    return Right(processedParams);
  }

  /// Calculate which fields have changed
  Map<String, dynamic> _calculateChangedFields(UserProfile current, UserProfile updated) {
    final changes = <String, dynamic>{};

    if (current.displayName != updated.displayName) {
      changes['display_name'] = {
        'old': current.displayName,
        'new': updated.displayName,
      };
    }

    if (current.bio != updated.bio) {
      changes['bio'] = {
        'old': current.bio,
        'new': updated.bio,
      };
    }

    if (current.email != updated.email) {
      changes['email'] = {
        'old': current.email,
        'new': updated.email,
      };
    }

    if (current.phoneNumber != updated.phoneNumber) {
      changes['phone_number'] = {
        'old': current.phoneNumber,
        'new': updated.phoneNumber,
      };
    }

    if (current.location != updated.location) {
      changes['location'] = {
        'old': current.location,
        'new': updated.location,
      };
    }

    if (current.firstName != updated.firstName) {
      changes['first_name'] = {
        'old': current.firstName,
        'new': updated.firstName,
      };
    }

    if (current.lastName != updated.lastName) {
      changes['last_name'] = {
        'old': current.lastName,
        'new': updated.lastName,
      };
    }

    if (current.gender != updated.gender) {
      changes['gender'] = {
        'old': current.gender,
        'new': updated.gender,
      };
    }

    if (current.dateOfBirth != updated.dateOfBirth) {
      changes['date_of_birth'] = {
        'old': current.dateOfBirth,
        'new': updated.dateOfBirth,
      };
    }

    return changes;
  }

  /// Calculate profile completion percentage
  double _calculateCompletionPercentage(UserProfile profile) {
    final requiredFields = [
      profile.displayName.isNotEmpty,
      profile.email.isNotEmpty,
      profile.bio?.isNotEmpty == true,
      profile.location?.isNotEmpty == true,
      profile.dateOfBirth != null,
      profile.avatarUrl?.isNotEmpty == true,
      profile.firstName?.isNotEmpty == true,
      profile.lastName?.isNotEmpty == true,
    ];

    final optionalFields = [
      profile.phoneNumber?.isNotEmpty == true,
      profile.gender?.isNotEmpty == true,
      profile.sportsProfiles.isNotEmpty,
    ];

    final completedRequired = requiredFields.where((field) => field).length;
    final completedOptional = optionalFields.where((field) => field).length;

    // Weight required fields more heavily
    final totalPossible = (requiredFields.length * 0.8) + (optionalFields.length * 0.2);
    final totalCompleted = (completedRequired * 0.8) + (completedOptional * 0.2);

    return (totalCompleted / totalPossible * 100).clamp(0.0, 100.0);
  }

  /// Generate warnings for the user
  List<String> _generateWarnings(UserProfile profile, Map<String, dynamic> changedFields) {
    final warnings = <String>[];

    // Warning: Profile completion
    final completion = _calculateCompletionPercentage(profile);
    if (completion < 80) {
      warnings.add('Profile is ${completion.toStringAsFixed(0)}% complete. Consider adding more information.');
    }

    // Warning: Missing avatar
    if (profile.avatarUrl == null || profile.avatarUrl!.isEmpty) {
      warnings.add('Consider adding a profile photo to help others recognize you.');
    }

    // Warning: Short bio
    if (profile.bio != null && profile.bio!.length < 50) {
      warnings.add('A longer bio helps others understand your interests better.');
    }

    // Warning: No location
    if (profile.location == null || profile.location!.isEmpty) {
      warnings.add('Adding your location helps find nearby games and players.');
    }

    // Warning: Privacy implications
    if (changedFields.containsKey('email')) {
      warnings.add('Email changes may affect your login and notifications.');
    }

    return warnings;
  }

  // Validation helper methods
  bool _isValidDisplayName(String name) {
    // Allow letters, numbers, spaces, and common punctuation
    return RegExp(r'^[a-zA-Z0-9\s\-_.]+$').hasMatch(name);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhoneNumber(String phone) {
    // Basic phone number validation (international format)
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone.replaceAll(RegExp(r'[\s\-()]'), ''));
  }

  String _filterProfanity(String text) {
    // Simple profanity filter - in production, use a proper service
    const profanityWords = ['spam', 'scam', 'fake']; // Add actual profanity list
    var cleanText = text;
    
    for (final word in profanityWords) {
      cleanText = cleanText.replaceAll(
        RegExp(word, caseSensitive: false),
        '*' * word.length,
      );
    }
    
    return cleanText;
  }
}
