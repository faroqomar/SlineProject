> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# 📌 Plan: Orders Fix & Contract Reconcile

## 1) Goal

- Goal: restore the `orders` feature as a reachable, contract-safe, RLS-aligned client workflow for published tasks, offer decisions, and task chat entry.
- Why: current code, docs, and live Supabase reality drift on entry-point wiring, owner identity, task status values, and offer-action authorization; patching without a plan would compound the drift.
- Result: one verified execution path for `orders`, one canonical runtime contract for `Task` and `TaskRequest`, verified owner-only mutations, stable MVVM state handling, and documentation that matches live DB reality.

## 2) Scope

### In-Scope

- `lib/features/orders/`
- Orders tab/app entry wiring:
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/widgets/custom_bottom_nav_bar.dart`
  - `lib/main.dart`
- Direct app-layer dependencies used by orders:
  - `lib/features/tasks/models/task_model.dart`
  - `lib/features/tasks/models/task_request_model.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_requests_service.dart`
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/core/utils/error_mapper.dart`
- Live Supabase objects directly touched or contract-coupled to orders:
  - `public.tasks`
  - `public.task_requests`
  - `public.notifications`
  - `public.conversations`
  - `public.messages`
  - RPCs `accept_task_request`, `reject_task_request`, `replace_task_request`
  - storage buckets/policies for `avatars`, `task-images`, `chat-attachments`

### Out-of-Scope

- General dashboard/workspace redesign beyond the `orders` entry decision.
- Full chat feature refactor beyond the task-conversation launch path used by orders.
- Wallet/booking redesign beyond direct contract or auth impacts discovered in scan.
- Repo-wide cleanup outside the touched orders flow.

## 3) Evidence & Findings (From Scan)

### Existing

- A dedicated orders module exists with screen, viewmodel, service, and widgets:
  - `lib/features/orders/view/orders_dashboard_screen.dart`
  - `lib/features/orders/view/widgets/order_card.dart`
  - `lib/features/orders/view/widgets/offer_list_sheet.dart`
  - `lib/features/orders/viewmodels/orders_view_model.dart`
  - `lib/features/orders/services/orders_service.dart`
- App navigation still exposes an `orders` nav slot:
  - `lib/core/widgets/custom_bottom_nav_bar.dart`
  - `lib/app/main_navigation_screen.dart`
- Orders depends directly on task, offer, chat, notification, and error-mapping layers:
  - `lib/features/tasks/models/task_model.dart`
  - `lib/features/tasks/models/task_request_model.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_requests_service.dart`
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/core/utils/error_mapper.dart`
- Docs still describe orders as an implemented client feature over `tasks` and `task_requests`:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/STRUCTURE.md`
- Live Supabase scan confirms:
  - `public.tasks` has RLS enabled and includes `user_id`, `client_id`, `owner_id`, `assigned_freelancer_id`, `status`, `packages`.
  - `public.tasks.status` allows `open`, `assigned`, `in_progress`, `delivered`, `completed`, `canceled`, `closed`.
  - `public.task_requests` has RLS enabled and includes `bidder_id`, `freelancer_id`, `client_id`, `deleted_at`, `payment_status`, `awarded_at`, `payment_deadline`, `awarded_by`.
  - Current indexes and triggers already exist for task and offer flows.
  - `messages` and `notifications` are published to realtime; `tasks` and `task_requests` are not.
  - Storage buckets present: `avatars`, `task-images`, `chat-attachments`, `portfolio`.

### Missing

- No in-repo live SQL snapshot for the currently deployed `accept_task_request` / `reject_task_request` variants and touched RLS policies.
- No feature-specific tests were found for `OrdersViewModel`, `OrdersDashboardScreen`, `OfferListSheet`, or orders navigation reachability.
- No explicit contract artifact exists for orders runtime payloads and accepted status values.
- No explicit threat-model or RLS matrix artifact exists for orders mutations.

### Must NOT Duplicate

