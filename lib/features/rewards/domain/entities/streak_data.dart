/// Streak data entity representing user streak information
class StreakData {
  final String userId;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime lastActiveDate;
  final DateTime streakStartDate;
  final bool isActive;
  final String category; // e.g., 'daily_login', 'game_completion'

  const StreakData({
    required this.userId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastActiveDate,
    required this.streakStartDate,
    required this.isActive,
    required this.category,
  });

  /// Check if streak is in grace period (user has some time to maintain it)
  bool get isInGracePeriod {
    final now = DateTime.now();
    final daysSinceLastActive = now.difference(lastActiveDate).inDays;
    return daysSinceLastActive <= 1 && isActive;
  }

  /// Check if streak is broken
  bool get isBroken {
    final now = DateTime.now();
    final daysSinceLastActive = now.difference(lastActiveDate).inDays;
    return daysSinceLastActive > 1 || !isActive;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreakData &&
        other.userId == userId &&
        other.currentStreakDays == currentStreakDays &&
        other.longestStreakDays == longestStreakDays &&
        other.lastActiveDate == lastActiveDate &&
        other.streakStartDate == streakStartDate &&
        other.isActive == isActive &&
        other.category == category;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      currentStreakDays,
      longestStreakDays,
      lastActiveDate,
      streakStartDate,
      isActive,
      category,
    );
  }

  @override
  String toString() {
    return 'StreakData('
        'userId: $userId, '
        'currentStreakDays: $currentStreakDays, '
        'longestStreakDays: $longestStreakDays, '
        'lastActiveDate: $lastActiveDate, '
        'streakStartDate: $streakStartDate, '
        'isActive: $isActive, '
        'category: $category'
        ')';
  }
}