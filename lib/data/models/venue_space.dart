import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue_space.freezed.dart';
part 'venue_space.g.dart';

@freezed
class VenueSpace with _$VenueSpace {
  const factory VenueSpace({
    required String id,
    @JsonKey(name: 'venue_id') required String venueId,
    required String name,
    @JsonKey(name: 'sport_key') String? sportKey,
    @JsonKey(name: 'is_active') bool? isActive,
    int? capacity,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _VenueSpace;

  factory VenueSpace.fromJson(Map<String, dynamic> json) =>
      _$VenueSpaceFromJson(json);
}
