# 📌 Plan Critique: Bookin Remediation — Re-improved with @PlanCritic

- Source plan: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_Bookin_Remediation_2026-02-28.md`
- Audit method applied: `@PlanCritic` from `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.agents/workflows/plan_critic.md`
- Scope audited: `Bookin` remediation plan only, plus the current repo evidence that materially affects execution safety

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- Scope remains limited to `lib/features/booking/**` and direct dependencies already identified in the source plan.
- The current repository state is the ground truth for app code, while `Sline_everything/*.md` remains intent until confirmed against live Supabase.
- Existing test infrastructure is partially present:
  - `mocktail` exists in `pubspec.yaml`
  - `test/test_support/pump_app.dart` exists
  - widget tests already exist for app/home/chat/dashboard areas
  - integration helpers and preflight gates already exist under `integration_test/support/`
- Booking integration coverage is not execution-ready today:
  - `integration_test/booking_request_flow_test.dart` is explicitly preflight-skipped because the current checkout path has no safe automation seam or seeded verification path.
- Minimal-risk remediation is still the right default because the feature currently contains exposed payment credentials and privileged client behavior.
- RLS remains the authorization source of truth. Any client permission checks are UX only.

### Decision Needed (Blocking)

- Missing decision: **What is the live DB truth source for this remediation?**
  - Options:
  - Use `@mcp:supabase-mcp-server:` live scan before execution begins (recommended)
  - Export a current staging schema/policy/function snapshot and treat it as the signed execution baseline
  - Proceed using docs + repo SQL only
  - Recommended: first option, or second if MCP access is unavailable. The current plan touches RLS, RPC, webhook behavior, and booking schema drift; docs-only execution is not safe.
  - Plan impact: blocks all DB/RLS/backend implementation work until the live baseline is captured.

- Missing decision: **Do we keep the current “booking draft row before payment” model or introduce a separate payment-intent object?**
  - Options:
  - Keep booking drafts in `bookings` and harden them with server-side validation, expiry, and idempotent recovery (recommended)
  - Introduce a new `payment_attempts` or `booking_payment_intents` object and migrate checkout flow to it
  - Leave the current mixed draft model unchanged
  - Recommended: first option. It is the lowest-risk path because the app, webhook, and ledger logic already assume a booking-centric flow. A new payment-intent object is cleaner, but it expands schema, migration, and compatibility risk.
  - Plan impact: changes the contract design, migration steps, recovery semantics, and rollout complexity.

- Missing decision: **What is the authoritative notification strategy for booking side effects?**
  - Options:
  - Move booking-triggered notifications to DB trigger or server-side function (recommended)
  - Keep client-side notification inserts and rely on RLS
  - Disable booking notifications during remediation and reintroduce later
  - Recommended: first option. Current client-side cross-user notification writes are a security and integrity smell.
  - Plan impact: changes Phase 2 and Phase 3 deliverables and removes notification inserts from the critical client path.

- Missing decision: **How will booking checkout be verified end-to-end in automation?**
  - Options:
  - Add a default-preserving checkout test seam for a deterministic integration happy path
  - Keep full QiCard checkout manual, and automate only server-contract/widget/unit coverage plus a seeded post-booking verification variant (recommended)
  - Ship without an automated booking payment verification path
  - Recommended: second option. The repo already documents that full checkout automation is blocked in current code. For this remediation, contract tests + widget tests + manual staging E2E are safer than inventing a fragile fake gateway seam under security pressure.
  - Plan impact: changes the Release/QA gate and prevents fake progress on an unautomatable path.

- Missing decision: **How do we handle old clients after rotating the exposed QiCard credentials?**
  - Options:
  - Deploy server-side payment path first, keep a short compatibility window, then rotate credentials and disable old client path after adoption threshold (recommended)
  - Rotate credentials immediately when the new app build ships
  - Leave the exposed credentials active indefinitely
  - Recommended: first option. Immediate rotation risks breaking active old clients; leaving credentials active defeats the main security fix.
  - Plan impact: adds release sequencing, telemetry thresholds, and a compatibility window to the plan.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate

- Status: ❌ FAIL
- Reason:
  - Shared Flutter test infrastructure exists, but Bookin-specific payment automation is still blocked by current code and preflight.
  - No Deno/edge-function test harness, fixture manifest, or run commands are defined for `qicard_webhook_handler` or a future recovery function.
  - The source plan asks for booking widget/integration/edge-function tests but does not define the deterministic setup, env injection, or failure artifact rules needed to execute them.
- What to add/fix to pass:
  - Add a Bookin-specific test foundation section before any per-test implementation:
    - Flutter widget test targets and harness reuse
    - edge-function test runner and fixture paths
    - integration env variables and staging credential contract
    - manual-vs-automated boundary for QiCard happy path
  - Reuse and document existing assets:
    - `test/test_support/pump_app.dart`
    - `integration_test/support/helpers.dart`
    - `integration_test/support/preflight.dart`
    - `.TODO/QiService/fixtures/*.json`

### 1) Data/Contracts Gate

- Status: ❌ FAIL
- Reason:
  - Live DB truth is still missing for booking tables, RLS, triggers, enums, and amount/status columns.
  - The plan does not resolve the core contract decision of draft booking state versus separate payment-intent state.
  - Canonical booking select shape is mentioned, but no contract artifact forces list/detail/post-action refresh parity before code changes begin.
- What to add/fix to pass:
  - Capture live schema/RLS/function evidence first.
  - Lock one booking/payment state model.
  - Create a canonical contract artifact for booking row shapes and payment/recovery payloads before implementation.

### 2) Security Gate

- Status: ❌ FAIL
- Reason:
  - The source plan removes client-side secrets but does not include merchant credential rotation or revocation, even though the credentials were already shipped in client code.
  - The plan mentions fail-closed webhook verification but does not explicitly require replay/idempotency controls, rate limits, or audit logging on recovery/refund flows.
  - Booking-triggered notifications remain architecturally unresolved, leaving a possible cross-user write surface.
- What to add/fix to pass:
  - Add a credential rotation task as a release blocker.
  - Add idempotency, rate-limit, and audit-log requirements for payment creation, recovery, webhook processing, and refund paths.
  - Decide and implement server-authoritative notification dispatch.

### 3) Backend/API Gate

- Status: ❌ FAIL
- Reason:
  - The source plan proposes new server functions/RPCs, but it does not define exact topology, ownership rules, request ids, or deployment order.
  - It mixes critical security changes with broad service/viewmodel refactors, which increases the chance of backend and app-layer changes drifting apart.
  - No compatibility contract is defined for in-flight booking drafts or older app versions during rollout.
- What to add/fix to pass:
  - Lock function/RPC topology and deploy order.
  - Separate must-fix backend security work from optional structural cleanup.
  - Add compatibility handling for old clients and in-flight booking drafts.

### 4) UI/Integration Gate

- Status: ❌ FAIL
- Reason:
  - The plan schedules large UI/viewmodel refactors before the payment/state contracts are stabilized.
  - It does not define explicit UX states for stale draft recovery, failed recovery, orphan timeout, or old-app incompatibility.
  - The current repo already shows the end-to-end booking integration test blocked at checkout, but the plan does not convert that into an explicit execution decision.
- What to add/fix to pass:
  - Reduce the critical UI change set to contract adoption, WebView hardening, duplicate-action protection, and legacy route cleanup.
  - Add explicit UX/state-machine requirements for recovery timeout, retry, and orphan draft handling.
  - Split post-release refactors out of the remediation critical path.

### 5) Release/QA Gate

- Status: ❌ FAIL
- Reason:
  - The source plan has no explicit server-before-client deployment order, no rollback checkpoints between phases, and no adoption threshold for rotating exposed credentials.
  - It lacks PR slicing, review checklist expectations, and post-deploy monitoring queries/alerts.
  - It does not define what evidence is sufficient to ship if the full payment happy path remains manual.
- What to add/fix to pass:
  - Add release sequencing, PR slicing, rollout thresholds, and monitoring queries.
  - Add a manual staging sign-off checklist for the checkout happy path.
  - Define stop-ship conditions tied to security and payment integrity metrics.

## C) Critical Gaps (Must-Fix)

- **Gap:** No live schema/RLS/function baseline exists before DB-facing remediation
  - **Why it will break:** You will design migrations, contracts, and policy changes against docs and stale repo SQL instead of actual deployed objects.
  - **Fix (exact step(s) to add / reorder):** Add a Phase 0 step that blocks all implementation until either `@mcp:supabase-mcp-server:` output or a staging schema/policy/function export is attached to `.TODO/`.
  - **Owner:** Backend / Infra
  - **Acceptance check:** A captured artifact lists live `bookings`, `availability_slots`, `notifications`, booking enums, booking triggers, relevant RPCs, indexes, and edge functions.

- **Gap:** The plan removes client-side secrets but does not rotate the exposed QiCard credentials
  - **Why it will break:** Even after the app is fixed, already-shipped credentials remain valid for abuse until they are rotated server-side.
  - **Fix (exact step(s) to add / reorder):** Add a security containment step before release:
    - create new QiCard credentials
    - switch server functions to the new credentials
    - disable old credentials after the compatibility window
  - **Owner:** Backend / Infra
  - **Acceptance check:** Old credentials fail, new server-side credentials work, and no client artifact contains the rotated secrets.

- **Gap:** The draft booking state model is not explicitly chosen
  - **Why it will break:** Recovery, orphan handling, idempotency, and rollback behavior all depend on whether payment starts from a booking draft row or another object.
  - **Fix (exact step(s) to add / reorder):** Add a contract decision step before schema/API work and lock the chosen model in `.TODO/CONTRACT_Bookin_Payment_2026-02-28.md`.
  - **Owner:** Backend / Product
  - **Acceptance check:** One documented state machine covers draft creation, hold, confirmation, timeout, cancel, refund, and replay handling.

- **Gap:** No explicit idempotency contract exists for payment create, webhook success, recovery, or refund
  - **Why it will break:** Retries, replays, app resumes, and duplicate taps can double-apply holds, refunds, or booking transitions.
  - **Fix (exact step(s) to add / reorder):** Add an idempotency design step before implementation:
    - deterministic correlation keys
    - one-write guarantees per transition
    - duplicate request handling semantics
  - **Owner:** Backend
  - **Acceptance check:** Contract and tests prove repeated requests are safe and return the same terminal result or a controlled conflict.

- **Gap:** Recovery endpoint auth, rate limiting, and audit logging are not specified
  - **Why it will break:** A user-owned JWT alone is not enough if recovery can be spammed, replayed, or used to probe booking state.
  - **Fix (exact step(s) to add / reorder):** Add backend security tasks for:
    - booking ownership validation
    - rate limiting or replay budget
    - audit log/event emission for recovery/refund/decline
  - **Owner:** Backend / Infra
  - **Acceptance check:** Recovery attempts for non-owned bookings fail, repeated spam is throttled/contained, and sensitive actions are traceable.

- **Gap:** Booking-triggered notifications are still treated as a side concern instead of a trust-boundary decision
  - **Why it will break:** If client inserts remain, you keep a cross-user write vector; if they fail under RLS, you may silently lose required notifications.
  - **Fix (exact step(s) to add / reorder):** Make notification authority a blocking architecture decision and either move it server-side or explicitly disable it for the remediation window.
  - **Owner:** Backend / Product
  - **Acceptance check:** Booking success/failure does not depend on client notification inserts, and notification delivery is authoritative.

- **Gap:** The source plan mixes security-critical remediation with broad service/viewmodel refactors
  - **Why it will break:** The blast radius becomes too large. A release-blocking security fix should not depend on splitting `BookingViewModel` and `BookingService` in the same execution stream.
  - **Fix (exact step(s) to add / reorder):** Defer non-essential structural refactors into a post-release cleanup phase. Keep the critical path focused on security, correctness, and contract adoption.
  - **Owner:** Frontend / Backend
  - **Acceptance check:** A minimal ship path exists that fixes security and integrity issues without requiring module-wide architectural surgery.

- **Gap:** No explicit server-before-client rollout order is defined
  - **Why it will break:** If the client switches to new endpoints before the server is live, checkout fails. If the server rotates secrets before compatibility is managed, old clients break unexpectedly.
  - **Fix (exact step(s) to add / reorder):** Add a release sequence:
    - deploy schema and server functions first
    - validate with staging/manual smoke
    - ship app changes
    - monitor adoption
    - rotate old credentials
  - **Owner:** Infra / Backend / Frontend
  - **Acceptance check:** Each rollout checkpoint has a measurable pass/fail rule and rollback trigger.

- **Gap:** No Bookin-specific test execution contract exists even though payment automation is currently blocked
  - **Why it will break:** Teams will mark “tests added” as complete without a deterministic path to verify checkout, webhook, and recovery behavior.
  - **Fix (exact step(s) to add / reorder):** Add a Bookin test plan section that separates:
    - unit/widget coverage
    - edge-function contract coverage
    - seeded or manual staging E2E
    - exact commands, env vars, fixture files, and failure artifact expectations
  - **Owner:** Infra / Frontend / Backend
  - **Acceptance check:** Every listed test has a runner, fixture source, env contract, and a bounded stop condition.

- **Gap:** The plan lacks post-deploy monitoring queries and support triage hooks
  - **Why it will break:** Payment failures and orphan booking states will surface first as support incidents, not compile errors.
  - **Fix (exact step(s) to add / reorder):** Add monitoring and runbook steps for:
    - stuck pending drafts
    - held payment with no booking confirmation
    - repeated recovery failures
    - unsigned webhook rejection spikes
  - **Owner:** Infra / Backend
  - **Acceptance check:** There is a documented query/log/alert path for each production failure mode.

- **Gap:** No PR slicing or review workflow is defined for a high-risk multi-layer change
  - **Why it will break:** One oversized PR will hide regressions and slow review on the exact areas that need scrutiny.
  - **Fix (exact step(s) to add / reorder):** Add a delivery workflow:
    - PR1: contracts/schema/security primitives
    - PR2: backend/app wiring
    - PR3: tests/docs/post-release cleanup
  - **Owner:** Product / Frontend / Backend
  - **Acceptance check:** Each PR has a bounded scope, definition of done, and reviewer checklist.

## D) Invariants & Success Criteria (Non-Negotiable)

- **Invariant:** No Flutter client artifact contains usable QiCard merchant secrets or privileged gateway operations
  - **How to enforce:** Server-side proxy/recovery only, credential rotation, code scan for `QICARD_USERNAME`, `QICARD_PASSWORD`, and `Authorization: Basic`
  - **How to verify:** `rg` checks in the repo and a built-app secret scan show no merchant credentials or Basic Auth construction in client code

- **Invariant:** Booking/payment state transitions are server-validated and idempotent
  - **How to enforce:** RPC/edge-function guards, deterministic correlation keys, duplicate-request handling, transaction boundaries on decline/refund
  - **How to verify:** Contract tests cover replay/retry cases and DB queries show one terminal transition per correlation id

- **Invariant:** RLS prevents non-party booking and notification access
  - **How to enforce:** Least-privilege policies and no client-side privileged fallback
  - **How to verify:** Positive/negative RLS matrix tests for client, provider, non-party authenticated user, and service role

- **Invariant:** Recovery acts only on a booking owned by the authenticated caller and only when gateway status supports it
  - **How to enforce:** Server-side ownership check, status lookup, rate limit, and audit log
  - **How to verify:** Forbidden recovery attempts fail, valid recovery succeeds once, repeat attempts are no-op or conflict safely

- **Invariant:** One user action triggers one authoritative booking mutation
  - **How to enforce:** Remove duplicate `markDelivered()` calls, disable duplicate taps, use idempotent backend primitives
  - **How to verify:** Unit/widget tests and logs show a single mutation and single side-effect chain per action

- **Invariant:** Booking list/detail/post-action refresh all consume one canonical row shape
  - **How to enforce:** Contract artifact and one shared select mapping for `BookingModel`
  - **How to verify:** Post-action refresh retains schedule, status, and payment fields without ad hoc null fallbacks

- **Invariant:** Missing security config fails closed outside explicit local-dev mode
  - **How to enforce:** Webhook signature requirement, explicit dev-only override flag, no permissive default branches
  - **How to verify:** Unsigned staging/prod payloads fail; only local-dev configuration can bypass signature checks

- **Invariant:** In-flight old clients do not create silent payment/data corruption during rollout
  - **How to enforce:** staged server-first rollout, compatibility window, monitored credential rotation, server-side controls
  - **How to verify:** rollout dashboards show checkout success and no spike in abandoned or invalid draft states during transition

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|-------------|--------|--------------|-------------|-----------|----------|
| Live schema differs from docs and repo SQL | Supabase schema/RLS/RPC | High | High | Feature | Live scan shows unexpected columns/policies/triggers | Block implementation until live evidence is captured | Restrict current turn to evidence capture and contract update only |
| Exposed QiCard credentials remain valid after app fix | Payment gateway / secrets | High | High | Security-breach | Gateway logs show requests using old credential pair | Rotate credentials and move all gateway calls server-side | Disable old credentials and pause checkout if abuse appears |
| Webhook or recovery replay double-applies hold/refund | Edge function / RPC / ledger | Med | High | Data-loss | Duplicate correlation ids, repeated hold/refund logs, inconsistent booking/payment state | Enforce idempotency keys and transactional guards | Freeze recovery/refund endpoint and reconcile affected bookings manually |
| Old app versions fail after rollout | Mobile release / checkout | Med | High | App-wide | Spike in checkout failures from older app versions | Server-first rollout plus compatibility window and telemetry thresholds | Delay credential rotation or temporarily restore overlap path while forcing upgrade |
| Booking drafts accumulate without terminal state | Booking checkout / recovery | Med | High | Feature | Query shows stale `pending`/draft rows older than threshold | Define expiry cleanup and recovery contract | Run cleanup/reconciliation job and support runbook |
| Notification side effects break or remain unsafe | Booking notifications | Med | Med | Feature | Missing booking notifications or RLS denials in logs | Move notifications server-side or disable them from critical path | Ship without booking notifications temporarily |
| Full automated checkout E2E remains blocked | QA / integration | High | Med | Delivery | `integration_test/booking_request_flow_test.dart` remains skipped | Define seeded/manual boundary and contract tests up front | Manual staging sign-off becomes ship gate |
| Broad refactor regresses booking UI while fixing security | Frontend MVVM/UI | Med | High | Feature | Widget tests fail or unrelated booking screens regress | Defer large refactors from critical path | Revert cleanup PR while keeping security fixes |
| Recovery endpoint gets abused for state probing | Server API / authz | Med | High | Security-breach | Spike in 403/429 on recovery endpoint | Rate limit, audit log, ownership checks, no verbose error leakage | Temporarily disable recovery and rely on webhook/manual support |
| Monitoring is too weak to catch rollout failures early | Ops / release | Med | High | App-wide | Support tickets appear before alerts do | Add explicit queries, alerts, and rollback thresholds | Freeze rollout and investigate using logs/DB queries |

## F) Pre-Mortem (How this fails in real life)

- This fails when the team writes migrations against docs, but live `bookings` has different columns or policies and the new client contract is wrong on day one.
- This fails when the client code is cleaned up, but the leaked QiCard credentials stay active and are abused from an old build or reverse-engineered binary.
- This fails when webhook signature enforcement is hardened, but replay/idempotency rules are still missing and the same successful payment is processed twice.
- This fails when the recovery endpoint is added without throttling or audit logs and becomes a user-controlled probe for booking/payment state.
- This fails when the rollout ships client changes before the new server functions are live and checkout breaks for every updated user.
- This fails when the team tries to split `BookingViewModel` and `BookingService` while also changing payment security boundaries and cannot isolate the regression source.
- This fails when the release is marked “tested” even though `integration_test/booking_request_flow_test.dart` is still skipped and no manual staging sign-off replaced it.
- This fails when stale draft bookings pile up because timeout/expiry cleanup was not defined and support sees “paid but not booked” incidents.
- This fails when booking notifications are left in the client path, RLS blocks them, and operators mistakenly believe the remediation preserved side effects.
- This fails when old clients lose checkout after credential rotation and there is no compatibility threshold or forced-upgrade plan.

## G) Plan Fixes (Concrete Additions / Expansions)

### 1. Add a live-evidence capture task

- **Goal:** Remove DB/RLS/function unknowns before any design or code work starts
- **Why:** Current plan is blocked by missing live Supabase truth
- **How:** Capture either `@mcp:supabase-mcp-server:` output or a staging schema/policy/function export and store it under `.TODO/`
- **Output artifact:** `.TODO/BOOKIN_LIVE_DB_BASELINE_2026-02-28.md`
- **Stop condition:** Live objects for `bookings`, `availability_slots`, `notifications`, booking enums, booking triggers, relevant RPCs, and edge functions are documented

### 2. Add a security containment step for credential rotation

- **Goal:** Close the already-shipped secret exposure, not just the source code smell
- **Why:** Removing secrets from source is insufficient if the credentials stay valid
- **How:** Provision new QiCard credentials, deploy server-side usage, monitor adoption, then disable old credentials
- **Output artifact:** `.TODO/BOOKIN_SECRET_ROTATION_2026-02-28.md`
- **Stop condition:** Old credentials fail, new credentials are server-only, and release sequencing is documented

### 3. Add a booking/payment state machine contract

- **Goal:** Eliminate ambiguity around drafts, holds, confirmation, timeout, cancel, refund, and replay
- **Why:** Recovery, rollback, and tests depend on one explicit state model
- **How:** Lock the chosen draft model and draw the allowed transitions with terminal/error paths
- **Output artifact:** `.TODO/CONTRACT_Bookin_Payment_2026-02-28.md`
- **Stop condition:** All teams can answer what happens for success, timeout, duplicate request, replay, cancel, decline, and refund without ambiguity

### 4. Add idempotency and audit-log design tasks

- **Goal:** Make retries and support reconciliation safe
- **Why:** Payment flows fail in production through retries, resumes, and duplicates, not just happy paths
- **How:** Define correlation keys, dedupe rules, audit events, and recovery/refund logging before implementation
- **Output artifact:** `.TODO/BOOKIN_IDEMPOTENCY_AUDIT_2026-02-28.md`
- **Stop condition:** Every sensitive payment mutation has a correlation id, dedupe behavior, and an audit trail

### 5. Add a server-topology and rollout-order task

- **Goal:** Prevent mismatch between new client expectations and server availability
- **Why:** Security and payment fixes require deploy sequencing
- **How:** Decide the function/RPC topology and specify server-first rollout, smoke checks, app switch, adoption monitoring, and credential rotation
- **Output artifact:** `.TODO/BOOKIN_ROLLOUT_2026-02-28.md`
- **Stop condition:** There is a step-by-step deployment order with measurable pass/fail checks and rollback triggers

### 6. Narrow the critical app change set

- **Goal:** Ship the security/correctness remediation without coupling it to a full module refactor
- **Why:** Broad MVVM refactors increase blast radius and delay the fix
- **How:** Limit the critical path to:
  - removing client gateway auth
  - replacing client webhook recovery
  - hardening WebView callback checks
  - fixing duplicate booking mutations
  - aligning canonical query/model shape
  - isolating tab loading/error state only as needed
- **Output artifact:** updated app-layer implementation plan
- **Stop condition:** The app can use the new backend contracts without requiring a full service/viewmodel split

### 7. Add a Bookin-specific test execution contract

- **Goal:** Make testing executable instead of aspirational
- **Why:** The current plan requests tests without defining runners, data, or environment contracts
- **How:** Split test work into:
  - unit tests
  - widget tests
  - edge-function contract tests
  - integration/manual staging verification
- **Output artifact:** `.TODO/BOOKIN_TEST_EXECUTION_2026-02-28.md`
- **Stop condition:** Each test task lists file path, runner, env/secrets contract, fixtures, and a bounded completion rule

### 8. Add post-deploy monitoring and support runbooks

- **Goal:** Catch payment/data integrity regressions before they become widespread
- **Why:** Checkout issues surface first as production drift
- **How:** Define queries, alerts, and operator steps for stale drafts, replay anomalies, webhook signature failures, and recovery spikes
- **Output artifact:** `.TODO/BOOKIN_MONITORING_2026-02-28.md`
- **Stop condition:** On-call/support can identify and triage each expected failure mode using documented signals

### 9. Add PR slicing and review gates

- **Goal:** Keep a high-risk remediation reviewable
- **Why:** One large PR will hide regressions and security mistakes
- **How:** Split execution into reviewable PRs:
  - PR1 contracts/security primitives
  - PR2 backend/app wiring
  - PR3 tests/docs/follow-up cleanup
- **Output artifact:** `.TODO/BOOKIN_DELIVERY_PLAN_2026-02-28.md`
- **Stop condition:** Each PR has a bounded scope, reviewers, and definition of done

## H) Corrected Plan (Execution-Ready, Gate-Based)

## Phase 0: Evidence, Decisions, and Test Baseline

- **Goal:** Remove blocking unknowns before any implementation starts
- **Why:** The source plan still depends on unresolved DB truth, rollout choices, and an undefined payment test strategy
- **How:**
  - Capture the live DB/function/policy baseline
  - Lock the booking draft model decision
  - Lock notification authority
  - Lock the release strategy for old clients and credential rotation
  - Lock the Bookin test execution contract:
    - widget/unit runner usage
    - edge-function test runner
    - integration env contract
    - manual-vs-automated checkout boundary
  - Define PR slicing and review checkpoints
- **Result:** No implementation begins with hidden assumptions
- **GATE CHECK:** Live DB evidence exists, blocking decisions are resolved, and the Bookin test plan is executable

## Phase 1: Data/Contracts

- **Goal:** Lock one canonical booking/payment contract and state machine
- **Why:** Backend, UI, recovery, and tests will drift without a single contract
- **How:**
  - Confirm live `bookings`/`availability_slots`/`notifications` schema and booking enums
  - Decide whether to retain booking drafts in `bookings` and document the chosen state machine
  - Define one canonical booking select shape for list/detail/post-action refresh
  - Reconcile `price` vs `amount_gross`
  - Define correlation/idempotency fields and terminal/error states
  - Write migration intent and compatibility rules
- **Result:** The data model and public/private payload boundaries are explicit
- **GATE CHECK:** Contract artifact is approved, live schema drift is reconciled, and no unresolved state-model ambiguity remains

## Phase 2: Security / RLS

- **Goal:** Restore trust boundaries before any app path uses the new flow
- **Why:** The feature currently exposes credentials and lets the client participate in privileged payment behavior
- **How:**
  - Verify/repair live RLS for bookings, slots, and notifications
  - Add fail-closed webhook verification rules
  - Add recovery authz, rate limits, replay handling, and audit logs
  - Decide and implement server-authoritative notification behavior
  - Plan and execute credential rotation with compatibility window
- **Result:** Security controls are defined and enforceable before backend and app wiring change
- **GATE CHECK:** Non-party access fails, unsigned/replayed payment events are contained, and credential rotation plan is approved

## Phase 3: Backend APIs

- **Goal:** Provide safe server-side primitives and deploy them in the right order
- **Why:** The app cannot safely move off client-side payment behavior without stable server endpoints and transactional primitives
- **How:**
  - Implement payment creation/status/recovery server endpoints or functions with the locked topology
  - Implement atomic decline/refund server-side behavior
  - Add webhook idempotency and correlation handling
  - Add any needed schema/index/policy migrations
  - Deploy server changes first to staging, then smoke test before app changes
- **Result:** Backend/API behavior is stable, traceable, and available before the app switches over
- **GATE CHECK:** Server endpoints pass contract/security tests and staging smoke checks before any app release depends on them

## Phase 4: UI Wiring

- **Goal:** Switch the app to the new contracts with the smallest safe change set
- **Why:** Security and correctness fixes should not depend on a full feature rewrite
- **How:**
  - Remove all client-side Basic Auth gateway calls
  - Replace client webhook recovery with the new authenticated recovery path
  - Harden WebView callback host/path/correlation checks
  - Fix duplicate `markDelivered()` writes and any other double-submit path
  - Align booking queries/model mapping to the canonical contract
  - Isolate client/provider loading/error state where required for correctness
  - Remove or redirect legacy booking payment route if still unused
- **Result:** The app uses the safe backend contracts and preserves booking UX
- **GATE CHECK:** No privileged payment behavior remains in the client, booking actions mutate once, and core booking screens behave correctly on staging

## Phase 5: QA, Release, and Documentation

- **Goal:** Prove the fix set and ship it without fake progress
- **Why:** The current Bookin happy path has known automation limits, so release evidence must be explicit
- **How:**
  - Run Flutter analyze, focused unit/widget tests, and edge-function tests
  - Run the approved integration subset and manual staging checkout sign-off
  - Execute RLS contract checks and migration verify queries
  - Monitor server-first rollout, app adoption, and credential rotation checkpoints
  - Update docs and attach runbook/rollback evidence
- **Result:** Release is backed by measurable security, correctness, and rollout evidence
- **GATE CHECK:** All required automated checks pass, manual staging sign-off exists for checkout, rollout telemetry is within threshold, and docs/runbooks are updated

## Phase 6: Post-Release Structural Cleanup (Deferred)

- **Goal:** Pay down architecture debt without blocking the security remediation
- **Why:** Full `BookingService` / `BookingViewModel` splits and broader presentation cleanup are valuable but not required to close the critical risk
- **How:**
  - Split services/view models incrementally
  - Consolidate booking status presentation
  - Replace note metadata string encoding with structured storage if still needed
- **Result:** The feature becomes cleaner after the release-blocking security/correctness work is stable
- **GATE CHECK:** Cleanup stays behind the released contract and does not reopen payment/security behavior

## I) Change Report (Diff-Style)

### 1) Original issues summary

- The original plan was directionally correct but not execution-safe.
- It blocked on live DB truth but still laid out downstream implementation as if the missing evidence were just another task.
- It mixed critical security remediation with broad app-layer refactors.
- It removed client-side secrets in theory but forgot the real-world containment step: credential rotation.
- It asked for testing without defining the Bookin-specific automation boundary, even though the current booking integration test is already preflight-blocked.
- It lacked deployment order, compatibility handling for old clients, and post-deploy monitoring specifics.

### 2) Added steps

- Live DB evidence capture
- Credential rotation and compatibility-window plan
- Explicit booking/payment draft-state decision
- Idempotency and audit-log design
- Recovery auth/rate-limit requirements
- Notification authority decision
- Bookin-specific test execution contract
- Server-before-client rollout sequence
- PR slicing and review gates
- Post-deploy monitoring/runbooks

### 3) Removed steps

- Removed full `BookingService` and `BookingViewModel` splitting from the release-blocking critical path
- Removed broader UI polish and note-metadata restructuring from the must-ship sequence
- Removed the assumption that full automated payment happy-path coverage is required immediately if the real checkout flow cannot yet be automated safely

### 4) Reordered steps

- From: contracts/security/backend/UI/tests mixed in one broad stream
- To:
  - evidence and decisions first
  - then data/contracts
  - then security/RLS
  - then backend APIs
  - then app wiring
  - then QA/release/docs

- From: “remove secrets from client” late in implementation
- To: “contain secret exposure and plan credential rotation” as an early release blocker

- From: “refactor structure” alongside critical fixes
- To: “defer structural cleanup until after the security/correctness release is stable”

### 5) Expanded steps

- Testing now includes:
  - existing harness reuse
  - Deno/edge-function coverage requirement
  - fixture/env contract
  - manual-vs-automated checkout boundary
- Security now includes:
  - credential rotation
  - replay/idempotency
  - rate limiting
  - audit logs
- Release now includes:
  - server-first rollout
  - compatibility window
  - adoption threshold
  - monitoring queries
  - support runbooks

### 6) Why

- The original plan would fail in execution because it treated critical unknowns as ordinary tasks and bundled too much architectural ambition into a security incident response.
- The corrected version reduces blast radius, makes blocking decisions explicit, and replaces vague “add tests/roll back if needed” language with concrete gates and artifacts.

### 7) Residual risks

- Live Supabase truth is still unavailable in this session; the plan remains blocked until that evidence exists.
- External gateway behavior and callback edge cases may still require staging-only validation even after contract tests are added.
- Old clients with embedded secrets remain a risk until credential rotation completes and the compatibility window closes.
- If notification authority is not moved server-side, one security/integrity compromise remains in the feature even after the main payment fixes ship.
