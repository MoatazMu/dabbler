import '../../../core/entities/base_entity.dart';
import 'badge_tier.dart';

/// Entity representing a tier upgrade event
class TierUpgrade extends BaseEntity {
  final String userId;
  final BadgeTier fromTier;
  final BadgeTier toTier;
  final int pointsEarned; // Points that triggered the upgrade
  final int totalPoints; // Total points at time of upgrade
  final List<String> unlockedBenefits; // Benefits unlocked with new tier
  final DateTime upgradeDate;
  final bool isNotificationSent;

  const TierUpgrade({
    required super.id,
    required this.userId,
    required this.fromTier,
    required this.toTier,
    required this.pointsEarned,
    required this.totalPoints,
    required this.unlockedBenefits,
    required this.upgradeDate,
    this.isNotificationSent = false,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        fromTier,
        toTier,
        pointsEarned,
        totalPoints,
        unlockedBenefits,
        upgradeDate,
        isNotificationSent,
      ];

  @override
  String toString() {
    return 'TierUpgrade('
        'id: $id, '
        'userId: $userId, '
        'fromTier: $fromTier, '
        'toTier: $toTier, '
        'pointsEarned: $pointsEarned, '
        'totalPoints: $totalPoints, '
        'unlockedBenefits: $unlockedBenefits, '
        'upgradeDate: $upgradeDate, '
        'isNotificationSent: $isNotificationSent'
        ')';
  }

  /// Check if this is a significant upgrade (skipping tiers)
  bool get isSignificantUpgrade {
    final fromIndex = BadgeTier.values.indexOf(fromTier);
    final toIndex = BadgeTier.values.indexOf(toTier);
    return toIndex - fromIndex > 1;
  }

  /// Get the upgrade message
  String get upgradeMessage {
    return 'Congratulations! You\'ve been upgraded from ${fromTier.displayName} to ${toTier.displayName}!';
  }

  /// Get the benefits message
  String get benefitsMessage {
    if (unlockedBenefits.isEmpty) return 'Enjoy your new tier status!';
    return 'You\'ve unlocked: ${unlockedBenefits.join(', ')}';
  }

  /// Create a copy of this upgrade with updated values
  TierUpgrade copyWith({
    String? id,
    String? userId,
    BadgeTier? fromTier,
    BadgeTier? toTier,
    int? pointsEarned,
    int? totalPoints,
    List<String>? unlockedBenefits,
    DateTime? upgradeDate,
    bool? isNotificationSent,
  }) {
    return TierUpgrade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromTier: fromTier ?? this.fromTier,
      toTier: toTier ?? this.toTier,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      totalPoints: totalPoints ?? this.totalPoints,
      unlockedBenefits: unlockedBenefits ?? this.unlockedBenefits,
      upgradeDate: upgradeDate ?? this.upgradeDate,
      isNotificationSent: isNotificationSent ?? this.isNotificationSent,
    );
  }

  /// Convert to JSON for storage/transport
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'from_tier': fromTier.name,
      'to_tier': toTier.name,
      'points_earned': pointsEarned,
      'total_points': totalPoints,
      'unlocked_benefits': unlockedBenefits,
      'upgrade_date': upgradeDate.toIso8601String(),
      'is_notification_sent': isNotificationSent,
    };
  }

  /// Create from JSON data
  factory TierUpgrade.fromJson(Map<String, dynamic> json) {
    return TierUpgrade(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fromTier: BadgeTier.values.firstWhere(
        (tier) => tier.name == json['from_tier'],
      ),
      toTier: BadgeTier.values.firstWhere(
        (tier) => tier.name == json['to_tier'],
      ),
      pointsEarned: json['points_earned'] as int,
      totalPoints: json['total_points'] as int,
      unlockedBenefits: List<String>.from(json['unlocked_benefits'] as List),
      upgradeDate: DateTime.parse(json['upgrade_date'] as String),
      isNotificationSent: json['is_notification_sent'] as bool? ?? false,
    );
  }

  /// Create a tier upgrade for testing/demo purposes
  factory TierUpgrade.demo({
    required String userId,
    required BadgeTier fromTier,
    required BadgeTier toTier,
  }) {
    return TierUpgrade(
      id: 'demo_upgrade_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      fromTier: fromTier,
      toTier: toTier,
      pointsEarned: 500,
      totalPoints: toTier.points,
      unlockedBenefits: _getTierBenefits(toTier),
      upgradeDate: DateTime.now(),
      isNotificationSent: false,
    );
  }

  /// Get benefits for a specific tier
  static List<String> _getTierBenefits(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return ['Profile badge', 'Basic rewards'];
      case BadgeTier.silver:
        return ['Increased point multiplier', 'Exclusive challenges'];
      case BadgeTier.gold:
        return ['Premium rewards', 'Priority support', 'Special events'];
      case BadgeTier.platinum:
        return ['VIP status', 'Early access', 'Bonus rewards'];
      case BadgeTier.diamond:
        return ['Elite status', 'Personal rewards consultant', 'Exclusive perks'];
    }
  }
}