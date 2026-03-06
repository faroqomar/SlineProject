# 04_EXECUTION_PLAN: Phased Implementation Strategy

---

## Phase 0: Naming & Contract Unification (No Behavior Changes)

> **Goal**: Establish a single glossary. Fix naming drift. Zero runtime impact.

### Targets

| Action                          | Folders    | Object                                                   | Change                                                                         |
| ------------------------------- | ---------- | -------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Rename config table             | 22, 23     | `system_config` → `platform_settings`                    | Update all docs and SQL references to use `platform_settings`                  |
| Fix status name                 | 06         | `pending` → `sent`                                       | All diagrams/UI strings referencing direct offer initial state                 |
| Standardize RPC naming          | 21         | `process_payment_event` → `process_payment_event_ledger` | Remove all references to deprecated RPC                                        |
| Unify "work in progress" status | 03, 05, 12 | `in_progress` (task) vs `active` (booking)               | Document canonical mapping in glossary. No DB change needed (view handles it). |
| Standardize RPC call pattern    | 07, 08     | Direct INSERT → `start_direct_conversation_v1`           | Document that all chat creation must go through RPCs                           |

### Blast Radius

- **Zero code/DB behavior changes.** Documentation and diagram updates only.
- If enum renaming in docs creates confusion, prefix old names with `[DEPRECATED]`.

### Rollback Strategy

- Revert documentation. No DB/code changes to undo.

### Verification

- [ ] Search all 24 folders for `system_config` → must return 0 hits.
- [ ] Search all 24 folders for `process_payment_event` (without `_ledger`) → must return 0 hits.
- [ ] Search all 24 folders for `pending` as direct offer status → must return 0 hits.

---

## Phase 1: DB Invariants & RLS Hardening

> **Goal**: Fix the foundation. Ensure DB constraints match diagram requirements.

### Targets

| Action                                                               | Folders | SQL Target                                                                                                              | Conflict Fixed |
| -------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------- | -------------- |
| **Drop `public.users` view**                                         | 15, 23  | `DROP VIEW IF EXISTS public.users CASCADE;`                                                                             | C-14           |
| **Create `platform_settings` table**                                 | 22, 23  | `CREATE TABLE platform_settings (key TEXT PRIMARY KEY, value JSONB, updated_at TIMESTAMPTZ DEFAULT now());`             | C-01, C-08     |
| **Add `disputed`, `no_show` to `booking_status_enum`**               | 05, 14  | `ALTER TYPE booking_status_enum ADD VALUE 'disputed'; ALTER TYPE booking_status_enum ADD VALUE 'no_show';`              | C-05           |
| **Add `delivered_at`, `review_expires_at` to `direct_offers`**       | 06, 15  | `ALTER TABLE direct_offers ADD COLUMN delivered_at TIMESTAMPTZ, ADD COLUMN review_expires_at TIMESTAMPTZ;`              | C-15           |
| **Add `fee_rate_applied`, `fee_amount`, `net_amount` to `bookings`** | 22      | `ALTER TABLE bookings ADD COLUMN fee_rate_applied INTEGER, ADD COLUMN fee_amount BIGINT, ADD COLUMN net_amount BIGINT;` | C-08           |
| **Create `dispute_status_enum`**                                     | 14      | `CREATE TYPE dispute_status_enum AS ENUM ('open', 'active', 'resolved', 'canceled');`                                   | C-06 enum      |
| **Extend `disputes` FK to accept `direct_offer_id`**                 | 06, 14  | `ALTER TABLE disputes ADD COLUMN direct_offer_id UUID REFERENCES direct_offers(id);`                                    | C-06           |
| **Re-create views with `security_invoker`**                          | 12, 15  | `DROP VIEW vw_unified_work_items; CREATE VIEW ... WITH (security_invoker = true);`                                      | C-20           |
| **Patch `rpc_request_revision` guards**                              | 10      | Add status check + revision cap check                                                                                   | C-07 side fix  |
| **Set `is_blocked` in `fn_booking_guard`**                           | 05, 11  | Atomically set slot `is_blocked=true` on booking confirmation                                                           | C-10           |

### Blast Radius

- **Medium**. Enum additions are safe (additive). Column additions are safe (nullable). View replacements may briefly break running queries.
- Dropping `public.users` will break any code using it — **audit code first**.

### Rollback Strategy

