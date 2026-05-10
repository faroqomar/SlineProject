# @PlanCritic Review: Role Switching Flow Implementation Plan

**Plan Under Review:** `.TODO/PLAN_RoleSwitchingFlow_2026-03-06.md`  
**Review Date:** 2026-03-06  
**Feature:** Role Switching Flow Hardening  
**Critic:** @PlanCritic v2.1

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred)

1. **Supabase Auth Hooks available** - Assumed project has access to Auth Hooks for JWT claim sync. If not available, trigger-based approach is fallback.
2. **pg_cron already enabled** - From `01_auth-profile-provisioning.md`, pg_cron is available.
3. **2-week migration window acceptable** - Assumed business can tolerate 14 days of dual-path support.
4. **Team composition** - Assumed access to @Supabase_Ops, @Architect, @Pixel, @Sentinel agents.
5. **Test infrastructure exists** - Assumed `test/` directory with unit/widget/integration structure exists.

### Decision Needed (Blocking)

| Decision | Options | Recommended | Impact on Plan |
|----------|---------|-------------|----------------|
| **D1: Auth Hook vs Trigger** | (A) Auth Hook for JWT sync; (B) Trigger on profiles table | **A if available, B as fallback** | If Hook unavailable, Phase 1.3 changes to trigger-only; session refresh becomes even more critical |
| **D2: Feature flag mechanism** | (A) Remote config (Supabase table); (B) Build-time flag; (C) No flag, YOLO | **A** | If no remote config, emergency rollback requires app store release |
| **D3: RLS policy migration** | (A) Immediate cutover; (B) Dual policies (JWT + join) for 2 weeks; (C) Keep joins forever | **B** | A risks regression; C defeats performance goal; B requires more DB work but safer |
| **D4: Teardown contract scope** | (A) Only Chat + Dashboard; (B) All ViewModels with cached data; (C) Full Provider tree wipe | **B** | A risks state pollution in Home/Tasks; C is overkill and causes UX flash |

**Blockers if not resolved:**
- **D1** blocks Phase 1.3 implementation
- **D2** blocks Phase 0.5 and rollback plan
- **D3** blocks Phase 1.2 RLS policy updates
- **D4** blocks Phase 2.3 teardown implementation

---

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate (NEW - Required)

**Status:** ❌ FAIL

**Reason:**
1. No mention of existing test harnesses for ViewModel testing with Provider
2. No fixture/seed data strategy for integration tests requiring auth sessions
3. No pgTAP test infrastructure mentioned (required for RLS negative tests)

**To Pass:**
- [ ] Verify `test/` directory structure exists
- [ ] Document existing ViewModel test patterns (mock repositories)
- [ ] Add pgTAP test setup documentation or migration path
- [ ] Define fixture manifest for profile + role scenarios

---

### Gate 1: Data/Contracts Gate

**Status:** ❌ FAIL

**Reason:**
1. RPC return type defined but no error code taxonomy (what codes can client expect?)
2. No DTO boundary defined for `RoleSwitchResult` vs internal models
3. Migration plan lacks "introduce" phase DDL ordering (what runs first?)
4. Missing backfill strategy for existing sessions (how do active users get JWT claims?)

**To Pass:**
- [ ] Define explicit error code taxonomy: `stale_state`, `invalid_role`, `db_error`, `session_error`
- [ ] Document DTO: JSONB from RPC → Dart `RoleSwitchResult` → ViewModel state
- [ ] Add migration ordering: (1) Create RPC, (2) Create trigger, (3) Backfill existing, (4) Add new RLS, (5) Deprecate old
- [ ] Add backfill strategy: On next login or session refresh, sync role to JWT

---

### Gate 2: Security Gate

**Status:** ❌ FAIL

**Reason:**
1. No explicit RLS policy audit list (which policies need updating?)
2. No mention of audit logging for role switches (who switched when?)
3. No validation that old `changeRole()` path is properly revoked after migration
4. Missing check for Supabase realtime subscription security (does role change affect channel permissions?)

**To Pass:**
- [ ] List exact policies to update: `task_requests_insert_freelancer`, `availability_slots_insert_freelancer`, `availability_slots_update_freelancer`
- [ ] Add `audit_logs` INSERT in RPC or trigger
- [ ] Document revocation plan for old `changeRole()` path
- [ ] Verify realtime channel re-authentication on role switch

---

### Gate 3: Backend/API Gate

