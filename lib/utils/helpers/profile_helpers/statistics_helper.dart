/// Helper class for calculating and formatting profile statistics
library;
import 'dart:math';

/// Temporary model class for profile statistics
class ProfileStatistics {
  final int totalGamesPlayed;
  final int totalWins;
  final int totalLosses;
  final int totalGamesOrganized;
  final double totalHoursPlayed;
  final int currentStreak;
  final int longestStreak;
  final double reliabilityRating;
  final double sportsmanshipRating;
  final double overallRating;
  final int totalFriends;
  final int totalAchievements;
  final DateTime? firstGameDate;
  final DateTime? lastGameDate;
  final Map<String, int> sportBreakdown;
  final Map<String, double> monthlyHours;
  
  const ProfileStatistics({
    this.totalGamesPlayed = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalGamesOrganized = 0,
    this.totalHoursPlayed = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.reliabilityRating = 0.0,
    this.sportsmanshipRating = 0.0,
    this.overallRating = 0.0,
    this.totalFriends = 0,
    this.totalAchievements = 0,
    this.firstGameDate,
    this.lastGameDate,
    this.sportBreakdown = const {},
    this.monthlyHours = const {},
  });
}

/// Helper class for calculating and formatting profile statistics
class StatisticsHelper {
  /// Calculate win rate as a percentage
  static double calculateWinRate(ProfileStatistics stats) {
    final totalGames = stats.totalWins + stats.totalLosses;
    if (totalGames == 0) return 0.0;
    return (stats.totalWins / totalGames) * 100;
  }

  /// Calculate win rate with draws included
  static double calculateWinRateWithDraws(ProfileStatistics stats) {
    if (stats.totalGamesPlayed == 0) return 0.0;
    return (stats.totalWins / stats.totalGamesPlayed) * 100;
  }

  /// Format play time in a human-readable way
  static String formatPlayTime(double totalHours) {
    if (totalHours < 1) {
      final minutes = (totalHours * 60).round();
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    } else if (totalHours < 24) {
      final hours = totalHours.round();
      return hours == 1 ? '1 hour' : '$hours hours';
    } else {
      final days = (totalHours / 24).round();
      return days == 1 ? '1 day' : '$days days';
    }
  }

  /// Format play time with more detailed breakdown
  static String formatDetailedPlayTime(double totalHours) {
    if (totalHours < 1) {
      return formatPlayTime(totalHours);
    }
    
    final days = (totalHours / 24).floor();
    final remainingHours = totalHours - (days * 24);
    final hours = remainingHours.floor();
    final minutes = ((remainingHours - hours) * 60).round();
    
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 && days == 0) parts.add('${minutes}m');
    
