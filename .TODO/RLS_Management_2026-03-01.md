# Management RLS Matrix — 2026-03-01

## Live Source
- Verification method: Supabase MCP via local `codex --enable rmcp_client exec`
- Verified objects:
  - `public.work_logs`
  - `public.is_work_log_participant(uuid, text, uuid)`
  - `work_logs_*` policies
  - `public.work_logs` grants and triggers

## Live Contract
- `public.work_logs` columns:
  - `id uuid not null default gen_random_uuid()`
  - `author_id uuid not null`
  - `related_entity_id uuid not null`
  - `related_entity_type text not null`
  - `content text not null`
  - `is_private boolean not null default false`
  - `metadata jsonb null default '{}'::jsonb`
  - `created_at timestamptz not null default now()`
- RLS enabled: `true`
- RLS forced: `false`
- Non-internal triggers: none
- Existing indexes:
  - `work_logs_pkey` on `(id)`
  - `idx_work_logs_entity` on `(related_entity_id, created_at desc)`

## Policies
- `work_logs_select`
  - Command: `SELECT`
  - Roles: `{public}`
  - Predicate:
    - private rows: `is_private = true AND author_id = auth.uid()`
    - shared rows: `is_private = false AND is_work_log_participant(related_entity_id, related_entity_type, auth.uid())`
- `work_logs_insert`
  - Command: `INSERT`
  - Roles: `{public}`
  - Check:
    - `auth.uid() = author_id`
    - `is_work_log_participant(related_entity_id, related_entity_type, auth.uid())`
- `work_logs_deny_update`
  - Command: `UPDATE`
  - Predicate: `false`
- `work_logs_deny_delete`
  - Command: `DELETE`
  - Predicate: `false`

## Helper Function
- Signature: `public.is_work_log_participant(p_entity_id uuid, p_entity_type text, p_user_id uuid)`
- Returns: `boolean`
- Language: `plpgsql`
- Volatility: `VOLATILE`
- Security definer: `true`
- Behavior:
  - `task` checks `public.tasks(id, client_id, freelancer_id)`
  - `booking` checks `public.bookings(id, client_id, provider_id)`
  - any other `p_entity_type` returns `false`

## Grants Observed
- `anon`: `DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE`
- `authenticated`: `DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE`
- `service_role`: `DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE`
- Interpretation:
  - Grants exist broadly, but RLS remains the authorization gate for reads and writes.
  - Client code must not treat grants as authorization.

## Decision
- App code may continue using direct table reads/inserts.
- No RPC or trigger is required for current invariants because live policies already enforce:
  - author must match `auth.uid()` on insert
  - participant membership for reads and inserts
  - immutable history through update/delete denial
- Additive migration is still required for performance once the app uses the correct polymorphic read filter. The live secondary index does not include `related_entity_type`.

## Verification Matrix
- Expected pass:
  - task participant reads task shared note
  - booking participant reads booking shared note
  - author reads own private note
  - participant inserts own note into related task/booking
- Expected deny:
  - non-participant reads any note
  - non-author reads private note
  - any client updates a `work_logs` row
  - any client deletes a `work_logs` row
  - unsupported `related_entity_type` inserts or reads via helper membership check