**Status:** ⚠️ PARTIAL

**Reason:**
1. RPC function defined but lacks idempotency key (what happens if client retries same request?)
2. No mention of rate limiting (prevent abuse: rapid role switching)
3. Session refresh retry logic has exponential backoff but no circuit breaker

**To Pass:**
- [ ] Add idempotency: RPC should return success if role already equals `new_role`
- [ ] Add rate limit: Max 3 switches per minute per user
- [ ] Document circuit breaker: After 3 failed session refreshes, force logout

---

### Gate 4: UI/Integration Gate

**Status:** ❌ FAIL

**Reason:**
1. ViewModel teardown contract assumes all ViewModels are accessible from ProfileViewModel - not true in Provider tree
2. No loading state UX specification (what does user see during 3-second switch?)
3. No error state recovery (if switch fails mid-teardown, how do we restore state?)
4. Missing offline handling (what if switch starts then connection drops?)

**To Pass:**
- [ ] Document Provider access pattern: `context.read<ChatViewModel>()` from Profile screen
- [ ] Specify loading UX: Full-screen modal with "Switching persona..." + progress steps
- [ ] Add recovery: If teardown succeeds but RPC fails, reload original role data
- [ ] Add offline guard: Check connectivity before initiating switch

---

### Gate 5: Release/QA Gate

**Status:** ❌ FAIL

**Reason:**
1. No test type allocation (which behaviors need unit vs widget vs integration?)
2. No device/browser matrix mentioned (does this affect all platforms?)
3. No flake/retry policy for integration tests
4. No artifact capture defined (what logs/screenshots on failure?)

**To Pass:**
- [ ] Allocate tests: Unit (teardown methods), Widget (loading states), Integration (full switch flow)
- [ ] Document matrix: iOS, Android, Web (all supported platforms)
- [ ] Define flake policy: Max 2 retries for integration tests, 5s timeout per step
- [ ] Define artifacts: `AppLogger` tag `role_switch_*` captured, screenshot on failure

---

## C) Critical Gaps (Must-Fix)

### Gap 1: Missing ViewModel Access Pattern

| Field | Value |
|-------|-------|
| **Gap** | `ProfileViewModel.changeRole()` receives ViewModels as parameters, but Profile screen doesn't have access to `DashboardViewModel` (different branch of Provider tree) |
| **Why it will break** | Compile error or runtime null - Profile screen is under Profile feature, DashboardViewModel is under Dashboard feature. Cross-feature Provider access violates MVVM boundaries. |
| **Fix** | Use event bus or coordinator pattern: `RoleSwitchCoordinator` singleton that ViewModels register with. Coordinator calls teardown on all registered ViewModels. |
| **Owner** | @Architect |
| **Acceptance** | Profile screen can trigger teardown without direct ViewModel references; unit test proves coordinator notifies all registered ViewModels |

### Gap 2: Missing Audit Trail

| Field | Value |
|-------|-------|
| **Gap** | No audit logging for role switches. If user abuses role switching (e.g., to game the system), there's no traceability. |
| **Why it will break** | Compliance/ops issue. Cannot debug "why did my role change?" support tickets. |
| **Fix** | (1) Add `audit_logs` table insert in RPC; (2) Log: user_id, old_role, new_role, timestamp, device_info (from JWT), success/failure |
| **Owner** | @Supabase_Ops |
| **Acceptance** | Query `audit_logs WHERE action = 'role_switch'` returns rows for every switch; test verifies insert on success and failure |

### Gap 3: Session Refresh Failure Handling

| Field | Value |
|-------|-------|
| **Gap** | If `refreshSession()` fails after RPC succeeds, user has new role in DB but old JWT claim. UI shows old role but backend treats as new role. |
| **Why it will break** | RLS confusion: User appears as Client in UI but Freelancer in JWT (or vice versa). Actions fail mysteriously. |
| **Fix** | Add verification step: After refresh, decode JWT locally and confirm `app_metadata.active_role == new_role`. If mismatch, retry once then force logout. |
| **Owner** | @Architect |
| **Acceptance** | Unit test: Mock refresh success but JWT mismatch → triggers logout flow |

### Gap 4: Realtime Channel Cleanup

