/// Mixin for managing privacy settings and access control
library;
import 'package:flutter/material.dart';

/// Temporary model class for privacy settings
class PrivacySettings {
  final String profileVisibility; // 'public', 'friends', 'private'
  final bool showEmail;
  final bool showPhone;
  final bool showLocation;
  final bool showAge;
  final bool showSportsStats;
  final bool showGameHistory;
  final bool allowMessages;
  final bool allowFriendRequests;
  final bool allowGameInvites;
  final bool showOnlineStatus;
  final List<String> blockedUsers;
  final Map<String, bool> customPermissions;
  
  const PrivacySettings({
    this.profileVisibility = 'public',
    this.showEmail = false,
    this.showPhone = false,
    this.showLocation = true,
    this.showAge = true,
    this.showSportsStats = true,
    this.showGameHistory = true,
    this.allowMessages = true,
    this.allowFriendRequests = true,
    this.allowGameInvites = true,
    this.showOnlineStatus = true,
    this.blockedUsers = const [],
    this.customPermissions = const {},
  });
  
  PrivacySettings copyWith({
    String? profileVisibility,
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showAge,
    bool? showSportsStats,
    bool? showGameHistory,
    bool? allowMessages,
    bool? allowFriendRequests,
    bool? allowGameInvites,
    bool? showOnlineStatus,
    List<String>? blockedUsers,
    Map<String, bool>? customPermissions,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showLocation: showLocation ?? this.showLocation,
      showAge: showAge ?? this.showAge,
      showSportsStats: showSportsStats ?? this.showSportsStats,
      showGameHistory: showGameHistory ?? this.showGameHistory,
      allowMessages: allowMessages ?? this.allowMessages,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowGameInvites: allowGameInvites ?? this.allowGameInvites,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      customPermissions: customPermissions ?? this.customPermissions,
    );
  }
}

