# PlanCritic Report: Notifications Server-Authority Alignment

## A) Assumptions + Decision Needed (Blocking)

- Assumptions:
  - The live Supabase project is the source of truth for the notifications contract because it already has `reconcile_orders_owner_contract` and `harden_notification_writes` applied.
  - Widget/unit test harnesses already exist and are reusable via `test/test_support/pump_app.dart`.
  - Integration test harness and env injection already exist via `integration_test/support/helpers.dart`, `integration_test/support/preflight.dart`, and `integration_test/support/t61_t70_env.dart`.
  - The notifications badge must remain available without requiring the user to open the modal first.
  - The team wants fresh-environment bootstrap from repo migrations to remain valid.

- Decision Needed (Blocking): Subscription ownership and lifecycle are not locked.
  - Missing decision: should notifications stay globally subscribed, be auth-gated globally, or be lazily subscribed only on a screen/modal?
  - Options:
    - Keep one provider instance and connect/disconnect on auth state only.
    - Lazy subscribe from the home screen/modal only.
  - Recommended: keep one provider instance but make the stream connection auth-aware and teardown on logout.
  - Why: preserves unread badge behavior with the smallest refactor and removes pre-auth listener noise.
  - Plan impact: if auth-aware global is chosen, Phase 2 must add explicit `connect()/disconnect()/clearState()` behavior. If lazy is chosen, Phase 2 and Phase 3 both need new shell-to-screen state handoff work.

- Decision Needed (Blocking): Fresh-bootstrap migration repair strategy is ambiguous.
  - Missing decision: how to fix the stale notification SQL in `20260226_tender_award_payment_flow.sql` without leaving fresh DB bootstrap broken.
  - Options:
    - Patch the historical repo migration for fresh bootstrap and add a forward verification/reconcile step for shared environments.
    - Leave history untouched and add only a new forward-fix migration.
  - Recommended: patch the stale historical repo migration for fresh bootstrap and add an explicit verification/reconcile step for deployed/shared environments.
  - Why: a fresh environment applying the old SQL will fail before later March migrations can correct behavior.
  - Plan impact: Phase 1 must explicitly split fresh-bootstrap repair from deployed-environment safety checks.

- Decision Needed (Blocking): Notification deep-link contract for `task_request` is unresolved.
  - Missing decision: how the app should open server-generated `task_request` notifications used by accept/reject/award/payment flows.
  - Options:
    - Normalize server rows to `task` / `conversation` only.
    - Keep `task_request` and resolve via metadata in the app.
  - Recommended: keep `task_request` in the DB contract and resolve in the app using metadata priority: `conversation_id` first, else `task_id`.
  - Why: live DB already emits `task_request`, and the metadata needed for deterministic routing is already present.
  - Plan impact: Phase 2 must add a notification-routing adapter and contract tests for `task_request` metadata resolution.

- Decision Needed (Blocking): Notification integration determinism is unresolved.
  - Missing decision: how integration tests will get a deterministic notification row.
  - Options:
    - Seed a deterministic notification fixture contract in staging/branch DB and pass identifiers via `--dart-define`.
    - Keep using opportunistic live data.
    - Replace with a mocked non-staging integration path.
  - Recommended: use a deterministic seeded fixture contract with `--dart-define` identifiers.
  - Why: current `notification_deeplink_flow_test.dart` fails when no notifications exist and selects by visible title, which is not execution-safe.
  - Plan impact: add Gate 0 test fixture manifest, selector work, and a preflight contract before any test implementation.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate

- Status: ❌ FAIL
- Reason:
  - The repo has reusable widget and integration harnesses, but there is no notification-specific fixture manifest or seed/reset contract.
  - `integration_test/notification_deeplink_flow_test.dart` depends on existing staging data and selects a row by title instead of a stable key.
  - The current plan does not define failure artifact capture, flake threshold, or rerun policy.
- What to add/fix to pass:
  - Add a notification fixture manifest and preflight contract.
  - Add stable selectors/keys for notification rows and modal states.
  - Add timeout budgets, rerun policy, and failure artifact/log-tagging rules.

### Gate 1: Data/Contracts Gate

- Status: ❌ FAIL
- Reason:
  - The plan does not lock the live `type` and `related_entity_type` contract tightly enough, especially `task_request`.
  - Fresh-bootstrap handling for the stale February 26 migration is ambiguous.
  - The plan leaves unsupported-type handling as an implementation detail instead of an explicit contract decision.
