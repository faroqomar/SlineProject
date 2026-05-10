# 📌 Plan: Dashboard Full Remediation v2

## 1) Goal

- Goal: harden the dashboard feature end-to-end with live-verified DB/RLS contracts, server-authoritative workflow transitions, one tender-payment orchestration path, bounded state ownership, deterministic QA, and reviewable release slices.
- Why: the current dashboard still carries direct client transition paths, duplicated payment orchestration, dead management/runtime debt, dormant cache wiring, wallet-init drift, and missing deterministic release gates. File References: `.TODO/dashboard.TODO.md:70-150`, `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:1-287`
- Result: a dashboard release where non-admin users cannot reach finance aggregates, workflow transitions are enforced on the server, award/pay cannot advance after ledger failure, UI no longer owns backend services, and the rollout is gated by live DB proof plus deterministic tests.

## 2) Scope

### In-Scope

- Dashboard runtime and direct dependencies already identified in the current audit:
  - `lib/features/dashboard/**`
  - `lib/features/booking/services/booking_service.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/view/tender_payment_screen.dart`
  - `lib/features/tasks/viewmodels/task_requests_view_model.dart`
  - `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
  - `lib/features/wallet/services/ledger_service.dart`
  - `lib/features/wallet/viewmodels/wallet_view_model.dart`
  - `lib/features/profile/services/profile_summary_service.dart`
  - `lib/features/profile/view/my_services_screen.dart`
  - `lib/features/services/services/services_service.dart`
  - `lib/core/services/dashboard_cache_service.dart`
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
- Live Supabase objects directly touched by dashboard code:
  - tables: `profiles`, `activity_log`, `tasks`, `task_requests`, `bookings`, `services`
  - views: `vw_unified_work_items`, `vw_financial_metrics_realtime`, `vw_financial_metrics_period`, `vw_wallet_balances_user`
  - RPC/functions: `rpc_get_profile_summaries`, `award_task_offer`, `pay_awarded_offer`, `process_payment_event_ledger`, `get_client_awarded_unpaid_offers`, `get_freelancer_awarded_unpaid_offers`
- Test harness, migration, QA, and docs artifacts required to ship those changes.

### Out-of-Scope

- Unrelated feature refactors outside the direct dependency chain already listed.
- New dashboard visuals or broad design changes unrelated to correctness, ownership, or performance stabilization.
- New edge-function architecture; no dashboard-specific edge-function usage is in the current audited path.
- Destructive DB cleanup that is not preceded by additive-first migration and rollback planning.
- Reintroducing or preserving the dead Manage runtime as a supported feature target.

## 3) Evidence & Findings (From Scan)

### Existing

- The live dashboard surface remains the four-tab shell for `Overview`, `Bookings`, `Work`, and `Inbox`. File References: `lib/app/main_navigation_screen.dart:39-51`, `lib/main.dart:166-182`, `lib/features/dashboard/view/dashboard_screen.dart:96-149`
- The current audit already proves critical defects in finance access, transition authority, tender payment sequencing, ownership sprawl, performance fan-out, and missing tests. File References: `.TODO/dashboard.TODO.md:17-150`
- The current full-remediation plan already identifies the right high-risk areas, but it does not yet enforce the missing execution gates called out by the critique. File References: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:128-339`, `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:68-230`
- Shared test helpers exist but are generic: `pumpApp()` for widget tests and staging-backed preflight/env helpers for integration tests. File References: `test/test_support/pump_app.dart:5-18`, `integration_test/support/preflight.dart:10-57`, `integration_test/support/t61_t70_env.dart:3-87`
- Existing dashboard automated coverage is narrow: shell tabs, booking card labels, permission mapping, cache serialization, and one role-switch integration flow. File References: `.TODO/dashboard.TODO.md:89-92`, `integration_test/dashboard_role_switch_flow_test.dart:12-105`

### Missing

- Live Supabase confirmation is still blocked by MCP auth failure, so touched grants/RLS/function definitions remain unverified until the live scan artifact exists. File References: `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md:62-80`, `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:11-30`
- No dashboard-specific test infrastructure artifact exists yet for selectors, fixtures, env injection, timeout budgets, failure artifacts, or rerun policy. File References: `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:68-88`
- No state-machine artifact exists yet for task, booking, offer, and payment transitions. File References: `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:89-112`
- No delivery workflow artifact exists yet for branch slicing, review checklist, or per-slice definition of done. File References: `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:113-126`

