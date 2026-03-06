# 01_NOTES: Notification Routing Audit

## 1. Skill Selection

**Skills selected:**

- Evidence-First Reading
- State Machine & Lifecycle
- Idempotency & Concurrency
- Diagram Crafting (Mermaid)

**Why these skills fit:**
Notifications bridge the database state and the client UI. Idempotency is crucial to prevent spamming users with the same notification. Evidence-First Reading ensures we only describe what is actually in the codebase and DB schema. Diagram Crafting is needed to accurately reflect the hybrid Trigger + Edge Function reality. State Machine & Lifecycle is relevant because notifications (e.g., offer_accepted) depend on the underlying entity's state transitions.

**Skills intentionally not used:**

- DB-First Financial Modeling: Not relevant for pure notification routing.
- Production Migration Planning: We are auditing the architectural flow, not deploying a DB migration right now.

## 2. Evidence Gathered

- **Code:** `lib/features/notifications/services/notification_service.dart` confirms client fetches recent notifications and subscribes via `.stream(primaryKey: ['id']).eq('user_id', userId).limit(50)`.
- **DB Triggers:** `supabase/migrations/Archive/20260301_harden_notification_writes.sql` confirms `private_upsert_notification` exists and is secured (`REVOKE ALL... FROM public, anon, authenticated`).
- **DB Trigger usage:** `trg_messages_after_insert_notify_receiver` handles `message`, `offer`, `offer_accepted`, `offer_rejected` via `private_upsert_notification`.
- **Missing DB Triggers:** No database triggers exist for `Booking Paid`, `Booking Confirmed`, `Dispute Update`. These are likely pushed from Edge Functions explicitly calling `private_upsert_notification` or direct inserts using a service_role key.

## 3. High-Level Observations

- The current diagram is honest about its unverified components (`Booking/Dispute Events`).
- Client effectively recovers from missed realtime events by fetching `limit: 20` on load/refresh, though the realtime stream relies entirely on `supabase_realtime`.
- `private_upsert_notification` provides a secure, centralized API for creating notifications without exposing the `notifications` table to arbitrary client inserts.
