# 📌 Plan: RLS Authorization Map Implementation

## 1) Goal

- **Goal**: Harden database security by implementing a comprehensive RLS Authorization Map that fixes critical security blockers, removes redundant policies, and establishes proper role-based access control using JWT claims.
- **Why**: Current production database has 4 CRITICAL security issues including wide-open message access, PII exposure via views, and overly permissive policies on the `public` role.
- **Result**: A secure database with 108 properly-scoped policies across 27 tables, hardened views, JWT-based role-aware access control, and comprehensive audit logging.

---

## 2) Scope

### In-Scope

1. **Critical Security Fixes (Blockers)**
   - Drop `public.users` view exposing `auth.users` PII
   - Remove wide-open `messages` policies (`Allow users to read/insert messages`)
   - Fix `admin_logs` INSERT policy on `public` role
   - Fix `bookings_update_status_only` NULL `with_check`

2. **Role Migration (`public` → `authenticated`)**
   - Drop 17 redundant `public` policies
   - Migrate ~15 policies from `public` to `authenticated` role
   - Keep 2 justified `public` policies (profiles INSERT, bookings deny_delete)

3. **View Hardening**
   - Recreate 3 SECURITY DEFINER views with `security_invoker = true`
   - Restrict 6 admin/analytics views to service_role only
   - Remove/restrict `vw_orphaned_auth_users` exposing auth emails

4. **JWT-Based RLS Policies**
   - Deploy already-created JWT policies for role-aware access control
   - Ensure `switch_active_role` RPC and JWT sync trigger are functional

5. **Validation & Testing**
   - RLS leak audit for all 27 tables
   - View bypass verification
   - Role switch integration tests

### Out-of-Scope

1. New feature development (this is hardening only)
2. UI/UX changes (backend security only)
3. Storage policy changes (already verified secure)
4. New RPC functions (beyond existing `switch_active_role`)
5. Schema migrations (no new tables/columns)

---

## 3) Evidence & Findings (From Scan)

### Existing

**Documentation:**
- `.TODO/improvement_the_system/15_rls-authorization-map/00_VERDICT.md` — Audit verdict with score comparison
- `.TODO/improvement_the_system/15_rls-authorization-map/01_FULL_POLICY_MAP.md` — All 108 policies with predicates
- `.TODO/improvement_the_system/15_rls-authorization-map/02_VIEW_BYPASS_AUDIT.md` — 14 views security assessment
- `.TODO/improvement_the_system/15_rls-authorization-map/03_ROLE_MIGRATION_PLAN.md` — Policy-by-policy migration list
- `.TODO/improvement_the_system/15_rls-authorization-map/04_STORAGE_POLICY_AUDIT.md` — Storage policy verification
- `.TODO/improvement_the_system/15_rls-authorization-map/05_MINIMAL_PATCH_PLAN.md` — Executable SQL with verification

**Code:**
- `lib/core/services/role_switch_coordinator.dart` — Coordinator for cross-ViewModel teardown
- `lib/core/mixins/role_switch_aware.dart` — Mixin for role-switch-aware ViewModels
- `lib/features/profile/data/role_switch_repository.dart` — Repository for role switch RPC
- `lib/features/profile/models/role_switch_result.dart` — Result model for role switch

**Database (Live Scan from 00_VERDICT.md):**
- 27 tables with RLS enabled
- 108 policies total (mix of `public`, `authenticated`, `service_role`)
- 14 views (mix of safe and vulnerable)
- 14 storage policies (all `authenticated`, verified secure)
- Migration: `20260306_role_switch_foundation.sql` with RPC, trigger, and JWT policies

### Missing

1. No comprehensive RLS test suite covering negative cases
2. No automated verification that views use `security_invoker`
3. No monitoring/alerting for policy violations

### Conflicts / Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Dropping `public.users` view may break existing queries | HIGH | Verify no app code references this view before dropping |
| Dropping redundant policies may break edge cases | MEDIUM | Each policy verified redundant via predicate analysis |
| Role migration timing with active sessions | MEDIUM | Changes are additive; old policies remain until explicitly dropped |
| JWT claim sync latency | LOW | Session refresh after role switch; retry logic exists |

---

## 4) System Impact Map

