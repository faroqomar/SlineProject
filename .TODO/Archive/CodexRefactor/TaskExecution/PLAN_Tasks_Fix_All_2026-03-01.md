# 📌 Plan: Tasks Full Remediation

## 1) Goal

- Goal:
  - Fully remediate the `tasks` feature and its direct dependencies so tender discovery, task creation, offer flows, tender payment, task status handling, and supporting contracts are correct, MVVM-compliant, and safe against authorization/payment drift.
- Why:
  - Current repo evidence shows critical tender-payment safety gaps, contract drift around task-request RPCs, inconsistent task/profile hydration, task status mismatch, MVVM leaks in views, and missing automated coverage around the riskiest flows.
- Result:
  - A production-safe additive rollout that hardens tender payment, reconciles Flutter ↔ Supabase contracts, removes view-layer data access, closes direct-dependency drift, adds verification/observability/security coverage, and leaves docs aligned with code plus live DB reality.

## 2) Scope

### In-Scope

- `lib/features/tasks/**` including task discovery, create/edit, task details, request/offer flows, tender payment, image flow, and task models/viewmodels/services.
- Direct dependencies touched by the task feature:
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/core/services/qicard_payment_service.dart`
  - `lib/core/services/demo_payment_service.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/features/home/viewmodels/home_view_model.dart`
  - `lib/features/profile/services/profile_summary_service.dart`
  - `lib/features/categories/data/categories_repository.dart`
  - `lib/features/favorites/data/favorites_service.dart`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
  - `lib/features/dashboard/view/tabs/inbox_tab.dart`
  - `lib/features/wallet/services/ledger_service.dart`
  - `lib/features/booking/view/payment_checkout_screen.dart`
- Supabase objects directly used by the feature:
  - `tasks`
  - `task_requests`
  - `profiles`
  - `notifications`
  - `conversations`
  - `messages`
  - `task-images` bucket
  - `rpc_get_profile_summaries`
  - `award_task_offer`
  - `pay_awarded_offer`
  - `accept_task_request`
  - `reject_task_request`
  - `replace_task_request`
  - `get_client_awarded_unpaid_offers`
  - `get_freelancer_awarded_unpaid_offers`
  - `process_payment_event_ledger`

### Out-of-Scope

- Booking payment redesign outside the task feature, except as a reference implementation and compatibility dependency.
- Wallet UI redesign beyond the minimum observability and payment-verification needs for tender payments.
- Broad dashboard feature refactors outside the task-related inbox/payment paths.
- Any destructive schema cleanup that drops or renames live objects before the live Supabase scan confirms safety.

## 3) Evidence & Findings (From Scan)

### Existing

- The repo uses MVVM with `view/`, `viewmodels/`, `services/`, and `data/` folders per feature, and views are expected not to call Supabase directly.
- The `tasks` feature currently spans discovery, create/edit, details, requests, tender payment, and image handling under `lib/features/tasks/`.
- Tender payment is still driven by `TenderPaymentScreen` calling `QiCardPaymentService.processPayment()` and then `TaskService.payAwardedOffer()`.
- `QiCardPaymentService.processPayment()` is explicitly disabled for direct QiCard use and falls back to `DemoPaymentService`.
- `TaskService.payAwardedOffer()` calls the ledger RPC but does not inspect the returned JSON `ok` field before calling `pay_awarded_offer`.
- The repo contains two generations of tender-payment SQL contract files: `20260226_tender_award_payment_flow.sql` and `20260301_reconcile_orders_owner_contract.sql`.
- `TaskRequestsService.replaceOffer()` calls `replace_task_request`, but the reviewed `supabase/migrations/` files do not define that RPC.
- `TaskService` still uses `user_id`-only hydration in `getOpenTasksForHome()` and `getTaskById()`, while `Task.fromJson()` already supports `owner_id` and `client_id`.
- Flutter task status handling does not represent `delivered` distinctly; it is parsed back to `TaskStatus.inProgress`.
- Current task tests cover models, filter VM, task VM image helpers, create screen, and tender list rendering, but not tender payment or request-list mutation flows.

### Missing

- Live Supabase confirmation of actual tables, policies, RPCs, indexes, storage buckets, and drift status is missing because MCP access is blocked by authentication.
- A checked-in migration for `replace_task_request` is missing from the reviewed migration set.
- Tender-payment-specific unit/widget tests are missing from the reviewed test tree.
- A task-delivery-specific enum/status contract is missing in Flutter.
- A contract doc for the tender payment flow and task-request RPC shapes is missing in `.TODO/`.
- A dedicated threat model, RLS matrix, migration plan, and observability event list for the task/tender payment flow are missing in `.TODO/`.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Live Supabase scan conflict:
  - `@mcp:supabase-mcp-server:` scan was attempted on 2026-03-01 via `get_project_url`, `list_tables`, `list_storage_buckets`, and `list_migrations`; each call returned `Auth required`.
  - Risk: docs and checked-in SQL can only be treated as intent until the live scan is unblocked.
- Docs/code drift:
  - `Sline_everything/DEVELOPER_GUIDE/Task Feature.md` still describes simpler task/task_request ownership and older status assumptions than the current migrations and code paths.
  - `Sline_everything/SUPABASE_SETUP.md` documents `replace_task_request(...)`, but the reviewed migration set does not define it.
- Contract drift:
  - Tender payment is presented as a pay-later hardened flow in product docs/roadmap, but the task screen still uses the disabled demo fallback path.
  - Multiple tender-payment migrations define overlapping RPC names, increasing risk of operator confusion during rollback or forensic debugging.
- Security/money-flow risk:
  - Payment flow touches wallet/ledger state, so any rollout without live contract confirmation, observability, idempotency checks, and negative security tests is high risk.
- Compatibility risk:
  - Status normalization (`delivered`) and ownership hydration (`owner_id`) will affect dashboard, task details, discovery, and work-permission surfaces at once.

## 4) System Impact Map

- UI:
  - `TendersScreen`, `TaskDetailsScreen`, `CreateTaskScreen`, `RequestsListScreen`, `SubmitRequestSheet`, `TenderPaymentScreen`, task cards, dashboard inbox payment entrypoints.
- MVVM/App Logic:
  - `TaskViewModel`, `TaskRequestsViewModel`, `TaskFilterViewModel`, `HomeViewModel`, `DashboardViewModel`, `TaskRepository`, `TaskService`, `TaskRequestsService`.
- Database:
  - `tasks`, `task_requests`, `notifications`, `conversations`, `messages`, profile summary RPC, tender payment RPCs, ledger RPC.
- RLS/Security:
  - `tasks` policies, `task_requests` policies, `profiles` read contract, storage policies for `task-images`, tender payment authority boundary, role/ownership enforcement.
- Realtime/Notifications (if any):
  - Task request notifications, award/payment notifications, dashboard inbox refresh behavior, task-linked chat conversation creation, existing realtime message/notification surfaces impacted by lifecycle changes.
- Storage:
  - `task-images` private bucket and signed URL rendering path.
- Observability (if any):
  - Payment flow correlation, ledger failures, RPC drift detection, auth/RLS denial visibility, safe error/logging boundaries.
- Compatibility & Migration:
  - Additive-first Supabase migration path, compatibility wrappers around split services/screens, live-DB reconcile before deletions, task status compatibility window.
- Contracts:
  - Flutter `Task`/`TaskRequest` models, task/profile hydration shape, task-request RPC payloads, tender payment flow contract, dashboard/task shared payment entrypoints.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Freeze measurable success criteria for tender payment safety, task-request contract parity, task status handling, and MVVM boundary restoration.
- [ ] (@Architect) Confirm all entry points and consumers for the task flow, including `tasks` screens, dashboard inbox, deep links, and shared discovery surfaces.
- [ ] (@Architect) Confirm rollout order is additive-first: live contract scan → DB/security fixes → app-layer fixes → UI wiring → tests → docs sync.
- **Verify (@Sentinel):** done-conditions and rollback triggers are explicit before execution begins.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Produce `.TODO/THREAT_MODEL_tasks_tender_payment_2026-03-01.md` covering payment spoofing, RLS bypass attempts, duplicate award/pay actions, stale-offer replay, unauthorized role mutation, and private-storage misuse.
- [ ] (@ThreatModeler) Define negative checks for demo-payment bypass, unauthorized `pay_awarded_offer`, unauthorized `replace_task_request`, expired deadline replay, and cross-user profile leakage.
- **Verify (@Sentinel):** every negative case maps to a concrete Phase 4 test or verification step.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Produce `.TODO/CONTRACT_tasks_tender_flow_2026-03-01.md` for Flutter ↔ RPC ↔ dashboard/task shared payloads, including `Task`, `TaskRequest`, `award_task_offer`, `pay_awarded_offer`, `replace_task_request`, and profile hydration shape.
- [ ] (@APIContract) Define the canonical status contract for `open`, `assigned`, `in_progress`, `delivered`, `completed`, and payment sub-statuses used by tender flows.
- **Verify (@Sentinel):** the contract matches reviewed repo code and becomes the baseline for live Supabase reconciliation.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Produce `.TODO/MIGRATION_PLAN_tasks_tender_flow_2026-03-01.md` with introduce/backfill/enforce stages, compatibility window, rollback notes, and no destructive renames/drops unless live scan proves safety.
- [ ] (@DataMigration) Plan the reconcile path for duplicate tender-payment migrations and the missing `replace_task_request` contract without assuming live DB matches checked-in SQL.
- **Verify (@Sentinel):** migration phases are measurable, additive-first, and safe to pause after each stage.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Define an emergency disable strategy for tender payment entrypoints if server-authoritative payment cannot be completed safely during rollout.
- [ ] (@Observability) Define alerting/monitoring thresholds for payment flow failures and ledger mismatches during rollout.
- **Verify (@Sentinel):** rollback/disable strategy can stop unsafe tender payments without breaking unrelated task discovery or booking checkout.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Unblock `@mcp:supabase-mcp-server:` authentication and re-scan touched objects: tables, columns, enums, views, RPCs, triggers, indexes, RLS policies, storage buckets/policies, and realtime settings for task/notification/message surfaces.
- [ ] (@Supabase_Ops) Compare live reality against:
  - `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql`
  - `supabase/migrations/20260226_tender_award_payment_flow.sql`
  - `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql`
  - `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql`
  - `supabase/migrations/20260301_reconcile_orders_owner_contract.sql`
  - `Sline_everything/SUPABASE_SETUP.md`
- [ ] (@Supabase_Ops) Record live drift, especially around `replace_task_request`, tender payment RPC versions, task/request policies, `task-images` bucket policies, and any stale duplicate functions.
- **Verify (@Sentinel):** drift and the safe reconcile approach are documented before any DB change is executed.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Introduce any missing additive schema objects required for the canonical tender contract, including `replace_task_request` if absent live and needed by product requirements.
- [ ] (@Supabase_Ops) Normalize task/request indexes to match real query paths: pending-payment lookups, task-request paging, and owner/request hydration queries.
- [ ] (@DataMigration) If `delivered` becomes a first-class task status in app logic, confirm the live schema supports the full lifecycle without breaking dashboard/work surfaces.
- **Verify (@Sentinel):** no destructive changes are required to ship the safe contract; all new objects are additive and named consistently.

### 1.2 RLS

- [ ] (@Supabase_Ops) Reconcile `tasks` and `task_requests` RLS with the live scan and remove any need for client-side `profiles.active_role` mutation to satisfy authorization.
- [ ] (@Supabase_Ops) Verify `profiles` cross-user task hydration is served only through approved server-side RPCs and not by broadening profile read policies.
- [ ] (@Supabase_Ops) Produce `.TODO/RLS_MATRIX_tasks_2026-03-01.md` covering task owner, bidder/freelancer, unrelated authenticated user, unauthenticated user, and dashboard/task shared surfaces.
- **Verify (@Sentinel):** positive scenarios pass and negative scenarios fail without relying on UI-only checks.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Make tender-payment transitions server-authoritative and idempotent: one canonical award path, one canonical pay path, and explicit handling for expired or already-held requests.
- [ ] (@ThreatModeler) Require server-side guards for duplicate pay attempts, stale request replay, cross-owner payment attempts, and mismatched ledger/payment status.
- [ ] (@APIContract) Define whether task payment will use a new server-backed payment-init/recovery RPC or a temporary fail-closed disable path until that server flow exists.
- **Verify (@Sentinel):** the server enforces state transitions even if the client sends stale or malicious requests.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Execute the introduce/backfill/enforce plan only after live scan confirmation, leaving a compatibility window for Flutter changes if payloads/statuses differ.
- [ ] (@DataMigration) Add verification queries for:
  - duplicate active offers
  - missing `replace_task_request`
  - task requests with `held` but no valid ledger evidence
  - tasks in `delivered` state that Flutter would previously mis-parse
- **Verify (@Sentinel):** migration verification queries pass after each stage and rollback notes are tested on paper before production rollout.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Update `Task` status modeling so `delivered` is represented explicitly and no longer collapsed into `inProgress`.
- [ ] (@Architect) Align `TaskRequest` and submit/replace UI typing so offer price semantics are consistent end-to-end and do not rely on implicit truncation.
- [ ] (@APIContract) Align task/profile hydration shape so `owner_id`, `client_id`, and `user_id` resolve consistently across list/detail/create paths.
- [ ] (@Architect) Extend domain error mapping for tender payment, RPC-not-found, expired award, unauthorized role, and ledger failure cases.
- **Verify (@Sentinel):** model types, nullability, and status mappings match the contract and live DB reality once Phase 1 completes.

### 2.2 Services/Repositories

- [ ] (@Architect) Split `TaskService` into focused query/payment modules behind a compatibility facade to reduce lifecycle coupling and duplication.
- [ ] (@Architect) Refactor `TaskRepository` so it uses the injected Supabase client consistently for both auth and data operations.
- [ ] (@Architect) Remove client-side `profiles.active_role` mutation from `TaskRequestsService` and replace it with contract-safe UX handling.
- [ ] (@Architect) Centralize task/profile hydration into one helper/service so home/detail/create/dashboard callers do not each re-implement owner resolution.
- [ ] (@Architect) Keep storage-path-only behavior for task images and preserve signed URL generation in services/widgets only.
- [ ] (@Observability) Add correlation-aware logging to service/viewmodel layers for award, pay, replace, and hydration failures without leaking PII or secrets.
- **Verify (@Sentinel):** no task UI calls Supabase directly, no N+1/hydration drift remains, and payment/hydration logs are actionable without privacy leaks.

### 2.3 ViewModels

- [ ] (@Architect) Introduce dedicated task editor and tender payment/award ViewModels so `CreateTaskScreen`, `RequestsListScreen`, and `TenderPaymentScreen` become thin wiring layers.
- [ ] (@Architect) Make one source of truth for task-request mutations so task screens and dashboard inbox share the same award/pay behavior instead of duplicating partial logic.
- [ ] (@Architect) Remove hardcoded `limit: 100` refresh patterns and replace them with local item updates or page-size-consistent reloads.
- [ ] (@Architect) Ensure error/loading state supports recoverable retries for payment, replace-offer, and category load failures.
- **Verify (@Sentinel):** state transitions are correct, recoverable, and consistent across task and dashboard surfaces.

### 2.4 Observability (If needed)

- [ ] (@Observability) Produce `.TODO/OBSERVABILITY_tasks_tender_flow_2026-03-01.md` with event names, correlation IDs, and redaction rules for award, pay, ledger failure, RPC drift, and status mismatch cases.
- [ ] (@Architect) Instrument services/viewmodels only; remove any logging responsibility from UI widgets beyond UI-local presentation.
- [ ] (@ThreatModeler) Review the event set to ensure it catches abuse/failure patterns without exposing payment tokens, profile-private data, or raw gateway payloads.
- **Verify (@Sentinel):** telemetry is useful for production debugging and respects privacy/redaction boundaries.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Rewire `CreateTaskScreen` so category loading, validation, and submission all go through a ViewModel.
- [ ] (@Pixel) Rewire `RequestsListScreen` and `SubmitRequestSheet` so replace-offer, award, and refresh actions go through ViewModels only.
- [ ] (@Pixel) Rewire `TenderPaymentScreen` and dashboard inbox entrypoints to the canonical tender-payment flow and remove demo-payment assumptions.
- [ ] (@Pixel) Fix task title/context propagation into payment surfaces and eliminate build-time side effects such as modal auto-open callbacks in `build()`.
- [ ] (@Pixel) Ensure loading/empty/error states exist for category load, task-request load, replace-offer, award, and payment failure surfaces.
- **Verify (@Sentinel):** UI uses ViewModels only and remains stable under slow, empty, or failed backend responses.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Extract duplicated bookmark/heart UI into a shared widget for task cards and keep request-tile favorites behavior callback-driven.
- [ ] (@Pixel) Apply low-risk UX polish only after the core correctness/security work is stable.
- **Verify (@Sentinel):** no performance or behavioral regression is introduced by UI cleanup.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Verify Flutter models, RPC payloads, and live DB objects match the contract file produced in Phase 0.
- [ ] (@Sentinel) Run migration verification queries from the migration plan and record results in `.TODO/SENTINEL_QA_tasks_2026-03-01.md`.
- [ ] (@APIContract) Reconcile any live-shape differences found during QA before rollout continues.
- **Verify (@Sentinel):** there is no remaining mismatch between contract, code, and live DB objects.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute the ThreatModeler negative checks: fake payment success, unauthorized pay, unauthorized replace, unauthorized status update, expired deadline replay, duplicate payment, and private-storage access misuse.
- [ ] (@Sentinel) Run an RLS leak audit and storage audit against live Supabase after auth is unblocked.
- [ ] (@ThreatModeler) Validate that unauthorized access is impossible even if the client bypasses UI checks.
- **Verify (@Sentinel):** unauthorized reads/writes and payment-state spoofing fail reliably.

### 4.3 Functional QA

- [ ] (@Sentinel) Run manual E2E scripts for:
  - create tender
  - create booking task with packages
  - submit offer
  - replace offer
  - award offer
  - pay awarded offer
  - dashboard pay-now path
  - task delivery/status display
  - deep link to task details
- [ ] (@Sentinel) Cover edge cases: null/missing profile summary, network failure, stale request, expired payment deadline, invalid task title propagation, category load failure, and empty request list.
- [ ] (@Sentinel) Expand automated coverage:
  - unit tests for tender payment/ledger failure handling
  - unit tests for replace-offer contract handling
  - widget tests for `TenderPaymentScreen`, `RequestsListScreen`, and `SubmitRequestSheet`
  - extended model tests for `owner_id` hydration and `delivered` status
- **Verify (@Sentinel):** no crashes, no stale state regressions, and behavior is consistent across task and dashboard surfaces.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm required logs/events exist for award, pay, ledger failure, RPC drift, and rollback/disable actions.
- [ ] (@Sentinel) Confirm privacy redaction and no sensitive logs from UI, payment responses, or profile payloads.
- [ ] (@Observability) Validate correlation IDs survive across award → payment → ledger → dashboard refresh flow.
- **Verify (@Sentinel):** telemetry is actionable and privacy-safe.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` and `Sline_everything/DEVELOPER_GUIDE/Task Feature.md` to reflect the final task/tender contract, status model, and MVVM boundaries.
- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` with the final live-verified task/task_request/payment/RLS/storage contract, including `replace_task_request` if it exists.
- [ ] (@DocsKeeper) Update `Sline_everything/MVP_ROADMAP.md` to reflect tender payment hardening progress and the post-fix status.
- [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md` if service/viewmodel/screen splits or new `.TODO/` artifacts become part of the working structure.
- [ ] (@DocsKeeper) Update `Sline_everything/CODE_REVIEW.md` with the reusable lessons from the tender payment hardening and MVVM cleanup.
- **Verify (@Sentinel):** docs match code plus live DB reality and do not preserve outdated tender/payment assumptions.

