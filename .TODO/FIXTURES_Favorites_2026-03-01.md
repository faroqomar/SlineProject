# Fixtures: Favorites (staging / test data)

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

## Deterministic staging data requirements

1. **Client account**  
   One authenticated client user (uid stored; used for RLS and favorites CRUD). Required for: loading favorites, add, remove, DM start.

2. **Freelancer account(s)**  
   At least two freelancer profiles (with `id`, `full_name`, `avatar_url` or null) so that:  
   - One can be added as favorite (and appear in list).  
   - One remains non-favorite (for “add to favorites” from request tile or profile).

3. **Favorites rows**  
   At least one row in `public.favorites`: `(client_id = client.uid, freelancer_id = freelancer_1.id)`. Optional: second row for second freelancer to test remove and list updates.

4. **Non-favorite freelancer**  
   One freelancer with no row in `favorites` for the client — used to test add flow and duplicate-add behavior (e.g. 23505).

## Cleanup / reset instructions

- **Staging**: Delete test favorites rows for the test client: `DELETE FROM public.favorites WHERE client_id = :test_client_uid;`  
- **Integration**: After test run, optionally reset favorites for test client so next run is deterministic.  
- Do not delete real user data; use dedicated test accounts or clearly tagged test UIDs.

## Use in tests

- Unit tests: use in-memory mocks (no live DB).  
- Widget tests: mock `FavoritesViewModel` / `FavoritesService` with fixed lists (empty, one item, error state).  
- Integration tests: use staging DB and above fixtures; run preflight (auth + at least one favorite row) before favorites flows.