| Layer | Impact |
|-------|--------|
| **UI** | None — all changes are backend security |
| **MVVM/App Logic** | Minor — ViewModels using `RoleSwitchAware` mixin already exist; ProfileViewModel triggers teardown |
| **Database** | Major — 108 policies reviewed; ~20+ policies dropped/created; 14 views modified |
| **RLS/Security** | Major — Critical blockers fixed; role-based access enforced |
| **Realtime/Notifications** | None — realtime uses same RLS policies |
| **Storage** | None — already verified secure |
| **Observability** | Audit logging enhanced via `audit_logs` entries on role switch |
| **Compatibility** | Sessions during migration remain valid; new policies apply to new queries |
| **Contracts** | No API contract changes; all changes internal to Supabase |

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> **Primary:** @Sentinel  
> **Secondary:** @ThreatModeler (security review), @DataMigration (policy migration safety)

### 0.1 Spec Lock

- [ ] (@Sentinel) Confirm acceptance criteria from 00_VERDICT.md blockers
- [ ] (@Sentinel) Define non-regression list: all existing app flows must pass
- [ ] (@Sentinel) Document rollback triggers: app errors, RLS failures, elevated error rates
- [ ] (@Architect) Confirm no app code references `public.users` view
- **Verify (@Sentinel):** Checklist complete, rollback plan documented

### 0.2 Threat Model

- [ ] (@ThreatModeler) Document attack scenarios:
  - Attacker with valid session reading others' messages
  - Attacker injecting admin_logs entries
  - Attacker accessing all users' PII via `public.users`
  - Attacker updating arbitrary booking columns
- [ ] (@ThreatModeler) Define negative test cases for each scenario
- [ ] (@ThreatModeler) Create threat model file in `.TODO/SECURITY_RLS_Threat_Model.md`
- **Verify (@Sentinel):** All 4 critical risks have testable mitigations

### 0.3 Migration Safety Plan

- [ ] (@DataMigration) Document policy drop order (dependencies check)
- [ ] (@DataMigration) Verify no foreign key or trigger dependencies on target policies
- [ ] (@DataMigration) Create migration verification queries
- **Verify (@Sentinel):** Migration can run in single transaction; rollback script ready

### 0.4 Feature Flag/Rollout Strategy

- [ ] (@Supabase_Ops) Deploy to staging first; run full app E2E suite
- [ ] (@Supabase_Ops) Plan production deployment during low-traffic window
- **Verify (@Sentinel):** Staging validation passed before production

---

## Phase 1: Database & Security — Critical Fixes

> **Primary:** @Supabase_Ops  
> **Verify:** @Sentinel

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via MCP: list all policies on `messages`, `admin_logs`, `bookings`
- [ ] (@Supabase_Ops) Confirm `public.users` view still exists
- [ ] (@Supabase_Ops) Verify view ownership and `security_invoker` status on `tasks_mvp`, `user_conversations`, `wallet_balances`
- **Verify (@Sentinel):** Drift documented; no unexpected objects found

### 1.1 Blocker Fixes (Deploy Immediately)

- [ ] (@Supabase_Ops) **Step 1:** Drop `public.users` view
  ```sql
  DROP VIEW IF EXISTS public.users;
  ```
- [ ] (@Supabase_Ops) **Step 2:** Drop wide-open messages policies
  ```sql
  DROP POLICY IF EXISTS "Allow users to read messages" ON public.messages;
  DROP POLICY IF EXISTS "Allow users to insert messages" ON public.messages;
  ```
- [ ] (@Supabase_Ops) **Step 3:** Fix admin_logs INSERT policy
  ```sql
  DROP POLICY IF EXISTS "Service Role can insert logs" ON public.admin_logs;
  CREATE POLICY "admin_logs_insert_service_only" ON public.admin_logs
    FOR INSERT TO service_role WITH CHECK (true);
  ```
- [ ] (@Supabase_Ops) **Step 4:** Fix bookings_update_status_only
  ```sql
  DROP POLICY IF EXISTS "bookings_update_status_only" ON public.bookings;
  -- Redundant with bookings_update_by_provider and bookings_cancel_by_client
  ```
- **Verify (@Sentinel):** Run verification queries; confirm 0 rows for dropped objects

### 1.2 Redundant Policy Cleanup

- [ ] (@Supabase_Ops) **Step 5:** Drop redundant messages policies
  ```sql
  DROP POLICY IF EXISTS "Users can insert their own messages" ON public.messages;
  DROP POLICY IF EXISTS "Users can view their messages" ON public.messages;
  DROP POLICY IF EXISTS "Users can view their conversation messages" ON public.messages;
  DROP POLICY IF EXISTS "Users can delete their own messages" ON public.messages;
  ```
