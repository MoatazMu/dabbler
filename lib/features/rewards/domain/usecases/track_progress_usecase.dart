import 'package:dartz/dartz.dart';

import '../entities/achievement.dart';
import '../entities/user_progress.dart';
import '../repositories/rewards_repository.dart';

/// Tracks and calculates progress for achievements and user milestones
class TrackProgressUseCase {
  final RewardsRepository _repository;

  const TrackProgressUseCase(this._repository);

  /// Tracks progress for a specific achievement
  /// 
  /// This use case handles comprehensive progress tracking including:
  /// - Current progress calculation and validation
  /// - Percentage completion with accurate ratios
  /// - Milestone detection and celebration triggers
  /// - Progress history and trending analysis
  /// - Multi-criteria achievement progress
  /// - Time-based progress tracking
  Future<Either<ProgressError, ProgressTrackingResult>> trackAchievementProgress({
    required String userId,
    required String achievementId,
    Map<String, dynamic>? additionalData,
    bool updateHistory = true,
  }) async {
    try {
      // Validate input parameters
      if (userId.trim().isEmpty) {
        return Left(ProgressError.invalidInput('User ID cannot be empty'));
      }
      if (achievementId.trim().isEmpty) {
        return Left(ProgressError.invalidInput('Achievement ID cannot be empty'));
      }

      // Get achievement details
      final achievementResult = await _repository.getAchievementById(achievementId);
      if (achievementResult.isLeft()) {
        return Left(ProgressError.achievementNotFound('Achievement not found: $achievementId'));
      }

      final achievement = achievementResult.getOrElse(() => throw StateError('Should not happen'));

      // Get user progress data
      final userProgressResult = await _repository.getUserProgress(userId);
      if (userProgressResult.isLeft()) {
        return Left(ProgressError.userProgressNotFound('User progress not found'));
      }

      final userProgressList = userProgressResult.getOrElse(() => throw StateError('Should not happen'));
      
      // Find progress for this specific achievement
      final userProgress = userProgressList
          .where((progress) => progress.achievementId == achievementId)
          .firstOrNull;

      // Calculate current progress based on achievement type
      final currentProgress = userProgress?.calculateProgress() ?? 0.0;

      // Calculate percentage completion
      final progressPercentage = currentProgress;

      // Detect milestone achievements
      final milestonesReached = _detectMilestones(
        achievement: achievement,
        currentProgress: currentProgress,
        previousProgress: 0.0, // Previous progress would need to be tracked separately
      );

      // Get progress history if requested
      final progressHistory = updateHistory ? 
        await _getProgressHistory(userId, achievementId) : 
        <ProgressHistoryEntry>[];

      // Check if achievement is completed
      final isCompleted = userProgress?.isComplete() ?? false;
      final isNewCompletion = isCompleted && userProgress?.status != ProgressStatus.completed;

      // Calculate progress trend
      final progressTrend = _calculateProgressTrend(progressHistory, currentProgress);

      // Estimate completion time
      final estimatedCompletion = _estimateCompletionTime(
        achievement: achievement,
        currentProgress: currentProgress,
        progressTrend: progressTrend,
      );

      // Generate progress insights
      final insights = _generateProgressInsights(
        achievement: achievement,
        currentProgress: currentProgress,
        progressPercentage: progressPercentage,
        progressTrend: progressTrend,
        milestonesReached: milestonesReached,
      );

      return Right(ProgressTrackingResult(
        achievementId: achievementId,
        userId: userId,
        currentProgress: currentProgress,
        requiredProgress: 100.0, // Progress is already in percentage
        progressPercentage: progressPercentage,
        isCompleted: isCompleted,
        isNewCompletion: isNewCompletion,
        milestonesReached: milestonesReached,
        progressHistory: progressHistory,
        progressTrend: progressTrend,
        estimatedCompletion: estimatedCompletion,
        insights: insights,
        lastUpdated: DateTime.now(),
      ));

    } catch (e) {
      return Left(ProgressError.unexpected('Unexpected error tracking progress: $e'));
    }
  }

