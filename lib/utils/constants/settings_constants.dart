/// Settings system constants for configuration, defaults, and validation
library;

/// Setting categories for organization
class SettingCategories {
  static const String account = 'account';
  static const String notifications = 'notifications';
  static const String privacy = 'privacy';
  static const String display = 'display';
  static const String preferences = 'preferences';
  static const String accessibility = 'accessibility';
  static const String security = 'security';
  static const String data = 'data';
  
  static const List<String> allCategories = [
    account,
    notifications,
    privacy,
    display,
    preferences,
    accessibility,
    security,
    data,
  ];
  
  static const Map<String, String> categoryTitles = {
    account: 'Account Settings',
    notifications: 'Notifications',
    privacy: 'Privacy & Safety',
    display: 'Display & Theme',
    preferences: 'Game Preferences',
    accessibility: 'Accessibility',
    security: 'Security',
    data: 'Data & Storage',
  };
  
  static const Map<String, String> categoryDescriptions = {
    account: 'Manage your account information and profile',
    notifications: 'Control how and when you receive notifications',
    privacy: 'Manage your privacy settings and data sharing',
    display: 'Customize the app appearance and layout',
    preferences: 'Set your game and activity preferences',
    accessibility: 'Accessibility features and options',
    security: 'Account security and authentication settings',
    data: 'Data usage, storage, and backup settings',
  };
}

/// Notification channels and types
class NotificationChannels {
  // Primary channels
  static const String gameInviteChannel = 'game_invites';
  static const String messageChannel = 'messages';
  static const String reminderChannel = 'reminders';
  static const String socialChannel = 'social';
  static const String systemChannel = 'system';
  static const String marketingChannel = 'marketing';
  
  // Sub-channels
  static const String gameStartReminderChannel = 'game_start_reminders';
  static const String gameUpdateChannel = 'game_updates';
  static const String friendRequestChannel = 'friend_requests';
  static const String achievementChannel = 'achievements';
  static const String venueUpdateChannel = 'venue_updates';
  static const String promotionalChannel = 'promotional';
  
  static const List<String> allChannels = [
    gameInviteChannel,
    messageChannel,
    reminderChannel,
    socialChannel,
    systemChannel,
    marketingChannel,
    gameStartReminderChannel,
    gameUpdateChannel,
    friendRequestChannel,
    achievementChannel,
    venueUpdateChannel,
    promotionalChannel,
  ];
  
  static const Map<String, String> channelTitles = {
    gameInviteChannel: 'Game Invitations',
    messageChannel: 'Messages',
    reminderChannel: 'Reminders',
    socialChannel: 'Social Activity',
    systemChannel: 'System Updates',
    marketingChannel: 'Marketing & Promotions',
    gameStartReminderChannel: 'Game Start Reminders',
    gameUpdateChannel: 'Game Updates',
    friendRequestChannel: 'Friend Requests',
    achievementChannel: 'Achievements',
    venueUpdateChannel: 'Venue Updates',
    promotionalChannel: 'Promotional Offers',
  };
  
  static const Map<String, bool> channelDefaults = {
    gameInviteChannel: true,
    messageChannel: true,
    reminderChannel: true,
    socialChannel: true,
    systemChannel: true,
    marketingChannel: false,
    gameStartReminderChannel: true,
    gameUpdateChannel: true,
    friendRequestChannel: true,
    achievementChannel: true,
    venueUpdateChannel: false,
    promotionalChannel: false,
  };
}

/// Theme and display options
class ThemeOptions {
  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';
  static const String auto = 'auto'; // Time-based switching
  
  static const List<String> allThemes = [light, dark, system, auto];
  
  static const Map<String, String> themeDisplayNames = {
    light: 'Light Mode',
    dark: 'Dark Mode',
    system: 'Follow System',
    auto: 'Automatic',
  };
  
  static const Map<String, String> themeDescriptions = {
    light: 'Always use light theme',
    dark: 'Always use dark theme',
    system: 'Follow system theme setting',
    auto: 'Automatically switch based on time',
  };
  
  // Color scheme options
  static const String defaultColorScheme = 'blue';
  static const List<String> colorSchemes = [
    'blue',
    'green',
    'purple',
    'orange',
    'red',
    'teal',
  ];
  
