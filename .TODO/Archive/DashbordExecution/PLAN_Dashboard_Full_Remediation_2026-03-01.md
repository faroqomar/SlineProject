# 📌 Plan: Dashboard Full Remediation

## 1) Goal

- Goal: Remediate the dashboard feature end-to-end so its data access, workflow transitions, tender payment path, MVVM structure, test coverage, and documentation are all production-safe and aligned with current repository contracts.
- Why: The current dashboard still mixes direct client-side workflow mutations, duplicated tender payment orchestration, dead management code, dormant cache wiring, and unfinished wallet/payment hardening, while the live DB confirmation step is currently blocked and must be treated as a release gate.
- Result: A dashboard that uses server-authoritative transitions, minimal-privilege data access, bounded ViewModels/services, verified payment sequencing, reduced dead code, measurable regression coverage, and synchronized docs.

## 2) Scope

### In-Scope

- `lib/features/dashboard/**`
- Direct dependencies touched by dashboard flows:
  - `lib/features/booking/services/booking_service.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/view/tender_payment_screen.dart`
  - `lib/features/tasks/viewmodels/task_requests_view_model.dart`
  - `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
  - `lib/features/wallet/services/ledger_service.dart`
  - `lib/features/wallet/viewmodels/wallet_view_model.dart`
  - `lib/features/profile/services/profile_summary_service.dart`
  - `lib/features/services/services/services_service.dart`
  - `lib/core/services/dashboard_cache_service.dart`
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
- Supabase objects directly touched by dashboard code:
  - tables: `profiles`, `activity_log`, `tasks`, `task_requests`, `bookings`, `services`
  - views: `vw_unified_work_items`, `vw_financial_metrics_realtime`, `vw_financial_metrics_period`, `vw_wallet_balances_user`
  - RPC/functions: `rpc_get_profile_summaries`, `award_task_offer`, `pay_awarded_offer`, `process_payment_event_ledger`, `get_client_awarded_unpaid_offers`, `get_freelancer_awarded_unpaid_offers`
- Tests, docs, and migration artifacts required to safely ship those changes

### Out-of-Scope

- Unrelated feature refactors outside the dashboard dependency chain
- Broader wallet architecture redesign beyond what dashboard/tender flows require
- Chat, notifications, or management feature changes unless directly required by dashboard contracts
- Visual redesign unrelated to correctness, MVVM cleanup, or performance stabilization
- Any destructive DB cleanup that is not preceded by additive-safe migration and rollback planning

## 3) Evidence & Findings (From Scan)

### Existing

- The live bottom-nav dashboard surface is `lib/features/dashboard/view/dashboard_screen.dart`; the standalone orders runtime was removed, but the dashboard remains the workspace shell. Reference: `Sline_everything/DEVELOPER_GUIDE.md:1491-1509`, `lib/app/main_navigation_screen.dart:39-51`
- The dashboard provider is still app-root scoped, and the shell mounts `Overview`, `Bookings`, `Work`, and `Inbox` tabs only. Reference: `lib/main.dart:166-182`, `lib/features/dashboard/view/dashboard_screen.dart:96-149`
- `DashboardViewModel` currently owns role switching, caching hooks, work loading, booking actions, inbox/tender actions, and management state in one notifier. Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:24-964`
- The dashboard refresh path fetches six datasets in parallel regardless of active tab. Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:396-425`
- Dashboard writes still use direct client-side task/booking updates instead of server-authoritative transition RPCs. Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-879`, `lib/features/tasks/services/task_service.dart:184-212`, `lib/features/booking/services/booking_service.dart:117-143`
- Tender payment is duplicated across dashboard and task-request flows and still launches a screen that instantiates services inside widget state. Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:21-105`, `lib/features/tasks/view/tender_payment_screen.dart:39-109`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:115-169`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:127-167`
- Docs establish that `vw_unified_work_items.needs_review` is only a raw delivered-state signal and that client review UI must combine it with role-derived permissions. Reference: `Sline_everything/CODE_REVIEW.md:494-502`, `Sline_everything/DEVELOPER_GUIDE.md:1984-1999`
- Docs also establish that wallet/ledger work is still in progress and automated coverage around dashboard/wallet/payment remains an active repo focus. Reference: `Sline_everything/MVP_ROADMAP.md:72-90`
- Current repo structure rules require `View -> ViewModel -> Service/Data -> Supabase`, and views must not call Supabase directly. Reference: `Sline_everything/STRUCTURE.md:209-226`
- Repo migrations show:
  - finance views are granted to `authenticated`
  - award flow sets offers to `accepted/unpaid`
  - tender pay flow expects follow-up payment RPCs
  - ledger RPC returns JSON payloads, including business-rule failures, not only SQL exceptions
  - profile-summary RPC returns more fields than the dashboard consumes
  Reference: `supabase/migrations/20260225_create_wallet_views.sql:161-430`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:472-693`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:4-260`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`

