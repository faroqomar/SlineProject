# FULL REPORT: 13 Notification Routing

## 0) Skill Selection

- **Skills selected**: Evidence-First Reading, State Machine & Lifecycle, Idempotency & Concurrency, Diagram Crafting.
- **Why these fit**: Notifications bridge the DB state and client UI. Reading evidence ensures we reflect real codebase usage. Concurrency skills evaluate idempotency needed when multiple node workers or edge functions push the same notification.
- **Skills not used**: DB-First Financial Modeling.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/ImplementReady/13_notification-routing`
- **What system/feature it describes**: How backend events (like a new message or booking) are routed via DB triggers into `notifications`, then pushed securely to the Flutter client.
- **Entities involved**: `messages`, `notifications`, `private_upsert_notification` (RPC), `supabase_realtime`, `NotificationService`.

## 2) Human Explanation

When an action occurs (e.g., someone sends a message), a Postgres trigger intercepts the `INSERT` and calls `private_upsert_notification`. This function enforces idempotency using `idempotency_key` so duplicate notifications aren't generated. It creates a new `notifications` row. `supabase_realtime` then detects this row and broadcasts it to the recipient's Flutter app if they are online. To stop clients from spoofing fake notifications, RLS explicitly blocks all public `INSERT` operations into the `notifications` table.

## 3) Symbol Legend

- **Rectangles**: Database Triggers vs App Layers.
- **Solid Arrows**: Strict invariants and writes.
- **Dashed Arrows**: Asynchronous pub/sub pushes (Realtime / APNs).

## 4) Extracted Contracts & Invariants

1. **API Boundary**: `private_upsert_notification` is the ONLY allowed write path. Clients cannot insert notifications directly.
2. **Read Boundary**: Users can only `SELECT` and `UPDATE` (`is_read=true`) their own notifications.
3. **Idempotency**: `private_upsert_notification` MUST rely on an idempotency key to prevent double-pushing.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: None. Schema uses standardized payload formats for message notifications.

### 5.2 Logic Drift

- **Conflict**: The legacy system relied entirely on WebSockets, ignoring users where the app was backgrounded.
- **Resolution**: A secondary asynchronous Push Queue (FCM/APNs) must be connected to the `notifications` table trigger.

### 5.3 Data Model Drift

- **Conflict**: Missing edge function integration for generic "Booking" updates.
- **Resolution**: Ensure all Webhook / Edge Functions pushing custom alerts utilize the same `private_upsert_notification` RPC.

## 6) Security & Failure Modes (Adversarial)

- **Self-Notification Spam**: User messages themselves to rack up notifications.
  - _Mitigation_: The trigger explicitly skips execution if `sender == receiver`.
- **Client Spoofing**: An attacker tries to write rows to create massive alerts on a target.
  - _Mitigation_: RLS entirely revokes `INSERT` on `notifications` from `anon` and `authenticated`.
- **Offline Delivery Failure**: Websocket drops.
  - _Mitigation_: Fallback Push Delivery (Firebase FCM) via async webhook.

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Notification Center, In-App Toast Bars.
- **States**: Rendering real-time stream via `.stream(primaryKey: ['id']).eq('user_id', userId)`.
- **Guardrails**: Polling for missed notifications `onAppResume` in OS lifecycles.

### 7.2 Admin Dashboard UI

- **Pages**: Unnecessary here.

### 7.3 Implementation Hooks

- `NotificationService.initRealtimeSync()`.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10
- **Best Diagram Type**: Data Flow + Component Diagram combining DB triggers, Realtime pub/sub, and internal APIs.

## 9) Upgrade Plan

- **Phase 0: Observability**: Track drop rates for WebSockets.
- **Phase 1: Contracts**: Enforce the "Sender != Receiver" loop rejection in the DB.
- **Phase 2: Hardening**: Strictly document Idempotency key formats for Edge Functions pushing Booking notifications.
- **Phase 3: Fallback**: Deploy FCM/APNs payload webhooks.

## 10) Risks

### 10.1 Risks if current version kept

- **Missed Offers**: Users do not receive push notifications when the app is closed.

### 10.2 Risks introduced by fixes

- **FCM API Complexity**: Edge Functions handling FCM Webhooks could slow down the DB transaction if performed synchronously. _Mitigation_: Use async queues like `pg_net`.

## 11) Test Plan (High-value)

- **Security**: Authenticate as a user, attempt `INSERT INTO notifications`, verify it is rejected.
- **Integration**: Send message to self -> Assert exactly 0 notifications created.

## 12) Production Checklist

- [ ] RLS blocking insertion verified.
- [ ] Idempotency key is non-null for all RPC calls.
- [ ] FCM / Push hook is implemented asynchronously.
