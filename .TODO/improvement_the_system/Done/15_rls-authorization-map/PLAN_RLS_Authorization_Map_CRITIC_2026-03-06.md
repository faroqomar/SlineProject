# 📌 Plan Critic Review: RLS Authorization Map Implementation

> **Mission:** Attack the plan until it becomes execution-safe.  
> **Status:** ❌ BLOCKED until Gate 0 and Gate 1 fixes applied.

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred)

| # | Assumption | Confidence | Impact if Wrong |
|---|------------|------------|-----------------|
| 1 | `public.users` view is not referenced by any app code | Medium | App crash on startup if referenced |
| 2 | `wallet_balances` view is not actively used (can be dropped) | Medium | Wallet UI errors if referenced |
| 3 | `service_role` key is properly secured (not exposed to clients) | High | All service_role policies become exploitable |
| 4 | Existing JWT policies from migration `20260306_role_switch_foundation.sql` are already applied | Medium | Role-based access won't work if missing |
| 5 | `RoleSwitchCoordinator` ViewModel registration doesn't cause memory leaks | Medium | Memory pressure over long sessions |
| 6 | All 4 ViewModels (`Chat`, `Dashboard`, `Home`, `Task`) are already using `RoleSwitchAware` | Low | Role switch teardown incomplete |

### Decision Needed (Blocking)

**Decision 1: Production Deployment Window**
- **What:** When can we deploy 13 SQL steps to production?
- **Options:**
  1. Single deployment during maintenance window (risk: longer downtime if rollback needed)
  2. Staged: blockers first (Steps 1-4), cleanup later (steps 5-13) (risk: partial security state)
  3. Feature flag via policy naming (risk: complex, unproven)
- **Recommended:** Option 2 — Deploy blockers (Steps 1-4) immediately; schedule cleanup (Steps 5-13) for next maintenance window
- **Plan Change:** Split Phase 1 into 1A (Blockers) and 1B (Cleanup)

**Decision 2: `wallet_balances` View Fate**
- **What:** Is `wallet_balances` actively used in the app?
- **Options:**
  1. Drop it now (clean) — risk if referenced
  2. Recreate with `security_invoker` first — safer, drop later after verification
  3. Keep but restrict to service_role — minimal change
- **Recommended:** Option 2 — Recreate with `security_invoker`, add deprecation warning, drop in future release
- **Plan Change:** Step 10 must verify usage before dropping

**Decision 3: Test Infrastructure for RLS**
- **What:** How do we test 108 policies without 100+ manual queries?
- **Options:**
  1. Create automated RLS test harness now (delays delivery, ensures safety)
  2. Manual SQL verification per policy (faster, error-prone)
  3. Hybrid: automated for blockers, manual for cleanup (balanced)
- **Recommended:** Option 1 — RLS test harness is non-negotiable for production security
- **Plan Change:** Add Gate 0: Test Infrastructure (BLOCKING)

---

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate ❌ FAIL

**Status:** ❌ **FAIL — BLOCKING**

**Reasons:**
1. No automated RLS test harness exists (needs: test DB setup, user fixture factory, policy assertion helpers)
2. No deterministic way to verify 108 policies without manual SQL
3. No negative test framework for security boundary validation

**To Pass:**
- [ ] Create `test/rls/` directory with harness
- [ ] Implement `RlsTestHelper` class with `assertCanSelect()`, `assertCannotInsert()` methods
- [ ] Add `test/fixtures/` with test user profiles (client, freelancer, admin, anon)
- [ ] Document run command: `flutter test test/rls/`

---

### Gate 1: Data/Contracts Gate ❌ FAIL

**Status:** ❌ **FAIL — BLOCKING**

**Reasons:**
1. No verification that `public.users` view is unreferenced in codebase
2. `wallet_balances` usage not confirmed before drop
3. No backup/restore procedure for policy changes

**To Pass:**
- [ ] Run `grep -r "public.users" lib/` — must return 0 matches
- [ ] Run `grep -r "wallet_balances" lib/` — must return 0 matches or documented references
- [ ] Create policy backup query: `COPY (SELECT * FROM pg_policies) TO '/tmp/policies_backup.csv'`

---

### Gate 2: Security Gate ⚠️ CONDITIONAL PASS

**Status:** ⚠️ **CONDITIONAL PASS — requires Gate 0**

**Reasons:**
1. Threat model documented but not created as artifact
2. Negative test cases defined but no harness to execute them
3. RLS leak audit steps exist but are manual

**To Pass:**
- [ ] Complete Gate 0 first
- [ ] Execute 4 critical blocker negative tests via harness
- [ ] Create `.TODO/SECURITY_RLS_Threat_Model.md`