  /// Tracks overall user progress across all achievements
  Future<Either<ProgressError, OverallProgressResult>> trackOverallProgress({
    required String userId,
    AchievementCategory? category,
    int? timeFrameDays,
  }) async {
    try {
      // Get user progress
      final userProgressResult = await _repository.getUserProgress(userId);
      if (userProgressResult.isLeft()) {
        return Left(ProgressError.userProgressNotFound('User progress not found'));
      }

      final userProgressList = userProgressResult.getOrElse(() => throw StateError('Should not happen'));

      // Get all achievements (filtered by category if specified)
      final achievementsResult = await _repository.getAchievements(
        category: category,
        includeHidden: false,
      );
      
      if (achievementsResult.isLeft()) {
        return Left(ProgressError.dataNotFound('Failed to fetch achievements'));
      }

      final achievements = achievementsResult.getOrElse(() => throw StateError('Should not happen'));

      // Calculate overall statistics
      final totalAchievements = achievements.length;
      final completedAchievements = userProgressList
        .where((progress) => progress.status == ProgressStatus.completed)
        .length;
      
      final inProgressAchievements = userProgressList
        .where((progress) => progress.status == ProgressStatus.inProgress)
        .length;

      final completionRate = totalAchievements > 0 ? 
        (completedAchievements / totalAchievements) * 100 : 0.0;

      // Calculate progress by category
      final progressByCategory = <String, CategoryProgress>{};
      final categorizedAchievements = _groupAchievementsByCategory(achievements);
      
      for (final categoryName in categorizedAchievements.keys) {
        final categoryAchievements = categorizedAchievements[categoryName]!;
        final categoryCompleted = userProgressList
          .where((progress) => 
            categoryAchievements.any((ach) => ach.id == progress.achievementId) &&
            progress.status == ProgressStatus.completed)
          .length;
        final categoryTotal = categoryAchievements.length;
        
        progressByCategory[categoryName] = CategoryProgress(
          category: categoryName,
          totalAchievements: categoryTotal,
          completedAchievements: categoryCompleted,
          completionRate: categoryTotal > 0 ? (categoryCompleted / categoryTotal) * 100 : 0.0,
          averageProgress: _calculateAverageCategoryProgress(
            categoryAchievements, 
            userProgressList,
          ),
        );
      }

      // Get recent activity
      final recentActivity = await _getRecentProgressActivity(
        userId: userId,
        days: timeFrameDays ?? 30,
      );

      // Calculate progress velocity (achievements per day)
      final progressVelocity = _calculateProgressVelocity(
        recentActivity: recentActivity,
        timeFrameDays: timeFrameDays ?? 30,
      );

      // Identify recommended next achievements
      final recommendedAchievements = _getRecommendedAchievements(
        achievements: achievements,
        userProgressList: userProgressList,
        limit: 5,
      );

      return Right(OverallProgressResult(
        userId: userId,
        totalAchievements: totalAchievements,
        completedAchievements: completedAchievements,
        inProgressAchievements: inProgressAchievements,
        completionRate: completionRate,
        progressByCategory: progressByCategory,
        recentActivity: recentActivity,
        progressVelocity: progressVelocity,
        recommendedAchievements: recommendedAchievements,
        lastUpdated: DateTime.now(),
      ));

    } catch (e) {
      return Left(ProgressError.unexpected('Unexpected error tracking overall progress: $e'));
    }
  }

  /// Detects milestone achievements
  List<ProgressMilestone> _detectMilestones({
    required Achievement achievement,
    required double currentProgress,
    required double previousProgress,
  }) {
    final milestones = <ProgressMilestone>[];

    // Standard percentage milestones
    final percentageMilestones = [25.0, 50.0, 75.0, 90.0];
    
    for (final milestone in percentageMilestones) {
      // Check if milestone was just reached
      if (currentProgress >= milestone && previousProgress < milestone) {
        milestones.add(ProgressMilestone(
          type: MilestoneType.percentage,
          value: milestone,
          achievedAt: DateTime.now(),
          description: '${milestone.toInt()}% progress milestone',
        ));
      }
    }

    return milestones;
  }

  /// Gets progress history for an achievement (simplified)
  Future<List<ProgressHistoryEntry>> _getProgressHistory(
    String userId, 
    String achievementId,
  ) async {
    // Simplified implementation - return empty list
    // In a real implementation, this would fetch from a history table
    return <ProgressHistoryEntry>[];
  }