---

## 7) Acceptance Criteria (MANDATORY)

- Tender payment cannot advance a task request to paid/active state from a demo or client-only payment result.
- `pay_awarded_offer` is never called from Flutter after a ledger failure or invalid gate response.
- No task feature view performs direct Supabase or direct service/repository mutations outside approved ViewModel boundaries.
- `replace_task_request` is either live and checked into repo migrations or removed from the Flutter flow with a safe replacement.
- Task/profile hydration works for canonical `owner_id` rows across discovery, task detail, and shared dashboard/task surfaces.
- Flutter represents the `delivered` task lifecycle explicitly and no longer collapses it into `inProgress`.
- Task request mutation flows behave the same from task screens and dashboard inbox entrypoints.
- Automated coverage exists for tender payment failure paths, replace-offer flow, and task status/hydration edge cases.
- Live RLS/storage checks pass after Supabase auth is unblocked.
- Logs/telemetry exist for payment and contract failures without leaking sensitive data.

## 8) Rollback Plan

- DB rollback / forward-fix:
  - Do not drop or rename existing live RPCs/policies in the initial rollout.
  - Roll back by disabling new call sites or routing back to the previous safe server contract, not by deleting live objects blindly.
  - If live scan reveals conflicting duplicate RPCs, prefer forward-fix deprecation with compatibility wrappers instead of destructive removal in the first pass.
