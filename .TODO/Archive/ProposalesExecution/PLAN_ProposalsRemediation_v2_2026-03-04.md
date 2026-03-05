# 📌 Plan: Proposals Remediation v2

## 1) Goal

- Goal:
  - Repair the proposals feature so authorization is server-owned, payment finalization is atomic, proposal reads are RLS-safe, runtime ownership is consolidated under `lib/features/proposals`, and release is blocked until live Supabase truth is verified. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/services/task_service.dart:513-920`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:1-230`
- Why:
  - The current runtime still trusts caller-supplied actor IDs in `SECURITY DEFINER` RPCs, mutates `profiles.active_role` from the client, splits non-QiCard finalize into two client-side steps, fragments proposal code across multiple features, and lacks proposal-specific test infrastructure and release gating. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`, `lib/features/tasks/services/task_requests_service.dart:106-121`, `lib/features/tasks/services/task_service.dart:749-799`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:61-173`
- Result:
  - One verified proposal contract, one secure backend path, one MVVM-compliant proposals module, one deterministic payment resume payload, one reviewable rollout sequence, and proposal coverage across unit/widget/integration/manual/security checks. References: `Sline_everything/DEVELOPER_GUIDE.md:41-68`, `Sline_everything/STRUCTURE.md:83-150`, `Sline_everything/CODE_REVIEW.md:12-25`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:174-230`

## 2) Scope

### In-Scope

- Proposal submit, replace, reject, award, resume-payment, cancel, and finalize-payment flows. References: `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`, `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/services/task_service.dart:513-920`
- Proposal launchers from task details, dashboard Inbox/Work/Next Actions, and work-item details. References: `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- Direct dependencies touched by proposal runtime:
  - `lib/features/profile/services/profile_summary_service.dart:13-33`
  - `lib/features/favorites/data/favorites_service.dart:52-66`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart:515-760`
  - `lib/features/work/services/work_management_service.dart:24-150`
  - `lib/core/services/payment_service.dart:309-325`
  - `lib/core/services/qicard_payment_service.dart:491-640`
  - `lib/main.dart:196-199`
- Proposal-related Supabase objects:
  - `task_requests`, `tasks`, `profiles`, `favorites`, `notifications`, `conversations`, `messages`, `vw_unified_work_items`
  - `replace_task_request`, `reject_task_request`, `award_task_offer`, `pay_awarded_offer`, `cancel_awarded_offer`, `get_client_awarded_unpaid_offers`, `get_freelancer_awarded_unpaid_offers`, `rpc_get_profile_summaries`, `process_payment_event_ledger`
  - `qicard_payment_create_tender`, `qicard_payment_recovery_tender`
  References: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`, `supabase/migrations/20260311000000_replace_task_request.sql:5-81`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-186`, `supabase/functions/qicard_payment_create_tender/index.ts:22-149`, `supabase/functions/qicard_payment_recovery_tender/index.ts:20-139`
- Test/runtime support that must be reused:
  - `test/test_support/pump_app.dart:5-18`
  - `test/integration_test/support/helpers.dart:19-240`
  - `test/integration_test/support/preflight.dart:10-56`
  - `pubspec.yaml:60-65`

### Out-of-Scope

- Booking-only runtime except where ledger or QiCard helpers are directly shared by proposal finalize or recovery. References: `lib/features/booking/services/booking_service.dart`, `lib/core/services/qicard_payment_service.dart:491-640`
- Direct-offer runtime and unrelated chat flows except where proposal RPCs produce shared notifications/messages. References: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`
- Proposal-specific storage or realtime changes unless authenticated live Supabase scan proves they exist. Current status: `UNVERIFIED`. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`

## 3) Evidence & Findings (From Scan)

### Existing

- Proposal runtime is currently fragmented outside `lib/features/proposals`, while the only file under `lib/features/proposals` is a mock modal. References: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- The documented architecture contract requires feature-local MVVM separation and forbids direct backend calls from views. References: `Sline_everything/DEVELOPER_GUIDE.md:54-62`, `Sline_everything/STRUCTURE.md:97-103`
- The current plan already captures the major proposal defects, but the critique found missing execution gates for test infra, live DB access, contract decisions, deprecation, and release slicing. References: `.TODO/PLAN_ProposalsRemediation_2026-03-04.md:72-269`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:61-230`
- Widget and integration harnesses already exist and are reusable. References: `test/test_support/pump_app.dart:5-18`, `test/integration_test/support/helpers.dart:19-240`, `test/integration_test/support/preflight.dart:10-56`

### Missing

