import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Exception types for settings data source operations
class SettingsDataSourceException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  const SettingsDataSourceException({
    required this.message,
    required this.code,
    this.details,
  });

  @override
  String toString() => 'SettingsDataSourceException: $message (Code: $code)';
}

/// Abstract interface for settings remote data operations
abstract class SettingsRemoteDataSource {
  Future<UserSettingsModel> getUserSettings(String userId);
  Future<UserSettingsModel> updateUserSettings(String userId, UserSettingsModel settings);
  Future<UserSettingsModel> updateSettingCategory(String userId, String category, Map<String, dynamic> data);
  Future<PrivacySettingsModel> getPrivacySettings(String userId);
  Future<PrivacySettingsModel> updatePrivacySettings(String userId, PrivacySettingsModel settings);
  Future<bool> updateSingleSetting(String userId, String key, dynamic value);
  Future<Map<String, dynamic>> batchUpdateSettings(String userId, Map<String, dynamic> updates);
  Future<UserSettingsModel> resetToDefaults(String userId, {List<String>? categories});
  Future<Map<String, dynamic>> getDefaultSettings({String? template});
  Future<bool> validateSettings(UserSettingsModel settings);
  Future<int> getSettingsVersion(String userId);
  Future<UserSettingsModel> migrateSettings(String userId, int fromVersion, int toVersion);
  Future<Map<String, dynamic>> exportSettings(String userId);
  Future<UserSettingsModel> importSettings(String userId, Map<String, dynamic> settings);
}

/// Abstract interface for settings local data operations
abstract class SettingsLocalDataSource {
  Future<UserSettingsModel?> getLocalSettings(String userId);
  Future<void> saveLocalSettings(String userId, UserSettingsModel settings);
  Future<PrivacySettingsModel?> getLocalPrivacySettings(String userId);
  Future<void> saveLocalPrivacySettings(String userId, PrivacySettingsModel settings);
  Future<bool> hasUnsyncedChanges(String userId);
  Future<void> markAsSynced(String userId);
  Future<void> clearLocalSettings(String userId);
  Future<Map<String, dynamic>> getUnsyncedChanges(String userId);
  Future<void> saveUnsyncedChange(String userId, String key, dynamic value);
  Future<int> getLocalVersion(String userId);
  Future<void> setLocalVersion(String userId, int version);
}

/// Supabase implementation of settings remote data source
class SupabaseSettingsDataSource implements SettingsRemoteDataSource {
  final SupabaseClient _client;
  final String _settingsTable = 'user_settings';
  final String _privacyTable = 'privacy_settings';
  final String _settingsVersionTable = 'settings_versions';

  SupabaseSettingsDataSource(this._client);

