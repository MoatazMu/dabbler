# Theme Mode Color Reference

Quick reference for all 10 theme mode primary colors and use cases.

## Light Themes

### Main Light (Purple)
- **Button Color**: `#7328CE` - Deep Purple
- **Header**: `#E0C7FF` - Soft Lavender
- **Use Case**: Default app theme, main navigation, general content
- **Best For**: Primary app experience

### Social Light (Blue)
- **Button Color**: `#3473D7` - Royal Blue
- **Header**: `#D1EAFA` - Light Sky Blue
- **Use Case**: Social features, community, messaging
- **Best For**: Social feed, profiles, connections

### Sports Light (Green)
- **Button Color**: `#348638` - Forest Green
- **Header**: `#B1FBDA` - Mint Green
- **Use Case**: Sports games, fitness activities
- **Best For**: Game listings, sports events

### Activities Light (Pink)
- **Button Color**: `#D72078` - Hot Pink
- **Header**: `#FCDEE8` - Pale Pink
- **Use Case**: General activities, events, entertainment
- **Best For**: Activity discovery, event calendars

### Profile Light (Orange)
- **Button Color**: `#F59E0B` - Vivid Orange
- **Header**: `#FCF8EA` - Pale Cream
- **Use Case**: User profiles, settings, personal space
- **Best For**: Profile pages, user management

---

## Dark Themes

### Main Dark (Light Purple)
- **Button Color**: `#C18FFF` - Lavender
- **Header**: `#4A148C` - Deep Purple
- **Base**: `#1F1F1F` - Dark Gray
- **Use Case**: Default dark mode
- **Best For**: Night-time usage, OLED screens

### Social Dark (Sky Blue)
- **Button Color**: `#A6DCFF` - Light Blue
- **Header**: `#023D99` - Navy Blue
- **Base**: `#1F1F1F` - Dark Gray
- **Use Case**: Social features in dark mode
- **Best For**: Evening social browsing

### Sports Dark (Mint)
- **Button Color**: `#7FD89B` - Mint Green
- **Header**: `#235826` - Dark Green
- **Base**: `#1F1F1F` - Dark Gray
- **Use Case**: Sports content at night
- **Best For**: Late-night game browsing

### Activities Dark (Rose)
- **Button Color**: `#FFA8D5` - Light Pink
- **Header**: `#9C2464` - Deep Magenta
- **Base**: `#1F1F1F` - Dark Gray
- **Use Case**: Activities in dark mode
- **Best For**: Evening event planning

### Profile Dark (Amber)
- **Button Color**: `#FFCE7A` - Warm Amber
- **Header**: `#AE6B09` - Dark Orange
- **Base**: `#1F1F1F` - Dark Gray
- **Use Case**: Profile in dark mode
- **Best For**: Personal settings at night

---

## Theme Pairing Recommendations

### By App Section
```
Home/Main     → Main Light/Dark
Social Feed   → Social Light/Dark
Sports Games  → Sports Light/Dark
Activities    → Activities Light/Dark
User Profile  → Profile Light/Dark
```

### By Time of Day
```
Day (6am-6pm)    → Light themes
Evening (6pm-10pm) → Light or Dark (user choice)
Night (10pm-6am)  → Dark themes (auto-switch)
```

### By Content Type
```
Reading-heavy    → Main theme (optimized typography)
Media-heavy      → Social theme (vibrant colors)
Action-oriented  → Sports theme (energetic green)
Creative/Events  → Activities theme (playful pink)
Personal/Private → Profile theme (warm orange)
```

## Common Color Tokens

All themes share:
- **Success**: `#00A63E` (Light) / `#0FBF5A` (Dark)
- **Warning**: `#EC8F1E` (Light) / `#FBBF24` (Dark)
- **Error**: `#FF3B30` (Light) / `#EF4444` (Dark)

## Accessibility

All color combinations meet **WCAG AA standards**:
- Text on background: 4.5:1 contrast minimum
- Large text: 3:1 contrast minimum
- UI components: 3:1 contrast minimum

## Implementation

```dart
// Category-aware theme routing
String getCategory(String route) {
  if (route.startsWith('/social')) return 'social';
  if (route.startsWith('/sports')) return 'sports';
  if (route.startsWith('/activities')) return 'activities';
  if (route.startsWith('/profile')) return 'profile';
  return 'main';
}

// Apply theme based on route
AppThemeMode getThemeForRoute(String route, bool isDark) {
  final category = getCategory(route);
  switch (category) {
    case 'social':
      return isDark ? AppThemeMode.socialDark : AppThemeMode.socialLight;
    case 'sports':
      return isDark ? AppThemeMode.sportsDark : AppThemeMode.sportsLight;
    case 'activities':
      return isDark ? AppThemeMode.activitiesDark : AppThemeMode.activitiesLight;
    case 'profile':
      return isDark ? AppThemeMode.profileDark : AppThemeMode.profileLight;
    default:
      return isDark ? AppThemeMode.mainDark : AppThemeMode.mainLight;
  }
}
```

## Visual Hierarchy

### Light Themes Priority
1. **Header** (lightest) - Top sections, hero areas
2. **Section** (semi-transparent) - Content containers
3. **Base** (#FBFBFB) - Page background
4. **Card** (semi-transparent) - Elevated content
5. **App** (#FFFFFF) - Absolute white when needed

### Dark Themes Priority
1. **Header** (darkest) - Top sections
2. **Section** (darker overlay) - Content containers
3. **Base** (#1F1F1F) - Page background
4. **Card** (lighter overlay) - Elevated content
5. **App** (#000000) - True black (OLED)

## Token Values Quick Reference

| Theme | Light Button | Dark Button | Light Header | Dark Header |
|-------|-------------|------------|--------------|-------------|
| Main | #7328CE | #C18FFF | #E0C7FF | #4A148C |
| Social | #3473D7 | #A6DCFF | #D1EAFA | #023D99 |
| Sports | #348638 | #7FD89B | #B1FBDA | #235826 |
| Activities | #D72078 | #FFA8D5 | #FCDEE8 | #9C2464 |
| Profile | #F59E0B | #FFCE7A | #FCF8EA | #AE6B09 |
