import '../entities/achievement.dart';
import '../entities/user_progress.dart';
import '../entities/badge.dart';
import '../entities/badge_tier.dart';
import '../entities/point_transaction.dart';
import '../entities/tier.dart';
import '../repositories/rewards_repository.dart';

/// Result of awarding an achievement
class AwardAchievementResult {
  final bool success;
  final Achievement? achievement;
  final int pointsAwarded;
  final List<Badge> badgesAwarded;
  final TierLevel? newTier;
  final UserProgress updatedProgress;
  final String? celebrationMessage;
  final Map<String, dynamic> metadata;
  final List<String> errors;

  const AwardAchievementResult({
    required this.success,
    this.achievement,
    required this.pointsAwarded,
    this.badgesAwarded = const [],
    this.newTier,
    required this.updatedProgress,
    this.celebrationMessage,
    this.metadata = const {},
    this.errors = const [],
  });

  /// Whether a tier upgrade occurred
  bool get hasTierUpgrade => newTier != null;

  /// Whether any badges were awarded
  bool get hasBadges => badgesAwarded.isNotEmpty;

  /// Whether points were awarded
  bool get hasPoints => pointsAwarded > 0;

  /// Whether celebration should be shown
  bool get shouldCelebrate => success && (hasPoints || hasBadges || hasTierUpgrade);
}

/// Use case for awarding achievements with full business logic
class AwardAchievementUseCase {
  final RewardsRepository _repository;

  AwardAchievementUseCase({
    required RewardsRepository repository,
  }) : _repository = repository;

