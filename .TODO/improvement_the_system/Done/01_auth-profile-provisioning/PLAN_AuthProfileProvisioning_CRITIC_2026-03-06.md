# @PlanCritic Audit: Auth & Profile Provisioning Implementation

**Original Plan**: `PLAN_AuthProfileProvisioning_2026-03-06.md`  
**Date**: 2026-03-06  
**Auditor**: @PlanCritic

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred Safe Defaults)

1. **pg_cron is available on Supabase project** - Supabase typically enables this on paid tiers; assumed available.
2. **Auth trigger `on_auth_user_created` is functioning** - Migration `20260301_auth_profile_bootstrap.sql` confirms it exists with `ON CONFLICT DO NOTHING` safety.
3. **Test infrastructure exists** - Found 63+ test files in `test/` directory with existing patterns for unit/widget/integration tests.
4. **No breaking schema changes required** - Current `profiles` table structure from SUPABASE_SETUP.md matches requirements.
5. **AccountGuardService is already integrated** - Evidence in `main.dart` shows `_runAccountGuards()` called on initState and lifecycle resume.

### Decision Needed (Blocking)

#### Decision 1: pg_cron Availability
- **What**: Is `pg_cron` enabled on the Supabase project `isddrknbjsgaantjojhm`?
- **Options**:
  - A) Yes, available - proceed with cron-based orphan sweep
  - B) No, not available - implement alternative (e.g., edge function triggered by external scheduler)
- **Recommended**: A (verify first with `SELECT * FROM pg_available_extensions WHERE name = 'pg_cron';`)
- **Plan Change if B**: Replace Phase 1.3 with Edge Function approach

#### Decision 2: Test Data Strategy
- **What**: How to test race condition artificially in CI?
- **Options**:
  - A) Add `pg_sleep()` to test migration only (clean rollback after test)
  - B) Use mock/stub in Flutter tests to simulate delay
  - C) Skip artificial delay testing, rely on production monitoring
- **Recommended**: B (keeps DB clean, deterministic)
- **Plan Change**: Add `AuthRepository.getCurrentUserProfileWithRetry()` test with mocked client delay

#### Decision 3: Retry Configuration
- **What**: Should retry parameters be configurable per environment?
- **Options**:
  - A) Hardcoded constants (3 retries, 500ms) - simpler
  - B) Environment-based config (different for dev/staging/prod)
- **Recommended**: A for now (complexity not justified)
- **Plan Change**: Document constants clearly for future extraction

---

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
**Status**: ⚠️ PARTIAL (needs attention before execution)

| Check | Status | Notes |
|-------|--------|-------|
| Test harness exists | ✅ | `test/test_support/pump_app.dart` exists |
| Unit test patterns | ✅ | 30+ unit tests in `test/unit/` |
| Widget test patterns | ✅ | 15+ widget tests in `test/widget/` |
| Integration test support | ✅ | `test/integration_test/` exists with helpers |
| **Auth-specific test coverage** | ❌ | `test/widget/auth/login_screen_test.dart` exists but minimal; no retry logic tests |
| **Mock/stub for Supabase** | ❌ | Not clear if `mocktail` or similar is configured for Supabase client mocking |

**To Fix**:
1. Verify `pubspec.yaml` has `mocktail` or equivalent for mocking
2. Add `test/unit/auth/auth_repository_test.dart` skeleton
3. Document Supabase mocking pattern in test README

---

### Gate 1: Data/Contracts Gate
**Status**: ✅ PASS

| Check | Status | Evidence |
|-------|--------|----------|
| Table schema exists | ✅ | `profiles` in SUPABASE_SETUP.md |
| Trigger exists | ✅ | `20260301_auth_profile_bootstrap.sql` - `handle_new_user()` |
| RPC for self-heal exists | ✅ | `rpc_ensure_self_profile()` exists |
| Contracts stable | ✅ | `UserProfile` model already used |

---