- Authenticated live Supabase scan evidence for proposal tables/views/RPCs/policies/indexes/buckets/realtime remains missing in this session. Status: `UNVERIFIED`. References: `.TODO/PLAN_ProposalsRemediation_2026-03-04.md:37-41`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:1-24`
- Proposal-specific test infrastructure artifacts are missing: selector map, fixture manifest, env/secrets injection doc, failure artifact policy, and rerun thresholds. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:61-73`, `test/integration_test/support/helpers.dart:78-127`, `test/integration_test/support/preflight.dart:10-56`
- The proposal lifecycle/state matrix, profile-read decision, payment-deadline decision, PR plan, release checklist, and deprecation checklist are not yet present. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:74-173`

### Must NOT Duplicate

- Must not leave both `TaskRequestsService` and a new proposal repository as active proposal data sources. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:15-21`
- Must not leave both old `tasks`-path UI/runtime and new `proposals`-path UI/runtime active after migration. References: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `Sline_everything/CODE_REVIEW.md:12-25`
- Must not create a second overlapping cross-user profile strategy without an explicit contract decision. References: `lib/features/profile/services/profile_summary_service.dart:13-33`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:9-18`
- Must not invent DB truth while MCP auth is blocked. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:19-24`, `.TODO/PLAN_ProposalsRemediation_2026-03-04.md:115-119`

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Roadmap/docs claim tender payment is completed and submit no longer mutates `active_role`, but current code still performs that mutation. References: `Sline_everything/MVP_ROADMAP.md:45-49`, `lib/features/tasks/services/task_requests_service.dart:106-121`
- The repo standard for integration tests is `test/integration_test/**`, but the previous plan left the proposal SQL/integration test home ambiguous. References: `test/integration_test/create_tender_task_flow_test.dart:1-106`, `.TODO/PLAN_ProposalsRemediation_2026-03-04.md:202-205`
- The live DB blocker is real and must become a release gate, not just a note. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:99-107`

## 4) System Impact Map

- UI:
  - Task-details proposal CTA
  - submit sheet
  - proposal list
  - request tile
  - dashboard Inbox/Work/Next Actions resume surfaces
  - work-item-details resume surface
  - proposal payment screen
  - stub proposal modal
  References: `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`, `lib/features/work/view/work_item_details_screen.dart:206-234`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- MVVM/App Logic:
  - `TaskRequest` model
  - proposal repository/service split
  - proposal/payment ViewModels
  - DI wiring
  - deprecated compatibility methods
  References: `lib/features/tasks/models/task_request_model.dart:8-202`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`, `lib/features/tasks/viewmodels/tender_payment_view_model.dart:5-202`, `lib/main.dart:196-199`
- Database:
  - proposal tables/views/RPCs and finalize contract
  References: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-186`
- RLS/Security:
  - actor-bound RPC auth
  - `profiles_select_self`
  - proposal profile summary scope
  - role mutation removal
  References: `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`, `lib/features/tasks/services/task_requests_service.dart:106-121`
- Realtime/Notifications (if any):
  - notifications remain server-generated
  - proposal-specific realtime remains `UNVERIFIED`
  References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:78-104`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:63-77`
- Storage:
  - none verified locally for proposals; live status `UNVERIFIED`
- Observability (if any):
  - proposal submit, award, resume, finalize, and auth rejection need correlation-safe instrumentation in services/ViewModels/server actions
  References: `lib/features/tasks/services/task_service.dart:749-799`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:146-156`
- Compatibility & Migration:
  - additive-first SQL
  - compatibility exports during path moves
  - explicit deprecation cutoff
  References: `Sline_everything/CODE_REVIEW.md:20-25`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:122-132`
- Contracts:
  - proposal state matrix
  - profile-read contract
  - awarded-unpaid resume contract
  - finalize contract
  - test harness contract
  References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:74-173`

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.0 Test Infrastructure Gate

- Goal:
  - Establish deterministic proposal test infrastructure before any new proposal tests are written.
- Why:
  - Proposal runtime currently lacks stable selectors and explicit fixture/env policy, while the repo already has reusable but staging-sensitive test harnesses. References: `test/integration_test/support/helpers.dart:23-240`, `test/integration_test/support/preflight.dart:10-56`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:61-73`
- How:
  - [ ] (@Sentinel) Create `.TODO/TEST_INFRA_Proposals_2026-03-04.md` documenting:
    - widget harness usage via `test/test_support/pump_app.dart`
    - integration harness usage via `test/integration_test/support/helpers.dart`
    - timeout budgets
    - rerun policy
    - failure artifact path/tagging convention
  - [ ] (@Pixel) Create a selector/key map in `.TODO/TEST_INFRA_Proposals_2026-03-04.md` and then implement selectors in:
    - `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
    - `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart`
    - `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`
    - `lib/features/dashboard/view/tabs/inbox_tab.dart`
    - `lib/features/dashboard/view/tabs/work_tab.dart`
    - `lib/features/dashboard/view/widgets/next_actions_list.dart`
    - `lib/features/work/view/work_item_details_screen.dart`
    - `lib/features/tasks/view/tender_payment_screen.dart` or its moved replacement
  - [ ] (@Sentinel) Create `.TODO/FIXTURES_Proposals_2026-03-04.md` with deterministic requirements for:
    - client owner account
    - freelancer account
    - unrelated authenticated account
    - one open tender without proposals
    - one tender with pending proposal
    - one awarded-unpaid proposal
    - one proposal with replace flow
    - one rejected proposal for negative UI assertions
    - cleanup/reset steps