  /// Award an achievement to a user with full validation and business logic
  Future<AwardAchievementResult> execute({
    required String userId,
    required String achievementId,
    Map<String, dynamic> eventContext = const {},
    bool force = false,
  }) async {
    try {
      // Step 1: Get achievement details
      final achievementResult = await _repository.getAchievementById(achievementId);
      final achievement = achievementResult.fold(
        (failure) => null,
        (achievement) => achievement,
      );
      
      if (achievement == null) {
        return AwardAchievementResult(
          success: false,
          pointsAwarded: 0,
          updatedProgress: _createEmptyProgress(userId, achievementId),
          errors: ['Achievement not found: $achievementId'],
        );
      }

      // Step 2: Get current user progress
      final progressResult = await _repository.getUserProgressForAchievement(
        userId,
        achievementId,
      );
      
      final currentProgress = progressResult.fold(
        (failure) => null,
        (progress) => progress,
      );

      if (currentProgress == null) {
        return AwardAchievementResult(
          success: false,
          pointsAwarded: 0,
          updatedProgress: _createEmptyProgress(userId, achievementId),
          errors: ['User progress not found for achievement: $achievementId'],
        );
      }

      // Step 3: Check if already completed (unless repeatable or forced)
      if (currentProgress.status == ProgressStatus.completed && 
          !achievement.type.isRepeatable && 
          !force) {
        return AwardAchievementResult(
          success: false,
          pointsAwarded: 0,
          updatedProgress: currentProgress,
          errors: ['Achievement already completed and not repeatable'],
        );
      }

      // Step 4: Validate achievement criteria
      final criteriaValidation = await _validateAchievementCriteria(
        achievement,
        currentProgress,
        eventContext,
      );

      if (!criteriaValidation.isValid && !force) {
        return AwardAchievementResult(
          success: false,
          pointsAwarded: 0,
          updatedProgress: currentProgress,
          errors: criteriaValidation.errors,
        );
      }

      // Step 5: Check prerequisites
      final prerequisiteCheck = await _checkPrerequisites(userId, achievement);
      if (!prerequisiteCheck.passed && !force) {
        return AwardAchievementResult(
          success: false,
          pointsAwarded: 0,
          updatedProgress: currentProgress,
          errors: prerequisiteCheck.errors,
        );
      }

      // Step 6: Calculate points and apply multipliers
      final pointsCalculation = await _calculateAchievementPoints(
        userId,
        achievement,
        eventContext,
      );

      // Step 7: Award points and create transaction
      PointTransaction? transaction;
      if (pointsCalculation.totalPoints > 0) {
        final transactionResult = await _repository.awardPoints(
          userId,
          pointsCalculation.basePoints,
          'Achievement completed: ${achievement.name}',
          metadata: {
            'achievement_id': achievementId,
            'multipliers': pointsCalculation.multipliers,
            'total_points': pointsCalculation.totalPoints,
            'event_context': eventContext,
          },
        );
        transaction = transactionResult.fold(
          (failure) => null,
          (pointTransaction) => pointTransaction,
        );
      }

      // Step 8: Award badges
      final badgesAwarded = await _awardAssociatedBadges(
        userId,
        achievement,
        eventContext,
      );

      // Step 9: Update progress to completed
      final updatedProgress = await _updateAchievementProgress(
        currentProgress,
        achievement,
        eventContext,
      );

      // Step 10: Update user statistics
      await _updateUserStatistics(
        userId,
        achievement,
        pointsCalculation.totalPoints,
        badgesAwarded,
      );

      // Step 11: Check for tier upgrade
      final tierUpgrade = await _checkTierUpgrade(userId);

      // Step 12: Create celebration event
      final celebrationMessage = _createCelebrationMessage(
        achievement,
        pointsCalculation.totalPoints,
        badgesAwarded,
        tierUpgrade,
      );

      // Step 13: Queue notifications
      await _queueNotifications(
        userId,
        achievement,
        pointsCalculation.totalPoints,
        badgesAwarded,
        tierUpgrade,
        celebrationMessage,
      );

      // Step 14: Handle repeatable achievement reset
      if (achievement.type.isRepeatable) {
        await _handleRepeatableReset(updatedProgress, achievement);
      }

      // Step 15: Track analytics
      await _trackAchievementAnalytics(
        userId,
        achievement,
        pointsCalculation.totalPoints,
        badgesAwarded.length,
        eventContext,
      );

      return AwardAchievementResult(
        success: true,
        achievement: achievement,
        pointsAwarded: pointsCalculation.totalPoints,
        badgesAwarded: badgesAwarded,
        newTier: tierUpgrade,
        updatedProgress: updatedProgress,
        celebrationMessage: celebrationMessage,
        metadata: {
          'transaction_id': transaction?.id,
          'badges_count': badgesAwarded.length,
          'multipliers_applied': pointsCalculation.multipliers,
          'event_context': eventContext,
        },
      );

    } catch (error) {
      return AwardAchievementResult(
        success: false,
        pointsAwarded: 0,
        updatedProgress: _createEmptyProgress(userId, achievementId),
        errors: ['Failed to award achievement: $error'],
      );
    }
  }

  // =============================================================================
  // VALIDATION METHODS
  // =============================================================================

