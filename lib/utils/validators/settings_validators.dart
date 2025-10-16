/// Comprehensive validation classes for user settings and preferences
library;

/// Temporary model class for user preferences
class UserPreferences {
  final int? preferredRadiusKm;
  final int? preferredGameDuration; // in minutes
  final int? preferredTeamSizeMin;
  final int? preferredTeamSizeMax;
  final int? preferredAgeRangeMin;
  final int? preferredAgeRangeMax;
  final List<String> preferredSports;
  final List<String> preferredDays;
  final List<String> preferredTimes;
  final String? preferredSkillLevel;
  final bool allowMixedGender;
  final bool allowDifferentSkillLevels;
  final int? maxTravelTime; // in minutes
  final String? preferredCommunication;
  
  const UserPreferences({
    this.preferredRadiusKm,
    this.preferredGameDuration,
    this.preferredTeamSizeMin,
    this.preferredTeamSizeMax,
    this.preferredAgeRangeMin,
    this.preferredAgeRangeMax,
    this.preferredSports = const [],
    this.preferredDays = const [],
    this.preferredTimes = const [],
    this.preferredSkillLevel,
    this.allowMixedGender = true,
    this.allowDifferentSkillLevels = true,
    this.maxTravelTime,
    this.preferredCommunication,
  });
}

/// Settings and preferences validation utilities
class SettingsValidators {
  // Constants for validation ranges
  static const int minRadius = 1;
  static const int maxRadius = 100;
  static const int minGameDuration = 15; // 15 minutes
  static const int maxGameDuration = 480; // 8 hours
  static const int minTeamSize = 1;
  static const int maxTeamSize = 50;
  static const int minAge = 13;
  static const int maxAge = 100;
  static const int minTravelTime = 5; // 5 minutes
  static const int maxTravelTime = 180; // 3 hours
  
  // Valid options for preferences
  static const List<String> validSkillLevels = [
    'beginner', 'intermediate', 'advanced', 'expert'
  ];
  
  static const List<String> validDays = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  
  static const List<String> validTimeSlots = [
    'early_morning', 'morning', 'afternoon', 'evening', 'night', 'late_night'
  ];
  
  static const List<String> validCommunicationMethods = [
    'in_app', 'phone', 'email', 'whatsapp', 'telegram'
  ];
  
  /// Validate search radius in kilometers
  static String? validateRadius(int? radius) {
    if (radius == null) {
      return 'Search radius is required';
    }
    
    if (radius < minRadius) {
      return 'Search radius must be at least $minRadius km';
    }
    
    if (radius > maxRadius) {
      return 'Search radius cannot exceed $maxRadius km';
    }
    
    return null;
  }
  
  /// Validate game duration in minutes
  static String? validateGameDuration(int? duration) {
    if (duration == null) {
      return 'Game duration is required';
    }
    
    if (duration < minGameDuration) {
      return 'Game duration must be at least $minGameDuration minutes';
    }
    
    if (duration > maxGameDuration) {
      return 'Game duration cannot exceed ${maxGameDuration ~/ 60} hours';
    }
    
    // Should be in reasonable increments (15 minute intervals)
    if (duration % 15 != 0) {
      return 'Game duration should be in 15-minute intervals';
    }
    
    return null;
  }
  
  /// Validate team size range
  static String? validateTeamSize(int? min, int? max) {
    if (min == null && max == null) {
      return 'Team size preferences are required';
    }
    
    if (min != null) {
      if (min < minTeamSize) {
        return 'Minimum team size must be at least $minTeamSize';
      }
      if (min > maxTeamSize) {
        return 'Minimum team size cannot exceed $maxTeamSize';
      }
    }
    
    if (max != null) {
      if (max < minTeamSize) {
        return 'Maximum team size must be at least $minTeamSize';
      }
      if (max > maxTeamSize) {
        return 'Maximum team size cannot exceed $maxTeamSize';
      }
    }
    
    if (min != null && max != null) {
      if (min > max) {
        return 'Minimum team size cannot be greater than maximum';
      }
      
      // Reasonable range check
      if (max - min > 30) {
        return 'Team size range is too broad (max difference: 30)';
      }
    }
    
    return null;
  }
  
