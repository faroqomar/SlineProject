# 📌 Plan: Auth & Profile Provisioning Implementation

**Date**: 2026-03-06  
**Source**: `.TODO/improvement_the_system/ImplementReady/01_auth-profile-provisioning`  
**Planner**: @SlinePlanner

---

## 1) Goal

- **Goal**: Harden the auth-profile provisioning flow to eliminate race conditions, orphaned users, and session restore bypass vulnerabilities.
- **Why**: Current implementation has critical gaps: profile fetch race condition on signup, orphaned auth users when triggers fail, and missing AccountGuard check on session restore (cold start).
- **Result**: Production-ready auth flow with retry logic, proper failure handling, automated orphaned user cleanup, and comprehensive security checks on all entry paths.

---

## 2) Scope

### In-Scope

1. **Race Condition Fix**: Implement profile polling/retry mechanism in `AuthSessionViewModel` with max 3 retries and 500ms backoff.
2. **Failure Policy**: Add `signOut()` fallback when profile provisioning fails after retries.
3. **Session Restore Guard**: Ensure `AccountGuardService.evaluateCurrentUser()` is called on cold start (app resume/lifecycle).
4. **Orphaned User Cleanup**: Create PostgreSQL `pg_cron` job to sweep orphaned `auth.users` without profiles after 15 minutes.
5. **RLS Verification**: Confirm `profiles` SELECT policy allows new users to read their own row immediately.
6. **Observability**: Add structured logging for provisioning attempts, failures, and sweeps.

### Out-of-Scope

1. UI redesign (screens remain same, only logic changes)
2. New registration methods (social auth, OTP)
3. Profile schema changes (no new columns)
4. Admin dashboard for user management
5. Email verification flow changes
6. Password policy modifications

---

## 3) Evidence & Findings (From Scan)

### Existing (Files + Code Patterns)

| Component | Location | Current State |
|-----------|----------|---------------|
| `AccountGuardService` | `lib/core/services/account_guard_service.dart` | ✅ Exists, implements `evaluateCurrentUser()` with ban/suspend/revoke checks |
| `AuthFormViewModel` | `lib/features/auth/viewmodels/auth_form_view_model.dart` | ✅ Calls `AccountGuardService` on login (line 55-69), but NO retry logic on signup |
| `AuthSessionViewModel` | `lib/features/auth/viewmodels/auth_session_view_model.dart` | ✅ Exists, calls `_loadInitialProfile()` on init, but NO retry on `PostgrestException` |
| `AuthRepository` | `lib/features/auth/data/auth_repository.dart` | ✅ `signUp()` exists (line 10-34), `getCurrentUserProfile()` exists but uses `.single()` (throws if no row) |
| `ProfileRepository` | `lib/features/profile/data/profile_repository.dart` | ✅ `fetchProfile()` exists, uses `.single()` (line 35-44) |
| Session Restore Guard | `lib/main.dart` | ✅ `_runAccountGuards()` exists (line 412-468), called on `initState` and `didChangeAppLifecycleState` |

### Existing (Live DB Schema - from SUPABASE_SETUP.md)

| Object | State | Notes |
|--------|-------|-------|
| `auth.users` | ✅ Exists | Supabase managed |
| `public.profiles` | ✅ Exists | PK `id` FK to `auth.users(id) ON DELETE CASCADE` |
| Profile trigger | ⚠️ Assumed | Documentation states trigger creates profile on auth signup |
| `pg_cron` extension | ❓ Unknown | Required for orphan sweep |
| Orphan cleanup job | ❌ Missing | Must create |

### Missing

| Item | Impact | Priority |
|------|--------|----------|
| Profile fetch retry loop | High - Race condition on signup | P0 |
| `signOut()` on max retry failure | High - Prevents corrupt state | P0 |
| Orphaned user sweeper cron | Medium - Data hygiene, user recovery | P1 |
| Structured provisioning logs | Medium - Debugging, monitoring | P2 |

### Conflicts / Risks

