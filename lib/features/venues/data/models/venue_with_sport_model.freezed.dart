// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_with_sport_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VenueWithSportModel _$VenueWithSportModelFromJson(Map<String, dynamic> json) {
  return _VenueWithSportModel.fromJson(json);
}

/// @nodoc
mixin _$VenueWithSportModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sport_id')
  String get sportId => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_en')
  String get nameEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_ar')
  String? get nameAr => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String? get area => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_indoor')
  bool? get isIndoor => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_per_hour')
  double? get pricePerHour => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  @JsonKey(name: 'phone_number')
  String? get phoneNumber => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String> get amenities => throw _privateConstructorUsedError;
  @JsonKey(name: 'composite_score')
  double? get compositeScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this VenueWithSportModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VenueWithSportModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueWithSportModelCopyWith<VenueWithSportModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueWithSportModelCopyWith<$Res> {
  factory $VenueWithSportModelCopyWith(
    VenueWithSportModel value,
    $Res Function(VenueWithSportModel) then,
  ) = _$VenueWithSportModelCopyWithImpl<$Res, VenueWithSportModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sport_id') String sportId,
    @JsonKey(name: 'name_en') String nameEn,
    @JsonKey(name: 'name_ar') String? nameAr,
    String city,
    String? area,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'is_indoor') bool? isIndoor,
    @JsonKey(name: 'price_per_hour') double? pricePerHour,
    double? latitude,
    double? longitude,
    String? address,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    String? description,
    List<String> amenities,
    @JsonKey(name: 'composite_score') double? compositeScore,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$VenueWithSportModelCopyWithImpl<$Res, $Val extends VenueWithSportModel>
    implements $VenueWithSportModelCopyWith<$Res> {
  _$VenueWithSportModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VenueWithSportModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sportId = null,
    Object? nameEn = null,
    Object? nameAr = freezed,
    Object? city = null,
    Object? area = freezed,
    Object? isActive = null,
    Object? isIndoor = freezed,
    Object? pricePerHour = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? address = freezed,
    Object? phoneNumber = freezed,
    Object? description = freezed,
    Object? amenities = null,
    Object? compositeScore = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sportId: null == sportId
                ? _value.sportId
                : sportId // ignore: cast_nullable_to_non_nullable
                      as String,
            nameEn: null == nameEn
                ? _value.nameEn
                : nameEn // ignore: cast_nullable_to_non_nullable
                      as String,
            nameAr: freezed == nameAr
                ? _value.nameAr
                : nameAr // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            area: freezed == area
                ? _value.area
                : area // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            isIndoor: freezed == isIndoor
                ? _value.isIndoor
                : isIndoor // ignore: cast_nullable_to_non_nullable
                      as bool?,
            pricePerHour: freezed == pricePerHour
                ? _value.pricePerHour
                : pricePerHour // ignore: cast_nullable_to_non_nullable
                      as double?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            phoneNumber: freezed == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            amenities: null == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            compositeScore: freezed == compositeScore
                ? _value.compositeScore
                : compositeScore // ignore: cast_nullable_to_non_nullable
                      as double?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VenueWithSportModelImplCopyWith<$Res>
    implements $VenueWithSportModelCopyWith<$Res> {
  factory _$$VenueWithSportModelImplCopyWith(
    _$VenueWithSportModelImpl value,
    $Res Function(_$VenueWithSportModelImpl) then,
  ) = __$$VenueWithSportModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sport_id') String sportId,
    @JsonKey(name: 'name_en') String nameEn,
    @JsonKey(name: 'name_ar') String? nameAr,
    String city,
    String? area,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'is_indoor') bool? isIndoor,
    @JsonKey(name: 'price_per_hour') double? pricePerHour,
    double? latitude,
    double? longitude,
    String? address,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    String? description,
    List<String> amenities,
    @JsonKey(name: 'composite_score') double? compositeScore,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$VenueWithSportModelImplCopyWithImpl<$Res>
    extends _$VenueWithSportModelCopyWithImpl<$Res, _$VenueWithSportModelImpl>
    implements _$$VenueWithSportModelImplCopyWith<$Res> {
  __$$VenueWithSportModelImplCopyWithImpl(
    _$VenueWithSportModelImpl _value,
    $Res Function(_$VenueWithSportModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VenueWithSportModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sportId = null,
    Object? nameEn = null,
    Object? nameAr = freezed,
    Object? city = null,
    Object? area = freezed,
    Object? isActive = null,
    Object? isIndoor = freezed,
    Object? pricePerHour = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? address = freezed,
    Object? phoneNumber = freezed,
    Object? description = freezed,
    Object? amenities = null,
    Object? compositeScore = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$VenueWithSportModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sportId: null == sportId
            ? _value.sportId
            : sportId // ignore: cast_nullable_to_non_nullable
                  as String,
        nameEn: null == nameEn
            ? _value.nameEn
            : nameEn // ignore: cast_nullable_to_non_nullable
                  as String,
        nameAr: freezed == nameAr
            ? _value.nameAr
            : nameAr // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        area: freezed == area
            ? _value.area
            : area // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        isIndoor: freezed == isIndoor
            ? _value.isIndoor
            : isIndoor // ignore: cast_nullable_to_non_nullable
                  as bool?,
        pricePerHour: freezed == pricePerHour
            ? _value.pricePerHour
            : pricePerHour // ignore: cast_nullable_to_non_nullable
                  as double?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        phoneNumber: freezed == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        amenities: null == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        compositeScore: freezed == compositeScore
            ? _value.compositeScore
            : compositeScore // ignore: cast_nullable_to_non_nullable
                  as double?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueWithSportModelImpl implements _VenueWithSportModel {
  const _$VenueWithSportModelImpl({
    required this.id,
    @JsonKey(name: 'sport_id') required this.sportId,
    @JsonKey(name: 'name_en') required this.nameEn,
    @JsonKey(name: 'name_ar') this.nameAr,
    required this.city,
    this.area,
    @JsonKey(name: 'is_active') this.isActive = true,
    @JsonKey(name: 'is_indoor') this.isIndoor,
    @JsonKey(name: 'price_per_hour') this.pricePerHour,
    this.latitude,
    this.longitude,
    this.address,
    @JsonKey(name: 'phone_number') this.phoneNumber,
    this.description,
    final List<String> amenities = const [],
    @JsonKey(name: 'composite_score') this.compositeScore,
    @JsonKey(name: 'created_at') this.createdAt,
  }) : _amenities = amenities;

  factory _$VenueWithSportModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueWithSportModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sport_id')
  final String sportId;
  @override
  @JsonKey(name: 'name_en')
  final String nameEn;
  @override
  @JsonKey(name: 'name_ar')
  final String? nameAr;
  @override
  final String city;
  @override
  final String? area;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'is_indoor')
  final bool? isIndoor;
  @override
  @JsonKey(name: 'price_per_hour')
  final double? pricePerHour;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final String? address;
  @override
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @override
  final String? description;
  final List<String> _amenities;
  @override
  @JsonKey()
  List<String> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  @override
  @JsonKey(name: 'composite_score')
  final double? compositeScore;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'VenueWithSportModel(id: $id, sportId: $sportId, nameEn: $nameEn, nameAr: $nameAr, city: $city, area: $area, isActive: $isActive, isIndoor: $isIndoor, pricePerHour: $pricePerHour, latitude: $latitude, longitude: $longitude, address: $address, phoneNumber: $phoneNumber, description: $description, amenities: $amenities, compositeScore: $compositeScore, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueWithSportModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sportId, sportId) || other.sportId == sportId) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.nameAr, nameAr) || other.nameAr == nameAr) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.area, area) || other.area == area) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isIndoor, isIndoor) ||
                other.isIndoor == isIndoor) &&
            (identical(other.pricePerHour, pricePerHour) ||
                other.pricePerHour == pricePerHour) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            (identical(other.compositeScore, compositeScore) ||
                other.compositeScore == compositeScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sportId,
    nameEn,
    nameAr,
    city,
    area,
    isActive,
    isIndoor,
    pricePerHour,
    latitude,
    longitude,
    address,
    phoneNumber,
    description,
    const DeepCollectionEquality().hash(_amenities),
    compositeScore,
    createdAt,
  );

  /// Create a copy of VenueWithSportModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueWithSportModelImplCopyWith<_$VenueWithSportModelImpl> get copyWith =>
      __$$VenueWithSportModelImplCopyWithImpl<_$VenueWithSportModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueWithSportModelImplToJson(this);
  }
}

abstract class _VenueWithSportModel implements VenueWithSportModel {
  const factory _VenueWithSportModel({
    required final String id,
    @JsonKey(name: 'sport_id') required final String sportId,
    @JsonKey(name: 'name_en') required final String nameEn,
    @JsonKey(name: 'name_ar') final String? nameAr,
    required final String city,
    final String? area,
    @JsonKey(name: 'is_active') final bool isActive,
    @JsonKey(name: 'is_indoor') final bool? isIndoor,
    @JsonKey(name: 'price_per_hour') final double? pricePerHour,
    final double? latitude,
    final double? longitude,
    final String? address,
    @JsonKey(name: 'phone_number') final String? phoneNumber,
    final String? description,
    final List<String> amenities,
    @JsonKey(name: 'composite_score') final double? compositeScore,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$VenueWithSportModelImpl;

  factory _VenueWithSportModel.fromJson(Map<String, dynamic> json) =
      _$VenueWithSportModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sport_id')
  String get sportId;
  @override
  @JsonKey(name: 'name_en')
  String get nameEn;
  @override
  @JsonKey(name: 'name_ar')
  String? get nameAr;
  @override
  String get city;
  @override
  String? get area;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'is_indoor')
  bool? get isIndoor;
  @override
  @JsonKey(name: 'price_per_hour')
  double? get pricePerHour;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  String? get address;
  @override
  @JsonKey(name: 'phone_number')
  String? get phoneNumber;
  @override
  String? get description;
  @override
  List<String> get amenities;
  @override
  @JsonKey(name: 'composite_score')
  double? get compositeScore;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of VenueWithSportModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueWithSportModelImplCopyWith<_$VenueWithSportModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