### Missing

- Live Supabase confirmation is currently blocked: `@mcp:supabase-mcp-server` `execute_sql` and `list_storage_buckets` returned `Auth required` during planning on 2026-03-01.
- Because of that auth block, the following remain `UNVERIFIED` until Phase 1.0:
  - actual deployed definitions and grants for `vw_unified_work_items`, `vw_financial_metrics_realtime`, `vw_financial_metrics_period`, `vw_wallet_balances_user`
  - actual live RLS/policy text for touched tables
  - actual live function definitions/grants for dashboard payment/profile RPCs
  - actual live storage buckets and policies
  - actual live indexes and triggers beyond what repo migrations/documentation state

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Docs describe work/payment flows that rely on server-authoritative RPCs such as `rpc_submit_delivery` and ledger-backed approval, but the dashboard still performs direct row mutations in app services. Reference: `Sline_everything/DEVELOPER_GUIDE.md:1969-1974`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:753-879`
- Docs say the orders runtime was removed, but dashboard still carries dead management files and hidden management state, and profile screens still depend on dashboard-owned service state. Reference: `Sline_everything/DEVELOPER_GUIDE.md:1491-1509`, `lib/features/dashboard/view/tabs/manage_tab.dart:10-83`, `lib/features/profile/view/my_services_screen.dart:14-17`
- Repo docs define `vw_unified_work_items` in `SUPABASE_SETUP.md`, but there is no matching checked-in migration for that view, so deployment parity is not guaranteed. Reference: `Sline_everything/SUPABASE_SETUP.md:934-986`
- Finance-view comments say service-role/admin only, but the checked-in migration grants them to `authenticated`. Reference: `supabase/migrations/20260225_create_wallet_views.sql:161-255`, `supabase/migrations/20260225_create_wallet_views.sql:412-430`
- Tender payment has a repo-visible status mismatch: award moves to `accepted/unpaid`, while the ledger escrow-hold guard currently expects `pending/unpaid`. Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:518-649`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:107-160`, `lib/features/tasks/services/task_service.dart:731-775`
- Wallet/booking/payment work falls under money-sensitive flows, so threat modeling, observability, and migration compatibility are mandatory before implementation. Reference: `Sline_everything/MVP_ROADMAP.md:75-90`, `Sline_everything/STRUCTURE.md:74-79`
- The live scan auth block itself is a release-planning risk: DB assumptions must not be treated as proven until MCP access is restored.

## 4) System Impact Map

- UI:
  - Dashboard shell tabs
  - Overview wallet snapshot, counters, next actions, activity feed
  - Bookings tab cards and actions
  - Work tab CTAs and rebuild scope
  - Inbox award/pay/reject/refund/withdraw actions
  - Tender payment screen and launchers
- MVVM/App Logic:
  - split oversized `DashboardViewModel`
  - centralize tender payment orchestration
  - remove profile dependency on dashboard-owned services state
  - activate or remove dormant dashboard cache flow
- Database:
  - finance view permissions
  - dashboard transition RPCs for task/booking state changes
  - tender payment state-machine alignment
  - minimal profile-summary RPC contract
  - possible additive indexes once live query patterns are confirmed
- RLS/Security:
  - least-privilege view access
  - workflow authorization moved from client UX to server-side checks
  - negative-case validation for payment, status changes, and cross-user profile reads
- Realtime/Notifications (if any):
  - no dashboard-specific realtime integration was found in current code; ensure no plan step introduces hidden realtime coupling without contract/docs updates
- Storage:
  - no direct storage access in current dashboard path; Phase 1.0 still needs live bucket/policy confirmation because planner.md requires it
- Observability (if any):
  - add correlation IDs and redacted service/viewmodel logs for award/pay/cancel/transition flows
  - keep logs out of UI layer
- Compatibility & Migration:
  - additive-first SQL
  - compatibility facade for `DashboardViewModel`
  - staged removal of dead dashboard management paths
  - migration/rollback notes for money-related state
- Contracts:
  - Flutter ↔ RPC transition contract
  - Flutter ↔ tender payment coordinator contract
  - dashboard ↔ profile-summary contract
  - dashboard ↔ finance view/admin reporting boundary

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Freeze the remediation target list from `dashboard.TODO.md` into a measurable acceptance/non-regression checklist in `.TODO/ACCEPTANCE_Dashboard_2026-03-01.md`.
- [ ] (@Architect) Confirm final module boundaries: dashboard shell, bookings/task services, tender payment coordinator, services/profile ownership, and doc sync targets.
- [ ] (@Architect) Confirm that direct dependencies outside dashboard stay limited to booking/tasks/wallet/profile/services/main app wiring.
- **Verify (@Sentinel):** done-conditions, blocker conditions, and rollback triggers are explicit before implementation starts.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_Dashboard_2026-03-01.md` covering payment abuse, unauthorized transitions, cross-user data reads, replay/idempotency, stale cache, and privileged reporting exposure.
- [ ] (@ThreatModeler) Define negative checks for insufficient funds, expired payment windows, replayed idempotency keys, unauthorized task/booking updates, and unauthorized finance/profile reads.
- [ ] (@Observability) Define the minimum audit/correlation events required for tender award, payment, cancel, refund, and transition failures.
- **Verify (@Sentinel):** threat cases are testable and mapped into Phase 4 security checks.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_Dashboard_Transitions_2026-03-01.md` for task/booking transition RPC request/response shapes and allowed state moves.
- [ ] (@APIContract) Create `.TODO/CONTRACT_Dashboard_Tender_Payment_2026-03-01.md` for award/pay/ledger sequencing, success/failure payloads, and idempotency behavior.
- [ ] (@APIContract) Create `.TODO/CONTRACT_Profile_Summary_Minimum_2026-03-01.md` for the reduced cross-user profile payload required by dashboard surfaces.
- **Verify (@Sentinel):** contract files match current repo models and are written to tolerate additive schema evolution.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_Dashboard_2026-03-01.md` with introduce/backfill/enforce stages for finance-view restriction, transition RPC introduction, tender payment alignment, and any profile-summary contract shrinkage.
- [ ] (@DataMigration) Define compatibility windows for app versions that may still call old direct-update paths or old profile-summary payloads.
- [ ] (@DataMigration) Define rollback/forward-fix rules for money-related state mismatches.
- **Verify (@Sentinel):** compatibility windows and rollback conditions are measurable and safe.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Decide whether tender payment remediation and finance-view restriction need temporary feature flags or admin-only rollout switches.
- [ ] (@Architect) Define the emergency-disable path for tender award/pay if live DB drift is discovered during Phase 1.0.
- **Verify (@Sentinel):** rollback path is documented before any DB or app rollout begins.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Restore `@mcp:supabase-mcp-server` access and re-scan touched tables, views, RPCs, triggers, indexes, RLS, and storage buckets.
- [ ] (@Supabase_Ops) Export live definitions/grants for `vw_unified_work_items`, `vw_financial_metrics_realtime`, `vw_financial_metrics_period`, `vw_wallet_balances_user`, `rpc_get_profile_summaries`, `award_task_offer`, `pay_awarded_offer`, and `process_payment_event_ledger` into `.TODO/LIVE_SCAN_Dashboard_2026-03-01.md`.
- [ ] (@Supabase_Ops) Record doc-vs-live drift instead of deleting or renaming DB objects to “match docs.”
- **Verify (@Sentinel):** live drift, missing access, and the safe reconcile path are recorded before schema work starts.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Add a migration to remove direct authenticated access to finance views or replace those reads with an admin-scoped RPC boundary.
- [ ] (@Supabase_Ops) Add transition RPCs for dashboard task and booking status changes instead of relying on raw row updates from the client.
- [ ] (@Supabase_Ops) Additive-fix the tender payment state machine so award status, ledger gate, and pay status all agree on one contract.
- [ ] (@Supabase_Ops) Add or update indexes only after live query patterns are confirmed for transition RPCs and dashboard list filters.
- [ ] (@DataMigration) If profile-summary payload reduction would break existing callers, introduce a versioned or additive RPC path before removal.
- **Verify (@Sentinel):** migrations are additive-first, names are consistent, and no client-visible contract is silently broken.