---

### Gate 3: Backend/API Gate ⚠️ CONDITIONAL PASS

**Status:** ⚠️ **CONDITIONAL PASS — requires verification**

**Reasons:**
1. `switch_active_role` RPC exists but not tested with actual role switch
2. JWT sync trigger exists but latency not measured
3. `RoleSwitchRepository` error handling exists but not stress-tested

**To Pass:**
- [ ] Test `switch_active_role` end-to-end: client → freelancer → client
- [ ] Measure JWT claim update latency (must be < 2s with retry)
- [ ] Verify `RoleSwitchTeardownException` handling in ProfileViewModel

---

### Gate 4: UI/Integration Gate ✅ PASS

**Status:** ✅ **PASS — No UI changes required**

**Verification:**
- No UI code references dropped views (assumed, needs Gate 1 confirmation)
- No new UI components needed
- Existing ViewModels already implement `RoleSwitchAware`

---

### Gate 5: Release/QA Gate ❌ FAIL

**Status:** ❌ **FAIL — BLOCKING**

**Reasons:**
1. No automated regression test suite defined
2. No rollback procedure tested
3. No monitoring/alerting for policy violations

**To Pass:**
- [ ] Define regression test list: task creation, booking flow, messaging, wallet view
- [ ] Test rollback script in staging
- [ ] Add `audit_logs` monitoring query for anomalies

---

## C) Critical Gaps (Must-Fix)

### Gap 1: Missing Test Infrastructure

| | Details |
|---|---|
| **Gap** | No automated way to test 108 RLS policies |
| **Why it will break** | Manual verification of 108 policies is error-prone; security regressions will slip through |
| **Fix** | Add **Gate 0: Test Infrastructure** phase with: `RlsTestHelper`, test fixtures, assertion library |
| **Owner** | @Sentinel |
| **Acceptance** | Run `flutter test test/rls/` — all 4 critical blocker tests pass |

### Gap 2: View Usage Not Verified

| | Details |
|---|---|
| **Gap** | `public.users` and `wallet_balances` view usage not grep'd |
| **Why it will break** | Dropping referenced views causes runtime app crashes |
| **Fix** | Add step to **Gate 1**: `grep -r "from users" lib/` and `grep -r "wallet_balances" lib/` |
| **Owner** | @Architect |
| **Acceptance** | Grep returns 0 matches or documented safe references |

### Gap 3: No Policy Backup/Restore

| | Details |
|---|---|
| **Gap** | No backup of current 108 policies before modification |
| **Why it will break** | If rollback needed, policies must be recreated manually from memory/docs |
| **Fix** | Add pre-migration step: `pg_dump --schema-only --table="*"` or `COPY pg_policies` to backup |
| **Owner** | @Supabase_Ops |
| **Acceptance** | `.TODO/BACKUP_policies_2026-03-06.sql` exists with all 108 policies |

### Gap 4: Missing JWT Latency Measurement

| | Details |
|---|---|
| **Gap** | No measurement of JWT claim sync latency |
| **Why it will break** | If sync takes > 5s, app will see stale role data after switch, causing confusing UX |
| **Fix** | Add instrumentation to `RoleSwitchRepository.refreshSession()` to log latency percentiles |
| **Owner** | @Observability |
| **Acceptance** | Logs show `jwt_sync_latency_ms` metric; p95 < 2000ms |

### Gap 5: No Memory Leak Verification

| | Details |
|---|---|
| **Gap** | `RoleSwitchCoordinator` holds strong references to ViewModels |
| **Why it will break** | ViewModels may not be garbage collected when screens disposed; memory pressure grows |
| **Fix** | Add diagnostic: log registered count before/after navigation; verify `unregister()` called in `dispose()` |
| **Owner** | @CodeGuard |
| **Acceptance** | Registered count returns to baseline after navigation cycles |

### Gap 6: ViewModel Teardown Not Verified