  // Font size options
  static const String smallFont = 'small';
  static const String mediumFont = 'medium';
  static const String largeFont = 'large';
  static const String extraLargeFont = 'extra_large';
  
  static const List<String> fontSizes = [
    smallFont,
    mediumFont,
    largeFont,
    extraLargeFont,
  ];
  
  static const Map<String, double> fontSizeMultipliers = {
    smallFont: 0.85,
    mediumFont: 1.0,
    largeFont: 1.2,
    extraLargeFont: 1.4,
  };
}

/// Language and localization options
class LanguageOptions {
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
  };
  
  static const String defaultLanguage = 'en';
  static const String systemLanguage = 'system';
  
  static const Map<String, bool> rtlLanguages = {
    'ar': true,
    'he': true,
    'fa': true,
    'ur': true,
  };
  
  static const List<String> fullyLocalizedLanguages = ['en', 'es', 'fr'];
  static const List<String> partiallyLocalizedLanguages = ['de', 'it', 'pt'];
}

/// Default settings values
class DefaultSettings {
  // Notification defaults
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultPushNotifications = true;
  static const bool defaultEmailNotifications = true;
  static const bool defaultSmsNotifications = false;
  
  // Privacy defaults
  static const bool defaultProfilePublic = true;
  static const bool defaultShowOnlineStatus = true;
  static const bool defaultAllowMessages = true;
  static const bool defaultShowLocation = false;
  static const bool defaultAnalyticsEnabled = true;
  
  // Display defaults
  static const String defaultTheme = ThemeOptions.system;
  static const String defaultColorScheme = 'blue';
  static const String defaultFontSize = ThemeOptions.mediumFont;
  static const bool defaultAnimationsEnabled = true;
  static const bool defaultHapticFeedback = true;
  
  // Game preferences defaults
  static const int defaultGameRadius = 10; // km
  static const String defaultSkillLevel = 'intermediate';
  static const int defaultMinPlayers = 2;
  static const int defaultMaxPlayers = 20;
  static const bool defaultWeekendGames = true;
  static const bool defaultWeekdayGames = true;
  
  // Account defaults
  static const bool defaultTwoFactorEnabled = false;
  static const bool defaultDataSavingMode = false;
  static const bool defaultAutoBackup = true;
  static const String defaultTimeFormat = '24h'; // or '12h'
  static const String defaultDateFormat = 'DD/MM/YYYY';
  static const String defaultDistanceUnit = 'km'; // or 'miles'
  
  // Accessibility defaults
  static const bool defaultScreenReaderEnabled = false;
  static const bool defaultHighContrastMode = false;
  static const bool defaultReducedMotion = false;
  static const bool defaultLargeText = false;
}

/// Settings validation and limits
class SettingsLimits {
  static const int maxCustomSportsRadius = 100; // km
  static const int minCustomSportsRadius = 1; // km
  static const int maxNotificationFrequency = 100; // per day
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 30;
  static const int maxDisplayNameLength = 50;
  static const int maxBioLength = 500;
  
  // Rate limiting
  static const int maxSettingChangesPerHour = 50;
  static const int maxPasswordChangesPerDay = 3;
  static const int maxEmailChangesPerWeek = 2;
  
  // Data limits
  static const int maxExportRequestsPerMonth = 5;
  static const int maxBackupSize = 100 * 1024 * 1024; // 100MB
  static const Duration settingsDebounce = Duration(milliseconds: 500);
}

/// Setting types for validation and UI generation
class SettingTypes {
  static const String boolean = 'boolean';
  static const String string = 'string';
  static const String number = 'number';
  static const String select = 'select';
  static const String multiSelect = 'multi_select';
  static const String range = 'range';
  static const String color = 'color';
  static const String time = 'time';
  static const String date = 'date';
  
  static const List<String> allTypes = [
    boolean,
    string,
    number,
    select,
    multiSelect,
    range,
    color,
    time,
    date,
  ];
}

/// Settings storage keys
class SettingsKeys {
  // Account settings
  static const String username = 'username';
  static const String displayName = 'display_name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String bio = 'bio';
  static const String location = 'location';
  
