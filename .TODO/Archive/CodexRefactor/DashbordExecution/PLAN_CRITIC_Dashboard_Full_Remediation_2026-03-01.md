# PlanCritic Report: Dashboard Full Remediation

## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The target remains the dashboard feature and only the direct dependency set already scoped in [/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dashboard.TODO.md](/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/dashboard.TODO.md) and [/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md](/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md). File References: `.TODO/dashboard.TODO.md:1-205`, `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:11-39`
- Existing shared test helpers are limited to the lightweight widget harness in [/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart](/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart) and the staging-backed integration preflight in [/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/preflight.dart](/Users/eros/Dev/Eros_Projects/Sline/sline_app/integration_test/support/preflight.dart). File References: `test/test_support/pump_app.dart:1-18`, `integration_test/support/preflight.dart:1-57`
- Dashboard currently has only one integration flow, and it covers role switching rather than payment, transition, or wallet correctness. File References: `integration_test/dashboard_role_switch_flow_test.dart:1-105`, `.TODO/dashboard.TODO.md:89-92`
- Live Supabase truth is still blocked by MCP auth failure, so repo migrations/docs are intent only until a live scan or verified export exists. File References: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:62-80`, `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:172-177`
- Dashboard remediation must stay additive-first for DB work because the touched flows are authz-sensitive and money-sensitive. File References: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:153-158`, `.TODO/dashboard.TODO.md:143-150`

### Decision Needed (Blocking)

1. Missing decision: what is the accepted source of truth for live DB reality while `@mcp:supabase-mcp-server` is blocked.
- Options:
  - Restore MCP auth and use live scan only.
  - Use a DBA-exported verified SQL snapshot for the touched objects.
  - Proceed from repo migrations/docs only.
- Recommended: restore MCP auth; if that is blocked for more than one work session, require a verified SQL export for the touched objects; do not proceed repo-only.
- Why: the current plan already acknowledges live drift risk, and dashboard touches RLS, grants, and payment RPCs. Repo-only planning is not safe for those surfaces.
- What changes in the plan depending on the choice:
  - MCP auth restored: Phase 1 proceeds normally with live verification.
  - Verified export: Phase 1 proceeds, but release remains blocked until the export is attached to the plan artifacts.
  - Repo-only: DB/RLS/payment phases must stop; only test infra, kill-switch UI, and documentation prep can proceed.

2. Missing decision: what happens to finance metrics in the standard dashboard client path.
- Options:
  - Remove finance metrics from the standard dashboard client completely.
  - Keep them only behind a dedicated admin-only RPC/service boundary.
  - Keep the current client-facing repository methods and rely on UI to hide them.
- Recommended: remove them from the standard dashboard path and keep a separate admin-only RPC/service boundary only if the product still needs those metrics.
- Why: the current repo exposes direct client methods while the checked-in SQL grants those views to `authenticated`, which is already a critical finding. File References: `.TODO/dashboard.TODO.md:17-24`, `.TODO/dashboard.TODO.md:145-147`
- What changes in the plan depending on the choice:
  - Remove entirely: Phase 1 revokes grants and Phase 3 deletes/quarantines the repository methods.
  - Admin RPC: Phase 1 adds new RPC/grants and Phase 3 moves the code to an admin-only module.
  - Keep current path: rejected; it leaves the release blocker intact.

3. Missing decision: how to evolve `rpc_get_profile_summaries` without breaking non-dashboard callers.
- Options:
  - Shrink the current RPC in place.
  - Add a versioned/additive minimal RPC and migrate dashboard first.
  - Leave the wide RPC and trust callers not to misuse it.
- Recommended: add a versioned/additive minimal RPC unless a direct caller scan proves no other caller depends on the wider shape.
- Why: the current audit proves dashboard only needs name/avatar, but live caller parity is unverified because MCP access is blocked. File References: `.TODO/dashboard.TODO.md:17-24`, `.TODO/dashboard.TODO.md:153-156`
- What changes in the plan depending on the choice:
  - In-place shrink: smaller DB change, higher hidden-caller risk.
  - Versioned/additive RPC: one more migration, safer rollout.
  - Leave wide RPC: security scope remains larger than necessary.

4. Missing decision: what to do with award/pay entry points if the live payment contract is still inconsistent after the live scan.
- Options:
  - Hard-disable dashboard and request-list award/pay entry points until the contract is proven.
  - Ship behind a temporary internal flag/allowlist.
  - Keep the current flow live while refactoring.