| Field | Value |
|-------|-------|
| **Gap** | `ChatViewModel.disconnectChannels()` cancels Dart StreamSubscriptions but doesn't unsubscribe from Supabase realtime channels. |
| **Why it will break** | Memory leak + security: Channels keep receiving messages for old role context. User might see notifications from wrong persona. |
| **Fix** | Call `_client.removeChannel()` or equivalent Supabase method to fully unsubscribe, not just cancel local listener. |
| **Owner** | @Architect |
| **Acceptance** | After role switch, Supabase Realtime inspector shows no active channels for user (or only new role channels) |

### Gap 5: Migration Window Enforcement

| Field | Value |
|-------|-------|
| **Gap** | "2-week compatibility window" mentioned but no mechanism to track or enforce it. |
| **Why it will break** | Old code path (`changeRole()`) stays in codebase forever. New developers use wrong method. Security holes persist. |
| **Fix** | Add TODO marker with date: `// TODO[2026-03-20]: Remove legacy changeRole() after migration window`. Add deprecation lint rule. Schedule calendar reminder. |
| **Owner** | @Sentinel |
| **Acceptance** | Calendar event created; lint rule fails CI if `@Deprecated` code called after 2026-03-20 |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | Enforcement | Verification |
|---|-----------|-------------|--------------|
| I1 | **Role atomicity** - Only one role switch succeeds per user at any moment | `expected_old_role` guard in RPC + unique constraint on user session | pgTAP test: concurrent RPC calls, exactly one succeeds |
| I2 | **JWT-DB consistency** - JWT claim matches DB `active_role` before UI unlock | Mandatory `refreshSession()` + JWT decode verification | Unit test: mock mismatch → triggers logout |
| I3 | **No state pollution** - ViewModels have no cached data from previous role | Teardown contract: all ViewModels implement `teardownForRoleSwitch()` | Integration test: switch roles, verify `chatViewModel.conversations.isEmpty` |
| I4 | **RLS enforcement** - Freelancer-only tables reject client JWT | RLS policies check `auth.jwt()->'app_metadata'->>'active_role'` | pgTAP negative test: client JWT INSERT to `task_requests` fails with 42501 |
| I5 | **Audit completeness** - Every role switch attempt logged | `audit_logs` INSERT in RPC (both success and failure paths) | Query audit_logs; verify both success and failure rows present |
| I6 | **Backward compatibility** - Old app versions still work during migration | Old RLS policies (join-based) remain functional during window | Integration test with old code path still passes |
| I7 | **Performance** - Role switch < 3 seconds total | No N+1 queries, JWT-based RLS, bounded retries | Performance test: 100 switches, p99 < 3s |

---

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|-------------|-----------|----------|
| R1: Supabase Auth Hook unavailable | Phase 1.3 | Med | High | Feature | Hook fails to appear in dashboard | Verify Hook availability in D1 decision | Use trigger-based sync; session refresh more critical |
| R2: JWT claim sync delay | Phase 2.4 | High | Med | UX | `refreshSession()` returns old claims | Add JWT decode verification step | Force logout if mismatch persists |
| R3: ViewModel teardown fails mid-flight | Phase 2.3 | Med | High | App-wide | Partial data, inconsistent UI | Try-catch each teardown, aggregate errors | Emergency full logout on any teardown failure |
| R4: Realtime channel cleanup incomplete | Gap 4 | Med | Med | Security | Messages from old role appear | Proper Supabase channel unsubscribe | App restart on role switch (nuclear option) |
| R5: RLS policy regression | Phase 1.2 | Low | Critical | Security | Unauthorized actions succeed | Dual-policy period with monitoring | Instant rollback to join-based policies |
| R6: Feature flag fails | Phase 0.5 | Low | High | Release | New code runs when should be legacy | Test flag in staging with both values | Hardcoded fallback in code; hotfix release |
| R7: Migration window expires | Gap 5 | Med | Low | Maintenance | Old code still present | Calendar reminder, lint rule | Manual cleanup sprint |
| R8: Multi-device race condition | Phase 1.1 | Med | Med | UX | User sees "stale state" error frequently | RPC guard educates user | Allow force-refresh option in error UI |

---

## F) Pre-Mortem (How this fails in real life)

1. **"This fails when"** a user has the app open on both phone and tablet, switches role on tablet, then immediately tries to switch back on phone. The phone gets "stale state" error and user thinks the app is broken (not understanding multi-device sync).

2. **"This fails when"** the Supabase Auth Hook takes 5+ seconds to propagate JWT claims. The session refresh returns old claims, verification fails, user is force-logged-out during what should be a simple role switch. User rage-quits.