  /// Calculates progress trend
  ProgressTrend _calculateProgressTrend(
    List<ProgressHistoryEntry> history, 
    double currentProgress,
  ) {
    if (history.length < 2) {
      return ProgressTrend.stable;
    }

    // Simple trend calculation based on recent entries
    final recentEntries = history.take(5).toList();
    if (recentEntries.isEmpty) return ProgressTrend.stable;

    final oldestRecent = recentEntries.last.progress;
    final newestRecent = recentEntries.first.progress;
    
    final progressDelta = newestRecent - oldestRecent;
    
    if (progressDelta > 5) return ProgressTrend.increasing;
    if (progressDelta < -5) return ProgressTrend.decreasing;
    return ProgressTrend.stable;
  }

  /// Estimates completion time
  DateTime? _estimateCompletionTime({
    required Achievement achievement,
    required double currentProgress,
    required ProgressTrend progressTrend,
  }) {
    final remaining = 100.0 - currentProgress;
    
    if (remaining <= 0 || progressTrend != ProgressTrend.increasing) {
      return null; // Already completed or no positive trend
    }

    // Simple linear estimation
    final estimatedDays = (remaining * 2).round(); // Assume 0.5% per day
    return DateTime.now().add(Duration(days: estimatedDays));
  }

  /// Generates progress insights
  List<ProgressInsight> _generateProgressInsights({
    required Achievement achievement,
    required double currentProgress,
    required double progressPercentage,
    required ProgressTrend progressTrend,
    required List<ProgressMilestone> milestonesReached,
  }) {
    final insights = <ProgressInsight>[];

    // Progress status insight
    if (progressPercentage >= 90) {
      insights.add(ProgressInsight(
        type: InsightType.encouragement,
        message: 'You\'re so close! Almost there!',
        priority: InsightPriority.high,
      ));
    } else if (progressPercentage >= 50) {
      insights.add(ProgressInsight(
        type: InsightType.milestone,
        message: 'Great progress! You\'re halfway there!',
        priority: InsightPriority.medium,
      ));
    }

    // Trend insights
    switch (progressTrend) {
      case ProgressTrend.increasing:
        insights.add(ProgressInsight(
          type: InsightType.trend,
          message: 'Your progress is accelerating - keep up the great work!',
          priority: InsightPriority.medium,
        ));
        break;
      case ProgressTrend.decreasing:
        insights.add(ProgressInsight(
          type: InsightType.warning,
          message: 'Progress has slowed down recently. Consider refocusing on this goal.',
          priority: InsightPriority.high,
        ));
        break;
      case ProgressTrend.stable:
        if (progressPercentage > 0 && progressPercentage < 100) {
          insights.add(ProgressInsight(
            type: InsightType.suggestion,
            message: 'Steady progress! A small push could accelerate your achievement.',
            priority: InsightPriority.low,
          ));
        }
        break;
    }

    return insights;
  }

  // Helper methods for overall progress tracking

  Map<String, List<Achievement>> _groupAchievementsByCategory(
    List<Achievement> achievements,
  ) {
    final grouped = <String, List<Achievement>>{};
    for (final achievement in achievements) {
      final category = achievement.category.toString().split('.').last;
      grouped.putIfAbsent(category, () => <Achievement>[]).add(achievement);
    }
    return grouped;
  }

  double _calculateAverageCategoryProgress(
    List<Achievement> categoryAchievements,
    List<UserProgress> userProgressList,
  ) {
    if (categoryAchievements.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (final achievement in categoryAchievements) {
      final progress = userProgressList
          .where((up) => up.achievementId == achievement.id)
          .firstOrNull;
      final percentage = progress?.calculateProgress() ?? 0.0;
      totalProgress += percentage;
    }

    return totalProgress / categoryAchievements.length;
  }

  Future<List<RecentActivity>> _getRecentProgressActivity({
    required String userId,
    required int days,
  }) async {
    // Simplified implementation - return empty list
    // In a real implementation, this would fetch recent activity from database
    return <RecentActivity>[];
  }

  double _calculateProgressVelocity({
    required List<RecentActivity> recentActivity,
    required int timeFrameDays,
  }) {
    if (recentActivity.isEmpty || timeFrameDays <= 0) return 0.0;
    
    final achievementsCompleted = recentActivity
      .where((activity) => activity.type == ActivityType.achievementCompleted)
      .length;
    
    return achievementsCompleted / timeFrameDays;
  }

  List<Achievement> _getRecommendedAchievements({
    required List<Achievement> achievements,
    required List<UserProgress> userProgressList,
    required int limit,
  }) {
    final completedIds = userProgressList
        .where((progress) => progress.status == ProgressStatus.completed)
        .map((progress) => progress.achievementId)
        .toSet();

    return achievements
      .where((achievement) => 
        !completedIds.contains(achievement.id) &&
        achievement.isAvailable())
      .take(limit)
      .toList();
  }
}

/// Result of progress tracking operation
class ProgressTrackingResult {
  final String achievementId;
  final String userId;
  final double currentProgress;
  final double requiredProgress;
  final double progressPercentage;
  final bool isCompleted;
  final bool isNewCompletion;
  final List<ProgressMilestone> milestonesReached;
  final List<ProgressHistoryEntry> progressHistory;
  final ProgressTrend progressTrend;
  final DateTime? estimatedCompletion;
  final List<ProgressInsight> insights;
  final DateTime lastUpdated;

