// coverage:ignore-file
// GENERATED CODE - MANUALLY WRITTEN TO MIRROR FREEZED OUTPUT
// ignore_for_file: type=lint

part of 'profile.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by Freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed',
);

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _$_Profile.fromJson(json);
}

mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_type')
  String get profileType => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get language => throw _privateConstructorUsedError;
  bool? get verified => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool? get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name_norm')
  String? get displayNameNorm => throw _privateConstructorUsedError;
  @JsonKey(name: 'geo_lat')
  double? get geoLat => throw _privateConstructorUsedError;
  @JsonKey(name: 'geo_lng')
  double? get geoLng => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'profile_type') String profileType,
    String? username,
    @JsonKey(name: 'display_name') String displayName,
    String? bio,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? city,
    String? country,
    String? language,
    bool? verified,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'display_name_norm') String? displayNameNorm,
    @JsonKey(name: 'geo_lat') double? geoLat,
    @JsonKey(name: 'geo_lng') double? geoLng,
  });
}

class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? profileType = null,
    Object? username = freezed,
    Object? displayName = null,
    Object? bio = freezed,
    Object? avatarUrl = freezed,
    Object? city = freezed,
    Object? country = freezed,
    Object? language = freezed,
    Object? verified = freezed,
    Object? isActive = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? displayNameNorm = freezed,
    Object? geoLat = freezed,
    Object? geoLng = freezed,
  }) {
    return _then(
      _value.copyWith(
        id: id == null ? _value.id : id as String,
        userId: userId == null ? _value.userId : userId as String,
        profileType:
            profileType == null ? _value.profileType : profileType as String,
        username: username == freezed ? _value.username : username as String?,
        displayName:
            displayName == null ? _value.displayName : displayName as String,
        bio: bio == freezed ? _value.bio : bio as String?,
        avatarUrl: avatarUrl == freezed ? _value.avatarUrl : avatarUrl as String?,
        city: city == freezed ? _value.city : city as String?,
        country: country == freezed ? _value.country : country as String?,
        language: language == freezed ? _value.language : language as String?,
        verified: verified == freezed ? _value.verified : verified as bool?,
        isActive: isActive == freezed ? _value.isActive : isActive as bool?,
        createdAt:
            createdAt == freezed ? _value.createdAt : createdAt as DateTime?,
        updatedAt:
            updatedAt == freezed ? _value.updatedAt : updatedAt as DateTime?,
        displayNameNorm: displayNameNorm == freezed
            ? _value.displayNameNorm
            : displayNameNorm as String?,
        geoLat: geoLat == freezed ? _value.geoLat : geoLat as double?,
        geoLng: geoLng == freezed ? _value.geoLng : geoLng as double?,
      ) as $Val,
    );
  }
}

abstract class _$$_ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$_ProfileCopyWith(
          _$_Profile value, $Res Function(_$_Profile) then) =
      __$$_ProfileCopyWithImpl<$Res>;
  @override
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'profile_type') String profileType,
    String? username,
    @JsonKey(name: 'display_name') String displayName,
    String? bio,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? city,
    String? country,
    String? language,
    bool? verified,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'display_name_norm') String? displayNameNorm,
    @JsonKey(name: 'geo_lat') double? geoLat,
    @JsonKey(name: 'geo_lng') double? geoLng,
  });
}

class __$$_ProfileCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$_Profile>
    implements _$$_ProfileCopyWith<$Res> {
  __$$_ProfileCopyWithImpl(_$_Profile _value, $Res Function(_$_Profile) _then)
      : super(_value, _then);

  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? profileType = null,
    Object? username = freezed,
    Object? displayName = null,
    Object? bio = freezed,
    Object? avatarUrl = freezed,
    Object? city = freezed,
    Object? country = freezed,
    Object? language = freezed,
    Object? verified = freezed,
    Object? isActive = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? displayNameNorm = freezed,
    Object? geoLat = freezed,
    Object? geoLng = freezed,
  }) {
    return _then(_$_Profile(
      id: id == null ? _value.id : id as String,
      userId: userId == null ? _value.userId : userId as String,
      profileType:
          profileType == null ? _value.profileType : profileType as String,
      username: username == freezed ? _value.username : username as String?,
      displayName:
          displayName == null ? _value.displayName : displayName as String,
      bio: bio == freezed ? _value.bio : bio as String?,
      avatarUrl: avatarUrl == freezed ? _value.avatarUrl : avatarUrl as String?,
      city: city == freezed ? _value.city : city as String?,
      country: country == freezed ? _value.country : country as String?,
      language: language == freezed ? _value.language : language as String?,
      verified: verified == freezed ? _value.verified : verified as bool?,
      isActive: isActive == freezed ? _value.isActive : isActive as bool?,
      createdAt:
          createdAt == freezed ? _value.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == freezed ? _value.updatedAt : updatedAt as DateTime?,
      displayNameNorm: displayNameNorm == freezed
          ? _value.displayNameNorm
          : displayNameNorm as String?,
      geoLat: geoLat == freezed ? _value.geoLat : geoLat as double?,
      geoLng: geoLng == freezed ? _value.geoLng : geoLng as double?,
    ));
  }
}

