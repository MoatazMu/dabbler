import 'package:meta/meta.dart';

@immutable
class Slot {
  const Slot({
    required this.id,
    required this.venueSpaceId,
    required this.start,
    required this.end,
  });

  final String id;
  final String venueSpaceId;
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  factory Slot.fromJson(Map<String, dynamic> json) {
    final startValue = json['slot_start'];
    final endValue = json['slot_end'];

    return Slot(
      id: json['id'] as String,
      venueSpaceId: json['venue_space_id'] as String,
      start: _parseDateTime(startValue),
      end: _parseDateTime(endValue),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'venue_space_id': venueSpaceId,
      'slot_start': start.toUtc().toIso8601String(),
      'slot_end': end.toUtc().toIso8601String(),
    };
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) {
      return value.toUtc();
    }
    return DateTime.parse(value as String).toUtc();
  }
}
