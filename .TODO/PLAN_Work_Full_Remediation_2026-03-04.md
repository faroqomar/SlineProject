# 📌 Plan: Work Feature Full Remediation

## 1) Goal

- Goal:
  - Remediate the `work` feature so task work, booking work, delivery/review, change/extension requests, awarded-pending-payment actions, and chat entry all run on verified contracts, server-authoritative transitions, and MVVM-safe boundaries. References: `lib/features/work/view/work_item_details_screen.dart:30-690`, `lib/features/work/viewmodels/work_item_details_view_model.dart:11-328`, `lib/features/work/services/work_management_service.dart:14-441`, `Sline_everything/DEVELOPER_GUIDE.md:1953-2024`.
- Why:
  - The current repo state has verified financial correctness risks, unverified work SQL provenance, direct widget orchestration, duplicated fallback logic, and missing work-specific test coverage. References: `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/view/work_item_details_screen.dart:497-585`, `lib/features/work/view/work_item_details_screen.dart:658-679`, `lib/features/work/viewmodels/work_item_details_view_model.dart:64-160`, `lib/features/work/services/work_management_service.dart:165-243`, `lib/features/work/services/work_management_service.dart:274-405`, `lib/features/tasks/services/task_service.dart:764-799`, `lib/features/booking/services/booking_service.dart:117-311`, `lib/features/dashboard/data/dashboard_repository.dart:232-290`.
- Result:
  - A work module with checked-in backend source-of-truth, explicit release gates, one shared unified-work contract, safer money/status transitions, deterministic UI states, and regression coverage tied to stable selectors and fixtures. References: `Sline_everything/DEVELOPER_GUIDE.md:42-57`, `Sline_everything/STRUCTURE.md:83-96`, `Sline_everything/CODE_REVIEW.md:16-23`, `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`.

## 2) Scope

### In-Scope

- `lib/features/work/**` and its route/local widgets/viewmodels/services/models. References: `lib/features/work/view/work_item_details_screen.dart:30-690`, `lib/features/work/view/widgets/submit_delivery_modal.dart:8-68`, `lib/features/work/view/widgets/request_extension_modal.dart:8-79`, `lib/features/work/view/widgets/review_delivery_modal.dart:9-161`, `lib/features/work/viewmodels/work_item_details_view_model.dart:11-328`, `lib/features/work/services/work_management_service.dart:14-441`, `lib/features/work/models/unified_work_item_model.dart:3-119`.
- Direct dependencies already touched by this feature: work dashboard surfaces, bookings tab, deep-link routing, booking service, chat service, profile summary, task/tender payment flows, root payment wiring. References: `lib/core/services/deep_link_service.dart:112-145`, `lib/features/dashboard/view/widgets/work_item_card.dart:83-93`, `lib/features/dashboard/view/tabs/bookings_tab.dart:83-116`, `lib/features/dashboard/data/dashboard_repository.dart:72-290`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:898-953`, `lib/features/booking/services/booking_service.dart:117-311`, `lib/features/chat/services/message_service.dart:15-84`, `lib/features/chat/viewmodels/chat_view_model.dart:156-188`, `lib/features/profile/services/profile_summary_service.dart:6-58`, `lib/features/tasks/services/task_service.dart:749-820`, `lib/features/tasks/services/tender_payment_coordinator.dart:11-105`, `lib/core/services/payment_service.dart:213-280`, `lib/main.dart:176-208`.
- Touched Supabase objects and server flows: `vw_unified_work_items`, `bookings`, `task_requests`, `work_contracts`, `change_requests`, `extension_requests`, `rpc_submit_delivery`, `rpc_request_revision`, `rpc_accept_change_request`, `rpc_approve_delivery`, `cancel_awarded_offer`, `pay_awarded_offer`, and the existing booking refund edge function. References: `lib/features/work/services/work_management_service.dart:23-409`, `lib/features/tasks/services/task_service.dart:764-820`, `supabase/functions/booking_decline_refund/index.ts:122-187`, `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql:4-68`, `supabase/migrations/20260224_fix_rpc_approve_delivery_digest_schema.sql:4-64`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:110-194`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:1-186`, `Sline_everything/SUPABASE_SETUP.md:612-650`, `Sline_everything/SUPABASE_SETUP.md:967-1101`, `Sline_everything/SUPABASE_SETUP.md:1790-1824`.
- Test, release, and docs assets needed to make the fix safe. References: `Sline_everything/DEVELOPER_GUIDE.md:169-173`, `Sline_everything/STRUCTURE.md:159-177`, `test/unit/models/unified_work_item_model_test.dart:1-36`, `test/widget/dashboard/work_tab_test.dart:1-127`.

### Out-of-Scope

- Unrelated wallet UI, direct-offers runtime, and generic chat/message features beyond the exact contracts the work screen calls today. References: `Sline_everything/STRUCTURE.md:132-152`, `lib/features/chat/services/message_service.dart:43-99`.
- Replacing QiCard internals or redesigning ledger architecture beyond the authority/recovery seams the work feature touches. References: `lib/features/tasks/services/tender_payment_coordinator.dart:31-93`, `lib/features/tasks/services/task_service.dart:764-799`, `Sline_everything/MVP_ROADMAP.md:48-52`, `Sline_everything/MVP_ROADMAP.md:82-84`.
- Shipping DB/security changes without authenticated live Supabase verification. Current live state remains `UNVERIFIED` in this session because Supabase MCP auth failed.

## 3) Assumptions + Decision Needed (Blocking)

### Assumptions

- Existing widget and integration harnesses under `test/test_support/` and `test/integration_test/support/` will be reused and extended rather than replaced. References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`.
- The work feature remains screen-scoped and should not become a global provider. References: `lib/features/work/view/work_item_details_screen.dart:40-70`, `Sline_everything/DEVELOPER_GUIDE.md:1987-1991`.
- Live Supabase remains the real source of truth for schema/RLS/RPC reality, but DB implementation and release are blocked until MCP authentication succeeds.

