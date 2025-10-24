// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint

part of 'profile_model.dart';

_$_ProfileModel _$$_ProfileModelFromJson(Map<String, dynamic> json) =>
    _$_ProfileModel(
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

Map<String, dynamic> _$$_ProfileModelToJson(_$_ProfileModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  val['user_id'] = instance.userId;
  val['display_name'] = instance.displayName;
  writeNotNull('username', instance.username);
  writeNotNull('avatar_url', instance.avatarUrl);
  val['profile_type'] = instance.profileType;
  writeNotNull('created_at', instance.createdAt?.toIso8601String());
  writeNotNull('updated_at', instance.updatedAt?.toIso8601String());
  writeNotNull('deleted_at', instance.deletedAt?.toIso8601String());
  return val;
}
