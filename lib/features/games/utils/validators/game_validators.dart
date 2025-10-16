import '../game_helpers.dart';
import '../constants/sports_constants.dart';

/// Comprehensive validation for game creation and management
class GameValidators {
  // GAME CREATION VALIDATION

  /// Validate game title
  static ValidationResult validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return ValidationResult.error('Game title is required');
    }

    final trimmedTitle = title.trim();
    
    if (trimmedTitle.length < 3) {
      return ValidationResult.error('Title must be at least 3 characters');
    }
    
    if (trimmedTitle.length > 100) {
      return ValidationResult.error('Title must be less than 100 characters');
    }

    // Check for inappropriate content (basic filter)
    if (_containsInappropriateContent(trimmedTitle)) {
      return ValidationResult.error('Title contains inappropriate content');
    }

    return ValidationResult.success();
  }

  /// Validate sport selection
  static ValidationResult validateSport(String? sport) {
    if (sport == null || sport.trim().isEmpty) {
      return ValidationResult.error('Sport selection is required');
    }

    final sportType = SportType.fromString(sport);
    final config = SportsConstants.getConfiguration(sportType);
    
    if (config == null && sportType == SportType.other) {
      return ValidationResult.warning('Custom sport selected - ensure all details are accurate');
    }

    return ValidationResult.success();
  }

  /// Validate skill level
  static ValidationResult validateSkillLevel(String? skillLevel, String? sport) {
    if (skillLevel == null || skillLevel.trim().isEmpty) {
      return ValidationResult.error('Skill level is required');
    }

    if (sport != null) {
      final sportType = SportType.fromString(sport);
      if (!SportsConstants.isValidSkillLevel(sportType, skillLevel)) {
        return ValidationResult.error('Invalid skill level for $sport');
      }
    }

    return ValidationResult.success();
  }

  /// Validate game date and time
  static ValidationResult validateDateTime(DateTime? dateTime, String? sport) {
    if (dateTime == null) {
      return ValidationResult.error('Game date and time is required');
    }

    // Must be in the future
    if (!GameHelpers.isValidFutureDate(dateTime)) {
      return ValidationResult.error('Game must be scheduled in the future');
    }

    // Must be within booking window
    if (!GameHelpers.isWithinBookingWindow(dateTime)) {
      return ValidationResult.error('Game must be scheduled within 90 days');
    }

    // Check minimum advance booking
    if (sport != null) {
      final minAdvance = GameHelpers.getMinimumAdvanceBooking(sport);
      final timeUntilGame = GameHelpers.getTimeUntilGame(dateTime);
      
      if (timeUntilGame < minAdvance) {
        final hours = minAdvance.inHours;
        return ValidationResult.error(
          'Game must be scheduled at least $hours hours in advance'
        );
      }
    }

    // Check for reasonable time (not too late/early)
    final hour = dateTime.hour;
    if (hour < 6 || hour > 23) {
      return ValidationResult.warning(
        'Game scheduled outside normal hours (6 AM - 11 PM)'
      );
    }

    return ValidationResult.success();
  }

  /// Validate game duration
  static ValidationResult validateDuration(Duration? duration, String? sport) {
    if (duration == null) {
      return ValidationResult.error('Game duration is required');
    }

    // Minimum duration
    if (duration.inMinutes < 15) {
      return ValidationResult.error('Game duration must be at least 15 minutes');
    }

    // Maximum duration
    if (duration.inHours > 8) {
      return ValidationResult.error('Game duration cannot exceed 8 hours');
    }

    // Sport-specific validation
    if (sport != null) {
      final sportType = SportType.fromString(sport);
      final config = SportsConstants.getConfiguration(sportType);
      
      if (config != null) {
        final suggested = config.suggestedDuration;
        final minReasonable = Duration(minutes: (suggested.inMinutes * 0.5).round());
        final maxReasonable = Duration(minutes: (suggested.inMinutes * 2).round());
        
        if (duration < minReasonable || duration > maxReasonable) {
          return ValidationResult.warning(
            'Unusual duration for $sport (suggested: ${GameHelpers.formatGameDuration(suggested)})'
          );
        }
      }
    }

    return ValidationResult.success();
  }

  /// Validate player count settings
  static ValidationResult validatePlayerCount({
    int? minPlayers,
    int? maxPlayers,
    String? sport,
  }) {
    if (minPlayers == null || maxPlayers == null) {
      return ValidationResult.error('Player count is required');
    }

    if (minPlayers < 1) {
      return ValidationResult.error('Minimum players must be at least 1');
    }

    if (maxPlayers < minPlayers) {
      return ValidationResult.error('Maximum players must be greater than or equal to minimum');
    }

    if (maxPlayers > 100) {
      return ValidationResult.error('Maximum players cannot exceed 100');
    }

    // Sport-specific validation
    if (sport != null) {
      final sportType = SportType.fromString(sport);
      final config = SportsConstants.getConfiguration(sportType);
      
      if (config != null) {
        if (minPlayers < config.minPlayers) {
          return ValidationResult.error(
            'Minimum players for $sport should be at least ${config.minPlayers}'
          );
        }
        
        if (maxPlayers > config.maxPlayers) {
          return ValidationResult.warning(
            'Maximum players for $sport is typically ${config.maxPlayers}'
          );
        }

        if (maxPlayers < config.idealPlayers) {
          return ValidationResult.warning(
            'Ideal player count for $sport is ${config.idealPlayers}'
          );
        }
      }
    }

    return ValidationResult.success();
  }

  /// Validate game price
  static ValidationResult validatePrice(double? price) {
    if (price == null) {
      return ValidationResult.error('Price is required (enter 0 for free games)');
    }

    if (price < 0) {
      return ValidationResult.error('Price cannot be negative');
    }

    if (price > 1000) {
      return ValidationResult.warning('High price - please confirm this is correct');
    }

    return ValidationResult.success();
  }

  /// Validate price per person
  static ValidationResult validatePricePerPerson(double? totalPrice, int? maxPlayers) {
    if (totalPrice == null || maxPlayers == null) {
      return ValidationResult.success(); // Other validations will catch these
    }

    if (totalPrice > 0 && maxPlayers > 0) {
      final pricePerPerson = totalPrice / maxPlayers;
      
      if (pricePerPerson > 200) {
        return ValidationResult.warning(
          'High per-person cost (${GameHelpers.formatPrice(pricePerPerson)} per person)'
        );
      }
    }

    return ValidationResult.success();
  }

  /// Validate venue selection
  static ValidationResult validateVenue(String? venueId) {
    if (venueId == null || venueId.trim().isEmpty) {
      return ValidationResult.error('Venue selection is required');
    }

    // Additional venue-specific validation would go here
    // (e.g., check if venue exists, is available, supports the sport)
    
    return ValidationResult.success();
  }

  /// Validate game description
  static ValidationResult validateDescription(String? description) {
    if (description == null) {
      return ValidationResult.success(); // Description is optional
    }

    final trimmedDescription = description.trim();
    
    if (trimmedDescription.length > 500) {
      return ValidationResult.error('Description must be less than 500 characters');
    }

    if (_containsInappropriateContent(trimmedDescription)) {
      return ValidationResult.error('Description contains inappropriate content');
    }

    return ValidationResult.success();
  }

  // BOOKING CONFLICT VALIDATION

  /// Validate for booking conflicts
  static ValidationResult validateBookingConflict({
    required DateTime dateTime,
    required Duration duration,
    required String venueId,
    List<BookingConflict>? existingConflicts,
  }) {
    if (existingConflicts == null || existingConflicts.isEmpty) {
      return ValidationResult.success();
    }

    final conflicts = existingConflicts;
    if (conflicts.length == 1) {
      return ValidationResult.error(
        'Time slot conflicts with an existing booking at this venue'
      );
    } else {
      return ValidationResult.error(
        'Time slot conflicts with ${conflicts.length} existing bookings at this venue'
      );
    }
  }

  /// Validate suggested alternative time
  static ValidationResult validateAlternativeTime(
    DateTime originalTime,
    DateTime alternativeTime,
    Duration duration,
  ) {
    // Alternative should be within reasonable range
    final timeDifference = alternativeTime.difference(originalTime).abs();
    
    if (timeDifference.inHours > 6) {
      return ValidationResult.warning('Alternative time is significantly different from requested time');
    }

    // Alternative should still be valid
    return validateDateTime(alternativeTime, null);
  }

  // CHECK-IN VALIDATION

  /// Validate check-in window
  static ValidationResult validateCheckinWindow({
    required DateTime gameTime,
    required DateTime checkinTime,
  }) {
    final timeUntilGame = gameTime.difference(checkinTime);
    
    // Check-in should be within 2 hours of game
    if (timeUntilGame.inHours > 2) {
      return ValidationResult.error('Check-in opens 2 hours before the game');
    }

    // Check-in should not be after game has ended (assuming 2 hour max game)
    if (timeUntilGame.inHours < -2) {
      return ValidationResult.error('Check-in window has closed');
    }

    return ValidationResult.success();
  }

  /// Validate QR code token
  static ValidationResult validateQRToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      return ValidationResult.error('Invalid QR code');
    }

    // Basic token format validation
    final parts = token.split('_');
    if (parts.length < 3) {
      return ValidationResult.error('Invalid QR code format');
    }

    // Check if token is expired (basic timestamp check)
    try {
      final timestamp = int.parse(parts[1]);
      final tokenTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      if (now.difference(tokenTime).inMinutes > 30) {
        return ValidationResult.error('QR code has expired');
      }
    } catch (e) {
      return ValidationResult.error('Invalid QR code timestamp');
    }

    return ValidationResult.success();
  }

  // COMPOSITE VALIDATIONS

  /// Validate complete game creation data
  static GameCreationValidationResult validateGameCreation({
    required String? title,
    required String? sport,
    required String? skillLevel,
    required DateTime? dateTime,
    required Duration? duration,
    required int? minPlayers,
    required int? maxPlayers,
    required double? price,
    required String? venueId,
    String? description,
  }) {
    final results = <ValidationResult>[];
    final warnings = <String>[];
    final errors = <String>[];

    // Validate each field
    results.add(validateTitle(title));
    results.add(validateSport(sport));
    results.add(validateSkillLevel(skillLevel, sport));
    results.add(validateDateTime(dateTime, sport));
    results.add(validateDuration(duration, sport));
    results.add(validatePlayerCount(minPlayers: minPlayers, maxPlayers: maxPlayers, sport: sport));
    results.add(validatePrice(price));
    results.add(validatePricePerPerson(price, maxPlayers));
    results.add(validateVenue(venueId));
    results.add(validateDescription(description));

    // Collect warnings and errors
    for (final result in results) {
      if (result.isError) {
        errors.add(result.message!);
      } else if (result.isWarning) {
        warnings.add(result.message!);
      }
    }

    return GameCreationValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate game join eligibility
  static ValidationResult validateGameJoinEligibility({
    required bool isGameFull,
    required bool isUserAlreadyJoined,
    required DateTime gameTime,
    required String gameStatus,
  }) {
    if (isUserAlreadyJoined) {
      return ValidationResult.error('You are already registered for this game');
    }

    if (gameStatus.toLowerCase() == 'cancelled') {
      return ValidationResult.error('This game has been cancelled');
    }

    if (gameStatus.toLowerCase() == 'completed') {
      return ValidationResult.error('This game has already ended');
    }

    if (GameHelpers.hasGameEnded(startTime: gameTime, duration: const Duration(hours: 2))) {
      return ValidationResult.error('This game has already ended');
    }

    if (isGameFull) {
      return ValidationResult.warning('Game is full - you will be added to the waitlist');
    }

    // Check if too close to game time
    final timeUntilGame = GameHelpers.getTimeUntilGame(gameTime);
    if (timeUntilGame.inHours < 1) {
      return ValidationResult.warning('Game starts soon - organizer approval may be needed');
    }

    return ValidationResult.success();
  }

  // HELPER METHODS

  /// Basic inappropriate content filter
  static bool _containsInappropriateContent(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Basic word filter - in a real app, this would be more comprehensive
    const inappropriateWords = [
      'spam',
      'scam',
      'fake',
      // Add more words as needed
    ];

    return inappropriateWords.any((word) => lowercaseText.contains(word));
  }

  /// Validate time slot availability
  static ValidationResult validateTimeSlotAvailability({
    required DateTime startTime,
    required Duration duration,
    required List<TimeSlot> occupiedSlots,
  }) {
    final endTime = startTime.add(duration);
    
    for (final slot in occupiedSlots) {
      final slotEnd = slot.startTime.add(slot.duration);
      
      // Check for overlap
      if (startTime.isBefore(slotEnd) && endTime.isAfter(slot.startTime)) {
        return ValidationResult.error(
          'Time slot overlaps with existing booking from ${_formatTime(slot.startTime)} to ${_formatTime(slotEnd)}'
        );
      }
    }
    
    return ValidationResult.success();
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }
}

