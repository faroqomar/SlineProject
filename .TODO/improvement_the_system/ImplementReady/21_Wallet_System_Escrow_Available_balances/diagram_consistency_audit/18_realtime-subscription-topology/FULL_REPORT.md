# FULL REPORT: 18 Realtime Subscription Topology

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, Threat Modeling (Security), Idempotency & Concurrency, Observability, RLS & Privilege Boundaries.
- **Why these fit**: Realtime streams bypass REST. If misconfigured, they flood the Flutter client, causing N+1 query storms that exhaust connections and crash the app. Tight RLS ensures users only see their own streams.
- **Skills not used**: Repo Mapping.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/18_realtime-subscription-topology`
- **What system/feature it describes**: The WebSocket pipelines routing DB INSERTS/UPDATES directly into Client ViewModels for Chat and Notifications.
- **Entities involved**: `supabase_realtime` publication, `messages`, `notifications`, `MessageService` streams.

## 2) Human Explanation

Instead of the app asking "Are there new messages?" every 5 seconds, Supabase watches the database WAL (Write-Ahead Log) for changes to `messages` and `notifications`. It routes these changes via WebSockets to any connected phone listening to that table. Crucially, the app must filter the stream (e.g., `receiver_id=eq.[my_uid]`) so it doesn't receive the entire platform's traffic, and Postgres RLS verifies the user is allowed to see those rows anyway.

## 3) Symbol Legend

- **Rectangles**: Client ViewModels vs Supabase Realtime Engine.
- **Solid Arrows**: DB WAL pushing into the publication.
- **Dashed Arrows**: Multiplexed WebSocket topics flowing into the app.

## 4) Extracted Contracts & Invariants

1. **Publication Contract**: A table MUST be in `alter publication supabase_realtime add table...` to trigger sockets.
2. **Owner Isolation Contract**: Subscriptions MUST use exact DB filters (`.eq()`) reflecting ownership to prevent bandwidth saturation.
3. **N+1 Prevention Constraint**: Stream handlers MUST NOT execute `.select()` fetching relations blindly for every insert event they receive.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Diagram assumed `conversations` was in the realtime publication. Codebase lacked it.
- **Resolution**: Do NOT add `conversations` to realtime. It wastes WAL CPU. Proxy conversation updates via `messages` events.

### 5.2 Logic Drift

- **Conflict**: The `message_service.dart` attempted `.stream()` on `conversations` yielding silent failures.
- **Resolution**: Delete that stream block. Route Inbox updates by listening to `.stream()` on `messages` where `receiver_id` equals the user.

### 5.3 Data Model Drift

- **Conflict**: Massive N+1 logic inside stream handlers where the app would go fetch the relations for 100 chats anytime an event hit.
- **Resolution**: Denormalize necessary payloads into the inserted row or cache relations locally so the event is processed in O(1) time without REST calls.

## 6) Security & Failure Modes (Adversarial)

- **CPU Starvation**: A malicious user connects 10,000 WebSockets listening to generic events.
  - _Mitigation_: Supabase limits concurrent connections. Strict RLS ensures the DB discards the payloads early for unauthorized channels.
- **Silent Inbox Stagnation**: User misses incoming messages because the `conversations` stream was broken.
  - _Mitigation_: Switch to the `messages` stream which is verified active in `supabase_realtime`.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Inbox (List of chats), Chat Thread (Inside a chat), Notification Center.
- **States**: Real-time bubbling of unread counts and message ordering.
- **Guardrails**: WebSocket reconnect logic if the OS kills the background connection.

### 7.2 Admin Dashboard UI

- **Pages**: Unused for general realtime logic.

### 7.3 Implementation Hooks

- `MessageService.subscribeToMessages(receiver_id=uid)`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10 (Post-fixes)
- **Best Diagram Type**: Component / Data Flow Diagram (DFD) defining exact filter strings (`channel:messages:receiver_id=eq.uid`).

## 9) Upgrade Plan

- **Phase 0: Observability**: Log warnings if a `.stream()` connects but times out yielding data.
- **Phase 1: Contracts**: Completely yank `subscribeToConversations()` from Dart.
- **Phase 2: Hardening**: Refactor `InboxViewModel` to consume `messages` realtime events and locally re-sort the conversation array.
- **Phase 3: Scale**: Ensure `pg_stat_statements` reads 0 SELECTs triggered when a user receives 10 rapid messages.

## 10) Risks

### 10.1 Risks if current version kept

- **CRITICAL**: The N+1 stream fetching would exhaust Flutter App memory and DB connection pools simultaneously.

### 10.2 Risks introduced by fixes

- **Client Processing Overhead**: Relying on the app to merge `messages` into a `conversations` array pushes logic to Flutter. _Mitigation_: Simple array manipulation is exceptionally fast in Dart.

## 11) Test Plan (High-value)

- **Performance**: Open app. Send 5 messages quickly. Assert Network tab shows 0 REST `SELECT` calls made by the client handling the events.
- **Integration**: Send message to User A. Assert User A's Inbox UI resorts the chat to the top instantly without pull-to-refresh.

## 12) Production Checklist

- [ ] `conversations` streams removed from Dart.
- [ ] `supabase_realtime` publication confirmed to only map `messages` & `notifications`.
- [ ] RLS policies validated.
