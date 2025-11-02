import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/profile_cache_service.dart';
import 'package:dabbler/data/models/profile/user_profile.dart';
// Import for future exception handling when implementing actual Supabase functionality

/// Profile repository interface
class ProfileRepository {
  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    throw UnimplementedError(
      'ProfileRepository.getUserProfile not implemented',
    );
  }

  /// Network-first, cache-fallback profile fetch
  Future<UserProfile?> getUserProfileSmart(String userId) async {
    // Connectivity check
    final connectivity = Connectivity();
    final status = await connectivity.checkConnectivity();
    final online = status != ConnectivityResult.none;
    if (online) {
      try {
        // Fetch from Supabase profiles table
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (response != null) {
          await ProfileCacheService().updateProfilePartial(userId, response);
          return UserProfile.fromJson(response);
        }
      } catch (e) {
        // On error, fallback to cache
        final cached = await ProfileCacheService().getProfileById(
          userId,
          preferCache: true,
          revalidate: false,
        );
        if (cached != null) {
          return UserProfile.fromJson(cached);
        }
      }
    } else {
      // Offline: use cache
      final cached = await ProfileCacheService().getProfileById(
        userId,
        preferCache: true,
        revalidate: false,
      );
      if (cached != null) {
        return UserProfile.fromJson(cached);
      }
    }
    return null;
  }

  /// Update user profile
  Future<UserProfile> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    throw UnimplementedError('ProfileRepository.updateProfile not implemented');
  }

  /// Create new profile
  Future<UserProfile> createProfile(UserProfile profile) async {
    throw UnimplementedError('ProfileRepository.createProfile not implemented');
  }

  /// Delete user profile
  Future<void> deleteProfile(String userId) async {
    throw UnimplementedError('ProfileRepository.deleteProfile not implemented');
  }

  /// Upload profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    throw UnimplementedError(
      'ProfileRepository.uploadProfileImage not implemented',
    );
  }

  /// Search profiles
  Future<List<UserProfile>> searchProfiles({
    required String query,
    List<String>? sportsFilter,
    String? locationFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    throw UnimplementedError(
      'ProfileRepository.searchProfiles not implemented',
    );
  }

  /// Get profiles by IDs
  Future<List<UserProfile>> getProfilesByIds(List<String> userIds) async {
    throw UnimplementedError(
      'ProfileRepository.getProfilesByIds not implemented',
    );
  }

  /// Update profile completion percentage
  Future<void> updateCompletionPercentage(
    String userId,
    double percentage,
  ) async {
    throw UnimplementedError(
      'ProfileRepository.updateCompletionPercentage not implemented',
    );
  }

  /// Get all user data for export
  Future<Map<String, dynamic>> getAllUserData(String userId) async {
    throw UnimplementedError(
      'ProfileRepository.getAllUserData not implemented',
    );
  }

  /// Delete all user data
  Future<void> deleteAllUserData(String userId) async {
    throw UnimplementedError(
      'ProfileRepository.deleteAllUserData not implemented',
    );
  }
}