| Risk | Description | Mitigation |
|------|-------------|------------|
| **Trigger latency** | Profile creation trigger may lag 50-500ms in production | Retry loop handles up to 1500ms total |
| **Trigger failure** | Constraint violations in trigger abort auth transaction | Test trigger thoroughly; orphan sweep as backup |
| **Cold start bypass** | Banned users with valid cached tokens can access app | `_runAccountGuards()` now runs on lifecycle resume |
| **RLS policy race** | New user can't SELECT their profile before trigger commits | Standard Supabase behavior - trigger is synchronous transaction |

---

## 4) System Impact Map

- **UI**: No changes. Existing `LoginScreen`, `SignupScreen`, `MainNavigationScreen` remain. Only error messages may improve.
- **MVVM/App Logic**: 
  - `AuthSessionViewModel`: Add retry logic in `_loadInitialProfile()`
  - `AuthFormViewModel`: Add post-signup profile polling
  - `AuthRepository`: Add `getCurrentUserProfileWithRetry()` method
- **Database**: 
  - Add `pg_cron` extension (if not exists)
  - Create `sweep_orphaned_auth_users()` function
  - Schedule cron job to run every 15 minutes
- **RLS/Security**: No changes required. Existing `profiles` SELECT policy `(id = auth.uid())` is correct.
- **Realtime/Notifications**: No changes.
- **Storage**: No changes.
- **Observability**: 
  - Add log events: `profile_fetch_retry`, `profile_fetch_success`, `profile_fetch_failed`, `orphan_sweep_count`
- **Compatibility & Migration**: 
  - Zero breaking changes
  - New retry logic is additive
  - Existing users unaffected
- **Contracts**: No API contract changes.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable)
  - All existing auth flows (login, signup, logout) continue to work
  - New signup race condition resolved (test with 1000ms artificial delay)
  - Banned user cold start interception works
- [ ] (@Architect) Confirm modules/entry points
  - Entry: `lib/features/auth/viewmodels/auth_session_view_model.dart`
  - Entry: `lib/features/auth/viewmodels/auth_form_view_model.dart`
  - Entry: `lib/features/auth/data/auth_repository.dart`
- **Verify (@Sentinel):** done-conditions + rollback triggers

### 0.2 Threat Model

- [ ] (@ThreatModeler) Review current threat model from `01_auth-profile-provisioning/03_RISK_REGISTER.md`
  - Risk J1-1: Race condition on profile fetch (HIGH)
  - Risk J1-2: Silent trigger failure - orphaned user (HIGH)
  - Risk J1-3: Session restore bypass (CRITICAL)
- **Verify (@Sentinel):** All risks addressed in implementation plan

### 0.3 Contracts

- [ ] (@APIContract) No new contracts required - internal changes only
- **Verify (@Sentinel):** N/A for this internal refactor

### 0.4 Migration Plan

- [ ] (@DataMigration) SQL migration for orphan sweeper:
  - Enable `pg_cron` extension
  - Create `sweep_orphaned_auth_users()` function
  - Schedule `SELECT cron.schedule('0/15 * * * *', 'SELECT sweep_orphaned_auth_users()');`
- **Verify (@Sentinel):** Migration is additive, no data loss risk

### 0.5 Feature Flag/Rollout

- [ ] (@Architect) Toggle strategy: Use `AppLogger` feature flag to disable retry logging in production if needed
- **Verify (@Sentinel):** Rollback path = revert to previous `single()` call without retry

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation

- [ ] (@Supabase_Ops) Confirm `profiles` table structure:
  ```sql
  SELECT column_name, data_type, is_nullable 
  FROM information_schema.columns 
  WHERE table_name = 'profiles' AND table_schema = 'public';
  ```
- [ ] (@Supabase_Ops) Confirm profile creation trigger exists:
  ```sql
  SELECT tgname, pg_get_triggerdef(oid) 
  FROM pg_trigger 
  WHERE tgrelid = 'auth.users'::regclass;
  ```
