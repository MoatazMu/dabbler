class UserModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? bio;
  final String? profileImageUrl;
  final String language; // 'en' or 'ar'
  final int? age;
  final String? gender;
  final List<String> sports;
  final String? intent;
  final bool onboardingCompleted;
  final String onboardingStep;
  final String timezone;
  final Map<String, dynamic> notificationSettings;
  final Map<String, dynamic> privacySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.bio,
    this.profileImageUrl,
    this.language = 'en',
    this.age,
    this.gender,
    this.sports = const [],
    this.intent,
    this.onboardingCompleted = false,
    this.onboardingStep = 'phone_input',
    this.timezone = 'UTC',
    this.notificationSettings = const {},
    this.privacySettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  // Get display name with fallback
  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      return lastName!;
    }
    return 'Player';
  }

  // Get full name
  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? 'Player' : parts.join(' ');
  }

  // Check if user has a valid name
  bool get hasValidName {
    return (firstName != null && firstName!.isNotEmpty) ||
           (lastName != null && lastName!.isNotEmpty);
  }

  // Sanitize name for display
  String get sanitizedName {
    final name = displayName;
    if (name.isEmpty) return 'Player';
    
    // Remove special characters and normalize
    return name
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? bio,
    String? profileImageUrl,
    String? language,
    int? age,
    String? gender,
    List<String>? sports,
    String? intent,
    bool? onboardingCompleted,
    String? onboardingStep,
    String? timezone,
    Map<String, dynamic>? notificationSettings,
    Map<String, dynamic>? privacySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      language: language ?? this.language,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      sports: sports ?? this.sports,
      intent: intent ?? this.intent,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      timezone: timezone ?? this.timezone,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'language': language,
      'age': age,
      'gender': gender,
      'sports': sports,
      'intent': intent,
      'onboardingCompleted': onboardingCompleted,
      'onboardingStep': onboardingStep,
      'timezone': timezone,
      'notificationSettings': notificationSettings,
      'privacySettings': privacySettings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      language: json['language'] as String? ?? 'en',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      sports: List<String>.from(json['sports'] ?? []),
      intent: json['intent'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      onboardingStep: json['onboardingStep'] as String? ?? 'phone_input',
      timezone: json['timezone'] as String? ?? 'UTC',
      notificationSettings: Map<String, dynamic>.from(json['notificationSettings'] ?? {}),
      privacySettings: Map<String, dynamic>.from(json['privacySettings'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create UserModel from Supabase JSON response
  factory UserModel.fromSupabaseJson(Map<String, dynamic> json) {
    final displayName = json['display_name'] as String? ?? '';
    
    return UserModel(
      id: json['id'] as String,
      firstName: displayName, // Store display name as firstName for compatibility
      lastName: '', // Keep lastName empty since we're using display name
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      profileImageUrl: json['avatar_url'] as String?,
      language: json['language'] as String? ?? 'en',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      sports: List<String>.from(json['sports'] ?? []),
      intent: json['intent'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      onboardingStep: json['onboarding_step'] as String? ?? 'phone_input',
      timezone: json['timezone'] as String? ?? 'UTC',
      notificationSettings: Map<String, dynamic>.from(json['notification_settings'] ?? {}),
      privacySettings: Map<String, dynamic>.from(json['privacy_settings'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }


}
