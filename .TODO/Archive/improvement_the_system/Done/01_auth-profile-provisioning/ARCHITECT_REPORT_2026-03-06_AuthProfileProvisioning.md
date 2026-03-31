# Architect Report: Auth Profile Provisioning

**Date:** 2026-03-06  
**Scope:** Auth Profile Provisioning (PLAN_AuthProfileProvisioning_CRITIC_2026-03-06.md)  
**Agent:** @Architect

---

## 1) Plan Reference

- Plan: `.TODO/PLAN_AuthProfileProvisioning_CRITIC_2026-03-06.md`
- Execution log: `.TODO/EXECUTION_LOG_AuthProfileProvisioning_CRITIC.md`

---

## 2) Files Scanned (Evidence)

| Path | Role |
|------|------|
| `lib/core/config/auth_config.dart` | Config constants |
| `lib/core/constants/auth_messages.dart` | User-facing strings |
| `lib/features/auth/data/auth_repository.dart` | Repository (data layer) |
| `lib/features/auth/viewmodels/auth_session_view_model.dart` | Session VM |
| `lib/features/auth/viewmodels/auth_form_view_model.dart` | Form VM |
| `lib/features/auth/view/login_screen.dart` | View (UI) |
| `test/unit/auth/auth_repository_test.dart` | Unit tests |
| `supabase/migrations/20260306120000_auth_profile_orphan_sweeper.sql` | View + function |
| `supabase/migrations/20260306120100_pg_cron_orphan_sweeper_schedule.sql` | Cron schedule |

---

## 3) MVVM Boundary Check

| Layer | Status | Evidence |
|-------|--------|----------|
| **View** | PASS | `login_screen.dart` only uses `context.read<AuthSessionViewModel>()`, `Consumer`/form VM; no `Supabase.instance` or direct DB calls. |
| **ViewModel** | PASS | `AuthSessionViewModel` and `AuthFormViewModel` call only `AuthRepository` and `AccountGuardService`; no direct `.from('profiles')`. Default constructor uses `Supabase.instance.client` only for bootstrap (auth stream, guard client)—acceptable per project pattern. |
| **Repository** | PASS | All Supabase access in `AuthRepository`; optional `SupabaseClient` for tests. |

**Finding:** No MVVM violations. Data flow is View → ViewModel → Repository → Supabase.

---

## 4) Data Flow Map

```
LoginScreen / SignupScreen
    → AuthFormViewModel.login() / register()
        → AuthRepository.signIn() / signUp()
        → AuthRepository.getCurrentUserProfileWithRetry() (after signUp)
        → AccountGuardService.evaluateCurrentUser() (login only)

main.dart _runAccountGuards() + auth state
    → AuthSessionViewModel._loadInitialProfile()
        → AuthRepository.getCurrentUserProfileWithRetry()
        → on null: logout(), _error = AuthMessages.profileProvisioningFailed
```

Single source of truth for “current user profile” after auth: `AuthSessionViewModel.currentUserProfile` loaded via `getCurrentUserProfileWithRetry()`.

---

## 5) Contract Checks

| Contract | Status |
|----------|--------|
| `UserProfile.fromMap()` | Used with `.maybeSingle()` response; map shape matches existing `profiles` select (id, full_name, email, avatar_url, account_status, etc.). |
| `AuthConfig` / `AuthMessages` | Referenced only from auth feature; no cross-feature coupling. |
| Auth repository constructor | `AuthRepository({SupabaseClient? client})`—optional client used in tests only. |

---

## 6) Proposed Refactors / Notes

- **MED** – `AuthFormViewModel.login` and `register` catch blocks log `'Login failed: $e'` / `'Registration failed: $e'`. Prefer not logging raw exception string (could contain server messages); use `AppLogger.e(..., error: e)` without interpolating `e` into message, or use a generic message. Assign to @Observability for consistency.
- **LOW** – Consider clearing `AuthSessionViewModel._error` in `logout()` so a subsequent login does not show a stale session error. Currently `clearError()` is only called from LoginScreen when the SnackBar is shown; if user never opens LoginScreen after session failure, next app open could still show the error when they do—acceptable but could be refined.

---

## 7) Path Validation

- All referenced files exist.
- `AuthConfig`, `AuthMessages` paths match imports.
- Supabase objects (view `vw_orphaned_auth_users`, function `sweep_orphaned_auth_users`) exist and are documented in SUPABASE_SETUP.md.

---

## 8) Verdict

**Architecture:** Compliant. No blockers. One MED recommendation (logging) and one LOW (error clear on logout).
