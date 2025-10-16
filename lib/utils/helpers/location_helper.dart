import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for location-related operations
class LocationHelper {
  static const String _distanceUnitKey = 'preferred_distance_unit';
  
  /// Get the current location with permission handling
  static Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(LocationError.serviceDisabled);
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error(LocationError.permissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(LocationError.permissionDeniedForever);
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout);

      return LocationResult.success(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
      );
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return LocationResult.error(LocationError.timeout);
      }
      return LocationResult.error(LocationError.unknown);
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Format distance with appropriate units
  static String formatDistance(
    double distanceKm, {
    DistanceUnit? unit,
    bool showUnit = true,
  }) {
    unit ??= getPreferredDistanceUnit();

    switch (unit) {
      case DistanceUnit.metric:
        if (distanceKm < 1) {
          final meters = (distanceKm * 1000).round();
          return showUnit ? '${meters}m' : meters.toString();
        } else {
          final km = distanceKm.toStringAsFixed(1);
          return showUnit ? '${km}km' : km;
        }

      case DistanceUnit.imperial:
        final miles = distanceKm * 0.621371;
        if (miles < 0.1) {
          final feet = (miles * 5280).round();
          return showUnit ? '${feet}ft' : feet.toString();
        } else {
          final mi = miles.toStringAsFixed(1);
          return showUnit ? '${mi}mi' : mi;
        }
    }
  }

  /// Get user's preferred distance unit
  static DistanceUnit getPreferredDistanceUnit() {
    // This would be stored in SharedPreferences
    // For now, return metric as default
    return DistanceUnit.metric;
  }

  /// Set user's preferred distance unit
  static Future<void> setPreferredDistanceUnit(DistanceUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_distanceUnitKey, unit.name);
  }

  /// Load preferred distance unit from storage
  static Future<DistanceUnit> loadPreferredDistanceUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final unitName = prefs.getString(_distanceUnitKey);
    
    if (unitName != null) {
      return DistanceUnit.values.firstWhere(
        (unit) => unit.name == unitName,
        orElse: () => DistanceUnit.metric,
      );
    }
    
    return DistanceUnit.metric;
  }

  /// Convert address to coordinates (geocoding)
  static Future<GeocodingResult> addressToCoordinates(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isEmpty) {
        return GeocodingResult.error(GeocodingError.notFound);
      }

      final location = locations.first;
      return GeocodingResult.success(
        Coordinates(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
    } catch (e) {
      return GeocodingResult.error(GeocodingError.apiError);
    }
  }

  /// Convert coordinates to address (reverse geocoding)
  static Future<ReverseGeocodingResult> coordinatesToAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return ReverseGeocodingResult.error(GeocodingError.notFound);
      }

      final placemark = placemarks.first;
      final address = VenueAddress(
        street: placemark.street ?? '',
        city: placemark.locality ?? '',
        state: placemark.administrativeArea ?? '',
        country: placemark.country ?? '',
        postalCode: placemark.postalCode ?? '',
        formattedAddress: _formatPlacemarkAddress(placemark),
      );

      return ReverseGeocodingResult.success(address);
    } catch (e) {
      return ReverseGeocodingResult.error(GeocodingError.apiError);
    }
  }

  /// Check if location is within a radius of center point
  static bool isWithinRadius(
    double centerLat,
    double centerLon,
    double pointLat,
    double pointLon,
    double radiusKm,
  ) {
    final distance = calculateDistance(centerLat, centerLon, pointLat, pointLon);
    return distance <= radiusKm;
  }

  /// Get approximate distance to user's location
  static Future<String?> getDistanceToUser(
    double venueLat,
    double venueLon,
  ) async {
    final locationResult = await getCurrentLocation();
    
    if (locationResult.isSuccess) {
      final userLocation = locationResult.location!;
      final distance = calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        venueLat,
        venueLon,
      );
      return formatDistance(distance);
    }
    
    return null;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Format placemark to readable address
  static String _formatPlacemarkAddress(Placemark placemark) {
    final components = <String>[];
    
    if (placemark.street?.isNotEmpty == true) {
      components.add(placemark.street!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      components.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      components.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode?.isNotEmpty == true) {
      components.add(placemark.postalCode!);
    }
    
    return components.join(', ');
  }
}

/// User's current location data
class UserLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'UserLocation(lat: $latitude, lon: $longitude, accuracy: ${accuracy}m)';
  }
}

/// Coordinates data class
class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return 'Coordinates($latitude, $longitude)';
  }
}

/// Venue address information
class VenueAddress {
  final String street;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String formattedAddress;

  const VenueAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.formattedAddress,
  });

  @override
  String toString() => formattedAddress;
}

/// Distance unit enumeration
enum DistanceUnit {
  metric,
  imperial,
}

/// Location operation result
class LocationResult {
  final UserLocation? location;
  final LocationError? error;

  const LocationResult._({this.location, this.error});

  factory LocationResult.success(UserLocation location) {
    return LocationResult._(location: location);
  }

  factory LocationResult.error(LocationError error) {
    return LocationResult._(error: error);
  }

  bool get isSuccess => location != null;
  bool get isError => error != null;
}

/// Geocoding operation result
class GeocodingResult {
  final Coordinates? coordinates;
  final GeocodingError? error;

  const GeocodingResult._({this.coordinates, this.error});

  factory GeocodingResult.success(Coordinates coordinates) {
    return GeocodingResult._(coordinates: coordinates);
  }

  factory GeocodingResult.error(GeocodingError error) {
    return GeocodingResult._(error: error);
  }

  bool get isSuccess => coordinates != null;
  bool get isError => error != null;
}

/// Reverse geocoding operation result
class ReverseGeocodingResult {
  final VenueAddress? address;
  final GeocodingError? error;

  const ReverseGeocodingResult._({this.address, this.error});

  factory ReverseGeocodingResult.success(VenueAddress address) {
    return ReverseGeocodingResult._(address: address);
  }

  factory ReverseGeocodingResult.error(GeocodingError error) {
    return ReverseGeocodingResult._(error: error);
  }

  bool get isSuccess => address != null;
  bool get isError => error != null;
}

/// Location-related errors
enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// Geocoding-related errors
enum GeocodingError {
  notFound,
  apiError,
  networkError,
}