  // Privacy settings
  static const String profileVisibility = 'profile_visibility';
  static const String showOnlineStatus = 'show_online_status';
  static const String allowMessages = 'allow_messages';
  static const String showLocation = 'show_location';
  static const String analyticsEnabled = 'analytics_enabled';
  static const String dataSharingEnabled = 'data_sharing_enabled';
  
  // Notification settings
  static const String notificationsEnabled = 'notifications_enabled';
  static const String pushNotifications = 'push_notifications';
  static const String emailNotifications = 'email_notifications';
  static const String smsNotifications = 'sms_notifications';
  static const String quietHoursEnabled = 'quiet_hours_enabled';
  static const String quietHoursStart = 'quiet_hours_start';
  static const String quietHoursEnd = 'quiet_hours_end';
  
  // Display settings
  static const String theme = 'theme';
  static const String colorScheme = 'color_scheme';
  static const String fontSize = 'font_size';
  static const String language = 'language';
  static const String animationsEnabled = 'animations_enabled';
  static const String hapticFeedback = 'haptic_feedback';
  
  // Game preferences
  static const String gameRadius = 'game_radius';
  static const String preferredSkillLevel = 'preferred_skill_level';
  static const String minPlayers = 'min_players';
  static const String maxPlayers = 'max_players';
  static const String weekendGames = 'weekend_games';
  static const String weekdayGames = 'weekday_games';
  static const String preferredGameTypes = 'preferred_game_types';
  static const String availableDays = 'available_days';
  static const String availableHours = 'available_hours';
  
  // Accessibility settings
  static const String screenReaderEnabled = 'screen_reader_enabled';
  static const String highContrastMode = 'high_contrast_mode';
  static const String reducedMotion = 'reduced_motion';
  static const String largeText = 'large_text';
  static const String voiceOverEnabled = 'voice_over_enabled';
  
  // Security settings
  static const String twoFactorEnabled = 'two_factor_enabled';
  static const String biometricEnabled = 'biometric_enabled';
  static const String sessionTimeout = 'session_timeout';
  static const String loginNotifications = 'login_notifications';
  
  // Data settings
  static const String dataSavingMode = 'data_saving_mode';
  static const String autoBackup = 'auto_backup';
  static const String syncEnabled = 'sync_enabled';
  static const String cacheSize = 'cache_size';
  static const String offlineMode = 'offline_mode';
}

/// Time and date format options
class TimeFormats {
  static const String format12h = '12h';
  static const String format24h = '24h';
  
  static const List<String> timeFormats = [format12h, format24h];
  
  static const Map<String, String> timeFormatDisplay = {
    format12h: '12-hour (AM/PM)',
    format24h: '24-hour',
  };
}

class DateFormats {
  static const String ddmmyyyy = 'DD/MM/YYYY';
  static const String mmddyyyy = 'MM/DD/YYYY';
  static const String yyyymmdd = 'YYYY-MM-DD';
  
  static const List<String> dateFormats = [ddmmyyyy, mmddyyyy, yyyymmdd];
  
  static const Map<String, String> dateFormatDisplay = {
    ddmmyyyy: 'DD/MM/YYYY',
    mmddyyyy: 'MM/DD/YYYY',
    yyyymmdd: 'YYYY-MM-DD',
  };
}

/// Unit preferences
class UnitPreferences {
  static const String metric = 'metric';
  static const String imperial = 'imperial';
  
  static const List<String> unitSystems = [metric, imperial];
  
  static const Map<String, String> distanceUnits = {
    metric: 'km',
    imperial: 'miles',
  };
  
  static const Map<String, String> weightUnits = {
    metric: 'kg',
    imperial: 'lbs',
  };
  
  static const Map<String, String> temperatureUnits = {
    metric: '°C',
    imperial: '°F',
  };
}

/// Settings error messages
class SettingsErrorMessages {
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String usernameTaken = 'This username is already taken';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String radiusTooLarge = 'Search radius cannot exceed 100 km';
  static const String radiusTooSmall = 'Search radius must be at least 1 km';
  static const String rateLimitExceeded = 'Too many changes. Please wait before trying again';
  static const String networkError = 'Unable to save settings. Please check your connection';
  static const String serverError = 'Server error. Please try again later';
  static const String invalidValue = 'Invalid value provided';
  static const String settingNotFound = 'Setting not found';
  static const String permissionDenied = 'Permission denied for this setting';
}
