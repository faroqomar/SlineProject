# 📌 Plan: Notification Routing (13_notification-routing)

## 1) Goal

- **Goal:** Harden notification routing (idempotency, sender exclusion, observability) and add production-grade offline delivery via FCM/APNs so users are notified when the app is backgrounded or killed.
- **Why:** Current system relies 100% on `supabase_realtime`; no push path exists. Booking/task notifications come from RPCs/triggers via `private_create_notification` (no strict idempotency). Self-notification is already guarded in `messages_after_insert_notify_receiver` (sender == receiver skip). Missing: push delivery, optional idempotency hardening for create path, and foreground sync strategy for unread catch-up.
- **Result:** Reliable in-app + background push; no duplicate notifications from retries; docs and diagram aligned with live DB and code.

## 2) Scope

### In-Scope

- Observability: ensure `private_upsert_notification` / `private_create_notification` failure paths are loggable (Edge/DB or app-side where applicable).
- Trigger guard: confirm and document that `trg_messages_after_insert_notify_receiver` skips when sender == receiver (already implemented; verify + document).
- Idempotency: document and optionally extend idempotency for notification creation (collapse-on-unread already in `private_upsert_notification`; consider idempotency key or locking for `private_create_notification` call sites in RPCs if race risk is confirmed).
- Push delivery: add `user_devices` (or equivalent) for FCM/APNs tokens; Edge Function for FCM; DB trigger on `notifications` INSERT that asynchronously invokes push (e.g. via `pg_net` or Edge Function webhook).
- Flutter: register FCM token on login; optional “sync all unread on foreground” before continuing stream (limit 50) to avoid truncation of unread count.
- RLS/security: no client INSERT on `notifications` (already enforced); push path uses service_role only.
- Documentation: update DEVELOPER_GUIDE, SUPABASE_SETUP, and `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md` to match implementation and live DB.
- Tests: RLS (no client INSERT), sender-exclusion, idempotency behaviour, and (if implemented) push path verification.

### Out-of-Scope

- Changing existing notification types or adding new in-app notification types beyond what’s needed for push payload.
- APNs native implementation in this plan (can be phased; FCM can cover iOS via FCM SDK).
- Replacing or refactoring existing RPCs that call `private_create_notification` beyond adding idempotency where agreed.

## 3) Evidence & Findings (From Scan)

### Existing

- **Docs:** `Sline_everything/DEVELOPER_GUIDE.md` (§3 architecture: notifications server-side; client read/update only). `Sline_everything/SUPABASE_SETUP.md` §5.13 `notifications` table; §8 triggers; Realtime on `messages`, `notifications`. `.TODO/improvement_the_system/ImplementReady/13_notification-routing/` (00–07) contain holistic report, gaps, diagram, test plan, risk register, system critic verdict.
- **Code:** `lib/features/notifications/services/notification_service.dart` — `getNotifications(limit: 20)`, `streamNotifications()` (`.stream(primaryKey: ['id']).eq('user_id', userId).order('created_at', false).limit(50)`), `markAsRead`, `markAllAsRead`. No direct INSERT. View/viewmodel in `lib/features/notifications/`.
- **DB (live scan):** Table `public.notifications` exists (columns per SUPABASE_SETUP). Triggers: `trg_messages_after_insert_notify_receiver` on `messages`; `trg_booking_server_notifications` on `bookings`. No trigger on `notifications` (no push path). RLS: `notifications_select_authenticated` (r), `notifications_update_authenticated` (w); no INSERT policy (client insert blocked).
- **Migrations:** `supabase/migrations/Archive/20260301_harden_notification_writes.sql` defines `private_upsert_notification` (collapse on unread by type/entity), REVOKE from anon/authenticated; `messages_after_insert_notify_receiver()` with sender == receiver skip; `trg_messages_after_insert_notify_receiver`; `tasks_after_status_change_notify_parties`; DROP `notifications_insert_any`. Active migrations call `private_create_notification` from RPCs (e.g. `pay_awarded_offer`, award/task flows).

### Missing

- Push: no `user_devices` (or similar) table; no FCM/APNs Edge Function; no trigger on `notifications` to queue push; no Flutter FCM token registration.
- `pg_net` (or equivalent) not present in repo for async HTTP from DB; to be added if trigger → Edge Function is used.
- Documented idempotency key format for booking/dispute flows (docs mention it; `private_upsert_notification` uses collapse-on-unread only; `private_create_notification` has no key parameter in current signature).
- Optional: “sync all unread on foreground” in Flutter before stream (to avoid limit-50 truncation of unread count).

