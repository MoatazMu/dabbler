import '../entities/point_transaction.dart';
import '../entities/tier.dart';
import '../repositories/rewards_repository.dart';

/// Result of points calculation
class PointsCalculationResult {
  final bool success;
  final int basePoints;
  final int finalPoints;
  final double totalMultiplier;
  final Map<String, double> appliedMultipliers;
  final Map<String, int> bonuses;
  final PointTransaction? transaction;
  final TierLevel? newTier;
  final bool hitDailyLimit;
  final bool hitWeeklyLimit;
  final String? limitMessage;
  final Map<String, dynamic> breakdown;
  final List<String> errors;

  const PointsCalculationResult({
    required this.success,
    required this.basePoints,
    required this.finalPoints,
    required this.totalMultiplier,
    this.appliedMultipliers = const {},
    this.bonuses = const {},
    this.transaction,
    this.newTier,
    this.hitDailyLimit = false,
    this.hitWeeklyLimit = false,
    this.limitMessage,
    this.breakdown = const {},
    this.errors = const [],
  });

  /// Whether the calculation resulted in a tier upgrade
  bool get hasTierUpgrade => newTier != null;

  /// Whether any limits were hit
  bool get hitLimits => hitDailyLimit || hitWeeklyLimit;

  /// Whether any bonuses were applied
  bool get hasBonuses => bonuses.isNotEmpty;

  /// Total bonus points from all sources
  int get totalBonusPoints => bonuses.values.fold(0, (sum, bonus) => sum + bonus);
}

/// Use case for calculating points with multipliers, bonuses, and limits
class CalculatePointsUseCase {
  final RewardsRepository _repository;

  // Point calculation constants
  static const int _dailyPointsLimit = 1000;
  static const int _weeklyPointsLimit = 7000;
  static const double _maxMultiplier = 5.0;
  static const double _streakMultiplierRate = 0.02; // 2% per day
  static const double _tierMultiplierRate = 0.05; // 5% per tier level
  static const double _weekendBonus = 1.2; // 20% bonus on weekends
  static const double _eventMultiplier = 2.0; // 100% during events

  CalculatePointsUseCase({
    required RewardsRepository repository,
  }) : _repository = repository;

  /// Calculate points with full business logic
  Future<PointsCalculationResult> execute({
    required String userId,
    required int basePoints,
    required String source,
    Map<String, dynamic> context = const {},
    TransactionType type = TransactionType.achievement,
    bool respectLimits = true,
    bool createTransaction = true,
  }) async {
    try {
      // Step 1: Input validation
      if (basePoints <= 0) {
        return PointsCalculationResult(
          success: false,
          basePoints: basePoints,
          finalPoints: 0,
          totalMultiplier: 0.0,
          errors: ['Base points must be positive'],
        );
      }

      // Step 2: Get user's current state
      final userState = await _getUserState(userId);
      if (userState == null) {
        return PointsCalculationResult(
          success: false,
          basePoints: basePoints,
          finalPoints: 0,
          totalMultiplier: 0.0,
          errors: ['Could not retrieve user state'],
        );
      }

      // Step 3: Check daily/weekly limits
      final limitCheck = await _checkPointsLimits(
        userId,
        basePoints,
        userState,
        respectLimits,
      );

      if (!limitCheck.allowed && respectLimits) {
        return PointsCalculationResult(
          success: false,
          basePoints: basePoints,
          finalPoints: 0,
          totalMultiplier: 0.0,
          hitDailyLimit: limitCheck.hitDailyLimit,
          hitWeeklyLimit: limitCheck.hitWeeklyLimit,
          limitMessage: limitCheck.message,
          errors: ['Points limit exceeded'],
        );
      }

      // Step 4: Calculate base multipliers
      final multipliers = await _calculateMultipliers(userId, userState, context);

      // Step 5: Calculate bonuses
      final bonuses = await _calculateBonuses(userId, userState, context, type);

      // Step 6: Apply calculations
      var calculatedPoints = basePoints.toDouble();
      var totalMultiplier = 1.0;

      // Apply multipliers
      for (final entry in multipliers.entries) {
        totalMultiplier *= entry.value;
      }

      // Cap total multiplier
      totalMultiplier = totalMultiplier.clamp(1.0, _maxMultiplier);
      calculatedPoints *= totalMultiplier;

      // Add bonuses
      final totalBonusPoints = bonuses.values.fold(0, (sum, bonus) => sum + bonus);
      calculatedPoints += totalBonusPoints;

      // Apply limits if respected
      final finalPoints = respectLimits 
          ? limitCheck.adjustedPoints?.round() ?? calculatedPoints.round()
          : calculatedPoints.round();

      // Step 7: Create transaction if requested
      PointTransaction? transaction;
      if (createTransaction && finalPoints > 0) {
        transaction = await _createPointTransaction(
          userId,
          basePoints,
          finalPoints,
          source,
          type,
          multipliers,
          bonuses,
          context,
        );
      }

      // Step 8: Check for tier upgrade
      final tierUpgrade = await _checkTierUpgrade(userId, finalPoints);

      // Step 9: Create detailed breakdown
      final breakdown = _createBreakdown(
        basePoints,
        multipliers,
        bonuses,
        totalMultiplier,
        finalPoints,
        limitCheck,
      );

      return PointsCalculationResult(
        success: true,
        basePoints: basePoints,
        finalPoints: finalPoints,
        totalMultiplier: totalMultiplier,
        appliedMultipliers: multipliers,
        bonuses: bonuses,
        transaction: transaction,
        newTier: tierUpgrade,
        hitDailyLimit: limitCheck.hitDailyLimit,
        hitWeeklyLimit: limitCheck.hitWeeklyLimit,
        limitMessage: limitCheck.message,
        breakdown: breakdown,
      );

    } catch (error) {
      return PointsCalculationResult(
        success: false,
        basePoints: basePoints,
        finalPoints: 0,
        totalMultiplier: 0.0,
        errors: ['Points calculation failed: $error'],
      );
    }
  }

