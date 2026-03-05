# 📌 Plan: Chat Security, Contract, and Realtime Hardening v2

## 1) Goal

- Goal:
  - Bring Chat into one verified state across Flutter, live Supabase RLS/storage/realtime, and project documentation without breaking valid user flows.
- Why:
  - Current Chat still has confirmed live security drift, app/backend contract drift, and incorrect realtime assumptions.
- Result:
  - Chat becomes least-privilege, contract-accurate, server-authoritative for sensitive actions, deterministic under realtime fallback, and releasable with clear rollback gates.

## 2) Scope

### In-Scope

- Flutter Chat feature and direct dependencies:
  - `lib/features/chat/**`
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/features/tasks/viewmodels/task_view_model.dart`
  - `lib/features/tasks/view/task_details_screen.dart`
- Chat tests and integration flows:
  - `test/widget/chat/**`
  - `test/unit/models/message_model_test.dart`
  - `integration_test/chat_message_flow_test.dart`
  - `integration_test/notification_deeplink_flow_test.dart`
  - `integration_test/support/**`
- Live Supabase objects touched by Chat:
  - tables: `conversations`, `messages`, `notifications`, `tasks`, `profiles`, `favorites`
  - enum: `message_type_enum`
  - functions/RPCs: `start_task_conversation_v1`, `mark_conversation_delivered`, `mark_conversation_seen`
  - trigger functions: `messages_before_insert_validate`, `messages_after_insert_offer_accept`, `messages_after_insert_notify_receiver`, `conversations_before_insert_guard`, `normalize_conversation_users`
  - helper functions used in policies: `is_conversation_participant`, `is_client`
  - storage bucket: `chat-attachments`
  - realtime publication: `supabase_realtime`
- Docs to reconcile after fixes:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`

### Out-of-Scope

- New Chat product features such as typing indicators, search, audio/file workflows beyond the existing image-attachment scope.
- Broad Notifications feature refactors outside Chat-triggered notification ownership validation.
- Unrelated index cleanup outside Chat-critical security/correctness fixes.
- Any expansion of offer semantics beyond the approved task-linked contract.

## 3) Evidence & Findings (From Scan)

### Existing

- Chat feature exists with current MVVM shape:
  - `lib/features/chat/view/messages_screen.dart`
  - `lib/features/chat/view/chat_screen.dart`
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/chat/services/attachment_service.dart`
  - `lib/features/chat/attachments/**`
- Chat is app-root provided and reachable from the main navigation surface:
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
- Direct entry paths exist:
  - booking starts task-linked chat via `lib/features/booking/viewmodels/booking_view_model.dart`
  - deep links resolve conversations via `lib/core/services/deep_link_service.dart`
- Test baseline exists already:
  - widget harness: `test/test_support/pump_app.dart`
  - widget chat tests: `test/widget/chat/chat_screen_test.dart`
  - model test: `test/unit/models/message_model_test.dart`
  - integration harness: `integration_test/support/helpers.dart`
  - integration preflight: `integration_test/support/preflight.dart`
  - runtime chat flow: `integration_test/chat_message_flow_test.dart`
- Current code reality relevant to the fix:
  - `MessageService` no longer performs client-side notification creation.
  - `MessageService.deleteConversation(...)` still writes client timestamps directly.
  - `MessageService.subscribeToMessages(...)` still collapses snapshots to `rows.last`.
  - `MessageService.subscribeToConversations(...)` still assumes `conversations` realtime exists.
  - `ChatScreen` still writes offer payload key `delivery` and clears the input before send success is confirmed.
  - `ChatViewModel.acceptOffer(...)` and `rejectOffer(...)` still send camelCase message types.
- Live Supabase scan confirms:
  - `messages` and `conversations` RLS are enabled, but `messages` currently has overly broad authenticated read/insert policies.
  - `chat-attachments` bucket is private, but `storage.objects` select is too broad for authenticated users.
  - live `message_type_enum` uses snake_case values such as `offer_accepted` and `offer_rejected`.
  - live offer validation requires payload field `days`, not `delivery`.
  - live `supabase_realtime` includes `messages` and `notifications`, not `conversations`.
  - live server trigger already owns receiver notifications.

### Missing

- No Chat SQL migration history exists in `supabase/migrations/` for the current live Chat policies/functions.
- No Chat-specific decision pack exists for direct DM rules, offer scope, or realtime list strategy.
- No Chat-specific service/viewmodel tests exist.
- No participant-scoped storage select helper/policy exists for `chat-attachments`.
- No server-side archive RPC exists for per-user conversation hiding.
- No Chat-specific rollout matrix or PR slicing artifact exists.

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Flutter writes camelCase message types while live DB uses snake_case enum values.
- Flutter writes offer payload key `delivery` while live DB validates `days`.
- Live `messages` policies include permissive authenticated read/insert access alongside stricter participant policies.
- Live `chat-attachments` storage select policy allows any authenticated user to select bucket objects.
- App subscribes to `conversations` realtime while live publication does not include `conversations`.
- Docs conflict on whether direct DMs require favorites.
- Docs and app comments conflict with live RPC truth on who may start task-linked chat.
- `startConversationByClient(...)` is misleadingly named relative to live backend behavior.
- `subscribeToMessages(...)` does not model Supabase stream snapshots correctly.
- Earlier planning assumed Chat still created client notifications; current repo state disproves that and the new plan must not preserve stale work.

## 4) System Impact Map

- UI:
  - `lib/features/chat/view/messages_screen.dart`
  - `lib/features/chat/view/chat_screen.dart`
  - `lib/features/chat/view/widgets/chat_context_widget.dart`
  - `lib/features/chat/view/widgets/conversation_list_tile.dart`
  - `lib/features/chat/view/widgets/offer_message_bubble.dart`
  - `lib/features/chat/attachments/widgets/attachment_message_tile.dart`
- MVVM/App Logic:
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/chat/services/attachment_service.dart`
  - `lib/features/chat/attachments/services/send_attachment_usecase.dart`
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/core/services/deep_link_service.dart`
- Database:
  - `public.conversations`
  - `public.messages`
  - `public.notifications`
  - `public.tasks`
  - `public.profiles`
  - `public.favorites`
  - `public.message_type_enum`
- RLS/Security:
  - `public.messages` policies
  - `public.conversations` policies
  - `public.notifications` policies
  - `storage.objects` policies for `chat-attachments`
- Realtime/Notifications:
  - `supabase_realtime`
  - message stream handling in `MessageService` / `ChatViewModel`
  - server-side notification trigger on `messages`
- Storage:
  - `chat-attachments`
  - current path contract `convos/<conversation_id>/<filename>`
  - signed URL resolution in widget/service layers only
- Observability:
  - `AppLogger`
  - Chat service/viewmodel logging and user-safe error mapping
- Compatibility & Migration:
  - additive DB rollout before app switch-over
  - temporary read compatibility for legacy offer payload rendering
  - fallback-first conversation list strategy before optional realtime expansion
- Contracts:
  - direct DM authorization rule
  - task-linked initiator rule
  - offer message scope and payload shape
  - server-owned notifications
  - server-owned archive timestamps
  - participant-scoped attachment access

---

# ✅ Execution Phases (Checklist)

## Phase 0: Test Infrastructure, Decisions, and Rollout Control

> Goal: lock the Chat contract and make the fix executable before any SQL or Flutter change.
> Why: unresolved decisions and missing Chat-specific test/release artifacts will invalidate later work.
> How: create the decision pack, test strategy, selector inventory, threat model, and rollout matrix first.
> Result: one approved baseline for implementation, review, and rollback.
>
> Primary: @Sentinel

### 0.0 Test Infrastructure Gate

- [ ] (@Sentinel) Create `.TODO/CHAT_TEST_STRATEGY_2026-03-01.md` with exact ownership for:
  - unit tests: message type codec, offer payload model, realtime merge helper, error mapping
  - widget tests: `MessagesScreen` load/empty/error/retry/archive states; `ChatScreen` draft preservation, offer gating, in-flight disable state
  - integration tests: open chat from list, booking path, deep-link path, send/fail/retry flow, fallback refresh behavior
  - RLS/manual SQL checks: allowed and forbidden message/conversation/storage access
- [ ] (@Architect) Define default-preserving test seams for `lib/features/chat/services/message_service.dart`, `lib/features/chat/data/chat_repository.dart`, and the planned split viewmodels.
- [ ] (@Pixel) Define the selector inventory to be added during UI changes:
  - message list error state
  - message list empty state
  - message list retry action
  - archive error state
  - chat send error state
  - chat in-flight send button state
  - manual refresh hint state if conversation realtime remains disabled
- **Verify (@Sentinel):** no implementation work starts until every planned test maps to an existing or explicitly planned harness.

### 0.1 Spec Lock (Blocking)

- [ ] (@APIContract) Create `.TODO/CHAT_DECISIONS_2026-03-01.md` and lock these decisions:
  - direct DM creation rule
  - task-linked initiator rule
  - offer scope
  - conversation-list freshness strategy
  - attachment mutation policy
- [ ] (@APIContract) Recommended defaults unless product explicitly overrides:
  - direct DM creation stays favorites-gated
  - task-linked chat is started by the non-owner via `start_task_conversation_v1`
  - offers are task-linked only
  - conversation list ships with fetch-refresh fallback first; realtime publication is optional and gated later
  - attachments stay append-only in this pass
- [ ] (@Architect) Record exact app-facing consequences of each decision in the decision doc.
- **Verify (@Sentinel):** every later checklist item is compatible with the approved decisions.

### 0.2 Threat Model

- [ ] (@ThreatModeler) Create `.TODO/CHAT_THREAT_MODEL_2026-03-01.md` covering:
  - unauthorized message read
  - unauthorized message insert / sender spoofing
  - over-broad direct DM creation
  - attachment path guessing / signed URL abuse
  - task-linked initiation abuse
  - archive misuse
  - duplicate conversation races
- [ ] (@ThreatModeler) Define negative checks for each threat and map them to Phase 5.
- **Verify (@Sentinel):** each threat has a corresponding allow/deny verification step.

### 0.3 Contract Pack

- [ ] (@APIContract) Create `.TODO/CHAT_CONTRACT_2026-03-01.md` with canonical definitions for:
  - message type wire values
  - offer payload shape
  - conversation creation semantics
  - archive semantics
  - notification source of truth
  - attachment storage/access contract
- [ ] (@APIContract) Create `.TODO/CHAT_RLS_MATRIX_2026-03-01.md` before any SQL authoring, not after.
- **Verify (@Sentinel):** no migration is authored until the contract doc and matrix exist.

### 0.4 Rollout, PR Slicing, and Rollback Control

- [ ] (@DataMigration) Create `.TODO/CHAT_ROLLOUT_MATRIX_2026-03-01.md` with deploy order:
  - PR1: decisions, audits, contracts, tests plan
  - PR2: additive DB/RLS/storage/RPC changes in staging/branch
  - PR3: app-layer contract and realtime corrections
  - PR4: UI states, tests, docs sync, release checklist
- [ ] (@DataMigration) Add rollback triggers to the rollout matrix:
  - valid participant read fails
  - attachment access fails for valid participants
  - DM creation failure rate rises after policy changes
  - archive hides the wrong conversation state
- [ ] (@Architect) Define feature fallback behavior that can remain active during rollout if realtime publication is not enabled.
- **Verify (@Sentinel):** rollout order and stop/rollback conditions are explicit before Phase 1 begins.

**GATE CHECK (@Sentinel):** Block execution if the decision pack, contract pack, test strategy, and rollout matrix are not complete.

---

## Phase 1: Data Audit and Contract Reconciliation

> Goal: inventory live Chat data and reconcile app contracts to backend truth.
> Why: contract cleanup without evidence risks stranding historical rows/objects and mis-sequencing migrations.
> How: capture live SQL state, audit existing message/storage data, then define compatibility rules and exact rename targets.
> Result: every behavior change is evidence-backed and rollout-safe.
>
> Primary: @APIContract

### 1.0 Live Supabase Capture

- [ ] (@Supabase_Ops) Re-scan live Chat objects on implementation day and capture current definitions for:
  - `messages` policies
  - `conversations` policies
  - `storage.objects` policies for `chat-attachments`
  - `start_task_conversation_v1`
  - `messages_before_insert_validate`
  - `messages_after_insert_offer_accept`
  - `messages_after_insert_notify_receiver`
  - `supabase_realtime` publication membership
- [ ] (@DataMigration) Store the captured SQL in `.TODO/CHAT_LIVE_SQL_BASELINE_2026-03-01.md`.
- **Verify (@Sentinel):** implementation uses a fresh live baseline, not stale assumptions.

### 1.1 Historical Data Audit

- [ ] (@Supabase_Ops) Audit `public.messages` for message type distribution and any rows whose payloads still use `delivery` instead of `days`.
- [ ] (@Supabase_Ops) Audit `public.conversations` for duplicate direct-DM pairs, task-linked duplicates, and suspicious archive column states.
- [ ] (@Supabase_Ops) Audit `chat-attachments` object names to confirm they all match `convos/<conversation_id>/...` or classify exceptions.
- [ ] (@DataMigration) Record keep/fix/defer decisions in `.TODO/CHAT_DATA_AUDIT_2026-03-01.md`.
- **Verify (@Sentinel):** every historical outlier has an explicit compatibility or remediation decision.

### 1.2 App Contract Reconciliation

- [ ] (@Architect) Define the exact rename and compatibility map:
  - canonical write values use snake_case only
  - app reads legacy `delivery` payloads temporarily but writes `days` only
  - misleading API name `startConversationByClient(...)` is replaced by explicit direct/task methods
- [ ] (@Architect) Plan exact file work for the contract layer:
  - edit `lib/features/chat/models/message_model.dart`
  - create `lib/features/chat/models/chat_offer_payload.dart`
  - create `lib/features/chat/services/chat_realtime_merger.dart`
  - edit `lib/features/chat/services/message_service.dart`
  - edit `lib/features/chat/data/chat_repository.dart`
- [ ] (@APIContract) Record the exact public method deprecation path in `.TODO/CHAT_CONTRACT_2026-03-01.md`.
- **Verify (@Sentinel):** every future app write path has one canonical contract.

### 1.3 Compatibility Window

- [ ] (@DataMigration) Define compatibility sequencing:
  - archive RPC ships before UI stops client timestamp writes
  - app write contract switches before weak policies are removed
  - conversation list remains fetch-refresh capable even if realtime publication is never enabled
- [ ] (@Architect) Define refresh triggers for the fallback strategy:
  - screen open
  - post-send success
  - post-archive success
  - pull-to-refresh
  - app resume or explicit retry when needed
- **Verify (@Sentinel):** the rollout remains safe even if realtime publication is deferred.

**GATE CHECK (@Sentinel):** Do not author or apply security migrations until the live SQL baseline, data audit, contract map, and compatibility window are complete.

---

## Phase 2: Database, RLS, Storage, and RPC Hardening

> Goal: replace over-broad Chat access with least-privilege, server-authoritative behavior.
> Why: the current live state exposes messages and attachments too broadly and still relies on client clock for archive behavior.
> How: add new helper/RPC objects first, validate allow/deny behavior, then remove weak policies.
> Result: Chat backend enforces the approved contract independently of client UX checks.
>
> Primary: @Supabase_Ops

### 2.0 Staging/Branch Execution Safety

- [ ] (@DataMigration) Apply Chat migrations in a safe environment first and record before/after SQL snapshots.
- [ ] (@Supabase_Ops) Confirm no unrelated policies/functions are unintentionally altered.
- **Verify (@Sentinel):** destructive policy removal is still blocked until positive and negative checks pass.

### 2.1 Archive RPC and Helper Functions

- [ ] (@Supabase_Ops) Add `archive_conversation_v1(p_conversation_id uuid)` that:
  - determines the caller from `auth.uid()`
  - stamps the correct archive column with server time
  - rejects non-participants
- [ ] (@Supabase_Ops) Add a helper function for attachment access, e.g. `can_access_chat_attachment(p_object_name text, p_uid uuid)` based on the locked path contract.
- **Verify (@Sentinel):** archive and storage helper behavior pass participant/non-participant checks.

### 2.2 Messages RLS Hardening

- [ ] (@Supabase_Ops) Replace the broad authenticated message read/insert policies with one least-privilege set that enforces:
  - participant-only select
  - sender-only insert with `sender_id = auth.uid()`
  - receiver-only receipt update where intended
  - sender-only delete if delete remains supported
- [ ] (@ThreatModeler) Validate spoofed sender and foreign conversation insert denials before removing the weak policies.
- **Verify (@Sentinel):** no policy remains that allows non-participant message access.

### 2.3 Conversations Creation Hardening

- [ ] (@Supabase_Ops) Replace the weak participant-only direct conversation insert behavior with one rule matching the approved DM decision.
- [ ] (@Supabase_Ops) Keep task-linked creation aligned with `start_task_conversation_v1` unless a separate approved backend redesign is scheduled.
- [ ] (@Architect) Update any app comments/docs that currently claim the opposite initiator rule.
- **Verify (@Sentinel):** direct and task-linked creation both obey one canonical rule each.

### 2.4 Attachment Storage Hardening

- [ ] (@Supabase_Ops) Replace bucket-wide authenticated select on `chat-attachments` with participant-scoped select using the helper function.
- [ ] (@Supabase_Ops) Restrict inserts to valid path format and authenticated uploader identity.
- [ ] (@Supabase_Ops) Do not add delete/update policies in this pass if append-only remains the approved rule.
- [ ] (@DataMigration) If the audit found legacy object-path outliers, document a temporary exception or cleanup step before enforcement.
- **Verify (@Sentinel):** valid participants keep access; foreign users lose access.

### 2.5 Notifications and Realtime Boundaries

- [ ] (@Supabase_Ops) Keep receiver-notification creation server-side only; do not add a client insert policy for `public.notifications`.
- [ ] (@Architect) Replace stale “remove client notification write” work with search-based verification that Chat code no longer inserts notifications directly.
- [ ] (@Supabase_Ops) Only add `public.conversations` to `supabase_realtime` if the approved decision requires it after fallback-first validation.
- **Verify (@Sentinel):** notification ownership and conversation-list freshness strategy match the decision pack.

### 2.6 Enforcement Removal

- [ ] (@DataMigration) Remove the weak policies only after all allow/deny checks pass in the safe environment.
- [ ] (@DataMigration) Record exact rollback SQL for each removed policy in `.TODO/CHAT_ROLLOUT_MATRIX_2026-03-01.md`.
- **Verify (@Sentinel):** no destructive step lands without a tested rollback snippet.

**GATE CHECK (@Sentinel):** Do not start app-layer dependency changes until RLS/storage checks pass and the rollback SQL is captured.

---

## Phase 3: App Layer (MVVM + Contracts)

> Goal: make Flutter write the approved contract and respect backend authority.
> Why: current app behavior still sends invalid message types/payloads, writes archive timestamps on the client, and models realtime incorrectly.
> How: normalize models, refactor service/repository APIs, split state responsibilities, and tighten logging/error handling.
> Result: the app layer becomes contract-safe, testable, and aligned with strict MVVM boundaries.
>
> Primary: @Architect

### 3.1 Models and Type Contracts

- [ ] (@Architect) Edit `lib/features/chat/models/message_model.dart` so canonical wire values are snake_case while keeping temporary read compatibility for legacy in-app expectations where needed.
- [ ] (@Architect) Create `lib/features/chat/models/chat_offer_payload.dart` and move offer payload validation/construction out of `ChatScreen`.
- [ ] (@Architect) Add unit coverage for the canonical contract in:
  - `test/unit/models/message_model_test.dart`
  - `test/unit/chat/chat_offer_payload_test.dart`
- **Verify (@Sentinel):** app writes only canonical values; read compatibility is explicit and temporary.

### 3.2 Service and Repository Refactor

- [ ] (@Architect) Edit `lib/features/chat/services/message_service.dart` to:
  - call `archive_conversation_v1` instead of writing client timestamps
  - implement the approved conversation-list strategy instead of assuming conversation realtime exists
  - replace snapshot-to-`rows.last` behavior with deterministic merge handling
  - perform attachment cleanup when upload succeeds but message insert fails
- [ ] (@Architect) Create `lib/features/chat/services/chat_realtime_merger.dart` for snapshot merge/dedupe/order rules.
- [ ] (@Architect) Edit `lib/features/chat/data/chat_repository.dart` to expose explicit methods:
  - `startDirectConversation(...)`
  - `startTaskConversation(...)`
  - temporary compatibility wrapper for `startConversationByClient(...)` only if needed for a staged migration
- [ ] (@Architect) Edit `lib/features/booking/viewmodels/booking_view_model.dart` to use the renamed task-conversation API that matches the approved initiator rule.
- [ ] (@Architect) Edit `lib/core/services/deep_link_service.dart` only if Chat navigation contracts or fetch/retry behavior require it.
- **Verify (@Sentinel):** services/repos are backend-accurate and do not retain client-authoritative behaviors.

### 3.3 ViewModel Restructure

- [ ] (@Architect) Split `lib/features/chat/viewmodels/chat_view_model.dart` into exact new paths:
  - `lib/features/chat/viewmodels/chat_conversations_view_model.dart`
  - `lib/features/chat/viewmodels/chat_thread_view_model.dart`
  - keep `lib/features/chat/viewmodels/chat_view_model.dart` only as a short-lived compatibility facade if one PR needs it
- [ ] (@Architect) Move conversation-list loading/realtime state into `chat_conversations_view_model.dart`.
- [ ] (@Architect) Move active-thread messages/send/receipts into `chat_thread_view_model.dart`.
- [ ] (@Architect) Add typed error state and in-flight state for:
  - fetch conversations
  - fetch messages
  - send message
  - archive conversation
  - send attachment
- [ ] (@Architect) Update `lib/main.dart` provider wiring only after the split viewmodels are ready.
- **Verify (@Sentinel):** list and thread state no longer share one large mutable bucket.

### 3.4 Observability and Error Hygiene

- [ ] (@Observability) Edit Chat logging to remove raw content and raw exception leakage from routine logs.
- [ ] (@Architect) Route user-facing failures through shared user-safe mapping instead of raw exception strings.
- [ ] (@Observability) Create `.TODO/CHAT_OBSERVABILITY_2026-03-01.md` with the minimum useful event/error list and early signals.
- **Verify (@Sentinel):** logs remain actionable without leaking message content or sensitive user data.

**GATE CHECK (@Sentinel):** Do not start UI-state work until service/repository/viewmodel tests pass for the new contract and archive/realtime behavior.

---

## Phase 4: UI Wiring, UX States, and Integration Paths

> Goal: make Chat screens behave correctly under load, failure, retry, archive, and fallback conditions.
> Why: current UI still hides failures, clears drafts too early, and violates the approved backend contract in places.
> How: wire the new viewmodels, move payload assembly out of widgets, add explicit states, and gate unsupported actions.
> Result: predictable Chat UX across list entry, booking entry, and deep-link entry.
>
> Primary: @Pixel

### 4.1 Messages Screen

- [ ] (@Pixel) Edit `lib/features/chat/view/messages_screen.dart` to render explicit loading, empty, error, retry, and archive-error states.
- [ ] (@Pixel) Replace raw delete failure text with English-only user-safe feedback.
- [ ] (@Pixel) Show the approved fallback hint when conversation-list realtime is not enabled.
- [ ] (@Pixel) Add stable widget keys/selectors for every new list state.
- [ ] (@Sentinel) Add widget coverage in `test/widget/chat/messages_screen_test.dart`.
- **Verify (@Sentinel):** list behavior is deterministic without relying on nonexistent realtime publication.

### 4.2 Chat Screen and Offer Flow

- [ ] (@Pixel) Edit `lib/features/chat/view/chat_screen.dart` so the composer:
  - awaits send success before clearing draft text
  - disables send while a send is in flight
  - preserves the draft on failure
  - uses the typed offer payload model instead of anonymous maps
- [ ] (@Pixel) Gate offer actions by the approved scope and hide/disable them for unsupported conversations.
- [ ] (@Pixel) Add stable widget keys/selectors for send error and in-flight states.
- [ ] (@Sentinel) Expand `test/widget/chat/chat_screen_test.dart` for failure recovery and offer gating.
- **Verify (@Sentinel):** failed sends preserve drafts and unsupported offer paths are impossible from the UI.

### 4.3 Context and Navigation Decoupling

- [ ] (@Architect) Edit `lib/features/chat/view/widgets/chat_context_widget.dart` so it no longer imports `TaskDetailsScreen` directly for navigation orchestration.
- [ ] (@Pixel) Replace raw exception text with user-safe English-only feedback.
- [ ] (@Sentinel) Add regression coverage for booking entry, list entry, and deep-link entry using updated navigation contracts.
- **Verify (@Sentinel):** Chat widgets remain MVVM-compliant and navigation behavior is explicit.

### 4.4 Shared Attachment Rendering

- [ ] (@Architect) Reuse the shared signed-image approach from `lib/core/widgets/signed_image.dart` where practical instead of duplicating signed-URL/network logic in chat attachment rendering.
- [ ] (@Pixel) Keep attachment rendering focused on storage path input only; never persist signed URLs into Chat state.
- **Verify (@Sentinel):** attachment rendering remains private-bucket safe and consistent.

**GATE CHECK (@Sentinel):** Do not enter release validation until widget tests, integration tests, and manual fallback scenarios pass for the updated UI.

---

## Phase 5: QA, Release Validation, and Docs Sync

> Goal: prove the final state in automation, in manual scenarios, and in live documentation.
> Why: this fix crosses app, DB, storage, and docs; release is not safe without final end-to-end proof.
> How: run automated and manual checks, re-scan live state, then sync docs from the final truth.
> Result: a release-ready Chat fix with auditable rollback steps.
>
> Primary: @Sentinel

### 5.0 Automated Verification

- [ ] (@Sentinel) Run the focused unit/widget suite for Chat and direct dependencies.
- [ ] (@Sentinel) Add or update exact test files:
  - `test/unit/chat/message_service_test.dart`
  - `test/unit/chat/chat_realtime_merger_test.dart`
  - `test/unit/chat/chat_thread_view_model_test.dart`
  - `test/unit/chat/chat_conversations_view_model_test.dart`
  - `test/widget/chat/messages_screen_test.dart`
  - `test/widget/chat/chat_screen_test.dart`
- [ ] (@Sentinel) Update integration coverage in:
  - `integration_test/chat_message_flow_test.dart`
  - `integration_test/notification_deeplink_flow_test.dart`
- **Verify (@Sentinel):** contract, fallback, archive, and navigation regressions are automated.

### 5.1 Security and RLS Validation

- [ ] (@ThreatModeler) Execute the negative checks from `.TODO/CHAT_THREAT_MODEL_2026-03-01.md`.
- [ ] (@Sentinel) Validate the approved allow/deny matrix from `.TODO/CHAT_RLS_MATRIX_2026-03-01.md` in the safe environment and again after production rollout.
- [ ] (@Sentinel) Verify there is no Chat code path performing client-side notification inserts.
- **Verify (@Sentinel):** DB/storage boundaries hold even if the client is modified or bypassed.

### 5.2 Manual Scenarios

- [ ] (@Sentinel) Run and record manual scenarios for:
  - open Messages tab with existing conversations
  - empty-state experience with no conversations
  - open chat from booking flow
  - open chat from deep link
  - send plain text
  - send image attachment
  - send offer in a valid task-linked conversation
  - confirm offer action is unavailable in invalid conversations
  - archive conversation and verify per-user behavior
  - recover from send failure without losing draft text
  - confirm fallback refresh behavior when conversation realtime is absent
- **Verify (@Sentinel):** no silent state loss, no raw error leakage, no invalid affordances.

### 5.3 Release Checklist and Rollback Proof

- [ ] (@DataMigration) Re-check live objects after rollout and compare them with `.TODO/CHAT_LIVE_SQL_BASELINE_2026-03-01.md` plus the intended final state.
- [ ] (@DataMigration) Confirm rollback SQL and app fallback behavior remain valid and documented.
- [ ] (@Sentinel) Sign off only after post-rollout smoke checks and RLS/storage validation succeed.
- **Verify (@Sentinel):** release is blocked if any rollback trigger in the rollout matrix fires.

### 5.4 Docs Sync

- [ ] (@SlineDocs) Update these docs from the final live/code truth:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/CODE_REVIEW.md` if new Chat-specific guardrails are added
  - `Sline_everything/STRUCTURE.md` after the Chat viewmodel split and any file additions
- [ ] (@SlineDocs) Remove contradictory statements about DM authorization, task initiator semantics, and notification ownership.
- **Verify (@Sentinel):** docs, code, and live Supabase state match before closure.

**GATE CHECK (@Sentinel):** Release only after automated checks, RLS/storage validation, manual scenarios, rollback proof, and docs sync all pass.

---

## 7) Acceptance Criteria (MANDATORY)

- Flutter writes only canonical Chat message types accepted by live `message_type_enum`.
- Flutter writes canonical offer payload field `days`; legacy `delivery` is read-only compatibility during the migration window.
- No authenticated non-participant can read or insert Chat messages.
- No authenticated non-participant can read `chat-attachments` objects or obtain signed access for foreign conversations.
- Direct DM authorization is consistent across app behavior, docs, and live policy behavior.
- Task-linked conversation initiation is consistent across app behavior, docs, and live RPC behavior.
- Conversation archive uses server time and authenticated identity, not device time.
- Conversation list behavior is correct even when `conversations` realtime is not enabled.
- `subscribeToMessages(...)` no longer loses updates by collapsing snapshots to `rows.last`.
- `MessagesScreen` distinguishes loading, empty, error, retry, and archive-error states.
- `ChatScreen` preserves draft text on failed send and disables send while a send is in flight.
- Offer actions are unavailable in unsupported conversation types.
- Chat widgets do not show raw exception strings to users.
- Chat logs do not include raw message content in routine failure paths.
- No Chat app layer path performs client-side notification creation.
- Docs are updated to the final live/code truth after rollout.

## 8) Rollback Plan

- DB rollback / forward-fix
  - Capture exact pre-change SQL for every touched policy, function, and publication entry.
  - If strict `messages` or storage policies block valid traffic, restore the captured SQL immediately and keep the app in fallback mode while forward-fixing.
  - If archive RPC misbehaves, revert UI usage of archive to a guarded fallback and keep the DB function out of the app path.
  - If optional `conversations` realtime publication causes instability, remove that publication entry and keep fetch-refresh fallback as the source of truth.
- App rollback / phased revert
  - Ship in slices from the rollout matrix so any regression can be reverted without undoing the entire fix set.
  - Keep temporary read compatibility for legacy offer payload rendering until the rollout matrix explicitly removes it.
  - If the viewmodel split regresses navigation or state, keep the service/repository fixes and revert only the provider/UI slice.
- Emergency disable strategy
  - Disable offer actions in the UI if any offer contract ambiguity or backend validation error remains.
  - Keep manual refresh and explicit retry paths available if realtime publication is deferred or rolled back.

## 9) References (From Scan)

- Docs
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`
- Code
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `lib/features/chat/models/conversation_model.dart`
  - `lib/features/chat/models/message_model.dart`
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/chat/services/attachment_service.dart`
  - `lib/features/chat/attachments/services/send_attachment_usecase.dart`
  - `lib/features/chat/view/chat_screen.dart`
  - `lib/features/chat/view/messages_screen.dart`
  - `lib/features/chat/view/widgets/chat_context_widget.dart`
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/features/tasks/viewmodels/task_view_model.dart`
- Tests
  - `test/test_support/pump_app.dart`
  - `test/widget/chat/chat_screen_test.dart`
  - `test/unit/models/message_model_test.dart`
  - `integration_test/chat_message_flow_test.dart`
  - `integration_test/notification_deeplink_flow_test.dart`
  - `integration_test/support/helpers.dart`
  - `integration_test/support/preflight.dart`
- Audit inputs
  - `.TODO/Chat.TODO.md`
  - `.TODO/PLAN_CRITIC_ChatFix_2026-03-01.md`
- Live Supabase scan evidence (2026-03-01 via `@mcp:supabase-mcp-server:`)
  - tables: `conversations`, `messages`, `notifications`, `tasks`, `profiles`, `favorites`
  - enum: `message_type_enum`
  - bucket: `chat-attachments`
  - RPC/functions: `start_task_conversation_v1`, `mark_conversation_delivered`, `mark_conversation_seen`, `messages_before_insert_validate`, `messages_after_insert_offer_accept`, `messages_after_insert_notify_receiver`, `conversations_before_insert_guard`, `normalize_conversation_users`, `is_conversation_participant`, `is_client`
  - triggers: `trg_conversations_before_insert_guard`, `trg_normalize_conversation_users`, `trg_messages_before_insert_validate`, `trg_messages_after_insert_offer_accept`, `trg_messages_after_insert_notify_receiver`
  - realtime: `supabase_realtime` currently includes `messages` and `notifications`, not `conversations`
