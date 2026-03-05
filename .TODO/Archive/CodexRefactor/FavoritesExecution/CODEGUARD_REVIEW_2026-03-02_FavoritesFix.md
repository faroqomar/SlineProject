# CodeGuard Review: Favorites Fix

**Scope**: FavoritesFix (PLAN_FavoritesFix_2026-03-01)  
**Date**: 2026-03-02  
**Plan**: .TODO/PLAN_FavoritesFix_2026-03-01.md

---

## 1) Path / name validation

- All files referenced in plan and execution log exist under `lib/features/favorites`, `lib/features/tasks/view/widgets/requests`, `lib/features/profile/view/public_profile_screen.dart`.
- Class names: `FavoritesViewModel`, `FavoritesService`, `FavoriteWithProfile`, `FavoritesMutationResult`, `FavoriteCard`, `RequestTile` — match usages.
- **No phantom or broken paths.**

---

## 2) Performance

- **Single read path**: One query `listFavoritesWithProfile()`; no dual listFavorites + listFavoritesWithProfile. **Good.**
- **add()**: Insert + full load(); still two round-trips. Acceptable per plan (optimization out of scope).
- **notifyListeners()**: Guarded in _setLoading/_setError (only when value changes); pending set triggers intentional notify. **No rebuild storm.**
- **Public profile**: `addPostFrameCallback(ensureLoaded)` every Consumer build — may schedule repeatedly; low cost. **No BLOCKER.**

---

## 3) Security

- **RLS**: Service uses `client_id = auth.uid()` via `_requireUid()`; no service role or raw SQL. **RLS-first satisfied.**
- **No secrets**: No keys or tokens in code.
- **UI**: No raw exception in snackbars; chat-start and remove errors are sanitized. **No info disclosure.**
- **RequestTile**: When `favoritesVM == null`, add-to-favorites button is hidden; no silent no-op with missing VM. **Safe.**

---

## 4) Compatibility

- Flutter/Dart: No deprecated APIs observed in changed code.
- Supabase client: Standard `from().select().eq()`; select shape matches contract.

---

## 5) Verification commands

```bash
flutter analyze lib/features/favorites lib/features/tasks/view/widgets/requests lib/features/profile/view/public_profile_screen.dart
# Expected: No issues found.

flutter test test/features/favorites/ test/integration_test/favorites_cross_feature_flow_test.dart
# Expected: All tests passed (with 1 skipped).

rg "FavoritesService\(" lib/features/tasks/view --glob '*.dart'
# Expected: No matches.

rg "Failed to start chat:.*\$e" lib/features/favorites --glob '*.dart'
# Expected: No matches.
```

---

## 6) Risk rating

| Area | Rating | Note |
|------|--------|------|
| Security | LOW | RLS, no raw errors in UI |
| Performance | LOW | Single read path; guarded notify |
| Compatibility | LOW | No deprecations |
| Data integrity | LOW | Null-safe parser; typed result |

---

## 7) Blockers

**None.** No Critical or BLOCKER issues.

---

## 8) Decision

**APPROVED**

CodeGuard gate: **PASS**. Safe to merge from performance, security, and compatibility perspective. Recommend addressing optional items (chat-start log, doc snippet) in follow-up.