  // =============================================================================
  // USER STATE AND VALIDATION
  // =============================================================================

  /// Get user's current state for calculations
  Future<_UserState?> _getUserState(String userId) async {
    try {
      final userTierResult = await _repository.getUserTier(userId);
      final achievementStatsResult = await _repository.getAchievementStats(userId);

      final userTier = userTierResult.fold(
        (failure) => null,
        (tier) => tier,
      );

      final stats = achievementStatsResult.fold(
        (failure) => <String, dynamic>{},
        (stats) => stats,
      );

      // Get today's and week's points
      final todayPointsResult = await _repository.getPointTransactions(
        userId,
        limit: 100, // Get recent transactions to calculate daily/weekly totals
      );

      final transactions = todayPointsResult.fold(
        (failure) => <PointTransaction>[],
        (transactions) => transactions,
      );

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

      final todayPoints = transactions
          .where((t) => t.createdAt.isAfter(todayStart))
          .fold(0.0, (sum, t) => sum + t.finalPoints)
          .round();

      final weekPoints = transactions
          .where((t) => t.createdAt.isAfter(weekStart))
          .fold(0.0, (sum, t) => sum + t.finalPoints)
          .round();

      return _UserState(
        tier: userTier,
        todayPoints: todayPoints,
        weekPoints: weekPoints,
        streakDays: stats['streak_days'] as int? ?? 0,
        totalAchievements: stats['total_achievements'] as int? ?? 0,
        totalPoints: stats['total_points'] as int? ?? 0,
        stats: stats,
      );

    } catch (error) {
      return null;
    }
  }

  /// Check daily and weekly points limits
  Future<_LimitCheck> _checkPointsLimits(
    String userId,
    int basePoints,
    _UserState userState,
    bool respectLimits,
  ) async {
    if (!respectLimits) {
      return _LimitCheck(
        allowed: true,
        hitDailyLimit: false,
        hitWeeklyLimit: false,
        adjustedPoints: basePoints.toDouble(),
      );
    }

    final wouldExceedDaily = (userState.todayPoints + basePoints) > _dailyPointsLimit;
    final wouldExceedWeekly = (userState.weekPoints + basePoints) > _weeklyPointsLimit;

    if (wouldExceedDaily || wouldExceedWeekly) {
      final dailyRemaining = (_dailyPointsLimit - userState.todayPoints).clamp(0, double.infinity);
      final weeklyRemaining = (_weeklyPointsLimit - userState.weekPoints).clamp(0, double.infinity);
      
      final adjustedPoints = [dailyRemaining, weeklyRemaining, basePoints.toDouble()].reduce((a, b) => a < b ? a : b);

      String message;
      if (wouldExceedDaily && wouldExceedWeekly) {
        message = 'Daily and weekly limits reached. Can only earn ${adjustedPoints.round()} more points today.';
      } else if (wouldExceedDaily) {
        message = 'Daily limit reached. Can only earn ${adjustedPoints.round()} more points today.';
      } else {
        message = 'Weekly limit reached. Can only earn ${adjustedPoints.round()} more points this week.';
      }

      return _LimitCheck(
        allowed: adjustedPoints > 0,
        hitDailyLimit: wouldExceedDaily,
        hitWeeklyLimit: wouldExceedWeekly,
        adjustedPoints: adjustedPoints.toDouble(),
        message: message,
      );
    }

    return _LimitCheck(
      allowed: true,
      hitDailyLimit: false,
      hitWeeklyLimit: false,
      adjustedPoints: basePoints.toDouble(),
    );
  }

  // =============================================================================
  // MULTIPLIERS CALCULATION
  // =============================================================================

