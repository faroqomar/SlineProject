# 📌 Plan: Notifications Server-Authority Alignment (Critic-Corrected)

## 1) Goal

- Goal: fix the notifications feature end-to-end so Flutter only reads/updates user-owned notifications, all notification creation stays server-side, deep links work for every live notification contract, and the feature ships with deterministic tests and synced docs.
- Why: live Supabase already enforces a server-authority notification model, but current app code still contains stale client write paths, an unsafe modal tap flow, unsupported live entity types, and incomplete test/release gates.
- Result: one source of truth per notification event, no client-side notification inserts, stable unread badge behavior, safe modal navigation, deterministic notification tests, and repo migrations/docs that match live reality.

## 2) Scope

### In-Scope

- Flutter feature code:
  - `lib/features/notifications/`
  - `lib/features/home/view/home_screen.dart`
  - `lib/main.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/core/utils/format_date.dart`
- Direct producer callsites that still invoke notification writes:
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_requests_service.dart`
  - `lib/features/booking/services/booking_service.dart`
- Notification-related migrations/docs:
  - `supabase/migrations/20260226_tender_award_payment_flow.sql`
  - `supabase/migrations/20260228_bookin_server_authority.sql`
  - `supabase/migrations/20260301_reconcile_orders_owner_contract.sql`
  - `supabase/migrations/20260301_harden_notification_writes.sql`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Notification tests:
  - `integration_test/notification_deeplink_flow_test.dart`
  - new unit/widget tests under `test/`
  - existing integration harness under `integration_test/support/`

### Out-of-Scope

- New push notifications or device notification channels
- New product requirements or redesign of the notifications experience
- Non-notification feature refactors outside the direct producer callsites above
- Storage bucket changes unless implementation proves notification payloads now depend on storage rules
- New edge functions unless implementation proves a DB-trigger/RPC path is insufficient

## 3) Evidence & Findings (From Scan)

### Existing

- The notifications feature already exists in Flutter with badge, modal, tile, model, service, and ViewModel.
- The home header already exposes the notification bell.
- A global notification provider already exists in `lib/main.dart`.
- The current Flutter service reads, streams, updates, and still tries to create notifications directly.
- Live Supabase confirms:
  - `public.notifications` columns match the Flutter row contract: `message`, `is_read`, `metadata`
  - `notifications_select_own` and `notifications_update_own` policies exist
  - `public.notifications` is in `supabase_realtime`
  - `private_create_notification(...)` and `private_upsert_notification(...)` exist
  - notification triggers already exist on `messages`, `task_requests`, `tasks`, and `bookings`
  - live DB has already applied `reconcile_orders_owner_contract` and `harden_notification_writes`
- Repo migrations already contain most of the live server-side notification authority logic.
- Existing test infrastructure already exists:
  - widget/unit harness via `test/test_support/pump_app.dart`
  - integration harness via `integration_test/support/helpers.dart`
  - env/preflight contract via `integration_test/support/preflight.dart` and `integration_test/support/t61_t70_env.dart`

### Missing

- Notification-specific unit tests
- Notification-specific widget tests
- Deterministic seeded notification fixture contract for integration
- Stable notification row selectors/keys for UI tests
- A locked contract for all live server-emitted notification `type` values and `related_entity_type` values
- An explicit producer decommission matrix mapping each client write callsite to its server-side replacement
- A delivery/PR slicing and flake policy section
- A clear fresh-bootstrap repair strategy for the stale February 26 migration

### Decisions Locked for This Plan

- Subscription scope: keep one `NotificationViewModel` provider instance, but make stream connection auth-aware and teardown on logout instead of passively auto-subscribing before session readiness.
- Deep-link contract: support live `related_entity_type = 'task_request'` in the app by routing from metadata using `conversation_id` first, else `task_id`.
- Fresh-bootstrap migration strategy: patch the stale historical repo migration for fresh environments and add a verify/reconcile step for already deployed/shared environments.
- Integration determinism: use seeded notification fixtures plus `--dart-define` identifiers; do not rely on opportunistic staging data.
- Release automation matrix: Android integration automation is required; iOS gets manual sanity until a deterministic iOS automation path is documented.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Flutter still tries to write notifications directly, but live RLS does not allow authenticated client inserts.
- Live DB emits notification entity kinds the current app deep-link layer does not fully support, especially `task_request`.
- `20260226_tender_award_payment_flow.sql` still contains stale notification column names for fresh bootstrap.
- `Sline_everything/SUPABASE_SETUP.md` still documents outdated realtime publication state for notifications.
- The current integration test is staging-backed and not deterministic enough to act as a release gate by itself.

## 4) System Impact Map

- UI:
  - `NotificationBadgeButton`
  - `NotificationsModal`
  - `NotificationTile`
  - home header bell
  - modal loading/empty/error/retry states
  - stable notification row selectors/keys
- MVVM/App Logic:
  - `NotificationViewModel` auth-aware lifecycle
  - `NotificationViewModel` no `BuildContext`/`Provider` navigation ownership
  - `NotificationService` read/update-only
  - notification-routing adapter for live entity kinds including `task_request`
- Database:
  - preserve live `private_create_notification(...)`
  - preserve live `private_upsert_notification(...)`
  - preserve current trigger-driven event generation
  - repair stale historical migration for fresh bootstrap
  - capture/version live policies if still missing locally
- RLS/Security:
  - keep select/update own only
  - keep direct client insert denied
  - add two-user negative checks and codebase grep gate
- Realtime/Notifications:
  - keep `public.notifications` in `supabase_realtime`
  - ensure exactly one active stream per authenticated session
- Storage:
  - no planned changes
- Observability:
  - move notification failure logging to service/viewmodel level
  - redact raw message content and unnecessary IDs
  - add unsupported-type telemetry
- Compatibility & Migration:
  - live DB is reality
  - fresh bootstrap must also work from repo
  - use additive or forward-fix steps for deployed/shared environments
- Contracts:
  - app consumes live `public.notifications` schema
  - server-side functions/triggers create notifications
  - app routes from `related_entity_type` plus metadata contract
- Delivery:
  - split into DB/contract, app cleanup, tests/docs slices
  - block release on deterministic test and RLS gates

---

# ✅ Execution Phases (Checklist)

## Phase 0: Test Infrastructure Gate

> Primary: @Sentinel

### 0.0 Notification Test Baseline

- [ ] (@Sentinel) Create `.TODO/TEST_notifications_2026-03-01.md` covering:
  - unit/widget/integration split
  - reusable harnesses already available
  - deterministic fixture manifest/seed contract
  - required `--dart-define` values
  - timeout budget per test type
  - rerun/flake threshold
  - failure artifact and log-tagging convention
- [ ] (@Architect) Confirm notification widget tests will reuse `test/test_support/pump_app.dart` rather than invent a second widget harness.
- [ ] (@Sentinel) Confirm integration tests will reuse `integration_test/support/helpers.dart`, `preflight.dart`, and `t61_t70_env.dart`.
- [ ] (@Pixel) Add stable selectors planned for:
  - bell button
  - modal shell
  - empty/error states
  - notification row by ID
- **Verify (@Sentinel):** no notification test work starts before the fixture contract, selector plan, timeout budget, and rerun policy exist.

### 0.1 Spec Lock

- [ ] (@Sentinel) Write `.TODO/ACCEPTANCE_notifications_2026-03-01.md` with measurable done conditions.
- [ ] (@Architect) Lock touched modules and direct producer callsites.
- [ ] (@APIContract) Lock the app-side contract: Flutter reads/updates only; DB triggers/functions/RPCs create notifications.
- **Verify (@Sentinel):** acceptance, touched files, and ownership boundaries are fixed before implementation.

### 0.2 Threat Model

- [ ] (@ThreatModeler) Create `.TODO/THREAT_notifications_2026-03-01.md` covering:
  - cross-user notification injection
  - unauthorized read/update
  - `task_request` route misuse
  - stale-session stream behavior
  - metadata leakage in logs
  - deterministic test seed abuse/failure cases
- [ ] (@Observability) Define privacy redaction rules for notification logs and crash events.
- **Verify (@Sentinel):** every threat maps to a Phase 4 check.

### 0.3 Contracts

- [ ] (@APIContract) Create `.TODO/CONTRACT_notifications_2026-03-01.md` documenting:
  - `public.notifications` live columns
  - all live server-emitted `type` values observed in migrations/live functions
  - supported `related_entity_type` values
  - routing rules for `task_request` using metadata (`conversation_id` first, else `task_id`)
  - allowed UI fallbacks for unsupported values
- [ ] (@APIContract) Create a producer matrix section listing every event family and its server-side source of truth.
- **Verify (@Sentinel):** contract doc covers every event family before any client write path is removed.

### 0.4 Migration Plan

- [ ] (@DataMigration) Create `.TODO/MIGRATION_notifications_2026-03-01.md` with separate tracks for:
  - fresh bootstrap repair
  - deployed/shared environment verification
  - policy-source capture if local SQL is still missing
  - rollback and forward-fix rules
- [ ] (@Supabase_Ops) Record the exact environments that must already be on the March 1 notification-hardening baseline before app cleanup merges.
- **Verify (@Sentinel):** migration sequence is explicit and environment-safe.

### 0.5 Delivery Plan

- [ ] (@Sentinel) Define PR slices:
  - PR1: contract + migration baseline + docs drift repair
  - PR2: app logic cleanup + MVVM/tap-flow fixes
  - PR3: tests + docs + release gates
- [ ] (@Architect) Add per-PR done criteria and reviewer checklist.
- **Verify (@Sentinel):** every slice has entry/exit criteria before code changes start.

---

## Phase 1: Data/Contracts Gate

> Primary: @Supabase_Ops

### 1.0 Live Supabase Reconfirmation

- [ ] (@Supabase_Ops) Re-scan live Supabase and capture into `.TODO/MIGRATION_notifications_2026-03-01.md`:
  - `public.notifications` columns
  - `notifications_select_own`
  - `notifications_update_own`
  - notification indexes
  - `private_create_notification(...)`
  - `private_upsert_notification(...)`
  - notification triggers
  - realtime publication membership
  - applied migration baseline
- [ ] (@Sentinel) Compare the live scan against the repo migrations and contract doc.
- **Verify (@Sentinel):** no new drift exists beyond what this plan already addresses.

### 1.1 Historical Migration Repair

- [ ] (@DataMigration) Patch `supabase/migrations/20260226_tender_award_payment_flow.sql` so fresh bootstrap uses the live notification column contract.
- [ ] (@Supabase_Ops) Ensure the repaired historical file does not change intended business semantics, only the stale column contract.
- [ ] (@Sentinel) Validate a branch DB can apply repo migrations through March 1 after the patch.
- **Verify (@Sentinel):** fresh bootstrap succeeds without notification-contract failure.

### 1.2 Policy Source Capture

- [ ] (@Supabase_Ops) If versioned SQL still lacks the live `notifications_select_own` / `notifications_update_own` policy definitions, add an idempotent migration that captures them.
- [ ] (@Supabase_Ops) Confirm there is still no client insert policy for authenticated users.
- [ ] (@ThreatModeler) Write `.TODO/RLS_notifications_matrix_2026-03-01.md` with exact positive/negative checks.
- **Verify (@Sentinel):** local SQL now fully represents the live notification security contract.

### 1.3 Event Family Verification Matrix

- [ ] (@APIContract) Build an explicit event-family matrix:
  - chat message insert -> `messages_after_insert_notify_receiver()`
  - task request submit -> `task_requests_after_insert_notify_owner()`
  - task owner close/cancel -> `tasks_after_status_change_notify_parties()`
  - booking insert/update -> `fn_booking_server_notifications()`
  - task accept/reject -> `accept_task_request(...)` / `reject_task_request(...)`
  - award/payment flows -> `private_create_notification(...)` usage inside the tender/payment RPC chain
- [ ] (@Supabase_Ops) Confirm each event family is covered server-side in repo SQL and live DB.
- **Verify (@Sentinel):** no client event source remains without a verified server-side writer.

### 1.4 Data Contract Freeze

- [ ] (@APIContract) Freeze the supported notification `type` list and entity-kind list for this release.
- [ ] (@Architect) Decide exact app-side mapping for each server-emitted type to icon/category/route behavior.
- **Verify (@Sentinel):** app mapping and server-emitted values are one-to-one or explicitly safely grouped.

---

## Phase 2: Security/RLS Gate

> Primary: @ThreatModeler

### 2.0 Codebase Security Cleanup Plan

- [ ] (@ThreatModeler) Convert “remove client-side writes” into a hard grep gate using exact patterns:
  - `createNotification(`
  - `createOrUpdateNotification(`
  - any direct `.from('notifications').insert(` outside approved DB migration code
- [ ] (@Architect) Document approved remaining references, if any, and why they are safe.
- **Verify (@Sentinel):** the grep gate is part of the release checklist before implementation starts.

### 2.1 RLS Negative/Positive Checks

- [ ] (@Supabase_Ops) Define exact verify queries/tests for:
  - user A select own notifications = allowed
  - user A select user B notifications = denied/empty
  - user A update own notification = allowed
  - user A update user B notification by ID = denied/0 rows
  - user A insert notification directly = denied
- [ ] (@Sentinel) Bind these checks to Phase 4 execution, not just documentation.
- **Verify (@Sentinel):** every security rule has a concrete query or test.

### 2.2 Logging and Privacy Cleanup

- [ ] (@Observability) Remove or redact notification log lines that expose unnecessary IDs or raw content.
- [ ] (@Architect) Ensure unsupported-type and deep-link-failure telemetry does not include sensitive payloads.
- **Verify (@Sentinel):** logs are actionable and privacy-safe.

---

## Phase 3: Backend/API Alignment in App Layer

> Primary: @Architect

### 3.0 Service Ownership Cleanup

- [ ] (@Architect) Refactor `lib/features/notifications/services/notification_service.dart` so it becomes read/update-only.
- [ ] (@Architect) Remove or deprecate `createNotification(...)` and `createOrUpdateNotification(...)` in a way that blocks future business-layer reuse.
- [ ] (@Architect) Keep explicit current-user filters for reads and updates as defense-in-depth.
- **Verify (@Sentinel):** notification service no longer owns cross-user writes.

### 3.1 Producer Decommission Matrix

- [ ] (@Architect) Remove duplicated client-side notification writes from:
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_requests_service.dart`
  - `lib/features/booking/services/booking_service.dart`
- [ ] (@APIContract) For each removed callsite, record the exact server-side replacement from the event-family matrix.
- [ ] (@Sentinel) Add a release grep gate proving no producer callsite remains.
- **Verify (@Sentinel):** business notification writes exist only server-side.

### 3.2 Type and Entity Contract Handling

- [ ] (@Architect) Update the Flutter notification parsing/model layer to support every live server-emitted `type` value for this release.
- [ ] (@Architect) Add a routing adapter that supports live `related_entity_type` values, especially `task_request` using metadata.
- [ ] (@Architect) Add explicit behavior for unsupported values:
  - safe UI fallback
  - telemetry event
  - no crash
- **Verify (@Sentinel):** live DB rows cannot produce an unsupported crash path.

### 3.3 ViewModel Lifecycle and MVVM Repair

- [ ] (@Architect) Remove `BuildContext` and `Provider` usage from `NotificationViewModel`.
- [ ] (@Architect) Implement auth-aware stream lifecycle:
  - connect only when session is ready
  - clear state on logout
  - prevent duplicate listeners
- [ ] (@Architect) Add explicit loading/error/retry state transitions.
- **Verify (@Sentinel):** the ViewModel is context-free and lifecycle-safe.

---

## Phase 4: UI/Integration Gate

> Primary: @Pixel

### 4.0 Modal Tap-Flow Fix First

- [ ] (@Pixel) Refactor the modal interaction so it no longer pops and reuses its own disposed context.
- [ ] (@Pixel) Route notification taps from a stable parent context or selection callback owned by the view layer.
- **Verify (@Sentinel):** widget tests prove no disposed-context navigation remains.

### 4.1 Stable Selectors and State Wiring

- [ ] (@Pixel) Add stable keys for:
  - bell button
  - modal shell
  - loading state
  - empty state
  - error state
  - notification row by row ID
- [ ] (@Pixel) Standardize modal opening through one public path only.
- [ ] (@Pixel) Ensure UI reads only from ViewModel state and routing adapter outputs.
- **Verify (@Sentinel):** tests can target notification UI deterministically.

### 4.2 UX Completion

- [ ] (@Pixel) Add visible retryable error state in the modal.
- [ ] (@Pixel) Keep strings English-only.
- [ ] (@Pixel) Narrow rebuild scope for unread count updates if implementation shows unnecessary rebuilds.
- **Verify (@Sentinel):** slow/empty/error UX is stable and no English-string regression exists.

---

## Phase 5: Polish + QA + Release

> Primary: @Sentinel

### 5.0 Unit and Widget Tests

- [ ] (@Sentinel) Add model tests for notification type parsing and contract handling.
- [ ] (@Sentinel) Add ViewModel tests for:
  - auth-aware connect/disconnect
  - clear on logout
  - read/update error transitions
  - unsupported-type handling
- [ ] (@Sentinel) Add widget tests for:
  - badge rendering
  - modal loading/empty/error/list states
  - mark-all behavior
  - stable row selection
  - task-request route selection callback behavior
- **Verify (@Sentinel):** the feature has deterministic unit/widget coverage for the critical paths.

### 5.1 Integration Stabilization

- [ ] (@Sentinel) Replace opportunistic notification selection in `integration_test/notification_deeplink_flow_test.dart` with a seeded notification contract.
- [ ] (@Sentinel) Use `T61T70Env` / preflight for exact fixture IDs and target entity expectations.
- [ ] (@Sentinel) Enforce bounded waits, rerun limit, and log-tagging from `.TODO/TEST_notifications_2026-03-01.md`.
- [ ] (@Sentinel) Automation target:
  - Android integration required
  - iOS manual sanity required until deterministic automation is defined
- **Verify (@Sentinel):** integration no longer depends on arbitrary staging notification data.

### 5.2 Security and Functional Validation

- [ ] (@Sentinel) Execute two-user RLS checks from `.TODO/RLS_notifications_matrix_2026-03-01.md`.
- [ ] (@Sentinel) Execute functional smoke scenarios for every event family in the producer matrix.
- [ ] (@ThreatModeler) Execute negative cases from `.TODO/THREAT_notifications_2026-03-01.md`.
- **Verify (@Sentinel):** the feature is safe, functional, and non-flaky.

### 5.3 Documentation Sync

- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` for:
  - notification write contract
  - realtime publication state
  - current policy source references
  - current trigger/function sources
- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` to say notifications are server-generated and client read/update-only.
- [ ] (@DocsKeeper) Update `Sline_everything/MVP_ROADMAP.md` notification status/note if the feature is now execution-safe.
- **Verify (@Sentinel):** docs match code and live DB.

### 5.4 Release Gate

- [ ] (@Sentinel) Run release grep gates:
  - no client notification writes in business features
  - no `NotificationViewModel` `BuildContext` routing ownership
- [ ] (@Sentinel) Verify PR1/PR2/PR3 done criteria and reviewer checklist completion.
- [ ] (@Sentinel) Verify flake budget is not exceeded.
- **Verify (@Sentinel):** release gate passes only if data/security/backend/UI/test/docs all pass together.

## 5) Acceptance Criteria (MANDATORY)

- The app no longer writes notifications directly from chat/tasks/task-requests/booking business code.
- `NotificationService` is read/update-only and user-scoped.
- `NotificationViewModel` is context-free and auth-aware in stream lifecycle.
- `task_request` notifications route correctly using metadata.
- The modal tap flow no longer navigates from a disposed sheet context.
- Fresh bootstrap from repo migrations succeeds through the March 1 notification-hardening baseline.
- Two-user RLS checks pass for select/update own and fail for cross-user select/update/insert.
- Notification unit/widget tests exist and pass.
- Notification integration uses deterministic seeded fixture data and stable selectors.
- Docs match live DB and final code behavior.

## 6) Rollback Plan

- DB rollback / forward-fix:
  - If a historical-migration patch causes issues, revert the repo patch and re-run validation on a branch DB while keeping deployed environments unchanged.
  - If deployed-environment verification fails, issue a forward-fix migration rather than altering live-applied policy/function state manually.
- App rollback:
  - Revert PR2 app cleanup if routing or lifecycle regressions appear.
  - Keep the server-side DB notification model intact during app rollback.
- Emergency disable strategy:
  - If deep-link routing is unstable, disable tap-through behavior while keeping notification read visibility.
  - Do not re-enable client-side direct notification inserts as an emergency fallback.

## 7) References (From Scan)

- Docs:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Flutter code:
  - `lib/main.dart`
  - `lib/features/home/view/home_screen.dart`
  - `lib/features/notifications/models/notification_model.dart`
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/features/notifications/viewmodels/notification_view_model.dart`
  - `lib/features/notifications/view/notifications_modal.dart`
  - `lib/features/notifications/view/widgets/notification_badge_button.dart`
  - `lib/features/notifications/view/widgets/notification_tile.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/core/utils/format_date.dart`
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/tasks/services/task_service.dart`
  - `lib/features/tasks/services/task_requests_service.dart`
  - `lib/features/booking/services/booking_service.dart`
- Tests/harness:
  - `test/test_support/pump_app.dart`
  - `integration_test/support/helpers.dart`
  - `integration_test/support/preflight.dart`
  - `integration_test/support/t61_t70_env.dart`
  - `integration_test/notification_deeplink_flow_test.dart`
- Repo migrations:
  - `supabase/migrations/20260226_tender_award_payment_flow.sql`
  - `supabase/migrations/20260228_bookin_server_authority.sql`
  - `supabase/migrations/20260301_reconcile_orders_owner_contract.sql`
  - `supabase/migrations/20260301_harden_notification_writes.sql`
- Live Supabase evidence:
  - live notifications columns
  - live notifications policies
  - live notification indexes
  - live notification triggers
  - live `private_create_notification(...)`
  - live `private_upsert_notification(...)`
  - live `supabase_realtime` membership for `public.notifications`
  - live applied migrations including March 1 notification hardening
