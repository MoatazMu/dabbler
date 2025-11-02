import 'package:dabbler/data/models/authentication/user.dart';
import 'sports_profile.dart';
import 'profile_statistics.dart';
import 'privacy_settings.dart';
import 'user_preferences.dart';
import 'user_settings.dart';

class UserProfile {
  // Core user information (extends from auth User)
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enhanced profile fields
  final String? bio;
  final DateTime? dateOfBirth;
  final String? location;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final double profileCompletionPercentage;
  final bool isVerified;
  final DateTime? lastActiveAt;

  // Related entities
  final List<SportProfile> sportsProfiles;
  final ProfileStatistics statistics;
  final PrivacySettings privacySettings;
  final UserPreferences preferences;
  final UserSettings settings;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.bio,
    this.dateOfBirth,
    this.location,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.gender,
    this.profileCompletionPercentage = 0.0,
    this.isVerified = false,
    this.lastActiveAt,
    this.sportsProfiles = const [],
    this.statistics = const ProfileStatistics(),
    this.privacySettings = const PrivacySettings(),
    this.preferences = const UserPreferences(userId: ''),
    this.settings = const UserSettings(),
  });

  /// Creates UserProfile from auth User with default values
  factory UserProfile.fromUser(User user) {
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      displayName: user.fullName ?? user.username ?? '',
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      profileCompletionPercentage: _calculateInitialCompletion(user),
    );
  }

  static double _calculateInitialCompletion(User user) {
    double completion = 40.0; // Base for having account
    if ((user.fullName?.isNotEmpty ?? false) ||
        (user.username?.isNotEmpty ?? false)) {
      completion += 10.0;
    }
    if (user.avatarUrl != null) completion += 20.0;
    return completion;
  }

  /// Checks if profile is considered complete
  bool isProfileComplete() {
    return profileCompletionPercentage >= 80.0;
  }

  /// Returns the primary sport (if any)
  SportProfile? getPrimarySport() {
    try {
      return sportsProfiles.firstWhere((sport) => sport.isPrimarySport);
    } catch (e) {
      // If no primary sport set, return most played sport
      if (sportsProfiles.isEmpty) return null;
      return sportsProfiles.reduce(
        (a, b) => a.gamesPlayed > b.gamesPlayed ? a : b,
      );
    }
  }

  /// Returns age calculated from date of birth
  int? getAge() {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Returns full name if available
  String getFullName() {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return '';
  }

  /// Returns display name with privacy considerations
  String getDisplayName({String? viewerId}) {
    if (!privacySettings.canViewField('realName', viewerId)) {
      return displayName.isNotEmpty
          ? displayName
          : ''; // Return username/handle instead
    }
    final fullName = getFullName();
    return fullName.isNotEmpty ? fullName : '';
  }

  /// Calculates and returns current profile completion percentage
  double calculateProfileCompletion() {
    double completion = 0.0;

    // Basic info (40%)
    completion += 20.0; // Account exists
    if (displayName.isNotEmpty) completion += 10.0;
    if (avatarUrl != null) completion += 10.0;

    // Personal details (30%)
    if (bio != null && bio!.isNotEmpty) completion += 10.0;
    if (dateOfBirth != null) completion += 5.0;
    if (location != null && location!.isNotEmpty) completion += 5.0;
    if (firstName != null && lastName != null) completion += 10.0;

    // Sports profiles (20%)
    if (sportsProfiles.isNotEmpty) completion += 10.0;
    if (sportsProfiles.any((sport) => sport.isPrimarySport)) completion += 5.0;
    if (sportsProfiles.any(
      (sport) => sport.skillLevel != SkillLevel.beginner,
    )) {
      completion += 5.0;
    }

    // Preferences and settings (10%)
    if (preferences.preferredGameTypes.isNotEmpty) completion += 5.0;
    if (preferences.weeklyAvailability.isNotEmpty) completion += 5.0;

    return completion.clamp(0.0, 100.0);
  }

  /// Checks if user is active based on various factors
  bool isActiveUser() {
    if (lastActiveAt == null) return false;

    final now = DateTime.now();
    final daysSinceActive = now.difference(lastActiveAt!).inDays;

    return daysSinceActive <= 7; // Active within last week
  }

  /// Returns user's activity status
  String getActivityStatus() {
    if (lastActiveAt == null) return 'New User';

    final now = DateTime.now();
    final duration = now.difference(lastActiveAt!);

    if (duration.inMinutes < 5) return 'Online';
    if (duration.inHours < 1) return 'Active';
    if (duration.inDays < 1) return 'Today';
    if (duration.inDays < 7) return 'This Week';
    if (duration.inDays < 30) return 'This Month';
    return 'Inactive';
  }

  /// Checks compatibility with another user for games
  double getCompatibilityScore(UserProfile otherUser) {
    double score = 0.0;

    // Sport compatibility (30%)
    final myPrimarySport = getPrimarySport();
    final otherPrimarySport = otherUser.getPrimarySport();

    if (myPrimarySport != null && otherPrimarySport != null) {
      if (myPrimarySport.sportId == otherPrimarySport.sportId) {
        score += 30.0;

        // Skill level compatibility bonus
        final skillDiff =
            (myPrimarySport.skillLevel.index -
                    otherPrimarySport.skillLevel.index)
                .abs();
        if (skillDiff <= 1) score += 10.0;
      }
    }

    // Location compatibility (20%)
    if (location != null && otherUser.location != null) {
      // Simplified - would need actual distance calculation
      if (location == otherUser.location) score += 20.0;
    }

    // Age compatibility (15%)
    final myAge = getAge();
    final otherAge = otherUser.getAge();
    if (myAge != null && otherAge != null) {
      final ageDiff = (myAge - otherAge).abs();
      if (ageDiff <= 5) {
        score += 15.0;
      } else if (ageDiff <= 10) {
        score += 10.0;
      } else if (ageDiff <= 15) {
        score += 5.0;
      }
    }

    // Activity compatibility (10%)
    if (isActiveUser() && otherUser.isActiveUser()) {
      score += 10.0;
    }

    // Experience compatibility (15%)
    if (statistics.isExperiencedPlayer() ==
        otherUser.statistics.isExperiencedPlayer()) {
      score += 15.0;
    }

    // Reliability compatibility (10%)
    final myReliability = statistics.getReliabilityScore();
    final otherReliability = otherUser.statistics.getReliabilityScore();
    final reliabilityDiff = (myReliability - otherReliability).abs();

    if (reliabilityDiff <= 10) {
      score += 10.0;
    } else if (reliabilityDiff <= 20) {
      score += 5.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Creates a copy with updated fields
  UserProfile copyWith({
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
    return UserProfile(
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

  /// Creates UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: (json['display_name'] as String?) ?? '',
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
      sportsProfiles: const [], // Placeholder for now
      statistics: const ProfileStatistics(),
      privacySettings: const PrivacySettings(),
      preferences: const UserPreferences(userId: ''),
      settings: const UserSettings(),
    );
  }

  /// Converts UserProfile to JSON
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
      // Placeholders for nested objects
      'sportsProfiles': [],
      'statistics': {},
      'privacySettings': {},
      'preferences': {},
      'settings': {},
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.bio == bio &&
        other.dateOfBirth == dateOfBirth &&
        other.location == location &&
        other.phoneNumber == phoneNumber &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.gender == gender &&
        other.profileCompletionPercentage == profileCompletionPercentage &&
        other.isVerified == isVerified &&
        other.lastActiveAt == lastActiveAt &&
        _listEquals(other.sportsProfiles, sportsProfiles) &&
        other.statistics == statistics &&
        other.privacySettings == privacySettings &&
        other.preferences == preferences &&
        other.settings == settings;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      email,
      displayName,
      avatarUrl,
      createdAt,
      updatedAt,
      bio,
      dateOfBirth,
      location,
      phoneNumber,
      firstName,
      lastName,
      gender,
      profileCompletionPercentage,
      isVerified,
      lastActiveAt,
      Object.hashAll(sportsProfiles),
      statistics,
      privacySettings,
      preferences,
      settings,
    ]);
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
