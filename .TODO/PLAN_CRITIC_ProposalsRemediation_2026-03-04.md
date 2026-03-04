## A) Assumptions + Decision Needed (Blocking)

### Assumptions

- The target plan is `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md`, and the feature boundary remains the proposal runtime currently spread across `tasks`, `dashboard`, `work`, and the stub `proposals` folder. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:1-320`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/proposals/view/proposal_details_modal.dart:10-348`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`
- Existing test infrastructure should be extended, not replaced: widget harness in `test/test_support/pump_app.dart` and integration harness in `test/integration_test/support/`. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:1-18`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/helpers.dart:1-240`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/preflight.dart:1-57`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/pubspec.yaml:60-65`
- The repository standard for integration coverage is `test/integration_test/**`, not a top-level `integration_test/` root and not `supabase/tests/` as a primary existing runtime pattern. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/create_tender_task_flow_test.dart:1-106`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:202-205`
- Live Supabase remains the source of truth for proposal objects, but authenticated MCP access failed during planning, so live DB facts are still `UNVERIFIED` in this session. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:37-41`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:115-123`

### Decision Needed (Blocking)

1. Missing decision: what is the canonical cross-user profile contract for proposal reads.
- Options:
  - Narrow `rpc_get_profile_summaries` for all consumers.
  - Add a proposal-specific profile summary RPC with minimum fields.
  - Relax `profiles_select_self` and keep direct joins.
- Recommended: add a proposal-specific minimum-field RPC or a dedicated proposal read contract; do not relax `profiles_select_self`.
- Why: the current proposal plan already identifies the RLS conflict and over-broad profile payload, but it does not lock one implementation path before repository/model refactors start. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:45-48`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:130-140`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`
- What changes in the plan depending on the choice:
  - Narrow existing RPC: broader regression risk across non-proposal consumers.
  - Proposal-specific RPC: slightly more SQL work, but lowest blast radius.
  - Relax `profiles` policy: highest security risk and should be rejected unless threat modeling proves necessity.

2. Missing decision: what is the canonical source of `paymentDeadline` / awarded-unpaid resume state.
- Options:
  - Derive it server-side in awarded-unpaid RPC/view output.
  - Add a dedicated `task_requests` column and backfill it.
  - Keep synthetic client-side deadline calculation.
- Recommended: derive it server-side in the awarded-unpaid contract first, and only add a column if live scan proves derivation is impossible or unstable.
- Why: the current plan says “add an additive field or view contract” but never commits to one approach before model and route work. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:41-41`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:121-126`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/models/task_request_model.dart:10-39`
- What changes in the plan depending on the choice:
  - Server-derived contract: smallest app-side divergence and no fake deadlines.
  - New column: adds backfill, compatibility window, and migration risk.
  - Client synthesis: keeps the known bug and is invalid.

3. Missing decision: what happens if live Supabase MCP auth remains blocked.
- Options:
  - Block all proposal work until MCP auth is fixed.
  - Proceed with app/test-prep work, but block DB reconcile and release.
  - Trust docs and local migrations as DB truth.
- Recommended: proceed with app/test-prep work, but block DB reconcile and release until authenticated live scan completes.
- Why: the current plan mentions the auth blocker but does not turn it into an operational gate with allowed/disallowed work. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:38-38`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:115-119`
- What changes in the plan depending on the choice:
  - Block all work: safest, but unnecessarily stalls local app correctness work.
  - App/test-prep only: practical and still release-safe.
  - Trust docs: invalid under the planner workflow.

4. Missing decision: release slicing and branch strategy.
- Options:
  - One PR for SQL, app refactor, tests, and docs.
  - Two PRs: app/tests first, then SQL/docs.
  - Three PRs: infra/contracts/tests, app refactor/wiring, DB/docs/release gate.
- Recommended: three PRs.
- Why: the current plan spans security SQL, app refactor, route unification, test expansion, and docs drift, but it defines no review slices or per-slice done criteria. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:72-269`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/CODE_REVIEW.md:12-25`
- What changes in the plan depending on the choice:
  - One PR: highest rollback and review risk.
  - Two PRs: workable only if SQL shape stays minimal.
  - Three PRs: clearest gates, rollback points, and reviewer focus.

## B) Gate Status (Pass/Fail)

### Gate 0: Test Infrastructure Gate
- Status: ❌ FAIL
- Reason:
  - The current plan adds tests in Phase 4, but it has no dedicated test-infrastructure gate before contract and app work. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:208-236`
  - The repo already has reusable widget and integration harnesses, but the current plan does not bind proposal tests to them or document environment/secrets requirements. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/test_support/pump_app.dart:5-18`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/helpers.dart:23-240`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/preflight.dart:10-56`
  - Audited proposal surfaces expose almost no stable selectors; the only verified key in the proposal UI path is the favorite button on `RequestTile`. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-60`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/tender_payment_screen.dart:11-348`
- What to add/fix to pass:
  - Add `Phase 0.0 Test Infrastructure Gate`.
  - Create a selector/key map, fixture manifest, env/secrets doc, bounded wait policy, and failure artifact policy before writing proposal tests.

### Gate 1: Data/Contracts Gate
- Status: ❌ FAIL
- Reason:
  - The current plan creates a generic contract doc, but it does not lock a proposal lifecycle/state matrix before model/repository refactors start. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:91-100`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:155-160`
  - It does not decide the canonical resume payload source for `paymentDeadline`, task title, and owner/freelancer resume visibility before the app-layer rewrite. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:121-126`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:157-160`
  - The plan leaves the proposal profile contract undecided even though it is a direct blocker for owner-side list reads and repository structure. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:130-140`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`
- What to add/fix to pass:
  - Add a blocking state-matrix artifact and explicit decisions for profile contract and resume deadline source before Phase 1/2 work.

### Gate 2: Security Gate
- Status: ❌ FAIL
- Reason:
  - The current plan records the live Supabase auth blocker, but it does not turn it into a release-blocking live-access gate with a fallback working mode. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:115-119`
  - It calls for an RLS matrix, but it does not require exact verification queries or actor-by-actor expected outcomes before implementation begins. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:128-141`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:214-223`
  - Sensitive proposal actions involve money and authorization, but the plan does not explicitly require audit-log verification or server-side rejection evidence for spoofed actors. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:178-183`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`
- What to add/fix to pass:
  - Add a live-access gate, exact RLS verify queries, and server-action audit validation requirements.

### Gate 3: Backend/API Gate
- Status: ❌ FAIL
- Reason:
  - The current plan does not decide whether to narrow `rpc_get_profile_summaries` or add a proposal-specific RPC before app repository work starts. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:137-140`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:164-168`
  - It introduces an atomic finalize RPC, but it does not explicitly define how non-QiCard finalize, QiCard recovery, and existing dashboard/work resume readers converge on one backend contract. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:137-146`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/core/services/qicard_payment_service.dart:591-640`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/qicard_payment_recovery_tender/index.ts:20-139`
  - The current plan allows old wrappers, but it never defines a concrete deprecation cutoff for `TaskRequest`, `TaskRequestsService`, `payForAwardedOffer()`, or `acceptOffer()`. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:145-146`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:173-176`
- What to add/fix to pass:
  - Add explicit contract convergence steps and a deprecation cutoff checklist.

### Gate 4: UI/Integration Gate
- Status: ❌ FAIL
- Reason:
  - The current plan has no proposal UI state matrix for loading, empty, pending, replace-confirm, awarded-waiting-payment, payment-failed, forbidden, and unavailable-resume states. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:191-204`
  - It does not require stable selectors for the list, submit sheet, award CTA, payment resume launchers, or payment screen before widget/integration coverage. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/work_item_details_screen.dart:206-234`
  - It does not define one expected behavior when auto-open launch collides with validation failure or when a resume record is missing after award. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:205-217`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/viewmodels/dashboard_view_model.dart:615-647`
- What to add/fix to pass:
  - Add a UI state matrix artifact and bind selector coverage to each proposal surface.

### Gate 5: Release/QA Gate
- Status: ❌ FAIL
- Reason:
  - The current plan defines no PR slicing artifact, reviewer checklist, or definition of done per slice. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:72-269`
  - It does not include a final go/no-go release checklist tying together live DB verification, test suites, docs sync, and manual payment scenarios. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:240-269`
  - It does not define flake thresholds, failure artifact paths, or rerun policy for proposal integration work. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/test/integration_test/support/helpers.dart:78-127`
- What to add/fix to pass:
  - Add PR slicing, release checklist, flake policy, and failure artifact tagging before implementation begins.

## C) Critical Gaps (Must-Fix)

### Gap 1
- Gap: No Test Infrastructure Gate.
- Why it will break: proposal tests will be authored against unstable copy/layout and ad hoc seeded data, even though the repo already has reusable but environment-sensitive harnesses.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.0 Test Infrastructure Gate`.
  - Create `.TODO/TEST_INFRA_Proposals_2026-03-04.md`.
  - Create `.TODO/FIXTURES_Proposals_2026-03-04.md`.
- Owner: Frontend
- Acceptance check: selectors, fixture manifest, env requirements, timeout budgets, rerun policy, and failure artifact path all exist before new proposal tests are written.

### Gap 2
- Gap: No proposal lifecycle/state matrix.
- Why it will break: model/repository/UI work can drift on pending, replaced, rejected, awarded-waiting-payment, paid, and unavailable-resume states.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/STATE_MATRIX_Proposals_2026-03-04.md` in Phase 0 before contracts and model work.
- Owner: Backend
- Acceptance check: every proposal state and transition has one server contract, one UI render rule, and one test target.

### Gap 3
- Gap: Live Supabase auth blocker is not operationalized.
- Why it will break: the plan can silently proceed into DB assumptions or stall without a hard stop/go rule while MCP auth remains unavailable.
- Fix (exact step(s) to add / reorder):
  - Add `Phase 0.1 Live Access Gate`.
  - Explicitly allow app/test-prep work only; block DB reconcile and release until authenticated live scan succeeds.
- Owner: Backend
- Acceptance check: the revised plan contains a hard gate and a fallback working mode instead of a passive warning.

### Gap 4
- Gap: The profile-summary contract is undecided.
- Why it will break: repository and SQL work can diverge into incompatible approaches.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/DECISION_ProposalProfileContract_2026-03-04.md` before Phase 1 and Phase 2.
- Owner: Backend
- Acceptance check: one canonical proposal profile-read contract is chosen and reused in SQL, repository, UI, and tests.

### Gap 5
- Gap: The awarded-unpaid deadline/resume contract is undecided.
- Why it will break: route, model, dashboard, and payment screen rewrites can proceed against different payload assumptions.
- Fix (exact step(s) to add / reorder):
  - Add `.TODO/DECISION_ProposalPaymentDeadline_2026-03-04.md`.
  - Bind the result into `.TODO/CONTRACT_proposals_rpc_and_models_2026-03-04.md`.
- Owner: Backend
- Acceptance check: there is one server-derived resume payload contract for all launchers.

### Gap 6
- Gap: No PR slicing or release checklist.
- Why it will break: SQL security work, app refactor, test expansion, and docs can land in one hard-to-review batch with weak rollback.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/PR_PLAN_Proposals_2026-03-04.md`.
  - Create `.TODO/RELEASE_CHECKLIST_Proposals_2026-03-04.md`.
- Owner: Product
- Acceptance check: every slice has reviewers, done criteria, gates, and rollback points.

### Gap 7
- Gap: No explicit compatibility/deprecation cutoff.
- Why it will break: old `tasks`-path wrappers and deprecated proposal helpers can linger as parallel runtime surfaces.
- Fix (exact step(s) to add / reorder):
  - Create `.TODO/DEPRECATION_Proposals_2026-03-04.md`.
  - Add a checklist for `TaskRequest`, `TaskRequestsService`, `payForAwardedOffer()`, `accept()`, and dashboard `acceptOffer()`.
- Owner: Frontend
- Acceptance check: every compatibility wrapper has a removal owner, verification step, and cutoff gate.

## D) Invariants & Success Criteria (Non-Negotiable)

1. Invariant: proposal authorization is actor-bound on the server, not caller-supplied from the client.
- How to enforce: `SECURITY DEFINER` functions bind `auth.uid()` internally and reject spoofed actor IDs.
- How to verify: positive/negative SQL checks for owner, freelancer, unrelated user, and unauthenticated caller. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`

2. Invariant: the client never mutates `profiles.active_role` as part of proposal submit.
- How to enforce: remove the profile update from the proposal service and surface an explicit role-mode requirement in UI.
- How to verify: unit/widget/integration tests plus grep check. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:106-121`

3. Invariant: proposal payment finalization is atomic and idempotent.
- How to enforce: one server-owned finalize path wraps ledger + proposal/task state transition.
- How to verify: failure-path tests show no ledger-only success state. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_service.dart:749-799`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/functions/_shared/bookin_payment.ts:383-437`

4. Invariant: owner/freelancer proposal reads use one RLS-safe cross-user profile contract.
- How to enforce: proposal reads stop depending on direct `profiles` joins that conflict with `profiles_select_self`.
- How to verify: repo grep and live RLS checks. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/services/task_requests_service.dart:50-76`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`

5. Invariant: all proposal payment resume surfaces consume the same typed payload.
- How to enforce: one `ProposalPaymentSummary` model and one route helper feed Requests, Inbox, Work, Next Actions, and Work Details.
- How to verify: widget/integration tests across all launchers. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/requests_list_screen.dart:143-167`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/work_item_details_screen.dart:210-234`

6. Invariant: proposals have one active runtime home under `lib/features/proposals`, and views do not call services directly.
- How to enforce: move the active runtime into `lib/features/proposals` and remove direct `TaskRequestsService` access from the submit sheet.
- How to verify: import scan and architecture review. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-301`, `/Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/DEVELOPER_GUIDE.md:54-62`

7. Invariant: no DB-changing release proceeds without authenticated live Supabase confirmation.
- How to enforce: Live Access Gate blocks DB reconcile and release until MCP auth succeeds.
- How to verify: release checklist requires authenticated scan evidence.

## E) Risk Register (Predict Problems)

| Risk | Where | Probability | Impact | Blast radius | Early signal | Prevention | Fallback |
|------|-------|------------|--------|--------------|-------------|-----------|----------|
| MCP auth remains unavailable and DB truth stays unverified | Supabase live scan | High | High | Feature | repeated `Auth required` during MCP initialize | add hard Live Access Gate and separate app-prep from DB/release work | freeze DB reconcile/release and ship no DB-assumption changes |
| Proposal profile-read contract is changed in the wrong place | profile summary RPC / proposal repository | Med | High | Feature | owner proposal list loses names/avatars after SQL change | lock profile contract decision before SQL/app work | keep old caller path via compatibility adapter until new contract passes |
| New finalize RPC diverges from QiCard recovery behavior | finalize RPC + tender recovery function | Med | High | Feature | awarded-unpaid items get stuck or double-finalize after gateway return | define contract convergence and explicit recovery tests | revert app caller to previous path while keeping actor-binding fixes |
| Refactor leaves old `tasks` runtime and new `proposals` runtime both active | app imports / routes | High | Med | Feature | duplicate screens, stale providers, or dead helper methods remain compiled | add deprecation artifact and PR slicing | revert file moves only and keep secured SQL |
| Resume payload still carries fake deadline or wrong title | dashboard/work launchers | Med | Med | Feature | payment screen shows UUID title or 24h synthetic deadline | lock resume contract and add widget/integration assertions | temporarily hide deadline until server contract is ready |
| Proposal integration tests flake due missing seeded roles/data | `test/integration_test` | High | Med | Delivery | repeated timeout failures in login/award/pay scenarios | create fixture manifest, env docs, and bounded waits | keep release evidence to unit/widget/manual until fixtures are stable |
| Audit and docs drift persists after rollout | docs / release process | Med | Med | App-wide | roadmap or structure still claims stale proposal behavior | add docs-sync and release checklist gates | block release until docs are updated in same slice |

## F) Pre-Mortem (How this fails in real life)

- This fails when the team starts moving files into `lib/features/proposals` before deciding the proposal profile-read contract, and owner proposal lists break under tightened RLS.
- This fails when an atomic finalize RPC is added for non-QiCard, but QiCard recovery still writes the old shape and the awarded-unpaid queue splits into two incompatible paths.
- This fails when dashboard and work launchers are rewritten, but the deadline source is still synthetic in one path and server-derived in another.
- This fails when widget tests are added against visible text because the proposal UI still lacks stable keys, and the suite becomes brittle immediately after copy changes.
- This fails when the team “fixes” the live DB blocker by trusting docs and migrations without authenticated MCP verification.
- This fails when `TaskRequest` and `ProposalModel` both survive as active types and future fixes patch only one path.
- This fails when the old stub `ProposalDetailsModal` remains compiled and another engineer mistakes it for the real proposal surface.

## G) Plan Fixes (Concrete Additions / Expansions)

1. Goal: add a Test Infrastructure Gate.
- Why: the current plan schedules tests without stable selectors, fixtures, or bounded wait policy.
- How: create `TEST_INFRA_Proposals`, `FIXTURES_Proposals`, and a selector map before writing proposal tests.
- Output artifact: test infra doc, fixture manifest, selector map.
- Stop condition: all planned proposal tests reference stable selectors and documented preconditions.

2. Goal: lock the proposal lifecycle/state matrix before code moves.
- Why: current contract work is too generic for execution-safe model/UI changes.
- How: create `STATE_MATRIX_Proposals` and make it a blocker for Phase 1/2 work.
- Output artifact: state matrix doc.
- Stop condition: every lifecycle state has one server contract, one UI rule, and one test target.

3. Goal: operationalize the live DB auth blocker.
- Why: passive warnings are fake progress.
- How: add a Live Access Gate that explicitly separates app-safe work from DB/release-blocked work.
- Output artifact: live-access gate plus release checklist dependency.
- Stop condition: no DB reconcile or release step can proceed without authenticated scan evidence.

4. Goal: lock the proposal profile-read contract.
- Why: the plan currently allows conflicting SQL/app implementations.
- How: create `DECISION_ProposalProfileContract` and bind it into contract, SQL, repository, and tests.
- Output artifact: decision doc plus contract update.
- Stop condition: one profile-read approach is chosen and used everywhere.

5. Goal: lock the awarded-unpaid resume contract.
- Why: deadline/title/resume data cannot be left to per-screen interpretation.
- How: create `DECISION_ProposalPaymentDeadline` and update the shared model contract.
- Output artifact: decision doc plus updated contract.
- Stop condition: one server-derived resume payload exists for all launchers.

6. Goal: add PR slicing and release gating.
- Why: the remediation spans security SQL, app refactor, test infra, and docs.
- How: create `PR_PLAN_Proposals` and `RELEASE_CHECKLIST_Proposals`.
- Output artifact: PR plan and release checklist.
- Stop condition: each slice has reviewers, done criteria, rollback, and gate checks.

7. Goal: add an explicit deprecation cutoff.
- Why: compatibility wrappers without a removal plan become permanent drift.
- How: create `DEPRECATION_Proposals` covering old models, services, methods, and the stub modal.
- Output artifact: deprecation checklist.
- Stop condition: every compatibility path has a removal condition and verification step.

## H) Corrected Plan (Execution-Ready, Gate-Based)

### Phase 0: Test Infrastructure + Access + Contracts
- Goal: remove planning ambiguity before DB or app changes start.
- Why: the current plan has unresolved contract, data, and test-harness blockers.
- How:
  - Add `0.0 Test Infrastructure Gate` with selectors, fixtures, env docs, timeout budgets, rerun policy, and failure artifact path.
  - Add `0.1 Live Access Gate` with explicit “app/test-prep allowed, DB/release blocked” behavior while MCP auth is down.
  - Add blocking decision artifacts for profile-read contract and payment-deadline source.
  - Add `STATE_MATRIX_Proposals`, `CONTRACT_proposals_rpc_and_models`, `PR_PLAN_Proposals`, `RELEASE_CHECKLIST_Proposals`, and `DEPRECATION_Proposals`.
- Result: one executable contract set, one test baseline, one release strategy.
- GATE CHECK: live access status is explicit, selectors/fixtures exist, and profile/deadline decisions are locked.

### Phase 1: Data/Contracts + Security/RLS
- Goal: make proposal authorization, state transitions, and resume data server-authoritative.
- Why: the current flow still has spoofable actor IDs, over-broad profile reads, and synthetic deadlines.
- How:
  - Re-scan live Supabase with MCP.
  - Implement the chosen profile-read contract.
  - Patch proposal RPC auth to bind `auth.uid()` internally.
  - Add the chosen awarded-unpaid resume contract.
  - Define exact RLS verify queries and actor matrix.
  - Add audit-log validation for sensitive server actions.
- Result: secure, verified DB/API contracts with documented actor behavior.
- GATE CHECK: spoofed actor tests fail, allowed actor tests pass, and live scan evidence is attached.

### Phase 2: Backend APIs + App Layer
- Goal: move proposal logic into a single MVVM-compliant module without parallel active paths.
- Why: the current runtime is fragmented and still contains UI-to-service bypasses and deprecated helpers.
- How:
  - Create `ProposalModel`, `ProposalPaymentSummary`, `ProposalRepository`, `ProposalAwardRepository`, and DI-managed ViewModels.
  - Remove client-side role mutation.
  - Replace direct profile joins with the chosen contract.
  - Add the atomic finalize caller path and align QiCard recovery consumers.
  - Introduce compatibility exports only where required, then track their removal in the deprecation artifact.
- Result: one proposals module, one repository strategy, one finalize path.
- GATE CHECK: no UI layer talks to services directly, no duplicate active proposal data source remains, and compatibility wrappers are tracked.

### Phase 3: UI Wiring + State Matrix
- Goal: unify proposal screens and launchers behind one contract and one route helper.
- Why: current launchers, auto-open behavior, title/deadline handling, and favorite behavior are inconsistent.
- How:
  - Move active proposal UI under `lib/features/proposals`.
  - Add stable keys/selectors to list, submit, award, resume, and payment surfaces.
  - Wire all launchers through one `proposal_payment_route.dart`.
  - Implement the state matrix across loading, empty, pending, replace, awarded-waiting-payment, missing-resume, and error states.
  - Remove or tombstone the stub modal.
- Result: one consistent proposal UX across Requests, Inbox, Work, Next Actions, and Work Details.
- GATE CHECK: all launchers use the same route helper and all UI states match the matrix.

### Phase 4: QA + Regression + Release
- Goal: prove the remediation works under unit, widget, integration, and manual abuse checks before release.
- Why: the current plan does not define deterministic evidence or release criteria.
- How:
  - Add proposal unit tests, widget tests, and `test/integration_test/proposals/**` flows.
  - Use the selector map and fixture manifest.
  - Run exact RLS and contract verification queries.
  - Capture failure artifacts and enforce rerun budgets.
  - Execute the release checklist including docs sync and rollback verification.
- Result: bounded, reviewable evidence for correctness, security, and release safety.
- GATE CHECK: all release criteria pass, live DB is authenticated and verified, and docs are updated in the same slice.

## I) Change Report (Diff-Style)

1. Original issues summary
- The original plan identified the right defects, but it was still too loose on test infrastructure, live DB gating, contract decisions, deprecation cutoff, and release slicing. References: `/Users/eros/Dev/Eros_Projects/Sline/sline_app/.TODO/PLAN_ProposalsRemediation_2026-03-04.md:72-269`

2. Added steps
- Added `Phase 0.0 Test Infrastructure Gate`.
- Added `Phase 0.1 Live Access Gate`.
- Added decision artifacts for profile contract and payment deadline source.
- Added proposal state matrix, PR plan, release checklist, and deprecation checklist.
- Added explicit audit-log validation requirement.
- Added integration-test placement decision tied to existing `test/integration_test/**` harness.

3. Removed steps (if any)
- No implementation areas were removed.
- Ambiguous dual-home test destination (`supabase/tests` or `test/integration_test`) must be removed from the revised plan in favor of one canonical path.

4. Reordered steps (from → to)
- Test work moved from late Phase 4 only → Phase 0 Test Infrastructure Gate plus Phase 4 execution.
- Live Supabase confirmation moved from passive Phase 1 note → Phase 0 blocking gate plus Phase 1 execution.
- Contract decisions moved from implicit within Phase 1/2 → explicit blocking decisions before DB/app work.

5. Expanded steps (what became more detailed)
- Contract work expanded into separate profile-read, resume-deadline, and state-matrix artifacts.
- QA expanded into selectors, fixtures, env requirements, failure artifacts, and rerun policy.
- Compatibility handling expanded into an explicit deprecation artifact with cutoff conditions.

6. Why (short, practical)
- The original plan was directionally correct but not execution-safe. The added gates prevent fake progress, contract drift, brittle tests, and release without live DB truth.

7. Residual risks (what still remains risky even after fixes)
- MCP auth can still delay DB reconcile and release.
- The final profile-read contract choice still has cross-feature regression risk if the wrong option is chosen.
- Proposal/file-path refactors can still cause import churn until compatibility wrappers are fully removed.
