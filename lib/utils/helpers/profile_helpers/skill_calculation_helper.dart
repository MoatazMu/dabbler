/// Helper class for calculating and managing skill-related operations
library;
import 'dart:math';
import '../../enums/profile_enums.dart';
import '../../enums/skill_level_enums.dart';

/// Temporary model classes for skill calculations
/// TODO: Replace with actual models from features/profile/data/models/
class SportProfile {
  final String sport;
  final int skillLevel;
  final int yearsPlaying;
  final bool isPrimarySport;
  final SportCategory category;
  final double? currentRating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  
  const SportProfile({
    required this.sport,
    required this.skillLevel,
    required this.yearsPlaying,
    this.isPrimarySport = false,
    required this.category,
    this.currentRating,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
  });
}

/// Helper class for calculating and managing skill-related operations
class SkillCalculationHelper {
  /// Calculate the overall skill level across all sports profiles
  static double calculateOverallSkill(List<SportProfile> sports) {
    if (sports.isEmpty) return 0.0;
    
    final totalSkill = sports.fold<int>(
      0, 
      (sum, sport) => sum + sport.skillLevel
    );
    
    return totalSkill / sports.length;
  }

  /// Calculate weighted overall skill (primary sport has more weight)
  static double calculateWeightedOverallSkill(List<SportProfile> sports) {
    if (sports.isEmpty) return 0.0;
    
    double totalWeightedSkill = 0.0;
    double totalWeight = 0.0;
    
    for (final sport in sports) {
      final weight = sport.isPrimarySport ? 2.0 : 1.0; // Primary sport gets 2x weight
      totalWeightedSkill += sport.skillLevel * weight;
      totalWeight += weight;
    }
    
    return totalWeight > 0 ? totalWeightedSkill / totalWeight : 0.0;
  }

  /// Get the primary sport profile (first one marked as primary or first in list)
  static SportProfile? getPrimarySport(List<SportProfile> sports) {
    try {
      return sports.firstWhere((sport) => sport.isPrimarySport);
    } catch (_) {
      return sports.isNotEmpty ? sports.first : null;
    }
  }

  /// Get top N sports by skill level
  static List<SportProfile> getTopSportsBySkill(
    List<SportProfile> sports, {
    int limit = 3,
  }) {
    final sortedSports = List<SportProfile>.from(sports);
    sortedSports.sort((a, b) => b.skillLevel.compareTo(a.skillLevel));
    return sortedSports.take(limit).toList();
  }

  /// Group sports by category for organization
  static Map<SportCategory, List<SportProfile>> groupByCategory(
    List<SportProfile> sports
  ) {
    return sports.fold<Map<SportCategory, List<SportProfile>>>({}, (map, sport) {
      final category = sport.category;
      map[category] = [...(map[category] ?? []), sport];
      return map;
    });
  }

  /// Get skill description combining level and experience
  static String getSkillDescription(int skillLevel, int yearsPlaying) {
    final skillLevelEnum = SkillLevel.fromValue(skillLevel);
    final baseDescription = skillLevelEnum.name;
    
    if (yearsPlaying < 1) return '$baseDescription (Just started)';
    if (yearsPlaying == 1) return '$baseDescription (1 year experience)';
    return '$baseDescription ($yearsPlaying years experience)';
  }

  /// Get detailed skill breakdown with recommendations
  static Map<String, dynamic> getSkillBreakdown(SportProfile sport) {
    final skillEnum = SkillLevel.fromValue(sport.skillLevel);
    
    return {
      'sport': sport.sport,
      'skill_level': sport.skillLevel,
      'skill_name': skillEnum.name,
      'skill_description': skillEnum.description,
      'years_playing': sport.yearsPlaying,
      'is_primary': sport.isPrimarySport,
      'category': sport.category.displayName,
      'experience_level': _getExperienceLevel(sport.yearsPlaying),
      'skill_color': skillEnum.color.value,
      'next_level': skillEnum.next?.name,
      'recommendations': _getSkillRecommendations(sport),
    };
  }

  /// Calculate skill trajectory (improvement over time)
  static double calculateSkillTrajectory(SportProfile sport) {
    if (sport.yearsPlaying <= 0) return 0.0;
    
    // Simple calculation: skill level per year of experience
    // This could be enhanced with historical data
    return sport.skillLevel / sport.yearsPlaying;
  }

