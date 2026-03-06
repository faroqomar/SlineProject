-- ============================================================================
-- Migration: Patch process_payment_event_ledger for fee locking
-- Phase: 3.0 RPC Patching - Add fee locking to escrow_hold and release_with_fee
-- Date: 2026-03-07
-- Depends: 20260307_01, 02, 03, 04, 05, 06, 07
-- WARNING: This patches a critical financial function. Test thoroughly!
-- ============================================================================

-- NOTE: This migration requires careful implementation.
-- The full function body is large. Below is the PSEUDOCODE for the key changes.
-- Actual implementation requires replacing the entire function.

/*

PSEUDOCODE for process_payment_event_ledger modifications:

=== ESCROW_HOLD BLOCK (around line 111 in original) ===

OLD CODE (vulnerable):
    -- No fee rate handling
    -- Just updates payment_status to 'held'

NEW CODE (with fee locking):
    -- Check feature flag
    IF (SELECT value->>'value' FROM platform_settings WHERE key = 'fee_locking_enabled') = 'true' THEN
        -- Read global fee rate
        SELECT (value->>'value')::INTEGER INTO v_fee_rate_bps
        FROM platform_settings 
        WHERE key = 'fee_rate_default_bps';
        
        -- Validate against max
        SELECT LEAST(v_fee_rate_bps, (value->>'value')::INTEGER)
        INTO v_fee_rate_bps
        FROM platform_settings 
        WHERE key = 'max_fee_rate_bps';
        
        -- Write locked rate to entity
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings 
            SET fee_rate_applied_bps = v_fee_rate_bps
            WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            UPDATE public.direct_offers 
            SET fee_rate_applied_bps = v_fee_rate_bps
            WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests 
            SET fee_rate_applied_bps = v_fee_rate_bps
            WHERE id = p_related_entity_id;
        END IF;
        
        -- Log in journal meta
        v_new_meta := jsonb_set(COALESCE(p_meta, '{}'), '{fee_rate_applied_bps}', to_jsonb(v_fee_rate_bps));
    ELSE
        -- Legacy mode: no fee locking
        v_new_meta := p_meta;
    END IF;

=== RELEASE_WITH_FEE BLOCK (around line 290 in original) ===

OLD CODE (vulnerable - line 339):
    v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);
    -- Client can spoof any fee rate!

NEW CODE (secure - with fee locking):
    -- Check feature flag
    IF (SELECT value->>'value' FROM platform_settings WHERE key = 'fee_locking_enabled') = 'true' THEN
        -- Read locked rate from entity (ignore p_meta for clients)
        IF p_related_entity_type = 'booking' THEN
            SELECT fee_rate_applied_bps, amount_gross 
            INTO v_fee_rate_bps, v_entity_amount_gross
            FROM public.bookings 
            WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            SELECT fee_rate_applied_bps, price 
            INTO v_fee_rate_bps, v_entity_amount_gross
            FROM public.direct_offers 
            WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            SELECT fee_rate_applied_bps, amount_gross 
            INTO v_fee_rate_bps, v_entity_amount_gross
            FROM public.task_requests 
            WHERE id = p_related_entity_id;
        END IF;
        
        -- Validate fee is locked
        IF v_fee_rate_bps IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_FEE_RATE_NOT_LOCKED',
                    'message', 'Fee rate not locked for this entity. Escrow may not have completed properly.'
                )
            );
        END IF;
        
        -- Admin override: only if actor is admin
        IF v_actor_user_id IN (SELECT user_id FROM admin_users) 
           AND p_meta ? 'fee_rate_bps' THEN
            v_fee_rate_bps := (p_meta->>'fee_rate_bps')::INTEGER;
        END IF;
        
        -- Calculate fee and net
        v_fee_amount := FLOOR(v_entity_amount_gross * v_fee_rate_bps / 10000);
        v_net_amount := v_entity_amount_gross - v_fee_amount;
        
        -- Store calculations
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings 
            SET fee_amount = v_fee_amount, net_amount = v_net_amount
            WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            UPDATE public.direct_offers 
            SET fee_amount = v_fee_amount, net_amount = v_net_amount
            WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests 
            SET fee_amount = v_fee_amount, net_amount = v_net_amount
            WHERE id = p_related_entity_id;
        END IF;
    ELSE
        -- Legacy mode: use hardcoded 1000 bps (old behavior)
        v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);
        v_fee_amount := FLOOR(v_entity_amount_gross * v_fee_rate_bps / 10000);
        v_net_amount := v_entity_amount_gross - v_fee_amount;
    END IF;

*/

-- This migration is a PLACEHOLDER
-- The actual implementation requires:
-- 1. Full function recreation (the function is 1000+ lines)
-- 2. Careful testing in staging
-- 3. Feature flag protection (already in place)

-- For now, document the required changes:
DO $$
BEGIN
    RAISE NOTICE '⚠️ RPC PATCH PLACEHOLDER';
    RAISE NOTICE 'This migration requires manual implementation of the patched RPC.';
    RAISE NOTICE 'Key changes needed:';
    RAISE NOTICE '  1. escrow_hold: Add fee rate locking logic';
    RAISE NOTICE '  2. release_with_fee: Read locked rate, ignore p_meta for clients';
    RAISE NOTICE '  3. Feature flag check: fee_locking_enabled';
    RAISE NOTICE '  4. Admin override: Allow admin actors to override via p_meta';
    RAISE NOTICE '';
    RAISE NOTICE 'Implementation approach:';
    RAISE NOTICE '  - Create new function: process_payment_event_ledger_v2()';
    RAISE NOTICE '  - Test thoroughly in staging';
    RAISE NOTICE '  - Replace old function in production';
    RAISE NOTICE '  - Keep old function as backup: process_payment_event_ledger_backup()';
END $$;

-- TODO: Replace this placeholder with actual RPC patch once tested
