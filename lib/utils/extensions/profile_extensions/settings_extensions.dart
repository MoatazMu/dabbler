/// Extension methods for UserSettings to add theme and notification functionality
library;
import '../../enums/notification_type_enums.dart';
import '../../enums/theme_enums.dart';

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
  final Map<String, bool> privacySettings;
  final Map<String, bool> notificationChannels;
  
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
    this.privacySettings = const {},
    this.notificationChannels = const {},
  });
}

/// Extension methods for UserSettings entity
extension UserSettingsExtensions on UserSettings {
  /// Check if dark mode is explicitly enabled
  bool get isDarkMode => themeMode == 'dark';
  
  /// Check if light mode is explicitly enabled
  bool get isLightMode => themeMode == 'light';
  
  /// Check if system theme is being followed
  bool get isSystemTheme => themeMode == 'system';
  
  /// Get theme mode as enum
  AppThemeMode get themeEnum => AppThemeMode.fromString(themeMode);
  
  /// Check if any notifications are enabled
  bool get hasNotificationsEnabled => 
      notificationEnabled && (emailNotifications || pushNotifications || smsNotifications);
  
  /// Check if critical notifications are enabled (push or SMS)
  bool get hasCriticalNotificationsEnabled => 
      notificationEnabled && (pushNotifications || smsNotifications);
  
  /// Get count of active notification channels
  int get activeNotificationChannels {
    int count = 0;
    if (notificationEnabled) {
      if (emailNotifications) count++;
      if (pushNotifications) count++;
      if (smsNotifications) count++;
    }
    return count;
  }
  
  /// Check if a specific notification type should be shown
  bool shouldShowNotification(NotificationType type) {
    if (!notificationEnabled) return false;
    
    // Check type-specific settings
    switch (type) {
      case NotificationType.gameInvite:
      case NotificationType.message:
      case NotificationType.friendRequest:
        return pushNotifications; // Real-time notifications use push
        
      case NotificationType.gameReminder:
        return pushNotifications || smsNotifications; // Reminders can use both
        
      case NotificationType.systemUpdate:
        return pushNotifications || emailNotifications; // System updates use both
        
      case NotificationType.marketing:
        return marketingEmails && emailNotifications; // Marketing only via email
    }
  }
  
  /// Check if notification channel is enabled
  bool isNotificationChannelEnabled(String channel) {
    return notificationChannels[channel] ?? true; // Default to enabled
  }
  
  /// Get notification delivery preference for a type
  List<NotificationDeliveryMethod> getDeliveryMethods(NotificationType type) {
    final methods = <NotificationDeliveryMethod>[];
    
    if (!shouldShowNotification(type)) return methods;
    
    switch (type) {
      case NotificationType.gameInvite:
      case NotificationType.message:
      case NotificationType.friendRequest:
        if (pushNotifications) methods.add(NotificationDeliveryMethod.push);
        break;
        
      case NotificationType.gameReminder:
        if (pushNotifications) methods.add(NotificationDeliveryMethod.push);
        if (smsNotifications) methods.add(NotificationDeliveryMethod.sms);
        break;
        
      case NotificationType.systemUpdate:
        if (pushNotifications) methods.add(NotificationDeliveryMethod.push);
        if (emailNotifications) methods.add(NotificationDeliveryMethod.email);
        break;
        
      case NotificationType.marketing:
        if (marketingEmails && emailNotifications) {
          methods.add(NotificationDeliveryMethod.email);
        }
        break;
    }
    
    return methods;
  }
  
  /// Get font size as enum
  FontSize get fontSizeEnum => FontSize.fromString(fontSize);
  
  /// Get accent color as enum
  AccentColor get accentColorEnum => AccentColor.fromString(accentColor);
  
  /// Check if accessibility features are enabled
  bool get hasAccessibilityFeatures => 
      fontSize != 'medium' || !soundEffects || !hapticFeedback;
  
  /// Check if battery saving mode is active
  bool get isBatterySavingMode => 
      !soundEffects || !hapticFeedback || dataUsageOptimization;
  
  /// Check if offline features are enabled
  bool get canWorkOffline => offlineMode;
  
  /// Get privacy level assessment
  String get privacyLevel {
    final privacyCount = privacySettings.values.where((v) => v).length;
    final totalPrivacySettings = privacySettings.length;
    
    if (totalPrivacySettings == 0) return 'default';
    
    final privacyRatio = privacyCount / totalPrivacySettings;
    if (privacyRatio >= 0.8) return 'high';
    if (privacyRatio >= 0.5) return 'medium';
    return 'low';
  }
  
  /// Get security score based on settings
  int get securityScore {
    int score = 0;
    
    if (twoFactorEnabled) score += 30;
    if (!marketingEmails) score += 10;
    if (privacyLevel == 'high') score += 25;
    if (privacyLevel == 'medium') score += 15;
    if (!smsNotifications) score += 5; // SMS can be less secure
    if (dataUsageOptimization) score += 5; // Less data sharing
    
    // Bonus for selective notifications
    if (notificationEnabled && activeNotificationChannels <= 2) score += 10;
    
    return score.clamp(0, 100);
  }
  
