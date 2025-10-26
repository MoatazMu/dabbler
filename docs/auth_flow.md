# Authentication and Account Creation Flow

This document captures how the Dabbler app authenticates users and provisions accounts using Supabase Auth and the Postgres database.

## 1. Initial Authentication Entry Points

Users can start authentication with email, phone (OTP), or Google OAuth from the onboarding screens.

- **Phone OTP** – `PhoneInputScreen` validates the number, checks whether the identity already exists, then sends an OTP via Supabase Auth. The screen remembers whether the user existed before the OTP so later steps can skip onboarding for returning users.【F:lib/screens/onboarding/phone_input_screen.dart†L39-L141】
- **Email** – `EmailInputScreen` validates the email and queries Supabase to see if the identity already exists. Existing users are sent to the password entry screen; new users are routed to onboarding with the email stored in onboarding state.【F:lib/screens/onboarding/email_input_screen.dart†L40-L131】
- **Google OAuth** – The current UX surfaces a "Continue with Google" CTA but the backing OAuth call is not implemented yet. Google identities will eventually follow the same post-login checks described below.【F:lib/screens/onboarding/phone_input_screen.dart†L227-L238】

The shared `AuthService` wraps Supabase Auth. It sends OTP codes, verifies them, and normalises email addresses for password flows.【F:lib/core/services/auth_service.dart†L16-L146】【F:lib/core/services/auth_service.dart†L167-L215】

## 2. Determining Whether the User Already Exists

After the initial step, the app checks Supabase for an existing identity before continuing:

- `AuthService.checkUserExistsByEmail`/`checkUserExistsByPhone` call the `check_user_exists_by_identifier` RPC, which is expected to inspect `auth.identities` for matching email, phone, or OAuth provider records.【F:lib/core/services/auth_service.dart†L284-L342】
- Phone OTP verification receives the "user existed" flag from the input screen so it can skip onboarding if a matching identity was already present.【F:lib/screens/onboarding/otp_verification_screen.dart†L86-L149】
- Email sign-ins route existing users straight to the password screen.【F:lib/screens/onboarding/email_input_screen.dart†L94-L114】

The password screen signs the user in and triggers a refresh of the global auth state; navigation afterwards is handled by the router based on authentication status.【F:lib/features/authentication/presentation/screens/enter_password_screen.dart†L33-L125】【F:lib/features/authentication/presentation/providers/auth_providers.dart†L189-L246】

## 3. New-User Onboarding

If the user does not already exist (email, phone, or future Google), the app walks them through a multi-step onboarding experience. Each screen stores its data in the `OnboardingData` notifier so that later steps and account creation can use a complete profile record.【F:lib/features/authentication/presentation/providers/onboarding_data_provider.dart†L6-L124】

1. **Profile basics** – `CreateUserInformation` collects the display name, age, and gender, resetting any cached state to ensure a fresh registration. It can also preload data if the user is editing while already authenticated.【F:lib/screens/onboarding/create_user_information.dart†L1-L158】
2. **Intent selection** – Users choose their primary intention (organise, compete, social), which determines their eventual `profile_type` during profile creation.【F:lib/screens/onboarding/intent_selection_screen.dart†L19-L104】
3. **Sports selection** – The screen captures a preferred sport and optional interests; phone users are directed to username creation, while email users proceed to password setup.【F:lib/screens/onboarding/sports_selection_screen.dart†L19-L129】
4. **Credential setup** –
   - Email users visit `SetPasswordScreen` to choose both a username and password; the screen re-validates required onboarding fields before creating the account.【F:lib/screens/onboarding/set_password_screen.dart†L20-L190】
   - Phone (and future Google) users go to `SetUsernameScreen`, which finalises the username before profile creation.【F:lib/screens/onboarding/set_username_screen.dart†L18-L148】
5. **Welcome screen** – After success, `WelcomeScreen` gives feedback and auto-redirects to the home screen.【F:lib/screens/onboarding/welcome_screen.dart†L1-L83】

`OnboardingService` tracks overall completion to know whether to return users to onboarding or straight into the app on subsequent launches.【F:lib/core/services/onboarding_service.dart†L1-L98】

## 4. Account Creation and Profile Provisioning

When onboarding completes, the app creates the Supabase auth account and associated profile:

- `SetPasswordScreen` creates the auth user via `AuthService.signUpWithEmailAndPassword`, then uses the currently authenticated user ID to insert a profile row with onboarding data, including mapping `organise` intent to the organiser profile type.【F:lib/screens/onboarding/set_password_screen.dart†L200-L277】【F:lib/core/services/auth_service.dart†L88-L153】
- For phone/Google users, `SetUsernameScreen` calls `AuthService.createProfile` with the existing Supabase user ID produced by OTP/OAuth sign-in, using the same intent mapping.【F:lib/screens/onboarding/set_username_screen.dart†L99-L138】【F:lib/core/services/auth_service.dart†L96-L153】
- `AuthService.createProfile` writes into `public.profiles` only if a row does not already exist, converting intention into the appropriate `profile_type` and persisting age, gender, sport preferences, and optional interests.【F:lib/core/services/auth_service.dart†L96-L153】

After profile creation, onboarding data is cleared, the auth state is refreshed, and the welcome screen transitions to the home experience. Home loads the profile to personalise the greeting and avatar.【F:lib/screens/onboarding/set_password_screen.dart†L279-L322】【F:lib/screens/onboarding/set_username_screen.dart†L140-L175】【F:lib/screens/home/home_screen.dart†L1-L86】

The Supabase schema migration establishes the `public.profiles` table with a foreign key to `auth.users`, unique usernames, and row-level security policies so the onboarding inserts comply with database constraints.【F:supabase/migrations/01_auth_profiles_init.sql†L1-L120】

## 5. Returning User Experience

On subsequent launches, `SimpleAuthNotifier` listens for Supabase auth changes, keeps the router in sync, and exposes helpers for sign-out or guest mode. It ensures that successful logins refresh the state so navigation can drop the user onto `HomeScreen` without manual redirects.【F:lib/features/authentication/presentation/providers/auth_providers.dart†L17-L246】

Home then loads the profile via `AuthService.getUserProfile` and displays a contextual greeting, confirming the final step of the flow.【F:lib/screens/home/home_screen.dart†L18-L86】