@JsonSerializable()
class _$_Profile implements _Profile {
  const _$_Profile({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'profile_type') required this.profileType,
    this.username,
    @JsonKey(name: 'display_name') required this.displayName,
    this.bio,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    this.city,
    this.country,
    this.language,
    this.verified,
    @JsonKey(name: 'is_active') this.isActive,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'display_name_norm') this.displayNameNorm,
    @JsonKey(name: 'geo_lat') this.geoLat,
    @JsonKey(name: 'geo_lng') this.geoLng,
  });

  factory _$_Profile.fromJson(Map<String, dynamic> json) =>
      _$$_ProfileFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'profile_type')
  final String profileType;
  @override
  final String? username;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  final String? bio;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  final String? city;
  @override
  final String? country;
  @override
  final String? language;
  @override
  final bool? verified;
  @override
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'display_name_norm')
  final String? displayNameNorm;
  @override
  @JsonKey(name: 'geo_lat')
  final double? geoLat;
  @override
  @JsonKey(name: 'geo_lng')
  final double? geoLng;

  @override
  String toString() {
    return 'Profile(id: $id, userId: $userId, profileType: $profileType, username: $username, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, city: $city, country: $country, language: $language, verified: $verified, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, displayNameNorm: $displayNameNorm, geoLat: $geoLat, geoLng: $geoLng)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Profile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.profileType, profileType) ||
                other.profileType == profileType) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.displayNameNorm, displayNameNorm) ||
                other.displayNameNorm == displayNameNorm) &&
            (identical(other.geoLat, geoLat) || other.geoLat == geoLat) &&
            (identical(other.geoLng, geoLng) || other.geoLng == geoLng));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        userId,
        profileType,
        username,
        displayName,
        bio,
        avatarUrl,
        city,
        country,
        language,
        verified,
        isActive,
        createdAt,
        updatedAt,
        displayNameNorm,
        geoLat,
        geoLng,
      );

  @JsonKey(ignore: true)
  @override
  _$$_ProfileCopyWith<_$_Profile> get copyWith =>
      __$$_ProfileCopyWithImpl<_$_Profile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ProfileToJson(this);
  }
}

abstract class _Profile implements Profile {
  const factory _Profile({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'profile_type') required final String profileType,
    final String? username,
    @JsonKey(name: 'display_name') required final String displayName,
    final String? bio,
    @JsonKey(name: 'avatar_url') final String? avatarUrl,
    final String? city,
    final String? country,
    final String? language,
    final bool? verified,
    @JsonKey(name: 'is_active') final bool? isActive,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'display_name_norm') final String? displayNameNorm,
    @JsonKey(name: 'geo_lat') final double? geoLat,
    @JsonKey(name: 'geo_lng') final double? geoLng,
  }) = _$_Profile;

  factory _Profile.fromJson(Map<String, dynamic> json) = _$_Profile.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'profile_type')
  String get profileType;
  @override
  String? get username;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String? get bio;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  String? get city;
  @override
  String? get country;
  @override
  String? get language;
  @override
  bool? get verified;
  @override
  @JsonKey(name: 'is_active')
  bool? get isActive;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'display_name_norm')
  String? get displayNameNorm;
  @override
  @JsonKey(name: 'geo_lat')
  double? get geoLat;
  @override
  @JsonKey(name: 'geo_lng')
  double? get geoLng;
  @override
  @JsonKey(ignore: true)
  _$$_ProfileCopyWith<_$_Profile> get copyWith => throw _privateConstructorUsedError;
}
