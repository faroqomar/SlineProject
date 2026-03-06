# Minimal Patch Plan: Dynamic Platform Fee

> **Status**: Required before any production deployment involving fee charging.

## Overview

This patch implements the "Lock at Escrow" strategy in 3 atomic steps. Each step is a single migration. All are non-breaking (ADD COLUMN, INSERT row, or ALTER FUNCTION).

---

## Step 1: Seed Fee Config Row

**Migration name**: `YYYYMMDD_seed_platform_fee_config.sql`

```sql
-- Seed the platform fee rate in system_config
-- Uses the existing system_config table from 20260310101000
INSERT INTO public.system_config (key, value, description)
VALUES (
  'platform_fee',
  '{"fee_rate_bps": 1000}'::jsonb,
  'Default platform commission in basis points (1000 = 10%)'
)
ON CONFLICT (key) DO NOTHING;
```

### Verification query:

```sql
SELECT key, value FROM public.system_config WHERE key = 'platform_fee';
-- Expected: {"fee_rate_bps": 1000}
```

---

## Step 2: Add Fee Columns to Entities

**Migration name**: `YYYYMMDD_add_fee_columns_to_entities.sql`

```sql
-- Add fee-locking columns to bookings
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS fee_rate_applied_bps INTEGER,
  ADD COLUMN IF NOT EXISTS fee_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS net_amount NUMERIC;

-- Add fee-locking columns to direct_offers
ALTER TABLE public.direct_offers
  ADD COLUMN IF NOT EXISTS fee_rate_applied_bps INTEGER,
  ADD COLUMN IF NOT EXISTS fee_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS net_amount NUMERIC;

-- Add fee-locking columns to task_requests
ALTER TABLE public.task_requests
  ADD COLUMN IF NOT EXISTS fee_rate_applied_bps INTEGER,
  ADD COLUMN IF NOT EXISTS fee_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS net_amount NUMERIC;

-- Backfill: set existing completed/released entities to the legacy 10% rate
UPDATE public.bookings
SET fee_rate_applied_bps = 1000,
    fee_amount = FLOOR(price * 1000 / 10000),
    net_amount = price - FLOOR(price * 1000 / 10000)
WHERE payment_status = 'released'
  AND fee_rate_applied_bps IS NULL;

UPDATE public.direct_offers
SET fee_rate_applied_bps = 1000,
    fee_amount = FLOOR(price * 1000 / 10000),
    net_amount = price - FLOOR(price * 1000 / 10000)
WHERE payment_status = 'released'
  AND fee_rate_applied_bps IS NULL;

-- Immutability constraint: prevent fee_rate_applied_bps changes after lock
CREATE OR REPLACE FUNCTION public.trg_immutable_fee_rate()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.fee_rate_applied_bps IS NOT NULL
     AND NEW.fee_rate_applied_bps IS DISTINCT FROM OLD.fee_rate_applied_bps THEN
    RAISE EXCEPTION 'fee_rate_applied_bps is immutable once set (current: %, attempted: %)',
      OLD.fee_rate_applied_bps, NEW.fee_rate_applied_bps;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bookings_immutable_fee
  BEFORE UPDATE OF fee_rate_applied_bps ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.trg_immutable_fee_rate();

CREATE TRIGGER trg_direct_offers_immutable_fee
  BEFORE UPDATE OF fee_rate_applied_bps ON public.direct_offers
  FOR EACH ROW EXECUTE FUNCTION public.trg_immutable_fee_rate();

CREATE TRIGGER trg_task_requests_immutable_fee
  BEFORE UPDATE OF fee_rate_applied_bps ON public.task_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_immutable_fee_rate();
```

### Verification queries:

```sql
-- Confirm columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='public' AND table_name='bookings'
  AND column_name IN ('fee_rate_applied_bps','fee_amount','net_amount');
-- Expected: 3 rows

-- Confirm backfill
SELECT COUNT(*) as backfilled
FROM public.bookings
WHERE payment_status = 'released' AND fee_rate_applied_bps = 1000;

-- Confirm immutability trigger
SELECT trigger_name FROM information_schema.triggers
WHERE event_object_table = 'bookings' AND trigger_name = 'trg_bookings_immutable_fee';
```

---

## Step 3: Patch `process_payment_event_ledger` RPC

**Migration name**: `YYYYMMDD_lock_fee_in_ledger_rpc.sql`

### 3a. Patch `escrow_hold` — Lock fee at escrow time

After the entity status update block (around line 256), add fee locking:

