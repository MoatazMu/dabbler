import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// Venue search optimization and management service
class VenuesService {
  final VenuesRepository _venuesRepository;
  final LocationService _locationService;
  final PricingEngine _pricingEngine;
  final CacheService _cacheService;

  // Cache keys
  static const String _availabilityCacheKey = 'venue_availability';
  static const String _searchResultsCacheKey = 'venue_search';
  static const String _recommendationsCacheKey = 'venue_recommendations';

  VenuesService({
    required VenuesRepository venuesRepository,
    required LocationService locationService,
    required PricingEngine pricingEngine,
    required CacheService cacheService,
  }) : _venuesRepository = venuesRepository,
       _locationService = locationService,
       _pricingEngine = pricingEngine,
       _cacheService = cacheService;

  // VENUE SEARCH OPTIMIZATION
  Future<VenueSearchResult> searchVenues({
    required String sport,
    required DateTime dateTime,
    required Duration duration,
    Location? userLocation,
    double? maxDistance,
    PriceRange? priceRange,
    List<String>? requiredAmenities,
    String? skillLevel,
    int? minRating,
  }) async {
    try {
      // Generate cache key based on search parameters
      final cacheKey = _generateSearchCacheKey(
        sport: sport,
        dateTime: dateTime,
        duration: duration,
        userLocation: userLocation,
        maxDistance: maxDistance,
        priceRange: priceRange,
        requiredAmenities: requiredAmenities,
        skillLevel: skillLevel,
        minRating: minRating,
      );

      // Check cache first
      final cachedResult = await _cacheService.get<VenueSearchResult>(
        '$_searchResultsCacheKey:$cacheKey',
      );
      
      if (cachedResult != null && !_isCacheExpired(cachedResult.timestamp)) {
        return cachedResult;
      }

      // Get user location if not provided
      final searchLocation = userLocation ?? await _locationService.getCurrentLocation();

      // Search venues from repository
      final allVenues = await _venuesRepository.searchVenues(
        sport: sport,
        requiredAmenities: requiredAmenities,
        minRating: minRating,
      );

      // Filter and score venues
      final filteredVenues = <ScoredVenue>[];
      
      for (final venue in allVenues) {
        // Distance filter
        final distance = searchLocation != null
            ? _calculateDistance(searchLocation, venue.location)
            : 0.0;
            
        if (maxDistance != null && distance > maxDistance) continue;

        // Availability check
        final availability = await _checkVenueAvailability(
          venue,
          dateTime,
          duration,
        );
        
        if (!availability.isAvailable) continue;

        // Price calculation
        final pricing = await _pricingEngine.calculatePrice(
          venue: venue,
          dateTime: dateTime,
          duration: duration,
          sport: sport,
        );

        // Price range filter
        if (priceRange != null && !_isPriceInRange(pricing.totalPrice, priceRange)) {
          continue;
        }

        // Calculate venue score
        final score = _calculateVenueScore(
          venue: venue,
          distance: distance,
          pricing: pricing,
          userLocation: searchLocation,
          skillLevel: skillLevel,
        );

        filteredVenues.add(ScoredVenue(
          venue: venue,
          score: score,
          distance: distance,
          pricing: pricing,
          availability: availability,
        ));
      }

      // Sort by score
      filteredVenues.sort((a, b) => b.score.compareTo(a.score));

      final result = VenueSearchResult(
        venues: filteredVenues,
        timestamp: DateTime.now(),
        searchLocation: searchLocation,
        totalResults: filteredVenues.length,
      );

      // Cache the result
      await _cacheService.set(
        '$_searchResultsCacheKey:$cacheKey',
        result,
        duration: const Duration(minutes: 15),
      );

      return result;

    } catch (e, stackTrace) {
      debugPrint('Error searching venues: $e\n$stackTrace');
      return VenueSearchResult(
        venues: [],
        timestamp: DateTime.now(),
        searchLocation: null,
        totalResults: 0,
        error: 'Failed to search venues: $e',
      );
    }
  }