3. **"This fails when"** a developer adds a new ViewModel (`NotificationViewModel`) but forgets to add it to the teardown contract. After role switch, user sees notifications from old role, violating I3.

4. **"This fails when"** the network drops exactly between RPC success and session refresh. User's role is updated in DB but JWT still has old role. User can still see old UI but actions fail mysteriously with RLS errors.

5. **"This fails when"** RLS policy update has a typo and accidentally allows all roles. Malicious user discovers they can submit proposals while in client mode, gaming the marketplace.

6. **"This fails when"** the 2-week migration window passes but `changeRole()` is still in the codebase. New hire uses it for a new feature, reintroducing race condition bugs.

7. **"This fails when"** realtime channel cleanup doesn't work and user continues receiving chat messages from their "client" persona while browsing as "freelancer". Confidential client data leaks.

8. **"This fails when"** integration tests are flaky due to unbounded session refresh timeouts. CI fails randomly, blocking releases, causing team to disable tests, causing undetected regression.

9. **"This fails when"** no audit logging exists and support team cannot answer "why did my role change?" tickets. Users lose trust in platform security.

10. **"This fails when"** performance testing wasn't done and role switch takes 8 seconds on slow networks. Users abandon app thinking it's frozen.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: RoleSwitchCoordinator Pattern

**Goal:** Enable cross-ViewModel teardown without violating MVVM boundaries  
**Why:** Profile screen cannot access DashboardViewModel directly via Provider  
**How:**
```dart
// lib/core/services/role_switch_coordinator.dart
class RoleSwitchCoordinator {
  static final RoleSwitchCoordinator _instance = RoleSwitchCoordinator._internal();
  factory RoleSwitchCoordinator() => _instance;
  RoleSwitchCoordinator._internal();

  final List<RoleSwitchAware> _registered = [];

  void register(RoleSwitchAware viewModel) => _registered.add(viewModel);
  void unregister(RoleSwitchAware viewModel) => _registered.remove(viewModel);

  Future<void> teardownAll() async {
    AppLogger.i('coordinator_teardown_begin', tag: 'RoleSwitch');
    final errors = <String>[];
    
    for (final vm in _registered) {
      try {
        await vm.teardownForRoleSwitch();
      } catch (e) {
        errors.add('${vm.runtimeType}: $e');
      }
    }
    
    if (errors.isNotEmpty) {
      AppLogger.e('coordinator_teardown_errors', tag: 'RoleSwitch', json: {'errors': errors});
      throw RoleSwitchTeardownException(errors);
    }
    
    AppLogger.i('coordinator_teardown_complete', tag: 'RoleSwitch');
  }
}

mixin RoleSwitchAware {
  Future<void> teardownForRoleSwitch();
}
```
**Output artifact:** `lib/core/services/role_switch_coordinator.dart`  
**Stop condition:** Unit test proves registration → teardown → all ViewModels cleared

---

### Fix 2: Audit Logging in RPC

**Goal:** Complete audit trail for all role switches  
**Why:** Support, compliance, debugging  
**How:**
```sql
-- In RPC function
INSERT INTO audit_logs (
  user_id,
  action,
  details,
  ip_address,
  user_agent,
  success,
  error_message
) VALUES (
  v_user_id,
  'role_switch',
  jsonb_build_object('old_role', v_current_role, 'new_role', p_new_role),
  auth.jwt()->>'ip',
  auth.jwt()->>'user_agent',
  v_success,
  v_error_message
);
```
**Output artifact:** Migration file with audit INSERT + `audit_logs` table if not exists  
**Stop condition:** pgTAP test verifies row inserted on both success and failure

---

### Fix 3: JWT Verification After Refresh

**Goal:** Ensure JWT claim matches expected role before unlocking UI  
**Why:** Prevent JWT-DB desync that causes mysterious RLS failures  
**How:**
```dart
Future<bool> _verifyJwtRoleMatches(String expectedRole) async {
  final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
  if (jwt == null) return false;
  
  // Decode JWT (without verification - we trust Supabase)
  final parts = jwt.split('.');
  if (parts.length != 3) return false;
  
  final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
  final jwtRole = payload['app_metadata']?['active_role'];
  
  return jwtRole == expectedRole;
}
```
**Output artifact:** Method added to `ProfileRepository`  
**Stop condition:** Unit test: mock JWT with wrong role → returns false

---