- App rollback:
  - Keep compatibility wrappers around split services/screens until all tests and QA pass.
  - If tender payment hardening exposes a server-contract gap, disable the tender payment action in UI rather than reverting to demo payment behavior.
- Emergency disable strategy:
  - Hide or disable `TenderPaymentScreen` entrypoints from task screens and dashboard inbox if live payment validation cannot be guaranteed.
  - Preserve task discovery, task details, booking checkout, and non-payment task flows while tender payment is disabled.

## 9) References (From Scan)

- Docs:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Task Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Code:
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/app_enums.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/core/services/qicard_payment_service.dart`
  - `lib/core/services/demo_payment_service.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/features/home/viewmodels/home_view_model.dart`
  - `lib/features/profile/services/profile_summary_service.dart`
  - `lib/features/categories/data/categories_repository.dart`
  - `lib/features/favorites/data/favorites_service.dart`
  - `lib/features/tasks/data/task_repository.dart`
  - `lib/features/tasks/models/task_model.dart`
  - `lib/features/tasks/models/task_request_model.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_requests_service.dart`
  - `lib/features/tasks/services/task_image_service.dart`
  - `lib/features/tasks/view/create_task_screen.dart`
  - `lib/features/tasks/view/task_details_screen.dart`
  - `lib/features/tasks/view/tender_payment_screen.dart`
  - `lib/features/tasks/view/tenders_screen.dart`
  - `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`
  - `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart`
  - `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`
  - `lib/features/tasks/view/widgets/task_card.dart`
  - `lib/features/tasks/view/widgets/tender_task_card.dart`
  - `lib/features/tasks/view/widgets/booking_task_card.dart`
  - `lib/features/tasks/viewmodels/task_view_model.dart`
  - `lib/features/tasks/viewmodels/task_filter_view_model.dart`
  - `lib/features/tasks/viewmodels/task_requests_view_model.dart`
  - `lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart`
  - `lib/features/dashboard/view/tabs/inbox_tab.dart`
  - `lib/features/wallet/services/ledger_service.dart`
  - `lib/features/booking/view/payment_checkout_screen.dart`
  - `test/unit/tasks/task_view_model_test.dart`
  - `test/unit/tasks/task_filter_view_model_test.dart`
  - `test/unit/models/task_model_test.dart`
  - `test/unit/models/task_request_model_test.dart`
  - `test/widget/tasks/create_task_screen_test.dart`
  - `test/widget/tasks/tenders_screen_test.dart`
- SQL / Supabase:
  - `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql`
  - `supabase/migrations/20260226_tender_award_payment_flow.sql`
  - `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql`
  - `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql`
  - `supabase/migrations/20260301_reconcile_orders_owner_contract.sql`
- Live Supabase scan evidence:
  - `@mcp:supabase-mcp-server:get_project_url` on 2026-03-01 → `Auth required`
  - `@mcp:supabase-mcp-server:list_tables` on 2026-03-01 → `Auth required`
  - `@mcp:supabase-mcp-server:list_storage_buckets` on 2026-03-01 → `Auth required`
  - `@mcp:supabase-mcp-server:list_migrations` on 2026-03-01 → `Auth required`
