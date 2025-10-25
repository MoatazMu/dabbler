class AbuseFlag {
  const AbuseFlag({
    required this.id,
    required this.subjectType,
    required this.subjectId,
    this.reason,
    required this.reporterUserId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String subjectType;
  final String subjectId;
  final String? reason;
  final String reporterUserId;
  final String status;
  final DateTime createdAt;

  factory AbuseFlag.fromJson(Map<String, dynamic> json) {
    return AbuseFlag(
      id: json['id'] as String,
      subjectType: json['subject_type'] as String,
      subjectId: json['subject_id'] as String,
      reason: json['reason'] as String?,
      reporterUserId: json['reporter_user_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_type': subjectType,
      'subject_id': subjectId,
      'reason': reason,
      'reporter_user_id': reporterUserId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AbuseFlag copyWith({
    String? id,
    String? subjectType,
    String? subjectId,
    String? reason,
    String? reporterUserId,
    String? status,
    DateTime? createdAt,
  }) {
    return AbuseFlag(
      id: id ?? this.id,
      subjectType: subjectType ?? this.subjectType,
      subjectId: subjectId ?? this.subjectId,
      reason: reason ?? this.reason,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbuseFlag &&
        other.id == id &&
        other.subjectType == subjectType &&
        other.subjectId == subjectId &&
        other.reason == reason &&
        other.reporterUserId == reporterUserId &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        subjectType,
        subjectId,
        reason,
        reporterUserId,
        status,
        createdAt,
      );
}
