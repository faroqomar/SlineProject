# Chat — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does
  - Chat provides conversation list UI, thread UI, offer-style messages, image attachments, and realtime updates via Provider/MVVM (`lib/features/chat/view/messages_screen.dart:14-268`, `lib/features/chat/view/chat_screen.dart:23-388`, `lib/features/chat/viewmodels/chat_view_model.dart:28-309`).
- Boundaries (in/out of scope)
  - In scope: `lib/features/chat/**` and direct dependencies it calls/imports (`lib/features/notifications/services/notification_service.dart:69-156`, `lib/features/booking/viewmodels/booking_view_model.dart:650-680`, `lib/core/services/deep_link_service.dart:180-206`, `lib/features/tasks/viewmodels/task_view_model.dart:171-172`, `lib/features/tasks/view/task_details_screen.dart` via import in `lib/features/chat/view/widgets/chat_context_widget.dart:11-12`).
  - Out of scope: full internals of Booking/Tasks/Notifications beyond the direct chat call paths above (UNVERIFIED by design; not audited unless directly touched).
- Entry points (screens/routes/calls)
  - Main navigation embeds `MessagesScreen()` in the app screen stack (`lib/app/main_navigation_screen.dart:39-49`).
  - Global `ChatViewModel` is registered in app `MultiProvider` (`lib/main.dart:141-149`).
  - Booking flow opens/creates chat through `ChatRepository.startConversationByClient(...)` (`lib/features/booking/viewmodels/booking_view_model.dart:650-669`).
  - Deep-link service opens `ChatScreen` after `MessageService.getConversationById(...)` (`lib/core/services/deep_link_service.dart:180-200`, `lib/features/chat/services/message_service.dart:121-145`).

## 1) Feature Map (Current Repo State)
- Primary feature files (with references)
  - ViewModels / data / services
    - `lib/features/chat/viewmodels/chat_view_model.dart:28-309`
    - `lib/features/chat/data/chat_repository.dart:9-92`
    - `lib/features/chat/services/message_service.dart:10-445`
    - `lib/features/chat/services/attachment_service.dart:6-55`
  - Models
    - `lib/features/chat/models/conversation_model.dart:4-114`
    - `lib/features/chat/models/message_model.dart:5-187`
    - `lib/features/chat/attachments/models/attachment_payload.dart:4-45`
  - Screens / widgets
    - `lib/features/chat/view/messages_screen.dart:14-268`
    - `lib/features/chat/view/chat_screen.dart:23-388`
    - `lib/features/chat/view/widgets/chat_context_widget.dart:16-139`
    - `lib/features/chat/view/widgets/conversation_list_tile.dart:13-243`
    - `lib/features/chat/view/widgets/message_bubble.dart:8-105`
    - `lib/features/chat/view/widgets/offer_message_bubble.dart:13-278`
    - `lib/features/chat/view/widgets/create_offer_sheet.dart:11-209`
    - `lib/features/chat/attachments/widgets/attachment_message_tile.dart:8-177`
  - Attachment submodule services
    - `lib/features/chat/attachments/services/send_attachment_usecase.dart:11-74`
    - `lib/features/chat/attachments/services/upload_service.dart:4-23`
    - `lib/features/chat/attachments/services/pick_image_service.dart:7-33`
    - `lib/features/chat/attachments/services/compress_service.dart:6-27`
    - `lib/features/chat/attachments/utils/mime_utils.dart:3-20`
    - `lib/features/chat/attachments/errors/attachment_exceptions.dart:4-21`