  /// Validate age range preferences
  static String? validateAgeRange(int? min, int? max) {
    if (min != null) {
      if (min < minAge) {
        return 'Minimum age must be at least $minAge';
      }
      if (min > maxAge) {
        return 'Minimum age cannot exceed $maxAge';
      }
    }
    
    if (max != null) {
      if (max < minAge) {
        return 'Maximum age must be at least $minAge';
      }
      if (max > maxAge) {
        return 'Maximum age cannot exceed $maxAge';
      }
    }
    
    if (min != null && max != null) {
      if (min > max) {
        return 'Minimum age cannot be greater than maximum';
      }
      
      // Age range shouldn't be too narrow for adults
      if (min > 21 && max > 21 && (max - min) < 5) {
        return 'Age range is too narrow (minimum 5 years for adults)';
      }
    }
    
    return null;
  }
  
  /// Validate travel time in minutes
  static String? validateTravelTime(int? travelTime) {
    if (travelTime == null) {
      return null; // Optional field
    }
    
    if (travelTime < minTravelTime) {
      return 'Travel time must be at least $minTravelTime minutes';
    }
    
    if (travelTime > maxTravelTime) {
      return 'Travel time cannot exceed ${maxTravelTime ~/ 60} hours';
    }
    
    // Should be in 5-minute increments
    if (travelTime % 5 != 0) {
      return 'Travel time should be in 5-minute intervals';
    }
    
    return null;
  }
  
  /// Validate skill level preference
  static String? validateSkillLevel(String? skillLevel) {
    if (skillLevel == null || skillLevel.isEmpty) {
      return null; // Optional field
    }
    
    if (!validSkillLevels.contains(skillLevel.toLowerCase())) {
      return 'Invalid skill level. Must be one of: ${validSkillLevels.join(', ')}';
    }
    
    return null;
  }
  
  /// Validate preferred days
  static String? validatePreferredDays(List<String>? days) {
    if (days == null || days.isEmpty) {
      return 'Please select at least one preferred day';
    }
    
    if (days.length > 7) {
      return 'Cannot select more than 7 days';
    }
    
    // Check for invalid days
    for (final day in days) {
      if (!validDays.contains(day.toLowerCase())) {
        return 'Invalid day: $day';
      }
    }
    
    // Check for duplicates
    if (days.length != days.toSet().length) {
      return 'Duplicate days selected';
    }
    
    return null;
  }
  
  /// Validate preferred time slots
  static String? validatePreferredTimes(List<String>? times) {
    if (times == null || times.isEmpty) {
      return 'Please select at least one preferred time';
    }
    
    if (times.length > validTimeSlots.length) {
      return 'Cannot select more time slots than available';
    }
    
    // Check for invalid time slots
    for (final time in times) {
      if (!validTimeSlots.contains(time.toLowerCase())) {
        return 'Invalid time slot: $time';
      }
    }
    
    // Check for duplicates
    if (times.length != times.toSet().length) {
      return 'Duplicate time slots selected';
    }
    
    return null;
  }
  
  /// Validate preferred sports list
  static String? validatePreferredSports(List<String>? sports) {
    if (sports == null || sports.isEmpty) {
      return 'Please select at least one sport';
    }
    
    if (sports.length > 10) {
      return 'Cannot select more than 10 sports';
    }
    
    // Check for duplicates
    if (sports.length != sports.toSet().length) {
      return 'Duplicate sports selected';
    }
    
    // Validate sport names (basic check)
    for (final sport in sports) {
      if (sport.trim().isEmpty) {
        return 'Sport names cannot be empty';
      }
      
      if (sport.length > 30) {
        return 'Sport name too long: $sport';
      }
    }
    
    return null;
  }
  
  /// Validate communication method preference
  static String? validateCommunicationMethod(String? method) {
    if (method == null || method.isEmpty) {
      return null; // Optional field
    }
    
    if (!validCommunicationMethods.contains(method.toLowerCase())) {
      return 'Invalid communication method. Must be one of: ${validCommunicationMethods.join(', ')}';
    }
    
    return null;
  }
  
