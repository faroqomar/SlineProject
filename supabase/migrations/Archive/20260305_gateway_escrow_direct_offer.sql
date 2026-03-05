-- Gateway escrow for direct offers (QiCard flow).
-- After QiCard payment success, the edge function calls process_gateway_escrow_direct_offer
-- to lock funds and set the offer to active.

CREATE OR REPLACE FUNCTION public.process_gateway_escrow_direct_offer(
    p_offer_id uuid,
    p_amount_gross numeric DEFAULT NULL,
    p_currency text DEFAULT 'IQD',
    p_idempotency_key text DEFAULT NULL,
    p_meta jsonb DEFAULT '{}'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_offer record;
    v_client_id uuid;
    v_freelancer_id uuid;
    v_amount numeric;
    v_platform_escrow_id uuid;
    v_user_pending_id uuid;
    v_journal_entry_id uuid;
BEGIN
    -- Only allow when called without a user (service role / edge function)
    IF auth.uid() IS NOT NULL THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_GATE_NOT_ALLOWED',
                'message', 'Gateway escrow for direct offer can only be triggered by system.'
            )
        );
    END IF;

    SELECT id, client_id, freelancer_id, status, payment_status, price AS amount_gross
    INTO v_offer
    FROM public.direct_offers
    WHERE id = p_offer_id
    FOR UPDATE;

    IF v_offer IS NULL THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_ENTITY_NOT_FOUND',
                'message', 'Direct offer not found.'
            )
        );
    END IF;

    -- Gate: accepted and unpaid
    IF v_offer.status != 'accepted' OR v_offer.payment_status != 'unpaid' THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_GATE_NOT_ALLOWED',
                'message', 'Direct offer must be accepted and unpaid for gateway escrow.'
            )
        );
    END IF;

    v_client_id := v_offer.client_id;
    v_freelancer_id := v_offer.freelancer_id;
    v_amount := COALESCE(p_amount_gross, v_offer.amount_gross);

    SELECT id INTO v_platform_escrow_id FROM public.accounts WHERE account_code = 'platform_escrow' LIMIT 1;
    IF v_platform_escrow_id IS NULL THEN
        RETURN jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'ERR_SETUP', 'message', 'platform_escrow account not found'));
    END IF;

    SELECT id INTO v_user_pending_id
    FROM public.accounts
    WHERE account_code = 'user_pending_withdrawal:' || v_client_id::TEXT;

    IF v_user_pending_id IS NULL THEN
        INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
        VALUES ('user_pending_withdrawal:' || v_client_id::TEXT, 'liability', v_client_id, 'IQD')
        RETURNING id INTO v_user_pending_id;
    END IF;

    INSERT INTO public.journal_entries (
        event_type, related_entity_type, related_entity_id,
        idempotency_key, created_by, currency, meta, status
    ) VALUES (
        'gateway_escrow', 'direct_offer', p_offer_id,
        p_idempotency_key, NULL, p_currency,
        jsonb_build_object(
            'client_id', v_client_id,
            'provider_id', v_freelancer_id,
            'amount_gross', v_amount,
            'psp_provider', p_meta->>'psp_provider',
            'psp_event_id', p_meta->>'psp_event_id',
            'psp_payment_id', p_meta->>'psp_payment_id',
            'psp_request_id', p_meta->>'psp_request_id',
            'psp_status', p_meta->>'psp_status',
            'psp_timestamp', p_meta->>'psp_timestamp'
        ),
        'posted'
    ) RETURNING id INTO v_journal_entry_id;

    INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
    VALUES
        (v_journal_entry_id, v_user_pending_id, 'DEBIT', v_amount, p_currency),
        (v_journal_entry_id, v_platform_escrow_id, 'CREDIT', v_amount, p_currency);

    UPDATE public.direct_offers
    SET payment_status = 'held', status = 'active'
    WHERE id = p_offer_id;

    INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
    VALUES (NULL, 'payment.gateway_escrow', 'direct_offer', p_offer_id, v_journal_entry_id,
            jsonb_build_object('amount', v_amount, 'client_id', v_client_id, 'gateway', p_meta->>'psp_provider'));

    RETURN jsonb_build_object(
        'ok', true,
        'journal_entry_id', v_journal_entry_id,
        'event_type', 'gateway_escrow',
        'related_entity_type', 'direct_offer',
        'related_entity_id', p_offer_id,
        'error', NULL
    );
END;
$$;

COMMENT ON FUNCTION public.process_gateway_escrow_direct_offer IS 'Called by edge function after QiCard payment success for a direct offer. Locks funds in escrow and sets offer to active.';
