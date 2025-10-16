/// Extension methods for ProfileStatistics to add formatting and analysis functionality
library;
import 'dart:ui';

/// Temporary model class for profile statistics
class ProfileStatistics {
  final int totalGames;
  final int gamesWon;
  final int gamesLost;
  final double averageRating;
  final int totalPlayTime; // in minutes
  final int profileViews;
  final int friendsCount;
  final int achievementsUnlocked;
  final int skillBadges;
  final DateTime lastActive;
  final Map<String, int> sportSpecificStats;
  final Map<String, double> skillRatings;
  final List<String> recentAchievements;
  final int streakDays;
  final double improvementRate;
  final int mentorshipSessions;
  final int eventsAttended;
  
  ProfileStatistics({
    this.totalGames = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.averageRating = 0.0,
    this.totalPlayTime = 0,
    this.profileViews = 0,
    this.friendsCount = 0,
    this.achievementsUnlocked = 0,
    this.skillBadges = 0,
    DateTime? lastActive,
    this.sportSpecificStats = const {},
    this.skillRatings = const {},
    this.recentAchievements = const [],
    this.streakDays = 0,
    this.improvementRate = 0.0,
    this.mentorshipSessions = 0,
    this.eventsAttended = 0,
  }) : lastActive = lastActive ?? DateTime.now();
}

/// Extension methods for ProfileStatistics entity
extension ProfileStatisticsExtensions on ProfileStatistics {
  /// Calculate win rate percentage
  double get winRate => totalGames > 0 ? (gamesWon / totalGames) * 100 : 0.0;
  
  /// Calculate loss rate percentage
  double get lossRate => totalGames > 0 ? (gamesLost / totalGames) * 100 : 0.0;
  
  /// Format win rate as string with percentage
  String get winRateFormatted => '${winRate.toStringAsFixed(1)}%';
  
  /// Format average rating with star display
  String get ratingFormatted => '${averageRating.toStringAsFixed(1)}★';
  
  /// Get rating as integer (for star displays)
  int get ratingStars => averageRating.round().clamp(0, 5);
  
  /// Get color for rating display
  Color get ratingColor {
    if (averageRating >= 4.5) return const Color(0xFF4CAF50); // Green
    if (averageRating >= 3.5) return const Color(0xFF2196F3); // Blue
    if (averageRating >= 2.5) return const Color(0xFFFF9800); // Orange
    if (averageRating >= 1.5) return const Color(0xFFFF5722); // Deep Orange
    return const Color(0xFFF44336); // Red
  }
  
  /// Format play time in human readable format
  String get playTimeFormatted {
    if (totalPlayTime < 60) return '${totalPlayTime}m';
    
    final hours = totalPlayTime ~/ 60;
    final minutes = totalPlayTime % 60;
    
    if (hours < 24) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    
    if (days < 7) {
      return remainingHours > 0 ? '${days}d ${remainingHours}h' : '${days}d';
    }
    
    final weeks = days ~/ 7;
    return '${weeks}w';
  }
  
