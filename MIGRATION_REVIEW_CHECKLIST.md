# Migration Review Checklist

Reference this checklist in every PR that includes files under `supabase/migrations/`.

## Required Checks

### 1. Naming
- [ ] Migration file follows `YYYYMMDD_description.sql` convention
- [ ] Description is concise and descriptive (e.g., `20260403_add_payment_deadline_index`)

### 2. Rollback Plan
- [ ] Down migration exists OR rollback steps are documented in the PR description
- [ ] Partial failure recovery is considered (what if migration fails halfway?)

### 3. Data Safety
- [ ] No existing rows violate the new constraint
- [ ] Backfill step included if adding a NOT NULL column to a populated table
- [ ] Default values specified for new columns on existing rows

### 4. RLS Impact
- [ ] RLS policies reviewed for affected tables
- [ ] Existing authenticated queries still work after the change
- [ ] New policies tested with both owner and non-owner contexts

### 5. RPC Contract
- [ ] If an RPC signature changes, all client code callers are updated in the same PR
- [ ] Return type changes are backward-compatible or documented as breaking
- [ ] Parameter additions use DEFAULT values to avoid breaking existing callers

### 6. Idempotency
- [ ] Migration can be re-run safely (`CREATE OR REPLACE`, `IF NOT EXISTS`, `ON CONFLICT DO NOTHING`)
- [ ] No destructive operations without guards (e.g., `DROP TABLE IF EXISTS`)

### 7. Performance
- [ ] New queries have supporting indexes
- [ ] Index creation uses `CONCURRENTLY` for large tables (prevents table lock)
- [ ] Query patterns checked against existing indexes (no full table scans)

## How to Use

1. Copy this checklist into your PR description when the PR includes migration files
2. Check off each item as you verify it
3. If any item is N/A, mark it as such with a brief explanation
4. Reviewer should verify all items are checked before approving
