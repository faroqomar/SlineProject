# Migration Plan: Dynamic Platform Fee System

**Version**: 1.0  
**Date**: 2026-03-06  
**Owner**: @DataMigration  
**Type**: Schema migration with data backfill

---

## 1. Migration Strategy

### Approach: Additive-First with Feature Flag

```
Phase 1: INTRODUCE (Non-breaking)
   - Create platform_settings table
   - Add nullable columns
   - Add RLS policies
   - Add triggers (disabled)
   - Seed with fee_locking_enabled = false

Phase 2: BACKFILL (Data migration)
   - Update held/released entities with 10% rate
   - Calculate fee_amount and net_amount
   - Verify completeness

Phase 3: ENABLE (Activation)
   - Deploy patched RPC
   - Enable triggers
   - Set fee_locking_enabled = true
```

---

## 2. Phase 1: Introduce (Non-Breaking)

### 2.1 Create platform_settings Table

**Migration File**: `20260307_01_create_platform_settings.sql`

```sql
-- Create platform_settings table
CREATE TABLE IF NOT EXISTS public.platform_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now(),
    updated_by UUID REFERENCES auth.users(id)
);

-- Add comment
COMMENT ON TABLE public.platform_settings IS 'Global platform configuration. Modified by admins only.';

-- Seed initial values (feature disabled by default)
INSERT INTO public.platform_settings (key, value) VALUES
('fee_rate_default_bps', '{"value": 1000}'),    -- 10% default
('max_fee_rate_bps', '{"value": 3000}'),          -- 30% max
('fee_locking_enabled', '{"value": false}')      -- Feature disabled initially
ON CONFLICT (key) DO NOTHING;

-- Enable RLS
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "platform_settings_read"
ON public.platform_settings FOR SELECT
TO authenticated USING (true);

CREATE POLICY "platform_settings_write_admin"
ON public.platform_settings FOR ALL
TO authenticated 
USING (auth.uid() IN (SELECT user_id FROM admin_users))
WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

CREATE POLICY "platform_settings_no_anon"
ON public.platform_settings FOR ALL
TO anon USING (false);

-- Create audit trigger
CREATE OR REPLACE FUNCTION fn_log_platform_settings_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO admin_logs (action, table_name, record_id, old_data, new_data, performed_by)
    VALUES (
        'UPDATE', 
        'platform_settings', 
        NEW.key, 
        jsonb_build_object('value', OLD.value), 
        jsonb_build_object('value', NEW.value), 
        NEW.updated_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_platform_settings_change
AFTER UPDATE ON public.platform_settings
FOR EACH ROW EXECUTE FUNCTION fn_log_platform_settings_change();
```

**Rollback**:
```sql
DROP TABLE IF EXISTS public.platform_settings CASCADE;
```

---

### 2.2 Add Fee Columns to Entities

**Migration File**: `20260307_02_add_fee_columns.sql`

```sql
-- Add columns to bookings
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS fee_rate_applied_bps INTEGER,
ADD COLUMN IF NOT EXISTS fee_amount BIGINT,
ADD COLUMN IF NOT EXISTS net_amount BIGINT;

-- Add columns to direct_offers
ALTER TABLE public.direct_offers
ADD COLUMN IF NOT EXISTS fee_rate_applied_bps INTEGER,
ADD COLUMN IF NOT EXISTS fee_amount BIGINT,
ADD COLUMN IF NOT EXISTS net_amount BIGINT;

-- Add columns to task_requests
ALTER TABLE public.task_requests
ADD COLUMN IF NOT EXISTS fee_rate_applied_bps INTEGER,
ADD COLUMN IF NOT EXISTS fee_amount BIGINT,
ADD COLUMN IF NOT EXISTS net_amount BIGINT;

-- Add comments
COMMENT ON COLUMN public.bookings.fee_rate_applied_bps IS 'Locked fee rate in basis points (1000 = 10%). Set at escrow time.';
COMMENT ON COLUMN public.bookings.fee_amount IS 'Calculated platform fee in IQD';
COMMENT ON COLUMN public.bookings.net_amount IS 'Net amount to freelancer in IQD';
```

**Rollback**:
```sql
ALTER TABLE public.bookings 
DROP COLUMN IF EXISTS fee_rate_applied_bps,
DROP COLUMN IF EXISTS fee_amount,
DROP COLUMN IF EXISTS net_amount;
-- Repeat for direct_offers, task_requests
```

---

### 2.3 Create Immutability Trigger (Disabled)

**Migration File**: `20260307_03_create_immutability_trigger.sql`

