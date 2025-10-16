/// Extension methods for UserProfile to add convenient functionality and computed properties
library;
import 'dart:math';
import 'package:flutter/material.dart';

/// Temporary model classes for extensions
class UserProfile {
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final List<SportProfile> sportsProfiles;
  final int profileCompletionPercentage;
  
  const UserProfile({
    this.username,
    this.fullName,
    this.avatarUrl,
    this.dateOfBirth,
    this.sportsProfiles = const [],
    this.profileCompletionPercentage = 0,
  });
}

class SportProfile {
  final String sport;
  final int skillLevel;
  final int yearsPlaying;
  final bool isPrimarySport;
  final List<String> preferredPositions;
  
  const SportProfile({
    required this.sport,
    required this.skillLevel,
    required this.yearsPlaying,
    this.isPrimarySport = false,
    this.preferredPositions = const [],
  });
}

/// Extension methods for UserProfile entity
extension UserProfileExtensions on UserProfile {
  /// Check if profile is considered complete (85% or higher)
  bool get isComplete => profileCompletionPercentage >= 85;
  
  /// Check if profile has a basic completion level (30% or higher)
  bool get hasBasicCompletion => profileCompletionPercentage >= 30;
  
  /// Check if profile is ready for advanced features (60% or higher)
  bool get isAdvancedReady => profileCompletionPercentage >= 60;
  
  /// Check if user has uploaded an avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  
  /// Check if user has a custom avatar (not default)
  bool get hasCustomAvatar => 
      hasAvatar && !avatarUrl!.contains('default-avatar') && !avatarUrl!.contains('assets/');
  
  /// Calculate user's current age from date of birth
  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth!.year;
    