- [ ] (@Supabase_Ops) Verify RLS policies on `profiles`:
  ```sql
  SELECT policyname, permissive, roles, cmd, qual 
  FROM pg_policies 
  WHERE tablename = 'profiles' AND schemaname = 'public';
  ```
- **Verify (@Sentinel):** drift + safe approach recorded

### 1.1 Schema (Additive)

- [ ] (@Supabase_Ops) Create orphan sweeper function:
  ```sql
  CREATE OR REPLACE FUNCTION sweep_orphaned_auth_users()
  RETURNS integer AS $$
  DECLARE
    deleted_count integer;
  BEGIN
    DELETE FROM auth.users 
    WHERE id NOT IN (SELECT id FROM public.profiles) 
    AND created_at < NOW() - INTERVAL '15 minutes';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log for monitoring (optional, if logging extension available)
    RAISE NOTICE 'Swept % orphaned auth users', deleted_count;
    
    RETURN deleted_count;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;
  ```
- **Verify (@Sentinel):** Function created and returns correct count

### 1.2 RLS (Verification)

- [ ] (@Supabase_Ops) Verify existing SELECT policy:
  ```sql
  -- Expected: users can only select their own profile
  -- Policy: CREATE POLICY "Users can view own profile" ON profiles
  --         FOR SELECT USING (auth.uid() = id);
  ```
- [ ] (@Supabase_Ops) Create RLS check matrix file in `.TODO/rls_check_matrix_auth.md`
- **Verify (@Sentinel):** Negative fails (user A cannot read user B profile), positive passes

### 1.3 Triggers/RPC (Orphan Sweeper)

- [ ] (@Supabase_Ops) Enable `pg_cron` extension if not exists:
  ```sql
  CREATE EXTENSION IF NOT EXISTS pg_cron;
  ```
- [ ] (@Supabase_Ops) Schedule orphan sweep job:
  ```sql
  SELECT cron.schedule(
    'sweep-orphaned-auth-users',
    '*/15 * * * *',
    'SELECT sweep_orphaned_auth_users()'
  );
  ```
- [ ] (@Supabase_Ops) Verify job scheduled:
  ```sql
  SELECT * FROM cron.job WHERE jobname = 'sweep-orphaned-auth-users';
  ```
- **Verify (@Sentinel):** Job appears in cron.job table

### 1.4 Migration Execution

- [ ] (@DataMigration) Run SQL migration file: `supabase/migrations/20260306120000_auth_profile_orphan_sweeper.sql`
- [ ] (@DataMigration) Record migration in `supabase/migrations/_journal.md`
- **Verify (@Sentinel):** Run `SELECT sweep_orphaned_auth_users();` returns 0 (no orphans yet)

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) No model changes required - existing `UserProfile`, `ProfileModel` sufficient
- **Verify (@Sentinel):** types/nullability match existing contracts

### 2.2 Services/Repositories

- [ ] (@Architect) Add retry method to `AuthRepository`:
  ```dart
  // lib/features/auth/data/auth_repository.dart
  
  /// Fetches current user profile with retry logic for race condition handling.
  /// Retries up to [maxRetries] times with [retryDelay] between attempts.
  Future<UserProfile?> getCurrentUserProfileWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async { ... }
  ```
- [ ] (@Architect) Add private helper `_fetchProfileOnce()` for single attempt
- **Verify (@Sentinel):** No UI→Supabase direct calls, all via repository

### 2.3 ViewModels

- [ ] (@Architect) Update `AuthSessionViewModel._loadInitialProfile()`:
  ```dart
  Future<void> _loadInitialProfile() async {
    if (!isAuthenticated) return;
    _isLoading = true;
    notifyListeners();
    
    try {
      // Use retry logic to handle race condition with DB trigger
      _currentUserProfile = await _authRepo.getCurrentUserProfileWithRetry(
        maxRetries: 3,
        retryDelay: const Duration(milliseconds: 500),
      );
      
      if (_currentUserProfile == null) {
        AppLogger.w('Profile not found after retries - signing out', tag: 'Auth');
        await logout();
        _error = 'Account provisioning failed. Please try again.';
      }
    } catch (e, st) {
      AppLogger.e('Failed to load profile', tag: 'Auth', error: e, stackTrace: st);
      await logout();
      _error = 'Authentication error. Please sign in again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  ```