### Conflicts / Risks (docs vs code vs live DB drift, naming mismatches, security/migration risks)

- Folder 13 describes `private_upsert_notification` as accepting `idempotency_key`; live function has no such parameter (collapse-on-unread only). Plan treats docs as intent; no breaking change to function signature unless we add optional param.
- System Critic (07) states booking/dispute notifications come from RPCs/triggers and `private_create_notification`, not Edge Functions — consistent with migrations; diagram in 06 should be updated to show RPC/trigger sources.
- Adding a trigger on `notifications` for push must be non-blocking (async) to avoid slowing INSERTs; use `pg_net` or out-of-band job, not synchronous HTTP in trigger.
- FCM/APNs require secrets (FCM server key, etc.); store in Edge Function secrets only, never in client or repo.

## 4) System Impact Map

- **UI:** Badge and notification list unchanged unless “sync all unread on foreground” is added (then initial load may show full unread count). Push: OS-level notifications when app backgrounded/killed.
- **MVVM/App Logic:** New or extended: device token registration (service/repository), optional foreground sync in NotificationViewModel; no change to “no client INSERT” rule.
- **Database:** New table `user_devices` (user_id, token, platform, updated_at); possibly new trigger on `notifications`; optional `pg_net` usage for async webhook.
- **RLS/Security:** RLS on `user_devices` (user can insert/update/delete own rows only). Push path: service_role only; no client calls to FCM.
- **Realtime/Notifications:** Realtime unchanged. New: push delivery path from `notifications` INSERT → async → Edge Function → FCM.
- **Storage:** None.
- **Observability:** Logging for push failures (Edge Function); optional audit or metrics for notification creation failures in RPCs.
- **Compatibility & Migration:** Additive: new table, new trigger, new Edge Function. Old clients continue to work (realtime + fetch); new clients register token and receive push.
- **Contracts:** Document notification payload shape for push (title, body, data payload for deep link); document idempotency behaviour of `private_upsert_notification` and any new `private_create_notification` idempotency.

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance + non-regression list (measurable): RLS blocks client INSERT; sender-exclusion test; idempotency behaviour; push E2E when app killed; docs match code/DB.
- [ ] (@Architect) Confirm modules/entry points: `lib/features/notifications/`, `supabase/functions/`, migrations, DEVELOPER_GUIDE + SUPABASE_SETUP + 13_notification-routing diagram.
- **Verify (@Sentinel):** done-conditions + rollback triggers documented.

### 0.2 Threat Model (If sensitive/high-risk)

- [ ] (@ThreatModeler) Threat model + security requirements + negative checks (in `.TODO/` or 13 folder): push token theft, spoofed push, abuse of device table; RLS and service_role boundary.
- **Verify (@Sentinel):** testable and included in Phase 4.

### 0.3 Contracts (If payloads change)

- [ ] (@APIContract) Contract file(s) in `.TODO/` (DB/RPC/Edge ↔ Flutter): notification push payload (title, body, data); `user_devices` shape; idempotency behaviour of notification APIs.
- **Verify (@Sentinel):** contract matches schema + shapes.

### 0.4 Migration Plan (If schema/data changes)

- [ ] (@DataMigration) Additive migration for `user_devices`; trigger for push; no backfill required. Rollback: drop trigger, drop table (and optionally revoke push Edge Function).
- **Verify (@Sentinel):** measurable compatibility window; old app continues to work.

### 0.5 Feature Flag/Rollout (If risky)

- [ ] (@Architect) Optional: feature flag to enable push (e.g. register token only when enabled) for gradual rollout.
- **Verify (@Sentinel):** rollback path documented.

---

## Phase 1: Database & Security (If applicable)

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation (MANDATORY)

- [ ] (@Supabase_Ops) Re-scan via `@mcp:supabase-mcp-server:` for `notifications`, triggers on `messages`/`bookings`, RLS on `notifications`; confirm no conflicts with planned new objects.
- **Verify (@Sentinel):** drift + safe approach recorded (already done in Evidence above).