### Gate 2: Security Gate
**Status**: ⚠️ PARTIAL (verification needed)

| Check | Status | Notes |
|-------|--------|-------|
| RLS enabled on profiles | ✅ | Documented in SUPABASE_SETUP.md |
| SELECT policy correct | ⚠️ | Assumed `USING (id = auth.uid())` - verify live |
| Orphan sweep security | ✅ | Uses `SECURITY DEFINER` correctly |
| Cron job access control | ⚠️ | Ensure only supabase_admin can modify jobs |

**To Fix**:
1. Add Phase 1.0 step to verify actual RLS policies via live query
2. Document cron job permissions

---

### Gate 3: Backend/API Gate
**Status**: ✅ PASS

| Check | Status | Notes |
|-------|--------|-------|
| No new backend APIs needed | ✅ | All changes in Flutter layer |
| Existing RPC sufficient | ✅ | `rpc_ensure_self_profile()` as fallback |

---

### Gate 4: UI/Integration Gate
**Status**: ✅ PASS

| Check | Status | Notes |
|-------|--------|-------|
| UI already wired to ViewModels | ✅ | `Consumer<AuthSessionViewModel>` patterns exist |
| Error display exists | ✅ | `_error` field already in `AuthFormViewModel` |
| Loading states exist | ✅ | `_isLoading` patterns established |

---

### Gate 5: Release/QA Gate
**Status**: ❌ FAIL (missing test specifications)

| Check | Status | Notes |
|-------|--------|-------|
| Test plan documented | ✅ | `04_TEST_PLAN.md` exists in source folder |
| Test data fixtures defined | ❌ | No deterministic test user setup |
| Rollback procedure | ⚠️ | Documented but needs validation test |
| Monitoring/alerts | ❌ | No log-based alerts specified |

**To Fix**:
1. Add test fixture manifest for auth tests
2. Define log query for orphan sweep monitoring

---

## C) Critical Gaps (Must-Fix)

### Gap 1: Missing pg_cron Verification Step
| | Details |
|--|---------|
| **Gap** | No step to verify `pg_cron` is available before attempting to use it |
| **Why it will break** | Migration fails on `CREATE EXTENSION` or `SELECT cron.schedule()` if extension unavailable |
| **Fix** | Add Phase 1.0 verification: `SELECT * FROM pg_available_extensions WHERE name = 'pg_cron';` |
| **Owner** | @Supabase_Ops |
| **Acceptance** | Query returns row with `installed = true` |

### Gap 2: No Test Mock Infrastructure for Retry Logic
| | Details |
|--|---------|
| **Gap** | No documented way to test retry behavior without modifying production DB |
| **Why it will break** | Cannot write deterministic tests for race condition handling; test flakiness |
| **Fix** | Add `test/unit/auth/auth_repository_test.dart` with mocked Supabase client that returns null then success |
| **Owner** | @Architect |
| **Acceptance** | Test passes with mocked 2-failure-then-success scenario |

### Gap 3: Missing RLS Live Verification
| | Details |
|--|---------|
| **Gap** | Plan assumes RLS policies without verifying live state |
| **Why it will break** | If policies differ from docs, new users may get permission denied on profile fetch |
| **Fix** | Add explicit Phase 1.2 step: Query `pg_policies` for `profiles` and verify exact policy text |
| **Owner** | @Supabase_Ops |
| **Acceptance** | Policy text matches: `(id = auth.uid())` for SELECT |

### Gap 4: No Monitoring for Orphan Sweep
| | Details |
|--|---------|
| **Gap** | No way to know if sweeper is working or if orphans are accumulating |
| **Why it will break** | Silent failure mode - orphans pile up, user complaints about "email taken" |
| **Fix** | Add logging to sweeper function; create view `vw_orphaned_auth_users_count`; document monitoring query |
| **Owner** | @Supabase_Ops + @Observability |
| **Acceptance** | Query `SELECT * FROM vw_orphaned_auth_users_count` returns count, sweeper logs visible |