/// Validation result with success/warning/error states
class ValidationResult {
  final bool isSuccess;
  final bool isWarning;
  final bool isError;
  final String? message;

  const ValidationResult._({
    required this.isSuccess,
    required this.isWarning,
    required this.isError,
    this.message,
  });

  factory ValidationResult.success({String? message}) {
    return ValidationResult._(
      isSuccess: true,
      isWarning: false,
      isError: false,
      message: message,
    );
  }

  factory ValidationResult.warning(String message) {
    return ValidationResult._(
      isSuccess: true,
      isWarning: true,
      isError: false,
      message: message,
    );
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(
      isSuccess: false,
      isWarning: false,
      isError: true,
      message: message,
    );
  }
}

/// Comprehensive validation result for game creation
class GameCreationValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const GameCreationValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  
  String get firstError => errors.isNotEmpty ? errors.first : '';
  String get firstWarning => warnings.isNotEmpty ? warnings.first : '';
}

/// Booking conflict data class
class BookingConflict {
  final String bookingId;
  final DateTime startTime;
  final Duration duration;
  final String details;

  const BookingConflict({
    required this.bookingId,
    required this.startTime,
    required this.duration,
    required this.details,
  });
}

/// Time slot data class
class TimeSlot {
  final DateTime startTime;
  final Duration duration;
  final String? bookingId;

  const TimeSlot({
    required this.startTime,
    required this.duration,
    this.bookingId,
  });
}