### Must NOT Duplicate

- Do not keep two tender-payment orchestration paths. File References: `.TODO/dashboard.TODO.md:74-74`, `.TODO/dashboard.TODO.md:103-106`
- Do not keep direct finance reads in both DB grants and client repositories. File References: `.TODO/dashboard.TODO.md:17-24`, `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:31-42`
- Do not split dead Manage runtime into new owners. File References: `.TODO/dashboard.TODO.md:79-81`, `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:60-67`
- Do not create UI-owned service instances for payment or workflow transitions. File References: `.TODO/dashboard.TODO.md:70-74`, `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:145-163`

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Finance-view comments and current grants disagree; the app-side repository still exposes the risky read surface. File References: `.TODO/dashboard.TODO.md:17-24`
- Award/pay state machine is inconsistent in the current repo, and `LedgerService` does not yet enforce `{ok:false}` as terminal failure. File References: `.TODO/dashboard.TODO.md:25-33`, `.TODO/dashboard.TODO.md:90-92`
- `DashboardViewModel` still owns too many live concerns, and dead Manage/service coupling remains in the target area. File References: `.TODO/dashboard.TODO.md:70-88`, `.TODO/dashboard.TODO.md:108-141`
- The live DB auth block is itself a release risk and must stay a hard stop for DB-sensitive phases. File References: `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:11-30`, `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md:68-101`
- The critique baseline for this rewrite is recorded in `.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md`.

## 4) System Impact Map

- UI:
  - dashboard shell tabs
  - overview wallet snapshot, counters, next actions, activity feed
  - bookings actions
  - work CTA visibility and follow-through
  - inbox award/pay/reject/refund/withdraw flows
  - tender payment disabled/error/success states
- MVVM/App Logic:
  - split live dashboard ownership into shell/role/overview/bookings/work/inbox only
  - centralize tender payment coordination
  - move `MyServices` ownership to services
  - lock cache and wallet ownership instead of leaving them implied
- Database:
  - finance-view grants or admin-only replacement
  - task/booking transition RPCs
  - payment state-machine alignment
  - minimal profile-summary RPC path
  - additive indexes only after live query confirmation
- RLS/Security:
  - least-privilege grants
  - RLS/authorization matrix for tables/views/RPCs
  - server-side workflow guards
  - privacy-safe observability on money-sensitive flows
- Realtime/Notifications (if any):
  - no dashboard-specific realtime addition in this plan unless the live scan proves a required touched object
- Storage:
  - no direct storage path in dashboard code, but planner-required live storage confirmation still applies
- Observability:
  - correlation IDs and redacted service/viewmodel logs
  - payment failure taxonomy
  - artifact capture for QA failures
- Compatibility & Migration:
  - additive-first DB rollout
  - kill-switch path for award/pay and finance reads
  - versioned/additive profile-summary compatibility if required
- Contracts:
  - finance boundary
  - task/booking transition contract
  - payment state machine and reconciliation contract
  - profile-summary minimal contract
  - state ownership and selector/key contract
- Delivery Workflow:
  - four `codex/` branch slices
  - review checklist
  - per-slice definition of done
  - release checklist backed by evidence

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

- Goal: lock the rollout design, test baseline, workflow controls, and kill-switch behavior before implementation begins.
- Why: the current risk is not only bad code; it is bad sequencing.
- How: add the missing infrastructure, workflow, contract, and migration artifacts first.
- Result: the implementation path becomes execution-safe instead of aspirational.

### 0.0 Test Infrastructure Gate

- [ ] (@Sentinel) Create `.TODO/TEST_INFRA_Dashboard_2026-03-01.md` covering:
  - unit/widget/integration scope mapping
  - shared harness usage
  - `--dart-define` env/secrets injection contract
  - timeout budgets
  - retry/flake policy
  - failure artifact path and naming
- [ ] (@Sentinel) Create `.TODO/FIXTURES_Dashboard_2026-03-01.md` covering:
  - seeded client and freelancer accounts
  - funded-wallet preconditions for payment happy path
  - insufficient-funds and expired-payment fixtures
  - task/request/booking IDs needed for integration or manual scripts
  - fail-fast reset/cleanup rules
