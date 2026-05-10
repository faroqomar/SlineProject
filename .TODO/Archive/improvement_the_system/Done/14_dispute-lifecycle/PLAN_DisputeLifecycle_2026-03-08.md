# 📌 Plan: Dispute Lifecycle Implementation (Plan Critic v2.1 — Execution-Ready)

**Source:** Original plan + `.agents/workflows/plan_critic.md` audit.  
**Date:** 2026-03-08.

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (Inferred)

- **Stack:** Flutter app + Supabase (Postgres, RLS, RPC, Storage). MVVM; no direct Supabase in views.
- **Team:** Single or small team; same repo for app + migrations; no separate admin app in this repo.
- **rpc_finalize_auto_approval:** Referenced in SUPABASE_SETUP.md §9.4 but not found in `supabase/migrations/` grep; assumed to exist in DB or in a migration not under that path. Plan assumes it will be located and patched in Phase 1.
- **Test runners:** Flutter tests via `flutter test`; Supabase/RLS tests via existing pattern (e.g. `test/rls/`, or pg_prove if introduced); no separate Supabase test runner specified.
- **Definition of Done:** Escrow never released while dispute open/active; RLS and trigger enforcements in place; UI disables approve when disputed; docs updated; regression tests added.

### Decision Needed (Blocking)

| # | Decision | Options | Recommended | Plan impact |
|---|----------|---------|-------------|-------------|
| 1 | **Scope of “optional” items** (enum, trigger, messages/evidence UI, admin RPC) | (A) Ship only escrow guard + deny policies; (B) Ship guard + deny + enum + transition trigger + resolved_at; (C) Full scope including messages/evidence UI + admin RPC | **B** for first release: guard + deny + enum + trigger + resolved_at. Messages/evidence and admin UI in a follow-up. | Phase 1 “optional” becomes mandatory for enum/trigger/resolved_at; Phase 2/3 messaging/evidence remain optional and move to “Phase 6 backlog”. |
| 2 | **Where does `rpc_finalize_auto_approval` live?** | (A) In a migration not yet found; (B) Inline in cron/edge; (C) Does not exist yet | **A** — locate via full migration search or DB introspection before Phase 1. If **C**, add “Implement or document N/A” step. | Phase 1.1 blocked until function location is confirmed; add explicit step “Locate rpc_finalize_auto_approval (migration or DB)”. |
| 3 | **RLS tests: run where?** | (A) Flutter integration calling Supabase with test users; (B) SQL files in repo run via pg_prove or similar; (C) Manual only | **B** preferred to align with existing `test/rls/`; if no runner, **A** with test helpers. | Add “Test Infrastructure Gate”: either `supabase/tests/` + runner doc or `test/rls/disputes_rls_test.dart` (or equivalent) with deterministic fixtures. |

---

## Mandatory Critique Checklist (Results)

