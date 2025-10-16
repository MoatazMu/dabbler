import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core imports

// Domain layer imports (commented out until entities are created)
// import '../../domain/entities/user_profile.dart';
// import '../../domain/entities/user_settings.dart';
// import '../../domain/entities/user_preferences.dart';
// import '../../domain/entities/privacy_settings.dart';
// import '../../domain/entities/sports_profile.dart';
// import '../../domain/entities/profile_statistics.dart';
// import '../../domain/usecases/update_profile_usecase.dart';
// import '../../domain/usecases/change_settings_usecase.dart';
// import '../../domain/usecases/update_preferences_usecase.dart';
// import '../../domain/usecases/manage_privacy_usecase.dart';
// import '../../domain/usecases/upload_avatar_usecase.dart';
// import '../../domain/usecases/manage_sports_profile_usecase.dart';
// import '../../domain/usecases/calculate_profile_completion_usecase.dart';

// Data layer imports (commented out until data sources are created)
// import '../../data/repositories/profile_repository_impl.dart';
// import '../../data/repositories/settings_repository_impl.dart';
// import '../../data/repositories/preferences_repository_impl.dart';
// import '../../data/datasources/supabase_profile_datasource.dart';
// import '../../data/datasources/profile_remote_datasource.dart';
// import '../../data/datasources/settings_datasource.dart';
// import '../../data/datasources/preferences_datasource.dart';
// import '../../data/datasources/profile_analytics_datasource.dart';

// Controller imports (commented out until controllers are created)
// import '../controllers/profile_controller.dart';
// import '../controllers/profile_edit_controller.dart';
// import '../controllers/settings_controller.dart';
// import '../controllers/preferences_controller.dart';
// import '../controllers/privacy_controller.dart';
// import '../controllers/sports_profile_controller.dart';

// =============================================================================
// INFRASTRUCTURE PROVIDERS
// =============================================================================

/// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// =============================================================================
// DATA SOURCE PROVIDERS (COMMENTED OUT UNTIL CLASSES ARE CREATED)
// =============================================================================

/*
/// Profile data source provider
final profileDataSourceProvider = Provider<SupabaseProfileDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  // Fixed: Use positional parameter instead of named parameter
  return SupabaseProfileDataSource(supabaseClient);
});

/// Settings data source provider
final settingsDataSourceProvider = Provider<SupabaseSettingsDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  // Fixed: Use positional parameter instead of named parameter
  return SupabaseSettingsDataSource(supabaseClient);
});

/// Preferences data source provider
final preferencesDataSourceProvider = Provider<SupabasePreferencesDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  // Fixed: Use positional parameter instead of named parameter
  return SupabasePreferencesDataSource(supabaseClient);
});

/// Analytics data source provider
final analyticsDataSourceProvider = Provider<SupabaseAnalyticsDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  // Fixed: Use positional parameter instead of named parameter
  return SupabaseAnalyticsDataSource(supabaseClient);
});
*/

// =============================================================================
// REPOSITORY PROVIDERS (COMMENTED OUT UNTIL REPOSITORIES ARE CREATED)
// =============================================================================

/*
/// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  final remoteDataSource = ref.watch(profileDataSourceProvider);
  return ProfileRepositoryImpl(
    remoteDataSource: remoteDataSource,
  );
});

/// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepositoryImpl>((ref) {
  final remoteDataSource = ref.watch(settingsDataSourceProvider);
  return SettingsRepositoryImpl(
    remoteDataSource: remoteDataSource,
  );
});

/// Preferences repository provider
final preferencesRepositoryProvider = Provider<PreferencesRepositoryImpl>((ref) {
  final remoteDataSource = ref.watch(preferencesDataSourceProvider);
  return PreferencesRepositoryImpl(
    remoteDataSource: remoteDataSource,
  );
});
*/

// =============================================================================
// USE CASE PROVIDERS (COMMENTED OUT UNTIL USE CASES ARE CREATED)
// =============================================================================

/*
/// Update profile use case provider
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

/// Change settings use case provider
final changeSettingsUseCaseProvider = Provider<ChangeSettingsUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return ChangeSettingsUseCase(repository);
});

/// Update preferences use case provider
final updatePreferencesUseCaseProvider = Provider<UpdatePreferencesUseCase>((ref) {
  final repository = ref.watch(preferencesRepositoryProvider);
  return UpdatePreferencesUseCase(repository);
});

/// Manage privacy use case provider
final managePrivacyUseCaseProvider = Provider<ManagePrivacyUseCase>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return ManagePrivacyUseCase(repository);
});

/// Upload avatar use case provider
final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UploadAvatarUseCase(repository);
});

/// Manage sports profile use case provider
final manageSportsProfileUseCaseProvider = Provider<ManageSportsProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ManageSportsProfileUseCase(repository);
});

/// Calculate profile completion use case provider
final calculateProfileCompletionUseCaseProvider = Provider<CalculateProfileCompletionUseCase>((ref) {
  return CalculateProfileCompletionUseCase();
});
*/

// =============================================================================
// CONTROLLER PROVIDERS (COMMENTED OUT UNTIL CONTROLLERS ARE CREATED)
// =============================================================================

