# PR plan: Favorites Fix (3 slices)

**Date**: 2026-03-01  
**Plan**: PLAN_FavoritesFix_2026-03-01.md

## PR1: Contracts + test infrastructure + selector wiring

**Scope**: Phase 0 artifacts and selector keys in UI (no behavior change to VM/service).

- Add `.TODO/` artifacts: TEST_INFRA, FIXTURES, DECISION_DM, DONE_CRITERIA, THREAT_MODEL, CONTRACT_Join, CONTRACT_Mutation, UI_STATE_MATRIX, MIGRATION, PR_PLAN.
- Add stable test keys to: favorites_screen.dart, favorite_card.dart, public_profile_screen.dart, request_tile.dart (per TEST_INFRA key map).
- **Done criteria**: All artifact files exist; keys implemented; `flutter analyze` clean.
- **Rollback**: Revert key additions only; keep .TODO docs.

---

## PR2: App-layer + provider + UI fixes + unit/widget tests

**Scope**: Phase 2–3 implementation and Phase 4 unit/widget tests.

- Single shared FavoritesViewModel; FavoritesScreen consumes app-level provider only.
- Typed mutation result (FavoritesMutationResult); add/remove return it; no false-success remove.
- Null-safe joined parser (root freelancer_id fallback); FavoriteWithProfile in own file if split.
- RequestTile: no FavoritesService; callback/VM from requests_list_screen.
- FavoritesScreen: sanitized chat-start error; FavoriteCard: formatUtcToLocal.
- AppLogger: service, ViewModel, model parse paths (load/add/remove, ensureLoaded, pending).
- Unit tests: parser, ViewModel (load/add/remove/result). Widget tests: favorites screen states, favorite card, profile toggle, request tile.
- **Done criteria**: DONE_CRITERIA satisfied; no FavoritesService in views (grep); no raw $e in favorites UI (grep); tests pass.
- **Rollback**: Revert app/VM/UI and test changes; keep PR1 keys/contracts if desired.

---

## PR3: Docs sync + optional DB reconcile + integration/release gate

**Scope**: Phase 1 (if any SQL/docs), Phase 4 integration/security checks, Phase 5 docs.

- RLS/Supabase verification output in execution log; optional trigger/comment reconcile.
- Integration test (if added): cross-feature favorites flow; use fixtures and selectors.
- Docs: DEVELOPER_GUIDE (Favorites), SUPABASE_SETUP, CODE_REVIEW aligned with DECISION_DM and implementation.
- **Done criteria**: Docs match code and DB; integration tests pass (if any); release checklist in execution log.
- **Rollback**: Revert docs and integration test; DB reconcile reverted via forward-fix if needed (no ad hoc manual SQL).