### 1.2 RLS

- [ ] (@Supabase_Ops) Build `.TODO/RLS_MATRIX_Dashboard_2026-03-01.md` covering positive and negative access for dashboard tables/views/RPCs.
- [ ] (@Supabase_Ops) Ensure workflow authorization lives in RPC/trigger logic and least-privilege grants, not only in broad row-level ownership policies.
- [ ] (@ThreatModeler) Add negative checks for finance-view leakage, unauthorized task/booking transitions, and overbroad profile-summary access.
- **Verify (@Sentinel):** positive cases pass and negative cases fail under authenticated non-admin users.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Reuse existing work-management RPCs where appropriate instead of creating overlapping dashboard-only behavior.
- [ ] (@Supabase_Ops) Ensure tender payment RPC flow is idempotent and cannot advance work state after ledger failure.
- [ ] (@APIContract) Lock response shapes for transition and payment RPCs before app-layer changes begin.
- **Verify (@Sentinel):** server state rules are authoritative and testable.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Execute introduce/backfill/enforce steps in sequence once live DB drift is confirmed.
- [ ] (@DataMigration) Keep a compatibility window for old app clients if any changed RPC or payload shape remains in active use.
- **Verify (@Sentinel):** verify queries and backfill checks pass before app rollout continues.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Align dashboard/tender/booking models and DTO parsing with the final RPC contracts and nullability rules.
- [ ] (@Architect) Remove or isolate dashboard repository methods that expose finance/admin-only data.
- [ ] (@APIContract) Ensure dashboard work item, booking, and offer presentation models match the final server contract without leaking unused fields.
- **Verify (@Sentinel):** types, enum mappings, and nullability match the contract and no stale payload assumptions remain.