### Decision Needed (Blocking)

1. Booking chat contract
- Options:
  - Plain DM path for booking work.
  - Dedicated booking conversation server contract.
- Recommended: plain DM path first.
- Why: it removes the verified contract bug immediately without inventing a new server surface. References: `lib/features/work/view/work_item_details_screen.dart:658-673`, `lib/features/chat/services/message_service.dart:21-33`.
- Plan impact:
  - Plain DM: app fix can land before new backend work.
  - Dedicated contract: adds Phase 2 security + Phase 3 backend work.

2. Client booking cancel authority
- Options:
  - One server-authoritative cancel/refund contract.
  - Separate app branches for unpaid cancel and held refund.
- Recommended: one server-authoritative cancel/refund contract.
- Why: current direct status update is inconsistent with the existing refund edge flow. References: `lib/features/work/services/work_management_service.dart:398-405`, `supabase/functions/booking_decline_refund/index.ts:122-187`.
- Plan impact:
  - Server-authoritative: booking cancel stays in scope and is safe to release.
  - App branches: blocked unless both branches terminate in server authority.

3. Live access fallback mode
- Options:
  - Block all work.
  - Proceed with app/test/docs prep, but block DB reconcile and release.
- Recommended: proceed with app/test/docs prep, but block DB reconcile and release.
- Why: app-side correctness work is still valid, but DB assumptions are not. References: `Sline_everything/SUPABASE_SETUP.md:612-650`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`.

4. Fallback mapper ownership
- Options:
  - Duplicate in work and dashboard.
  - Work-owned shared mapper used by dashboard.
- Recommended: work-owned shared mapper.
- Why: unified-work domain semantics belong with the work feature. References: `lib/features/work/models/unified_work_item_model.dart:3-119`, `lib/features/dashboard/data/dashboard_repository.dart:191-290`.

5. Release slicing
- Options:
  - One PR.
  - Three PRs: gates/contracts, runtime, release/docs.
- Recommended: three PRs.
- Why: reduces rollback and review risk across DB, runtime, and release evidence. References: `Sline_everything/CODE_REVIEW.md:16-23`.

## 4) Evidence & Findings (From Scan)

### Existing

- The work feature is the documented unified task+booking workspace and is already route-local, not app-global. References: `lib/features/work/view/work_item_details_screen.dart:40-70`, `Sline_everything/DEVELOPER_GUIDE.md:1953-1991`.
- Repo docs declare the intended work backend surface, including work tables, unified view, and delivery/review RPCs. References: `Sline_everything/DEVELOPER_GUIDE.md:1998-2005`, `Sline_everything/SUPABASE_SETUP.md:612-650`, `Sline_everything/SUPABASE_SETUP.md:967-1101`, `Sline_everything/SUPABASE_SETUP.md:1790-1824`.
- Existing server-authoritative adjacent flows already exist for booking refund and task award cancel/payment. References: `supabase/functions/booking_decline_refund/index.ts:122-187`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:110-194`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:1-186`.
- Existing test harnesses already support widget and integration setup, but the work plan had not been tied to them. References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`.

### Missing

- No checked-in migration defining `work_contracts`, `change_requests`, `extension_requests`, `rpc_request_revision`, or `rpc_accept_change_request` was found in the current `supabase/migrations/` scan. References: `lib/features/work/services/work_management_service.dart:165-243`, `lib/features/work/services/work_management_service.dart:274-350`, `Sline_everything/SUPABASE_SETUP.md:612-650`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`.
- No dedicated work-detail tests were found for the work screen, viewmodel, service, or modals. References: `test/unit/models/unified_work_item_model_test.dart:1-36`, `test/widget/dashboard/work_tab_test.dart:1-127`.
- No live Supabase confirmation is available in this session because MCP startup failed with `Auth required`.

### Must NOT duplicate

- Do not keep duplicate fallback mappers across work and dashboard. References: `lib/features/work/services/work_management_service.dart:42-128`, `lib/features/dashboard/data/dashboard_repository.dart:232-290`.
- Do not keep multiple UI-owned tender payment launchers. References: `lib/features/work/view/work_item_details_screen.dart:208-233`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`.
- Do not leave client-owned privileged booking transitions in place. References: `lib/features/work/services/work_management_service.dart:376-405`, `lib/features/booking/services/booking_service.dart:117-311`.
- Do not fabricate historical migrations to explain missing work SQL provenance.

