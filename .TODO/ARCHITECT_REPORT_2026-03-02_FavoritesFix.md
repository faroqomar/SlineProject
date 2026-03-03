# Architect Report: Favorites Fix

**Scope**: FavoritesFix (PLAN_FavoritesFix_2026-03-01)  
**Date**: 2026-03-02  
**Plan**: .TODO/PLAN_FavoritesFix_2026-03-01.md

---

## 1) Architecture / Logic Findings

### MVVM boundary check — PASS

- **View → Service**: No view file imports or calls `FavoritesService`. Verified: `lib/features/favorites/view/` has no `favorites_service` import; `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` has no `FavoritesService` (uses `FavoritesViewModel` only).
- **View → ViewModel**: FavoritesScreen uses `context.watch<FavoritesViewModel>()` and `context.read<FavoritesViewModel>()`; no local VM creation. RequestTile receives `favoritesVM` from parent; PublicProfileScreen uses `Consumer<FavoritesViewModel>`.
- **ViewModel → Service**: Single path: `FavoritesViewModel` holds `FavoritesService` and calls `listFavoritesWithProfile()`, `addFavorite()`, `removeFavorite()` only.

### Data flow map

```
App (main.dart) → ChangeNotifierProvider<FavoritesViewModel>
       ↓
FavoritesScreen / PublicProfileScreen / RequestsListScreen
       ↓ context.watch / read
FavoritesViewModel (single instance)
       ↓
FavoritesService → Supabase (favorites table, RLS)
       ↓
FavoriteWithProfile.fromMap (null-safe), FavoriteModel
```

- **Single source of truth**: One `FavoritesViewModel` instance at app level; FavoritesScreen no longer creates its own VM. **Contract satisfied.**

### Path validation

| Referenced path | Exists | Notes |
|-----------------|--------|--------|
| lib/features/favorites/data/favorites_service.dart | Yes | Single read path, no listFavorites() |
| lib/features/favorites/models/favorite_model.dart | Yes | FavoriteModel only; FavoriteWithProfile moved out |
| lib/features/favorites/models/favorite_with_profile_model.dart | Yes | Null-safe parser, root freelancer_id fallback |
| lib/features/favorites/models/favorites_mutation_result.dart | Yes | Enum for add/remove result |
| lib/features/favorites/viewmodels/favorites_view_model.dart | Yes | ensureLoaded, typed result, pending set |
| lib/features/favorites/view/favorites_screen.dart | Yes | No FavoritesService import |
| lib/features/tasks/view/widgets/requests/widgets/request_tile.dart | Yes | favoritesVM only |
| lib/features/tasks/view/widgets/requests/requests_list_screen.dart | Yes | Passes context.read<FavoritesViewModel>() |
| lib/features/profile/view/public_profile_screen.dart | Yes | Consumer<FavoritesViewModel>, ensureLoaded in callback |

### Contract checks

- **CONTRACT_FavoritesJoin**: Service select includes `id, client_id, freelancer_id, created_at` + join; `FavoriteWithProfile.fromMap` uses root `freelancer_id` when `freelancer` is null. **Aligned.**
- **CONTRACT_FavoritesMutation**: `add`/`remove` return `FavoritesMutationResult`; UI branches on result. **Aligned.**
- **DECISION_Favorites_DM**: Docs/code do not change DM rule; app still assumes favorites-gated DM. **No contract breach.**

---

## 2) Proposed refactors (non-blocking)

- **MED** — Public profile: `ensureLoaded()` is invoked inside `Consumer` builder via `addPostFrameCallback` on every build; consider moving to a one-time init (e.g. `State.didChangeDependencies` with a flag) to avoid scheduling the same callback repeatedly. Behavior is correct; minor efficiency.
- **LOW** — FavoritesScreen: `_ensureLoadedScheduled` is set true on first build but `ensureLoaded()` is async; if widget is disposed before it completes, no cancel. Acceptable for current scope.

---

## 3) Summary

| Check | Result |
|-------|--------|
| MVVM boundaries | PASS — No view→service; single ViewModel instance |
| Data flow | PASS — Single canonical read, typed mutation result |
| Paths / contracts | PASS — All paths exist; contracts implemented |
| Blockers | None |

**Architect output**: No BLOCKER. Implementation matches plan and CONTRACT_* artifacts. Optional refactors above are non-blocking.