    return parts.isEmpty ? '0m' : parts.join(' ');
  }

  /// Get list of earned achievements based on statistics
  static List<String> getAchievements(ProfileStatistics stats) {
    final achievements = <String>[];
    
    // Game count achievements
    if (stats.totalGamesPlayed >= 1) achievements.add('First Game');
    if (stats.totalGamesPlayed >= 10) achievements.add('Getting Started');
    if (stats.totalGamesPlayed >= 50) achievements.add('Regular Player');
    if (stats.totalGamesPlayed >= 100) achievements.add('Century Player');
    if (stats.totalGamesPlayed >= 500) achievements.add('Dedicated Player');
    if (stats.totalGamesPlayed >= 1000) achievements.add('Game Legend');
    
    // Organization achievements
    if (stats.totalGamesOrganized >= 1) achievements.add('First Organizer');
    if (stats.totalGamesOrganized >= 10) achievements.add('Event Coordinator');
    if (stats.totalGamesOrganized >= 50) achievements.add('Game Master');
    if (stats.totalGamesOrganized >= 100) achievements.add('Community Leader');
    
    // Streak achievements
    if (stats.currentStreak >= 3) achievements.add('Hot Streak');
    if (stats.currentStreak >= 5) achievements.add('On Fire');
    if (stats.currentStreak >= 10) achievements.add('Unstoppable');
    if (stats.longestStreak >= 15) achievements.add('Streak Master');
    
    // Rating achievements
    if (stats.reliabilityRating >= 4.0) achievements.add('Reliable');
    if (stats.reliabilityRating >= 4.5) achievements.add('Very Reliable');
    if (stats.reliabilityRating >= 4.8) achievements.add('Extremely Reliable');
    if (stats.sportsmanshipRating >= 4.0) achievements.add('Good Sport');
    if (stats.sportsmanshipRating >= 4.5) achievements.add('Great Sport');
    if (stats.sportsmanshipRating >= 4.8) achievements.add('Exemplary Sport');
    
    // Win rate achievements
    final winRate = calculateWinRate(stats);
    if (winRate >= 60 && stats.totalGamesPlayed >= 20) achievements.add('Winner');
    if (winRate >= 75 && stats.totalGamesPlayed >= 50) achievements.add('Champion');
    if (winRate >= 85 && stats.totalGamesPlayed >= 100) achievements.add('Dominator');
    
    // Time-based achievements
    if (stats.totalHoursPlayed >= 10) achievements.add('10 Hour Club');
    if (stats.totalHoursPlayed >= 50) achievements.add('50 Hour Club');
    if (stats.totalHoursPlayed >= 100) achievements.add('Century Hours');
    if (stats.totalHoursPlayed >= 500) achievements.add('Time Warrior');
    
    // Social achievements
    if (stats.totalFriends >= 10) achievements.add('Social Player');
    if (stats.totalFriends >= 50) achievements.add('Popular Player');
    if (stats.totalFriends >= 100) achievements.add('Community Connector');
    
    // Time period achievements
    if (stats.firstGameDate != null && stats.lastGameDate != null) {
      final daysSinceFirst = DateTime.now().difference(stats.firstGameDate!).inDays;
      if (daysSinceFirst >= 30) achievements.add('One Month Active');
      if (daysSinceFirst >= 365) achievements.add('One Year Strong');
      if (daysSinceFirst >= 365 * 2) achievements.add('Two Year Veteran');
    }
    
    return achievements;
  }

  /// Get a concise statistics summary
  static Map<String, dynamic> getStatsSummary(ProfileStatistics stats) {
    return {
      'games_played': stats.totalGamesPlayed,
      'win_rate': calculateWinRate(stats).round(),
      'hours_played': stats.totalHoursPlayed.round(),
      'reliability_rating': stats.reliabilityRating,
      'sportsmanship_rating': stats.sportsmanshipRating,
      'current_streak': stats.currentStreak,
      'games_organized': stats.totalGamesOrganized,
    };
  }

  /// Get detailed statistics breakdown
  static Map<String, dynamic> getDetailedStats(ProfileStatistics stats) {
    final winRate = calculateWinRate(stats);
    final totalGames = stats.totalWins + stats.totalLosses;
    final draws = stats.totalGamesPlayed - totalGames;
    
    return {
      'games': {
        'total_played': stats.totalGamesPlayed,
        'wins': stats.totalWins,
        'losses': stats.totalLosses,
        'draws': draws,
        'organized': stats.totalGamesOrganized,
      },
      'performance': {
        'win_rate': winRate,
        'current_streak': stats.currentStreak,
        'longest_streak': stats.longestStreak,
        'total_hours': stats.totalHoursPlayed,
        'average_game_duration': _calculateAverageGameDuration(stats),
      },
      'ratings': {
        'reliability': stats.reliabilityRating,
        'sportsmanship': stats.sportsmanshipRating,
        'overall': stats.overallRating,
      },
      'social': {
        'friends': stats.totalFriends,
        'achievements': getAchievements(stats).length,
      },
      'activity': {
        'first_game': stats.firstGameDate?.toIso8601String(),
        'last_game': stats.lastGameDate?.toIso8601String(),
        'days_active': _calculateDaysActive(stats),
      },
    };
  }

  /// Get performance trends and insights
  static Map<String, dynamic> getPerformanceInsights(ProfileStatistics stats) {
    final insights = <String, dynamic>{};
    final winRate = calculateWinRate(stats);
    
    // Performance level
    if (stats.totalGamesPlayed < 5) {
      insights['level'] = 'newcomer';
      insights['message'] = 'Play more games to establish your performance level';
    } else if (winRate >= 70) {
      insights['level'] = 'excellent';
      insights['message'] = 'Outstanding performance! You\'re a strong player';
    } else if (winRate >= 55) {
      insights['level'] = 'good';
      insights['message'] = 'Good performance, keep up the momentum';
    } else if (winRate >= 40) {
      insights['level'] = 'average';
      insights['message'] = 'Room for improvement, consider practicing more';
    } else {
      insights['level'] = 'developing';
      insights['message'] = 'Focus on fundamentals to improve your game';
    }
    
    // Activity insights
    if (stats.totalHoursPlayed > 0 && stats.totalGamesPlayed > 0) {
      final avgHoursPerGame = stats.totalHoursPlayed / stats.totalGamesPlayed;
      insights['avg_game_duration'] = formatPlayTime(avgHoursPerGame);
      
      if (avgHoursPerGame > 3) {
        insights['duration_note'] = 'You enjoy longer games';
      } else if (avgHoursPerGame < 1) {
        insights['duration_note'] = 'You prefer quick games';
      }
    }
    
    // Streak insights
    if (stats.currentStreak > 0) {
      insights['streak_status'] = 'active';
      insights['streak_message'] = 'You\'re on a ${stats.currentStreak}-game streak!';
    } else if (stats.longestStreak >= 5) {
      insights['streak_status'] = 'potential';
      insights['streak_message'] = 'Your best streak was ${stats.longestStreak} games';
    }
    
    // Social insights
    if (stats.totalFriends >= 20) {
      insights['social_level'] = 'very_social';
    } else if (stats.totalFriends >= 5) {
      insights['social_level'] = 'social';
    } else {
      insights['social_level'] = 'growing';
      insights['social_message'] = 'Connect with more players to expand your network';
    }
    
    return insights;
  }

  /// Get comparative statistics (percentiles)
  static Map<String, dynamic> getComparativeStats(
    ProfileStatistics userStats,
    ProfileStatistics communityAverages,
  ) {
    return {
      'games_played_percentile': _calculatePercentile(
        userStats.totalGamesPlayed.toDouble(),
        communityAverages.totalGamesPlayed.toDouble(),
      ),
      'win_rate_percentile': _calculatePercentile(
        calculateWinRate(userStats),
        calculateWinRate(communityAverages),
      ),
      'hours_played_percentile': _calculatePercentile(
        userStats.totalHoursPlayed,
        communityAverages.totalHoursPlayed,
      ),
      'reliability_percentile': _calculatePercentile(
        userStats.reliabilityRating,
        communityAverages.reliabilityRating,
      ),
      'organization_percentile': _calculatePercentile(
        userStats.totalGamesOrganized.toDouble(),
        communityAverages.totalGamesOrganized.toDouble(),
      ),
    };
  }

  /// Private helper methods
  static double _calculateAverageGameDuration(ProfileStatistics stats) {
    if (stats.totalGamesPlayed == 0) return 0.0;
    return stats.totalHoursPlayed / stats.totalGamesPlayed;
  }

  static int _calculateDaysActive(ProfileStatistics stats) {
    if (stats.firstGameDate == null || stats.lastGameDate == null) return 0;
    return stats.lastGameDate!.difference(stats.firstGameDate!).inDays + 1;
  }

  static double _calculatePercentile(double userValue, double averageValue) {
    if (averageValue == 0) return 50.0;
    
    // Simple percentile calculation - this could be enhanced with actual distribution data
    final ratio = userValue / averageValue;
    if (ratio >= 2.0) return 95.0;
    if (ratio >= 1.5) return 85.0;
    if (ratio >= 1.2) return 75.0;
    if (ratio >= 1.1) return 65.0;
    if (ratio >= 0.9) return 50.0;
    if (ratio >= 0.8) return 35.0;
    if (ratio >= 0.6) return 25.0;
    if (ratio >= 0.4) return 15.0;
    return 5.0;
  }

  /// Get monthly activity trends
  static Map<String, dynamic> getMonthlyTrends(ProfileStatistics stats) {
    final trends = <String, dynamic>{};
    
    if (stats.monthlyHours.isNotEmpty) {
      final months = stats.monthlyHours.keys.toList()..sort();
      final hours = months.map((month) => stats.monthlyHours[month] ?? 0.0).toList();
      
      trends['months'] = months;
      trends['hours'] = hours;
      trends['peak_month'] = _findPeakMonth(stats.monthlyHours);
      trends['average_monthly_hours'] = hours.fold<double>(0.0, (sum, h) => sum + h) / hours.length;
      trends['trend_direction'] = _calculateTrendDirection(hours);
    }
    
    return trends;
  }

  static String _findPeakMonth(Map<String, double> monthlyHours) {
    if (monthlyHours.isEmpty) return '';
    
    return monthlyHours.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  static String _calculateTrendDirection(List<double> values) {
    if (values.length < 2) return 'stable';
    
    final recent = values.sublist(max(0, values.length - 3));
    final earlier = values.sublist(0, min(values.length, 3));
    
    final recentAvg = recent.fold<double>(0.0, (sum, v) => sum + v) / recent.length;
    final earlierAvg = earlier.fold<double>(0.0, (sum, v) => sum + v) / earlier.length;
    
    if (recentAvg > earlierAvg * 1.2) return 'increasing';
    if (recentAvg < earlierAvg * 0.8) return 'decreasing';
    return 'stable';
  }
}
