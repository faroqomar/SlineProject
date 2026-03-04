## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The target remains the live `work` feature bounded to `lib/features/work/**` plus its direct dependencies in booking, dashboard, tasks, chat, and deep links. References: `lib/features/work/view/work_item_details_screen.dart:30-690`, `lib/features/work/viewmodels/work_item_details_view_model.dart:11-328`, `lib/features/work/services/work_management_service.dart:14-441`, `lib/features/dashboard/data/dashboard_repository.dart:72-290`, `lib/features/booking/services/booking_service.dart:117-311`, `lib/features/chat/services/message_service.dart:15-84`, `lib/features/tasks/services/task_service.dart:749-820`.
- Existing widget and integration harnesses under `test/test_support/` and `test/integration_test/support/` are the baseline to extend, not replace. References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`.
- Strict MVVM remains non-negotiable: widgets do not orchestrate Supabase/payment/chat/dashboard behavior directly. References: `Sline_everything/DEVELOPER_GUIDE.md:42-57`, `Sline_everything/STRUCTURE.md:183-188`, `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/view/work_item_details_screen.dart:665-679`.
- RLS remains the source of truth for work authorization, but live Supabase state is still `UNVERIFIED` in this session because MCP auth failed. References: `Sline_everything/SUPABASE_SETUP.md:1082-1101`, `functions.list_mcp_resources(server="supabase") -> Auth required`, `functions.list_mcp_resource_templates(server="supabase") -> Auth required`.

### Decision Needed (Blocking)

1. Missing decision: what is the canonical chat contract for booking work items.
- Options:
  - Route booking work chat through plain DM only.
  - Add a dedicated booking conversation server contract.
  - Keep using the task RPC with booking ids.
- Recommended: route booking work chat through plain DM until a dedicated booking server contract exists.
- Why: the current code passes `booking.id` into `start_task_conversation_v1`, which is a verified contract mismatch and should not survive the fix. References: `lib/features/work/view/work_item_details_screen.dart:658-673`, `lib/features/chat/services/message_service.dart:21-33`.
- What changes in the plan depending on the choice:
  - Plain DM: app-only fix is possible immediately.
  - Dedicated booking contract: requires new server API/RLS/retests before UI wiring.
  - Task RPC reuse: invalid; should be rejected.

2. Missing decision: what is the canonical cancel authority for client booking cancel.
- Options:
  - Client direct row update.
  - One server-authoritative cancel/refund path that branches on payment state.
  - Separate client-unpaid and held-refund app paths.
- Recommended: one server-authoritative cancel/refund path that branches on payment state.
- Why: direct client status update is already inconsistent with the existing refund flow and creates orphan-money risk. References: `lib/features/work/services/work_management_service.dart:398-405`, `lib/features/booking/services/booking_service.dart:215-245`, `supabase/functions/booking_decline_refund/index.ts:122-187`.
- What changes in the plan depending on the choice:
  - Server-authoritative: safest and consistent with RLS/server authority.
  - Separate app paths: still risky unless both paths terminate in server authority.
  - Direct row update: invalid for release.

3. Missing decision: what work proceeds while live Supabase auth is still blocked.
- Options:
  - Block all work until MCP auth is fixed.
  - Proceed with app-side/test-infra/test-contract work, but block DB reconcile and release.
  - Trust docs and continue fully.
- Recommended: proceed with app-side/test-infra/test-contract work, but block DB reconcile and release.
- Why: the repo has safe local work to do, but docs are not enough to ship DB/security changes. References: `Sline_everything/SUPABASE_SETUP.md:612-650`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`, MCP auth failure above.
- What changes in the plan depending on the choice:
  - Block all work: safest but slows low-risk app cleanup unnecessarily.
  - App-only proceed, DB/release blocked: safest practical path.
  - Trust docs: invalid and should be rejected.

4. Missing decision: what is the single owner of fallback mapping and CTA contract.
- Options:
  - Keep separate work and dashboard fallback mappers.
  - Make work own a shared mapper consumed by dashboard.
  - Move the mapper into dashboard and have work depend on it.
