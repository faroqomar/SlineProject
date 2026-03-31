# 📌 Plan: Work Contract Revisions (RPC Hardening)

## 1) Goal

- **Goal:** Harden `rpc_request_revision` with state and revision-cap guards so clients cannot trap escrow via infinite revisions or corrupt workflow state.
- **Why:** Current RPC lacks (1) `status = 'delivered'` check and (2) `revisions_used < revisions_total` check; docs and diagrams claim these guards exist. This creates escrow-trapping and state-machine corruption risks.
- **Result:** DB enforces “revision only on delivered” and “no revision when cap reached”; app surfaces clear user messages and UI reflects limits.

## 2) Scope

### In-Scope

- Add state guard (`status = 'delivered'`) and hard-cap guard (`revisions_used < revisions_total`) to `rpc_request_revision` for both `task` and `booking` in a new migration.
- Map new RPC exception messages in `ErrorMapper` and ensure ViewModel/UI show them (no generic “Database error”).
- Optional: idempotency/token for double-click protection (document as follow-up if not in this plan).
- Document and verify with DB + Flutter tests per `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/04_TEST_PLAN.md` and `07_SYSTEM_CRITIC_VERDICT.md`.
- Update `SUPABASE_SETUP.md` and any work flow docs to match implemented behavior.
- No schema table/column additions; only function replacement (additive guards).

### Out-of-Scope

- Contract freeze / `trg_freeze_contract_fields` changes (separate audit).
- Change request flow (`rpc_accept_change_request`) logic changes.
- Admin tooling for “revisions exhausted” disputes (future phase).
- Realtime/notifications changes (existing notify behavior unchanged).

## 3) Evidence & Findings (From Scan)

### Existing

- **Migration:** `supabase/migrations/20260305180100_work_revision_and_change_rpcs.sql` — defines `rpc_request_revision(entity_type, entity_id, p_note)`. Has client check (`auth.uid() = client_id`), no `status = 'delivered'` check, no `revisions_total` check; unconditionally UPDATEs to `active` and increments `revisions_used`.
- **Service:** `lib/features/work/services/work_management_service.dart` — `requestRevision()` calls `_supabase.rpc('rpc_request_revision', params: entity_type, entity_id, p_note)`; rethrows; no special handling for revision-limit or state errors.
- **ViewModel:** `lib/features/work/viewmodels/work_item_details_view_model.dart` — `requestRevision(note)` calls `_workService.requestRevision(...)`; caller in `lib/features/work/view/work_item_details_screen.dart` (e.g. line ~634) awaits `vm.requestRevision(reason)`.
- **Error mapping:** `lib/core/utils/error_mapper.dart` — no specific handling for “Can only request revision on delivered work”, “No revisions remaining”, or “Only client can request revision”; PostgrestException falls to default “Database error occurred”.
- **Docs:** `Sline_everything/SUPABASE_SETUP.md` §9.2 describes `rpc_request_revision` as “Resets status='active', increments revisions_used”; §1 Key Business Rules states “Revision requests check limit before resetting status” — **intent only**, not implemented in current RPC.
- **Spec folder:** `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/` — `00_HOLISTIC_REPORT.md`, `02_GAPS_AND_FIXES.md`, `03_RISK_REGISTER.md`, `04_TEST_PLAN.md`, `07_SYSTEM_CRITIC_VERDICT.md` define required guards, tests, and minimal patch.

### Missing

- Migration that adds state + cap guards to `rpc_request_revision` (no such migration in repo).
- `ErrorMapper` branches for revision-related P0001 messages.
- DB-level tests (e.g. in repo or runbook) that assert failure when `status != 'delivered'` and when `revisions_used >= revisions_total`.
- Flutter unit/widget test that asserts “No revisions remaining” is shown when RPC returns that exception.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- **Docs vs code:** SUPABASE_SETUP claims “Revision requests check limit”; RPC does not. Plan fixes RPC to match docs.
- **Live DB:** Planner requires live Supabase scan at execution time (tables `tasks`/`bookings` columns `revisions_used`, `revisions_total`, `status`; function `rpc_request_revision`) to confirm no drift before applying new migration. If `revisions_total` is missing on a table, migration must add it or guard with COALESCE (spec uses COALESCE in guard).
- **Security:** No new RPC surface; same SECURITY DEFINER, same client check. New guards only tighten behavior.
- **Migration risk:** Replace function only; no table drops/renames. Rollback = redeploy previous function body.

## 4) System Impact Map

