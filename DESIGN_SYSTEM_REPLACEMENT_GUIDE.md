# Design System Replacement Guide

## AppTypography → Theme.of(context).textTheme

Replace all instances:

```dart
// OLD
style: AppTypography.displayLarge.copyWith(color: ...)
style: AppTypography.displayMedium.copyWith(color: ...)  
style: AppTypography.displaySmall.copyWith(color: ...)
style: AppTypography.headlineLarge.copyWith(color: ...)
style: AppTypography.headlineMedium.copyWith(color: ...)
style: AppTypography.headlineSmall.copyWith(color: ...)
style: AppTypography.titleLarge.copyWith(color: ...)
style: AppTypography.titleMedium.copyWith(color: ...)
style: AppTypography.titleSmall.copyWith(color: ...)
style: AppTypography.bodyLarge.copyWith(color: ...)
style: AppTypography.bodyMedium.copyWith(color: ...)
style: AppTypography.bodySmall.copyWith(color: ...)
style: AppTypography.labelLarge.copyWith(color: ...)
style: AppTypography.labelMedium.copyWith(color: ...)
style: AppTypography.labelSmall.copyWith(color: ...)

// NEW
style: Theme.of(context).textTheme.displayLarge?.copyWith(color: ...)
style: Theme.of(context).textTheme.displayMedium?.copyWith(color: ...)
style: Theme.of(context).textTheme.displaySmall?.copyWith(color: ...)
style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: ...)
style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: ...)
style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: ...)
style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ...)
style: Theme.of(context).textTheme.titleMedium?.copyWith(color: ...)
style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ...)
style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ...)
style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ...)
style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ...)
style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ...)
style: Theme.of(context).textTheme.labelMedium?.copyWith(color: ...)
style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ...)
```

## AppSpacing → Numeric Values

Replace all instances:

```dart
// OLD → NEW
AppSpacing.xs        → 4.0
AppSpacing.sm        → 8.0
AppSpacing.md        → 12.0
AppSpacing.lg        → 16.0
AppSpacing.xl        → 24.0
AppSpacing.xxl       → 32.0
AppSpacing.huge      → 48.0

// Examples:
SizedBox(height: AppSpacing.md)  → const SizedBox(height: 12)
SizedBox(height: AppSpacing.lg)  → const SizedBox(height: 16)
SizedBox(height: AppSpacing.xl)  → const SizedBox(height: 24)

EdgeInsets.all(AppSpacing.md)    → const EdgeInsets.all(12)
EdgeInsets.symmetric(horizontal: AppSpacing.lg) → const EdgeInsets.symmetric(horizontal: 16)
```

## AppButton → Material 3 Buttons

Replace all instances:

```dart
// OLD: AppButton with type/size parameters
AppButton(
  label: 'Continue',
  onPressed: () {},
  type: AppButtonType.filled,
  size: AppButtonSize.lg,
)

// NEW: FilledButton with child
FilledButton(
  onPressed: () {},
  style: FilledButton.styleFrom(
    minimumSize: const Size(double.infinity, 56),
  ),
  child: const Text('Continue'),
)

// OLD: AppButton.primary
AppButton.primary(
  label: 'Save',
  onPressed: () {},
)

// NEW: FilledButton
FilledButton(
  onPressed: () {},
  child: const Text('Save'),
)

// OLD: AppButton with type=AppButtonType.outline
AppButton(
  label: 'Cancel',
  type: AppButtonType.outline,
  onPressed: () {},
)

// NEW: OutlinedButton
OutlinedButton(
  onPressed: () {},
  child: const Text('Cancel'),
)

// OLD: AppButton with type=AppButtonType.ghost
AppButton(
  label: 'Skip',
  type: AppButtonType.ghost,
  onPressed: () {},
)

// NEW: TextButton
TextButton(
  onPressed: () {},
  child: const Text('Skip'),
)
```

## Priority Files to Update

1. **Onboarding Screens** (User-facing):
   - `lib/features/misc/presentation/screens/set_username_screen.dart`
   - `lib/features/misc/presentation/screens/intent_selection_screen.dart`
   - `lib/features/misc/presentation/screens/sports_selection_screen.dart`
   - `lib/features/misc/presentation/screens/welcome_screen.dart`
   - `lib/features/misc/presentation/screens/create_user_information.dart`

2. **Auth Screens**:
   - `lib/features/misc/presentation/screens/identity_verification_screen.dart`
   - `lib/features/misc/presentation/screens/otp_verification_screen.dart`

3. **Landing & Main Screens**:
   - `lib/features/landing/presentation/screens/landing_page.dart`
   - `lib/features/home/presentation/screens/home_screen.dart` (DONE)

## Search & Replace Commands

Use these for bulk replacement:

```bash
# Replace AppTypography
find lib/features -name "*.dart" -type f ! -name "*.bak" ! -path "*/test/*" -exec sed -i '' 's/AppTypography\./Theme.of(context).textTheme./g' {} \;

# Note: Manual review required for proper null safety (add ?)
```

## Status

- ✅ Home Screen completed
- ⏳ Onboarding screens in progress
- ⏳ Auth screens pending
- ⏳ Other screens pending
