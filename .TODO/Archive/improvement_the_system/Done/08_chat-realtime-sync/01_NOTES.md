# Audit Notes: 08_chat-realtime-sync

## Skill Selection Protocol

- **Skills selected**:
  1. **Evidence-First Reading**: To verify actual implementation in `message_service.dart` and DB.
  2. **Threat Modeling (Security)**: To identify risks like unauthorized message insertion or presence spoofing.
  3. **RLS & Privilege Boundaries**: To ensure strict isolation of chat data between conversations.
  4. **Idempotency & Concurrency**: To address race conditions in message ordering and delivery.
  5. **Observability**: To plan for connection tracking and message status (sent/delivered/read).
  6. **Diagram Crafting (Mermaid)**: To produce a valid, production-grade redesign.

- **Why these skills fit**:
  Realtime chat systems live and die by their security (RLS), reliability (concurrency), and visibility (observability). Evidence-first reading is the foundation of this audit.

- **Skills intentionally not used**:
  - **DB-First Financial Modeling**: This system doesn't involve transactions or ledger logic.
  - **Production Migration Planning**: Aiming for a system design first; migration is secondary to the architectural audit.
  - **State Machine & Lifecycle**: While chat has states, the sync process is more about topology and flow than complex state transitions.

## Initial Observations from 08_chat-realtime-sync.md

1. **Topological Simplification**: The current diagram is very high-level. It assumes "Process Triggers" handles everything but doesn't specify what.
2. **Missing State/Feedback**: No mention of "Delivered" or "Read" receipts in the flow.
3. **Presence Ambiguity**: `UPSERT conversation_presence` is mentioned, but how is stale presence cleaned up?
4. **Security Assumptions**: `INSERT INTO messages` without mentioning RLS or validation triggers is a risk.
5. **Realtime Topology**: Mentions `.stream()` which is heavy for active chat; might need a hybrid of `stream` and `broadcast`.