### Gap 5: Unclear Error Message Handling
| | Details |
|--|---------|
| **Gap** | UI error display exists but no specification of exact user-facing messages |
| **Why it will break** | Generic "something went wrong" messages confuse users; support burden |
| **Fix** | Define exact strings in constants; add i18n keys if applicable |
| **Owner** | @Pixel |
| **Acceptance** | Messages are specific: "Account setup in progress...", "Account creation failed. Please try again." |

### Gap 6: Missing Feature Flag for Retry Logic
| | Details |
|--|---------|
| **Gap** | No way to disable retry logic if it causes issues in production |
| **Why it will break** | If retry loop has bug, cannot quickly disable without code deploy |
| **Fix** | Add `AuthConfig` class with `enableProfileFetchRetry` flag (default true) |
| **Owner** | @Architect |
| **Acceptance** | Flag exists in `lib/core/config/auth_config.dart`, referenced in `AuthRepository` |

---

## D) Invariants & Success Criteria (Non-Negotiable)

### Invariant 1: 1:1 Auth-to-Profile Relationship
- **Statement**: Every active session MUST have exactly one profile row accessible via `auth.uid() = profiles.id`
- **Enforce**: DB trigger `handle_new_user()` + orphan sweeper + app retry logic
- **Verify**: Query `SELECT COUNT(*) FROM auth.users u LEFT JOIN profiles p ON u.id = p.id WHERE p.id IS NULL AND u.created_at < NOW() - INTERVAL '1 hour'` returns 0

### Invariant 2: Banned User Session Invalidation
- **Statement**: Users with `account_status = 'banned'` or `'suspended'` cannot access app features
- **Enforce**: `AccountGuardService.evaluateCurrentUser()` called on: login, session restore, app resume
- **Verify**: Integration test: set status to banned, trigger session restore, verify redirect to `AccountRestrictedScreen`

### Invariant 3: No Infinite Retry Loops
- **Statement**: Profile fetch retry MUST terminate after bounded attempts with clean signOut
- **Enforce**: Code review - maxRetries hardcoded, no while-loop without counter
- **Verify**: Unit test with mocked infinite-failure returns null after max attempts, calls signOut

### Invariant 4: No Direct UI→Supabase Calls
- **Statement**: All Supabase calls MUST go through Repository layer, not ViewModels directly (MVVM)
- **Enforce**: Architecture guard - no `Supabase.instance.client` imports in `viewmodels/` except via Repository
- **Verify**: `grep -r "Supabase.instance" lib/features/auth/viewmodels/` returns only Repository injection points

### Invariant 5: Sensitive Data Not Logged
- **Statement**: Email addresses and user IDs must never appear in logs unmasked
- **Enforce**: Code review - use existing `_maskEmail()` pattern, UUIDs truncated
- **Verify**: Log inspection shows masked emails (e.g., "jo***@example.com")

---

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast Radius | Early Signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|-------------|-----------|----------|
| pg_cron not available | Phase 1.3 | Low | High | DB layer | Migration fails | Pre-verify extension availability | Edge Function sweeper fallback |
| Trigger latency >1.5s | Phase 2.3 | Low | High | UX - new user signup | User sees error after "Creating account..." | Retry loop handles up to 1.5s | Increase maxRetries to 5, notify user to retry manually |
| Retry loop infinite | Phase 2.3 | Low | Critical | App freeze | CPU spike, ANR report | Code review + unit test with mock | Kill switch via remote config |
| RLS policy drift | Phase 1.2 | Med | High | Security - new users can't signup | signup error rate spike | Live policy verification step | Emergency policy fix via SQL |
| Orphan sweep deletes wrong users | Phase 1.4 | Low | Critical | Data loss - valid users deleted | User reports "account disappeared" | Strict time filter (15 min), exclude recently created | Restore from backup, fix time filter |
| Banned user bypass on cold start | Phase 0.2 | Med | Critical | Security - banned content access | Banned user activity in logs | Test: ban → kill app → reopen → verify block | Emergency server-side token revocation |
| Test flakiness from network | Phase 4.3 | Med | Med | Delayed release, false failures | CI test failures | Mock Supabase client, no real network in unit tests | Tag tests as @integration, run separately |

