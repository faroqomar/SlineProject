# CodeGuard Review: Realtime Subscription Topology

**Scope:** RealtimeSubscriptionTopology (Plan 18)  
**Plan:** `.TODO/PLAN_RealtimeSubscriptionTopology_2026-03-07.md`  
**Date:** 2026-03-07  
**Agent:** @CodeGuard  
**Review mode:** STANDARD (business logic, services, state, realtime)

---

## 1) Risk Rating

- **Overall:** MEDIUM (realtime + state; no wallet/payment)
- **Security:** LOW (RLS unchanged; filter by receiver_id; messages_select enforced)
- **Performance:** LOW (N+1 removed; single stream; guarded single fetch per new convo)
- **Compatibility:** LOW (app-only; no schema break)

---

## 2) Findings

### 2.1 Security ✅

- No direct Supabase in View. Repository/Service only.
- Stream filter `.eq('receiver_id', userId)` narrows at client; RLS messages_select enforces conversation participation. No new bypass.
- No secrets or PII in logs (UUIDs and counts only).
- Migration only drops conversations from publication if present; no new tables or RLS change.

### 2.2 Performance ✅

- No N+1: no asyncMap/select in subscribeToInboxMessages. Merge is in-memory; getConversationById is one call per new conversation_id with guard.
- _inboxMsgSub cancelled on re-subscribe and in dispose; no duplicate listeners.
- copyWith creates new instances; list sort and single _notify() per batch; no rebuild storm observed.

### 2.3 Correctness

- **Conversation.copyWith:** Now preserves otherUserTyping and presenceUpdatedAt (per Architect fix). Typing indicator no longer lost on Inbox merge.
- **New-conversation race:** Two messages for same new conversation in quick succession could both pass _fetchingConversationIds check before either then() runs. Result: two getConversationById calls; second add is no-op (conversations.any). Acceptable; no duplicate UI entries.

### 2.4 Compatibility

- No breaking API change. subscribeToUserConversations() signature unchanged; callers unchanged.
- getConversationById already existed in service; repository now exposes it. No caller break.

### 2.5 Verification Commands

```bash
flutter analyze lib/features/chat/
# Expect: No issues found.

# Invariant: no conversations stream
rg "conversations.*stream|\.from\('conversations'\)\.stream" lib/
# Expect: no matches
```

---

## 3) Blockers

- **None.**

---

## 4) Freshness

- No new dependencies. supabase_flutter usage (stream, eq, order) matches existing patterns. No web search required for this scope.

---

## 5) Decision

**APPROVED ✅**

- MVVM respected, N+1 removed, observability in place, docs aligned.
- One fix applied during review (copyWith preserves typing fields). No remaining blocker.