- Recommended: hard-disable the risky entry points until the live contract is proven.
- Why: the current repo shows status mismatch and ledger `{ok:false}` handling defects. Shipping while refactoring a money path is not acceptable. File References: `.TODO/dashboard.TODO.md:25-33`, `.TODO/dashboard.TODO.md:145-150`
- What changes in the plan depending on the choice:
  - Hard-disable: Phase 0 adds explicit kill-switch UX and Phase 4 wires disabled states.
  - Internal flag: Phase 0 adds flag ownership and tester allowlist work.
  - Keep current flow: rejected; the critical correctness issue stays live.

5. Missing decision: how to slice delivery.
- Options:
  - One PR for everything.
  - Three PRs: planning/test infra, DB/security, app/UI/tests/docs.
  - Four PRs: planning/test infra, DB/security, app-layer, UI/QA/docs.
- Recommended: four PRs.
- Why: the current plan already spans DB grants, RPC contracts, payment orchestration, feature refactors, and QA/doc sync. One or three slices still mix too much rollback risk.
- What changes in the plan depending on the choice:
  - One PR: highest rollback risk; review quality drops.
  - Three PRs: workable, but app-layer and UI/test churn remain too broad.
  - Four PRs: lowest risk and cleanest review gates.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The current plan starts at `0.1 Spec Lock`; it has no `0.0 Test Infrastructure Gate` even though it adds new unit/widget/integration work. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:128-164`
  - The plan never defines a dashboard selector/key map, fixture manifest, timeout budgets, failure artifact path, or rerun policy. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:286-297`
  - Existing shared harnesses are generic and staging-oriented; they are not dashboard-specific and do not solve payment-fixture determinism on their own. File References: `test/test_support/pump_app.dart:5-18`, `integration_test/support/preflight.dart:10-57`, `integration_test/support/t61_t70_env.dart:3-87`
- What to add/fix to pass:
  - Add `Phase 0.0 Test Infrastructure Gate`.
  - Add dashboard selector/key map, fixture/seed/reset contract, env/secrets injection contract, timeout/retry budgets, failure artifact path, and per-test-ID matrix.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The current plan acknowledges live DB auth blockage but does not turn it into a blocking decision with an approved fallback. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:62-80`
  - The plan defines contract files, but it does not lock decisions for finance boundary, profile-summary rollout mode, or payment kill-switch behavior. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:146-164`
  - Acceptance criteria are outcome-level only; they do not define a state-machine artifact for booking/task/payment transitions. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:314-324`
- What to add/fix to pass:
  - Add blocking decisions in Phase 0.
  - Add a dashboard state-machine artifact and a payment reconciliation artifact.
  - Block Phase 1.1 onward if live truth is still unavailable.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - The plan does not make finance-view leakage a stop/go release gate with exact verify queries and expected grants before app-layer work continues. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:181-193`
  - The plan does not explicitly require a kill-switch if live payment or transition drift remains unresolved. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:160-164`, `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:337-339`
  - The current release gates do not require privacy-safe observability artifacts or grep checks for sensitive payment/profile logging. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:293-297`
- What to add/fix to pass:
  - Make finance grants, transition authorization, and payment failure handling must-pass release checks.
  - Add exact RLS/grant verification queries with expected outcomes.
  - Add privacy/log-redaction checks to the QA gate.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The current plan does not sequence tolerant app-side seams or kill-switch behavior ahead of DB contract changes. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:160-164`, `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:181-205`
  - The plan does not require a partial-payment reconciliation output for rows affected by status mismatch or ledger failure. File References: `.TODO/dashboard.TODO.md:25-33`, `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:155-157`
  - The plan still carries a `dashboard_management_view_model` split path even though the live surface has no Manage tab; that introduces extra refactor surface without a runtime owner. File References: `.TODO/dashboard.TODO.md:79-81`, `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:231-234`
- What to add/fix to pass:
  - Add a reconciliation artifact and verify query set for partial payment drift.
  - Remove Manage from the target architecture rather than splitting it into another owner.
  - Sequence kill-switch/tolerance seams before risky backend rollout.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - The current plan says to add UI states but never defines stable selectors/keys for the critical dashboard actions and terminal states. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:250-257`
  - There is no screen-state matrix for disabled award/pay actions, stale wallet state, or transition failures after the contract hardens. File References: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:252-256`, `.TODO/dashboard.TODO.md:77-87`
  - The existing integration test only proves role switching, not payment/transition behavior. File Reference: `integration_test/dashboard_role_switch_flow_test.dart:12-105`
- What to add/fix to pass:
  - Add a UI selector map and explicit disabled/error/kill-switch state matrix.
  - Add at least one payment/transition integration or, if not automatable, a documented preflight-blocked manual contract with postconditions.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The current plan has no branch strategy, per-PR definition of done, or review checklist. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:126-339`
  - The plan does not define failure artifact capture, bounded retry policy, or flake threshold for the new tests. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:286-291`
  - Docs sync exists, but there is no release go/no-go checklist tying docs, live DB proof, and slice completion together. File Reference: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:301-339`
