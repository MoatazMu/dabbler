/// User statistics for leaderboards and achievements
class UserStats {
  final String userId;
  final double totalPoints;
  final int totalAchievements;
  final int completedChallenges;
  final int streakDays;
  final double averageScore;
  final Map<String, int> categoryStats;
  final Map<String, dynamic> gameStats;
  final DateTime lastActivity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserStats({
    required this.userId,
    required this.totalPoints,
    required this.totalAchievements,
    required this.completedChallenges,
    required this.streakDays,
    required this.averageScore,
    this.categoryStats = const {},
    this.gameStats = const {},
    required this.lastActivity,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether user has been active recently
  bool get isActiveUser {
    final now = DateTime.now();
    return now.difference(lastActivity).inDays <= 7;
  }

  /// Whether user is a high performer
  bool get isHighPerformer => averageScore >= 75.0;

  /// Whether user has a long streak
  bool get hasLongStreak => streakDays >= 7;

  /// Gets stats for a specific category
  int getCategoryStats(String category) {
    return categoryStats[category] ?? 0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'total_achievements': totalAchievements,
      'completed_challenges': completedChallenges,
      'streak_days': streakDays,
      'average_score': averageScore,
      'category_stats': categoryStats,
      'game_stats': gameStats,
      'last_activity': lastActivity.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] as String,
      totalPoints: (json['total_points'] as num?)?.toDouble() ?? 0.0,
      totalAchievements: json['total_achievements'] as int? ?? 0,
      completedChallenges: json['completed_challenges'] as int? ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      categoryStats: Map<String, int>.from(json['category_stats'] as Map? ?? {}),
      gameStats: json['game_stats'] as Map<String, dynamic>? ?? {},
      lastActivity: DateTime.parse(json['last_activity'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Create a copy with modifications
  UserStats copyWith({
    String? userId,
    double? totalPoints,
    int? totalAchievements,
    int? completedChallenges,
    int? streakDays,
    double? averageScore,
    Map<String, int>? categoryStats,
    Map<String, dynamic>? gameStats,
    DateTime? lastActivity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      streakDays: streakDays ?? this.streakDays,
      averageScore: averageScore ?? this.averageScore,
      categoryStats: categoryStats ?? this.categoryStats,
      gameStats: gameStats ?? this.gameStats,
      lastActivity: lastActivity ?? this.lastActivity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStats && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}