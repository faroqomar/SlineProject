# FULL REPORT: 08 Chat Realtime Sync

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Threat Modeling (Security), RLS & Privilege Boundaries, Idempotency & Concurrency, Observability, Diagram Crafting.
- **Why these fit**: Realtime syncing requires absolute correctness in RLS (only seeing your own messages) and high reliability in delivery (handling socket drops, dupe messages). Threat modeling secures presence spoofing.
- **Skills not used**: DB-First Financial Modeling.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/08_chat-realtime-sync`
- **What system/feature it describes**: The WebSocket-driven flow for sending messages, broadcasting them to the receiver, handling typing indicators (presence), and managing read receipts.
- **Entities involved**: `messages`, `conversation_presence`, `MessageService`.

## 2) Human Explanation

A Sender types a message, firing a presence heartbeat to `conversation_presence`. The Sender inserts a message into the DB. Supabase Realtime broadcasts the INSERT to the Receiver. The Receiver's app appends the message, and calls `mark_delivered`. When the Receiver opens the chat, the app calls `mark_seen`. The Sender listens to these updates via streams and updates the UI (single tick -> double grey -> double blue). If a user stops typing, a DB trigger auto-expires their presence state after 15 seconds.

## 3) Symbol Legend

- **Rectangles**: Process/Operation groups (Presence, Secure Message Flow).
- **Solid Arrows**: API calls.
- **Dashed Arrows**: Supabase Realtime Broadcasts.

## 4) Extracted Contracts & Invariants

1. **Isolation Contract**: A user can only see/receive messages for conversations where they are `user1_id` or `user2_id`.
2. **Presence TTL**: `conversation_presence` records MUST expire after 15 seconds to prevent ghost typing markers.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Diagram mentioned presence as "Implemented" but codebase marked it as `TODO`.
- **Resolution**: Must execute implementation in `PresenceService`.

### 5.2 Logic Drift

- **Conflict**: Reliance on client-side time for message ordering.
- **Resolution**: Use `created_at` from the DB explicitly to sort messages.

### 5.3 Data Model Drift

- None detected.

## 6) Security & Failure Modes (Adversarial)

- **Presence Spoofing**: A user sends a heartbeat marking another user's ID as typing.
  - _Mitigation_: RLS on `conversation_presence` enforcing `auth.uid() = user_id`.
- **Duplicate Delivery**: Socket reconnect appends the same message twice.
  - _Mitigation_: `ChatRealtimeMerger` must deduplicate by `id` on the client.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Chat Thread.
- **States**: Typing Indicator, Message Bubbles (Ticks: Sent, Delivered, Read).
- **Guardrails**: Reconnect sequence if socket drops (show "Connecting...").

### 7.2 Admin Dashboard UI

- **Pages**: Not heavily monitored by admins (privacy). System health only.
- **Metrics**: Realtime concurrent connection count.

### 7.3 Implementation Hooks

- `PresenceService.sendHeartbeat()`.
- `MessageService.markDelivered(msgId)`.
- `MessageService.markSeen(convoId)`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: Sequence Diagram (timing of broadcasts and callbacks is strictly sequential).

## 9) Upgrade Plan

- **Phase 0: Observability**: Track Socket drop/reconnect rates.
- **Phase 1: Contracts**: Implement Flutter `PresenceService` and deduplication merge algorithms.
- **Phase 2: Hardening**: Setup the DB Trigger `expire_typing_presence` (15s TTL).
- **Phase 3: Scale**: Move to client-side caching to reduce payload sizes on reconnects.

## 10) Risks

### 10.1 Risks if current version kept

- **Ghost Data**: Stale presence records if clients crash mid-type.

### 10.2 Risks introduced by fixes

- **Socket Overhead**: High volume of presence heartbeats strains DB. _Mitigation_: Supabase ephemeral broadcast channels instead of DB writes if possible.

## 11) Test Plan (High-value)

- **Integration**: Send message, disconnect network, reconnect network -> assert message deduplicates and syncing restores.
- **Security**: Attempt to update presence for a different user UUID -> assert RLS blocks.

## 12) Production Checklist

- [ ] Client-side deduplication functional.
- [ ] 15s TTL presence trigger active in Postgres.
- [ ] RLS policies strictly applied to presence tables.
