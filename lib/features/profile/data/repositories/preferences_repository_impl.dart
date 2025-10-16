import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../models/models.dart';

/// Data source for preferences remote operations
abstract class PreferencesRemoteDataSource {
  Future<UserPreferencesModel> getPreferences(String userId);
  Future<UserPreferencesModel> updatePreferences(String userId, UserPreferencesModel preferences);
  Future<UserPreferencesModel> updatePreferenceCategory(String userId, String category, dynamic data);
  Future<Map<String, List<TimeSlot>>> getAvailabilitySchedule(String userId);
  Future<Map<String, List<TimeSlot>>> updateAvailabilitySchedule(String userId, Map<String, List<TimeSlot>> schedule);
  Future<bool> isAvailableAt(String userId, DateTime dateTime);
  Future<Map<String, dynamic>> getCompatibilityWith(String userId, String otherUserId);
  Future<double> calculateCompatibilityScore(String userId, String otherUserId);
  Future<UserPreferencesModel> getDefaultPreferencesTemplate({
    List<String>? sportTypes,
    String? location,
    String? experience,
  });
}

/// Data source for preferences local storage operations
abstract class PreferencesLocalDataSource {
  Future<UserPreferencesModel?> getLocalPreferences(String userId);
  Future<void> saveLocalPreferences(String userId, UserPreferencesModel preferences);
  Future<Map<String, List<TimeSlot>>?> getLocalAvailability(String userId);
  Future<void> saveLocalAvailability(String userId, Map<String, List<TimeSlot>> schedule);
  Future<bool> hasUnsyncedChanges(String userId);
  Future<void> markAsSynced(String userId);
  Future<void> clearLocalPreferences(String userId);
  Future<Map<String, dynamic>> exportLocalPreferences(String userId);
  Future<void> importLocalPreferences(String userId, Map<String, dynamic> preferences);
  Future<List<String>> validatePreferences(UserPreferencesModel preferences);
}