- Recommended: make `work` own a shared mapper consumed by dashboard.
- Why: the detail feature already owns the unified-work domain model and should remain the source of truth for fallback semantics. References: `lib/features/work/models/unified_work_item_model.dart:3-119`, `lib/features/work/viewmodels/work_item_details_view_model.dart:122-160`, `lib/features/dashboard/data/dashboard_repository.dart:191-290`.
- What changes in the plan depending on the choice:
  - Shared work-owned mapper: one contract.
  - Duplicated mappers: current drift persists.
  - Dashboard-owned mapper: inverts feature ownership and spreads detail-domain logic outward.

5. Missing decision: release slicing.
- Options:
  - One PR with backend, app, tests, docs.
  - Two PRs: backend/app and then tests/docs.
  - Three PRs: gates/contracts, app/runtime, release/docs/verification.
- Recommended: three PRs.
- Why: the fix spans missing DB provenance, security gates, runtime refactor, and test infra. References: `Sline_everything/CODE_REVIEW.md:16-23`, `Sline_everything/STRUCTURE.md:35-52`.
- What changes in the plan depending on the choice:
  - One PR: rollback and review risk are too high.
  - Two PRs: acceptable only if DB changes prove unnecessary.
  - Three PRs: cleanest gate and rollback control.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The current work plan added tests but did not create a test-infra phase before implementation.
  - The audited work screen and modals expose no documented stable selector map for widget/integration tests.
  - Existing harnesses exist, but the plan did not bind work tests to them or define failure artifacts / retry budgets.
- What to add/fix to pass:
  - Add a `Test Infrastructure Gate` before spec lock.
  - Create selector map, fixture manifest, timeout budgets, failure artifact path, and rerun policy. References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-239`, `test/integration_test/support/preflight.dart:5-56`, `lib/features/work/view/work_item_details_screen.dart:77-690`.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The prior plan did not explicitly lock the booking chat contract decision.
  - It did not define one idempotency matrix for booking accept/cancel, delivery/review, and tender pay-now flows.
  - It did not add a provenance artifact for missing work SQL source-of-truth.
- What to add/fix to pass:
  - Add contract artifacts for chat routing, action/idempotency matrix, and DB provenance before service refactors. References: `lib/features/work/services/work_management_service.dart:165-243`, `lib/features/work/services/work_management_service.dart:274-405`, `lib/features/chat/services/message_service.dart:15-33`, `lib/features/tasks/services/task_service.dart:764-799`.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - Live Supabase verification is still blocked, but the prior plan treated that as context instead of a hard release gate.
  - The plan did not define exact positive/negative RLS checks for work tables or the conversation boundary.
  - It did not explicitly forbid continuing with DB reconcile if live auth remains unavailable.
- What to add/fix to pass:
  - Add a `Live Access Gate`, exact RLS verification queries, and a release-blocking rule for missing live auth. References: `Sline_everything/SUPABASE_SETUP.md:1082-1101`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The prior plan did not choose the canonical app-side route for booking chat.
  - It did not force atomic booking accept/cancel authority before app refactors.
  - It did not separate safe app work from live-DB-dependent server work.
- What to add/fix to pass:
  - Add explicit backend/API sequencing: contracts -> security -> server authority -> app adapters -> UI. References: `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/services/work_management_service.dart:376-405`, `lib/features/booking/services/booking_service.dart:117-311`.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - The prior plan did not define a work UI state matrix covering loading, partial failure, unavailable history, pending action, duplicate taps, and message-open failures.
  - It did not force stable keys/selectors before widget/integration test authoring.
  - It did not bind the work screen split to one deterministic CTA/render contract.
- What to add/fix to pass:
  - Add `STATE_MATRIX_work`, `SELECTORS_work`, and explicit UI-state tests before UI wiring closes. References: `lib/features/work/view/work_item_details_screen.dart:497-690`, `lib/features/work/view/widgets/request_extension_modal.dart:64-72`, `lib/features/work/view/widgets/review_delivery_modal.dart:36-56`.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The prior plan had no explicit PR slicing artifact or go/no-go release checklist.
  - It did not define failure artifact capture or rerun policy for any new integration coverage.
  - It did not tie docs-sync and live DB verification into one release gate.
- What to add/fix to pass:
  - Add `PR_PLAN_work`, `RELEASE_CHECKLIST_work`, and explicit final gate checks for analyze/tests/manual scenarios/live DB verification.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No Test Infrastructure Gate.
- Why it will break: tests will be added against unstable selectors and ad hoc setup.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.0 Test Infrastructure Gate`.
  - Create `.TODO/TEST_INFRA_work_2026-03-04.md`, `.TODO/FIXTURES_work_2026-03-04.md`, `.TODO/SELECTORS_work_2026-03-04.md`, `.TODO/FAILURE_ARTIFACTS_work_2026-03-04.md`.
