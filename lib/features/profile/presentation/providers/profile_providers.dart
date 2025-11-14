import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dabbler/core/services/auth_service.dart';
import 'package:dabbler/core/utils/logger.dart';
import 'package:dabbler/data/models/sport_profiles/sport_profile.dart'
    as advanced_profile;
import 'package:dabbler/data/models/sport_profiles/sport_profile_badge.dart'
    as advanced_badge;
import 'package:dabbler/data/models/sport_profiles/sport_profile_tier.dart'
    as advanced_tier;
import 'package:dabbler/services/sport_profile_service.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../data/datasources/supabase_profile_datasource.dart';
import '../../data/datasources/profile_data_sources.dart'
    show ProfileLocalDataSource, ProfileLocalDataSourceImpl;
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';

// Domain layer imports
import 'package:dabbler/data/models/profile/user_profile.dart';
import 'package:dabbler/data/models/profile/user_settings.dart';
import 'package:dabbler/data/models/profile/user_preferences.dart';
import 'package:dabbler/data/models/profile/privacy_settings.dart';
import 'package:dabbler/data/models/profile/sports_profile.dart';

// Controller imports
import '../controllers/profile_controller.dart';
import '../controllers/profile_edit_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/preferences_controller.dart';
import '../controllers/privacy_controller.dart';
import '../controllers/sports_profile_controller.dart';

// =============================================================================
// CONTROLLER PROVIDERS (Simplified)
// =============================================================================

// Infrastructure: Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sportProfileServiceProvider = Provider<SportProfileService>((ref) {
  final client = ref.watch(supabaseProvider);
  return SportProfileService(supabase: client);
});

// Data sources
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return SupabaseProfileDataSource(client);
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSourceImpl();
});

// Repository
final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    localDataSource: ref.watch(profileLocalDataSourceProvider),
  );
});

// Use cases
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return GetProfileUseCase(repo);
});

/// Main profile controller provider
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(
        getProfileUseCase: ref.watch(getProfileUseCaseProvider),
      );
    });

/// Sports profile controller provider
final sportsProfileControllerProvider =
    StateNotifierProvider<SportsProfileController, SportsProfileState>((ref) {
      return SportsProfileController();
    });

class SportProfileHeaderData {
  const SportProfileHeaderData({
    required this.profile,
    this.tier,
    this.badges = const <advanced_badge.SportProfileBadge>[],
  });

  final advanced_profile.SportProfile profile;
  final advanced_tier.SportProfileTier? tier;
  final List<advanced_badge.SportProfileBadge> badges;
}

final sportProfileHeaderProvider = FutureProvider.autoDispose
    .family<SportProfileHeaderData?, String>((ref, userId) async {
  if (userId.isEmpty) {
    return null;
  }

  final service = ref.watch(sportProfileServiceProvider);

  try {
    final profiles = await service.getSportProfilesForUser(userId);
    if (profiles.isEmpty) {
      return null;
    }

    final selectedProfile = _selectPrimarySportProfile(profiles);

    final badges = await service.getPlayerBadges(
      selectedProfile.profileId,
      selectedProfile.sportKey,
    );
    final tier = await service.getTierById(selectedProfile.tierId);

    return SportProfileHeaderData(
      profile: selectedProfile,
      tier: tier,
      badges: badges,
    );
  } on SportProfileServiceException catch (error) {
    Logger.warning(
      'Failed to load sport profile header for userId=$userId',
      error,
    );
    return null;
  } catch (error) {
    Logger.error(
      'Unexpected error loading sport profile header for userId=$userId',
      error,
    );
    return null;
  }
});

/// Profile edit controller provider
final profileEditControllerProvider =
    StateNotifierProvider<ProfileEditController, ProfileEditState>((ref) {
      return ProfileEditController();
    });

/// Settings controller provider
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      return SettingsController();
    });

/// Preferences controller provider
final preferencesControllerProvider =
    StateNotifierProvider<PreferencesController, PreferencesState>((ref) {
      return PreferencesController();
    });

/// Privacy controller provider
final privacyControllerProvider =
    StateNotifierProvider<PrivacyController, PrivacyState>((ref) {
      return PrivacyController();
    });

// =============================================================================
// COMPUTED STATE PROVIDERS
// =============================================================================