- **3.1 Scope & Requirements:** Goal measurable (escrow never released when dispute open/active). Non-goals stated (split refunds, external admin, realtime). Edge cases (booking vs task vs direct_offer) and abuse (status injection) defined. **Gap:** Cancellation/retry (dispute withdrawn) not explicitly tested.  
- **3.2 Dependencies & Ordering:** Original had UI possible before CTA data source — fixed: Phase 2 “single source for dispute state” before Phase 3 UI. DB/RLS before API/UI enforced. Migration/backfill path added (status audit + optional backfill).  
- **3.3 Data Model & Contracts:** Tables/enums in SUPABASE_SETUP; DTO boundaries (Dispute model) in Phase 2; status transitions defined (invariants + trigger). **Gap:** Contract file in .TODO/ only “if new RPCs” — added in Phase 0.3/1.6 (RLS matrix).  
- **3.4 Security (RLS + AuthZ):** Explicit deny UPDATE/DELETE; participant-only for messages/evidence; privileged (status change) via DEFINER RPC only. **Failure:** Original did not specify exact policy expressions — fixed in Gaps and Phase 1.4–1.5. Audit (admin_logs) optional/backlog.  
- **3.5 Performance & Scalability:** Indexes on disputes(task_id), (direct_offer_id), (status) added; no N+1 (single source for dispute state). Realtime not in scope.  
- **3.6 Error Handling & Observability:** Error taxonomy (RAISE in RPC); AppLogger in DisputeService; user-facing (exception → ErrorMapper) assumed. **Gap:** Correlation id for dispute events optional.  
- **3.7 UX & State Machine:** Loading/empty/error in Phase 3; double submit prevented by guard; offline/retry not explicit — residual risk.  
- **3.8 Testing & QA:** Smoke (escrow guard) and RLS (allowed + forbidden) added; regression checklist added. **Failures:** Test infra missing (Gate 0 FAIL); no fixture manifest (added in Gate 0); no timeout/retry (added in Phase 4); no flake policy (residual).  
- **3.9 Release & Migration:** Rollback in Phase 5; backward compatibility (additive only); feature flag optional.  
- **3.10 Developer Workflow:** Branch/review/DoD not specified — assumed per project; documentation update in Phase 5.

---

