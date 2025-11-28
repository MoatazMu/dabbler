# AI Coding Agent Instructions for Dabbler

Concise, actionable guidance to be productive immediately. Focus on existing patterns only.

## Architecture Snapshot
- **Framework**: Flutter (Material 3) + Riverpod (State) + GoRouter (Nav) + Supabase (Backend).
- **Structure**:
  - `lib/features/<domain>/`: UI (screens, widgets), state (controllers, providers).
  - `lib/data/`: Models (Freezed), Repositories.
  - `lib/core/`: Design system, config, utils, FP primitives.
  - `lib/app/app_router.dart`: Central route map & redirect logic.
  - `lib/providers.dart`: Central export hub for providers.
- **Data Flow**:
  - Repositories return `Result<T, Failure>` (`lib/core/fp/result.dart`).
  - Use `Result.guard` to wrap async calls and map exceptions to `Failure`.
  - **Never** throw exceptions in UI-facing code; surface `Failure` variants.
  - Trust Supabase RLS for authorization; keep repository queries minimal.

## Critical Workflows
- **Code Generation**: Run `dart run build_runner build -d` after modifying Freezed models (`lib/data/models/`) or Riverpod generators.
- **Environment**: `Environment.load()` initializes config from `.env`.
- **Feature Flags**: Check `lib/core/config/feature_flags.dart`. Gate new features using `FeatureFlags.<featureName>`.

## Navigation Pattern
- **Router**: `GoRouter` defined in `lib/app/app_router.dart`.
- **Redirects**: Centralized in `_handleRedirect`. Handles Auth, Onboarding, and Feature Flag gating.
- **Transitions**: Use wrappers in `utils/transitions/page_transitions.dart`:
  - `FadeTransitionPage`, `SlideTransitionPage`, `SharedAxisTransitionPage`, `BottomSheetTransitionPage`.
- **Constants**: Use `RoutePaths` and `RouteNames` from `utils/constants/route_constants.dart`.

## Design System & UI
- **Scaffold**: Use `TwoSectionLayout` (Purple top / Dark bottom) for standard screens.
- **Theme**: Material 3 via `AppTheme`. Access colors via `Theme.of(context).colorScheme`.
- **Extensions**: Use `colorScheme.categoryMain`, `colorScheme.categorySocial`, etc. for domain colors.
- **Components**:
  - Buttons: `AppButton.primary`, `AppButton.secondary`, `AppButton.ghost`.
  - Cards: `AppCard`, `AppButtonCard` (emoji+label), `AppActionCard` (title+subtitle).
  - Inputs: `CustomInputField`.
- **Spacing**: 4dp grid system.

## State & Providers
- **Riverpod**: Used extensively. Export new providers in `lib/providers.dart`.
- **Access**:
  - In Widgets: `ref.watch(provider)`.
  - In Router: `ProviderScope.containerOf(context, listen: false).read(provider)`.

## Data & Supabase
- **Access**: Use `Supabase.instance.client`.
- **Models**: Freezed classes with `@JsonSerializable`.
- **Pattern**:
  1. Define Model (Freezed).
  2. Implement Repository returning `Result<T, Failure>`.
  3. Expose via Provider.
  4. Consume in Controller/UI.

## Do / Avoid
- **Do** use `Result<T, Failure>` for all data operations.
- **Do** use `TwoSectionLayout` for consistency.
- **Do** gate new routes/features with `FeatureFlags`.
- **Avoid** hardcoded colors; use `ColorScheme` or `AppTheme` extensions.
- **Avoid** raw `MaterialPage`; use transition wrappers.
- **Avoid** throwing exceptions from repositories.