### 2.2 Services/Repositories

- [ ] (@Architect) Split `DashboardRepository` by responsibility and keep finance/admin reporting out of the standard dashboard data path.
- [ ] (@Architect) Introduce `tender_payment_coordinator` to centralize award/pay orchestration for both dashboard and task-request flows.
- [ ] (@Architect) Move all Supabase calls to services/repositories only; no dashboard view should instantiate backend services directly.
- [ ] (@Observability) Instrument services/repositories for correlation IDs and safe error logging.
- **Verify (@Sentinel):** all app-layer data access is RLS-safe, service-owned, and free of UI→Supabase leaks.

### 2.3 ViewModels

- [ ] (@Architect) Split `DashboardViewModel` into bounded notifiers or controllers for role, overview, work, inbox, and management responsibilities while keeping one temporary compatibility facade.
- [ ] (@Architect) Remove dead dashboard state and hidden management fetches that are not part of the live four-tab surface.
- [ ] (@Architect) Wire `DashboardCacheService` into production DI or remove dormant cache code if it is not retained.
- [ ] (@Architect) Move profile-service ownership out of dashboard by introducing a service-owned ViewModel for `MyServicesScreen`.
- **Verify (@Sentinel):** there is one source of truth per responsibility, transitions are recoverable, and duplicate query orchestration is gone.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_Dashboard_2026-03-01.md` with required events, fields, and redaction rules for payment, transition, and cache paths.
- [ ] (@Architect) Instrument service/viewmodel layers only, not widgets.
- [ ] (@ThreatModeler) Review logs for accidental PII, secret, or payment detail leakage.
- **Verify (@Sentinel):** telemetry is actionable, correlated, and privacy-safe.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Move booking, offer, and wallet snapshot widgets to their owning features and keep dashboard as a shell/composition layer.
- [ ] (@Pixel) Ensure `WorkItemCard` and related CTAs reflect the final permission contract so start/pay/review actions are either visible and wired or intentionally removed from the contract.
- [ ] (@Pixel) Replace no-op callbacks and TODO-only actions with explicit disabled/error states where the flow is not supported.
- [ ] (@Pixel) Ensure tender payment UI is bound to a ViewModel/coordinator instead of instantiating services in widget state.
- [ ] (@Pixel) Provide stable loading, empty, and error states for overview/bookings/work/inbox after the ViewModel split.
- **Verify (@Sentinel):** UX remains stable on slow, empty, stale, or failed data and all UI uses ViewModels only.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Reduce rebuild scope with selectors or narrower consumers for dashboard tabs/widgets.
- [ ] (@Pixel) Lazy-load tab data so Overview does not fetch hidden Bookings/Inbox/Manage datasets on first paint.
- [ ] (@Pixel) Correct counter-card navigation semantics so each card opens the section that owns the underlying state.
- **Verify (@Sentinel):** no visual or performance regression is introduced by the cleanup.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Verify all migration output against the contract files and live DB scans.
- [ ] (@Sentinel) Run transition/payment verify queries and confirm no shape/type mismatch remains.
- [ ] (@Sentinel) Validate compatibility windows for older clients if any temporary contract overlap exists.
- **Verify (@Sentinel):** no migration or contract mismatch remains.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the ThreatModeler negative checks for unauthorized task/booking updates, finance-view reads, profile-summary overreach, replayed payments, expired windows, and insufficient-funds flows.
- [ ] (@Sentinel) Run an RLS leak audit for all touched dashboard tables/views/RPCs after the final migrations.
- [ ] (@Sentinel) Run a storage audit even if dashboard currently has no direct storage paths, because planner.md requires live storage confirmation.
- **Verify (@Sentinel):** unauthorized access is blocked and no privileged client path remains.

### 4.3 Functional QA

- [ ] (@Sentinel) Write and execute a manual E2E script for client and freelancer dashboard flows, including overview, bookings, work, inbox, and tender payment.
- [ ] (@Sentinel) Cover edge cases: network failure, stale cache, expired payment deadline, insufficient funds, refresh lag, and unsupported state recovery.
- [ ] (@Sentinel) Add/expand automated unit and widget tests for dashboard shell, CTA rendering, tender payment, booking transitions, and cache injection.
- **Verify (@Sentinel):** behavior is consistent, crash-free, and non-regressive.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm required payment/transition/cancel/refund logs exist and support correlation.
- [ ] (@Sentinel) Confirm redaction rules remove sensitive values from logs.
- **Verify (@Sentinel):** telemetry is useful in production without privacy leakage.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md` for dashboard shell ownership, work/payment contracts, and any new ViewModel/service paths.
- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md` for actual dashboard views, grants, RPCs, and RLS behavior after live reconciliation.
- [ ] (@SlineDocs) Update `Sline_everything/MVP_ROADMAP.md` to reflect the post-remediation status of dashboard, wallet, and payment hardening.
- [ ] (@SlineDocs) Update `Sline_everything/STRUCTURE.md` and, if needed, `Sline_everything/CODE_REVIEW.md` with the final file layout and reusable review rules.
- [ ] (@SlineDocs) If the implementation materially changes architecture guidance, update `Sline_everything/ARCHITECTURE_ANALYSIS.md` current-live notes rather than historical sections.
- **Verify (@Sentinel):** docs match code and confirmed live DB reality, not stale intent.

---

## 7) Acceptance Criteria (MANDATORY)

- Dashboard no longer exposes direct authenticated client access to platform-wide financial metrics unless the user is explicitly authorized through a server-side admin contract.
- Dashboard task and booking workflow transitions are server-authoritative; direct client row updates are removed from dashboard-driven workflow paths.
- Tender payment award/pay flow succeeds on the happy path and cannot advance task/request state after ledger business-rule failure.
- Cross-user profile-summary reads return only the minimum fields required by live dashboard/profile-preview callers.
- `DashboardViewModel` is decomposed into bounded responsibilities or an equivalent structure, with a temporary compatibility facade only if needed for migration safety.
- Removed Manage-tab runtime debt, dead state, and dashboard-owned service coupling no longer exist in live code paths.
- Wallet snapshot loads correctly from dashboard entry without requiring the wallet screen to be visited first.
- Automated coverage exists for tender payment, transition guards, cache wiring, CTA rendering, and key dashboard surface regressions.
- Docs and live DB contract notes are synchronized, and any remaining `UNVERIFIED` live-drift items are explicitly resolved or kept behind a release gate.

## 8) Rollback Plan

- DB rollback/forward-fix steps:
  - Revoke or restore grants only via dedicated rollback migration files; do not hand-edit production grants.
  - If tender payment remediation causes live drift, prefer forward-fix to reconcile state machine and affected `task_requests` rows rather than partial rollback of money-related functions.
  - Keep old contract paths available during compatibility window only if required and only until Phase 4 validation passes.
- App rollback (flag/revert):
  - Preserve a compatibility facade at `lib/features/dashboard/viewmodels/dashboard_view_model.dart` until the refactor is stable.
  - If the new tender payment coordinator causes regressions, disable the new launch path behind the agreed rollout switch and route users away from award/pay until fixed.
  - Keep widget moves behind import-compatible wrappers for one release if necessary.
- Emergency disable strategy (if applicable):
  - Disable tender award/pay entry points from dashboard and task-request UI if live DB scan reveals unresolved contract drift.
  - Disable client finance/admin metrics access immediately if any non-admin read path remains.
  - Treat live Supabase auth/scan failure as a hard release gate for DB-sensitive changes.

## 9) References (From Scan)

- `/.agents/workflows/planner.md`
- `/.TODO/dashboard.TODO.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/ARCHITECTURE_ANALYSIS.md`
- `Sline_everything/CODE_REVIEW.md`
- `Sline_everything/STRUCTURE.md`
- `lib/main.dart`
- `lib/app/main_navigation_screen.dart`
- `lib/core/app_enums.dart`
- `lib/core/services/dashboard_cache_service.dart`
- `lib/features/dashboard/view/dashboard_screen.dart`
- `lib/features/dashboard/view/tabs/overview_tab.dart`
- `lib/features/dashboard/view/tabs/bookings_tab.dart`
- `lib/features/dashboard/view/tabs/work_tab.dart`
- `lib/features/dashboard/view/tabs/inbox_tab.dart`
- `lib/features/dashboard/view/tabs/manage_tab.dart`
- `lib/features/dashboard/view/widgets/work_item_card.dart`
- `lib/features/dashboard/view/widgets/booking_card.dart`
- `lib/features/dashboard/view/widgets/offer_card.dart`
- `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart`
- `lib/features/dashboard/view/widgets/manage_service_list.dart`
- `lib/features/dashboard/view/widgets/manage_task_list.dart`
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
- `lib/features/dashboard/data/dashboard_repository.dart`
- `lib/features/dashboard/data/mock/mock_dashboard_repository.dart`
- `lib/features/dashboard/models/activity_item.dart`
- `lib/features/booking/services/booking_service.dart`
- `lib/features/tasks/services/task_service.dart`
- `lib/features/tasks/view/tender_payment_screen.dart`
- `lib/features/tasks/viewmodels/task_requests_view_model.dart`
- `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
- `lib/features/wallet/services/ledger_service.dart`
- `lib/features/wallet/viewmodels/wallet_view_model.dart`
- `lib/features/wallet/view/wallet_screen.dart`
- `lib/features/profile/services/profile_summary_service.dart`
- `lib/features/profile/view/my_services_screen.dart`
- `lib/features/services/services/services_service.dart`
- `supabase/migrations/20260225_create_wallet_views.sql`
- `supabase/migrations/20260301_reconcile_orders_owner_contract.sql`
- `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql`
- `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql`
- `@mcp:supabase-mcp-server:` attempted live scan on 2026-03-01:
  - `execute_sql` for touched columns/policies/views/functions
  - `list_storage_buckets`
  - result: `Auth required`