### Conflicts / Risks

- Docs describe a work schema and RLS surface that is not fully represented in checked-in migration history. References: `Sline_everything/SUPABASE_SETUP.md:36-38`, `Sline_everything/SUPABASE_SETUP.md:612-650`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`.
- Booking chat currently sends a booking UUID into a task-only RPC path. References: `lib/features/work/view/work_item_details_screen.dart:658-673`, `lib/features/chat/services/message_service.dart:21-33`.
- Client booking cancel bypasses refund authority, and tender payment can create a hold before DB state completes. References: `lib/features/work/services/work_management_service.dart:398-405`, `lib/features/tasks/services/task_service.dart:764-799`, `supabase/functions/booking_decline_refund/index.ts:122-187`.
- The work widget layer currently owns payment orchestration, dashboard mutation calls, and chat launch logic. References: `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/view/work_item_details_screen.dart:665-679`, `Sline_everything/DEVELOPER_GUIDE.md:42-57`.

## 5) System Impact Map

- UI:
  - `WorkItemDetailsScreen`, its bottom CTA bar, pending-payment panel, and three modal flows. References: `lib/features/work/view/work_item_details_screen.dart:77-690`, `lib/features/work/view/widgets/submit_delivery_modal.dart:8-68`, `lib/features/work/view/widgets/request_extension_modal.dart:8-79`, `lib/features/work/view/widgets/review_delivery_modal.dart:9-161`.
- MVVM/App Logic:
  - `WorkItemDetailsViewModel` and `WorkManagementService`, plus dashboard fallback mapping and work-card entry routing. References: `lib/features/work/viewmodels/work_item_details_view_model.dart:44-328`, `lib/features/work/services/work_management_service.dart:23-430`, `lib/features/dashboard/data/dashboard_repository.dart:72-290`.
- Database:
  - unified work view, work tables, booking/task tables, and delivery/review/cancel/payment RPC surfaces. References: `Sline_everything/SUPABASE_SETUP.md:612-650`, `Sline_everything/SUPABASE_SETUP.md:967-1101`, `Sline_everything/SUPABASE_SETUP.md:1790-1824`.
- RLS/Security:
  - participant-only work access, booking cancel/refund authority, and chat authorization boundary. References: `Sline_everything/SUPABASE_SETUP.md:1082-1101`, `lib/features/chat/services/message_service.dart:21-33`, `supabase/functions/booking_decline_refund/index.ts:122-187`.
- Observability:
  - client work-load logs and server refund audit/notification flow. References: `lib/features/work/viewmodels/work_item_details_view_model.dart:89-103`, `supabase/functions/booking_decline_refund/index.ts:122-179`.
- Compatibility & Migration:
  - unified-view lag fallback, booking direct detail path, and dashboard work-card path must all stay safe during rollout. References: `lib/features/work/viewmodels/work_item_details_view_model.dart:81-84`, `lib/core/services/deep_link_service.dart:112-145`, `lib/features/dashboard/view/tabs/bookings_tab.dart:83-116`.

## 6) Execution Gates (Current Status)

- Gate 0: Test Infrastructure Gate
  - Current status: FAIL
  - Pass condition:
    - selector map exists
    - fixture manifest exists
    - timeout/retry/failure-artifact policy exists
    - work tests are mapped to existing harnesses
- Gate 1: Data/Contracts Gate
  - Current status: FAIL
  - Pass condition:
    - booking chat contract is written
    - action/idempotency matrix is written
    - DB provenance strategy is written
    - shared fallback ownership is locked
- Gate 2: Security Gate
  - Current status: FAIL
  - Pass condition:
    - live Supabase auth is available
    - positive/negative RLS checks are defined and executed
    - DB reconcile is blocked until live verification exists
- Gate 3: Backend/API Gate
  - Current status: FAIL
  - Pass condition:
    - atomic booking authority is designed
    - work SQL source-of-truth reconcile path is approved
    - app service split order is fixed
- Gate 4: UI/Integration Gate
  - Current status: FAIL
  - Pass condition:
    - UI state matrix exists
    - stable keys/selectors exist
    - widget/integration coverage targets map to visible states
- Gate 5: Release/QA Gate
  - Current status: FAIL
  - Pass condition:
    - PR plan exists
    - release checklist exists
    - live DB evidence, tests, docs, and rollback readiness all pass

---

# ✅ Execution Phases (Checklist)

## Phase 0: Gates & Contracts

> Primary: @Sentinel

### 0.0 Test Infrastructure Gate

- [ ] (@Architect) Create `.TODO/TEST_INFRA_work_2026-03-04.md` defining the test type mix:
  - unit: mapper/service/viewmodel logic
  - widget: work detail shell, action bar, modals
  - integration: critical routed flows only after selectors/fixtures exist
  References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `Sline_everything/DEVELOPER_GUIDE.md:169-173`.
- [ ] (@Pixel) Create `.TODO/SELECTORS_work_2026-03-04.md` mapping required keys for:
  - work detail route shell
  - action buttons
  - pending-payment panel
  - modal submit/cancel buttons
  - chat entry button
  References: `lib/features/work/view/work_item_details_screen.dart:497-690`, `lib/features/work/view/widgets/submit_delivery_modal.dart:8-68`, `lib/features/work/view/widgets/request_extension_modal.dart:8-79`, `lib/features/work/view/widgets/review_delivery_modal.dart:9-161`.
- [ ] (@Sentinel) Create `.TODO/FIXTURES_work_2026-03-04.md` and `.TODO/FAILURE_ARTIFACTS_work_2026-03-04.md` covering fixture types, timeout budgets, rerun policy, and failure-log capture paths.
- **Verify (@Sentinel):** no new work tests are authored before selectors, fixtures, and timeout/retry policy exist.

### 0.1 Live Access Gate

- [ ] (@Supabase_Ops) Create `.TODO/LIVE_ACCESS_work_2026-03-04.md` recording the current MCP auth blocker and the rule that DB reconcile/release work cannot proceed without authenticated live scan evidence.
- [ ] (@Supabase_Ops) Attempt authenticated `@mcp:supabase-mcp-server:` access and record the result for the touched work objects only.
- [ ] (@Sentinel) Mark all DB/security/release tasks blocked if live auth remains unavailable; allow only app-safe/test-safe/docs-safe prep work.
- **Verify (@Sentinel):** the plan has a hard stop/go rule for live DB access.

### 0.2 Spec Lock

- [ ] (@Sentinel) Freeze the non-regression list:
  - no booking ids in task chat RPCs
  - no direct client booking cancel status update
  - no duplicated fallback mapper
  - no widget-layer payment/chat/dashboard orchestration
  - no info-level participant-id logging
  References: `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/view/work_item_details_screen.dart:658-679`, `lib/features/work/services/work_management_service.dart:398-405`, `lib/features/work/viewmodels/work_item_details_view_model.dart:89-103`, `lib/features/dashboard/data/dashboard_repository.dart:232-290`.
- [ ] (@Architect) Lock the target refactor paths:
  - `lib/features/work/services/work_item_query_service.dart`
  - `lib/features/work/services/work_item_action_service.dart`
  - `lib/features/work/services/work_item_chat_service.dart`
  - `lib/features/work/models/unified_work_item_fallback_mapper.dart`
  - `lib/features/work/viewmodels/work_item_actions_controller.dart`
  - `lib/features/work/view/widgets/work_item_overview_tab.dart`
  - `lib/features/work/view/widgets/work_item_requests_tab.dart`
  - `lib/features/work/view/widgets/work_item_contract_tab.dart`
  - `lib/features/work/view/widgets/work_item_action_bar.dart`
  - `lib/features/work/view/widgets/work_item_pending_payment_panel.dart`
  - compatibility facade retained temporarily at `lib/features/work/services/work_management_service.dart`
- **Verify (@Sentinel):** every later task maps to these bounded files or an explicit Supabase artifact.

### 0.3 Threat Model

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_work_2026-03-04.md` covering unauthorized work reads, forged booking transitions, repeated pay/cancel taps, booking chat misuse, and PII log leakage.
- [ ] (@ThreatModeler) Add negative test cases for participant/non-participant work access, booking cancel with held funds, provider/client role misuse, and booking chat routing.
- [ ] (@Sentinel) Tie each threat directly to one Phase 4 verification step.
- **Verify (@Sentinel):** all sensitive/abuse cases are testable and explicitly owned.