- **UI:** Work item detail “Request revision” flow; error snackbar/dialog must show “No revisions remaining” / “Can only request revision on delivered work” (or equivalent) instead of generic error when RPC raises.
- **MVVM/App Logic:** ViewModel continues to call `WorkManagementService.requestRevision`; service continues to call RPC and rethrow; ViewModel/View should use `ErrorMapper.map(e)` so new messages appear. Optional: ViewModel exposes “revisions remaining” from work item model so UI can hide/disable “Request revision” when 0 remaining (consistency with DB).
- **Database:** Single function replacement: `rpc_request_revision` — add two IF guards (status, cap) before existing UPDATE for both task and booking branches.
- **RLS/Security:** Unchanged; RPC remains SECURITY DEFINER with same auth.uid() checks.
- **Realtime/Notifications:** No change.
- **Storage:** No change.
- **Observability:** Optional: log revision request and outcome (success / limit reached / state invalid) in service layer; not mandatory for this plan.
- **Compatibility & Migration:** Additive guards; older app versions that call RPC will receive new exceptions when invalid; no backfill required. Ensure `revisions_total`/`revisions_used` exist on tasks and bookings (confirm in live scan).
- **Contracts:** RPC contract unchanged (same params/return); new exception messages are part of the contract and must be documented and mapped in app.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance: (1) RPC raises on non-delivered status, (2) RPC raises when revisions_used >= revisions_total, (3) UI shows specific messages for these errors; non-regression: existing client-only check and success path unchanged.
- [ ] (@Architect) Confirm modules: `lib/features/work/` (service, viewmodel, view), `lib/core/utils/error_mapper.dart`; entry: Request revision from work item detail.
- **Verify (@Sentinel):** Done-conditions and rollback triggers documented in §8 below.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Threat model already in `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/03_RISK_REGISTER.md` — infinite revisions (escrow trapping), state corruption. Negative tests in Phase 4.
- **Verify (@Sentinel):** Phase 4 includes RLS/role and cap/state tests.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Contract: RPC signature unchanged; new exception messages `Can only request revision on delivered work`, `No revisions remaining` (and existing `Only client can request revision`) must be mapped in Flutter and documented in SUPABASE_SETUP.
- **Verify (@Sentinel):** ErrorMapper + docs updated in Phase 2/5.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) No schema/data backfill; function-only migration. Compatibility: existing rows with NULL revisions_used/revisions_total handled by COALESCE in guard.
- **Verify (@Sentinel):** Migration is additive (guards only); rollback = revert function.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) No feature flag required; behavior is strict enforcement of documented intent.
- **Verify (@Sentinel):** Rollback path = redeploy previous RPC body.

---

## Phase 1: Database & Security

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via Supabase MCP (or SQL) for `tasks` and `bookings`: columns `revisions_used`, `revisions_total`, `status`; confirm `rpc_request_revision` exists and current body matches repo migration `20260305180100`.
- [ ] (@Supabase_Ops) Confirm no conflicting migrations or redefinitions of same function.
- **Verify (@Sentinel):** Drift and safe approach recorded; if columns missing, plan add column or guard with COALESCE only.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) No new tables/columns in this plan. If live DB lacks `revisions_total`/`revisions_used` on either table, add in separate migration first (out of scope here) or document as prerequisite.
- **Verify (@Sentinel):** No drops/renames; naming consistent.

### 1.2 RLS

- [ ] (@Supabase_Ops) No RLS change; RPC remains SECURITY DEFINER with auth.uid() check.
- **Verify (@Sentinel):** No policy change required.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) New migration (e.g. `YYYYMMDD_harden_rpc_request_revision.sql`): CREATE OR REPLACE FUNCTION `rpc_request_revision` — in both `task` and `booking` branches, after client check: (1) SELECT current status and revisions_used/revisions_total; (2) IF status <> 'delivered' THEN RAISE EXCEPTION 'Can only request revision on delivered work'; (3) IF COALESCE(revisions_used,0) >= COALESCE(revisions_total,0) THEN RAISE EXCEPTION 'No revisions remaining'; (4) then existing UPDATE. Apply via Supabase MCP `apply_migration` or run in dashboard.
- **Verify (@Sentinel):** State and cap guards run before any UPDATE; both branches covered.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Run new migration against project; verify no errors.
- **Verify (@Sentinel):** RPC exists and returns expected errors in manual SQL tests (see Phase 4).

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) No new DTOs; work item models already carry status and optionally revisions_used/revisions_total. Ensure any UI that shows “revisions remaining” uses these if present.
- **Verify (@Sentinel):** Types and contract match; no nullability mismatch.

### 2.2 Services/Repositories

- [ ] (@Architect) `WorkManagementService.requestRevision` unchanged in signature; continues to call RPC and rethrow. Callers must use ErrorMapper on catch (ViewModel or View).
- **Verify (@Sentinel):** No direct Supabase in UI; service rethrows so ViewModel can map.

### 2.3 ViewModels

- [ ] (@Architect) `WorkItemDetailsViewModel.requestRevision`: on catch, map exception with `ErrorMapper.map(e)` and set error state / return user message so UI displays it (e.g. snackbar/dialog). Optionally refresh work item after success to show updated revisions_used/status.
- **Verify (@Sentinel):** User sees “No revisions remaining” or “Can only request revision on delivered work” when RPC raises; no sensitive stack in UI.