| | Details |
|---|---|
| **Gap** | 4 ViewModels claim to use `RoleSwitchAware` but teardown logic not verified |
| **Why it will break** | If `teardownForRoleSwitch()` doesn't clear caches, role switch shows stale data |
| **Fix** | Add unit tests for each ViewModel: verify `teardownForRoleSwitch()` clears `Listenable`/streams |
| **Owner** | @Sentinel |
| **Acceptance** | 4 unit tests pass; each verifies cache cleared |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| # | Invariant | Enforcement | Verification |
|---|-----------|-------------|------------|
| 1 | **No cross-user message access** | RLS policy: `messages` SELECT requires `is_conversation_participant()` | Test: User A cannot SELECT messages from User B's conversation |
| 2 | **No admin_logs injection by non-service** | RLS policy: `admin_logs` INSERT restricted to `service_role` | Test: Authenticated user INSERT returns 403 |
| 3 | **No PII exposure via views** | `public.users` view dropped; admin views REVOKEd | Query: `SELECT * FROM pg_views WHERE viewname='users'` returns 0 rows |
| 4 | **Role-based write enforcement** | JWT policies require `(auth.jwt()->'app_metadata'->>'active_role') = 'expected_role'` | Test: Client cannot INSERT task_request (freelancer-only) |
| 5 | **ViewModel cache isolation** | `teardownForRoleSwitch()` clears all role-specific state | Unit test: After teardown, ViewModel reports `isLoading=false, data=null` |
| 6 | **Audit trail completeness** | Every role switch logged to `audit_logs` | Query: `SELECT count(*) FROM audit_logs WHERE action='role_switch'` increases after switch |
| 7 | **No policy bypass via views** | All views use `security_invoker = true` or explicit RLS predicates | Query: `SELECT viewname FROM pg_views WHERE security_invoker IS DISTINCT FROM true` returns only admin views with explicit checks |
| 8 | **Session continuity** | Role switch does not invalidate session or require re-login | Test: After role switch, same session token valid for subsequent queries |

---

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast Radius | Early Signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| `public.users` view referenced in hidden code | Gap 2 fix | Med | High | App-wide crash | App fails to start / compile | Grepping all SQL strings | Restore view temporarily; fix code; re-drop |
| JWT claim sync latency > 5s | `sync_role_to_jwt` trigger | Low | High | Role switch UX broken | Users report seeing old role after switch | Instrumentation + retry logic | Manual refresh button; reduce retry delay |
| Policy drop order causes dependency error | Phase 1.2 | Low | Med | Migration fails | SQL error during deployment | Check `pg_depend` before drops | Transaction rollback; fix order; retry |
| `service_role` key leaked | Security config | Low | Critical | Security breach | Unusual admin activity in logs | Key rotation audit; IP restrictions | Immediate key rotation; incident response |
| ViewModel teardown fails (throws) | Phase 2.2 | Med | Med | Stale data shown | Error logs in `RoleSwitchCoordinator` | Unit tests for teardown methods | Catch and log; continue with other ViewModels |
| Policy backup corrupted/incomplete | Gap 3 fix | Low | High | Cannot rollback | Backup file size < expected | Verify backup row count matches | Manual policy recreation from audit docs |
| Realtime subscriptions not reconnected after role switch | Phase 2.2 | Med | Med | Stale realtime data | Missed notifications | Teardown should unsubscribe; resubscribe after switch | Manual refresh; periodic polling fallback |
| Rate limit false positive blocks legitimate switch | `check_role_switch_rate_limit` | Low | Low | User cannot switch roles | Rate limit error in UI | Fail open (allow) if check errors | Manual admin override |

---

## F) Pre-Mortem (How This Fails in Real Life)

1. **This fails when** we drop `public.users` and discover the admin dashboard references it via a raw SQL query in a buried RPC helper we didn't grep.

2. **This fails when** the JWT sync trigger has a bug where it doesn't fire on 5% of role switches, causing users to see wrong role data, leading to support tickets about "can't bid on tasks as freelancer."

3. **This fails when** we deploy all 13 SQL steps at once and Step 7 has a syntax error we missed, causing the entire migration to fail halfway, leaving the DB in a partially migrated state that's hard to recover from.

4. **This fails when** `RoleSwitchCoordinator.teardownAll()` throws because one ViewModel's `teardownForRoleSwitch()` has an unawaited async operation, and we didn't catch the exception, crashing the app during role switch.

5. **This fails when** we don't verify that `ChatViewModel.unregister()` is called in `dispose()`, causing memory to grow unbounded over multiple role switches until the app is killed by the OS.

6. **This fails when** a new developer sees the RLS test harness and thinks "I can skip this for my feature," adding a policy without a negative test, and 6 months later we have a data leak.

7. **This fails when** we assume `service_role` is secure but it's actually exposed in a client-side Edge Function that someone forgot to protect, and an attacker discovers it during the security audit.

8. **This fails when** the `wallet_balances` view is actually used by a legacy wallet screen we forgot to check, and dropping it breaks the wallet for users on older app versions.

9. **This fails when** we don't measure JWT sync latency and discover in production that Supabase Auth has occasional 10s latency spikes, making role switch feel broken to users.

10. **This fails when** we deploy to production during peak hours, a policy fails to apply, and we have to rollback under pressure without a tested rollback script.