- [ ] (@Supabase_Ops) **Step 6:** Drop redundant bookings/conversations policies
  ```sql
  DROP POLICY IF EXISTS "bookings_insert_client" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_select_parties" ON public.bookings;
  DROP POLICY IF EXISTS "Allow users to read conversations" ON public.conversations;
  DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
  DROP POLICY IF EXISTS "Users can insert conversation if they are a participant" ON public.conversations;
  ```
- **Verify (@Sentinel):** Policy count reduced by ~17; no `public` role on messages/bookings/conversations except justified cases

### 1.3 Role Migration (public → authenticated)

- [ ] (@Supabase_Ops) **Step 7:** Migrate notifications policies
  ```sql
  -- Drop public versions
  DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
  DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
  -- Create authenticated versions (same predicates)
  CREATE POLICY "notifications_select_authenticated" ON public.notifications
    FOR SELECT TO authenticated USING (user_id = auth.uid());
  CREATE POLICY "notifications_update_authenticated" ON public.notifications
    FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  ```
- [ ] (@Supabase_Ops) **Step 8:** Migrate services policies
  ```sql
  -- Drop all 5 public policies
  DROP POLICY IF EXISTS "Public can view active services" ON public.services;
  DROP POLICY IF EXISTS "Freelancers can view own services" ON public.services;
  DROP POLICY IF EXISTS "Freelancers can insert own services" ON public.services;
  DROP POLICY IF EXISTS "Freelancers can update own services" ON public.services;
  DROP POLICY IF EXISTS "Freelancers can delete own services" ON public.services;
  -- Recreate with authenticated + add with_check for UPDATE
  CREATE POLICY "services_select_authenticated" ON public.services
    FOR SELECT TO authenticated USING (status = 'active' OR auth.uid() = freelancer_id);
  CREATE POLICY "services_insert_authenticated" ON public.services
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = freelancer_id);
  CREATE POLICY "services_update_authenticated" ON public.services
    FOR UPDATE TO authenticated USING (auth.uid() = freelancer_id) WITH CHECK (auth.uid() = freelancer_id);
  CREATE POLICY "services_delete_authenticated" ON public.services
    FOR DELETE TO authenticated USING (auth.uid() = freelancer_id);
  ```
- [ ] (@Supabase_Ops) **Step 9:** Migrate remaining tables (activity_log, change_requests, extension_requests, work_contracts, work_logs, wallet_transactions)
  - Each: drop public policy, create authenticated equivalent
  - Copy exact `qual` and `with_check` predicates
- **Verify (@Sentinel):** All migrated policies tested with positive/negative cases

### 1.4 View Hardening

- [ ] (@Supabase_Ops) **Step 10:** Recreate SECURITY DEFINER views with security_invoker
  ```sql
  -- tasks_mvp
  DROP VIEW IF EXISTS public.tasks_mvp;
  CREATE VIEW public.tasks_mvp WITH (security_invoker = true) AS
  SELECT id, owner_id AS client_id, title, description, category_id, budget_cents,
         status, created_at, image_paths, assigned_freelancer_id, deadline, skills, task_type
  FROM tasks;
  
  -- user_conversations
  DROP VIEW IF EXISTS public.user_conversations;
  CREATE VIEW public.user_conversations WITH (security_invoker = true) AS
  SELECT id, task_id, user1_id, user2_id, created_at
  FROM conversations c
  WHERE user1_id = auth.uid() OR user2_id = auth.uid();
  
  -- wallet_balances (legacy - verify not used before dropping)
  DROP VIEW IF EXISTS public.wallet_balances;
  ```
- [ ] (@Supabase_Ops) **Step 11:** Restrict admin/analytics views
  ```sql
  REVOKE SELECT ON public.vw_orphaned_auth_users FROM anon, authenticated;
  REVOKE SELECT ON public.vw_admin_journal_ledger FROM anon, authenticated;
  REVOKE SELECT ON public.vw_financial_metrics_realtime FROM anon, authenticated;
  REVOKE SELECT ON public.vw_financial_metrics_period FROM anon, authenticated;
  REVOKE SELECT ON public.vw_analytics_monthly_revenue FROM anon, authenticated;
  REVOKE SELECT ON public.vw_analytics_monthly_user_growth FROM anon, authenticated;
  ```
- **Verify (@Sentinel):** Views recreate without errors; GRANTs removed successfully

### 1.5 JWT Policy Deployment

