# Observability Report: Chat Realtime Sync (08_chat-realtime-sync)

**Date:** 2026-03-08  
**Scope:** Chat feature — presence, receipts, realtime stream, merge.  
**Plan:** `.TODO/PLAN_ChatRealtimeSync_2026-03-07_PlanCritic.md`  
**Execution:** `.TODO/EXECUTION_LOG_ChatRealtimeSync_2026-03-07.md`  
**Deliverable:** Report only — no code edits.

---

## 1) Files Scanned and Log Points Found

### 1.1 Files Scanned

| File | Role | AppLogger present |
|------|------|--------------------|
| `lib/features/chat/services/message_service.dart` | Service (presence, receipts, streams) | Yes |
| `lib/features/chat/viewmodels/chat_view_model.dart` | ViewModel (merge, presence, receipts, teardown) | Yes |
| `lib/features/chat/data/chat_repository.dart` | Repository (pass-through) | No |
| `lib/features/chat/models/conversation_model.dart` | Model (fromJson) | Yes |
| `lib/features/chat/models/message_model.dart` | Model (fromJson error) | Yes |
| `lib/features/chat/services/chat_realtime_merger.dart` | Merger (dedupe/sort) | No |
| `lib/features/chat/view/chat_screen.dart` | View | Yes |
| `lib/features/chat/view/messages_screen.dart` | View | Yes |
| `lib/features/chat/attachments/services/send_attachment_usecase.dart` | Use case | Yes (out of scope for realtime sync) |
| `lib/features/chat/view/widgets/chat_context_widget.dart` | View widget | Yes (error only) |
| `lib/core/services/logger_service.dart` | Logger (reference) | N/A |

### 1.2 Log Points by File (Evidence)

**message_service.dart**

| Line(s) | Level | Tag | Message / context |
|---------|--------|-----|-------------------|
| 46 | d | (none) | Feature flag enable_direct_conversation_rpc |
| 49 | w | (none) | Failed to check feature flag |
| 74 | d | Chat | feature flag chat_presence_receipts_enabled |
| 77 | w | Chat | Failed to check chat_presence_receipts_enabled |
| 90 | d | Chat | presence upsert throttled conversationId= |
| 104 | d | Chat | presence_upsert conversationId= isTyping= |
| 106 | e | Chat | presence upsert failed (error, stackTrace) |
| 113 | d | Chat | presence subscription start conversationId= |
| 119 | e | Chat | presence stream error (error, stackTrace) |
| 138, 147, 152, 155, 161, 168, 175 | d/e | (none) | createOrGet path / RPC / timeout |
| 201, 204, 207, 211 | i/e | (none) | start_direct_conversation_v1 |
| 234, 238, 260 | d/i | (none) | DM conversation lookup / create |
| 268, 274, 276 | i/e | (none) | [ARCHIVE] conversationId |
| 309, 332, 382, 386 | d/w/e | (none) | [CONVOS] fetch / count / error |
| 393, 421 | d | (none) | [MESSAGES] fetch / Sending message (convo, type) |
| 448, 451 | i/e | (none) | Sent message / Failed to send (convo, error) |
| 467 | d | (none) | [RECEIPTS] delivered marked for convo= |
| 477 | d | (none) | [RECEIPTS] seen marked for convo= |
| 482–495 | e | (none) | Realtime messages stream error / parse error |
| 520, 527, 531, 540, 543 | d/w/e | (none) | [REALTIME] inbox subscription start/error/count/parse |

**chat_view_model.dart**

| Line(s) | Level | Tag | Message / context |
|---------|--------|-----|-------------------|
| 101 | i | ChatVM | chat_teardown_role_switch |
| 115 | d | ChatVM | chat_removed_all_supabase_channels |
| 117 | w | ChatVM | chat_remove_channels_warning |
| 136 | i | ChatVM | chat_teardown_complete |
| 161 | e | (none) | Error marking receipts |
| 176, 178 | i/e | (none) | Conversations fetched / Error fetching |
| 188, 192 | d | (none) | subscribeToUserConversations no user / starting inbox |
| 206, 209, 213 | d/e | (none) | Inbox merged count / Error merging / subscription error |
| 247 | d | (none) | New conversation added from inbox message |
| 252 | w | (none) | getConversationById failed (conversationId) |
| 261 | d | (none) | unsubscribeFromUserConversations |
| 272, 286, 291 | d/i/e | (none) | createOrGetConversation double-tap / success / error |
| 356, 366, 368 | e/i/e | (none) | Task conversation / delete convo |
| 386 | e | (none) | Error fetching messages |
| 428, 467, 486, 504 | e | (none) | Error sending / create offer / accept / reject |
| 559 | w | ChatVM | Failed to refresh offer statuses |
| 585 | d | ChatVM | [CHAT] messages merged count= |
| 589 | e | ChatVM | [CHAT] stream_error messages subscription |
| 610 | d | ChatVM | [CHAT] presence_updated otherTyping= |
| 625 | e | ChatVM | [CHAT] presence stream error |
| 659 | w | ChatVM | [CHAT] setTyping failed |