  /// Get activity status based on last active time
  String get activityStatus {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inMinutes < 5) return 'online';
    if (difference.inHours < 1) return 'recently_active';
    if (difference.inDays < 1) return 'today';
    if (difference.inDays < 7) return 'this_week';
    if (difference.inDays < 30) return 'this_month';
    return 'inactive';
  }
  
  /// Get color for activity status
  Color get activityColor {
    switch (activityStatus) {
      case 'online': return const Color(0xFF4CAF50); // Green
      case 'recently_active': return const Color(0xFF8BC34A); // Light Green
      case 'today': return const Color(0xFF2196F3); // Blue
      case 'this_week': return const Color(0xFF03A9F4); // Light Blue
      case 'this_month': return const Color(0xFFFF9800); // Orange
      case 'inactive': return const Color(0xFF9E9E9E); // Grey
      default: return const Color(0xFF9E9E9E);
    }
  }
  
  /// Format last active time
  String get lastActiveFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo ago';
    return '${(difference.inDays / 365).floor()}y ago';
  }
  
  /// Check if user is currently active (within 30 minutes)
  bool get isCurrentlyActive => DateTime.now().difference(lastActive).inMinutes <= 30;
  
  /// Check if user is a regular player (plays frequently)
  bool get isRegularPlayer => totalGames >= 50 || streakDays >= 7;
  
  /// Check if user is experienced (high stats)
  bool get isExperienced => 
      totalGames >= 100 || averageRating >= 4.0 || achievementsUnlocked >= 20;
  
  /// Check if user is a mentor (helps others)
  bool get isMentor => mentorshipSessions >= 5 || averageRating >= 4.5;
  
  /// Check if user is social (has many connections)
  bool get isSocialPlayer => friendsCount >= 25 || eventsAttended >= 10;
  
  /// Get performance level
  String get performanceLevel {
    if (averageRating >= 4.5) return 'expert';
    if (averageRating >= 4.0) return 'advanced';
    if (averageRating >= 3.0) return 'intermediate';
    if (averageRating >= 2.0) return 'beginner';
    return 'new';
  }
  
  /// Get engagement level
  String get engagementLevel {
    int engagementScore = 0;
    
    if (totalGames >= 100) {
      engagementScore += 25;
    } else if (totalGames >= 50) engagementScore += 15;
    else if (totalGames >= 10) engagementScore += 5;
    
    if (streakDays >= 30) {
      engagementScore += 25;
    } else if (streakDays >= 14) engagementScore += 15;
    else if (streakDays >= 7) engagementScore += 10;
    else if (streakDays >= 3) engagementScore += 5;
    
    if (friendsCount >= 50) {
      engagementScore += 20;
    } else if (friendsCount >= 20) engagementScore += 10;
    else if (friendsCount >= 5) engagementScore += 5;
    
    if (eventsAttended >= 20) {
      engagementScore += 15;
    } else if (eventsAttended >= 10) engagementScore += 10;
    else if (eventsAttended >= 5) engagementScore += 5;
    
    if (mentorshipSessions >= 10) {
      engagementScore += 15;
    } else if (mentorshipSessions >= 5) engagementScore += 10;
    
    if (engagementScore >= 80) return 'very_high';
    if (engagementScore >= 60) return 'high';
    if (engagementScore >= 40) return 'medium';
    if (engagementScore >= 20) return 'low';
    return 'very_low';
  }
  
  /// Get most played sport
  String? get mostPlayedSport {
    if (sportSpecificStats.isEmpty) return null;
    
    String? topSport;
    int maxGames = 0;
    
    for (final entry in sportSpecificStats.entries) {
      if (entry.value > maxGames) {
        maxGames = entry.value;
        topSport = entry.key;
      }
    }
    
    return topSport;
  }
  
  /// Get best skill rating
  double get bestSkillRating {
    if (skillRatings.isEmpty) return 0.0;
    return skillRatings.values.reduce((a, b) => a > b ? a : b);
  }
  
  /// Get best skill sport
  String? get bestSkillSport {
    if (skillRatings.isEmpty) return null;
    
    String? bestSport;
    double bestRating = 0.0;
    
    for (final entry in skillRatings.entries) {
      if (entry.value > bestRating) {
        bestRating = entry.value;
        bestSport = entry.key;
      }
    }
    
    return bestSport;
  }
  
  /// Get improvement trend
  String get improvementTrend {
    if (improvementRate >= 0.1) return 'rapidly_improving';
    if (improvementRate >= 0.05) return 'improving';
    if (improvementRate >= -0.05) return 'stable';
    if (improvementRate >= -0.1) return 'declining';
    return 'rapidly_declining';
  }
  
  /// Get improvement color
  Color get improvementColor {
    switch (improvementTrend) {
      case 'rapidly_improving': return const Color(0xFF4CAF50); // Green
      case 'improving': return const Color(0xFF8BC34A); // Light Green
      case 'stable': return const Color(0xFF2196F3); // Blue
      case 'declining': return const Color(0xFFFF9800); // Orange
      case 'rapidly_declining': return const Color(0xFFF44336); // Red
      default: return const Color(0xFF9E9E9E);
    }
  }
  
  /// Format improvement rate
  String get improvementRateFormatted {
    final percentage = (improvementRate * 100).abs();
    final sign = improvementRate >= 0 ? '+' : '-';
    return '$sign${percentage.toStringAsFixed(1)}%';
  }
  
  /// Get streak display text
  String get streakDisplayText {
    if (streakDays == 0) return 'No streak';
    if (streakDays == 1) return '1 day streak';
    if (streakDays < 7) return '$streakDays days streak';
    if (streakDays < 30) return '${(streakDays / 7).floor()}w streak';
    return '${(streakDays / 30).floor()}mo streak';
  }
  
  /// Get achievement rate (achievements per game)
  double get achievementRate => 
      totalGames > 0 ? achievementsUnlocked / totalGames : 0.0;
  
  /// Format achievement rate
  String get achievementRateFormatted => 
      '${(achievementRate * 100).toStringAsFixed(1)}%';
  
  /// Get profile popularity (views per friend ratio)
  double get profilePopularity => 
      friendsCount > 0 ? profileViews / friendsCount : profileViews.toDouble();
  
  /// Check if profile is trending (high recent views)
  bool get isTrending => profileViews >= 100; // Simplified logic
  
  /// Get comprehensive performance summary
  Map<String, dynamic> get performanceSummary {
    return {
      'level': performanceLevel,
      'win_rate': winRateFormatted,
      'rating': ratingFormatted,
      'play_time': playTimeFormatted,
      'improvement': improvementTrend,
      'streak': streakDisplayText,
      'most_played_sport': mostPlayedSport,
      'best_skill_sport': bestSkillSport,
      'achievement_rate': achievementRateFormatted,
    };
  }
  
  /// Get social statistics summary
  Map<String, dynamic> get socialSummary {
    return {
      'friends': friendsCount,
      'profile_views': profileViews,
      'events_attended': eventsAttended,
      'mentorship_sessions': mentorshipSessions,
      'engagement_level': engagementLevel,
      'is_mentor': isMentor,
      'is_social': isSocialPlayer,
      'profile_popularity': profilePopularity.toStringAsFixed(1),
    };
  }
  
  /// Get activity summary
  Map<String, dynamic> get activitySummary {
    return {
      'status': activityStatus,
      'last_active': lastActiveFormatted,
      'is_currently_active': isCurrentlyActive,
      'streak_days': streakDays,
      'total_games': totalGames,
      'is_regular_player': isRegularPlayer,
      'play_time_formatted': playTimeFormatted,
    };
  }
  
  /// Get achievements summary
  Map<String, dynamic> get achievementsSummary {
    return {
      'total': achievementsUnlocked,
      'skill_badges': skillBadges,
      'recent': recentAchievements.take(3).toList(),
      'achievement_rate': achievementRateFormatted,
      'recent_count': recentAchievements.length,
    };
  }
  
  /// Convert statistics to analytics data
  Map<String, dynamic> toAnalytics() {
    return {
      'total_games': totalGames,
      'win_rate': winRate,
      'average_rating': averageRating,
      'play_time_minutes': totalPlayTime,
      'profile_views': profileViews,
      'friends_count': friendsCount,
      'achievements': achievementsUnlocked,
      'streak_days': streakDays,
      'improvement_rate': improvementRate,
      'performance_level': performanceLevel,
      'engagement_level': engagementLevel,
      'activity_status': activityStatus,
      'is_mentor': isMentor,
      'is_social': isSocialPlayer,
      'most_played_sport': mostPlayedSport,
      'best_skill_rating': bestSkillRating,
      'mentorship_sessions': mentorshipSessions,
      'events_attended': eventsAttended,
    };
  }
  
  /// Generate comparison data for profile matching
  Map<String, dynamic> getComparisonData() {
    return {
      'skill_level': performanceLevel,
      'activity_level': engagementLevel,
      'experience_games': totalGames,
      'rating_range': _getRatingRange(),
      'play_frequency': _getPlayFrequency(),
      'social_level': isSocialPlayer ? 'high' : 'normal',
      'mentor_status': isMentor,
      'sports_played': sportSpecificStats.keys.toList(),
      'skill_ratings': skillRatings,
    };
  }
  
  /// Get goals and recommendations
  List<String> get recommendations {
    final suggestions = <String>[];
    
    if (winRate < 30) {
      suggestions.add('Focus on improving game strategy and skills');
    }
    
    if (averageRating < 3.0) {
      suggestions.add('Consider taking lessons or finding a mentor');
    }
    
    if (streakDays == 0) {
      suggestions.add('Try to play consistently to build a streak');
    }
    
    if (friendsCount < 5) {
      suggestions.add('Connect with more players to expand your network');
    }
    
    if (eventsAttended < 5) {
      suggestions.add('Participate in more events to gain experience');
    }
    
    if (achievementsUnlocked < totalGames * 0.1) {
      suggestions.add('Explore different achievements to unlock rewards');
    }
    
    if (improvementRate < 0) {
      suggestions.add('Review your recent games to identify areas for improvement');
    }
    
    if (mentorshipSessions == 0 && averageRating >= 3.5) {
      suggestions.add('Consider mentoring newer players to give back to the community');
    }
    
    return suggestions;
  }
  
  /// Private helper to get rating range for matching
  String _getRatingRange() {
    if (averageRating >= 4.5) return '4.5-5.0';
    if (averageRating >= 4.0) return '4.0-4.5';
    if (averageRating >= 3.5) return '3.5-4.0';
    if (averageRating >= 3.0) return '3.0-3.5';
    if (averageRating >= 2.5) return '2.5-3.0';
    if (averageRating >= 2.0) return '2.0-2.5';
    return '0.0-2.0';
  }
  
  /// Private helper to get play frequency
  String _getPlayFrequency() {
    if (streakDays >= 30) return 'daily';
    if (streakDays >= 14) return 'frequent';
    if (streakDays >= 7) return 'weekly';
    if (totalGames >= 50) return 'regular';
    if (totalGames >= 10) return 'occasional';
    return 'infrequent';
  }
  
  /// Generate achievements progress report
  Map<String, dynamic> get achievementProgress {
    return {
      'unlocked': achievementsUnlocked,
      'skill_badges': skillBadges,
      'recent': recentAchievements,
      'games_milestone': _getGamesProgress(),
      'rating_milestone': _getRatingProgress(),
      'social_milestone': _getSocialProgress(),
      'streak_milestone': _getStreakProgress(),
    };
  }
  
  /// Private helpers for achievement progress
  Map<String, dynamic> _getGamesProgress() {
    final milestones = [10, 25, 50, 100, 250, 500, 1000];
    final nextMilestone = milestones.firstWhere(
      (m) => m > totalGames,
      orElse: () => milestones.last,
    );
    
    return {
      'current': totalGames,
      'next_milestone': nextMilestone,
      'progress': totalGames / nextMilestone,
      'remaining': nextMilestone - totalGames,
    };
  }
  
  Map<String, dynamic> _getRatingProgress() {
    final ratingMilestones = [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];
    final nextMilestone = ratingMilestones.firstWhere(
      (m) => m > averageRating,
      orElse: () => 5.0,
    );
    
    return {
      'current': averageRating,
      'next_milestone': nextMilestone,
      'progress': averageRating / nextMilestone,
      'improvement_needed': (nextMilestone - averageRating).toStringAsFixed(1),
    };
  }
  
  Map<String, dynamic> _getSocialProgress() {
    final socialMilestones = [5, 10, 25, 50, 100];
    final nextMilestone = socialMilestones.firstWhere(
      (m) => m > friendsCount,
      orElse: () => socialMilestones.last,
    );
    
    return {
      'current_friends': friendsCount,
      'next_milestone': nextMilestone,
      'events_attended': eventsAttended,
      'mentorship_sessions': mentorshipSessions,
    };
  }
  
  Map<String, dynamic> _getStreakProgress() {
    final streakMilestones = [3, 7, 14, 30, 60, 100];
    final nextMilestone = streakMilestones.firstWhere(
      (m) => m > streakDays,
      orElse: () => streakMilestones.last,
    );
    
    return {
      'current': streakDays,
      'next_milestone': nextMilestone,
      'days_remaining': nextMilestone - streakDays,
      'display_text': streakDisplayText,
    };
  }
}