- [ ] (@Pixel) Define stable selector/key names for:
  - role switch settings button and role options
  - overview wallet ready/empty/error states
  - booking accept / decline / cancel actions
  - work-item start / review / pay actions
  - inbox award / pay-now / reject / refund / withdraw actions
  - tender payment submit / loading / error / success states
  - dashboard kill-switch or read-only banners
- [ ] (@Sentinel) Add `integration_test/support/dashboard_env.dart` and `integration_test/support/dashboard_preflight.dart`, using the existing `t61_t70_env.dart` and `preflight.dart` pattern as the baseline.
- [ ] (@Sentinel) Define one behavior per dashboard test ID and block bundled multi-behavior tests.
- **Verify (@Sentinel):** no dashboard test may be implemented or counted as complete without stable selectors, documented fixtures, preflight, and bounded waits.

### 0.1 Delivery Workflow Gate

- [ ] (@Architect) Lock four rollout slices and branch names:
  - `codex/dashboard-remediation-01-test-infra`
  - `codex/dashboard-remediation-02-db-security`
  - `codex/dashboard-remediation-03-app-layer`
  - `codex/dashboard-remediation-04-ui-qa-docs`
- [ ] (@Sentinel) Create `.TODO/REVIEW_CHECKLIST_Dashboard_2026-03-01.md` covering:
  - security/RLS review
  - MVVM boundary review
  - dead-code/duplicate-flow review
  - test evidence review
  - docs-sync review
- [ ] (@Sentinel) Create `.TODO/RELEASE_CHECKLIST_Dashboard_2026-03-01.md` with definition of done per slice, merge blockers, and rollback points.
- [ ] (@DocsKeeper) Map which docs must be updated in each slice so docs drift does not remain until the final merge.
- **Verify (@Sentinel):** each slice has one owner, one rollback point, and one merge checklist.

### 0.2 Spec Lock

- [ ] (@Architect) Lock the live DB truth-source rule: MCP auth restored or verified SQL export required before any DB-sensitive implementation starts.
- [ ] (@Architect) Lock the finance boundary: standard dashboard runtime cannot own finance metrics; use remove-or-admin-RPC only.
- [ ] (@APIContract) Lock the profile-summary strategy: versioned/additive minimal RPC unless caller parity proves safe in-place shrink.
- [ ] (@Architect) Lock the payment kill-switch rule: award/pay entry points stay disabled if live contract proof fails.
- [ ] (@Architect) Create `.TODO/OWNERSHIP_Dashboard_2026-03-01.md` covering:
  - `dashboard_shell`
  - `dashboard_role`
  - `dashboard_overview`
  - `dashboard_bookings`
  - `dashboard_work`
  - `dashboard_inbox`
  - `wallet`
  - `services/my_services`
  - `dashboard_cache`
- [ ] (@Sentinel) Create `.TODO/ACCEPTANCE_Dashboard_2026-03-01.md` with measurable release blockers and non-regression rules.
- **Verify (@Sentinel):** blocking decisions are frozen; no optional branch remains for finance, payment, or profile-summary contracts.

### 0.3 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_Dashboard_2026-03-01.md` covering:
  - finance data exposure
  - unauthorized transitions
  - replay/idempotency
  - insufficient-funds and expired-payment abuse
  - partial payment drift
  - stale cache / stale wallet state
  - PII leakage in logs
- [ ] (@Observability) Create `.TODO/OBSERVABILITY_Dashboard_2026-03-01.md` covering:
  - correlation IDs
  - payment/transition event taxonomy
  - redaction rules
  - failure artifact tagging convention
- [ ] (@Sentinel) Convert each threat into a negative test, verify query, or manual scenario.
- **Verify (@Sentinel):** every money/authz risk has one enforcement path and one verification path.