## B) Gate Status (Pass / Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|-------------------------|
| **Gate 0: Test Infrastructure** | ❌ FAIL | No `test/features/safety/`; no `supabase/tests/` files; `04_TEST_PLAN.md` references non-existent paths. No fixture manifest or runner doc for dispute RLS. | Add: (1) `test/unit/safety/dispute_service_test.dart` (or `test/features/safety/...`) with mock Supabase; (2) Either `test/rls/disputes_rls_test.dart` using existing RLS harness or `supabase/tests/disputes_rls.test.sql` + runner doc; (3) Fixture contract (e.g. dispute row, booking + task) for integration; (4) Run commands in plan or README. |
| **1) Data/Contracts** | ❌ FAIL | Dispute check predicate not specified for booking (task_id from booking) and for `rpc_finalize_auto_approval` (entity type unknown). Enum migration has no explicit backfill step. | Add: exact SQL predicate for booking branch (e.g. `(SELECT task_id FROM bookings WHERE id = entity_id)`); locate and document `rpc_finalize_auto_approval`; add step “Pre-migration: SELECT DISTINCT status FROM disputes” and backfill step if non-standard values. |
| **2) Security** | ❌ FAIL | RLS for `dispute_messages` and `dispute_evidence` described at high level only; no explicit “who can INSERT message” (participant only). Admin path (service_role vs DEFINER RPC) undefined. | Add: per-table policy names and USING/WITH CHECK expressions; decision: status updates only via SECURITY DEFINER RPC (no service_role in app). |
| **3) Backend/API** | ❌ FAIL | Ordering risk: UI might be built before “dispute state in CTA resolver” is defined. `rpc_finalize_auto_approval` not located. | Add: Phase 2 must complete “dispute state in dashboard/CTA” before Phase 3 uses it; explicit step to find and patch `rpc_finalize_auto_approval`. |
| **4) UI/Integration** | ⚠️ CONDITIONAL | “Disable Approve when dispute exists” depends on data source (vw_unified_work_items vs disputes table). Not specified how dispute flag is exposed to CTA. | Add: single source of truth (e.g. view column or join) and step “Expose has_open_dispute (or equivalent) to dashboard/CTA”. |
| **5) Release/QA** | ❌ FAIL | No regression list; no flake/retry policy; no artifact capture for failed tests. | Add: regression checklist (approve without dispute still works; booking/direct_offer both covered); timeout/retry bounds for integration tests; failure log path. |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix | Owner | Acceptance |
|-----|-------------------|-----|--------|------------|
| **rpc_finalize_auto_approval not located** | Cannot add dispute check; auto-approval can still release funds. | Add step: “Locate `rpc_finalize_auto_approval` in migrations or DB; document path; add dispute guard (task_id/direct_offer_id as applicable).” If missing, add “Implement or document as N/A”. | @Supabase_Ops | Function body contains dispute check or N/A documented. |
| **Booking branch dispute check ambiguous** | Implementer may use wrong column; disputes link to task_id, not booking_id. | In Phase 1.1: “Booking branch: get v_task_id from `SELECT task_id FROM bookings WHERE id = entity_id`; then check `EXISTS (SELECT 1 FROM disputes WHERE task_id = v_task_id AND status IN ('open','active'))`.” | @Supabase_Ops | Migration includes exact predicate. |
| **Test infra missing** | Tests in 04_TEST_PLAN reference files that don’t exist; no runnable RLS tests. | Add Gate 0: Create `test/unit/safety/dispute_service_test.dart` (mock client); add RLS test (supabase/tests or test/rls) with fixture contract and run command. | @Sentinel + @Architect | `flutter test test/unit/safety/` passes; RLS test runnable and documented. |
| **Optional vs mandatory unclear** | Ship may skip enum/trigger and leave status tampering possible. | Decision: Phase 1 mandatory = escrow guard + deny policies + (recommended) enum + transition trigger + resolved_at. Move messages/evidence UI to explicit “Phase 6 backlog”. | @Architect | Plan labels “Mandatory” vs “Backlog” clearly. |
| **No single source for “has dispute” in UI** | CTA resolver may duplicate logic or read wrong source. | Add step: “Define and expose has_open_dispute (or disputed flag) from vw_unified_work_items or disputes join; use in dashboard_permission_service and unified_cta_resolver.” | @Architect | One code path provides dispute flag to CTA. |
| **RLS policy exact shape missing** | dispute_messages INSERT could allow non-participants if WITH CHECK is wrong. | Add: “dispute_messages_insert: WITH CHECK (auth.uid() IN (SELECT complainant_id FROM disputes WHERE id = dispute_id UNION SELECT defendant_id FROM disputes WHERE id = dispute_id))”. Same pattern for SELECT. | @Supabase_Ops | Policy created with exact expression; negative test: non-participant INSERT fails. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|---------------|
| Escrow is never released while a dispute is open or active for that entity. | Guard at start of `rpc_approve_delivery` (task, booking, direct_offer) and in `rpc_finalize_auto_approval`; RAISE or early return. | Integration test: open dispute → call approve → expect exception; query journal_entries for no release. |
| Authenticated users cannot UPDATE or DELETE disputes. | Explicit RLS policies: FOR UPDATE/DELETE TO authenticated USING (false). | RLS test: authenticated UPDATE/DELETE fails. |
| Status transitions are constrained (open→active, open→canceled, active→resolved). | Trigger `trg_dispute_guard` BEFORE UPDATE on disputes. | SQL test: UPDATE disputes SET status='resolved' WHERE status='open' → expect exception. |
| resolved_at is set when status becomes 'resolved'. | Trigger on disputes SET resolved_at = now() WHEN NEW.status = 'resolved'. | Query: after status → resolved, resolved_at IS NOT NULL. |
| Only dispute participants (and admin via RPC) can read/write messages and evidence. | RLS on dispute_messages and dispute_evidence; admin via SECURITY DEFINER RPC only. | RLS tests: participant can SELECT/INSERT; non-participant cannot. |
| Single source of truth for “work item has open/active dispute” in UI. | One place (view column or service) used by CTA resolver and permission service. | Code review: no duplicate dispute lookup logic in UI layer. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|--------------|------------|----------|
| Escrow released despite open dispute | rpc_approve_delivery / rpc_finalize_auto_approval | High | High | Data-loss / financial | User report; ledger entry for release_with_fee while dispute open | Dispute check at start of both RPCs; integration test | Hotfix: re-add guard; refund via support |
| Enum migration fails (bad status value) | ALTER COLUMN status TYPE enum | Med | Med | Feature | Migration error on USING cast | Pre-migration SELECT DISTINCT status; backfill to open/active/resolved/canceled | Rollback migration; keep text column |
| rpc_finalize_auto_approval not found | Phase 1 | Med | High | App-wide | Grep returns no result; deployment without patch | Explicit “locate function” step; document or implement | Document N/A; accept auto-approval risk until added |
| Non-participant reads dispute messages | dispute_messages RLS | Low | High | Security-breach | RLS audit; user report | Participant-only SELECT/INSERT policies; negative test | Revoke policy; fix WITH CHECK |
| CTA shows “Approve” when dispute active | Dashboard/booking UI | Med | Med | Feature | Manual QA; user complaint | Expose has_open_dispute from single source; gate CTA | Fix data source and redeploy |
| Flaky integration test (network/state) | test/ | Med | Low | Local | CI failure; timeout | Bounded timeouts; deterministic fixtures; no hidden realtime in unit tests | Retry budget; skip if env missing |

