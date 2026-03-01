# 📌 Plan: Chat Security, Contract, and Realtime Hardening

## 1) Goal

- Goal:
  - Bring the Chat feature into a single safe, verified state across Flutter app code, live Supabase auth/RLS/storage/realtime, and project documentation.
- Why:
  - The current system has confirmed contract drift and live security drift:
    - code writes camelCase message types while live DB uses snake_case enum values
    - code writes offer payload key `delivery` while live DB trigger validates `days`
    - live `messages` RLS includes permissive authenticated read/insert policies alongside stricter participant policies
    - live `chat-attachments` storage select policy allows any authenticated user to read bucket objects
    - code subscribes to `conversations` realtime while live publication only includes `messages` and `notifications`
    - code still attempts client-side notification writes while live DB already has server-side notification trigger logic
- Result:
  - Chat is least-privilege, contract-consistent, server-authoritative for sensitive actions, resilient under realtime load, and backed by measurable verification and rollback paths.

## 2) Scope

### In-Scope

- Flutter feature files under `lib/features/chat/`
- Direct app dependencies touched by Chat:
  - `lib/main.dart`
  - `lib/app/main_navigation_screen.dart`
  - `lib/core/services/deep_link_service.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/features/tasks/viewmodels/task_view_model.dart`
  - `lib/features/tasks/view/task_details_screen.dart`
- Live Supabase objects touched by Chat:
  - tables: `conversations`, `messages`, `notifications`, `tasks`, `profiles`, `favorites`
  - enum: `message_type_enum`
  - functions/RPCs: `start_task_conversation_v1`, `mark_conversation_delivered`, `mark_conversation_seen`, `messages_before_insert_validate`, `messages_after_insert_offer_accept`, `messages_after_insert_notify_receiver`, `is_conversation_participant`, `is_client`
  - triggers on `conversations` and `messages`
  - storage bucket: `chat-attachments`
  - realtime publication: `supabase_realtime`