/// Current user profile provider
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final profileState = ref.watch(profileControllerProvider);
  return profileState.profile;
});

/// Current user settings provider
final currentUserSettingsProvider = Provider<UserSettings?>((ref) {
  final settingsState = ref.watch(settingsControllerProvider);
  return settingsState.settings;
});

/// Current user preferences provider
final currentUserPreferencesProvider = Provider<UserPreferences?>((ref) {
  final preferencesState = ref.watch(preferencesControllerProvider);
  return preferencesState.preferences;
});

/// Current privacy settings provider
final currentPrivacySettingsProvider = Provider<PrivacySettings?>((ref) {
  final privacyState = ref.watch(privacyControllerProvider);
  return privacyState.settings;
});

/// All sports profiles provider
final allSportsProfilesProvider = Provider<List<SportProfile>>((ref) {
  final sportsState = ref.watch(sportsProfileControllerProvider);
  return sportsState.profiles;
});

/// Active sports profiles provider
final activeSportsProfilesProvider = Provider<List<SportProfile>>((ref) {
  final allProfiles = ref.watch(allSportsProfilesProvider);
  return allProfiles.where((profile) => profile.gamesPlayed > 0).toList();
});

/// Primary sport profile provider
final primarySportProfileProvider = Provider<SportProfile?>((ref) {
  final allProfiles = ref.watch(allSportsProfilesProvider);
  try {
    return allProfiles.firstWhere((profile) => profile.isPrimarySport);
  } catch (e) {
    return null;
  }
});

/// Profile completion percentage provider
final profileCompletionProvider = Provider<double>((ref) {
  final profile = ref.watch(currentUserProfileProvider);
  final settings = ref.watch(currentUserSettingsProvider);
  final preferences = ref.watch(currentUserPreferencesProvider);
  final sportsProfiles = ref.watch(allSportsProfilesProvider);

  if (profile == null) return 0.0;

  double completion = 0.0;

  // Basic profile info (40%)
  if (profile.username?.isNotEmpty == true) completion += 8.0;
  if (profile.displayName.isNotEmpty == true) completion += 8.0;
  if (profile.email?.isNotEmpty ?? false) completion += 8.0;
  if (profile.phoneNumber?.isNotEmpty == true) completion += 8.0;
  if (profile.city?.isNotEmpty == true) completion += 8.0;

  // Settings (20%)
  if (settings != null) completion += 20.0;

  // Preferences (20%)
  if (preferences != null) {
    completion += 10.0;
    if (preferences.preferredGameTypes.isNotEmpty) completion += 10.0;
  }

  // Sports profiles (20%)
  if (sportsProfiles.isNotEmpty) {
    completion += 10.0;
    if (sportsProfiles.any((p) => p.isPrimarySport)) completion += 10.0;
  }

  return completion.clamp(0.0, 100.0);
});

/// Profile loading state provider
final isProfileLoadingProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileControllerProvider);
  final settingsState = ref.watch(settingsControllerProvider);
  final preferencesState = ref.watch(preferencesControllerProvider);
  final privacyState = ref.watch(privacyControllerProvider);
  final sportsState = ref.watch(sportsProfileControllerProvider);

  return profileState.isLoading ||
      settingsState.isLoading ||
      preferencesState.isLoading ||
      privacyState.isLoading ||
      sportsState.isLoading;
});

/// Profile has unsaved changes provider
final hasUnsavedChangesProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileControllerProvider);
  final settingsState = ref.watch(settingsControllerProvider);
  final preferencesState = ref.watch(preferencesControllerProvider);
  final privacyState = ref.watch(privacyControllerProvider);
  final sportsState = ref.watch(sportsProfileControllerProvider);

  return profileState.hasUnsavedChanges ||
      settingsState.hasUnsavedChanges ||
      preferencesState.hasUnsavedChanges ||
      privacyState.hasUnsavedChanges ||
      sportsState.hasUnsavedChanges;
});

// =============================================================================
// FAMILY PROVIDERS
// =============================================================================

/// Get sports profile by ID
final sportsProfileByIdProvider = Provider.family<SportProfile?, String>((
  ref,
  sportId,
) {
  final sportsController = ref.watch(sportsProfileControllerProvider.notifier);
  return sportsController.getProfileBySport(sportId);
});