**conversation_model.dart**

| Line(s) | Level | Tag | Message / context |
|---------|--------|-----|-------------------|
| 94 | d | (none) | last_message raw: $rawLastMessage |
| 113 | d | (none) | Parsed other user: name \| avatar |

**message_model.dart**

| Line(s) | Level | Tag | Message / context |
|---------|--------|-----|-------------------|
| 174–178 | e | Chat | Failed to parse Message (error, stackTrace) |

**chat_screen.dart**

| Line(s) | Level | Tag | Message / context |
|---------|--------|-----|-------------------|
| 56 | i | (none) | [CHAT] opened: convo= |
| 66 | d | (none) | [CHAT] closed: convo= |
| 77 | i | (none) | [CHAT] image sent via usecase convo= |
| 81 | e | (none) | sendImageAttachment failed |

**messages_screen.dart**

| Line(s) | Level | Tag | Message / context |
|---------|--------|-----|-------------------|
| 260 | i | (none) | [CONVOS] open: convo.id |

**chat_realtime_merger.dart**

- No AppLogger calls. Unparseable rows are skipped without logging (comment: "do not log raw content").

---

## 2) Telemetry Gaps

### 2.1 Missing or Inconsistent Events

- **Stable event names:** Logs use ad-hoc messages (`[CHAT] presence_upsert`, `[RECEIPTS] delivered marked`, etc.) rather than a single event-name field. No `event_name` (e.g. `chat_presence_upsert`, `chat_mark_delivered`) in a consistent field.
- **mark_delivered / mark_seen on failure:** MessageService does not log on RPC failure (no try/catch). Only ViewModel logs "Error marking receipts: $e" — no `conversation_id` or `operation` (delivered vs seen) in that log.
- **Correlation:** No `correlation_id` is propagated for multi-step flows (e.g. open chat → subscribe → mark receipts → presence updates). Only `conversation_id` (and sometimes `receiver_id`/count) appear where present.
- **Merger:** No log when merge runs (e.g. count before/after) except in ViewModel (`messages merged count=`). No log for merge input failure (merger intentionally does not log raw content).
- **Stream lifecycle:** No explicit "subscription ended" (e.g. unsubscribe) for messages stream; only for inbox ("inbox stream cancelled") and presence (cancel only, no log). Reconnect/retry is not logged as a distinct event.

### 2.2 Tag Usage

- **Chat:** Used in MessageService for presence/feature-flag and in message_model for parse error.
- **ChatVM:** Used in ViewModel for teardown, merge, presence, setTyping, stream_error, offer refresh.
- Inconsistent: many chat-related logs have no tag (e.g. receipts, conversations fetch, send message, inbox).

### 2.3 PII / Sensitive Data in Logs

| Location | Risk | Detail |
|----------|------|--------|
| conversation_model.dart:94 | **High** | `rawLastMessage` can include message `content` (chat body). Debug log in fromJson. |
| conversation_model.dart:113 | **Medium** | `other_user_name` (full name) and `other_user_avatar` (URL) — identifiable. |
| chat_view_model.dart:161 | Low | "Error marking receipts: $e" — exception message could theoretically contain server text; usually safe. |
| message_service.dart | Low | conversationId, message id, userId (uuid), isTyping, type — no message content. |
| chat_view_model.dart | Low | conversation ids, counts, otherTyping bool — no content. |

No logging of: message body, attachment content, or tokens. Logger_service masks access_token/refresh_token in JSON.

---

## 3) What to Log vs What NOT to Log

### 3.1 Presence

| Do log | Do not log |
|--------|------------|
| presence_upsert: conversation_id, user_id (uuid), is_typing, throttled (bool) | Raw presence row payload (may contain timestamps only; low risk but keep minimal) |
| presence subscription start/end for conversation_id | Other user’s identity beyond “other user typing” boolean |
| presence stream error (sanitized error, no stack in prod if noisy) | — |
| presence_updated: conversation_id, other_typing (bool) | — |

### 3.2 Receipts

| Do log | Do not log |
|--------|------------|
| mark_delivered / mark_seen: conversation_id, success | Message ids or message content |
| Receipt failure: conversation_id, operation (delivered|seen), error_code / sanitized message | Full exception message if it could contain DB/user data |

### 3.3 Realtime Stream

| Do log | Do not log |
|--------|------------|
| subscription start: conversation_id (messages) or receiver_id (inbox) | Full message rows or content |
| stream_error: conversation_id or “inbox”, error type/sanitized message | Stack traces in high-volume paths (optional in prod) |
| messages merged: conversation_id, count (before/after or final count) | Message ids in hot path (optional; allow for debug level only) |
| inbox: event count or conversation count updated | Message content or attachment URLs |