- What to add/fix to pass:
  - Enumerate live server-emitted notification types and route expectations.
  - Make the historical-migration repair strategy explicit.
  - Add parser/routing acceptance checks for `task_request`, `offer_awarded`, `payment_required`, `work_active`, and `award_expired`.

### Gate 2: Security Gate

- Status: ❌ FAIL
- Reason:
  - The plan does not make removal of all direct client notification writes a hard pre-release grep gate.
  - The negative RLS checks are described, but not bound to specific verify commands and two-user scenarios per operation.
  - Privacy logging rules are present but not connected to exact code removal/replacement steps.
- What to add/fix to pass:
  - Add a codebase grep gate proving no direct client write path remains.
  - Add explicit two-user RLS checks for select, update, and insert-denied.
  - Add a concrete logging cleanup step with stop conditions.

### Gate 3: Backend/API Gate

- Status: ❌ FAIL
- Reason:
  - The plan does not include a producer-by-producer decommission matrix tying each client write callsite to its live server-side replacement.
  - The plan assumes all event families are fully covered server-side without a one-by-one verification table.
  - The plan does not separate “DB already supports this” from “app still duplicates this.”
- What to add/fix to pass:
  - Add a business-event matrix mapping each app producer callsite to the specific trigger/RPC/function that replaces it.
  - Add stop conditions per event family.
  - Block app cleanup until each event family is verified in live DB and test scenarios.

### Gate 4: UI/Integration Gate

- Status: ❌ FAIL
- Reason:
  - The plan does not explicitly isolate the modal tap-flow fix before broader UI polish.
  - Stable notification selectors are missing, which blocks deterministic widget/integration coverage.
  - The unresolved subscription-scope decision affects provider placement and loading/error behavior.
- What to add/fix to pass:
  - Move modal selection/routing refactor to the first UI subphase.
  - Add stable keys for bell, modal states, and notification rows.
  - Lock subscription lifecycle before UI wiring starts.

### Gate 5: Release/QA Gate

- Status: ❌ FAIL
- Reason:
  - The plan does not define PR slicing, review checkpoints, or definition-of-done per delivery slice.
  - The plan does not lock the automated device matrix or manual platform sanity requirements.
  - The plan does not define flake thresholds or rerun limits for the staging-backed integration path.
- What to add/fix to pass:
  - Add delivery slices/PR order.
  - Add Android automation + manual iOS sanity gate (or another explicit matrix).
  - Add rerun budget and failure-artifact expectations.

## C) Critical Gaps (Must-Fix)

- Gap: No Test Infrastructure Gate.
  - Why it will break: notification integration work will start before deterministic data, stable selectors, and harness rules exist, causing false failures and late blockers.
  - Fix (exact step(s) to add / reorder): add a new Phase 0 "Test Infrastructure Gate" before any contract or DB changes; create `.TODO/TEST_notifications_2026-03-01.md` with fixture manifest, env contract, timeout budget, and failure artifact rules.
  - Owner: QA
  - Acceptance check: one document exists with fixture IDs, env vars, timeout/retry limits, and artifact paths; notification tests reference it.

- Gap: The live `task_request` deep-link contract is not planned.
  - Why it will break: server-generated notifications for accept/reject/award/payment flows will hit the app with an unsupported `related_entity_type` and produce unknown-route behavior.
  - Fix (exact step(s) to add / reorder): add a contract subphase before app refactor that locks `task_request` routing via metadata (`conversation_id` first, else `task_id`), then implement adapter + tests before UI release.
  - Owner: Backend / Frontend
  - Acceptance check: `task_request` notifications open the correct destination in widget/integration tests and manual QA.

- Gap: Producer-by-producer client-write removal is not explicit.
  - Why it will break: some duplicated client writes will remain and silently fail under live RLS, leading to partial cleanup and inconsistent behavior.
  - Fix (exact step(s) to add / reorder): add a decommission matrix covering chat, task status, task request submit, task accept/reject, booking create/update, offer award/payment.
  - Owner: Frontend
  - Acceptance check: grep for `createNotification(` / `createOrUpdateNotification(` returns only notification read/update service compatibility stubs or zero business callsites.

- Gap: Fresh-bootstrap migration repair strategy is not explicit.
  - Why it will break: a new environment can fail on the stale February 26 migration even if live DB is already correct.
  - Fix (exact step(s) to add / reorder): split migration work into "historical bootstrap repair" and "deployed-environment verify/reconcile" tasks, in that order.
  - Owner: Backend
  - Acceptance check: a fresh branch DB can apply repo migrations through March 1 without notification-contract failure.

