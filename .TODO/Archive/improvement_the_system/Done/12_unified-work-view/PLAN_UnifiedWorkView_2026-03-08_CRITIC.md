# Plan Critic: Unified Work View (12_unified-work-view)

**Source plan:** `.TODO/PLAN_UnifiedWorkView_2026-03-08.md`  
**Critic workflow:** `.agents/workflows/plan_critic.md`  
**Date:** 2026-03-08

---

## A) Assumptions + Decision Needed (Blocking)

### Assumptions (inferred)

- Stack: Flutter + Supabase; MVVM; Provider; no feature flag required for this change.
- Deployment: view migration applied first, then app deploy (single coordinated release).
- Test baseline: existing `test/unit/work/` and `test/unit/models/`; no dedicated integration/e2e harness for "My Work" listed in plan.
- Live DB: view may be created from archived migration or another migration; MCP scan will confirm.
- Disputes table: schema is as in SUPABASE_SETUP §5.24 (`task_id`, `direct_offer_id` only); no `related_entity_id`/`related_entity_type` — migration must not use them.
- Bookings and disputes: disputes attach to task or direct_offer only; for Branch 2 (bookings) we join disputes via `d.task_id = b.task_id`.

### Decision Needed (Blocking)

| # | Decision | Options | Recommended | Why | Plan impact |
|---|----------|---------|-------------|-----|-------------|
| 1 | Work detail when view returns null for a valid (id, type) that user owns | (A) Show "not found" and remove all fallbacks. (B) Keep booking-only fallback so detail still loads from booking table when view has no row. | **A** | Single source of truth; if view has no row, treat as not found and fix view/RLS instead of masking. | Plan must explicitly remove booking fallback in WorkItemDetailsViewModel and define "not found" UX. |
| 2 | Dispute status values that count as "open" for override | (A) `d.status NOT IN ('resolved', 'closed')`. (B) Only `d.status = 'open'`. (C) Document exact enum/list from DB. | **C** | Avoid drift with disputes.status enum. | Add step: read disputes.status values from live DB or SUPABASE_SETUP; use exact list in view CASE. |
| 3 | Rollback SQL artifact | (A) Inline in plan only. (B) Stored as a separate migration file (e.g. `*_rollback_unified_work_view.sql`) to run if needed. | **B** | One-command rollback; no copy-paste from plan. | Add step: create rollback migration file with previous 3-branch view definition. |

---

## B) Gate Status (Pass/Fail)

| Gate | Status | Reason | What to add/fix to pass |
|------|--------|--------|---------------------------|
| **0) Test Infrastructure** | ❌ FAIL | No test harness or fixture contract for view-backed flows; RLS tests not tied to a runnable script; fallback mapper test removal mentioned but no replacement test contract. | Add: (1) Contract for view query test (columns, sample source_type values). (2) RLS test script or doc (User A / User B steps + expected row sets). (3) Decision: remove vs repurpose fallback mapper test + add view-only unit test for _mapUnifiedToWorkItem(direct_offer). |
| **1) Data/Contracts** | ❌ FAIL | Disputes JOIN in 08_PATCH_PLAN uses wrong columns (related_entity_id/type); plan says "must use task_id/direct_offer_id" but migration DDL not locked. Dispute "open" status list not defined. | Add: (1) Single source of truth for dispute JOIN (task_id for tasks/bookings, direct_offer_id for direct_offers). (2) Resolve dispute status list from DB/docs and freeze in migration. (3) Written contract file or plan appendix with exact view column list and source_type/unified_status enums. |
| **2) Security** | ⚠️ CONDITIONAL | security_invoker = true is correct; RLS check is manual. No automated RLS test artifact. | Add: (1) RLS check matrix (user A/B, client/freelancer, expected row count or id set). (2) Optional: SQL script runnable in Supabase (SET auth.uid then SELECT) to assert no cross-user leak. |
| **3) Backend/API** | ✅ PASS | View is the API; Flutter consumes view. Contract and migration steps are defined once Data gate fixes applied. | Proceed after Gate 0 and 1 pass. |
| **4) UI/Integration** | ✅ PASS | Wiring is "ensure loading/empty/error"; WorkItemType.directOffer already exists. | Add explicit "not found" behavior for getUnifiedWorkItem(id, type) returning null (per Decision 1). |
| **5) Release/QA** | ❌ FAIL | No rollback artifact; no explicit Definition of Done per PR; no branch/review checklist. | Add: rollback migration file; DoD checklist (view applied, fallback code removed, RLS verified, docs updated); optional branch strategy. |

