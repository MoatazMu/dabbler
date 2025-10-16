import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_preferences.dart';
import '../models/models.dart';

/// Exception types for preferences data source operations
class PreferencesDataSourceException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  const PreferencesDataSourceException({
    required this.message,
    required this.code,
    this.details,
  });

  @override
  String toString() => 'PreferencesDataSourceException: $message (Code: $code)';
}

/// Abstract interface for preferences remote data operations
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
  Future<List<UserPreferencesModel>> findCompatibleUsers(String userId, {
    int limit = 20,
    double minCompatibilityScore = 0.5,
  });
  Future<Map<String, dynamic>> analyzePreferencePattern(String userId);
  Future<List<String>> getLocationSuggestions(String query, {int limit = 10});
  Future<Map<String, dynamic>> getPreferenceStatistics(String userId);
}

/// Abstract interface for preferences local data operations  
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
  Future<List<String>> getCachedLocationSuggestions(String query);
  Future<void> cacheLocationSuggestions(String query, List<String> suggestions);
}

/// Supabase implementation of preferences remote data source
class SupabasePreferencesDataSource implements PreferencesRemoteDataSource {
  final SupabaseClient _client;
  final String _preferencesTable = 'user_preferences';
  final String _availabilityTable = 'user_availability';
  // final String _compatibilityTable = 'user_compatibility'; // reserved for future use
  final String _locationsTable = 'locations';
  final String _preferencesTemplatesTable = 'preference_templates';

  SupabasePreferencesDataSource(this._client);

