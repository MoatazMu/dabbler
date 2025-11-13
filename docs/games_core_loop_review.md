# Games Core Loop MVP Review

## 1) Browse Public Games Flow — Needs Fix Before Launch
- Home quick actions still surface the Community feed, the multi-sport "Sports" explore hub, and an always-on "Create Game" CTA, so non-MVP surfaces remain one tap away on the core landing screen.【F:lib/features/home/presentation/screens/home_screen.dart†L242-L295】
- Feature flags keep public game creation and the social module enabled globally, so even if UI tweaks land elsewhere the router still exposes out-of-scope flows to normal users.【F:lib/core/config/feature_flags.dart†L49-L88】
- The explore screen itself is built around venue discovery, multi-sport filters, and match detail journeys that branch into venue pages—none of which are aligned with a football-only public games list for MVP.【F:lib/features/explore/presentation/screens/sports_screen.dart†L1-L200】

## 2) Join / Leave Logic & Error Handling — Needs Fix Before Launch
- Game detail UI keeps premium affordances active (chatting with organiser, sharing, pricing per player, ratings snippets) even though MVP only needs simple join/leave over public football games.【F:lib/features/games/presentation/screens/join_game/game_detail_screen.dart†L720-L840】
- The use case doubles down on waitlists, organiser notifications, and other advanced flows despite the MVP explicitly excluding waitlists and realtime messaging—failures here will confuse players because join attempts can silently become "waitlist" outcomes.【F:lib/features/games/domain/usecases/join_game_usecase.dart†L18-L205】

## 3) My Games Display & Data Source — Needs Fix Before Launch
- The Supabase query powering "My Games" only returns matches the user is hosting (`host_user_id`), so regular players will never see games they joined in the MVP core loop.【F:lib/features/games/data/datasources/supabase_games_datasource.dart†L444-L487】
- The Activities screen layers on bookings sync, analytics logging, and post-game rating prompts that depend on data the broken roster query never supplies, leaving both tabs effectively empty for a normal player account.【F:lib/features/misc/presentation/screens/activities_screen_v2.dart†L15-L200】

## 4) Navigation Bar & Routes — Needs Fix Before Launch
- Feature flags still mark the Social and Sports tabs as "now enabled" and the home screen wires those routes into the hero section, so non-MVP destinations remain first-class navigation targets.【F:lib/core/config/feature_flags.dart†L234-L241】【F:lib/features/home/presentation/screens/home_screen.dart†L242-L295】
- The router continues to register full social, rewards, and create-game stacks without any MVP guardrail beyond the permissive flags, making it easy for testers or deep links to expose excluded experiences during launch.【F:lib/app/app_router.dart†L470-L812】