  /// Validate achievement criteria
  Future<_CriteriaValidation> _validateAchievementCriteria(
    Achievement achievement,
    UserProgress currentProgress,
    Map<String, dynamic> eventContext,
  ) async {
    final errors = <String>[];

    // Check if achievement is active
    if (!achievement.isActive) {
      errors.add('Achievement is not active');
    }

    // Check availability window
    final now = DateTime.now();
    if (achievement.availableFrom != null && now.isBefore(achievement.availableFrom!)) {
      errors.add('Achievement not yet available');
    }
    if (achievement.availableUntil != null && now.isAfter(achievement.availableUntil!)) {
      errors.add('Achievement is no longer available');
    }

    // Validate specific criteria based on achievement type
    switch (achievement.type) {
      case AchievementType.single:
        if (!_validateStandardCriteria(achievement.criteria, currentProgress)) {
          errors.add('Single achievement criteria not met');
        }
        break;

      case AchievementType.cumulative:
        if (!_validateStandardCriteria(achievement.criteria, currentProgress)) {
          errors.add('Cumulative criteria not met');
        }
        break;

      case AchievementType.conditional:
        if (!_validateStandardCriteria(achievement.criteria, currentProgress)) {
          errors.add('Conditional criteria not met');
        }
        break;

      case AchievementType.hidden:
        if (!_validateStandardCriteria(achievement.criteria, currentProgress)) {
          errors.add('Hidden criteria not met');
        }
        break;

      case AchievementType.standard:
        if (!_validateStandardCriteria(achievement.criteria, currentProgress)) {
          errors.add('Standard criteria not met');
        }
        break;

      case AchievementType.milestone:
        if (!_validateMilestoneCriteria(achievement.criteria, eventContext)) {
          errors.add('Milestone criteria not met');
        }
        break;

      case AchievementType.streak:
        if (!_validateStreakCriteria(achievement.criteria, eventContext)) {
          errors.add('Streak criteria not met');
        }
        break;

      case AchievementType.social:
        if (!_validateSocialCriteria(achievement.criteria, eventContext)) {
          errors.add('Social criteria not met');
        }
        break;

      case AchievementType.challenge:
        if (!_validateChallengeCriteria(achievement.criteria, eventContext)) {
          errors.add('Challenge criteria not met');
        }
        break;
    }

    return _CriteriaValidation(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Check if all prerequisites are completed
  Future<_PrerequisiteCheck> _checkPrerequisites(
    String userId,
    Achievement achievement,
  ) async {
    if (achievement.prerequisites.isEmpty) {
      return _PrerequisiteCheck(passed: true, errors: []);
    }

    final errors = <String>[];
    for (final prerequisiteId in achievement.prerequisites) {
      final prerequisiteResult = await _repository.getUserProgressForAchievement(
        userId,
        prerequisiteId,
      );
      
      final prerequisiteProgress = prerequisiteResult.fold(
        (failure) => null,
        (progress) => progress,
      );

      if (prerequisiteProgress == null || 
          prerequisiteProgress.status != ProgressStatus.completed) {
        final prerequisiteResult = await _repository.getAchievementById(prerequisiteId);
        final prerequisiteAchievement = prerequisiteResult.fold(
          (failure) => null,
          (achievement) => achievement,
        );
        errors.add('Prerequisite not completed: ${prerequisiteAchievement?.name ?? prerequisiteId}');
      }
    }

    return _PrerequisiteCheck(
      passed: errors.isEmpty,
      errors: errors,
    );
  }

  // =============================================================================
  // CRITERIA VALIDATION HELPERS
  // =============================================================================

  bool _validateProgressCriteria(Map<String, dynamic> criteria, UserProgress progress) {
    final requiredProgress = criteria['required'] as Map<String, dynamic>? ?? {};
    
    for (final entry in requiredProgress.entries) {
      final key = entry.key;
      final requiredValue = entry.value;
      final currentValue = progress.currentProgress[key];
      
      if (currentValue == null || !_compareValues(currentValue, requiredValue)) {
        return false;
      }
    }
    
    return true;
  }
  
  bool _validateStandardCriteria(Map<String, dynamic> criteria, UserProgress progress) {
    // For standard achievements, use the same logic as progress criteria
    return _validateProgressCriteria(criteria, progress);
  }

  bool _validateMilestoneCriteria(Map<String, dynamic> criteria, Map<String, dynamic> context) {
    final milestoneValue = criteria['milestone_value'];
    final contextValue = context[criteria['context_key']];
    
    return contextValue != null && _compareValues(contextValue, milestoneValue);
  }

  bool _validateStreakCriteria(Map<String, dynamic> criteria, Map<String, dynamic> context) {
    final requiredStreak = criteria['required_streak'] as int? ?? 0;
    final currentStreak = context['streak'] as int? ?? 0;
    
    return currentStreak >= requiredStreak;
  }

  bool _validateSocialCriteria(Map<String, dynamic> criteria, Map<String, dynamic> context) {
    final socialType = criteria['social_type'] as String?;
    
    switch (socialType) {
      case 'friends_invited':
        final required = criteria['required_invites'] as int? ?? 0;
        final actual = context['friends_invited'] as int? ?? 0;
        return actual >= required;
        
      case 'games_with_friends':
        final required = criteria['required_games'] as int? ?? 0;
        final actual = context['games_with_friends'] as int? ?? 0;
        return actual >= required;
        
      default:
        return false;
    }
  }

  bool _validateChallengeCriteria(Map<String, dynamic> criteria, Map<String, dynamic> context) {
    final challengeId = criteria['challenge_id'] as String?;
    final completedChallenges = context['completed_challenges'] as List<String>? ?? [];
    
    return challengeId != null && completedChallenges.contains(challengeId);
  }

  bool _compareValues(dynamic actual, dynamic required) {
    if (actual is num && required is num) {
      return actual >= required;
    } else if (actual is String && required is String) {
      return actual == required;
    } else if (actual is bool && required is bool) {
      return actual == required;
    }
    return false;
  }

  // =============================================================================
  // POINTS AND REWARDS
  // =============================================================================

  /// Calculate achievement points with multipliers
  Future<_PointsCalculation> _calculateAchievementPoints(
    String userId,
    Achievement achievement,
    Map<String, dynamic> eventContext,
  ) async {
    final basePoints = achievement.points;
    var totalPoints = basePoints;
    final multipliers = <String, double>{};

    // Get user's current tier for tier multiplier
    try {
      final userStatsResult = await _repository.getUserStats(userId);
      if (userStatsResult.isRight()) {
        final userStats = userStatsResult.getOrElse(() => null);
        if (userStats != null) {
          // Tier multiplier (higher tiers get small bonus)
          final totalAchievements = userStats['total_achievements'] as int? ?? 0;
          final tierMultiplier = 1.0 + (totalAchievements * 0.01);
          multipliers['tier'] = tierMultiplier;
          totalPoints = (totalPoints * tierMultiplier).round();

          // Streak multiplier
          final streakDays = userStats['streak_days'] as int? ?? 0;
          if (streakDays > 0) {
            final streakMultiplier = 1.0 + (streakDays * 0.02);
            multipliers['streak'] = streakMultiplier;
            totalPoints = (totalPoints * streakMultiplier).round();
          }
        }
      }

      // Difficulty multiplier
      switch (achievement.tier) {
        case BadgeTier.bronze:
          multipliers['difficulty'] = 1.0;
          break;
        case BadgeTier.silver:
          multipliers['difficulty'] = 1.2;
          totalPoints = (totalPoints * 1.2).round();
          break;
        case BadgeTier.gold:
          multipliers['difficulty'] = 1.5;
          totalPoints = (totalPoints * 1.5).round();
          break;
        case BadgeTier.platinum:
          multipliers['difficulty'] = 2.0;
          totalPoints = (totalPoints * 2.0).round();
          break;
        case BadgeTier.diamond:
          multipliers['difficulty'] = 3.0;
          totalPoints = (totalPoints * 3.0).round();
          break;
      }

      // Special event multiplier
      if (eventContext.containsKey('special_event')) {
        final eventMultiplier = eventContext['event_multiplier'] as double? ?? 1.5;
        multipliers['event'] = eventMultiplier;
        totalPoints = (totalPoints * eventMultiplier).round();
      }

      // First-time completion bonus
      if (eventContext['first_completion'] == true) {
        multipliers['first_time'] = 1.1;
        totalPoints = (totalPoints * 1.1).round();
      }

    } catch (error) {
      // Fallback to base points if calculation fails
      totalPoints = basePoints;
    }

    return _PointsCalculation(
      basePoints: basePoints,
      totalPoints: totalPoints,
      multipliers: multipliers,
    );
  }

  /// Award badges associated with achievement
  Future<List<Badge>> _awardAssociatedBadges(
    String userId,
    Achievement achievement,
    Map<String, dynamic> eventContext,
  ) async {
    final badges = <Badge>[];

    try {
      // Get badges for this achievement
      final badgeResult = await _repository.getBadgesForAchievement(achievement.id);
      
      if (badgeResult.isRight()) {
        final achievementBadges = badgeResult.getOrElse(() => []);
        for (final badge in achievementBadges) {
          // Check if user already has this badge
          final userBadgesResult = await _repository.getUserBadges(userId);
          if (userBadgesResult.isRight()) {
            final userBadges = userBadgesResult.getOrElse(() => []);
            final alreadyHas = userBadges.any((b) => b.id == badge.id);
            
            if (!alreadyHas) {
              // Award the badge
              await _repository.awardBadge(userId, badge.id);
              badges.add(badge);
            }
          }
        }
      }

      // Check for special tier-based badges
      final tierBadge = await _checkTierBadge(userId, achievement);
      if (tierBadge != null) {
        badges.add(tierBadge);
      }

      // Check for streak badges
      final streakBadge = await _checkStreakBadge(userId, eventContext);
      if (streakBadge != null) {
        badges.add(streakBadge);
      }

    } catch (error) {
      // Log error but don't fail the entire operation
      print('Error awarding badges: $error');
    }

    return badges;
  }

  // =============================================================================
  // PROGRESS AND STATISTICS
  // =============================================================================

  /// Update achievement progress to completed
  Future<UserProgress> _updateAchievementProgress(
    UserProgress currentProgress,
    Achievement achievement,
    Map<String, dynamic> eventContext,
  ) async {
    final now = DateTime.now();
    
    // Mark as completed with full progress
    final updatedProgress = currentProgress.copyWith(
      currentProgress: achievement.criteria,
      status: ProgressStatus.completed,
      completedAt: now,
      updatedAt: now,
      metadata: {
        ...currentProgress.metadata ?? {},
        'completion_context': eventContext,
        'completed_at': now.toIso8601String(),
      },
    );

    // Save to repository
    await _repository.updateUserProgress(updatedProgress);
    
    return updatedProgress;
  }

  /// Update user statistics
  Future<void> _updateUserStatistics(
    String userId,
    Achievement achievement,
    int pointsAwarded,
    List<Badge> badgesAwarded,
  ) async {
    try {
      // This would typically update user stats
      // Implementation depends on your UserStats structure
      await _repository.incrementUserStats(
        userId,
        {
          'achievements_completed': 1,
          'points_earned': pointsAwarded,
          'badges_earned': badgesAwarded.length,
          'category': achievement.category.name,
        },
      );
    } catch (error) {
      print('Error updating user statistics: $error');
    }
  }

  /// Check for tier upgrade
  Future<TierLevel?> _checkTierUpgrade(String userId) async {
    try {
      final userTierResult = await _repository.getUserTier(userId);
      final userStatsResult = await _repository.getUserStats(userId);
      
      if (userTierResult.isRight() && userStatsResult.isRight()) {
        final userTier = userTierResult.getOrElse(() => null);
        final userStats = userStatsResult.getOrElse(() => null);
        
        if (userTier != null && userStats != null) {
          // Simplified tier checking - would need proper implementation
          // For now, just return null to avoid compilation errors
        }
      }
    } catch (error) {
      print('Error checking tier upgrade: $error');
    }
    
    return null;
  }

  // =============================================================================
  // NOTIFICATIONS AND CELEBRATIONS
  // =============================================================================

  /// Create celebration message
  String _createCelebrationMessage(
    Achievement achievement,
    int pointsAwarded,
    List<Badge> badgesAwarded,
    TierLevel? tierUpgrade,
  ) {
    final messages = <String>[];
    
    // Achievement completion
    messages.add('🎉 Achievement unlocked: ${achievement.name}!');
    
    // Points awarded
    if (pointsAwarded > 0) {
      messages.add('💰 +$pointsAwarded points earned!');
    }
    
    // Badges awarded
    if (badgesAwarded.isNotEmpty) {
      messages.add('🏆 ${badgesAwarded.length} badge${badgesAwarded.length > 1 ? 's' : ''} earned!');
    }
    
    // Tier upgrade
    if (tierUpgrade != null) {
      messages.add('⭐ Tier upgraded to ${tierUpgrade.displayName}!');
    }
    
    return messages.join('\n');
  }

  /// Queue notifications
  Future<void> _queueNotifications(
    String userId,
    Achievement achievement,
    int pointsAwarded,
    List<Badge> badgesAwarded,
    TierLevel? tierUpgrade,
    String celebrationMessage,
  ) async {
    try {
      // Queue achievement notification
      await _repository.queueNotification(
        userId: userId,
        type: 'achievement_completed',
        title: 'Achievement Unlocked!',
        message: achievement.name,
        data: {
          'achievement_id': achievement.id,
          'points_awarded': pointsAwarded,
          'badges_awarded': badgesAwarded.map((b) => b.id).toList(),
          'tier_upgrade': tierUpgrade?.displayName,
          'celebration_message': celebrationMessage,
        },
      );

      // Queue tier upgrade notification if applicable
      if (tierUpgrade != null) {
        await _repository.queueNotification(
          userId: userId,
          type: 'tier_upgrade',
          title: 'Tier Upgrade!',
          message: 'Congratulations! You\'ve reached ${tierUpgrade.displayName}!',
          data: {'new_tier': tierUpgrade.displayName},
        );
      }

    } catch (error) {
      print('Error queuing notifications: $error');
    }
  }

  /// Handle repeatable achievement reset
  Future<void> _handleRepeatableReset(
    UserProgress progress,
    Achievement achievement,
  ) async {
    if (!achievement.type.isRepeatable) return;

    try {
      // Reset progress for next completion
      final resetProgress = progress.copyWith(
        currentProgress: {},
        status: ProgressStatus.inProgress,
        completedAt: null,
        updatedAt: DateTime.now(),
        metadata: {
          ...progress.metadata ?? {},
          'reset_for_repeat': true,
          'completion_count': (progress.metadata?['completion_count'] ?? 0) + 1,
        },
      );

      await _repository.updateUserProgress(resetProgress);
    } catch (error) {
      print('Error resetting repeatable achievement: $error');
    }
  }

  // =============================================================================
  // ANALYTICS AND TRACKING
  // =============================================================================

  /// Track achievement analytics
  Future<void> _trackAchievementAnalytics(
    String userId,
    Achievement achievement,
    int pointsAwarded,
    int badgesAwarded,
    Map<String, dynamic> eventContext,
  ) async {
    try {
      await _repository.trackEvent(
        EventType.achievementView, // Using achievementView as closest match
        {
          'user_id': userId,
          'achievement_id': achievement.id,
          'achievement_category': achievement.category.name,
          'achievement_tier': achievement.tier.name,
          'points_awarded': pointsAwarded,
          'badges_awarded': badgesAwarded,
          'event_context': eventContext,
          'completion_time': DateTime.now().toIso8601String(),
        },
        userId,
      );
    } catch (error) {
      print('Error tracking achievement analytics: $error');
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Create empty progress for error cases
  UserProgress _createEmptyProgress(String userId, String achievementId) {
    final now = DateTime.now();
    return UserProgress(
      id: '${userId}_$achievementId',
      userId: userId,
      achievementId: achievementId,
      currentProgress: {},
      requiredProgress: {},
      status: ProgressStatus.notStarted,
      startedAt: now,
      updatedAt: now,
    );
  }

  /// Check for tier-specific badges
  Future<Badge?> _checkTierBadge(String userId, Achievement achievement) async {
    // Implementation for tier-specific badge logic
    return null;
  }

  /// Check for streak badges
  Future<Badge?> _checkStreakBadge(String userId, Map<String, dynamic> context) async {
    // Implementation for streak badge logic
    return null;
  }
}

// =============================================================================
// HELPER CLASSES
// =============================================================================

class _CriteriaValidation {
  final bool isValid;
  final List<String> errors;

  _CriteriaValidation({
    required this.isValid,
    required this.errors,
  });
}

class _PrerequisiteCheck {
  final bool passed;
  final List<String> errors;

  _PrerequisiteCheck({
    required this.passed,
    required this.errors,
  });
}

class _PointsCalculation {
  final int basePoints;
  final int totalPoints;
  final Map<String, double> multipliers;

  _PointsCalculation({
    required this.basePoints,
    required this.totalPoints,
    required this.multipliers,
  });
}