/// Mixin for managing user settings with caching and change tracking
library;
import 'dart:async';
import 'package:flutter/material.dart';

/// Temporary model class for user settings
/// TODO: Replace with actual model from features/profile/data/models/
class UserSettings {
  final String themeMode;
  final String language;
  final bool notificationEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool marketingEmails;
  final bool twoFactorEnabled;
  final String fontSize;
  final String accentColor;
  final bool soundEffects;
  final bool hapticFeedback;
  final bool dataUsageOptimization;
  final bool offlineMode;
  final Map<String, dynamic> preferences;
  
  const UserSettings({
    this.themeMode = 'system',
    this.language = 'en',
    this.notificationEnabled = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.marketingEmails = false,
    this.twoFactorEnabled = false,
    this.fontSize = 'medium',
    this.accentColor = 'blue',
    this.soundEffects = true,
    this.hapticFeedback = true,
    this.dataUsageOptimization = false,
    this.offlineMode = false,
    this.preferences = const {},
  });
  
  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'language': language,
    'notificationEnabled': notificationEnabled,
    'emailNotifications': emailNotifications,
    'pushNotifications': pushNotifications,
    'smsNotifications': smsNotifications,
    'marketingEmails': marketingEmails,
    'twoFactorEnabled': twoFactorEnabled,
    'fontSize': fontSize,
    'accentColor': accentColor,
    'soundEffects': soundEffects,
    'hapticFeedback': hapticFeedback,
    'dataUsageOptimization': dataUsageOptimization,
    'offlineMode': offlineMode,
    'preferences': preferences,
  };
}

