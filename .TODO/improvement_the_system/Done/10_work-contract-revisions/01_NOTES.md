# Audit Notes: Work Contract Revisions

## Skills Selected

- **Evidence-First Reading**: To pull exact RPC implementations and table columns from Postgres migrations.
- **Invariants & Contracts**: To identify rules like "Only clients can request revisions" and "Revisions increment `revisions_used`".
- **State Machine & Lifecycle**: The flow transitions a task/booking from `delivered` back to `active`.
- **Threat Modeling (Security)**: Assessing bypasses where a non-client tries to request a revision, or revision spamming.

## Evidence Formed

- `supabase/migrations/20260305180100_work_revision_and_change_rpcs.sql`:
  - `rpc_request_revision` sets status back to 'active', nullifies `delivered_at` and `review_expires_at`, updates `revision_note`, and increments `revisions_used`.
  - It enforces `auth.uid() = t.client_id` (or owner for tasks).
- `supabase/migrations/20260305180000_work_contracts_change_extension_requests.sql`:
  - `work_contracts`, `change_requests`, and `extension_requests` are present. RLS restricts access to participants.
- `lib/features/work/services/work_management_service.dart`:
  - `requestRevision` correctly calls `rpc_request_revision` with the entity details and note.

## System Observations

- Revisions are fundamentally state reversions (`delivered` -> `active`).
- Revisions_used increments indefinitely unless capped. The RPC (`rpc_request_revision`) currently lacks a strict check against `revisions_total`. It just does: `revisions_used = COALESCE(revisions_used, 0) + 1`. The diagram states "DB checks limits" but the snippet doesn't show a strict raise exception if `revisions_used >= revisions_total`. This is a critical gap!
