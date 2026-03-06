# Master Report: Auth Profile Provisioning

**Date:** 2026-03-06  
**Scope:** Auth Profile Provisioning  
**Orchestrator:** Pipeline run per `.agents/workflows/orchestrator.md`

---

## A) Executive Summary

| Item | Value |
|------|--------|
| **What was reviewed** | Auth profile provisioning: config/constants, AuthRepository retry, session/form ViewModels, LoginScreen error display, unit tests, DB view/function, pg_cron job, and docs. |
| **Overall risk level** | **LOW** |
| **Final decision** | **Ready** (no BLOCKERs; optional MED fix recommended) |

CodeGuard: **APPROVED**. No pipeline halt.

---

## B) Consolidated Findings (Deduplicated)

### Security

| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| MED | CodeGuard, Observability | `lib/features/auth/viewmodels/auth_form_view_model.dart` | `AppLogger.e('Login failed: $e')` and `AppLogger.e('Registration failed: $e')` interpolate exception into message; can leak server/internal text. | Use `AppLogger.e('Login failed', tag: 'Auth', error: e)` and same for registration; do not put `$e` in message. |

### Data Integrity

- No findings. View, function, and cron are correct and idempotent.

### Architecture / MVVM

| Severity | Owner | Location | Finding | Fix |
|----------|--------|----------|---------|-----|
| LOW | Architect | `lib/features/auth/viewmodels/auth_session_view_model.dart` | Consider clearing `_error` in `logout()` so a subsequent login does not show a stale session error. | Optional: call `clearError()` (or set `_error = null`) inside `logout()`. |

### Performance

- No findings. Bounded retries and cron; no N+1.

### Observability

- MED finding folded into **Security** (same fix: no exception in log message).
- Tag `'Auth'` and masked email are in place; no other gaps.

### Docs / Reference Integrity

- No broken refs or outdated statements. Optional: add short “Profile provisioning retry” subsection to Auth feature doc (LOW).

---

## C) Fix Plan (Ordered)

| Step | Owner | Action | Verification |
|------|--------|--------|--------------|
| 1 | @Observability / dev | In `auth_form_view_model.dart`, replace `AppLogger.e('Login failed: $e')` with `AppLogger.e('Login failed', tag: 'Auth', error: e)` and same for registration. | Grep for `$e` in AppLogger.e in that file → none. |
| 2 | (Optional) | In `AuthSessionViewModel.logout()`, call `clearError()` so error state is cleared on sign-out. | Manual: sign in → trigger profile failure → sign out → sign in again; no stale error. |
| 3 | (Optional) | @SlineDocs: add “Profile provisioning retry” subsection under Auth in DEVELOPER_GUIDE. | Doc scan. |
| 4 | @CodeGuard | Re-run review after Step 1 if desired (no gate required for MED). | Run `flutter analyze` and auth tests. |

---

## D) Regression Checklist

- **Sign up** → profile created or retry → on failure: sign out + message; no crash.
- **Login** → session restore → `getCurrentUserProfileWithRetry()` → on success: home; on null: logout + “Profile provisioning failed” (or configured message).
- **LoginScreen** → after init, if `AuthSessionViewModel.error` is set, SnackBar shows and `clearError()` is called.
- **Orphan sweep** → cron runs every 15 min; `sweep_orphaned_auth_users()` deletes only auth users with no profile and created &gt; 15 min ago.
- **Unit tests:** `flutter test test/unit/auth/ test/widget/` (or full `flutter test`) — all pass.

---

## E) Rollback Notes

| Area | Rollback |
|------|----------|
| **App (Dart)** | Revert commits for auth_config, auth_messages, auth_repository (retry + _fetchProfileOnce), auth_session_view_model, auth_form_view_model, login_screen. Restore previous `getCurrentUserProfile()` behavior if it previously threw. |
| **DB – view/function** | Drop function `sweep_orphaned_auth_users`, drop view `vw_orphaned_auth_users` (migration 20260306120000). No data loss. |
| **DB – cron** | Unschedule job `sweep-orphaned-auth-users` (e.g. `SELECT cron.unschedule('sweep-orphaned-auth-users');`). Optionally disable pg_cron if not used elsewhere. |
| **Docs** | Revert doc edits in SUPABASE_SETUP, DEVELOPER_GUIDE, Sline_Log. |

---

## Agent Report Index

- `.TODO/ARCHITECT_REPORT_2026-03-06_AuthProfileProvisioning.md`
- `.TODO/OBSERVABILITY_REPORT_2026-03-06_AuthProfileProvisioning.md`
- `.TODO/DOCS_REPORT_2026-03-06_AuthProfileProvisioning.md`
- `.TODO/CODEGUARD_REVIEW_2026-03-06_AuthProfileProvisioning.md`

Pipeline **complete**. No BLOCKER; optional MED fix and LOW improvements can be applied when convenient.
