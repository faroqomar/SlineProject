-- ============================================================================
-- Migration: Enable fee locking feature
-- Phase: 3.2 Enable - Activate the fee locking system
-- Date: 2026-03-07
-- Depends: All previous migrations, RPC patch applied and tested
-- WARNING: Only run after verification queries return 0
-- ============================================================================

BEGIN;

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

-- Verify enablement
DO $$
DECLARE
    v_feature_enabled BOOLEAN;
    v_bookings_trigger_enabled BOOLEAN;
    v_direct_offers_trigger_enabled BOOLEAN;
    v_task_requests_trigger_enabled BOOLEAN;
BEGIN
    -- Check feature flag
    SELECT (value->>'value')::BOOLEAN INTO v_feature_enabled
    FROM public.platform_settings 
    WHERE key = 'fee_locking_enabled';
    
    -- Check trigger status
    SELECT tgenabled INTO v_bookings_trigger_enabled
    FROM pg_trigger 
    WHERE tgname = 'trg_protect_fee_rate_applied_bookings';
    
    SELECT tgenabled INTO v_direct_offers_trigger_enabled
    FROM pg_trigger 
    WHERE tgname = 'trg_protect_fee_rate_applied_direct_offers';
    
    SELECT tgenabled INTO v_task_requests_trigger_enabled
    FROM pg_trigger 
    WHERE tgname = 'trg_protect_fee_rate_applied_task_requests';
    
    RAISE NOTICE '✅ Fee locking feature enabled:';
    RAISE NOTICE '  Feature flag: %', CASE WHEN v_feature_enabled THEN 'ENABLED' ELSE 'DISABLED' END;
    RAISE NOTICE '  Bookings trigger: %', CASE WHEN v_bookings_trigger_enabled THEN 'ENABLED' ELSE 'DISABLED' END;
    RAISE NOTICE '  Direct offers trigger: %', CASE WHEN v_direct_offers_trigger_enabled THEN 'ENABLED' ELSE 'DISABLED' END;
    RAISE NOTICE '  Task requests trigger: %', CASE WHEN v_task_requests_trigger_enabled THEN 'ENABLED' ELSE 'DISABLED' END;
    
    IF NOT v_feature_enabled THEN
        RAISE EXCEPTION 'Feature flag not enabled!';
    END IF;
    
    IF NOT (v_bookings_trigger_enabled AND v_direct_offers_trigger_enabled AND v_task_requests_trigger_enabled) THEN
        RAISE WARNING 'Some triggers not enabled!';
    END IF;
END $$;

COMMIT;

-- Post-enablement verification query
-- Run this after commit to confirm everything is working:
/*
SELECT 
    key,
    value->>'value' as current_value,
    updated_at,
    updated_by
FROM public.platform_settings 
WHERE key = 'fee_locking_enabled';

-- Expected result:
-- key                  | current_value | updated_at           | updated_by
-- fee_locking_enabled  | true          | 2026-03-07...        | <admin_user_id>
*/
