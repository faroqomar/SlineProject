# 04_TEST_PLAN: Notification Routing

## K) Verification Checklist (Production Readiness)

### Automated Tests

- [ ] **Unit (DB - RLS):** Attempt to `INSERT` into `notifications` as an `authenticated` user. Assert `42501 RLS policy` error.
- [ ] **Unit (DB - RLS):** Attempt to `UPDATE` a notification belonging to another user. Assert zero rows affected.
- [ ] **Integration (Triggers):** Insert a message as User A to User B. Assert `private_upsert_notification` is called and User B has 1 unread notification.
- [ ] **Integration (Triggers):** Insert a message as User A to User A (if possible). Assert 0 notifications created (sender exclusion).
- [ ] **Integration (Idempotency):** Directly call `private_upsert_notification` twice with the same idempotency key for the same user. Assert only 1 notification is stored.

### Monitoring & Alerts

- [ ] **Realtime Disconnects:** Monitor Supabase active websocket connections to ensure no mass-disconnect events.
- [ ] **Drop Rates:** (Future) If FCM/APNs are added, monitor the delivery failure rate from the push provider.
- [ ] **Queue Depth:** (Future) If using pg_net or webhook for push, monitor pending delivery jobs.

### Audit Logs

- [ ] All direct calls to `private_upsert_notification` via `service_role` (Edge Functions) should ideally log their payload to an `audit_log` or observability platform (e.g. Datadog / Sentry) to trace missing booking notifications.