---

## C) Critical Gaps (Must-Fix)

| Gap | Why it will break | Fix (exact step(s)) | Owner | Acceptance check |
|-----|-------------------|---------------------|--------|-------------------|
| Disputes JOIN uses wrong columns | 08_PATCH_PLAN SQL uses related_entity_id/related_entity_type; DB has task_id/direct_offer_id. Migration would fail or join zero rows. | In migration: Branch 1 & 3 use `LEFT JOIN disputes d ON d.task_id = t.id`; Branch 2 use `LEFT JOIN disputes d ON d.task_id = b.task_id`; Branch 4 use `LEFT JOIN disputes d ON d.direct_offer_id = do.id`. Do not copy JOIN from 08_PATCH_PLAN without editing. | Backend (Supabase_Ops) | Migration runs without error; dispute override verified by one task + one dispute row. |
| "Open" dispute status not defined | CASE uses `d.status NOT IN ('resolved', 'closed')`; if DB has other final states (e.g. 'withdrawn'), we may mislabel. | Look up disputes.status values in SUPABASE_SETUP or live DB; document in plan; use exact list in view (e.g. override when status IN ('open', 'under_review') or NOT IN ('resolved','closed') per schema). | Backend | View returns 'disputed' for a row that has an open dispute and not for resolved. |
| No rollback migration file | Rollback is "re-apply previous view"; operator must find and run old SQL manually — error-prone. | Create `supabase/migrations/YYYYMMDD_rollback_unified_work_view.sql` (or similar naming) containing the exact 3-branch view from Archive; document "run this if rollback needed". | Backend | File exists; `apply_migration` or run script restores 3-branch view. |
| WorkItemDetailsViewModel booking fallback ambiguous | Plan says "optionally keep booking-only fallback". If kept, we retain two sources of truth; if removed, product must accept "not found" when view has no row. | Decision 1: remove all fallbacks. Step: In WorkItemDetailsViewModel, remove branch that calls UnifiedWorkItemFallbackMapper.fromBooking when view returns null; when getUnifiedWorkItem returns null, set _workItem = null and show not-found (error state). | Frontend (Architect) | No reference to UnifiedWorkItemFallbackMapper; detail screen shows not-found when view returns null. |
| _mapDirectOfferToWorkItem removal vs reuse | Dashboard currently maps direct offers from _fetchDirectOffers to WorkItem via _mapDirectOfferToWorkItem. After view returns direct_offer rows, we map from UnifiedWorkItemModel. Plan says "remove _mapDirectOfferToWorkItem" but must map direct_offer in _mapUnifiedToWorkItem. | In _mapUnifiedToWorkItem: add branch for u.sourceType == 'direct_offer' → WorkItemType.directOffer, populating id, title, price, status, sortRank, etc. from UnifiedWorkItemModel. Remove _fetchDirectOffers and _mapDirectOfferToWorkItem; keep _directOfferStatusToUnified/Bucket only if needed for the new branch (or derive from unified_status). | Frontend (Architect) | Single code path: view → UnifiedWorkItemModel → _mapUnifiedToWorkItem → WorkItem for all 4 types. |
| RLS not verified by runnable test | Plan relies on manual "as User A / User B" check; no artifact. | Add RLS check matrix (User A client, User A freelancer, User B; expected row counts or id sets) and optional SQL script that sets request context and SELECTs view, with expected result doc. | Backend + Sentinel | Matrix or script exists; execution proves no cross-user rows. |
| Test removal without replacement contract | Removing unified_work_item_fallback_mapper_test without defining what "view-only path" tests we add. | (1) Remove or repurpose fallback mapper test. (2) Add unit test: _mapUnifiedToWorkItem with UnifiedWorkItemModel(sourceType: 'direct_offer', ...) produces WorkItem with type directOffer and correct status/sortRank. (3) Optional: service test that mocks view response and asserts no fallback call. | Frontend + Sentinel | No test imports UnifiedWorkItemFallbackMapper; at least one test covers direct_offer mapping. |

