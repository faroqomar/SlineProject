# Execution Log: PLAN_RealtimeSubscriptionTopology_2026-03-07

**Plan:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`  
**Started:** 2026-03-07  
**Executor:** @Executor (AppLogger + Supabase MCP)

---

## Phase Status

| Phase | Status | Evidence |
|-------|--------|----------|
| Phase 0: Preconditions & Decisions | Done | Decisions locked (getConversationById; publication blocks) |
| Phase 1: Data/Contracts & Live DB | Done | Publication query run via Supabase MCP |
| Phase 2: Backend/API (Service + Repository) | Done | message_service, chat_repository updated |
| Phase 3: ViewModel | Done | _inboxMsgSub, _mergeInboxMessages, _fetchingConversationIds |
| Phase 4: UI | Done | MessagesScreen unchanged; wiring via subscribeToUserConversations |
| Phase 5: QA + Release | Done | E2E script created; flutter analyze pass; no conversations stream in lib |
| Phase 6: Documentation Sync | Done | Diagram 18, SUPABASE_SETUP, Chat Feature updated |

---

## Phase 1: Evidence

**Step 1.1 – Publication query (Supabase MCP execute_sql)**

- **Query:** `SELECT schemaname, tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime' ORDER BY schemaname, tablename;`
- **Result:** `public.messages`, `public.notifications`
- **Gate:** PASS — `conversations` is NOT in publication. Proceed to Phase 2.

---

## Phase 2–3: Code Changes

**message_service.dart**

- Removed: `subscribeToConversations` (entire method including asyncMap N+1).
- Added: `subscribeToInboxMessages(String userId)` — stream from `messages` with `.eq('receiver_id', userId)`, map to `List<Message>`, no asyncMap/select. handleError with AppLogger.w.

**chat_repository.dart**

- Removed: `subscribeToConversations`.
- Added: `subscribeToInboxMessages(userId)`, `getConversationById(conversationId)` (delegate to service).

**conversation_model.dart**

- Added: `copyWith({ lastMessage, lastMessageTime, lastMessageSenderId, lastMessageSeenAt })` for immutable merge.

**chat_view_model.dart**

- Replaced `_convoSub` with `_inboxMsgSub` (type `StreamSubscription<List<Message>>?`).
- Added `_fetchingConversationIds` (Set<String>) to guard double fetch for new conversation.
- `subscribeToUserConversations()` now calls `_repo.subscribeToInboxMessages(user.id)` and uses `_mergeInboxMessages(messages)` to update list (new Conversation instances via copyWith; new conversations via getConversationById with guard).
- dispose and teardownForRoleSwitch cancel `_inboxMsgSub`.

---

## Phase 5: Verification

- **Grep:** No `.from('conversations').stream` or `conversations` + `stream` in `lib/` — invariant satisfied.
- **flutter analyze lib/features/chat/:** No issues found.
- **E2E script:** `.TODO/improvement_the_system/ImplementReady/18_realtime-subscription-topology/MANUAL_E2E_INBOX_REALTIME.md` created with steps and N+1 check.

---

## Phase 6: Docs Updated

- `Sline_everything/AppDigram/All_Diagrams/18_realtime-subscription-topology.md`: Inbox from messages (receiver_id); conversations NOT in publication; diagram and evidence table fixed.
- `Sline_everything/SUPABASE_SETUP.md`: Realtime section — only messages and notifications; do NOT add conversations; result snippet updated.
- `Sline_everything/DEVELOPER_GUIDE/Chat Feature.md`: Realtime subsection 2.6 added (subscribeToInboxMessages, merge, getConversationById guard); service description updated.

---

## Blockers

None.

---

## Observability

- AppLogger.d: `[REALTIME] inbox messages subscription start`, `[REALTIME] inbox messages event count`, `[REALTIME] Inbox merged`, `[REALTIME] New conversation added`, `[REALTIME] subscribeToUserConversations` / `unsubscribeFromUserConversations`.
- AppLogger.w: Inbox stream handleError (timeout/protocol/connection); getConversationById catchError.
- AppLogger.e: merge/parse errors; subscription onError.
- No print(); all logging via AppLogger.

---

## SQL via Supabase MCP

- **Phase 1 (verification):** `execute_sql` — `SELECT schemaname, tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';` — result: messages, notifications only.
- **Enforcement migration:** `apply_migration` — `realtime_topology_no_conversations`: idempotent DO block that drops `conversations` from `supabase_realtime` if present (so it is never in publication). Applied successfully via MCP.
- **Re-verification (post-migration):** Publication query re-run; result: `conversation_presence`, `messages`, `notifications` — **conversations** not in list (invariant satisfied).

## Rollback

- **App:** Revert commit(s) that introduced subscribeToInboxMessages and removed subscribeToConversations.
- **DB:** No rollback needed for realtime topology migration (it only removes conversations from publication if present). To re-add conversations to publication (not recommended): `ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;`
- Emergency: Comment out `subscribeToUserConversations()` call in MessagesScreen initState for pull-to-refresh-only behavior.
