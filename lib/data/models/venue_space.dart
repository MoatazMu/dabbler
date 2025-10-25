/// Immutable representation of a venue space row.
class VenueSpace {
  const VenueSpace({
    required this.id,
    required this.venueId,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory VenueSpace.fromJson(Map<String, dynamic> json) {
    return VenueSpace(
      id: json['id'] as String,
      venueId: json['venue_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  final String id;
  final String venueId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'venue_id': venueId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Unsupported date value: $value');
  }
}