  /// Get skill level recommendations for improvement
  static List<String> getSkillImprovementSuggestions(SportProfile sport) {
    final skillEnum = SkillLevel.fromValue(sport.skillLevel);
    final suggestions = <String>[];
    
    // Base suggestions from skill level enum
    suggestions.addAll(skillEnum.trainingFocus);
    
    // Experience-based suggestions
    if (sport.yearsPlaying < 1) {
      suggestions.add('Focus on basic rules and safety');
      suggestions.add('Practice with more experienced players');
    } else if (sport.yearsPlaying < 3) {
      suggestions.add('Join a local club or team');
      suggestions.add('Consider taking lessons from a coach');
    } else if (sport.yearsPlaying >= 5) {
      suggestions.add('Consider mentoring newer players');
      suggestions.add('Try competitive tournaments');
    }
    
    // Performance-based suggestions
    if (sport.gamesPlayed > 0) {
      final winRate = sport.wins / sport.gamesPlayed;
      if (winRate < 0.3) {
        suggestions.add('Focus on fundamentals and consistency');
      } else if (winRate > 0.7) {
        suggestions.add('Challenge yourself with higher-level opponents');
      }
    }
    
    return suggestions.take(5).toList(); // Limit to 5 suggestions
  }

  /// Check if two players are skill-compatible for games
  static bool areSkillCompatible(
    SportProfile player1Sport, 
    SportProfile player2Sport,
    {int maxSkillDifference = 1}
  ) {
    if (player1Sport.sport != player2Sport.sport) return false;
    
    final skillDifference = (player1Sport.skillLevel - player2Sport.skillLevel).abs();
    return skillDifference <= maxSkillDifference;
  }

  /// Find compatible players for a given sport and skill level
  static List<SportProfile> findCompatiblePlayers(
    SportProfile targetSport,
    List<SportProfile> candidateSports,
    {int maxSkillDifference = 1}
  ) {
    return candidateSports.where((candidate) =>
      areSkillCompatible(targetSport, candidate, maxSkillDifference: maxSkillDifference)
    ).toList();
  }

  /// Calculate team skill balance for game organization
  static Map<String, dynamic> calculateTeamBalance(
    List<SportProfile> team1,
    List<SportProfile> team2,
  ) {
    final team1Avg = calculateOverallSkill(team1);
    final team2Avg = calculateOverallSkill(team2);
    final difference = (team1Avg - team2Avg).abs();
    
    return {
      'team1_average': team1Avg,
      'team2_average': team2Avg,
      'skill_difference': difference,
      'is_balanced': difference <= 0.5, // Within 0.5 skill levels
      'balance_rating': max(0.0, 1.0 - (difference / 5.0)), // 0-1 scale
      'recommendation': difference <= 0.5 
          ? 'Teams are well balanced'
          : difference <= 1.0 
              ? 'Teams are moderately balanced'
              : 'Consider rebalancing teams',
    };
  }

  /// Get skill statistics summary
  static Map<String, dynamic> getSkillStatistics(List<SportProfile> sports) {
    if (sports.isEmpty) {
      return {
        'total_sports': 0,
        'average_skill': 0.0,
        'highest_skill': 0,
        'lowest_skill': 0,
        'total_experience': 0,
        'categories_count': 0,
      };
    }
    
    final skillLevels = sports.map((s) => s.skillLevel).toList();
    final experienceYears = sports.map((s) => s.yearsPlaying).toList();
    final categories = sports.map((s) => s.category).toSet();
    
    return {
      'total_sports': sports.length,
      'average_skill': calculateOverallSkill(sports),
      'highest_skill': skillLevels.reduce(max),
      'lowest_skill': skillLevels.reduce(min),
      'total_experience': experienceYears.fold<int>(0, (sum, years) => sum + years),
      'average_experience': experienceYears.fold<int>(0, (sum, years) => sum + years) / sports.length,
      'categories_count': categories.length,
      'primary_sport': getPrimarySport(sports)?.sport ?? 'None',
    };
  }

  /// Private helper methods
  static String _getExperienceLevel(int yearsPlaying) {
    if (yearsPlaying < 1) return 'Newcomer';
    if (yearsPlaying < 2) return 'Novice';
    if (yearsPlaying < 5) return 'Developing';
    if (yearsPlaying < 10) return 'Experienced';
    return 'Veteran';
  }

  static List<String> _getSkillRecommendations(SportProfile sport) {
    final recommendations = <String>[];
    final skillEnum = SkillLevel.fromValue(sport.skillLevel);
    
    // Add 2-3 specific recommendations based on skill level and experience
    recommendations.addAll(skillEnum.trainingFocus.take(2));
    
    if (sport.isPrimarySport) {
      recommendations.add('Consider coaching others in your primary sport');
    }
    
    return recommendations;
  }
}