---

## F) Pre-Mortem (How This Fails in Real Life)

1. **This fails when** the `pg_cron` extension is not available on the Supabase project and the migration silently fails, leaving no orphan sweeper and causing user lockout complaints weeks later.

2. **This fails when** the profile trigger takes 2+ seconds due to high DB load, exceeding our retry budget, and new users get "Account creation failed" errors on signup, causing conversion drop.

3. **This fails when** a developer adds `Supabase.instance.client.from('profiles')...` directly in a ViewModel during a different feature, bypassing the Repository retry logic, and the race condition reappears in a new flow.

4. **This fails when** the RLS policy on `profiles` was manually modified in production to be more restrictive (e.g., requires email verification), and new users get permission denied on profile fetch even after trigger completes.

5. **This fails when** the orphan sweeper cron job is created with a bug that deletes users created 15 seconds ago instead of 15 minutes, causing mass account deletion.

6. **This fails when** `AccountGuardService` throws an exception during cold start (network blip), the exception is caught but not handled properly, and a banned user briefly sees the dashboard before the next lifecycle event.

7. **This fails when** tests are written against the real Supabase instance with artificial `pg_sleep()` delays, making CI flaky and causing developers to skip the tests or disable them.

8. **This fails when** the retry logic works perfectly in testing but confuses users who see "Setting up your account..." for 1.5 seconds and think the app is broken, causing them to force-quit.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Add pg_cron Pre-Verification
**Goal**: Verify extension availability before migration
**Why**: Prevents migration failure on production
**How**: Add to Phase 1.0:
```sql
SELECT installed FROM pg_available_extensions WHERE name = 'pg_cron';
-- If false, document alternative approach in migration notes
```
**Output**: Verification query result in migration comments
**Stop Condition**: Query returns `installed = true` OR documented fallback

### Fix 2: Add Test Infrastructure for Auth
**Goal**: Enable deterministic testing of retry logic
**Why**: Current test suite lacks Supabase mocking patterns
**How**:
1. Verify `mocktail: ^1.0.0` in `pubspec.yaml` dev_dependencies
2. Create `test/unit/auth/auth_repository_test.dart`:
   - Mock `SupabaseClient` and `PostgrestQueryBuilder`
   - Test `getCurrentUserProfileWithRetry()` with 2 failures then success
   - Test max retry exceeded calls `signOut()`
3. Document pattern in `test/README.md`
**Output**: Passing unit test file + documentation
**Stop Condition**: `flutter test test/unit/auth/auth_repository_test.dart` passes

### Fix 3: Add Live RLS Verification
**Goal**: Confirm production RLS policies match expectations
**Why**: Prevents permission denied errors on signup
**How**: Add to Phase 1.0:
```sql
SELECT policyname, qual FROM pg_policies 
WHERE tablename = 'profiles' AND cmd = 'SELECT';
-- Expected: qual contains '(id = auth.uid())'
```
**Output**: RLS verification query result logged
**Stop Condition**: Policy qual matches expected expression

### Fix 4: Add Orphan Sweep Monitoring
**Goal**: Observable sweeper execution
**Why**: Silent failures are dangerous for data cleanup jobs
**How**:
1. Modify sweeper function to log via `RAISE NOTICE` (captured by Supabase logs)
2. Create view:
```sql
CREATE VIEW vw_orphaned_auth_users AS
SELECT u.id, u.email, u.created_at 
FROM auth.users u 
LEFT JOIN profiles p ON u.id = p.id 
WHERE p.id IS NULL;
```
3. Document monitoring query: `SELECT COUNT(*) FROM vw_orphaned_auth_users;`
**Output**: View + documentation
**Stop Condition**: View returns expected count, logs visible in Supabase dashboard

