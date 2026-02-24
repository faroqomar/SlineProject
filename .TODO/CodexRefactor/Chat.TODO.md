# Chat Feature Audit (Phase 1)

## Overview (what feature does, boundaries, dependencies)

- **Feature purpose:** user-to-user conversations (task-linked and direct), message send/receive, offers, receipts, attachments, and realtime updates.
- **Primary entry UI:** `lib/features/chat/view/messages_screen.dart`, `lib/features/chat/view/chat_screen.dart`, `lib/features/chat/view/widgets/create_offer_sheet.dart`
- **Primary state/data path:** `ChatViewModel` -> `ChatRepository` -> `MessageService` / attachment services -> Supabase (tables `conversations`, `messages`, RPCs `start_task_conversation_v1`, `mark_conversation_delivered`, `mark_conversation_seen`, storage bucket `chat-attachments`)
- **Direct dependencies touched by Chat code (audited):**
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/features/notifications/models/notification_model.dart`
  - `lib/features/tasks/viewmodels/task_view_model.dart`
  - `lib/features/tasks/view/task_details_screen.dart`
  - `lib/features/tasks/models/task_model.dart`
  - `lib/core/services/logger_service.dart`
  - `lib/core/utils/loading_utils.dart`
- **Static analysis used:** scoped `flutter analyze` on Chat + direct dependency files (no analyzer issues found).
- **Important audit limitation:** no local Supabase SQL migrations/schema files were present (`rg --files | rg '\.sql$'` returned none). RLS/policy/realtime findings are based on client code + project docs (`Sline_everything/*`) and should be verified against the live DB.

## Findings

### Security (highest priority)

1. **High: stale thread messages can be shown in the wrong conversation (client-side privacy leak)**
   - `lib/features/chat/viewmodels/chat_view_model.dart:35` stores a shared mutable `currentMessages` list for all threads.
   - `lib/features/chat/viewmodels/chat_view_model.dart:186` only clears/replaces `currentMessages` on successful fetch; on error it logs and returns without clearing/rethrowing (`:196-198`).
   - `lib/features/chat/view/messages_screen.dart:259` always navigates after `await fetchMessages(...)`, even if fetch failed (because errors are swallowed).
   - `lib/features/chat/view/chat_screen.dart:36` does not fetch messages on open; it renders whatever is already in `currentMessages`.
   - Multiple non-Chat entry points push `ChatScreen` directly without prefetch (examples: `lib/core/services/deep_link_service.dart:199`, `lib/features/tasks/view/task_details_screen.dart:353`, `lib/features/orders/view/orders_dashboard_screen.dart:315`, `lib/features/favorites/view/favorites_screen.dart:113`, `lib/features/profile/view/public_profile_screen.dart:424`, `lib/features/booking/view/booking_details_screen.dart:404`, `lib/features/work/view/work_item_details_screen.dart:555`).
   - **Impact:** one conversation can temporarily (or persistently, if fetch fails) display messages from another conversation.

2. **High: backend message-type contract drift breaks offer acceptance/rejection semantics**
   - Docs describe snake_case values (`offer_accepted`, `offer_rejected`) and DB trigger behavior on `offer_accepted`:
     - `Sline_everything/DEVELOPER_GUIDE.md:1756`
     - `Sline_everything/DEVELOPER_GUIDE.md:1790`
     - `Sline_everything/DEVELOPER_GUIDE.md:1796`
     - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:29`
   - Chat code sends/parses camelCase values instead:
     - `lib/features/chat/viewmodels/chat_view_model.dart:244` (`offerAccepted`)
     - `lib/features/chat/viewmodels/chat_view_model.dart:254` (`offerRejected`)
     - `lib/features/chat/models/message_model.dart:16-56` (camelCase parser/serializer only)
   - `lib/features/chat/services/message_service.dart:286-298` notification logic expects snake_case (`offer_accepted` / `offer_rejected`), so current ViewModel values bypass offer notification handling too.
   - **Impact:** offer accept/reject actions may not trigger expected backend logic and may be treated as plain messages.

3. **Medium: authorization/RLS contract drift in docs/comments increases authz regression risk**
   - `Sline_everything/SUPABASE_SETUP.md:71` says direct DMs no longer require favorites.
   - `Sline_everything/DEVELOPER_GUIDE.md:1788` and `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:57` still say DMs require favorites.
   - `lib/features/chat/services/message_service.dart:430-431` comments also describe favorites-based DM rules and task-owner caller assumptions.
   - **Impact:** client behavior/comments may be coded against outdated policy assumptions; future fixes may reintroduce wrong UX gates or trust the wrong authz model.

4. **Medium: raw exception text is surfaced in chat-context UI**
   - `lib/features/chat/view/widgets/chat_context_widget.dart:52` shows `Error: ${e.toString()}` to end users.
   - **Impact:** low-grade information disclosure (technical errors / DB messages) and poor UX.

5. **Low (verification-required): notification creation is client-side and depends entirely on RLS correctness**
   - `lib/features/chat/services/message_service.dart:300-309` writes notifications from the client via `NotificationService`.
   - `lib/features/notifications/services/notification_service.dart:98-156` inserts/updates `notifications`.
   - **Risk:** if `notifications` RLS is permissive, a compromised client could spoof notifications for arbitrary users. This must be verified in DB policies (not available locally).

### Data Integrity

1. **High: shared thread state + swallowed fetch errors causes cross-thread state contamination**
   - Same root cause as Security finding #1.
   - Also affects `MessagesScreen` path, not only external entry points, because `fetchMessages()` suppresses failures and `_openChat()` still pushes.

2. **High: offer payload schema likely drift (`delivery` vs documented `days`)**
   - `lib/features/chat/view/chat_screen.dart:75-87` sends offer payload with keys `title`, `description`, `price`, `delivery`.
   - Docs state trigger validates `price` + `days` in payload:
     - `Sline_everything/DEVELOPER_GUIDE.md:1795`
     - `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md:63`
   - **Impact:** if docs match production DB trigger, offer creation fails; if code matches DB, docs are stale and dangerous for future changes.

3. **Medium: realtime conversation updates drop unread-state fields**
   - Initial fetch includes `seen_at` + `sender_id` in embedded last message:
     - `lib/features/chat/services/message_service.dart:163`
   - Realtime re-fetch omits those fields:
     - `lib/features/chat/services/message_service.dart:381`
   - Unread logic depends on them:
     - `lib/features/chat/models/conversation_model.dart:62-65`
     - `lib/features/chat/view/messages_screen.dart:244-251`
     - `lib/features/chat/view/widgets/conversation_list_tile.dart:23-32`
   - **Impact:** unread badge/count can become incorrect after realtime updates.

4. **Medium: `ChatScreen` depends on callers to preload messages (hidden contract)**
   - `lib/features/chat/view/chat_screen.dart:36-46` subscribes/marks receipts but never loads thread messages.
   - **Impact:** inconsistent behavior across entry points and fragile navigation APIs.

5. **Medium: `sendMessage` error path loses user input**
   - `lib/features/chat/view/chat_screen.dart:333-339` clears input immediately and does not await send.
   - `lib/features/chat/viewmodels/chat_view_model.dart:235-237` logs errors but suppresses them.
   - **Impact:** failed sends can silently discard typed text.

### Architecture

1. **High: chat/tasks import cycle and cross-feature view coupling**
   - `lib/features/chat/view/chat_screen.dart:12` imports `chat_context_widget.dart`
   - `lib/features/chat/view/widgets/chat_context_widget.dart:11-12` imports `TaskDetailsScreen` + `TaskViewModel`
   - `lib/features/tasks/view/task_details_screen.dart:15` imports `ChatScreen`
   - This creates a `chat -> tasks -> chat` import cycle through UI layers.
   - `ChatContextWidget` also performs data fetch + navigation (`:21-55`) inside a view widget, increasing coupling.

2. **Medium: monolithic `ChatViewModel` mixes conversation-list state and thread state**
   - `lib/features/chat/viewmodels/chat_view_model.dart:34-45` stores both list and active-thread state/subscriptions.
   - `MessagesScreen` and `ChatScreen` both observe the same notifier (`lib/features/chat/view/messages_screen.dart:48`, `lib/features/chat/view/chat_screen.dart:103`).
   - **Impact:** unnecessary rebuilds and cross-screen state coupling while navigating.

3. **Medium: attachment send path bypasses injected repository/client and uses globals**
   - `lib/features/chat/viewmodels/chat_view_model.dart:298-307` calls top-level use case.
   - `lib/features/chat/attachments/services/send_attachment_usecase.dart:16` creates global `Supabase.instance.client` and `MessageService()` directly.
   - **Impact:** weaker testability and inconsistent dependency injection.

4. **Low: public mutable state collections expose internal invariants**
   - `lib/features/chat/viewmodels/chat_view_model.dart:34-35` exposes mutable `List`s directly.
   - **Impact:** accidental external mutation risk and harder debugging.

### Code Quality

1. **Medium: duplicate unread logic**
   - `lib/features/chat/view/messages_screen.dart:244-251`
   - `lib/features/chat/view/widgets/conversation_list_tile.dart:23-32`

2. **Medium: duplicate conversation filtering/mapping logic between fetch and realtime paths**
   - Deletion filter + sort duplicated in `lib/features/chat/services/message_service.dart:147-228` and `lib/features/chat/services/message_service.dart:359-426`
   - Conversation DTO enrichment duplicated in `lib/features/chat/services/message_service.dart:198-208` and `lib/features/chat/viewmodels/chat_view_model.dart:104-115`

3. **Low: silent catch blocks reduce debuggability**
   - `lib/features/chat/services/message_service.dart:81-84`
   - `lib/features/chat/view/chat_screen.dart:127-129`
   - `lib/features/chat/attachments/services/compress_service.dart:23-24`

4. **Low: outdated/inaccurate comments**
   - `lib/features/chat/attachments/widgets/attachment_message_tile.dart:7` comment shows a storage path including bucket prefix, but uploader stores bucket-relative paths.
   - `lib/features/chat/services/message_service.dart:430-431` comments conflict with newer documented business rules.

### Performance

1. **High (scaling): no message pagination + heavy realtime strategy**
   - `lib/features/chat/services/message_service.dart:231-243` fetches full conversation history.
   - `lib/features/chat/services/message_service.dart:336-350` message realtime stream receives row sets and maps only the last row.
   - `lib/features/chat/viewmodels/chat_view_model.dart:269-279` handles only one message per event and also calls receipt RPCs per event.
   - **Impact:** long threads will incur increasing bandwidth/latency and stale updates for non-last-message changes.

2. **Medium: conversation realtime pipeline refetches full enriched list on every event**
   - `lib/features/chat/services/message_service.dart:355-427`
   - `lib/features/chat/viewmodels/chat_view_model.dart:104-123` rebuilds whole conversation list on each emission.
   - **Impact:** redundant queries and UI churn.

3. **Medium: off-screen `MessagesScreen` can rebuild during active chat because list/thread share one notifier**
   - `lib/features/chat/view/messages_screen.dart:48-240`
   - `lib/features/chat/view/chat_screen.dart:103-171`
   - **Impact:** hidden rebuild cost while user is in a thread.

4. **Low/Medium: attachment image tiles generate signed URLs per tile with no shared cache**
   - `lib/features/chat/attachments/widgets/attachment_message_tile.dart:29-33`
   - **Impact:** repeated signed-URL calls for image-heavy threads and possible URL expiry issues on long-lived screens.

### Testing gaps

- No local Dart test files were found (`rg --files | rg '_test\\.dart$'` returned none).
- No Chat unit tests for:
  - message type mapping compatibility (snake_case + camelCase)
  - offer payload schema validation (`days` vs `delivery`)
  - conversation parsing (`last_message` object/list + unread fields)
  - stale-state prevention on message fetch failure
  - realtime conversation unread badge updates
- No widget tests for:
  - opening Chat from each entry path (messages list, deep link, task/profile/favorites/orders/booking/work)
  - send-message failure preserving input text and showing error
  - chat-context task navigation loading/error states
- No integration tests for:
  - offer accept/reject backend-trigger side effects
  - attachment upload + signed URL display
  - receipts (`delivered`/`seen`) RPC behavior

## Dead/Unused code candidates (with file paths)

- `lib/features/chat/attachments/utils/mime_utils.dart`
  - `guessMimeFromExt()` appears unused in the repo.
- `lib/features/chat/attachments/models/attachment_payload.dart`
  - `AttachmentResult` model appears unused (no references found).
- `lib/features/chat/attachments/errors/attachment_exceptions.dart`
  - `AttachmentUploadError` class appears unused (declared but never constructed).
- `lib/features/chat/services/message_service.dart`
  - `startConversationByClient()` appears unused (no references to `MessageService.startConversationByClient` found).

## Duplicate code candidates (with file paths)

- Unread detection logic duplicated:
  - `lib/features/chat/view/messages_screen.dart`
  - `lib/features/chat/view/widgets/conversation_list_tile.dart`
- Conversation deletion filter / last-message timestamp logic duplicated:
  - `lib/features/chat/services/message_service.dart` (`getUserConversations`)
  - `lib/features/chat/services/message_service.dart` (`subscribeToConversations`)
- Conversation DTO enrichment (`task_title`, other-user fields) duplicated:
  - `lib/features/chat/services/message_service.dart`
  - `lib/features/chat/viewmodels/chat_view_model.dart`
- Attachment upload/signed-url wrapper duplication:
  - `lib/features/chat/services/attachment_service.dart`
  - `lib/features/chat/attachments/services/upload_service.dart` (thin pass-through wrapper)

## Refactor plan (exact file moves/splits)

1. **Split monolithic message service**
   - Split `lib/features/chat/services/message_service.dart` into:
     - `lib/features/chat/services/chat_conversation_service.dart`
     - `lib/features/chat/services/chat_message_service.dart`
     - `lib/features/chat/services/chat_receipts_service.dart`
     - `lib/features/chat/services/chat_realtime_service.dart`
     - `lib/features/chat/services/chat_notification_adapter.dart`
   - Keep `lib/features/chat/services/message_service.dart` temporarily as a compatibility facade delegating to the new services, then delete in Phase 2.

2. **Split ChatViewModel by screen responsibility**
   - Split `lib/features/chat/viewmodels/chat_view_model.dart` into:
     - `lib/features/chat/viewmodels/conversations_view_model.dart`
     - `lib/features/chat/viewmodels/chat_thread_view_model.dart`
   - Add a temporary compatibility wrapper:
     - `lib/features/chat/viewmodels/chat_view_model.dart` (facade forwarding to the two VMs until callers are migrated)

3. **Break chat/tasks UI cycle**
   - Split `lib/features/chat/view/widgets/chat_context_widget.dart` into:
     - `lib/features/chat/view/widgets/chat_context_banner.dart` (pure UI; no `TaskViewModel`, no `TaskDetailsScreen`)
     - `lib/features/chat/viewmodels/chat_context_action_view_model.dart` (fetch context target model only)
   - Add a navigation bridge in tasks (or shared navigation layer) so Chat does not import task views:
     - `lib/features/tasks/navigation/task_context_navigator.dart`
   - Update `lib/features/chat/view/chat_screen.dart` to consume `ChatContextBanner` + callback instead of importing task screens.

4. **Normalize message type contract in a single source of truth**
   - Add:
     - `lib/features/chat/models/chat_message_type_codes.dart` (string constants + parser aliases for snake_case/camelCase)
   - Update:
     - `lib/features/chat/models/message_model.dart` to accept both formats and serialize canonical snake_case
     - `lib/features/chat/viewmodels/chat_view_model.dart`
     - `lib/features/chat/services/chat_message_service.dart` (post-split)

5. **Consolidate attachment upload code**
   - Merge wrapper `lib/features/chat/attachments/services/upload_service.dart` into `lib/features/chat/services/attachment_service.dart`
   - Add explicit metadata/content-type handling in:
     - `lib/features/chat/services/attachment_service.dart`
   - If `AttachmentResult` is kept, move to its own file:
     - `lib/features/chat/attachments/models/attachment_result.dart`
   - If not needed, remove `AttachmentResult` and keep only:
     - `lib/features/chat/attachments/models/attachment_payload.dart`

6. **Introduce thread-loading API that removes hidden caller contract**
   - Add:
     - `lib/features/chat/viewmodels/chat_thread_loader.dart` (or a method on `chat_thread_view_model.dart`)
   - Goal: all callers open threads through one API that clears stale state, fetches messages, handles errors, and then subscribes.

## Fix Plan (Phases)

### Phase 1: critical security & correctness

1. **Eliminate stale-message cross-thread leak**
   - Clear `currentMessages` before fetch begins.
   - Make `fetchMessages()` return success/error (do not silently swallow).
   - Prevent navigation to `ChatScreen` if fetch fails, or let `ChatScreen` own loading/error state and fetch itself.
   - Add defensive filtering in `ChatScreen` render path (`message.conversationId == activeConversation.id`) until architecture refactor lands.

2. **Fix message type contract drift**
   - Canonicalize to backend-compatible snake_case (`offer_accepted`, `offer_rejected`, etc.).
   - Make parser backward compatible with both camelCase and snake_case.
   - Update notification branching to use shared constants.

3. **Fix offer payload key drift**
   - Send canonical `days` key (optionally include temporary alias `delivery` during migration).
   - Accept both keys in UI parser during transition.

4. **Fix realtime unread-state correctness**
   - Include `sender_id`, `seen_at`, and `task_type` in realtime conversation re-fetch select.

5. **Fix loading-dialog lifecycle bug in Chat context navigation**
   - Ensure `LoadingUtils.hide()` runs in `finally` / root navigator-safe path.
   - Replace raw error string snackbar with user-friendly message.

6. **Verify backend policy/publication assumptions before code rollout**
   - Confirm actual RLS policies and realtime publication for `conversations`.

### Phase 2: refactor/structure

1. Split `MessageService` into conversation/message/realtime/receipts services.
2. Split `ChatViewModel` into conversation-list and thread-specific viewmodels.
3. Remove chat->tasks UI import cycle via callback/navigation bridge.
4. Replace public mutable lists with read-only views (e.g., `UnmodifiableListView`).
5. Inject dependencies (Supabase client/services) into attachment use case instead of global access.

### Phase 3: tests

1. Unit tests
   - Message type parser/serializer alias compatibility
   - Offer payload parsing (`days` + legacy `delivery`)
   - `Conversation.fromJson` for list/object `last_message` shapes
   - `fetchMessages` stale-state prevention on failure
2. Widget tests
   - `ChatScreen` opens with loading state and no stale messages
   - Send error preserves text and shows feedback
   - Unread badge/count updates after realtime conversation payload
3. Integration tests
   - Offer accept/reject trigger side effects
   - Attachment send + render via signed URL
   - Delivered/seen receipts update path

### Phase 4: polish/perf

1. Add message pagination/infinite scroll (load recent N, fetch older on demand).
2. Replace realtime “full list refetch every event” with incremental patching where safe.
3. Cache signed URLs / image widgets for attachment-heavy threads.
4. Reduce rebuild scope with `Selector`/split VMs so off-screen lists don’t rebuild on thread updates.
5. Clean debug logs that print message payload/content shapes (keep structured safe logs only).

## Verification steps (commands + manual scenarios)

### Commands (local)

- Scoped analyzer (current audit baseline):
  - `flutter analyze lib/features/chat lib/features/notifications/services/notification_service.dart lib/features/notifications/models/notification_model.dart lib/features/tasks/viewmodels/task_view_model.dart lib/features/tasks/view/task_details_screen.dart lib/features/tasks/models/task_model.dart`
- Search for hidden `ChatScreen` direct pushes (must be migrated to common open-thread API or explicitly prefetch):
  - `rg -n "ChatScreen\\(conversation:" lib --glob '*.dart'`
- Search for non-canonical message type literals (after fix should be centralized):
  - `rg -n "offerAccepted|offerRejected|offer_accepted|offer_rejected" lib/features/chat --glob '*.dart'`
- Search for raw technical error snackbars in Chat scope:
  - `rg -n "SnackBar\\(content: Text\\('Error:|Failed to .*: \\$e" lib/features/chat --glob '*.dart'`
- Architecture guard check (no Supabase in chat views):
  - `rg -n "Supabase\\.instance|SupabaseClient|http\\.|dio\\." lib/features/chat/view --glob '*.dart'`

### DB / Supabase verification (manual or SQL editor)

- Confirm realtime publication includes both tables used by Chat realtime UX:
  - `SELECT schemaname, tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename IN ('messages', 'conversations');`
- Confirm `conversations`/`messages` policies and storage policies for `chat-attachments`:
  - inspect `pg_policies` for `public.conversations`, `public.messages`, and `storage.objects`
- Confirm RPCs exist and are `SECURITY INVOKER` (unless intentionally definer with strict checks):
  - inspect `pg_proc` / function definitions for:
    - `start_task_conversation_v1`
    - `mark_conversation_delivered`
    - `mark_conversation_seen`

### Manual scenarios (must pass after fixes)

1. Open chat from **Messages list** and verify correct thread history loads (no stale messages).
2. Open chat from **Task details**, **Profile**, **Favorites**, **Orders**, **Booking**, **Work item**, and **Deep Link**:
   - thread loads correctly
   - no stale messages flash
   - header shows correct participant/context
3. Force message fetch failure (offline / revoke network) and verify:
   - no navigation to stale thread OR safe error state in `ChatScreen`
   - typed text is not silently lost
4. Send offer, then accept/reject:
   - DB accepts message type
   - expected trigger side effects occur (task assignment/status where applicable)
   - UI renders correct status/message state
5. Realtime checks:
   - new incoming message updates conversation preview + unread badge/count
   - delivered/seen ticks update without loops or excessive calls
6. Attachment flow:
   - pick large image > limit -> friendly validation error
   - pick valid image -> upload succeeds, image renders
   - reopen thread after signed URL expiry -> image still resolves (refresh path works)
7. Delete/hide conversation:
   - conversation disappears
   - conversation reappears only when a newer message arrives

## Risks & rollback notes

- **Highest-risk code change:** thread-loading flow (`fetchMessages`/navigation contract). Roll out behind a single new `openConversation()` API to avoid partial caller migrations.
- **Message-type normalization risk:** existing DB rows may contain mixed formats. Parser should accept both formats before serializer is switched to canonical snake_case.
- **Offer payload key migration risk:** backend and clients may currently disagree (`days` vs `delivery`). Use dual-read / dual-write transition temporarily and remove legacy key later.
- **Architecture split risk:** provider wiring changes (`lib/main.dart`) can break navigation state if moved all at once. Keep a compatibility `ChatViewModel` facade during migration.
- **Realtime backend risk:** enabling `conversations` in realtime publication changes server behavior. Verify subscription load and rollback SQL prepared before production change.
- **No fixes applied in this phase:** this file is an audit/report only. Source code was not modified during this step.