- Do not introduce a second owner-identity rule in app code; choose one canonical runtime owner contract and keep compatibility mapping explicit.
- Do not create new accept/reject paths beside the existing live RPC surface unless the old path is formally versioned and deprecated.
- Do not let both dashboard-global and offer-modal-local layers own the same loading/action state.
- Do not leave both `OrdersDashboardScreen` and `DashboardScreen` as ambiguous implementations of the `orders` tab.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Entry-point drift:
  - `lib/core/widgets/custom_bottom_nav_bar.dart` labels `NavView.orders` as `Dashboard`.
  - `lib/app/main_navigation_screen.dart` maps the orders slot to `DashboardScreen()` while `OrdersDashboardScreen` is commented out.
  - Docs still describe a standalone orders feature.
- Owner-contract drift:
  - `OrdersService` and `TaskService.getTasksByUser(...)` read orders by `tasks.user_id`.
  - Live `task_requests` owner-side RLS uses `tasks.client_id`.
  - Live `tasks` policies mix `user_id`, `client_id`, and `owner_id`.
- RPC auth drift:
  - The single-argument live `accept_task_request` and `reject_task_request` variants enforce owner checks through `tasks.user_id`.
  - Alternate overloads use `tasks.client_id`.
  - Current app code calls the single-argument variants.
- Status-contract drift:
  - Live DB uses `in_progress`; current app parsing in `Task.fromJson(...)` reads raw enum names only.
  - Live DB includes `delivered`; current app enum contract does not clearly model or map that state for orders.
- Offer-state drift:
  - `TaskRequest.fromMap(...)` defaults unknown statuses to actionable `pending`.
  - `OfferListSheet` shows accept/reject controls whenever the parsed status is pending.
- UX/error-state drift:
  - `OrdersViewModel.loadOrders()` logs failures and falls through to a no-data UI state.
  - `OrdersDashboardScreen` currently leaks raw exception text in some snackbars.
  - `OfferListSheet` uses `.then(...)` action chaining without in-flight guards or local failure handling.
- Security/abuse risk:
  - Live `notifications_insert_any` allows any authenticated insert, which makes client-side notification writes high-trust.
- Performance risk:
  - `OrdersDashboardScreen` recomputes filtered collections multiple times per build.
  - `OfferListSheet` watches global dashboard loading state even though it has its own fetch lifecycle.

## 4) System Impact Map

- UI:
  - orders tab label and target screen
  - dashboard loading/empty/error/list states
  - offer-sheet actions and task chat launch
- MVVM/App Logic:
  - `OrdersViewModel`
  - `OrdersService`
  - `TaskService`
  - `TaskRequestsService`
  - `ChatViewModel.getTaskConversation(...)`
- Database:
  - `tasks` owner/status fields and indexes
  - `task_requests` owner/status/payment fields, indexes, and triggers
  - `notifications`, `conversations`, `messages` as side-effect surfaces
- RLS/Security:
  - `tasks` policies
  - `task_requests` policies
  - overloaded task-request RPC authorization rules
  - notification insert scope
- Realtime/Notifications (if any):
  - realtime on `messages` and `notifications`
  - client notification writes triggered by offer accept/reject
- Storage:
  - private `avatars`, `task-images`, `chat-attachments`
- Observability (if any):
  - current state relies on `AppLogger`; no orders-specific correlation or contract-failure instrumentation exists
- Compatibility & Migration:
  - status parsing changes affect all task consumers
  - owner-contract fixes affect orders, offers, and chat launch assumptions
  - RPC reconciliation must be additive-first and rollback-safe