- Gap: Subscription lifecycle is still a decision placeholder.
  - Why it will break: the implementation may change provider scope midstream and destabilize badge behavior or auth transitions.
  - Fix (exact step(s) to add / reorder): lock auth-aware global subscription as a design decision in Phase 0 and implement connect/disconnect semantics before UI tests.
  - Owner: Frontend
  - Acceptance check: signed-out state has no active notification stream, sign-in starts one stream, logout clears notifications and unsubscribes.

- Gap: Notification selectors are not planned.
  - Why it will break: widget/integration tests will continue to select rows by visible title, which is unstable and can false-pass on duplicates.
  - Fix (exact step(s) to add / reorder): add row keys and modal-state keys in the first UI wiring subphase.
  - Owner: Frontend
  - Acceptance check: integration tests can target the seeded notification by stable key or ID-derived marker.

- Gap: Release workflow is underspecified.
  - Why it will break: work may ship without a clear merge order, definition of done, or flake handling policy.
  - Fix (exact step(s) to add / reorder): add PR slices, review checklist, per-slice done criteria, Android automation target, manual iOS sanity, and flake budget before Phase 4.
  - Owner: Delivery
  - Acceptance check: the plan names PR1/PR2/PR3, each with merge gate and validation checklist.

## D) Invariants & Success Criteria (Non-Negotiable)

- Invariant: Flutter client never inserts or upserts `public.notifications` directly.
  - How to enforce: remove business callsites and keep direct insert denied by RLS.
  - How to verify: grep codebase + two-user insert-denied SQL check.

- Invariant: users can only read and update their own notifications.
  - How to enforce: `notifications_select_own` and `notifications_update_own` policies plus client-side current-user filters.
  - How to verify: two-user select/update forbidden checks.

- Invariant: each notification-producing business event has one server-side source of truth.
  - How to enforce: trigger/RPC matrix and client-write removal.
  - How to verify: event-family checklist and smoke tests for each source.

- Invariant: every notification row consumed by Flutter matches the live contract.
  - How to enforce: repaired migration chain, contract doc, parser tests.
  - How to verify: fresh DB apply + model tests + live sample row checks.

- Invariant: notification taps never navigate from a disposed modal context.
  - How to enforce: modal returns selection or uses stable parent context only.
  - How to verify: widget tests for tap flow and no runtime exception in manual QA.

- Invariant: supported live notification types never degrade to an unknown silent fallback.
  - How to enforce: explicit type mapping contract and telemetry.
  - How to verify: unit tests and log assertions for unknown types.

- Invariant: there is at most one active notification stream per authenticated app session.
  - How to enforce: auth-aware connect/disconnect lifecycle in ViewModel/service.
  - How to verify: lifecycle tests and debug instrumentation.

- Invariant: integration tests fail fast on missing prerequisites.
  - How to enforce: preflight + fixture manifest + bounded waits.
  - How to verify: missing env/fixture causes immediate skip/fail with actionable message.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| Some client write callsites remain after cleanup | Flutter services | High | High | Feature | `rg` still finds `createNotification(` in producer features | Add decommission matrix + grep release gate | Revert app cleanup slice and keep read/update only changes |
| Fresh DB bootstrap still fails on stale Feb migration | Repo migrations | Med | High | App-wide | Branch DB migrate fails before March migrations | Patch historical file + run branch DB verification | Ship temporary branch-only bootstrap patch while corrective migration is finalized |
| `task_request` notifications open wrong destination or no destination | App deep-link layer | High | Med | Feature | SnackBar for unknown type or wrong screen after offer events | Lock metadata-based routing contract and test it | Fallback to task details with visible message |
| Global notification stream leaks or duplicates across auth transitions | ViewModel/provider lifecycle | Med | High | Feature | Stale notifications after logout or repeated listener logs | Auth-aware connect/disconnect and clear-state tests | Disable stream connect on startup and reconnect only on home shell temporarily |
| Unsupported live `type` values silently degrade UX | Model/parser | Med | Med | Feature | Generic icon/category for payment/award notifications | Explicit type map + telemetry | Temporary fallback with warning banner/log while contract patch ships |
| Notification integration test remains flaky in staging | Integration harness | High | Med | Delivery | Intermittent T69 failures / missing row | Seed fixture contract + stable keys + flake budget | Mark integration as non-blocking until deterministic seed path is ready |
| Logging still leaks IDs or message content | Deep link / services | Med | Med | Security-breach | QA logs include raw IDs/content | Add log-redaction checklist and review gate | Disable noisy logs before release |
| Docs drift returns after fixes | Docs / DB / app | Med | Med | Team workflow | Setup guide disagrees with live scan again | Make doc sync a release gate with live evidence | Follow-up docs-only PR before release cut |

