// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_type')
  String get profileType => throw _privateConstructorUsedError;
  @JsonKey(name: 'username')
  String get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'bio')
  String? get bio => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'city')
  String? get city => throw _privateConstructorUsedError;
  @JsonKey(name: 'country')
  String? get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'language')
  String? get language => throw _privateConstructorUsedError;
  @JsonKey(name: 'verified')
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
  double? get geoLng => throw _privateConstructorUsedError; // New onboarding fields
  @JsonKey(name: 'intention')
  String? get intention => throw _privateConstructorUsedError;
  @JsonKey(name: 'gender')
  String? get gender => throw _privateConstructorUsedError;
  @JsonKey(name: 'age')
  int? get age => throw _privateConstructorUsedError;
  @JsonKey(name: 'preferred_sport')
  String? get preferredSport => throw _privateConstructorUsedError;
  @JsonKey(name: 'interests')
  String? get interests => throw _privateConstructorUsedError;

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'profile_type') String profileType,
    @JsonKey(name: 'username') String username,
    @JsonKey(name: 'display_name') String displayName,
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
    @JsonKey(name: 'intention') String? intention,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'age') int? age,
    @JsonKey(name: 'preferred_sport') String? preferredSport,
    @JsonKey(name: 'interests') String? interests,
  });
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? profileType = null,
    Object? username = null,
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
    Object? intention = freezed,
    Object? gender = freezed,
    Object? age = freezed,
    Object? preferredSport = freezed,
    Object? interests = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            profileType: null == profileType
                ? _value.profileType
                : profileType // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
            country: freezed == country
                ? _value.country
                : country // ignore: cast_nullable_to_non_nullable
                      as String?,
            language: freezed == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String?,
            verified: freezed == verified
                ? _value.verified
                : verified // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isActive: freezed == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            displayNameNorm: freezed == displayNameNorm
                ? _value.displayNameNorm
                : displayNameNorm // ignore: cast_nullable_to_non_nullable
                      as String?,
            geoLat: freezed == geoLat
                ? _value.geoLat
                : geoLat // ignore: cast_nullable_to_non_nullable
                      as double?,
            geoLng: freezed == geoLng
                ? _value.geoLng
                : geoLng // ignore: cast_nullable_to_non_nullable
                      as double?,
            intention: freezed == intention
                ? _value.intention
                : intention // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String?,
            age: freezed == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as int?,
            preferredSport: freezed == preferredSport
                ? _value.preferredSport
                : preferredSport // ignore: cast_nullable_to_non_nullable
                      as String?,
            interests: freezed == interests
                ? _value.interests
                : interests // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
    _$ProfileImpl value,
    $Res Function(_$ProfileImpl) then,
  ) = __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'profile_type') String profileType,
    @JsonKey(name: 'username') String username,
    @JsonKey(name: 'display_name') String displayName,
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
    @JsonKey(name: 'intention') String? intention,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'age') int? age,
    @JsonKey(name: 'preferred_sport') String? preferredSport,
    @JsonKey(name: 'interests') String? interests,
  });
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
    _$ProfileImpl _value,
    $Res Function(_$ProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? profileType = null,
    Object? username = null,
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
    Object? intention = freezed,
    Object? gender = freezed,
    Object? age = freezed,
    Object? preferredSport = freezed,
    Object? interests = freezed,
  }) {
    return _then(
      _$ProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        profileType: null == profileType
            ? _value.profileType
            : profileType // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
        country: freezed == country
            ? _value.country
            : country // ignore: cast_nullable_to_non_nullable
                  as String?,
        language: freezed == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
        verified: freezed == verified
            ? _value.verified
            : verified // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isActive: freezed == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        displayNameNorm: freezed == displayNameNorm
            ? _value.displayNameNorm
            : displayNameNorm // ignore: cast_nullable_to_non_nullable
                  as String?,
        geoLat: freezed == geoLat
            ? _value.geoLat
            : geoLat // ignore: cast_nullable_to_non_nullable
                  as double?,
        geoLng: freezed == geoLng
            ? _value.geoLng
            : geoLng // ignore: cast_nullable_to_non_nullable
                  as double?,
        intention: freezed == intention
            ? _value.intention
            : intention // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String?,
        age: freezed == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int?,
        preferredSport: freezed == preferredSport
            ? _value.preferredSport
            : preferredSport // ignore: cast_nullable_to_non_nullable
                  as String?,
        interests: freezed == interests
            ? _value.interests
            : interests // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl extends _Profile {
  const _$ProfileImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'profile_type') required this.profileType,
    @JsonKey(name: 'username') required this.username,
    @JsonKey(name: 'display_name') required this.displayName,
    @JsonKey(name: 'bio') this.bio,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    @JsonKey(name: 'city') this.city,
    @JsonKey(name: 'country') this.country,
    @JsonKey(name: 'language') this.language,
    @JsonKey(name: 'verified') this.verified,
    @JsonKey(name: 'is_active') this.isActive,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'display_name_norm') this.displayNameNorm,
    @JsonKey(name: 'geo_lat') this.geoLat,
    @JsonKey(name: 'geo_lng') this.geoLng,
    @JsonKey(name: 'intention') this.intention,
    @JsonKey(name: 'gender') this.gender,
    @JsonKey(name: 'age') this.age,
    @JsonKey(name: 'preferred_sport') this.preferredSport,
    @JsonKey(name: 'interests') this.interests,
  }) : super._();

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'profile_type')
  final String profileType;
  @override
  @JsonKey(name: 'username')
  final String username;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  @JsonKey(name: 'bio')
  final String? bio;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'city')
  final String? city;
  @override
  @JsonKey(name: 'country')
  final String? country;
  @override
  @JsonKey(name: 'language')
  final String? language;
  @override
  @JsonKey(name: 'verified')
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
  // New onboarding fields
  @override
  @JsonKey(name: 'intention')
  final String? intention;
  @override
  @JsonKey(name: 'gender')
  final String? gender;
  @override
  @JsonKey(name: 'age')
  final int? age;
  @override
  @JsonKey(name: 'preferred_sport')
  final String? preferredSport;
  @override
  @JsonKey(name: 'interests')
  final String? interests;

  @override
  String toString() {
    return 'Profile(id: $id, userId: $userId, profileType: $profileType, username: $username, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, city: $city, country: $country, language: $language, verified: $verified, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, displayNameNorm: $displayNameNorm, geoLat: $geoLat, geoLng: $geoLng, intention: $intention, gender: $gender, age: $age, preferredSport: $preferredSport, interests: $interests)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
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
            (identical(other.geoLng, geoLng) || other.geoLng == geoLng) &&
            (identical(other.intention, intention) ||
                other.intention == intention) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.preferredSport, preferredSport) ||
                other.preferredSport == preferredSport) &&
            (identical(other.interests, interests) ||
                other.interests == interests));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
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
    intention,
    gender,
    age,
    preferredSport,
    interests,
  ]);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(this);
  }
}