- Result:
  - One stable proposal test baseline.
- **Verify (@Sentinel):** selector map, fixture manifest, env/secrets doc, timeout budgets, rerun policy, and failure artifact path all exist before proposal tests are authored.

### 0.1 Live Access Gate

- Goal:
  - Turn the live Supabase auth blocker into an operational gate.
- Why:
  - The prior plan noted the blocker but did not define allowed/disallowed work while it remains unresolved. References: `.TODO/PLAN_ProposalsRemediation_2026-03-04.md:115-119`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:99-107`
- How:
  - [ ] (@Supabase_Ops) Retry authenticated `@mcp:supabase-mcp-server:` access and capture evidence for:
    - `task_requests`
    - `tasks`
    - `profiles`
    - `favorites`
    - `notifications`
    - `vw_unified_work_items`
    - proposal/payment RPCs
    - relevant indexes
    - buckets/realtime if any
  - [ ] (@Supabase_Ops) If auth remains blocked, create `.TODO/DB_PROVENANCE_Proposals_2026-03-04.md` and mark the plan as:
    - app/test-prep work allowed
    - DB reconcile blocked
    - release blocked
  - [ ] (@Sentinel) Create `.TODO/RELEASE_CHECKLIST_Proposals_2026-03-04.md` and add live-access success as a hard go/no-go gate.
- Result:
  - No hidden DB assumptions.
- **Verify (@Sentinel):** either authenticated scan evidence exists, or DB reconcile/release are explicitly blocked.

### 0.2 Spec Lock

- Goal:
  - Freeze product/UX/architecture decisions that would otherwise cause contract drift.
- Why:
  - The critique identified unresolved decisions for profile scope, payment deadline source, and release slicing. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:1-60`
