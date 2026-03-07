# 00_HOLISTIC_REPORT: Realtime Subscription Topology

**Skills Applied**:

1. **Evidence-First Reading**: Verifying streams vs DB publication.
2. **Threat Modeling (Security)**: Preventing DB unauthenticated/unfiltered broadcast scale issues.
3. **Idempotency & Concurrency**: Handling N+1 queries during rapid stream ingestion.
4. **Observability**: Creating tracing structures for WS limits.
5. **RLS & Privilege Boundaries**: Ensuring Postgres filters push events correctly.

_Why these fit:_ Realtime subscriptions bypass the standard HTTP request/response cycle, turning the DB into an event broker. Accurate RLS, tight query mapping, and exact publication filtering are mandatory to prevent silent failures or DB connection exhaustion.
_Skills intentionally not used:_ DB-First Financial Modeling (no financial events are streamed via these sockets).

---

## A) What This Diagram Is

A mapping of the WebSocket pipes (`supabase_realtime` channels) connecting the Postgres database to the users' client apps for instant data delivery of chat messages, conversations, and notifications.

## B) Why It Exists

To orchestrate immediate updates without polling. By tracking exactly which tables are subscribed and with what filters, this topology defines the connection footprint of a connected client, dictating how many events the backend must push and how often the client fetches relations.

## C) Where It Lives in the Product

- **App Entry Points:** `NotificationService` (App root), `MessageService` (Inbox and Chat screens).
- **Service Layer:** `lib/features/chat/services/message_service.dart`, `lib/features/notifications/services/notification_service.dart`.
- **DB Touchpoints:** `supabase_realtime` publication, Postgres WAL, RLS policies (`messages_select`, `notifications_select_own`, `conversations_select`).

---

## D) Current Diagram Evaluation

- **What’s good:** Captures the three streams the Dart code _attempts_ to subscribe to.
- **What’s missing:** Doesn't map the N+1 relationship query triggered inside the conversations stream `asyncMap`.
- **What’s ambiguous:** Claims `conversations` is working via Realtime.
- **What’s unsafe:** It hallucinates that `conversations` is actually published to `supabase_realtime` (it is NOT in `SUPABASE_SETUP.md`). It also misses the devastating N+1 query bomb inside the code handling that stream.
- **Score NOW:** **3/10** (Dangerously inaccurate. Reassures developers about a feature that is silently failing in production, hiding a massive N+1 scaling risk).

---

## E) Extracted Invariants & Contracts

1. **Publication Contract**: `stream()` calls MUST match a table listed in `alter publication supabase_realtime add table ...;`. (FAILED for `conversations`).
2. **Owner Isolation Contract**: Broad `.stream()` subscriptions must only process payloads relevant to the user, either enforced by DB Wal2Json filters (`.eq('user_id', ...)`) or strict RLS.
3. **Relation Hydration Constraint (N+1 Prevention)**: Stream `asyncMap` transformers MUST NOT execute unbounded `.select()` calls equal to the size of the _entire_ list of rows on every single insert event.

---

## F) Failure Modes & Attack Scenarios

**1. The Silent Fallback (Current State)**

- _What happens now_: The `conversations` stream connects and receives nothing. The Inbox requires a pull-to-refresh to see new chats.
- _What should happen_: The app should listen to `messages` inserts to infer conversation status changes, or explicitly track conversation metadata changes.
- _Missing Guardrails_: No integration test checks if a new message dynamically updates the recipient's Inbox without reloading.

**2. The CPU Starvation attack (If conversations was published)**