### 0.4 Contracts

- [ ] (@APIContract) Create `.TODO/DECISION_work_chat_contract_2026-03-04.md` locking the booking chat contract.
- [ ] (@APIContract) Create `.TODO/CONTRACT_work_actions_2026-03-04.md` defining:
  - action owner
  - request/response shapes
  - error taxonomy
  - caller responsibilities
  - acceptance states
  for submit delivery, approve delivery, request revision, request extension, accept/decline/cancel booking, pay awarded offer, and cancel award.
- [ ] (@APIContract) Create `.TODO/IDEMPOTENCY_work_2026-03-04.md` defining retry rules and duplicate-submit expectations for each mutation.
- [ ] (@Sentinel) Block service/UI work until these contracts exist.
- **Verify (@Sentinel):** every state-changing action has one documented contract and one retry rule.

### 0.5 DB Provenance

- [ ] (@DataMigration) Create `.TODO/DB_PROVENANCE_work_2026-03-04.md` documenting the missing work SQL source-of-truth and the forward-reconcile-only rule.
- [ ] (@DataMigration) List the exact missing objects that need source-controlled definitions if live scan confirms they exist:
  - `work_contracts`
  - `change_requests`
  - `extension_requests`
  - `rpc_request_revision`
  - `rpc_accept_change_request`