### 1.1 Schema (Additive-first)

- [ ] (@Supabase_Ops) DDL: `user_devices` table (e.g. id, user_id, fcm_token, platform, created_at, updated_at); unique constraint (user_id, platform) or (user_id, fcm_token) as appropriate; indexes for lookup by user_id.
- [ ] (@Supabase_Ops) No change to `notifications` columns unless optional idempotency key column is agreed (out-of-scope for minimal push path).
- **Verify (@Sentinel):** no leaks/breaks, naming consistent with STRUCTURE/SUPABASE_SETUP.

### 1.2 RLS

- [ ] (@Supabase_Ops) Policies on `user_devices`: user can SELECT/INSERT/UPDATE/DELETE own rows only (by auth.uid() = user_id).
- [ ] (@Supabase_Ops) RLS check matrix file in `.TODO/` or 13 folder for `user_devices`.
- **Verify (@Sentinel):** negative fails (other user’s rows), positive passes.

### 1.3 Triggers/RPC (If needed)

- [ ] (@Supabase_Ops) Trigger on `notifications` AFTER INSERT: call a function that queues async work (e.g. `pg_net.http_post` to Edge Function URL with notification payload). Ensure trigger is non-blocking and does not hold transaction.
- [ ] (@Supabase_Ops) If `pg_net` not enabled: enable extension; or use Supabase recommended pattern for “trigger → Edge Function” (e.g. webhook URL + queue).
- **Verify (@Sentinel):** state rules enforced; INSERT to notifications still fast.

### 1.4 Migration Execution (If needed)

- [ ] (@DataMigration) Run migration(s) for `user_devices` and push trigger per plan.
- **Verify (@Sentinel):** verify queries and trigger fire without error.

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 Models & Contract Compliance

- [ ] (@Architect) Model for device registration (e.g. `UserDevice` or DTO) aligned to `user_devices` contract.
- [ ] (@Architect) Mapping + domain error mapping for token registration failures.
- **Verify (@Sentinel):** types/nullability match contract.

### 2.2 Services/Repositories

- [ ] (@Architect) Service or repository: register FCM token (upsert into `user_devices`), call from auth flow (after login/session restore). Use anon key with RLS (user_id = auth.uid()).
- [ ] (@Architect) No N+1; storage rule: DB stores paths only (N/A for notifications).
- **Verify (@Sentinel):** RLS-safe; no UI → Supabase direct INSERT into `notifications`.

### 2.3 ViewModels

- [ ] (@Architect) Optional: on app foreground, fetch “all unread” count or list once, then continue with existing stream (limit 50) so badge is correct and no truncation of unread.
- [ ] (@Architect) Single source of truth for notification list (existing stream + optional initial unread sync).
- **Verify (@Sentinel):** recoverable state + correct transitions.

### 2.4 Observability (If needed)

- [ ] (@Observability) Event list + correlation strategy (in `.TODO/` or 13): push delivery success/failure, token registration failure.
- [ ] (@Architect) Instrument token registration and optional sync in service/viewmodel (not UI).
- **Verify (@Sentinel):** no sensitive logs (no tokens in logs); consistent correlation.

---

## Phase 3: UI (After logic)

> Primary: @Pixel

### 3.1 Wiring

- [ ] (@Pixel) Ensure notification UI uses ViewModels only; no new direct Supabase calls.
- [ ] (@Pixel) Loading/empty/error states for notification list and (if added) token registration failure (e.g. toast or silent retry).
- **Verify (@Sentinel):** stable UX on slow/empty data.

### 3.2 Polish (Optional)

- [ ] (@Pixel) Optional: micro-interactions for notification list (low-risk only).
- **Verify (@Sentinel):** no perf regression.

---

## Phase 4: QA + Security (MANDATORY)

> Primary: @Sentinel

### 4.1 Contract + Migration Checks

- [ ] (@Sentinel) Shapes/types match contract (Flutter models vs `user_devices`, push payload).
- [ ] (@Sentinel) Run migration verify queries (if any).
- **Verify (@Sentinel):** no mismatch.

### 4.2 Security + Abuse Tests

- [ ] (@Sentinel) Execute ThreatModeler negative checks: RLS on `notifications` (INSERT denied); RLS on `user_devices` (own rows only); push path not callable by client.
- [ ] (@Sentinel) RLS leak audit: no client can insert into `notifications` or read/update another user’s devices.
- **Verify (@Sentinel):** unauthorized access impossible.