### Fix 4: Realtime Channel Unsubscribe

**Goal:** Fully unsubscribe from Supabase channels, not just cancel Dart streams  
**Why:** Prevent memory leaks and cross-role message leakage  
**How:**
```dart
void disconnectChannels() {
  AppLogger.i('chat_disconnect_channels', tag: 'ChatVM');
  
  // Cancel local subscriptions
  _msgSub?.cancel();
  _msgSub = null;
  _convoSub?.cancel();
  _convoSub = null;
  
  // Unsubscribe from Supabase realtime channels
  _client.removeAllChannels(); // or track specific channel refs and remove individually
}
```
**Output artifact:** Updated `ChatViewModel.disconnectChannels()`  
**Stop condition:** Supabase Realtime dashboard shows no active channels after role switch

---

### Fix 5: Test Infrastructure Setup

**Goal:** Ensure test harnesses exist for all test types  
**Why:** Block execution if we can't verify the implementation  
**How:**
1. Verify `test/unit/viewmodels/` exists for ViewModel tests
2. Create `test/fixtures/profiles.dart` with role scenarios:
```dart
final clientProfile = {'id': 'uuid', 'active_role': 'client', ...};
final freelancerProfile = {'id': 'uuid', 'active_role': 'freelancer', ...};
```
3. Create `test/helpers/mock_supabase.dart` for mocking Supabase client
4. Document: `flutter test --tags=role_switch` runs role-specific tests

**Output artifact:** `test/fixtures/profiles.dart`, `test/helpers/mock_supabase.dart`  
**Stop condition:** `flutter test` passes with at least one role switch test

---

### Fix 6: Error Code Taxonomy

**Goal:** Client knows exactly what went wrong and how to handle it  
**Why:** Proper error UX, retry logic, analytics  
**How:**
```dart
class RoleSwitchError {
  static const staleState = 'stale_state'; // Expected role mismatch - refresh and retry
  static const invalidRole = 'invalid_role'; // Bad input - shouldn't happen
  static const dbError = 'db_error'; // Database issue - retry later
  static const sessionError = 'session_error'; // JWT sync failed - force logout
  static const networkError = 'network_error'; // Connection issue - retry
  static const teardownError = 'teardown_error'; // Cleanup failed - force logout
}
```
**Output artifact:** `lib/features/profile/models/role_switch_error.dart`  
**Stop condition:** All error paths map to one of these codes; UI handles each appropriately

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure & Decision Lock

**Goal:** Unblock execution with firm decisions and working test harness  
**Why:** Foundation for all verification; no execution without testability  
**How:**
1. **Decision Lock** - Resolve D1-D4 with stakeholders
2. **Test Harness** - Create fixtures, mock helpers, base test classes
3. **pgTAP Setup** - Document how to run DB tests locally
4. **CI Check** - Verify `flutter test` passes in CI

**Sub-steps:**
- [ ] (Product) Confirm Auth Hook availability (D1)
- [ ] (DevOps) Confirm remote config mechanism (D2)
- [ ] (Architect) Confirm teardown scope (D4)
- [ ] (@Sentinel) Create `test/fixtures/profiles.dart` with 3 role scenarios
- [ ] (@Sentinel) Create `test/helpers/mock_supabase.dart`
- [ ] (@Sentinel) Create `test/helpers/role_switch_coordinator_test.dart`
- [ ] (@Supabase_Ops) Document pgTAP setup in `Sline_everything/TESTING.md`

**Output artifact:** `test/` structure complete, decisions documented in plan comments  
**GATE CHECK:** All 4 decisions resolved; `flutter test` runs without errors

---

### Phase 1: Database & Security Foundation

**Goal:** Atomic RPC, JWT sync, audit logging, hardened RLS  
**Why:** Security and correctness foundation  
**How:**
1. Create `switch_active_role` RPC with `expected_old_role` guard
2. Create trigger/hook for JWT claim sync
3. Add `audit_logs` INSERT in RPC
4. Add rate limiting (3 switches/minute)
5. Add idempotency (success if role already equals `new_role`)
6. Create new JWT-based RLS policies (dual-policy approach)

