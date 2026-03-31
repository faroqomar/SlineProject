# Audit Notes: Chat Creation Matrix

## 1) Skill Selection Protocol

- **Skills selected**:
  - **Evidence-First Reading**: To link the "matrix" logic to actual RPCs and triggers.
  - **Threat Modeling (Security)**: Essential to verify the anti-spam/anti-abuse claims.
  - **Invariants & Contracts**: To define the rigid rules for "Direct vs Task" DMs.
  - **Diagram Crafting (Mermaid)**: To rebuild the matrix into a production-hardened version.
  - **RLS & Privilege Boundaries**: To audit the `conversations_insert_client_only` policy.
- **Why these skills fit**: This diagram is purely about access control and decision boundaries. Security and Evidence are the primary tools to validate it.
- **Skills intentionally not used**:
  - **DB-First Financial Modeling**: No money/escrow involved in _creation_ of chat (happens later in offers).
  - **Production Migration Planning**: This is a logic audit, not a schema migration (though it may suggest one).

## 2) Evidence Summary

- **Code Reference**: `lib/features/chat/services/message_service.dart:16-86` (`createOrGetConversation`).
- **DB Reference**: `conversations` table; `conversations_before_insert_guard` trigger (confirmed in `SUPABASE_SETUP.md:1182` and `Archive/20260305071000...sql`).
- **RPC Reference**: `start_task_conversation_v1` (`SUPABASE_SETUP.md:1385`).
- **Rules Reference**: `SUPABASE_SETUP.md:83-84` (Direct DM requires favorites; Task-linked requires non-owner).

## 3) Preliminary Analysis

- The "Matrix" correctly identifies the two primary entry points: Task Context and Direct DM.
- The "Guard rule" for Freelancers in Direct DM is currently unverified as "Strictly Forbidden" in the SQL I reviewed, but `SUPABASE_SETUP.md` claims it's enforced.
- **Gap discovered**: The `createOrGetConversation` method in `MessageService.dart` handles normalized pairs in Dart, but the DB also has a normalization trigger (`normalize_conversation_users`). This is good redundancy.
- **Risk**: A client can bypass the "Favorites" rule if they know the freelancer's UUID and insert directly via PostgREST, _unless_ the RLS `conversations_insert_client_only` is extremely tight.