/// Mixin for managing privacy settings and access control
mixin PrivacyManagementMixin {
  PrivacySettings? _currentSettings;
  final Set<String> _pendingChanges = {};
  final Map<String, dynamic> _originalValues = {};
  bool _hasUnsavedChanges = false;
  
  /// Initialize privacy management with current settings
  void initPrivacyManagement(PrivacySettings settings) {
    _currentSettings = settings;
    _pendingChanges.clear();
    _originalValues.clear();
    _hasUnsavedChanges = false;
    
    // Store original values for change tracking
    _storeOriginalValues(settings);
  }
  
  /// Store original values for comparison
  void _storeOriginalValues(PrivacySettings settings) {
    _originalValues.addAll({
      'profileVisibility': settings.profileVisibility,
      'showEmail': settings.showEmail,
      'showPhone': settings.showPhone,
      'showLocation': settings.showLocation,
      'showAge': settings.showAge,
      'showSportsStats': settings.showSportsStats,
      'showGameHistory': settings.showGameHistory,
      'allowMessages': settings.allowMessages,
      'allowFriendRequests': settings.allowFriendRequests,
      'allowGameInvites': settings.allowGameInvites,
      'showOnlineStatus': settings.showOnlineStatus,
    });
  }
  
  /// Check if user can view specific field
  bool canUserView(
    String field, {
    required bool isFriend,
    required bool isOwner,
    String? userId,
  }) {
    if (isOwner) return true;
    if (_currentSettings == null) return false;
    
    // Check if user is blocked
    if (userId != null && _currentSettings!.blockedUsers.contains(userId)) {
      return false;
    }
    
    // Check profile visibility first
    switch (_currentSettings!.profileVisibility) {
      case 'private':
        return false; // Only owner can see private profiles
      case 'friends':
        if (!isFriend) return false;
        break;
      case 'public':
        // Continue to field-specific checks
        break;
    }
    
    // Field-specific visibility checks
    switch (field.toLowerCase()) {
      case 'email':
        return _currentSettings!.showEmail && isFriend;
      case 'phone':
      case 'phone_number':
        return _currentSettings!.showPhone && isFriend;
      case 'location':
        return _currentSettings!.showLocation;
      case 'age':
      case 'date_of_birth':
        return _currentSettings!.showAge;
      case 'stats':
      case 'statistics':
      case 'sports_stats':
        return _currentSettings!.showSportsStats;
      case 'games':
      case 'game_history':
        return _currentSettings!.showGameHistory;
      case 'online_status':
        return _currentSettings!.showOnlineStatus;
      default:
        // Check custom permissions
        return _currentSettings!.customPermissions[field] ?? true;
    }
  }
  
  /// Check if user can perform specific action
  bool canUserPerformAction(
    String action, {
    required bool isFriend,
    required bool isOwner,
    String? userId,
  }) {
    if (isOwner) return true;
    if (_currentSettings == null) return false;
    
    // Check if user is blocked
    if (userId != null && _currentSettings!.blockedUsers.contains(userId)) {
      return false;
    }
    
    switch (action.toLowerCase()) {
      case 'send_message':
        return _currentSettings!.allowMessages;
      case 'send_friend_request':
        return _currentSettings!.allowFriendRequests;
      case 'send_game_invite':
        return _currentSettings!.allowGameInvites;
      default:
        return false;
    }
  }
  
  /// Update privacy setting with change tracking
  void updatePrivacySetting(String key, dynamic value) {
    if (_currentSettings == null) return;
    
    final oldValue = _getSettingValue(key);
    if (oldValue == value) return; // No change
    
    // Track the change
    _pendingChanges.add(key);
    _hasUnsavedChanges = true;
    
    // Update the setting
    _currentSettings = _updateSettingValue(key, value);
  }
  
  /// Get current value of a setting
  dynamic _getSettingValue(String key) {
    if (_currentSettings == null) return null;
    
    switch (key) {
      case 'profileVisibility':
        return _currentSettings!.profileVisibility;
      case 'showEmail':
        return _currentSettings!.showEmail;
      case 'showPhone':
        return _currentSettings!.showPhone;
      case 'showLocation':
        return _currentSettings!.showLocation;
      case 'showAge':
        return _currentSettings!.showAge;
      case 'showSportsStats':
        return _currentSettings!.showSportsStats;
      case 'showGameHistory':
        return _currentSettings!.showGameHistory;
      case 'allowMessages':
        return _currentSettings!.allowMessages;
      case 'allowFriendRequests':
        return _currentSettings!.allowFriendRequests;
      case 'allowGameInvites':
        return _currentSettings!.allowGameInvites;
      case 'showOnlineStatus':
        return _currentSettings!.showOnlineStatus;
      default:
        return _currentSettings!.customPermissions[key];
    }
  }
  
  /// Update setting value and return new settings object
  PrivacySettings _updateSettingValue(String key, dynamic value) {
    switch (key) {
      case 'profileVisibility':
        return _currentSettings!.copyWith(profileVisibility: value as String);
      case 'showEmail':
        return _currentSettings!.copyWith(showEmail: value as bool);
      case 'showPhone':
        return _currentSettings!.copyWith(showPhone: value as bool);
      case 'showLocation':
        return _currentSettings!.copyWith(showLocation: value as bool);
      case 'showAge':
        return _currentSettings!.copyWith(showAge: value as bool);
      case 'showSportsStats':
        return _currentSettings!.copyWith(showSportsStats: value as bool);
      case 'showGameHistory':
        return _currentSettings!.copyWith(showGameHistory: value as bool);
      case 'allowMessages':
        return _currentSettings!.copyWith(allowMessages: value as bool);
      case 'allowFriendRequests':
        return _currentSettings!.copyWith(allowFriendRequests: value as bool);
      case 'allowGameInvites':
        return _currentSettings!.copyWith(allowGameInvites: value as bool);
      case 'showOnlineStatus':
        return _currentSettings!.copyWith(showOnlineStatus: value as bool);
      default:
        // Handle custom permissions
        final newPermissions = Map<String, bool>.from(_currentSettings!.customPermissions);
        newPermissions[key] = value as bool;
        return _currentSettings!.copyWith(customPermissions: newPermissions);
    }
  }
  
  /// Show confirmation dialog for privacy changes
  Future<bool> confirmPrivacyChanges(BuildContext context) async {
    if (_pendingChanges.isEmpty) return true;
    
    final warnings = _getPrivacyWarnings();
    final hasSignificantChanges = _hasSignificantPrivacyChanges();
    
    if (!hasSignificantChanges && warnings.isEmpty) return true;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              hasSignificantChanges ? Icons.security : Icons.info_outline,
              color: hasSignificantChanges ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 8),
            const Text('Privacy Settings'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasSignificantChanges)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'You\'re making significant changes to your privacy settings.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (hasSignificantChanges) const SizedBox(height: 16),
              
              const Text('The following changes will be applied:'),
              const SizedBox(height: 12),
              
              ..._getPendingChangesList().map((change) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(change)),
                  ],
                ),
              )),
              
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Important considerations:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(hasSignificantChanges ? 'Confirm Changes' : 'Apply'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Get list of privacy warnings for current changes
  List<String> _getPrivacyWarnings() {
    final warnings = <String>[];
    
    for (final change in _pendingChanges) {
      final currentValue = _getSettingValue(change);
      final originalValue = _originalValues[change];
      
      switch (change) {
        case 'profileVisibility':
          if (originalValue == 'public' && currentValue != 'public') {
            warnings.add('Your profile will be less visible to other users');
          } else if (originalValue != 'public' && currentValue == 'public') {
            warnings.add('Your profile will be visible to all users');
          }
          break;
          
        case 'showLocation':
          if (originalValue == true && currentValue == false) {
            warnings.add('Hiding location will reduce match accuracy');
          }
          break;
          
        case 'allowMessages':
          if (originalValue == true && currentValue == false) {
            warnings.add('You won\'t receive messages from other users');
          }
          break;
          
        case 'allowGameInvites':
          if (originalValue == true && currentValue == false) {
            warnings.add('You won\'t receive game invitations');
          }
          break;
          
        case 'showSportsStats':
          if (originalValue == true && currentValue == false) {
            warnings.add('Other players won\'t see your sports performance');
          }
          break;
      }
    }
    
    return warnings;
  }
  
  /// Check if changes are significant (affect core functionality)
  bool _hasSignificantPrivacyChanges() {
    final significantFields = {
      'profileVisibility',
      'allowMessages',
      'allowFriendRequests',
      'allowGameInvites',
    };
    
    return _pendingChanges.any((change) => significantFields.contains(change));
  }
  
  /// Get human-readable list of pending changes
  List<String> _getPendingChangesList() {
    final changes = <String>[];
    
    for (final change in _pendingChanges) {
      final currentValue = _getSettingValue(change);
      final originalValue = _originalValues[change];
      
      switch (change) {
        case 'profileVisibility':
          changes.add('Profile visibility: ${_capitalizeFirst(originalValue)} → ${_capitalizeFirst(currentValue)}');
          break;
        case 'showEmail':
          changes.add('Email visibility: ${_boolToText(originalValue)} → ${_boolToText(currentValue)}');
          break;
        case 'showPhone':
          changes.add('Phone visibility: ${_boolToText(originalValue)} → ${_boolToText(currentValue)}');
          break;
        case 'showLocation':
          changes.add('Location visibility: ${_boolToText(originalValue)} → ${_boolToText(currentValue)}');
          break;
        case 'allowMessages':
          changes.add('Allow messages: ${_boolToText(originalValue)} → ${_boolToText(currentValue)}');
          break;
        case 'allowGameInvites':
          changes.add('Allow game invites: ${_boolToText(originalValue)} → ${_boolToText(currentValue)}');
          break;
        default:
          changes.add('${_humanizeFieldName(change)}: ${_boolToText(originalValue)} → ${_boolToText(currentValue)}');
          break;
      }
    }
    
    return changes;
  }
  
  /// Convert boolean to human readable text
  String _boolToText(bool value) {
    return value ? 'Enabled' : 'Disabled';
  }
  
  /// Capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
  
  /// Convert field name to human readable format
  String _humanizeFieldName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => _capitalizeFirst(word))
        .join(' ');
  }
  
  /// Clear pending changes without saving
  void clearPendingChanges() {
    _pendingChanges.clear();
    _hasUnsavedChanges = false;
    
    // Restore original settings
    if (_originalValues.isNotEmpty && _currentSettings != null) {
      _currentSettings = PrivacySettings(
        profileVisibility: _originalValues['profileVisibility'],
        showEmail: _originalValues['showEmail'],
        showPhone: _originalValues['showPhone'],
        showLocation: _originalValues['showLocation'],
        showAge: _originalValues['showAge'],
        showSportsStats: _originalValues['showSportsStats'],
        showGameHistory: _originalValues['showGameHistory'],
        allowMessages: _originalValues['allowMessages'],
        allowFriendRequests: _originalValues['allowFriendRequests'],
        allowGameInvites: _originalValues['allowGameInvites'],
        showOnlineStatus: _originalValues['showOnlineStatus'],
      );
    }
  }
  
  /// Commit pending changes
  void commitPrivacyChanges() {
    _pendingChanges.clear();
    _hasUnsavedChanges = false;
    
    // Update original values with current settings
    if (_currentSettings != null) {
      _storeOriginalValues(_currentSettings!);
    }
  }
  
  /// Get current privacy settings
  PrivacySettings? get currentPrivacySettings => _currentSettings;
  
  /// Check if there are unsaved changes
  bool get hasUnsavedPrivacyChanges => _hasUnsavedChanges;
  
  /// Get list of pending changes
  Set<String> get pendingPrivacyChanges => Set.from(_pendingChanges);
  
  /// Get privacy level assessment
  String get privacyLevel {
    if (_currentSettings == null) return 'unknown';
    
    int privacyScore = 0;
    
    // Profile visibility
    switch (_currentSettings!.profileVisibility) {
      case 'private':
        privacyScore += 30;
        break;
      case 'friends':
        privacyScore += 20;
        break;
      case 'public':
        privacyScore += 0;
        break;
    }
    
    // Field visibility (each worth 10 points if hidden)
    if (!_currentSettings!.showEmail) privacyScore += 10;
    if (!_currentSettings!.showPhone) privacyScore += 10;
    if (!_currentSettings!.showLocation) privacyScore += 5;
    if (!_currentSettings!.showAge) privacyScore += 5;
    if (!_currentSettings!.showOnlineStatus) privacyScore += 10;
    
    // Communication settings (each worth 10 points if disabled)
    if (!_currentSettings!.allowMessages) privacyScore += 10;
    if (!_currentSettings!.allowFriendRequests) privacyScore += 10;
    if (!_currentSettings!.allowGameInvites) privacyScore += 10;
    
    // Determine privacy level
    if (privacyScore >= 80) return 'very_high';
    if (privacyScore >= 60) return 'high';
    if (privacyScore >= 40) return 'medium';
    if (privacyScore >= 20) return 'low';
    return 'very_low';
  }
  
  /// Get privacy recommendations
  List<String> get privacyRecommendations {
    if (_currentSettings == null) return [];
    
    final recommendations = <String>[];
    
    if (_currentSettings!.profileVisibility == 'public') {
      recommendations.add('Consider limiting profile visibility to friends for better privacy');
    }
    
    if (_currentSettings!.showEmail && _currentSettings!.showPhone) {
      recommendations.add('Showing both email and phone might be unnecessary');
    }
    
    if (_currentSettings!.allowMessages && _currentSettings!.allowFriendRequests) {
      recommendations.add('Your profile is very open to contact - consider if this is intentional');
    }
    
    if (_currentSettings!.showLocation && _currentSettings!.profileVisibility == 'public') {
      recommendations.add('Showing location on public profile reduces privacy');
    }
    
    return recommendations;
  }
}
