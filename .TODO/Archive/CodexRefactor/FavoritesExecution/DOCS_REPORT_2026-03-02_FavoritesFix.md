# Docs Report: Favorites Fix

**Scope**: FavoritesFix (PLAN_FavoritesFix_2026-03-01)  
**Date**: 2026-03-02  
**Plan**: .TODO/PLAN_FavoritesFix_2026-03-01.md

---

## 1) Documentation delta

### Updated (and consistent with code)

| Doc | Section | Change | Status |
|-----|---------|--------|--------|
| Sline_everything/DEVELOPER_GUIDE/Favorites Feature.md | File inventory, RLS table, Extra notes | Added favorite_with_profile_model, favorites_mutation_result; corrected RLS policy names to _self; single read path, RequestTile VM-only | Aligned |
| Sline_everything/SUPABASE_SETUP.md | Key Business Rules, conversations 5.5 | DM rule set to "require favorites"; direct DMs require favorites | Aligned |
| Sline_everything/CODE_REVIEW.md | §5 Direct Service Calls from UI | RequestTile VM-only; no legacy fallback; typed result | Aligned |

### References checked

- DEVELOPER_GUIDE Favorites references `trg_conversations_guard`; SUPABASE_SETUP and plan refer to `conversations_insert_client_only`. Both refer to conversation DM gate; naming differs (trigger vs policy). **Not broken**; both exist in typical setups.
- DEVELOPER_GUIDE Favorites still shows example `listFavorites()` and `listFavoritesWithProfile()` returning `List<Map<String, dynamic>>` in §5.2 Dart; actual code uses `List<FavoriteWithProfile>` and no longer exposes `listFavorites()`. **Outdated snippet** — MED priority to update when touching that section.

---

## 2) Broken refs / outdated statements

| Ref | Location | Issue | Severity |
|-----|----------|--------|----------|
| Example code returning `List<Map<String, dynamic>>` for list with profile | DEVELOPER_GUIDE/Favorites Feature.md §5.2 | Service now returns `List<FavoriteWithProfile>`; `listFavorites()` removed | MED — doc snippet outdated |
| "favorites_insert_own" / "favorites_delete_own" | Already fixed in prior execution | Now "favorites_insert_self" / "favorites_delete_self" in doc | Fixed |

No broken file paths or missing artifacts. Plan refs (.TODO/PLAN_*, CONTRACT_*, DECISION_*) exist.

---

## 3) Required doc updates (ordered)

1. **DEVELOPER_GUIDE/Favorites Feature.md** (§5.2 Dart): Update snippet so `listFavoritesWithProfile()` returns `List<FavoriteWithProfile>` and remove or deprecate `listFavorites()` in the example. Add note that add/remove use typed `FavoritesMutationResult`.
2. Optional: Add one-line reference to DECISION_Favorites_DM and CONTRACT_FavoritesJoin in Favorites Feature.md "Extra Notes" for traceability.

---

## 4) Summary

| Check | Result |
|-------|--------|
| Doc vs code (main behavior) | Aligned (single VM, VM-only RequestTile, DM rule) |
| Broken refs | None |
| Outdated snippets | 1 (Favorites §5.2 Dart example) — MED |
| Blockers | None |

**DocsKeeper output**: No BLOCKER. One MED doc update recommended for §5.2 example.