**Sub-steps:**
- [ ] (@Supabase_Ops) Migration: Create RPC with atomic guard, error taxonomy, audit INSERT
- [ ] (@Supabase_Ops) Migration: Create JWT sync trigger (or document Auth Hook setup)
- [ ] (@Supabase_Ops) Migration: Add rate limiting function
- [ ] (@Supabase_Ops) Migration: Add `task_requests_insert_freelancer_jwt` policy
- [ ] (@Supabase_Ops) Migration: Add `availability_slots_insert_freelancer_jwt` policy
- [ ] (@Supabase_Ops) Migration: Add `availability_slots_update_freelancer_jwt` policy
- [ ] (@Supabase_Ops) pgTAP test: Concurrent RPC calls → exactly one succeeds
- [ ] (@Supabase_Ops) pgTAP test: Client JWT INSERT to task_requests → 42501
- [ ] (@Supabase_Ops) pgTAP test: Audit log row inserted on success
- [ ] (@Supabase_Ops) pgTAP test: Audit log row inserted on failure
- [ ] (@Supabase_Ops) pgTAP test: Rate limit enforced after 3 rapid switches

**Output artifact:** Migration file `20260306_role_switch_foundation.sql`, pgTAP tests passing  
**GATE CHECK:** All pgTAP tests pass; RLS policies verified; audit rows present

---

### Phase 2: Backend/App Layer - Core Logic

**Goal:** Repository method, coordinator pattern, JWT verification  
**Why:** MVVM-compliant role switch with proper teardown  
**How:**
1. Create `RoleSwitchCoordinator` singleton
2. Create `RoleSwitchResult` + `RoleSwitchError` models
3. Add `ProfileRepository.switchRole()` calling RPC
4. Add JWT verification method
5. Add session refresh with retry

**Sub-steps:**
- [ ] (@Architect) Create `lib/core/services/role_switch_coordinator.dart`
- [ ] (@Architect) Create `lib/features/profile/models/role_switch_result.dart`
- [ ] (@Architect) Create `lib/features/profile/models/role_switch_error.dart`
- [ ] (@Architect) Add `ProfileRepository.switchRole()` with full error mapping
- [ ] (@Architect) Add `ProfileRepository.verifyJwtRole()`
- [ ] (@Architect) Add `ProfileRepository.refreshSessionWithRetry()`
- [ ] (@Sentinel) Unit test: Coordinator registration → teardown sequence
- [ ] (@Sentinel) Unit test: RPC success → correct RoleSwitchResult
- [ ] (@Sentinel) Unit test: RPC stale_state → correct error code
- [ ] (@Sentinel) Unit test: JWT mismatch after refresh → returns false

**Output artifact:** Repository methods, models, coordinator, unit tests passing  
**GATE CHECK:** 100% unit test coverage on repository methods; all error paths tested

---

### Phase 3: ViewModel Teardown Contract

**Goal:** All ViewModels implement `teardownForRoleSwitch()`  
**Why:** Prevent state pollution across personas  
**How:**
1. Add `RoleSwitchAware` mixin to affected ViewModels
2. Implement `teardownForRoleSwitch()` in each
3. Register with coordinator in `initState` / `dispose`

**Sub-steps:**
- [ ] (@Architect) Create `lib/core/mixins/role_switch_aware.dart`
- [ ] (@Architect) `ChatViewModel`: implement mixin, add `disconnectChannels()` (proper unsubscribe)
- [ ] (@Architect) `DashboardViewModel`: implement mixin, add `resetAllCaches()`
- [ ] (@Architect) `TaskViewModel`: implement mixin, add `clearCache()`
- [ ] (@Architect) `HomeViewModel`: implement mixin, add `clearCache()`
- [ ] (@Architect) `FavoritesViewModel`: implement mixin, add `clearCache()` (if caches favorites)
- [ ] (@Architect) `WalletViewModel`: implement mixin, add `clearCache()` (if role affects wallet view)
- [ ] (@Sentinel) Unit test: Each ViewModel teardown clears all cached data
- [ ] (@Sentinel) Unit test: Coordinator calls all registered ViewModels
- [ ] (@Sentinel) Unit test: Teardown partial failure → throws with all errors

**Output artifact:** All ViewModels updated, tests passing  
**GATE CHECK:** All ViewModels implement mixin; unit tests prove cache cleared

---

### Phase 4: ProfileViewModel Integration

**Goal:** Enhanced `changeRole()` with full teardown + verification flow  
**Why:** Orchestrate the complete role switch with error handling  
**How:**
1. Update `changeRole()` to use coordinator + new repository methods
2. Add JWT verification after session refresh
3. Add recovery logic for partial failures