---

## D) Invariants & Success Criteria (Non-Negotiable)

| Invariant | How to enforce | How to verify |
|-----------|----------------|----------------|
| Single source of truth for work list and detail | View is the only query for list and get-by-id; no fallback mapper, no _fetchDirectOffers merge. | Grep for UnifiedWorkItemFallbackMapper, _fetchAwardedPendingPaymentFallback, _fetchDirectOffers returns 0 in lib. |
| RLS prevents cross-user reads on view | View created with security_invoker = true; RLS on tasks, bookings, task_requests, direct_offers. | Run RLS check: two users; each SELECT from view; no shared ids. |
| All four item types appear when applicable | 4-branch UNION; client_id/freelancer_id filter in app. | Manual or E2E: create one of each type; open My Work as client and freelancer; all visible where applicable. |
| Disputed state overrides normal status when dispute is open | LEFT JOIN disputes + CASE in each branch. | Create task + dispute; query view; unified_status = 'disputed'. |
| View column contract stable | Same columns and types across all branches; Flutter fromJson matches. | Migration UNION type-check; Flutter fromJson for each source_type; no runtime cast errors. |

---

## E) Risk Register

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|-------------|------------|----------|
| View migration uses wrong disputes columns | Phase 1 migration | Med | High | Feature (wrong/missing disputed rows) | View returns no disputed rows; or migration fails | Use task_id/direct_offer_id only; peer review migration SQL | Rollback migration; fix JOIN and re-apply |
| RLS bypass if security_invoker missing | Phase 1 | Low | High | Security-breach | User reports seeing other's work; or RLS audit | Explicit WITH (security_invoker = true) in CREATE VIEW | Re-create view with security_invoker |
| Removing fallback breaks detail for edge rows | Phase 2 WorkItemDetailsViewModel | Med | Med | Feature (detail 404 for some users) | User reports "work item not found" for known item | Ensure Branch 3 and 4 and RLS include all eligible rows; test with awarded-unpaid and direct_offer | Restore fallback behind flag; fix view |
| UNION type mismatch | Phase 1 migration | Low | High | App-wide (view query fails) | Migration fails or Flutter fromJson throws | Align types in all branches (numeric, text, timestamptz, uuid); test migration on copy | Rollback view; fix types; re-apply |
| Direct offer branch column mismatch with direct_offers table | Phase 1 Branch 4 | Med | Med | Feature (direct offers missing/wrong) | Direct offers not in list or wrong price/deadline | Validate Branch 4 against §5.14 column list; run 1-row insert + SELECT | Fix Branch 4 SQL; re-apply |
| Test flake after removing fallback tests | Phase 4 | Low | Low | Local (CI noise) | Intermittent failure in work/dashboard tests | Repurpose tests; add view-only tests with mocked response; no network in unit tests | Stabilize with mocks; document timeout/retry if e2e |
| Docs out of date | Phase 5 | Med | Low | App-wide (wrong mental model) | Dev uses old view shape | DoD: docs updated in same PR as code | Update in follow-up PR |

---

## F) Pre-Mortem (How this fails in real life)