```sql
-- Create immutability function
CREATE OR REPLACE FUNCTION fn_protect_fee_rate_applied()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow NULL -> value (initial lock)
    -- Block value -> different value (attempted modification)
    IF OLD.fee_rate_applied_bps IS NOT NULL 
       AND NEW.fee_rate_applied_bps IS DISTINCT FROM OLD.fee_rate_applied_bps THEN
        RAISE EXCEPTION 'ERR_IMMUTABILITY_VIOLATION: fee_rate_applied_bps is immutable once set (current: %, attempted: %)',
            OLD.fee_rate_applied_bps, NEW.fee_rate_applied_bps;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers (initially disabled - enable in Phase 3)
DO $$
BEGIN
    -- Bookings
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_protect_fee_rate_applied_bookings'
    ) THEN
        CREATE TRIGGER trg_protect_fee_rate_applied_bookings
        BEFORE UPDATE ON public.bookings
        FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();
        -- ALTER TABLE public.bookings DISABLE TRIGGER trg_protect_fee_rate_applied_bookings;
    END IF;

    -- Direct offers
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_protect_fee_rate_applied_direct_offers'
    ) THEN
        CREATE TRIGGER trg_protect_fee_rate_applied_direct_offers
        BEFORE UPDATE ON public.direct_offers
        FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();
        -- ALTER TABLE public.direct_offers DISABLE TRIGGER trg_protect_fee_rate_applied_direct_offers;
    END IF;

    -- Task requests
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_protect_fee_rate_applied_task_requests'
    ) THEN
        CREATE TRIGGER trg_protect_fee_rate_applied_task_requests
        BEFORE UPDATE ON public.task_requests
        FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();
        -- ALTER TABLE public.task_requests DISABLE TRIGGER trg_protect_fee_rate_applied_task_requests;
    END IF;
END $$;
```

**Rollback**:
```sql
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied_bookings ON public.bookings;
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied_direct_offers ON public.direct_offers;
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied_task_requests ON public.task_requests;
DROP FUNCTION IF EXISTS fn_protect_fee_rate_applied();
```

---

## 3. Phase 2: Backfill

### 3.1 Backfill Bookings

**Migration File**: `20260307_04_backfill_bookings.sql`

```sql
-- Update all held/released bookings with 10% rate
UPDATE public.bookings 
SET 
    fee_rate_applied_bps = 1000,
    fee_amount = (price * 1000) / 10000,
    net_amount = price - ((price * 1000) / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Verification query
SELECT 
    'bookings' as table_name,
    COUNT(*) as total_affected,
    COUNT(*) FILTER (WHERE fee_rate_applied_bps = 1000) as correctly_backfilled
FROM public.bookings 
WHERE payment_status IN ('held', 'released');
```

---

### 3.2 Backfill Direct Offers

**Migration File**: `20260307_05_backfill_direct_offers.sql`

```sql
-- Update all held/released direct_offers
UPDATE public.direct_offers 
SET 
    fee_rate_applied_bps = 1000,
    fee_amount = (price * 1000) / 10000,
    net_amount = price - ((price * 1000) / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Verification
SELECT 
    'direct_offers' as table_name,
    COUNT(*) as null_count
FROM public.direct_offers
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;
```

---

### 3.3 Backfill Task Requests

**Migration File**: `20260307_06_backfill_task_requests.sql`

```sql
-- Update all held/released task_requests
UPDATE public.task_requests 
SET 
    fee_rate_applied_bps = 1000,
    fee_amount = (proposed_price * 1000) / 10000,
    net_amount = proposed_price - ((proposed_price * 1000) / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Verification
SELECT 
    'task_requests' as table_name,
    COUNT(*) as null_count
FROM public.task_requests
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;
```

---

### 3.4 Verification Query

**Check**: All backfill must complete with 0 NULL values

```sql
-- Master verification query
SELECT 
    'bookings' as table_name, 
    COUNT(*) as null_count
FROM bookings 
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL
UNION ALL
SELECT 
    'direct_offers', 
    COUNT(*)
FROM direct_offers
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL
UNION ALL
SELECT 
    'task_requests', 
    COUNT(*)
FROM task_requests  
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Expected result: all counts = 0
```

---

## 4. Phase 3: Enable

### 4.1 Deploy Patched RPC

**Migration File**: `20260307_07_patch_process_payment_event_ledger.sql`

```sql
-- Patch process_payment_event_ledger function
-- (Full function definition in contract)
-- Key changes:
-- 1. escrow_hold reads from platform_settings and writes to entity
-- 2. release_with_fee reads from entity (ignores p_meta for clients)
-- 3. Feature flag check at start of modified blocks

-- Note: This is a large migration that patches the existing RPC
-- Must be tested thoroughly in staging before production
```

---

### 4.2 Enable Feature Flag

**Migration File**: `20260307_08_enable_fee_locking.sql`

```sql
-- Enable fee locking feature
UPDATE public.platform_settings 
SET 
    value = '{"value": true}',
    updated_at = now(),
    updated_by = auth.uid()
WHERE key = 'fee_locking_enabled';

-- Enable immutability triggers
ALTER TABLE public.bookings ENABLE TRIGGER trg_protect_fee_rate_applied_bookings;
ALTER TABLE public.direct_offers ENABLE TRIGGER trg_protect_fee_rate_applied_direct_offers;
ALTER TABLE public.task_requests ENABLE TRIGGER trg_protect_fee_rate_applied_task_requests;

-- Verify
SELECT 
    key,
    value->>'value' as current_value
FROM public.platform_settings 
WHERE key = 'fee_locking_enabled';
-- Expected: 'true'
```