/// Mixin for managing user settings with automatic caching and change tracking
mixin SettingsMixin<T extends StatefulWidget> on State<T> {
  final Map<String, dynamic> _settingsCache = {};
  final Set<String> _dirtySettings = {};
  StreamSubscription? _settingsSubscription;
  Timer? _autoSaveTimer;
  bool _isInitialized = false;
  bool _isSaving = false;
  Duration _autoSaveDelay = const Duration(seconds: 5);
  
  /// Initialize settings management with stream subscription
  void initSettings(
    Stream<UserSettings> settingsStream, {
    Duration? autoSaveDelay,
    bool enableAutoSave = true,
  }) {
    if (_isInitialized) return;
    
    _autoSaveDelay = autoSaveDelay ?? _autoSaveDelay;
    _isInitialized = true;
    
    // Subscribe to settings stream
    _settingsSubscription = settingsStream.listen(
      (settings) => _updateCache(settings.toJson()),
      onError: (error) => _handleStreamError(error),
    );
    
    // Enable auto-save if requested
    if (enableAutoSave) {
      _enableAutoSave();
    }
  }
  
  /// Update cache with new settings data
  void _updateCache(Map<String, dynamic> settings) {
    if (!mounted) return;
    
    setState(() {
      _settingsCache.clear();
      _settingsCache.addAll(settings);
    });
  }
  
  /// Handle stream errors
  void _handleStreamError(dynamic error) {
    print('Settings stream error: $error');
    // Could show error dialog or retry logic here
  }
  
  /// Get setting value with type safety
  T? getSetting<T>(String key) {
    final value = _settingsCache[key];
    if (value is T) return value;
    return null;
  }
  
  /// Get setting value with default fallback
  T getSettingWithDefault<T>(String key, T defaultValue) {
    final value = getSetting<T>(key);
    return value ?? defaultValue;
  }
  
  /// Update setting value with change tracking
  void updateSetting(String key, dynamic value) {
    if (!mounted) return;
    
    final currentValue = _settingsCache[key];
    if (currentValue == value) return; // No change
    
    setState(() {
      _settingsCache[key] = value;
      _dirtySettings.add(key);
    });
    
    // Schedule auto-save
    _scheduleAutoSave();
    
    // Trigger immediate effects for certain settings
    _handleImmediateSettingChange(key, value);
  }
  
  /// Update multiple settings at once
  void updateSettings(Map<String, dynamic> updates) {
    if (!mounted || updates.isEmpty) return;
    
    bool hasChanges = false;
    
    setState(() {
      for (final entry in updates.entries) {
        if (_settingsCache[entry.key] != entry.value) {
          _settingsCache[entry.key] = entry.value;
          _dirtySettings.add(entry.key);
          hasChanges = true;
        }
      }
    });
    
    if (hasChanges) {
      _scheduleAutoSave();
    }
  }
  
  /// Handle immediate setting changes (like theme)
  void _handleImmediateSettingChange(String key, dynamic value) {
    switch (key) {
      case 'themeMode':
        _applyThemeChange(value as String);
        break;
      case 'language':
        _applyLanguageChange(value as String);
        break;
      case 'hapticFeedback':
        _applyHapticFeedbackChange(value as bool);
        break;
    }
  }
  
  /// Apply theme change immediately
  void _applyThemeChange(String themeMode) {
    // This would typically update the app's theme
    print('Theme changed to: $themeMode');
  }
  
  /// Apply language change immediately
  void _applyLanguageChange(String language) {
    // This would typically trigger a locale change
    print('Language changed to: $language');
  }
  
  /// Apply haptic feedback setting immediately
  void _applyHapticFeedbackChange(bool enabled) {
    // This would configure haptic feedback globally
    print('Haptic feedback: ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Schedule auto-save with debouncing
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      if (hasUnsavedChanges && !_isSaving) {
        saveSettings();
      }
    });
  }
  
  /// Enable auto-save functionality
  void _enableAutoSave() {
    // Auto-save is enabled through _scheduleAutoSave calls
    print('Auto-save enabled with ${_autoSaveDelay.inSeconds}s delay');
  }
  
  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => _dirtySettings.isNotEmpty;
  
  /// Get count of unsaved changes
  int get unsavedChangesCount => _dirtySettings.length;
  
  /// Get list of dirty setting keys
  Set<String> get dirtySettings => Set.from(_dirtySettings);
  
  /// Save settings to persistent storage
  Future<bool> saveSettings({bool showProgress = true}) async {
    if (!hasUnsavedChanges || _isSaving) return true;
    
    _isSaving = true;
    bool success = false;
    
    try {
      if (showProgress && mounted) {
        _showSavingDialog();
      }
      
      // Prepare updates for saving
      final updates = Map.fromEntries(
        _dirtySettings.map((key) => MapEntry(key, _settingsCache[key])),
      );
      
      // Simulate API call - replace with actual settings service
      await _saveToService(updates);
      
      // Mark as saved
      _dirtySettings.clear();
      success = true;
      
      if (mounted && showProgress) {
        Navigator.pop(context); // Hide progress dialog
        _showSuccessMessage();
      }
      
    } catch (e) {
      print('Failed to save settings: $e');
      
      if (mounted && showProgress) {
        Navigator.pop(context); // Hide progress dialog
        _showErrorMessage(e.toString());
      }
    } finally {
      _isSaving = false;
    }
    
    return success;
  }
  
  /// Save settings updates to service
  Future<void> _saveToService(Map<String, dynamic> updates) async {
    // This would call your actual settings service
    print('Saving ${updates.length} settings: ${updates.keys.toList()}');
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate potential failures
    if (updates.containsKey('invalid_setting')) {
      throw Exception('Invalid setting detected');
    }
  }
  
  /// Show saving progress dialog
  void _showSavingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Saving settings...')
          ],
        ),
      ),
    );
  }
  
  /// Show success message
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Settings saved successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Show error message
  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to save: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => saveSettings(),
        ),
      ),
    );
  }
  
  /// Reset specific setting to default value
  void resetSetting(String key) {
    final defaultValues = _getDefaultSettings();
    if (defaultValues.containsKey(key)) {
      updateSetting(key, defaultValues[key]);
    }
  }
  
  /// Reset all settings to defaults
  void resetAllSettings() {
    final defaultValues = _getDefaultSettings();
    updateSettings(defaultValues);
  }
  
  /// Get default settings values
  Map<String, dynamic> _getDefaultSettings() {
    return const UserSettings().toJson();
  }
  
  /// Discard unsaved changes
  void discardChanges() {
    if (!hasUnsavedChanges) return;
    
    setState(() {
      // Clear dirty settings without restoring values
      // TODO: Implement restoration from last saved state when needed
      _dirtySettings.clear();
    });
    
    _autoSaveTimer?.cancel();
  }
  
  /// Handle back navigation with unsaved changes
  Future<bool> onWillPop() async {
    if (!hasUnsavedChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unsaved Changes'),
          ],
        ),
        content: Text(
          'You have $unsavedChangesCount unsaved change${unsavedChangesCount > 1 ? 's' : ''}. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, false); // Don't leave yet
              final saved = await saveSettings();
              if (saved && mounted) {
                Navigator.pop(context); // Now we can leave
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Show settings comparison dialog
  void showSettingsChanges() {
    if (!hasUnsavedChanges) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Changes'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have $unsavedChangesCount unsaved changes:'),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _dirtySettings.length,
                  itemBuilder: (context, index) {
                    final key = _dirtySettings.elementAt(index);
                    final value = _settingsCache[key];
                    return ListTile(
                      leading: Icon(
                        _getSettingIcon(key),
                        size: 20,
                      ),
                      title: Text(_humanizeSettingName(key)),
                      subtitle: Text(_formatSettingValue(value)),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              saveSettings();
            },
            child: const Text('Save All'),
          ),
        ],
      ),
    );
  }
  
  /// Get icon for setting type
  IconData _getSettingIcon(String key) {
    switch (key) {
      case 'themeMode':
        return Icons.palette;
      case 'language':
        return Icons.language;
      case 'notificationEnabled':
      case 'emailNotifications':
      case 'pushNotifications':
        return Icons.notifications;
      case 'fontSize':
        return Icons.text_fields;
      case 'soundEffects':
        return Icons.volume_up;
      case 'hapticFeedback':
        return Icons.vibration;
      case 'dataUsageOptimization':
        return Icons.data_usage;
      default:
        return Icons.settings;
    }
  }
  
  /// Convert setting key to human readable name
  String _humanizeSettingName(String key) {
    final words = key.replaceAll(RegExp(r'([A-Z])'), ' \$1').split(' ');
    return words
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
  
  /// Format setting value for display
  String _formatSettingValue(dynamic value) {
    if (value is bool) {
      return value ? 'Enabled' : 'Disabled';
    } else if (value is String) {
      return value.isEmpty ? '(empty)' : value;
    } else if (value == null) {
      return '(not set)';
    }
    return value.toString();
  }
  
  /// Export settings as JSON
  Map<String, dynamic> exportSettings() {
    return Map.from(_settingsCache);
  }
  
  /// Import settings from JSON
  void importSettings(Map<String, dynamic> settings) {
    updateSettings(settings);
  }
  
  /// Get settings synchronously (cached values)
  Map<String, dynamic> get currentSettings => Map.from(_settingsCache);
  
  /// Check if settings are being saved
  bool get isSaving => _isSaving;
  
  /// Force immediate save (bypass auto-save delay)
  Future<bool> saveSettingsImmediate() {
    _autoSaveTimer?.cancel();
    return saveSettings();
  }
  
  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _autoSaveTimer?.cancel();
    
    // Auto-save on dispose if there are unsaved changes
    if (hasUnsavedChanges && !_isSaving) {
      saveSettings(showProgress: false);
    }
    
    super.dispose();
  }
}
