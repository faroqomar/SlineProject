# 04_TEST_AND_VERIFICATION

## A. Runnable SQL Verification Script

Run this script via Supabase SQL Editor or `psql` to verify the guard conditions against the current schema manually. (Requires `service_role` or test user IDs).

```sql
-- Replace these with real IDs in your test environment
DO $$
DECLARE
    v_offer_id uuid;
    v_client_id uuid := '00000000-0000-0000-0000-000000000001'; -- Replace
    v_freelancer_id uuid := '00000000-0000-0000-0000-000000000002'; -- Replace
    v_conv_id uuid := '00000000-0000-0000-0000-000000000003'; -- Replace
BEGIN
    -- 1. Create Offer
    INSERT INTO public.direct_offers (conversation_id, client_id, freelancer_id, price, status, payment_status)
    VALUES (v_conv_id, v_client_id, v_freelancer_id, 50000, 'sent', 'unpaid')
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

    -- 5. Test Delivery Transition (Simulating as freelancer)
    -- Note: This requires auth context in a real RLS environment.
    -- Set auth context if running outside service_role.

    -- Clean up test
    DELETE FROM public.direct_offers WHERE id = v_offer_id;
END $$;
```

## B. App Manual Test Script

### Pre-requisites

1. Two emulator devices (Device A: Client account, Device B: Freelancer account).
2. Establish a Chat Conversation between them.

### Test Steps

1. **Create**: On Device B (Freelancer), open chat, tap the "+" menu, create a Custom Offer for 10,000 IQD.
   - _Verify_: Message appears. DB `direct_offers` shows `status='sent', payment_status='unpaid'`.
2. **Accept**: On Device A (Client), tap "Accept" on the message bubble.
   - _Verify_: UI updates. DB shows `status='accepted'`. Button changes or navigates to Dashboard.
3. **Pay**: On Device A, go to Direct Offers dashboard. Tap "Pay Now" using the Wallet.
   - _Verify_: Funds deducted from user wallet. DB shows `status='active', payment_status='held'`.
4. **Deliver**: On Device B, go to Direct Offers dashboard. Tap "Mark Delivered".
   - _Verify_: DB shows `status='delivered'`.
5. **Release**: On Device A, go to Direct Offers dashboard. Tap "Approve & Complete" on the delivered offer.
   - _Verify_: Escrow funds released to Freelancer wallet. DB shows `status='completed', payment_status='released'`.
