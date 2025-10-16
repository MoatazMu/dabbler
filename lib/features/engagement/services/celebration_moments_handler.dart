import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../rewards/domain/entities/achievement.dart';
import '../../rewards/domain/entities/badge_tier.dart';
import '../../rewards/services/achievement_notification_service.dart';
import '../../rewards/services/rewards_service.dart';

/// Celebration moment types
enum CelebrationMoment {
  firstAchievement,
  tierPromotion,
  milestoneAchievement,
  leaderboardPosition,
  badgeCollection,
  perfectWeek,
  perfectMonth,
  streakMilestone,
  pointsMilestone,
  socialMilestone,
}

/// Celebration data model
class CelebrationData {
  final CelebrationMoment type;
  final String title;
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color? secondaryColor;
  final Duration duration;
  final bool hasSound;
  final bool hasVibration;
  final bool hasConfetti;
  final Map<String, dynamic> metadata;

  const CelebrationData({
    required this.type,
    required this.title,
    required this.message,
    this.subtitle,
    required this.icon,
    required this.primaryColor,
    this.secondaryColor,
    this.duration = const Duration(seconds: 3),
    this.hasSound = true,
    this.hasVibration = true,
    this.hasConfetti = false,
    this.metadata = const {},
  });
}

/// Animation controller data
class CelebrationAnimation {
  final AnimationController controller;
  final Animation<double> scale;
  final Animation<double> opacity;
  final Animation<double> rotation;
  final Animation<Offset> slide;
  final Animation<Color?> color;

  const CelebrationAnimation({
    required this.controller,
    required this.scale,
    required this.opacity,
    required this.rotation,
    required this.slide,
    required this.color,
  });
}