- What to add/fix to pass:
  - Add a delivery workflow gate with `codex/` branch slices, review checklist, and DoD per slice.
  - Add failure artifact conventions, timeout/retry budgets, and flake policy.
  - Add a release checklist that blocks merge/release until docs and live DB proof are attached.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No `Test Infrastructure Gate` exists before new dashboard tests.
- Why it will break: the implementation will add tests before the key map, fixtures, preflight, and timeout rules exist, which guarantees flaky or skipped coverage.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.0 Test Infrastructure Gate`.
  - Create `.TODO/TEST_INFRA_Dashboard_2026-03-01.md`.
  - Create `.TODO/FIXTURES_Dashboard_2026-03-01.md`.
  - Add `integration_test/support/dashboard_env.dart` and `integration_test/support/dashboard_preflight.dart`.
- Owner: Frontend
- Acceptance check: every planned dashboard test references documented selectors, fixtures, preflight rules, and bounded waits.

### Gap 2
- Gap: Live DB truth source is still unresolved.
- Why it will break: DB/RLS/payment work can be implemented against repo intent while production/staging reality differs.
- Fix (exact step(s) to add / reorder):
  - Add a blocking Phase 0 decision for MCP auth restoration vs verified SQL export.
  - Add a hard stop: no DB/RLS/payment migration work without live evidence.
- Owner: Infra
- Acceptance check: `.TODO/LIVE_SCAN_Dashboard_2026-03-01.md` or an equivalent verified export artifact exists before Phase 1.1.

### Gap 3
- Gap: The plan does not lock the finance metrics boundary.
- Why it will break: developers can “fix” grants while leaving hidden client methods or can remove methods while leaving insecure grants.
- Fix (exact step(s) to add / reorder):
  - Add a blocking decision in Phase 0 for remove-vs-admin-RPC.
  - Add a dedicated Phase 1 finance-boundary subphase and a Phase 3 repository cleanup step.
- Owner: Backend
- Acceptance check: there is exactly one approved finance path, and non-admin dashboard runtime has zero direct finance-view reads.

### Gap 4
- Gap: Tender payment has no explicit invariant matrix or reconciliation output.
- Why it will break: status mismatch and ledger failure cases can still leave partially advanced rows with no planned recovery path.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/STATE_MACHINE_Dashboard_2026-03-01.md` for task/booking/payment transitions.
  - Add `.TODO/RECONCILIATION_Dashboard_2026-03-01.md` with verify queries and forward-fix rules for orphaned payment state.
- Owner: Backend
- Acceptance check: payment state transitions and recovery queries are documented and tested before the UI flow is re-enabled.

### Gap 5
- Gap: The profile-summary rollout strategy is ambiguous.
- Why it will break: shrinking the RPC in place can silently break other callers, while leaving it wide keeps unnecessary exposure.
- Fix (exact step(s) to add / reorder):
  - Add a blocking decision in Phase 0.
  - Add a dedicated contract artifact and compatibility-window exit criteria.
- Owner: Backend
- Acceptance check: the final plan names one migration strategy and one removal condition for any temporary compatibility path.

### Gap 6
- Gap: Delivery workflow is missing.
- Why it will break: DB, app-layer, UI, tests, and docs can land together with no clean review or rollback boundary.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.1 Delivery Workflow Gate`.
  - Lock four `codex/` branch slices, reviewer checklist, and DoD per slice.
- Owner: Product
- Acceptance check: the corrected plan includes slice names, merge order, required reviewers, and rollback points.

### Gap 7
- Gap: Dashboard state ownership is underspecified.
- Why it will break: the current plan still carries management-state split work even though Manage is dead, and it does not lock wallet/cache ownership or `MyServices` ownership before refactor.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/OWNERSHIP_Dashboard_2026-03-01.md`.
  - Remove management from the target architecture.
  - Lock wallet snapshot, cache, and services ownership in Phase 0 before refactor work.