- **This fails when** the migration is copied from 08_PATCH_PLAN without changing the disputes JOIN to task_id/direct_offer_id, so the migration runs but disputed status never appears.
- **This fails when** we deploy the app (no fallbacks) before the view is deployed, so the app queries the old 3-branch view and direct offers disappear until view is fixed.
- **This fails when** Branch 3 (awarded unpaid) is still not visible to the client due to RLS on task_requests/tasks, and we removed the fallback, so "Pay" items vanish for some users.
- **This fails when** one UNION branch returns a different type for price or deadline, and Flutter fromJson throws in production for direct_offer rows.
- **This fails when** we remove the booking fallback and the view sometimes returns no row for a booking (e.g. RLS edge case), so the user clicks a booking and gets "not found".
- **This fails when** dispute status in DB is 'closed' but we only excluded 'resolved', so resolved disputes still show as disputed.
- **This fails when** there is no rollback file and production view is broken; ops must dig through Archive and re-type SQL under pressure.

---

## G) Plan Fixes (Concrete Additions / Expansions)

| Goal | Why | How | Output artifact | Stop condition |
|------|-----|-----|-----------------|----------------|
| Freeze dispute JOIN and open status | Prevent wrong SQL and status drift | Document: disputes JOIN per branch (task_id / direct_offer_id); list "open" status values from schema; add to plan and migration comment | Plan appendix or .TODO contract: dispute JOIN and status list | Migration uses only these; one dispute row verified in view |
| Rollback migration file | One-command rollback | Create SQL file with 3-branch view from Archive (same as 20260315000000); name for rollback | `supabase/migrations/YYYYMMDD_rollback_unified_work_view.sql` | File applies and view is 3-branch again |
| Remove all fallbacks; define not-found | Single source of truth; no ambiguity | Remove WorkItemDetailsViewModel booking fallback; getUnifiedWorkItem returns null → show error/not-found; remove fallback mapper file and all usages | Code: no UnifiedWorkItemFallbackMapper; detail shows not-found when view null | Grep confirms; manual test: invalid id shows not-found |
| _mapUnifiedToWorkItem handles direct_offer | Dashboard shows direct offers from view | Add branch in _mapUnifiedToWorkItem: sourceType == 'direct_offer' → WorkItemType.directOffer, map id, title, price, unifiedStatus, sortRank, etc. from UnifiedWorkItemModel | Code in dashboard_repository.dart | List with direct_offer row renders correctly |
| RLS check matrix + optional script | Prove no cross-user leak | Write matrix (User A client/freelancer, User B; expected row set); optional: SQL that sets auth and SELECTs view | .TODO/ or plan: RLS matrix; optional *.sql | Matrix filled; script run shows no overlap |
| View contract document | Align Flutter and DB | List columns and types; source_type and unified_status allowed values | Plan appendix or .TODO/ contract | Migration and fromJson match contract |
| Test: direct_offer mapping | Regression safety | Unit test: _mapUnifiedToWorkItem(unifiedModel with sourceType direct_offer) → WorkItem type directOffer | test/ unit for dashboard or work | Test passes; no fallback mapper test |
| DoD and rollback in DoD | Release gate | Add DoD: view applied, fallbacks removed, RLS verified, docs updated, rollback file exists; PR checklist | Plan §DoD / §Release | Every PR closes DoD items |

---

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions and Contracts

**Goal:** Lock contracts, resolve disputes schema, and create rollback artifact so execution cannot proceed with wrong assumptions.

**Why:** Prevents wrong migration (disputes JOIN, status list) and missing rollback.

**How:**

