# Game Creation Feature Flags - Backend Implementation Plan

## Current Status (Frontend Only)

Currently, the game creation feature flags work **only on the frontend/UI level**:
- `enablePlayerGameCreation` (set to `true`)
- `enableOrganiserGameCreation` (set to `true`)

These flags control:
- UI visibility (buttons, screens)
- Route access (navigation redirects)
- Widget rendering (conditional display)

**Important**: These are NOT enforced on the backend/database level.

## Security Gap

Users could potentially bypass UI restrictions by:
- Making direct API calls
- Manipulating client-side code
- Using modified app versions

## Implementation TODO

### 1. Backend Validation Required

Add profile type checks in the game creation flow:

**Location**: `lib/features/games/domain/usecases/create_game_usecase.dart`

```dart
Future<Failure?> _validateGameParameters(CreateGameParams params) async {
  // Get user's profile type from database
  final userProfile = await profileRepository.getProfile(params.organizerId);
  
  // Validate based on profile type
  if (userProfile.profileType == 'player') {
    if (!FeatureFlags.enablePlayerGameCreation) {
      return GameFailure('Players cannot create games at this time');
    }
    // Additional player restrictions:
    // - Can only create pickup games
    // - Limited to certain sports
    // - Cannot set advanced settings
  }
  
  if (userProfile.profileType == 'organiser') {
    if (!FeatureFlags.enableOrganiserGameCreation) {
      return GameFailure('Organisers cannot create games at this time');
    }
    // Organiser has full access to:
    // - All game types
    // - Advanced scheduling
    // - Payment settings
  }
  
  // ... rest of validation
}
```

### 2. Database Schema Updates

**Add to `profiles` table**:
```sql
ALTER TABLE profiles ADD COLUMN profile_type VARCHAR(20) DEFAULT 'player';
ALTER TABLE profiles ADD CONSTRAINT check_profile_type 
  CHECK (profile_type IN ('player', 'organiser'));
```

**Add to `games` table** (optional - for tracking):
```sql
ALTER TABLE games ADD COLUMN created_by_profile_type VARCHAR(20);
```

### 3. API Endpoint Security

**Supabase RLS Policies**:

```sql
-- Players can only create games if player creation is enabled
CREATE POLICY "player_game_creation" ON games
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.profile_type = 'player'
      -- Add feature flag check here via database function
    )
  );

-- Organisers can create games if organiser creation is enabled
CREATE POLICY "organiser_game_creation" ON games
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.profile_type = 'organiser'
    )
  );
```

### 4. Feature Flag Database Function

Store feature flags in database for backend validation:

```sql
CREATE TABLE feature_flags (
  flag_name VARCHAR(50) PRIMARY KEY,
  enabled BOOLEAN DEFAULT false,
  updated_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO feature_flags (flag_name, enabled) VALUES
  ('player_game_creation', true),
  ('organiser_game_creation', true);

CREATE FUNCTION check_feature_flag(flag_name TEXT)
RETURNS BOOLEAN AS $$
  SELECT enabled FROM feature_flags WHERE feature_flags.flag_name = $1;
$$ LANGUAGE SQL STABLE;
```

### 5. Middleware Layer (Optional)

Create a middleware service to sync flags between client and server:

**Location**: `lib/core/services/feature_flag_service.dart`

```dart
class FeatureFlagService {
  final SupabaseClient _supabase;
  
  // Sync flags from server on app start
  Future<Map<String, bool>> fetchServerFlags() async {
    final response = await _supabase
      .from('feature_flags')
      .select();
    // Return server flags
  }
  
  // Check if user can create game based on profile type
  Future<bool> canCreateGame(String userId) async {
    final profile = await _getProfile(userId);
    
    if (profile.profileType == 'player') {
      return await _checkFlag('player_game_creation');
    }
    
    if (profile.profileType == 'organiser') {
      return await _checkFlag('organiser_game_creation');
    }
    
    return false;
  }
}
```

### 6. Update Game Creation Repository

**Location**: `lib/data/repositories/games_repository_impl.dart`

```dart
@override
Future<Either<Failure, Game>> createGame(Map<String, dynamic> gameData) async {
  try {
    // Get creator's profile type
    final creatorId = gameData['organizerId'];
    final profile = await _getProfile(creatorId);
    
    // Backend validation
    if (profile.profileType == 'player' && !await _checkFlag('player_game_creation')) {
      return Left(GameFailure('Player game creation is currently disabled'));
    }
    
    if (profile.profileType == 'organiser' && !await _checkFlag('organiser_game_creation')) {
      return Left(GameFailure('Organiser game creation is currently disabled'));
    }
    
    // Add profile type to game data
    gameData['created_by_profile_type'] = profile.profileType;
    
    // Proceed with creation
    final result = await _dataSource.createGame(gameData);
    return Right(result);
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

### 7. Testing Checklist

- [ ] Test player creating game when `enablePlayerGameCreation = false`
- [ ] Test organiser creating game when `enableOrganiserGameCreation = false`
- [ ] Test direct API calls bypass (should fail with backend validation)
- [ ] Test profile type enforcement
- [ ] Test feature flag sync from server
- [ ] Test migration of existing games
- [ ] Test analytics tracking for denied attempts

### 8. Migration Plan

1. **Phase 1**: Add database columns and RLS policies (non-breaking)
2. **Phase 2**: Deploy backend validation (shadow mode - log but don't block)
3. **Phase 3**: Monitor logs for issues
4. **Phase 4**: Enable enforcement (block invalid attempts)
5. **Phase 5**: Update existing games with profile type

### 9. Related Files to Update

- `lib/features/games/domain/usecases/create_game_usecase.dart`
- `lib/data/repositories/games_repository_impl.dart`
- `lib/features/games/data/datasources/supabase_games_datasource.dart`
- `lib/core/services/feature_flag_service.dart` (new)
- `supabase/migrations/` (new migration files)

### 10. Analytics Events to Track

```dart
// When game creation is attempted
analyticsService.trackEvent('game_creation_attempt', {
  'profile_type': profileType,
  'feature_enabled': flagEnabled,
  'allowed': canCreate,
  'sport': sport,
});

// When blocked by backend
analyticsService.trackEvent('game_creation_blocked', {
  'profile_type': profileType,
  'reason': 'feature_disabled',
});
```

## Benefits of Backend Implementation

1. **Security**: Prevents unauthorized game creation
2. **Consistency**: Server is source of truth for permissions
3. **Flexibility**: Can toggle features without app update
4. **Analytics**: Track attempted bypasses
5. **Compliance**: Meet data protection requirements

## Priority: Medium-High

Should be implemented before public launch to ensure proper access control and prevent abuse.