- Enum additions: Cannot be rolled back in Postgres. Ensure they're correct.
- Column additions: `ALTER TABLE ... DROP COLUMN`.
- View replacements: Keep old DDL as backup migration.

### Verification

- [ ] `SELECT * FROM public.users` → returns error.
- [ ] `SELECT * FROM platform_settings` → returns rows.
- [ ] `INSERT INTO bookings (status) VALUES ('disputed')` → succeeds.
- [ ] `INSERT INTO direct_offers (delivered_at, review_expires_at) VALUES (now(), now() + '3 days')` → succeeds.
- [ ] `vw_unified_work_items` is `security_invoker = true` (check `pg_views`).
- [ ] `rpc_request_revision` on `status='active'` → raises exception.

---

## Phase 2: RPC Atomicity & Idempotency

> **Goal**: Fix the broken financial guards and make them production-safe.

### Targets

| Action                                                 | Folders | Target                                                                                            | Conflict Fixed |
| ------------------------------------------------------ | ------- | ------------------------------------------------------------------------------------------------- | -------------- | --- | --- | ---------- | --- | --- | --- | --------------- | ---- |
| **Fix idempotency key generation**                     | 16, 09  | Remove `now()` from digest. Use `entity_id                                                        |                | ':' |     | event_type |     | ':' |     | source_status`. | C-09 |
| **Add `FOR UPDATE` lock**                              | 16      | Add `SELECT ... FOR UPDATE` on entity row before ledger processing                                | C-09           |
| **Patch ledger to read fee from entity**               | 09, 22  | `process_payment_event_ledger` reads `fee_rate_applied` from booking record, NOT `p_meta`         | C-08           |
| **Add `withdrawal_cancel` event**                      | 20, 09  | New event type in ledger that reverses `withdrawal_request`                                       | C-17           |
| **Add active dispute check to** `rpc_approve_delivery` | 14, 16  | `IF EXISTS (SELECT 1 FROM disputes WHERE task_id=... AND status IN ('open','active'))` THEN block | C-16           |
| **Create `rpc_create_withdrawal_request`**             | 20      | Atomic RPC: INSERT request + ledger lock in one transaction                                       | —              |
| **Implement `switch_active_role` RPC**                 | 02      | Atomic role switch with `expected_old_role` optimistic lock                                       | —              |
| **Migrate chat creation to RPCs**                      | 07, 08  | `start_direct_conversation_v1`, `start_task_conversation_v1`                                      | C-03           |
| **Add 4th branch to unified work view**                | 12      | `UNION ALL` for `direct_offers`                                                                   | C-11           |

### Blast Radius

- **High but contained**. Each RPC change is transactional. If one fails, only that flow is affected.
- `p_meta` fee override removal may break admin manual corrections — add `admin_manual_correction` event.

### Rollback Strategy

- Keep old RPC versions with `_v1` suffix. New RPCs use `_v2`. Switch at app layer.
- Idempotency key change: Old keys will never collide with new keys (different hash inputs). Safe.

### Verification

- [ ] Rapid double-tap test on "Approve Delivery" → exactly 1 journal entry created.
- [ ] `withdrawal_cancel` → funds return to `user_available`.
- [ ] `rpc_approve_delivery` with active dispute → raises exception.
- [ ] `switch_active_role` with wrong `expected_old_role` → raises exception.
- [ ] `vw_unified_work_items` returns direct offers in result set.

---

## Phase 3: App Wiring (Flutter Services/UI) + Removal of Fallbacks

> **Goal**: Connect Flutter layer to hardened DB. Remove workarounds.

### Targets

| Action                                              | Folders | File(s)                                     | Notes                                           |
| --------------------------------------------------- | ------- | ------------------------------------------- | ----------------------------------------------- |
| **Implement `AvailabilityService`**                 | 11      | `lib/features/availability/services/`       | Zero Flutter code exists today                  |
| **Remove `subscribeToConversations()`**             | 18      | `message_service.dart`                      | Replace with `messages` stream for inbox resort |
| **Update `DirectOffersService` for `delivered_at`** | 06, 19  | `direct_offers_service.dart`                | Set `review_expires_at` on delivery             |
| **Wire `WalletService` to atomic RPC**              | 20      | `wallet_service.dart`                       | Use `rpc_create_withdrawal_request`             |
| **Implement state teardown on role switch**         | 02      | Multiple ViewModels                         | `clearCache()`, `disconnectChannels()`          |
| **Map `disputed` + `no_show` in UI**                | 05, 14  | Booking screens, `UnifiedWorkStatus`        | Add new status chips/cards                      |
| **Implement `PresenceService`**                     | 08      | `presence_service.dart` (new)               | Connect typing indicators                       |
| **Migrate off deprecated wallet tables**            | 21      | `wallet_service.dart`                       | Remove `wallet_transactions` references         |
| **Implement FCM push integration**                  | 13      | `notification_service.dart` + Edge Function | Background notifications                        |
| **Remove unified view Dart fallback**               | 12      | `WorkManagementService`                     | DB view is now the single source                |

