-- ============================================================================
-- Migration: Create immutability trigger for fee_rate_applied_bps
-- Phase: 1.3 Triggers - Protect locked fee rates
-- Date: 2026-03-07
-- Depends: 20260307_02_add_fee_columns.sql
-- ============================================================================

BEGIN;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for all three tables
-- Initially disabled - will be enabled in Phase 3 after backfill

-- Bookings trigger
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied_bookings ON public.bookings;
CREATE TRIGGER trg_protect_fee_rate_applied_bookings
BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();

-- Direct offers trigger
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied_direct_offers ON public.direct_offers;
CREATE TRIGGER trg_protect_fee_rate_applied_direct_offers
BEFORE UPDATE ON public.direct_offers
FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();

-- Task requests trigger
DROP TRIGGER IF EXISTS trg_protect_fee_rate_applied_task_requests ON public.task_requests;
CREATE TRIGGER trg_protect_fee_rate_applied_task_requests
BEFORE UPDATE ON public.task_requests
FOR EACH ROW EXECUTE FUNCTION fn_protect_fee_rate_applied();

-- Disable initially (will be enabled in Phase 3)
ALTER TABLE public.bookings DISABLE TRIGGER trg_protect_fee_rate_applied_bookings;
ALTER TABLE public.direct_offers DISABLE TRIGGER trg_protect_fee_rate_applied_direct_offers;
ALTER TABLE public.task_requests DISABLE TRIGGER trg_protect_fee_rate_applied_task_requests;

-- Log migration completion
DO $$
BEGIN
    RAISE NOTICE '✅ Immutability triggers created (disabled until Phase 3)';
END $$;

COMMIT;