  /// Validate notification frequency (in hours)
  static String? validateNotificationFrequency(int? frequency) {
    if (frequency == null) {
      return null; // Optional field
    }
    
    if (frequency < 1) {
      return 'Notification frequency must be at least 1 hour';
    }
    
    if (frequency > 168) { // 1 week
      return 'Notification frequency cannot exceed 1 week';
    }
    
    // Should be reasonable intervals
    final validFrequencies = [1, 2, 4, 6, 12, 24, 48, 72, 168];
    if (!validFrequencies.contains(frequency)) {
      return 'Invalid frequency. Choose from: ${validFrequencies.join(', ')} hours';
    }
    
    return null;
  }
  
  /// Validate all user preferences at once
  static Map<String, String?> validatePreferences(UserPreferences prefs) {
    final errors = <String, String?>{};
    
    errors['radius'] = validateRadius(prefs.preferredRadiusKm);
    errors['gameDuration'] = validateGameDuration(prefs.preferredGameDuration);
    errors['teamSize'] = validateTeamSize(
      prefs.preferredTeamSizeMin,
      prefs.preferredTeamSizeMax,
    );
    errors['ageRange'] = validateAgeRange(
      prefs.preferredAgeRangeMin,
      prefs.preferredAgeRangeMax,
    );
    errors['travelTime'] = validateTravelTime(prefs.maxTravelTime);
    errors['skillLevel'] = validateSkillLevel(prefs.preferredSkillLevel);
    errors['preferredDays'] = validatePreferredDays(prefs.preferredDays);
    errors['preferredTimes'] = validatePreferredTimes(prefs.preferredTimes);
    errors['preferredSports'] = validatePreferredSports(prefs.preferredSports);
    errors['communication'] = validateCommunicationMethod(prefs.preferredCommunication);
    
    // Remove null entries (no errors)
    errors.removeWhere((key, value) => value == null);
    
    return errors;
  }
  
  /// Cross-field validation for complex business rules
  static List<String> validatePreferenceLogic(UserPreferences prefs) {
    final warnings = <String>[];
    
    // Check if radius and travel time are consistent
    if (prefs.preferredRadiusKm != null && prefs.maxTravelTime != null) {
      // Rough estimation: 1km = ~3 minutes travel time
      final estimatedTravelTime = prefs.preferredRadiusKm! * 3;
      if (prefs.maxTravelTime! < estimatedTravelTime * 0.5) {
        warnings.add('Travel time might be too short for selected search radius');
      }
    }
    
    // Check if team size preferences make sense for selected sports
    if (prefs.preferredSports.isNotEmpty && 
        prefs.preferredTeamSizeMin != null && 
        prefs.preferredTeamSizeMax != null) {
      
      // Sports that typically need larger teams
      final teamSports = ['football', 'basketball', 'volleyball', 'rugby'];
      final hasTeamSports = prefs.preferredSports.any(
        (sport) => teamSports.any((team) => sport.toLowerCase().contains(team))
      );
      
      if (hasTeamSports && prefs.preferredTeamSizeMax! < 6) {
        warnings.add('Team sports typically require larger groups');
      }
      
      // Individual sports
      final individualSports = ['tennis', 'badminton', 'ping pong', 'squash'];
      final hasIndividualSports = prefs.preferredSports.any(
        (sport) => individualSports.any((individual) => sport.toLowerCase().contains(individual))
      );
      
      if (hasIndividualSports && prefs.preferredTeamSizeMin! > 4) {
        warnings.add('Individual sports typically need smaller groups');
      }
    }
    
    // Check age range vs skill level consistency
    if (prefs.preferredAgeRangeMin != null && 
        prefs.preferredAgeRangeMax != null &&
        prefs.preferredSkillLevel != null) {
      
      if (prefs.preferredSkillLevel == 'expert' && prefs.preferredAgeRangeMax! < 25) {
        warnings.add('Expert level players are typically older and more experienced');
      }
      
      if (prefs.preferredSkillLevel == 'beginner' && prefs.preferredAgeRangeMin! > 40) {
        warnings.add('Consider allowing different skill levels for broader matching');
      }
    }
    
    // Check time consistency
    if (prefs.preferredTimes.isNotEmpty && prefs.preferredDays.isNotEmpty) {
      final hasWeekendDays = prefs.preferredDays.any(
        (day) => ['saturday', 'sunday'].contains(day.toLowerCase())
      );
      final hasWeekdayTimes = prefs.preferredTimes.any(
        (time) => ['morning', 'afternoon'].contains(time.toLowerCase())
      );
      
      if (!hasWeekendDays && hasWeekdayTimes) {
        warnings.add('Morning/afternoon times on weekdays might limit availability');
      }
    }
    
    return warnings;
  }
  