  /// Calculate all applicable multipliers
  Future<Map<String, double>> _calculateMultipliers(
    String userId,
    _UserState userState,
    Map<String, dynamic> context,
  ) async {
    final multipliers = <String, double>{};

    // Tier multiplier
    if (userState.tier != null) {
      final tierMultiplier = 1.0 + (userState.tier!.level.level * _tierMultiplierRate);
      multipliers['tier'] = tierMultiplier;
    }

    // Streak multiplier
    if (userState.streakDays > 0) {
      final streakMultiplier = 1.0 + (userState.streakDays * _streakMultiplierRate);
      multipliers['streak'] = streakMultiplier.clamp(1.0, 2.0); // Cap at 200%
    }

    // Weekend multiplier
    final now = DateTime.now();
    if (now.weekday >= 6) { // Saturday or Sunday
      multipliers['weekend'] = _weekendBonus;
    }

    // Special event multiplier
    if (context.containsKey('special_event') && context['special_event'] == true) {
      multipliers['event'] = context['event_multiplier'] as double? ?? _eventMultiplier;
    }

    // First completion multiplier
    if (context.containsKey('first_completion') && context['first_completion'] == true) {
      multipliers['first_completion'] = 1.5;
    }

    // Achievement difficulty multiplier
    if (context.containsKey('achievement_tier')) {
      final tier = context['achievement_tier'] as String?;
      switch (tier?.toLowerCase()) {
        case 'bronze':
          multipliers['difficulty'] = 1.0;
          break;
        case 'silver':
          multipliers['difficulty'] = 1.2;
          break;
        case 'gold':
          multipliers['difficulty'] = 1.5;
          break;
        case 'platinum':
          multipliers['difficulty'] = 2.0;
          break;
        case 'diamond':
          multipliers['difficulty'] = 2.5;
          break;
      }
    }

    // Performance multiplier
    if (context.containsKey('performance_score')) {
      final score = context['performance_score'] as double?;
      if (score != null && score > 0.8) { // 80%+ performance
        multipliers['performance'] = 1.0 + ((score - 0.8) * 0.5); // Up to 10% bonus
      }
    }

    return multipliers;
  }

  // =============================================================================
  // BONUSES CALCULATION
  // =============================================================================

  /// Calculate all applicable bonuses
  Future<Map<String, int>> _calculateBonuses(
    String userId,
    _UserState userState,
    Map<String, dynamic> context,
    TransactionType type,
  ) async {
    final bonuses = <String, int>{};

    // Daily login bonus (applied to daily bonus type)
    if (type == TransactionType.dailyBonus) {
      bonuses['daily_login'] = _calculateDailyLoginBonus(userState.streakDays);
    }

    // Milestone bonus
    if (context.containsKey('milestone_reached')) {
      final milestone = context['milestone_reached'] as int? ?? 0;
      bonuses['milestone'] = _calculateMilestoneBonus(milestone);
    }

    // Perfect score bonus
    if (context.containsKey('perfect_score') && context['perfect_score'] == true) {
      bonuses['perfect_score'] = 50;
    }

    // Speed bonus
    if (context.containsKey('completion_time') && context.containsKey('target_time')) {
      final completionTime = context['completion_time'] as int?;
      final targetTime = context['target_time'] as int?;
      if (completionTime != null && targetTime != null && completionTime < targetTime) {
        final speedBonus = ((targetTime - completionTime) / targetTime * 100).round();
        bonuses['speed'] = speedBonus.clamp(0, 100);
      }
    }

    // Combo bonus
    if (context.containsKey('combo_count')) {
      final combo = context['combo_count'] as int? ?? 0;
      if (combo > 1) {
        bonuses['combo'] = (combo * 5).clamp(0, 50); // 5 points per combo, max 50
      }
    }

    // Social bonus
    if (context.containsKey('friends_playing')) {
      final friendsCount = context['friends_playing'] as int? ?? 0;
      if (friendsCount > 0) {
        bonuses['social'] = (friendsCount * 10).clamp(0, 50); // 10 points per friend, max 50
      }
    }

    return bonuses;
  }

  /// Calculate daily login bonus based on streak
  int _calculateDailyLoginBonus(int streakDays) {
    if (streakDays <= 0) return 10; // Base login bonus
    
    // Escalating bonus: 10, 15, 20, 25, 30, then 50 for 7+ days
    if (streakDays >= 7) return 50;
    return 10 + (streakDays * 5);
  }

  /// Calculate milestone bonus
  int _calculateMilestoneBonus(int milestone) {
    // Bonuses for different milestone tiers
    if (milestone >= 1000) return 500;
    if (milestone >= 500) return 200;
    if (milestone >= 100) return 100;
    if (milestone >= 50) return 50;
    if (milestone >= 10) return 25;
    return 10;
  }

