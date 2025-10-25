class Rating {
  final String id;
  final String raterUserId;
  final String? targetUserId;
  final String? targetGameId;
  final String? targetVenueId;
  final String? contextId;
  final double? score;
  final String? comment;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.raterUserId,
    required this.createdAt,
    this.targetUserId,
    this.targetGameId,
    this.targetVenueId,
    this.contextId,
    this.score,
    this.comment,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      raterUserId: json['rater_user_id'] as String,
      targetUserId: json['target_user_id'] as String?,
      targetGameId: json['target_game_id'] as String?,
      targetVenueId: json['target_venue_id'] as String?,
      contextId: json['context_id'] as String?,
      score: json['score'] == null ? null : (json['score'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rater_user_id': raterUserId,
        'target_user_id': targetUserId,
        'target_game_id': targetGameId,
        'target_venue_id': targetVenueId,
        'context_id': contextId,
        'score': score,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}