- How:
  - [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_proposals_2026-03-04.md` covering:
    - actor spoofing
    - cross-user profile reads
    - partial finalize
    - role-side-effect abuse
    - self-favorite misuse
    - replay/idempotency
  - [ ] (@APIContract) Create `.TODO/DECISION_ProposalProfileContract_2026-03-04.md` and lock one cross-user profile strategy.
  - [ ] (@APIContract) Create `.TODO/DECISION_ProposalPaymentDeadline_2026-03-04.md` and lock one server-derived resume deadline strategy.
  - [ ] (@Pixel) Create `.TODO/UI_STATE_MATRIX_Proposals_2026-03-04.md` covering:
    - loading
    - empty
    - pending submit
    - pending replace
    - rejected
    - awarded-waiting-payment
    - missing resume record
    - payment failed/retry
    - forbidden/role mismatch
    - unavailable launcher
  - [ ] (@Sentinel) Create `.TODO/DONE_CRITERIA_Proposals_2026-03-04.md`.
- Result:
  - One locked proposal spec.
- **Verify (@Sentinel):** threat model, decisions, state matrix, and done criteria exist before Phase 1 or 2 implementation.

### 0.3 Contracts

- Goal:
  - Convert the proposal remediation into explicit typed contracts.
- Why:
  - The original plan’s contract step was too generic for safe execution. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:74-98`
- How:
  - [ ] (@APIContract) Create `.TODO/CONTRACT_proposals_rpc_and_models_2026-03-04.md` defining:
    - proposal model
    - proposal payment summary model
    - awarded-unpaid resume payload
    - profile summary fields allowed for proposal surfaces
    - error taxonomy
    - actor matrix by operation
  - [ ] (@APIContract) Create `.TODO/STATE_MATRIX_Proposals_2026-03-04.md` with transition rules for submit, replace, reject, award, pay, cancel, and resume.
  - [ ] (@Sentinel) Lock canonical test destination to `test/integration_test/proposals/` for proposal runtime scenarios; keep SQL verification steps in `.TODO/RLS_MATRIX_Proposals_2026-03-04.md`.
- Result:
  - One typed, testable proposal contract set.
- **Verify (@Sentinel):** no later phase introduces contract ambiguity around profile scope, deadline source, or test home.

### 0.4 Migration / Provenance Plan

- Goal:
  - Keep DB changes additive-first and provenance-safe.
- Why:
  - Live DB truth is not yet authenticated, and the proposal fix requires secure SQL changes. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:99-107`
- How:
  - [ ] (@DataMigration) Create `.TODO/MIGRATION_Proposals_2026-03-04.md` with introduce/backfill/enforce/cleanup sequencing.
  - [ ] (@DataMigration) Reserve migration slots:
    - `supabase/migrations/20260304060000_secure_proposal_rpc_contract.sql`
    - `supabase/migrations/20260304061000_proposal_profile_summary_contract.sql`
    - `supabase/migrations/20260304062000_finalize_awarded_offer_payment.sql`
    - a deadline/resume contract migration only if Phase 1 live scan proves it is required
  - [ ] (@DataMigration) Document forward-only reconcile rules in `.TODO/DB_PROVENANCE_Proposals_2026-03-04.md`.
- Result:
  - Safe migration sequencing.
- **Verify (@Sentinel):** no drops/renames in first rollout, no fake DB truth, and compatibility window is measurable.

### 0.5 Delivery Slicing / Workflow

- Goal:
  - Make the remediation reviewable and rollback-safe.
- Why:
  - The original plan had no PR slicing or per-slice done criteria. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:122-132`
- How:
  - [ ] (@Architect) Create `.TODO/PR_PLAN_Proposals_2026-03-04.md` with 3 slices:
    - PR1: contracts + test infrastructure + selectors + state matrix artifacts
    - PR2: app/runtime refactor + unit/widget tests + compatibility exports
    - PR3: DB reconcile (if needed) + integration/manual/security checks + docs sync + release gate
  - [ ] (@Sentinel) Add reviewer checklist and definition of done per PR.
  - [ ] (@SlineDocs) Add docs-sync requirements to PR3 and release checklist.
- Result:
  - One reviewable rollout structure.
- **Verify (@Sentinel):** each slice has owners, reviewers, acceptance, rollback point, and stop condition.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- Goal:
  - Confirm live DB reality for every proposal object touched by the fix.
- Why:
  - Docs and repo migrations are intent; live DB is reality. References: `Sline_everything/SUPABASE_SETUP.md:1-10`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:19-24`
- How:
  - [ ] (@Supabase_Ops) Re-scan via MCP for touched tables, views, RPCs, triggers, indexes, buckets, and realtime state.
  - [ ] (@Supabase_Ops) Record drift vs:
    - `Sline_everything/SUPABASE_SETUP.md`
    - repo migrations
    - current app assumptions
  - [ ] (@Sentinel) Block all DB-changing work if live scan remains unavailable.
- Result:
  - Authenticated DB baseline.
- **Verify (@Sentinel):** drift report exists and DB work is either cleared or blocked.

### 1.1 Data Contracts & Resume Source

- Goal:
  - Implement the chosen profile-read and resume-deadline contract.
- Why:
  - Both are blocking contract decisions for repository and UI work. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:9-18`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:19-28`
- How:
  - [ ] (@Supabase_Ops) Implement the chosen minimum-field proposal profile contract.
  - [ ] (@Supabase_Ops) Implement the chosen server-derived awarded-unpaid deadline/title/source contract.
  - [ ] (@APIContract) Update `.TODO/CONTRACT_proposals_rpc_and_models_2026-03-04.md` after live SQL decisions are final.
- Result:
  - Stable read contracts for owner/freelancer/resume paths.
- **Verify (@Sentinel):** one read contract exists, and the UI no longer depends on direct `profiles` joins or synthetic deadlines.

### 1.2 RLS

- Goal:
  - Restore least-privilege proposal reads and writes.
- Why:
  - Current owner-side profile joins conflict with `profiles_select_self`, and sensitive proposal actions need actor-specific verification. References: `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:84-98`
- How:
  - [ ] (@Supabase_Ops) Create `.TODO/RLS_MATRIX_Proposals_2026-03-04.md` covering:
    - owner allowed
    - freelancer allowed
    - unrelated authenticated denied
    - unauthenticated denied
    - profile summary allowed only via chosen contract
  - [ ] (@ThreatModeler) Add explicit negative checks for spoofed actor IDs and cross-user profile reads.
  - [ ] (@Sentinel) Bind exact SQL verify queries and expected results into the matrix.
- Result:
  - One testable RLS contract.
- **Verify (@Sentinel):** positive passes and forbidden reads/writes fail under the matrix.

### 1.3 RPC / Finalize / Audit

- Goal:
  - Make proposal mutations secure, atomic, and auditable.
- Why:
  - Current proposal RPCs are spoofable, and non-QiCard finalize is split client-side. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `lib/features/tasks/services/task_service.dart:749-799`
- How:
  - [ ] (@Supabase_Ops) Patch:
    - `award_task_offer`
    - `pay_awarded_offer`
    - `cancel_awarded_offer`
    - `get_client_awarded_unpaid_offers`
    - `get_freelancer_awarded_unpaid_offers`
    so auth binds to `auth.uid()` inside the function body.
  - [ ] (@Supabase_Ops) Introduce the atomic finalize RPC for non-QiCard payment.
  - [ ] (@Supabase_Ops) Align QiCard recovery consumers to the same final server contract.
  - [ ] (@Observability) Define audit/event expectations for:
    - award start
    - finalize success
    - finalize failure
    - auth rejection
    - cancel by owner
- Result:
  - Secure and converged proposal mutation backend.
- **Verify (@Sentinel):** spoofed actors fail, finalize is atomic/idempotent, and audit evidence exists for sensitive paths.

### 1.4 Migration Execution (If needed)

- Goal:
  - Apply secure proposal DB changes safely.
- Why:
  - Proposal fixes must not break older app builds or require destructive rollout.
- How:
  - [ ] (@DataMigration) Apply introduce migrations first on staging.
  - [ ] (@DataMigration) Backfill only if the chosen deadline/resume strategy requires it.
  - [ ] (@DataMigration) Keep compatibility wrappers until app callers are switched and verified.
- Result:
  - Safe DB rollout path.
- **Verify (@Sentinel):** post-migration queries pass, compatibility window holds, and cleanup is deferred until later release.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- Goal:
  - Replace ambiguous proposal data shapes with typed proposal contracts.
- Why:
  - Current runtime still centers on `TaskRequest` and ad hoc resume arguments. References: `lib/features/tasks/models/task_request_model.dart:8-202`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:74-98`
- How:
  - [ ] (@Architect) Create:
    - `lib/features/proposals/models/proposal_model.dart`
    - `lib/features/proposals/models/proposal_payment_summary.dart`
  - [ ] (@APIContract) Map legacy `TaskRequest` fields into the new contract with explicit nullability and capability fields.
  - [ ] (@Architect) Add domain error mapping for submit/replace/reject/award/finalize/resume failure outcomes.
- Result:
  - Typed proposal app contracts.
- **Verify (@Sentinel):** model nullability and route payloads match the locked contract and no screen fabricates missing server state.

### 2.2 Services/Repositories

- Goal:
  - Consolidate proposal backend access into one app-layer module.
- Why:
  - Current proposal logic is split between `TaskRequestsService` and `TaskService`, with a UI bypass in the submit sheet. References: `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/services/task_service.dart:513-920`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-301`
- How:
  - [ ] (@Architect) Move `TaskRequestsService` responsibilities into `lib/features/proposals/data/proposal_repository.dart`.
  - [ ] (@Architect) Extract award/payment logic into `lib/features/proposals/data/proposal_award_repository.dart`.
  - [ ] (@Architect) Remove client-side `active_role` mutation.
  - [ ] (@Architect) Replace direct profile joins with the chosen proposal profile contract.
  - [ ] (@Architect) Keep all Supabase calls inside repository/service layers only.
- Result:
  - One proposal data layer.
- **Verify (@Sentinel):** no UI-to-service bypass remains and no duplicate active proposal data path survives.

### 2.3 ViewModels & DI

- Goal:
  - Make proposals a DI-managed single source of truth.
- Why:
  - Current ViewModel constructs its own services and still carries deprecated one-step methods. References: `lib/features/tasks/viewmodels/task_requests_view_model.dart:15-21`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:147-191`
- How:
  - [ ] (@Architect) Create:
    - `lib/features/proposals/viewmodels/proposals_view_model.dart`
    - `lib/features/proposals/viewmodels/proposal_payment_view_model.dart`
  - [ ] (@Architect) Inject dependencies from `main.dart` rather than creating them in constructors.
  - [ ] (@Architect) Remove or tombstone:
    - `payForAwardedOffer()`
    - legacy `accept()`
    - dashboard `acceptOffer()`
    - unused awarded-unpaid getters
    only after replacement paths are live.
- Result:
  - One DI-managed proposal ViewModel layer.
- **Verify (@Sentinel):** state is single-sourced, dependencies are injected, and deprecated methods are tracked in the deprecation checklist.

### 2.4 Compatibility / Deprecation

- Goal:
  - Prevent old proposal runtime paths from lingering indefinitely.
- Why:
  - The critique identified no explicit removal cutoff in the previous plan. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:122-132`
- How:
  - [ ] (@Architect) Create `.TODO/DEPRECATION_Proposals_2026-03-04.md` covering:
    - `TaskRequest`
    - `TaskRequestsService`
    - old `tasks` path exports
    - `ProposalDetailsModal`
    - deprecated ViewModel methods
  - [ ] (@Sentinel) Add one verification check per deprecated path.
- Result:
  - Controlled compatibility window.
- **Verify (@Sentinel):** every compatibility wrapper has an owner, stop condition, and removal gate.

### 2.5 Observability

- Goal:
  - Add privacy-safe, rollout-useful proposal telemetry.
- Why:
  - Proposal remediation touches security and payment flows; silent regressions are not acceptable. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:146-156`
- How:
  - [ ] (@Observability) Create `.TODO/OBSERVABILITY_Proposals_2026-03-04.md`.
  - [ ] (@Architect) Instrument repositories/ViewModels/server hooks only, not UI widgets.
  - [ ] (@ThreatModeler) Validate no PII, profile oversharing, or payment payload leakage enters logs.
- Result:
  - Actionable proposal telemetry.
- **Verify (@Sentinel):** telemetry supports rollout decisions without leaking sensitive data.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Selector & Route Wiring

- Goal:
  - Make proposal UI testable and route-consistent.
- Why:
  - Current proposal surfaces have insufficient selector coverage and duplicate launcher construction. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:61-73`, `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:108-119`
- How:
  - [ ] (@Pixel) Implement the selector map from `TEST_INFRA_Proposals`.
  - [ ] (@Architect) Create `lib/features/proposals/routes/proposal_payment_route.dart`.
  - [ ] (@Pixel) Route Requests, Inbox, Work, Next Actions, and Work Details through the shared route helper.
- Result:
  - Testable and unified proposal launchers.
- **Verify (@Sentinel):** every launcher has stable selectors and uses the same route helper.

### 3.2 Proposals Module UI

- Goal:
  - Move the active proposal runtime into the real proposals feature.
- Why:
  - The current `proposals` feature folder is a stub and violates the documented feature boundary. References: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `Sline_everything/STRUCTURE.md:97-103`
- How:
  - [ ] (@Pixel) Move/create:
    - `lib/features/proposals/view/proposals_list_screen.dart`
    - `lib/features/proposals/view/widgets/submit_proposal_sheet.dart`
    - `lib/features/proposals/view/widgets/proposal_tile.dart`
    - `lib/features/proposals/view/proposal_payment_screen.dart`
  - [ ] (@Pixel) Remove or tombstone `ProposalDetailsModal` after proving no call sites remain.
  - [ ] (@Pixel) Keep all user-facing strings in English and standardize terminology.
- Result:
  - One cohesive proposals UI module.
- **Verify (@Sentinel):** the active runtime lives under `lib/features/proposals` and old task-path UI is compatibility-only or removed.

### 3.3 State Matrix Wiring

- Goal:
  - Make every proposal UI surface follow the same state rules.
- Why:
  - The critique found no explicit UI state matrix in the previous plan. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:108-119`
- How:
  - [ ] (@Pixel) Implement `UI_STATE_MATRIX_Proposals` across:
    - list loading/empty/error
    - submit pending
    - replace confirm
    - award success/failure
    - awarded-waiting-payment
    - missing resume payload
    - finalize retry
    - role mismatch
  - [ ] (@Pixel) Fix verified correctness bugs:
    - auto-open from `build()`
    - UUID task title in payment
    - fake Inbox deadline
    - non-owner favorite mis-scope
- Result:
  - Consistent proposal UX states across surfaces.
- **Verify (@Sentinel):** every state in the matrix has one visible behavior and one test target.

### 3.4 Polish (Optional)

- Goal:
  - Add only low-risk polish after correctness is stable.
- Why:
  - Proposal remediation is security/correctness-first.
- How:
  - [ ] (@Pixel) Standardize copy and disabled states only.
  - [ ] (@Pixel) Avoid large layout churn or animation changes in this release.
- Result:
  - Stable final UX.
- **Verify (@Sentinel):** no performance or navigation regressions appear in rebuild-heavy flows.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.0 Test Execution Foundation

- Goal:
  - Bind proposal tests to the approved harness, fixtures, and selector map.
- Why:
  - Proposal testing is only valid if it uses the defined test infrastructure gate.
- How:
  - [ ] (@Sentinel) Confirm `TEST_INFRA_Proposals`, `FIXTURES_Proposals`, selector map, env docs, and rerun policy are complete before proposal tests are added.
- Result:
  - Deterministic proposal test execution baseline.
- **Verify (@Sentinel):** test authors can run proposal suites without hidden setup assumptions.

### 4.1 Unit / Widget Suites

- Goal:
  - Cover proposal runtime logic and UI transitions directly.
- Why:
  - Existing coverage only touches `TaskRequest` mapping and tender payment coordinator/screen. References: `test/unit/models/task_request_model_test.dart:24-105`, `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`, `test/widget/tasks/tender_payment_screen_test.dart:10-51`
- How:
  - [ ] (@Sentinel) Add:
    - `test/unit/proposals/proposal_model_test.dart`
    - `test/unit/proposals/proposal_repository_test.dart`
    - `test/unit/proposals/proposal_award_repository_test.dart`
    - `test/unit/proposals/proposals_view_model_test.dart`
    - `test/unit/proposals/proposal_payment_view_model_test.dart`
  - [ ] (@Sentinel) Add:
    - `test/widget/proposals/proposals_list_screen_test.dart`
    - `test/widget/proposals/submit_proposal_sheet_test.dart`
    - `test/widget/proposals/proposal_payment_screen_test.dart`
    - widget tests for Requests/Inbox/Work route helper surfaces if needed
- Result:
  - Direct proposal unit/widget coverage.
- **Verify (@Sentinel):** submit, replace, reject, award, resume, finalize failure, and state-matrix paths are covered deterministically.

### 4.2 Integration / Manual / SQL

- Goal:
  - Validate proposal flow end-to-end with real app wiring and SQL actor checks.
- Why:
  - Proposal remediation spans app routes, payment resume, and server auth.
- How:
  - [ ] (@Sentinel) Add proposal runtime integration scenarios under `test/integration_test/proposals/`.
  - [ ] (@Sentinel) Add SQL verification steps to `.TODO/RLS_MATRIX_Proposals_2026-03-04.md`.
  - [ ] (@Sentinel) Run manual E2E scripts for:
    - freelancer submit/replace
    - owner reject/award
    - client resume from Requests/Inbox/Work/Next Actions/Work Details
    - non-QiCard finalize
    - QiCard recovery
- Result:
  - End-to-end proposal evidence.
- **Verify (@Sentinel):** route, resume, finalize, and actor checks all pass with seeded roles and bounded waits.

### 4.3 Security / Abuse / Flake Control

- Goal:
  - Prove the proposal fix resists abuse and has bounded test flakiness.
- Why:
  - This feature handles auth and payment-sensitive mutations.
- How:
  - [ ] (@Sentinel) Execute the ThreatModeler negative matrix.
  - [ ] (@Sentinel) Validate failure artifact capture and rerun budget from `TEST_INFRA_Proposals`.
  - [ ] (@Observability) Confirm rollout telemetry exists for finalize/auth regressions.
- Result:
  - Security evidence and controlled test flake policy.
- **Verify (@Sentinel):** unauthorized access fails, no sensitive logs leak, and failed tests emit actionable artifacts.

### 4.4 Release Evidence

- Goal:
  - Make release go/no-go objective.
- Why:
  - The prior plan had no final release gate artifact.
- How:
  - [ ] (@Sentinel) Complete `.TODO/RELEASE_CHECKLIST_Proposals_2026-03-04.md`.
  - [ ] (@Sentinel) Require:
    - authenticated live DB scan evidence
    - passing analyze/tests
    - passing SQL checks
    - passing manual scenarios
    - docs sync
    - rollback validation
- Result:
  - One objective release gate.
- **Verify (@Sentinel):** release is blocked until every checklist item is satisfied.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- Goal:
  - Align docs with final proposal runtime and verified DB truth.
- Why:
  - Current docs/roadmap already drift on `active_role` mutation and proposal module ownership. References: `Sline_everything/MVP_ROADMAP.md:45-49`, `Sline_everything/STRUCTURE.md:97-103`
- How:
  - [ ] (@SlineDocs) Update:
    - `Sline_everything/DEVELOPER_GUIDE.md`
    - `Sline_everything/SUPABASE_SETUP.md`
    - `Sline_everything/MVP_ROADMAP.md`
    - `Sline_everything/STRUCTURE.md`
    - `Sline_everything/Sline_Log.md`
  - [ ] (@SlineDocs) Add or update a proposal deep-dive under `Sline_everything/DEVELOPER_GUIDE/`.
- Result:
  - Proposal docs match code and live DB reality.
- **Verify (@Sentinel):** docs reflect the final implementation and release state, not historical intent.

## 7) Acceptance Criteria (MANDATORY)

- Proposal RPC authorization is bound to `auth.uid()` inside function bodies, and spoofed actor IDs cannot change read or mutation outcomes. References: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`
- Proposal submit no longer mutates `profiles.active_role` from the client. References: `lib/features/tasks/services/task_requests_service.dart:106-121`
- Non-QiCard proposal finalization is atomic and idempotent, and QiCard recovery converges on the same final server contract. References: `lib/features/tasks/services/task_service.dart:749-799`, `supabase/functions/qicard_payment_recovery_tender/index.ts:20-139`
- Owner/freelancer proposal reads use the chosen minimum-field contract and do not depend on forbidden direct `profiles` joins. References: `lib/features/tasks/services/task_requests_service.dart:50-76`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`
- Every proposal payment resume surface uses the same typed payload and route helper, showing the real task title and a server-derived deadline. References: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:143-167`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `lib/features/work/view/work_item_details_screen.dart:210-234`
- Proposal runtime lives under `lib/features/proposals`, and no stub-only or duplicate active proposal surface remains. References: `Sline_everything/STRUCTURE.md:97-103`, `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- Proposal test infrastructure artifacts exist, and proposal unit/widget/integration/manual/security evidence passes the release gate. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:61-173`
- No DB-changing release proceeds without authenticated live Supabase verification. References: `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:19-24`
- Docs match final code and verified DB reality. References: `Sline_everything/CODE_REVIEW.md:20-25`

## 8) Rollback Plan

- DB rollback / forward-fix:
  - If secure proposal RPC or finalize rollout fails before app cutover, revert or forward-fix only the newest additive proposal migrations.
  - If the app is already on the new contract, prefer forward-fix wrappers that preserve actor-bound auth rather than restoring spoofable behavior.
  - Do not run cleanup/deletion migrations until the compatibility window closes.
- App rollback:
  - Keep compatibility exports at old `tasks` paths until `proposals` imports are fully switched and verified.
  - If file moves regress navigation, roll back the app refactor slice while keeping secured SQL in place.
- Release rollback:
  - If authenticated live scan never completes, no DB/release step proceeds.
  - If integration/manual/security evidence fails, stop at the current PR slice and do not advance to release.

## 9) References (From Scan)

- `.TODO/PLAN_ProposalsRemediation_2026-03-04.md:1-320`
- `.TODO/PLAN_CRITIC_ProposalsRemediation_2026-03-04.md:1-230`
- `Sline_everything/DEVELOPER_GUIDE.md:41-68`
- `Sline_everything/SUPABASE_SETUP.md:1-56`
- `Sline_everything/MVP_ROADMAP.md:39-49`
- `Sline_everything/STRUCTURE.md:83-150`
- `Sline_everything/CODE_REVIEW.md:12-25`
- `lib/main.dart:196-199`
- `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- `lib/features/tasks/models/task_request_model.dart:8-202`
- `lib/features/tasks/services/task_requests_service.dart:5-299`
- `lib/features/tasks/services/task_service.dart:513-920`
- `lib/features/tasks/services/tender_payment_coordinator.dart:7-105`
- `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`
- `lib/features/tasks/viewmodels/tender_payment_view_model.dart:5-202`
- `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`
- `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`
- `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-60`
- `lib/features/tasks/view/task_details_screen.dart:218-254`
- `lib/features/tasks/view/task_details_screen.dart:668-681`
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart:515-760`
- `lib/features/dashboard/view/tabs/inbox_tab.dart:64-146`
- `lib/features/dashboard/view/tabs/work_tab.dart:286-317`
- `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`
- `lib/features/work/view/work_item_details_screen.dart:206-234`
- `lib/features/work/services/work_management_service.dart:24-150`
- `lib/features/profile/services/profile_summary_service.dart:13-33`
- `lib/features/favorites/data/favorites_service.dart:52-66`
- `lib/core/services/payment_service.dart:309-325`
- `lib/core/services/qicard_payment_service.dart:491-640`
- `supabase/migrations/20260226_tender_award_payment_flow.sql:328-367`
- `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`
- `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`
- `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`
- `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
- `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`
- `supabase/migrations/20260311000000_replace_task_request.sql:5-81`
- `supabase/migrations/20260312000000_profiles_update_own_for_active_role.sql:1-12`
- `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`
- `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-186`
- `supabase/migrations/20260316000000_task_requests_view_index.sql:1-4`
- `supabase/migrations/20260317000000_fix_task_request_amount_gross.sql:1-22`
- `supabase/functions/_shared/bookin_payment.ts:97-166`
- `supabase/functions/_shared/bookin_payment.ts:383-437`
- `supabase/functions/qicard_payment_create_tender/index.ts:22-149`
- `supabase/functions/qicard_payment_recovery_tender/index.ts:20-139`
- `test/test_support/pump_app.dart:5-18`
- `test/integration_test/support/helpers.dart:19-240`
- `test/integration_test/support/preflight.dart:10-56`
- `test/integration_test/create_tender_task_flow_test.dart:1-106`
- `test/unit/models/task_request_model_test.dart:24-105`
- `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`
- `test/widget/tasks/tender_payment_screen_test.dart:10-51`
- `pubspec.yaml:60-65`