  // AVAILABILITY CACHING
  Future<VenueAvailabilityResult> checkAvailability({
    required String venueId,
    required DateTime dateTime,
    required Duration duration,
  }) async {
    // Check cache first
    final cacheKey = '${venueId}_${dateTime.millisecondsSinceEpoch}_${duration.inMinutes}';
    final cachedResult = await _cacheService.get<VenueAvailabilityResult>(
      '$_availabilityCacheKey:$cacheKey',
    );

    if (cachedResult != null && !_isCacheExpired(cachedResult.timestamp, minutes: 5)) {
      return cachedResult;
    }

    // Fetch from repository
    final venue = await _venuesRepository.getVenueById(venueId);
    if (venue == null) {
      return VenueAvailabilityResult(
        isAvailable: false,
        reason: 'Venue not found',
        timestamp: DateTime.now(),
      );
    }

    final availability = await _checkVenueAvailability(venue, dateTime, duration);

    // Cache the result
    await _cacheService.set(
      '$_availabilityCacheKey:$cacheKey',
      availability,
      duration: const Duration(minutes: 5),
    );

    return availability;
  }

  // DISTANCE CALCULATIONS
  double calculateDistance(Location from, Location to) {
    return _calculateDistance(from, to);
  }

  double _calculateDistance(Location from, Location to) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = from.latitude * math.pi / 180;
    final double lat2Rad = to.latitude * math.pi / 180;
    final double deltaLatRad = (to.latitude - from.latitude) * math.pi / 180;
    final double deltaLngRad = (to.longitude - from.longitude) * math.pi / 180;

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // VENUE RECOMMENDATION ENGINE
  Future<List<RecommendedVenue>> getRecommendations({
    required String userId,
    required String sport,
    Location? userLocation,
    int limit = 10,
  }) async {
    try {
      final cacheKey = '${userId}_${sport}_${userLocation?.toString() ?? 'no_location'}';
      
      // Check cache
      final cached = await _cacheService.get<List<RecommendedVenue>>(
        '$_recommendationsCacheKey:$cacheKey',
      );
      
      if (cached != null) {
        return cached.take(limit).toList();
      }

      // Get user's game history and preferences
      final userPreferences = await _getUserPreferences(userId, sport);
      final gameHistory = await _getUserGameHistory(userId, sport);
      
      // Get venues for the sport
      final venues = await _venuesRepository.searchVenues(sport: sport);
      
      // Score venues based on user preferences
      final recommendations = <RecommendedVenue>[];
      
      for (final venue in venues) {
        final score = _calculateRecommendationScore(
          venue: venue,
          userPreferences: userPreferences,
          gameHistory: gameHistory,
          userLocation: userLocation,
        );
        
        if (score > 0.3) { // Threshold for recommendations
          recommendations.add(RecommendedVenue(
            venue: venue,
            score: score,
            reasons: _generateRecommendationReasons(venue, userPreferences, gameHistory),
          ));
        }
      }
      
      // Sort by score
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      
      // Cache recommendations
      await _cacheService.set(
        '$_recommendationsCacheKey:$cacheKey',
        recommendations,
        duration: const Duration(hours: 1),
      );
      
      return recommendations.take(limit).toList();
      
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      return [];
    }
  }

  // DYNAMIC PRICING
  Future<VenuePricing> calculateDynamicPricing({
    required String venueId,
    required DateTime dateTime,
    required Duration duration,
    required String sport,
  }) async {
    final venue = await _venuesRepository.getVenueById(venueId);
    if (venue == null) {
      throw Exception('Venue not found');
    }

    return await _pricingEngine.calculatePrice(
      venue: venue,
      dateTime: dateTime,
      duration: duration,
      sport: sport,
    );
  }

  // PEAK/OFF-PEAK PRICING LOGIC
  bool isPeakTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final weekday = dateTime.weekday;
    
