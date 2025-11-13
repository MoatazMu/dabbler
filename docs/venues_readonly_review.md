# Venues Read-Only MVP Review

## Safe read-only surfaces
- `lib/features/venues/presentation/screens/venue_detail_screen.dart` keeps the primary CTA limited to a "Directions" button in the footer with no booking or payment hooks, so the detail view remains informational only. (see `_buildBottomBar`)
- `lib/core/config/feature_flags.dart` disables venue search, nearby venues, booking, ratings, and photos by default, preventing those non-MVP capabilities from surfacing if a screen accidentally checks the flags. (`enableVenueSearch`, `enableNearbyVenues`, `enableVenueBooking`, `enableVenueRatings`, `enableVenuePhotos`)

## Problematic actions
- `lib/features/venues/venues_consumer.dart` still renders a live list of `venue_spaces` beneath the venue list, exposing the per-court inventory that the MVP must hide. Consider dropping the second `Expanded` section or gating it behind a future flag before shipping.
- `lib/features/venues/presentation/screens/venue_detail_screen.dart` advertises multiple sports via the `supportedSports` chips and multi-sport icons, which conflicts with the football-only launch positioning. Restrict the chips to football (or remove the section) until multi-sport support is in scope.
