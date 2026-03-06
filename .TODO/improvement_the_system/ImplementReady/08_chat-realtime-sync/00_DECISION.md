# Decision: 08_chat-realtime-sync (Old vs New)

## Final Verdict

**NEW is better: YES**

The NEW diagram explicitly models connection resilience, explicit delivery/read receipt lifecycles (which are physically implemented in the Dart RPC calls but ignored in the OLD diagram), and forces the security discussion by naming triggers that _must_ exist for safe operations. The OLD diagram is a dangerous simplification over-trusting client-side `INSERT`s.

## 10 Concrete Differences

1. **Connection State**: NEW models the explicit WebSocket connection establishment phase; OLD skips it.
2. **Structural Grouping**: NEW splits the diagram into three concrete domains (Presence, Messages, Receipts); OLD clumps them linearly.
3. **Trigger Specificity**: NEW removes the ambiguous `Process Triggers` box and names specific security guards (`validate_sender_participation`, `notifications_upsert`).
4. **Delivery Receipts**: NEW models the `mark_delivered` RPC loop and subsequent row broadcast; OLD omits it entirely.
5. **Read Receipts**: NEW models the `mark_seen` RPC loop for read-receipts; OLD omits it.
6. **Presence Payload**: NEW details the actual attributes pushed for presence (`isTyping: true`).
7. **Timeout Enforcement**: NEW models the 15s inactivity DB-side timeout (`expire_typing_presence`); OLD relies purely on the client sending a "stop" event.
8. **Deduplication**: NEW mandates client-side "Dedupe by ID" (which matches `ChatRealtimeMerger`); OLD implies raw append.
9. **UI Corollaries**: NEW maps network events to exact UI states (Single Tick, Double Grey, Double Blue).
10. **Lifecycle Separation**: NEW decouples the presence heartbeat from the permanent message append log.

## Scores Table

| Category               | OLD Score (0-10) | NEW Score (0-10) | Notes                                                                                       |
| :--------------------- | :--------------- | :--------------- | :------------------------------------------------------------------------------------------ |
| **Security isolation** | 2                | 8                | OLD assumes DB is safe. NEW explicitly models the triggers required to block spoofing.      |
| **Correctness**        | 3                | 9                | NEW handles the exact receipt cycle and deduplication needed for correct WhatsApp-style UX. |
| **Resilience**         | 1                | 7                | NEW adds timeouts to clean up stale state if connections drop.                              |
| **Performance**        | 5                | 5                | Both diagrams leave the `subscribeToConversations` N+1 unaddressed at the macro level.      |
| **Observability**      | 2                | 6                | NEW tracks the lifecycle of messages much more clearly.                                     |

## Critical Blockers for Production

The audit revealed severe, critical blockers. The NEW diagram models a safe system, but the **underlying codebase and database completely lack the assumed security mechanisms**.

1. **Missing RLS**: No Row-Level Security exists for `messages` or `conversation_presence` in the source of truth (`supabase/migrations`).
2. **Missing Triggers**: `expire_typing_presence` and `validate_sender_participation` do not exist.
3. **Presence Hallucination**: `conversation_presence` table doesn't even exist in the migrations, and the UI has a hardcoded `TODO`.
4. **N+1 Stream Load**: The Dart service executes an N+1 query loop inside the `subscribeToConversations` stream listener.

A minimal patch plan is REQUIRED before shipping.
