// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, invalid_annotation_target

part of 'profile_model.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `ProfileModel._()`.
This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.',
);

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) {
  return _ProfileModel.fromJson(json);
}

mixin _$ProfileModel {
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'username')
  String? get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_type')
  String get profileType => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProfileModelCopyWith<ProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $ProfileModelCopyWith<$Res> {
  factory $ProfileModelCopyWith(
    ProfileModel value,
    $Res Function(ProfileModel) then,
  ) = _$ProfileModelCopyWithImpl<$Res, ProfileModel>;
  $Res call({
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'display_name') String displayName,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'profile_type') String profileType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  });
}

class _$ProfileModelCopyWithImpl<$Res, $Val extends ProfileModel>
    implements $ProfileModelCopyWith<$Res> {
  _$ProfileModelCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? username = freezed,
    Object? avatarUrl = freezed,
    Object? profileType = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
        userId: userId == null
            ? _value.userId
            : userId as String,
        displayName: displayName == null
            ? _value.displayName
            : displayName as String,
        username: username == freezed
            ? _value.username
            : username as String?,
        avatarUrl: avatarUrl == freezed
            ? _value.avatarUrl
            : avatarUrl as String?,
        profileType: profileType == null
            ? _value.profileType
            : profileType as String,
        createdAt: createdAt == freezed
            ? _value.createdAt
            : createdAt as DateTime?,
        updatedAt: updatedAt == freezed
            ? _value.updatedAt
            : updatedAt as DateTime?,
        deletedAt: deletedAt == freezed
            ? _value.deletedAt
            : deletedAt as DateTime?,
      ) as $Val,
    );
  }
}

abstract class _$$_ProfileModelCopyWith<$Res>
    implements $ProfileModelCopyWith<$Res> {
  factory _$$_ProfileModelCopyWith(
    _$_ProfileModel value,
    $Res Function(_$_ProfileModel) then,
  ) = __$$_ProfileModelCopyWithImpl<$Res>;
  @override
  $Res call({
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'display_name') String displayName,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'profile_type') String profileType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  });
}

class __$$_ProfileModelCopyWithImpl<$Res>
    extends _$ProfileModelCopyWithImpl<$Res, _$_ProfileModel>
    implements _$$_ProfileModelCopyWith<$Res> {
  __$$_ProfileModelCopyWithImpl(
    _$_ProfileModel _value,
    $Res Function(_$_ProfileModel) _then,
  ) : super(_value, _then);

  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? username = freezed,
    Object? avatarUrl = freezed,
    Object? profileType = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(
      _$_ProfileModel(
        userId: userId == null ? _value.userId : userId as String,
        displayName:
            displayName == null ? _value.displayName : displayName as String,
        username: username == freezed ? _value.username : username as String?,
        avatarUrl:
            avatarUrl == freezed ? _value.avatarUrl : avatarUrl as String?,
        profileType:
            profileType == null ? _value.profileType : profileType as String,
        createdAt:
            createdAt == freezed ? _value.createdAt : createdAt as DateTime?,
        updatedAt:
            updatedAt == freezed ? _value.updatedAt : updatedAt as DateTime?,
        deletedAt:
            deletedAt == freezed ? _value.deletedAt : deletedAt as DateTime?,
      ),
    );
  }
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class _$_ProfileModel extends _ProfileModel {
  const _$_ProfileModel({
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'display_name') required this.displayName,
    @JsonKey(name: 'username') this.username,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    @JsonKey(name: 'profile_type') this.profileType = 'player',
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'deleted_at') this.deletedAt,
  }) : super._();

  factory _$_ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$$_ProfileModelFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  @JsonKey(name: 'username')
  final String? username;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'profile_type')
  final String profileType;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'ProfileModel(userId: $userId, displayName: $displayName, username: $username, avatarUrl: $avatarUrl, profileType: $profileType, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _$_ProfileModel &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.username == username &&
        other.avatarUrl == avatarUrl &&
        other.profileType == profileType &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        userId,
        displayName,
        username,
        avatarUrl,
        profileType,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @JsonKey(ignore: true)
  @override
  _$$_ProfileModelCopyWith<_$_ProfileModel> get copyWith =>
      __$$_ProfileModelCopyWithImpl<_$_ProfileModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ProfileModelToJson(this);
  }
}

abstract class _ProfileModel extends ProfileModel {
  const factory _ProfileModel({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'profile_type') String profileType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _$_ProfileModel;
  const _ProfileModel._() : super._();

  factory _ProfileModel.fromJson(Map<String, dynamic> json) =
      _$_ProfileModel.fromJson;

  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  @JsonKey(name: 'username')
  String? get username;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'profile_type')
  String get profileType;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @override
  @JsonKey(ignore: true)
  _$$_ProfileModelCopyWith<_$_ProfileModel> get copyWith;
}