- Contracts:
  - `Task` read/write mapping
  - `TaskRequest` parsing and RPC return shape
  - `NavView.orders` entry contract

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Lock a measurable non-regression list for orders: reachable tab, correct task grouping, safe offer actions, clean error states, and owner-only writes.
- [ ] (@Architect) Decide whether `NavView.orders` must open `OrdersDashboardScreen` or whether the feature is intentionally subsumed by `DashboardScreen`.
- [ ] (@Architect) Lock the canonical runtime owner contract for orders reads and offer mutations (`user_id` vs `client_id` vs `owner_id`).
- [ ] (@Architect) Lock the canonical task and offer status values the app supports, including explicit handling for live `in_progress` and approved behavior for `delivered`.
- **Verify (@Sentinel):** no implementation starts until entry-point, owner, and status contracts are written down.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Create `.TODO/THREAT_MODEL_Orders_2026-03-01.md` covering unauthorized list/delete/accept/reject, raw-error leakage, duplicate decision attempts, stale-offer actions, and notification abuse.
- [ ] (@ThreatModeler) Define negative-test scenarios for mixed-owner drift and unsupported status payloads.
- **Verify (@Sentinel):** every identified abuse case maps to a Phase 4 verification step.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Create `.TODO/CONTRACT_Orders_Runtime_2026-03-01.md` for `Task`, `TaskRequest`, and task-request RPC payloads.
- [ ] (@APIContract) Record live DB fields that are internal-only versus UI-visible, and the compatibility mapping rules for legacy fields.
- **Verify (@Sentinel):** the contract artifact matches live DB scan results and app expectations.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Create `.TODO/MIGRATION_OrdersContract_2026-03-01.md` with introduce/backfill/enforce sequencing for any RLS, RPC, or schema reconciliation.
- [ ] (@DataMigration) Include compatibility-window and rollback-safe rules for owner or status contract changes.
- **Verify (@Sentinel):** migration sequencing is additive-first and measurable.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Decide whether orders routing or offer-decision behavior needs staged rollout or temporary read-only mode.
- [ ] (@Architect) Define an emergency disable strategy for offer decisions if live authz cannot be proven safe immediately.
- **Verify (@Sentinel):** rollback trigger and emergency-disable path are explicit.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan live `tasks`, `task_requests`, `notifications`, `conversations`, `messages`, RPC definitions, indexes, triggers, storage policies, and realtime publication immediately before implementation.
- [ ] (@Supabase_Ops) Export the exact live SQL for touched policies and task-request RPCs into repo-visible planning artifacts so code work is not anchored only to docs.
- **Verify (@Sentinel):** implementation inputs reflect live reality, not stale repo assumptions.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Decide whether the canonical app owner contract should read from `tasks.user_id`, `tasks.client_id`, or `tasks.owner_id` based on current live RLS and the least-risk compatibility path.
- [ ] (@Supabase_Ops) If live schema reconciliation is required, prefer additive helpers such as views/functions/trigger-safe compatibility updates over destructive renames or drops.
- [ ] (@DataMigration) Assess whether owner-based read paths need index adjustments once the canonical contract is chosen.
- **Verify (@Sentinel):** schema changes preserve existing clients and current data semantics.

### 1.2 RLS

- [ ] (@Supabase_Ops) Reconcile `tasks` and `task_requests` owner-side RLS so list/delete/accept/reject semantics align to the same owner rule.
- [ ] (@Supabase_Ops) Create `.TODO/RLS_MATRIX_Orders_2026-03-01.md` for positive and negative checks across list, offer view, delete, accept, reject, notifications, and chat launch prerequisites.
- [ ] (@ThreatModeler) Review whether `notifications_insert_any` should remain client-writable or move to a narrower server-controlled path for offer decisions.
- **Verify (@Sentinel):** unauthorized reads and cross-owner mutations fail with real tokens under live policies.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Reconcile overloaded `accept_task_request` and `reject_task_request` functions so all supported signatures enforce the same owner contract and state-transition rules.
- [ ] (@APIContract) Lock one canonical RPC return shape and error surface for Flutter to consume.
- [ ] (@ThreatModeler) Define idempotency and stale-state rules for repeated accept/reject attempts.
- **Verify (@Sentinel):** task-request decisions are atomic, owner-only, and contract-stable.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Apply any additive migrations or RPC revisions per the approved migration plan.
- [ ] (@Supabase_Ops) Re-run live verification queries for policies, indexes, triggers, and RPC definitions after migration.
- **Verify (@Sentinel):** post-migration live reality matches the locked contract.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Introduce a canonical task status codec in `lib/features/tasks/models/task_model.dart` that correctly maps live DB values, including `in_progress`, and explicitly handles any approved `delivered` behavior.
- [ ] (@Architect) Introduce a safe offer status codec in `lib/features/tasks/models/task_request_model.dart` so unknown or expanded statuses cannot fall back to actionable `pending`.
- [ ] (@APIContract) Align `Task` and `TaskRequest` fields/nullability to the locked runtime contract without exposing internal-only DB fields to UI.
- [ ] (@Architect) Fix `TaskRequest` equality/hashCode consistency and any stale field assumptions.
- **Verify (@Sentinel):** model mapping is deterministic, contract-aligned, and safe on unknown payloads.

