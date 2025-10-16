/// Extension methods for SportProfile to add skill-level functionality and display helpers
library;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../features/profile/domain/entities/sports_profile.dart';

/// Extension methods for SportProfile entity
extension SportsProfileExtensions on SportProfile {
  /// Get skill level name from enum
  String get skillLevelName {
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
  
  /// Get skill level color from enum
  Color get skillLevelColor {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return Colors.orange;
      case SkillLevel.intermediate:
        return Colors.blue;
      case SkillLevel.advanced:
        return Colors.purple;
      case SkillLevel.expert:
        return Colors.red;
    }
  }
  
  /// Get skill level description from enum
  String get skillLevelDescription {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return 'Learning the basics';
      case SkillLevel.intermediate:
        return 'Developing skills';
      case SkillLevel.advanced:
        return 'Highly skilled';
      case SkillLevel.expert:
        return 'Master level';
    }
  }
  
  /// Check if player is considered experienced (3+ years)
  bool get isExperienced => yearsPlaying >= 3;
  
  /// Check if player is a veteran (5+ years)
  bool get isVeteran => yearsPlaying >= 5;
  
  /// Check if player is a rookie (less than 1 year)
  bool get isRookie => yearsPlaying < 1;
  
  /// Check if player has expert-level skills
  bool get isExpert => skillLevel == SkillLevel.expert;
  
  /// Check if player is at professional level
  bool get isProfessional => skillLevel == SkillLevel.expert && yearsPlaying >= 5;
  
  /// Check if player is a beginner
  bool get isBeginner => skillLevel == SkillLevel.beginner && yearsPlaying < 2;
  
  /// Get human-readable experience description
  String get experienceDescription {
    if (yearsPlaying == 0) return 'Just started';
    if (yearsPlaying == 1) return '1 year experience';
    if (yearsPlaying < 5) return '$yearsPlaying years experience';
    if (yearsPlaying < 10) return '$yearsPlaying years (experienced)';
    return '$yearsPlaying years (veteran)';
  }
  
  /// Get short experience text for compact display
  String get experienceShort {
    if (yearsPlaying == 0) return 'New';
    if (yearsPlaying == 1) return '1yr';
    return '${yearsPlaying}yrs';
  }
  
  /// Calculate proficiency score combining skill and experience
  double get proficiencyScore {
    // Weighted score: 70% skill level, 30% experience (capped at 10 years)
    final experienceScore = math.min(yearsPlaying, 10) / 10.0 * 5; // Scale to 0-5
    final skillScore = _getSkillLevelNumeric(skillLevel);
    return (skillScore * 0.7) + (experienceScore * 0.3);
  }
  
  /// Convert skill level to numeric value for calculations
  double _getSkillLevelNumeric(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 1.0;
      case SkillLevel.intermediate:
        return 2.5;
      case SkillLevel.advanced:
        return 4.0;
      case SkillLevel.expert:
        return 5.0;
    }
  }
  
  /// Get proficiency level based on score
  String get proficiencyLevel {
    final score = proficiencyScore;
    if (score >= 4.5) return 'Elite';
    if (score >= 4.0) return 'Advanced';
    if (score >= 3.0) return 'Intermediate';
    if (score >= 2.0) return 'Developing';
    return 'Beginner';
  }
  
  /// Generate skill star widgets for UI display
  List<Widget> get skillStars {
    final numericLevel = _getSkillLevelNumeric(skillLevel);
    return List.generate(5, (index) => 
      Icon(
        index < numericLevel ? Icons.star : Icons.star_border,
        color: skillLevelColor,
        size: 16,
      ),
    );
  }
  
  /// Generate larger skill stars for detailed view
  List<Widget> get skillStarsLarge {
    final numericLevel = _getSkillLevelNumeric(skillLevel);
    return List.generate(5, (index) => 
      Icon(
        index < numericLevel ? Icons.star : Icons.star_border,
        color: skillLevelColor,
        size: 24,
      ),
    );
  }
  
  /// Get skill level as a progress value (0.0 to 1.0)
  double get skillProgress => _getSkillLevelNumeric(skillLevel) / 5.0;
  
  /// Get experience progress as a value (0.0 to 1.0, capped at 10 years)
  double get experienceProgress => math.min(yearsPlaying, 10) / 10.0;
  
  /// Get formatted positions text for display
  String get positionsText {
    if (preferredPositions.isEmpty) return 'Any position';
    if (preferredPositions.length == 1) return preferredPositions.first;
    
    // Show first two positions and count if more
    final displayPositions = preferredPositions.take(2).join(', ');
    final remainingCount = preferredPositions.length - 2;
    
    return remainingCount > 0 
        ? '$displayPositions +$remainingCount more'
        : displayPositions;
  }
  
  /// Get short positions text for compact display
  String get positionsShort {
    if (preferredPositions.isEmpty) return 'Any';
    if (preferredPositions.length == 1) return preferredPositions.first;
    return '${preferredPositions.first} +${preferredPositions.length - 1}';
  }
  
  /// Get sport category display name
  String get categoryName => sportName;
  
  /// Get sport category icon
  IconData get categoryIcon => Icons.sports_soccer; // Default icon
  
  /// Check if can compete with another player
  bool canCompeteWith(SportProfile other) {
    if (sportName.toLowerCase() != other.sportName.toLowerCase()) return false;
    
    // Allow competition if skill difference is 1 level or less
    final skillDiff = _getSkillLevelNumeric(skillLevel) - _getSkillLevelNumeric(other.skillLevel);
    return skillDiff.abs() <= 1.5;
  }
  
  /// Check if can mentor another player
  bool canMentor(SportProfile other) {
    if (sportName.toLowerCase() != other.sportName.toLowerCase()) return false;
    
    // Can mentor if at least 2 skill levels higher or much more experienced
    final skillDiff = _getSkillLevelNumeric(skillLevel) - _getSkillLevelNumeric(other.skillLevel);
    return skillDiff >= 2.0 || 
           (skillDiff > 0 && yearsPlaying >= other.yearsPlaying + 3);
  }
  
  /// Check if needs mentoring from another player
  bool needsMentoring(SportProfile other) {
    return other.canMentor(this);
  }
  
  /// Get recommended training focus areas
  List<String> get trainingFocus {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return ['Basic techniques', 'Rule understanding', 'Fitness foundation'];
      case SkillLevel.intermediate:
        return ['Skill refinement', 'Tactical awareness', 'Match experience'];
      case SkillLevel.advanced:
        return ['Advanced tactics', 'Mental game', 'Specialization'];
      case SkillLevel.expert:
        return ['Mastery perfection', 'Leadership skills', 'Teaching others'];
    }
  }
  
  /// Get skill development recommendations
  List<String> get developmentTips {
    final tips = <String>[];
    final numericLevel = _getSkillLevelNumeric(skillLevel);
    
    if (isBeginner) {
      tips.add('Focus on learning basic rules and techniques');
      tips.add('Practice regularly to build muscle memory');
      tips.add('Watch experienced players and learn from them');
    } else if (numericLevel <= 3) {
      tips.add('Work on consistency in your techniques');
      tips.add('Start playing in competitive environments');
      tips.add('Consider taking lessons from a qualified coach');
    } else {
      tips.add('Focus on advanced strategies and tactics');
      tips.add('Consider mentoring less experienced players');
      tips.add('Compete in tournaments to test your skills');
    }
    
    // Experience-based tips
    if (yearsPlaying < 2) {
      tips.add('Join a local club or team for regular practice');
    } else if (yearsPlaying >= 5) {
      tips.add('Share your knowledge with newcomers to the sport');
    }
    
    return tips.take(3).toList();
  }
  
  /// Get playing style recommendations
  List<String> get playingStyleSuggestions {
    final suggestions = <String>[];
    
    switch (skillLevel) {
      case SkillLevel.beginner:
        suggestions.addAll(['Defensive', 'Supportive', 'Team-oriented']);
        break;
      case SkillLevel.intermediate:
        suggestions.addAll(['Balanced', 'Adaptable', 'Strategic']);
        break;
      case SkillLevel.advanced:
      case SkillLevel.expert:
        suggestions.addAll(['Aggressive', 'Leadership', 'Playmaker']);
        break;
    }
    
    return suggestions;
  }
  
  /// Get commitment level based on skill and experience
  String get commitmentLevel {
    if (isProfessional || (isExpert && isVeteran)) return 'High';
    if (skillLevel == SkillLevel.advanced || skillLevel == SkillLevel.expert || isExperienced) return 'Medium';
    return 'Casual';
  }
  
  /// Get expected weekly playing hours
  int get expectedWeeklyHours {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return 2;
      case SkillLevel.intermediate:
        return 4;
      case SkillLevel.advanced:
        return 6;
      case SkillLevel.expert:
        return 8;
    }
  }
  
  /// Check if sport profile is well-developed
  bool get isWellDeveloped => 
      (skillLevel == SkillLevel.advanced || skillLevel == SkillLevel.expert) && yearsPlaying >= 2;
  
  /// Check if ready for competitive play
  bool get isCompetitionReady => 
      (skillLevel == SkillLevel.advanced || skillLevel == SkillLevel.expert) && yearsPlaying >= 1;
  
  /// Check if ready for coaching others
  bool get canCoach => 
      skillLevel == SkillLevel.expert && yearsPlaying >= 3;
  
  /// Get sport profile summary
  Map<String, dynamic> get summary {
    return {
      'sport': sportName,
      'skill_level': skillLevel,
      'skill_name': skillLevelName,
      'years_playing': yearsPlaying,
      'experience_description': experienceDescription,
      'proficiency_score': proficiencyScore.toStringAsFixed(1),
      'proficiency_level': proficiencyLevel,
      'is_primary': isPrimarySport,
      'is_experienced': isExperienced,
      'is_expert': isExpert,
      'commitment_level': commitmentLevel,
      'positions': positionsText,
    };
  }
  
  /// Generate display card data for UI
  Map<String, dynamic> get cardData {
    return {
      'title': sportName,
      'subtitle': '$skillLevelName • $experienceShort',
      'color': skillLevelColor,
      'progress': skillProgress,
      'badge': isPrimarySport ? 'Primary' : null,
      'icon': categoryIcon,
      'positions': positionsShort,
    };
  }
  
  /// Get achievement level for this sport
  String get achievementLevel {
    if (isProfessional && isVeteran) return 'Legend';
    if (isProfessional) return 'Professional';
    if (isExpert && isVeteran) return 'Master';
    if (isExpert) return 'Expert';
    if ((skillLevel == SkillLevel.advanced || skillLevel == SkillLevel.expert) && isExperienced) return 'Advanced';
    if (skillLevel == SkillLevel.advanced || skillLevel == SkillLevel.expert || isExperienced) return 'Intermediate';
    return 'Developing';
  }
  
  /// Get next milestone for progression
  String get nextMilestone {
    if (skillLevel != SkillLevel.expert) {
      final nextLevel = _getNextSkillLevel(skillLevel);
      return 'Reach $nextLevel level';
    }
    
    if (yearsPlaying < 5) {
      return 'Gain more experience (${5 - yearsPlaying} years to veteran)';
    }
    
    if (!isPrimarySport) {
      return 'Consider making this your primary sport';
    }
    
    return 'Consider coaching others or competing professionally';
  }
  
  /// Get next skill level name
  String _getNextSkillLevel(SkillLevel current) {
    switch (current) {
      case SkillLevel.beginner:
        return 'Intermediate';
      case SkillLevel.intermediate:
        return 'Advanced';
      case SkillLevel.advanced:
        return 'Expert';
      case SkillLevel.expert:
        return 'Master';
    }
  }
  
  /// Check compatibility for team formation
  bool isTeamCompatibleWith(List<SportProfile> teammates) {
    if (teammates.isEmpty) return true;
    
    // Check if sport matches
    final sameSport = teammates.every((mate) => mate.sportName.toLowerCase() == sportName.toLowerCase());
    if (!sameSport) return false;
    
    // Check skill level balance (within 2 levels)
    final skillLevels = teammates.map((mate) => _getSkillLevelNumeric(mate.skillLevel)).toList()..add(_getSkillLevelNumeric(skillLevel));
    final minSkill = skillLevels.reduce(math.min);
    final maxSkill = skillLevels.reduce(math.max);
    
    return (maxSkill - minSkill) <= 2;
  }
  
  /// Get recommended match types
  List<String> get recommendedMatchTypes {
    final types = <String>[];
    
    if (isBeginner) {
      types.addAll(['Casual', 'Practice', 'Beginner-friendly']);
    } else if (skillLevel == SkillLevel.intermediate) {
      types.addAll(['Casual', 'Semi-competitive', 'Skill-building']);
    } else {
      types.addAll(['Competitive', 'Tournament', 'Advanced']);
    }
    
    if (isPrimarySport) {
      types.add('Championship');
    }
    
    return types;
  }
}