**Sub-steps:**
- [ ] (@Architect) Rewrite `ProfileViewModel.changeRole()`:
  - Call RPC
  - If success: refresh session (with retry)
  - If refresh success: verify JWT role matches
  - If verify success: call coordinator teardown
  - If teardown success: reload profile, return true
  - Any failure: map error, attempt recovery, return false
- [ ] (@Architect) Add recovery: If teardown succeeds but RPC verification fails, force logout
- [ ] (@Pixel) Update Profile Settings UI to show step-by-step loading UI
- [ ] (@Sentinel) Widget test: Loading states shown during each phase
- [ ] (@Sentinel) Widget test: Error state shown on failure
- [ ] (@Sentinel) Widget test: Success state triggers navigation/rebuild

**Output artifact:** `ProfileViewModel` updated, UI loading states, widget tests passing  
**GATE CHECK:** Widget tests prove loading → success flow; error paths handled

---

### Phase 5: Integration & E2E Testing

**Goal:** Full role switch flow verified end-to-end  
**Why:** Catch integration issues not visible in unit tests  
**How:**
1. Integration test: Full switch flow with mock Supabase
2. E2E test: Manual QA script with real backend
3. Performance test: 100 switches, measure timing

**Sub-steps:**
- [ ] (@Sentinel) Integration test: 
  - Tap switch → RPC called → session refreshed → teardown executed → UI updated
- [ ] (@Sentinel) Integration test: 
  - Network failure mid-RPC → error shown → state consistent
- [ ] (@Sentinel) Integration test:
  - Double-tap switch → second call blocked (RPC guard)
- [ ] (@Sentinel) Performance test:
  - 100 role switches, measure each phase (RPC, refresh, teardown)
  - Assert p99 < 3 seconds total
- [ ] (@Sentinel) Manual QA script:
  - Device A: Switch to Freelancer
  - Device B: Attempt switch to Client → expect stale_state error
  - Device A: Verify Freelancer data loads
  - Device A: Switch back to Client → success

**Output artifact:** Integration tests passing, performance report, QA sign-off  
**GATE CHECK:** All integration tests pass; p99 < 3s; manual QA signed off

---

### Phase 6: Release & Migration

**Goal:** Safe rollout with rollback capability  
**Why:** Production safety  
**How:**
1. Feature flag setup (remote config)
2. Staged rollout (5% → 50% → 100%)
3. Monitoring dashboard
4. 14-day migration window tracking

**Sub-steps:**
- [ ] (@DevOps) Create remote config flag `enable_atomic_role_switch`
- [ ] (@DevOps) Create monitoring dashboard: role_switch_success_rate, duration_histogram, error_breakdown
- [ ] (@Architect) Add feature flag check in `ProfileViewModel`:
  - If enabled: use new flow
  - If disabled: use legacy `changeRole()`
- [ ] (@Sentinel) Deploy to staging: verify both flag values work
- [ ] (@Sentinel) Production rollout: Day 1 (5%), Day 3 (50%), Day 7 (100%)
- [ ] (@Sentinel) Calendar reminder: 2026-03-20 - remove legacy code
- [ ] (@DocsKeeper) Update all documentation

**Output artifact:** Feature flag working, monitoring dashboard live, docs updated  
**GATE CHECK:** Staging proves flag works; production 5% rollout successful; docs complete

---

### Phase 7: Cleanup

**Goal:** Remove legacy code after migration window  
**Why:** Tech debt elimination  
**How:**
1. Remove legacy `changeRole()` method
2. Remove legacy RLS policies
3. Remove feature flag
4. Final docs update

**Sub-steps:**
- [ ] (@Architect) Remove `ProfileRepository.changeRole()` method
- [ ] (@Supabase_Ops) Migration: Remove legacy join-based RLS policies
- [ ] (@DevOps) Remove `enable_atomic_role_switch` remote config
- [ ] (@DocsKeeper) Final docs pass: remove references to legacy flow

**Output artifact:** Clean codebase, no legacy references  
**GATE CHECK:** Code search for `changeRole` returns only new method; all tests still pass

---

## I) Change Report (Diff-Style)

### Original Issues Summary

The original plan had 6 major categories of issues:
1. **Test infrastructure** - Missing entirely (Gate 0 fail)
2. **ViewModel access** - Violated MVVM boundaries
3. **Security gaps** - Missing audit logging, RLS audit list
4. **Error handling** - No taxonomy, partial failure recovery undefined
5. **Realtime cleanup** - Incomplete channel unsubscribe
6. **Migration enforcement** - No mechanism to ensure cleanup happens

