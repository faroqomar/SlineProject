# Observability Report: Realtime Subscription Topology

**Scope:** RealtimeSubscriptionTopology (Plan 18)  
**Plan:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @Observability

---

## 1) What Was Reviewed

- `lib/features/chat/services/message_service.dart` — subscribeToInboxMessages (stream start, handleError, map)
- `lib/features/chat/viewmodels/chat_view_model.dart` — subscribeToUserConversations, _mergeInboxMessages, getConversationById then/catchError

---

## 2) Telemetry Gaps

- **None critical.** Subscription lifecycle and errors are logged.
- **Optional:** No correlation ID across stream event → merge → notify. Acceptable for chat; add only if debugging cross-request flows.

---

## 3) Event Taxonomy (Current)

| Event / Location | Level | What | What NOT logged |
|------------------|--------|------|-------------------|
| subscribeToInboxMessages start | AppLogger.d | receiver_id (userId) | Full user object, email |
| Inbox stream event count | AppLogger.d | list.length | Message content, PII |
| Inbox stream error | AppLogger.w | error, context string | Stack in W (stack in .d as json) |
| Inbox stream parse error | AppLogger.e | error | Message payloads |
| subscribeToUserConversations: no user | AppLogger.d | — | — |
| subscribeToUserConversations: starting | AppLogger.d | — | — |
| Inbox merged | AppLogger.d | conversations.length | Conversation content, names |
| New conversation added | AppLogger.d | merged.id (conversation UUID) | User names, content |
| getConversationById failed | AppLogger.w | conversationId, error | Response body |
| unsubscribeFromUserConversations | AppLogger.d | — | — |
| Realtime inbox subscription onError | AppLogger.e | error | — |

---

## 4) Privacy / What NOT to Log

- **Not logged:** Message content, user names, emails, avatar URLs in these paths. Only IDs (conversation id, receiver_id) and counts.
- **Safe:** conversationId and merged.id are UUIDs; no PII. userId/receiver_id in logs is UUID; acceptable for ops; ensure no logging of tokens or secrets (none found).

---

## 5) Correlation Strategy

- No explicit correlation ID. Logs are scoped by tag/prefix: `[REALTIME]` for inbox stream. For incident investigation, filter by time window and `[REALTIME]` or `subscribeToInboxMessages` / `Inbox merged`. Sufficient for current scope.

---

## 6) Recommendations

- **None mandatory.** Observability meets plan (AppLogger only, no print; stream errors and merge/fetch failures logged).
- **Optional:** Add a single debug log with a correlation id (e.g. one per subscribeToUserConversations call) if multi-user debugging becomes common.

**Verdict:** Observability adequate. No blocker.