- [ ] (@Architect) Add `_error` field to `AuthSessionViewModel` with getter
- [ ] (@Architect) Update `AuthFormViewModel.register()` to use retry after signup:
  ```dart
  Future<bool> register({...}) async {
    // ... existing signup code ...
    
    if (success) {
      // Wait for profile creation with retry
      final profile = await _authRepo.getCurrentUserProfileWithRetry();
      if (profile == null) {
        await _authRepo.signOut();
        _setError('Account creation failed. Please try again.');
        return false;
      }
    }
    return success;
  }
  ```
- **Verify (@Sentinel):** recoverable state + correct transitions (no infinite loops)

### 2.4 Observability

- [ ] (@Observability) Instrument `AuthRepository.getCurrentUserProfileWithRetry()`:
  ```dart
  AppLogger.d('Profile fetch attempt $attempt/$maxRetries', tag: 'Auth');
  // ... on success ...
  AppLogger.i('Profile fetch succeeded after $attempt attempt(s)', tag: 'Auth');
  // ... on final failure ...
  AppLogger.w('Profile fetch failed after $maxRetries attempts', tag: 'Auth');
  ```
- [ ] (@Observability) Instrument `AuthSessionViewModel` state transitions:
  ```dart
  AppLogger.i('Auth state: $event, user: ${user?.id}', tag: 'Auth');
  ```
- **Verify (@Sentinel):** no sensitive data in logs (email masked like existing `_maskEmail`)

---

## Phase 3: UI (After Logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Verify `LoginScreen` and `SignupScreen` already use `Consumer<AuthFormViewModel>`
- [ ] (@Pixel) Verify `MainNavigationScreen` checks `AuthSessionViewModel.isLoading` and `currentUserProfile != null`
- [ ] (@Pixel) Add error display for `AuthSessionViewModel.error` in relevant screens
- **Verify (@Sentinel):** stable UX on slow/empty data (test with throttled connection)

### 3.2 Polish

- [ ] (@Pixel) Optional: Add loading indicator text "Setting up your account..." during signup retry loop
- **Verify (@Sentinel):** no perf regression

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Verify SQL migration applied: `SELECT * FROM cron.job;`
- [ ] (@Sentinel) Verify no breaking changes to `UserProfile` model
- **Verify (@Sentinel):** no mismatch

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) RLS leak audit:
  ```sql
  -- As user A, attempt to read user B's profile
  -- Should return 0 rows or RLS error
  ```
- [ ] (@Sentinel) Test banned user cold start interception:
  1. Login as test user
  2. Ban user in admin (set `account_status = 'banned'`)
  3. Kill app
  4. Reopen app
  5. Verify redirected to `AccountRestrictedScreen`
- [ ] (@Sentinel) Test profile race condition:
  1. Temporarily add `pg_sleep(2)` to profile creation trigger
  2. Sign up new user
  3. Verify retry loop waits and eventually succeeds
- **Verify (@Sentinel):** unauthorized access impossible

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E script:
  - [ ] New user signup → profile created → dashboard visible
  - [ ] Existing user login → profile loaded → dashboard visible
  - [ ] Session restore (cold start) → profile loaded → dashboard visible
  - [ ] Logout → login screen shown
  - [ ] Banned user login → restricted screen shown
- [ ] (@Sentinel) Edge cases:
  - [ ] Network loss during signup retry
  - [ ] App killed during signup retry
  - [ ] Server error (500) during profile fetch
- **Verify (@Sentinel):** no crashes, consistent behavior

### 4.4 Observability Validation

- [ ] (@Sentinel) Verify logs appear in console/logcat:
  - `Profile fetch attempt 1/3`
  - `Profile fetch succeeded after 2 attempt(s)`
  - `Profile fetch failed after 3 attempts`
