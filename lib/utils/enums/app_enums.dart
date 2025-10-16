/// Application-wide enums
library;

/// Represents the current loading state of a process
enum LoadingState {
    initial,
    loading,
    loaded,
    error;

    bool get isLoading => this == LoadingState.loading;
    bool get hasError => this == LoadingState.error;
    bool get isLoaded => this == LoadingState.loaded;
  }

  /// Represents the current environment the app is running in
  enum Environment {
    development,
    staging,
    production;

    bool get isDevelopment => this == Environment.development;
    bool get isStaging => this == Environment.staging;
    bool get isProduction => this == Environment.production;
  }

  /// Sort order for lists and queries
  enum SortOrder {
    ascending('asc'),
    descending('desc');

    final String value;
    const SortOrder(this.value);
  }

  /// Type of network connection
  enum ConnectionType {
    wifi('WiFi'),
    mobile('Mobile Data'),
    none('No Connection');

    final String label;
    const ConnectionType(this.label);
  }

  /// User role types
  enum UserRole {
    admin('Administrator'),
    moderator('Moderator'),
    user('User'),
    guest('Guest');

    final String label;
    const UserRole(this.label);
  }

  /// Notification types
  enum NotificationType {
    info('Info', 'info'),
    success('Success', 'success'),
    warning('Warning', 'warning'),
    error('Error', 'error');

    final String label;
    final String value;
    const NotificationType(this.label, this.value);
  }

  /// Content visibility settings
  enum Visibility {
    public('Public'),
    private('Private'),
    restricted('Restricted');

    final String label;
    const Visibility(this.label);
  }

  /// File types for uploads
  enum FileType {
    image('Image'),
    video('Video'),
    audio('Audio'),
    document('Document'),
    other('Other');

    final String label;
    const FileType(this.label);
  }

  /// Theme modes
  enum ThemeMode {
    light('Light'),
    dark('Dark'),
    system('System');

    final String label;
    const ThemeMode(this.label);
  }

  /// Message status for chat/messaging features
  enum MessageStatus {
    sent('Sent'),
    delivered('Delivered'),
    read('Read'),
    failed('Failed');

    final String label;
    const MessageStatus(this.label);
  }
