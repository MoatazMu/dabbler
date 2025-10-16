import '../domain/entities/badge_tier.dart';
import '../domain/entities/achievement.dart';
import '../domain/entities/badge.dart';
import '../domain/entities/user_progress.dart';
import '../domain/entities/points_transaction.dart';

/// Stub implementation of RewardsService for quick app compilation
class RewardsService {
  // Stub methods that return mock data or do nothing
  
  Future<int> getUserPoints(String userId) async {
    return 150; // Mock points
  }
  
  Future<BadgeTier> getUserTier(String userId) async {
    return BadgeTier.silver; // Mock tier
  }
  
  Future<List<Achievement>> getUserAchievements(String userId) async {
    return []; // Mock empty achievements
  }
  
  Future<UserProgress> getUserProgress(String userId) async {
    // Return mock UserProgress - will need to create this entity
    throw UnimplementedError('UserProgress entity needs proper structure');
  }
  
  Future<List<Badge>> getUserBadges(String userId) async {
    return []; // Mock empty badges
  }
  
  Future<int> getUserRank(String userId) async {
    return 42; // Mock rank
  }
  
  Future<void> awardPoints(String userId, int points, String reason, {String? source}) async {
    // Do nothing - stub implementation
    print('Stub: Awarded $points points to $userId for $reason');
  }
  
  Future<void> unlockAchievement(String userId, String achievementId) async {
    // Do nothing - stub implementation  
    print('Stub: Unlocked achievement $achievementId for $userId');
  }
  
  Future<List<PointsTransaction>> getTransactionHistory(String userId, {int? limit, int? offset}) async {
    return []; // Mock empty transaction history
  }
}