- [ ] (@Sentinel) Mark fake historical migration reconstruction as disallowed.
- **Verify (@Sentinel):** migration authors have a concrete provenance rule before Phase 1 starts.

### 0.6 UI State Matrix

- [ ] (@Pixel) Create `.TODO/STATE_MATRIX_work_2026-03-04.md` covering:
  - initial load
  - partial optional-data failure
  - full load failure
  - pending-payment state
  - active state
  - awaiting review
  - delivered/reviewable
  - duplicate-submit busy state
  - chat-open failure
  - invalid extension input
  - review failure
- [ ] (@Sentinel) Bind each state to one widget or integration test target.
- **Verify (@Sentinel):** every user-visible state has one expected render path and one planned verification.

### 0.7 PR Plan & Release Skeleton

- [ ] (@SlineDocs) Create `.TODO/PR_PLAN_work_2026-03-04.md` with three slices:
  - PR1: gates/contracts/provenance/test infra
  - PR2: runtime/backend/UI changes
  - PR3: release evidence/docs sync/live verification closeout
- [ ] (@SlineDocs) Create `.TODO/RELEASE_CHECKLIST_work_2026-03-04.md` tying analyze, tests, manual scenarios, live DB verification, docs sync, and rollback readiness together.
- [ ] (@Sentinel) Define per-slice done criteria and reviewer expectations.
- **Verify (@Sentinel):** rollout/review order is explicit before implementation begins.

### GATE CHECK

- [ ] (@Sentinel) Gate 0 passes only when test infra, live-access mode, contracts, provenance, UI-state matrix, and PR/release scaffolding artifacts all exist.

---

## Phase 1: Data/Contracts Gate

> Primary: @Architect

### 1.1 Unified Work Contract

- [ ] (@Architect) Extract `lib/features/work/models/unified_work_item_fallback_mapper.dart` and define it as the single fallback mapper for both work detail and dashboard.
- [ ] (@Architect) Remove fallback duplication from dashboard by routing its fallback path through the shared mapper or shared work query contract. References: `lib/features/dashboard/data/dashboard_repository.dart:232-290`, `lib/features/work/viewmodels/work_item_details_view_model.dart:122-160`.
- [ ] (@Sentinel) Add unit tests covering:
  - booking completed vs delivered
  - pending-payment award fallback
  - missing unified-view row with fallback booking
- **Verify (@Sentinel):** dashboard and work detail resolve the same fallback item semantics for the same source rows.

### 1.2 Action/Status Matrix

- [ ] (@APIContract) Lock a typed status/action matrix for:
  - booking accept/decline/cancel
  - delivery submit/review/revision
  - extension request
  - award pay/cancel
- [ ] (@Architect) Ensure `canReview` and CTA resolution derive from role + contract, not fallback aliasing alone. References: `lib/features/work/viewmodels/work_item_details_view_model.dart:48-50`, `lib/features/work/viewmodels/work_item_details_view_model.dart:135-137`, `Sline_everything/DEVELOPER_GUIDE.md:2020-2021`.
- [ ] (@Sentinel) Add explicit acceptance tests for each action/state pair in the contract artifact.
- **Verify (@Sentinel):** no CTA or review state remains dependent on ad hoc raw-string interpretation.

### 1.3 Read-Path and Partial-Failure Contract

- [ ] (@Architect) Define the canonical work-detail load path separating:
  - required data
  - optional contract/history/profile data
  - fallback creation path
- [ ] (@Architect) Replace the all-or-nothing `Future.wait` contract with a partial-failure-tolerant design in the implementation plan. References: `lib/features/work/viewmodels/work_item_details_view_model.dart:64-118`.
- [ ] (@Sentinel) Require the state matrix and tests to distinguish required-load failure from optional-load degradation.
- **Verify (@Sentinel):** optional request/contract/profile failures cannot blank the entire screen.

### GATE CHECK

- [ ] (@Sentinel) Gate 1 passes only when the unified work contract, action/status matrix, and partial-failure load contract are explicit and test-mapped.

---

## Phase 2: Security/RLS Gate

> Primary: @Supabase_Ops

### 2.0 Live Supabase Confirmation

- [ ] (@Supabase_Ops) Authenticate `@mcp:supabase-mcp-server:` and re-scan only the touched objects:
  - `vw_unified_work_items`
  - `work_contracts`
  - `change_requests`
  - `extension_requests`
  - `bookings`
  - `task_requests`
  - `rpc_submit_delivery`
  - `rpc_request_revision`
  - `rpc_accept_change_request`
  - `rpc_approve_delivery`
  - `cancel_awarded_offer`
  - `pay_awarded_offer`