  const ProgressTrackingResult({
    required this.achievementId,
    required this.userId,
    required this.currentProgress,
    required this.requiredProgress,
    required this.progressPercentage,
    required this.isCompleted,
    required this.isNewCompletion,
    required this.milestonesReached,
    required this.progressHistory,
    required this.progressTrend,
    this.estimatedCompletion,
    required this.insights,
    required this.lastUpdated,
  });
}

/// Result of overall progress tracking
class OverallProgressResult {
  final String userId;
  final int totalAchievements;
  final int completedAchievements;
  final int inProgressAchievements;
  final double completionRate;
  final Map<String, CategoryProgress> progressByCategory;
  final List<RecentActivity> recentActivity;
  final double progressVelocity;
  final List<Achievement> recommendedAchievements;
  final DateTime lastUpdated;

  const OverallProgressResult({
    required this.userId,
    required this.totalAchievements,
    required this.completedAchievements,
    required this.inProgressAchievements,
    required this.completionRate,
    required this.progressByCategory,
    required this.recentActivity,
    required this.progressVelocity,
    required this.recommendedAchievements,
    required this.lastUpdated,
  });
}

/// Progress milestone model
class ProgressMilestone {
  final MilestoneType type;
  final double value;
  final DateTime achievedAt;
  final String description;

  const ProgressMilestone({
    required this.type,
    required this.value,
    required this.achievedAt,
    required this.description,
  });
}

/// Progress history entry
class ProgressHistoryEntry {
  final String userId;
  final String achievementId;
  final double progress;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ProgressHistoryEntry({
    required this.userId,
    required this.achievementId,
    required this.progress,
    required this.timestamp,
    this.metadata,
  });
}

/// Category progress summary
class CategoryProgress {
  final String category;
  final int totalAchievements;
  final int completedAchievements;
  final double completionRate;
  final double averageProgress;

  const CategoryProgress({
    required this.category,
    required this.totalAchievements,
    required this.completedAchievements,
    required this.completionRate,
    required this.averageProgress,
  });
}

/// Recent activity entry
class RecentActivity {
  final String userId;
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const RecentActivity({
    required this.userId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });
}

/// Progress insight
class ProgressInsight {
  final InsightType type;
  final String message;
  final InsightPriority priority;

  const ProgressInsight({
    required this.type,
    required this.message,
    required this.priority,
  });
}

/// Enums for progress tracking

enum ProgressTrend {
  increasing,
  decreasing,
  stable,
}

enum MilestoneType {
  percentage,
  custom,
}

enum ActivityType {
  achievementCompleted,
  milestoneReached,
  progressMade,
}

enum InsightType {
  encouragement,
  milestone,
  trend,
  warning,
  suggestion,
}

enum InsightPriority {
  low,
  medium,
  high,
}

/// Progress tracking error types
class ProgressError {
  final String message;
  final String code;

  const ProgressError._(this.message, this.code);

  static ProgressError invalidInput(String message) => ProgressError._(message, 'INVALID_INPUT');
  static ProgressError achievementNotFound(String message) => ProgressError._(message, 'ACHIEVEMENT_NOT_FOUND');
  static ProgressError userProgressNotFound(String message) => ProgressError._(message, 'USER_PROGRESS_NOT_FOUND');
  static ProgressError dataNotFound(String message) => ProgressError._(message, 'DATA_NOT_FOUND');
  static ProgressError unexpected(String message) => ProgressError._(message, 'UNEXPECTED_ERROR');

  @override
  String toString() => 'ProgressError($code): $message';
}