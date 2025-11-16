// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  username: json['username'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  profileType: json['profile_type'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'display_name': instance.displayName,
      if (instance.username case final value?) 'username': value,
      if (instance.avatarUrl case final value?) 'avatar_url': value,
      'profile_type': instance.profileType,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
      if (instance.deletedAt?.toIso8601String() case final value?)
        'deleted_at': value,
    };

_$ProfileModelImpl _$$ProfileModelImplFromJson(Map<String, dynamic> json) =>
    _$ProfileModelImpl(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      profileType: json['profile_type'] as String? ?? 'player',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$ProfileModelImplToJson(_$ProfileModelImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
      'profile_type': instance.profileType,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