- Owner: Frontend
- Acceptance check: selectors, fixtures, timeout budgets, and failure-artifact policy exist before new work tests are authored.

### Gap 2
- Gap: Live Supabase auth blocker is not operationalized.
- Why it will break: the plan can slip into DB guesses or stall without a stop/go rule.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.1 Live Access Gate`.
  - Block DB reconcile and release until authenticated live scan evidence is recorded.
- Owner: Backend
- Acceptance check: the revised plan contains a hard gate and a fallback working mode.

### Gap 3
- Gap: No DB provenance strategy for missing work SQL source-of-truth.
- Why it will break: the team can invent fake historical migrations or silently ignore drift.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/DB_PROVENANCE_work_2026-03-04.md`.
  - Require forward reconcile only; no fabricated historical migration timestamps.
- Owner: Backend
- Acceptance check: provenance handling is documented and reviewable before any new migration is written.

### Gap 4
- Gap: Booking chat contract is not locked.
- Why it will break: the app can still ship with booking ids sent into task-only RPCs.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/DECISION_work_chat_contract_2026-03-04.md`.
  - Block chat refactor until the decision is written.
- Owner: Product
- Acceptance check: one chat contract is documented and every call site migrates to it.

### Gap 5
- Gap: No action/idempotency matrix.
- Why it will break: repeated taps and partial failures will still have ambiguous outcomes.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/CONTRACT_work_actions_2026-03-04.md` and `.TODO/IDEMPOTENCY_work_2026-03-04.md`.
- Owner: Backend
- Acceptance check: every money- or status-changing action has one owner, one retry rule, and one expected outcome table.

### Gap 6
- Gap: No UI state matrix.
- Why it will break: split widgets can still render inconsistent loading/error/pending states.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/STATE_MATRIX_work_2026-03-04.md`.
  - Bind widget and integration tests to that matrix.
- Owner: Frontend
- Acceptance check: each user-visible state has one expected render path and one test target.

### Gap 7
- Gap: No PR slicing or release checklist.
- Why it will break: DB, runtime, tests, and docs can still land in one unsafe batch.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/PR_PLAN_work_2026-03-04.md` and `.TODO/RELEASE_CHECKLIST_work_2026-03-04.md`.
- Owner: Product
- Acceptance check: each slice has definition of done, gate checks, and rollback point.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: one shared contract owns fallback mapping and CTA resolution for unified work items.
- How to enforce: shared mapper/service contract in `work`, not duplicated in dashboard.
- How to verify: unit tests assert identical output for dashboard and work detail fallback scenarios. References: `lib/features/work/viewmodels/work_item_details_view_model.dart:122-160`, `lib/features/dashboard/data/dashboard_repository.dart:232-290`.

2. Invariant: booking work never sends booking ids into task-only chat RPCs.
- How to enforce: plain DM or dedicated booking conversation server path only.
- How to verify: service test for booking chat route and grep check for `taskId: item.id` in booking work path. References: `lib/features/work/view/work_item_details_screen.dart:658-673`, `lib/features/chat/services/message_service.dart:21-33`.

3. Invariant: all money-sensitive transitions are server-authoritative and retry-safe.
- How to enforce: atomic RPC/edge-function contract for booking cancel/refund and booking accept authority; idempotency rules for pay-now path.
- How to verify: negative/positive server tests, manual retry scenarios, and live DB audit checks. References: `lib/features/booking/services/booking_service.dart:117-311`, `lib/features/tasks/services/task_service.dart:764-799`, `supabase/functions/booking_decline_refund/index.ts:122-187`.

4. Invariant: RLS prevents cross-user reads/writes on work tables.
- How to enforce: verified policies and no client-side privileged bypass.
- How to verify: authenticated live positive/negative SQL checks for participant vs non-participant access. References: `Sline_everything/SUPABASE_SETUP.md:1082-1101`.