    // Weekend peak hours: 8AM - 8PM
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return hour >= 8 && hour <= 20;
    }
    
    // Weekday peak hours: 6PM - 10PM and 6AM - 9AM
    return (hour >= 18 && hour <= 22) || (hour >= 6 && hour <= 9);
  }

  double getPeakMultiplier(DateTime dateTime) {
    if (isPeakTime(dateTime)) {
      return 1.5; // 50% increase during peak times
    }
    
    // Off-peak discount
    final hour = dateTime.hour;
    if (hour >= 10 && hour <= 14) {
      return 0.8; // 20% discount during off-peak
    }
    
    return 1.0; // Standard pricing
  }

  // PRIVATE HELPER METHODS
  Future<VenueAvailabilityResult> _checkVenueAvailability(
    Venue venue,
    DateTime dateTime,
    Duration duration,
  ) async {
    try {
      // Check venue operating hours
      if (!_isWithinOperatingHours(venue, dateTime, duration)) {
        return VenueAvailabilityResult(
          isAvailable: false,
          reason: 'Outside venue operating hours',
          timestamp: DateTime.now(),
          suggestedTimes: _getSuggestedTimes(venue, dateTime),
        );
      }

      // Check existing bookings
      final existingBookings = await _venuesRepository.getVenueBookings(
        venue.id,
        dateTime.subtract(duration),
        dateTime.add(duration),
      );

      final endTime = dateTime.add(duration);
      
      for (final booking in existingBookings) {
        final bookingEnd = booking.dateTime.add(booking.duration);
        
        // Check for overlap
        if (dateTime.isBefore(bookingEnd) && endTime.isAfter(booking.dateTime)) {
          return VenueAvailabilityResult(
            isAvailable: false,
            reason: 'Venue already booked for this time',
            timestamp: DateTime.now(),
            suggestedTimes: _getSuggestedTimes(venue, dateTime),
            conflictingBooking: booking,
          );
        }
      }

      return VenueAvailabilityResult(
        isAvailable: true,
        timestamp: DateTime.now(),
        requiresBooking: venue.requiresBooking,
      );

    } catch (e) {
      return VenueAvailabilityResult(
        isAvailable: false,
        reason: 'Error checking availability: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  bool _isWithinOperatingHours(Venue venue, DateTime dateTime, Duration duration) {
    final dayOfWeek = dateTime.weekday;
    final operatingHours = venue.operatingHours[dayOfWeek];
    
    if (operatingHours == null || !operatingHours.isOpen) {
      return false;
    }

    final timeOfDay = TimeOfDay.fromDateTime(dateTime);
    final endTimeOfDay = TimeOfDay.fromDateTime(dateTime.add(duration));
    
    return _isTimeAfterOrEqual(timeOfDay, operatingHours.openTime) &&
           _isTimeBeforeOrEqual(endTimeOfDay, operatingHours.closeTime);
  }

  bool _isTimeAfterOrEqual(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour > time2.hour ||
           (time1.hour == time2.hour && time1.minute >= time2.minute);
  }

  bool _isTimeBeforeOrEqual(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour < time2.hour ||
           (time1.hour == time2.hour && time1.minute <= time2.minute);
  }

  List<DateTime> _getSuggestedTimes(Venue venue, DateTime requestedTime) {
    final suggestions = <DateTime>[];
    final baseDate = DateTime(requestedTime.year, requestedTime.month, requestedTime.day);
    
    // Suggest times for the same day
    for (int hour = 8; hour <= 20; hour += 2) {
      final suggestionTime = baseDate.add(Duration(hours: hour));
      if (suggestionTime.isAfter(DateTime.now()) && 
          _isWithinOperatingHours(venue, suggestionTime, const Duration(hours: 1))) {
        suggestions.add(suggestionTime);
      }
    }
    
    // Suggest times for next day if same day has no suggestions
    if (suggestions.isEmpty) {
      final nextDay = baseDate.add(const Duration(days: 1));
      for (int hour = 8; hour <= 20; hour += 2) {
        final suggestionTime = nextDay.add(Duration(hours: hour));
        if (_isWithinOperatingHours(venue, suggestionTime, const Duration(hours: 1))) {
          suggestions.add(suggestionTime);
          if (suggestions.length >= 3) break;
        }
      }
    }
    
    return suggestions.take(5).toList();
  }

  double _calculateVenueScore({
    required Venue venue,
    required double distance,
    required VenuePricing pricing,
    Location? userLocation,
    String? skillLevel,
  }) {
    double score = 0.0;

    // Base score from venue rating
    score += venue.rating * 20; // 0-100 points

    // Distance penalty (closer is better)
    if (distance <= 1.0) {
      score += 30; // Very close
    } else if (distance <= 5.0) {
      score += 20; // Close
    } else if (distance <= 15.0) {
      score += 10; // Moderate distance
    } else {
      score -= (distance - 15) * 2; // Penalty for far venues
    }

    // Price score (better value = higher score)
    final priceScore = math.max(0, 50 - (pricing.totalPrice * 2));
    score += priceScore;

    // Amenities bonus
    score += venue.amenities.length * 2;

    // Peak time penalty
    if (pricing.isPeakTime) {
      score -= 10;
    }

    // Skill level matching bonus
    if (skillLevel != null && venue.skillLevels.contains(skillLevel)) {
      score += 15;
    }

    return math.max(0, score / 100); // Normalize to 0-1 scale
  }

  double _calculateRecommendationScore({
    required Venue venue,
    required UserPreferences userPreferences,
    required List<GameHistory> gameHistory,
    Location? userLocation,
  }) {
    double score = 0.0;

    // Venue rating weight
    score += venue.rating * 0.2;

    // Distance preference
    if (userLocation != null) {
      final distance = _calculateDistance(userLocation, venue.location);
      if (distance <= userPreferences.maxPreferredDistance) {
        score += 0.3;
      } else {
        score -= (distance - userPreferences.maxPreferredDistance) * 0.05;
      }
    }

    // Price preference
    if (venue.averagePrice <= userPreferences.maxPreferredPrice) {
      score += 0.25;
    }

    // Previously played venues bonus
    if (gameHistory.any((game) => game.venueId == venue.id)) {
      score += 0.1;
    }

    // Amenity preferences
    final matchingAmenities = venue.amenities
        .where((amenity) => userPreferences.preferredAmenities.contains(amenity))
        .length;
    score += matchingAmenities * 0.05;

    return math.max(0, score);
  }

  List<String> _generateRecommendationReasons(
    Venue venue,
    UserPreferences preferences,
    List<GameHistory> history,
  ) {
    final reasons = <String>[];

    if (venue.rating >= 4.5) {
      reasons.add('Highly rated (${venue.rating}⭐)');
    }

    if (history.any((game) => game.venueId == venue.id)) {
      reasons.add('You\'ve played here before');
    }

    if (venue.averagePrice <= preferences.maxPreferredPrice * 0.8) {
      reasons.add('Great value for money');
    }

    final matchingAmenities = venue.amenities
        .where((amenity) => preferences.preferredAmenities.contains(amenity))
        .toList();
    
    if (matchingAmenities.isNotEmpty) {
      reasons.add('Has ${matchingAmenities.join(', ')}');
    }

    return reasons;
  }

  Future<UserPreferences> _getUserPreferences(String userId, String sport) async {
    // This would fetch from a repository
    return UserPreferences(
      maxPreferredDistance: 10.0,
      maxPreferredPrice: 50.0,
      preferredAmenities: ['parking', 'showers'],
    );
  }

  Future<List<GameHistory>> _getUserGameHistory(String userId, String sport) async {
    // This would fetch from a repository
    return [];
  }

  bool _isPriceInRange(double price, PriceRange range) {
    return price >= range.min && price <= range.max;
  }

  bool _isCacheExpired(DateTime timestamp, {int minutes = 15}) {
    return DateTime.now().difference(timestamp).inMinutes > minutes;
  }

  String _generateSearchCacheKey({
    required String sport,
    required DateTime dateTime,
    required Duration duration,
    Location? userLocation,
    double? maxDistance,
    PriceRange? priceRange,
    List<String>? requiredAmenities,
    String? skillLevel,
    int? minRating,
  }) {
    final buffer = StringBuffer();
    buffer.write('${sport}_');
    buffer.write('${dateTime.millisecondsSinceEpoch}_');
    buffer.write('${duration.inMinutes}_');
    buffer.write('${userLocation?.hashCode ?? 'no_loc'}_');
    buffer.write('${maxDistance?.toInt() ?? 'no_dist'}_');
    buffer.write('${priceRange?.hashCode ?? 'no_price'}_');
    buffer.write('${requiredAmenities?.join(',') ?? 'no_amenities'}_');
    buffer.write('${skillLevel ?? 'no_skill'}_');
    buffer.write('${minRating ?? 'no_rating'}');
    
    return buffer.toString().hashCode.toString();
  }

  Future<Venue?> getVenueById(String venueId) async {
    return await _venuesRepository.getVenueById(venueId);
  }
}

// Data classes
class VenueSearchResult {
  final List<ScoredVenue> venues;
  final DateTime timestamp;
  final Location? searchLocation;
  final int totalResults;
  final String? error;

  VenueSearchResult({
    required this.venues,
    required this.timestamp,
    required this.searchLocation,
    required this.totalResults,
    this.error,
  });
}

class ScoredVenue {
  final Venue venue;
  final double score;
  final double distance;
  final VenuePricing pricing;
  final VenueAvailabilityResult availability;

  ScoredVenue({
    required this.venue,
    required this.score,
    required this.distance,
    required this.pricing,
    required this.availability,
  });
}

class VenueAvailabilityResult {
  final bool isAvailable;
  final String? reason;
  final DateTime timestamp;
  final List<DateTime>? suggestedTimes;
  final VenueBooking? conflictingBooking;
  final bool requiresBooking;

  VenueAvailabilityResult({
    required this.isAvailable,
    this.reason,
    required this.timestamp,
    this.suggestedTimes,
    this.conflictingBooking,
    this.requiresBooking = false,
  });
}

class RecommendedVenue {
  final Venue venue;
  final double score;
  final List<String> reasons;

  RecommendedVenue({
    required this.venue,
    required this.score,
    required this.reasons,
  });
}

class VenuePricing {
  final double basePrice;
  final double peakMultiplier;
  final double totalPrice;
  final bool isPeakTime;
  final Map<String, double> breakdown;

  VenuePricing({
    required this.basePrice,
    required this.peakMultiplier,
    required this.totalPrice,
    required this.isPeakTime,
    required this.breakdown,
  });
}

class PriceRange {
  final double min;
  final double max;

  PriceRange({required this.min, required this.max});

  @override
  int get hashCode => min.hashCode ^ max.hashCode;
}

class UserPreferences {
  final double maxPreferredDistance;
  final double maxPreferredPrice;
  final List<String> preferredAmenities;

  UserPreferences({
    required this.maxPreferredDistance,
    required this.maxPreferredPrice,
    required this.preferredAmenities,
  });
}

class GameHistory {
  final String gameId;
  final String venueId;
  final DateTime dateTime;

  GameHistory({
    required this.gameId,
    required this.venueId,
    required this.dateTime,
  });
}

// Placeholder classes that would be implemented elsewhere
class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  @override
  String toString() => '($latitude,$longitude)';
  
  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

class Venue {
  final String id;
  final String name;
  final Location location;
  final List<String> supportedSports;
  final double rating;
  final List<String> amenities;
  final Map<int, OperatingHours> operatingHours;
  final bool requiresBooking;
  final double averagePrice;
  final List<String> skillLevels;

  Venue({
    required this.id,
    required this.name,
    required this.location,
    required this.supportedSports,
    required this.rating,
    required this.amenities,
    required this.operatingHours,
    required this.requiresBooking,
    required this.averagePrice,
    required this.skillLevels,
  });
}

class OperatingHours {
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  OperatingHours({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });
}

class VenueBooking {
  final String id;
  final String venueId;
  final DateTime dateTime;
  final Duration duration;

  VenueBooking({
    required this.id,
    required this.venueId,
    required this.dateTime,
    required this.duration,
  });
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  static TimeOfDay fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}

// Abstract dependencies
abstract class VenuesRepository {
  Future<List<Venue>> searchVenues({
    required String sport,
    List<String>? requiredAmenities,
    int? minRating,
  });
  Future<Venue?> getVenueById(String venueId);
  Future<List<VenueBooking>> getVenueBookings(String venueId, DateTime start, DateTime end);
}

abstract class LocationService {
  Future<Location?> getCurrentLocation();
}

abstract class PricingEngine {
  Future<VenuePricing> calculatePrice({
    required Venue venue,
    required DateTime dateTime,
    required Duration duration,
    required String sport,
  });
}

abstract class CacheService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? duration});
}