### 0.4 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_Dashboard_Finance_Boundary_2026-03-01.md`.
- [ ] (@APIContract) Create `.TODO/CONTRACT_Dashboard_Transitions_2026-03-01.md`.
- [ ] (@APIContract) Create `.TODO/CONTRACT_Dashboard_Tender_Payment_2026-03-01.md`.
- [ ] (@APIContract) Create `.TODO/CONTRACT_Profile_Summary_Minimum_2026-03-01.md`.
- [ ] (@Architect) Create `.TODO/STATE_MACHINE_Dashboard_2026-03-01.md` covering:
  - task transitions
  - booking transitions
  - offer award/pay states
  - ledger failure states
  - kill-switch / disabled states
- **Verify (@Sentinel):** every touched contract has one approved server owner and one typed app consumer contract.

### 0.5 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_Dashboard_2026-03-01.md` with introduce/backfill/enforce order for:
  - finance grant restriction or admin-RPC replacement
  - transition RPC introduction
  - payment state-machine alignment
  - profile-summary compatibility path
  - dead-path removal timing
- [ ] (@DataMigration) Create `.TODO/RECONCILIATION_Dashboard_2026-03-01.md` covering:
  - partial payment drift detection queries
  - forward-fix rules
  - rollback triggers
  - kill-switch activation conditions
- [ ] (@Supabase_Ops) Define exact verify queries for grants, RLS, RPC presence, and status-alignment checks.
- **Verify (@Sentinel):** migration order, compatibility windows, and forward-fix rules are measurable and rollback-safe.

### 0.6 Feature Flag / Kill Switch

- [ ] (@Architect) Define the award/pay kill-switch behavior in dashboard and request-list surfaces.
- [ ] (@Architect) Define the finance-metrics fallback behavior: remove from standard dashboard or replace with explicit unauthorized state.
- [ ] (@Pixel) Define disabled/read-only/error UI for unsupported transitions and blocked payment flows.
- **Verify (@Sentinel):** there is a user-visible safe fallback for every blocked risky flow.

### GATE CHECK

- Test infra artifacts exist.
- Delivery slices and review checklist exist.
- Blocking decisions are fixed.
- Threat model, contracts, migration plan, and kill-switch rules are written.
- If any item above is missing, Phase 1 does not start.

---

## Phase 1: Data/Contracts

> Primary: @Supabase_Ops

- Goal: verify live DB reality and lock the exact server contract to implement.
- Why: repo intent is not enough for grants, RLS, or payment flow correction.
- How: re-scan live DB, capture drift, and then define the additive-first contract work.
- Result: DB/security work proceeds against verified reality.

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Restore `@mcp:supabase-mcp-server` access or attach a verified SQL export for touched objects.
- [ ] (@Supabase_Ops) Export live definitions/grants for:
  - `vw_unified_work_items`
  - `vw_financial_metrics_realtime`
  - `vw_financial_metrics_period`
  - `vw_wallet_balances_user`
  - `rpc_get_profile_summaries`
  - `award_task_offer`
  - `pay_awarded_offer`
  - `process_payment_event_ledger`
- [ ] (@Supabase_Ops) Export live RLS/policy text for `tasks`, `task_requests`, `bookings`, `profiles`, `services`, and any touched payment tables.
- [ ] (@Supabase_Ops) Write the result to `.TODO/LIVE_SCAN_Dashboard_2026-03-01.md`.
- **Verify (@Sentinel):** no Phase 1.1 work starts without this artifact.

### 1.1 Finance Boundary

- [ ] (@Supabase_Ops) Implement the chosen finance boundary:
  - revoke direct `authenticated` reads from finance views, or
  - replace them with a dedicated admin-only RPC/service boundary
- [ ] (@APIContract) Align the finance boundary contract artifact to the live definitions.
- [ ] (@Sentinel) Add verify queries for grant state before and after the migration.
- **Verify (@Sentinel):** non-admin runtime has no direct finance-view path.

### 1.2 Workflow Transition Contract

- [ ] (@Supabase_Ops) Add or confirm server-authoritative transition RPCs for dashboard-driven task and booking transitions.
- [ ] (@APIContract) Lock request/response/error shapes and allowed actor/current/next-state combinations.
- [ ] (@ThreatModeler) Add negative checks for unauthorized jumps and actor spoofing.
- **Verify (@Sentinel):** raw row updates are no longer the authority for workflow transitions.

### 1.3 Tender Payment Contract

