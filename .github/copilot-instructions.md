# AI Coding Agent Instructions for Dabbler

Concise, actionable guidance to be productive immediately. Focus on existing patterns only.

## Architecture Snapshot
- Flutter app (Material 3) with Riverpod for state; GoRouter for navigation; Supabase for backend.
- Layering: `lib/features/<domain>/` (UI + controllers + providers), `lib/data/` (models + repositories), `lib/core/` (design system, config, fp primitives), `lib/app/app_router.dart` (central route map), `lib/providers.dart` (re-export hub).
- Data models: Freezed + JsonSerializable (see `lib/data/models/README.md`). After changes run: `dart run build_runner build -d`.
- Repositories return `Result<T>` (`lib/core/fp/result.dart`) with `Failure` for errors—do not throw inside UI-facing code; surface failures.
- Feature flags in `core/config/feature_flags.dart` gate UI/routes (e.g. `socialFeed`, `createGamePublic`, `notifications`). Respect them when adding screens or enabling functionality.

## State & Providers
- Riverpod used extensively; central exports in `lib/providers.dart`. Prefer adding new provider exports here for broad availability.
- Access providers inside router redirects via `ProviderScope.containerOf(context, listen: false)` (see `_handleRedirect` in `app_router.dart`). When extending redirect logic, avoid heavy work—keep it synchronous or quick async.

## Navigation Pattern
- All routes declared in `_routes` list inside `lib/app/app_router.dart` using `GoRoute`.
- Use constants from `utils/constants/route_constants.dart` for paths; do not hardcode strings.
- Choose a transition wrapper: `FadeTransitionPage`, `SlideTransitionPage`, `SharedAxisTransitionPage`, `BottomSheetTransitionPage`, `ScaleTransitionPage`, `FadeThroughTransitionPage` (in `utils/transitions/page_transitions.dart`). Pick one consistent with neighboring routes.
- Apply feature flag redirects (see social & notifications routes) rather than removing routes—deep links rely on route presence.

## Design System & UI
- Theme via `ThemeService` and `AppTheme` (light/dark). Use `TwoSectionLayout` for standard screen scaffolding (top purple / bottom dark) per `core/design_system/README.md`.
- Prefer Material 3 `ColorScheme` + extensions (`colorScheme.categoryMain`, etc.) instead of legacy `AppColors`.
- For buttons/cards use wrappers: `AppButton`, `AppCard`, `AppButtonCard`, `AppActionCard` to keep consistent elevation, shape, spacing.

## Data & Supabase Integration
- Supabase initialized in `main.dart` after `Environment.load()`. Environment values (`supabaseUrl`, `supabaseAnonKey`) come from `.env` listed in `pubspec.yaml` assets.
- Keep client access through `Supabase.instance.client`. Avoid scattering initialization.
- Trust server-side RLS for authorization; keep repository queries minimal (see `lib/data/repositories/README.md`).

## Result & Error Handling
- Wrap async operations in `Result<T>`; never expose raw exceptions above repository layer. Use `Failure` variants to classify.
- Log analytics events via `AnalyticsService.trackEvent` sparingly (see feature flag snapshot in `main.dart`).

## Model & Code Generation Workflow
1. Create/modify a Freezed data class in `lib/data/models/`.
2. Add JSON (de)serialization annotations as needed.
3. Run `dart run build_runner build -d` to regenerate code.
4. Return instances via repositories using `Result.success(data)` or `Result.failure(failure)`.

## Adding a New Feature (Example)
1. Create directory: `lib/features/<feature>/presentation/screens/` for UI, `.../controllers/` or `.../providers/` for state.
2. Add models (if needed) under `lib/data/models/` + run generator.
3. Implement repository or extend existing one under `lib/data/repositories/` returning `Result<T>`.
4. Export new providers through `lib/providers.dart`.
5. Add a `GoRoute` in `app_router.dart` using a proper transition; guard with feature flag if experimental.
6. Use `TwoSectionLayout` and design system tokens; avoid ad-hoc colors.

## Routing & Auth Nuances
- Auth and onboarding routes share unauthenticated access; redirect logic in `_handleRedirect` ensures correct flow based on `isAuthenticatedProvider` & `isGuestProvider`.
- When adding onboarding steps, include them in relevant path sets (`authPaths`, `onboardingPaths`) to avoid premature redirect.

## Performance & Logging
- Keep router `_routeLogging` true only when actively debugging; avoid verbose prints in production logic.
- Prefer `debugPrint` for dev-only logs; remove or gate prints behind flags before merging.

## Do / Avoid
- Do reuse transition page wrappers; avoid raw `MaterialPage` duplication.
- Do centralize provider exports; avoid importing deep feature paths repeatedly.
- Avoid throwing errors from repositories; use `Failure`.
- Avoid hardcoded route strings; rely on route constants & feature flags.

## Open Points / Confirm
- CI/test workflow not documented—confirm if integration tests or unit tests are actively used beyond `flutter_test`. Add guidance once clarified.
- Admin role checks for restricted routes (e.g., create game) still TODO—avoid assuming roles.

Provide feedback on missing workflows (testing, CI, analytics standards) or clarify if additional layers (e.g., caching) need documenting.
