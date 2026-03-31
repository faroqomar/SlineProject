# Realtime Subscription Topology — Checklist & Summary

**Plan:** 18_realtime-subscription-topology  
**What changed:** Inbox now updates in realtime from the **messages** stream instead of a broken **conversations** stream. N+1 query removed.

---

## What Was Done (Short)

| Action | What | Why |
|--------|------|-----|
| **Removed** | `subscribeToConversations` (service + repository) | The app was subscribing to `conversations`, but that table is **not** in the DB realtime publication — so the stream never received events. It also had an N+1: every event triggered a bulk `SELECT ... conversations WHERE id IN (...)` for all your chats. |
| **Added** | `subscribeToInboxMessages(userId)` | Streams **messages** where you are the **receiver**. That table is in the publication, so you get events. No extra DB calls in the handler — we only merge data in memory. |
| **Added** | `getConversationById(conversationId)` in repository | When a message arrives for a **new** conversation (not in your list yet), we fetch that one conversation instead of refetching the whole list. |
| **Modified** | `ChatViewModel` — Inbox subscription | Same method name `subscribeToUserConversations()` but it now listens to **inbox messages** and **merges** each message into the conversation list (updates last message, re-sorts). New conversations are added with one fetch, with a guard so we don’t fetch the same conversation twice. |
| **Added** | `Conversation.copyWith(...)` | Conversation is immutable. To “update” last message we create a new Conversation with the same fields plus new last message; copyWith does that and keeps typing state. |
| **Added** | Migration `20260307230000_realtime_topology_no_conversations.sql` | Ensures `conversations` is never in the realtime publication (drops it if someone adds it). So we never rely on a conversations stream again. |
| **Updated** | Docs (diagram 18, SUPABASE_SETUP, Chat Feature) | Diagram and docs now say: Inbox = messages stream (receiver_id); conversations NOT in publication. |

---

## Add / Remove / Modify (Quick List)

**Removed**
- `MessageService.subscribeToConversations` (and its N+1 asyncMap/select).
- `ChatRepository.subscribeToConversations`.
- ViewModel logic that expected a stream of **conversation** rows (replaced by message-based merge).

**Added**
- `MessageService.subscribeToInboxMessages(userId)` — stream `messages` with `.eq('receiver_id', userId)`.
- `ChatRepository.subscribeToInboxMessages(userId)` and `getConversationById(conversationId)`.
- `Conversation.copyWith(...)` for last-message fields (and typing fields preserved).
- ViewModel: `_inboxMsgSub`, `_fetchingConversationIds`, `_mergeInboxMessages()` (merge messages into list; for new conversation_id call getConversationById once).
- AppLogger.d/w/e for subscription start/stop, merge, new convo, stream errors, getConversationById errors.
- Migration: realtime publication must not include `conversations`.
- Docs: diagram 18, SUPABASE_SETUP realtime, Chat Feature §2.6, Sline_Log entry, manual E2E script.

**Modified**
- `ChatViewModel.subscribeToUserConversations()` — now uses `subscribeToInboxMessages` and merge logic instead of replacing the list from a conversations stream.
- `ChatViewModel` subscription variable: `_convoSub` → `_inboxMsgSub` (type `StreamSubscription<List<Message>>?`).
- dispose / teardown: cancel `_inboxMsgSub` instead of `_convoSub`.
- Diagram 18 and related docs: Inbox driven by messages; conversations not in publication.

---

## Checklist — Verify on the Actual App

Use this on a device/emulator to confirm behavior.

### Before you start
- [ ] App built from the branch that has the realtime topology changes (subscribeToInboxMessages, no conversations stream).
- [ ] Two test accounts (User A and User B) or two devices.

### 1. Inbox updates without refresh
- [ ] **User A:** Open app, log in, go to **Inbox** (conversation list).
- [ ] **User B:** Log in, open a conversation with A, send a message.
- [ ] **User A (still on Inbox):** The conversation with B **moves to the top** and the **preview text** updates to the new message **without** pull-to-refresh or reopening the screen.
- [ ] **Fail if:** A must pull-to-refresh or leave and come back to see the new message.

### 2. New conversation appears
- [ ] **User B** starts a **new** conversation with A (first message).
- [ ] **User A (on Inbox):** The **new** conversation appears in the list (after a short moment). No full-screen loading spinner; at most one small load for that conversation.
- [ ] **Fail if:** New conversation never appears, or list reloads with a big spinner.

### 3. Active chat still works
- [ ] **User A** opens a conversation with B (chat screen).
- [ ] **User B** sends a message.
- [ ] **User A:** The new message **appears in the thread** immediately (same as before). No regression.
- [ ] **Fail if:** Messages don’t appear in the open chat.

### 4. Notifications unchanged
- [ ] Notifications badge and list still update when you get a notification (no change intended).
- [ ] **Fail if:** Notifications stop updating.

### 5. No crashes or freezes
- [ ] Send several messages in a row (e.g. 5–10) while the other user is on Inbox.
- [ ] **User on Inbox:** App stays responsive; list updates; no crash or long freeze.
- [ ] **Fail if:** App crashes or freezes when many messages arrive.

### 6. Logs (optional, for N+1 check)
- [ ] Run app in **debug**, watch console/AppLogger.
- [ ] Trigger inbox updates (B sends to A while A on Inbox).
- [ ] **Pass:** You see lines like `[REALTIME] inbox messages`, `[REALTIME] Inbox merged`.
- [ ] **Fail:** You see repeated logs like `SELECT ... FROM conversations ... WHERE id IN (...)` on every message (that was the old N+1).

### 7. After role switch
- [ ] Log in as **User A**, open Inbox, then **switch role** (if your app has role switching).
- [ ] Inbox should clear or refresh; no duplicate listeners or stale data.
- [ ] **Fail if:** Double updates, wrong user’s chats, or errors after role switch.

---

## One-Line Summary

**Inbox realtime now comes from new messages where you’re the receiver; the old “conversations” stream was removed because it didn’t work and caused N+1 queries — so we added a messages-based stream and merge logic, one fetch per new conversation, and made sure the DB never exposes conversations to realtime.**