### Fix 5: Define User-Facing Error Messages
**Goal**: Consistent, helpful error messages
**Why**: Reduces support burden, improves UX
**How**: Add to `lib/core/constants/auth_messages.dart`:
```dart
class AuthMessages {
  static const String profileProvisioning = 'Setting up your account...';
  static const String profileRetryAttempt = 'Still working... (attempt {attempt}/{max})';
  static const String profileProvisioningFailed = 'Account creation failed. Please try again.';
  static const String accountBanned = 'Your account has been banned.';
  static const String accountSuspended = 'Your account is temporarily suspended.';
}
```
**Output**: Constants file with i18n-ready structure
**Stop Condition**: Messages used in `AuthFormViewModel` and `AuthSessionViewModel`

### Fix 6: Add Retry Feature Flag
**Goal**: Kill switch for retry logic
**Why**: Emergency disable without code deploy
**How**: Create `lib/core/config/auth_config.dart`:
```dart
class AuthConfig {
  static const bool enableProfileFetchRetry = true;
  static const int profileFetchMaxRetries = 3;
  static const int profileFetchRetryDelayMs = 500;
}
```
**Output**: Config class referenced in `AuthRepository`
**Stop Condition**: Changing `enableProfileFetchRetry = false` disables retry in tests

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions & Gates (COMPLETE BEFORE ANY CODE)

**Goal**: Verify all gates pass before touching code
**Why**: Prevents wasted work on unstable foundations
**How**: Run checklist below

#### 0.1 Test Infrastructure Verification
- [ ] Verify `mocktail` in `pubspec.yaml` dev_dependencies
- [ ] Confirm `test/unit/auth/` directory exists or create it
- [ ] Run `flutter test` baseline - should pass existing tests

**GATE CHECK**: `flutter test` passes with no failures

#### 0.2 Supabase Live Scan
- [ ] Run: `SELECT installed FROM pg_available_extensions WHERE name = 'pg_cron';`
- [ ] If `installed = false`, document alternative approach
- [ ] Run: `SELECT policyname, qual FROM pg_policies WHERE tablename = 'profiles';`
- [ ] Verify trigger exists: `SELECT tgname FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass;`

**GATE CHECK**: pg_cron availability documented, RLS policies verified

#### 0.3 Security Review
- [ ] Review `AccountGuardService` implementation for exception handling
- [ ] Document exception scenarios and fallback behavior

**GATE CHECK**: All exception paths lead to safe state (signOut or restricted screen)

---

### Phase 1: Database Foundation

**Goal**: Ensure DB layer ready for app changes
**Why**: App depends on DB trigger and RLS policies
**How**: SQL changes only, no app code yet

#### 1.1 Verify pg_cron Extension
```sql
-- Query:
SELECT * FROM pg_available_extensions WHERE name = 'pg_cron';

-- If installed = true, proceed
-- If installed = false:
--   Option A: Request Supabase support enable it
--   Option B: Document Edge Function alternative in plan
```

#### 1.2 Create Orphan Monitoring View
```sql
CREATE OR REPLACE VIEW vw_orphaned_auth_users AS
SELECT u.id, u.email, u.created_at 
FROM auth.users u 
LEFT JOIN profiles p ON u.id = p.id 
WHERE p.id IS NULL;
```

#### 1.3 Create Orphan Sweeper Function
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
    RAISE NOTICE 'Orphan sweep completed: % users deleted', deleted_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### 1.4 Schedule Cron Job
```sql
SELECT cron.schedule(
    'sweep-orphaned-auth-users',
    '*/15 * * * *',
    'SELECT sweep_orphaned_auth_users()'
);

-- Verify:
SELECT * FROM cron.job WHERE jobname = 'sweep-orphaned-auth-users';
```

