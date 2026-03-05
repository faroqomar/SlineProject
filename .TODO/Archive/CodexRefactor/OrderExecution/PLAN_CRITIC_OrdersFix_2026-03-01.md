> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The target feature is still intended to exist as a distinct user-facing `orders` flow because the repo still contains a dedicated module and docs still describe it as implemented (`/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`).
- The live Supabase project scanned is the same project contract the app currently targets.
- Existing test infrastructure is the baseline to extend, not replace: widget tests use `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5`, and integration tests use `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/t61_t70_env.dart:3` plus `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/preflight.dart:10`.
- Fixes must preserve MVVM boundaries and keep privileged authorization in RLS/server-side paths only.

### Decision Needed (Blocking)

1. Missing decision: what the `orders` nav item actually is.
- Options:
  - Restore standalone `OrdersDashboardScreen`.
  - Deprecate `orders` and formally replace it with `DashboardScreen`.
- Recommended: restore standalone `OrdersDashboardScreen`.
- Why: current code and docs are inconsistent, but the repo still has a dedicated feature module and the existing mismatch is a bug, not a clean deprecation (`/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart:10`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart:38`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/widgets/custom_bottom_nav_bar.dart:55`).
- Plan impact:
  - If restored: keep current feature scope and fix wiring.
  - If deprecated: this stops being a repair plan and becomes a retirement/migration plan across nav, docs, tests, and feature index.

2. Missing decision: canonical owner contract for reads and offer mutations.
- Options:
  - Standardize on `tasks.user_id`.
  - Standardize on `tasks.client_id`.
  - Standardize on `tasks.owner_id` as compatibility surface, with server-side mapping for legacy/newer rows.
- Recommended: `owner_id` as the canonical app/read contract, with server-side compatibility preserved for `user_id` and `client_id`.
- Why: live DB already carries mixed owner semantics; choosing either legacy field directly hardcodes drift back into the app.
- Plan impact:
  - If `user_id`: app changes are smaller, but you keep drifting from current `task_requests` owner-side RLS.
  - If `client_id`: offer auth aligns better, but legacy task reads and older rows may break.
  - If `owner_id`: requires clearer DB/API compatibility work, but it is the least fragile long-term path.

3. Missing decision: canonical RPC surface for offer decisions.
- Options:
  - Keep calling the current single-argument `accept_task_request` / `reject_task_request` variants.
  - Introduce explicit versioned, non-overloaded RPCs and keep old ones during compatibility window.
  - Keep overloads but document one canonical client signature.
- Recommended: introduce explicit versioned, non-overloaded RPCs and keep legacy ones during rollout.
- Why: overloaded auth-critical RPCs are already drifting on owner semantics; keeping overloads is how this broke.
- Plan impact:
  - If current single-arg RPCs remain canonical: DB risk stays higher and the plan needs tighter drift controls.
  - If versioned RPCs become canonical: migration scope grows, but the contract becomes testable and stable.

4. Missing decision: how release work is sliced.
- Options:
  - One PR for DB + app + UI + tests + docs.
  - Two PRs: DB/security first, app/UI/tests/docs second.
  - Three PRs: contract/test-infra, DB/security, app/UI/tests/docs.
- Recommended: three PRs.
- Why: current plan spans live DB contract, authz, app state, and navigation. One PR is review-hostile and rollback-hostile.
- Plan impact:
  - One PR: fastest on paper, worst for rollback and review.
  - Two PRs: acceptable, but still mixes planning baseline with risky DB changes.
  - Three PRs: slowest, but safest and easiest to gate.

5. Missing decision: how RLS/API verification is automated.
- Options:
  - Manual SQL verification only.
  - Staging-backed integration checks only.
  - Both SQL verification and staging-backed integration checks.
- Recommended: both.
- Why: SQL alone proves intent; staging-backed checks prove the actual PostgREST/RPC behavior the app consumes.
- Plan impact:
  - SQL only: release gate remains weak.
  - Integration only: you can miss policy drift details.
  - Both: stronger signal and better rollback safety.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The plan adds unit, widget, and functional coverage but does not define the shared harness work that must come first.
  - Existing harnesses exist, but the plan does not specify how orders tests will extend them (`/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/t61_t70_env.dart:3`).
  - The orders UI does not expose stable keys/selectors today, so widget/integration tests will be brittle (`/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/widgets/order_card.dart`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/widgets/offer_list_sheet.dart`).
- What to add/fix to pass:
  - Add a dedicated test-infra phase before any contract or feature work.
  - Define orders-specific selector/key map, fixture manifest, test commands, failure artifact path, and flake policy.
  - Define provider/bootstrap helpers for orders widget tests and staging env requirements for owner/freelancer test accounts.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The plan correctly names the owner/status drift, but it does not force a single canonical contract before downstream work.
  - It does not define a task status state machine or unsupported-status behavior, even though current parsing is unsafe (`/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart:142`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_request_model.dart:72`).
  - It does not define one canonical RPC return/error contract before app-layer rewrites.