---

## F) Pre-Mortem (How This Fails in Real Life)

- **This fails when** we deploy the app without deploying the migration that adds the escrow guard → client approves delivery while dispute is open → funds released → dispute unresolvable. *→ Mitigation: deploy migration before or with app; gate release on migration verification.*
- **This fails when** `rpc_finalize_auto_approval` is never found and we only patch `rpc_approve_delivery` → review timer expires → auto-approval runs without dispute check → same escrow race. *→ Mitigation: explicit locate-and-patch step; document if N/A.*
- **This fails when** booking branch uses `entity_id` (booking id) in the dispute check instead of task_id → check always false → approve allowed despite dispute. *→ Mitigation: exact predicate in plan (task_id from bookings).*
- **This fails when** we add an UPDATE policy later and forget the explicit deny → participant can set status = 'resolved' → fraud. *→ Mitigation: explicit deny policies; checklist in Phase 4.*
- **This fails when** UI reads dispute state from a different source than the RPC guard → UI hides Approve but RPC still allows (or vice versa) → inconsistent UX or security. *→ Mitigation: single source of truth for has_open_dispute.*
- **This fails when** RLS tests don’t exist or aren’t run → policy typo allows cross-tenant read. *→ Mitigation: Gate 0 test infra; negative RLS test.*
- **This fails when** enum migration runs on a row with status = 'pending' or typo → cast fails → migration rollback. *→ Mitigation: SELECT DISTINCT status; backfill step.*

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|-----------------|-----------------|
| Locate rpc_finalize_auto_approval | Cannot patch what we can’t find. | Grep all migrations; query pg_proc; document file or “not in repo”. | `.TODO/14_dispute-lifecycle/rpc_finalize_auto_approval_location.md` or note in execution log | Path or N/A documented. |
| Pre-migration status audit | Avoid enum migration failure. | Run SELECT DISTINCT status FROM disputes; list in migration or doc; if any not in (open,active,resolved,canceled), add UPDATE backfill. | Migration or audit note | All rows castable to enum. |
| Booking branch predicate | Correct guard. | In migration: declare v_task_id; SELECT task_id FROM bookings WHERE id = entity_id INTO v_task_id; then EXISTS (SELECT 1 FROM disputes WHERE task_id = v_task_id AND status IN ('open','active')). | SQL in migration | Booking + dispute → approve raises. |
| Dispute messages RLS exact policy | Safe INSERT. | CREATE POLICY dispute_messages_select ... USING (auth.uid() IN (SELECT complainant_id FROM disputes WHERE id = dispute_id UNION SELECT defendant_id ...)); same for INSERT WITH CHECK (participant). | Migration | Non-participant INSERT fails in test. |
| Expose has_open_dispute to CTA | Single source for UI. | Add to vw_unified_work_items or provide DisputeService.getOpenDisputeIdsForUser() / hasOpenDispute(entity_type, entity_id) used by dashboard and CTA resolver. | View or service method + wiring | CTA uses one source. |
| Test infra for disputes | Runnable tests. | Add test/unit/safety/dispute_service_test.dart (mock Supabase); add test/rls/disputes_rls_test.dart or supabase/tests/disputes_rls.test.sql + run doc; fixture: one dispute, one booking. | Test files + README or plan step | flutter test passes; RLS test runnable. |
| Regression checklist | No fake progress. | List: “Approve delivery (booking, no dispute) succeeds”; “Approve delivery (direct_offer, no dispute) succeeds”; “Approve with open dispute fails”. | Phase 4 checklist | All checked before release. |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions & Gates