5. Invariant: work UI does not orchestrate backend/payment/chat/dashboard actions directly.
- How to enforce: route-local ViewModel/controller composition only.
- How to verify: grep check for direct `context.read<TaskService|PaymentService|DashboardViewModel|ChatViewModel>` in `lib/features/work/view/`. References: `lib/features/work/view/work_item_details_screen.dart:208-249`, `lib/features/work/view/work_item_details_screen.dart:665-679`.

6. Invariant: docs match code and verified live DB reality in the same release slice.
- How to enforce: docs-sync is release-blocking.
- How to verify: final docs diff plus release checklist.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| MCP auth remains unavailable and DB verification stalls | Supabase live scan | High | High | Feature | repeated `Auth required` during MCP init | add live access gate and separate app-safe work from DB/release work | pause DB reconcile and release; continue only local app/test prep |
| Booking chat fix picks the wrong canonical route | work/chat boundary | Med | High | Feature | booking message action opens wrong thread or server error | lock chat decision doc before implementation | revert to plain DM path only |
| New booking cancel/accept authority still allows partial transitions | booking/work backend | Med | High | Data-loss | mismatched booking/payment statuses after retries | define atomic RPC/edge path plus idempotency contract | force read-only CTA fallback until server contract is corrected |
| Fallback mapper remains duplicated and drifts again | work/dashboard domain | High | Med | Feature | dashboard and detail show different statuses for same item | extract one shared mapper and test it directly | keep compatibility facade but route both consumers through shared mapper |
| Work tests remain brittle | widget/integration | High | Med | Delivery | tests depend on text/layout or time out late | add test infra gate, selectors, fixtures, timeout budgets | restrict release proof to unit/widget/manual until integration support is stable |
| PII logging survives refactor | observability | Med | Med | Security-breach | logs still contain raw user ids in info traces | explicit observability artifact and grep checks | remove info logs and keep error-only sanitized traces |

## F) Pre-Mortem (How this fails in real life)

- This fails when the team rewires chat first and only later decides whether bookings should use DM or a booking conversation contract.
- This fails when DB work starts before MCP auth is fixed, and the repo gets migrations based on docs rather than live reality.
- This fails when booking cancel is “fixed” in UI only and held funds still skip the server refund path.
- This fails when the screen is split into smaller widgets but the CTA state matrix is still implicit, so loading/error behavior changes silently.
- This fails when fallback mapping is moved but dashboard keeps its own stale copy.
- This fails when tests are written before selectors/fixtures exist and later get skipped or weakened.
- This fails when release proceeds without a provenance note for the missing work SQL objects.

## G) Plan Fixes (Concrete Additions / Expansions)

1. Goal: add a Test Infrastructure Gate.
- Why: planned tests are currently under-specified.
- How: create selector map, fixture manifest, timeout budgets, failure artifact policy, rerun policy.
- Output artifact: `.TODO/TEST_INFRA_work_2026-03-04.md`, `.TODO/FIXTURES_work_2026-03-04.md`, `.TODO/SELECTORS_work_2026-03-04.md`, `.TODO/FAILURE_ARTIFACTS_work_2026-03-04.md`
- Stop condition: every planned work test references stable selectors and documented setup.

2. Goal: operationalize the live DB blocker.
- Why: passive warnings are fake progress.
- How: add `Live Access Gate` that allows app-safe work but blocks DB reconcile and release.
- Output artifact: `.TODO/LIVE_ACCESS_work_2026-03-04.md`
- Stop condition: no DB/release task is executable without authenticated live scan evidence.

3. Goal: lock missing product/contract decisions.
- Why: chat routing and cancel authority are blocking decisions, not implementation details.
- How: create decision docs and one action/idempotency contract before app changes.
- Output artifact: `.TODO/DECISION_work_chat_contract_2026-03-04.md`, `.TODO/CONTRACT_work_actions_2026-03-04.md`, `.TODO/IDEMPOTENCY_work_2026-03-04.md`
- Stop condition: all runtime tasks can point to one written contract.

4. Goal: prevent fake migration-history repair.
- Why: repo/live drift already exists for work objects.
- How: create provenance doc and forward-reconcile rule before any migration changes.
- Output artifact: `.TODO/DB_PROVENANCE_work_2026-03-04.md`
- Stop condition: migration authors have a reviewable reconcile strategy.

