-- ============================================================================
-- Migration: Verify backfill completeness
-- Phase: 2.4 Verification - Ensure all held/released entities have fee data
-- Date: 2026-03-07
-- Depends: 20260307_04, 05, 06 (backfills)
-- ============================================================================

-- Master verification query
-- All counts must be 0 before proceeding to Phase 3

SELECT 
    'bookings' as table_name, 
    COUNT(*) as null_count,
    'MUST BE 0' as requirement
FROM public.bookings 
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL
UNION ALL
SELECT 
    'direct_offers', 
    COUNT(*),
    'MUST BE 0'
FROM public.direct_offers
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL
UNION ALL
SELECT 
    'task_requests', 
    COUNT(*),
    'MUST BE 0'
FROM public.task_requests  
WHERE payment_status IN ('held', 'released') 
  AND fee_rate_applied_bps IS NULL
ORDER BY table_name;

-- Summary: All null_count values must be 0
-- If any are > 0, DO NOT proceed to Phase 3
