// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_with_sport_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VenueWithSportModelImpl _$$VenueWithSportModelImplFromJson(
  Map<String, dynamic> json,
) => _$VenueWithSportModelImpl(
  id: json['id'] as String,
  sportId: json['sport_id'] as String,
  nameEn: json['name_en'] as String,
  nameAr: json['name_ar'] as String?,
  city: json['city'] as String,
  area: json['area'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  isIndoor: json['is_indoor'] as bool?,
  pricePerHour: (json['price_per_hour'] as num?)?.toDouble(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  address: json['address'] as String?,
  phoneNumber: json['phone_number'] as String?,
  description: json['description'] as String?,
  amenities:
      (json['amenities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  compositeScore: (json['composite_score'] as num?)?.toDouble(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$VenueWithSportModelImplToJson(
  _$VenueWithSportModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'sport_id': instance.sportId,
  'name_en': instance.nameEn,
  'name_ar': instance.nameAr,
  'city': instance.city,
  'area': instance.area,
  'is_active': instance.isActive,
  'is_indoor': instance.isIndoor,
  'price_per_hour': instance.pricePerHour,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'address': instance.address,
  'phone_number': instance.phoneNumber,
  'description': instance.description,
  'amenities': instance.amenities,
  'composite_score': instance.compositeScore,
  'created_at': instance.createdAt?.toIso8601String(),
};
