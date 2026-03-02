-- Extend process_payment_event_ledger for direct_offer (escrow_hold, release_with_fee, refund).
-- Builds on 20260301_fix_booking_ledger_amount_source.sql.

CREATE OR REPLACE FUNCTION public.process_payment_event_ledger(
    p_event_type TEXT,
    p_related_entity_type TEXT,
    p_related_entity_id UUID,
    p_idempotency_key TEXT,
    p_amount_gross NUMERIC DEFAULT NULL,
    p_currency TEXT DEFAULT 'IQD',
    p_meta JSONB DEFAULT '{}'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor_user_id UUID;
    v_actor_role TEXT;
    v_journal_entry_id UUID;
    v_existing_journal_id UUID;
    v_entity_amount_gross NUMERIC;
    v_entity RECORD;
    v_client_id UUID;
    v_provider_id UUID;
    v_booking_status TEXT;
    v_payment_status TEXT;
    v_available_balance NUMERIC;
    v_held_balance NUMERIC;
    v_fee_rate_bps NUMERIC;
    v_fee_amount NUMERIC;
    v_net_amount NUMERIC;
    v_platform_cash_id UUID;
    v_platform_escrow_id UUID;
    v_platform_revenue_id UUID;
    v_platform_test_float_id UUID;
    v_user_available_id UUID;
    v_user_pending_id UUID;
    v_result JSONB;
    v_new_meta JSONB;
    v_withdrawal_record RECORD;
BEGIN
    -- ========================================================================
    -- 1. EXTRACT ACTOR (Anti-spoof: never trust client input)
    -- ========================================================================
    v_actor_user_id := auth.uid();

    -- ========================================================================
    -- 2. VALIDATE INPUTS
    -- ========================================================================
    IF p_idempotency_key IS NULL OR TRIM(p_idempotency_key) = '' THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_MISSING_IDEMPOTENCY_KEY',
                'message', 'Idempotency key is required.'
            )
        );
    END IF;

    IF p_currency != 'IQD' THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_CURRENCY_MISMATCH',
                'message', 'Currency mismatch. Only IQD is supported.'
            )
        );
    END IF;

    -- ========================================================================
    -- 3. CHECK IDEMPOTENCY (Replay protection)
    -- ========================================================================
    SELECT id INTO v_existing_journal_id
    FROM public.journal_entries
    WHERE idempotency_key = p_idempotency_key
    AND status = 'posted';

    IF v_existing_journal_id IS NOT NULL THEN
        -- Return existing result (idempotent replay)
        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_existing_journal_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'error', NULL
        );
    END IF;

    -- ========================================================================
    -- 4. GET PLATFORM ACCOUNT IDs
    -- ========================================================================
    SELECT id INTO v_platform_cash_id FROM public.accounts WHERE account_code = 'platform_cash';
    SELECT id INTO v_platform_escrow_id FROM public.accounts WHERE account_code = 'platform_escrow';
    SELECT id INTO v_platform_revenue_id FROM public.accounts WHERE account_code = 'platform_revenue';
    SELECT id INTO v_platform_test_float_id FROM public.accounts WHERE account_code = 'platform_test_float';

    -- ========================================================================
    -- 5. EVENT TYPE HANDLING
    -- ========================================================================

    -- ------------------------------------------------------------------------
    -- 5.1 ESCROW_HOLD
    -- ------------------------------------------------------------------------
    IF p_event_type = 'escrow_hold' THEN
        -- Validate entity type
        IF p_related_entity_type NOT IN ('booking', 'task_request', 'direct_offer') THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'escrow_hold only allowed for booking, task_request, or direct_offer entities.'
                )
            );
        END IF;

        -- Lock and fetch entity
        IF p_related_entity_type = 'booking' THEN
            SELECT id, client_id, provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.bookings
            WHERE id = p_related_entity_id
            FOR UPDATE;
        ELSIF p_related_entity_type = 'task_request' THEN
            SELECT id, client_id, provider_id, status, payment_status, amount_gross
            INTO v_entity
            FROM public.task_requests
            WHERE id = p_related_entity_id
            FOR UPDATE;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.direct_offers
            WHERE id = p_related_entity_id
            FOR UPDATE;
        END IF;

        -- Entity not found
        IF v_entity IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Related entity not found.'
                )
            );
        END IF;

        v_client_id := v_entity.client_id;
        v_provider_id := v_entity.provider_id;
        v_booking_status := v_entity.status;
        v_payment_status := v_entity.payment_status;
        v_entity_amount_gross := v_entity.amount_gross;

        -- Gate validation: booking/task_request pending+unpaid; direct_offer sent+unpaid
        IF (p_related_entity_type IN ('booking', 'task_request') AND (v_booking_status != 'pending' OR v_payment_status != 'unpaid'))
           OR (p_related_entity_type = 'direct_offer' AND (v_booking_status != 'sent' OR v_payment_status != 'unpaid')) THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Event not allowed for current status. Entity must be pending/sent and unpaid.'
                )
            );
        END IF;

        -- Actor validation: must be client
        IF v_actor_user_id IS NULL OR v_actor_user_id != v_client_id THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Only the client can escrow funds.'
                )
            );
        END IF;

        -- Amount validation
        IF p_amount_gross IS NOT NULL AND p_amount_gross != v_entity_amount_gross THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_AMOUNT_MISMATCH',
                    'message', 'Client amount does not match entity amount.'
                )
            );
        END IF;

        -- Get or create user available account
        SELECT id INTO v_user_available_id
        FROM public.accounts
        WHERE account_code = 'user_available:' || v_client_id::TEXT;

        IF v_user_available_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_available:' || v_client_id::TEXT, 'asset', v_client_id, 'IQD')
            RETURNING id INTO v_user_available_id;
        END IF;

        -- Check sufficient funds (calculate available balance)
        SELECT COALESCE(SUM(
            CASE 
                WHEN direction = 'DEBIT' AND a.account_type = 'asset' THEN amount
                WHEN direction = 'CREDIT' AND a.account_type = 'asset' THEN -amount
                WHEN direction = 'CREDIT' AND a.account_type = 'liability' THEN amount
                WHEN direction = 'DEBIT' AND a.account_type = 'liability' THEN -amount
                ELSE 0
            END
        ), 0) INTO v_available_balance
        FROM public.ledger_lines ll
        JOIN public.journal_entries je ON ll.journal_entry_id = je.id
        JOIN public.accounts a ON ll.account_id = a.id
        WHERE a.account_code = 'user_available:' || v_client_id::TEXT
        AND je.status = 'posted';

        IF v_available_balance < v_entity_amount_gross THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_INSUFFICIENT_FUNDS',
                    'message', 'Insufficient available balance.'
                )
            );
        END IF;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, v_actor_user_id, p_currency,
            jsonb_build_object(
                'client_id', v_client_id,
                'provider_id', v_provider_id,
                'amount_gross', v_entity_amount_gross
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT user_available, CREDIT platform_escrow)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_user_available_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_platform_escrow_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Update entity payment_status (direct_offer: also set status to active)
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings SET payment_status = 'held' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests SET payment_status = 'held' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            UPDATE public.direct_offers SET payment_status = 'held', status = 'active' WHERE id = p_related_entity_id;
        END IF;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (v_actor_user_id, 'payment.escrow_hold', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'currency', p_currency));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'balances', jsonb_build_object(
                'available_balance', v_available_balance - v_entity_amount_gross,
                'held_balance', v_entity_amount_gross
            ),
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.2 RELEASE_WITH_FEE
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'release_with_fee' THEN
        IF p_related_entity_type NOT IN ('booking', 'task_request', 'direct_offer') THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'release_with_fee only allowed for booking, task_request, or direct_offer entities.'
                )
            );
        END IF;

        -- Lock and fetch entity
        IF p_related_entity_type = 'booking' THEN
            SELECT id, client_id, provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.bookings
            WHERE id = p_related_entity_id
            FOR UPDATE;
        ELSIF p_related_entity_type = 'task_request' THEN
            SELECT id, client_id, provider_id, status, payment_status, amount_gross
            INTO v_entity
            FROM public.task_requests
            WHERE id = p_related_entity_id
            FOR UPDATE;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.direct_offers
            WHERE id = p_related_entity_id
            FOR UPDATE;
        END IF;

        IF v_entity IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Related entity not found.'
                )
            );
        END IF;

        v_client_id := v_entity.client_id;
        v_provider_id := v_entity.provider_id;
        v_booking_status := v_entity.status;
        v_payment_status := v_entity.payment_status;
        v_entity_amount_gross := v_entity.amount_gross;

        -- Gate validation: status must be delivered, payment_status must be held
        IF v_booking_status != 'delivered' OR v_payment_status != 'held' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Event not allowed for current status. Booking must be delivered and payment held.'
                )
            );
        END IF;

        -- Actor validation: must be client
        IF v_actor_user_id IS NULL OR v_actor_user_id != v_client_id THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Only the client can release funds.'
                )
            );
        END IF;

        -- Fee calculation (default 10% = 1000 bps if not specified)
        v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);
        v_fee_amount := FLOOR((v_entity_amount_gross * v_fee_rate_bps) / 10000);
        v_net_amount := v_entity_amount_gross - v_fee_amount;

        -- Get or create provider account
        SELECT id INTO v_user_available_id
        FROM public.accounts
        WHERE account_code = 'user_available:' || v_provider_id::TEXT;

        IF v_user_available_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_available:' || v_provider_id::TEXT, 'asset', v_provider_id, 'IQD')
            RETURNING id INTO v_user_available_id;
        END IF;

        -- Create journal entry
        v_new_meta := jsonb_build_object(
            'client_id', v_client_id,
            'provider_id', v_provider_id,
            'gross_amount', v_entity_amount_gross,
            'fee_rate_bps', v_fee_rate_bps,
            'fee_amount', v_fee_amount,
            'net_amount', v_net_amount,
            'rounding_policy', 'floor'
        ) || p_meta;

        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, v_actor_user_id, p_currency, v_new_meta, 'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines
        -- DEBIT platform_escrow, CREDIT provider_available, CREDIT platform_revenue
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_platform_escrow_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_available_id, 'CREDIT', v_net_amount, p_currency),
            (v_journal_entry_id, v_platform_revenue_id, 'CREDIT', v_fee_amount, p_currency);

        -- Update entity
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings SET payment_status = 'released', status = 'completed' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests SET payment_status = 'released', status = 'completed' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            UPDATE public.direct_offers SET payment_status = 'released', status = 'completed' WHERE id = p_related_entity_id;
        END IF;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (v_actor_user_id, 'payment.release_with_fee', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('gross_amount', v_entity_amount_gross, 'fee_amount', v_fee_amount, 'net_amount', v_net_amount));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'balances', jsonb_build_object(
                'fee_amount', v_fee_amount,
                'net_amount', v_net_amount
            ),
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.3 REFUND
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'refund' THEN
        IF p_related_entity_type NOT IN ('booking', 'task_request', 'direct_offer') THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'refund only allowed for booking, task_request, or direct_offer entities.'
                )
            );
        END IF;

        -- Lock and fetch entity
        IF p_related_entity_type = 'booking' THEN
            SELECT id, client_id, provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.bookings
            WHERE id = p_related_entity_id
            FOR UPDATE;
        ELSIF p_related_entity_type = 'task_request' THEN
            SELECT id, client_id, provider_id, status, payment_status, amount_gross
            INTO v_entity
            FROM public.task_requests
            WHERE id = p_related_entity_id
            FOR UPDATE;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.direct_offers
            WHERE id = p_related_entity_id
            FOR UPDATE;
        END IF;

        IF v_entity IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Related entity not found.'
                )
            );
        END IF;

        v_client_id := v_entity.client_id;
        v_provider_id := v_entity.provider_id;
        v_booking_status := v_entity.status;
        v_payment_status := v_entity.payment_status;
        v_entity_amount_gross := v_entity.amount_gross;

        -- Gate validation: payment_status must be held
        IF v_payment_status != 'held' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Refund only allowed when payment_status is held.'
                )
            );
        END IF;

        -- Gate validation: status must allow refund (booking/tr: declined/canceled/expired; direct_offer: client or freelancer may refund when held)
        IF p_related_entity_type IN ('booking', 'task_request') AND v_booking_status NOT IN ('declined', 'canceled', 'expired_unanswered', 'dispute_refund') THEN
            IF v_actor_user_id IS NOT NULL THEN
                RETURN jsonb_build_object(
                    'ok', false,
                    'error', jsonb_build_object(
                        'code', 'ERR_GATE_NOT_ALLOWED',
                        'message', 'Refund not allowed for current booking status.'
                    )
                );
            END IF;
        END IF;

        -- Actor validation: provider, client, or system (for direct_offer both client and freelancer may refund)
        IF v_actor_user_id IS NOT NULL AND 
           v_actor_user_id != v_provider_id AND 
           v_actor_user_id != v_client_id THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Only provider or client can process refunds.'
                )
            );
        END IF;

        -- Get or create client available account
        SELECT id INTO v_user_available_id
        FROM public.accounts
        WHERE account_code = 'user_available:' || v_client_id::TEXT;

        IF v_user_available_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_available:' || v_client_id::TEXT, 'asset', v_client_id, 'IQD')
            RETURNING id INTO v_user_available_id;
        END IF;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, v_actor_user_id, p_currency,
            jsonb_build_object(
                'client_id', v_client_id,
                'provider_id', v_provider_id,
                'refund_reason', p_meta->>'refund_reason',
                'amount_gross', v_entity_amount_gross
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT platform_escrow, CREDIT user_available)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_platform_escrow_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_available_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Update entity (direct_offer: set status to refunded)
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings SET payment_status = 'refunded' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests SET payment_status = 'refunded' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            UPDATE public.direct_offers SET payment_status = 'refunded', status = 'refunded' WHERE id = p_related_entity_id;
        END IF;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (v_actor_user_id, 'payment.refund', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'reason', p_meta->>'refund_reason'));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'balances', jsonb_build_object(
                'refunded_amount', v_entity_amount_gross
            ),
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.4 WITHDRAWAL_REQUEST
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'withdrawal_request' THEN
        IF p_related_entity_type != 'withdrawal_request' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'withdrawal_request only allowed for withdrawal_request entities.'
                )
            );
        END IF;

        -- Lock and fetch withdrawal request
        SELECT id, user_id, amount, status, currency
        INTO v_withdrawal_record
        FROM public.withdrawal_requests
        WHERE id = p_related_entity_id
        FOR UPDATE;

        IF v_withdrawal_record IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Withdrawal request not found.'
                )
            );
        END IF;

        -- Actor validation: must be the owner
        IF v_actor_user_id IS NULL OR v_actor_user_id != v_withdrawal_record.user_id THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Only the owner can request withdrawal.'
                )
            );
        END IF;

        -- Gate validation: must be in requested status
        IF v_withdrawal_record.status != 'requested' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Withdrawal request already processed.'
                )
            );
        END IF;

        v_entity_amount_gross := v_withdrawal_record.amount;

        -- Validate amount
        IF v_entity_amount_gross <= 0 THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_WITHDRAWAL_AMOUNT_INVALID',
                    'message', 'Invalid withdrawal amount.'
                )
            );
        END IF;

        -- Get or create user accounts
        SELECT id INTO v_user_available_id
        FROM public.accounts
        WHERE account_code = 'user_available:' || v_withdrawal_record.user_id::TEXT;

        IF v_user_available_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_available:' || v_withdrawal_record.user_id::TEXT, 'asset', v_withdrawal_record.user_id, 'IQD')
            RETURNING id INTO v_user_available_id;
        END IF;

        SELECT id INTO v_user_pending_id
        FROM public.accounts
        WHERE account_code = 'user_pending_withdrawal:' || v_withdrawal_record.user_id::TEXT;

        IF v_user_pending_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_pending_withdrawal:' || v_withdrawal_record.user_id::TEXT, 'liability', v_withdrawal_record.user_id, 'IQD')
            RETURNING id INTO v_user_pending_id;
        END IF;

        -- Check sufficient funds
        SELECT COALESCE(SUM(
            CASE 
                WHEN direction = 'DEBIT' AND a.account_type = 'asset' THEN amount
                WHEN direction = 'CREDIT' AND a.account_type = 'asset' THEN -amount
                ELSE 0
            END
        ), 0) INTO v_available_balance
        FROM public.ledger_lines ll
        JOIN public.journal_entries je ON ll.journal_entry_id = je.id
        JOIN public.accounts a ON ll.account_id = a.id
        WHERE a.account_code = 'user_available:' || v_withdrawal_record.user_id::TEXT
        AND je.status = 'posted';

        IF v_available_balance < v_entity_amount_gross THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_INSUFFICIENT_FUNDS',
                    'message', 'Insufficient available balance for withdrawal.'
                )
            );
        END IF;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, v_actor_user_id, p_currency,
            jsonb_build_object(
                'user_id', v_withdrawal_record.user_id,
                'withdrawal_request_id', p_related_entity_id,
                'amount', v_entity_amount_gross
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT user_available, CREDIT user_pending_withdrawal)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_user_available_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_pending_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Update withdrawal request status
        UPDATE public.withdrawal_requests 
        SET status = 'processing' 
        WHERE id = p_related_entity_id;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (v_actor_user_id, 'payment.withdrawal_request', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'user_id', v_withdrawal_record.user_id));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'balances', jsonb_build_object(
                'available_balance', v_available_balance - v_entity_amount_gross,
                'pending_withdrawal_balance', v_entity_amount_gross
            ),
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.5 DEPOSIT (System/Edge Function only)
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'deposit' THEN
        -- Only system/service role can deposit
        IF v_actor_user_id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Deposit events can only be triggered by system.'
                )
            );
        END IF;

        -- Expect user_id in meta for gateway deposits
        v_client_id := (p_meta->>'user_id')::UUID;
        v_entity_amount_gross := COALESCE(p_amount_gross, 0);

        IF v_client_id IS NULL OR v_entity_amount_gross <= 0 THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Invalid deposit parameters.'
                )
            );
        END IF;

        -- Get or create user available account
        SELECT id INTO v_user_available_id
        FROM public.accounts
        WHERE account_code = 'user_available:' || v_client_id::TEXT;

        IF v_user_available_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_available:' || v_client_id::TEXT, 'asset', v_client_id, 'IQD')
            RETURNING id INTO v_user_available_id;
        END IF;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, NULL, p_currency,
            jsonb_build_object(
                'user_id', v_client_id,
                'amount', v_entity_amount_gross,
                'psp_provider', p_meta->>'psp_provider',
                'psp_event_id', p_meta->>'psp_event_id',
                'psp_payment_id', p_meta->>'psp_payment_id',
                'psp_request_id', p_meta->>'psp_request_id',
                'psp_status', p_meta->>'psp_status',
                'psp_timestamp', p_meta->>'psp_timestamp'
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT platform_cash, CREDIT user_available)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_platform_cash_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_available_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (NULL, 'gateway.deposit', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'user_id', v_client_id));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'balances', jsonb_build_object(
                'deposited_amount', v_entity_amount_gross
            ),
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.6 WITHDRAWAL_COMPLETE (System/Edge Function only)
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'withdrawal_complete' THEN
        -- Only system/service role can complete withdrawal
        IF v_actor_user_id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Withdrawal completion can only be triggered by system.'
                )
            );
        END IF;

        IF p_related_entity_type != 'withdrawal_request' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'withdrawal_complete only allowed for withdrawal_request entities.'
                )
            );
        END IF;

        -- Lock and fetch withdrawal request
        SELECT id, user_id, amount, status, currency
        INTO v_withdrawal_record
        FROM public.withdrawal_requests
        WHERE id = p_related_entity_id
        FOR UPDATE;

        IF v_withdrawal_record IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Withdrawal request not found.'
                )
            );
        END IF;

        IF v_withdrawal_record.status != 'processing' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Withdrawal must be in processing state to complete.'
                )
            );
        END IF;

        v_entity_amount_gross := v_withdrawal_record.amount;

        -- Get user accounts
        SELECT id INTO v_user_pending_id
        FROM public.accounts
        WHERE account_code = 'user_pending_withdrawal:' || v_withdrawal_record.user_id::TEXT;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, NULL, p_currency,
            jsonb_build_object(
                'user_id', v_withdrawal_record.user_id,
                'withdrawal_request_id', p_related_entity_id,
                'amount', v_entity_amount_gross,
                'psp_provider', p_meta->>'psp_provider',
                'psp_event_id', p_meta->>'psp_event_id'
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT user_pending_withdrawal, CREDIT platform_cash)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_user_pending_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_platform_cash_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Update withdrawal request
        UPDATE public.withdrawal_requests 
        SET status = 'completed', processed_at = NOW()
        WHERE id = p_related_entity_id;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (NULL, 'gateway.withdrawal_complete', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'user_id', v_withdrawal_record.user_id));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.7 WITHDRAWAL_FAILED (System/Edge Function only)
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'withdrawal_failed' THEN
        -- Only system/service role can fail withdrawal
        IF v_actor_user_id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Withdrawal failure can only be triggered by system.'
                )
            );
        END IF;

        IF p_related_entity_type != 'withdrawal_request' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'withdrawal_failed only allowed for withdrawal_request entities.'
                )
            );
        END IF;

        -- Lock and fetch withdrawal request
        SELECT id, user_id, amount, status, currency
        INTO v_withdrawal_record
        FROM public.withdrawal_requests
        WHERE id = p_related_entity_id
        FOR UPDATE;

        IF v_withdrawal_record IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Withdrawal request not found.'
                )
            );
        END IF;

        IF v_withdrawal_record.status != 'processing' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Withdrawal must be in processing state to fail.'
                )
            );
        END IF;

        v_entity_amount_gross := v_withdrawal_record.amount;

        -- Get user accounts
        SELECT id INTO v_user_available_id
        FROM public.accounts
        WHERE account_code = 'user_available:' || v_withdrawal_record.user_id::TEXT;

        SELECT id INTO v_user_pending_id
        FROM public.accounts
        WHERE account_code = 'user_pending_withdrawal:' || v_withdrawal_record.user_id::TEXT;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, NULL, p_currency,
            jsonb_build_object(
                'user_id', v_withdrawal_record.user_id,
                'withdrawal_request_id', p_related_entity_id,
                'amount', v_entity_amount_gross,
                'failure_reason', p_meta->>'failure_reason'
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT user_pending_withdrawal, CREDIT user_available)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_user_pending_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_available_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Update withdrawal request
        UPDATE public.withdrawal_requests 
        SET status = 'failed', failure_reason = COALESCE(p_meta->>'failure_reason', 'Gateway error')
        WHERE id = p_related_entity_id;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (NULL, 'gateway.withdrawal_failed', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'user_id', v_withdrawal_record.user_id, 'reason', p_meta->>'failure_reason'));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.8 GATEWAY_ESCROW (System/Edge Function only)
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'gateway_escrow' THEN
        -- Only system/service role can process gateway escrow
        IF v_actor_user_id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Gateway escrow can only be triggered by system.'
                )
            );
        END IF;

        IF p_related_entity_type NOT IN ('booking', 'task_request') THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'gateway_escrow only allowed for booking or task_request entities.'
                )
            );
        END IF;

        -- Lock and fetch entity
        IF p_related_entity_type = 'booking' THEN
            SELECT id, client_id, provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.bookings
            WHERE id = p_related_entity_id
            FOR UPDATE;
        ELSIF p_related_entity_type = 'task_request' THEN
            SELECT id, client_id, provider_id, status, payment_status, amount_gross
            INTO v_entity
            FROM public.task_requests
            WHERE id = p_related_entity_id
            FOR UPDATE;
        END IF;

        IF v_entity IS NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Related entity not found.'
                )
            );
        END IF;

        v_client_id := v_entity.client_id;
        v_entity_amount_gross := COALESCE(p_amount_gross, v_entity.amount_gross);

        -- Gate validation: status must be pending, payment_status must be unpaid
        IF v_entity.status != 'pending' OR v_entity.payment_status != 'unpaid' THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Gateway escrow not allowed. Booking must be pending and unpaid.'
                )
            );
        END IF;

        -- Get or create client pending withdrawal account (for locked funds)
        SELECT id INTO v_user_pending_id
        FROM public.accounts
        WHERE account_code = 'user_pending_withdrawal:' || v_client_id::TEXT;

        IF v_user_pending_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_pending_withdrawal:' || v_client_id::TEXT, 'liability', v_client_id, 'IQD')
            RETURNING id INTO v_user_pending_id;
        END IF;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, NULL, p_currency,
            jsonb_build_object(
                'client_id', v_client_id,
                'provider_id', v_entity.provider_id,
                'amount_gross', v_entity_amount_gross,
                'psp_provider', p_meta->>'psp_provider',
                'psp_event_id', p_meta->>'psp_event_id',
                'psp_payment_id', p_meta->>'psp_payment_id',
                'psp_request_id', p_meta->>'psp_request_id',
                'psp_status', p_meta->>'psp_status',
                'psp_timestamp', p_meta->>'psp_timestamp'
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT user_pending_withdrawal, CREDIT platform_escrow)
        -- Note: Funds were already locked from user's bank account via gateway
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_user_pending_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_platform_escrow_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Update entity payment_status
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings SET payment_status = 'held' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests SET payment_status = 'held' WHERE id = p_related_entity_id;
        END IF;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (NULL, 'payment.gateway_escrow', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'client_id', v_client_id, 'gateway', p_meta->>'psp_provider'));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'error', NULL
        );

    -- ------------------------------------------------------------------------
    -- 5.9 ADMIN_CREDIT (Testing only - System only)
    -- ------------------------------------------------------------------------
    ELSIF p_event_type = 'admin_credit' THEN
        -- Only system/service role can admin_credit
        IF v_actor_user_id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_GATE_NOT_ALLOWED',
                    'message', 'Admin credit can only be triggered by system.'
                )
            );
        END IF;

        v_client_id := (p_meta->>'user_id')::UUID;
        v_entity_amount_gross := COALESCE(p_amount_gross, 0);

        IF v_client_id IS NULL OR v_entity_amount_gross <= 0 THEN
            RETURN jsonb_build_object(
                'ok', false,
                'error', jsonb_build_object(
                    'code', 'ERR_ENTITY_NOT_FOUND',
                    'message', 'Invalid admin credit parameters.'
                )
            );
        END IF;

        -- Get or create user available account
        SELECT id INTO v_user_available_id
        FROM public.accounts
        WHERE account_code = 'user_available:' || v_client_id::TEXT;

        IF v_user_available_id IS NULL THEN
            INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
            VALUES ('user_available:' || v_client_id::TEXT, 'asset', v_client_id, 'IQD')
            RETURNING id INTO v_user_available_id;
        END IF;

        -- Create journal entry
        INSERT INTO public.journal_entries (
            event_type, related_entity_type, related_entity_id,
            idempotency_key, created_by, currency, meta, status
        ) VALUES (
            p_event_type, p_related_entity_type, p_related_entity_id,
            p_idempotency_key, NULL, p_currency,
            jsonb_build_object(
                'user_id', v_client_id,
                'amount', v_entity_amount_gross,
                'reason', p_meta->>'reason'
            ),
            'posted'
        ) RETURNING id INTO v_journal_entry_id;

        -- Create ledger lines (DEBIT platform_test_float, CREDIT user_available)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_platform_test_float_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_available_id, 'CREDIT', v_entity_amount_gross, p_currency);

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (NULL, 'payment.admin_credit', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object('amount', v_entity_amount_gross, 'user_id', v_client_id, 'reason', p_meta->>'reason'));

        RETURN jsonb_build_object(
            'ok', true,
            'journal_entry_id', v_journal_entry_id,
            'event_type', p_event_type,
            'related_entity_type', p_related_entity_type,
            'related_entity_id', p_related_entity_id,
            'error', NULL
        );

    ELSE
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_GATE_NOT_ALLOWED',
                'message', 'Unknown event type: ' || p_event_type
            )
        );
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        -- Handle race condition on idempotency key
        IF SQLERRM LIKE '%uq_journal_entries_idempotency_key%' OR
           SQLERRM LIKE '%journal_entries_idempotency_key%' THEN
            SELECT id INTO v_existing_journal_id
            FROM public.journal_entries
            WHERE idempotency_key = p_idempotency_key;

            IF v_existing_journal_id IS NOT NULL THEN
                RETURN jsonb_build_object(
                    'ok', true,
                    'journal_entry_id', v_existing_journal_id,
                    'event_type', p_event_type,
                    'related_entity_type', p_related_entity_type,
                    'related_entity_id', p_related_entity_id,
                    'error', NULL
                );
            END IF;
        END IF;

        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_IDEMPOTENCY_REPLAY',
                'message', 'Transaction was already processed.'
            )
        );

    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'ERR_INTERNAL',
                'message', SQLERRM
            )
        );
END;
$$;
