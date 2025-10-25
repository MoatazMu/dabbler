import 'package:flutter/foundation.dart';

/// Immutable representation of a row in `public.notifications`.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.payload,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime? readAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      payload: _mapPayload(json['payload']),
      createdAt: _parseDateTime(json['created_at'])!,
      readAt: _parseDateTime(json['read_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'type': type,
      'payload': payload == null ? null : Map<String, dynamic>.from(payload!),
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  static Map<String, dynamic>? _mapPayload(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, dynamic v) => MapEntry(key as String, v),
      );
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value).toUtc();
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        mapEquals(other.payload, payload) &&
        other.createdAt == createdAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        type,
        payload == null ? null : Object.hashAll(payload!.entries),
        createdAt,
        readAt,
      );
}