### 4.3 Functional QA

- [ ] (@Sentinel) Manual E2E: send message → other user gets in-app notification; send message → other user kills app → other user receives OS push.
- [ ] (@Sentinel) Edge cases: sender == receiver (no notification); duplicate call idempotency (single notification); network/null/stale.
- **Verify (@Sentinel):** no crashes, consistent behaviour.

### 4.4 Observability Validation (If included)

- [ ] (@Sentinel) Required logs/events exist and are useful (push failure, token registration).
- [ ] (@Sentinel) Privacy redaction enforced (no FCM tokens in logs).
- **Verify (@Sentinel):** actionable telemetry without leaks.

---

## Phase 5: Documentation Sync (MANDATORY)

> Primary: @SlineDocs

- [ ] (@SlineDocs) Update `Sline_everything/DEVELOPER_GUIDE.md` (notification flow: realtime + push; client read/update only; device registration).
- [ ] (@SlineDocs) Update `Sline_everything/SUPABASE_SETUP.md`: `user_devices` table, RLS, trigger on `notifications`, push Edge Function reference; correct description of `private_upsert_notification` (collapse-on-unread, no idempotency_key param unless added).
- [ ] (@SlineDocs) Update `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md` to match implementation (RPC/trigger sources for booking/task; push path; Flutter token registration).
- [ ] (@SlineDocs) Move or reference `.TODO/improvement_the_system/ImplementReady/13_notification-routing/` content into plan/execution log as needed.
- **Verify (@Sentinel):** docs match code + live DB reality.

---

## 7) Acceptance Criteria (MANDATORY)

- RLS: Authenticated client `INSERT` into `notifications` returns 42501 (or equivalent denial).
- Sender exclusion: Insert message where sender_id = receiver_id; exactly 0 notifications created for that message.
- Idempotency: Documented behaviour of `private_upsert_notification` (collapse on unread); if idempotency added to `private_create_notification` call sites, duplicate call produces single notification.
- Push: New notification row → async trigger → Edge Function → FCM → OS push when app is backgrounded/killed (measurable via test).
- Flutter: Token registered after login; notification list and badge work with existing realtime stream; optional “sync all unread on foreground” avoids limit-50 truncation of unread count.
- No regression: Existing in-app notification flow (realtime + fetch) unchanged for users without push or on first release.
- Observability: Push delivery failures and token registration failures are loggable and non-sensitive.

## 8) Rollback Plan

- **DB:** Drop trigger on `notifications` (push); optionally drop `user_devices` if no dependency; re-run migration down or new migration to revert. No drop of `notifications` or existing RLS.
- **App:** Feature flag off: stop registering token and/or ignore push; revert deploy to previous version.
- **Edge Function:** Disable or remove `push-notify` (or equivalent) invocation from trigger; keep function for quick re-enable.
- **Emergency:** Disable push by removing trigger or turning off Edge Function; clients fall back to realtime + fetch only.

## 9) References (From Scan)

- `Sline_everything/DEVELOPER_GUIDE.md` (architecture, notifications server-side)
- `Sline_everything/SUPABASE_SETUP.md` (§5.13 notifications, §8 triggers, Realtime)
- `Sline_everything/STRUCTURE.md`, `Sline_everything/MVP_ROADMAP.md`
- `Sline_everything/AppDigram/All_Diagrams/13_notification-routing.md`
- `lib/features/notifications/services/notification_service.dart`, `viewmodels/notification_view_model.dart`, `view/`
- `supabase/migrations/Archive/20260301_harden_notification_writes.sql`
- `supabase/migrations/20260308180000_tender_assign_only_after_payment.sql` (and other callers of `private_create_notification`)
- `.TODO/improvement_the_system/ImplementReady/13_notification-routing/` (00_HOLISTIC_REPORT, 01_NOTES, 02_GAPS_AND_FIXES, 03_RISK_REGISTER, 04_TEST_PLAN, 06_DIAGRAM_FINAL, 07_SYSTEM_CRITIC_VERDICT)
- Live Supabase scan (plugin-supabase-supabase): `list_tables`, `execute_sql` for triggers on messages/bookings/notifications and RLS on notifications (2026-03-08).
