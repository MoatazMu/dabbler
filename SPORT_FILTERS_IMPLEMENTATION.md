# Sport-Specific Filters Implementation

## Overview
This document tracks the implementation of sport-specific filters for Football, Cricket, and Padel in the Dabbler app.

## ✅ Completed (Phase 1 & 2 - UI Layer)

### 1. Configuration File
**File:** `lib/core/config/sport_filters_config.dart`

Centralized configuration containing all sport-specific filter options:

#### Football Filters
- **Game Types:** All, Futsal, 5-a-side, 7-a-side, 11-a-side, Competitive, Casual
- **Surface Types:** All, Grass, Artificial Turf, Indoor, Outdoor

#### Cricket Filters
- **Match Formats:** All, T20, ODI, Test Match, Box Cricket
- **Ball Types:** All, Tennis Ball, Leather Ball, Season Ball, Soft Ball
- **Over Formats:** All, 6 overs, 10 overs, 20 overs, 30 overs, 50 overs
- **Pitch Types:** All, Turf, Matting, Concrete, Astro Turf

#### Padel Filters
- **Game Types:** All, Singles, Doubles, Mixed Doubles
- **Court Types:** All, Indoor, Outdoor, Covered
- **Surface Types:** All, Artificial Grass, Concrete, Synthetic

**Helper Methods:**
- `getGameTypesForSport(String sport)` - Returns game type options for a specific sport
- `hasSportSpecificFilters(String sport)` - Checks if sport has specific filters
- `getFilterDisplayName(String key)` - Returns human-readable filter names

### 2. UI Components
**File:** `lib/features/explore/presentation/widgets/sport_specific_filters.dart`

Reusable widget components following Material 3 design:

- **Base Class:** `SportSpecificFilters` - Abstract class with shared UI methods
  - `buildSectionTitle()` - Creates filter section headers
  - `buildChipGroup()` - Creates FilterChip groups for filter options

- **Sport Implementations:**
  - `FootballFilters` - Game type and surface type filters
  - `CricketFilters` - Match format, ball type, over format, and pitch type filters
  - `PadelFilters` - Game type, court type, and surface type filters

- **Factory:** `SportSpecificFiltersFactory` - Creates appropriate widget based on sport

### 3. Sports Screen Integration
**File:** `lib/features/explore/presentation/screens/sports_screen.dart`

**Changes Made:**
- ✅ Added imports for `sport_specific_filters.dart` and `sport_filters_config.dart`
- ✅ Added state variable: `Map<String, dynamic> _sportSpecificFilters = {}`
- ✅ Removed deprecated `_secondarySports` list and `_selectedSecondarySports` state
- ✅ Updated filter modal to conditionally show sport-specific filters
- ✅ Added filter change handler that updates state
- ✅ Updated clear filters to include sport-specific filters
- ✅ Updated `_buildVenuesTab` to pass `sportSpecificFilters` instead of `secondarySports`
- ✅ Updated `_VenuesTabContent` widget to accept `sportSpecificFilters` parameter

**Filter Modal Logic:**
```dart
// Only shows sport-specific filters if the sport supports them
if (SportFiltersConfig.hasSportSpecificFilters(_sports[_selectedSportIndex]['name']))
  SportSpecificFiltersFactory.create(
    sport: _sports[_selectedSportIndex]['name'],
    selectedFilters: _sportSpecificFilters,
    onFilterChanged: (key, value) {
      // Updates state when filter changes
      // Removes filter if value is null or 'All'
    },
  )
```

### 4. Database Schema
**Status:** ✅ Applied by user

Migration adds `sport_specific_data` JSONB column to `games` table for storing flexible sport-specific metadata.

## 🔄 In Progress

### Phase 3: State Management (Next Step)
- [ ] Create `sports_filter_provider.dart` using Riverpod
- [ ] Define `SportsFilterState` class to manage all filter state
- [ ] Implement StateNotifier methods for filter updates
- [ ] Migrate filter state from `sports_screen.dart` to provider

## ⏳ Pending

### Phase 4: Data Model Updates
- [ ] Update `Game` model to include `sportSpecificData` field
- [ ] Add `Map<String, dynamic>? sportSpecificData;` property
- [ ] Update `fromJson` and `toJson` methods
- [ ] Ensure backward compatibility

### Phase 5: Backend Query Logic
- [ ] Update games repository to filter by sport-specific data
- [ ] Implement JSONB contains queries in Supabase
- [ ] Add sport-specific filter parameters to `fetchFilteredGames()`
- [ ] Test query performance with JSONB filters

### Phase 6: Create Game Screen
- [ ] Add sport-specific fields to create game form
- [ ] Implement dynamic field rendering based on selected sport
- [ ] Integrate with form state management
- [ ] Save sport-specific data when creating games

## Testing Checklist

### UI Testing
- [ ] Test filter modal with Football selected
- [ ] Test filter modal with Cricket selected
- [ ] Test filter modal with Padel selected
- [ ] Verify "Clear All" clears sport-specific filters
- [ ] Test filter persistence when switching between tabs
- [ ] Verify filters update when changing sports

### Integration Testing
- [ ] Test venue filtering with sport-specific filters applied
- [ ] Verify games are filtered correctly based on sport-specific data
- [ ] Test creating games with sport-specific metadata
- [ ] Verify sport-specific data is saved and retrieved correctly

## Architecture Decisions

### 1. Configuration Separation
**Decision:** Centralized filter configuration in `sport_filters_config.dart`
**Rationale:** 
- Single source of truth for all filter options
- Easy to add new sports or modify existing filters
- Reduces code duplication

### 2. Factory Pattern
**Decision:** Use factory pattern for creating sport-specific filter widgets
**Rationale:**
- Extensible design for adding new sports
- Encapsulates widget creation logic
- Returns null for unsupported sports, allowing graceful handling

### 3. JSONB Storage
**Decision:** Store sport-specific data in JSONB column
**Rationale:**
- Flexible schema for varying sport requirements
- Efficient querying using PostgreSQL JSONB operators
- No need for separate tables per sport

### 4. Map<String, dynamic> State
**Decision:** Use Map for sport-specific filter state
**Rationale:**
- Flexible structure accommodates different filter types
- Easy to serialize/deserialize
- Simple to check for empty filters

## Code Quality

### ✅ All Files Pass Linting
- No compile errors
- No unused imports
- No unused variables
- Follows Flutter best practices

### Material 3 Compliance
- Uses `FilterChip` for consistent Material Design
- Proper use of theme colors and typography
- Responsive layout with proper spacing

## Next Steps

1. **Create State Provider** (Estimated: 1-2 hours)
   - Set up Riverpod StateNotifier
   - Define filter state class
   - Implement state management methods

2. **Update Game Model** (Estimated: 30 minutes)
   - Add sportSpecificData field
   - Update serialization methods

3. **Implement Backend Filtering** (Estimated: 2-3 hours)
   - Update repository query methods
   - Test JSONB filtering in Supabase
   - Handle edge cases

4. **Update Create Game Flow** (Estimated: 2-3 hours)
   - Add dynamic form fields
   - Integrate with game creation logic
   - Test end-to-end flow

## Total Progress: ~40% Complete

✅ Phase 1: Configuration & Data Model - 80% (DB migration applied, model update pending)
✅ Phase 2: UI Components - 100% (All widgets created and integrated)
⏳ Phase 3: State Management - 0%
⏳ Phase 4: Backend Query Logic - 0%
⏳ Phase 5: Create Game Screen - 0%
