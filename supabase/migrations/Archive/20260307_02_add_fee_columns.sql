-- ============================================================================
-- Migration: Add fee columns to bookings, direct_offers, task_requests
-- Phase: 1.1 Schema - Add fee columns
-- Date: 2026-03-07
-- Depends: None (additive columns)
-- ============================================================================

BEGIN;

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
COMMENT ON COLUMN public.bookings.fee_rate_applied_bps IS 'Locked fee rate in basis points (1000 = 10%). Set at escrow time. Immutable after lock.';
COMMENT ON COLUMN public.bookings.fee_amount IS 'Calculated platform fee in IQD. Set at release time.';
COMMENT ON COLUMN public.bookings.net_amount IS 'Net amount to freelancer in IQD. Set at release time.';

COMMENT ON COLUMN public.direct_offers.fee_rate_applied_bps IS 'Locked fee rate in basis points. Set at escrow time.';
COMMENT ON COLUMN public.direct_offers.fee_amount IS 'Calculated platform fee in IQD.';
COMMENT ON COLUMN public.direct_offers.net_amount IS 'Net amount to freelancer in IQD.';

COMMENT ON COLUMN public.task_requests.fee_rate_applied_bps IS 'Locked fee rate in basis points. Set at escrow time.';
COMMENT ON COLUMN public.task_requests.fee_amount IS 'Calculated platform fee in IQD.';
COMMENT ON COLUMN public.task_requests.net_amount IS 'Net amount to freelancer in IQD.';

-- Log migration completion
DO $$
BEGIN
    RAISE NOTICE '✅ Fee columns added to bookings, direct_offers, task_requests';
END $$;

COMMIT;