- [ ] (@Supabase_Ops) Align award, ledger hold, and pay RPC contracts to one state machine.
- [ ] (@APIContract) Lock idempotency, duplicate-submit, insufficient-funds, and expiry behavior.
- [ ] (@DataMigration) Finalize reconciliation queries and candidate-row detection for partial drift.
- **Verify (@Sentinel):** the payment contract cannot advance after ledger rejection and has a documented forward-fix path.

### 1.4 Profile Summary Contract

- [ ] (@Supabase_Ops) Implement the chosen minimal summary strategy.
- [ ] (@APIContract) Document compatibility-window exit criteria if a versioned/additive RPC is used.
- [ ] (@Sentinel) Prove the dashboard gets exactly the approved fields.
- **Verify (@Sentinel):** summary exposure is minimal and rollout-safe.

### 1.5 Migration Execution Prep

- [ ] (@DataMigration) Prepare additive migrations and any explicit rollback migrations.
- [ ] (@DataMigration) Sequence introduce/backfill/enforce order for staging/live rollout.
- [ ] (@Sentinel) Block execution if any migration still depends on unverified live assumptions.
- **Verify (@Sentinel):** the migration pack is execution-ready and rollback-aware.

### GATE CHECK

- `.TODO/LIVE_SCAN_Dashboard_2026-03-01.md` exists.
- Finance boundary, transition, payment, and profile-summary contracts are locked.
- Reconciliation/verify queries are written.
- No unresolved live drift remains on touched objects.

---

## Phase 2: Security/RLS

> Primary: @Supabase_Ops

- Goal: enforce least privilege and server authority for every touched dashboard flow.
- Why: client checks are UX only; the server contract must be the source of truth.
- How: implement grants/RLS/RPC checks, then prove them with negative and positive verification.
- Result: authorization and data-exposure risks are closed before app wiring changes continue.

### 2.1 RLS / Grant Matrix

- [ ] (@Supabase_Ops) Create `.TODO/RLS_MATRIX_Dashboard_2026-03-01.md` covering allowed and forbidden access for:
  - client
  - freelancer
  - provider
  - admin
  - anonymous
- [ ] (@ThreatModeler) Map each matrix row to a negative or positive verification.
- **Verify (@Sentinel):** every touched object has a documented permission contract.

### 2.2 Server-Only Privileged Actions

- [ ] (@Supabase_Ops) Ensure finance reporting, award/pay, refund/release, and workflow transitions remain server-owned.
- [ ] (@Supabase_Ops) Remove any grant or broad update path that lets the client bypass the server contract.
- [ ] (@APIContract) Freeze error taxonomy for auth, validation, expired-state, and business-rule failures.
- **Verify (@Sentinel):** privileged actions cannot be executed from raw client writes.

### 2.3 Verification Queries and Negative Checks

- [ ] (@Sentinel) Run exact grant queries for finance views.
- [ ] (@Sentinel) Run positive and negative transition/payment checks.
- [ ] (@Sentinel) Run storage audit required by the planner workflow even though dashboard has no direct storage path.
- [ ] (@Sentinel) Run privacy/log-redaction checks against the observability rules.
- **Verify (@Sentinel):** finance leaks, invalid transitions, and over-broad reads are demonstrably blocked.

### 2.4 Migration Execution

- [ ] (@DataMigration) Execute introduce/backfill/enforce steps in the approved order.
- [ ] (@DataMigration) Record results and rollback triggers in the reconciliation artifact.
- **Verify (@Sentinel):** staged migration checks pass before the app rollout proceeds.

### GATE CHECK

- Grant and RLS queries pass.
- Invalid transitions fail.
- Payment failure paths fail closed.
- Storage/privacy checks pass.

---

## Phase 3: Backend/API

> Primary: @Architect

- Goal: centralize business logic and remove duplicate or dead ownership paths.
- Why: the current dashboard breaks MVVM boundaries and spreads orchestration across features.
- How: refactor services, repositories, and ViewModels around the approved contracts and ownership matrix.
- Result: the app layer becomes smaller, testable, and aligned with the server contract.

### 3.1 Repositories and Services

- [ ] (@Architect) Split `lib/features/dashboard/data/dashboard_repository.dart` by live responsibility only:
  - `dashboard_overview_repository.dart`
  - `dashboard_work_repository.dart`
  - `dashboard_activity_repository.dart`
  - `dashboard_profile_repository.dart`