1. (@Supabase_Ops) Live scan: list view definition, disputes columns and status values, direct_offers columns. Record in execution log or plan appendix.
2. (@APIContract) Write view contract: column list and types; source_type in ('task','booking','direct_offer'); unified_status includes active, delivered, completed, pending_payment, disputed, canceled, etc. Put in plan or .TODO/.
3. (@Supabase_Ops) Freeze dispute JOIN: Branch 1 & 3 `d.task_id = t.id`; Branch 2 `d.task_id = b.task_id`; Branch 4 `d.direct_offer_id = do.id`. Freeze "open" dispute condition from DB (e.g. status NOT IN ('resolved','closed') or exact list).
4. (@DataMigration) Create rollback migration file with exact 3-branch view from `Archive/20260315000000_award_to_work_cancel_and_view.sql`. Name e.g. `YYYYMMDD_rollback_unified_work_view.sql`.
5. (@Sentinel) Acceptance list: 4 types in My Work; disputed override; RLS no cross-user; no fallback code; docs updated. Non-regression: task/booking flows unchanged.

**Result:** Contract and JOIN/status locked; rollback file exists; acceptance list agreed.

**GATE CHECK (Data/Contracts):** Contract document exists. Dispute JOIN and status list written. Rollback file exists. Live scan done. ✅ Proceed to Phase 1.

---

### Phase 1: Database & Security

**Goal:** Replace view with 4-branch UNION, disputes override, security_invoker = true; verify RLS.

**Why:** Single source of truth at DB; RLS enforced.

**How:**

1. (@Supabase_Ops) Create migration `YYYYMMDD_upgrade_unified_work_view.sql`: DROP VIEW IF EXISTS; CREATE VIEW ... WITH (security_invoker = true) AS Branch 1 (tasks + LEFT JOIN disputes ON d.task_id = t.id), Branch 2 (bookings + LEFT JOIN disputes ON d.task_id = b.task_id), Branch 3 (awarded unpaid unchanged), Branch 4 (direct_offers + LEFT JOIN disputes ON d.direct_offer_id = do.id). Same column list; dispute CASE per frozen rule.
2. (@Supabase_Ops) Ensure UNION type alignment (numeric, text, timestamptz, uuid).
3. (@Supabase_Ops) Apply migration to target environment.
4. (@Sentinel) Verification query: SELECT source_type, COUNT(*) FROM vw_unified_work_items GROUP BY source_type (and optionally insert one per type and confirm).
5. (@Supabase_Ops) RLS check matrix: User A / User B, client/freelancer, expected rows. Optional: SQL script with SET + SELECT; document expected result.
6. (@Sentinel) Run RLS check: no overlap of ids between users.

**Result:** New view live; RLS verified.

**GATE CHECK (Security):** security_invoker = true in view. RLS matrix or script run; no cross-user rows. ✅ Proceed to Phase 2.

---

### Phase 2: App Layer (MVVM)

**Goal:** Remove all fallbacks; single query path; map direct_offer from view to WorkItem.

**Why:** Single source of truth in app; no drift.

**How:**

1. (@Architect) WorkManagementService: remove _getTaskUnifiedWorkItemFallback and its call; remove UnifiedWorkItemFallbackMapper import. getUnifiedWorkItem: return UnifiedWorkItemModel.fromJson(response) or null (no fallback).
2. (@Architect) DashboardRepository: remove _fetchAwardedPendingPaymentFallback, _fetchDirectOffers, merge/sort of direct offers. Single query to vw_unified_work_items by client_id or freelancer_id. Update _mapUnifiedToWorkItem: add branch for u.sourceType == 'direct_offer' → WorkItemType.directOffer (id, title, price, status, sortRank, lastActivityAt, etc. from UnifiedWorkItemModel). Remove _mapDirectOfferToWorkItem and _directOfferStatusToUnified / _directOfferStatusToBucket if unused.
3. (@Architect) Delete lib/features/work/models/unified_work_item_fallback_mapper.dart. Remove every import and usage (WorkManagementService, DashboardRepository, WorkItemDetailsViewModel).
4. (@Architect) WorkItemDetailsViewModel: remove branch that uses UnifiedWorkItemFallbackMapper.fromBooking when view returns null. When getUnifiedWorkItem returns null, set _workItem = null and error/not-found. For type == 'direct_offer', load via getUnifiedWorkItem(id, 'direct_offer').
5. (@Architect) UnifiedWorkItemModel: confirm fromJson and _mapStatus handle source_type 'direct_offer' and unified_status 'disputed'. Add isDirectOffer getter if used in UI.
6. (@Sentinel) flutter analyze clean; grep for UnifiedWorkItemFallbackMapper, _fetchAwardedPendingPaymentFallback, _fetchDirectOffers in lib → 0 hits.