- [ ] (@Supabase_Ops) Record exact live signatures, policies, indexes, and drift from repo docs/migrations in `.TODO/LIVE_ACCESS_work_2026-03-04.md`.
- [ ] (@Sentinel) Stop this phase and block release if live auth remains unavailable.
- **Verify (@Sentinel):** no DB/RLS implementation proceeds without authenticated live evidence.

### 2.1 RLS Matrix

- [ ] (@ThreatModeler) Create `.TODO/RLS_MATRIX_work_2026-03-04.md` with positive/negative cases for participant, requester, client, freelancer, and non-participant access.
- [ ] (@Supabase_Ops) Define exact validation queries for `work_contracts`, `change_requests`, `extension_requests`, and any new booking/work RPCs.
- [ ] (@Sentinel) Require both allowed and forbidden checks to pass before moving to backend changes.
- **Verify (@Sentinel):** participant-only access and least privilege are demonstrated, not assumed.

### 2.2 Sensitive Action Authority

- [ ] (@Supabase_Ops) Confirm or design one server-authoritative cancel/refund authority for booking cancel, branching by payment state.
- [ ] (@Supabase_Ops) Confirm or design one atomic booking accept authority covering `pending + held` and `paid_request_pending`.
- [ ] (@ThreatModeler) Require auditable traces for sensitive money/state transitions.
- **Verify (@Sentinel):** no client path can directly mutate privileged booking states after this phase.

### 2.3 Provenance Reconcile Rule

- [ ] (@DataMigration) If live objects exist without repo SQL, plan forward reconcile migrations only; no fake historical timestamps or backfilled fiction.
- [ ] (@Sentinel) Review every proposed work migration against the provenance artifact before approval.
- **Verify (@Sentinel):** repo/live drift handling remains explicit and reviewable.

### GATE CHECK

- [ ] (@Sentinel) Gate 2 passes only when live access is authenticated, RLS checks are defined/passing, and sensitive action authority is locked to server-side paths.

---

## Phase 3: Backend/API Gate

> Primary: @Architect

### 3.1 Work SQL Source-of-Truth

- [ ] (@Supabase_Ops) Add checked-in migration definitions for missing live work objects only after Phase 2 confirms reality.
- [ ] (@DataMigration) Use additive-first naming and verify queries for:
  - work tables
  - missing RPCs
  - supporting indexes
- [ ] (@Sentinel) Review that the migration set matches the provenance artifact and live scan evidence.
- **Verify (@Sentinel):** every app-used work DB object is now traceable in repo SQL or explicitly marked out-of-scope.

### 3.2 Atomic Booking and Payment Authority

- [ ] (@Supabase_Ops) Implement or reconcile one atomic booking accept authority.
- [ ] (@Supabase_Ops) Implement or reconcile one booking cancel/refund authority that covers unpaid and held cases.
- [ ] (@Supabase_Ops) Reconcile pay-awarded-offer recovery/idempotency semantics so duplicate or partial hold/pay failures have one contract. References: `lib/features/tasks/services/task_service.dart:764-799`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:110-194`.
- [ ] (@Sentinel) Require acceptance queries/manual scenarios for repeated taps, transient failures, and retry-after-failure.
- **Verify (@Sentinel):** money-sensitive transitions are server-authoritative and retry-safe.

### 3.3 App Service Split

- [ ] (@Architect) Split `lib/features/work/services/work_management_service.dart` into:
  - `lib/features/work/services/work_item_query_service.dart`
  - `lib/features/work/services/work_item_action_service.dart`
  - `lib/features/work/services/work_item_chat_service.dart`
  - temporary compatibility facade at `lib/features/work/services/work_management_service.dart`
- [ ] (@Architect) Move booking chat routing, booking action routing, and tender-payment launcher orchestration into these focused services/controllers. References: `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/view/work_item_details_screen.dart:658-679`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`.
- [ ] (@Sentinel) Add grep-based review checks to confirm the widget layer no longer constructs payment/chat/dashboard orchestration directly.
- **Verify (@Sentinel):** backend access is centralized and MVVM-safe.

### 3.4 ViewModel/Controller Contract

- [ ] (@Architect) Keep `WorkItemDetailsViewModel` focused on state and loading; move mutations into `lib/features/work/viewmodels/work_item_actions_controller.dart` or equivalent route-local controller.
- [ ] (@Architect) Make route-local dependencies explicit and stop relying on hidden root-provider knowledge in the widget layer. References: `lib/features/work/view/work_item_details_screen.dart:210-214`, `lib/main.dart:176-208`.
- [ ] (@Sentinel) Require viewmodel/controller tests for happy path, partial failure, and duplicate-submit prevention.
- **Verify (@Sentinel):** state orchestration and mutation orchestration are separated and testable.

### GATE CHECK

- [ ] (@Sentinel) Gate 3 passes only when work SQL provenance is reconciled, atomic authority is server-backed, and app services/viewmodels are split behind explicit contracts.

---

## Phase 4: UI/Integration Gate