- Direct dependencies (with references)
  - Provider wiring / app entry
    - `lib/main.dart:141-149` (global `ChatViewModel`, `BookingViewModel(chatRepository: ...)`)
    - `lib/app/main_navigation_screen.dart:39-49` (`MessagesScreen()` entry)
  - Booking -> Chat integration
    - `lib/features/booking/viewmodels/booking_view_model.dart:650-669`
  - Deep-link -> Chat integration
    - `lib/core/services/deep_link_service.dart:180-200`
    - `lib/features/chat/services/message_service.dart:121-145`
  - Notification side-effects triggered by chat send
    - `lib/features/chat/services/message_service.dart:281-309`
    - `lib/features/notifications/services/notification_service.dart:69-156`
  - Tasks dependency from Chat context banner
    - `lib/features/chat/view/widgets/chat_context_widget.dart:11-12`
    - `lib/features/chat/view/widgets/chat_context_widget.dart:21-55`
    - `lib/features/tasks/viewmodels/task_view_model.dart:171-172`
  - Shared image/signed URL utility used for comparison (duplicate behavior candidate)
    - `lib/core/widgets/signed_image.dart:25-201`
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs)
  - Tables (`conversations`, `messages`, joins on `tasks`, `profiles`)
    - `lib/features/chat/services/message_service.dart:47-87`
    - `lib/features/chat/services/message_service.dart:123-132`
    - `lib/features/chat/services/message_service.dart:150-168`
    - `lib/features/chat/services/message_service.dart:232-243`
    - `lib/features/chat/services/message_service.dart:271-277`
  - RPCs (`start_task_conversation_v1`, receipts RPCs)
    - `lib/features/chat/services/message_service.dart:30-35`
    - `lib/features/chat/services/message_service.dart:317-330`
  - Storage bucket (`chat-attachments`)
    - `lib/features/chat/services/attachment_service.dart:7-8`
    - `lib/features/chat/services/attachment_service.dart:21-29`
    - `lib/features/chat/services/attachment_service.dart:36-39`
    - Doc mention: `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:50-52`
  - Realtime streams (`messages`, `conversations`)
    - `lib/features/chat/services/message_service.dart:335-351`
    - `lib/features/chat/services/message_service.dart:353-427`
    - Doc note (publication mismatch risk): `Sline_everything/SUPABASE_SETUP.md:1619-1626`
  - Notifications table (direct dependency side-effect)
    - `lib/features/notifications/services/notification_service.dart:69-94`
    - `lib/features/notifications/services/notification_service.dart:96-156`
  - RLS / trigger / enum contract (docs only; live SQL in repo is UNVERIFIED)
    - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:53-64`
    - `Sline_everything/SUPABASE_SETUP.md:232-258`
    - `Sline_everything/SUPABASE_SETUP.md:1041-1064`

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
|---|---|---|---|---|
| MAP-01 | Chat screen is a main navigation tab entry point | `lib/app/main_navigation_screen.dart:39-49` | Low | Defines runtime entry path into feature |
| MAP-02 | `ChatViewModel` is globally provided (shared state) | `lib/main.dart:141-149` | Medium | Affects lifecycle/rebuild scope across app |
| MAP-03 | Booking feature directly starts chat via `ChatRepository` | `lib/features/booking/viewmodels/booking_view_model.dart:650-669` | Medium | Direct dependency / blast radius |
| MAP-04 | Deep-link service opens chat by conversation id through `MessageService` | `lib/core/services/deep_link_service.dart:180-200`; `lib/features/chat/services/message_service.dart:121-145` | Medium | Direct dependency / auth path relies on RLS |
| SB-01 | Chat service reads/writes `conversations` and `messages` plus `tasks`/`profiles` joins | `lib/features/chat/services/message_service.dart:47-87`; `lib/features/chat/services/message_service.dart:123-132`; `lib/features/chat/services/message_service.dart:150-168`; `lib/features/chat/services/message_service.dart:232-243`; `lib/features/chat/services/message_service.dart:271-277` | High | Core data surface |
| SB-02 | Chat service calls RPCs for conversation creation + receipts | `lib/features/chat/services/message_service.dart:30-35`; `lib/features/chat/services/message_service.dart:317-330` | High | Server contract dependency |
| SB-03 | Attachments use Supabase Storage bucket `chat-attachments` | `lib/features/chat/services/attachment_service.dart:7-8`; `lib/features/chat/services/attachment_service.dart:21-29`; `lib/features/chat/services/attachment_service.dart:36-39` | High | Private file access path |
| SB-04 | Chat uses realtime streams on `messages` and `conversations` | `lib/features/chat/services/message_service.dart:335-351`; `lib/features/chat/services/message_service.dart:353-427` | High | Correctness + performance critical |
| DOC-01 | Chat docs describe RLS rules + triggers (participants only, offer payload, offer accept trigger) | `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:53-64` | High | Docs-only backend contract |
| DOC-02 | Supabase docs define `message_type_enum` values in snake_case and `{price, days}` offer payload | `Sline_everything/SUPABASE_SETUP.md:232-258` | Critical | Contract mismatch candidate |
| DOC-03 | Supabase docs list `conversations/messages` policy expectations | `Sline_everything/SUPABASE_SETUP.md:1041-1064` | High | Docs-only RLS expectations |
| DOC-04 | Supabase docs say realtime publication includes `messages` only (conversations may be missing) | `Sline_everything/SUPABASE_SETUP.md:1619-1626` | Medium | Potential runtime mismatch with code |
| SEC-01 | Chat context widget shows raw exception text to users | `lib/features/chat/view/widgets/chat_context_widget.dart:46-53` | High | Technical error leakage |
| SEC-02 | Messages screen delete flow shows raw exception text to users | `lib/features/chat/view/messages_screen.dart:213-227` | High | Technical error leakage |
| SEC-03 | Conversation parser logs raw last message payload and participant info | `lib/features/chat/models/conversation_model.dart:51-56`; `lib/features/chat/models/conversation_model.dart:74-76`; debug-only logger gate `lib/core/services/logger_service.dart:90-92` | Medium | PII/content exposure in debug logs |
| SEC-04 | Attachment flow uploads file before message insert and lacks rollback cleanup on failure | `lib/features/chat/attachments/services/send_attachment_usecase.dart:37-57`; `lib/features/chat/attachments/services/send_attachment_usecase.dart:61-73` | High | Orphaned private objects / storage drift |
| INT-01 | Client sends camelCase `offerAccepted/offerRejected` message types | `lib/features/chat/viewmodels/chat_view_model.dart:240-257`; `lib/features/chat/models/message_model.dart:16-35`; `lib/features/chat/models/message_model.dart:38-57` | Critical | Conflicts with DB enum docs |
| INT-02 | Notification branch logic expects snake_case `offer_accepted/offer_rejected` | `lib/features/chat/services/message_service.dart:286-298` | High | Behavior mismatch even if insert succeeds |
| INT-03 | Offer composer uses `delivery` payload key (not `days`) | `lib/features/chat/view/chat_screen.dart:90-103`; docs `Sline_everything/SUPABASE_SETUP.md:252-253`; docs trigger note `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:61-64` | High | Trigger validation failure risk |
| INT-04 | Realtime message stream maps each snapshot to only `rows.last` | `lib/features/chat/services/message_service.dart:335-351`; `lib/features/chat/viewmodels/chat_view_model.dart:259-289` | High | Missed messages/receipt updates risk |
| INT-05 | Realtime conversation refetch omits `sender_id`, `seen_at`, and `task_type` fields required by parser/unread UI | realtime select `lib/features/chat/services/message_service.dart:370-382`; parser expectations `lib/features/chat/models/conversation_model.dart:57-65`; task type parse `lib/features/chat/models/conversation_model.dart:84-85`; unread usage `lib/features/chat/view/messages_screen.dart:244-251` | High | Unread/task context drift after realtime updates |
| INT-06 | Conversation fetch swallows exceptions and returns empty list; VM clears state | service `lib/features/chat/services/message_service.dart:149-227`; VM `lib/features/chat/viewmodels/chat_view_model.dart:76-93` | High | False empty state / data loss UX |
| INT-07 | DM create path checks then inserts without unique-conflict recovery | `lib/features/chat/services/message_service.dart:47-87`; docs expected `23505` handling `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:187-194` | Medium | Race condition / non-idempotent UX |
| INT-08 | Conversation delete timestamp uses client clock (`DateTime.now().toUtc()`) | `lib/features/chat/services/message_service.dart:103-115` | Medium | Clock-skew impacts deletion visibility logic |
| INT-09 | Chat composer clears text immediately; VM logs send errors but does not surface them | UI `lib/features/chat/view/chat_screen.dart:349-357`; VM `lib/features/chat/viewmodels/chat_view_model.dart:204-238` | Medium | User loses unsent text on failure |
| ARCH-01 | Chat view widget imports and navigates Tasks feature UI directly | `lib/features/chat/view/widgets/chat_context_widget.dart:11-12`; `lib/features/chat/view/widgets/chat_context_widget.dart:21-55` | Medium | Cross-feature UI coupling |
| ARCH-02 | Chat view constructs offer payload schema in UI callback | `lib/features/chat/view/chat_screen.dart:87-105` | Medium | Schema drift / poor testability |
| ARCH-03 | `MessageService` directly depends on `NotificationService` | `lib/features/chat/services/message_service.dart:5-6`; `lib/features/chat/services/message_service.dart:13`; `lib/features/chat/services/message_service.dart:281-309` | Medium | Cross-domain coupling |
| PERF-01 | Broad `Consumer/watch` usage rebuilds whole screens on shared VM changes | `lib/features/chat/view/messages_screen.dart:48-57`; `lib/features/chat/view/chat_screen.dart:110-120` | Medium | Rebuild overhead |
| PERF-02 | Conversation realtime path re-fetches detailed rows for all streamed conversation ids | `lib/features/chat/services/message_service.dart:359-387`; `lib/features/chat/services/message_service.dart:390-425` | Medium | Extra network + compute |
| PERF-03 | Attachment image widget builds signed URLs/image loads without shared cache abstraction used elsewhere | `lib/features/chat/attachments/widgets/attachment_message_tile.dart:29-40`; `lib/features/chat/attachments/widgets/attachment_message_tile.dart:74-97`; comparison `lib/core/widgets/signed_image.dart:82-111`; `lib/core/widgets/signed_image.dart:163-199` | Medium | Redundant signed URL/network calls |
| CQ-01 | Unread calculation logic duplicated in two UI files | `lib/features/chat/view/messages_screen.dart:244-251`; `lib/features/chat/view/widgets/conversation_list_tile.dart:23-32` | Low | Logic drift risk |
| CQ-02 | Attachment helper/model code appears unused in current Chat flow | defs `lib/features/chat/attachments/utils/mime_utils.dart:3-20`; `lib/features/chat/attachments/models/attachment_payload.dart:25-44`; producer-only `lib/features/chat/attachments/services/pick_image_service.dart:24-31` | Low | Call-site absence is UNVERIFIED without full static dead-code tooling |
| TST-01 | Chat tests cover only `ChatScreen` widget branches and `Message` model parsing | `test/widget/chat/chat_screen_test.dart:87-143`; `test/unit/models/message_model_test.dart:20-63` | Medium | Critical service/VM/realtime paths uncovered |
| UNV-01 | Live chat SQL migrations/policies/functions are not present in repo migrations for direct verification | UNVERIFIED (missing files under `supabase/migrations/**` for chat tables/functions/policies) | High | Must verify in DB or separate SQL repo |
| UNV-02 | Storage RLS/object policies for `chat-attachments` are not verifiable from audited repo files | UNVERIFIED (missing SQL policy files for `storage.objects` / bucket policy DDL) | High | Authorization source of truth not inspectable here |

## 3) Findings
### 3.1 Security (Highest Priority)
- `SEC-01` — Raw exception leakage in chat context navigation (`lib/features/chat/view/widgets/chat_context_widget.dart:46-53`)
  - Impact: Backend/RLS/DB exception strings can be exposed to end users.
  - Exploit/Failure scenario: A permission or parsing error surfaces internal details (table names, SQL errors, stack fragments) in a snackbar.
- `SEC-02` — Raw exception leakage in conversation delete failure path (`lib/features/chat/view/messages_screen.dart:213-227`)
  - Impact: Same technical-detail leakage risk as above, plus inconsistent UX messaging.
  - Exploit/Failure scenario: RLS-denied delete or connectivity failure displays raw exception text to the user.
- `SEC-03` — Debug logging includes raw message preview and participant metadata (`lib/features/chat/models/conversation_model.dart:51-56`, `lib/features/chat/models/conversation_model.dart:74-76`)
  - Impact: Chat content and participant profile details may appear in debug logs (debug-gated by `lib/core/services/logger_service.dart:90-92`, but still PII exposure in dev/test logs).
  - Exploit/Failure scenario: Shared dev/test logs or screen recordings capture private message content.
- `SEC-04` — Attachment upload-before-message insert can leave orphaned private objects (`lib/features/chat/attachments/services/send_attachment_usecase.dart:37-57`, `lib/features/chat/attachments/services/send_attachment_usecase.dart:61-73`)
  - Impact: Storage objects can persist without DB references, complicating retention/audit/cleanup.
  - Exploit/Failure scenario: Message insert fails due RLS/enum mismatch/network after upload succeeds; user retries and duplicates orphan files.
- `UNV-01` / `UNV-02` — RLS/storage authorization source of truth is not verifiable from repo SQL
  - Impact: Client-side checks/comments in `lib/features/chat/services/message_service.dart:430-432` and `lib/features/chat/attachments/services/send_attachment_usecase.dart:16-20` cannot be trusted without DB policy verification.
  - Exploit/Failure scenario: Live policies may be weaker or different than docs; unauthorized message or storage access could occur despite client assumptions.
  - Missing files: chat policy/function SQL in `supabase/migrations/**`, storage object policy SQL for `chat-attachments`.
- `DOC-01` + `DOC-03` + `UNV-01` — Docs are treated as contract but contain policy assumptions only (`Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:53-64`, `Sline_everything/SUPABASE_SETUP.md:1041-1064`)
  - Impact: Authorization audit is incomplete until live SQL is checked.
  - Exploit/Failure scenario: Client code ships against stale docs and trusts nonexistent/changed RLS rules.

### 3.2 Data Integrity
- `INT-01` + `DOC-02` — Message type naming mismatch (camelCase client vs snake_case DB enum docs)
  - File Reference: `lib/features/chat/viewmodels/chat_view_model.dart:240-257`, `lib/features/chat/models/message_model.dart:16-57`, `Sline_everything/SUPABASE_SETUP.md:235-245`
  - Impact: `offerAccepted` / `offerRejected` inserts may fail against `message_type_enum`, and downstream triggers may not run.
  - Failure scenario: Accepting an offer appears to send in UI but backend rejects insert or stores wrong type mapping.
- `INT-02` — Notification classification mismatch for offer acceptance/rejection
  - File Reference: `lib/features/chat/services/message_service.dart:286-298`
  - Impact: Even if a message is inserted, notification title/type can be wrong because service branches only on snake_case strings.
  - Failure scenario: Accepted/rejected offers generate generic “New Message” notifications.
- `INT-03` + `DOC-01` + `DOC-02` — Offer payload key mismatch (`delivery` vs required `days`)
  - File Reference: `lib/features/chat/view/chat_screen.dart:90-103`, `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:61-64`, `Sline_everything/SUPABASE_SETUP.md:252-253`
  - Impact: Trigger validation may reject offer messages or backend automation may ignore payload.
  - Failure scenario: Offer send fails with validation error; UI has no schema-level prevention.
- `INT-04` — Realtime messages stream drops snapshot rows by returning only `rows.last`
  - File Reference: `lib/features/chat/services/message_service.dart:335-351`, `lib/features/chat/viewmodels/chat_view_model.dart:259-289`
  - Impact: Missed inserts/updates in batch snapshots or reconnect scenarios.
  - Failure scenario: Multiple messages arrive while app reconnects; only the last one is processed.
- `INT-05` — Realtime conversation payload shape omits fields needed for unread/task-context correctness
  - File Reference: realtime select `lib/features/chat/services/message_service.dart:370-382`; parser expectations `lib/features/chat/models/conversation_model.dart:57-65`, `lib/features/chat/models/conversation_model.dart:84-85`; unread calc `lib/features/chat/view/messages_screen.dart:244-251`
  - Impact: Unread badge/count and booking/task label/icon can drift after realtime updates.
  - Failure scenario: Fresh reload shows correct unread status; subsequent realtime refresh shows incorrect unread count until manual refresh.
- `INT-06` — `getUserConversations` converts backend errors into empty list and VM clears state
  - File Reference: `lib/features/chat/services/message_service.dart:149-227`, `lib/features/chat/viewmodels/chat_view_model.dart:76-93`
  - Impact: Error state is misrepresented as “no conversations”; prior valid state is lost.
  - Failure scenario: Temporary network error wipes visible conversation list and shows empty-state UX.
- `INT-07` — DM create path is not idempotent under race without unique-conflict recovery
  - File Reference: `lib/features/chat/services/message_service.dart:47-87`, docs mitigation `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:187-194`
  - Impact: Duplicate-create race can surface hard failure instead of reopening existing conversation.
  - Failure scenario: Two clients start the same DM nearly simultaneously; one side receives unhandled unique violation path.
- `INT-08` — Delete tombstone timestamps use client clock
  - File Reference: `lib/features/chat/services/message_service.dart:103-115`
  - Impact: Clock skew can break “hide until newer message” comparisons.
  - Failure scenario: User with incorrect device time hides conversation indefinitely or resurrects it incorrectly.
- `INT-09` — Composer clears before confirmed send and send errors are swallowed
  - File Reference: `lib/features/chat/view/chat_screen.dart:349-357`, `lib/features/chat/viewmodels/chat_view_model.dart:204-238`
  - Impact: User message text can be lost on failure.
  - Failure scenario: Network failure occurs after tap; text disappears, no retry prompt, no inline error state.

### 3.3 Architecture
- `ARCH-01` — Chat view directly imports and navigates Tasks feature UI
  - File Reference: `lib/features/chat/view/widgets/chat_context_widget.dart:11-12`, `lib/features/chat/view/widgets/chat_context_widget.dart:21-55`
  - Impact: Cross-feature view coupling violates clean feature boundaries and increases refactor blast radius.
- `ARCH-02` — Offer payload schema is built inside `ChatScreen` UI callback
  - File Reference: `lib/features/chat/view/chat_screen.dart:87-105`
  - Impact: UI layer owns domain contract details; harder to test and easier to drift (already drifted).
- `ARCH-03` — Chat persistence service directly invokes notification domain service
  - File Reference: `lib/features/chat/services/message_service.dart:5-6`, `lib/features/chat/services/message_service.dart:13`, `lib/features/chat/services/message_service.dart:281-309`
  - Impact: Service mixes chat persistence and cross-domain side-effects; complicates test isolation and retries.
- `MAP-02` + `PERF-01` — Single global `ChatViewModel` handles both list and thread concerns
  - File Reference: `lib/main.dart:141-149`, `lib/features/chat/viewmodels/chat_view_model.dart:34-45`, `lib/features/chat/viewmodels/chat_view_model.dart:76-93`, `lib/features/chat/viewmodels/chat_view_model.dart:259-289`
  - Impact: Shared mutable state and broad notifications create coupling between screens and subscriptions.
- Architecture guard check (strict view-to-Supabase)
  - Pass for direct Supabase usage inside Chat views: no `Supabase.instance` / raw client calls in `lib/features/chat/view/**` (UNVERIFIED by file-only negative proof; verified by targeted scan in audit command, not a file reference).
  - Fail for feature isolation due `chat_context_widget` cross-feature UI import (`lib/features/chat/view/widgets/chat_context_widget.dart:11-12`).

### 3.4 Code Quality
- `CQ-01` — Unread logic duplicated in two UI layers
  - File Reference: `lib/features/chat/view/messages_screen.dart:244-251`, `lib/features/chat/view/widgets/conversation_list_tile.dart:23-32`
  - Impact: Behavioral drift risk when unread rule changes.
- `INT-05` + `INT-06` — Conversation mapping/filtering logic is fragmented across service and VM
  - File Reference: `lib/features/chat/services/message_service.dart:170-220`, `lib/features/chat/services/message_service.dart:388-425`, `lib/features/chat/viewmodels/chat_view_model.dart:102-125`
  - Impact: Field omissions and inconsistent transformations already exist.
- `CQ-02` — Attachment helper/model definitions appear unused in current flow
  - File Reference: `lib/features/chat/attachments/utils/mime_utils.dart:3-20`, `lib/features/chat/attachments/models/attachment_payload.dart:25-44`, `lib/features/chat/attachments/services/pick_image_service.dart:24-31`
  - Impact: Dead code increases maintenance cost and hides real attachment contract.
  - Notes: Call-site absence is UNVERIFIED without dead-code tooling; confirm with analyzer + explicit search before deletion.
- Stale/debug comments in production paths
  - File Reference: `lib/features/chat/view/chat_screen.dart:12`, `lib/features/chat/models/conversation_model.dart:52-55`, `lib/features/chat/view/widgets/conversation_list_tile.dart:40-42`
  - Impact: Signals partially migrated code and unresolved behavior assumptions.
- Error handling inconsistency across chat UI/VM
  - File Reference: raw UI errors `lib/features/chat/view/widgets/chat_context_widget.dart:46-53`, `lib/features/chat/view/messages_screen.dart:213-227`; swallowed VM errors `lib/features/chat/viewmodels/chat_view_model.dart:87-89`, `lib/features/chat/viewmodels/chat_view_model.dart:196-198`, `lib/features/chat/viewmodels/chat_view_model.dart:235-237`
  - Impact: Operators/users get inconsistent feedback and harder bug triage.

### 3.5 Performance
- `INT-04` + `SB-04` — Realtime message stream design is snapshot-heavy and lossy
  - File Reference: `lib/features/chat/services/message_service.dart:335-351`
  - Impact: Correctness and performance degrade for long conversations (full snapshots processed to take one row).
- `PERF-02` — Conversation realtime path re-queries full details for all conversation ids on every emission
  - File Reference: `lib/features/chat/services/message_service.dart:359-387`, `lib/features/chat/services/message_service.dart:390-425`
  - Impact: Repeated network calls and JSON parsing under active messaging.
- `PERF-01` — Broad `Consumer/watch` scope on shared VM drives unnecessary rebuilds
  - File Reference: `lib/features/chat/view/messages_screen.dart:48-57`, `lib/features/chat/view/chat_screen.dart:110-120`, `lib/features/chat/view/chat_screen.dart:119-187`
  - Impact: List and thread UI rebuild more often than required.
- `PERF-03` — Attachment tile does not reuse shared signed-url cache/image caching abstraction
  - File Reference: `lib/features/chat/attachments/widgets/attachment_message_tile.dart:29-40`, `lib/features/chat/attachments/widgets/attachment_message_tile.dart:74-97`, comparison `lib/core/widgets/signed_image.dart:82-111`, `lib/core/widgets/signed_image.dart:163-199`
  - Impact: Extra signed URL generation and inconsistent image cache behavior.
- `DOC-04` + `SB-04` — Code subscribes to `conversations` realtime but docs say publication may include only `messages`
  - File Reference: `lib/features/chat/services/message_service.dart:355-358`, `Sline_everything/SUPABASE_SETUP.md:1619-1626`
  - Impact: Chat list realtime may silently fail in environments not configured with `conversations` publication.

### 3.6 Testing Gaps
- `TST-01` — No unit tests for `MessageService` contracts (enum names, payload schema, notification branching)
  - File Reference: Existing tests only `test/widget/chat/chat_screen_test.dart:87-143`, `test/unit/models/message_model_test.dart:20-63`
  - Impact: Current critical mismatches (`INT-01`, `INT-03`) were not prevented.
- `TST-01` — No ViewModel tests for realtime merge/upsert, error states, or send failure behavior
  - File Reference: `lib/features/chat/viewmodels/chat_view_model.dart:76-93`, `lib/features/chat/viewmodels/chat_view_model.dart:204-238`, `lib/features/chat/viewmodels/chat_view_model.dart:259-289`
  - Impact: Realtime and failure regressions are likely to ship unnoticed.
- `TST-01` — No tests for attachment pipeline failure cleanup / rollback
  - File Reference: `lib/features/chat/attachments/services/send_attachment_usecase.dart:37-73`
  - Impact: Orphan storage regression risk remains unbounded.
- `TST-01` — No integration-style tests for booking/deep-link entry to chat
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:650-669`, `lib/core/services/deep_link_service.dart:180-200`
  - Impact: Cross-feature wiring can break without Chat tests failing.

## 4) Dead/Unused Code Candidates
- Candidate: `guessMimeFromExt()` in `lib/features/chat/attachments/utils/mime_utils.dart:3-20`
  - Why candidate: helper is defined but not referenced in the audited Chat attachment flow (`lib/features/chat/attachments/services/send_attachment_usecase.dart:22-57`, `lib/features/chat/attachments/services/upload_service.dart:8-22`).
  - How to confirm: run `rg -n "guessMimeFromExt\\(" lib --glob '*.dart'` and verify no call sites outside this file.
- Candidate: `AttachmentResult` model in `lib/features/chat/attachments/models/attachment_payload.dart:25-44`
  - Why candidate: current upload path returns `String storagePath` (`lib/features/chat/attachments/services/upload_service.dart:8-22`) and does not construct `AttachmentResult`.
  - How to confirm: run `rg -n "AttachmentResult\\b" lib --glob '*.dart'`.
- Candidate: `AttachmentPayload.ext` field (`lib/features/chat/attachments/models/attachment_payload.dart:8-22`)
  - Why candidate: field is set in picker (`lib/features/chat/attachments/services/pick_image_service.dart:24-31`) but not consumed in current compress/upload/send path (`lib/features/chat/attachments/services/send_attachment_usecase.dart:22-57`).
  - How to confirm: run `rg -n "\\.ext\\b" lib/features/chat --glob '*.dart'`.
- Candidate: hardcoded offline presence branch (`isOnline = false`) in `lib/features/chat/view/widgets/conversation_list_tile.dart:40-42`
  - Why candidate: online indicator UI path is effectively disabled unless presence service is implemented (`lib/features/chat/view/widgets/conversation_list_tile.dart:214-230`).
  - How to confirm: product decision; either implement presence source or remove dormant branch.

## 5) Duplicate Code Candidates
- Duplicate unread rule
  - Files: `lib/features/chat/view/messages_screen.dart:244-251`, `lib/features/chat/view/widgets/conversation_list_tile.dart:23-32`
  - Proposed shared abstraction: `ConversationUnreadPolicy` helper or `Conversation.isUnreadFor(userId)` extension in `lib/features/chat/models/conversation_selectors.dart`.
- Duplicate conversation preview mapping/filter/sort logic
  - Files: `lib/features/chat/services/message_service.dart:170-220`, `lib/features/chat/services/message_service.dart:388-425`, `lib/features/chat/viewmodels/chat_view_model.dart:102-125`
  - Proposed shared abstraction: `ConversationMapper` + `ConversationListPolicy` in `lib/features/chat/models/conversation_mapper.dart`.
- Duplicate signed-url/image loading behavior (Chat attachment tile vs shared core widget)
  - Files: `lib/features/chat/attachments/widgets/attachment_message_tile.dart:29-40`, `lib/features/chat/attachments/widgets/attachment_message_tile.dart:74-97`, `lib/core/widgets/signed_image.dart:82-111`, `lib/core/widgets/signed_image.dart:163-199`
  - Proposed shared abstraction: reuse `SignedImage` (with `bucket: 'chat-attachments'`) or extract a shared `SignedStorageImage` widget.

## 6) Refactor Plan (Exact Paths)
- Split `MessageService` by responsibility (keep compatibility wrapper during migration)
  - Current: `lib/features/chat/services/message_service.dart`
  - New files:
    - `lib/features/chat/services/chat_conversation_service.dart`
    - `lib/features/chat/services/chat_message_service.dart`
    - `lib/features/chat/services/chat_realtime_service.dart`
    - `lib/features/chat/services/message_service.dart` (compat facade forwarding to new services; temporary)
  - Migration strategy: preserve current public methods in facade until callers (`ChatRepository`, `DeepLinkService`) are moved.
- Split global `ChatViewModel` into list/thread state
  - Current: `lib/features/chat/viewmodels/chat_view_model.dart`
  - New files:
    - `lib/features/chat/viewmodels/chat_conversations_view_model.dart`
    - `lib/features/chat/viewmodels/chat_thread_view_model.dart`
    - `lib/features/chat/viewmodels/chat_view_model.dart` (compat/composition wrapper; temporary)
  - Migration strategy: move screens one at a time; keep provider wiring stable first.
- Move offer send contract logic out of UI
  - New file:
    - `lib/features/chat/services/send_offer_message_usecase.dart`
  - Edit callers:
    - `lib/features/chat/view/chat_screen.dart`
    - `lib/features/chat/viewmodels/chat_view_model.dart`
  - Migration strategy: UI passes typed form inputs only; use-case owns payload keys and message type.
- Decouple chat context banner from Tasks feature UI
  - Current: `lib/features/chat/view/widgets/chat_context_widget.dart`
  - New files:
    - `lib/features/chat/view/widgets/chat_context_banner.dart` (UI-only)
    - `lib/features/chat/viewmodels/chat_context_view_model.dart` (optional if context loading remains in Chat domain)
  - Edits:
    - `lib/features/chat/view/chat_screen.dart` (inject callback/navigation action)
  - Migration strategy: replace direct `TaskDetailsScreen` import with callback from screen/router.
- Consolidate attachment storage service
  - Current:
    - `lib/features/chat/services/attachment_service.dart`
    - `lib/features/chat/attachments/services/upload_service.dart`
  - New target:
    - `lib/features/chat/attachments/services/chat_attachment_storage_service.dart`
  - Migration strategy: merge functionality first, then remove thin wrapper after call sites migrate.
- Add conversation mapping/selectors utilities
  - New files:
    - `lib/features/chat/models/conversation_mapper.dart`
    - `lib/features/chat/models/conversation_selectors.dart`
  - Migration strategy: reuse in both fetch and realtime code before splitting services further.

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
1. Normalize message type contract to snake_case (DB/docs parity)
   - What to change: update enum/string mapping and callers to send `offer_accepted` / `offer_rejected`; keep backward-compatible parsing for legacy camelCase values.
   - Exact file(s) to edit/create: `lib/features/chat/models/message_model.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`, `lib/features/chat/services/message_service.dart`
   - Acceptance criteria: accepting/rejecting offers inserts successfully against `message_type_enum` and `NotificationService` branch runs for accepted/rejected events.
2. Normalize offer payload schema (`days` instead of `delivery`) with backward-compatible reads
   - What to change: send `{price, days, ...}` payload; UI renderer reads `days` first and falls back to legacy `delivery` if present.
   - Exact file(s) to edit/create: `lib/features/chat/view/chat_screen.dart`, `lib/features/chat/view/widgets/offer_message_bubble.dart` (if display mapping changes), optionally `lib/features/chat/services/send_offer_message_usecase.dart` (new)
   - Acceptance criteria: offer creation succeeds with backend trigger validation described in `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:61-64`.
3. Fix realtime message processing to avoid snapshot-row loss
   - What to change: process all rows or convert stream contract to `Stream<List<Message>>`/delta-aware upsert; ensure receipt updates do not drop messages.
   - Exact file(s) to edit/create: `lib/features/chat/services/message_service.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`
   - Acceptance criteria: multi-message burst/reconnect preserves all messages and receipt fields in order.
4. Align realtime conversation query shape with parser/unread needs
   - What to change: include `sender_id`, `seen_at`, and `task_type` in realtime `last_message`/`tasks` select; centralize mapper logic.
   - Exact file(s) to edit/create: `lib/features/chat/services/message_service.dart`, `lib/features/chat/models/conversation_model.dart` (or new mapper file)
   - Acceptance criteria: unread counts and booking/task context remain correct after realtime updates without manual refresh.
5. Stop raw exception leakage in Chat UI
   - What to change: replace raw `e.toString()` snackbars with user-safe English messages; log technical detail via `AppLogger`.
   - Exact file(s) to edit/create: `lib/features/chat/view/widgets/chat_context_widget.dart`, `lib/features/chat/view/messages_screen.dart`, optionally `lib/core/utils/error_mapper.dart` (if shared mapping is adopted)
   - Acceptance criteria: UI never displays raw DB/RLS exception strings in audited Chat flows.
6. Preserve composer input on send failure (or provide explicit retry UX)
   - What to change: await send result in UI or expose send result/error from VM; clear input only on success.
   - Exact file(s) to edit/create: `lib/features/chat/view/chat_screen.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`
   - Acceptance criteria: failed send does not silently discard text.
7. Add DM create unique-conflict recovery (`23505`)
   - What to change: catch unique violation and refetch existing conversation (docs already describe desired behavior).
   - Exact file(s) to edit/create: `lib/features/chat/services/message_service.dart`
   - Acceptance criteria: concurrent DM creation returns/open existing conversation instead of hard failure.
8. Add best-effort attachment rollback on post-upload message failure
   - What to change: on message insert failure after upload, attempt storage delete (or queue cleanup) and surface safe error.
   - Exact file(s) to edit/create: `lib/features/chat/attachments/services/send_attachment_usecase.dart`, `lib/features/chat/services/attachment_service.dart`
   - Acceptance criteria: failed attachment send does not leave untracked object without cleanup attempt/log.

### Phase 2: Refactor/structure
1. Split conversation/thread responsibilities from `ChatViewModel`
   - What to change: extract list and thread state/subscriptions into separate VMs; reduce shared mutable state.
   - Exact file(s) to edit/create: `lib/features/chat/viewmodels/chat_conversations_view_model.dart`, `lib/features/chat/viewmodels/chat_thread_view_model.dart`, `lib/features/chat/viewmodels/chat_view_model.dart`, `lib/main.dart`, `lib/features/chat/view/messages_screen.dart`, `lib/features/chat/view/chat_screen.dart`
   - Acceptance criteria: screens compile with narrower rebuild scopes and independent subscriptions.
2. Remove cross-feature UI import from Chat context widget
   - What to change: convert chat context widget to callback-driven banner; navigation handled by screen/router layer.
   - Exact file(s) to edit/create: `lib/features/chat/view/widgets/chat_context_widget.dart` (or replace with `chat_context_banner.dart`), `lib/features/chat/view/chat_screen.dart`
   - Acceptance criteria: Chat widget no longer imports `TaskDetailsScreen` directly.
3. Consolidate conversation mapping/unread logic
   - What to change: extract mapper/selectors used by fetch + realtime + UI.
   - Exact file(s) to edit/create: `lib/features/chat/models/conversation_mapper.dart`, `lib/features/chat/models/conversation_selectors.dart`, `lib/features/chat/services/message_service.dart`, `lib/features/chat/view/messages_screen.dart`, `lib/features/chat/view/widgets/conversation_list_tile.dart`
   - Acceptance criteria: one unread rule implementation and one conversation preview mapping path.
4. Decouple notification side-effects from chat persistence service
   - What to change: move notification dispatch into use-case or orchestrator layer, or inject notifier interface.
   - Exact file(s) to edit/create: `lib/features/chat/services/message_service.dart`, `lib/features/chat/data/chat_repository.dart`, optional new `lib/features/chat/services/send_message_usecase.dart`
   - Acceptance criteria: `MessageService` can be unit-tested without `NotificationService` side-effects.

### Phase 3: Tests
1. Add message contract tests (enum + payload)
   - What to change: add unit tests for snake_case mapping and legacy compatibility, plus offer payload keys.
   - Exact file(s) to edit/create: `test/unit/models/message_model_test.dart`, new `test/unit/features/chat/send_offer_message_usecase_test.dart` (if use-case added)
   - Acceptance criteria: tests fail on camelCase regression and payload key regression.
2. Add `MessageService` tests for DM race recovery and notification branching
   - What to change: mock Supabase responses/errors and assert fallback/refetch behavior.
   - Exact file(s) to edit/create: new `test/unit/features/chat/message_service_test.dart`
   - Acceptance criteria: `23505` path and accepted/rejected notification branch are covered.
3. Add `ChatViewModel` realtime + failure behavior tests
   - What to change: test multi-row realtime handling, error states, and composer failure propagation contract.
   - Exact file(s) to edit/create: new `test/unit/features/chat/chat_view_model_test.dart`
   - Acceptance criteria: no message-loss regression on batched realtime events.
4. Add widget tests for safe error messaging and unread updates
   - What to change: simulate failures and realtime-updated conversation previews.
   - Exact file(s) to edit/create: `test/widget/chat/chat_screen_test.dart`, new `test/widget/chat/messages_screen_test.dart`
   - Acceptance criteria: no raw exception strings in UI; unread badge logic matches selector.
5. Add integration-style coverage for booking/deep-link chat entry (targeted)
   - What to change: add lightweight integration or high-level widget tests around booking/deep-link chat entry wiring.
   - Exact file(s) to edit/create: new `test/widget/booking/booking_chat_entry_test.dart`, new `test/unit/core/deep_link_chat_navigation_test.dart` (or project-standard equivalent)
   - Acceptance criteria: direct chat entry paths fail fast when contracts break.

### Phase 4: Polish/perf
1. Reduce rebuild scope in chat screens
   - What to change: adopt narrower selectors / split VM reads for message list, composer, header, unread counts.
   - Exact file(s) to edit/create: `lib/features/chat/view/messages_screen.dart`, `lib/features/chat/view/chat_screen.dart`, `lib/features/chat/view/widgets/*`
   - Acceptance criteria: unrelated state changes do not rebuild full screens.
2. Reuse shared signed URL/image caching path for chat attachments
   - What to change: refactor `AttachmentMessageTile` to use shared cached signed-image behavior or a shared wrapper.
   - Exact file(s) to edit/create: `lib/features/chat/attachments/widgets/attachment_message_tile.dart`, `lib/core/widgets/signed_image.dart` (only if extending shared API)
   - Acceptance criteria: repeated attachment renders avoid redundant signed URL work.
3. Clarify/trim dead code in attachments submodule
   - What to change: remove or wire `mime_utils.dart`, `AttachmentResult`, and `ext` field based on actual attachment roadmap.
   - Exact file(s) to edit/create: `lib/features/chat/attachments/utils/mime_utils.dart`, `lib/features/chat/attachments/models/attachment_payload.dart`, `lib/features/chat/attachments/services/*`
   - Acceptance criteria: no stale attachment helpers remain without explicit use.
4. Improve conversation fetch/realtime error UX
   - What to change: distinguish loading/empty/error states in VM and screens.
   - Exact file(s) to edit/create: `lib/features/chat/viewmodels/chat_view_model.dart` (or split VMs), `lib/features/chat/view/messages_screen.dart`
   - Acceptance criteria: backend failures render explicit error state instead of false empty state.

## 8) Verification Checklist
### Commands
- `flutter analyze`
- `flutter test test/unit/models/message_model_test.dart`
- `flutter test test/widget/chat/chat_screen_test.dart`
- `flutter test test/widget/chat/messages_screen_test.dart` (after adding)
- `flutter test test/unit/features/chat/message_service_test.dart` (after adding)
- `flutter test test/unit/features/chat/chat_view_model_test.dart` (after adding)
- `rg -n "offerAccepted|offerRejected|offerUpdate|deliverySubmitted|endEarlyRequest|disputeReport" lib/features/chat --glob '*.dart'`
  - Goal: confirm camelCase message type literals are removed or intentionally legacy-only parse paths.
- `rg -n "'delivery'\\s*:" lib/features/chat --glob '*.dart'`
  - Goal: confirm offer send payload uses `days` key instead of `delivery` in new writes.
- `rg -n "Text\\('Error: \\$\\{e\\.toString\\(\\)\\}'\\)|Failed to delete: \\$e" lib/features/chat --glob '*.dart'`
  - Goal: confirm raw exception UI strings are removed.
- `rg -n "guessMimeFromExt\\(|AttachmentResult\\b|\\.ext\\b" lib/features/chat --glob '*.dart'`
  - Goal: confirm attachment dead-code decision (removed or intentionally used).

### Manual Scenarios
1. Open Messages tab from main navigation and verify list loads (`lib/app/main_navigation_screen.dart:39-49`, `lib/features/chat/view/messages_screen.dart:14-268`).
2. Create/open DM from booking flow and verify chat opens correctly (`lib/features/booking/viewmodels/booking_view_model.dart:650-669`).
3. Open chat via deep link conversation id and verify fetch + navigation (`lib/core/services/deep_link_service.dart:180-200`, `lib/features/chat/services/message_service.dart:121-145`).
4. Send plain text message with network available; verify message appears once and input clears only on success (`lib/features/chat/view/chat_screen.dart:349-357`).
5. Simulate send failure (network off / mocked error); verify text is preserved or retry UI appears (`lib/features/chat/view/chat_screen.dart:349-357`, `lib/features/chat/viewmodels/chat_view_model.dart:204-238`).
6. Create custom offer; verify backend accepts payload and offer renders with correct status/type (`lib/features/chat/view/chat_screen.dart:87-105`, `lib/features/chat/view/widgets/offer_message_bubble.dart:143-277`).
7. Accept and reject an offer; verify message insert succeeds, notification type/title is correct, and no enum mismatch occurs (`lib/features/chat/viewmodels/chat_view_model.dart:240-257`, `lib/features/chat/services/message_service.dart:286-309`).
8. Send image attachment; verify image renders, signed URL resolves, and failure path shows safe message (`lib/features/chat/attachments/services/send_attachment_usecase.dart:22-73`, `lib/features/chat/attachments/widgets/attachment_message_tile.dart:74-97`, `lib/features/chat/view/chat_screen.dart:72-84`).
9. Trigger conversation delete failure; verify user-safe English error message (no raw exception) (`lib/features/chat/view/messages_screen.dart:213-227`).
10. Realtime burst test (multiple rapid messages / reconnect): verify no dropped messages and unread state stays correct (`lib/features/chat/services/message_service.dart:335-427`, `lib/features/chat/viewmodels/chat_view_model.dart:95-131`, `lib/features/chat/viewmodels/chat_view_model.dart:259-289`).

### Supabase/RLS Contract Checks
- `UNVERIFIED` in repo: chat SQL policies/functions/storage policies are not present in `supabase/migrations/**` for direct inspection (`UNV-01`, `UNV-02`).
- Validate live DB policy/function contract before applying fixes (RLS is source of truth, not client comments/docs):
  - Check policies:
    - `select schemaname, tablename, policyname, cmd, permissive, qual, with_check from pg_policies where schemaname='public' and tablename in ('conversations','messages');`
    - `select schemaname, tablename, policyname, cmd, qual, with_check from pg_policies where schemaname='storage' and tablename='objects';`
  - Check functions/RPCs:
    - `select proname from pg_proc where proname in ('start_task_conversation_v1','mark_conversation_delivered','mark_conversation_seen');`
  - Check triggers for message validation/offer acceptance:
    - `select tgname from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='messages' and not t.tgisinternal;`
  - Check enum values:
    - `select e.enumlabel from pg_type t join pg_enum e on e.enumtypid=t.oid where t.typname='message_type_enum' order by e.enumsortorder;`
  - Check realtime publication includes both tables:
    - `select * from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename in ('messages','conversations');`
  - Check bucket + access assumptions:
    - `select id, public from storage.buckets where id='chat-attachments';`
- Compare live DB results against docs used in this audit:
  - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:53-64`
  - `Sline_everything/SUPABASE_SETUP.md:232-258`
  - `Sline_everything/SUPABASE_SETUP.md:1041-1064`
  - `Sline_everything/SUPABASE_SETUP.md:1619-1626`

## 9) Risks & Rollback Notes
- What could break
  - Offer acceptance/rejection behavior can change when message type literals are normalized (`lib/features/chat/viewmodels/chat_view_model.dart:240-257`, `lib/features/chat/models/message_model.dart:16-57`, `lib/features/chat/services/message_service.dart:286-298`).
  - Booking and deep-link chat entry can regress if service/viewmodel signatures change (`lib/features/booking/viewmodels/booking_view_model.dart:650-669`, `lib/core/services/deep_link_service.dart:180-200`).
  - Realtime behavior may regress during stream contract changes (`lib/features/chat/services/message_service.dart:335-427`, `lib/features/chat/viewmodels/chat_view_model.dart:95-131`, `lib/features/chat/viewmodels/chat_view_model.dart:259-289`).
  - Attachment UX can regress if signed-image refactor changes rendering path (`lib/features/chat/attachments/widgets/attachment_message_tile.dart:74-97`, `lib/core/widgets/signed_image.dart:163-199`).
- Rollback steps
  - Keep compatibility parsing and facades during Phase 1/2:
    - Backward-compatible `MessageType` parsing in `lib/features/chat/models/message_model.dart`
    - Temporary `message_service.dart` facade if service split is introduced
    - Temporary `chat_view_model.dart` wrapper if VM split is introduced
  - Roll back in small slices:
    - Revert message type/payload changes separately from realtime refactor.
    - Revert UI error-message changes independently if only UX strings regress.
    - Revert attachment rollback logic independently if storage delete path is unstable.
  - Validate post-rollback invariants:
    - Chat tab opens (`lib/app/main_navigation_screen.dart:39-49`)
    - Booking/deep-link entry still opens chat (`lib/features/booking/viewmodels/booking_view_model.dart:650-669`, `lib/core/services/deep_link_service.dart:180-200`)
    - Message send/receive still functions for text messages (`lib/features/chat/view/chat_screen.dart:349-357`, `lib/features/chat/services/message_service.dart:271-277`)

