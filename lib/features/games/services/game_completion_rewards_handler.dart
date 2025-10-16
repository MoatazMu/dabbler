import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../rewards/domain/entities/badge_tier.dart';

/// Game completion integration with rewards system
class GameCompletionRewardsHandler {
  
  GameCompletionRewardsHandler();

  /// Handle game completion with rewards integration
  Future<void> handleGameCompletion({
    required String userId,
    required String gameId,
    required String sport,
    required bool isWinner,
    required Duration gameDuration,
    required Map<String, dynamic> gameStats,
    required BuildContext context,
  }) async {
    try {
      debugPrint('Game completion handler called for user $userId, game $gameId');
      
      // Calculate base points for game completion
      final pointsEarned = _calculateGamePoints(
        sport: sport,
        isWinner: isWinner,
        gameDuration: gameDuration,
        gameStats: gameStats,
      );
      
      debugPrint('Points earned: $pointsEarned');
      
      // Show haptic feedback
      HapticFeedback.mediumImpact();
      
    } catch (e) {
      debugPrint('Error handling game completion rewards: $e');
    }
  }

  /// Calculate points earned from game completion
  int _calculateGamePoints({
    required String sport,
    required bool isWinner,
    required Duration gameDuration,
    required Map<String, dynamic> gameStats,
  }) {
    int basePoints = 50; // Base participation points

    // Bonus for winning
    if (isWinner) {
      basePoints += 25;
    }

    // Sport-specific multipliers
    final sportMultiplier = _getSportMultiplier(sport);
    basePoints = (basePoints * sportMultiplier).round();

    // Game duration bonus (longer games get slight bonus)
    if (gameDuration.inMinutes > 30) {
      basePoints += 10;
    }

    return basePoints;
  }

  /// Get sport-specific multiplier
  double _getSportMultiplier(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
      case 'soccer':
        return 1.2;
      case 'basketball':
        return 1.1;
      case 'tennis':
        return 1.3;
      case 'volleyball':
        return 1.0;
      default:
        return 1.0;
    }
  }

  /// Get tier based on milestone count
  BadgeTier _getTierForMilestone(int count) {
    if (count >= 100) return BadgeTier.diamond;
    if (count >= 50) return BadgeTier.platinum;
    if (count >= 25) return BadgeTier.gold;
    if (count >= 10) return BadgeTier.silver;
    return BadgeTier.bronze;
  }

  /// Get tier based on win streak
  BadgeTier _getTierForWinStreak(int streak) {
    if (streak >= 20) return BadgeTier.platinum;
    if (streak >= 10) return BadgeTier.gold;
    if (streak >= 5) return BadgeTier.silver;
    return BadgeTier.bronze;
  }

  /// Get milestone name for achievement
  String _getMilestoneName(int count) {
    switch (count) {
      case 5: return 'Newcomer';
      case 10: return 'Regular';
      case 25: return 'Veteran';
      case 50: return 'Expert';
      case 100: return 'Master';
      default: return 'Player';
    }
  }
}