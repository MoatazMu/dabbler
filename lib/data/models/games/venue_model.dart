import 'package:dabbler/data/models/games/venue.dart';

class VenueModel extends Venue {
  const VenueModel({
    required super.id,
    required super.name,
    required super.description,
    required super.addressLine1,
    super.addressLine2,
    required super.city,
    required super.state,
    required super.country,
    required super.postalCode,
    required super.latitude,
    required super.longitude,
    super.phone,
    super.email,
    super.website,
    required super.openingTime,
    required super.closingTime,
    required super.rating,
    required super.totalRatings,
    required super.pricePerHour,
    required super.currency,
    required super.supportedSports,
    required super.amenities,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    try {
      // Use name_en for English name, fallback to name if present
      final name =
          json['name_en'] as String? ??
          json['name'] as String? ??
          'Unnamed Venue';
      print('🏟️ [DEBUG] Parsing venue: $name');
      return VenueModel(
        id: json['id'] as String,
        name: name,
        description:
            json['description_en'] as String? ??
            json['description'] as String? ??
            '',
        addressLine1:
            json['address_line1'] as String? ??
            json['address_line_1'] as String? ??
            '',
        addressLine2:
            json['address_line2'] as String? ??
            json['address_line_2'] as String?,
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        postalCode: json['postal_code'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        phone: json['phone_number'] as String? ?? json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        openingTime: _parseTime(json['opening_time']) ?? '09:00',
        closingTime: _parseTime(json['closing_time']) ?? '18:00',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        totalRatings: json['total_ratings'] as int? ?? 0,
        pricePerHour: (json['price_per_hour'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'USD',
        supportedSports:
            _parseStringList(json['supported_sports']) ??
            ['Football', 'Padel'], // Default sports
        amenities:
            _parseAmenities(json['venue_amenities'] ?? json['amenities']) ?? [],
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    } catch (e, stackTrace) {
      print('❌ [ERROR] Failed to parse venue: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static String? _parseTime(dynamic timeData) {
    if (timeData == null) return null;
    if (timeData is String) return timeData;
    // Handle PostgreSQL time format
    return timeData.toString();
  }

  static List<String>? _parseStringList(dynamic listData) {
    if (listData == null) return null;

    if (listData is List) {
      return listData.map((item) => item.toString()).toList();
    }

    if (listData is String) {
      if (listData.contains(',')) {
        return listData.split(',').map((s) => s.trim()).toList();
      }
      return [listData];
    }

    return null;
  }

  static List<String>? _parseAmenities(dynamic amenitiesData) {
    if (amenitiesData == null) return null;

    if (amenitiesData is List) {
      // Handle array of amenity objects
      return amenitiesData.map((item) {
        if (item is Map<String, dynamic>) {
          return item['name'] as String? ??
              item['amenity'] as String? ??
              item.toString();
        }
        return item.toString();
      }).toList();
    }

    return _parseStringList(amenitiesData);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'rating': rating,
      'total_ratings': totalRatings,
      'price_per_hour': pricePerHour,
      'currency': currency,
      'supported_sports': supportedSports,
      'amenities': amenities,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'description': description,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'price_per_hour': pricePerHour,
      'currency': currency,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'price_per_hour': pricePerHour,
      'currency': currency,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Get formatted distance string
  String getFormattedDistance(double fromLatitude, double fromLongitude) {
    final distance = distanceFrom(fromLatitude, fromLongitude);

    if (distance < 1000) {
      return '${distance.round()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  // Get venue coordinate as string
  String get coordinateString {
    return '$latitude, $longitude';
  }

  // Get full address string
  @override
  String get fullAddress {
    final parts = <String>[addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country.isNotEmpty) parts.add(country);
    if (postalCode.isNotEmpty) parts.add(postalCode);

    return parts.join(', ');
  }

  // Get rating display string
  String get ratingDisplay {
    if (totalRatings == 0) return 'No ratings';
    return '${rating.toStringAsFixed(1)} ($totalRatings reviews)';
  }

  // Check if venue has specific amenity
  @override
  bool hasAmenity(String amenityName) {
    return amenities.any(
      (amenity) => amenity.toLowerCase().contains(amenityName.toLowerCase()),
    );
  }

  // Check if venue supports specific sport
  @override
  bool supportsSport(String sportName) {
    return supportedSports.any(
      (sport) => sport.toLowerCase().contains(sportName.toLowerCase()),
    );
  }

  // Get price display text
  String get priceDisplay {
    return '$currency${pricePerHour.toStringAsFixed(2)}/hour';
  }

  // Get operating hours display text
  String get operatingHoursDisplay {
    return '$openingTime - $closingTime';
  }

  factory VenueModel.fromVenue(Venue venue) {
    return VenueModel(
      id: venue.id,
      name: venue.name,
      description: venue.description,
      addressLine1: venue.addressLine1,
      addressLine2: venue.addressLine2,
      city: venue.city,
      state: venue.state,
      country: venue.country,
      postalCode: venue.postalCode,
      latitude: venue.latitude,
      longitude: venue.longitude,
      phone: venue.phone,
      email: venue.email,
      website: venue.website,
      openingTime: venue.openingTime,
      closingTime: venue.closingTime,
      rating: venue.rating,
      totalRatings: venue.totalRatings,
      pricePerHour: venue.pricePerHour,
      currency: venue.currency,
      supportedSports: venue.supportedSports,
      amenities: venue.amenities,
      createdAt: venue.createdAt,
      updatedAt: venue.updatedAt,
    );
  }

  @override
  VenueModel copyWith({
    String? id,
    String? name,
    String? description,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? website,
    String? openingTime,
    String? closingTime,
    double? rating,
    int? totalRatings,
    double? pricePerHour,
    String? currency,
    List<String>? supportedSports,
    List<String>? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VenueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      currency: currency ?? this.currency,
      supportedSports: supportedSports ?? this.supportedSports,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