> Primary: @Pixel

### 4.1 Screen Split and Stable Wiring

- [ ] (@Pixel) Split `WorkItemDetailsScreen` into:
  - `lib/features/work/view/widgets/work_item_overview_tab.dart`
  - `lib/features/work/view/widgets/work_item_requests_tab.dart`
  - `lib/features/work/view/widgets/work_item_contract_tab.dart`
  - `lib/features/work/view/widgets/work_item_action_bar.dart`
  - `lib/features/work/view/widgets/work_item_pending_payment_panel.dart`
- [ ] (@Pixel) Ensure the shell only wires controllers/viewmodels and renders tabs/sections. References: `lib/features/work/view/work_item_details_screen.dart:77-293`, `lib/features/work/view/work_item_details_screen.dart:489-690`.
- [ ] (@Sentinel) Review that no direct `TaskService`, `PaymentService`, `DashboardViewModel`, or `ChatViewModel` orchestration remains in `lib/features/work/view/`.
- **Verify (@Sentinel):** the widget tree is a pure consumer of work state and actions.

### 4.2 UI State Matrix Implementation

- [ ] (@Pixel) Bind action buttons and modal submits to explicit busy states so duplicate submits are blocked.
- [ ] (@Pixel) Implement explicit visible states from `.TODO/STATE_MATRIX_work_2026-03-04.md`, including partial failure, invalid extension input, review failure, and chat-open failure. References: `lib/features/work/view/widgets/request_extension_modal.dart:64-72`, `lib/features/work/view/widgets/review_delivery_modal.dart:36-56`.
- [ ] (@Pixel) Sort request history deterministically.
- [ ] (@Sentinel) Verify each visible state has a test target and user-visible expectation.
- **Verify (@Sentinel):** UI behavior is deterministic and matches the state matrix.

### 4.3 Stable Selectors and Testability Seams

- [ ] (@Pixel) Add only default-preserving keys/selectors needed by `.TODO/SELECTORS_work_2026-03-04.md`.
- [ ] (@Architect) Keep any testability seam default-preserving; no production-only branching for tests.
- [ ] (@Sentinel) Reject UI test work that depends on text/layout instead of the selector map.
- **Verify (@Sentinel):** work widget/integration tests can target stable elements without altering runtime behavior.

### GATE CHECK

- [ ] (@Sentinel) Gate 4 passes only when the split screen matches the state matrix, stable selectors exist, and the view layer is orchestration-free.

---

## Phase 5: QA + Release Gate

> Primary: @Sentinel

### 5.1 Automated Verification

- [ ] (@Sentinel) Run:
  - `flutter analyze`
  - targeted `flutter test` for new work unit/widget tests
  - `rg -n "context.read<(TaskService|PaymentService|DashboardViewModel|ChatViewModel)>" lib/features/work/view`
  - `rg -n "work_contracts|change_requests|extension_requests|rpc_request_revision|rpc_accept_change_request" supabase/migrations`
- [ ] (@Sentinel) Add and run at minimum:
  - `test/unit/work/unified_work_item_fallback_mapper_test.dart`
  - `test/unit/work/work_item_details_view_model_test.dart`
  - `test/unit/work/work_item_action_service_test.dart`
  - `test/unit/chat/message_service_work_routing_test.dart`
  - `test/widget/work/work_item_details_screen_test.dart`
  - `test/widget/work/request_extension_modal_test.dart`
  - `test/widget/work/review_delivery_modal_test.dart`
- [ ] (@Sentinel) Record failure artifacts and rerun outcomes per `.TODO/FAILURE_ARTIFACTS_work_2026-03-04.md`.
- **Verify (@Sentinel):** analyze/tests/grep checks all pass and failure artifacts are preserved for any flake.

### 5.2 Manual Scenarios

- [ ] (@Sentinel) Execute manual scenarios for:
  - task awarded pending payment -> pay -> refresh
  - task awarded pending payment -> cancel award
  - booking pending/request-pending -> provider accept/decline
  - booking pending/request-pending -> client cancel unpaid and held
  - active booking -> open message
  - active work -> submit delivery -> approve/revision
  - active work -> request extension -> history order and validation
- [ ] (@ThreatModeler) Run abuse scenarios:
  - repeated taps
  - stale item refresh
  - unauthorized work access
  - booking chat misuse
- [ ] (@Sentinel) Record expected vs actual outcomes in the release checklist.
- **Verify (@Sentinel):** manual behavior matches contracts and no orphan financial state is observed.

### 5.3 Live DB and Security Closeout

- [ ] (@Supabase_Ops) Execute the live RLS/RPC/index checks defined in `.TODO/RLS_MATRIX_work_2026-03-04.md` and `.TODO/LIVE_ACCESS_work_2026-03-04.md`.
- [ ] (@Observability) Validate privacy-safe logs and any required audit traces for sensitive actions.
- [ ] (@Sentinel) Block release if live verification remains unavailable or fails.
- **Verify (@Sentinel):** release evidence includes authenticated live DB confirmation, not docs-only assumptions.

