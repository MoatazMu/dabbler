import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/entities/privacy_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/models.dart';

/// Data source for settings remote operations
abstract class SettingsRemoteDataSource {
  Future<UserSettingsModel> getSettings(String userId);
  Future<UserSettingsModel> updateSettings(String userId, UserSettingsModel settings);
  Future<PrivacySettingsModel> getPrivacySettings(String userId);
  Future<PrivacySettingsModel> updatePrivacySettings(String userId, PrivacySettingsModel settings);
  Future<void> syncSettings(String userId, Map<String, dynamic> localSettings);
  Future<Map<String, dynamic>> getRemoteSettings(String userId);
  Future<DateTime?> getLastSyncTime(String userId);
  Future<String> backupSettings(String userId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>> restoreSettings(String userId, String backupId);
  Future<List<Map<String, dynamic>>> listBackups(String userId);
}

/// Data source for settings local storage operations
abstract class SettingsLocalDataSource {
  Future<UserSettingsModel?> getLocalSettings(String userId);
  Future<void> saveLocalSettings(String userId, UserSettingsModel settings);
  Future<PrivacySettingsModel?> getLocalPrivacySettings(String userId);
  Future<void> saveLocalPrivacySettings(String userId, PrivacySettingsModel settings);
  Future<DateTime?> getLastSyncTime(String userId);
  Future<void> updateLastSyncTime(String userId, DateTime time);
  Future<bool> hasUnsyncedChanges(String userId);
  Future<void> markAsSynced(String userId);
  Future<void> clearLocalSettings(String userId);
  Future<Map<String, dynamic>> exportLocalSettings(String userId);
  Future<void> importLocalSettings(String userId, Map<String, dynamic> settings);
}

/// Implementation of SettingsRepository with local storage and remote sync
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;
  final SettingsLocalDataSource localDataSource;