- [ ] (@Architect) Remove or quarantine finance reads from the standard dashboard path.
- [ ] (@Architect) Consolidate awarded-unpaid-offer access into one owner rather than keeping it in both dashboard and task services.
- **Verify (@Sentinel):** live repository boundaries match the approved ownership matrix.

### 3.2 Tender Payment Coordination

- [ ] (@Architect) Add `lib/features/tasks/services/tender_payment_coordinator.dart`.
- [ ] (@Architect) Add `lib/features/tasks/viewmodels/tender_payment_view_model.dart`.
- [ ] (@Architect) Make `lib/features/wallet/services/ledger_service.dart` treat `{ok:false}` as terminal failure.
- [ ] (@Architect) Route dashboard inbox and task-request entry points through the same coordinator.
- **Verify (@Sentinel):** there is one payment orchestration path and it fails closed.

### 3.3 Dashboard Ownership Split

- [ ] (@Architect) Keep `lib/features/dashboard/viewmodels/dashboard_view_model.dart` only as a temporary compatibility facade if needed.
- [ ] (@Architect) Add bounded owners for live runtime only:
  - `dashboard_role_view_model.dart`
  - `dashboard_overview_view_model.dart`
  - `dashboard_bookings_view_model.dart`
  - `dashboard_work_view_model.dart`
  - `dashboard_inbox_view_model.dart`
- [ ] (@Architect) Remove dead Manage state from the target architecture instead of giving it a new owner.
- **Verify (@Sentinel):** each live dashboard surface has one state owner and no dead owner is created.

### 3.4 Wallet, Cache, and Services Ownership

- [ ] (@Architect) Decide and implement one of:
  - wire `DashboardCacheService` into real DI, or
  - delete dormant cache code and references
- [ ] (@Architect) Move `MyServicesScreen` off dashboard-owned state and add `lib/features/services/viewmodels/my_services_view_model.dart`.
- [ ] (@Architect) Lock wallet snapshot initialization to the wallet owner so overview first-entry load is correct.
- **Verify (@Sentinel):** cache, services, and wallet ownership are explicit and testable.

### 3.5 Observability and Error Handling

- [ ] (@Observability) Instrument service/viewmodel layers only.
- [ ] (@Architect) Route business-rule failures through one typed error path instead of raw exception text.
- [ ] (@ThreatModeler) Re-check logs for PII or payment-detail leakage.
- **Verify (@Sentinel):** logs are useful, correlated, and redacted.

### GATE CHECK

- UI no longer instantiates backend services.
- Duplicate payment orchestration is removed.
- Dead Manage ownership is removed.
- Wallet/cache/services ownership is explicit and verified.

---

## Phase 4: UI Wiring

> Primary: @Pixel

- Goal: wire the dashboard shell to the new owners and expose safe states for enabled, disabled, and failed flows.
- Why: correct backend contracts still fail users if the UI hides state or preserves dead paths.
- How: refactor the shell, move domain-owned widgets, narrow rebuild scope, and remove unsupported runtime debt.
- Result: the dashboard is a composition shell, not a business-logic owner.

### 4.1 Shell and Tabs

- [ ] (@Pixel) Update the shell and tabs to consume only the bounded view models.
- [ ] (@Pixel) Replace broad provider watches with selectors or narrow consumers.
- [ ] (@Pixel) Lazy-load by active tab so Overview does not fetch hidden Bookings/Inbox state on first paint.
- **Verify (@Sentinel):** hidden tabs are not fetched on first entry and rebuild scope is reduced.

### 4.2 Widget Ownership Moves

- [ ] (@Pixel) Move:
  - `booking_card.dart` -> `lib/features/booking/view/widgets/dashboard_booking_card.dart`
  - `offer_card.dart` -> `lib/features/tasks/view/widgets/dashboard_offer_card.dart`
  - `wallet_snapshot_card.dart` -> `lib/features/wallet/view/widgets/wallet_snapshot_card.dart`
- [ ] (@Architect) Add shared status presentation helpers instead of duplicated card-specific rules.
- [ ] (@Sentinel) Keep temporary wrappers only if needed for one-slice compatibility.
- **Verify (@Sentinel):** dashboard imports feature-owned widgets and status presentation is centralized.