### 3.4 Merge (ChatRealtimeMerger)

| Do log | Do not log |
|--------|------------|
| Optional: merge applied, conversation_id, count_in, count_out (debug) | Raw rows or message content |
| Parse failure: optional count of skipped rows (no payload) | Any part of unparseable row |

### 3.5 Errors (General)

| Do log | Do not log |
|--------|------------|
| feature, operation, entity_id (conversation_id / message_id if needed), error_code, user-safe message | Full stack in every error (use level/context); tokens; PII; message body |

---

## 4) Event Taxonomy for Chat (Stable Naming)

Recommended **event_name** values (snake_case, stable):

| event_name | When | Suggested level |
|------------|------|------------------|
| chat_presence_upsert | After successful upsert (or throttled skip) | debug |
| chat_presence_upsert_failed | Presence upsert throw | error |
| chat_presence_subscription_start | subscribeToPresence(conversationId) | debug |
| chat_presence_subscription_error | Presence stream onError | error |
| chat_presence_updated | ViewModel received presence row(s), otherTyping resolved | debug |
| chat_mark_delivered | RPC mark_conversation_delivered success | debug |
| chat_mark_seen | RPC mark_conversation_seen success | debug |
| chat_mark_receipts_failed | markReceiptsForActive catch | error |
| chat_messages_subscription_start | subscribeToMessages(conversationId) | debug |
| chat_messages_subscription_error | Messages stream onError | error |
| chat_messages_merged | After ChatRealtimeMerger.merge, new count | debug |
| chat_inbox_subscription_start | subscribeToInboxMessages(userId) | debug |
| chat_inbox_subscription_error | Inbox stream onError | error |
| chat_inbox_merged | Inbox messages merged into conversation list | debug |
| chat_conversation_opened | Chat screen opened for conversation | info |
| chat_conversation_closed | Chat screen disposed / unsubscribe | debug |
| chat_feature_flag_presence_receipts | After reading chat_presence_receipts_enabled | debug |
| chat_set_typing_failed | setTyping throw | warn |
| chat_teardown_role_switch | RoleSwitchAware teardown | info |
| chat_teardown_complete | After teardown | info |

Not in plan but already present: conversation create/fetch, send message, archive, fetch conversations — can be aligned to same taxonomy (e.g. chat_conversation_created, chat_message_sent, chat_conversation_archived) in a later pass.

---

## 5) Correlation Strategy

- **Primary key:** `conversation_id` for all chat events for a given conversation (presence, messages stream, receipts, merge).
- **Secondary:** `user_id` (current user uuid) for inbox and presence; no need to log other user id for presence beyond “other typing” boolean.
- **No correlation_id today:** Multi-step flows (open → subscribe → mark receipts → presence) are not tied by a single request/correlation id. Recommendation: for incident tracing, introduce an optional `correlation_id` (e.g. per “open chat” or per session) in a follow-up; minimum is consistent `conversation_id` + `feature: chat`.
- **Do not log:** message body, attachment content, raw payloads, full names, avatar URLs (or redact to last 2–4 chars if ever needed for support).

---

## 6) Privacy-Safe Logging Plan

1. **Remove or redact PII in existing logs**
   - conversation_model: Remove or gate debug log that logs `rawLastMessage` (may contain content). Remove or redact log that logs `other_user_name` and `other_user_avatar` (e.g. log only “other_user present” or hash).
2. **Structured fields**
   - Add consistent fields: `event_name`, `conversation_id` (when applicable), `feature: chat`, `severity`. Avoid free-text that might contain user data.
3. **Error messages**
   - Log sanitized error (code or type + short message); avoid logging full exception message if it can contain DB or user data. Keep stack for error level in debug builds only if desired.
4. **Receipt failure**
   - Add conversation_id and operation (delivered|seen) to “Error marking receipts” so incidents are traceable without adding PII.
5. **Merger**
   - Keep “do not log raw content” policy. Optionally add a single debug log: “merge applied, count=N” with no payload.

---

## 7) Summary

- **Coverage:** Presence, receipts, and realtime (messages + inbox) are partially instrumented in MessageService and ChatViewModel with ad-hoc messages and tags (Chat, ChatVM). Merger has no logs (by design for privacy).
- **Gaps:** No stable event_name field; no correlation_id; receipt failure missing conversation_id/operation; two PII risks in conversation_model (last_message raw, other_user name/avatar).
- **Recommendations:** (1) Adopt the event taxonomy above and add `event_name` (+ conversation_id, feature) to new or updated logs. (2) Remove or redact PII in conversation_model logs. (3) Add conversation_id (and operation) to receipt failure log. (4) Optionally add correlation_id in a later observability pass for multi-step flows.

---

**End of report.**
