import 'package:dabbler/data/models/profile/user_profile.dart';
import 'package:dabbler/data/models/profile/sports_profile.dart';
import 'package:dabbler/data/models/profile/profile_statistics.dart';
import 'package:dabbler/data/models/profile/privacy_settings.dart';
import 'package:dabbler/data/models/profile/user_preferences.dart';
import 'package:dabbler/data/models/profile/user_settings.dart';
import 'sports_profile_model.dart';
import 'profile_statistics_model.dart';
import 'privacy_settings_model.dart';
import 'user_preferences_model.dart';
import 'user_settings_model.dart';

class ProfileModel extends UserProfile {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.avatarUrl,
    required super.createdAt,
    required super.updatedAt,
    super.bio,
    super.dateOfBirth,
    super.location,
    super.phoneNumber,
    super.firstName,
    super.lastName,
    super.gender,
    super.profileCompletionPercentage = 0.0,
    super.isVerified = false,
    super.lastActiveAt,
    super.sportsProfiles = const [],
    super.statistics = const ProfileStatistics(),
    super.privacySettings = const PrivacySettings(),
    super.preferences = const UserPreferences(userId: ''),
    super.settings = const UserSettings(),
  });

  /// Creates ProfileModel from domain entity
  factory ProfileModel.fromEntity(UserProfile entity) {
    return ProfileModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      bio: entity.bio,
      dateOfBirth: entity.dateOfBirth,
      location: entity.location,
      phoneNumber: entity.phoneNumber,
      firstName: entity.firstName,
      lastName: entity.lastName,
      gender: entity.gender,
      profileCompletionPercentage: entity.profileCompletionPercentage,
      isVerified: entity.isVerified,
      lastActiveAt: entity.lastActiveAt,
      sportsProfiles: entity.sportsProfiles,
      statistics: entity.statistics,
      privacySettings: entity.privacySettings,
      preferences: entity.preferences,
      settings: entity.settings,
    );
  }

  /// Creates ProfileModel from JSON (Supabase response)
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Prefer coalesced display name if present (from a view), then common fallbacks
    final coalescedName =
        (json['display_name_coalesced'] as String?) ??
        (json['display_name'] as String?) ??
        (json['username'] as String?) ??
        (json['full_name'] as String?);
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: coalescedName ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bio: json['bio'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      location: json['location'] as String?,
      phoneNumber: json['phone_number'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      gender: json['gender'] as String?,
      profileCompletionPercentage:
          (json['profile_completion_percentage'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['is_verified'] as bool? ?? false,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      sportsProfiles: _parseSportsProfiles(json['sports_profiles']),
      statistics: _parseStatistics(json['statistics']),
      privacySettings: _parsePrivacySettings(json['privacy_settings']),
      preferences: _parsePreferences(json['preferences']),
      settings: _parseSettings(json['settings']),
    );
  }

  /// Creates ProfileModel from comprehensive Supabase profile query
  factory ProfileModel.fromSupabaseProfile(Map<String, dynamic> json) {
    // Handle nested relationships from complex JOIN queries
    final coalescedName =
        (json['display_name_coalesced'] as String?) ??
        (json['display_name'] as String?) ??
        (json['username'] as String?) ??
        (json['full_name'] as String?);
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: coalescedName ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bio: json['bio'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      location: json['location'] as String?,
      phoneNumber: json['phone_number'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      gender: json['gender'] as String?,
      profileCompletionPercentage: _calculateCompletionFromData(json),
      isVerified: json['is_verified'] as bool? ?? false,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      sportsProfiles: _parseSportsProfilesFromSupabase(json),
      statistics: _parseStatisticsFromSupabase(json),
      privacySettings: _parsePrivacyFromSupabase(json),
      preferences: _parsePreferencesFromSupabase(json),
      settings: _parseSettingsFromSupabase(json),
    );
  }

  /// Creates ProfileModel from auth user with minimal data
  factory ProfileModel.fromAuthUser(Map<String, dynamic> authUser) {
    final now = DateTime.now();
    return ProfileModel(
      id: authUser['id'] as String,
      email: authUser['email'] as String,
      displayName:
          authUser['user_metadata']?['display_name'] as String? ??
          authUser['user_metadata']?['full_name'] as String? ??
          authUser['email'] as String,
      avatarUrl: authUser['user_metadata']?['avatar_url'] as String?,
      createdAt: DateTime.parse(authUser['created_at'] as String),
      updatedAt: now,
      profileCompletionPercentage: 20.0, // Minimal completion
      lastActiveAt: now,
    );
  }

  /// Converts ProfileModel to JSON for API requests
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'location': location,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'profile_completion_percentage': profileCompletionPercentage,
      'is_verified': isVerified,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'sports_profiles': sportsProfiles.map((e) {
        // Create a temporary SportProfileModel with required parameters
        final now = DateTime.now();
        return SportProfileModel.fromEntity(
          e,
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
          userId: id,
          createdAt: now,
          updatedAt: now,
        ).toJson();
      }).toList(),
      'statistics': ProfileStatisticsModel.fromEntity(statistics).toJson(),
      'privacy_settings': PrivacySettingsModel.fromEntity(
        privacySettings,
      ).toJson(),
      'preferences': UserPreferencesModel.fromEntity(preferences).toJson(),
      'settings': UserSettingsModel.fromEntity(settings).toJson(),
    };
  }

  /// Converts to JSON for profile updates (main profile table)
  Map<String, dynamic> toProfileUpdateJson() {
    return {
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'location': location,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'profile_completion_percentage': calculateProfileCompletion(),
      'last_active_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Converts to JSON for initial profile creation
  Map<String, dynamic> toInsertJson() {
    final now = DateTime.now();
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'location': location,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'profile_completion_percentage': calculateProfileCompletion(),
      'is_verified': isVerified,
      'last_active_at': now.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }

  /// Returns data for separate table insertions
  Map<String, List<Map<String, dynamic>>> getRelatedDataForInsert() {
    final now = DateTime.now();
    return {
      'sports_profiles': sportsProfiles.map((e) {
        // Create a temporary SportProfileModel with required parameters
        return SportProfileModel.fromEntity(
          e,
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
          userId: id,
          createdAt: now,
          updatedAt: now,
        ).toInsertJson();
      }).toList(),
      'statistics': [
        ProfileStatisticsModel.fromEntity(statistics).toUpdateJson(),
      ],
      'privacy_settings': [
        PrivacySettingsModel.fromEntity(privacySettings).toUpdateJson(),
      ],
      'preferences': [
        UserPreferencesModel.fromEntity(preferences).toUpdateJson(),
      ],
      'settings': [UserSettingsModel.fromEntity(settings).toUpdateJson()],
      'availability': UserPreferencesModel.fromEntity(
        preferences,
      ).toAvailabilityRecords(id),
      'notifications': UserPreferencesModel.fromEntity(
        preferences,
      ).toNotificationRecords(id),
    };
  }

  /// Converts ProfileModel to a map for Supabase updates and inserts
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'location': location,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'profile_completion_percentage': profileCompletionPercentage,
      'is_verified': isVerified,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  // Helper parsing methods

  static List<SportProfile> _parseSportsProfiles(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map(
            (e) => SportProfileModel.fromJson(
              e as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    }
    return [];
  }

  static ProfileStatistics _parseStatistics(dynamic value) {
    if (value == null) return const ProfileStatistics();
    if (value is Map<String, dynamic>) {
      return ProfileStatisticsModel.fromJson(value).toEntity();
    }
    return const ProfileStatistics();
  }

  static PrivacySettings _parsePrivacySettings(dynamic value) {
    if (value == null) return const PrivacySettings();
    if (value is Map<String, dynamic>) {
      return PrivacySettingsModel.fromJson(value).toEntity();
    }
    return const PrivacySettings();
  }

  static UserPreferences _parsePreferences(dynamic value) {
    if (value == null) return const UserPreferences(userId: '');
    if (value is Map<String, dynamic>) {
      return UserPreferencesModel.fromJson(value).toEntity();
    }
    return const UserPreferences(userId: '');
  }

  static UserSettings _parseSettings(dynamic value) {
    if (value == null) return const UserSettings();
    if (value is Map<String, dynamic>) {
      return UserSettingsModel.fromJson(value).toEntity();
    }
    return const UserSettings();
  }

  // Supabase-specific parsing methods

  static List<SportProfile> _parseSportsProfilesFromSupabase(
    Map<String, dynamic> json,
  ) {
    if (json.containsKey('sports_profiles') &&
        json['sports_profiles'] is List) {
      return (json['sports_profiles'] as List)
          .map(
            (e) => SportProfileModel.fromSupabaseResponse(
              e as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    }
    if (json.containsKey('user_sports') && json['user_sports'] is List) {
      return (json['user_sports'] as List)
          .map(
            (e) => SportProfileModel.fromSupabaseResponse(
              e as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    }
    return [];
  }

  static ProfileStatistics _parseStatisticsFromSupabase(
    Map<String, dynamic> json,
  ) {
    if (json.containsKey('profile_statistics')) {
      return ProfileStatisticsModel.fromSupabaseAggregated(
        json['profile_statistics'] as Map<String, dynamic>,
      ).toEntity();
    }
    // Parse from aggregated fields in main query
    return ProfileStatisticsModel.fromSupabaseAggregated(json).toEntity();
  }

  static PrivacySettings _parsePrivacyFromSupabase(Map<String, dynamic> json) {
    if (json.containsKey('privacy_settings')) {
      return PrivacySettingsModel.fromJson(
        json['privacy_settings'] as Map<String, dynamic>,
      ).toEntity();
    }
    // Try to parse from flattened fields
    final flattened = <String, dynamic>{};
    json.forEach((key, value) {
      if (key.startsWith('privacy_') ||
          key.startsWith('allow_') ||
          key.startsWith('show_')) {
        flattened[key] = value;
      }
    });
    if (flattened.isNotEmpty) {
      return PrivacySettingsModel.fromJson(flattened).toEntity();
    }
    return const PrivacySettings();
  }

  static UserPreferences _parsePreferencesFromSupabase(
    Map<String, dynamic> json,
  ) {
    if (json.containsKey('user_preferences')) {
      return UserPreferencesModel.fromSupabaseResponse(
        json['user_preferences'] as Map<String, dynamic>,
      ).toEntity();
    }
    return UserPreferencesModel.fromSupabaseResponse(json).toEntity();
  }

  static UserSettings _parseSettingsFromSupabase(Map<String, dynamic> json) {
    if (json.containsKey('user_settings')) {
      return UserSettingsModel.fromJson(
        json['user_settings'] as Map<String, dynamic>,
      ).toEntity();
    }
    // Try to parse from flattened fields
    final flattened = <String, dynamic>{};
    json.forEach((key, value) {
      if (key.startsWith('settings_') ||
          key.contains('language') ||
          key.contains('theme') ||
          key.contains('unit')) {
        flattened[key] = value;
      }
    });
    if (flattened.isNotEmpty) {
      return UserSettingsModel.fromJson(flattened).toEntity();
    }
    return const UserSettings();
  }

  static double _calculateCompletionFromData(Map<String, dynamic> json) {
    double completion = 0.0;

    // Basic info (40%)
    completion += 20.0; // Account exists
    if ((json['display_name'] as String?)?.isNotEmpty == true)
      completion += 10.0;
    if (json['avatar_url'] != null) completion += 10.0;

    // Personal details (30%)
    if ((json['bio'] as String?)?.isNotEmpty == true) completion += 10.0;
    if (json['date_of_birth'] != null) completion += 5.0;
    if ((json['location'] as String?)?.isNotEmpty == true) completion += 5.0;
    if (json['first_name'] != null && json['last_name'] != null)
      completion += 10.0;

    // Sports profiles (20%)
    final sportsProfiles = json['sports_profiles'] ?? json['user_sports'];
    if (sportsProfiles is List && sportsProfiles.isNotEmpty) {
      completion += 10.0;
      // Check for primary sport
      if (sportsProfiles.any((s) => s['is_primary_sport'] == true))
        completion += 5.0;
      // Check for skill levels
      if (sportsProfiles.any(
        (s) => s['skill_level'] != null && s['skill_level'] > 0,
      ))
        completion += 5.0;
    }

    // Preferences (10%)
    final preferences = json['user_preferences'] ?? json['preferences'];
    if (preferences is Map) {
      if ((preferences['preferred_game_types'] as List?)?.isNotEmpty == true)
        completion += 5.0;
      if ((preferences['weekly_availability'] as Map?)?.isNotEmpty == true)
        completion += 5.0;
    }

    return completion.clamp(0.0, 100.0);
  }

  /// Creates a copy with updated fields
  @override
  ProfileModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bio,
    DateTime? dateOfBirth,
    String? location,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? gender,
    double? profileCompletionPercentage,
    bool? isVerified,
    DateTime? lastActiveAt,
    List<SportProfile>? sportsProfiles,
    ProfileStatistics? statistics,
    PrivacySettings? privacySettings,
    UserPreferences? preferences,
    UserSettings? settings,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      profileCompletionPercentage:
          profileCompletionPercentage ?? this.profileCompletionPercentage,
      isVerified: isVerified ?? this.isVerified,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      sportsProfiles: sportsProfiles ?? this.sportsProfiles,
      statistics: statistics ?? this.statistics,
      privacySettings: privacySettings ?? this.privacySettings,
      preferences: preferences ?? this.preferences,
      settings: settings ?? this.settings,
    );
  }

  /// Converts back to domain entity
  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      bio: bio,
      dateOfBirth: dateOfBirth,
      location: location,
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      profileCompletionPercentage: profileCompletionPercentage,
      isVerified: isVerified,
      lastActiveAt: lastActiveAt,
      sportsProfiles: sportsProfiles,
      statistics: statistics,
      privacySettings: privacySettings,
      preferences: preferences,
      settings: settings,
    );
  }
}
