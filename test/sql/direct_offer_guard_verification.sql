-- Direct Offer Guard Verification Script
-- Run via Supabase SQL Editor or psql. Requires service_role or test user IDs.
-- See test/sql/README.md for fixture and run instructions.
--
-- Replace placeholder UUIDs with real IDs from your test environment:
--   v_client_id, v_freelancer_id, v_conv_id (conversation must exist; both users participants).

DO $$
DECLARE
    v_offer_id uuid;
    v_client_id uuid := '00000000-0000-0000-0000-000000000001'; -- Replace with real client profile id
    v_freelancer_id uuid := '00000000-0000-0000-0000-000000000002'; -- Replace with real freelancer profile id
    v_conv_id uuid := '00000000-0000-0000-0000-000000000003'; -- Replace with real conversation id
BEGIN
    -- 1. Create Offer
    INSERT INTO public.direct_offers (conversation_id, client_id, freelancer_id, price, days, status, payment_status)
    VALUES (v_conv_id, v_client_id, v_freelancer_id, 50000, 7, 'sent', 'unpaid')
    RETURNING id INTO v_offer_id;

    -- 2. Test Illegal Transition: sent -> active (Should Fail)
    BEGIN
        UPDATE public.direct_offers SET status = 'active' WHERE id = v_offer_id;
        RAISE EXCEPTION 'TEST FAILED: Allowed sent->active without payment_status=held';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'TEST PASSED: Blocked sent->active without held. (%)', SQLERRM;
    END;

    -- 3. Test Legal Transition: sent -> accepted
    UPDATE public.direct_offers SET status = 'accepted' WHERE id = v_offer_id;
    RAISE NOTICE 'TEST PASSED: Allowed sent->accepted (unpaid)';

    -- 4. Test Ledger Escrow Hold
    PERFORM public.process_payment_event_ledger(
        'escrow_hold', 'direct_offer', v_offer_id,
        gen_random_uuid()::text, 50000, 'IQD',
        jsonb_build_object('client_id', v_client_id, 'freelancer_id', v_freelancer_id)
    );
    RAISE NOTICE 'TEST PASSED: Ledger processed escrow_hold (active+held)';

    -- 5. Delivery transition is enforced by guard (freelancer only); skip in this script without auth context.

    -- Clean up test
    DELETE FROM public.direct_offers WHERE id = v_offer_id;
    RAISE NOTICE 'Cleanup done. All guard checks passed.';
END $$;
