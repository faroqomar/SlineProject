## Migration Review Checklist

> This PR includes `supabase/migrations/` files. Complete all checks before requesting review.

### 1. Naming
- [ ] Migration file follows `YYYYMMDD_description.sql` convention
- [ ] Description is concise and descriptive

### 2. Rollback Plan
- [ ] Down migration exists OR rollback steps documented in this PR
- [ ] Partial failure recovery considered (what if migration fails halfway?)

### 3. Data Safety
- [ ] No existing rows violate the new constraint
- [ ] Backfill step included if adding NOT NULL column to populated table
- [ ] Default values specified for new columns on existing rows

### 4. RLS Impact
- [ ] RLS policies reviewed for affected tables
- [ ] Existing authenticated queries still work after the change
- [ ] New policies tested with both owner and non-owner contexts

### 5. RPC Contract
- [ ] If RPC signature changes, all client code callers updated in same PR
- [ ] Return type changes are backward-compatible or documented as breaking
- [ ] Parameter additions use DEFAULT values

### 6. Idempotency
- [ ] Migration can be re-run safely (`CREATE OR REPLACE`, `IF NOT EXISTS`)
- [ ] No destructive operations without guards

### 7. Performance
- [ ] New queries have supporting indexes
- [ ] Index creation uses `CONCURRENTLY` for large tables
- [ ] Query patterns checked against existing indexes (no full table scans)

---

## Summary
<!-- Brief description of what this migration does and why -->

## Test Plan
<!-- How you verified the migration works (local DB, SQL tests, etc.) -->
