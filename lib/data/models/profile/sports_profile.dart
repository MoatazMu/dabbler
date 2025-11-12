enum SkillLevel { beginner, intermediate, advanced, expert }

class SportProfile {
  final String sportId;
  final String sportName;
  final SkillLevel skillLevel;
  final int yearsPlaying;
  final List<String> preferredPositions;
  final List<String> certifications;
  final List<String> achievements;
  final bool isPrimarySport;
  final DateTime? lastPlayed;
  final int gamesPlayed;
  final double averageRating;

  const SportProfile({
    required this.sportId,
    required this.sportName,
    required this.skillLevel,
    this.yearsPlaying = 0,
    this.preferredPositions = const [],
    this.certifications = const [],
    this.achievements = const [],
    this.isPrimarySport = false,
    this.lastPlayed,
    this.gamesPlayed = 0,
    this.averageRating = 0.0,
  });

  /// Returns the skill level as a human-readable string
  String getSkillLevelName() {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return 'Beginner';
      case SkillLevel.intermediate:
        return 'Intermediate';
      case SkillLevel.advanced:
        return 'Advanced';
      case SkillLevel.expert:
        return 'Expert';
    }
  }

  /// Returns true if player has significant experience (2+ years or intermediate+)
  bool isExperienced() {
    return yearsPlaying >= 2 ||
        skillLevel == SkillLevel.advanced ||
        skillLevel == SkillLevel.expert;
  }

  /// Returns true if player is active (played within last 3 months)
  bool isActive() {
    if (lastPlayed == null) return false;
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    return lastPlayed!.isAfter(threeMonthsAgo);
  }

  /// Returns true if player has certifications in this sport
  bool isCertified() => certifications.isNotEmpty;

  /// Returns experience level description combining years and skill
  String getExperienceDescription() {
    if (yearsPlaying == 0) return 'New to ${sportName.toLowerCase()}';
    if (yearsPlaying == 1) return '1 year of ${sportName.toLowerCase()}';
    return '$yearsPlaying years of ${sportName.toLowerCase()}';
  }

  /// Creates a copy with updated fields
  SportProfile copyWith({
    String? sportId,
    String? sportName,
    SkillLevel? skillLevel,
    int? yearsPlaying,
    List<String>? preferredPositions,
    List<String>? certifications,
    List<String>? achievements,
    bool? isPrimarySport,
    DateTime? lastPlayed,
    int? gamesPlayed,
    double? averageRating,
  }) {
    return SportProfile(
      sportId: sportId ?? this.sportId,
      sportName: sportName ?? this.sportName,
      skillLevel: skillLevel ?? this.skillLevel,
      yearsPlaying: yearsPlaying ?? this.yearsPlaying,
      preferredPositions: preferredPositions ?? this.preferredPositions,
      certifications: certifications ?? this.certifications,
      achievements: achievements ?? this.achievements,
      isPrimarySport: isPrimarySport ?? this.isPrimarySport,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  /// Creates a SportProfile from JSON
  /// Supports both simple schema (sport_key, skill_level) and full schema
  factory SportProfile.fromJson(Map<String, dynamic> json) {
    // Handle simple schema from database: sport_key, skill_level
    if (json.containsKey('sport_key')) {
      final sportKey = json['sport_key'] as String;
      final skillLevelInt = json['skill_level'] as int? ?? 0;
      
      return SportProfile(
        sportId: sportKey,
        sportName: _getSportNameFromKey(sportKey),
        skillLevel: _parseSkillLevelFromInt(skillLevelInt),
        yearsPlaying: 0, // Not in simple schema
        preferredPositions: const [], // Not in simple schema
        certifications: const [], // Not in simple schema
        achievements: const [], // Not in simple schema
        isPrimarySport: false, // Not in simple schema
        lastPlayed: null, // Not in simple schema
        gamesPlayed: 0, // Not in simple schema
        averageRating: 0.0, // Not in simple schema
      );
    }
    
    // Handle full schema (backward compatibility)
    return SportProfile(
      sportId: json['sportId'] as String? ?? json['sport_id'] as String? ?? '',
      sportName: json['sportName'] as String? ?? json['sport_name'] as String? ?? '',
      skillLevel: _parseSkillLevel(json['skillLevel'] ?? json['skill_level']),
      yearsPlaying: json['yearsPlaying'] as int? ?? json['years_playing'] as int? ?? 0,
      preferredPositions: List<String>.from(
        json['preferredPositions'] as List? ?? json['positions'] as List? ?? [],
      ),
      certifications: List<String>.from(
        json['certifications'] as List? ?? [],
      ),
      achievements: List<String>.from(
        json['achievements'] as List? ?? [],
      ),
      isPrimarySport: json['isPrimarySport'] as bool? ?? json['is_primary_sport'] as bool? ?? false,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'] as String)
          : json['last_played'] != null
              ? DateTime.parse(json['last_played'] as String)
              : null,
      gamesPlayed: json['gamesPlayed'] as int? ?? json['games_played'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 
          (json['average_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  /// Parse skill level from integer (0=beginner, 1=intermediate, 2=advanced, 3=expert)
  static SkillLevel _parseSkillLevelFromInt(int value) {
    switch (value) {
      case 0:
        return SkillLevel.beginner;
      case 1:
        return SkillLevel.intermediate;
      case 2:
        return SkillLevel.advanced;
      case 3:
        return SkillLevel.expert;
      default:
        return SkillLevel.beginner;
    }
  }
  
  /// Parse skill level from various formats
  static SkillLevel _parseSkillLevel(dynamic value) {
    if (value == null) return SkillLevel.beginner;
    
    if (value is int) {
      return _parseSkillLevelFromInt(value);
    }
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'beginner':
          return SkillLevel.beginner;
        case 'intermediate':
          return SkillLevel.intermediate;
        case 'advanced':
          return SkillLevel.advanced;
        case 'expert':
          return SkillLevel.expert;
        default:
          return SkillLevel.beginner;
      }
    }
    
    return SkillLevel.beginner;
  }
  
  /// Get sport display name from sport_key
  static String _getSportNameFromKey(String sportKey) {
    // Map common sport keys to display names
    final key = sportKey.toLowerCase();
    switch (key) {
      case 'football':
      case 'soccer':
        return 'Football';
      case 'basketball':
        return 'Basketball';
      case 'tennis':
        return 'Tennis';
      case 'badminton':
        return 'Badminton';
      case 'volleyball':
        return 'Volleyball';
      case 'tabletennis':
      case 'table_tennis':
        return 'Table Tennis';
      case 'squash':
        return 'Squash';
      case 'cricket':
        return 'Cricket';
      case 'baseball':
        return 'Baseball';
      case 'hockey':
        return 'Hockey';
      case 'rugby':
        return 'Rugby';
      case 'swimming':
        return 'Swimming';
      case 'golf':
        return 'Golf';
      case 'padel':
        return 'Padel';
      default:
        // Capitalize first letter as fallback
        return sportKey.isEmpty 
            ? 'Unknown Sport'
            : '${sportKey[0].toUpperCase()}${sportKey.substring(1)}';
    }
  }

  /// Converts SportProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'sportId': sportId,
      'sportName': sportName,
      'skillLevel': skillLevel.toString().split('.').last,
      'yearsPlaying': yearsPlaying,
      'preferredPositions': preferredPositions,
      'certifications': certifications,
      'achievements': achievements,
      'isPrimarySport': isPrimarySport,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'gamesPlayed': gamesPlayed,
      'averageRating': averageRating,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SportProfile &&
        other.sportId == sportId &&
        other.sportName == sportName &&
        other.skillLevel == skillLevel &&
        other.yearsPlaying == yearsPlaying &&
        _listEquals(other.preferredPositions, preferredPositions) &&
        _listEquals(other.certifications, certifications) &&
        _listEquals(other.achievements, achievements) &&
        other.isPrimarySport == isPrimarySport &&
        other.lastPlayed == lastPlayed &&
        other.gamesPlayed == gamesPlayed &&
        other.averageRating == averageRating;
  }

  @override
  int get hashCode {
    return Object.hash(
      sportId,
      sportName,
      skillLevel,
      yearsPlaying,
      Object.hashAll(preferredPositions),
      Object.hashAll(certifications),
      Object.hashAll(achievements),
      isPrimarySport,
      lastPlayed,
      gamesPlayed,
      averageRating,
    );
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