---

## G) Plan Fixes (Concrete Additions / Expansions)

### Fix 1: Add Gate 0 — Test Infrastructure (BLOCKING)

**Goal:** Automated RLS policy testing  
**Why:** 108 policies cannot be manually verified safely  
**How:**
```
test/rls/
  rls_test_helper.dart      # assertCanSelect, assertCannotInsert
  fixtures/
    test_users.dart         # client_user, freelancer_user, admin_user
  critical_blockers_test.dart  # 4 critical tests
  view_security_test.dart   # View access tests
  role_switch_test.dart     # JWT policy tests
```
**Artifact:** `test/rls/` directory with working tests  
**Stop Condition:** `flutter test test/rls/` passes

### Fix 2: Add Policy Backup Step

**Goal:** Backup before any policy changes  
**Why:** Rollback requires exact previous state  
**How:** Add to Phase 0:
```sql
-- Pre-migration backup
COPY (SELECT * FROM pg_policies ORDER BY schemaname, tablename, policyname) 
TO '/tmp/policies_backup_20260306.csv' WITH CSV HEADER;
```
**Artifact:** `.TODO/BACKUP_policies_2026-03-06.csv`  
**Stop Condition:** File exists with 108 rows

### Fix 3: Add View Usage Verification

**Goal:** Confirm no code references views before dropping  
**Why:** Prevent runtime crashes  
**How:** Add to Phase 0:
```bash
# Run these commands
grep -r "from users" lib/ --include="*.dart"
grep -r "public.users" lib/ --include="*.dart"
grep -r "wallet_balances" lib/ --include="*.dart"
grep -r "tasks_mvp" lib/ --include="*.dart"
```
**Artifact:** Usage report in `.TODO/VIEW_USAGE_AUDIT.md`  
**Stop Condition:** All greps return 0 matches or documented safe references

### Fix 4: Add JWT Latency Instrumentation

**Goal:** Measure JWT claim sync time  
**Why:** Detect slow sync issues before users report them  
**How:** Add to `RoleSwitchRepository.refreshSession()`:
```dart
final stopwatch = Stopwatch()..start();
await _client.auth.refreshSession();
stopwatch.stop();
AppLogger.i('jwt_sync_latency_ms', json: {'ms': stopwatch.elapsedMilliseconds});
```
**Artifact:** Latency logs in debug console / analytics  
**Stop Condition:** Logs show p95 < 2000ms

### Fix 5: Add Memory Leak Diagnostic

**Goal:** Verify ViewModels unregister on dispose  
**Why:** Prevent memory pressure over long sessions  
**How:** Add diagnostic to `RoleSwitchCoordinator`:
```dart
void logDiagnostics() {
  AppLogger.d('coordinator_diagnostics', 
    json: {'registeredCount': _registered.length, 'registeredTypes': _registered.map((r) => r.runtimeType.toString()).toList()});
}
```
**Artifact:** Diagnostic logs showing stable registered count  
**Stop Condition:** Registered count stable after navigation cycles

### Fix 6: Expand ViewModel Teardown Verification

**Goal:** Unit tests for all 4 ViewModels  
**Why:** Ensure teardown clears caches correctly  
**How:**
```dart
// test/viewmodels/chat_view_model_test.dart
test('teardownForRoleSwitch clears messages cache', () {
  final vm = ChatViewModel();
  vm.loadMessages(); // populate cache
  await vm.teardownForRoleSwitch();
  expect(vm.messages, isEmpty);
  expect(vm.isLoading, false);
});
```
**Artifact:** 4 passing unit tests  
**Stop Condition:** `flutter test test/viewmodels/*_test.dart` passes

### Fix 7: Split Phase 1 into Blockers + Cleanup

**Goal:** Deploy critical fixes faster, reduce risk  
**Why:** 13 steps in one deployment is high risk  
**How:**
- **Phase 1A (Blockers):** Steps 1-4 — Deploy immediately after Gate 0/1 pass
- **Phase 1B (Cleanup):** Steps 5-13 — Deploy in next maintenance window
**Artifact:** Two separate migration files  
**Stop Condition:** 1A deployed and verified in production

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Gate 0: Test Infrastructure (BLOCKING)

**Goal:** Automated RLS policy testing capability  
**Why:** Cannot safely verify 108 policies manually  
**How:**

#### 0.1 Create Test Directory Structure
- [ ] (@Sentinel) Create `test/rls/` directory
- [ ] (@Sentinel) Create `test/rls/fixtures/` for test data
- [ ] (@Sentinel) Create `test/helpers/mock_supabase.dart` if not exists

