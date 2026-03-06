# CodeGuard Review: Auth Profile Provisioning

**Date:** 2026-03-06  
**Scope:** Auth Profile Provisioning  
**Agent:** @CodeGuard

---

## 1) Scope Reviewed

- `lib/core/config/auth_config.dart`
- `lib/core/constants/auth_messages.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/viewmodels/auth_session_view_model.dart`
- `lib/features/auth/viewmodels/auth_form_view_model.dart`
- `lib/features/auth/view/login_screen.dart`
- `test/unit/auth/auth_repository_test.dart`
- `supabase/migrations/20260306120000_auth_profile_orphan_sweeper.sql`
- `supabase/migrations/20260306120100_pg_cron_orphan_sweeper_schedule.sql`

---

## 2) Security

| Check | Result | Evidence |
|-------|--------|----------|
| No secrets in code | PASS | No keys or tokens. |
| RLS / DB | PASS | View and function use `public.profiles` and 15-minute filter; function is SECURITY DEFINER with explicit search_path. |
| Auth flow | PASS | Guard on login and cold start; signOut on profile failure. |
| Logging | MED | `AuthFormViewModel`: `AppLogger.e('Login failed: $e')` and similar—exception text in message; prefer `error: e` only. Not a BLOCKER. |

No BLOCKERs. One MED (log message content).

---

## 3) Performance

| Check | Result |
|-------|--------|
| N+1 | PASS – single profile fetch per user, retry loop bounded (3 attempts). |
| Rebuilds | PASS – ViewModels notifyListeners on state change only. |
| Cron | PASS – job every 15 min; query restricted by 15-minute interval. |

No issues.

---

## 4) Compatibility

| Check | Result |
|-------|--------|
| AuthRepository constructor | Optional `client` is backward-compatible; default `Supabase.instance.client`. |
| getCurrentUserProfile() | Now returns `Future<UserProfile?>` via `_fetchProfileOnce()` (no throw on missing row); callers (session VM) use retry path. |
| Existing tests | Widget auth tests pass with try/catch for missing AuthSessionViewModel. |

No breaking changes identified.

---

## 5) Risk Rating

| Area | Rating | Note |
|------|--------|------|
| Security | LOW | No RLS/auth regressions; one logging improvement. |
| Data integrity | LOW | Orphan sweep and view are correct; cron idempotent. |
| Performance | LOW | Bounded retries and cron. |
| Compatibility | LOW | Backward compatible. |

**Overall risk:** LOW.

---

## 6) Verification Commands

```bash
flutter analyze lib/features/auth/ lib/core/config/ lib/core/constants/
flutter test test/unit/auth/ test/widget/auth/
```

Pre-existing lints in `reset_password_update_screen.dart` only; no new issues in reviewed files.

---

## 7) Blockers

**None.**

---

## 8) Decision

**APPROVED**

Proceed with optional MED fix (log message in AuthFormViewModel) when convenient. No BLOCKER; no gate halt.
