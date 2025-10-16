import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_progress.dart';
import '../repositories/rewards_repository.dart';

/// Simplified award achievement use case that compiles and works
class AwardAchievementUseCase {
  final RewardsRepository _repository;

  const AwardAchievementUseCase(this._repository);

  /// Awards an achievement to a user
  Future<Either<Failure, bool>> call({
    required String userId,
    required String achievementId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Get the achievement
      final achievementResult = await _repository.getAchievementById(achievementId);
      if (achievementResult.isLeft()) {
        return Left(ServerFailure(message: 'Achievement not found'));
      }

      final achievement = achievementResult.getOrElse(() => throw StateError('Should not happen'));

      // Check if user already has this achievement (if not repeatable)
      if (!achievement.type.isRepeatable) {
        final existingProgress = await _repository.getUserProgressForAchievement(
          userId, 
          achievementId,
        );
        if (existingProgress.isRight()) {
          final progress = existingProgress.getOrElse(() => null);
          if (progress != null && progress.status == ProgressStatus.completed) {
            return Left(ServerFailure(message: 'Achievement already completed'));
          }
        }
      }

      // Award points if achievement has points
      if (achievement.points > 0) {
        await _repository.awardPoints(
          userId,
          achievement.points,
          'Achievement completed: ${achievement.name}',
        );
      }

      // Update user progress to completed
      final now = DateTime.now();
      final updatedProgress = UserProgress(
        id: '${userId}_${achievementId}_${now.millisecondsSinceEpoch}',
        userId: userId,
        achievementId: achievementId,
        currentProgress: achievement.criteria['target'] ?? {'count': 1},
        requiredProgress: achievement.criteria,
        status: ProgressStatus.completed,
        completedAt: now,
        startedAt: now.subtract(const Duration(seconds: 1)),
        updatedAt: now,
      );

      await _repository.updateUserProgress(updatedProgress);

      // Try to award badges (non-blocking)
      try {
        final badgesResult = await _repository.getBadgesForAchievement(achievementId);
        if (badgesResult.isRight()) {
          final badges = badgesResult.getOrElse(() => []);
          for (final badge in badges) {
            await _repository.awardBadge(userId, badge.id);
          }
        }
      } catch (e) {
        // Badge awarding is non-critical, continue without failing
      }

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to award achievement: $e'));
    }
  }
}