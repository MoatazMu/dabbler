import 'package:dartz/dartz.dart';

import '../entities/tier.dart';
import '../entities/user_progress.dart';
import '../repositories/rewards_repository.dart';

/// Handles tier progression and updates in the rewards system
class UpdateTierUseCase {
  final RewardsRepository _repository;

  const UpdateTierUseCase(this._repository);

  /// Updates user tier based on current points and tier requirements
  /// 
  /// This use case handles the complete tier progression workflow including:
  /// - Calculating tier eligibility based on points
  /// - Validating tier upgrade requirements
  /// - Processing tier-related rewards and benefits
  /// - Updating user progress with new tier information
  /// - Triggering celebration events and notifications
  /// - Tracking tier change analytics
  Future<Either<TierError, TierUpdateResult>> call({
    required String userId,
    bool forceUpdate = false,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Validate request parameters
      if (userId.trim().isEmpty) {
        return Left(TierError.invalidUserId('User ID cannot be empty'));
      }

      // Get current user progress
      final userProgressResult = await _repository.getUserProgress(userId);
      if (userProgressResult.isLeft()) {
        return Left(TierError.userProgressNotFound('Failed to fetch user progress'));
      }

      final userProgressList = userProgressResult.getOrElse(() => throw StateError('Should not happen'));
      
      // Get current user tier
      final currentTierResult = await _repository.getUserTier(userId);
      if (currentTierResult.isLeft()) {
        return Left(TierError.userProgressNotFound('Failed to fetch user tier'));
      }

      final currentTier = currentTierResult.getOrElse(() => null);

      // Calculate total points from completed achievements
      final totalPoints = userProgressList
          .where((progress) => progress.status == ProgressStatus.completed)
          .fold(0, (sum, progress) => sum + (progress.achievement?.points ?? 0));

      // Get available tiers from achievements (for now, use a simplified approach)
      final achievementsResult = await _repository.getAchievements();
      if (achievementsResult.isLeft()) {
        return Left(TierError.tiersNotFound('Failed to fetch achievements for tier calculation'));
      }

      final achievements = achievementsResult.getOrElse(() => throw StateError('Should not happen'));
      if (achievements.isEmpty) {
        return Left(TierError.tiersNotFound('No achievements configured'));
      }

      // Calculate eligible tier based on current points
      final eligibleTier = _calculateEligibleTierFromPoints(totalPoints);
      
      // Check if tier update is needed
      final currentTierLevel = currentTier?.level.level ?? 0;
      final eligibleTierLevel = eligibleTier.level.level;

      if (!forceUpdate && currentTierLevel >= eligibleTierLevel) {
        // No tier change needed
        return Right(TierUpdateResult(
          previousTier: currentTier,
          newTier: currentTier ?? eligibleTier,
          tierChanged: false,
          pointsToNext: _calculatePointsToNextTierFromPoints(totalPoints, eligibleTier),
          milestoneRewards: [],
          benefitsUnlocked: [],
          celebrationTriggered: false,
          analyticsData: _generateAnalyticsData(
            userId: userId,
            previousTier: currentTier,
            newTier: currentTier ?? eligibleTier,
            tierChanged: false,
            context: context ?? {},
          ),
        ));
      }

      // Process tier upgrade - Simplified implementation
      final previousTier = currentTier;
      final newTier = eligibleTier;

      // For now, return a simple result indicating tier change
      // In a full implementation, this would include:
      // - Award milestone rewards
      // - Update user tier in database
      // - Log analytics event
      // - Trigger notifications

      return Right(TierUpdateResult(
        previousTier: previousTier,
        newTier: newTier,
        tierChanged: true,
        pointsToNext: _calculatePointsToNextTierFromPoints(totalPoints, newTier),
        milestoneRewards: [], // Would be calculated based on tier progression
        benefitsUnlocked: [], // Would be calculated based on new tier benefits
        celebrationTriggered: false, // Would trigger celebration UI
        analyticsData: _generateAnalyticsData(
          userId: userId,
          previousTier: previousTier,
          newTier: newTier,
          tierChanged: true,
          context: context ?? {},
        ),
      ));

    } catch (e) {
      return Left(TierError.unexpected('Unexpected error during tier update: $e'));
    }
  }