#### 1.5 Verify RLS Policies
```sql
-- Document current state:
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'profiles' AND schemaname = 'public';

-- Expected: SELECT policy with qual containing '(id = auth.uid())'
```

**Output Artifact**: Migration file `20260306120000_auth_profile_orphan_sweeper.sql`

**GATE CHECK**: 
- `SELECT * FROM cron.job` shows scheduled job
- `SELECT COUNT(*) FROM vw_orphaned_auth_users` returns count without error
- RLS policy qual matches expected

---

### Phase 2: Configuration & Constants

**Goal**: Define configurable parameters and user-facing messages
**Why**: Centralizes tuning and localization
**How**: Pure Dart, no logic yet

#### 2.1 Create Auth Config
File: `lib/core/config/auth_config.dart`
```dart
class AuthConfig {
  static const bool enableProfileFetchRetry = true;
  static const int profileFetchMaxRetries = 3;
  static const int profileFetchRetryDelayMs = 500;
  static const int profileFetchMaxTotalWaitMs = 
      profileFetchMaxRetries * profileFetchRetryDelayMs; // 1500ms
}
```

#### 2.2 Create Auth Messages
File: `lib/core/constants/auth_messages.dart`
```dart
class AuthMessages {
  static const String profileProvisioning = 'Setting up your account...';
  static const String profileRetryAttempt = 'Still working...';
  static const String profileProvisioningFailed = 
      'Account creation failed. Please try again.';
  static const String accountBanned = 'Your account has been banned.';
  static const String accountSuspended = 
      'Your account is temporarily suspended.';
  static const String sessionInvalid = 
      'Your session is no longer valid. Please sign in again.';
}
```

**Output Artifacts**: `auth_config.dart`, `auth_messages.dart`

**GATE CHECK**: Files compile, constants accessible in `AuthRepository`

---

### Phase 3: Repository Layer

**Goal**: Add retry logic to profile fetch
**Why**: Handles race condition at data layer
**How**: Modify `AuthRepository`, add tests

#### 3.1 Add Retry Method to AuthRepository
File: `lib/features/auth/data/auth_repository.dart`

Add method:
```dart
/// Fetches current user profile with retry for race condition handling.
/// Retries up to [maxRetries] with [retryDelay] between attempts.
Future<UserProfile?> getCurrentUserProfileWithRetry({
  int? maxRetries,
  Duration? retryDelay,
}) async {
  final retries = maxRetries ?? AuthConfig.profileFetchMaxRetries;
  final delay = retryDelay ?? 
      const Duration(milliseconds: AuthConfig.profileFetchRetryDelayMs);
  
  if (!AuthConfig.enableProfileFetchRetry) {
    return _fetchProfileOnce();
  }
  
  for (int attempt = 1; attempt <= retries; attempt++) {
    try {
      final profile = await _fetchProfileOnce();
      if (profile != null) {
        AppLogger.i('Profile fetch succeeded on attempt $attempt', tag: 'Auth');
        return profile;
      }
    } catch (e) {
      AppLogger.w('Profile fetch attempt $attempt failed: $e', tag: 'Auth');
    }
    
    if (attempt < retries) {
      AppLogger.d('Waiting ${delay.inMilliseconds}ms before retry', tag: 'Auth');
      await Future.delayed(delay);
    }
  }
  
  AppLogger.w('Profile fetch failed after $retries attempts', tag: 'Auth');
  return null;
}

Future<UserProfile?> _fetchProfileOnce() async {
  final user = _client.auth.currentUser;
  if (user == null) return null;
  
  final response = await _client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle(); // Use maybeSingle to avoid exception on no rows
      
  return response != null ? UserProfile.fromMap(response) : null;
}
```

#### 3.2 Create Unit Tests
File: `test/unit/auth/auth_repository_test.dart`

Test cases:
1. Success on first attempt
2. Success on third attempt (2 failures then success)
3. Failure after max retries returns null
4. When `enableProfileFetchRetry = false`, only one attempt
5. Verify `signOut()` not called from Repository (ViewModel responsibility)