    // Adjust if birthday hasn't occurred this year
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      calculatedAge--;
    }
    
    return calculatedAge;
  }
  
  /// Get age group string based on current age
  String get ageGroup {
    final currentAge = age;
    if (currentAge < 18) return 'Youth';
    if (currentAge < 25) return 'Young Adult';
    if (currentAge < 35) return 'Adult';
    if (currentAge < 50) return 'Middle-aged';
    if (currentAge < 65) return 'Senior';
    return 'Elder';
  }
  
  /// Get display name with fallback priority
  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return 'Anonymous User';
  }
  
  /// Get first name from full name
  String get firstName {
    if (fullName == null || fullName!.isEmpty) return displayName;
    final parts = fullName!.trim().split(' ');
    return parts.first;
  }
  
  /// Get last name from full name
  String get lastName {
    if (fullName == null || fullName!.isEmpty) return '';
    final parts = fullName!.trim().split(' ');
    return parts.length > 1 ? parts.last : '';
  }
  
  /// Generate user initials from name
  String get initials {
    if (fullName == null || fullName!.trim().isEmpty) {
      if (username != null && username!.isNotEmpty) {
        return username!.substring(0, min(2, username!.length)).toUpperCase();
      }
      return '?';
    }
    
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    
    final firstWord = parts.first;
    return firstWord.substring(0, min(2, firstWord.length)).toUpperCase();
  }
  
  /// Get primary sport profile (marked as primary or first one)
  SportProfile? get primarySport {
    if (sportsProfiles.isEmpty) return null;
    
    try {
      return sportsProfiles.firstWhere((sport) => sport.isPrimarySport);
    } catch (_) {
      // If no sport is marked as primary, return the first one
      return sportsProfiles.first;
    }
  }
  
  /// Get the highest skill level among all sports
  int get highestSkillLevel {
    if (sportsProfiles.isEmpty) return 0;
    return sportsProfiles.map((sport) => sport.skillLevel).reduce(max);
  }
  
  /// Get average skill level across all sports
  double get averageSkillLevel {
    if (sportsProfiles.isEmpty) return 0.0;
    final totalSkill = sportsProfiles.fold<int>(0, (sum, sport) => sum + sport.skillLevel);
    return totalSkill / sportsProfiles.length;
  }
  
  /// Get total years of experience across all sports
  int get totalSportsExperience {
    if (sportsProfiles.isEmpty) return 0;
    return sportsProfiles.fold<int>(0, (sum, sport) => sum + sport.yearsPlaying);
  }
  
  /// Get completion message based on current progress
  String get completionMessage {
    if (isComplete) return 'Profile complete! 🎉';
    if (isAdvancedReady) return 'Almost there! $profileCompletionPercentage% complete';
    if (hasBasicCompletion) return 'Good start! $profileCompletionPercentage% complete';
    return 'Just getting started - $profileCompletionPercentage% complete';
  }
  
  /// Get next completion milestone
  String get nextMilestone {
    if (profileCompletionPercentage < 30) return 'Reach 30% to unlock basic features';
    if (profileCompletionPercentage < 60) return 'Reach 60% to unlock messaging';
    if (profileCompletionPercentage < 85) return 'Reach 85% to unlock all features';
    return 'Profile complete!';
  }
  
  /// Get list of earned badges based on profile characteristics
  List<String> get badges {
    final earnedBadges = <String>[];
    
    // Completion badges
    if (isComplete) earnedBadges.add('complete_profile');
    if (hasCustomAvatar) earnedBadges.add('custom_avatar');
    
    // Sports badges
    if (sportsProfiles.length >= 5) earnedBadges.add('multi_sport_athlete');
    if (sportsProfiles.length >= 3) earnedBadges.add('versatile_player');
    if (sportsProfiles.isNotEmpty && sportsProfiles.every((s) => s.skillLevel >= 4)) {
      earnedBadges.add('expert_athlete');
    }
    
    // Experience badges
    if (totalSportsExperience >= 20) earnedBadges.add('experienced_player');
    if (totalSportsExperience >= 50) earnedBadges.add('veteran_athlete');
    
    // Age-based badges
    final currentAge = age;
    if (currentAge >= 50) earnedBadges.add('senior_athlete');
    if (currentAge >= 65) earnedBadges.add('golden_years');
    if (currentAge < 25) earnedBadges.add('young_gun');
    
    // Skill-based badges
    if (highestSkillLevel == 5) earnedBadges.add('professional_level');
    if (averageSkillLevel >= 4.0) earnedBadges.add('high_performer');
    
    return earnedBadges;
  }
  
  /// Get user type based on profile characteristics
  String get userType {
    if (!hasBasicCompletion) return 'newcomer';
    if (sportsProfiles.isEmpty) return 'observer';
    if (sportsProfiles.length == 1) return 'specialist';
    if (sportsProfiles.length <= 3) return 'multi_sport';
    return 'athlete';
  }
  
  /// Check if user is considered a beginner
  bool get isBeginner => 
      sportsProfiles.isEmpty || 
      sportsProfiles.every((sport) => sport.skillLevel <= 2 && sport.yearsPlaying < 2);
  
  /// Check if user is considered intermediate
  bool get isIntermediate => 
      !isBeginner && !isAdvanced && 
      sportsProfiles.any((sport) => sport.skillLevel >= 3 || sport.yearsPlaying >= 2);
  
  /// Check if user is considered advanced
  bool get isAdvanced => 
      sportsProfiles.any((sport) => sport.skillLevel >= 4 || sport.yearsPlaying >= 5);
  
  /// Check if user qualifies for competitive play
  bool get canPlayCompetitive => 
      isComplete && sportsProfiles.any((sport) => sport.skillLevel >= 3);
  
  /// Get recommended sports based on current sports (placeholder for ML logic)
  List<String> get recommendedSports {
    if (sportsProfiles.isEmpty) return ['Tennis', 'Basketball', 'Soccer'];
    
    // Simple recommendation based on existing sports categories
    final recommendations = <String>[];
    final currentSports = sportsProfiles.map((s) => s.sport.toLowerCase()).toSet();
    
    if (currentSports.contains('tennis') && !currentSports.contains('badminton')) {
      recommendations.add('Badminton');
    }
    if (currentSports.contains('basketball') && !currentSports.contains('volleyball')) {
      recommendations.add('Volleyball');
    }
    if (currentSports.contains('soccer') && !currentSports.contains('rugby')) {
      recommendations.add('Rugby');
    }
    
    // Add some general recommendations if list is short
    if (recommendations.length < 3) {
      final generalSports = ['Swimming', 'Running', 'Cycling', 'Golf'];
      for (final sport in generalSports) {
        if (!currentSports.contains(sport.toLowerCase()) && 
            !recommendations.contains(sport)) {
          recommendations.add(sport);
          if (recommendations.length >= 3) break;
        }
      }
    }
    
    return recommendations.take(3).toList();
  }
  
  /// Generate user summary for display
  Map<String, dynamic> get summary {
    return {
      'display_name': displayName,
      'age': age,
      'completion': profileCompletionPercentage,
      'sports_count': sportsProfiles.length,
      'primary_sport': primarySport?.sport ?? 'None',
      'skill_level': averageSkillLevel.toStringAsFixed(1),
      'experience_years': totalSportsExperience,
      'user_type': userType,
      'badges': badges.length,
      'is_complete': isComplete,
    };
  }
  
  /// Check if profiles are compatible for playing together
  bool isCompatibleWith(UserProfile other) {
    // Basic compatibility checks
    if (sportsProfiles.isEmpty || other.sportsProfiles.isEmpty) return false;
    
    // Check for common sports
    final mySports = sportsProfiles.map((s) => s.sport.toLowerCase()).toSet();
    final otherSports = other.sportsProfiles.map((s) => s.sport.toLowerCase()).toSet();
    final commonSports = mySports.intersection(otherSports);
    
    if (commonSports.isEmpty) return false;
    
    // Check skill level compatibility for common sports
    for (final sport in commonSports) {
      final mySkill = sportsProfiles
          .firstWhere((s) => s.sport.toLowerCase() == sport)
          .skillLevel;
      final otherSkill = other.sportsProfiles
          .firstWhere((s) => s.sport.toLowerCase() == sport)
          .skillLevel;
      
      // Allow play if skill difference is 2 levels or less
      if ((mySkill - otherSkill).abs() <= 2) return true;
    }
    
    return false;
  }
  
  /// Get profile strength assessment
  String get profileStrength {
    if (profileCompletionPercentage >= 90) return 'Excellent';
    if (profileCompletionPercentage >= 75) return 'Very Good';
    if (profileCompletionPercentage >= 50) return 'Good';
    if (profileCompletionPercentage >= 25) return 'Fair';
    return 'Needs Work';
  }
  
  /// Get profile color theme based on characteristics
  Color get profileColor {
    if (isComplete && isAdvanced) return Colors.purple;
    if (isComplete) return Colors.green;
    if (isAdvancedReady) return Colors.blue;
    if (hasBasicCompletion) return Colors.orange;
    return Colors.grey;
  }
}