## F) Pre-Mortem (How this fails in real life)

- This fails when the app cleanup removes chat-side notification writes, but one booking callsite still inserts directly and silently fails under RLS.
- This fails when a newly provisioned environment hits the stale February 26 migration and cannot build the schema chain.
- This fails when an accepted or rejected offer creates a `task_request` notification and the app shows “Cannot open this item type”.
- This fails when logout/login leaves the old notification list in memory because the global stream never disconnected.
- This fails when the notification deep-link test passes locally on a reused staging account but fails in CI because no seeded notification exists.
- This fails when multiple notifications share the same title and the integration test taps the wrong row because no stable selector exists.
- This fails when a later backend change emits a new notification `type` and the Flutter app silently categorizes it as generic without any alert.
- This fails when the team updates code but forgets to sync `SUPABASE_SETUP.md`, and the next planner run makes the wrong assumptions again.

## G) Plan Fixes (Concrete Additions / Expansions)

- Goal: establish a test infrastructure gate before feature changes.
  - Why: current plan is test-heavy but lacks deterministic notification fixtures and selector rules.
  - How: add `.TODO/TEST_notifications_2026-03-01.md` with fixture manifest, env vars, timeout budget, retry/flake policy, artifact naming, and stable selector requirements.
  - Output artifact: test infrastructure doc.
  - Stop condition: all notification tests reference the doc and fail fast on missing prerequisites.

- Goal: lock the live notification contract, including `task_request` routing.
  - Why: live DB emits types and entity kinds the current app does not fully support.
  - How: add `.TODO/CONTRACT_notifications_2026-03-01.md` enumerating all live `type` values and route resolution rules.
  - Output artifact: contract doc.
  - Stop condition: parser/routing tests cover every listed server-emitted type and entity kind.

- Goal: remove every stale client-side notification write path with proof.
  - Why: silent RLS-denied writes are the highest-risk drift still in the app.
  - How: build a producer decommission matrix and bind each callsite to a server-side trigger/RPC equivalent before deletion.
  - Output artifact: decommission checklist in the revised plan + grep gate.
  - Stop condition: release gate grep finds no producer callsites writing notifications directly.

- Goal: make fresh bootstrap safe.
  - Why: stale migration history can break new environments even if live DB is already correct.
  - How: patch the stale historical SQL in repo and add deployed-environment verification steps.
  - Output artifact: repaired migration file + migrate verification notes.
  - Stop condition: a branch DB applies repo migrations cleanly through March 1.

- Goal: isolate the modal tap-flow bug before broader UI changes.
  - Why: the current flow uses a disposed context and can fail unpredictably.
  - How: change the modal to return a selection or route using a stable parent context; add row keys at the same time.
  - Output artifact: updated modal/badge wiring + widget tests.
  - Stop condition: widget tests prove no disposed-context navigation path remains.

- Goal: lock delivery workflow and release gates.
  - Why: the plan currently lacks PR slicing, done criteria, and flake handling.
  - How: add PR1/PR2/PR3 sequencing, reviewer gates, Android automation target, manual iOS sanity, and flake budget.
  - Output artifact: revised plan sections for delivery/release.
  - Stop condition: every delivery slice has a done checklist and release gate.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure + Decision Lock
- Goal: eliminate planning ambiguity before implementation starts.
- Why: the current plan will fail if subscription scope, migration strategy, test fixtures, and `task_request` routing remain open questions.
- How:
  - Create acceptance, threat, contract, migration, and test-infrastructure docs in `.TODO/`.
  - Lock four decisions: auth-aware global subscription, historical migration repair, metadata-based `task_request` routing, deterministic seeded integration fixture strategy.
  - Add PR slicing and release matrix.
- Result: implementation starts with fixed decisions, deterministic test prerequisites, and delivery gates.
- GATE CHECK: decisions are explicit, test infra doc exists, and PR slicing is defined.