```sql
-- Read current fee rate from system_config
SELECT (value->>'fee_rate_bps')::INTEGER INTO v_fee_rate_bps
FROM public.system_config WHERE key = 'platform_fee';

-- Fallback to 1000 bps (10%) if not configured (safety net, should always be set)
v_fee_rate_bps := COALESCE(v_fee_rate_bps, 1000);

-- Lock the fee rate to the entity
IF p_related_entity_type = 'booking' THEN
    UPDATE public.bookings SET fee_rate_applied_bps = v_fee_rate_bps WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'task_request' THEN
    UPDATE public.task_requests SET fee_rate_applied_bps = v_fee_rate_bps WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'direct_offer' THEN
    UPDATE public.direct_offers SET fee_rate_applied_bps = v_fee_rate_bps WHERE id = p_related_entity_id;
END IF;
```

### 3b. Patch `release_with_fee` — Use locked rate, ignore meta

**Replace line 350:**

```sql
-- BEFORE:
v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);

-- AFTER:
-- Read the locked fee rate from the entity
IF p_related_entity_type = 'booking' THEN
    SELECT fee_rate_applied_bps INTO v_fee_rate_bps FROM public.bookings WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'task_request' THEN
    SELECT fee_rate_applied_bps INTO v_fee_rate_bps FROM public.task_requests WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'direct_offer' THEN
    SELECT fee_rate_applied_bps INTO v_fee_rate_bps FROM public.direct_offers WHERE id = p_related_entity_id;
END IF;

IF v_fee_rate_bps IS NULL THEN
    RETURN jsonb_build_object(
        'ok', false,
        'error', jsonb_build_object(
            'code', 'ERR_FEE_NOT_LOCKED',
            'message', 'Fee rate was not locked at escrow. Cannot release funds.'
        )
    );
END IF;
```

### 3c. Store calculated amounts on entity

After the ledger lines insert (around line 390), add:

```sql
IF p_related_entity_type = 'booking' THEN
    UPDATE public.bookings
    SET fee_amount = v_fee_amount, net_amount = v_net_amount,
        payment_status = 'released'::public.payment_status_enum,
        status = 'completed'::public.booking_status_enum
    WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'direct_offer' THEN
    UPDATE public.direct_offers
    SET fee_amount = v_fee_amount, net_amount = v_net_amount,
        payment_status = 'released'::public.payment_status_enum,
        status = 'completed'
    WHERE id = p_related_entity_id;
ELSIF p_related_entity_type = 'task_request' THEN
    UPDATE public.task_requests
    SET fee_amount = v_fee_amount, net_amount = v_net_amount,
        payment_status = 'released',
        status = 'completed'
    WHERE id = p_related_entity_id;
END IF;
```

---

## Integration Test Script

```sql
-- 1. Set fee to 12%
SELECT admin_update_system_config('platform_fee', '{"fee_rate_bps": 1200}'::jsonb, '<admin_uuid>');

-- 2. Create booking, set to pending/unpaid
-- (Test data setup omitted for brevity — use existing test booking)

-- 3. Escrow as client
SELECT process_payment_event_ledger(
  'escrow_hold', 'booking', '<booking_id>', 'test_lock_1', NULL, 'IQD', '{}'
);

-- 4. Verify fee locked
SELECT fee_rate_applied_bps FROM public.bookings WHERE id = '<booking_id>';
-- Expected: 1200

-- 5. Change global fee to 15%
SELECT admin_update_system_config('platform_fee', '{"fee_rate_bps": 1500}'::jsonb, '<admin_uuid>');

-- 6. Move booking to delivered (simulate provider delivery)
UPDATE public.bookings SET status = 'delivered' WHERE id = '<booking_id>';

-- 7. Release as client WITH spoofed meta (should be ignored)
SELECT process_payment_event_ledger(
  'release_with_fee', 'booking', '<booking_id>', 'test_release_1', NULL, 'IQD', '{"fee_rate_bps": 0}'
);

-- 8. Verify amounts
SELECT price, fee_rate_applied_bps, fee_amount, net_amount FROM public.bookings WHERE id = '<booking_id>';
-- Expected: fee_rate_applied_bps=1200, fee_amount=FLOOR(price*1200/10000), net_amount=price-fee_amount

-- 9. Verify ledger balance
SELECT SUM(CASE WHEN direction='DEBIT' THEN amount ELSE -amount END) AS net_balance
FROM public.ledger_lines ll
JOIN public.journal_entries je ON ll.journal_entry_id = je.id
WHERE je.related_entity_id = '<booking_id>'
  AND je.event_type = 'release_with_fee';
-- Expected: 0
```
