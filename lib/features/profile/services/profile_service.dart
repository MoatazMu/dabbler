import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/profile_statistics.dart';
import 'image_upload_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/error/exceptions.dart' as app_exceptions;
import '../../../core/utils/logger.dart' as app_logger;
import '../data/repositories/profile_repository.dart';
import '../data/repositories/profile_stats_repository.dart';
import '../data/providers/profile_providers.dart';

/// High-level profile service that coordinates between repositories
/// and handles complex profile operations
class ProfileService {
  final ProfileRepository _profileRepository;
  final ProfileStatsRepository _statsRepository;
  final ImageUploadService _imageUploadService;
  final AnalyticsService _analyticsService;
  final CacheService _cacheService;

  ProfileService({
    required ProfileRepository profileRepository,
    required ProfileStatsRepository statsRepository,
    required ImageUploadService imageUploadService,
    required AnalyticsService analyticsService,
    required CacheService cacheService,
  })  : _profileRepository = profileRepository,
        _statsRepository = statsRepository,
        _imageUploadService = imageUploadService,
        _analyticsService = analyticsService,
        _cacheService = cacheService;

  /// Get user profile with caching and analytics tracking
  Future<UserProfile?> getUserProfile(String userId, {bool forceRefresh = false}) async {
    try {
      final cacheKey = 'profile_$userId';
      
      // Check cache first unless forced refresh
      if (!forceRefresh) {
        final cachedProfile = await _cacheService.get<UserProfile>(cacheKey);
        if (cachedProfile != null) {
          app_logger.Logger.info('Profile loaded from cache for user $userId');
          return cachedProfile;
        }
      }

      // Fetch from repository
      final profile = await _profileRepository.getUserProfile(userId);
      if (profile != null) {
        // Cache the profile
        await _cacheService.set(cacheKey, profile, duration: const Duration(minutes: 30));
        
        // Track profile view analytics
        await _trackProfileView(profile);
        
        app_logger.Logger.info('Profile loaded for user $userId');
      }

      return profile;
    } catch (e) {
      app_logger.Logger.error('Error loading profile for user $userId', e);
      await _analyticsService.trackError('profile_load_error', {'user_id': userId, 'error': e.toString()});
      rethrow;
    }
  }

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile({bool forceRefresh = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw app_exceptions.AuthException('User not authenticated');
    }
    return getUserProfile(user.id, forceRefresh: forceRefresh);
  }

