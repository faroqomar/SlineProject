-- ============================================================================
-- Migration: Backfill bookings with default 10% fee rate
-- Phase: 2.1 Backfill - Populate fee columns for existing data
-- Date: 2026-03-07
-- Depends: 20260307_02_add_fee_columns.sql
-- ============================================================================

BEGIN;

-- Update all held/released bookings with 10% rate
-- Using FLOOR() as per contract for explicit truncation
UPDATE public.bookings 
SET 
    fee_rate_applied_bps = 1000,
    fee_amount = FLOOR(price * 1000 / 10000),
    net_amount = price - FLOOR(price * 1000 / 10000)
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL;

-- Verification: Report backfill results
DO $$
DECLARE
    v_total_affected INTEGER;
    v_correctly_backfilled INTEGER;
    v_remaining_null INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total_affected
    FROM public.bookings 
    WHERE payment_status IN ('held', 'released');
    
    SELECT COUNT(*) INTO v_correctly_backfilled
    FROM public.bookings 
    WHERE payment_status IN ('held', 'released')
      AND fee_rate_applied_bps = 1000;
    
    SELECT COUNT(*) INTO v_remaining_null
    FROM public.bookings 
    WHERE payment_status IN ('held', 'released') 
      AND fee_rate_applied_bps IS NULL;
    
    RAISE NOTICE '✅ Bookings backfill complete: % total, % backfilled, % remaining null',
        v_total_affected, v_correctly_backfilled, v_remaining_null;
        
    IF v_remaining_null > 0 THEN
        RAISE WARNING '⚠️ % bookings still have NULL fee_rate_applied_bps', v_remaining_null;
    END IF;
END $$;

COMMIT;