### 2.2 Services/Repositories

- [ ] (@Architect) Update `lib/features/tasks/services/task_service.dart` so orders reads use the chosen owner contract and task status mapping consistently.
- [ ] (@Architect) Update `lib/features/tasks/services/task_requests_service.dart` to use explicit projections, correct soft-delete visibility, one RPC parser, and one notification side-effect path.
- [ ] (@Architect) Keep storage behavior path-only in services and do not move signed-media logic into widgets.
- [ ] (@Architect) Remove or formally justify unused orders-facing service surface such as `OrdersService.closeTask()`.
- **Verify (@Sentinel):** no touched view calls Supabase directly and each service uses one canonical contract path.

### 2.3 ViewModels

- [ ] (@Architect) Refactor `lib/features/orders/viewmodels/orders_view_model.dart` to expose explicit loading, empty, error, and refreshed data states.
- [ ] (@Architect) Move offer-sheet loading/action state into a dedicated orders-offers viewmodel or equivalent single source of truth.
- [ ] (@Architect) Ensure accept/reject/delete actions are in-flight safe, recoverable, and contract-aware.
- **Verify (@Sentinel):** state transitions remain correct under retry, failure, and stale-data scenarios.

### 2.4 Observability (If needed)

- [ ] (@Observability) Create `.TODO/OBSERVABILITY_Orders_2026-03-01.md` listing service/viewmodel events for load failures, action failures, contract mismatches, and rollback triggers.
- [ ] (@Architect) Add instrumentation only at service/viewmodel boundaries and route UI through friendly mapped error messages.
- **Verify (@Sentinel):** logs are useful for triage and do not leak sensitive payloads or raw DB text.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Align the bottom-nav label and the `orders` screen target with the spec-locked decision in `lib/core/widgets/custom_bottom_nav_bar.dart` and `lib/app/main_navigation_screen.dart`.
- [ ] (@Pixel) Keep `lib/features/orders/view/orders_dashboard_screen.dart` and `lib/features/orders/view/widgets/offer_list_sheet.dart` bound to viewmodels only; remove raw async orchestration from widget callbacks where it causes hidden failure paths.
- [ ] (@Pixel) Add stable dashboard and offer-sheet loading, empty, and error states with English-only strings.
- [ ] (@Pixel) Replace raw exception text in UI feedback with mapped, user-safe messages.
- **Verify (@Sentinel):** the UI stays stable on slow network, auth expiry, empty data, and stale-offer failures.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Reduce rebuild scope by splitting large dashboard sections and narrowing watches/selectors.
- [ ] (@Pixel) Make offer-sheet post-action behavior deterministic without relying only on close-and-reopen.
- **Verify (@Sentinel):** UX improves without introducing performance regressions.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Verify final app models and service payloads against `.TODO/CONTRACT_Orders_Runtime_2026-03-01.md` and the final live Supabase definitions.
- [ ] (@Sentinel) Run migration verification queries for touched RLS, indexes, triggers, and RPC signatures if any DB work was applied.
- [ ] (@APIContract) Reconfirm Flutter expectations against the final live RPC return shapes.
- **Verify (@Sentinel):** no contract mismatch remains between app code, docs, and live DB.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute negative checks for cross-owner list/delete/accept/reject attempts using real auth contexts.
- [ ] (@Sentinel) Force network, RLS, and stale-state failures to confirm the UI does not leak raw exception text.
- [ ] (@Sentinel) Validate storage access assumptions for avatars, task images, and chat attachments touched by the orders flow.
- [ ] (@ThreatModeler) Re-test notification abuse risk and confirm the accepted path is still least-privilege.
- **Verify (@Sentinel):** unauthorized access is blocked and sensitive internal details never surface to end users.

### 4.3 Functional QA