  // Sync configuration
  

  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserSettings>> getSettings(String userId) async {
    try {
      // Always try local first for quick access
      final localSettings = await localDataSource.getLocalSettings(userId);
      
      if (localSettings != null) {
        // Start background sync if needed
        _syncSettingsInBackground(userId);
        return Right(localSettings.toEntity());
      }

      // Fetch from remote if no local settings
      final remoteSettings = await remoteDataSource.getSettings(userId);
      
      // Save locally for future quick access
      await localDataSource.saveLocalSettings(userId, remoteSettings);
      await localDataSource.markAsSynced(userId);
      
      return Right(remoteSettings.toEntity());
    } on NetworkFailure catch (e) {
      // Return local settings on network error
      final localSettings = await localDataSource.getLocalSettings(userId);
      if (localSettings != null) {
        return Right(localSettings.toEntity());
      }
      return Left(NetworkFailure(message: 'No network and no local settings: ${e.message}'));
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get settings: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSettings>> updateSettings(
    String userId,
    UserSettings settings,
  ) async {
    try {
      final settingsModel = UserSettingsModel.fromEntity(settings);
      
      // Save locally first for immediate response
      await localDataSource.saveLocalSettings(userId, settingsModel);
      
      try {
        // Sync with remote
        final updatedSettings = await remoteDataSource.updateSettings(userId, settingsModel);
        
        // Update local with server response
        await localDataSource.saveLocalSettings(userId, updatedSettings);
        await localDataSource.markAsSynced(userId);
        
        return Right(updatedSettings.toEntity());
      } catch (e) {
        // Mark as needing sync but return local version
        print('Failed to sync settings: $e');
        return Right(settingsModel.toEntity());
      }
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update settings: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSettings>> updateSetting(
    String userId,
    String key,
    dynamic value,
  ) async {
    try {
      // Get current settings
      final currentResult = await getSettings(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          // Create updated settings with the single change
          final updatedSettings = _updateSingleSetting(currentSettings, key, value);
          return updateSettings(userId, updatedSettings);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update setting: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSettings>> batchUpdateSettings(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Get current settings
      final currentResult = await getSettings(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          // Apply all updates
          var updatedSettings = currentSettings;
          for (final entry in updates.entries) {
            updatedSettings = _updateSingleSetting(updatedSettings, entry.key, entry.value);
          }
          return updateSettings(userId, updatedSettings);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to batch update settings: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSettings>> resetToDefaults(String userId) async {
    try {
      final defaultSettings = await getDefaultSettings();
      return defaultSettings.fold(
        (failure) => Left(failure),
        (defaults) => updateSettings(userId, defaults),
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to reset settings: $e'));
    }
  }

  @override
  Future<Either<Failure, PrivacySettings>> getPrivacySettings(String userId) async {
    try {
      // Try local first
      final localPrivacy = await localDataSource.getLocalPrivacySettings(userId);
      
      if (localPrivacy != null) {
        // Background sync
        _syncPrivacyInBackground(userId);
        return Right(localPrivacy.toEntity());
      }

      // Fetch from remote
      final remotePrivacy = await remoteDataSource.getPrivacySettings(userId);
      
      // Save locally
      await localDataSource.saveLocalPrivacySettings(userId, remotePrivacy);
      
      return Right(remotePrivacy.toEntity());
    } on NetworkFailure catch (e) {
      final localPrivacy = await localDataSource.getLocalPrivacySettings(userId);
      if (localPrivacy != null) {
        return Right(localPrivacy.toEntity());
      }
      return Left(NetworkFailure(message: 'No network and no local privacy settings: ${e.message}'));
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get privacy settings: $e'));
    }
  }

  @override
  Future<Either<Failure, PrivacySettings>> updatePrivacySettings(
    String userId,
    PrivacySettings privacySettings,
  ) async {
    try {
      final privacyModel = PrivacySettingsModel.fromEntity(privacySettings);
      
      // Save locally first
      await localDataSource.saveLocalPrivacySettings(userId, privacyModel);
      
      try {
        // Sync with remote
        final updatedPrivacy = await remoteDataSource.updatePrivacySettings(userId, privacyModel);
        
        // Update local with server response
        await localDataSource.saveLocalPrivacySettings(userId, updatedPrivacy);
        
        return Right(updatedPrivacy.toEntity());
      } catch (e) {
        print('Failed to sync privacy settings: $e');
        return Right(privacyModel.toEntity());
      }
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update privacy settings: $e'));
    }
  }

  @override
  Future<Either<Failure, PrivacySettings>> updatePrivacySetting(
    String userId,
    String key,
    dynamic value,
  ) async {
    try {
      final currentResult = await getPrivacySettings(userId);
      return currentResult.fold(
        (failure) => Left(failure),
        (currentPrivacy) async {
          final updatedPrivacy = _updateSinglePrivacySetting(currentPrivacy, key, value);
          return updatePrivacySettings(userId, updatedPrivacy);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update privacy setting: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> getNotificationPreferences(String userId) async {
    try {
      final settingsResult = await getSettings(userId);
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final prefs = <String, bool>{
            'push_notifications': settings.enablePushNotifications,
            'email_notifications': settings.enablePushNotifications, // Using push notifications as proxy
            'sms_notifications': settings.enablePushNotifications, // Using push notifications as proxy
            'marketing_emails': settings.systemNotifications,
            'enable_sounds': settings.notificationSound != NotificationSound.off,
            'enable_vibration': settings.vibrationEnabled,
          };
          return Right(prefs);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get notification preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> updateNotificationPreferences(
    String userId,
    Map<String, bool> preferences,
  ) async {
    try {
      final updates = <String, dynamic>{};
      preferences.forEach((key, value) {
        updates[key] = value;
      });
      
      final result = await batchUpdateSettings(userId, updates);
      return result.fold(
        (failure) => Left(failure),
        (settings) => getNotificationPreferences(userId),
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update notification preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setNotificationEnabled(
    String userId,
    String notificationType,
    bool enabled,
  ) async {
    try {
      await updateSetting(userId, notificationType, enabled);
      return const Right(null);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to set notification: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getThemeSettings(String userId) async {
    try {
      final settingsResult = await getSettings(userId);
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final themeSettings = {
            'theme': settings.themeMode.name,
            'font_size': settings.textScale.toString(),
            'high_contrast_mode': settings.highContrastMode,
            'large_text_mode': settings.largeTextEnabled,
            'reduced_motion_mode': settings.reduceMotion,
          };
          return Right(themeSettings);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get theme settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateThemeSettings(
    String userId,
    Map<String, dynamic> themeSettings,
  ) async {
    try {
      final result = await batchUpdateSettings(userId, themeSettings);
      return result.fold(
        (failure) => Left(failure),
        (settings) => getThemeSettings(userId),
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update theme settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAccessibilitySettings(String userId) async {
    try {
      final settingsResult = await getSettings(userId);
      return settingsResult.fold(
        (failure) => Left(failure),
        (settings) {
          final accessibilitySettings = {
            'screen_reader_mode': settings.screenReaderEnabled,
            'voice_control_mode': settings.voiceOverEnabled,
            'high_contrast_mode': settings.highContrastMode,
            'large_text_mode': settings.largeTextEnabled,
            'reduced_motion_mode': settings.reduceMotion,
          };
          return Right(accessibilitySettings);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get accessibility settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateAccessibilitySettings(
    String userId,
    Map<String, dynamic> accessibilitySettings,
  ) async {
    try {
      final result = await batchUpdateSettings(userId, accessibilitySettings);
      return result.fold(
        (failure) => Left(failure),
        (settings) => getAccessibilitySettings(userId),
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to update accessibility settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncSettings(String userId) async {
    try {
      final hasChanges = await localDataSource.hasUnsyncedChanges(userId);
      
      if (hasChanges) {
        final localSettings = await localDataSource.getLocalSettings(userId);
        if (localSettings != null) {
          await remoteDataSource.updateSettings(userId, localSettings);
          await localDataSource.markAsSynced(userId);
        }
        
        final localPrivacy = await localDataSource.getLocalPrivacySettings(userId);
        if (localPrivacy != null) {
          await remoteDataSource.updatePrivacySettings(userId, localPrivacy);
        }
      }
      
      await localDataSource.updateLastSyncTime(userId, DateTime.now());
      return const Right(null);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to sync settings: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> needsSync(String userId) async {
    try {
      final hasChanges = await localDataSource.hasUnsyncedChanges(userId);
      return Right(hasChanges);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to check sync status: $e'));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncTime(String userId) async {
    try {
      final lastSync = await localDataSource.getLastSyncTime(userId);
      return Right(lastSync);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get last sync time: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache(String userId) async {
    try {
      await localDataSource.clearLocalSettings(userId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear cache: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportSettings(String userId) async {
    try {
      final exportData = await localDataSource.exportLocalSettings(userId);
      return Right(exportData);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to export settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> importSettings(
    String userId,
    Map<String, dynamic> settingsData, {
    bool overwriteExisting = false,
  }) async {
    try {
      if (!overwriteExisting) {
        // Check if settings exist
        final existing = await localDataSource.getLocalSettings(userId);
        if (existing != null) {
          return const Left(ConflictFailure(message: 'Settings already exist'));
        }
      }
      
      await localDataSource.importLocalSettings(userId, settingsData);
      return const Right(null);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to import settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> migrateSettings(
    String userId,
    int fromVersion,
    int toVersion,
  ) async {
    try {
      // Implement version-specific migration logic
      final local = await localDataSource.getLocalSettings(userId);
      if (local == null) return const Right(null);

      // Apply migrations based on version differences
      var migratedSettings = local;
      
      // Example migrations (implement based on actual schema changes)
      if (fromVersion < 2 && toVersion >= 2) {
        // Migration from v1 to v2
        migratedSettings = _migrateFromV1ToV2(migratedSettings);
      }
      
      if (fromVersion < 3 && toVersion >= 3) {
        // Migration from v2 to v3
        migratedSettings = _migrateFromV2ToV3(migratedSettings);
      }
      
      await localDataSource.saveLocalSettings(userId, migratedSettings);
      return const Right(null);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to migrate settings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> validateSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final errors = <String>[];
      
      // Validate theme
      if (settings.containsKey('theme')) {
        final theme = settings['theme'];
        if (theme is! String || !['light', 'dark', 'system'].contains(theme)) {
          errors.add('Invalid theme value');
        }
      }
      
      // Validate font size
      if (settings.containsKey('font_size')) {
        final fontSize = settings['font_size'];
        if (fontSize is! String || !['small', 'medium', 'large', 'extra_large'].contains(fontSize)) {
          errors.add('Invalid font size value');
        }
      }
      
      // Validate session timeout
      if (settings.containsKey('session_timeout')) {
        final timeout = settings['session_timeout'];
        if (timeout is! int || timeout < 5 || timeout > 1440) { // 5 minutes to 24 hours
          errors.add('Session timeout must be between 5 and 1440 minutes');
        }
      }
      
      return Right(errors);
    } catch (e) {
      return Left(ValidationFailure(message: 'Failed to validate settings: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSettings>> getDefaultSettings({
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      // Create default settings, optionally customized for device
      final defaults = const UserSettings();
      
      if (deviceInfo != null) {
        // Customize based on device capabilities
        // This is where you'd apply device-specific defaults
      }
      
      return Right(defaults);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get default settings: $e'));
    }
  }

  @override
  Future<Either<Failure, PrivacySettings>> getDefaultPrivacySettings() async {
    try {
      // Conservative privacy defaults
      const defaults = PrivacySettings();
      return Right(defaults);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to get default privacy settings: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> backupSettings(String userId) async {
    try {
      final exportResult = await exportSettings(userId);
      return exportResult.fold(
        (failure) => Left(failure),
        (settingsData) async {
          final backupId = await remoteDataSource.backupSettings(userId, settingsData);
          return Right(backupId);
        },
      );
    } catch (e) {
      return Left(DataFailure(message: 'Failed to backup settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> restoreSettings(String userId, String backupId) async {
    try {
      final settingsData = await remoteDataSource.restoreSettings(userId, backupId);
      await localDataSource.importLocalSettings(userId, settingsData);
      return const Right(null);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to restore settings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> listBackups(String userId) async {
    try {
      final backups = await remoteDataSource.listBackups(userId);
      return Right(backups);
    } catch (e) {
      return Left(DataFailure(message: 'Failed to list backups: $e'));
    }
  }

  // Background sync methods
  void _syncSettingsInBackground(String userId) {
    // Run sync in background without blocking UI
    Future.delayed(Duration.zero, () async {
      try {
        await syncSettings(userId);
      } catch (e) {
        print('Background settings sync failed: $e');
      }
    });
  }

  void _syncPrivacyInBackground(String userId) {
    // Similar background sync for privacy settings
    Future.delayed(Duration.zero, () async {
      try {
        final localPrivacy = await localDataSource.getLocalPrivacySettings(userId);
        if (localPrivacy != null) {
          await remoteDataSource.updatePrivacySettings(userId, localPrivacy);
        }
      } catch (e) {
        print('Background privacy sync failed: $e');
      }
    });
  }

  // Helper methods for updating single settings
  UserSettings _updateSingleSetting(UserSettings settings, String key, dynamic value) {
    // This would map setting keys to the appropriate copyWith parameters
    // Implementation depends on the specific UserSettings structure
    switch (key) {
      case 'theme':
        return settings.copyWith(
          themeMode: ThemeMode.values.firstWhere((t) => t.name == value, orElse: () => settings.themeMode),
        );
      case 'language':
        return settings.copyWith(language: value as String);
      case 'push_notifications':
        return settings.copyWith(enablePushNotifications: value as bool);
      case 'email_notifications':
        return settings.copyWith(enablePushNotifications: value as bool);
      // Add more cases as needed
      default:
        return settings;
    }
  }

  PrivacySettings _updateSinglePrivacySetting(PrivacySettings privacy, String key, dynamic value) {
    switch (key) {
      case 'show_real_name':
        return privacy.copyWith(showRealName: value as bool);
      case 'show_age':
        return privacy.copyWith(showAge: value as bool);
      case 'profile_visibility':
        return privacy.copyWith(
          profileVisibility: ProfileVisibility.values.firstWhere(
            (v) => v.name == value,
            orElse: () => privacy.profileVisibility,
          ),
        );
      // Add more cases as needed
      default:
        return privacy;
    }
  }

  // Migration methods
  UserSettingsModel _migrateFromV1ToV2(UserSettingsModel settings) {
    // Implement specific v1 to v2 migration logic
    return settings;
  }

  UserSettingsModel _migrateFromV2ToV3(UserSettingsModel settings) {
    // Implement specific v2 to v3 migration logic
    return settings;
  }
}