### Added Steps (Bullet List)

1. **Phase 0** (entirely new) - Test infrastructure & decision lock
2. **Decision D1-D4** - Blocking decisions with options and recommendations
3. **RoleSwitchCoordinator** - Pattern for cross-ViewModel teardown
4. **RoleSwitchAware mixin** - Standardized teardown interface
5. **JWT verification step** - Post-refresh claim verification
6. **Proper channel unsubscribe** - Supabase channel cleanup, not just Dart streams
7. **Audit logging** - `audit_logs` table INSERT in RPC
8. **Rate limiting** - 3 switches/minute per user
9. **Error taxonomy** - `RoleSwitchError` with all error codes
10. **Feature flag** - Remote config for gradual rollout
11. **Performance testing** - 100 switches p99 < 3s requirement
12. **pgTAP tests** - DB-level RLS and atomicity verification
13. **Calendar reminder** - 2026-03-20 cleanup deadline
14. **Monitoring dashboard** - Success rate, duration, error breakdown
15. **Pre-mortem stories** - 10 failure scenarios for team awareness

### Removed Steps (If Any)

- None removed, but reordered significantly

### Reordered Steps (From → To)

| Original | Corrected | Reason |
|----------|-----------|--------|
| Phase 0 (Preconditions) was after plan start | Phase 0 (Test Infrastructure) is FIRST | Cannot execute without testability |
| Teardown contract (Phase 2.3) came after repository | Teardown (Phase 3) after coordinator/repository (Phase 2) | Needs coordinator pattern first |
| UI (Phase 3) came before full backend | UI (Phase 4) after all backend ready | UI needs working backend to test |
| QA (Phase 4) was single phase | Split into Integration (Phase 5) and Release (Phase 6) | QA is continuous, release is separate |
| No explicit cleanup phase | Phase 7: Cleanup | Enforces migration window completion |

### Expanded Steps (What Became More Detailed)

| Step | Original Granularity | Expanded Granularity |
|------|---------------------|---------------------|
| RPC creation | "Create RPC" | 5 sub-steps: RPC, trigger, rate limit, audit, idempotency |
| RLS updates | "Audit RLS" | 3 specific policies named + pgTAP tests |
| ViewModel teardown | "Add teardown methods" | 6 ViewModels listed + mixin pattern + coordinator |
| Error handling | "Error mapping" | Full taxonomy class + 6 error codes + recovery logic |
| Testing | "Unit and integration tests" | Phase 0 infra + 3 test types + fixtures + performance + manual QA |
| Migration | "2-week window mentioned" | Feature flag + staged rollout + monitoring + calendar reminder |

### Why (Short, Practical)

1. **Test infrastructure first** - Foundational; can't verify without it
2. **Coordinator pattern** - Original violated MVVM; this maintains architecture
3. **JWT verification** - Discovered gap where refresh could succeed but claim stale
4. **Audit logging** - Security/compliance requirement originally missed
5. **Error taxonomy** - Needed for proper UX (different errors need different handling)
6. **Feature flag** - Production safety; can't ship atomic change without rollback
7. **pgTAP tests** - RLS correctness must be verified at DB level, not just integration
8. **Pre-mortem** - Team awareness of failure modes prevents panic when issues occur

### Residual Risks (What Still Remains Risky Even After Fixes)

| Risk | Mitigation | Why Residual |
|------|-----------|--------------|
| Supabase Auth Hook delays | JWT verification fallback | If Hook consistently slow, UX suffers despite verification |
| Multi-device user confusion | Error message education | Users may still not understand "stale state" errors |
| New ViewModel forgets mixin | Code review checklist | Human error possible despite checklist |
| Realtime channel edge case | Proper unsubscribe + monitoring | Supabase Realtime has complex behavior; may miss edge case |
| RLS policy typo | pgTAP tests + dual policy period | Tests can't catch all possible query patterns |
| Feature flag misconfiguration | Staged rollout | Human error in flag value could expose all users to bugs |
| Performance on slow networks | Bounded retries | Network issues outside our control |
| Calendar reminder missed | Lint rule + team process | Process dependency |

---

**END OF PLAN CRITIC REVIEW**

**Recommendation:** DO NOT PROCEED with original plan. Use this corrected version with all gates passing before Phase 1 execution.