### Phase 1: Data/Contracts + Security Baseline
- Goal: make the repo contract match live DB reality.
- Why: current code and one repo migration still drift from the live backend contract.
- How:
  - Reconfirm live notification schema, policies, functions, triggers, realtime membership.
  - Patch stale February 26 notification SQL for fresh bootstrap.
  - Capture missing versioned policy source if still absent locally.
  - Write RLS matrix with positive/negative checks.
- Result: repo migrations, live DB, and contract docs align.
- GATE CHECK: fresh/bootstrap and live verification both pass, and RLS matrix is complete.

### Phase 2: Backend/API Alignment in App Layer
- Goal: remove duplicate client writes and align every event family to its server-side source.
- Why: duplicated client writes silently fail and blur ownership.
- How:
  - Build producer decommission matrix.
  - Refactor notification service to read/update only.
  - Remove chat/task/task-request/booking notification writes after their server-side equivalents are verified.
  - Add explicit handling for all live notification types and entity kinds.
- Result: one source of truth per business event and no client writes to `public.notifications`.
- GATE CHECK: producer matrix is complete and grep proves no business callsite writes notifications directly.

### Phase 3: UI Wiring + MVVM Repair
- Goal: make notification reading, rendering, and routing stable.
- Why: current ViewModel owns navigation context and the modal tap flow is unsafe.
- How:
  - Make `NotificationViewModel` context-free.
  - Implement auth-aware connect/disconnect lifecycle.
  - Refactor modal selection/routing using a stable context.
  - Add stable keys for bell, modal states, and rows.
  - Add explicit error/retry states.
- Result: stable badge/modal UX with strict MVVM boundaries.
- GATE CHECK: widget tests cover modal tap flow, row keys exist, and auth transitions clear/reconnect safely.

### Phase 4: QA + Security Validation
- Goal: prove the corrected feature is safe and deterministic.
- Why: staging-backed integration alone is insufficient and current notification tests are flaky.
- How:
  - Add unit tests for parsing/type handling and lifecycle.
  - Add widget tests for badge/modal/error/tap states.
  - Stabilize integration with seeded fixture contract and bounded waits.
  - Run two-user RLS negative checks and event-family smoke tests.
- Result: automated and manual proof that the feature works under the live server-authority model.
- GATE CHECK: test suite passes, integration is deterministic, and RLS negative checks fail correctly.

### Phase 5: Docs + Release
- Goal: make the change sustainable and releasable.
- Why: documentation drift and undefined release workflow caused part of the original problem.
- How:
  - Sync setup/developer/roadmap docs.
  - Execute PR review checklist and release sanity matrix.
  - Validate observability and flake budget before merge.
- Result: code, docs, and release process stay aligned.
- GATE CHECK: docs match reality, release checklist passes, and residual risks are signed off.

## I) Change Report (Diff-Style)

1. Original issues summary
- The original plan was directionally right but left foundational decisions open.
- It did not include a Test Infrastructure Gate despite being test-heavy.
- It did not lock the `task_request` routing contract.
- It did not turn client-write removal into a proof-based grep gate.
- It did not define delivery slicing or flake policy.

2. Added steps
- Added Gate 0 test infrastructure work.
- Added decision lock for subscription lifecycle, migration repair, `task_request` routing, and seeded integration fixtures.
- Added producer decommission matrix.
- Added stable selector/key requirement.
- Added PR slicing and release matrix.

3. Removed steps (if any)
- Removed the open-ended “decide later” treatment for provider lifecycle.
- Removed the implicit assumption that all live server-emitted entity types are already supported by the app.

4. Reordered steps (from → to)
- Test planning moved from late QA to Gate 0 before data/contracts.
- Modal tap-flow fix moved ahead of general UI polish.
- Producer decommission proof moved ahead of release QA.

5. Expanded steps (what became more detailed)
- Contract work now explicitly covers live types and `task_request` metadata routing.
- Migration work now distinguishes fresh-bootstrap repair from deployed-environment verification.
- QA now defines deterministic fixtures, selector requirements, and flake handling.

6. Why (short, practical)
- Without these additions, the plan would likely ship partial cleanup, flaky tests, and an unresolved live contract mismatch.

7. Residual risks (what still remains risky even after fixes)
- Live DB may still contain historical rows with unexpected `type` values not seen in current function definitions.
- Fresh bootstrap repair of historical migrations remains sensitive and must be validated on an isolated branch DB.
- Staging-backed integration will still be slower and more brittle than pure local/widget tests even after deterministic seeding.