- [ ] (@Supabase_Ops) **Step 12:** Verify existing JWT policies from `20260306_role_switch_foundation.sql`
  - `task_requests_insert_freelancer_jwt`
  - `availability_slots_insert_freelancer_jwt`
  - `availability_slots_update_freelancer_jwt`
  - `tasks_insert_client_jwt`
- [ ] (@Supabase_Ops) **Step 13:** Test role switch RPC end-to-end
  - Call `switch_active_role('client', 'freelancer')`
  - Verify JWT claim updated
  - Verify task_requests INSERT allowed for freelancer, blocked for client
- **Verify (@Sentinel):** JWT policies active; role switching functional

---

## Phase 2: App Layer (MVVM) — Integration

> **Primary:** @Architect  
> **Verify:** @Sentinel

### 2.1 Role Switch Repository Validation

- [ ] (@Architect) Verify `RoleSwitchRepository.switchRole()` calls correct RPC
- [ ] (@Architect) Verify `refreshSession()` retry logic handles JWT sync latency
- [ ] (@Architect) Verify `verifyJwtRole()` correctly decodes and checks claims
- **Verify (@Sentinel):** Repository methods have error handling and logging

### 2.2 ViewModel Teardown Registration

- [ ] (@Architect) Ensure `ChatViewModel` uses `RoleSwitchAware` mixin and registers
- [ ] (@Architect) Ensure `DashboardViewModel` uses `RoleSwitchAware` mixin and registers
- [ ] (@Architect) Ensure `HomeViewModel` uses `RoleSwitchAware` mixin and registers
- [ ] (@Architect) Ensure `TaskViewModel` uses `RoleSwitchAware` mixin and registers
- [ ] (@Architect) Verify each ViewModel's `teardownForRoleSwitch()` clears role-specific caches
- **Verify (@Sentinel):** All 4 ViewModels register and teardown correctly

### 2.3 Profile ViewModel Integration

- [ ] (@Architect) Verify `ProfileViewModel` triggers `RoleSwitchCoordinator().teardownAll()` on role switch
- [ ] (@Architect) Verify error handling for `RoleSwitchTeardownException`
- **Verify (@Sentinel):** End-to-end role switch flow tested

---

## Phase 3: UI — No Changes Required

> **Primary:** @Pixel (verification only)  
> **Verify:** @Sentinel

### 3.1 Verification

- [ ] (@Sentinel) Confirm no UI code references `public.users` view directly
- [ ] (@Sentinel) Confirm no UI code bypasses ViewModels for Supabase calls
- **Verify (@Sentinel):** No UI layer changes required

---

## Phase 4: QA + Security (MANDATORY)

> **Primary:** @Sentinel  
> **Secondary:** @ThreatModeler (negative tests)

### 4.1 Policy Verification

- [ ] (@Sentinel) **Test 1:** Messages SELECT without conversation participation → should fail
- [ ] (@Sentinel) **Test 2:** Messages INSERT without conversation participation → should fail
- [ ] (@Sentinel) **Test 3:** admin_logs INSERT as authenticated (not service_role) → should fail
- [ ] (@Sentinel) **Test 4:** Bookings UPDATE non-status columns as client → should fail
- **Verify (@Sentinel):** All 4 critical blockers verified blocked

### 4.2 View Security Tests

- [ ] (@Sentinel) **Test 5:** `public.users` view no longer exists
- [ ] (@Sentinel) **Test 6:** `tasks_mvp` view with `security_invoker` respects RLS
- [ ] (@Sentinel) **Test 7:** Admin/analytics views return 403 for authenticated role
- **Verify (@Sentinel):** No PII exposure via views

### 4.3 Role Switch Integration Tests

- [ ] (@Sentinel) **Test 8:** Client cannot INSERT task_request (freelancer-only via JWT policy)
- [ ] (@Sentinel) **Test 9:** Freelancer cannot INSERT task (client-only via JWT policy)
- [ ] (@Sentinel) **Test 10:** Role switch updates JWT claim within 2 seconds
- **Verify (@Sentinel):** Role-based access control functional

### 4.4 Regression Tests

- [ ] (@Sentinel) **Test 11:** Existing user flows (task creation, booking, messaging) still work
- [ ] (@Sentinel) **Test 12:** Realtime subscriptions receive updates correctly
- [ ] (@Sentinel) **Test 13:** Storage uploads/downloads work for authenticated users
- **Verify (@Sentinel):** No functional regression

### 4.5 Performance Check

- [ ] (@Sentinel) **Test 14:** Query performance unchanged (no N+1 from policy predicates)
- [ ] (@Sentinel) **Test 15:** Role switch completes within 500ms
- **Verify (@Sentinel):** No performance regression

