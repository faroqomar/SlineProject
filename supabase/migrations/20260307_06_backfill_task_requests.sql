-- ============================================================================
-- Migration: Backfill task_requests with default 10% fee rate
-- Phase: 2.3 Backfill - Populate fee columns
-- Date: 2026-03-07
-- Depends: 20260307_02_add_fee_columns.sql
-- ============================================================================

BEGIN;

-- Update all held/released task_requests
UPDATE public.task_requests 
SET 
    fee_rate_applied_bps = 1000,
    fee_amount = (proposed_price * 1000) / 10000,
    net_amount = proposed_price - ((proposed_price * 1000) / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Verification
DO $$
DECLARE
    v_remaining_null INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_remaining_null
    FROM public.task_requests
    WHERE payment_status IN ('held', 'released') 
      AND fee_rate_applied_bps IS NULL;
    
    RAISE NOTICE '✅ Task requests backfill complete. Remaining null: %', v_remaining_null;
END $$;

COMMIT;
