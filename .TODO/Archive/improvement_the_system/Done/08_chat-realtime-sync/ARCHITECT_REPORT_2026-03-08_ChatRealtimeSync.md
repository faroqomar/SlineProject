# Architect Report — Chat Realtime Sync (08_chat-realtime-sync)

**Date:** 2026-03-08  
**Plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`  
**Execution log:** `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md`  
**Scope:** Feature 08_chat-realtime-sync (presence, receipts, realtime merge).

---

## 1. Summary

Implementation was scanned for MVVM boundaries, data flow, contract alignment, and path/name references. **Conclusion:** The feature is MVVM-compliant, data flow matches the plan (accumulation in ViewModel, ChatRealtimeMerger, presence subscription, feature flag), and contract/migrations/RLS references are consistent. A few optional refactors and one contract note are recorded below. **No code changes were made** (report only).

---

## 2. Files and Objects Scanned

### 2.1 Code (lib/features/chat/)

| Path | Purpose |
|------|--------|
| `lib/features/chat/view/chat_screen.dart` | Chat UI; typing row, receipt status, setTyping, Consumer&lt;ChatViewModel&gt; |
| `lib/features/chat/view/widgets/conversation_list_tile.dart` | List tile; otherUserTyping, presenceUpdatedAt, 15s TTL helper |
| `lib/features/chat/view/widgets/message_bubble.dart` | Bubble; status 'sent' \| 'delivered' \| 'read' |
| `lib/features/chat/viewmodels/chat_view_model.dart` | _lastMessages, merger, presence, feature flag, 15s TTL, stream error handling |
| `lib/features/chat/services/message_service.dart` | upsertPresence, subscribeToPresence, subscribeToMessages, isPresenceReceiptsEnabled, throttle |
| `lib/features/chat/services/chat_realtime_merger.dart` | merge(existing, newRows, fromJson) |
| `lib/features/chat/data/chat_repository.dart` | Delegates to MessageService; exposes presence and messages streams |
| `lib/features/chat/models/conversation_model.dart` | otherUserTyping, presenceUpdatedAt, copyWith |
| `lib/features/chat/models/message_model.dart` | deliveredAt, seenAt, fromJson/toJson |

### 2.2 Test

| Path | Purpose |
|------|--------|
| `test/features/chat/services/chat_realtime_merger_test.dart` | 4 tests: empty merge, dedupe by id, order by created_at, skip unparseable |

### 2.3 Migrations

| Path | Purpose |
|------|--------|
| `supabase/migrations/20260307219900_chat_presence_and_rls_full.sql` | conversation_presence CREATE IF NOT EXISTS, RLS (presence_*), realtime ADD TABLE (messages, conversation_presence), app_config chat_presence_receipts_enabled |
| `supabase/migrations/20260307220000_chat_realtime_presence_publication.sql` | ADD TABLE conversation_presence to supabase_realtime |
| `supabase/migrations/20260307220100_chat_presence_receipts_flag.sql` | app_config insert chat_presence_receipts_enabled (ON CONFLICT DO NOTHING) |

### 2.4 Contract and RLS

| Path | Purpose |
|------|--------|
| `.TODO/08_chat_realtime_contract.md` | messages/conversation_presence columns, RPCs mark_conversation_delivered / mark_conversation_seen |
| `.TODO/08_RLS_verification_chat.md` | Check 1–4 procedure (participant SELECT/INSERT, non-participant SELECT, receiver UPDATE, presence INSERT negative) |
| `.TODO/RLS_Matrix_Chat_2026-03-07.md` | Policy names and intent for messages and conversation_presence |
| `.TODO/08_live_db_state_20260307.md` | Live DB state used for migration strategy |

---

## 3. MVVM Boundary Check

**Result: PASS — No direct Supabase in View.**

- **Evidence:** Grep for `Supabase.instance`, `supabase.`, `_client.`, `from(` in `lib/features/chat/view/` returned **no matches**.
- **View → ViewModel:** `chat_screen.dart` uses `context.read<ChatViewModel>()` / `context.watch<ChatViewModel>()`, `Consumer<ChatViewModel>`, and calls `_chatCtrl.subscribeToActiveConversation()`, `setTyping()`, `markReceiptsForActive()`, `sendImageForActive()`, etc. `conversation_list_tile.dart` uses `context.read<ChatViewModel>()` for `currentUserId`, `activeConversation`, `otherUserTyping`, and uses `conversation.otherUserTyping` / `conversation.presenceUpdatedAt`.
- **ViewModel → Repository/Service:** `ChatViewModel` uses `ChatRepository` only (`_repo`); no direct `Supabase.instance.client` for data (only `client.removeAllChannels()` in teardownForRoleSwitch, which is lifecycle/cleanup).
- **Service:** `MessageService` holds `_client` (SupabaseClient) and performs all `from('messages')`, `from('conversation_presence')`, `from('app_config')`, and RPCs.

---

## 4. Data Flow Validation

### 4.1 ChatRealtimeMerger and accumulation

- **Plan:** ViewModel keeps `_lastMessages` for the active conversation; on each stream emission, merge with `ChatRealtimeMerger.merge(_lastMessages, newRows, Message.fromJson)`, then set `_lastMessages = merged`, update `currentMessages`, `notifyListeners()`.
- **Code:** In `chat_view_model.dart`, `subscribeToActiveConversation()` subscribes to `_repo.subscribeToMessages(cid)`. Listener receives `List<Message> messages`, converts to `newRows` via `messages.map((m) => m.toJson()).toList()`, then `merged = ChatRealtimeMerger.merge(_lastMessages, newRows, Message.fromJson)`, `_lastMessages = merged`, `currentMessages` cleared and filled with `merged`, `_notify()`. **Matches plan.**
- **Initialization:** `fetchMessages(conversationId)` (called from `messages_screen.dart` in `_openChat` before navigating to ChatScreen) sets `_lastMessages = List.from(msgs)` and updates `currentMessages`, so the first realtime emission merges with the correct conversation’s messages.

### 4.2 Presence subscription

- **Plan:** When feature flag is true, subscribe to presence for active conversation; update `_otherUserTyping` and `_presenceUpdatedAt`; also update the corresponding conversation in `conversations` with `copyWith(otherUserTyping, presenceUpdatedAt)`.
- **Code:** When `_presenceReceiptsEnabled == true`, `_presenceSub = _repo.subscribeToPresence(cid).listen(...)`; listener filters rows by other user id, sets `_otherUserTyping` and `_presenceUpdatedAt`, and updates the conversation in `conversations` via `copyWith`. **Matches plan.**

### 4.3 Feature flag

- **Plan:** App-level flag `chat_presence_receipts_enabled`; when false, no presence upsert, no typing/ticks (single tick only).
- **Code:** `MessageService.isPresenceReceiptsEnabled()` reads `app_config` key `chat_presence_receipts_enabled` (cached 1 min). ViewModel calls it in `subscribeToActiveConversation()` and stores in `_presenceReceiptsEnabled`. If not true: no `subscribeToPresence`, no `upsertPresence` from `setTyping`. In `chat_screen.dart`, `status = controller.isPresenceReceiptsEnabled && isMine ? (seen/delivered/sent) : (isMine ? 'sent' : null)`; typing row shows only when `vm.otherUserTyping` (which is false when flag is off because presence is not subscribed). **Matches plan.**

### 4.4 15s TTL

- **Plan:** Client ignores `is_typing` when `now() - updated_at > 15s`.
- **Code:** ViewModel getter `otherUserTyping` returns false if `!_otherUserTyping`, or `_presenceUpdatedAt == null`, or `DateTime.now().difference(_presenceUpdatedAt!).inSeconds > 15`. Conversation list tile uses `_isTypingWithin15s(conversation.presenceUpdatedAt, conversation.otherUserTyping)`. **Matches plan.**

### 4.5 Stream error handling

- **Plan:** On stream error, log, keep last known list (or empty), optionally reconnecting.
- **Code:** In `subscribeToMessages` listener, `onError` logs with AppLogger, then `currentMessages.clear(); currentMessages.addAll(_lastMessages); _notify()`. No automatic reconnect; user can reopen chat to resubscribe. **Matches plan.**

---

## 5. Contract and Path/Name Validation

### 5.1 Contract (`.TODO/08_chat_realtime_contract.md`)

- **messages:** Columns id, conversation_id, sender_id, receiver_id, content, message_type, payload, attachment_*, delivered_at, seen_at, created_at — **aligned** with `MessageService.getMessages`/`sendMessage` select/insert and `Message.fromJson`/`toJson`.
- **conversation_presence:** Columns conversation_id, user_id, is_typing, updated_at — **aligned** with `MessageService.upsertPresence` and presence stream handling. **Note:** Contract says `user_id` FK to `auth.users`; migration and live DB use `profiles(id)`. This is consistent with app schema (profiles mirrors auth users); no change required, but docs could state "user_id references profiles(id)" for clarity.
- **RPCs:** Contract lists `mark_conversation_delivered(p_conversation_id uuid)` and `mark_conversation_seen(p_conversation_id uuid)`. **MessageService** uses `mark_conversation_delivered` and `mark_conversation_seen` with `params: {'p_conversation_id': conversationId}`. **Aligned.**

### 5.2 Migrations

- **20260307219900:** Creates `conversation_presence` (IF NOT EXISTS), enables RLS on `conversation_presence` and `messages`, adds presence policies (presence_select_participant, presence_upsert_self, presence_update_self), adds messages and conversation_presence to `supabase_realtime` (idempotent block), inserts `app_config` key `chat_presence_receipts_enabled`. References to plan and contract (table/column names) are correct.
- **20260307220000:** Adds `conversation_presence` to `supabase_realtime` (standalone ALTER; may be redundant if 20260307219900 already ran).
- **20260307220100:** Inserts same app_config key (ON CONFLICT DO NOTHING). Ordering: 219900 runs before 220000 and 220100; 220100 duplicates the flag insert in 219900; idempotent.

### 5.3 RLS and verification

- **RLS_Matrix_Chat_2026-03-07.md:** Lists policies for `messages` (including messages_update_by_receiver) and `conversation_presence` (presence_select_participant, presence_upsert_self, presence_update_self). **Aligned** with migration 20260307219900 and verification doc.
- **08_RLS_verification_chat.md:** Check 1–4 reference participant SELECT/INSERT, non-participant SELECT, receiver UPDATE (mark_conversation_delivered / mark_conversation_seen), and presence INSERT negative. **Aligned** with contract and matrix.

---

## 6. Architecture / Logic Findings

- **Single source of truth:** Message list for the active conversation is owned by the ViewModel (`currentMessages` + `_lastMessages`); merged in ViewModel; service emits snapshots only. **Correct.**
- **No N+1 in view layer:** View does not perform async or DB calls; list data comes from ViewModel. **Correct.**
- **Presence throttle:** MessageService throttles upsert to 5s per conversation. **Correct.**
- **Lifecycle:** `subscribeToActiveConversation` is called from ChatScreen initState; `unsubscribeFromConversation` and `_msgSub`/`_presenceSub` cancel in dispose and in teardownForRoleSwitch. **Correct.**

---

## 7. Optional Refactors (Non-Blocking)

1. **Defensive clear of _lastMessages on subscribe:** Today, `_lastMessages` is always set by `fetchMessages(convo.id)` in `messages_screen._openChat` before navigating to ChatScreen. If a future entry point (e.g. deep link) opens ChatScreen without calling `fetchMessages` for that conversation, `_lastMessages` could still refer to a previous conversation and the merger would mix two conversations by id. **Suggestion:** At the start of `subscribeToActiveConversation()`, set `_lastMessages = []` (or clear when `cid != activeConversation?.id` if tracking cid) so the active conversation’s list is driven only by that conversation’s stream. **Low priority** while the only entry point is _openChat.
2. **Migration ordering:** 20260307220100 duplicates the app_config insert in 20260307219900. No functional issue (ON CONFLICT DO NOTHING). For clarity, docs could state that 219900 is the single source for the flag insert and 220100 is legacy/redundant.

---

## 8. Data Flow Map (Concise)

```
View (chat_screen, conversation_list_tile, message_bubble)
  → read/watch ChatViewModel
  → status from controller.isPresenceReceiptsEnabled + msg.deliveredAt/seenAt
  → typing from vm.otherUserTyping (15s TTL in VM) or conversation + _isTypingWithin15s
  → setTyping(trim.isNotEmpty) → ViewModel.setTyping

ChatViewModel
  → ChatRepository (only)
  → _lastMessages + ChatRealtimeMerger.merge on subscribeToMessages emission
  → subscribeToPresence when flag on; _otherUserTyping, _presenceUpdatedAt; update conversations[idx].copyWith
  → isPresenceReceiptsEnabled from _repo.isPresenceReceiptsEnabled()
  → otherUserTyping getter: 15s TTL
  → setTyping → _repo.upsertPresence (throttled in service)
  → markReceiptsForActive → _repo.markDelivered / markSeen

ChatRepository
  → MessageService (only)

MessageService
  → Supabase client: messages, conversation_presence, app_config, RPCs
  → subscribeToMessages: stream of List<Message> (snapshots)
  → subscribeToPresence: stream of List<Map<String, dynamic>>
  → upsertPresence: 5s throttle per conversation
```

---

## 9. Evidence Summary

| Check | Result | Evidence |
|-------|--------|----------|
| No Supabase in view | PASS | Grep over lib/features/chat/view: no Supabase.instance, supabase., _client., from( |
| Data flow View → VM → Repo/Service | PASS | View uses only ChatViewModel; VM uses only ChatRepository; Repository uses only MessageService |
| ChatRealtimeMerger + _lastMessages | PASS | ViewModel merges in subscribeToMessages listener; fetchMessages sets _lastMessages before open |
| Presence subscription + 15s TTL | PASS | subscribeToPresence when flag on; otherUserTyping getter and _isTypingWithin15s in tile |
| Feature flag | PASS | app_config chat_presence_receipts_enabled; VM and UI gate presence and receipt ticks |
| Stream error handling | PASS | onError: keep _lastMessages, restore currentMessages, _notify() |
| Contract (tables, RPCs) | PASS | Message and Conversation models and service calls match 08_chat_realtime_contract.md |
| Migrations (names, tables) | PASS | 20260307219900/220000/220100 reference correct table and config key names |
| RLS matrix and verification | PASS | RLS_Matrix_Chat and 08_RLS_verification_chat align with migration and contract |

---

## 10. Conclusion

The Chat Realtime Sync implementation is **MVVM-compliant**, uses a **single source of truth** for the message list with **accumulation in the ViewModel** and **ChatRealtimeMerger**, and correctly applies the **feature flag**, **15s TTL**, and **stream error** behavior. Contract, migrations, and RLS docs are consistent and correctly referenced. Optional refinements (defensive clear of _lastMessages on subscribe, migration doc note) are non-blocking. No breaking changes or code edits recommended for this report.