/// Implementation of PreferencesRepository with local caching and validation
class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesRemoteDataSource remoteDataSource;
  final PreferencesLocalDataSource localDataSource;

  PreferencesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserPreferences>> getPreferences(String userId) async {
    try {
      // Try local first for quick access
      final localPreferences = await localDataSource.getLocalPreferences(userId);
      
      if (localPreferences != null) {
        // Start background sync
        _syncPreferencesInBackground(userId);
        return Right(localPreferences.toEntity());
      }

      // Fetch from remote
      final remotePreferences = await remoteDataSource.getPreferences(userId);
      
      // Cache locally
      await localDataSource.saveLocalPreferences(userId, remotePreferences);
      await localDataSource.markAsSynced(userId);
      
      return Right(remotePreferences.toEntity());
    } on NetworkFailure catch (e) {
      final localPreferences = await localDataSource.getLocalPreferences(userId);
      if (localPreferences != null) {
        return Right(localPreferences.toEntity());
      }
      return Left(NetworkFailure(message: 'No network and no local preferences: ${e.message}'));
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> updatePreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    try {
      // Validate preferences first
      final preferencesModel = UserPreferencesModel.fromEntity(preferences);
      final validationErrors = await localDataSource.validatePreferences(preferencesModel);
      
      if (validationErrors.isNotEmpty) {
        return Left(ValidationFailure(
          message: 'Invalid preferences: ${validationErrors.join(', ')}'
        ));
      }

      // Save locally first for immediate response
      await localDataSource.saveLocalPreferences(userId, preferencesModel);
      
      try {
        // Sync with remote
        final updatedPreferences = await remoteDataSource.updatePreferences(userId, preferencesModel);
        
        // Update local with server response
        await localDataSource.saveLocalPreferences(userId, updatedPreferences);
        await localDataSource.markAsSynced(userId);
        
        return Right(updatedPreferences.toEntity());
      } catch (e) {
        // Return local version if remote sync fails
        print('Failed to sync preferences: $e');
        return Right(preferencesModel.toEntity());
      }
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> updatePreferenceCategory(
    String userId,
    String category,
    dynamic data,
  ) async {
    try {
      final updatedPreferences = await remoteDataSource.updatePreferenceCategory(userId, category, data);
      await localDataSource.saveLocalPreferences(userId, updatedPreferences);
      return Right(updatedPreferences.toEntity());
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update preference category: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getGamePreferences(String userId) async {
    try {
      final preferencesResult = await getPreferences(userId);
      return preferencesResult.fold(
        (failure) => Left(failure),
        (preferences) {
          final gamePrefs = {
            'preferred_game_types': preferences.preferredGameTypes,
            'skill_level_preferences': preferences.skillLevelPreferences,
            'preferred_team_size': preferences.preferredTeamSize.toString().split('.').last,
            'preferred_duration': preferences.preferredDuration.toString().split('.').last,
            'prefer_competitive': preferences.preferCompetitive,
            'prefer_casual': preferences.preferCasual,
            'auto_accept_invites': preferences.autoAcceptInvites,
            'minimum_notice_hours': preferences.minimumNoticeHours,
          };
          return Right(gamePrefs);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get game preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateGamePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          // Apply game preference updates
          final updated = _applyGamePreferenceUpdates(current, preferences);
          final updateResult = await updatePreferences(userId, updated);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => getGamePreferences(userId),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update game preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> addPreferredGameType(
    String userId,
    String gameType,
  ) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = List<String>.from(current.preferredGameTypes);
          if (!updated.contains(gameType)) {
            updated.add(gameType);
          }
          
          final newPrefs = current.copyWith(preferredGameTypes: updated);
          final updateResult = await updatePreferences(userId, newPrefs);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => Right(updatedPrefs.preferredGameTypes),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to add preferred game type: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> removePreferredGameType(
    String userId,
    String gameType,
  ) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = List<String>.from(current.preferredGameTypes);
          updated.remove(gameType);
          
          final newPrefs = current.copyWith(preferredGameTypes: updated);
          final updateResult = await updatePreferences(userId, newPrefs);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => Right(updatedPrefs.preferredGameTypes),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to remove preferred game type: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLocationPreferences(String userId) async {
    try {
      final preferencesResult = await getPreferences(userId);
      return preferencesResult.fold(
        (failure) => Left(failure),
        (preferences) {
          final locationPrefs = {
            'preferred_venues': preferences.preferredVenues,
            'max_travel_radius': preferences.maxTravelRadius,
          };
          return Right(locationPrefs);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get location preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateLocationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = _applyLocationPreferenceUpdates(current, preferences);
          final updateResult = await updatePreferences(userId, updated);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => getLocationPreferences(userId),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update location preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> addPreferredLocation(
    String userId,
    String location, {
    Map<String, double>? coordinates,
  }) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = List<String>.from(current.preferredVenues);
          if (!updated.contains(location)) {
            updated.add(location);
          }
          
          final newPrefs = current.copyWith(preferredVenues: updated);
          final updateResult = await updatePreferences(userId, newPrefs);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => Right(updatedPrefs.preferredVenues),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to add preferred location: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> removePreferredLocation(
    String userId,
    String location,
  ) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = List<String>.from(current.preferredVenues);
          updated.remove(location);
          
          final newPrefs = current.copyWith(preferredVenues: updated);
          final updateResult = await updatePreferences(userId, newPrefs);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => Right(updatedPrefs.preferredVenues),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to remove preferred location: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMaxTravelDistance(
    String userId,
    double distance,
  ) async {
    try {
      if (distance < 0 || distance > 1000) {
        return const Left(ValidationFailure(message: 'Travel distance must be between 0 and 1000 km'));
      }

      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = current.copyWith(maxTravelRadius: distance);
          final updateResult = await updatePreferences(userId, updated);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => const Right(null),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update max travel distance: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<TimeSlot>>>> getAvailabilitySchedule(
    String userId,
  ) async {
    try {
      // Try local first for availability data
      final localSchedule = await localDataSource.getLocalAvailability(userId);
      
      if (localSchedule != null) {
        return Right(localSchedule);
      }

      // Fetch from remote
      final remoteSchedule = await remoteDataSource.getAvailabilitySchedule(userId);
      
      // Cache locally
      await localDataSource.saveLocalAvailability(userId, remoteSchedule);
      
      return Right(remoteSchedule);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get availability schedule: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<TimeSlot>>>> updateAvailabilitySchedule(
    String userId,
    Map<String, List<TimeSlot>> schedule,
  ) async {
    try {
      // Validate schedule first
      final validationResult = await validateAvailabilitySchedule(schedule);
      final validationErrors = validationResult.getOrElse(() => []);
      
      if (validationErrors.isNotEmpty) {
        return Left(ValidationFailure(
          message: 'Invalid schedule: ${validationErrors.join(', ')}'
        ));
      }

      // Update local first
      await localDataSource.saveLocalAvailability(userId, schedule);
      
      try {
        // Update remote
        final updatedSchedule = await remoteDataSource.updateAvailabilitySchedule(userId, schedule);
        
        // Update local with server response
        await localDataSource.saveLocalAvailability(userId, updatedSchedule);
        
        return Right(updatedSchedule);
      } catch (e) {
        print('Failed to sync availability: $e');
        return Right(schedule);
      }
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update availability schedule: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<TimeSlot>>>> updateDayAvailability(
    String userId,
    String dayOfWeek,
    List<TimeSlot> timeSlots,
  ) async {
    try {
      final scheduleResult = await getAvailabilitySchedule(userId);
      return scheduleResult.fold(
        (failure) => Left(failure),
        (currentSchedule) async {
          final updatedSchedule = Map<String, List<TimeSlot>>.from(currentSchedule);
          updatedSchedule[dayOfWeek] = timeSlots;
          
          return updateAvailabilitySchedule(userId, updatedSchedule);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update day availability: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<TimeSlot>>>> addAvailabilitySlot(
    String userId,
    String dayOfWeek,
    TimeSlot timeSlot,
  ) async {
    try {
      final scheduleResult = await getAvailabilitySchedule(userId);
      return scheduleResult.fold(
        (failure) => Left(failure),
        (currentSchedule) async {
          final updatedSchedule = Map<String, List<TimeSlot>>.from(currentSchedule);
          final daySlots = List<TimeSlot>.from(updatedSchedule[dayOfWeek] ?? []);
          
          // Check for conflicts
          if (_hasTimeSlotConflict(daySlots, timeSlot)) {
            return const Left(ConflictFailure(message: 'Time slot conflicts with existing availability'));
          }
          
          daySlots.add(timeSlot);
          daySlots.sort((a, b) => a.startHour.compareTo(b.startHour));
          updatedSchedule[dayOfWeek] = daySlots;
          
          return updateAvailabilitySchedule(userId, updatedSchedule);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to add availability slot: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<TimeSlot>>>> removeAvailabilitySlot(
    String userId,
    String dayOfWeek,
    TimeSlot timeSlot,
  ) async {
    try {
      final scheduleResult = await getAvailabilitySchedule(userId);
      return scheduleResult.fold(
        (failure) => Left(failure),
        (currentSchedule) async {
          final updatedSchedule = Map<String, List<TimeSlot>>.from(currentSchedule);
          final daySlots = List<TimeSlot>.from(updatedSchedule[dayOfWeek] ?? []);
          
          daySlots.removeWhere((slot) => 
              slot.startHour == timeSlot.startHour &&
              slot.endHour == timeSlot.endHour);
          
          updatedSchedule[dayOfWeek] = daySlots;
          
          return updateAvailabilitySchedule(userId, updatedSchedule);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to remove availability slot: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAvailableAt(String userId, DateTime dateTime) async {
    try {
      final isAvailable = await remoteDataSource.isAvailableAt(userId, dateTime);
      return Right(isAvailable);
    } catch (e) {
      // Fallback to local calculation
      final scheduleResult = await getAvailabilitySchedule(userId);
      return scheduleResult.fold(
        (failure) => Left(failure),
        (schedule) {
          final dayName = _getDayName(dateTime.weekday);
          final daySlots = schedule[dayName] ?? [];
          
          final timeInMinutes = dateTime.hour * 60 + dateTime.minute;
          
          for (final slot in daySlots) {
            final startMinutes = slot.startHour * 60;
            final endMinutes = slot.endHour * 60;
            
            if (timeInMinutes >= startMinutes && timeInMinutes <= endMinutes) {
              return const Right(true);
            }
          }
          
          return const Right(false);
        },
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSocialPreferences(String userId) async {
    try {
      final preferencesResult = await getPreferences(userId);
      return preferencesResult.fold(
        (failure) => Left(failure),
        (preferences) {
          final socialPrefs = {
            'age_range_preference': preferences.ageRangePreference.toString().split('.').last,
            'gender_mix_preference': preferences.genderMixPreference.toString().split('.').last,
            'open_to_new_players': preferences.openToNewPlayers,
            'prefer_competitive': preferences.preferCompetitive,
          };
          return Right(socialPrefs);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get social preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateSocialPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = _applySocialPreferenceUpdates(current, preferences);
          final updateResult = await updatePreferences(userId, updated);
          
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => getSocialPreferences(userId),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update social preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePreferredAgeRanges(
    String userId,
    List<int> ageRanges,
  ) async {
    try {
      if (ageRanges.any((age) => age < 13 || age > 100)) {
        return const Left(ValidationFailure(message: 'Age ranges must be between 13 and 100'));
      }

      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          // Note: UserPreferences doesn't have preferredAgeRanges, using ageRangePreference instead
          // This method might need to be updated based on actual requirements
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update preferred age ranges: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateGenderPreference(
    String userId,
    String? preference,
  ) async {
    try {
      if (preference != null && !['any', 'male', 'female', 'non-binary'].contains(preference)) {
        return const Left(ValidationFailure(message: 'Invalid gender preference'));
      }

      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          // Note: UserPreferences doesn't have genderPreference, using genderMixPreference instead
          // This method might need to be updated based on actual requirements
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update gender preference: $e'));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> getDefaultPreferencesTemplate({
    List<String>? sportTypes,
    String? location,
    String? experience,
  }) async {
    try {
      final template = await remoteDataSource.getDefaultPreferencesTemplate(
        sportTypes: sportTypes,
        location: location,
        experience: experience,
      );
      return Right(template.toEntity());
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get default preferences template: $e'));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> applyPreferencesTemplate(
    String userId,
    UserPreferences template, {
    bool overwriteExisting = false,
  }) async {
    try {
      if (!overwriteExisting) {
        final currentResult = await getPreferences(userId);
        if (currentResult.isRight) {
          final current = currentResult.rightOrNull()!;
          // Merge template with existing preferences
          final merged = _mergePreferences(current, template);
          return updatePreferences(userId, merged);
        }
      }
      
      return updatePreferences(userId, template);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to apply preferences template: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> validatePreferences(UserPreferences preferences) async {
    try {
      final preferencesModel = UserPreferencesModel.fromEntity(preferences);
      final errors = await localDataSource.validatePreferences(preferencesModel);
      return Right(errors);
    } catch (e) {
      return Left(ValidationFailure(message: 'Failed to validate preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> validateAvailabilitySchedule(
    Map<String, List<TimeSlot>> schedule,
  ) async {
    try {
      final errors = <String>[];
      
      for (final entry in schedule.entries) {
        final day = entry.key;
        final slots = entry.value;
        
        // Check for overlapping slots
        for (int i = 0; i < slots.length; i++) {
          for (int j = i + 1; j < slots.length; j++) {
            if (_doTimeSlotsOverlap(slots[i], slots[j])) {
              errors.add('Overlapping time slots found for $day');
              break;
            }
          }
        }
        
        // Check for valid time ranges
        for (final slot in slots) {
          if (slot.startHour < 0 || slot.startHour > 23 || 
              slot.endHour < 0 || slot.endHour > 23) {
            errors.add('Invalid time values for $day');
            break;
          }
          
          final startMinutes = slot.startHour * 60;
          final endMinutes = slot.endHour * 60;
          
          if (startMinutes >= endMinutes) {
            errors.add('Start time must be before end time for $day');
            break;
          }
        }
      }
      
      return Right(errors);
    } catch (e) {
      return Left(ValidationFailure(message: 'Failed to validate availability schedule: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCompatibilityWith(
    String userId,
    String otherUserId,
  ) async {
    try {
      final compatibility = await remoteDataSource.getCompatibilityWith(userId, otherUserId);
      return Right(compatibility);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get compatibility: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> calculateCompatibilityScore(
    String userId,
    String otherUserId,
  ) async {
    try {
      final score = await remoteDataSource.calculateCompatibilityScore(userId, otherUserId);
      return Right(score);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to calculate compatibility score: $e'));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> importPreferences(
    String userId,
    String source,
    Map<String, dynamic> data,
  ) async {
    try {
      // Validate imported data
      final validationResult = await _validateImportedData(data, source);
      if (validationResult.isLeft) {
        return Left(validationResult.leftOrNull()!);
      }

      // Convert imported data to preferences format
      final convertedPreferences = _convertImportedData(data, source);
      
      return updatePreferences(userId, convertedPreferences);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to import preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportPreferences(String userId) async {
    try {
      final exportData = await localDataSource.exportLocalPreferences(userId);
      return Right(exportData);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to export preferences: $e'));
    }
  }

  // Implementation of remaining interface methods with similar patterns...
  @override
  Future<Either<Failure, void>> updateCompetitiveLevel(String userId, int level) async {
    if (level < 1 || level > 10) {
      return const Left(ValidationFailure(message: 'Competitive level must be between 1 and 10'));
    }
    return _updateSinglePreference(userId, (prefs) => prefs.copyWith(preferCompetitive: level > 5));
  }

  @override
  Future<Either<Failure, void>> updateSocialPreference(String userId, int level) async {
    if (level < 1 || level > 10) {
      return const Left(ValidationFailure(message: 'Social preference must be between 1 and 10'));
    }
    return _updateSinglePreference(userId, (prefs) => prefs.copyWith(openToNewPlayers: level > 5));
  }

  @override
  Future<Either<Failure, void>> updateAdvanceNoticeHours(String userId, int hours) async {
    if (hours < 0 || hours > 168) { // Max 1 week
      return const Left(ValidationFailure(message: 'Advance notice must be between 0 and 168 hours'));
    }
    return _updateSinglePreference(userId, (prefs) => prefs.copyWith(minimumNoticeHours: hours));
  }

  @override
  Future<Either<Failure, void>> setAutoAcceptInvitations(String userId, bool enabled) async {
    return _updateSinglePreference(userId, (prefs) => prefs.copyWith(autoAcceptInvites: enabled));
  }

  @override
  Future<Either<Failure, void>> setAutoMatchmaking(String userId, bool enabled) async {
    // Note: UserPreferences doesn't have autoMatchmaking property
    // This method might need to be updated based on actual requirements
    return const Right(null);
  }

  // Helper methods
  Future<Either<Failure, void>> _updateSinglePreference(
    String userId,
    UserPreferences Function(UserPreferences) updater,
  ) async {
    try {
      final currentResult = await getPreferences(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (current) async {
          final updated = updater(current);
          final updateResult = await updatePreferences(userId, updated);
          return updateResult.fold(
            (failure) => Left(failure),
            (updatedPrefs) => const Right(null),
          );
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update preference: $e'));
    }
  }

  void _syncPreferencesInBackground(String userId) {
    Future.delayed(Duration.zero, () async {
      try {
        final hasChanges = await localDataSource.hasUnsyncedChanges(userId);
        if (hasChanges) {
          final localPrefs = await localDataSource.getLocalPreferences(userId);
          if (localPrefs != null) {
            await remoteDataSource.updatePreferences(userId, localPrefs);
            await localDataSource.markAsSynced(userId);
          }
        }
      } catch (e) {
        print('Background preferences sync failed: $e');
      }
    });
  }

  UserPreferences _applyGamePreferenceUpdates(UserPreferences current, Map<String, dynamic> updates) {
    var updated = current;
    
    if (updates.containsKey('preferred_game_types')) {
      updated = updated.copyWith(preferredGameTypes: List<String>.from(updates['preferred_game_types']));
    }
    if (updates.containsKey('prefer_competitive')) {
      updated = updated.copyWith(preferCompetitive: updates['prefer_competitive']);
    }
    // Add more update mappings as needed
    
    return updated;
  }

  UserPreferences _applyLocationPreferenceUpdates(UserPreferences current, Map<String, dynamic> updates) {
    var updated = current;
    
    if (updates.containsKey('preferred_venues')) {
      updated = updated.copyWith(preferredVenues: List<String>.from(updates['preferred_venues']));
    }
    if (updates.containsKey('max_travel_radius')) {
      updated = updated.copyWith(maxTravelRadius: updates['max_travel_radius']);
    }
    
    return updated;
  }

  UserPreferences _applySocialPreferenceUpdates(UserPreferences current, Map<String, dynamic> updates) {
    var updated = current;
    
    if (updates.containsKey('age_range_preference')) {
      // Note: This would need to be converted to AgeRangePreference enum
      // updated = updated.copyWith(ageRangePreference: updates['age_range_preference']);
    }
    if (updates.containsKey('gender_mix_preference')) {
      // Note: This would need to be converted to GenderMixPreference enum
      // updated = updated.copyWith(genderMixPreference: updates['gender_mix_preference']);
    }
    
    return updated;
  }

  bool _hasTimeSlotConflict(List<TimeSlot> existingSlots, TimeSlot newSlot) {
    for (final existing in existingSlots) {
      if (_doTimeSlotsOverlap(existing, newSlot)) {
        return true;
      }
    }
    return false;
  }

  bool _doTimeSlotsOverlap(TimeSlot slot1, TimeSlot slot2) {
    final start1 = slot1.startHour * 60;
    final end1 = slot1.endHour * 60;
    final start2 = slot2.startHour * 60;
    final end2 = slot2.endHour * 60;
    
    return start1 < end2 && start2 < end1;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  UserPreferences _mergePreferences(UserPreferences current, UserPreferences template) {
    // Merge logic - keep existing values where they exist, use template for new values
    return current.copyWith(
      preferredGameTypes: current.preferredGameTypes.isNotEmpty 
          ? current.preferredGameTypes 
          : template.preferredGameTypes,
      maxTravelRadius: current.maxTravelRadius != 15.0 
          ? current.maxTravelRadius 
          : template.maxTravelRadius,
      // Add more merge logic as needed
    );
  }

  Future<Either<Failure, void>> _validateImportedData(Map<String, dynamic> data, String source) async {
    // Implement validation logic based on source
    return const Right(null);
  }

  UserPreferences _convertImportedData(Map<String, dynamic> data, String source) {
    // Implement conversion logic based on source
    return const UserPreferences(userId: '');
  }
}
