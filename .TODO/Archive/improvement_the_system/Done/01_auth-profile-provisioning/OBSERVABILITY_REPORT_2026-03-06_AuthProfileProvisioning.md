# Observability Report: Auth Profile Provisioning

**Date:** 2026-03-06  
**Scope:** Auth Profile Provisioning  
**Agent:** @Observability

---

## 1) What Was Reviewed

- `lib/features/auth/data/auth_repository.dart` (AppLogger usage)
- `lib/features/auth/viewmodels/auth_session_view_model.dart`
- `lib/features/auth/viewmodels/auth_form_view_model.dart`
- Plan requirement: “AppLogger to follow everything”

---

## 2) Event Taxonomy (Current)

| Event | Location | Level | Tag | Sensitive? |
|-------|----------|--------|-----|------------|
| Profile fetch attempt X of Y | AuthRepository | d | Auth | No |
| Profile fetch succeeded on attempt X | AuthRepository | i | Auth | No |
| Profile fetch attempt X failed | AuthRepository | w | Auth | No (error string may contain DB/code; see gap) |
| Waiting Xms before retry | AuthRepository | d | Auth | No |
| Profile fetch failed after X attempts | AuthRepository | w | Auth | No |
| Profile not found after retries - signing out | AuthSessionViewModel | w | Auth | No |
| Failed to load profile | AuthSessionViewModel | e | Auth | No (stack trace server-side only) |
| Profile creation failed after signup - signing out | AuthFormViewModel | w | Auth | No |
| SignUp/SignIn/SignOut (existing) | AuthRepository | i | - | No (email masked via _maskEmail) |

---

## 3) What to Log (Aligned)

- Retry attempt index and max retries.
- Success after N attempts.
- Final failure after all retries.
- Sign-out due to missing profile or exception.
- All auth lifecycle (signUp, signIn, signOut) with masked email.

---

## 4) What NOT to Log (Privacy-Safe)

- Raw email: **enforced** via `_maskEmail()` in AuthRepository.
- User IDs: not logged in new code (only attempt counts and generic messages).
- Tokens: not logged.

**Gap (MED):** In `AuthFormViewModel`, `AppLogger.e('Login failed: $e')` and `AppLogger.e('Registration failed: $e')` interpolate the exception `e` into the message. Exception messages can contain server or internal details. **Recommendation:** Use `AppLogger.e('Login failed', tag: 'Auth', error: e)` (and same for registration) so the message is fixed and the exception is passed as the `error` parameter; avoid `$e` in the message string.

---

## 5) Correlation Strategy

- Tag `'Auth'` used consistently for auth flow logs.
- No correlation ID introduced; scope is single-user auth. For future: if request IDs are added app-wide, auth flows can include them.

---

## 6) Verification

- `grep -r "print(" lib/features/auth/ lib/core/config/ lib/core/constants/` → no `print()` in changed code.
- AppLogger used for all new failure and retry paths.

---

## 7) Recommendations

1. **MED:** In `auth_form_view_model.dart`, replace `AppLogger.e('Login failed: $e')` with `AppLogger.e('Login failed', tag: 'Auth', error: e)` and similarly for registration. Ensures no accidental leakage of exception text into log message.
2. **LOW:** Optionally add a single debug log when `enableProfileFetchRetry` is false and we take the single-attempt path, for traceability.

---

## 8) Verdict

Observability is in place and aligned with plan. One MED fix recommended (no exception interpolation in log message).
