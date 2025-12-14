# Sports Color Token Mapping

This document maps sports-related screens to use the sports color category tokens.

## Token Files
- `design-system/tokens/sports-light-theme.json` - Sports light theme
- `design-system/tokens/sports-dark-theme.json` - Sports dark theme

## Sports Category Colors

### Light Theme (sportsLight)
- Primary: `#348638` (Green)
- Primary Container: `#B6F2B5`
- Secondary: `#6CBD6A`
- Tertiary: `#0050B6` (Blue)

### Dark Theme (sportsDark)
- Primary: `#79FFC3` (Bright green)
- Primary Container: `#005231`
- Secondary: `#00E6CB`
- Tertiary: `#00D6FF` (Cyan)

## Screen Mapping to Sports Category

### Game Screens (category: 'sports')
1. **Game Detail Screen** (`lib/features/games/presentation/screens/join_game/game_detail_screen.dart`)
   - Uses: TwoSectionLayout or SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 Cards, Buttons, Chips
   - Icons: Iconsax only (replace Material Icons)
   - Color: `colorScheme.categorySports`

2. **Game Type Selection Screen** (`lib/features/games/presentation/screens/create_game/game_type_selection_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 Cards, SearchBar
   - Icons: Iconsax sport icons
   - Color: `colorScheme.categorySports`

3. **Game Configuration Screen** (`lib/features/games/presentation/screens/create_game/game_configuration_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 Input fields, Switches, Sliders
   - Icons: Iconsax
   - Color: `colorScheme.categorySports`

4. **Venue Selection Screen** (`lib/features/games/presentation/screens/create_game/venue_selection_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 Cards with venue info
   - Icons: Iconsax location icons
   - Color: `colorScheme.categorySports`

5. **Date/Time Selection Screen** (`lib/features/games/presentation/screens/create_game/datetime_selection_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 Date/Time pickers
   - Icons: Iconsax calendar icons
   - Color: `colorScheme.categorySports`

6. **Booking Confirmation Screen** (`lib/features/games/presentation/screens/create_game/booking_confirmation_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 Cards with summary
   - Icons: Iconsax check icons
   - Color: `colorScheme.categorySports`

7. **Game Creation Success Screen** (`lib/features/games/presentation/screens/create_game/game_creation_success_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Success message with Material 3
   - Icons: Iconsax success icons
   - Color: `colorScheme.categorySports`

8. **Sports History Screen** (`lib/features/explore/presentation/screens/sports_history_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 Cards, Filter chips
   - Icons: Iconsax sport icons (replace Material Icons)
   - Color: `colorScheme.categorySports`

9. **Profile Sports Screen** (`lib/features/profile/presentation/screens/settings/profile_sports_screen.dart`)
   - Uses: SingleSectionLayout with `category: 'sports'`
   - Components: Material 3 sport preference cards
   - Icons: Iconsax sport icons
   - Color: `colorScheme.categorySports`

10. **Onboarding Sports Screen** (`lib/features/profile/presentation/screens/onboarding/onboarding_sports_screen.dart`)
    - Uses: TwoSectionLayout with `category: 'sports'`
    - Components: Material 3 selection chips/cards
    - Icons: Iconsax sport icons
    - Color: `colorScheme.categorySports`

11. **Sports Selection Screen** (`lib/features/misc/presentation/screens/sports_selection_screen.dart`)
    - Uses: SingleSectionLayout with `category: 'sports'`
    - Components: Material 3 grid cards
    - Icons: Iconsax sport icons
    - Color: `colorScheme.categorySports`

## Implementation Requirements

### 1. Use Design System Layouts
```dart
// For screens with clear top/bottom sections
TwoSectionLayout(
  category: 'sports',
  topSection: Widget,
  bottomSection: Widget,
)

// For single scrolling screens
SingleSectionLayout(
  category: 'sports',
  scrollable: true,
  child: Widget,
)
```

### 2. Use Material 3 Components Only
- ✅ Card (with Material 3 styling)
- ✅ FilledButton / OutlinedButton / TextButton
- ✅ SearchBar
- ✅ Chip / FilterChip / InputChip
- ✅ TextField with Material 3 styling
- ✅ Switch / Checkbox / Radio
- ✅ DatePicker / TimePicker
- ✅ BottomSheet
- ✅ Dialog

### 3. Use Iconsax Icons Only
```dart
import 'package:iconsax_flutter/iconsax_flutter.dart';

// Sport icons mapping
Basketball → Iconsax.game_copy
Football/Soccer → Iconsax.medal_star_copy
Tennis → Iconsax.game_copy
Volleyball → Iconsax.game_copy
Location → Iconsax.location_copy
Calendar → Iconsax.calendar_copy
Time → Iconsax.clock_copy
Success → Iconsax.tick_circle_copy
```

### 4. Access Sports Colors
```dart
import 'package:dabbler/themes/material3_extensions.dart';

final colorScheme = Theme.of(context).colorScheme;

// Sports category color
colorScheme.categorySports  // Main sports color
colorScheme.categorySports.withValues(alpha: 0.12)  // Container background
colorScheme.categorySports.withValues(alpha: 0.0)   // Transparent
```

## Next Steps

1. ✅ Token files created
2. ⏳ Update each screen to use SingleSectionLayout/TwoSectionLayout with `category: 'sports'`
3. ⏳ Replace all Material Icons with Iconsax equivalents
4. ⏳ Ensure all components use Material 3 styling
5. ⏳ Use `colorScheme.categorySports` for all sports-related accent colors
6. ⏳ Test in both light and dark modes

## Notes

- Sports tokens use green as primary color (representing sports/outdoors)
- All game-related features should consistently use sports category
- Maintains design system consistency with other categories (profile, social, activity)
- Sports colors are optimized for both accessibility and visual appeal