---

## Phase 5: Documentation Sync (MANDATORY)

> **Primary:** @DocsKeeper  
> **Verify:** @Sentinel

- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` §13 (RLS policies) with new policy list
- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` §14 (Views) with security_invoker requirement
- [ ] (@DocsKeeper) Add JWT-based RLS policy documentation
- [ ] (@DocsKeeper) Document role switch flow in `Sline_everything/DEVELOPER_GUIDE.md`
- [ ] (@DocsKeeper) Archive old `15_rls-authorization-map.md` diagram; reference new audit files
- **Verify (@Sentinel):** All docs match live DB reality

---

## 7) Acceptance Criteria (MANDATORY)

| Criterion | Measurement |
|-----------|-------------|
| **Correctness** | All 4 critical security blockers resolved; no regression in existing flows |
| **Security** | 100% of policies use appropriate roles; no `public` role on sensitive tables (messages, bookings) except justified cases |
| **UX Stability** | Role switch completes in < 500ms; app state correctly reset; no user-visible errors |
| **Performance** | Query response times within 10% of baseline; no N+1 regressions |
| **Compatibility** | Existing sessions remain valid; no forced logout required for deployment |
| **Observability** | Role switches logged to `audit_logs`; JWT sync events tracked; errors logged with context |

---

## 8) Rollback Plan

### DB Rollback

If critical issues discovered post-deployment:

1. **Immediate (if data corruption risk):**
   ```sql
   -- Restore admin_logs policy temporarily (allows wider access but unblocks logging)
   CREATE POLICY "admin_logs_insert_service_only_emergency" ON public.admin_logs
     FOR INSERT TO authenticated WITH CHECK (true);
   ```

2. **Full Rollback Script (saved in `.TODO/ROLLBACK_RLS_Map.sql`):**
   - Recreate `public.users` view (if truly needed, though not recommended)
   - Restore dropped policies from backup (create temporary policies with `_backup` suffix before Phase 1)
   - Revert view changes (restore SECURITY DEFINER if needed)

### App Rollback

1. No app code changes in this plan — no app rollback needed
2. If JWT policies cause issues, temporarily disable by removing role checks (keep auth.uid checks)

### Emergency Contacts

- Security issues: Immediate escalation
- Policy failures: @Supabase_Ops can disable specific policies via SQL

---

## 9) References (From Scan)

### Documentation
- `.TODO/improvement_the_system/15_rls-authorization-map/00_VERDICT.md`
- `.TODO/improvement_the_system/15_rls-authorization-map/01_FULL_POLICY_MAP.md`
- `.TODO/improvement_the_system/15_rls-authorization-map/02_VIEW_BYPASS_AUDIT.md`
- `.TODO/improvement_the_system/15_rls-authorization-map/03_ROLE_MIGRATION_PLAN.md`
- `.TODO/improvement_the_system/15_rls-authorization-map/04_STORAGE_POLICY_AUDIT.md`
- `.TODO/improvement_the_system/15_rls-authorization-map/05_MINIMAL_PATCH_PLAN.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/DEVELOPER_GUIDE.md`

### Code
- `lib/core/services/role_switch_coordinator.dart`
- `lib/core/mixins/role_switch_aware.dart`
- `lib/features/profile/data/role_switch_repository.dart`
- `lib/features/profile/models/role_switch_result.dart`
- `lib/features/chat/viewmodels/chat_view_model.dart`
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
- `lib/features/home/viewmodels/home_view_model.dart`
- `lib/features/tasks/viewmodels/task_view_model.dart`

### Database
- `supabase/migrations/20260306_role_switch_foundation.sql`
- Live Supabase scan (108 policies, 14 views, 27 tables) — evidence in 00_VERDICT.md

---

## 10) Agent Assignment Summary

| Phase | Primary Agent | Secondary Agents |
|-------|---------------|------------------|
| 0 — Preconditions | @Sentinel | @ThreatModeler, @DataMigration |
| 1 — Database & Security | @Supabase_Ops | @Sentinel (verification) |
| 2 — App Layer | @Architect | @Sentinel |
| 3 — UI | @Pixel (verification) | @Sentinel |
| 4 — QA + Security | @Sentinel | @ThreatModeler |
| 5 — Documentation | @DocsKeeper | @Sentinel |

---

*Plan created: 2026-03-06*  
*Based on: 15_rls-authorization-map audit evidence*  
*Next step: Review and approval, then Phase 0 execution*