/*
/// Main profile controller provider
final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
  final uploadAvatarUseCase = ref.watch(uploadAvatarUseCaseProvider);
  return ProfileController(
    updateProfileUseCase: updateProfileUseCase,
    uploadAvatarUseCase: uploadAvatarUseCase,
  );
});

/// Profile edit controller provider
final profileEditControllerProvider = StateNotifierProvider<ProfileEditController, ProfileEditState>((ref) {
  final updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
  final uploadAvatarUseCase = ref.watch(uploadAvatarUseCaseProvider);
  return ProfileEditController(
    updateProfileUseCase: updateProfileUseCase,
    uploadAvatarUseCase: uploadAvatarUseCase,
  );
});

/// Settings controller provider
final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final changeSettingsUseCase = ref.watch(changeSettingsUseCaseProvider);
  return SettingsController(
    changeSettingsUseCase: changeSettingsUseCase,
  );
});

/// Preferences controller provider
final preferencesControllerProvider = StateNotifierProvider<PreferencesController, PreferencesState>((ref) {
  final updatePreferencesUseCase = ref.watch(updatePreferencesUseCaseProvider);
  return PreferencesController(
    updatePreferencesUseCase: updatePreferencesUseCase,
  );
});

/// Privacy controller provider
final privacyControllerProvider = StateNotifierProvider<PrivacyController, PrivacyState>((ref) {
  final managePrivacyUseCase = ref.watch(managePrivacyUseCaseProvider);
  return PrivacyController(
    managePrivacyUseCase: managePrivacyUseCase,
  );
});

/// Sports profile controller provider
final sportsProfileControllerProvider = StateNotifierProvider<SportsProfileController, SportsProfileState>((ref) {
  final manageSportsProfileUseCase = ref.watch(manageSportsProfileUseCaseProvider);
  return SportsProfileController(
    manageSportsProfileUseCase: manageSportsProfileUseCase,
  );
});
*/

// =============================================================================
// COMPUTED STATE PROVIDERS (COMMENTED OUT UNTIL ENTITIES ARE AVAILABLE)
// =============================================================================

/*
/// Current user profile provider
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final profileState = ref.watch(profileControllerProvider);
  return profileState.userProfile;
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
  if (profile.firstName.isNotEmpty) completion += 8.0;
  if (profile.lastName.isNotEmpty) completion += 8.0;
  if (profile.email.isNotEmpty) completion += 8.0;
  if (profile.phoneNumber?.isNotEmpty == true) completion += 8.0;
  if (profile.location?.isNotEmpty == true) completion += 8.0;

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
*/

// =============================================================================
// FAMILY PROVIDERS (COMMENTED OUT UNTIL ENTITIES ARE AVAILABLE)
// =============================================================================

/*
/// Get sports profile by ID
final sportsProfileByIdProvider = Provider.family<SportProfile?, String>((ref, sportId) {
  final sportsController = ref.watch(sportsProfileControllerProvider.notifier);
  return sportsController.getProfileBySport(sportId);
});

/// User profile provider by ID (for viewing other users)
final userProfileByIdProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getUserProfile(userId);
  return result.fold(
    (failure) => null,
    (profile) => profile,
  );
});
*/

// =============================================================================
// UTILITY PROVIDERS (COMMENTED OUT UNTIL CONTROLLERS ARE AVAILABLE)
// =============================================================================

/*
/// Initialize all profile data provider
final initializeProfileDataProvider = FutureProvider<bool>((ref) async {
  final profileController = ref.read(profileControllerProvider.notifier);
  final settingsController = ref.read(settingsControllerProvider.notifier);
  final preferencesController = ref.read(preferencesControllerProvider.notifier);
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

  final profileController = ref.read(profileControllerProvider.notifier);
  final settingsController = ref.read(settingsControllerProvider.notifier);
  final preferencesController = ref.read(preferencesControllerProvider.notifier);
  final privacyController = ref.read(privacyControllerProvider.notifier);

  final results = await Future.wait([
    profileController.saveProfile(),
    settingsController.saveAllChanges(),
    preferencesController.saveAllChanges(),
    privacyController.saveAllChanges(),
  ]);

  return results.every((success) => success);
});
*/

// =============================================================================
// PLACEHOLDER PROVIDER FOR DEVELOPMENT
// =============================================================================

/// Simple placeholder provider that works for now
final profilePlaceholderProvider = Provider<String>((ref) {
  return 'Profile system ready for implementation';
});

/*
/// Profile data source provider
final profileDataSourceProvider = Provider<SupabaseProfileDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseProvider);
  return SupabaseProfileDataSource(supabaseClient);
});

/// Profile repository provider
final profileRepositoryProvider = Provider<domain.ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileDataSourceProvider);
  // Assuming you have a local data source, otherwise you can simplify this
  // final localDataSource = ref.watch(profileLocalDataSourceProvider);
  return ProfileRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: ref.watch(profileLocalDataSourceProvider), // Placeholder for local data source
  );
});

/// Get profile use case provider
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return GetProfileUseCase(repository);
});

// You will also need a local data source provider
final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  // This is a placeholder. You should implement a real local data source.
  return ProfileLocalDataSourceImpl();
});
*/