- What to add/fix to pass:
  - Add a state-machine artifact for task and offer statuses.
  - Add a field-by-field contract matrix for `Task`, `TaskRequest`, and offer-decision RPCs.
  - Make contract lock a hard precondition, not just an early checklist item.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - The plan calls out RLS and notification risk, but it does not require a least-privilege decision for notifications before app changes.
  - Sensitive offer-decision actions still lack explicit audit-log requirements.
  - Owner auth drift across RLS and RPCs is treated as work to reconcile, but not as a release blocker with a kill switch.
- What to add/fix to pass:
  - Add explicit release-blocking invariant: cross-owner accept/reject/delete must fail under live auth contexts.
  - Add a decision on whether offer-decision notifications remain client-written.
  - Add audit-log/observability requirements for offer decisions and denial paths.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The plan does not pick a final RPC strategy for overloaded offer-decision functions.
  - It does not define exact error taxonomy and idempotency expectations for accept/reject/delete.
  - It does not specify compatibility handling when app code and live DB cannot switch atomically.
- What to add/fix to pass:
  - Add a canonical RPC naming/versioning decision.
  - Add error contract and idempotency matrix.
  - Add migration sequencing with live verify queries and rollback-by-phase.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - The plan tells UI to use viewmodels only, but does not define the missing test seams and selectors needed to validate that change.
  - It does not explicitly replace the current raw `.then(...)` async flow in offer actions and raw snackbar exception rendering with a state-driven UX contract (`/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/widgets/offer_list_sheet.dart:254`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:290`).
  - It does not define the user-visible behavior for unsupported statuses, stale offers, or partial notification failure.
- What to add/fix to pass:
  - Add a UI state matrix for dashboard and offer sheet.
  - Add stable keys for critical widgets and actions.
  - Add explicit acceptance criteria for stale/retry/error states.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The plan has no branch/PR slicing rule, review checklist, or definition of done per delivery slice.
  - It does not define flake thresholds, rerun policy, or failure artifact capture even though integration validation is required.
  - Docs sync exists, but there is no go/no-go release checklist tied to gates.
- What to add/fix to pass:
  - Add PR slicing, reviewer checklist, and release criteria.
  - Add run-command docs, artifact capture path, and rerun budget.
  - Add a final go/no-go gate after docs, DB verify, and staging checks.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No Test Infrastructure Gate.
- Why it will break: the plan schedules tests, but not the shared setup required to run them deterministically. Orders screens currently lack stable keys, and the harness does not yet describe orders-specific providers or fixtures.
- Fix (exact step(s) to add / reorder):
  - Add Phase 0: Test Infrastructure Gate before contract work.
  - Add tasks for `orders` selector/key map, widget bootstrap helper, integration fixture manifest, env contract, failure artifact convention, and rerun policy.
- Owner: Frontend
- Acceptance check: a dedicated test-infra artifact exists, orders widget tests have stable selectors, and staging integration prerequisites are documented before any feature test is written.

### Gap 2
- Gap: No explicit task/offer state machine artifact.
- Why it will break: the current bug is already a state-mapping failure. If you do not lock valid states and transitions first, service and UI work will diverge again.
- Fix (exact step(s) to add / reorder):
  - Add a `STATE_MACHINE` artifact under `.TODO/` before DB or app implementation.
  - Include allowed states, monotonic transitions, unsupported-state behavior, and UI affordance rules.
- Owner: Backend
- Acceptance check: every status value seen in live DB has one documented app behavior, and unsupported values are explicitly non-actionable.

### Gap 3
- Gap: Canonical owner contract is unresolved.
- Why it will break: reads, deletes, and offer decisions will keep using different owner identities, which reintroduces auth bugs after the first fix.
- Fix (exact step(s) to add / reorder):
  - Add an owner-contract decision artifact before Phase 1.
  - Add a compatibility matrix showing `user_id`, `client_id`, and `owner_id` across reads, writes, RLS, and RPCs.
- Owner: Backend
- Acceptance check: one owner field is canonical for app reads and one server-side compatibility strategy is documented for legacy/new rows.

### Gap 4
- Gap: No final RPC strategy for auth-critical offer decisions.
- Why it will break: overloaded RPCs with mixed auth semantics are a latent production bug. The plan cannot safely proceed without either deprecating or explicitly standardizing them.
- Fix (exact step(s) to add / reorder):
  - Add a blocking RPC decision step in Phase 1.
  - Add a migration/deprecation plan for old RPC signatures.
  - Add exact request/response/error contract artifact.
- Owner: Backend
- Acceptance check: the app points at one canonical offer-decision RPC contract, and legacy signatures are either compatibility-only or retired.

### Gap 5
- Gap: Notification security path is still ambiguous.
- Why it will break: if client-side notification writes remain broad under `notifications_insert_any`, a correctness fix can still ship with an abuse surface.
- Fix (exact step(s) to add / reorder):
  - Add a security decision step before UI work: keep client-side notification writes, narrow policy, or move offer-decision notifications server-side.
  - Add abuse tests and observability for notification writes.
- Owner: Backend
- Acceptance check: notification creation path for offer decisions is documented, least-privilege, and verified in live policy checks.

### Gap 6
- Gap: No UI state matrix for failure/retry/stale flows.
- Why it will break: current widgets already conflate loading with empty and leak raw errors. Without an explicit state matrix, the rewrite will be cosmetic and regressible.
- Fix (exact step(s) to add / reorder):
  - Add a dashboard/offer-sheet state matrix before UI implementation.
  - Include loading, empty, recoverable error, stale offer, retry, and partial-side-effect states.
- Owner: Frontend
- Acceptance check: each UI state has one expected render path and one test case.

### Gap 7
- Gap: No deterministic fixture manifest for auth/RLS validation.
- Why it will break: owner-vs-freelancer flows cannot be safely validated without seeded accounts, task IDs, and request IDs. Manual testing will miss cross-role regressions.
- Fix (exact step(s) to add / reorder):
  - Add a fixture manifest artifact listing required users, roles, sample tasks, sample requests, and reset expectations.
  - Add staging preflight checks patterned after the existing integration harness.
- Owner: Infra
- Acceptance check: staging-backed tests fail fast on missing accounts/IDs instead of timing out late.

### Gap 8
- Gap: No release slicing or review gates.
- Why it will break: DB, authz, UI, and test changes in one undifferentiated stream are hard to review and hard to roll back.
- Fix (exact step(s) to add / reorder):
  - Add PR slicing plan and per-slice done criteria.
  - Add final go/no-go release checklist tied to all gates.
- Owner: Product
- Acceptance check: work is split into reviewable slices with explicit rollback points.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: one canonical owner contract governs orders reads, deletes, and offer decisions.
- How to enforce: server-side contract artifact plus aligned RLS and RPC checks.
- How to verify: SQL policy/function checks and staging-backed owner-vs-non-owner tests.

2. Invariant: task and offer statuses are explicit, monotonic, and never inferred through permissive fallback.
- How to enforce: status codecs, state-machine doc, RPC/DB transition guards.
- How to verify: unit tests for mapping and negative tests for unsupported states.

3. Invariant: unsupported or unknown offer states are non-actionable in UI.
- How to enforce: parser returns non-actionable state, not `pending`.
- How to verify: widget test confirms no `Accept`/`Reject` buttons for unknown/stale statuses.

4. Invariant: orders load failure is distinguishable from empty data.
- How to enforce: explicit error state in viewmodel and UI state matrix.
- How to verify: widget and viewmodel tests for auth/network/RLS failure paths.

5. Invariant: cross-user reads and mutations are blocked by RLS or server-side guards.
- How to enforce: least-privilege policies and canonical RPC auth checks.
- How to verify: allowed and forbidden tests for list, delete, accept, and reject.

6. Invariant: sensitive action telemetry exists without leaking raw DB payloads or user-private data.
- How to enforce: service/viewmodel instrumentation with redaction rules.
- How to verify: log review and automated checks for raw exception interpolation.

7. Invariant: UI talks to viewmodels only; widgets do not own backend state machines.
- How to enforce: move async action orchestration and error mapping into viewmodels/services.
- How to verify: code review plus widget tests using stubbed viewmodels.

8. Invariant: test runs are deterministic and fail fast on missing prerequisites.
- How to enforce: test infrastructure gate, fixture manifest, env contract, bounded waits.
- How to verify: documented commands, preflight checks, and rerun policy.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Wrong nav target remains after “fix” | `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/app/main_navigation_screen.dart` | Med | High | Feature | Orders tab opens dashboard again | Lock entry decision first; add nav wiring test | Temporarily hide or relabel orders tab |
| Owner auth still split across fields | live `tasks` / `task_requests` / RPCs | High | High | Security-breach | Owner can read but cannot accept/reject, or vice versa | Canonical owner matrix and live verify checks | Disable offer decisions until auth is aligned |
| Single-arg RPCs keep legacy auth semantics | live `accept_task_request` / `reject_task_request` | High | High | Security-breach | Accept/reject works for wrong owner field only | Versioned non-overloaded RPCs and deprecation window | Force read-only offer sheet |
| Unknown status becomes actionable again | `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_request_model.dart:72` | Med | High | Feature | Accept/Reject shown for unsupported status | State-machine artifact and parser tests | Treat unknown as blocked state in UI |
| Task status drift breaks tab grouping | `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_model.dart:142` | High | Med | Feature | `in_progress` tasks appear under wrong tab | Canonical task status codec and tests | Add temporary server-side mapping layer |
| Client-side notification writes stay too broad | live `notifications_insert_any` | Med | High | Security-breach | Unexpected notifications from arbitrary users | Narrow policy or move decision notifications server-side | Disable notification side effects for offer decisions |
| Widget tests are flaky or impossible | orders UI + missing keys | High | Med | Delivery | Test failures depend on text/layout changes | Add stable keys/selectors and harness helpers | Limit release gate to unit + manual only until seams land |
| Staging validation is non-deterministic | integration env/accounts | Med | High | Delivery | Tests skip late or fail on missing seed data | Fixture manifest + preflight + fail-fast env checks | Manual SQL + scripted smoke on staging |
| Raw exception text still leaks | `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/orders/view/orders_dashboard_screen.dart:290` | Med | Med | Feature | Snackbar shows DB or Postgrest error text | Error taxonomy and grep checks | Replace UI errors with generic mapped fallback |
| One large change set becomes unreleasable | DB + app + UI + tests | High | High | App-wide | Review stalls, rollback unclear | Three-PR slicing with per-slice gates | Freeze risky scope and ship read-only fix first |

## F) Pre-Mortem (How this fails in real life)

- This fails when the tab still routes to `DashboardScreen`, and everyone assumes the feature is fixed because the underlying orders code compiled.
- This fails when `getTasksByUser(...)` still uses `user_id`, but live owner-side offer auth uses `client_id`, so the same user can view orders but cannot act on them.
- This fails when a new or stale offer status comes back from the backend and the parser silently maps it to `pending`, exposing `Accept` and `Reject` to the wrong state.
- This fails when a DB/RPC denial is rendered as an empty dashboard, and the team misdiagnoses a security regression as “no data”.
- This fails when notification writes remain client-driven and a malicious user can create misleading offer decision notifications.
- This fails when the team rewrites UI callbacks but does not add stable keys, so widget tests become brittle and get skipped before release.
- This fails when staging validation depends on ad hoc accounts and IDs, and the release gate passes only because the high-risk tests were skipped.
- This fails when overloaded RPCs remain in place, and a future maintainer updates one owner check but not the other.

## G) Plan Fixes (Concrete Additions / Expansions)

1. Goal: establish testability before implementation.
- Why: current plan adds tests without defining deterministic setup.
- How: add `.TODO/TEST_INFRA_Orders_2026-03-01.md` covering harness reuse, provider bootstrap, stable keys, fixture manifest, env contract, run commands, failure artifacts, and rerun policy.
- Output artifact: test harness/helper plan.
- Stop condition: orders test infra is documented and reusable before any new test file is created.

2. Goal: lock task and offer state machines.
- Why: current production bug is already a status-contract bug.
- How: add `.TODO/STATE_MACHINE_Orders_2026-03-01.md` with allowed states, transitions, UI affordances, and unsupported-state behavior.
- Output artifact: state-machine contract.
- Stop condition: every live status value has exactly one documented app behavior.

3. Goal: lock owner semantics.
- Why: mixed `user_id` / `client_id` / `owner_id` semantics are the highest structural risk.
- How: add `.TODO/OWNER_CONTRACT_Orders_2026-03-01.md` with read/write/RLS/RPC mapping and chosen canonical field.
- Output artifact: owner contract matrix.
- Stop condition: all app reads and privileged writes map to one approved owner rule.

4. Goal: remove RPC ambiguity.
- Why: overloaded auth-critical RPCs are fragile.
- How: add a versioning/deprecation task that either introduces canonical non-overloaded RPCs or explicitly freezes one supported signature and retires the other.
- Output artifact: RPC contract doc + migration notes.
- Stop condition: one client-facing offer-decision RPC contract exists.

5. Goal: define notification security path.
- Why: offer-decision side effects are currently over-trusted.
- How: add a security decision and policy verification task for notification creation.
- Output artifact: RLS/policy decision note and verify queries.
- Stop condition: notification path for offer decisions is least-privilege and documented.

6. Goal: define user-visible state behavior.
- Why: raw errors, empty-vs-error confusion, and stale-offer actions are already present.
- How: add `.TODO/UI_STATE_MATRIX_Orders_2026-03-01.md` for dashboard and offer sheet.
- Output artifact: UI state matrix.
- Stop condition: every error/loading/stale path has one expected render and one test case.

7. Goal: make tests deterministic on staging.
- Why: owner/RLS checks need real backend behavior.
- How: add `.TODO/FIXTURES_Orders_2026-03-01.md` listing required accounts, roles, tasks, requests, reset rules, and preflight checks.
- Output artifact: fixture manifest / seed contract.
- Stop condition: staging-backed verification fails fast on missing preconditions.

8. Goal: bound failure triage.
- Why: current plan lacks artifact capture and flake policy.
- How: add run-command docs, failure artifact path/tagging, timeout budgets, and rerun thresholds to the test infra artifact.
- Output artifact: QA runbook.
- Stop condition: failed runs produce actionable artifacts and bounded retries.

9. Goal: make release reviewable and rollback-safe.
- Why: the change spans DB, authz, app state, UI, tests, and docs.
- How: add a three-PR delivery plan with per-PR gate criteria and rollback notes.
- Output artifact: release checklist / PR plan.
- Stop condition: each slice can be reviewed and rolled back independently.

10. Goal: make live verification non-optional.
- Why: docs and code are already behind live DB reality.
- How: add explicit SQL verify tasks plus staging-backed integration checks to the release gate.
- Output artifact: live verify checklist.
- Stop condition: release cannot pass without both SQL and staging evidence.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure Gate
- Goal: make the planned unit/widget/integration work executable and deterministic.
- Why: without stable selectors, fixture manifests, and runbook rules, the later QA phase will either be skipped or produce false confidence.
- How:
  - Inventory and extend existing harnesses in `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart` and `/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/`.
  - Add orders-specific selector/key map for dashboard tabs, refresh action, order card actions, offer item actions, and error states.
  - Add provider/bootstrap requirements for widget tests.
  - Add fixture manifest, env injection method, timeout budgets, rerun policy, and failure artifact tagging.
- Result: test work is deterministic, reviewable, and blocked early on missing prerequisites.
- GATE CHECK:
  - Orders selectors/keys are defined.
  - Test bootstrap helper requirements are documented.
  - Fixture/env contract exists and fails fast.
  - Run commands and retry policy are written.

### Phase 1: Data/Contracts
- Goal: lock the feature contract before changing DB or app code.
- Why: current failures are contract drift failures, not implementation details.
- How:
  - Decide the `orders` entry contract.
  - Decide canonical owner field.
  - Create task/offer state-machine artifact.
  - Create field-level contract for `Task`, `TaskRequest`, and offer-decision RPCs.
  - Define unsupported-state behavior as non-actionable.
- Result: one source of truth exists for navigation, ownership, payload shape, and status transitions.
- GATE CHECK:
  - Entry-point decision is written and approved.
  - Owner contract is chosen.
  - State machine covers all live statuses.
  - RPC request/response/error contract exists.

### Phase 2: Security/RLS
- Goal: reconcile live authorization behavior with the locked contract.
- Why: fixing UI or models first is wasted work if RLS and RPC auth remain split.
- How:
  - Export live SQL for touched policies and RPCs.
  - Reconcile owner-side RLS across `tasks` and `task_requests`.
  - Decide canonical offer-decision RPC path and deprecate or quarantine ambiguous signatures.
  - Decide notification security path.
  - Add audit-log and denial observability requirements.
  - Create RLS matrix with allowed and forbidden cases.
- Result: live DB authorization becomes explicit, least-privilege, and testable.
- GATE CHECK:
  - One owner auth rule is enforced across reads and mutations.
  - RLS matrix exists with positive and negative cases.
  - Offer-decision notification path is least-privilege.
  - Kill switch for unsafe offer actions is defined.

### Phase 3: Backend APIs and App Data Layer
- Goal: align models, services, and viewmodels to the locked contract.
- Why: app-layer fixes must consume the final contract, not re-interpret it.
- How:
  - Implement task and offer status codecs.
  - Remove permissive fallback parsing.
  - Align task queries to canonical owner contract.
  - Implement one canonical RPC parser and error taxonomy for offer decisions.
  - Make accept/reject/delete idempotent and in-flight safe.
  - Move async orchestration and error mapping into services/viewmodels.
  - Keep compatibility shims thin and temporary.
- Result: the app layer becomes deterministic, contract-safe, and MVVM-compliant.
- GATE CHECK:
  - Unknown states are non-actionable.
  - One service path exists per privileged action.
  - Viewmodels expose explicit loading/error/data states.
  - Compatibility shims are documented and bounded.

### Phase 4: UI Wiring and Integration
- Goal: wire the feature to the correct entry point and render all states safely.
- Why: current UI hides failures, leaks raw errors, and owns too much async behavior.
- How:
  - Align nav label and target screen.
  - Replace raw callback chains with state-driven viewmodel actions.
  - Render explicit loading, empty, recoverable error, stale, and success states.
  - Add stable keys and deterministic post-action behavior in offer sheet.
  - Keep all strings English-only.
- Result: the orders UX becomes reachable, testable, and resilient to backend failure modes.
- GATE CHECK:
  - Orders tab opens the intended screen.
  - Empty vs error is visibly distinct.
  - Raw exception strings are gone.
  - Critical widgets/actions expose stable selectors.

### Phase 5: Polish, QA, and Release
- Goal: prove the fix is safe to ship and leave a rollback-ready paper trail.
- Why: this feature crosses DB auth, RPCs, app state, navigation, and docs.
- How:
  - Run unit tests for codecs and viewmodels.
  - Run widget tests for navigation, dashboard states, and offer sheet behavior.
  - Run staging-backed contract/RLS/integration checks using fixture manifest and preflight.
  - Execute manual E2E for owner and non-owner paths.
  - Sync docs to final code and live DB.
  - Ship via three PR slices with review checklist and go/no-go gate.
- Result: release decision is evidence-based, reviewable, and rollback-safe.
- GATE CHECK:
  - Unit/widget/staging checks pass.
  - Allowed and forbidden auth cases are proven.
  - Docs match final code and live DB.
  - PR slices meet done criteria and rollback notes exist.

## I) Change Report (Diff-Style)

1. Original issues summary
- The original plan identified the right drift areas, but it left the highest-risk decisions unresolved.
- It lacked a Test Infrastructure Gate even though it added significant new tests.
- It did not force a canonical owner/state/RPC contract before downstream implementation.
- It had no delivery slicing, artifact capture, or release checklist.

2. Added steps
- Test Infrastructure Gate
- selector/key map
- fixture manifest / preflight contract
- state-machine artifact
- owner contract matrix
- explicit RPC strategy/deprecation step
- notification security decision
- UI state matrix
- audit-log / observability requirement
- PR slicing and go/no-go release checklist

3. Removed steps (if any)
- Removed implicit assumption that QA can be safely deferred to the end without harness work.
- Removed implicit assumption that “reconcile overloaded RPCs” is sufficient without choosing a canonical client contract.

4. Reordered steps (from → to)
- Tests from late-phase implementation → upfront Test Infrastructure Gate.
- Mixed contract/security decisions inside Phase 0/1 → explicit Data/Contracts phase before Security/RLS.
- Docs-only finalization → release gate after SQL + staging verification.

5. Expanded steps (what became more detailed)
- Contract work expanded into owner matrix, state machine, and RPC request/response/error contract.
- Security work expanded into notification path decision, RLS matrix, audit logging, and kill switch.
- QA work expanded into harness, fixtures, selectors, retries, and failure artifacts.
- Release work expanded into PR slicing and go/no-go criteria.

6. Why (short, practical)
- The original plan would likely produce motion, not safety. These additions turn it into a sequence that can actually survive live DB drift, authz mistakes, and flaky verification.

7. Residual risks (what still remains risky even after fixes)
- Live DB history may contain mixed legacy rows that behave differently under the chosen owner contract.
- Existing consumers outside `orders` may depend on current `Task` parsing behavior and regress once codecs tighten.
- If notification writes cannot be moved or narrowed, some residual abuse risk may remain and will need explicit acceptance.
- If product chooses to deprecate orders instead of restoring it, much of the current repair scope becomes invalid and must be rewritten.
