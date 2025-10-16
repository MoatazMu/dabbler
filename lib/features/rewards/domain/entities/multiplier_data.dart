/// Types of multipliers available in the rewards system
enum MultiplierType {
  /// Multiplier based on user's current tier
  tier,
  /// Multiplier for active streak
  streak,
  /// Special event multiplier
  event,
  /// First-time bonus multiplier
  firstTime,
  /// Achievement completion multiplier
  achievement,
  /// Daily/weekly/monthly bonus
  bonus,
}

/// Multiplier data entity representing point multiplication factors
class MultiplierData {
  final String id;
  final MultiplierType type;
  final double multiplier;
  final String reason;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const MultiplierData({
    required this.id,
    required this.type,
    required this.multiplier,
    required this.reason,
    this.expiresAt,
    this.isActive = true,
    this.metadata,
  });

  /// Check if multiplier is currently valid
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Get the actual points after applying this multiplier
  int applyMultiplier(int basePoints) {
    if (!isValid) return basePoints;
    return (basePoints * multiplier).round();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MultiplierData &&
        other.id == id &&
        other.type == type &&
        other.multiplier == multiplier &&
        other.reason == reason &&
        other.expiresAt == expiresAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      multiplier,
      reason,
      expiresAt,
      isActive,
    );
  }

  @override
  String toString() {
    return 'MultiplierData('
        'id: $id, '
        'type: $type, '
        'multiplier: ${multiplier}x, '
        'reason: $reason, '
        'expiresAt: $expiresAt, '
        'isActive: $isActive'
        ')';
  }
}