// =============================================================================
// UTILITY PROVIDERS
// =============================================================================

/// Initialize all profile data provider
final initializeProfileDataProvider = FutureProvider<bool>((ref) async {
  final profileController = ref.read(profileControllerProvider.notifier);
  final settingsController = ref.read(settingsControllerProvider.notifier);
  final preferencesController = ref.read(
    preferencesControllerProvider.notifier,
  );
  final privacyController = ref.read(privacyControllerProvider.notifier);
  final sportsController = ref.read(sportsProfileControllerProvider.notifier);

  const userId = 'current-user-id'; // Would come from auth

  try {
    await Future.wait([
      profileController.loadProfile(userId),
      settingsController.loadSettings(userId),
      preferencesController.loadPreferences(userId),
      privacyController.loadPrivacySettings(userId),
      sportsController.loadSportsProfiles(userId),
    ]);
    return true;
  } catch (e) {
    return false;
  }
});

/// Save all profile changes provider
final saveAllProfileChangesProvider = FutureProvider<bool>((ref) async {
  final hasChanges = ref.read(hasUnsavedChangesProvider);
  if (!hasChanges) return true;

  final settingsController = ref.read(settingsControllerProvider.notifier);
  final preferencesController = ref.read(
    preferencesControllerProvider.notifier,
  );
  final privacyController = ref.read(privacyControllerProvider.notifier);

  final results = await Future.wait([
    settingsController.saveAllChanges(),
    preferencesController.saveAllChanges(),
    privacyController.saveAllChanges(),
  ]);

  return results.every((success) => success);
});

// =============================================================================
// CURRENT USER AND UTILITY PROVIDERS
// =============================================================================

// Current user provider that returns UserProfile for profile features
final currentUserProvider = Provider<UserProfile?>((ref) {
  // Use AuthService singleton to read the authenticated user and convert to minimal UserProfile
  final authUser = AuthService().getCurrentUser();
  if (authUser == null) return null;
  final now = DateTime.now();
  final metadata = authUser.userMetadata;
  final displayName =
      (metadata?['display_name'] as String?) ??
      (metadata?['full_name'] as String?) ??
      (authUser.email ?? '');
  final avatarUrl = metadata?['avatar_url'] as String?;

  // Safely convert timestamps that may be DateTime or String or other
  DateTime asDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? now;
    return now;
  }

  return UserProfile(
    id: authUser.id,
    userId: authUser.id,
    email: authUser.email ?? '',
    displayName: displayName,
    avatarUrl: avatarUrl,
    createdAt: asDateTime(authUser.createdAt),
    updatedAt: asDateTime(authUser.updatedAt),
  );
});

// Profile loading provider
final profileLoadingProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileControllerProvider);
  final sportsState = ref.watch(sportsProfileControllerProvider);
  return profileState.isLoading || sportsState.isLoading;
});

// Profile error provider
final profileErrorProvider = Provider<String?>((ref) {
  final profileState = ref.watch(profileControllerProvider);
  final sportsState = ref.watch(sportsProfileControllerProvider);
  return profileState.errorMessage ?? sportsState.errorMessage;
});

advanced_profile.SportProfile _selectPrimarySportProfile(
  List<advanced_profile.SportProfile> profiles,
) {
  if (profiles.length == 1) {
    return profiles.first;
  }

  final flagged = profiles.where(_isPrimaryProfile).toList();
  if (flagged.isNotEmpty) {
    return flagged.first;
  }

  return profiles.reduce((current, next) {
    if (next.overallLevel > current.overallLevel) {
      return next;
    }
    if (next.overallLevel == current.overallLevel &&
        next.xpTotal > current.xpTotal) {
      return next;
    }
    return current;
  });
}

bool _isPrimaryProfile(advanced_profile.SportProfile profile) {
  final attributes = profile.attributes;
  final dynamic candidate = attributes['is_primary'] ??
      attributes['isPrimary'] ??
      attributes['primary'];

  if (candidate is bool) {
    return candidate;
  }
  if (candidate is num) {
    return candidate != 0;
  }
  if (candidate is String) {
    final normalized = candidate.toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'primary';
  }
  return false;
}