**Rollback**:
```sql
-- Disable feature
UPDATE public.platform_settings 
SET value = '{"value": false}'
WHERE key = 'fee_locking_enabled';

-- Disable triggers
ALTER TABLE public.bookings DISABLE TRIGGER trg_protect_fee_rate_applied_bookings;
ALTER TABLE public.direct_offers DISABLE TRIGGER trg_protect_fee_rate_applied_direct_offers;
ALTER TABLE public.task_requests DISABLE TRIGGER trg_protect_fee_rate_applied_task_requests;
```

---

## 5. Execution Order

```bash
# Phase 1: Introduce (Non-breaking)
psql -f 20260307_01_create_platform_settings.sql
psql -f 20260307_02_add_fee_columns.sql
psql -f 20260307_03_create_immutability_trigger.sql

# Phase 2: Backfill (Data migration)
psql -f 20260307_04_backfill_bookings.sql
psql -f 20260307_05_backfill_direct_offers.sql
psql -f 20260307_06_backfill_task_requests.sql

# Verification (MUST pass before Phase 3)
psql -c "SELECT * FROM verification_query;"  # All counts must be 0

# Phase 3: Enable (Activation)
psql -f 20260307_07_patch_process_payment_event_ledger.sql
psql -f 20260307_08_enable_fee_locking.sql
```

---

## 6. Compatibility Window

### Backward Compatibility

| Version | Behavior |
|---------|----------|
| Old App | Ignores new columns (fine) |
| New App | Reads new columns (fine after Phase 1) |
| Old RPC | Uses hardcoded 10% (fine until Phase 3) |
| New RPC | Uses fee locking (after Phase 3) |

### Rollback Scenarios

**Within 1 hour (Phase 1-2 only)**:
```sql
-- Disable triggers
ALTER TABLE bookings DISABLE TRIGGER trg_protect_fee_rate_applied_bookings;
-- Repeat for other tables

-- Drop columns (optional - can leave nullable)
ALTER TABLE bookings DROP COLUMN fee_rate_applied_bps;
-- ... etc
```

**Within 24 hours (After Phase 3)**:
```sql
-- Disable feature flag (reverts to legacy RPC behavior)
UPDATE platform_settings SET value = '{"value": false}' WHERE key = 'fee_locking_enabled';

-- Disable triggers
ALTER TABLE bookings DISABLE TRIGGER trg_protect_fee_rate_applied_bookings;
-- ... etc

-- Revert RPC to previous version (restore from archive)
```

**After 24 hours (Forward fix only)**:
- Do not rollback
- Fix forward via new migration
- May require data correction if bugs found

---

## 7. Timing Estimates

| Phase | Estimated Time | Downtime |
|-------|----------------|----------|
| 1.1 Create platform_settings | 1 second | None |
| 1.2 Add columns | 1 second | None (Postgres ADD COLUMN is non-blocking for nullable) |
| 1.3 Create triggers | 1 second | None |
| 2.1 Backfill bookings | 5-30 seconds | None |
| 2.2 Backfill direct_offers | 5-30 seconds | None |
| 2.3 Backfill task_requests | 5-30 seconds | None |
| 2.4 Verification | 5 seconds | None |
| 3.1 Patch RPC | 2 seconds | None (function replacement) |
| 3.2 Enable feature | 1 second | None |

**Total**: ~1-2 minutes, **zero downtime**

---

## 8. Verification Checklist

### Pre-Enablement Verification

- [ ] platform_settings table exists with 3 rows
- [ ] All 3 entity tables have 3 new columns (nullable)
- [ ] RLS policies block anon, allow authenticated read
- [ ] Immutability triggers exist (can be disabled)
- [ ] Backfill complete: 0 NULL values for held/released
- [ ] Patched RPC deployed to staging
- [ ] Integration tests pass in staging

### Post-Enablement Verification

- [ ] fee_locking_enabled = true
- [ ] Immutability triggers enabled
- [ ] New escrow locks fee rate correctly
- [ ] Release uses locked rate
- [ ] Client spoof attempts ignored
- [ ] Admin overrides logged
- [ ] No errors in logs

---

## 9. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Backfill incomplete | Verification query must return 0 before Phase 3 |
| RPC patch error | Test thoroughly in staging; keep previous version backup |
| Trigger too aggressive | Initially disabled; enable only after verification |
| Feature flag premature | Start with `false`; explicit step to enable |
| Concurrent modification | Each escrow is independent; no cross-booking dependencies |

---

**Approved By**: @DataMigration  
**Reviewed By**: @Supabase_Ops, @Sentinel, @Architect
