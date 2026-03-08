# 02_GAPS_AND_FIXES: Notification Routing

## Extracted Invariants & Contracts

1. **API boundary:** `private_upsert_notification` is the ONLY allowed write path into the `notifications` table. Clients cannot insert notifications directly. Evidence: `REVOKE ALL ON FUNCTION public.private_upsert_notification... FROM PUBLIC, anon, authenticated;` in `supabase/migrations/Archive/20260301_harden_notification_writes.sql`.
2. **Read boundary:** Users can only select and update (`is_read` flag) their own notifications. Evidence: `notifications_select_own`, `notifications_update_own` in `13_notification-routing.md`.
3. **Idempotency:** The `private_upsert_notification` takes an `idempotency_key` which prevents sending or storing duplicate notifications for the same underlying event (e.g. repeated clicks on a button).

## Failure Modes & Attack Scenarios

**Scenario 1: Edge Function Over-Pushing Notifications**

- **What happens now:** Edge Functions (for bookings or disputes) might push notifications. If they fail mid-way, they might retry and push duplicates unless an idempotency key is strictly enforced.
- **What should happen:** The `private_upsert_notification` signature accepts an `idempotency_key`, but Edge Functions must systematically generate and supply one (e.g. `booking_paid_{booking_id}_{status}`).
- **Missing guardrails:** Enforcement of idempotency key formatting inside Edge Functions.

**Scenario 2: Realtime Disconnection**

- **What happens now:** `supabase_realtime` pushes events to the flutter client via WebSocket `.stream()`. If the user has poor connectivity, they miss the payload.
- **What should happen:** When the app re-foregrounds or reconnects, it re-fetches the latest 50 notifications via `.stream(primaryKey: ['id'])`. This works gracefully as the Flutter SDK automatically re-fetches under the hood.
- **Missing guardrails:** The client code currently queries with `limit(50)`. If a user gets 51 notifications while offline, that 51st notification is lost from the stream history until specifically queried. Also, there's no push notification fallback mentioned (e.g. FCM/APNs).

**Scenario 3: Self-Notification Spam**

- **What happens now:** A user might send a message and trigger a notification to themselves.
- **What should happen:** `messages_after_insert_notify_receiver` must explicitly exclude `user_id = auth.uid()` from receiving the notification.
- **Missing guardrails:** Explicit verification that the trigger skips the sender.

**Scenario 4: Client Spoofing Notifications**

- **What happens now:** A client tries to insert a notification for another user via REST API.
- **What should happen:** RLS on the `notifications` table blocks all inserts from `authenticated` and `anon` roles.
- **Missing guardrails:** RLS policy must strictly omit `INSERT` for users. `13_notification-routing.md` only lists `SELECT` and `UPDATE` policies, implying `INSERT` is omitted, which is correct.
