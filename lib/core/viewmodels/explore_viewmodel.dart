import 'package:flutter/material.dart';
import '../models/explore_filters.dart';
import '../models/match_model.dart';
import '../services/location_service.dart';

class ExploreViewModel extends ChangeNotifier {
  static final ExploreViewModel _instance = ExploreViewModel._internal();
  factory ExploreViewModel() => _instance;
  ExploreViewModel._internal();

  final LocationService _locationService = LocationService();

  List<Match> _matches = [];
  ExploreFilters? _currentFilters;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastApiCall;

  // Getters
  List<Match> get matches => List.unmodifiable(_matches);
  ExploreFilters? get currentFilters => _currentFilters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMatches => _matches.isNotEmpty;

  // Debouncing - prevent API calls within 1 second
  bool get canMakeApiCall {
    if (_lastApiCall == null) return true;
    return DateTime.now().difference(_lastApiCall!).inSeconds >= 1;
  }

  // Create filters from user data and location
  ExploreFilters createFiltersFromUserData({String? preferredSport}) {
    final userLocation = _locationService.currentArea;
    final position = _locationService.currentPosition;
    
    return ExploreFilters.quickFind(
      userLocation: userLocation,
      latitude: position?.latitude,
      longitude: position?.longitude,
      preferredSport: preferredSport,
    );
  }

  // Apply filters and fetch matches
  Future<bool> applyFiltersAndFetch(ExploreFilters filters) async {
    if (!canMakeApiCall) {
      // Show debounce message
      _error = 'Please wait before searching again';
      notifyListeners();
      return false;
    }

    _currentFilters = filters;
    _error = null;
    _isLoading = true;
    _lastApiCall = DateTime.now();
    notifyListeners();

    try {
      // Check if location is required but not available
      if (!filters.hasLocationData && _locationService.permissionDenied) {
        _error = 'location_permission_required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // TODO: Replace with real Supabase API implementation
      // For now, return empty list - use GamesHomeScreen for real data
      await Future.delayed(const Duration(seconds: 1));
      
      // No demo data - integrate with GamesRepository from features/games
      _matches = [];
      
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = 'Failed to fetch matches: $e';
      _matches = [];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Quick find - used by CTA button
  Future<bool> quickFind({String? sport}) async {
    final filters = createFiltersFromUserData(preferredSport: sport);
    return await applyFiltersAndFetch(filters);
  }

  // Refresh matches with current filters
  Future<void> refresh() async {
    if (_currentFilters != null) {
      await applyFiltersAndFetch(_currentFilters!);
    }
  }

  // Clear current results
  void clearResults() {
    _matches = [];
    _currentFilters = null;
    _error = null;
    notifyListeners();
  }

  // Update filters without fetching
  void updateFilters(ExploreFilters filters) {
    _currentFilters = filters;
    notifyListeners();
  }

  // Handle location permission result
  void handleLocationPermissionResult(bool granted) {
    if (granted) {
      _locationService.fetchLocation().then((_) {
        // Retry last search if filters exist
        if (_currentFilters != null) {
          final updatedFilters = _currentFilters!.copyWith(
            location: _locationService.currentArea,
            latitude: _locationService.currentPosition?.latitude,
            longitude: _locationService.currentPosition?.longitude,
          );
          applyFiltersAndFetch(updatedFilters);
        }
      });
    }
  }

  // Get readable error message
  String getErrorMessage() {
    switch (_error) {
      case 'location_permission_required':
        return 'Location access is required to find nearby games. Please enable location or set your area manually.';
      case null:
        return '';
      default:
        return _error ?? 'An unexpected error occurred';
    }
  }

  // Check if current error requires location permission
  bool get requiresLocationPermission => _error == 'location_permission_required';
} 