// coverage:ignore-file
// GENERATED CODE - MANUALLY WRITTEN TO MIRROR JSON SERIALIZABLE OUTPUT

part of 'profile.dart';

_$_Profile _$$_ProfileFromJson(Map<String, dynamic> json) => _$_Profile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      profileType: json['profile_type'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      language: json['language'] as String?,
      verified: json['verified'] as bool?,
      isActive: json['is_active'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      displayNameNorm: json['display_name_norm'] as String?,
      geoLat: (json['geo_lat'] as num?)?.toDouble(),
      geoLng: (json['geo_lng'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$_ProfileToJson(_$_Profile instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'profile_type': instance.profileType,
      'username': instance.username,
      'display_name': instance.displayName,
      'bio': instance.bio,
      'avatar_url': instance.avatarUrl,
      'city': instance.city,
      'country': instance.country,
      'language': instance.language,
      'verified': instance.verified,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'display_name_norm': instance.displayNameNorm,
      'geo_lat': instance.geoLat,
      'geo_lng': instance.geoLng,
    };