5. Goal: add a UI state matrix.
- Why: split widgets and new tests need one visible-state contract.
- How: define states, triggers, expected UI, and test coverage target per state.
- Output artifact: `.TODO/STATE_MATRIX_work_2026-03-04.md`
- Stop condition: every user-visible state is covered by design and tests.

6. Goal: add PR slicing and release gates.
- Why: the fix is too broad for one unsafe batch.
- How: define three PR slices, reviewers, done conditions, and rollback points.
- Output artifact: `.TODO/PR_PLAN_work_2026-03-04.md`, `.TODO/RELEASE_CHECKLIST_work_2026-03-04.md`
- Stop condition: rollout/review order is explicit and enforceable.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Gates & Contracts
- Goal: remove ambiguity before implementation starts.
- Why: the original plan allowed foundational items to remain implicit.
- How:
  - add Test Infrastructure Gate
  - add Live Access Gate
  - lock chat/cancel/action contracts
  - add DB provenance, UI state matrix, PR plan
- Result: all downstream phases execute against explicit contracts and stop/go rules.
- GATE CHECK: test infra artifacts exist, live-access mode is documented, blocking decisions are written.

### Phase 1: Data/Contracts
- Goal: define the single source of truth for work item semantics and transitions.
- Why: current runtime duplicates fallback logic and leaves action semantics implicit.
- How:
  - extract one shared fallback mapper
  - define typed work action/idempotency matrix
  - define canonical booking chat route
- Result: dashboard/work/booking/chat all share one contract.
- GATE CHECK: no duplicated mapper/contract decisions remain.

### Phase 2: Security/RLS
- Goal: confirm live DB reality and secure touched work objects.
- Why: repo docs are not enough.
- How:
  - authenticate MCP
  - verify work policies/RPC signatures/indexes
  - document provenance and forward reconcile only
- Result: DB/security work becomes safe to execute.
- GATE CHECK: authenticated live scan evidence exists; otherwise phase blocks.

### Phase 3: Backend/API
- Goal: make money- and status-changing flows server-authoritative.
- Why: current booking cancel/accept and tender pay-now flows have partial-failure risk.
- How:
  - implement atomic booking authority
  - reconcile missing work SQL source-of-truth
  - split work services behind compatibility facade
- Result: server rules, app contracts, and service boundaries align.
- GATE CHECK: no client-owned privileged transition remains.

### Phase 4: UI/Integration
- Goal: wire the screen against the new contracts without regressions.
- Why: current widget owns orchestration and broad rebuild scope.
- How:
  - split screen widgets
  - add stable selectors/keys
  - bind pending/error/loading states to the UI state matrix
- Result: work detail becomes testable and deterministic.
- GATE CHECK: UI uses ViewModels/controllers only and selectors exist for planned tests.

### Phase 5: QA + Release
- Goal: prove the fix and ship safely.
- Why: docs, tests, and live DB verification all need to close together.
- How:
  - run analyze/tests/manual scenarios/live checks
  - validate observability/privacy
  - sync docs and execute PR/release checklist
- Result: ship/no-ship decision is evidence-based.
- GATE CHECK: release checklist passes with live DB evidence, tests, docs, and rollback readiness.

## I) Change Report (Diff-Style)

1. Original issues summary
- The original work plan had good coverage of findings but left critical execution gates implicit.
- It did not operationalize the live Supabase auth blocker.
- It did not add test-infrastructure, provenance, UI-state, or PR-slicing artifacts.

2. Added steps
- Test Infrastructure Gate
- Live Access Gate
- DB provenance artifact
- chat-contract decision artifact
- action/idempotency contract artifacts
- UI state matrix
- PR plan and release checklist

3. Removed steps
- None; the plan needed expansion, not reduction.

4. Reordered steps
- Contracts and gates move ahead of DB/app work.
- Security/RLS verification moves ahead of any DB reconcile or release activity.
- UI work moves after server/app contracts, not alongside them.

5. Expanded steps
- Test planning became infrastructure + fixtures + selectors + retry policy.
- DB work became provenance + live access + forward reconcile only.
- App work became explicit atomic transition and chat contract work.

6. Why
- The prior version could still produce fake progress or wrong ordering under missing live DB access and ambiguous contracts.

7. Residual risks
- Live Supabase auth can still block DB/release progress.
- If product rejects the recommended plain-DM booking chat path, backend scope grows materially.
