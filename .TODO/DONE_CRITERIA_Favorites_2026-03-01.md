# Done criteria: Favorites Fix

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

Implementation is not “done” until all of the following are true.

## Non-regression conditions (measurable)

1. **No parser crash**  
   Favorites list load does not throw when a joined freelancer profile row is missing; parser uses root `freelancer_id` fallback and placeholder rendering where needed.

2. **No split provider ownership**  
   One shared `FavoritesViewModel` instance (app-level provider) is used for Favorites screen, Public Profile, and Request Tile. No screen-owned duplicate VM.

3. **No direct widget → Favorites service call**  
   No view-layer file under `lib/features/tasks/view` (or favorites view) imports or calls `FavoritesService` directly. Request tile uses callback or VM only.

4. **No false-success remove**  
   Remove success snackbar (or equivalent UI) is shown only after successful delete; remove failure shows error, not success.

5. **No raw backend chat error in UI**  
   User never sees raw exception text (e.g. `$e`, PostgrestException) for chat-start failure; only sanitized English copy; details logged via AppLogger.

6. **Verified DM contract**  
   Direct-DM rule is documented and matches live DB behavior (policy/trigger); docs and code comments aligned (see DECISION_Favorites_DM).

7. **Deterministic tests**  
   Favorites unit/widget tests exist and pass; integration tests (if added) use fixtures and selectors from TEST_INFRA and FIXTURES; no flake from missing keys or unbounded waits.

## Verification

- Grep: `FavoritesService(` in `lib/features/tasks/view` → no hits.  
- Grep: `Failed to start chat: \$e` (or raw `$e` in snackbar) in `lib/features/favorites` → no hits.  
- `flutter analyze` clean for touched files.  
- Execution log updated with evidence per phase.