- _What happens now_: If published, the backend broadcasts _every_ conversation change to _every_ client to evaluate via RLS.
- _What should happen_: DB channels should bind explicitly to row equivalence or the client should subscribe to a narrowed channel.
- _Missing Guardrails_: The `message_service.dart` code does not use `.eq` or `.or` filters on the `conversations` stream (Supabase `.stream()` doesn't support `.or()`).

**3. The Stream N+1 Bomb**

- _What happens now_: If the conversations stream worked, a user with 100 chats gets a message. The `conversations` stream yields 100 rows. Dart code calls `await supabase.from('conversations').select(...).in_('id', 100_ids)`.
- _What should happen_: The realtime payload should be merged into local state, or only the affected `id` should be re-fetched.

---

## G) Production-Grade Improvement Plan (Step-by-step)

### Phase 0: Observability & Validation

- **Change:** Add `AppLogger.w` warnings if a stream connects but receives a timeout or protocol error.
- **Why:** To detect when a requested table is not in the publication.

### Phase 1: Core Contracts (Fixing the Silent Failure & N+1)

- **Change:** REMOVE the `.stream()` listener targeting `conversations` from `message_service.dart`.
- **Change:** Build a unified `InboxViewModel` that listens to `.stream()` on `messages` where `receiver_id=userId`. When a message arrives, the ViewModel merges it into the local conversation array and bumps the `last_message_at` sorting order.
- **Why:** Supabase realtime doesn't efficiently support OR clauses on `stream()`. Subscribing to `messages` where `receiver_id` or `sender_id` equals the user is more precise and requires 0 extra DB lookups.

### Phase 2: Hardening

- **Change:** Ensure `messages` payload includes sufficient denormalized data (or that the Inbox caches profiles) so fetching relations on new messages is O(1).
- **Why:** Eliminates the need to hit REST every time a WS event arrives.

### Phase 3: DB Finalization

- **Change:** Leave `conversations` OUT of `supabase_realtime` to save WAL processing CPU.

---

## H) Best Diagram Recommendation

- **Type:** **Component / Data Flow Diagram (DFD)**.
- **Why:** Realtime topologies are best modeled as Publish-Subscribe graphs. State changes in the DB (Postgres WAL) flow into the Supabase Realtime Elixir engine, which routes multiplexed channels to Client ViewModels.
- **Required diagrams:** Channel Topology (shows exact filters), and Client State Merge Flow (shows how WS payloads hydrate the ViewModel without triggering REST N+1s).

---

## I) Final Improved Diagram (Mermaid)

```mermaid
graph TD
    subgraph Supabase [Supabase Backend]
        DB[(PostgreSQL WAL)]
        PUB[Publication: supabase_realtime]
        RT_ENG[Elixir Realtime Engine]
        RLS{Row Level Security}

        DB -- "WAL writes" --> PUB
        PUB -- "messages, notifications" --> RT_ENG
    end

    subgraph Client [Client App ViewModels]
        VM_NOTIF[NotificationViewModel]
        VM_CHAT[ChatScreenViewModel]
        VM_INBOX[InboxViewModel]
    end

    %% Notification Stream
    RT_ENG -- "Topic: realtime:public:notifications\nFilter: `user_id=eq.{auth.uid}`" --> RLS
    RLS -- "Yields 1 row" --> VM_NOTIF

    %% Active Chat Stream
    RT_ENG -- "Topic: realtime:public:messages\nFilter: `conversation_id=eq.{id}`" --> RLS
    RLS -- "Yields 1 row" --> VM_CHAT

    %% Inbox Proxy Stream (Replaces broken conversations stream)
    RT_ENG -- "Topic: realtime:public:messages\nFilter: `receiver_id=eq.{auth.uid}`" --> RLS
    RLS -- "Triggers inbox resort" --> VM_INBOX

    %% N+1 Danger Zone Note
    classDef danger fill:#ffcccc,stroke:#ff0000,stroke-width:2px;
    class VM_INBOX danger

    note_N1>WARNING: Do NOT run .asyncMap() with \nREST bulk queries inside Stream handlers] -.-> VM_INBOX
```

---

## J) Risk Register

### J1) Risks if we keep the current system

| Risk                        | Severity | Impact                                                    | Evidence                                                                     |
| --------------------------- | -------- | --------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Silent Inbox Stagnation** | HIGH     | Users miss messages unless they reopen the app.           | `conversations` not in `supabase_realtime` publication (`SUPABASE_SETUP.md`) |
| **N+1 Stream Fetching**     | CRITICAL | Out of Memory / DB Connection Exhaustion on active users. | `message_service.dart:352`                                                   |

### J2) Risks introduced by improvements

| Risk                             | Severity | Mitigations                                                                                                                                                              |
| -------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Messages stream multiplexing** | LOW      | Relying on `receiver_id=eq.uid` or `sender_id=eq.uid` for the Inbox view means managing 2 channel filters. Mitigation: Use standard `channel()` builder in Supabase SDK. |

---

## K) Verification Checklist (Production Readiness)

- [ ] **DB Verify:** `SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';` only lists `messages`, `notifications`.
- [ ] **Code Verify:** Remove `subscribeToConversations()` from `message_service.dart`.
- [ ] **UI Verify:** InboxViewModel uses `subscribeToMessages(receiver_id=uid)` to detect new inbound chats and updates UI locally.
- [ ] **Performance Verify:** Send 10 messages rapidly. Verify Postgres `pg_stat_statements` shows 0 scaling `SELECT` queries triggered by the client stream handler.

---

## L) Final Verdict

- **Score AFTER fixes:** **9/10**
- **Blockers to production:** The Dart code (`message_service.dart:340`) must be explicitly refactored. The diagram is now correct, but the codebase has an explicit bug based on the previous bad diagram flow.
- **Ship criteria:** Once `subscribeToConversations` is removed and Inbox realtime relies either on polling or `messages` events, the component is safe to ship.