**Result:** No fallback code; one path: view → model → _mapUnifiedToWorkItem → WorkItem.

**GATE CHECK (Backend/API):** No fallback references; _mapUnifiedToWorkItem covers all 4 types. ✅ Proceed to Phase 3.

---

### Phase 3: UI

**Goal:** Correct loading/empty/error and not-found for work detail.

**Why:** Stable UX when view returns empty or null.

**How:**

1. (@Pixel) Dashboard Work tab: already uses repo list; ensure loading and empty states. Work detail: when workItem is null (view returned null), show not-found or error state; no crash.
2. (@Pixel) Work item cards and next actions: already support WorkItemType.directOffer; confirm no change needed when repo returns direct_offer from view.
3. (@Sentinel) Smoke: open My Work (loading → list); open detail for task/booking/direct_offer (load → content or not-found).

**Result:** UX stable; not-found defined.

**GATE CHECK (UI/Integration):** Loading/empty/error and not-found behave correctly. ✅ Proceed to Phase 4.

---

### Phase 4: QA + Security

**Goal:** Contract, RLS, functional and regression coverage; tests updated.

**Why:** No regressions; security proven.

**How:**

1. (@Sentinel) Contract: view columns and types match contract; fromJson and _mapUnifiedToWorkItem handle all source_type and unified_status.
2. (@Sentinel) RLS: run matrix or script; assert no cross-user rows.
3. (@Sentinel) Remove or repurpose test/unit/work/unified_work_item_fallback_mapper_test.dart. Add unit test: _mapUnifiedToWorkItem with UnifiedWorkItemModel(sourceType: 'direct_offer', ...) → WorkItem type directOffer and correct fields.
4. (@Sentinel) Manual E2E: create task (in progress), booking (active), awarded unpaid task, direct offer (accepted/active). My Work as client and freelancer — all appear. Open detail for each type — correct or not-found. File dispute on task — refresh; status Disputed.
5. (@Sentinel) Edge: getUnifiedWorkItem(id, type) returns null → not-found, no crash. Network error → error state.
6. (@Sentinel) Regression: existing task and booking flows (list, detail, pay, deliver) unchanged.

**Result:** All checks pass; tests updated.

**GATE CHECK (Release/QA):** RLS verified; functional and regression passed; test contract (view-only + mapping) in place. ✅ Proceed to Phase 5.

---

### Phase 5: Documentation & Release

**Goal:** Docs match code and view; DoD closed.

**Why:** Future work and ops rely on accurate docs.

**How:**

1. (@DocsKeeper) Update Sline_everything/SUPABASE_SETUP.md §6.4: 4 branches (tasks, bookings, awarded pending, direct_offers); disputes override; security_invoker = true; column list unchanged.
2. (@DocsKeeper) Update Work Management in Sline_everything/DEVELOPER_GUIDE.md: view is single source of truth; no fallback or direct_offer merge.
3. (@DocsKeeper) Optional: STRUCTURE.md / MVP_ROADMAP if Work/dashboard is summarized there.
4. (@Sentinel) DoD: view applied, fallbacks removed, RLS verified, docs updated, rollback file exists. PR checklist: migration applied (or documented), flutter analyze, tests pass, docs updated.

**Result:** Docs and release gate complete.

**GATE CHECK (Release/QA):** Docs updated; DoD and PR checklist satisfied. ✅ Plan complete.

---

## I) Change Report (Diff-Style)

### 1) Original issues summary

