# Gaps and Fixes: 08_chat-realtime-sync

## Identified Gaps

### 1. Presence Hallucination

- **Gap**: The current diagram claims presence is "Implemented" and "Verified". However, `lib/features/chat/view/widgets/conversation_list_tile.dart:40` contains a `TODO` stating presence is not in the model.
- **Evidence**: `isOnline` is hardcoded to `false` in the UI. `MessageService` lacks presence UPSERT/subscription logic.
- **Fix**: Implement a dedicated `PresenceService` or extend `MessageService` to handle `conversation_presence` table. Add `isOnline` and `isTyping` to `Conversation` and `Message` models.

### 2. Delivery & Seen Receipts Synchronization

- **Gap**: While the DB has `delivered_at` and `seen_at`, and the service has RPCs to set them, the diagram doesn't show how these updates propagate back to the sender.
- **Evidence**: `message_service.dart:303` subscribes to the `messages` stream, which _should_ pick up updates, but the diagram only shows the initial `INSERT`.
- **Fix**: Explicitly include the "Update Payload" flow in the diagram for receipts.

### 3. Performance Bottleneck in Conversation Stream

- **Gap**: `subscribeToConversations` performs a full re-fetch of relationships on every stream event.
- **Evidence**: `message_service.dart:351` uses `asyncMap` to perform a `select` with multiple joins whenever the stream emits.
- **Fix**: Move to a client-side merge strategy (similar to `ChatRealtimeMerger` but for conversations) or optimize the query to only fetch changes.

### 4. Connection Lifecycle & Resilience

- **Gap**: No mention of socket lifecycle (connect/disconnect/error) in the diagram or code.
- **Evidence**: `message_service.dart` just returns the stream; it doesn't handle connection state.
- **Fix**: Add a "Connection Manager" actors/process to the diagram to show how the app handles offline-to-online transitions (re-sync).

### 5. Security Guardrails

- **Gap**: The "Favorites required for DM" rule is a critical business invariant but missing from the topological diagram.
- **Evidence**: `SUPABASE_SETUP.md:83`.
- **Fix**: Add RLS and Trigger check blocks to the diagram to show how unauthorized chat initiation is blocked.

## Proposed Redesign Highlights

- **Hybrid Sync**: Standard Realtime for messages + Presence for volatile states.
- **Explicit Receipts**: Showing the dual-tick cycle in the sequence.
- **Resilient Sockets**: Connection state handling in the flow.
- **Optimized Presence**: 15s TTL in DB + client-side heartbeat.