- [ ] (@Sentinel) Run manual E2E for orders-tab reachability, list load, tab filtering, edit, delete, offer view, accept, reject, and chat launch.
- [ ] (@Sentinel) Run edge-case checks for expired session, empty offers, soft-deleted offers, stale accepted offers, unsupported statuses, and partial notification failure.
- [ ] (@Sentinel) Run automated coverage for task/offer parser regressions, orders viewmodel state transitions, offer-sheet interactions, and navigation wiring.
- **Verify (@Sentinel):** no crashes, incorrect transitions, or orphaned entry points remain.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm required service/viewmodel logs or events exist for the new failure paths.
- [ ] (@Sentinel) Confirm privacy redaction for all logged contract or Supabase errors.
- **Verify (@Sentinel):** telemetry is actionable without leaking user-private or DB-internal data.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md` and `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md` to reflect the final orders entry point, owner contract, task status contract, and offer flow.
- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md` if touched RLS/RPC definitions were reconciled or exported.
- [ ] (@SlineDocs) Update `.TODO/CodexRefactor/01_FEATURES_INDEX.md` if feature boundaries or touchpoints change.
- [ ] (@SlineDocs) If the orders module is formally deprecated instead of restored, document that decision explicitly in roadmap and guide files.
- **Verify (@Sentinel):** docs match code and live DB reality after the fix set lands.

---

## 7) Acceptance Criteria (MANDATORY)

- The `orders` nav item opens the intended screen or an explicitly documented replacement; there is no silent label-target mismatch.
- Tasks with live DB status `in_progress` render in the correct orders state, and all approved live task statuses are mapped safely.
- Unknown or unsupported offer statuses never surface `Accept` or `Reject` controls.
- Orders load failures show a friendly error state instead of collapsing to an empty-state UX.
- Delete, accept, reject, and chat-launch failure paths do not expose raw exception or SQL/RPC text in UI.
- Owner-only actions are proven against live RLS and RPC behavior, not just client assumptions or docs.
- Orders state has one source of truth per flow; offer-sheet state is no longer coupled to unrelated dashboard loading state.
- Automated tests cover parser regressions, viewmodel state transitions, offer-sheet interactions, and orders entry wiring.
- Updated docs match final code and live Supabase behavior.

## 8) Rollback Plan

- DB rollback / forward-fix:
  - revert only additive migrations or RPC revisions that break the locked contract
  - prefer forward-fix with compatibility preservation over destructive rollback once app clients depend on new semantics
  - keep prior RPC signatures available through the compatibility window if rollout is staged
- App rollback:
  - revert navigation wiring independently if the restored orders route is product-invalid or unstable
  - revert status-codec changes independently if unrelated task consumers regress
  - keep service refactors behind thin delegators first so rollback stays file-local
- Emergency disable strategy:
  - if offer-decision auth cannot be proven safe, disable accept/reject UI while preserving read-only orders visibility
  - if orders is intentionally dormant, remove or rename the tab contract explicitly instead of leaving silent drift

## 9) References (From Scan)

- Planner workflow:
  - `.agents/workflows/planner.md`
- Required docs:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
- Existing audit/supporting artifacts:
  - `.TODO/orders.TODO.md`
  - `.TODO/CodexRefactor/01_FEATURES_INDEX.md`
- Feature and dependency code scanned:
  - `lib/app/main_navigation_screen.dart`
  - `lib/main.dart`
  - `lib/core/widgets/custom_bottom_nav_bar.dart`
  - `lib/core/utils/error_mapper.dart`
  - `lib/features/orders/view/orders_dashboard_screen.dart`
  - `lib/features/orders/view/widgets/order_card.dart`
  - `lib/features/orders/view/widgets/offer_list_sheet.dart`
  - `lib/features/orders/viewmodels/orders_view_model.dart`
  - `lib/features/orders/services/orders_service.dart`
  - `lib/features/tasks/models/task_model.dart`
  - `lib/features/tasks/models/task_request_model.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_requests_service.dart`
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/notifications/services/notification_service.dart`
- Live Supabase scan evidence:
  - `@mcp:supabase-mcp-server:list_tables` for `public.tasks`, `public.task_requests`, `public.notifications`, `public.conversations`, `public.messages`
  - `@mcp:supabase-mcp-server:execute_sql` for `pg_policies`, `pg_indexes`, `pg_proc`, `information_schema.triggers`, `pg_publication_tables`, and storage policies
  - `@mcp:supabase-mcp-server:list_storage_buckets`