  @override
  Future<UserPreferencesModel> getPreferences(String userId) async {
    try {
      final response = await _client
          .from(_preferencesTable)
          .select('*, user_availability(*)')
          .eq('user_id', userId)
          .single();

      return UserPreferencesModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return await _createDefaultPreferences(userId);
      }
      throw PreferencesDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to get preferences: $e',
        code: 'FETCH_ERROR',
      );
    }
  }

  @override
  Future<UserPreferencesModel> updatePreferences(String userId, UserPreferencesModel preferences) async {
    try {
      final preferencesData = preferences.toJson();
      preferencesData['updated_at'] = DateTime.now().toIso8601String();

      // Update main preferences
      final response = await _client
          .from(_preferencesTable)
          .upsert(preferencesData)
          .eq('user_id', userId)
          .select('*, user_availability(*)')
          .single();

      // Update availability if provided
      if (preferences.weeklyAvailability.isNotEmpty) {
        // Convert List<TimeSlot> to Map<String, List<TimeSlot>> grouped by day string
        final schedule = <String, List<TimeSlot>>{};
        for (final slot in preferences.weeklyAvailability) {
          final day = _getDayOfWeekString(slot.dayOfWeek);
          schedule.putIfAbsent(day, () => []).add(slot);
        }
        await updateAvailabilitySchedule(userId, schedule);
      }

      return UserPreferencesModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw PreferencesDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to update preferences: $e',
        code: 'UPDATE_ERROR',
      );
    }
  }

  @override
  Future<UserPreferencesModel> updatePreferenceCategory(String userId, String category, dynamic data) async {
    try {
  await getPreferences(userId); // ensure user exists; not used directly here
      final updateData = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      switch (category) {
        case 'game_types':
          updateData['preferred_game_types'] = data is List ? data : [data];
          break;
        case 'skill_levels':
          updateData['preferred_skill_levels'] = data is List ? data : [data];
          break;
        case 'group_sizes':
          updateData['preferred_group_sizes'] = data is List ? data : [data];
          break;
        case 'locations':
          updateData['preferred_locations'] = data is List ? data : [data];
          break;
        case 'age_ranges':
          updateData['preferred_age_ranges'] = data is List ? data : [data];
          break;
        case 'distance':
          updateData['max_travel_distance'] = data;
          break;
        case 'competitive_level':
          updateData['competitive_level'] = data;
          break;
        case 'social_preference':
          updateData['social_preference'] = data;
          break;
        case 'gender_preference':
          updateData['gender_preference'] = data;
          break;
        case 'auto_accept':
          updateData['auto_accept_invitations'] = data;
          break;
        case 'auto_matchmaking':
          updateData['auto_matchmaking'] = data;
          break;
        case 'advance_notice':
          updateData['advance_notice_hours'] = data;
          break;
        case 'game_durations':
          updateData['preferred_game_durations'] = data is List ? data : [data];
          break;
        default:
          throw PreferencesDataSourceException(
            message: 'Unknown preference category: $category',
            code: 'INVALID_CATEGORY',
          );
      }

      final response = await _client
          .from(_preferencesTable)
          .upsert(updateData)
          .eq('user_id', userId)
          .select('*, user_availability(*)')
          .single();

      return UserPreferencesModel.fromJson(response);
    } catch (e) {
      if (e is PreferencesDataSourceException) rethrow;
      throw PreferencesDataSourceException(
        message: 'Failed to update preference category: $e',
        code: 'CATEGORY_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<Map<String, List<TimeSlot>>> getAvailabilitySchedule(String userId) async {
    try {
      final response = await _client
          .from(_availabilityTable)
          .select()
          .eq('user_id', userId);

      final schedule = <String, List<TimeSlot>>{};
      
      for (final row in response) {
        final dayOfWeek = row['day_of_week'] as String;
        final timeSlot = TimeSlot(
          dayOfWeek: _dayStringToInt(dayOfWeek),
          startHour: row['start_hour'] as int,
          endHour: row['end_hour'] as int,
        );

        schedule[dayOfWeek] ??= [];
        schedule[dayOfWeek]!.add(timeSlot);
      }

      // Ensure all days are represented
      for (final day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']) {
        schedule[day] ??= [];
      }

      return schedule;
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to get availability schedule: $e',
        code: 'AVAILABILITY_FETCH_ERROR',
      );
    }
  }

  @override
  Future<Map<String, List<TimeSlot>>> updateAvailabilitySchedule(
    String userId, 
    Map<String, List<TimeSlot>> schedule,
  ) async {
    try {
      // Delete existing availability
      await _client
          .from(_availabilityTable)
          .delete()
          .eq('user_id', userId);

      // Insert new availability slots
      final insertData = <Map<String, dynamic>>[];
      
      for (final entry in schedule.entries) {
        final dayOfWeek = entry.key;
        final timeSlots = entry.value;
        
        for (final slot in timeSlots) {
          insertData.add({
            'user_id': userId,
            'day_of_week': dayOfWeek,
            'start_hour': slot.startHour,
            'end_hour': slot.endHour,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      if (insertData.isNotEmpty) {
        await _client.from(_availabilityTable).insert(insertData);
      }

      return schedule;
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to update availability schedule: $e',
        code: 'AVAILABILITY_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<bool> isAvailableAt(String userId, DateTime dateTime) async {
    try {
      final dayOfWeek = _getDayOfWeekString(dateTime.weekday);
      final timeInMinutes = dateTime.hour * 60 + dateTime.minute;

      final response = await _client
          .from(_availabilityTable)
          .select()
          .eq('user_id', userId)
          .eq('day_of_week', dayOfWeek);

      for (final slot in response) {
        final startMinutes = (slot['start_hour'] as int) * 60 + (slot['start_minute'] as int);
        final endMinutes = (slot['end_hour'] as int) * 60 + (slot['end_minute'] as int);
        
        if (timeInMinutes >= startMinutes && timeInMinutes <= endMinutes) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to check availability: $e',
        code: 'AVAILABILITY_CHECK_ERROR',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getCompatibilityWith(String userId, String otherUserId) async {
    try {
      final response = await _client.rpc('calculate_user_compatibility', params: {
        'user1_id': userId,
        'user2_id': otherUserId,
      });

      return {
        'compatibility_score': response['score'] ?? 0.0,
        'common_sports': response['common_sports'] ?? [],
        'common_locations': response['common_locations'] ?? [],
        'skill_level_compatibility': response['skill_compatibility'] ?? 0.0,
        'schedule_overlap': response['schedule_overlap'] ?? 0.0,
        'social_compatibility': response['social_compatibility'] ?? 0.0,
        'age_compatibility': response['age_compatibility'] ?? 0.0,
        'calculated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to calculate compatibility: $e',
        code: 'COMPATIBILITY_ERROR',
      );
    }
  }

  @override
  Future<double> calculateCompatibilityScore(String userId, String otherUserId) async {
    try {
      final compatibility = await getCompatibilityWith(userId, otherUserId);
      return compatibility['compatibility_score'] as double;
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to calculate compatibility score: $e',
        code: 'COMPATIBILITY_SCORE_ERROR',
      );
    }
  }

  @override
  Future<UserPreferencesModel> getDefaultPreferencesTemplate({
    List<String>? sportTypes,
    String? location,
    String? experience,
  }) async {
    try {
      // Try to fetch a matching template from the database
      var query = _client.from(_preferencesTemplatesTable).select();
      
      if (sportTypes != null && sportTypes.isNotEmpty) {
        query = query.contains('sport_types', sportTypes);
      }
      
      if (location != null) {
        query = query.eq('location_type', location);
      }
      
      if (experience != null) {
        query = query.eq('experience_level', experience);
      }

      final templates = await query.limit(1);
      
      if (templates.isNotEmpty) {
        final template = templates.first;
        return UserPreferencesModel.fromJson(template['preferences_data']);
      }

      // Return hardcoded default if no template found
      return _getHardcodedDefaultPreferences('', sportTypes, location, experience);
    } catch (e) {
      // Fallback to hardcoded defaults
      return _getHardcodedDefaultPreferences('', sportTypes, location, experience);
    }
  }

  @override
  Future<List<UserPreferencesModel>> findCompatibleUsers(String userId, {
    int limit = 20,
    double minCompatibilityScore = 0.5,
  }) async {
    try {
      final response = await _client.rpc('find_compatible_users', params: {
        'target_user_id': userId,
        'min_score': minCompatibilityScore,
        'max_results': limit,
      });

      return (response as List)
          .map<UserPreferencesModel>((json) => UserPreferencesModel.fromJson(json))
          .toList();
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to find compatible users: $e',
        code: 'COMPATIBLE_USERS_ERROR',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> analyzePreferencePattern(String userId) async {
    try {
      final response = await _client.rpc('analyze_preference_pattern', params: {
        'target_user_id': userId,
      });

      return {
        'most_preferred_sports': response['top_sports'] ?? [],
        'preferred_time_slots': response['peak_times'] ?? [],
        'location_patterns': response['location_patterns'] ?? {},
        'social_patterns': response['social_patterns'] ?? {},
        'seasonal_preferences': response['seasonal_preferences'] ?? {},
        'recommendation_tags': response['recommendation_tags'] ?? [],
        'analyzed_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to analyze preference pattern: $e',
        code: 'PATTERN_ANALYSIS_ERROR',
      );
    }
  }

  @override
  Future<List<String>> getLocationSuggestions(String query, {int limit = 10}) async {
    try {
      if (query.length < 2) {
        return [];
      }

      final response = await _client
          .from(_locationsTable)
          .select('name')
          .textSearch('name', query)
          .limit(limit);

      return response.map<String>((row) => row['name'] as String).toList();
    } catch (e) {
      // Return empty list on error rather than throwing
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getPreferenceStatistics(String userId) async {
    try {
      final response = await _client.rpc('get_preference_statistics', params: {
        'target_user_id': userId,
      });

      return {
        'total_preferences_set': response['total_preferences'] ?? 0,
        'completion_percentage': response['completion_percentage'] ?? 0.0,
        'most_active_sports': response['active_sports'] ?? [],
        'availability_hours_per_week': response['weekly_availability'] ?? 0,
        'preference_diversity_score': response['diversity_score'] ?? 0.0,
        'last_updated': response['last_updated'],
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw PreferencesDataSourceException(
        message: 'Failed to get preference statistics: $e',
        code: 'STATISTICS_ERROR',
      );
    }
  }

  // Helper methods
  Future<UserPreferencesModel> _createDefaultPreferences(String userId) async {
    final defaultPrefs = _getHardcodedDefaultPreferences(userId, null, null, null);
    final preferencesData = defaultPrefs.toJson();
    preferencesData['user_id'] = userId;
    preferencesData['created_at'] = DateTime.now().toIso8601String();
    preferencesData['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from(_preferencesTable)
        .insert(preferencesData)
        .select()
        .single();

    return UserPreferencesModel.fromJson(response);
  }

  UserPreferencesModel _getHardcodedDefaultPreferences(
    String userId,
    List<String>? sportTypes,
    String? location,
    String? experience,
  ) {
    return UserPreferencesModel(
      userId: userId,
      preferredGameTypes: sportTypes ?? ['tennis', 'badminton'],
      skillLevelPreferences: ['beginner', 'intermediate'],
      preferredTeamSize: TeamSize.small,
      preferredVenues: location != null ? [location] : [],
      maxTravelRadius: 10.0,
      preferredDuration: GameDuration.medium,
      weeklyAvailability: const [],
      preferOutdoor: true,
      preferIndoor: true,
      minimumNoticeHours: 24,
      autoAcceptInvites: false,
      preferCompetitive: false,
      preferCasual: true,
      ageRangePreference: AgeRangePreference.any,
      genderMixPreference: GenderMixPreference.any,
      openToNewPlayers: true,
      acceptWaitlist: true,
      maxGroupSize: 4,
      minGroupSize: 2,
      travelWillingness: TravelWillingness.moderate,
      advanceBookingDays: 7,
      unavailableDates: const [],
      preferFriendsOfFriends: false,
    );
  }

  String _getDayOfWeekString(int weekday) {
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

  int _dayStringToInt(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 1;
    }
  }
}

/// Local storage implementation for preferences
class LocalPreferencesDataSource implements PreferencesLocalDataSource {
  final Map<String, UserPreferencesModel> _preferencesCache = {};
  final Map<String, Map<String, List<TimeSlot>>> _availabilityCache = {};
  final Map<String, bool> _unsyncedFlags = {};
  final Map<String, List<String>> _locationSuggestionsCache = {};

  @override
  Future<UserPreferencesModel?> getLocalPreferences(String userId) async {
    return _preferencesCache[userId];
  }

  @override
  Future<void> saveLocalPreferences(String userId, UserPreferencesModel preferences) async {
    _preferencesCache[userId] = preferences;
  }

  @override
  Future<Map<String, List<TimeSlot>>?> getLocalAvailability(String userId) async {
    return _availabilityCache[userId];
  }

  @override
  Future<void> saveLocalAvailability(String userId, Map<String, List<TimeSlot>> schedule) async {
    _availabilityCache[userId] = schedule;
  }

  @override
  Future<bool> hasUnsyncedChanges(String userId) async {
    return _unsyncedFlags[userId] ?? false;
  }

  @override
  Future<void> markAsSynced(String userId) async {
    _unsyncedFlags[userId] = false;
  }

  @override
  Future<void> clearLocalPreferences(String userId) async {
    _preferencesCache.remove(userId);
    _availabilityCache.remove(userId);
    _unsyncedFlags.remove(userId);
  }

  @override
  Future<Map<String, dynamic>> exportLocalPreferences(String userId) async {
    final preferences = _preferencesCache[userId];
    final availability = _availabilityCache[userId];

    if (preferences == null) {
      throw const PreferencesDataSourceException(
        message: 'No local preferences found',
        code: 'NO_LOCAL_DATA',
      );
    }

    return {
      'user_id': userId,
      'preferences': preferences.toJson(),
      'availability': availability?.map((key, value) => MapEntry(
        key,
        value.map((slot) => {
          'dayOfWeek': slot.dayOfWeek,
          'startHour': slot.startHour,
          'endHour': slot.endHour,
        }).toList(),
      )),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> importLocalPreferences(String userId, Map<String, dynamic> preferences) async {
    if (!preferences.containsKey('preferences')) {
      throw const PreferencesDataSourceException(
        message: 'Invalid preferences format',
        code: 'INVALID_FORMAT',
      );
    }

    final prefsData = preferences['preferences'] as Map<String, dynamic>;
    final userPreferences = UserPreferencesModel.fromJson(prefsData);
    
    await saveLocalPreferences(userId, userPreferences);

    if (preferences.containsKey('availability')) {
      final availabilityData = preferences['availability'] as Map<String, dynamic>;
      final schedule = availabilityData.map<String, List<TimeSlot>>(
        (key, value) => MapEntry(
          key,
          (value as List).map<TimeSlot>((slot) => TimeSlot(
            dayOfWeek: slot['dayOfWeek'],
            startHour: slot['startHour'],
            endHour: slot['endHour'],
          )).toList(),
        ),
      );
      
      await saveLocalAvailability(userId, schedule);
    }

    _unsyncedFlags[userId] = true;
  }

  @override
  Future<List<String>> validatePreferences(UserPreferencesModel preferences) async {
    final errors = <String>[];

    // Validation: safely access optional properties via dynamic to support
    // multiple model shapes without compile-time errors.
    final dyn = preferences as dynamic;

    final int? competitiveLevel = dyn is Map
        ? (dyn['competitiveLevel'] as int?)
        : (dyn.competitiveLevel as int?);
    if (competitiveLevel != null && (competitiveLevel < 1 || competitiveLevel > 10)) {
      errors.add('Competitive level must be between 1 and 10');
    }

    final int? socialPreference = dyn is Map
        ? (dyn['socialPreference'] as int?)
        : (dyn.socialPreference as int?);
    if (socialPreference != null && (socialPreference < 1 || socialPreference > 10)) {
      errors.add('Social preference must be between 1 and 10');
    }

    final double? maxTravelDistance = dyn is Map
        ? (dyn['maxTravelDistance'] as num?)?.toDouble()
        : (dyn.maxTravelDistance as double?);
    final double? maxTravelRadius = dyn is Map
        ? (dyn['maxTravelRadius'] as num?)?.toDouble()
        : (dyn.maxTravelRadius as double?);
    final double travel = (maxTravelDistance ?? maxTravelRadius ?? 0).toDouble();
    if (travel < 0 || travel > 1000) {
      errors.add('Max travel distance must be between 0 and 1000 km');
    }

    final List<int>? preferredAgeRanges = dyn is Map
        ? (dyn['preferredAgeRanges'] as List?)?.whereType<int>().toList()
        : (dyn.preferredAgeRanges as List<int>?);
    if (preferredAgeRanges != null &&
        preferredAgeRanges.any((age) => age < 13 || age > 100)) {
      errors.add('Age ranges must be between 13 and 100');
    }

    final int? advanceNoticeHours = dyn is Map
        ? dyn['advanceNoticeHours'] as int?
        : (dyn.advanceNoticeHours as int? ?? dyn.minimumNoticeHours as int?);
    if (advanceNoticeHours != null && (advanceNoticeHours < 0 || advanceNoticeHours > 168)) {
      errors.add('Advance notice must be between 0 and 168 hours');
    }

    final String? genderPreference = dyn is Map
        ? dyn['genderPreference'] as String?
        : dyn.genderPreference as String?;
    if (genderPreference != null &&
        !['any', 'male', 'female', 'non-binary', 'same'].contains(genderPreference)) {
      errors.add('Invalid gender preference');
    }

    return errors;
  }

  @override
  Future<List<String>> getCachedLocationSuggestions(String query) async {
    return _locationSuggestionsCache[query.toLowerCase()] ?? [];
  }

  @override
  Future<void> cacheLocationSuggestions(String query, List<String> suggestions) async {
    _locationSuggestionsCache[query.toLowerCase()] = suggestions;
    
    // Keep cache size manageable
    if (_locationSuggestionsCache.length > 100) {
      final keys = _locationSuggestionsCache.keys.toList();
      _locationSuggestionsCache.remove(keys.first);
    }
  }
}