abstract class _Profile extends Profile {
  const factory _Profile({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'profile_type') required final String profileType,
    @JsonKey(name: 'username') required final String username,
    @JsonKey(name: 'display_name') required final String displayName,
    @JsonKey(name: 'bio') final String? bio,
    @JsonKey(name: 'avatar_url') final String? avatarUrl,
    @JsonKey(name: 'city') final String? city,
    @JsonKey(name: 'country') final String? country,
    @JsonKey(name: 'language') final String? language,
    @JsonKey(name: 'verified') final bool? verified,
    @JsonKey(name: 'is_active') final bool? isActive,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'display_name_norm') final String? displayNameNorm,
    @JsonKey(name: 'geo_lat') final double? geoLat,
    @JsonKey(name: 'geo_lng') final double? geoLng,
    @JsonKey(name: 'intention') final String? intention,
    @JsonKey(name: 'gender') final String? gender,
    @JsonKey(name: 'age') final int? age,
    @JsonKey(name: 'preferred_sport') final String? preferredSport,
    @JsonKey(name: 'interests') final String? interests,
  }) = _$ProfileImpl;
  const _Profile._() : super._();

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'profile_type')
  String get profileType;
  @override
  @JsonKey(name: 'username')
  String get username;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  @JsonKey(name: 'bio')
  String? get bio;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'city')
  String? get city;
  @override
  @JsonKey(name: 'country')
  String? get country;
  @override
  @JsonKey(name: 'language')
  String? get language;
  @override
  @JsonKey(name: 'verified')
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
  double? get geoLng; // New onboarding fields
  @override
  @JsonKey(name: 'intention')
  String? get intention;
  @override
  @JsonKey(name: 'gender')
  String? get gender;
  @override
  @JsonKey(name: 'age')
  int? get age;
  @override
  @JsonKey(name: 'preferred_sport')
  String? get preferredSport;
  @override
  @JsonKey(name: 'interests')
  String? get interests;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