**Output Artifacts**: Updated `auth_repository.dart`, new test file

**GATE CHECK**: `flutter test test/unit/auth/auth_repository_test.dart` passes all cases

---

### Phase 4: ViewModel Layer

**Goal**: Integrate retry logic into auth flows
**Why**: Coordinates Repository calls with UI state
**How**: Modify `AuthSessionViewModel` and `AuthFormViewModel`

#### 4.1 Update AuthSessionViewModel
File: `lib/features/auth/viewmodels/auth_session_view_model.dart`

Update `_loadInitialProfile()`:
```dart
Future<void> _loadInitialProfile() async {
  if (!isAuthenticated) return;
  _isLoading = true;
  _error = null;
  notifyListeners();
  
  try {
    _currentUserProfile = await _authRepo.getCurrentUserProfileWithRetry();
    
    if (_currentUserProfile == null && isAuthenticated) {
      // Max retries exceeded - sign out to clear corrupt state
      AppLogger.w('Profile not found after retries - signing out', tag: 'Auth');
      await logout();
      _error = AuthMessages.profileProvisioningFailed;
    }
  } catch (e, st) {
    AppLogger.e('Failed to load profile', tag: 'Auth', error: e, stackTrace: st);
    await logout();
    _error = AuthMessages.sessionInvalid;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

Add error getter:
```dart
String? _error;
String? get error => _error;
```

#### 4.2 Update AuthFormViewModel
File: `lib/features/auth/viewmodels/auth_form_view_model.dart`

Update `register()` method:
```dart
Future<bool> register({...}) async {
  _setError(null);
  _setLoading(true);
  try {
    await _authRepo.signUp(email: email, password: password, fullName: fullName);
    
    // Wait for profile creation with retry
    final profile = await _authRepo.getCurrentUserProfileWithRetry();
    if (profile == null) {
      AppLogger.w('Profile creation failed after signup - signing out');
      await _authRepo.signOut();
      _setError(AuthMessages.profileProvisioningFailed);
      return false;
    }
    
    AppLogger.i('Registration complete with profile');
    return true;
  } catch (e) {
    _setError(ErrorMapper.map(e));
    AppLogger.e('Registration failed: $e');
    return false;
  } finally {
    if (hasListeners) _setLoading(false);
  }
}
```

**Output Artifacts**: Updated ViewModel files

**GATE CHECK**: 
- `flutter analyze` passes
- No `Supabase.instance.client` direct calls in ViewModels (verify via grep)

---

### Phase 5: UI Wiring

**Goal**: Display retry progress and errors
**Why**: Users need feedback during delays
**How**: Update existing screens

#### 5.1 Update Login/Signup Screens
Files: `lib/features/auth/view/login_screen.dart`, `signup_screen.dart`

Ensure screens:
1. Display `AuthSessionViewModel.error` in error banner
2. Show `AuthMessages.profileProvisioning` when `isLoading = true` during signup
3. Use existing `Consumer<AuthFormViewModel>` patterns

**Output Artifacts**: Updated screen files (if changes needed)

**GATE CHECK**: Screens compile, existing widget tests pass

---

### Phase 6: QA & Security Validation

**Goal**: Verify all acceptance criteria
**Why**: Production safety
**How**: Manual + automated tests

#### 6.1 Unit Tests
- [ ] Run: `flutter test test/unit/auth/`
- [ ] Verify retry logic tests pass

#### 6.2 Widget Tests
- [ ] Run: `flutter test test/widget/auth/`
- [ ] Verify existing auth flow tests pass

#### 6.3 Integration Tests
- [ ] Test: New user signup → profile created → dashboard visible
- [ ] Test: Existing user login → profile loaded
- [ ] Test: Session restore (cold start) → profile loaded
- [ ] Test: Banned user cold start → restricted screen shown

#### 6.4 Security Tests
- [ ] RLS: Verify user A cannot read user B profile (query returns 0 rows)
- [ ] Guard: Verify banned user intercepted on session restore

#### 6.5 DB Validation
- [ ] Verify cron job running: `SELECT * FROM cron.job_run_details`
- [ ] Check no orphans: `SELECT COUNT(*) FROM vw_orphaned_auth_users` should be 0 or decreasing

**Output Artifact**: `test/unit/auth/auth_repository_test.dart` (new)

**GATE CHECK**: All test suites pass, no orphaned auth users > 15 min old

---

### Phase 7: Documentation Sync

**Goal**: Keep docs aligned with changes
**Why**: Future developers need accurate reference
**How**: Update `Sline_everything/`

#### 7.1 Update SUPABASE_SETUP.md
- Document `pg_cron` extension usage
- Document `vw_orphaned_auth_users` view
- Document `sweep_orphaned_auth_users()` function

#### 7.2 Update DEVELOPER_GUIDE.md
- Document retry logic behavior
- Reference `AuthConfig` for tuning
- Document AccountGuard cold start check

#### 7.3 Update Changelog
File: `Sline_everything/Sline_Log.md`
- Entry: Auth profile provisioning hardening (2026-03-06)
- List: retry logic, orphan sweeper, RLS verification

**Output Artifacts**: Updated documentation files

**GATE CHECK**: Docs reference correct file paths and function names

---

## I) Change Report (Diff-Style)

### Original Issues Summary
1. Missing pg_cron verification step
2. No test infrastructure for retry logic
3. Assumed RLS policies without live verification
4. No monitoring for orphan sweep
5. Unclear error message handling
6. Missing feature flag for retry logic
7. No Gate 0 test infrastructure check

### Added Steps (Bullet List)
- Phase 0: Preconditions & Gates (COMPLETE BEFORE ANY CODE)
- Phase 2: Configuration & Constants (AuthConfig, AuthMessages)
- Phase 3: Repository Layer (unit tests, _fetchProfileOnce, retry method)
- Phase 4: ViewModel Layer (error handling, signOut on failure)
- Phase 5: UI Wiring (progress/error display)
- Phase 6: QA & Security Validation (comprehensive test suite)
- Phase 7: Documentation Sync (SUPABASE_SETUP.md, DEVELOPER_GUIDE.md)

### Removed Steps
- None (all original steps incorporated or expanded)

### Reordered Steps
- Original: Phase 1 DB → Phase 2 MVVM → Phase 3 UI → Phase 4 QA
- Corrected: Phase 0 Gates → Phase 1 DB → Phase 2 Config → Phase 3 Repository → Phase 4 ViewModel → Phase 5 UI → Phase 6 QA → Phase 7 Docs

### Expanded Steps
- Phase 0: Added explicit gate checks with stop conditions
- Phase 1: Added pg_cron verification, RLS live verification, monitoring view
- Phase 3: Added explicit test file with 5 test cases
- Phase 4: Split into Repository and ViewModel sub-phases
- Phase 6: Expanded from 4 checklist items to 5 categories with explicit commands

### Why (Short, Practical)
- Gates prevent wasted work on unstable foundations
- Config/constants enable tuning without code changes
- Repository-first approach keeps MVVM boundaries clean
- Unit tests enable deterministic retry testing without real network
- Live RLS verification catches production drift before it breaks users

### Residual Risks (What Still Remains Risky)
1. **pg_cron availability**: Even with verification, if Supabase disables it later, sweeper stops
2. **Trigger latency**: If production DB trigger takes >1.5s consistently, retry budget exceeded
3. **Banned user bypass on exception**: If `AccountGuardService` throws, exception handling must signOut (verify in code review)
4. **Test flakiness**: Integration tests with real Supabase may flake; mitigate with retries and clear failure artifacts

---

**Plan Status**: ✅ READY FOR EXECUTION (after Gate 0 completion)

**Next Action**: Run Gate 0 verification checklist before any code changes.
