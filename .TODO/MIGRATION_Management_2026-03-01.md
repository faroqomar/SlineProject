# Management Migration Note — 2026-03-01

## Decision
- Live Supabase MCP verification showed `public.work_logs` already has the required columns and RLS policies.
- No schema or policy migration is required for correctness.
- One additive performance migration is required because the corrected app query filters by both `related_entity_id` and `related_entity_type`.

## Applied Migration
- File: `supabase/migrations/20260301_add_management_work_logs_scope_index.sql`
- SQL:
  - `CREATE INDEX IF NOT EXISTS idx_work_logs_entity_scope_created_at ON public.work_logs (related_entity_id, related_entity_type, created_at DESC);`

## Why
- Live index before remediation:
  - `idx_work_logs_entity` on `(related_entity_id, created_at desc)`
- Remediated app query shape:
  - `WHERE related_entity_id = ? AND related_entity_type = ? ORDER BY created_at ASC`
- The new composite index matches the verified scope contract without changing RLS or write behavior.

## Rollback
- If planner or production telemetry shows the new index is redundant or regresses planner choices, ship a follow-up migration that drops:
  - `idx_work_logs_entity_scope_created_at`
