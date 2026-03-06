-- ============================================================================
-- Migration: Backfill direct_offers with default 10% fee rate
-- Phase: 2.2 Backfill - Populate fee columns
-- Date: 2026-03-07
-- Depends: 20260307_02_add_fee_columns.sql
-- ============================================================================

BEGIN;

-- Update all held/released direct_offers
UPDATE public.direct_offers 
SET 
    fee_rate_applied_bps = 1000,
    fee_amount = (price * 1000) / 10000,
    net_amount = price - ((price * 1000) / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Verification
DO $$
DECLARE
    v_remaining_null INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_remaining_null
    FROM public.direct_offers
    WHERE payment_status IN ('held', 'released') 
      AND fee_rate_applied_bps IS NULL;
    
    RAISE NOTICE '✅ Direct offers backfill complete. Remaining null: %', v_remaining_null;
END $$;

COMMIT;
