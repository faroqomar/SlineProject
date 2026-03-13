-- Fix booking QiCard recovery/webhook escrow path.
-- Why: booking payment recovery currently fails inside the generic gateway_escrow
-- ledger path with `invalid input value for enum booking_status_enum: "sent"`.
-- We isolate booking gateway escrow behind a dedicated booking-only RPC so the
-- booking flow no longer depends on status handling shared with other entities.

BEGIN;

CREATE OR REPLACE FUNCTION public.process_gateway_escrow_booking(
    p_booking_id uuid,
    p_amount_gross numeric DEFAULT NULL,
    p_currency text DEFAULT 'IQD',
    p_idempotency_key text DEFAULT NULL,
    p_meta jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_booking record;
    v_client_id uuid;
    v_provider_id uuid;
    v_amount numeric;
    v_platform_escrow_id uuid;
    v_user_pending_id uuid;
    v_existing_journal_id uuid;
    v_journal_entry_id uuid;
BEGIN
    IF auth.uid() IS NOT NULL THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_GATE_NOT_ALLOWED',
                'message', 'Gateway escrow for booking can only be triggered by system.'
            )
        );
    END IF;

    IF p_idempotency_key IS NULL OR trim(p_idempotency_key) = '' THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_MISSING_IDEMPOTENCY_KEY',
                'message', 'Idempotency key is required.'
            )
        );
    END IF;

    IF p_currency <> 'IQD' THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_CURRENCY_MISMATCH',
                'message', 'Currency mismatch. Only IQD is supported.'
            )
        );
    END IF;

    SELECT id
    INTO v_existing_journal_id
    FROM public.journal_entries
    WHERE idempotency_key = p_idempotency_key
      AND status = 'posted'
      AND related_entity_type = 'booking'
      AND related_entity_id = p_booking_id
    LIMIT 1;

    IF v_existing_journal_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_existing_journal_id,
            'event_type', 'gateway_escrow',
            'related_entity_type', 'booking',
            'related_entity_id', p_booking_id,
            'replayed', true,
            'error', NULL
        );
    END IF;

    -- Reject if idempotency key was already used for a different entity
    IF EXISTS (
        SELECT 1 FROM public.journal_entries
        WHERE idempotency_key = p_idempotency_key
          AND status = 'posted'
          AND (related_entity_id IS DISTINCT FROM p_booking_id OR related_entity_type IS DISTINCT FROM 'booking')
    ) THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_IDEMPOTENCY_KEY_CONFLICT',
                'message', 'Idempotency key already used for a different entity.'
            )
        );
    END IF;

    SELECT
        id,
        client_id,
        provider_id,
        status::text AS status,
        payment_status::text AS payment_status,
        price AS amount_gross
    INTO v_booking
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;

    IF v_booking IS NULL THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_ENTITY_NOT_FOUND',
                'message', 'Booking not found.'
            )
        );
    END IF;

    IF v_booking.payment_status = 'held' THEN
        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', NULL,
            'event_type', 'gateway_escrow',
            'related_entity_type', 'booking',
            'related_entity_id', p_booking_id,
            'replayed', true,
            'error', NULL
        );
    END IF;

    IF v_booking.status NOT IN ('pending', 'confirmed') OR v_booking.payment_status <> 'unpaid' THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_GATE_NOT_ALLOWED',
                'message', 'Gateway escrow not allowed. Booking must be pending/confirmed and unpaid.'
            )
        );
    END IF;

    v_client_id := v_booking.client_id;
    v_provider_id := v_booking.provider_id;
    v_amount := COALESCE(p_amount_gross, v_booking.amount_gross);

    IF v_amount IS NULL OR v_amount <= 0 THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_AMOUNT_INVALID',
                'message', 'Booking amount must be greater than zero.'
            )
        );
    END IF;

    SELECT id
    INTO v_platform_escrow_id
    FROM public.accounts
    WHERE account_code = 'platform_escrow'
    LIMIT 1;

    IF v_platform_escrow_id IS NULL THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_SETUP',
                'message', 'platform_escrow account not found.'
            )
        );
    END IF;

    INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
    VALUES ('user_pending_withdrawal:' || v_client_id::text, 'liability', v_client_id, 'IQD')
    ON CONFLICT (account_code) DO NOTHING;

    SELECT id INTO v_user_pending_id
    FROM public.accounts
    WHERE account_code = 'user_pending_withdrawal:' || v_client_id::text;

    INSERT INTO public.journal_entries (
        event_type,
        related_entity_type,
        related_entity_id,
        idempotency_key,
        created_by,
        currency,
        meta,
        status
    ) VALUES (
        'gateway_escrow'::public.payment_event_type_enum,
        'booking'::public.related_entity_type_enum,
        p_booking_id,
        p_idempotency_key,
        NULL,
        p_currency,
        jsonb_build_object(
            'client_id', v_client_id,
            'provider_id', v_provider_id,
            'amount_gross', v_amount,
            'psp_provider', p_meta->>'psp_provider',
            'psp_event_id', p_meta->>'psp_event_id',
            'psp_payment_id', p_meta->>'psp_payment_id',
            'psp_request_id', p_meta->>'psp_request_id',
            'psp_status', p_meta->>'psp_status',
            'psp_timestamp', p_meta->>'psp_timestamp',
            'booking_id', p_booking_id,
            'correlation_id', p_meta->>'correlation_id'
        ) || CASE
            WHEN p_meta ? 'payment_intent_id'
                THEN jsonb_build_object('payment_intent_id', p_meta->>'payment_intent_id')
            ELSE '{}'::jsonb
        END,
        'posted'
    )
    RETURNING id INTO v_journal_entry_id;

    INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
    VALUES
        (v_journal_entry_id, v_user_pending_id, 'DEBIT', v_amount, p_currency),
        (v_journal_entry_id, v_platform_escrow_id, 'CREDIT', v_amount, p_currency);

    UPDATE public.bookings
    SET payment_status = 'held'::public.payment_status_enum
    WHERE id = p_booking_id;

    INSERT INTO public.audit_logs (
        actor_user_id,
        action,
        related_entity_type,
        related_entity_id,
        journal_entry_id,
        meta
    )
    VALUES (
        NULL,
        'payment.gateway_escrow',
        'booking',
        p_booking_id,
        v_journal_entry_id,
        jsonb_build_object(
            'amount', v_amount,
            'client_id', v_client_id,
            'provider_id', v_provider_id,
            'gateway', p_meta->>'psp_provider'
        )
    );

    RETURN jsonb_build_object(
        'ok', true,
        'journal_entry_id', v_journal_entry_id,
        'event_type', 'gateway_escrow',
        'related_entity_type', 'booking',
        'related_entity_id', p_booking_id,
        'error', NULL
    );
END;
$$;

COMMENT ON FUNCTION public.process_gateway_escrow_booking IS
    'Called by booking QiCard recovery/webhook paths after payment success. Posts booking escrow hold without routing through the generic gateway_escrow ledger branch.';

REVOKE EXECUTE ON FUNCTION public.process_gateway_escrow_booking(uuid, numeric, text, text, jsonb) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.process_gateway_escrow_booking(uuid, numeric, text, text, jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.process_gateway_escrow_booking(uuid, numeric, text, text, jsonb) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.process_gateway_escrow_booking(uuid, numeric, text, text, jsonb) TO service_role;

COMMIT;