### 2.4 ErrorMapper

- [ ] (@Architect) In `lib/core/utils/error_mapper.dart` (_mapPostgrestError): add branches for message.contains('Can only request revision on delivered work') → user-facing string; 'No revisions remaining' → user-facing string; keep 'Only client can request revision' if not already present.
- **Verify (@Sentinel):** All three revision-related messages mapped; no fallback to generic “Database error” for these.

### 2.5 Observability (If needed)

- [ ] (@Observability) Optional: log revision request success vs limit/state failure in WorkManagementService (tag, no PII).
- **Verify (@Sentinel):** If added, no sensitive data in logs.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Work item detail: ensure error path from `requestRevision` shows ErrorMapper message (snackbar or dialog). If ViewModel exposes “revisions remaining”, consider disabling “Request revision” when 0 remaining and/or showing “No revisions left” copy.
- **Verify (@Sentinel):** Stable UX on “No revisions remaining” and “Can only request revision on delivered work”; no crash, clear message.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Optional: micro-copy or tooltip explaining revision limit.
- **Verify (@Sentinel):** No perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Confirm RPC returns exact message strings assumed by ErrorMapper; run manual SQL: call `rpc_request_revision('task', <id>, 'note')` for task with status 'active' → expect exception “Can only request revision on delivered work”; for status 'delivered' and revisions_used >= revisions_total → “No revisions remaining”; as non-client → “Only client can request revision”.
- **Verify (@Sentinel):** No mismatch between DB messages and ErrorMapper branches.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute: (1) Freelancer cannot request revision (RLS/caller check), (2) Third-party cannot request revision, (3) Request on active task fails, (4) Request when revisions_used >= revisions_total fails.
- **Verify (@Sentinel):** Unauthorized and invalid transitions impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E: client requests revision on delivered work (success); client requests revision when no revisions left (see “No revisions remaining” in UI); client requests revision on already active item if reachable (see appropriate message). Edge: network error, null note.
- **Verify (@Sentinel):** No crashes; consistent behavior and messages.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) If Phase 2.5 added logging: required events present and non-sensitive.
- **Verify (@Sentinel):** Actionable without PII.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md` §9.2: state that `rpc_request_revision` checks status = 'delivered' and revisions_used < revisions_total; document the three exception messages. Update §1 Key Business Rules to “Revision requests enforce status and limit (rpc_request_revision)”.
- [ ] (@SlineDocs) If DEVELOPER_GUIDE or work flow doc describes revision flow, align with new behavior and error messages.
- **Verify (@Sentinel):** Docs match code and DB behavior.

---

## 7) Acceptance Criteria (MANDATORY)

- RPC raises “Can only request revision on delivered work” when status <> 'delivered' (task and booking).
- RPC raises “No revisions remaining” when revisions_used >= revisions_total (with COALESCE for NULLs).
- Client-only check unchanged; freelancer/third-party receive “Only client can request revision” (or equivalent).
- UI shows user-friendly messages for these three cases (no generic “Database error”).
- Existing success path unchanged: delivered work with revisions left → status active, revisions_used +1, delivery fields cleared.
- No regression on approve delivery, submit delivery, or change-request flows.
- Docs (SUPABASE_SETUP + work flow) reflect enforced guards and exception messages.

## 8) Rollback Plan

- **DB:** Revert `rpc_request_revision` to previous body (re-apply migration from `20260305180100_work_revision_and_change_rpcs.sql` or store previous version in a rollback migration file). No table/column rollback.
- **App:** Revert ErrorMapper and ViewModel changes if any; previous behavior is “generic error” for revision failures — acceptable short-term.
- **Emergency:** If production issue, re-deploy previous RPC via SQL; app continues to work with generic error messages until ErrorMapper re-deployed.

## 9) References (From Scan)

- `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/00_HOLISTIC_REPORT.md`
- `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/01_NOTES.md`
- `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/02_GAPS_AND_FIXES.md`
- `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/03_RISK_REGISTER.md`
- `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/04_TEST_PLAN.md`
- `.TODO/improvement_the_system/ImplementReady/10_work-contract-revisions/07_SYSTEM_CRITIC_VERDICT.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md` (§1, §9.2)
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/STRUCTURE.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `supabase/migrations/20260305180100_work_revision_and_change_rpcs.sql`
- `lib/features/work/services/work_management_service.dart`
- `lib/features/work/viewmodels/work_item_details_view_model.dart`
- `lib/features/work/view/work_item_details_screen.dart`
- `lib/core/utils/error_mapper.dart`
- Live Supabase scan at execution time: project_id from SUPABASE_SETUP (e.g. `isddrknbjsgaantjojhm`), tables `tasks`, `bookings`, function `rpc_request_revision`.