- Owner: Frontend
- Acceptance check: each live dashboard surface has one state owner, and dead Manage ownership is not reintroduced.

### Gap 8
- Gap: Release go/no-go and kill-switch behavior are too soft.
- Why it will break: the team can reach the end of implementation with unresolved payment/grant drift and no agreed emergency behavior.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/RELEASE_CHECKLIST_Dashboard_2026-03-01.md`.
  - Add explicit kill-switch states for award/pay, finance metrics, and unsupported transitions.
  - Make those items must-pass before release.
- Owner: Product
- Acceptance check: the release checklist names kill-switch owners, activation conditions, and rollback steps.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: non-admin authenticated users cannot read platform finance aggregates directly.
- How to enforce: revoke direct grants or move access behind an admin-only RPC/service boundary.
- How to verify: grant query shows no direct `authenticated` `SELECT` on finance views; non-admin runtime has no finance-read methods left.

2. Invariant: task and booking transitions are server-authoritative.
- How to enforce: transition RPCs validate actor, current state, and next state; client UX checks remain advisory only.
- How to verify: SQL negative tests fail for unauthorized or invalid transitions; `rg` shows no dashboard-driven raw workflow `update()` path remains.

3. Invariant: tender payment never advances work state after ledger `{ok:false}` or status mismatch.
- How to enforce: `LedgerService` treats `{ok:false}` as failure, coordinator short-circuits, and RPC contract aligns award/pay states.
- How to verify: unit test for `{ok:false}`; SQL/QA flow proves task/request status does not advance after failure.

4. Invariant: there is one tender payment orchestration path for dashboard and request-list flows.
- How to enforce: shared `tender_payment_coordinator.dart` and view-model-owned launch contract.
- How to verify: duplicate orchestration code is removed and both entry points call the same coordinator.

5. Invariant: no dashboard or task payment view instantiates backend services directly.
- How to enforce: DI/ViewModel ownership only.
- How to verify: `rg -n "TaskService\\(|QiCardPaymentService\\(" lib/features/dashboard lib/features/tasks/view` returns only DI/factory owners, not widgets.

6. Invariant: cross-user profile summaries expose only the approved minimum fields.
- How to enforce: versioned or reduced summary RPC contract.
- How to verify: function definition matches approved fields; callers compile and tests pass.

7. Invariant: wallet snapshot and wallet screen share one loading/source-of-truth contract.
- How to enforce: one wallet ViewModel/service owner and explicit dashboard initialization path.
- How to verify: dashboard overview shows real balances on first entry without visiting wallet screen.

8. Invariant: hidden tabs do not fetch data on first paint.
- How to enforce: tab-scoped loaders and narrower selectors.
- How to verify: service call counts or logs show Overview load does not fan out into hidden Bookings/Inbox data.

9. Invariant: tests are deterministic and bounded.
- How to enforce: selector map, fixture manifest, `--dart-define` env contract, timeout budgets, and one-rerun flake policy.
- How to verify: dashboard preflight fails fast on missing fixtures; failure artifacts are captured at the documented path.

10. Invariant: release cannot proceed without live DB evidence or verified export.
- How to enforce: Gate 1 remains blocking until `.TODO/LIVE_SCAN_Dashboard_2026-03-01.md` exists.
- How to verify: release checklist references the artifact and refuses signoff without it.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| MCP auth remains blocked | Supabase scan / migration planning | High | High | Feature | Re-run still returns `Auth required` | Make live evidence a hard gate in Phase 0 | Limit work to test infra and kill-switch prep until verified export exists |
| Finance view leak survives rollout | DB grants + repository methods | Med | High | Security-breach | `information_schema.role_table_grants` still shows `authenticated` on finance views | Lock finance boundary decision and pair DB changes with repo cleanup | Disable finance reads in app and ship revocation migration first |
| Payment state mismatch leaves partially advanced rows | `award_task_offer` / ledger / `pay_awarded_offer` | High | High | Data-loss | Award succeeds but pay path fails or task/request status changes after ledger rejection | Add state machine + reconciliation artifact before UI re-enable | Hard-disable award/pay and run forward-fix reconciliation |
| Wide profile summary contract breaks hidden callers when reduced | profile summary RPC callers | Med | Med | Feature | Runtime parsing failures or missing fields in non-dashboard surfaces | Use versioned/additive RPC unless caller scan proves safe shrink | Keep old RPC temporarily and migrate callers one by one |
| Dashboard refactor reintroduces dead management ownership | app layer | Med | Med | Feature | New VM/service files mention Manage-only state | Lock ownership matrix and remove Manage from target architecture | Keep facade thin and cut dead management code entirely |
| Wallet snapshot still loads stale zero state | overview tab + wallet VM | Med | Med | Feature | Overview shows zeros until wallet screen visited | Lock single wallet ownership contract and widget test it | Fallback to explicit overview-triggered wallet load |
| New tests flake because fixtures or payment seams are under-specified | widget/integration tests | High | Med | Delivery | Repeated timeouts or skipped tests on staging | Add `TEST_INFRA` and `FIXTURES` artifacts, preflight, and bounded waits | Keep release blocked and run manual signed scenarios while stabilizing |
| Docs remain stale after runtime fixes | docs sync | Med | Low | Team workflow | `SUPABASE_SETUP.md` and `DEVELOPER_GUIDE.md` disagree with code/live DB | Make docs-sync part of final gate | Patch docs in the last slice before merge |

## F) Pre-Mortem (How this fails in real life)

- This fails when app-layer refactor starts before live DB grants and RPC definitions are verified, and the team “fixes” code against stale repo intent.
- This fails when finance grants are revoked but hidden repository methods survive, and the first non-admin dashboard request starts failing at runtime instead of being removed deliberately.
- This fails when award/pay UI is left enabled while the live payment state machine still disagrees on `accepted/unpaid` vs `pending/unpaid`.
- This fails when `{ok:false}` is still treated as a normal payload somewhere outside `LedgerService`, and task/request state advances after a failed hold.
- This fails when `DashboardViewModel` is split without a state-ownership matrix, and wallet/cache/services state gets duplicated under new ViewModels.
- This fails when Manage debt is partially kept “just in case,” and the refactor spends time preserving a dead runtime path.
- This fails when dashboard tests are added without stable keys and fixture contracts, and the team gets a false sense of coverage from skipped or flaky runs.
- This fails when the release reaches docs sync without a slice checklist, and reviewers cannot prove whether live DB drift was actually resolved or merely assumed away.

## G) Plan Fixes (Concrete Additions / Expansions)

1. Add a dedicated test-infrastructure subphase.
- Goal: make dashboard QA deterministic before feature changes begin.
- Why: the current plan adds tests but not the prerequisites that make them reliable.
- How: create `TEST_INFRA`, `FIXTURES`, `dashboard_env.dart`, `dashboard_preflight.dart`, selector map, timeout budgets, and rerun policy.
- Output artifact: `.TODO/TEST_INFRA_Dashboard_2026-03-01.md`, `.TODO/FIXTURES_Dashboard_2026-03-01.md`, `integration_test/support/dashboard_env.dart`, `integration_test/support/dashboard_preflight.dart`
- Stop condition: every planned dashboard test has a documented owner, fixture source, selector, and timeout budget.

2. Add a delivery workflow gate.
- Goal: keep rollout reviewable and rollback-safe.
- Why: dashboard remediation is too broad for a single PR.
- How: define four `codex/` branch slices, review checklist, DoD per slice, and rollback points.
- Output artifact: `.TODO/REVIEW_CHECKLIST_Dashboard_2026-03-01.md`, `.TODO/RELEASE_CHECKLIST_Dashboard_2026-03-01.md`
- Stop condition: every slice has explicit go/no-go criteria and reviewer expectations.

3. Add a live-DB-truth decision gate.
- Goal: block unsafe DB work until reality is known.
- Why: the current plan records the auth block but does not operationalize it.
- How: require MCP re-auth or verified SQL export before Phase 1.1 onward.
- Output artifact: `.TODO/LIVE_SCAN_Dashboard_2026-03-01.md`
- Stop condition: touched live objects and grants are captured or Phase 1 stops.

4. Add a finance-boundary contract.
- Goal: remove ambiguity around finance view access.
- Why: grant changes without app cleanup, or app cleanup without grant changes, both leave risk.
- How: choose remove-vs-admin-RPC in Phase 0, then implement DB and app changes in paired phases.
- Output artifact: `.TODO/CONTRACT_Dashboard_Finance_Boundary_2026-03-01.md`
- Stop condition: non-admin dashboard runtime has zero direct finance-view access.

5. Add a transition/payment state-machine artifact.
- Goal: make workflow rules explicit before coding.
- Why: the current failures are contract failures, not only implementation failures.
- How: document task, booking, offer, and payment transitions including invalid states and reconciliation rules.
- Output artifact: `.TODO/STATE_MACHINE_Dashboard_2026-03-01.md`
- Stop condition: every transition path has one server owner, one failure rule, and one verification query/test.

6. Add a reconciliation and forward-fix artifact for payment drift.
- Goal: recover safely from partially advanced payment state.
- Why: money-path fixes need an explicit operational response, not just code changes.
- How: define verify queries, candidate row detection, safe forward-fix rules, and kill-switch triggers.
- Output artifact: `.TODO/RECONCILIATION_Dashboard_2026-03-01.md`
- Stop condition: the team can detect and repair inconsistent rows without improvisation.

7. Replace management split work with an ownership matrix.
- Goal: refactor only live runtime ownership, not dead code paths.
- Why: splitting a dead Manage runtime into new owners wastes risk budget.
- How: lock live owners for role, overview, bookings, work, inbox, wallet, services, and cache; remove Manage from target architecture.
- Output artifact: `.TODO/OWNERSHIP_Dashboard_2026-03-01.md`
- Stop condition: each live dashboard surface has one owner and dead Manage state is excluded.

8. Expand QA into a real release gate.
- Goal: prevent “done on paper” without proof.
- Why: the current QA phase is too generic for a money/authz-sensitive feature.
- How: add grant queries, negative SQL checks, widget/integration/manual matrix, privacy grep, artifact capture, and flake policy.
- Output artifact: `.TODO/RELEASE_CHECKLIST_Dashboard_2026-03-01.md`
- Stop condition: release checklist passes with attached evidence.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Preconditions & Control Gates
- Goal: lock the rollout design, test baseline, and stop/go rules before code changes.
- Why: current plan ambiguity is itself a failure mode.
- How:
  - `0.0` Test Infrastructure Gate: create selector map, fixture manifest, env/preflight files, timeout budgets, retry/flake policy, and failure artifact convention.
  - `0.1` Delivery Workflow Gate: define four `codex/` slices, reviewer checklist, DoD per slice, and rollback points.
  - `0.2` Spec Lock: make blocking decisions for live DB truth source, finance boundary, profile-summary strategy, payment kill-switch, and target ownership model.
  - `0.3` Threat Model: formalize abuse cases and observability needs.
  - `0.4` Contracts: create finance, transition, payment, profile-summary, and state-machine artifacts.
  - `0.5` Migration Plan: define introduce/backfill/enforce plus reconciliation and rollback rules.
  - `0.6` Kill Switch: define disabled award/pay, read-only fallback, and finance-hide behavior.
- Result: implementation starts only after decisions and prerequisites are frozen.
- GATE CHECK: test infra artifacts exist, slice plan exists, and blocking decisions are resolved.

### Phase 1: Data/Contracts
- Goal: verify live DB reality and define the exact server-side contract to implement.
- Why: dashboard cannot safely harden security or payment flows against unverified DB state.
- How:
  - `1.0` restore MCP auth or attach verified SQL export; capture live definitions/grants in `.TODO/LIVE_SCAN_Dashboard_2026-03-01.md`
  - `1.1` lock finance boundary and paired app cleanup
  - `1.2` lock task/booking transition RPC contract
  - `1.3` align award/pay/ledger state machine and define reconciliation output
  - `1.4` lock profile-summary rollout path
  - `1.5` prepare additive migrations and rollback migrations
- Result: the final server contract is known and migration-safe.
- GATE CHECK: live evidence exists, contract artifacts are complete, and no unresolved DB drift remains on touched objects.

### Phase 2: Security/RLS
- Goal: make authorization server-authoritative and prove least privilege.
- Why: client UX cannot be the source of truth for transitions or finance access.
- How:
  - `2.1` build an RLS/grant matrix for touched views, tables, and RPCs
  - `2.2` implement least-privilege grants and server-side transition checks
  - `2.3` run positive and negative SQL checks, including storage audit required by planner workflow
  - `2.4` execute additive introduce/backfill/enforce steps only after checks pass
- Result: the dashboard server boundary is enforceable and verified.
- GATE CHECK: non-admin finance reads fail, invalid transitions fail, and live verify queries match the contract.

### Phase 3: Backend/API
- Goal: centralize business logic and remove dangerous duplicate paths.
- Why: the current defects come from duplicated orchestration, raw updates, and oversized ownership.
- How:
  - `3.1` split dashboard data access by live responsibility and remove/quarantine finance reads
  - `3.2` add `tender_payment_coordinator.dart` and `tender_payment_view_model.dart`; make `{ok:false}` terminal
  - `3.3` split dashboard ownership into live surfaces only: role, overview, bookings, work, inbox; remove Manage from target architecture
  - `3.4` move `MyServices` ownership to services, and lock wallet/cache ownership
  - `3.5` add service/viewmodel observability with privacy-safe correlation
- Result: one owner per live concern and one orchestration path per payment flow.
- GATE CHECK: UI no longer creates services, duplicate award/pay logic is removed, and dead Manage ownership is gone.

### Phase 4: UI/Integration
- Goal: wire the shell to the new owners and expose safe user-facing behavior.
- Why: backend correctness is not enough if the UI still hides failures or keeps stale flows live.
- How:
  - `4.1` convert dashboard shell/tabs to bounded owners and narrow selectors
  - `4.2` lazy-load by active tab and remove hidden-tab fan-out
  - `4.3` move booking/offer/wallet widgets to owning features and share status presenters
  - `4.4` wire tender payment screen to the coordinator/view model and add explicit disabled/error/kill-switch states
  - `4.5` delete dead Manage files and unsupported TODO/no-op actions
- Result: dashboard behaves safely under normal, failed, and disabled states.
- GATE CHECK: live UI only reflects supported actions, and hidden/dead runtime paths are removed.

### Phase 5: Release/QA
- Goal: prove the feature is safe to merge and release.
- Why: dashboard remediation touches money, authorization, and navigation-critical flows.
- How:
  - `5.1` run unit/widget/integration tests using the new infra contracts
  - `5.2` run manual scenarios for award/pay success, award/pay failure, confirmed booking cancel, wallet snapshot first-entry load, and role switch
  - `5.3` run SQL/RLS/grant checks and privacy grep checks
  - `5.4` attach failure artifacts and apply one-rerun flake policy only after artifacts exist
  - `5.5` update docs and close the release checklist slice by slice
- Result: release evidence exists instead of assumptions.
- GATE CHECK: all slice DoD items pass, docs are synced, and live DB evidence is attached.

## I) Change Report (Diff-Style)

1. Original issues summary
- The original dashboard plan was directionally correct on DB hardening, app refactor, and docs sync, but it was not execution-safe.
- It lacked `Gate 0: Test Infrastructure Gate`.
- It did not convert the live DB auth block into a hard stop with an approved fallback.
- It did not lock blocking decisions for finance boundary, profile-summary rollout, or payment kill-switch behavior.
- It did not include delivery workflow controls: branch slicing, review checklist, DoD per PR, or artifact capture/flaking rules.

2. Added steps
- Added `Phase 0.0 Test Infrastructure Gate`
- Added `Phase 0.1 Delivery Workflow Gate`
- Added finance-boundary contract artifact
- Added state-machine artifact
- Added reconciliation/forward-fix artifact
- Added ownership matrix artifact
- Added release checklist artifact
- Added explicit kill-switch and disabled-flow behavior

3. Removed steps
- Removed the need to introduce a `dashboard_management_view_model` for a dead runtime path.
- Removed any implied option to proceed with DB-sensitive work from repo intent alone.

4. Reordered steps
- From: spec/threat/contracts/migration first, then generic QA
- To: test infra and workflow gates first, then live DB truth, then security/data contracts, then backend, then UI, then QA/release

5. Expanded steps
- QA expanded into selector map, fixture manifest, env contract, timeout budgets, artifact capture, and flake policy.
- Migration planning expanded into reconciliation and forward-fix for partial payment drift.
- Release planning expanded into four delivery slices with branch names, review checklist, and DoD.

6. Why
- The dashboard feature is not a normal UI cleanup. It touches grants, RLS, money movement, and cross-feature ownership. The plan must fail closed, not “move fast and verify later.”

7. Residual risks
- Live DB truth remains blocked until MCP auth or verified export exists.
- Payment integration automation may still require a controlled seam or staged manual verification if QiCard cannot be driven deterministically.
- Profile-summary caller parity remains partially unverified until the live scan confirms actual production/staging usage.