### 4.3 Tender Payment and Action States

- [ ] (@Pixel) Bind `tender_payment_screen.dart` to the new view model only.
- [ ] (@Pixel) Replace TODO/no-op action surfaces with explicit disabled/error/read-only states.
- [ ] (@Pixel) Restore or intentionally remove CTA behavior where permission logic and UI are currently mismatched.
- [ ] (@Pixel) Render kill-switch/read-only states clearly when award/pay is intentionally blocked.
- **Verify (@Sentinel):** critical actions are either correctly wired or explicitly unavailable with user-visible explanation.

### 4.4 Dead Runtime Removal

- [ ] (@Architect) Delete dead Manage-only files once compatibility wrappers are no longer needed:
  - `lib/features/dashboard/view/tabs/manage_tab.dart`
  - `lib/features/dashboard/view/widgets/manage_service_list.dart`
  - `lib/features/dashboard/view/widgets/manage_task_list.dart`
  - `lib/features/dashboard/data/mock/mock_dashboard_repository.dart`
  - `lib/features/dashboard/models/activity_item.dart`
- [ ] (@Sentinel) Re-run dead-code searches and `flutter analyze` after removal.
- **Verify (@Sentinel):** dead runtime debt is gone and no live import depends on it.

### GATE CHECK

- Dashboard shell consumes bounded owners only.
- Widget ownership moves compile cleanly.
- Unsupported actions are explicit, not silent.
- Dead Manage runtime is removed.

---

## Phase 5: QA + Release

> Primary: @Sentinel

- Goal: prove the dashboard remediation is safe to merge and release.
- Why: this feature spans money, authorization, navigation, and shared state.
- How: run deterministic automated tests, staged manual scenarios, SQL verification, privacy checks, and per-slice release gates.
- Result: release readiness is evidenced, not assumed.

### 5.1 Automated Tests

- [ ] (@Sentinel) Add unit tests for:
  - dashboard ownership/facade behavior
  - tender payment coordinator
  - `LedgerService` `{ok:false}` handling
  - booking/task transition service guards
  - wallet snapshot initialization contract
  - profile-summary contract parsing
- [ ] (@Sentinel) Add widget tests for:
  - overview wallet snapshot ready/empty/error states
  - work CTA visibility and disabled states
  - inbox award/pay actions and kill-switch banners
  - tender payment loading/error/success states
  - booking accept/decline/cancel state handling
- [ ] (@Sentinel) Add integration coverage for:
  - role switch persistence
  - award/pay happy path if a deterministic seam/fixture exists
  - blocked/disabled payment flow when kill switch is active
- [ ] (@Sentinel) Use these budgets:
  - unit/widget: zero retries
  - integration: one rerun max after artifact capture
  - locator wait ceiling: 20 seconds
  - scenario ceiling: 120 seconds
- **Verify (@Sentinel):** every critical dashboard behavior has one planned test type, bounded wait, and artifact path.

### 5.2 Manual Scenarios

- [ ] (@Sentinel) Run a client happy path: role switch -> overview -> award offer -> tender payment -> success verification.
- [ ] (@Sentinel) Run a payment failure path: insufficient funds or expired payment -> verify no downstream state advance.
- [ ] (@Sentinel) Run a provider booking path: `paid_request_pending` accept/decline through the server-backed transition contract.
- [ ] (@Sentinel) Run a client cancel path on a confirmed booking and verify refund/release rules.
- [ ] (@Sentinel) Run a first-entry overview path and verify wallet snapshot loads without visiting wallet screen first.
- **Verify (@Sentinel):** each manual scenario records expected postconditions and attached evidence.

### 5.3 SQL / Security / Privacy Checks

- [ ] (@Sentinel) Run finance grant queries and confirm no non-admin direct read remains.
- [ ] (@Sentinel) Run transition/payment contract queries and negative checks.
- [ ] (@Sentinel) Run storage audit required by planner workflow.
- [ ] (@Sentinel) Run privacy grep/log review against the observability rules.
- **Verify (@Sentinel):** grant, transition, payment, storage, and privacy checks all pass.

### 5.4 Slice Closeout and Docs Sync

- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md`.
- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md`.
- [ ] (@DocsKeeper) Update `Sline_everything/MVP_ROADMAP.md`.
- [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md`.
- [ ] (@DocsKeeper) Update `Sline_everything/CODE_REVIEW.md` and `Sline_everything/ARCHITECTURE_ANALYSIS.md` only where the current-live contract changed.
- [ ] (@Sentinel) Close the release checklist only after code, DB evidence, tests, and docs all match.
- **Verify (@Sentinel):** docs and release evidence are synchronized with the shipped contract.

### GATE CHECK

- Unit/widget/integration/manual evidence is attached.
- SQL/RLS/grant/privacy checks pass.
- Slice review checklist is complete.
- Docs are synced.
- If any item above is missing, release is blocked.

---

## 7) Acceptance Criteria (MANDATORY)

- Standard dashboard runtime has zero non-admin direct access to platform finance aggregates.
- Dashboard task and booking transitions are server-authoritative; raw client row updates are not the workflow authority.
- Award/pay cannot advance task/request state after ledger rejection, `{ok:false}`, or status mismatch.
- Dashboard and task-request flows use one tender-payment coordinator path.
- `TenderPaymentScreen` does not instantiate backend services directly.
- Dashboard live ownership is split only across shell/role/overview/bookings/work/inbox; dead Manage ownership does not survive.
- `MyServicesScreen` no longer depends on dashboard-owned state.
- Wallet snapshot shows correct balances on first dashboard entry without visiting wallet first.
- Hidden tabs do not fetch data on first paint.
- Dead Manage files and unsupported TODO/no-op paths are removed or replaced with explicit disabled states.
- Test infrastructure artifacts, fixtures, selector map, and failure artifact conventions exist and are used.
- Docs and live DB evidence are synced, and any remaining unresolved live drift keeps release blocked.

## 8) Rollback Plan

- Slice 1 rollback:
  - revert test infra and planning artifacts without touching runtime contracts
  - remove new selectors/preflight files if they cause unrelated test churn
- Slice 2 rollback:
  - revert DB/security changes via dedicated rollback migrations only
  - re-enable kill-switch/read-only UI if any finance or payment contract remains unresolved
  - do not hand-edit grants in production
- Slice 3 rollback:
  - keep `dashboard_view_model.dart` compatibility facade available until the new owners are stable
  - revert coordinator/viewmodel rollout while leaving server hardening in place if app-layer regressions appear
- Slice 4 rollback:
  - disable award/pay entry points and keep dashboard read-only if UI/QA evidence fails late
  - keep moved widget wrappers for one release if import churn causes unexpected breakage
- Money-path forward-fix rule:
  - use `.TODO/RECONCILIATION_Dashboard_2026-03-01.md` candidate-row queries and forward-fix steps instead of ad hoc edits
- Release blocker rule:
  - if live DB proof or SQL verification cannot be attached, do not release DB-sensitive dashboard changes

## 9) References (From Scan)

- `/.agents/workflows/planner.md`
- `/.agents/workflows/plan_critic.md`
- `/.TODO/dashboard.TODO.md`
- `/.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md`
- `/.TODO/PLAN_CRITIC_Dashboard_Full_Remediation_2026-03-01.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/STRUCTURE.md`
- `lib/main.dart`
- `lib/app/main_navigation_screen.dart`
- `lib/core/services/dashboard_cache_service.dart`
- `lib/features/dashboard/view/dashboard_screen.dart`
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
- `lib/features/dashboard/data/dashboard_repository.dart`
- `lib/features/booking/services/booking_service.dart`
- `lib/features/tasks/services/task_service.dart`
- `lib/features/tasks/view/tender_payment_screen.dart`
- `lib/features/tasks/viewmodels/task_requests_view_model.dart`
- `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
- `lib/features/wallet/services/ledger_service.dart`
- `lib/features/wallet/viewmodels/wallet_view_model.dart`
- `lib/features/profile/services/profile_summary_service.dart`
- `lib/features/profile/view/my_services_screen.dart`
- `lib/features/services/services/services_service.dart`
- `test/test_support/pump_app.dart`
- `integration_test/support/preflight.dart`
- `integration_test/support/t61_t70_env.dart`
- `integration_test/dashboard_role_switch_flow_test.dart`
