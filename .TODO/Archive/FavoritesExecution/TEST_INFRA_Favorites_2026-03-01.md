# Test Infrastructure: Favorites

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

## Harnesses (reuse, do not replace)

- **Widget tests**: `test/test_support/pump_app.dart` — `pumpApp(tester, child)` with MaterialApp + AppTheme. Use for all favorites widget tests.
- **Integration tests**: No existing `integration_test/support/helpers.dart` in repo. When adding integration tests (Phase 4), create `integration_test/support/helpers.dart` with app pump, auth helpers, and bounded waits; reference this doc.
- **Dependencies**: `pubspec.yaml` — `flutter_test`, `integration_test`, `mocktail` (dev_dependencies).

## Selector / Key map (favorites-critical UI)

Stable keys for `find.byKey()` and integration selectors. Implement in code as `key: FavoritesTestKeys.*`.

| Key constant | Widget / area | File |
|--------------|----------------|------|
| `favoritesScreen` | FavoritesScreen scaffold | favorites_screen.dart |
| `favoritesList` | ListView.builder (list of favorites) | favorites_screen.dart |
| `favoritesEmpty` | Empty state "No favorites yet." | favorites_screen.dart |
| `favoritesError` | Error state text | favorites_screen.dart |
| `favoritesLoading` | Loading indicator | favorites_screen.dart |
| `favoriteCard(freelancerId)` | FavoriteCard for a freelancer | favorite_card.dart |
| `favoriteCardStartChat(freelancerId)` | Start Chat button on card | favorite_card.dart |
| `favoriteCardRemove(freelancerId)` | Remove button on card | favorite_card.dart |
| `publicProfileFavoriteToggle` | Heart / favorite toggle on public profile | public_profile_screen.dart |
| `requestTileAddFavorite(bidderId)` | Add to favorites on request tile | request_tile.dart |

Keys are implemented via `ValueKey<String>` or `KeyedSubtree` with `ValueKey` where needed. Use semantic keys (e.g. `Key('favorites_screen')`) for simplicity and stability.

## Bounded waits and rerun policy

- **Widget tests**: `tester.pumpAndSettle()` with default timeout; avoid indefinite `pump()` loops. For async load, use `tester.pump()` then `tester.pump(const Duration(seconds: 2))` or mock VM to avoid real network.
- **Integration tests**: Max wait for favorites list load: 10s. Retry policy: 1 retry on timeout. Tag failures with `[favorites]` in test output.
- **Failure artifacts**: On failure, capture test name, phase, and (if available) last screenshot path. Store in `.TODO/` or CI artifact path as `favorites_test_failure_<timestamp>.txt`.

## Run commands

```bash
# Widget/unit (favorites scope)
flutter test test/features/favorites/

# All favorites-related (after adding tests)
flutter analyze lib/features/favorites lib/features/profile/view/public_profile_screen.dart lib/features/tasks/view/widgets/requests/
flutter test test/features/favorites/
# Integration (when added)
# flutter test integration_test/favorites_cross_feature_flow_test.dart
```

## Preflight / fail-fast

Before running favorites integration tests: ensure test user (client) is authenticated, at least one freelancer exists, and favorites table is accessible (RLS allows own rows). If preflight fails, fail fast with clear message; do not hang.