  // =============================================================================
  // TRANSACTION AND TIER MANAGEMENT
  // =============================================================================

  /// Create a point transaction record
  Future<PointTransaction?> _createPointTransaction(
    String userId,
    int basePoints,
    int finalPoints,
    String source,
    TransactionType type,
    Map<String, double> multipliers,
    Map<String, int> bonuses,
    Map<String, dynamic> context,
  ) async {
    try {
      // Get current balance
      final transactionsResult = await _repository.getPointTransactions(
        userId,
        limit: 1,
      );

      final currentBalance = transactionsResult.fold(
        (failure) => 0,
        (transactions) => transactions.isNotEmpty ? transactions.first.runningBalance : 0,
      );

      final newBalance = currentBalance + finalPoints;

      // Create transaction object
      final transaction = PointTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        basePoints: basePoints.toDouble(),
        finalPoints: finalPoints.toDouble(),
        runningBalance: newBalance.toDouble(),
        type: type,
        description: source,
        createdAt: DateTime.now(),
        metadata: {
          'multipliers': multipliers,
          'bonuses': bonuses,
          'context': context,
          'calculation_source': 'CalculatePointsUseCase',
        },
      );

      // In a real implementation, this would save to the repository
      // For now, we'll return the transaction object
      return transaction;

    } catch (error) {
      return null;
    }
  }

  /// Check if user should be upgraded to a new tier
  Future<TierLevel?> _checkTierUpgrade(String userId, int pointsToAdd) async {
    try {
      final userTierResult = await _repository.getUserTier(userId);
      
      final currentTier = userTierResult.fold(
        (failure) => null,
        (tier) => tier,
      );

      if (currentTier == null) return null;

      // Calculate new total points
      final achievementStatsResult = await _repository.getAchievementStats(userId);
      final stats = achievementStatsResult.fold(
        (failure) => <String, dynamic>{},
        (stats) => stats,
      );

      final currentPoints = stats['total_points'] as int? ?? 0;
      final newTotalPoints = currentPoints + pointsToAdd;

      // Determine new tier
      final newTierLevel = TierLevel.fromPoints(newTotalPoints.toDouble());

      // Check if upgrade is needed
      if (newTierLevel.level > currentTier.level.level) {
        return newTierLevel;
      }

      return null;

    } catch (error) {
      return null;
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Create detailed calculation breakdown
  Map<String, dynamic> _createBreakdown(
    int basePoints,
    Map<String, double> multipliers,
    Map<String, int> bonuses,
    double totalMultiplier,
    int finalPoints,
    _LimitCheck limitCheck,
  ) {
    return {
      'base_points': basePoints,
      'multipliers': {
        'individual': multipliers,
        'total': totalMultiplier,
        'applied_points': (basePoints * totalMultiplier).round(),
      },
      'bonuses': {
        'individual': bonuses,
        'total': bonuses.values.fold(0, (sum, bonus) => sum + bonus),
      },
      'limits': {
        'daily_limit_hit': limitCheck.hitDailyLimit,
        'weekly_limit_hit': limitCheck.hitWeeklyLimit,
        'adjusted': limitCheck.adjustedPoints != basePoints,
        'message': limitCheck.message,
      },
      'final_points': finalPoints,
      'calculation_steps': [
        'Started with $basePoints base points',
        'Applied ${multipliers.length} multiplier(s): ${multipliers.keys.join(', ')}',
        'Total multiplier: ${totalMultiplier.toStringAsFixed(2)}x',
        'Points after multipliers: ${(basePoints * totalMultiplier).round()}',
        'Added ${bonuses.length} bonus(es): ${bonuses.keys.join(', ')}',
        'Total bonus points: ${bonuses.values.fold(0, (sum, bonus) => sum + bonus)}',
        if (limitCheck.hitDailyLimit || limitCheck.hitWeeklyLimit) 
          'Applied limits: ${limitCheck.message}',
        'Final points awarded: $finalPoints',
      ],
    };
  }


}

// =============================================================================
// HELPER CLASSES
// =============================================================================

class _UserState {
  final UserTier? tier;
  final int todayPoints;
  final int weekPoints;
  final int streakDays;
  final int totalAchievements;
  final int totalPoints;
  final Map<String, dynamic> stats;

  _UserState({
    this.tier,
    required this.todayPoints,
    required this.weekPoints,
    required this.streakDays,
    required this.totalAchievements,
    required this.totalPoints,
    this.stats = const {},
  });
}

class _LimitCheck {
  final bool allowed;
  final bool hitDailyLimit;
  final bool hitWeeklyLimit;
  final double? adjustedPoints;
  final String? message;

  _LimitCheck({
    required this.allowed,
    required this.hitDailyLimit,
    required this.hitWeeklyLimit,
    this.adjustedPoints,
    this.message,
  });
}