### 5.4 Docs Sync and Release Decision

- [ ] (@SlineDocs) Update:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/STRUCTURE.md`
  only after code and live verification are final.
- [ ] (@SlineDocs) Ensure docs reflect the final work architecture, SQL provenance story, state matrix, and test coverage.
- [ ] (@Sentinel) Execute `.TODO/RELEASE_CHECKLIST_work_2026-03-04.md` and produce the final go/no-go outcome.
- **Verify (@Sentinel):** docs, code, live DB reality, and release evidence are consistent.

### GATE CHECK

- [ ] (@Sentinel) Gate 5 passes only when analyze/tests/manual scenarios/live DB checks/docs sync/release checklist all pass.

## 7) Acceptance Criteria (MANDATORY)

- Gate 0 through Gate 5 all pass with explicit evidence.
- Booking work never routes chat through `start_task_conversation_v1` using a booking id. References: `lib/features/work/view/work_item_details_screen.dart:658-673`, `lib/features/chat/services/message_service.dart:21-33`.
- No work widget directly orchestrates payment, dashboard mutation, or chat creation services. References: `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/view/work_item_details_screen.dart:665-679`.
- Booking cancel and accept are server-authoritative and retry-safe; no direct client `bookings.status` mutation remains for privileged transitions. References: `lib/features/work/services/work_management_service.dart:398-405`, `lib/features/booking/services/booking_service.dart:117-311`.
- Shared fallback mapping drives both dashboard and work detail semantics, including completed-vs-delivered behavior. References: `lib/features/work/viewmodels/work_item_details_view_model.dart:122-160`, `lib/features/dashboard/data/dashboard_repository.dart:232-290`.
- Work tests exist for mapper/service/viewmodel/screen/modals/chat routing and run on top of documented selectors, fixtures, and retry policy.
- Work SQL source-of-truth is either present in repo migrations or explicitly reconciled via approved forward migrations backed by live scan evidence.
- Docs match code and verified live DB reality in the same release slice.

## 8) Rollback Plan

- DB rollback / forward-fix:
  - Keep all schema work additive-first.
  - If a new work migration misbehaves, disable the new app path and forward-fix; do not fabricate or backdate historical migrations.
  - Preserve legacy-safe read behavior via unified-view + fallback mapper until new SQL/runtime contracts are proven. References: `lib/features/work/services/work_management_service.dart:31-128`, `lib/features/work/viewmodels/work_item_details_view_model.dart:81-84`.
- App rollback:
  - Keep the temporary `WorkManagementService` facade until all call sites migrate and verification passes.
  - Revert by PR slice:
    - PR3 docs/release evidence
    - PR2 runtime/UI/service split
    - PR1 gate artifacts only if necessary
- Emergency disable:
  - If live DB checks fail or server-authoritative booking/payment work regresses, disable pay/review/accept/cancel CTAs and keep work detail read-only until fixed.

## 9) References (From Scan)

- `.agents/workflows/planner.md`
- `.agents/workflows/plan_critic.md`
- `.TODO/work.TODO.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/STRUCTURE.md`
- `lib/core/services/deep_link_service.dart`
- `lib/core/services/payment_service.dart`
- `lib/features/work/view/work_item_details_screen.dart`
- `lib/features/work/view/widgets/submit_delivery_modal.dart`
- `lib/features/work/view/widgets/request_extension_modal.dart`
- `lib/features/work/view/widgets/review_delivery_modal.dart`
- `lib/features/work/viewmodels/work_item_details_view_model.dart`
- `lib/features/work/services/work_management_service.dart`
- `lib/features/work/models/unified_work_item_model.dart`
- `lib/features/dashboard/data/dashboard_repository.dart`
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
- `lib/features/dashboard/view/tabs/work_tab.dart`
- `lib/features/dashboard/view/tabs/bookings_tab.dart`
- `lib/features/dashboard/view/widgets/work_item_card.dart`
- `lib/features/booking/services/booking_service.dart`
- `lib/features/chat/services/message_service.dart`
- `lib/features/chat/viewmodels/chat_view_model.dart`
- `lib/features/profile/services/profile_summary_service.dart`
- `lib/features/tasks/services/task_service.dart`
- `lib/features/tasks/services/tender_payment_coordinator.dart`
- `supabase/functions/booking_decline_refund/index.ts`
- `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql`
- `supabase/migrations/20260224_fix_rpc_approve_delivery_digest_schema.sql`
- `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql`
- `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql`
- `test/test_support/pump_app.dart`
- `test/integration_test/support/helpers.dart`
- `test/integration_test/support/preflight.dart`
- `test/unit/models/unified_work_item_model_test.dart`
- `test/widget/dashboard/work_tab_test.dart`
- Live Supabase evidence:
  - `UNVERIFIED` in this session because `@mcp:supabase-mcp-server:` failed to initialize with `Auth required`; live DB verification remains a hard release blocker.
