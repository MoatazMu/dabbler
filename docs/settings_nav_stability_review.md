# Settings, Navigation & Stability — MVP review

- [ ] **Settings matches MVP**
  - `SettingsScreen` still exposes non-MVP surfaces such as Password & Security, Connected Accounts, privacy toggles, payment methods, help/support, terms, and contact CTAs, all wired to snackbars or missing routes. These should be hidden or replaced with theme/language/logout only for the MVP cut.【F:lib/features/profile/presentation/screens/settings_screen.dart†L139-L353】

- [ ] **Nav tabs match MVP**
  - Home quick actions still link to the social feed, multi-sport explore, and the create-game flow, while feature flags keep the Social and Sports tabs enabled. Remove these entry points or hard-disable the flags so only Home, My Games, Profile, and Settings remain reachable in the launch build.【F:lib/features/home/presentation/screens/home_screen.dart†L242-L295】【F:lib/core/config/feature_flags.dart†L228-L239】

- [ ] **No obvious crash-prone patterns in core flows**
  - Several settings actions call routes that are not defined in the router (e.g. `/edit_profile`, `/payment_methods`, `/theme_settings`), which will throw GoRouter exceptions at runtime. Update the route targets to the registered paths (such as `/profile/edit` or `/settings/theme`) or remove the buttons until the destinations exist.【F:lib/features/profile/presentation/screens/settings_screen.dart†L142-L264】【F:lib/app/app_router.dart†L592-L663】