/// Celebration moments handler for rewards system
class CelebrationMomentsHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Active celebrations tracking
  final List<CelebrationData> _activeCelebrations = [];
  final Map<CelebrationMoment, DateTime> _lastCelebrationTimes = {};

  /// Initialize celebration system
  Future<void> initialize(
    RewardsService rewardsService,
    AchievementNotificationService notificationService,
  ) async {
    // Services are passed as parameters and used directly in methods
    debugPrint('CelebrationMomentsHandler initialized');
  }

  /// Trigger first achievement celebration
  Future<void> celebrateFirstAchievement(
    String userId,
    Achievement achievement,
  ) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.firstAchievement,
      title: '🎉 First Achievement!',
      message: 'Congratulations on unlocking your first achievement!',
      subtitle: achievement.name,
      icon: Icons.emoji_events,
      primaryColor: Colors.amber,
      secondaryColor: Colors.orange,
      duration: const Duration(seconds: 5),
      hasConfetti: true,
      metadata: {
        'achievementId': achievement.id,
        'achievementName': achievement.name,
        'tier': achievement.tier.name,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger tier promotion celebration
  Future<void> celebrateTierPromotion(
    String userId,
    BadgeTier oldTier,
    BadgeTier newTier,
    int newPoints,
  ) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.tierPromotion,
      title: '⬆️ Tier Promotion!',
      message: 'You\'ve been promoted to ${_getTierDisplayName(newTier)}!',
      subtitle: 'Total Points: $newPoints',
      icon: Icons.military_tech,
      primaryColor: _getTierColor(newTier),
      secondaryColor: _getTierColor(oldTier),
      duration: const Duration(seconds: 6),
      hasConfetti: true,
      metadata: {
        'oldTier': oldTier.name,
        'newTier': newTier.name,
        'points': newPoints,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
    
    // Play special tier promotion sound
    await _playTierPromotionSound(newTier);
  }

  /// Trigger milestone achievement celebration
  Future<void> celebrateMilestoneAchievement(
    String userId,
    Achievement achievement,
    String milestoneType,
  ) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.milestoneAchievement,
      title: '🏆 Milestone Reached!',
      message: achievement.name,
      subtitle: achievement.description,
      icon: Icons.flag,
      primaryColor: _getMilestoneColor(milestoneType),
      duration: const Duration(seconds: 4),
      hasConfetti: true,
      metadata: {
        'achievementId': achievement.id,
        'milestoneType': milestoneType,
        'tier': achievement.tier.name,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger leaderboard position celebration
  Future<void> celebrateLeaderboardPosition(
    String userId,
    int position,
    String leaderboardType,
    int totalParticipants,
  ) async {
    String title = '';
    String message = '';
    IconData icon = Icons.leaderboard;
    Color primaryColor = Colors.blue;
    
    if (position == 1) {
      title = '👑 #1 Position!';
      message = 'You\'re at the top of the $leaderboardType leaderboard!';
      icon = Icons.workspace_premium;
      primaryColor = Colors.amber;
    } else if (position <= 3) {
      title = '🥉 Top 3 Position!';
      message = 'You\'re #$position on the $leaderboardType leaderboard!';
      primaryColor = Colors.orange;
    } else if (position <= 10) {
      title = '⭐ Top 10 Position!';
      message = 'You\'re #$position on the $leaderboardType leaderboard!';
      primaryColor = Colors.purple;
    } else {
      title = '📈 Great Progress!';
      message = 'You\'re #$position out of $totalParticipants players!';
      primaryColor = Colors.green;
    }

    final celebration = CelebrationData(
      type: CelebrationMoment.leaderboardPosition,
      title: title,
      message: message,
      subtitle: '$leaderboardType Leaderboard',
      icon: icon,
      primaryColor: primaryColor,
      duration: const Duration(seconds: 4),
      hasConfetti: position <= 10,
      metadata: {
        'position': position,
        'leaderboardType': leaderboardType,
        'totalParticipants': totalParticipants,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger badge collection celebration
  Future<void> celebrateBadgeCollection(
    String userId,
    String collectionName,
    int collectionSize,
    int completedBadges,
  ) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.badgeCollection,
      title: '🎖️ Collection Complete!',
      message: 'You\'ve completed the $collectionName collection!',
      subtitle: '$completedBadges/$collectionSize badges collected',
      icon: Icons.collections,
      primaryColor: Colors.indigo,
      secondaryColor: Colors.cyan,
      duration: const Duration(seconds: 4),
      hasConfetti: true,
      metadata: {
        'collectionName': collectionName,
        'collectionSize': collectionSize,
        'completedBadges': completedBadges,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger perfect week celebration
  Future<void> celebratePerfectWeek(String userId) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.perfectWeek,
      title: '🗓️ Perfect Week!',
      message: 'You completed all daily challenges this week!',
      subtitle: 'Consistency pays off!',
      icon: Icons.calendar_today,
      primaryColor: Colors.green,
      secondaryColor: Colors.lightGreen,
      duration: const Duration(seconds: 5),
      hasConfetti: true,
      metadata: {
        'weekStart': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'weekEnd': DateTime.now().toIso8601String(),
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger perfect month celebration
  Future<void> celebratePerfectMonth(String userId) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.perfectMonth,
      title: '📅 Perfect Month!',
      message: 'You completed all daily challenges this month!',
      subtitle: 'Incredible dedication!',
      icon: Icons.event_available,
      primaryColor: Colors.deepPurple,
      secondaryColor: Colors.purple,
      duration: const Duration(seconds: 6),
      hasConfetti: true,
      metadata: {
        'monthStart': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'monthEnd': DateTime.now().toIso8601String(),
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger streak milestone celebration
  Future<void> celebrateStreakMilestone(
    String userId,
    String streakType,
    int streakCount,
  ) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.streakMilestone,
      title: '🔥 $streakCount Day Streak!',
      message: 'Amazing $streakType streak!',
      subtitle: 'Keep the momentum going!',
      icon: Icons.local_fire_department,
      primaryColor: Colors.red,
      secondaryColor: Colors.orange,
      duration: const Duration(seconds: 4),
      hasConfetti: streakCount >= 30,
      metadata: {
        'streakType': streakType,
        'streakCount': streakCount,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger points milestone celebration
  Future<void> celebratePointsMilestone(
    String userId,
    int totalPoints,
    int milestone,
  ) async {
    final celebration = CelebrationData(
      type: CelebrationMoment.pointsMilestone,
      title: '💎 $milestone Points!',
      message: 'You\'ve reached $totalPoints total points!',
      subtitle: 'Fantastic achievement!',
      icon: Icons.stars,
      primaryColor: Colors.amber,
      secondaryColor: Colors.yellow,
      duration: const Duration(seconds: 4),
      hasConfetti: milestone >= 10000,
      metadata: {
        'totalPoints': totalPoints,
        'milestone': milestone,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  /// Trigger social milestone celebration
  Future<void> celebrateSocialMilestone(
    String userId,
    String milestoneType,
    int count,
  ) async {
    String title = '';
    String message = '';
    IconData icon = Icons.people;
    
    switch (milestoneType) {
      case 'friends':
        title = '👫 $count Friends!';
        message = 'Your friend network is growing!';
        break;
      case 'likes':
        title = '❤️ $count Likes!';
        message = 'People love your posts!';
        icon = Icons.favorite;
        break;
      case 'comments':
        title = '💬 $count Comments!';
        message = 'You\'re great at engaging with the community!';
        icon = Icons.comment;
        break;
      case 'shares':
        title = '📤 $count Shares!';
        message = 'Your content is being shared!';
        icon = Icons.share;
        break;
    }

    final celebration = CelebrationData(
      type: CelebrationMoment.socialMilestone,
      title: title,
      message: message,
      subtitle: 'Social engagement milestone',
      icon: icon,
      primaryColor: Colors.pink,
      secondaryColor: Colors.pinkAccent,
      duration: const Duration(seconds: 3),
      hasConfetti: count >= 100,
      metadata: {
        'milestoneType': milestoneType,
        'count': count,
      },
    );

    await _showCelebration(celebration);
    await _trackCelebrationMoment(userId, celebration);
  }

  // Private helper methods

  Future<void> _showCelebration(CelebrationData celebration) async {
    // Prevent duplicate celebrations within a short time
    final lastTime = _lastCelebrationTimes[celebration.type];
    if (lastTime != null && DateTime.now().difference(lastTime) < const Duration(minutes: 1)) {
      return;
    }

    _activeCelebrations.add(celebration);
    _lastCelebrationTimes[celebration.type] = DateTime.now();

    try {
      // Play sound effect
      if (celebration.hasSound) {
        await _playCelebrationSound(celebration.type);
      }

      // Trigger vibration
      if (celebration.hasVibration) {
        await _triggerVibration(celebration.type);
      }

      // Show visual celebration (this would be integrated with the UI layer)
      debugPrint('🎉 CELEBRATION: ${celebration.title} - ${celebration.message}');
      
      // Simulate celebration duration
      await Future.delayed(celebration.duration);
      
      _activeCelebrations.remove(celebration);
    } catch (e) {
      debugPrint('Error showing celebration: $e');
      _activeCelebrations.remove(celebration);
    }
  }

  Future<void> _trackCelebrationMoment(String userId, CelebrationData celebration) async {
    // Track celebration analytics
    debugPrint('Celebration tracked: ${celebration.type.name} for user $userId');
  }

  Future<void> _playCelebrationSound(CelebrationMoment type) async {
    try {
      String soundFile = '';
      
      switch (type) {
        case CelebrationMoment.firstAchievement:
          soundFile = 'celebration_first.mp3';
          break;
        case CelebrationMoment.tierPromotion:
          soundFile = 'celebration_tier.mp3';
          break;
        case CelebrationMoment.milestoneAchievement:
          soundFile = 'celebration_milestone.mp3';
          break;
        case CelebrationMoment.perfectWeek:
        case CelebrationMoment.perfectMonth:
          soundFile = 'celebration_perfect.mp3';
          break;
        default:
          soundFile = 'celebration_general.mp3';
      }
      
      // This would play the actual sound file
      debugPrint('Playing celebration sound: $soundFile');
    } catch (e) {
      debugPrint('Error playing celebration sound: $e');
    }
  }

  Future<void> _playTierPromotionSound(BadgeTier tier) async {
    try {
      String soundFile = '';
      
      switch (tier) {
        case BadgeTier.bronze:
          soundFile = 'tier_bronze.mp3';
          break;
        case BadgeTier.silver:
          soundFile = 'tier_silver.mp3';
          break;
        case BadgeTier.gold:
          soundFile = 'tier_gold.mp3';
          break;
        case BadgeTier.platinum:
          soundFile = 'tier_platinum.mp3';
          break;
        case BadgeTier.diamond:
          soundFile = 'tier_diamond.mp3';
          break;
      }
      
      debugPrint('Playing tier promotion sound: $soundFile');
    } catch (e) {
      debugPrint('Error playing tier promotion sound: $e');
    }
  }

  Future<void> _triggerVibration(CelebrationMoment type) async {
    try {
      switch (type) {
        case CelebrationMoment.tierPromotion:
        case CelebrationMoment.perfectMonth:
          // Strong vibration for major achievements
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          break;
        case CelebrationMoment.firstAchievement:
        case CelebrationMoment.milestoneAchievement:
        case CelebrationMoment.perfectWeek:
          // Medium vibration
          await HapticFeedback.mediumImpact();
          break;
        default:
          // Light vibration
          await HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error triggering vibration: $e');
    }
  }

  String _getTierDisplayName(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return 'Bronze Tier';
      case BadgeTier.silver:
        return 'Silver Tier';
      case BadgeTier.gold:
        return 'Gold Tier';
      case BadgeTier.platinum:
        return 'Platinum Tier';
      case BadgeTier.diamond:
        return 'Diamond Tier';
    }
  }

  Color _getTierColor(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  Color _getMilestoneColor(String milestoneType) {
    switch (milestoneType) {
      case 'games':
        return Colors.blue;
      case 'social':
        return Colors.pink;
      case 'points':
        return Colors.amber;
      case 'achievements':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  /// Check if celebration should be throttled
  bool shouldThrottleCelebration(CelebrationMoment type) {
    final lastTime = _lastCelebrationTimes[type];
    if (lastTime == null) return false;
    
    const throttleMap = {
      CelebrationMoment.firstAchievement: Duration(hours: 24),
      CelebrationMoment.tierPromotion: Duration(minutes: 30),
      CelebrationMoment.milestoneAchievement: Duration(minutes: 15),
      CelebrationMoment.leaderboardPosition: Duration(minutes: 10),
      CelebrationMoment.badgeCollection: Duration(minutes: 15),
      CelebrationMoment.perfectWeek: Duration(hours: 24),
      CelebrationMoment.perfectMonth: Duration(hours: 24),
      CelebrationMoment.streakMilestone: Duration(minutes: 30),
      CelebrationMoment.pointsMilestone: Duration(minutes: 15),
      CelebrationMoment.socialMilestone: Duration(minutes: 10),
    };
    
    final throttleDuration = throttleMap[type] ?? const Duration(minutes: 5);
    return DateTime.now().difference(lastTime) < throttleDuration;
  }

  /// Get active celebrations
  List<CelebrationData> get activeCelebrations => List.unmodifiable(_activeCelebrations);

  /// Clean up resources
  void dispose() {
    _audioPlayer.dispose();
    _activeCelebrations.clear();
    _lastCelebrationTimes.clear();
  }
}