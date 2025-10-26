import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'profile_type') required String profileType,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'bio') String? bio,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'city') String? city,
    @JsonKey(name: 'country') String? country,
    @JsonKey(name: 'language') String? language,
    @JsonKey(name: 'verified') bool? verified,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'display_name_norm') String? displayNameNorm,
    @JsonKey(name: 'geo_lat') double? geoLat,
    @JsonKey(name: 'geo_lng') double? geoLng,
    // New onboarding fields
    @JsonKey(name: 'intention') String? intention,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'age') int? age,
    @JsonKey(name: 'preferred_sport') String? preferredSport,
    @JsonKey(name: 'interests') String? interests, // comma-separated
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