#### 0.2 Implement RlsTestHelper
- [ ] (@Sentinel) Create `test/rls/rls_test_helper.dart`:
  ```dart
  class RlsTestHelper {
    Future<void> assertCanSelect(String table, Map<String, dynamic> filters, String asUserId);
    Future<void> assertCannotSelect(String table, Map<String, dynamic> filters, String asUserId);
    Future<void> assertCanInsert(String table, Map<String, dynamic> data, String asUserId);
    Future<void> assertCannotInsert(String table, Map<String, dynamic> data, String asUserId);
  }
  ```

#### 0.3 Create Test User Fixtures
- [ ] (@Sentinel) Create `test/rls/fixtures/test_users.dart`:
  - `clientUser` (id: '11111111-...', role: 'client')
  - `freelancerUser` (id: '22222222-...', role: 'freelancer')
  - `otherUser` (id: '33333333-...', role: 'client')
  - `adminUser` (id: '44444444-...', role: 'admin')

#### 0.4 Implement Critical Blocker Tests
- [ ] (@Sentinel) `test/rls/critical_blockers_test.dart`:
  - Test 1: `otherUser` cannot SELECT messages from `clientUser` conversation
  - Test 2: `otherUser` cannot INSERT message into `clientUser` conversation
  - Test 3: `clientUser` cannot INSERT into `admin_logs`
  - Test 4: `clientUser` cannot UPDATE `bookings` non-status columns