- Disputes JOIN in 08_PATCH_PLAN used non-existent columns (related_entity_id/type).
- "Open" dispute status for override not defined from schema.
- No rollback migration file; rollback described only in text.
- WorkItemDetailsViewModel booking fallback left optional (two sources of truth).
- RLS verification was manual only; no matrix or script.
- Test strategy: remove fallback test but no replacement contract for view-only and direct_offer mapping.
- No explicit DoD or PR checklist; no Test Infrastructure gate.

### 2) Added steps

- Phase 0: Live scan; view contract document; freeze dispute JOIN and open status list; create rollback migration file; acceptance list.
- RLS check matrix and optional SQL script (Phase 1).
- Explicit removal of booking fallback and not-found behavior (Phase 2).
- _mapUnifiedToWorkItem branch for direct_offer with exact field mapping (Phase 2).
- Unit test for direct_offer mapping (Phase 4).
- DoD and PR checklist (Phase 5).
- GATE CHECK at end of each phase.

### 3) Removed steps

- None removed; all original steps kept and refined.

### 4) Reordered steps

- Contracts and dispute/status freeze moved before any migration (Phase 0 before Phase 1).
- Rollback file creation moved to Phase 0 (before applying new view).
- RLS matrix/script explicitly in Phase 1 before marking Security gate pass.

### 5) Expanded steps

- Phase 1.1: migration step now specifies exact JOIN columns (task_id / direct_offer_id) and dispute condition from frozen list.
- Phase 2.2: _mapUnifiedToWorkItem expansion for direct_offer; removal of _mapDirectOfferToWorkItem and helpers.
- Phase 2.3: WorkItemDetailsViewModel — explicit "set null and show not-found" when view returns null.
- Phase 4: test removal + replacement (unit test for direct_offer mapping); RLS and E2E spelled out.

### 6) Why (short, practical)

- Contract and JOIN freeze prevent wrong migration and rework.
- Rollback file enables one-command rollback in production.
- Removing all fallbacks and defining not-found avoids two sources of truth and product ambiguity.
- RLS matrix/script makes security verification repeatable.
- Gate checks block progress until each phase is provably done.
- DoD and PR checklist close the release gate explicitly.

### 7) Residual risks

- Branch 3 (awarded unpaid) visibility still depends on RLS on task_requests/tasks; if RLS is too strict, some users lose "Pay" items after fallback removal — mitigate by testing with real roles before release.
- No automated E2E in plan; manual E2E remains critical path — consider adding a short E2E checklist or script later.
- Flake in any new unit test (e.g. mapping test) — use mocks and deterministic data; no network in unit tests.

---

## Mandatory Critique Checklist (Summary)

### 3.1 Scope & Requirements — ✅ Goal measurable; non-goals stated. Edge (null view row, network error) now explicit. Abuse (cross-user) in RLS.

### 3.2 Dependencies & Ordering — ✅ Fixed: Phase 0 (contracts, rollback) before Phase 1; no UI before stable view.

### 3.3 Data Model & Contracts — ✅ View contract and dispute JOIN/status frozen; DTO = view row; source_type/unified_status enumerated.

### 3.4 Security — ✅ security_invoker = true; RLS matrix/script added; no public read of view beyond RLS.

### 3.5 Performance — ✅ Single view query; optional indexes noted in original plan; no N+1.

### 3.6 Error Handling — ✅ Not-found and error state defined; optional logging mentioned.

### 3.7 UX & State Machine — ✅ Loading/empty/error and not-found; no double-submit change; timeout/retry not in scope.

### 3.8 Testing & QA — ⚠️ Improved: test removal + replacement (direct_offer mapping test); RLS verification artifact. Still no full test harness for view; manual E2E required. Deterministic unit test with mocked view row.

### 3.9 Release & Migration — ✅ Rollback file added; DoD and PR checklist; deploy order (view then app) stated.

### 3.10 Developer Workflow — ✅ DoD and PR checklist added; docs update in Phase 5; branch strategy optional.

---

**End of Plan Critic. Use this document as the execution-ready plan; run phases in order and pass each GATE CHECK before proceeding.**