  /// Get recommended settings based on user profile
  static Map<String, dynamic> getRecommendedSettings({
    int? userAge,
    String? userSkillLevel,
    List<String>? userSports,
    String? userLocation,
  }) {
    final recommendations = <String, dynamic>{};
    
    // Age-based recommendations
    if (userAge != null) {
      if (userAge < 25) {
        recommendations['preferredAgeRange'] = {'min': userAge - 5, 'max': userAge + 10};
        recommendations['preferredRadius'] = 15; // Younger users might travel further
      } else if (userAge < 40) {
        recommendations['preferredAgeRange'] = {'min': userAge - 8, 'max': userAge + 8};
        recommendations['preferredRadius'] = 10;
      } else {
        recommendations['preferredAgeRange'] = {'min': userAge - 10, 'max': userAge + 5};
        recommendations['preferredRadius'] = 8; // Older users prefer closer venues
      }
    }
    
    // Skill-based recommendations
    if (userSkillLevel != null) {
      switch (userSkillLevel.toLowerCase()) {
        case 'beginner':
          recommendations['allowDifferentSkillLevels'] = true;
          recommendations['preferredGameDuration'] = 60; // Shorter games
          break;
        case 'intermediate':
          recommendations['preferredGameDuration'] = 90;
          break;
        case 'advanced':
        case 'expert':
          recommendations['allowDifferentSkillLevels'] = false;
          recommendations['preferredGameDuration'] = 120; // Longer games
          break;
      }
    }
    
    // Sport-specific recommendations
    if (userSports != null && userSports.isNotEmpty) {
      final teamSports = ['football', 'basketball', 'volleyball'];
      final hasTeamSports = userSports.any(
        (sport) => teamSports.any((team) => sport.toLowerCase().contains(team))
      );
      
      if (hasTeamSports) {
        recommendations['preferredTeamSize'] = {'min': 8, 'max': 22};
        recommendations['preferredGameDuration'] = 90;
      } else {
        recommendations['preferredTeamSize'] = {'min': 2, 'max': 8};
        recommendations['preferredGameDuration'] = 60;
      }
    }
    
    // Default recommendations
    recommendations.putIfAbsent('preferredRadius', () => 10);
    recommendations.putIfAbsent('maxTravelTime', () => 30);
    recommendations.putIfAbsent('allowMixedGender', () => true);
    recommendations.putIfAbsent('preferredCommunication', () => 'in_app');
    
    return recommendations;
  }
  
  /// Validate settings for specific use cases
  static Map<String, String?> validateForUseCase(
    UserPreferences prefs,
    String useCase,
  ) {
    final errors = <String, String?>{};
    
    switch (useCase.toLowerCase()) {
      case 'quick_match':
        if (prefs.preferredRadiusKm == null || prefs.preferredRadiusKm! > 20) {
          errors['radius'] = 'Quick matches require smaller search radius (≤20km)';
        }
        if (prefs.maxTravelTime == null || prefs.maxTravelTime! > 45) {
          errors['travelTime'] = 'Quick matches require shorter travel time (≤45min)';
        }
        break;
        
      case 'tournament':
        if (prefs.preferredGameDuration == null || prefs.preferredGameDuration! < 60) {
          errors['duration'] = 'Tournament games require longer duration (≥60min)';
        }
        if (!prefs.allowDifferentSkillLevels) {
          errors['skillLevel'] = 'Tournaments benefit from skill level flexibility';
        }
        break;
        
      case 'casual_play':
        if (prefs.allowMixedGender == false && prefs.allowDifferentSkillLevels == false) {
          errors['flexibility'] = 'Casual play works better with more flexibility';
        }
        break;
    }
    
    return errors;
  }
}