### Blast Radius

- **High**. Multiple features touched. Requires feature flags or phased rollout.
- Each service change should have its own PR with integration tests.

### Rollback Strategy

- Feature flags per service. If `AvailabilityService` is buggy, disable availability feature in app config.
- Keep old `subscribeToConversations` behind a flag for 1 release.

### Verification

- [ ] `AvailabilityService` creates slots. Overlap → user-friendly error.
- [ ] Inbox updates reactively when a message arrives (without pull-to-refresh).
- [ ] Direct offer auto-approve fires after `review_expires_at`.
- [ ] Role switch clears all old-role data from memory.
- [ ] Wallet shows correct `available` + `pending_withdrawal` balances.

---

## Phase 4: Observability (Admin Trace Views, Logs, Reconciliation)

> **Goal**: Make the system debuggable and auditable.

### Targets

| Action                                                 | Folders    | Notes                                               |
| ------------------------------------------------------ | ---------- | --------------------------------------------------- |
| **Deploy `vw_admin_finance_overview`**                 | 23         | Aggregate GMV, revenue, escrow from `ledger_lines`  |
| **Deploy `vw_admin_booking_finance`**                  | 23         | Per-booking money story                             |
| **Implement `admin_logs` triggers**                    | 14, 20, 22 | Status changes on disputes, withdrawals, fee config |
| **Create `payment_intents` + `payment_events` tables** | 24         | Foundation for payment linking                      |
| **Deploy Webhook Handler edge function**               | 24         | QiCard → `process_payment_event_ledger`             |
| **Set up `orphan_payments` alerting**                  | 24         | Monitor quarantined payments                        |
| **Configure 42501 (RLS denied) alerts**                | 15         | Supabase Log Explorer                               |
| **Track `supabase_realtime` connection drops**         | 18         | Mobile health monitor                               |

### Blast Radius

- **Low**. All additions are additive (new views, new tables, new logging). No existing behavior changed.

### Rollback Strategy

- Drop new views/tables if they cause performance issues.

### Verification

- [ ] Admin can see platform-wide GMV.
- [ ] Admin can drill into a booking and see full ledger trail.
- [ ] Orphan payments appear in quarantine table with reason.
- [ ] RLS denied events produce alerts.

---

## Phase 5: Load/Performance + Final QA

> **Goal**: Ensure everything scales and passes end-to-end validation.

### Targets

| Action                                    | Notes                                                                                                          |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Add compound indexes**                  | `tasks(status, payment_status)`, `bookings(status, provider_id)`, `availability_slots(provider_id, starts_at)` |
| **Benchmark `vw_unified_work_items`**     | `EXPLAIN ANALYZE` on heavy user with 100+ items. Consider materialized view if >1s.                            |
| **Benchmark `vw_admin_finance_overview`** | Must respond <3s for admin dashboard. Use materialized view + cron refresh if needed.                          |
| **Stress-test idempotency**               | 100 concurrent `rpc_approve_delivery` calls. Expect exactly 1 journal entry.                                   |
| **Stress-test realtime**                  | 50 rapid messages in active chat. Verify 0 duplicates, correct ordering.                                       |
| **Full end-to-end regression**            | Signup → Post Task → Accept Bid → Pay → Deliver → Approve → Withdraw → Admin Dashboard                         |

### Blast Radius

- **Minimal**. Indexes are additive. Materialized views are supplementary.

### Rollback Strategy

- Drop indexes if they slow write paths.
- Replace materialized view with standard view if refresh cron causes lag.

### Verification

- [ ] All `EXPLAIN ANALYZE` queries use indexes (no seq scans on large tables).
- [ ] Load tests pass within SLA (<500ms p95 for API calls).
- [ ] End-to-end test passes without manual intervention.
- [ ] No orphan funds remain in escrow after full test cycle.