  /// Update user profile with comprehensive validation and analytics
  Future<UserProfile> updateProfile(UserProfile profile, {Map<String, dynamic>? changes}) async {
    try {
      // Validate profile data
      await _validateProfileUpdate(profile);

      // Track what changed for analytics
      if (changes != null && changes.isNotEmpty) {
        await _analyticsService.trackEvent('profile_updated', {
          'user_id': profile.id,
          'fields_changed': changes.keys.toList(),
          'completion_before': _calculateCompletionPercentage(profile),
        });
      }

      // Update in repository
      final updatedProfile = await _profileRepository.updateProfile(profile.id, profile.toJson());

      // Clear cache
      await _invalidateProfileCache(profile.id);

      // Calculate new completion percentage
      final completionPercentage = _calculateCompletionPercentage(updatedProfile);
      final oldPercentage = _calculateCompletionPercentage(profile);
      if (completionPercentage != oldPercentage) {
        await _trackCompletionChange(profile.id, oldPercentage, completionPercentage);
      }

      app_logger.Logger.info('Profile updated for user ${profile.id}');
      return updatedProfile;
    } catch (e) {
      app_logger.Logger.error('Error updating profile for user ${profile.id}', e);
      await _analyticsService.trackError('profile_update_error', {
        'user_id': profile.id,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Update profile avatar with image processing
  Future<UserProfile> updateProfileAvatar(String userId, String imagePath) async {
    try {
      // Upload and process image
      final uploadResult = await _imageUploadService.uploadProfileImage(
        userId: userId,
        imagePath: imagePath,
      );

      // Get current profile
      final currentProfile = await getUserProfile(userId, forceRefresh: true);
      if (currentProfile == null) {
        throw app_exceptions.ProfileException('Profile not found');
      }

      // Update profile with new avatar URL
      final updatedProfile = currentProfile.copyWith(
        avatarUrl: uploadResult.url,
        updatedAt: DateTime.now(),
      );

      // Save updated profile
      final result = await updateProfile(updatedProfile, changes: {'avatarUrl': uploadResult.url});

      // Track avatar update
      await _analyticsService.trackEvent('avatar_updated', {
        'user_id': userId,
        'image_size': uploadResult.metadata['size'],
        'image_format': uploadResult.metadata['format'],
      });

      app_logger.Logger.info('Avatar updated for user $userId');
      return result;
    } catch (e) {
      app_logger.Logger.error('Error updating avatar for user $userId', e);
      await _analyticsService.trackError('avatar_update_error', {
        'user_id': userId,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Get profile with stats
  Future<ProfileWithStats> getProfileWithStats(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) {
        throw app_exceptions.ProfileException('Profile not found');
      }

      final stats = await _statsRepository.getProfileStats(userId);
      
      return ProfileWithStats(
        profile: profile,
        stats: stats,
      );
    } catch (e) {
      app_logger.Logger.error('Error loading profile with stats for user $userId', e);
      rethrow;
    }
  }

  /// Search profiles with caching
  Future<List<UserProfile>> searchProfiles(String query, {
    int limit = 20,
    int offset = 0,
    List<String>? sports,
    String? location,
  }) async {
    try {
      final cacheKey = 'search_${query}_${sports?.join(',')}_${location}_${limit}_$offset';
      
      // Check cache first
      final cachedResults = await _cacheService.get<List<UserProfile>>(cacheKey);
      if (cachedResults != null) {
        return cachedResults;
      }

      // Search in repository
      final results = await _profileRepository.searchProfiles(
        query: query,
        limit: limit,
        offset: offset,
        sportsFilter: sports,
        locationFilter: location,
      );

      // Cache results for shorter duration (search results change frequently)
      await _cacheService.set(cacheKey, results, duration: const Duration(minutes: 5));

      // Track search analytics
      await _analyticsService.trackEvent('profile_search', {
        'query': query,
        'results_count': results.length,
        'filters': {
          'sports': sports,
          'location': location,
        },
      });

      return results;
    } catch (e) {
      app_logger.Logger.error('Error searching profiles', e);
      await _analyticsService.trackError('profile_search_error', {'query': query, 'error': e.toString()});
      rethrow;
    }
  }

  /// Get profile completion steps
  List<ProfileCompletionStep> getCompletionSteps(UserProfile profile) {
    final steps = <ProfileCompletionStep>[];

    steps.add(ProfileCompletionStep(
      id: 'basic_info',
      title: 'Basic Information',
      description: 'Add your name and basic details',
      isCompleted: profile.displayName.isNotEmpty,
      weight: 10.0,
    ));

    steps.add(ProfileCompletionStep(
      id: 'avatar',
      title: 'Profile Photo',
      description: 'Upload a profile picture',
      isCompleted: profile.avatarUrl?.isNotEmpty ?? false,
      weight: 15.0,
    ));

    steps.add(ProfileCompletionStep(
      id: 'bio',
      title: 'Bio',
      description: 'Tell others about yourself',
      isCompleted: profile.bio?.isNotEmpty ?? false,
      weight: 10.0,
    ));

    steps.add(ProfileCompletionStep(
      id: 'location',
      title: 'Location',
      description: 'Add your location to find nearby players',
      isCompleted: profile.location?.isNotEmpty ?? false,
      weight: 10.0,
    ));

    steps.add(ProfileCompletionStep(
      id: 'sports',
      title: 'Sports & Interests',
      description: 'Select your favorite sports',
      isCompleted: profile.sportsProfiles.isNotEmpty,
      weight: 20.0,
    ));

    steps.add(ProfileCompletionStep(
      id: 'skill_levels',
      title: 'Skill Levels',
      description: 'Set your skill level for each sport',
      isCompleted: profile.sportsProfiles.isNotEmpty,
      weight: 15.0,
    ));

    steps.add(ProfileCompletionStep(
      id: 'availability',
      title: 'Availability',
      description: 'Set your weekly availability',
      isCompleted: profile.preferences.weeklyAvailability.isNotEmpty,
      weight: 10.0,
    ));

    steps.add(ProfileCompletionStep(
      id: 'preferences',
      title: 'Game Preferences',
      description: 'Set your game preferences',
      isCompleted: profile.preferences.preferredGameTypes.isNotEmpty,
      weight: 10.0,
    ));

    return steps;
  }

  /// Calculate profile completion percentage
  double _calculateCompletionPercentage(UserProfile profile) {
    final steps = getCompletionSteps(profile);
    final totalWeight = steps.fold(0.0, (sum, step) => sum + step.weight);
    final completedWeight = steps
        .where((step) => step.isCompleted)
        .fold(0.0, (sum, step) => sum + step.weight);

    return totalWeight > 0 ? (completedWeight / totalWeight) * 100 : 0.0;
  }

  /// Validate profile update
  Future<void> _validateProfileUpdate(UserProfile profile) async {
    final errors = <String>[];

    // Basic validations
    if (profile.displayName.isEmpty) {
      errors.add('Display name is required');
    }

    if (profile.displayName.length > 50) {
      errors.add('Display name must be less than 50 characters');
    }

    if (profile.bio != null && profile.bio!.length > 500) {
      errors.add('Bio must be less than 500 characters');
    }

    // Email validation if provided
    if (profile.email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(profile.email)) {
      errors.add('Invalid email format');
    }

    // Phone validation if provided
    if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) {
      if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(profile.phoneNumber!)) {
        errors.add('Invalid phone number format');
      }
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
  }

  /// Track profile view analytics
  Future<void> _trackProfileView(UserProfile profile) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnProfile = currentUser?.id == profile.id;

    await _analyticsService.trackEvent('profile_viewed', {
      'profile_user_id': profile.id,
      'viewer_user_id': currentUser?.id,
      'is_own_profile': isOwnProfile,
      'profile_completion': profile.profileCompletionPercentage,
      'has_avatar': profile.avatarUrl?.isNotEmpty ?? false,
    });
  }

  /// Track completion percentage change
  Future<void> _trackCompletionChange(String userId, double oldPercentage, double newPercentage) async {
    await _analyticsService.trackEvent('profile_completion_changed', {
      'user_id': userId,
      'old_percentage': oldPercentage,
      'new_percentage': newPercentage,
      'improvement': newPercentage - oldPercentage,
    });

    // Track milestone achievements
    final milestones = [25.0, 50.0, 75.0, 100.0];
    for (final milestone in milestones) {
      if (oldPercentage < milestone && newPercentage >= milestone) {
        await _analyticsService.trackEvent('profile_milestone_reached', {
          'user_id': userId,
          'milestone': milestone,
        });
      }
    }
  }

  /// Invalidate profile cache
  Future<void> _invalidateProfileCache(String userId) async {
    await _cacheService.delete('profile_$userId');
    
    // Also clear related caches
    final keys = await _cacheService.getKeys();
    for (final key in keys) {
      if (key.startsWith('search_') || key.contains(userId)) {
        await _cacheService.delete(key);
      }
    }
  }

  /// Refresh user stats
  Future<void> refreshUserStats(String userId) async {
    try {
      await _statsRepository.getProfileStats(userId);
      await _invalidateProfileCache(userId);
      
      Logger.info('Stats refreshed for user $userId');
    } catch (e) {
      Logger.error('Error refreshing stats for user $userId', e);
      rethrow;
    }
  }

  /// Delete user profile and related data
  Future<void> deleteProfile(String userId) async {
    try {
      // This will be called by AccountDeletionService
      await _profileRepository.deleteProfile(userId);
      await _invalidateProfileCache(userId);
      
      app_logger.Logger.info('Profile deleted for user $userId');
    } catch (e) {
      app_logger.Logger.error('Error deleting profile for user $userId', e);
      rethrow;
    }
  }
}

/// Profile with stats data class
class ProfileWithStats {
  final UserProfile profile;
  final ProfileStatistics stats;

  ProfileWithStats({
    required this.profile,
    required this.stats,
  });
}

/// Profile completion step
class ProfileCompletionStep {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final double weight;

  ProfileCompletionStep({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.weight,
  });
}

/// Profile service provider - simplified for now
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(
    profileRepository: ref.watch(profileRepositoryProvider),
    statsRepository: ref.watch(profileStatsRepositoryProvider),
    imageUploadService: ImageUploadService(), // TODO: Add provider
    analyticsService: AnalyticsService(), // TODO: Add provider  
    cacheService: CacheService(), // TODO: Add provider
  );
});
