import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService {
  static final MockUserService _instance = MockUserService._internal();
  factory MockUserService() => _instance;
  MockUserService._internal();

  // Mock user profile data
  Map<String, dynamic>? _userProfile;
  final String _userProfileKey = 'mock_user_profile';

  // Initialize user profile
  Future<void> _initializeProfile() async {
    if (_userProfile == null) {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      if (profileJson != null) {
        _userProfile = json.decode(profileJson);
      } else {
        _userProfile = {
          'id': 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          'name': null,
          'email': null,
          'phone': null,
          'age': null,
          'gender': null,
          'sports': [],
          'intent': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        await _saveProfile();
      }
    }
  }

  // Save profile to local storage
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, json.encode(_userProfile));
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    await _initializeProfile();
    return _userProfile;
  }

  // Update user basic info
  Future<void> updateUserBasicInfo({
    String? name,
    int? age,
    String? gender,
  }) async {
    await _initializeProfile();
    
    if (name != null) _userProfile!['name'] = name;
    if (age != null) _userProfile!['age'] = age;
    if (gender != null) _userProfile!['gender'] = gender;
    _userProfile!['updated_at'] = DateTime.now().toIso8601String();
    
    await _saveProfile();
  }

  // Update user sports
  Future<void> updateUserSports(List<String> sports) async {
    await _initializeProfile();
    
    _userProfile!['sports'] = sports;
    _userProfile!['updated_at'] = DateTime.now().toIso8601String();
    
    await _saveProfile();
  }

  // Update user intent
  Future<void> updateUserIntent(String intent) async {
    await _initializeProfile();
    
    _userProfile!['intent'] = intent;
    _userProfile!['updated_at'] = DateTime.now().toIso8601String();
    
    await _saveProfile();
  }

  // Complete registration
  Future<void> completeRegistration(Map<String, dynamic> registrationData) async {
    await _initializeProfile();
    
    // Update profile with registration data
    if (registrationData['display_name'] != null) {
      _userProfile!['display_name'] = registrationData['display_name'];
    }
    if (registrationData['age'] != null) {
      _userProfile!['age'] = registrationData['age'];
    }
    if (registrationData['gender'] != null) {
      _userProfile!['gender'] = registrationData['gender'];
    }
    if (registrationData['sports'] != null) {
      _userProfile!['sports'] = registrationData['sports'];
    }
    if (registrationData['intent'] != null) {
      _userProfile!['intent'] = registrationData['intent'];
    }
    if (registrationData['email'] != null) {
      _userProfile!['email'] = registrationData['email'];
    }
    
    _userProfile!['updated_at'] = DateTime.now().toIso8601String();
    
    await _saveProfile();
  }

  // Clear user data
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProfileKey);
    _userProfile = null;
  }
} 