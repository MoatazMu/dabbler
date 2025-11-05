# Dabbler Design System

## Overview
This design system ensures consistency across all screens in the Dabbler app.

## Layout Structure

### Two-Section Layout
All screens follow a consistent two-section structure:

```dart
TwoSectionLayout(
  topSection: Column(
    children: [
      // Content for purple top section
    ],
  ),
  bottomSection: Column(
    children: [
      // Content for dark bottom section
    ],
  ),
)
```

**Top Section:**
- Background: Primary Purple (#6B2D9E)
- Border Radius: 52px (bottom corners)
- Padding: 20px (default)
- Contains: Headers, key actions, featured content

**Bottom Section:**
- Background: Dark (#1A1A1A)
- Padding: 20px (default)
- Contains: Lists, cards, secondary content

## Colors

### Primary Colors
- `primaryPurple`: #6B2D9E
- `primaryPurpleLight`: #E8E3FF

### Backgrounds
- `backgroundDark`: #1A1A1A (main)
- `backgroundCardDark`: #2D2D2D (cards)
- `borderDark`: #404040 (borders)

### Text
- `textPrimary`: #FFFFFF (white)
- `textSecondary`: #AAAAAA (light gray)
- `textTertiary`: #CCCCCC (medium gray)

## Typography

### Display
- `displayLarge`: 28px, weight 800
- `displayMedium`: 24px, weight 700

### Headings
- `headingLarge`: 20px, bold
- `headingMedium`: 18px, weight 600
- `headingSmall`: 16px, weight 600

### Body
- `bodyLarge`: 15px, weight 500
- `bodyMedium`: 14px, weight 400
- `bodySmall`: 13px, weight 400

## Spacing

### Base Units
- `xs`: 4px
- `sm`: 8px
- `md`: 12px
- `lg`: 16px
- `xl`: 20px
- `xxl`: 24px
- `xxxl`: 28px
- `huge`: 32px

### Specific Use Cases
- Screen padding: 20px
- Card padding: 16px
- Section spacing: 24px
- Section border radius: 52px
- Card border radius: 16px
- Button border radius: 12px

## Components

### Cards

#### AppCard
Generic container with consistent styling:
```dart
AppCard(
  child: YourContent(),
)
```

#### AppButtonCard
Button-style card with emoji and label:
```dart
AppButtonCard(
  emoji: '🏆',
  label: 'Sports',
  onTap: () {},
)
```

#### AppActionCard
Card with emoji, title, and subtitle:
```dart
AppActionCard(
  emoji: '➕',
  title: 'Create Game',
  subtitle: 'Start a new match',
  onTap: () {},
)
```

## Usage Example

```dart
import 'package:dabbler/core/design_system/layouts/two_section_layout.dart';
import 'package:dabbler/core/design_system/widgets/app_card.dart';
import 'package:dabbler/core/design_system/colors/app_colors.dart';
import 'package:dabbler/core/design_system/typography/app_typography.dart';
import 'package:dabbler/core/design_system/spacing/app_spacing.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TwoSectionLayout(
      topSection: Column(
        children: [
          Text('Header', style: AppTypography.displayLarge),
          SizedBox(height: AppSpacing.xxl),
          // More top section content
        ],
      ),
      bottomSection: Column(
        children: [
          AppCard(
            child: Text('Card Content'),
          ),
          SizedBox(height: AppSpacing.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: AppButtonCard(
                  emoji: '📚',
                  label: 'Community',
                  onTap: () {},
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButtonCard(
                  emoji: '🏆',
                  label: 'Sports',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## Naming Conventions

### Files
- Colors: `app_colors.dart`
- Typography: `app_typography.dart`
- Spacing: `app_spacing.dart`
- Widgets: `app_[widget_name].dart`

### Classes
- Use `App` prefix for design system classes
- Use descriptive names: `AppCard`, `AppButtonCard`, `AppActionCard`

## Future Additions
- Dark/Light theme toggle support
- Animation constants
- Icon system
- Form components
- Navigation components