**Goal:** Lock scope, locate dependencies, and pass Gate 0 (test infra).  
**Why:** Prevents building on wrong or missing foundations.  
**How:** Decisions (mandatory vs backlog); locate rpc_finalize_auto_approval; create dispute test files and fixture contract; document run commands.

**Steps:**

0.1 **Decision (Blocking):** Choose scope: (B) Guard + deny + enum + trigger + resolved_at for first ship; messages/evidence and admin UI → backlog. Record in plan.  
0.2 **Locate rpc_finalize_auto_approval:** Search migrations and DB; document path or “N/A”. If N/A, add step to implement or accept risk.  
0.3 **Threat model:** @ThreatModeler — escrow bypass, status injection, evidence leak; store in `.TODO/`.  
0.4 **Test infra (Gate 0):** Create `test/unit/safety/dispute_service_test.dart` (submitDispute inserts status 'open'; empty reason throws; task_id/defendant_id set). Use existing mock Supabase pattern. Add RLS test: either `test/rls/disputes_rls_test.dart` or `supabase/tests/disputes_rls.test.sql` with runner doc. Fixture contract: dispute row, booking + task (or document “use existing fixtures”). Document: `flutter test test/unit/safety/` and how to run RLS tests.  
0.5 **Migration plan:** @DataMigration — order: (1) Pre-migration SELECT DISTINCT status; backfill if needed. (2) Escrow guard in RPCs. (3) Deny policies. (4) Enum + trigger + resolved_at (optional per decision). Rollback: revert RPC, drop trigger, optional enum→text.

**GATE CHECK:** rpc_finalize_auto_approval located or N/A documented; test/unit/safety test exists and passes; RLS test runnable; scope decision recorded.

---

### Phase 1: Data & Security (Database)

**Goal:** Escrow guard, RLS, and optional state machine in DB.  
**Why:** Prevents financial and integrity failures.  
**How:** One or more additive migrations; no drops.

**Steps:**

1.1 **Live Supabase confirmation:** @Supabase_Ops — List current rpc_approve_delivery, rpc_finalize_auto_approval, policies on disputes/dispute_messages/dispute_evidence. Record drift.  
1.2 **Escrow race guard (CRITICAL):**  
- **Task branch:** At start, `IF EXISTS (SELECT 1 FROM disputes WHERE task_id = entity_id AND status IN ('open','active')) THEN RAISE EXCEPTION '...'; END IF;`  
- **Booking branch:** `SELECT task_id INTO v_task_id FROM bookings WHERE id = entity_id;` then same EXISTS with task_id = v_task_id.  
- **Direct_offer branch:** EXISTS (SELECT 1 FROM disputes WHERE direct_offer_id = entity_id AND status IN ('open','active')).  
- **rpc_finalize_auto_approval:** Add same logic (by task_id / direct_offer_id as applicable); if dispute exists, return without releasing.  
1.3 **Explicit deny:** CREATE POLICY disputes_deny_update ON disputes FOR UPDATE TO authenticated USING (false); same for DELETE.  
1.4 **RLS dispute_messages:** SELECT and INSERT for participants only (complainant_id/defendant_id of dispute); exact USING/WITH CHECK as in Gap fix.  
1.5 **RLS dispute_evidence:** SELECT and INSERT for participants; uploader_id = auth.uid() for INSERT.  
1.6 **RLS check matrix:** Write `.TODO/14_dispute-lifecycle/RLS_CHECK_MATRIX.md` (who can do what).  
1.7 **Optional (per decision):** dispute_status_enum; ALTER status column; fn_dispute_guard + trg_dispute_guard; trigger set resolved_at on status → resolved.  
1.8 **Indexes:** disputes(task_id), disputes(direct_offer_id), disputes(status) if not present.  
1.9 **Run migration(s).**

