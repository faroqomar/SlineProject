# Architect Report: Realtime Subscription Topology

**Scope:** RealtimeSubscriptionTopology (Plan 18)  
**Plan:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @Architect

---

## 1) Architecture / Logic Findings

### 1.1 MVVM Boundary Check ✅

- **View:** `messages_screen.dart` calls `subscribeToUserConversations()` only; no Supabase or repository access. No change to view layer.
- **ViewModel:** `chat_view_model.dart` uses only `_repo.subscribeToInboxMessages(user.id)` and `_repo.getConversationById(...)`. No direct Supabase calls.
- **Repository:** `chat_repository.dart` delegates to `MessageService` for all data and streams.
- **Service:** `message_service.dart` is the only layer that calls `_client.from('messages').stream(...)` and `_client.from('conversations').select(...)`.

**Verdict:** MVVM boundaries respected. No UI → Supabase.

### 1.2 Data Flow Map

- **Inbox list source of truth:** Single list `conversations` in ChatViewModel. Initial load: `fetchConversations()` (REST). Updates: `subscribeToInboxMessages(userId)` → `_mergeInboxMessages(messages)` (new Conversation instances via copyWith; new convos via getConversationById with guard).
- **Single query path:** Inbox realtime uses one stream (messages by receiver_id). No duplicate subscriptions; previous _inboxMsgSub cancelled before re-subscribe.
- **N+1 removed:** No `.select()` or `.in_('id', ...)` inside stream handlers; merge is in-memory only (except one getConversationById per new conversation_id, guarded).

### 1.3 Contract Checks

- **subscribeToInboxMessages(userId):** Returns `Stream<List<Message>>`. Message has conversationId, content, createdAt, senderId, receiverId (verified in message_model.dart). Contract satisfied.
- **getConversationById(conversationId):** Returns `Future<Conversation>`; throws if not found. Repository exposes it; ViewModel catches and logs. Contract satisfied.
- **Conversation.copyWith:** Used only for lastMessage, lastMessageTime, lastMessageSenderId, lastMessageSeenAt. Preserves otherUserTyping and presenceUpdatedAt (fixed in this review so typing state is not lost on merge).

### 1.4 Path Validation

| Path | Exists | Notes |
|------|--------|-------|
| lib/features/chat/services/message_service.dart | ✅ | subscribeToInboxMessages, getConversationById |
| lib/features/chat/data/chat_repository.dart | ✅ | subscribeToInboxMessages, getConversationById |
| lib/features/chat/viewmodels/chat_view_model.dart | ✅ | _inboxMsgSub, _mergeInboxMessages, _fetchingConversationIds |
| lib/features/chat/models/conversation_model.dart | ✅ | copyWith |
| lib/features/chat/view/messages_screen.dart | ✅ | No change; calls subscribeToUserConversations |

### 1.5 Proposed Refactors / Fixes

- **Done in review:** Conversation.copyWith now preserves `otherUserTyping` and `presenceUpdatedAt` so typing indicator is not reset when merging inbox messages.
- **Optional:** Consider extracting _mergeInboxMessages into a small private helper that returns the updated list (pure function) for easier unit testing; not required for correctness.

---

## 2) Risk Notes

- **Async merge:** getConversationById is async; the then/catchError run later. _notify() is called inside then, so UI updates after fetch. Race: two messages for same new conversation could still trigger two fetches if the first then hasn’t run yet; _fetchingConversationIds reduces but does not eliminate that window. Acceptable for current scope; could add a single “pending new convo” lock if needed later.
- **Dispose:** _mounted check in then callback and cancel in dispose prevent use-after-dispose. No leak found.

---

## 3) Evidence Summary

- Scanned: message_service.dart (subscribeToInboxMessages, no subscribeToConversations), chat_repository.dart, chat_view_model.dart (_mergeInboxMessages, _inboxMsgSub, _fetchingConversationIds), conversation_model.dart (copyWith).
- Plan reference: Phase 2–3 steps and gate checks matched to code.

**Verdict:** Architecture and MVVM compliant. Single fix applied (copyWith preserves typing fields). No blocker.
