# Auth-Database Integration Guide

## Overview

The auth-database integration connects Supabase authentication with the app's profile data through a unified service and provider system.

## Key Components

### 1. **AuthProfileService** (`lib/core/services/auth_profile_service.dart`)
Bridges authentication with profile data. Provides methods for:
- Getting current user with their profile
- Accessing profile data
- Updating profiles
- Watching profile changes in real-time

### 2. **Auth Profile Providers** (`lib/features/authentication/presentation/providers/auth_profile_providers.dart`)
Riverpod providers that expose auth + profile data throughout the app.

## How It Works

### Signup Flow
```
User fills form → signUpWithEmailAndMetadata() → 
AuthService creates auth.users entry → 
Database trigger OR manual insert creates profiles row → 
Profile ready for use
```

### Login Flow
```
User signs in → Auth state updated → 
Providers automatically fetch profile → 
UI displays user data
```

## Usage Examples

### 1. Get Current User with Profile

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dabbler/features/authentication/presentation/providers/auth_profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userWithProfileAsync = ref.watch(authenticatedUserWithProfileProvider);

    return userWithProfileAsync.when(
      data: (userWithProfile) {
        if (userWithProfile == null) {
          return Text('Not authenticated or no profile');
        }

        return Column(
          children: [
            Text('Email: ${userWithProfile.email}'),
            Text('Name: ${userWithProfile.displayName}'),
            Text('Bio: ${userWithProfile.bio ?? "No bio"}'),
            if (userWithProfile.avatarUrl != null)
              Image.network(userWithProfile.avatarUrl!),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 2. Get Just the Display Name

```dart
class WelcomeWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayNameAsync = ref.watch(currentDisplayNameProvider);

    return displayNameAsync.when(
      data: (name) => Text('Welcome, $name!'),
      loading: () => Text('Loading...'),
      error: (_, __) => Text('Welcome!'),
    );
  }
}
```

### 3. Watch Profile Changes in Real-Time

```dart
class LiveProfileWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileStreamAsync = ref.watch(watchMyProfileProvider);

    return profileStreamAsync.when(
      data: (result) {
        return result.fold(
          (failure) => Text('Error: $failure'),
          (profile) => profile != null
              ? Text('Profile: ${profile.displayName}')
              : Text('No profile'),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Stream error: $error'),
    );
  }
}
```

### 4. View Another User's Profile

```dart
class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByUserIdProvider(userId));

    return profileAsync.when(
      data: (result) {
        return result.fold(
          (failure) => Text('Failed to load profile: $failure'),
          (profile) => Column(
            children: [
              Text('Name: ${profile.displayName}'),
              Text('Bio: ${profile.bio ?? "No bio"}'),
            ],
          ),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 5. Update Profile

```dart
class EditProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _bioController = TextEditingController();

  Future<void> _updateProfile() async {
    final service = ref.read(authProfileServiceProvider);
    
    final result = await service.updateProfile(
      bio: _bioController.text,
      // Add other fields as needed
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $failure')),
        );
      },
      (updatedData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated!')),
        );
        // Refresh providers
        ref.invalidate(myProfileProvider);
        ref.invalidate(authenticatedUserWithProfileProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Column(
        children: [
          TextField(
            controller: _bioController,
            decoration: InputDecoration(labelText: 'Bio'),
          ),
          ElevatedButton(
            onPressed: _updateProfile,
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

### 6. Check Profile Completeness

```dart
class OnboardingCheck extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleteAsync = ref.watch(isProfileCompleteProvider);

    return isCompleteAsync.when(
      data: (isComplete) {
        if (!isComplete) {
          return AlertDialog(
            title: Text('Complete Your Profile'),
            content: Text('Please fill in all required information'),
            actions: [
              TextButton(
                onPressed: () => context.go('/profile/edit'),
                child: Text('Complete Now'),
              ),
            ],
          );
        }
        return SizedBox.shrink();
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  }
}
```

## Available Providers

### Profile Data
- `myProfileProvider` - Current user's profile (Result<Profile>)
- `authenticatedUserWithProfileProvider` - User + Profile combined
- `watchMyProfileProvider` - Real-time profile stream
- `currentDisplayNameProvider` - Just the display name
- `currentUserIdProvider` - Just the user ID
- `currentUserEmailProvider` - Just the user email

### Profile Status
- `isProfileCompleteProvider` - Check if profile has all required fields
- `hasProfileProvider` - Check if profile exists

### Other Users
- `profileByUserIdProvider(userId)` - Get profile by user ID
- `publicProfileByUsernameProvider(username)` - Get profile by username

## Service Methods

### AuthProfileService Methods

```dart
// Auth state
bool get isAuthenticated
User? get currentUser
String? get currentUserId
String? get currentUserEmail
Session? get currentSession

// Profile access
Future<Result<Profile>> getMyProfile()
Future<Result<Profile>> getProfileByUserId(String userId)
Future<Result<Profile?>> getPublicProfileByUsername(String username)
Stream<Result<Profile?>> watchMyProfile()

// Combined operations
Future<AuthenticatedUserWithProfile?> getAuthenticatedUserWithProfile()

// Profile updates
Future<Result<Map<String, dynamic>>> updateProfile({
  String? displayName,
  String? username,
  String? bio,
  // ... other fields
})

// Auth operations
Future<Result<void>> signOut()
Future<Result<AuthResponse>> signInWithEmail({...})
Future<Result<AuthResponse>> signUpWithEmailAndMetadata({...})

// Utilities
Future<bool> hasProfile()
Future<bool> isProfileComplete()
```

## Testing Scenarios

### Test 1: Signup → Profile Created
```dart
// 1. User signs up with metadata
await authService.signUpWithEmailAndMetadata(
  email: 'test@example.com',
  password: 'password123',
  metadata: {
    'name': 'John Doe',
    'age': 25,
    'gender': 'male',
    'sports': ['football'],
    'intent': 'casual',
  },
);

// 2. Verify profile exists
final hasProfile = await authProfileService.hasProfile();
expect(hasProfile, true);

// 3. Verify profile data
final profile = await authProfileService.getMyProfile();
profile.fold(
  (failure) => fail('Profile should exist'),
  (profile) {
    expect(profile.displayName, 'John Doe');
  },
);
```

### Test 2: Login → Profile Loaded
```dart
// 1. Sign in
await authService.signInWithEmail(
  email: 'test@example.com',
  password: 'password123',
);

// 2. Get profile
final userWithProfile = await authProfileService.getAuthenticatedUserWithProfile();
expect(userWithProfile, isNotNull);
expect(userWithProfile!.email, 'test@example.com');
```

### Test 3: Update Profile
```dart
// 1. Update profile
final result = await authProfileService.updateProfile(
  displayName: 'Jane Doe',
  bio: 'Updated bio',
);

// 2. Verify update
result.fold(
  (failure) => fail('Update should succeed'),
  (data) => expect(data['display_name'], 'Jane Doe'),
);
```

### Test 4: Logout
```dart
// 1. Sign out
await authProfileService.signOut();

// 2. Verify not authenticated
expect(authProfileService.isAuthenticated, false);

// 3. Verify profile access fails
final result = await authProfileService.getMyProfile();
result.fold(
  (failure) => expect(failure, isA<AuthFailure>()),
  (_) => fail('Should not get profile when not authenticated'),
);
```

## Database Schema Expectations

The integration assumes:

1. **profiles table** exists with columns:
   - id, user_id, profile_type, display_name (required)
   - username, bio, avatar_url, city, country, language (optional)
   - is_active, verified, created_at, updated_at (optional)

2. **Row Level Security (RLS)** policies allow:
   - Users to read their own profile
   - Users to update their own profile
   - Public read access for active profiles

3. **Database trigger or manual insert** creates profile row on signup

## Notes

- All profile operations return `Result<T>` which uses fpdart's `Either<Failure, T>`
- Always use `.fold()` to handle both success and failure cases
- Providers automatically handle loading states
- Profile changes are reactive when using `watchMyProfileProvider`
- Auth state changes automatically invalidate profile providers

## Troubleshooting

### Profile not found after signup
- Check if database trigger is working
- Verify AuthService._ensureUserProfileExists is being called
- Check RLS policies allow insert

### Profile not updating
- Verify RLS policies allow updates
- Check if display_name validation passes (2-50 chars, not empty)
- Ensure updateUserProfile RPC exists or fallback works

### Real-time updates not working
- Verify Supabase realtime is enabled for profiles table
- Check if watchMyProfile stream is being listened to
- Ensure profile changes are actually being saved to database
