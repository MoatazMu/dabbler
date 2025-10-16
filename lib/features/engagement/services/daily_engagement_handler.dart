import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../rewards/services/rewards_service.dart';
import '../../rewards/services/achievement_notification_service.dart';
import '../../rewards/services/progress_tracking_service.dart';
import '../../rewards/domain/entities/achievement.dart';
import '../../rewards/domain/entities/badge_tier.dart';

/// Daily challenge data model
class DailyChallenge {
  final String id;
  final String name;
  final String description;
  final String type; // 'games', 'social', 'points', 'login'
  final int target;
  final int current;
  final int reward;
  final DateTime expiresAt;
  final bool isCompleted;

  const DailyChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.target,
    required this.current,
    required this.reward,
    required this.expiresAt,
    required this.isCompleted,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'target': target,
      'current': current,
      'reward': reward,
      'expiresAt': expiresAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory DailyChallenge.fromMap(Map<String, dynamic> map) {
    return DailyChallenge(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      target: map['target'],
      current: map['current'],
      reward: map['reward'],
      expiresAt: DateTime.parse(map['expiresAt']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  DailyChallenge copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    int? target,
    int? current,
    int? reward,
    DateTime? expiresAt,
    bool? isCompleted,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      current: current ?? this.current,
      reward: reward ?? this.reward,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Weekly goal data model
class WeeklyGoal {
  final String id;
  final String name;
  final String description;
  final String type;
  final int target;
  final int current;
  final int reward;
  final DateTime weekStart;
  final DateTime weekEnd;
  final bool isCompleted;

  const WeeklyGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.target,
    required this.current,
    required this.reward,
    required this.weekStart,
    required this.weekEnd,
    required this.isCompleted,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  int get daysLeft => weekEnd.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'target': target,
      'current': current,
      'reward': reward,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory WeeklyGoal.fromMap(Map<String, dynamic> map) {
    return WeeklyGoal(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      target: map['target'],
      current: map['current'],
      reward: map['reward'],
      weekStart: DateTime.parse(map['weekStart']),
      weekEnd: DateTime.parse(map['weekEnd']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

/// Daily engagement handler for rewards system
class DailyEngagementHandler {
  RewardsService? _rewardsService;
  AchievementNotificationService? _notificationService;
  ProgressTrackingService? _progressService;
  SharedPreferences? _prefs;

  /// Initialize daily engagement system
  Future<void> initialize(
    String userId,
    RewardsService rewardsService,
    AchievementNotificationService notificationService,
    ProgressTrackingService progressService,
  ) async {
    _prefs = await SharedPreferences.getInstance();
    _rewardsService = rewardsService;
    _notificationService = notificationService;
    _progressService = progressService;
  }

  /// Handle daily login bonus
  Future<bool> processDailyLogin(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastLoginDate = _prefs?.getString('last_login_date_$userId');
      
      if (lastLoginDate == today) {
        return false; // Already logged in today
      }

      // Update login streak
      final currentStreak = await _updateLoginStreak(userId, lastLoginDate);
      
      // Award daily login bonus
      final bonusPoints = _calculateLoginBonus(currentStreak);
      if (_rewardsService != null) {
        await _rewardsService!.awardPoints(
          userId: userId,
          points: bonusPoints,
          reason: 'Daily login bonus',
          source: 'daily_login',
        );
      }
      
      // Track login event
      await _progressService!.trackEvent(ProgressEvent(
        id: '${userId}_daily_login_$today',
        userId: userId,
        type: ProgressEventType.dailyLogin,
        data: {
          'date': today,
          'streak': currentStreak,
          'bonusPoints': bonusPoints,
        },
        timestamp: DateTime.now(),
      ));

      // Save login date
      await _prefs?.setString('last_login_date_$userId', today);
      
      // Check for login streak achievements
      await _checkLoginStreakAchievements(userId, currentStreak);
      
      return true;
    } catch (e) {
      debugPrint('Error processing daily login: $e');
      return false;
    }
  }

  /// Generate daily challenges for user
  Future<List<DailyChallenge>> generateDailyChallenges(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existingChallenges = await _loadDailyChallenges(userId, today);
      
      if (existingChallenges.isNotEmpty) {
        return existingChallenges; // Return existing challenges
      }

      // Generate new challenges for today
      final challenges = <DailyChallenge>[];
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final endOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      // Game challenge
      challenges.add(DailyChallenge(
        id: 'daily_games_$today',
        name: 'Play Games',
        description: 'Complete 2 games today',
        type: 'games',
        target: 2,
        current: 0,
        reward: 50,
        expiresAt: endOfDay,
        isCompleted: false,
      ));

      // Social challenge
      challenges.add(DailyChallenge(
        id: 'daily_social_$today',
        name: 'Social Butterfly',
        description: 'Like 5 posts or comment on 3 posts',
        type: 'social',
        target: 5,
        current: 0,
        reward: 25,
        expiresAt: endOfDay,
        isCompleted: false,
      ));

      // Points challenge
      challenges.add(DailyChallenge(
        id: 'daily_points_$today',
        name: 'Point Collector',
        description: 'Earn 100 points today',
        type: 'points',
        target: 100,
        current: 0,
        reward: 30,
        expiresAt: endOfDay,
        isCompleted: false,
      ));

      // Save challenges
      await _saveDailyChallenges(userId, today, challenges);
      
      return challenges;
    } catch (e) {
      debugPrint('Error generating daily challenges: $e');
      return [];
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(
    String userId,
    String challengeType,
    int increment,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final challenges = await _loadDailyChallenges(userId, today);
      
      for (int i = 0; i < challenges.length; i++) {
        final challenge = challenges[i];
        if (challenge.type == challengeType && !challenge.isCompleted) {
          final newCurrent = challenge.current + increment;
          final isCompleted = newCurrent >= challenge.target;
          
          challenges[i] = challenge.copyWith(
            current: newCurrent,
            isCompleted: isCompleted,
          );
          
          // Award reward if completed
          if (isCompleted && !challenge.isCompleted) {
            await _rewardsService!.awardPoints(
              userId: userId,
              points: challenge.reward,
              reason: 'Daily challenge completed: ${challenge.name}',
              source: 'daily_challenge',
            );
            
            // Show completion notification
            await _showChallengeCompletionNotification(challenge);
          }
        }
      }
      
      await _saveDailyChallenges(userId, today, challenges);
    } catch (e) {
      debugPrint('Error updating challenge progress: $e');
    }
  }

  /// Generate weekly goals
  Future<List<WeeklyGoal>> generateWeeklyGoals(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartKey = weekStart.toIso8601String().split('T')[0];
      
      final existingGoals = await _loadWeeklyGoals(userId, weekStartKey);
      
      if (existingGoals.isNotEmpty) {
        return existingGoals;
      }

      // Generate new weekly goals
      final goals = <WeeklyGoal>[];
      final weekEnd = weekStart.add(const Duration(days: 6));

      goals.add(WeeklyGoal(
        id: 'weekly_games_$weekStartKey',
        name: 'Game Master',
        description: 'Complete 10 games this week',
        type: 'games',
        target: 10,
        current: 0,
        reward: 200,
        weekStart: weekStart,
        weekEnd: weekEnd,
        isCompleted: false,
      ));

      goals.add(WeeklyGoal(
        id: 'weekly_social_$weekStartKey',
        name: 'Community Supporter',
        description: 'Make 50 social interactions this week',
        type: 'social',
        target: 50,
        current: 0,
        reward: 150,
        weekStart: weekStart,
        weekEnd: weekEnd,
        isCompleted: false,
      ));

      await _saveWeeklyGoals(userId, weekStartKey, goals);
      return goals;
    } catch (e) {
      debugPrint('Error generating weekly goals: $e');
      return [];
    }
  }

  /// Get current login streak
  Future<int> getCurrentLoginStreak(String userId) async {
    return _prefs?.getInt('login_streak_$userId') ?? 0;
  }

  /// Create special event achievements
  Future<void> createSpecialEventAchievements(String userId) async {
    try {
      // Weekend warrior achievement
      if (DateTime.now().weekday >= 6) {
        // Check for weekend activity (simplified)
        final weekendActivity = _prefs?.getInt('weekend_games_$userId') ?? 0;
        if (weekendActivity >= 5) {
          final achievement = Achievement(
            id: 'weekend_warrior',
            code: 'WEEKEND_WARRIOR',
            name: 'Weekend Warrior',
            description: 'Play 5 games during the weekend',
            type: AchievementType.conditional,
            category: AchievementCategory.special,
            tier: BadgeTier.gold,
            criteria: {'weekendGames': 5},
            points: 100,
            createdAt: DateTime.now(),
          );
          
          await _rewardsService!.unlockAchievement(
            userId: userId,
            achievementId: achievement.id,
          );
          
          await _notificationService!.queueAchievementNotification(
            userId: userId,
            achievement: achievement,
          );
        }
      }

      // Perfect week achievement
      final perfectWeek = await _checkPerfectWeek(userId);
      if (perfectWeek) {
        final achievement = Achievement(
          id: 'perfect_week',
          code: 'PERFECT_WEEK',
          name: 'Perfect Week',
          description: 'Complete all daily challenges for 7 days straight',
          type: AchievementType.streak,
          category: AchievementCategory.special,
          tier: BadgeTier.platinum,
          criteria: {'perfectDays': 7},
          points: 500,
          createdAt: DateTime.now(),
        );
        
        await _rewardsService!.unlockAchievement(
          userId: userId,
          achievementId: achievement.id,
        );
        
        await _notificationService!.queueAchievementNotification(
          userId: userId,
          achievement: achievement,
        );
      }
    } catch (e) {
      debugPrint('Error creating special event achievements: $e');
    }
  }

  // Private helper methods

  Future<int> _updateLoginStreak(String userId, String? lastLoginDate) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1))
                      .toIso8601String().split('T')[0];
    
    int currentStreak = _prefs?.getInt('login_streak_$userId') ?? 0;
    
    if (lastLoginDate == yesterday) {
      // Consecutive login
      currentStreak++;
    } else if (lastLoginDate != null) {
      // Streak broken
      currentStreak = 1;
    } else {
      // First login
      currentStreak = 1;
    }
    
    await _prefs?.setInt('login_streak_$userId', currentStreak);
    return currentStreak;
  }

  int _calculateLoginBonus(int streak) {
    // Bonus increases with streak up to a maximum
    return (10 + (streak * 5)).clamp(10, 100);
  }

  Future<void> _checkLoginStreakAchievements(String userId, int streak) async {
    if ([7, 14, 30, 50, 100].contains(streak)) {
      final tier = streak >= 100 ? BadgeTier.platinum :
                   streak >= 50 ? BadgeTier.gold :
                   streak >= 30 ? BadgeTier.silver : BadgeTier.bronze;
      
      final achievement = Achievement(
        id: 'login_streak_$streak',
        code: 'LOGIN_STREAK_$streak',
        name: '$streak Day Streak',
        description: 'Log in for $streak consecutive days',
        type: AchievementType.streak,
        category: AchievementCategory.special,
        tier: tier,
        criteria: {'loginStreak': streak},
        points: streak * 2,
        createdAt: DateTime.now(),
      );
      
      await _rewardsService!.unlockAchievement(
        userId: userId,
        achievementId: achievement.id,
      );
      
      await _notificationService!.queueAchievementNotification(
        userId: userId,
        achievement: achievement,
      );
    }
  }

  Future<List<DailyChallenge>> _loadDailyChallenges(String userId, String date) async {
    try {
      final challengesJson = _prefs?.getStringList('daily_challenges_${userId}_$date');
      if (challengesJson == null) return [];
      
      return challengesJson
          .map((jsonStr) => DailyChallenge.fromMap(
                Map<String, dynamic>.from(jsonDecode(jsonStr))
              ))
          .toList();
    } catch (e) {
      debugPrint('Error loading daily challenges: $e');
      return [];
    }
  }

  Future<void> _saveDailyChallenges(
    String userId,
    String date,
    List<DailyChallenge> challenges,
  ) async {
    try {
      final challengesJson = challenges
          .map((c) => jsonEncode(c.toMap()))
          .toList();
      
      await _prefs?.setStringList(
        'daily_challenges_${userId}_$date',
        challengesJson,
      );
    } catch (e) {
      debugPrint('Error saving daily challenges: $e');
    }
  }

  Future<List<WeeklyGoal>> _loadWeeklyGoals(String userId, String weekStart) async {
    try {
      final goalsJson = _prefs?.getStringList('weekly_goals_${userId}_$weekStart');
      if (goalsJson == null) return [];
      
      return goalsJson
          .map((jsonStr) => WeeklyGoal.fromMap(
                Map<String, dynamic>.from(jsonDecode(jsonStr))
              ))
          .toList();
    } catch (e) {
      debugPrint('Error loading weekly goals: $e');
      return [];
    }
  }

  Future<void> _saveWeeklyGoals(
    String userId,
    String weekStart,
    List<WeeklyGoal> goals,
  ) async {
    try {
      final goalsJson = goals
          .map((g) => jsonEncode(g.toMap()))
          .toList();
      
      await _prefs?.setStringList(
        'weekly_goals_${userId}_$weekStart',
        goalsJson,
      );
    } catch (e) {
      debugPrint('Error saving weekly goals: $e');
    }
  }

  Future<void> _showChallengeCompletionNotification(DailyChallenge challenge) async {
    // This would show a local notification or in-app notification
    debugPrint('Challenge completed: ${challenge.name} - ${challenge.reward} points!');
  }

  Future<bool> _checkPerfectWeek(String userId) async {
    // Check if user completed all daily challenges for the past 7 days
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
      final challenges = await _loadDailyChallenges(userId, date);
      
      if (challenges.isEmpty || !challenges.every((c) => c.isCompleted)) {
        return false;
      }
    }
    
    return true;
  }
}