- [ ] (@Sentinel) Verify no email addresses in logs (only masked)
- **Verify (@Sentinel):** actionable telemetry without leaks

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md`:
  - Add `pg_cron` extension note
  - Document `sweep_orphaned_auth_users()` function
- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md`:
  - Document auth retry logic behavior
  - Document AccountGuard cold start check
- [ ] (@SlineDocs) Update `.cursor/PROJECT_CONTEXT.md` if auth flow summary exists
- [ ] (@SlineDocs) Add changelog entry to `Sline_everything/Sline_Log.md`
- **Verify (@Sentinel):** docs match code + live DB reality

---

## 7) Acceptance Criteria (MANDATORY)

### Correctness
- [ ] New user signup succeeds even with 1000ms artificial DB trigger delay
- [ ] Profile fetch retry loop attempts exactly 3 times before failing
- [ ] On max retry failure, user is signed out and shown error message
- [ ] Existing user login flow unchanged
- [ ] Session restore (cold start) loads profile successfully

### Security
- [ ] Banned user cannot access app via session restore
- [ ] Suspended user shown appropriate message on cold start
- [ ] RLS policy prevents reading other users' profiles
- [ ] Orphaned auth users older than 15 minutes are auto-deleted

### UX Stability
- [ ] No UI crashes during network delays
- [ ] Loading states clearly indicate progress
- [ ] Error messages are user-friendly (not technical)

### Performance
- [ ] Profile fetch completes within 2 seconds (including retries)
- [ ] No N+1 queries introduced
- [ ] Cron job runs efficiently (scans only auth.users > 15 min old)

### Compatibility
- [ ] Zero breaking changes to existing auth flows
- [ ] Existing logged-in users unaffected
- [ ] Rollback possible by reverting to `.single()` without retry

---

## 8) Rollback Plan

### DB Rollback
```sql
-- Remove cron job
SELECT cron.unschedule('sweep-orphaned-auth-users');

-- Remove function (optional - safe to keep)
-- DROP FUNCTION IF EXISTS sweep_orphaned_auth_users();
```

### App Rollback
1. Revert `AuthRepository` to use `.single()` instead of `.getCurrentUserProfileWithRetry()`
2. Revert `AuthSessionViewModel._loadInitialProfile()` to direct call without retry
3. Revert `AuthFormViewModel.register()` to skip post-signup profile polling
4. Deploy previous version

### Emergency Disable
- If retry logic causes issues: Set `maxRetries: 1` in `AuthSessionViewModel` to effectively disable retry
- If orphan sweep causes issues: `SELECT cron.unschedule('sweep-orphaned-auth-users');` immediate effect

---

## 9) References

### Documentation
- `Sline_everything/DEVELOPER_GUIDE.md` - Feature documentation, MVVM patterns
- `Sline_everything/SUPABASE_SETUP.md` - Database schema, RLS policies, triggers
- `Sline_everything/STRUCTURE.md` - File organization guide
- `.TODO/improvement_the_system/ImplementReady/01_auth-profile-provisioning/00_HOLISTIC_REPORT.md` - Full analysis
- `.TODO/improvement_the_system/ImplementReady/01_auth-profile-provisioning/06_DIAGRAM_FINAL.md` - Sequence diagram
- `.TODO/improvement_the_system/ImplementReady/01_auth-profile-provisioning/03_RISK_REGISTER.md` - Risk analysis

### Code Files (Scanned)
- `lib/core/services/account_guard_service.dart` - Guard service implementation
- `lib/features/auth/viewmodels/auth_form_view_model.dart` - Login/register logic
- `lib/features/auth/viewmodels/auth_session_view_model.dart` - Session management
- `lib/features/auth/data/auth_repository.dart` - Auth API calls
- `lib/features/profile/data/profile_repository.dart` - Profile data access
- `lib/main.dart` - App entry, AccountGuard integration on cold start

### Test Plan
- `.TODO/improvement_the_system/ImplementReady/01_auth-profile-provisioning/04_TEST_PLAN.md`