**GATE CHECK:** Migration applied; integration test: open dispute → rpc_approve_delivery → exception; no ledger release. RLS negative test: non-participant cannot UPDATE disputes or INSERT dispute_messages.

---

### Phase 2: App Layer (MVVM)

**Goal:** Models, services, and single source for “has dispute” so UI can gate CTA.  
**Why:** UI must not call Supabase directly; CTA must have one dispute signal.  
**How:** Add/align Dispute model; extend DisputeService; expose has_open_dispute (view or service) and use in CTA resolver and permission service.

**Steps:**

2.1 **Models:** Dispute (and optional DisputeMessage, DisputeEvidence) aligned to DB; status as enum or string per contract.  
2.2 **DisputeService:** Keep submitDispute; add getDispute(id) and, if backlog scope, listMessages/addMessage/uploadEvidence (path only; signed URL in service). Optional: submitDispute(direct_offer_id) for direct-offer flow.  
2.3 **Single source for dispute state:** Define how dashboard/CTA gets “has open/active dispute” (e.g. vw_unified_work_items column or DisputeService.hasOpenDispute(entity_type, entity_id)). Implement and use in dashboard_permission_service and unified_cta_resolver.  
2.4 **ViewModels:** SafetyViewModel unchanged for submit; optional DisputeDetailViewModel if backlog. Dashboard/CTA: use dispute state from 2.3 to disable/hide “Approve & Release”.

**GATE CHECK:** No UI calls Supabase for disputes; CTA resolver and permission service use single dispute source; unit tests pass.

---

### Phase 3: UI (Wiring)

**Goal:** Approve disabled when dispute exists; optional detail/thread/evidence (backlog).  
**Why:** Consistent UX and no accidental approve.  
**How:** Wire existing screens to ViewModel/dispute state; loading/empty/error states.

**Steps:**

3.1 **Booking/task detail:** When dispute exists for entity (from Phase 2), disable or hide “Approve & Release Funds”.  
3.2 **Dashboard:** “Submit Evidence” for disputed items — wire to dispute detail or placeholder (backlog).  
3.3 **Loading/empty/error** for any new or touched screens.

**GATE CHECK:** Manual: with open dispute, Approve not available; without dispute, Approve works. No direct Supabase in widgets.

---

### Phase 4: QA & Release

**Goal:** Security, regression, and observability verified.  
**Why:** Avoid regressions and leaks.  
**How:** Checklist-driven QA; RLS and integration tests; doc update.

**Steps:**

4.1 **Regression checklist:** (1) Approve delivery (booking, no dispute) succeeds. (2) Approve delivery (direct_offer, no dispute) succeeds. (3) Approve with open dispute (booking and direct_offer) fails. (4) Non-participant cannot read dispute/messages/evidence. (5) Authenticated cannot UPDATE/DELETE disputes.  
4.2 **Security/RLS:** Run RLS tests; ThreatModeler negative cases.  
4.3 **Integration:** Escrow guard test (dispute + approve → exception; no release).  
4.4 **Observability:** If events added, verify no sensitive data in logs.  
4.5 **Timeouts/retries:** Bounded for integration tests; failure artifact path documented.

**GATE CHECK:** All regression items pass; RLS tests green; no unauthorized access.

---

### Phase 5: Documentation & Rollback

**Goal:** Docs match reality; rollback repeatable.  
**Why:** Safe ops and onboarding.  
**How:** Update SUPABASE_SETUP, DEVELOPER_GUIDE, MVP_ROADMAP, STRUCTURE; finalize rollback steps.

**Steps:**