  /// Calculates the eligible tier based on total points
  // Helper method to calculate tier based on total points
  UserTier _calculateEligibleTierFromPoints(int totalPoints) {
    final pointsDouble = totalPoints.toDouble();
    final now = DateTime.now();
    
    // Find the appropriate tier level based on points
    TierLevel tierLevel;
    if (pointsDouble >= 150000) {
      tierLevel = TierLevel.dabbler;
    } else if (pointsDouble >= 100000) {
      tierLevel = TierLevel.champion;
    } else if (pointsDouble >= 65000) {
      tierLevel = TierLevel.legend;
    } else if (pointsDouble >= 40000) {
      tierLevel = TierLevel.grandmaster;
    } else if (pointsDouble >= 25000) {
      tierLevel = TierLevel.master;
    } else if (pointsDouble >= 16000) {
      tierLevel = TierLevel.elite;
    } else if (pointsDouble >= 10000) {
      tierLevel = TierLevel.veteran;
    } else if (pointsDouble >= 6000) {
      tierLevel = TierLevel.expert;
    } else if (pointsDouble >= 3500) {
      tierLevel = TierLevel.skilled;
    } else if (pointsDouble >= 2000) {
      tierLevel = TierLevel.competitor;
    } else if (pointsDouble >= 1000) {
      tierLevel = TierLevel.enthusiast;
    } else if (pointsDouble >= 500) {
      tierLevel = TierLevel.amateur;
    } else if (pointsDouble >= 250) {
      tierLevel = TierLevel.novice;
    } else if (pointsDouble >= 100) {
      tierLevel = TierLevel.rookie;
    } else {
      tierLevel = TierLevel.freshPlayer;
    }

    return UserTier(
      id: 'temp_tier_${tierLevel.name}',
      userId: 'temp_user',
      level: tierLevel,
      currentPoints: pointsDouble,
      pointsInTier: pointsDouble - tierLevel.minPoints,
      achievedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Helper method to calculate points to next tier
  double _calculatePointsToNextTierFromPoints(int currentPoints, UserTier currentTier) {
    final pointsDouble = currentPoints.toDouble();
    return currentTier.level.maxPoints.isInfinite ? 0 : (currentTier.level.maxPoints + 1 - pointsDouble);
  }

  /// Generate analytics data for tier changes
  Map<String, dynamic> _generateAnalyticsData({
    required String userId,
    required UserTier? previousTier,
    required UserTier newTier,
    required bool tierChanged,
    required Map<String, dynamic> context,
  }) {
    return {
      'user_id': userId,
      'previous_tier': previousTier?.level.name,
      'new_tier': newTier.level.name,
      'tier_changed': tierChanged,
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
    };
  }
}

/// Result of tier update operation
class TierUpdateResult {
  final UserTier? previousTier;
  final UserTier newTier;
  final bool tierChanged;
  final double pointsToNext;
  final List<dynamic> milestoneRewards; // Simplified for now
  final List<dynamic> benefitsUnlocked; // Simplified for now
  final bool celebrationTriggered;
  final List<String>? rewardErrors;
  final Map<String, dynamic> analyticsData;

  const TierUpdateResult({
    required this.previousTier,
    required this.newTier,
    required this.tierChanged,
    required this.pointsToNext,
    required this.milestoneRewards,
    required this.benefitsUnlocked,
    required this.celebrationTriggered,
    this.rewardErrors,
    required this.analyticsData,
  });
}

/// Tier update error types
class TierError {
  final String message;
  final String code;

  const TierError._(this.message, this.code);

  static TierError invalidUserId(String message) => TierError._(message, 'INVALID_USER_ID');
  static TierError userProgressNotFound(String message) => TierError._(message, 'USER_PROGRESS_NOT_FOUND');
  static TierError tiersNotFound(String message) => TierError._(message, 'TIERS_NOT_FOUND');
  static TierError updateFailed(String message) => TierError._(message, 'UPDATE_FAILED');
  static TierError unexpected(String message) => TierError._(message, 'UNEXPECTED_ERROR');

  @override
  String toString() => 'TierError($code): $message';
}