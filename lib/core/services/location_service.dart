import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _cachedAreaKey = 'cached_area';
  static const String _cachedLatKey = 'cached_latitude';
  static const String _cachedLngKey = 'cached_longitude';

  String? _currentArea;
  Position? _currentPosition;
  bool _permissionDenied = false;
  bool _isLoading = false;

  String? get currentArea => _currentArea;
  Position? get currentPosition => _currentPosition;
  bool get permissionDenied => _permissionDenied;
  bool get isLoading => _isLoading;
  bool get hasLocation => _currentPosition != null;

  Future<void> init() async {
    await _loadCachedLocation();
    await fetchLocation();
  }

  Future<void> fetchLocation() async {
    _isLoading = true;
    notifyListeners();
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _permissionDenied = true;
        _isLoading = false;
        notifyListeners();
        return;
      }
      _permissionDenied = false;
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _reverseGeocode(_currentPosition!);
      await _cacheLocation(_currentPosition!, _currentArea);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reverseGeocode(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentArea = placemark.subLocality?.isNotEmpty == true
            ? placemark.subLocality
            : placemark.locality?.isNotEmpty == true
                ? placemark.locality
                : placemark.administrativeArea?.isNotEmpty == true
                    ? placemark.administrativeArea
                    : placemark.country;
      } else {
        _currentArea = null;
      }
    } catch (e) {
      _currentArea = null;
    }
  }

  Future<void> _cacheLocation(Position position, String? area) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cachedLatKey, position.latitude);
    await prefs.setDouble(_cachedLngKey, position.longitude);
    if (area != null) {
      await prefs.setString(_cachedAreaKey, area);
    }
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_cachedLatKey);
    final lng = prefs.getDouble(_cachedLngKey);
    final area = prefs.getString(_cachedAreaKey);
    if (lat != null && lng != null) {
      _currentPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    _currentArea = area;
  }

  Future<void> overrideLocation(String area) async {
    _currentArea = area;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedAreaKey, area);
    notifyListeners();
  }

  Future<void> setManualLocation(String area) async {
    _currentArea = area;
    _permissionDenied = false; // Reset permission denied if user sets location manually
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedAreaKey, area);
    notifyListeners();
  }

  Future<void> clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedAreaKey);
    await prefs.remove(_cachedLatKey);
    await prefs.remove(_cachedLngKey);
    _currentArea = null;
    _currentPosition = null;
    notifyListeners();
  }
} 