5.1 **@DocsKeeper:** Update SUPABASE_SETUP.md — escrow guard behavior, RPC changes, enum/trigger if added, RLS for dispute_messages/dispute_evidence.  
5.2 **@DocsKeeper:** Update DEVELOPER_GUIDE.md — dispute lifecycle, safety entry points, dashboard disputed state.  
5.3 **@DocsKeeper:** MVP_ROADMAP.md and STRUCTURE.md if new modules/screens.  
5.4 **Rollback:** Document: revert migration (RPC + trigger + policies; optional enum→text); app revert; emergency: remove only escrow guard if needed.

**GATE CHECK:** Docs match code and DB; rollback steps executable.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Optional vs mandatory scope unclear (enum/trigger could be skipped).  
- rpc_finalize_auto_approval not located; booking branch predicate not explicit.  
- Test plan referenced non-existent paths; no test infra gate.  
- No single source for “has dispute” in UI.  
- RLS for dispute_messages/dispute_evidence not explicit (exact policies).  
- No regression checklist; no flake/retry or artifact policy.  
- Gates not defined; ordering and stop conditions not strict.

### 2) Added steps

- **Gate 0:** Test infra — create test/unit/safety/dispute_service_test.dart; RLS test file + runner doc; fixture contract.  
- **Phase 0:** Locate rpc_finalize_auto_approval; decision (scope B vs full); pre-migration status audit.  
- **Phase 1:** Exact booking-branch predicate (v_task_id from bookings); explicit RLS policy expressions; RLS check matrix artifact.  
- **Phase 2:** Single source for has_open_dispute and wiring to CTA/permission service.  
- **Phase 4:** Regression checklist (5 items); timeout/retry and failure artifact.  
- **Sections A–G:** Assumptions, decisions, gates, gaps, invariants, risk register, pre-mortem, plan fixes.

### 3) Removed steps

- None; optional items reclassified as “mandatory for first ship” (enum, trigger, resolved_at) or “backlog” (messages/evidence UI, admin RPC).

### 4) Reordered

- Test infra (Gate 0) before any Phase 1 implementation.  
- “Single source for dispute state” (Phase 2) before UI “disable Approve” (Phase 3).  
- Regression checklist and RLS verification before “Documentation” (Phase 4 before Phase 5).

### 5) Expanded steps

- Phase 1.1: from “add dispute check” to exact SQL for task, booking (with v_task_id), direct_offer, and rpc_finalize_auto_approval.  
- RLS: from “participant-scoped” to exact USING/WITH CHECK for dispute_messages and dispute_evidence.  
- Phase 4: from “Functional QA” to numbered regression checklist + security + integration + observability + test stability.

### 6) Why (short, practical)

- To make the plan executable without ambiguity: one person (or agent) can implement from this doc.  
- To block fake progress: gates and “locate function” prevent shipping without escrow guard.  
- To reduce risk: explicit predicates, RLS expressions, and pre-mortem force failure modes to be addressed.

### 7) Residual risks

- rpc_finalize_auto_approval might still be missing in repo (documented N/A and accepted risk until implemented).  
- Admin resolution path still not implemented (backlog); disputes can be opened but not resolved in-app without admin tooling.  
- Realtime for dispute thread not in scope; UX may feel stale until added.

---

## 10) References (Unchanged)

- `Sline_everything/DEVELOPER_GUIDE.md`, `SUPABASE_SETUP.md` (§5.24–5.26, §9.4, §9.5), `MVP_ROADMAP.md`, `STRUCTURE.md`, `ARCHITECTURE_ANALYSIS.md`, `CODE_REVIEW.md`
- `.TODO/improvement_the_system/ImplementReady/14_dispute-lifecycle/` (all referenced files)
- `lib/features/safety/services/dispute_service.dart`, viewmodels, booking_details_screen, dashboard repository/permission service
- `supabase/migrations/20260307120000_rpc_approve_delivery_direct_offer.sql`, `20260319110000_direct_offer_guard_rls_ledger.sql`
- Live Supabase: confirm via MCP or manual SQL before and after Phase 1.
