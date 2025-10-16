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
  factory SportProfile.fromJson(Map<String, dynamic> json) {
    return SportProfile(
      sportId: json['sportId'] as String,
      sportName: json['sportName'] as String,
      skillLevel: SkillLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['skillLevel'],
        orElse: () => SkillLevel.beginner,
      ),
      yearsPlaying: json['yearsPlaying'] as int? ?? 0,
      preferredPositions: List<String>.from(json['preferredPositions'] as List? ?? []),
      certifications: List<String>.from(json['certifications'] as List? ?? []),
      achievements: List<String>.from(json['achievements'] as List? ?? []),
      isPrimarySport: json['isPrimarySport'] as bool? ?? false,
      lastPlayed: json['lastPlayed'] != null 
          ? DateTime.parse(json['lastPlayed'] as String)
          : null,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
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