- Docs that must be reconciled:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/ARCHITECTURE_ANALYSIS.md`
  - `Sline_everything/CODE_REVIEW.md`
  - `Sline_everything/STRUCTURE.md`

### Out-of-Scope

- Rebuilding unrelated Booking, Dashboard, Notifications, or Tasks features beyond direct Chat call paths
- Product expansion such as typing/presence UI, full chat search, message pagination redesign, or new media types
- Deleting redundant legacy DB indexes in the first safe-fix pass unless performance evidence proves they are causing operational harm
- Relaxing Chat authorization rules beyond current least-privilege behavior without explicit product approval

## 3) Evidence & Findings (From Scan)

### Existing

- Flutter Chat module exists with MVVM shape:
  - `lib/features/chat/view/messages_screen.dart`
  - `lib/features/chat/view/chat_screen.dart`
  - `lib/features/chat/viewmodels/chat_view_model.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/chat/services/attachment_service.dart`
  - `lib/features/chat/attachments/**`
- Chat is a live bottom-nav surface:
  - `lib/app/main_navigation_screen.dart`
- Chat state is app-root provided:
  - `lib/main.dart`
- Direct dependency entry paths exist:
  - Booking starts chat via `ChatRepository.startConversationByClient(...)`
  - Deep links open chat via `MessageService.getConversationById(...)`
- Live Supabase scan confirms current chat backend reality:
  - `conversations` table exists with RLS enabled
  - `messages` table exists with RLS enabled
  - `notifications` table exists with RLS enabled
  - `message_type_enum` values are:
    - `text`
    - `system`
    - `offer`
    - `offer_update`
    - `offer_accepted`
    - `offer_rejected`
    - `delivery_submitted`
    - `end_early_request`
    - `dispute_report`
  - live RPC/functions exist:
    - `start_task_conversation_v1(p_task_id uuid)`
    - `mark_conversation_delivered(p_conversation_id uuid)`
    - `mark_conversation_seen(p_conversation_id uuid)`
  - live message/conversation trigger set exists:
    - `trg_conversations_before_insert_guard`
    - `trg_normalize_conversation_users`
    - `trg_messages_before_insert_validate`
    - `trg_messages_after_insert_offer_accept`
    - `trg_messages_after_insert_notify_receiver`
  - `chat-attachments` bucket exists and is private
  - `supabase_realtime` currently includes:
    - `messages`
    - `notifications`
    - not `conversations`

### Missing

- No Chat-specific SQL migration files are present in `supabase/migrations/` for direct code-to-live verification of the currently active Chat policies/functions
- No Chat unit tests currently cover:
  - `MessageService`
  - `ChatViewModel`
  - realtime merge behavior
  - policy/error contract behavior
- No participant-scoped storage select policy exists for `chat-attachments`
- No server-side archive RPC exists for conversation soft-delete timestamps; app writes client timestamps directly
- No contract file exists that locks:
  - direct DM authorization rule
  - task-linked conversation initiation rule
  - message type naming
  - offer payload shape
  - notification ownership model
- No explicit app fallback exists for missing `conversations` realtime publication

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Live DB vs app contract mismatch:
  - Flutter sends `offerAccepted` / `offerRejected`
  - live DB enum and trigger logic use `offer_accepted` / `offer_rejected`
- Live DB vs app contract mismatch:
  - Flutter sends offer payload key `delivery`
  - live `messages_before_insert_validate` requires integer `days`
- Live DB vs docs drift on direct DM authorization:
  - `Sline_everything/SUPABASE_SETUP.md` says direct DMs no longer require favorites
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md` says direct DMs require favorites
  - live `conversations_before_insert_guard()` removed favorites check
  - live `conversations_insert_client_only` policy still requires favorites
  - live permissive insert policy `Users can insert conversation if they are a participant` means effective behavior is broader than the stricter favorites-based policy
- Live DB vs docs/code drift on task-linked initiation:
  - live `start_task_conversation_v1` blocks task owner from starting task-linked chat
  - code comments in `MessageService.startConversationByClient` still say task owner must be caller
  - docs disagree on owner vs non-owner initiation
- Confirmed live security risk:
  - live `messages` policies include permissive authenticated read policy and permissive authenticated insert policy in addition to stricter participant/sender checks
  - because policies are permissive, live auth is broader than intended least-privilege design
- Confirmed live storage risk:
  - `chat_attach_select_auth` allows any authenticated user to select storage objects in `chat-attachments`
- Confirmed client/server duplication:
  - app still attempts client notification writes
  - live DB already has `messages_after_insert_notify_receiver()` server trigger
  - `notifications` RLS exposes select/update for owner only and does not expose client insert path for creating receiver notifications
- Confirmed realtime drift:
  - app subscribes to `conversations`
  - live publication does not include `conversations`
- App-architecture risk:
  - Chat UI still imports Task UI directly via `ChatContextWidget`
- Migration risk:
  - tightening broad live policies can surface existing hidden client assumptions immediately; rollout must capture before/after SQL and verify every Chat entry path

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
  - `public.conversations` policies
  - `public.messages` policies
  - `public.notifications` policies
  - `storage.objects` policies for `chat-attachments`
  - helper functions used in policies
- Realtime/Notifications (if any):
  - `supabase_realtime` publication
  - message stream logic in Flutter
  - server-side notification trigger on `messages`
- Storage:
  - `chat-attachments` bucket
  - path convention `convos/<conversationId>/<random>_<filename>`
  - signed URL generation at render time
- Observability (if any):
  - `AppLogger`
  - Chat service/viewmodel logging
  - privacy redaction and correlation naming for chat failures
- Compatibility & Migration:
  - temporary read compatibility for legacy offer payload/rendering
  - additive-first DB rollout for archive RPC / storage helper / realtime publication
  - explicit removal of weak policies only after verification
- Contracts:
  - direct DM authorization rule
  - task-linked conversation initiation rule
  - offer message type and payload contract
  - server vs client notification ownership
  - storage access contract for attachments

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Lock measurable acceptance list for Chat security, contract parity, realtime behavior, and UX stability using this plan plus `.TODO/Chat.TODO.md`.
- [ ] (@Architect) Confirm current Chat entry points and direct dependencies:
  - `lib/app/main_navigation_screen.dart`
  - `lib/main.dart`
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/core/services/deep_link_service.dart`
- [ ] (@APIContract) Freeze the canonical contract decisions before implementation:
  - direct DM authorization rule
  - task-linked initiation rule
  - message type string set
  - offer payload shape
  - notification ownership model
- **Verify (@Sentinel):** done-conditions, non-regression list, and rollback triggers are documented before any code or SQL change.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Produce `.TODO/CHAT_THREAT_MODEL_2026-03-01.md` covering:
  - unauthorized message read
  - unauthorized message insert / sender spoofing
  - attachment path guessing / signed URL abuse
  - direct DM abuse if favorites rule is relaxed
  - task-linked initiation abuse
  - replay / duplicate conversation creation
- [ ] (@ThreatModeler) Define negative checks for:
  - non-participant message select
  - non-participant message insert
  - non-owner storage select
  - non-owner storage insert outside allowed path
  - unauthorized notification creation path
- **Verify (@Sentinel):** negative checks are testable and mapped into Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Produce `.TODO/CHAT_CONTRACT_2026-03-01.md` covering:
  - `message_type_enum` canonical values
  - offer payload fields (`price`, `days`, optional display-only fields)
  - direct DM authorization rule
  - task-linked chat initiation rule
  - notification source of truth
  - attachment storage path/access contract
- [ ] (@APIContract) Recommended default contract, unless product explicitly overrides:
  - direct DMs remain favorites-gated for least privilege
  - task-linked chat initiation follows live RPC rule: non-owner starts the chat
  - server trigger owns receiver notifications
  - server-generated timestamps own chat archive state
- **Verify (@Sentinel):** contract matches live schema/trigger/function reality and every contract drift is either reconciled or explicitly staged.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Produce `.TODO/CHAT_MIGRATION_PLAN_2026-03-01.md` with introduce/verify/enforce/rollback sequence for:
  - participant-scoped storage access helper/policies
  - archive conversation RPC
  - realtime publication update for `conversations`
  - removal of weak permissive chat policies
- [ ] (@DataMigration) Include before/after SQL snapshots for every touched policy/function/publication object.
- [ ] (@DataMigration) Include compatibility window decisions:
  - temporary app-side fallback for legacy `delivery` payload rendering
  - temporary parser compatibility for legacy camelCase message types if encountered in app-local data/tests
- **Verify (@Sentinel):** migration sequence is additive-first where possible and explicitly names the only destructive steps (policy removals).

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Define rollout gates:
  - keep manual refresh path operational until `conversations` realtime publication is confirmed
  - allow a temporary runtime fallback to fetch conversation list after send/delete/open if realtime is unavailable
  - if contract ambiguity remains, temporarily hide offer actions on unsupported conversation types instead of guessing
- **Verify (@Sentinel):** rollback path is documented and can disable risky behavior without database rollback.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan live Chat objects on implementation day using `@mcp:supabase-mcp-server:`:
  - `conversations`, `messages`, `notifications`
  - `message_type_enum`
  - chat triggers/functions/RPCs
  - `chat-attachments` bucket + `storage.objects` policies
  - `supabase_realtime` publication
- [ ] (@Supabase_Ops) Capture current live policy names exactly before any change:
  - `Allow users to read messages`
  - `Allow users to insert messages`
  - `Users can insert conversation if they are a participant`
  - `chat_attach_select_auth`
  - `chat_attach_insert_auth`
  - any duplicate participant policies left in place
- **Verify (@Sentinel):** current drift and safe approach are re-confirmed before execution.

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) Add a server-authoritative archive RPC, e.g. `archive_conversation_v1(p_conversation_id uuid)`, that stamps `deleted_at_user1` or `deleted_at_user2` using server time and authenticated user identity.
- [ ] (@Supabase_Ops) Add a storage helper function for `chat-attachments` access, e.g. `can_access_chat_attachment(p_object_name text, p_uid uuid)`, based on the current path contract `convos/<conversation_id>/...`.
- [ ] (@Supabase_Ops) Add `public.conversations` to `supabase_realtime` publication if the product requires realtime conversation list updates.
- [ ] (@Supabase_Ops) Do not alter tables/enums unless a new hard blocker appears during re-scan.
- [ ] (@Supabase_Ops) Defer redundant index cleanup on `conversations` and `messages` to a later measured maintenance pass; record duplicates but do not drop them in the initial security/correctness release.
- **Verify (@Sentinel):** new DB objects are additive, named consistently, and do not widen access.

### 1.2 RLS

- [ ] (@Supabase_Ops) Tighten `public.messages` to least privilege:
  - remove broad authenticated-read policy
  - remove broad authenticated-insert policy
  - keep only participant/sender/receiver policies that enforce:
    - message select by conversation participant
    - insert by authenticated sender who is a participant
    - update by receiver for receipts
    - delete by sender only
- [ ] (@Supabase_Ops) Tighten `public.conversations` insert path:
  - remove or replace weak participant-only insert policy if it bypasses the agreed DM rule
  - keep one canonical insert path that matches the locked contract
- [ ] (@Supabase_Ops) Tighten `storage.objects` for `chat-attachments`:
  - replace bucket-wide authenticated select with participant-scoped select using the storage helper
  - constrain insert to the uploader and valid chat path convention
  - add delete/update rules only if ownership and path semantics are explicit
- [ ] (@Supabase_Ops) Keep notifications receiver creation server-side; do not add a client insert policy to `public.notifications`.
- [ ] (@Supabase_Ops) Produce `.TODO/CHAT_RLS_MATRIX_2026-03-01.md` covering positive and negative cases for:
  - direct DM create
  - task-linked chat create
  - message read/write/update/delete
  - notification read/update
  - attachment select/insert/delete
- **Verify (@Sentinel):** unauthorized access fails, positive paths pass, and no policy remains that widens Chat access unexpectedly.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Verify `messages_before_insert_validate()` remains the canonical offer payload guard after app contract changes.
- [ ] (@Supabase_Ops) Verify `messages_after_insert_offer_accept()` still matches the locked task/offer business rule after message type normalization.
- [ ] (@Supabase_Ops) Keep `messages_after_insert_notify_receiver()` as the notification source of truth for receiver notifications.
- [ ] (@Supabase_Ops) Decide whether to align `conversations_before_insert_guard()` with the final DM rule for defense-in-depth, or explicitly document why policy-only enforcement is sufficient.
- [ ] (@APIContract) If task-linked initiation semantics remain “non-owner starts,” rename app-layer methods/comments to match the server truth instead of changing live DB behavior by assumption.
- **Verify (@Sentinel):** state rules, notification ownership, and initiation rules are enforced at the backend boundary.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Apply introduce-first DB changes:
  - archive RPC
  - storage helper
  - realtime publication update
  - any replacement least-privilege policies
- [ ] (@DataMigration) Validate replacement policies in staging/branch before removing weak live policies.
- [ ] (@DataMigration) Remove weak permissive policies only after positive/negative verification passes.
- **Verify (@Sentinel):** verify queries and abuse checks pass after every migration step; no hidden dependency is left untested.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Normalize `lib/features/chat/models/message_model.dart` to use snake_case wire values as the canonical write contract:
  - `offer_update`
  - `offer_accepted`
  - `offer_rejected`
  - `delivery_submitted`
  - `end_early_request`
  - `dispute_report`
- [ ] (@Architect) Preserve temporary read compatibility for legacy in-app expectations where needed:
  - parse legacy camelCase values if present in tests/local data
  - render offer payload from `days` first, fallback to legacy `delivery` only during transition
- [ ] (@Architect) Add a typed offer payload model, e.g. `lib/features/chat/models/chat_offer_payload.dart`, instead of building anonymous maps in the UI.
- [ ] (@Architect) Add centralized conversation mapping/selectors, e.g.:
  - `lib/features/chat/models/conversation_mapper.dart`
  - `lib/features/chat/models/conversation_selectors.dart`
- [ ] (@Architect) Route Chat service errors through shared user-safe mapping (`lib/core/utils/error_mapper.dart`) instead of ad-hoc raw exception text.
- **Verify (@Sentinel):** types, nullability, and wire contracts match live DB behavior exactly.

### 2.2 Services/Repositories

- [ ] (@Architect) Refactor Chat service boundaries:
  - remove client-side `NotificationService` receiver-notification creation from Chat send path
  - rely on server trigger for receiver notifications
- [ ] (@Architect) Replace client-clock conversation archive writes with the new archive RPC.
- [ ] (@Architect) Split misleading conversation creation API into explicit methods:
  - direct conversation creation path
  - task-linked conversation path
  - deprecate/remove `startConversationByClient(...)` naming if it no longer matches server behavior
- [ ] (@Architect) Fix `subscribeToMessages(...)` so batched snapshots do not collapse to `rows.last`.
- [ ] (@Architect) Fix `subscribeToConversations(...)` to either:
  - consume real conversation realtime safely after publication exists, or
  - fall back to explicit fetch refresh logic without pretending realtime exists
- [ ] (@Architect) Keep storage-path-only persistence and signed URL generation in service/widget boundaries; do not store signed URLs in DB state.
- [ ] (@Architect) Add best-effort attachment cleanup if upload succeeds but message insert fails.
- **Verify (@Sentinel):** service/repository layer is RLS-safe, contract-safe, and free of client-side privileged side effects.

### 2.3 ViewModels

- [ ] (@Architect) Split or internally separate conversation-list state from thread state to reduce shared mutable state and rebuild blast radius.
- [ ] (@Architect) Add explicit recoverable error states for:
  - fetch conversations
  - fetch messages
  - send message
  - delete/archive conversation
  - send attachment
- [ ] (@Architect) Stop swallowing send/delete/fetch errors; surface typed failure state to the UI.
- [ ] (@Architect) Ensure one source of truth for realtime merge/upsert logic.
- [ ] (@Architect) Remove duplicate unread-rule computation from UI and expose selector-based unread state.
- **Verify (@Sentinel):** state transitions are recoverable, deterministic, and do not erase valid user state on transient failures.

### 2.4 Observability (If needed)

- [ ] (@Observability) Produce `.TODO/CHAT_OBSERVABILITY_2026-03-01.md` listing required low-sensitivity events:
  - `chat_send_failed`
  - `chat_fetch_failed`
  - `chat_archive_failed`
  - `chat_attachment_cleanup_failed`
  - `chat_realtime_unavailable`
  - `chat_rls_denied`
- [ ] (@Architect) Instrument services/viewmodels only; do not add analytics/logging side effects to widgets.
- [ ] (@Observability) Remove raw message-content logging and participant metadata logging from routine debug flows.
- **Verify (@Sentinel):** logs/events are useful, correlation-friendly, and do not leak message content or private user data.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Update `MessagesScreen` to render explicit loading, empty, and error states instead of treating all failures as empty lists.
- [ ] (@Pixel) Update `ChatScreen` composer behavior:
  - await send result
  - preserve text on failure
  - show user-safe English-only error feedback
- [ ] (@Pixel) Remove raw exception strings from `ChatContextWidget` and conversation delete snackbar paths.
- [ ] (@Pixel) Move offer creation payload assembly out of `ChatScreen` UI callback; UI passes validated form inputs only.
- [ ] (@Pixel) Gate offer actions by the final contract:
  - if offers are only valid in tender-linked chat, hide or disable offer action elsewhere
  - if broader use is approved, document and test it explicitly
- [ ] (@Pixel) Decouple `ChatContextWidget` from direct `TaskDetailsScreen` navigation by using callback/routing orchestration from the screen layer.
- [ ] (@Pixel) Reuse shared signed-image caching behavior for attachments, or extract a shared storage-image widget instead of duplicating signed URL/network logic.
- **Verify (@Sentinel):** UI uses ViewModels only, keeps strings in English, and behaves predictably on slow/empty/error data.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Add low-risk UX polish only after correctness/security pass:
  - inline retry affordance for failed sends
  - explicit “realtime unavailable, pull to refresh” hint if publication is absent
  - improved archive/delete recovery feedback
- **Verify (@Sentinel):** no performance regression and no new state ambiguity.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Re-run contract verification against live DB after Phase 1:
  - enum values
  - policy set
  - trigger/function ownership
  - storage access behavior
  - realtime publication membership
- [ ] (@Sentinel) Re-run migration verification queries from `.TODO/CHAT_MIGRATION_PLAN_2026-03-01.md`.
- [ ] (@APIContract) Confirm Flutter write shapes now match live DB contract exactly.
- **Verify (@Sentinel):** no code-to-schema mismatch remains.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks:
  - non-participant cannot read any chat messages
  - non-participant cannot insert a message into a foreign conversation
  - participant cannot spoof `sender_id`
  - unauthorized user cannot create signed URL/select foreign attachment object
  - unauthorized user cannot archive another participant’s conversation
  - direct DM create obeys final least-privilege rule
- [ ] (@ThreatModeler) Validate that no client-side path can recreate privileged notification writes.
- [ ] (@Sentinel) Run RLS leak audit and storage audit in live/staging environment.
- **Verify (@Sentinel):** unauthorized access is blocked at DB/storage boundaries, not just hidden in UI.

### 4.3 Functional QA

- [ ] (@Sentinel) Execute manual E2E script for:
  - open Messages tab
  - open chat from booking flow
  - open chat from deep link
  - send plain text message
  - send custom offer
  - accept/reject offer
  - send image attachment
  - archive conversation
  - receive realtime updates
  - recover from network failure
- [ ] (@Sentinel) Exercise edge cases:
  - empty chat
  - transient fetch failure
  - missing conversation realtime publication
  - duplicate DM creation race
  - legacy offer payload rendering fallback
- **Verify (@Sentinel):** no crashes, no silent state loss, and consistent behavior across entry paths.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Confirm required chat failure events/logs exist and are actionable.
- [ ] (@Sentinel) Confirm privacy redaction removes raw message content and sensitive user fields from routine logs.
- **Verify (@Sentinel):** telemetry is useful without leaking chat content.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update Chat contract and architecture docs to match live reality after fixes:
  - `Sline_everything/DEVELOPER_GUIDE.md`
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`
  - `Sline_everything/SUPABASE_SETUP.md`
  - `Sline_everything/MVP_ROADMAP.md`
  - `Sline_everything/CODE_REVIEW.md` if a new chat-specific guardrail is introduced
  - `Sline_everything/STRUCTURE.md` if Chat files are split/moved
- [ ] (@SlineDocs) Record the final direct DM rule and task-linked initiation rule explicitly; remove contradictory statements.
- [ ] (@SlineDocs) Document server-owned notification behavior and attachment access model.
- **Verify (@Sentinel):** docs match code and live DB reality exactly.

---

## 7) Acceptance Criteria (MANDATORY)

- Chat message writes from Flutter use live enum values and accepted payload shape; offer send/accept/reject succeeds without DB contract errors.
- No authenticated non-participant can read or write Chat messages through RLS.
- No authenticated non-participant can access `chat-attachments` objects or signed URLs for foreign conversations.
- Direct DM authorization rule is consistent across app code, docs, and live RLS/policy behavior.
- Task-linked initiation rule is consistent across app code, docs, and live RPC behavior.
- Receiver notifications are created server-side only; client-side duplicate notification writes are removed from the Chat send path.
- Conversation archive uses server time, not device time.
- Chat list realtime behavior is either:
  - backed by live `conversations` publication and verified, or
  - explicitly replaced with deterministic refresh behavior.
- `MessagesScreen` distinguishes loading, empty, and error states.
- `ChatScreen` does not discard unsent message text on failed send.
- Raw exception strings and raw chat-content debug logs are removed from user-facing and routine logging paths.
- Unit/widget/service/viewmodel coverage exists for the critical paths:
  - message contract
  - offer payload contract
  - realtime merge/upsert
  - send failure recovery
  - archive failure recovery
  - booking/deep-link chat entry

## 8) Rollback Plan

- DB rollback/forward-fix steps
  - Capture current SQL definitions for all touched policies/functions/publication entries before any change.
  - If new strict policies block valid traffic, restore the captured policy set immediately and disable the risky app path while forward-fixing.
  - If `conversations` realtime publication causes issues, remove `public.conversations` from `supabase_realtime` and keep app in manual-refresh fallback mode.
  - If archive RPC misbehaves, revert the app to read-only archive UI or temporary client-side hide with explicit warning while forward-fixing server logic.
- App rollback (flag/revert)
  - Keep parser read compatibility for legacy payload/rendering during rollout.
  - Ship app fixes in slices:
    - contract normalization
    - error-state/UI handling
    - realtime refactor
    - architecture split/refactor
  - If a slice regresses, revert only that slice while keeping DB hardening in place where safe.
- Emergency disable strategy (if applicable)
  - Disable conversation-list realtime and fall back to explicit fetch/refresh.
  - Temporarily hide offer actions if contract ambiguity is discovered late.
  - Keep attachment sending disabled behind UI guard if storage policy rollout is incomplete.

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
  - `lib/features/chat/attachments/services/upload_service.dart`
  - `lib/features/chat/attachments/services/pick_image_service.dart`
  - `lib/features/chat/attachments/services/compress_service.dart`
  - `lib/features/chat/view/chat_screen.dart`
  - `lib/features/chat/view/messages_screen.dart`
  - `lib/features/chat/view/widgets/chat_context_widget.dart`
  - `lib/features/chat/view/widgets/conversation_list_tile.dart`
  - `lib/features/chat/attachments/widgets/attachment_message_tile.dart`
  - `lib/features/booking/viewmodels/booking_view_model.dart`
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/features/tasks/viewmodels/task_view_model.dart`
  - `test/widget/chat/chat_screen_test.dart`
  - `test/unit/models/message_model_test.dart`
- Audit input
  - `.TODO/Chat.TODO.md`
- Live Supabase scan evidence (2026-03-01 via `@mcp:supabase-mcp-server:`)
  - tables: `conversations`, `messages`, `notifications`, `tasks`, `profiles`, `favorites`
  - enum: `message_type_enum`
  - bucket: `chat-attachments`
  - functions/RPCs:
    - `start_task_conversation_v1`
    - `mark_conversation_delivered`
    - `mark_conversation_seen`
    - `messages_before_insert_validate`
    - `messages_after_insert_offer_accept`
    - `messages_after_insert_notify_receiver`
    - `conversations_before_insert_guard`
    - `normalize_conversation_users`
    - `is_conversation_participant`
    - `is_client`
  - triggers:
    - `trg_conversations_before_insert_guard`
    - `trg_normalize_conversation_users`
    - `trg_messages_before_insert_validate`
    - `trg_messages_after_insert_offer_accept`
    - `trg_messages_after_insert_notify_receiver`
  - policy evidence reviewed for:
    - `public.conversations`
    - `public.messages`
    - `public.notifications`
    - `storage.objects`
  - realtime publication evidence reviewed for:
    - `messages`
    - `notifications`
    - missing `conversations`
