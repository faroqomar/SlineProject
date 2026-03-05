# Observability Report: Favorites Fix

**Scope**: FavoritesFix (PLAN_FavoritesFix_2026-03-01)  
**Date**: 2026-03-02  
**Plan**: .TODO/PLAN_FavoritesFix_2026-03-01.md

---

## 1) Telemetry coverage

### What is logged (AppLogger)

| Location | Event | Tag | Level |
|----------|--------|-----|--------|
| favorites_service.dart | Not authenticated | Favorites | error |
| favorites_service.dart | Loading favorites with profile | FavoritesService | debug |
| favorites_service.dart | Loaded N favorites | FavoritesService | info |
| favorites_service.dart | Failed to list favorites with profile | FavoritesService | error |
| favorites_service.dart | Adding favorite: id | FavoritesService | debug |
| favorites_service.dart | Added favorite: id | FavoritesService | info |
| favorites_service.dart | Failed to add favorite | FavoritesService | error |
| favorites_service.dart | Removing favorite: id | FavoritesService | debug |
| favorites_service.dart | Removed favorite: id | FavoritesService | info |
| favorites_service.dart | Failed to remove favorite | FavoritesService | error |
| favorites_view_model.dart | ensureLoaded skip/loading | FavoritesViewModel | debug |
| favorites_view_model.dart | Load favorites start | FavoritesViewModel | debug |
| favorites_view_model.dart | Load favorites success: N items | FavoritesViewModel | info |
| favorites_view_model.dart | Failed to load favorites | FavoritesViewModel | error |
| favorites_view_model.dart | Add/Remove skipped (pending) | FavoritesViewModel | debug |
| favorites_view_model.dart | Add/Remove favorite: id | FavoritesViewModel | debug |
| favorites_view_model.dart | Add/Remove favorite success | FavoritesViewModel | info |
| favorites_view_model.dart | Failed to add/remove favorite | FavoritesViewModel | error |
| favorite_with_profile_model.dart | Joined freelancer profile missing | Favorites | warning |

- **Critical flows covered**: Load start/success/failure; add/remove start/success/failure; auth guard; null-join fallback.
- **No `print()`** in touched code. **Rule satisfied.**

### What is NOT logged (correct)

- Raw exception text or DB payloads are not sent to any user-facing or analytics sink; exceptions are passed to `AppLogger.e` with error/stackTrace; UI shows sanitized messages only.
- No PII (e.g. email, name) in log messages; only `freelancerId` (UUID) appears in debug/info. **Privacy-safe for current scope.**

---

## 2) Event taxonomy

- **Domain**: Favorites  
- **Actions**: load, add, remove, ensureLoaded  
- **Outcomes**: success, failure (with error type: auth, duplicate, forbidden, generic)  
- **Correlation**: Tag `FavoritesService` / `FavoritesViewModel` / `Favorites` allows filtering. No explicit correlation ID; acceptable for current feature size.

---

## 3) Gaps (non-blocking)

- **LOW** — Chat-start failure in FavoritesScreen: exception is caught and a generic snackbar is shown but the exception is **not** logged. Recommendation: add `AppLogger.e('Chat start failed', tag: 'Favorites', error: e);` in the catch block before showing the snackbar so failures are visible in logs.
- **LOW** — Public profile add/remove: no explicit log at view layer; ViewModel already logs success/failure. Optional: log at VM only is sufficient.

---

## 4) Summary

| Check | Result |
|-------|--------|
| AppLogger used for critical paths | PASS |
| No print() | PASS |
| No raw exception in UI | PASS |
| Privacy (no PII in logs) | PASS |
| Chat-start failure logging | Gap — recommend adding 1 log line in FavoritesScreen catch |

**Observability output**: No BLOCKER. One optional improvement: log chat-start failure in FavoritesScreen.