  /// Get user experience level based on customization
  String get experienceLevel {
    int customizations = 0;
    
    if (themeMode != 'system') customizations++;
    if (fontSize != 'medium') customizations++;
    if (accentColor != 'blue') customizations++;
    if (!soundEffects || !hapticFeedback) customizations++;
    if (twoFactorEnabled) customizations++;
    if (privacySettings.isNotEmpty) customizations++;
    if (language != 'en') customizations++;
    
    if (customizations >= 5) return 'power_user';
    if (customizations >= 3) return 'intermediate';
    if (customizations >= 1) return 'beginner';
    return 'default';
  }
  
  /// Convert settings to analytics data
  Map<String, dynamic> toAnalytics() {
    return {
      'theme': themeMode,
      'language': language,
      'notifications_enabled': notificationEnabled,
      'notification_channels': activeNotificationChannels,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'marketing_emails': marketingEmails,
      '2fa_enabled': twoFactorEnabled,
      'font_size': fontSize,
      'accent_color': accentColor,
      'sound_effects': soundEffects,
      'haptic_feedback': hapticFeedback,
      'data_optimization': dataUsageOptimization,
      'offline_mode': offlineMode,
      'privacy_level': privacyLevel,
      'security_score': securityScore,
      'experience_level': experienceLevel,
    };
  }
  
  /// Get accessibility summary
  Map<String, dynamic> get accessibilitySettings {
    return {
      'font_size': fontSize,
      'sound_effects': soundEffects,
      'haptic_feedback': hapticFeedback,
      'high_contrast': false, // Would come from theme settings
      'large_text': fontSize == 'large' || fontSize == 'extra_large',
      'reduce_motion': false, // Would come from animation settings
    };
  }
  
  /// Get notification summary
  Map<String, dynamic> get notificationSummary {
    return {
      'enabled': notificationEnabled,
      'channels': {
        'push': pushNotifications,
        'email': emailNotifications,
        'sms': smsNotifications,
      },
      'marketing': marketingEmails,
      'active_channels': activeNotificationChannels,
      'game_invites': shouldShowNotification(NotificationType.gameInvite),
      'messages': shouldShowNotification(NotificationType.message),
      'friend_requests': shouldShowNotification(NotificationType.friendRequest),
      'reminders': shouldShowNotification(NotificationType.gameReminder),
      'system_updates': shouldShowNotification(NotificationType.systemUpdate),
    };
  }
  
  /// Get performance settings summary
  Map<String, dynamic> get performanceSettings {
    return {
      'data_usage_optimization': dataUsageOptimization,
      'offline_mode': offlineMode,
      'sound_effects': soundEffects,
      'haptic_feedback': hapticFeedback,
      'battery_saving': isBatterySavingMode,
    };
  }
  
  /// Check if settings indicate a new user
  bool get appearsToBeBeginner {
    // New users typically have default settings
    return themeMode == 'system' &&
           fontSize == 'medium' &&
           accentColor == 'blue' &&
           soundEffects &&
           hapticFeedback &&
           !twoFactorEnabled &&
           privacySettings.isEmpty;
  }
  
  /// Get recommended settings improvements
  List<String> get recommendedImprovements {
    final recommendations = <String>[];
    
    if (!twoFactorEnabled) {
      recommendations.add('Enable two-factor authentication for better security');
    }
    
    if (marketingEmails) {
      recommendations.add('Consider disabling marketing emails to reduce clutter');
    }
    
    if (smsNotifications && pushNotifications) {
      recommendations.add('You might not need both SMS and push notifications');
    }
    
    if (privacyLevel == 'low') {
      recommendations.add('Review your privacy settings for better data protection');
    }
    
    if (activeNotificationChannels == 0 && notificationEnabled) {
      recommendations.add('Enable at least one notification channel to stay updated');
    }
    
    if (!dataUsageOptimization && offlineMode) {
      recommendations.add('Enable data usage optimization to complement offline mode');
    }
    
    return recommendations;
  }
  
  /// Get settings validation issues
  List<String> get validationIssues {
    final issues = <String>[];
    
    if (notificationEnabled && activeNotificationChannels == 0) {
      issues.add('Notifications are enabled but no delivery channels are active');
    }
    
    if (smsNotifications && !pushNotifications && !emailNotifications) {
      issues.add('SMS is the only notification channel - consider adding backup methods');
    }
    
    if (offlineMode && !dataUsageOptimization) {
      issues.add('Offline mode works better with data usage optimization enabled');
    }
    
    return issues;
  }
  
  /// Generate settings health report
  Map<String, dynamic> get healthReport {
    return {
      'security_score': securityScore,
      'privacy_level': privacyLevel,
      'accessibility_enabled': hasAccessibilityFeatures,
      'notifications_configured': hasNotificationsEnabled,
      'battery_optimized': isBatterySavingMode,
      'experience_level': experienceLevel,
      'recommendations': recommendedImprovements.length,
      'issues': validationIssues.length,
      'overall_health': _calculateOverallHealth(),
    };
  }
  
  /// Private helper to calculate overall settings health
  String _calculateOverallHealth() {
    int healthScore = 0;
    
    if (securityScore >= 70) {
      healthScore += 30;
    } else if (securityScore >= 40) healthScore += 15;
    
    if (privacyLevel == 'high') {
      healthScore += 25;
    } else if (privacyLevel == 'medium') healthScore += 15;
    
    if (hasNotificationsEnabled) healthScore += 20;
    if (validationIssues.isEmpty) healthScore += 15;
    if (twoFactorEnabled) healthScore += 10;
    
    if (healthScore >= 80) return 'excellent';
    if (healthScore >= 60) return 'good';
    if (healthScore >= 40) return 'fair';
    return 'needs_attention';
  }
}