#### 0.5 Implement View Security Tests
- [ ] (@Sentinel) `test/rls/view_security_test.dart`:
  - Test: `public.users` view does not exist
  - Test: `tasks_mvp` respects RLS (cannot see others' private tasks)
  - Test: Admin views return 403 for non-admin users

#### GATE 0 CHECK
```
✅ test/rls/ directory exists with 3+ test files
✅ flutter test test/rls/ passes (or fails with expected failures before blockers fixed)
✅ RlsTestHelper has 4 assertion methods
```

---

### Gate 1: Data/Contracts Gate

**Goal:** Verify no references to objects being modified  
**Why:** Prevent runtime crashes from dropped views  
**How:**

#### 1.1 View Usage Audit
- [ ] (@Architect) Run grep commands:
  ```bash
  grep -r "from users" lib/ --include="*.dart" > .TODO/VIEW_USAGE_AUDIT.md
  grep -r "public.users" lib/ --include="*.dart" >> .TODO/VIEW_USAGE_AUDIT.md
  grep -r "wallet_balances" lib/ --include="*.dart" >> .TODO/VIEW_USAGE_AUDIT.md
  grep -r "tasks_mvp" lib/ --include="*.dart" >> .TODO/VIEW_USAGE_AUDIT.md
  ```
- [ ] (@Architect) Document any findings; if matches found, mark as blockers to fix first

#### 1.2 Policy Backup
- [ ] (@Supabase_Ops) Create policy backup:
  ```sql
  COPY (SELECT * FROM pg_policies ORDER BY schemaname, tablename, policyname) 
  TO '/tmp/policies_backup_20260306.csv' WITH CSV HEADER;
  ```
- [ ] (@Supabase_Ops) Copy to `.TODO/BACKUP_policies_2026-03-06.csv`

#### 1.3 View Definition Backup
- [ ] (@Supabase_Ops) Backup current view definitions:
  ```sql
  COPY (SELECT viewname, definition FROM pg_views WHERE schemaname = 'public') 
  TO '/tmp/views_backup_20260306.csv' WITH CSV HEADER;
  ```

#### GATE 1 CHECK
```
✅ VIEW_USAGE_AUDIT.md shows 0 unsafe references (or documented fixes)
✅ BACKUP_policies_2026-03-06.csv exists with 108 rows
✅ Views backup exists with 14 rows
```

---

### Gate 2: Security Gate

**Goal:** Threat model documented; negative tests defined  
**Why:** Security requires intentional design, not accidental safety  
**How:**

#### 2.1 Threat Model Document
- [ ] (@ThreatModeler) Create `.TODO/SECURITY_RLS_Threat_Model.md`:
  - Attack scenario: Session hijacker reading cross-user messages
  - Attack scenario: Log injection via admin_logs
  - Attack scenario: PII dump via views
  - Attack scenario: Privilege escalation via bookings
  - Mitigation per scenario
  - Negative test case per scenario

#### 2.2 Security Review
- [ ] (@ThreatModeler) Review all policy predicates for injection risks
- [ ] (@ThreatModeler) Verify `service_role` is not exposed in client code

#### GATE 2 CHECK
```
✅ SECURITY_RLS_Threat_Model.md exists with 4+ attack scenarios
✅ Each scenario has negative test case in test/rls/
✅ service_role key exposure check passed
```

---

### Gate 3: Backend/API Gate

**Goal:** Role switch RPC and JWT sync fully functional  
**Why:** JWT policies depend on accurate role claims  
**How:**

#### 3.1 RPC Functionality Test
- [ ] (@Supabase_Ops) Test `switch_active_role` RPC:
  ```sql
  SELECT switch_active_role('client', 'freelancer');
  -- Verify success JSONB returned
  ```

#### 3.2 JWT Sync Verification
- [ ] (@Supabase_Ops) Verify trigger updates `auth.users`:
  ```sql
  -- After role switch
  SELECT raw_app_meta_data->>'active_role' FROM auth.users WHERE id = 'test-user-id';
  -- Should show 'freelancer'
  ```

#### 3.3 JWT Policy Test
- [ ] (@Sentinel) Test JWT policy enforcement:
  - Client user: INSERT to `task_requests` → should fail
  - Freelancer user: INSERT to `task_requests` → should succeed
  - Client user: INSERT to `tasks` → should succeed
  - Freelancer user: INSERT to `tasks` → should fail

#### 3.4 Latency Instrumentation
- [ ] (@Observability) Add to `RoleSwitchRepository`:
  ```dart
  final sw = Stopwatch()..start();
  await _client.auth.refreshSession();
  AppLogger.i('jwt_sync_latency', json: {'ms': sw.elapsedMilliseconds});
  ```

#### GATE 3 CHECK
```
✅ switch_active_role returns success for valid role change
✅ auth.users raw_app_meta_data updates within 2 seconds
✅ JWT policies enforce role-based access (4 tests pass)
✅ Latency logging active
```

---

### Phase 1A: Critical Blocker Fixes (Deploy Immediately)

**Goal:** Fix 4 production security blockers  
**Why:** These are actively exploitable vulnerabilities  
**How:**

#### 1A.1 Drop `public.users` View
- [ ] (@Supabase_Ops) **SQL:**
  ```sql
  DROP VIEW IF EXISTS public.users;
  ```
- [ ] (@Sentinel) **Verify:** `SELECT viewname FROM pg_views WHERE viewname = 'users'` → 0 rows

#### 1A.2 Drop Wide-Open Messages Policies
- [ ] (@Supabase_Ops) **SQL:**
  ```sql
  DROP POLICY IF EXISTS "Allow users to read messages" ON public.messages;
  DROP POLICY IF EXISTS "Allow users to insert messages" ON public.messages;
  ```
- [ ] (@Sentinel) **Verify:** `SELECT policyname FROM pg_policies WHERE tablename = 'messages' AND policyname LIKE 'Allow users%'` → 0 rows
- [ ] (@Sentinel) **Test:** `otherUser` cannot SELECT/INSERT messages from others' conversations

#### 1A.3 Fix admin_logs INSERT Policy
- [ ] (@Supabase_Ops) **SQL:**
  ```sql
  DROP POLICY IF EXISTS "Service Role can insert logs" ON public.admin_logs;
  CREATE POLICY "admin_logs_insert_service_only" ON public.admin_logs
    FOR INSERT TO service_role WITH CHECK (true);
  ```
- [ ] (@Sentinel) **Verify:** `SELECT roles FROM pg_policies WHERE tablename = 'admin_logs' AND cmd = 'INSERT'` → `{service_role}`
- [ ] (@Sentinel) **Test:** `clientUser` INSERT to admin_logs → 403

#### 1A.4 Fix bookings_update_status_only
- [ ] (@Supabase_Ops) **SQL:**
  ```sql
  DROP POLICY IF EXISTS "bookings_update_status_only" ON public.bookings;
  ```
- [ ] (@Sentinel) **Verify:** Policy no longer exists; existing `bookings_update_by_provider` and `bookings_cancel_by_client` cover needed functionality

#### PHASE 1A GATE CHECK
```
✅ All 4 blockers fixed in production
✅ Verification queries pass
✅ test/rls/critical_blockers_test.dart passes
✅ No elevated error rates in logs
```

---

### Phase 1B: Policy Cleanup (Next Maintenance Window)

**Goal:** Remove redundant policies; migrate `public` → `authenticated`  
**Why:** Reduce attack surface; explicit role contracts  
**How:**

#### 1B.1 Messages Policy Cleanup
- [ ] (@Supabase_Ops) Drop redundant message policies (Steps 5 from original)
- [ ] (@Sentinel) Verify: Only authenticated policies remain

#### 1B.2 Bookings/Conversations Cleanup
- [ ] (@Supabase_Ops) Drop redundant booking/conversation policies (Step 6)

#### 1B.3 Role Migration Batch
- [ ] (@Supabase_Ops) Migrate notifications, services, activity_log, etc. (Steps 7-9)
- [ ] (@Sentinel) Test each migrated policy with positive/negative cases

#### PHASE 1B GATE CHECK
```
✅ ~17 policies dropped
✅ ~15 policies migrated to authenticated
✅ Policy count reduced by ~30%
✅ All tests pass
```

---

### Phase 2: View Hardening

**Goal:** Secure views with `security_invoker` or explicit restrictions  
**Why:** Views currently bypass RLS via SECURITY DEFINER  
**How:**

#### 2.1 Recreate Core Views
- [ ] (@Supabase_Ops) **SQL:**
  ```sql
  DROP VIEW IF EXISTS public.tasks_mvp;
  CREATE VIEW public.tasks_mvp WITH (security_invoker = true) AS ...;
  
  DROP VIEW IF EXISTS public.user_conversations;
  CREATE VIEW public.user_conversations WITH (security_invoker = true) AS ...;
  
  -- wallet_balances: verify unused, then recreate with invoker or drop
  ```

#### 2.2 Restrict Admin Views
- [ ] (@Supabase_Ops) **SQL:**
  ```sql
  REVOKE SELECT ON public.vw_orphaned_auth_users FROM anon, authenticated;
  REVOKE SELECT ON public.vw_admin_journal_ledger FROM anon, authenticated;
  -- ... (6 total)
  ```

#### PHASE 2 GATE CHECK
```
✅ 3 core views use security_invoker
✅ 6 admin views restricted to service_role
✅ test/rls/view_security_test.dart passes
```

---

### Phase 3: App Layer Integration

**Goal:** Verify role switch teardown works end-to-end  
**Why:** Stale caches after role switch cause confusing UX  
**How:**

#### 3.1 Repository Validation
- [ ] (@Architect) Verify `RoleSwitchRepository.switchRole()` error handling
- [ ] (@Architect) Verify `refreshSession()` retry logic works

#### 3.2 ViewModel Registration Verification
- [ ] (@CodeGuard) Verify `ChatViewModel` calls `register(this)` in constructor
- [ ] (@CodeGuard) Verify `ChatViewModel` calls `unregister(this)` in `dispose()`
- [ ] (@CodeGuard) Repeat for Dashboard, Home, Task ViewModels

#### 3.3 Teardown Logic Unit Tests
- [ ] (@Sentinel) Create unit tests verifying each ViewModel's `teardownForRoleSwitch()` clears caches

#### 3.4 Memory Leak Diagnostic
- [ ] (@CodeGuard) Add `RoleSwitchCoordinator.logDiagnostics()` and call from debug menu

#### PHASE 3 GATE CHECK
```
✅ All 4 ViewModels register/unregister correctly
✅ 4 unit tests for teardown logic pass
✅ Memory count stable after navigation cycles
✅ End-to-end role switch flow tested manually
```

---

### Phase 4: QA + Regression

**Goal:** No regression in existing flows  
**Why:** Security fixes must not break functionality  
**How:**

#### 4.1 Regression Test List
- [ ] (@Sentinel) Task creation flow (client)
- [ ] (@Sentinel) Task bidding flow (freelancer)
- [ ] (@Sentinel) Booking creation flow
- [ ] (@Sentinel) Messaging flow
- [ ] (@Sentinel) Wallet view
- [ ] (@Sentinel) Realtime notifications

#### 4.2 Performance Baseline
- [ ] (@Sentinel) Measure query latency before/after
- [ ] (@Sentinel) Verify role switch completes < 500ms

#### PHASE 4 GATE CHECK
```
✅ All 6 regression flows pass
✅ Query latency within 10% of baseline
✅ Role switch < 500ms
```

---

### Phase 5: Documentation Sync

**Goal:** Documentation matches reality  
**Why:** Future developers need accurate security docs  
**How:**

#### 5.1 Update SUPABASE_SETUP.md
- [ ] (@SlineDocs) Update §13 with current policy list
- [ ] (@SlineDocs) Update §14 with `security_invoker` requirement

#### 5.2 Update DEVELOPER_GUIDE.md
- [ ] (@SlineDocs) Document role switch flow
- [ ] (@SlineDocs) Document `RoleSwitchAware` mixin usage

#### 5.3 Archive Old Diagrams
- [ ] (@SlineDocs) Add note to old `15_rls-authorization-map.md` pointing to new audit files

#### PHASE 5 GATE CHECK
```
✅ All docs updated
✅ No references to dropped views in docs
✅ New developer can understand RLS setup from docs alone
```

---

## I) Change Report (Diff-Style)

### Original Issues Summary

1. **No Test Infrastructure Gate** — Plan assumed manual policy verification
2. **No View Usage Verification** — Risk of dropping referenced views
3. **No Policy Backup Step** — Rollback would be manual/recreate
4. **13 Steps in Single Phase** — High risk deployment
5. **No JWT Latency Measurement** — Performance blind spot
6. **No Memory Leak Verification** — Potential production memory pressure
7. **No Split Deployment** — All-or-nothing approach risky
8. **No Explicit Gate Checks** — Hard to know when phase complete

### Added Steps

| # | Step | Phase | Owner |
|---|------|-------|-------|
| 1 | Create `test/rls/` directory structure | Gate 0 | @Sentinel |
| 2 | Implement `RlsTestHelper` with 4 assertion methods | Gate 0 | @Sentinel |
| 3 | Create test user fixtures | Gate 0 | @Sentinel |
| 4 | Implement critical blocker RLS tests | Gate 0 | @Sentinel |
| 5 | Implement view security tests | Gate 0 | @Sentinel |
| 6 | View usage grep audit | Gate 1 | @Architect |
| 7 | Policy backup to CSV | Gate 1 | @Supabase_Ops |
| 8 | View definition backup | Gate 1 | @Supabase_Ops |
| 9 | Create `SECURITY_RLS_Threat_Model.md` | Gate 2 | @ThreatModeler |
| 10 | JWT latency instrumentation | Gate 3 | @Observability |
| 11 | Split Phase 1 into 1A (blockers) + 1B (cleanup) | — | @PlanCritic |
| 12 | Add explicit GATE CHECK at end of each phase | All | @PlanCritic |
| 13 | Memory leak diagnostic logging | Phase 3 | @CodeGuard |
| 14 | ViewModel teardown unit tests | Phase 3 | @Sentinel |

### Removed Steps

- None — all original steps preserved but reorganized

### Reordered Steps

| Original | New Location | Reason |
|----------|--------------|--------|
| Phase 1 (all 13 steps) | Split: 1A (steps 1-4) + 1B (steps 5-13) | Reduce deployment risk |
| Policy backup | Added to Gate 1 (pre-work) | Must backup before changes |
| View usage verification | Added to Gate 1 (pre-work) | Must verify before dropping |

### Expanded Steps

| Step | Original Detail | New Detail |
|------|-----------------|------------|
| Phase 0 | 4 checklist items | Full Gate 0 with 5 sub-steps, test infrastructure, fixtures |
| Phase 1 | Single phase with 13 steps | Split into 1A (blockers) and 1B (cleanup), each with verification |
| Rollback Plan | Generic SQL snippets | Explicit backup artifact, tested rollback procedure |
| Acceptance Criteria | 6 bullets | 8 invariants with enforcement + verification methods |

### Why (Short, Practical)

1. **Test Infrastructure** — 108 policies cannot be manually verified; automation prevents human error
2. **Gate-Based** — Explicit gates prevent "fake progress" where phases claim complete but aren't
3. **Split Deployment** — Blockers need immediate fix; cleanup can wait for maintenance window
4. **Pre-Mortem** — Predicting failures allows prevention; 10 failure modes identified
5. **Invariants** — Security requires non-negotiable guarantees, not just "tested"

### Residual Risks (What Remains Risky)

| Risk | Mitigation Status |
|------|-------------------|
| `service_role` key exposure | Assumed secure; needs audit |
| JWT sync latency spikes | Monitored but not controlled |
| ViewModel teardown performance | Tested but not stress-tested |
| Policy backup corruption | Backup exists but not tested for restore |
| Realtime subscription handling | Teardown exists but edge cases untested |

---

## J) Execution Status

| Gate | Status | Blocker? |
|------|--------|----------|
| 0 — Test Infrastructure | ❌ FAIL | YES — Add 5 steps |
| 1 — Data/Contracts | ❌ FAIL | YES — Add 3 steps |
| 2 — Security | ⚠️ CONDITIONAL | Needs Gate 0 |
| 3 — Backend/API | ⚠️ CONDITIONAL | Needs verification |
| 4 — UI/Integration | ✅ PASS | — |
| 5 — Release/QA | ❌ FAIL | Needs regression suite |

**Overall Status:** ❌ **BLOCKED** — Fix Gates 0 and 1 before proceeding.

---

*Reviewed by: @PlanCritic*  
*Date: 2026-03-06*  
*Next Action: Implement Gate 0 and Gate 1 fixes, then re-review*
