# Color Token Mapping

This document describes how the design token values from the JSON files are mapped to the Flutter app theme.

## Token Files → Theme Mapping

### Main Theme (Purple)
The app's default theme uses the Main category colors:

**Files**: `main-light-theme.json`, `main-dark-theme.json`

**Usage**:
- Applied to `AppTheme.lightTheme` and `AppTheme.darkTheme`
- Used throughout the app as the default color scheme
- Primary color: Purple (#7328CE light / #C18FFF dark)

**Access**:
```dart
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.primaryContainer
```

### Category Colors
Each category has dedicated primary colors from their respective token files:

#### Sports Category (Green)
**Files**: `sports-light-theme.json`, `sports-dark-theme.json`
**Primary**: #348638 (light) / #79FFC3 (dark)

**Access**:
```dart
Theme.of(context).colorScheme.categorySports
```

**Used in**:
- Sports History Screen
- Game Detail Screen
- Game Configuration Screens
- All sports-related features

#### Social Category (Blue)
**Files**: `social-light-theme.json`, `social-dark-theme.json`
**Primary**: #3473D7 (light) / #A6DCFF (dark)

**Access**:
```dart
Theme.of(context).colorScheme.categorySocial
```

**Used in**:
- Community/Social features
- Messaging
- Friend lists

#### Activities Category (Pink)
**Files**: `activity-light-theme.json`, `activity-dark-theme.json`
**Primary**: #CF3989 (light) / #FCDEE8 (dark)

**Access**:
```dart
Theme.of(context).colorScheme.categoryActivities
```

**Used in**:
- Activity tracking features
- Event scheduling

#### Profile Category (Orange)
**Files**: `profile-light-theme.json`, `profile-dark-theme.json`
**Primary**: #F6AA4F (light) / #FFF4CC (dark)

**Access**:
```dart
Theme.of(context).colorScheme.categoryProfile
```

**Used in**:
- User profile screens
- Account settings
- Personal statistics

#### Main Category (Purple)
**Primary**: #7328CE (light) / #C18FFF (dark)

**Access**:
```dart
Theme.of(context).colorScheme.categoryMain
```

**Used in**:
- Navigation
- Onboarding
- General UI elements

## Implementation Details

### Main ColorScheme
Located in: `lib/themes/app_theme.dart`

The app uses explicit ColorScheme definitions rather than seed color generation:
- `_mainLightColorScheme`: Maps all 40+ Material 3 color tokens for light mode
- `_mainDarkColorScheme`: Maps all 40+ Material 3 color tokens for dark mode

### Category Colors Extension
Located in: `lib/themes/material3_extensions.dart`

Extension methods on `ColorScheme` provide access to category-specific colors:
```dart
extension AppColorSchemeExtension on ColorScheme {
  Color get categoryMain => ...
  Color get categorySocial => ...
  Color get categorySports => ...
  Color get categoryActivities => ...
  Color get categoryProfile => ...
}
```

### Dynamic Category Colors
Use `getCategoryColor(String category)` to dynamically get a category color:
```dart
final color = Theme.of(context).colorScheme.getCategoryColor('sports');
```

## Material 3 Color Roles

Each token file defines the complete Material 3 color system:

### Primary Colors
- `primary`: Main brand color
- `onPrimary`: Text/icons on primary
- `primaryContainer`: Prominent container background
- `onPrimaryContainer`: Text/icons on primary container

### Secondary Colors
- `secondary`: Secondary brand color
- `onSecondary`: Text/icons on secondary
- `secondaryContainer`: Less prominent container
- `onSecondaryContainer`: Text/icons on secondary container

### Tertiary Colors
- `tertiary`: Accent color
- `onTertiary`: Text/icons on tertiary
- `tertiaryContainer`: Accent container
- `onTertiaryContainer`: Text/icons on tertiary container

### Surface Colors
- `surface`: Default surface background
- `onSurface`: Text/icons on surface
- `surfaceVariant`: Variant surface for differentiation
- `onSurfaceVariant`: Text/icons on surface variant
- `surfaceContainer`: Container backgrounds (5 levels of elevation)
- `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`

### Outline Colors
- `outline`: Borders and dividers
- `outlineVariant`: Subtle borders

### Other Colors
- `error`: Error states
- `onError`: Text/icons on error
- `errorContainer`: Error container background
- `onErrorContainer`: Text/icons on error container
- `shadow`: Shadow color
- `scrim`: Overlay scrim
- `inverseSurface`, `onInverseSurface`, `inversePrimary`: Inverse colors for high contrast

## Usage Examples

### Using Main Theme Colors
```dart
Container(
  color: Theme.of(context).colorScheme.primaryContainer,
  child: Text(
    'Hello',
    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
  ),
)
```

### Using Category Colors
```dart
// Sports screen with green theme
SingleSectionLayout(
  category: 'sports', // Automatically uses sports colors
  child: Icon(
    Icons.sports,
    color: Theme.of(context).colorScheme.categorySports,
  ),
)
```

### Using with Alpha/Opacity
```dart
colorScheme.categorySports.withValues(alpha: 0.2) // 20% opacity
colorScheme.primaryContainer.withValues(alpha: 0.5) // 50% opacity
```

## Design System Integration

The layout components (`SingleSectionLayout`, `TwoSectionLayout`) automatically apply category colors:

```dart
SingleSectionLayout(
  category: 'sports', // Uses sports green
  child: ...,
)

TwoSectionLayout(
  category: 'social', // Uses social blue
  topChild: ...,
  bottomChild: ...,
)
```

## Future Enhancements

To apply category-specific themes dynamically:
1. Create full ColorScheme definitions for each category (sports, social, activity, profile)
2. Use Theme widget to wrap category-specific sections
3. Example:
```dart
Theme(
  data: ThemeData(colorScheme: sportColorScheme),
  child: SportsFeatureWidget(),
)
```