  @override
  Future<UserSettingsModel> getUserSettings(String userId) async {
    try {
      final response = await _client
          .from(_settingsTable)
          .select('*, privacy_settings(*)')
          .eq('user_id', userId)
          .single();

      return UserSettingsModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return await _createDefaultSettings(userId);
      }
      throw SettingsDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to get user settings: $e',
        code: 'FETCH_ERROR',
      );
    }
  }

  @override
  Future<UserSettingsModel> updateUserSettings(String userId, UserSettingsModel settings) async {
    try {
      final settingsData = settings.toJson();
      settingsData['updated_at'] = DateTime.now().toIso8601String();

      // Update main settings
      final response = await _client
          .from(_settingsTable)
          .upsert(settingsData)
          .eq('user_id', userId)
          .select('*, privacy_settings(*)')
          .single();

      // Update version
      await _incrementSettingsVersion(userId);

      return UserSettingsModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SettingsDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to update user settings: $e',
        code: 'UPDATE_ERROR',
      );
    }
  }

  @override
  Future<UserSettingsModel> updateSettingCategory(String userId, String category, Map<String, dynamic> data) async {
    try {
      final currentSettings = await getUserSettings(userId);
      final updatedData = <String, dynamic>{};

      switch (category) {
        case 'notifications':
          updatedData['game_invite_notifications'] = data['game_invites'] ?? currentSettings.gameInviteNotifications;
          updatedData['social_notifications'] = data['messages'] ?? currentSettings.socialNotifications;
          updatedData['game_update_notifications'] = data['game_updates'] ?? currentSettings.gameUpdateNotifications;
          updatedData['game_reminder_notifications'] = data['achievements'] ?? currentSettings.gameReminderNotifications;
          updatedData['system_notifications'] = data['marketing'] ?? currentSettings.systemNotifications;
          break;
        case 'privacy':
          // Handle privacy settings separately since they're in a different table
          final currentPrivacySettings = await getPrivacySettings(userId);
          final privacyUpdates = PrivacySettingsModel(
            profileVisibility: data['profile_visibility'] ?? currentPrivacySettings.profileVisibility,
            showOnlineStatus: data['show_online_status'] ?? currentPrivacySettings.showOnlineStatus,
            messagePreference: data['allow_direct_messages'] ?? currentPrivacySettings.messagePreference,
            showGameHistory: data['show_game_history'] ?? currentPrivacySettings.showGameHistory,
            showStats: data['show_statistics'] ?? currentPrivacySettings.showStats,
            allowLocationTracking: data['allow_location_sharing'] ?? currentPrivacySettings.allowLocationTracking,
            blockedUsers: currentPrivacySettings.blockedUsers,
            allowDataAnalytics: data['data_processing_consent'] ?? currentPrivacySettings.allowDataAnalytics,
            dataSharingLevel: data['marketing_consent'] ?? currentPrivacySettings.dataSharingLevel,
            showRealName: currentPrivacySettings.showRealName,
            showAge: currentPrivacySettings.showAge,
            showLocation: currentPrivacySettings.showLocation,
            showPhone: currentPrivacySettings.showPhone,
            showEmail: currentPrivacySettings.showEmail,
            showSportsProfiles: currentPrivacySettings.showSportsProfiles,
            showAchievements: currentPrivacySettings.showAchievements,
            gameInvitePreference: currentPrivacySettings.gameInvitePreference,
            allowGameRecommendations: currentPrivacySettings.allowGameRecommendations,
          );
          await updatePrivacySettings(userId, privacyUpdates);
          break;
        case 'preferences':
          updatedData['language'] = data['language'] ?? currentSettings.language;
          updatedData['theme_mode'] = data['theme'] ?? currentSettings.themeMode.name;
          updatedData['region'] = data['timezone'] ?? currentSettings.region;
          updatedData['distance_unit'] = data['distance_unit'] ?? currentSettings.distanceUnit.name;
          updatedData['time_format'] = data['time_format'] ?? currentSettings.timeFormat.name;
          break;
        case 'game':
          updatedData['default_is_public'] = data['default_game_privacy'] ?? currentSettings.defaultIsPublic;
          updatedData['default_allow_waitlist'] = data['enable_game_reminders'] ?? currentSettings.defaultAllowWaitlist;
          updatedData['default_advance_notice_hours'] = data['default_advance_notice_hours'] ?? currentSettings.defaultAdvanceNoticeHours;
          break;
      }

      if (updatedData.isNotEmpty) {
        updatedData['user_id'] = userId;
        updatedData['updated_at'] = DateTime.now().toIso8601String();

        final response = await _client
            .from(_settingsTable)
            .upsert(updatedData)
            .eq('user_id', userId)
            .select('*, privacy_settings(*)')
            .single();

        await _incrementSettingsVersion(userId);
        return UserSettingsModel.fromJson(response);
      }

      return currentSettings;
    } catch (e) {
      if (e is SettingsDataSourceException) rethrow;
      throw SettingsDataSourceException(
        message: 'Failed to update setting category: $e',
        code: 'CATEGORY_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<PrivacySettingsModel> getPrivacySettings(String userId) async {
    try {
      final response = await _client
          .from(_privacyTable)
          .select()
          .eq('user_id', userId)
          .single();

      return PrivacySettingsModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return await _createDefaultPrivacySettings(userId);
      }
      throw SettingsDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to get privacy settings: $e',
        code: 'FETCH_ERROR',
      );
    }
  }

  @override
  Future<PrivacySettingsModel> updatePrivacySettings(String userId, PrivacySettingsModel settings) async {
    try {
      final privacyData = settings.toJson();
      privacyData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(_privacyTable)
          .upsert(privacyData)
          .eq('user_id', userId)
          .select()
          .single();

      await _incrementSettingsVersion(userId);
      return PrivacySettingsModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw SettingsDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to update privacy settings: $e',
        code: 'UPDATE_ERROR',
      );
    }
  }

  @override
  Future<bool> updateSingleSetting(String userId, String key, dynamic value) async {
    try {
      final updateData = {
        'user_id': userId,
        key: value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from(_settingsTable)
          .upsert(updateData)
          .eq('user_id', userId);

      await _incrementSettingsVersion(userId);
      return true;
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to update single setting: $e',
        code: 'SINGLE_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> batchUpdateSettings(String userId, Map<String, dynamic> updates) async {
    try {
      final updateData = {
        'user_id': userId,
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from(_settingsTable)
          .upsert(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      await _incrementSettingsVersion(userId);
      return response;
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to batch update settings: $e',
        code: 'BATCH_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<UserSettingsModel> resetToDefaults(String userId, {List<String>? categories}) async {
    try {
      final defaultSettings = await getDefaultSettings();
      
      if (categories != null && categories.isNotEmpty) {
        // Reset only specific categories
        final currentSettings = await getUserSettings(userId);
        final resetData = <String, dynamic>{};
        
        for (final category in categories) {
          switch (category) {
            case 'notifications':
              resetData.addAll({
                'game_invite_notifications': defaultSettings['game_invite_notifications'],
                'social_notifications': defaultSettings['social_notifications'],
                'game_update_notifications': defaultSettings['game_update_notifications'],
                'game_reminder_notifications': defaultSettings['game_reminder_notifications'],
                'system_notifications': defaultSettings['system_notifications'],
              });
              break;
            case 'preferences':
              resetData.addAll({
                'language': defaultSettings['language'],
                'theme_mode': defaultSettings['theme_mode'],
                'region': defaultSettings['region'],
                'distance_unit': defaultSettings['distance_unit'],
                'time_format': defaultSettings['time_format'],
              });
              break;
            case 'game':
              resetData.addAll({
                'default_is_public': defaultSettings['default_is_public'],
                'default_allow_waitlist': defaultSettings['default_allow_waitlist'],
                'default_advance_notice_hours': defaultSettings['default_advance_notice_hours'],
              });
              break;
          }
        }
        
        if (resetData.isNotEmpty) {
          resetData['user_id'] = userId;
          resetData['updated_at'] = DateTime.now().toIso8601String();
          
          final response = await _client
              .from(_settingsTable)
              .upsert(resetData)
              .eq('user_id', userId)
              .select('*, privacy_settings(*)')
              .single();
          
          return UserSettingsModel.fromJson(response);
        }
        
        return currentSettings;
      } else {
        // Reset all settings
        final resetData = {
          'user_id': userId,
          ...defaultSettings,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // Delete existing settings
        await _client.from(_settingsTable).delete().eq('user_id', userId);
        await _client.from(_privacyTable).delete().eq('user_id', userId);
        
        // Insert default settings
        final response = await _client
            .from(_settingsTable)
            .insert(resetData)
            .select('*, privacy_settings(*)')
            .single();
        
        // Create default privacy settings
        await _createDefaultPrivacySettings(userId);
        
        await _resetSettingsVersion(userId);
        return UserSettingsModel.fromJson(response);
      }
    } catch (e) {
      if (e is SettingsDataSourceException) rethrow;
      throw SettingsDataSourceException(
        message: 'Failed to reset settings: $e',
        code: 'RESET_ERROR',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getDefaultSettings({String? template}) async {
    try {
      // This could be fetched from a default_settings table or hardcoded
      return {
        'language': 'en',
        'theme_mode': 'system',
        'region': 'US',
        'distance_unit': 'miles',
        'time_format': 'twelve',
        'game_invite_notifications': true,
        'social_notifications': true,
        'game_update_notifications': true,
        'game_reminder_notifications': true,
        'system_notifications': false,
        'default_is_public': true,
        'default_allow_waitlist': true,
        'default_advance_notice_hours': 24,
        'enable_push_notifications': true,
        'notification_sound': 'standard',
        'vibration_enabled': true,
        'reminder_minutes_before': 60,
        'enable_animations': true,
        'text_scale': 1.0,
        'high_contrast_mode': false,
        'reduce_motion': false,
        'temperature_unit': 'fahrenheit',
        'date_format': 'mmddyyyy',
        'default_sport': '',
        'default_game_duration': 60,
        'default_max_players': 10,
        'show_traffic_layer': false,
        'show_satellite_view': false,
        'default_map_zoom': 14.0,
        'auto_location_detection': true,
        'enable_data_saver': false,
        'preload_images': true,
        'background_refresh': true,
        'cache_size': 100,
        'screen_reader_enabled': false,
        'voice_over_enabled': false,
        'large_text_enabled': false,
        'button_shapes_enabled': false,
      };
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to get default settings: $e',
        code: 'DEFAULT_SETTINGS_ERROR',
      );
    }
  }

  @override
  Future<bool> validateSettings(UserSettingsModel settings) async {
    try {
      final validLanguages = ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh'];
      final validThemes = ['light', 'dark', 'system'];
      final validDistanceUnits = ['km', 'miles'];
      final validTimeFormats = ['12h', '24h'];

      if (!validLanguages.contains(settings.language)) {
        return false;
      }

      if (!validThemes.contains(settings.themeMode.name)) {
        return false;
      }

      if (!validDistanceUnits.contains(settings.distanceUnit.name)) {
        return false;
      }

      if (!validTimeFormats.contains(settings.timeFormat.name)) {
        return false;
      }

      // defaultIsPublic is a boolean, so no need to validate against string array
      // Just ensure it's a valid boolean value
      if (settings.defaultIsPublic != true && settings.defaultIsPublic != false) {
        return false;
      }

      return true;
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Settings validation failed: $e',
        code: 'VALIDATION_ERROR',
      );
    }
  }

  @override
  Future<int> getSettingsVersion(String userId) async {
    try {
      final response = await _client
          .from(_settingsVersionTable)
          .select('version')
          .eq('user_id', userId)
          .single();

      return response['version'] ?? 1;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // Create initial version
        await _client.from(_settingsVersionTable).insert({
          'user_id': userId,
          'version': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        return 1;
      }
      throw SettingsDataSourceException(
        message: 'Database error: ${e.message}',
        code: 'DATABASE_ERROR',
        details: e,
      );
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to get settings version: $e',
        code: 'VERSION_ERROR',
      );
    }
  }

  @override
  Future<UserSettingsModel> migrateSettings(String userId, int fromVersion, int toVersion) async {
    try {
      // Implement version-specific migration logic
      for (int version = fromVersion + 1; version <= toVersion; version++) {
        await _performMigration(userId, version);
      }

      // Update version
      await _client
          .from(_settingsVersionTable)
          .upsert({
            'user_id': userId,
            'version': toVersion,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      return await getUserSettings(userId);
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Settings migration failed: $e',
        code: 'MIGRATION_ERROR',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> exportSettings(String userId) async {
    try {
      final settings = await getUserSettings(userId);
      final privacySettings = await getPrivacySettings(userId);
      final version = await getSettingsVersion(userId);

      return {
        'user_id': userId,
        'settings': settings.toJson(),
        'privacy_settings': privacySettings.toJson(),
        'version': version,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw SettingsDataSourceException(
        message: 'Failed to export settings: $e',
        code: 'EXPORT_ERROR',
      );
    }
  }

  @override
  Future<UserSettingsModel> importSettings(String userId, Map<String, dynamic> settings) async {
    try {
      // Validate imported settings structure
      if (!settings.containsKey('settings') || !settings.containsKey('privacy_settings')) {
        throw const SettingsDataSourceException(
          message: 'Invalid settings format',
          code: 'INVALID_FORMAT',
        );
      }

      // Import main settings
      final settingsData = settings['settings'] as Map<String, dynamic>;
      settingsData['user_id'] = userId;
      settingsData['created_at'] = DateTime.now().toIso8601String();
      settingsData['updated_at'] = DateTime.now().toIso8601String();

      // Import privacy settings
      final privacyData = settings['privacy_settings'] as Map<String, dynamic>;
      privacyData['user_id'] = userId;
      privacyData['created_at'] = DateTime.now().toIso8601String();
      privacyData['updated_at'] = DateTime.now().toIso8601String();

      // Delete existing settings
      await _client.from(_settingsTable).delete().eq('user_id', userId);
      await _client.from(_privacyTable).delete().eq('user_id', userId);

      // Insert imported settings
      await _client
          .from(_settingsTable)
          .insert(settingsData);

      await _client.from(_privacyTable).insert(privacyData);

      // Update version if provided
      if (settings.containsKey('version')) {
        await _client
            .from(_settingsVersionTable)
            .upsert({
              'user_id': userId,
              'version': settings['version'],
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      }

      return await getUserSettings(userId);
    } catch (e) {
      if (e is SettingsDataSourceException) rethrow;
      throw SettingsDataSourceException(
        message: 'Failed to import settings: $e',
        code: 'IMPORT_ERROR',
      );
    }
  }

  // Helper methods
  Future<UserSettingsModel> _createDefaultSettings(String userId) async {
    final defaultSettings = await getDefaultSettings();
    defaultSettings['user_id'] = userId;
    defaultSettings['created_at'] = DateTime.now().toIso8601String();
    defaultSettings['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from(_settingsTable)
        .insert(defaultSettings)
        .select()
        .single();

    // Create default privacy settings
    await _createDefaultPrivacySettings(userId);

    return UserSettingsModel.fromJson(response);
  }

  Future<PrivacySettingsModel> _createDefaultPrivacySettings(String userId) async {
    final defaultPrivacy = {
      'user_id': userId,
      'profile_visibility': 'public',
      'show_online_status': true,
      'message_preference': 'anyone',
      'show_game_history': true,
      'show_stats': false,
      'allow_location_tracking': false,
      'blocked_users': <String>[],
      'allow_data_analytics': true,
      'data_sharing_level': 'limited',
      'show_real_name': true,
      'show_age': false,
      'show_location': true,
      'show_phone': false,
      'show_email': false,
      'show_sports_profiles': true,
      'show_achievements': true,
      'game_invite_preference': 'anyone',
      'allow_game_recommendations': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from(_privacyTable)
        .insert(defaultPrivacy)
        .select()
        .single();

    return PrivacySettingsModel.fromJson(response);
  }

  Future<void> _incrementSettingsVersion(String userId) async {
    await _client.rpc('increment_settings_version', params: {
      'user_id_param': userId,
    });
  }

  Future<void> _resetSettingsVersion(String userId) async {
    await _client
        .from(_settingsVersionTable)
        .upsert({
          'user_id': userId,
          'version': 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  Future<void> _performMigration(String userId, int toVersion) async {
    // Implement version-specific migrations
    switch (toVersion) {
      case 2:
        // Add new notification settings
        await _client
            .from(_settingsTable)
            .update({
              'game_reminder_notifications': true,
              'system_notifications': false,
            })
            .eq('user_id', userId);
        break;
      case 3:
        // Add new privacy settings
        await _client
            .from(_privacyTable)
            .update({
              'allow_location_tracking': false,
              'allow_data_analytics': true,
            })
            .eq('user_id', userId);
        break;
      // Add more version migrations as needed
    }
  }
}

/// Local storage implementation for settings (could use SharedPreferences, Hive, etc.)
class LocalSettingsDataSource implements SettingsLocalDataSource {
  final Map<String, UserSettingsModel> _settingsCache = {};
  final Map<String, PrivacySettingsModel> _privacyCache = {};
  final Map<String, bool> _unsyncedFlags = {};
  final Map<String, Map<String, dynamic>> _unsyncedChanges = {};
  final Map<String, int> _versions = {};

  @override
  Future<UserSettingsModel?> getLocalSettings(String userId) async {
    return _settingsCache[userId];
  }

  @override
  Future<void> saveLocalSettings(String userId, UserSettingsModel settings) async {
    _settingsCache[userId] = settings;
  }

  @override
  Future<PrivacySettingsModel?> getLocalPrivacySettings(String userId) async {
    return _privacyCache[userId];
  }

  @override
  Future<void> saveLocalPrivacySettings(String userId, PrivacySettingsModel settings) async {
    _privacyCache[userId] = settings;
  }

  @override
  Future<bool> hasUnsyncedChanges(String userId) async {
    return _unsyncedFlags[userId] ?? false;
  }

  @override
  Future<void> markAsSynced(String userId) async {
    _unsyncedFlags[userId] = false;
    _unsyncedChanges[userId] = {};
  }

  @override
  Future<void> clearLocalSettings(String userId) async {
    _settingsCache.remove(userId);
    _privacyCache.remove(userId);
    _unsyncedFlags.remove(userId);
    _unsyncedChanges.remove(userId);
    _versions.remove(userId);
  }

  @override
  Future<Map<String, dynamic>> getUnsyncedChanges(String userId) async {
    return _unsyncedChanges[userId] ?? {};
  }

  @override
  Future<void> saveUnsyncedChange(String userId, String key, dynamic value) async {
    _unsyncedFlags[userId] = true;
    _unsyncedChanges[userId] ??= {};
    _unsyncedChanges[userId]![key] = value;
  }

  @override
  Future<int> getLocalVersion(String userId) async {
    return _versions[userId] ?? 1;
  }

  @override
  Future<void> setLocalVersion(String userId, int version) async {
    _versions[userId] = version;
  }
}
