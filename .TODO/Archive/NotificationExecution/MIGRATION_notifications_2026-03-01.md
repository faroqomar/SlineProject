# Migration Plan: Notifications (2026-03-01)

## Tracks

### 1. Fresh bootstrap repair

- **Problem**: `supabase/migrations/20260226_tender_award_payment_flow.sql` inserts into `notifications` with columns `body`, `data`, `read`. Live schema uses `message`, `is_read`, `metadata`.
- **Action**: Patch the same file: replace every notification INSERT to use `message` (not `body`), `is_read` (not `read`), `metadata` (not `data`). Keep all other columns and logic.
- **Verification**: On a fresh branch DB, run `supabase db reset` (or apply migrations in order); no error on notifications table. Optional: `SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='notifications'` — expect `message`, `is_read`, `metadata`.

### 2. Deployed / shared environment

- **Assumption**: Live DB already has correct schema and policies (reconcile_orders_owner_contract, harden_notification_writes applied).
- **Action**: No destructive change. If a deployed DB was created from an older 20260226, it may have had a one-time failure or manual fix; forward migrations (reconcile, harden) do not re-insert using body/data/read. Verification: confirm live `notifications` columns match contract; confirm RLS policies exist (select_own, update_own; no insert for authenticated).

### 3. Policy source capture

- If versioned SQL in repo does not contain `notifications_select_own` / `notifications_update_own` DDL: add an idempotent migration that creates them if not present (e.g. `CREATE POLICY ... IF NOT EXISTS` or equivalent). Current plan assumes they exist in live; doc in SUPABASE_SETUP.md.

## Rollback

- **Bootstrap patch**: Revert the 20260226 patch; re-run migrations on a fresh clone only. Do not alter already-applied migrations on shared DB.
- **App**: Revert app PR (ViewModel, modal, service); keep DB and RLS as-is.

## Environment baseline

- App cleanup (Phase 3–5) assumes: live DB has correct notification schema, RLS (select_own, update_own, no client insert), triggers and `private_create_notification` / `private_upsert_notification` in place.
