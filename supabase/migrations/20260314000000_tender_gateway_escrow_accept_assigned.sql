-- Tender QiCard: allow gateway_escrow for task_request in accepted/unpaid;
-- assign task (freelancer_id, in_progress) after holding payment.
-- Patches process_payment_event_ledger gateway_escrow block only.
DO $$
DECLARE
    v_def text;
BEGIN
    SELECT pg_get_functiondef(oid) INTO v_def
    FROM pg_proc
    WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
      AND proname = 'process_payment_event_ledger';

    IF v_def IS NULL THEN
        RAISE EXCEPTION 'process_payment_event_ledger not found';
    END IF;

    -- 1. task_request: fetch with JOIN to get client_id from tasks and task_id for later UPDATE
    v_def := replace(v_def,
        '        ELSIF p_related_entity_type = ''task_request'' THEN
            SELECT id, client_id, provider_id, status, payment_status, amount_gross
            INTO v_entity
            FROM public.task_requests
            WHERE id = p_related_entity_id
            FOR UPDATE;
        END IF;

        IF v_entity IS NULL THEN
            RETURN jsonb_build_object(
                ''ok'', false,
                ''error'', jsonb_build_object(
                    ''code'', ''ERR_ENTITY_NOT_FOUND'',
                    ''message'', ''Related entity not found.''
                )
            );
        END IF;

        v_client_id := v_entity.client_id;
        v_entity_amount_gross := COALESCE(p_amount_gross, v_entity.amount_gross);

        -- Gate validation: status must be pending, payment_status must be unpaid
        IF v_entity.status != ''pending'' OR v_entity.payment_status != ''unpaid'' THEN
            RETURN jsonb_build_object(
                ''ok'', false,
                ''error'', jsonb_build_object(
                    ''code'', ''ERR_GATE_NOT_ALLOWED'',
                    ''message'', ''Gateway escrow not allowed. Booking must be pending and unpaid.''
                )
            );
        END IF;',
        '        ELSIF p_related_entity_type = ''task_request'' THEN
            SELECT tr.id, t.owner_id AS client_id, tr.freelancer_id AS provider_id, tr.status, tr.payment_status,
                   (COALESCE(tr.amount_gross, tr.price))::numeric AS amount_gross, tr.task_id
            INTO v_entity
            FROM public.task_requests tr
            JOIN public.tasks t ON t.id = tr.task_id
            WHERE tr.id = p_related_entity_id
            FOR UPDATE OF tr;
        END IF;

        IF v_entity IS NULL THEN
            RETURN jsonb_build_object(
                ''ok'', false,
                ''error'', jsonb_build_object(
                    ''code'', ''ERR_ENTITY_NOT_FOUND'',
                    ''message'', ''Related entity not found.''
                )
            );
        END IF;

        v_client_id := v_entity.client_id;
        v_entity_amount_gross := COALESCE(p_amount_gross, v_entity.amount_gross);

        -- Gate: booking = pending/unpaid; task_request = accepted/unpaid (awarded, not yet paid)
        IF p_related_entity_type = ''booking'' AND (v_entity.status != ''pending'' OR v_entity.payment_status != ''unpaid'') THEN
            RETURN jsonb_build_object(
                ''ok'', false,
                ''error'', jsonb_build_object(
                    ''code'', ''ERR_GATE_NOT_ALLOWED'',
                    ''message'', ''Gateway escrow not allowed. Booking must be pending and unpaid.''
                )
            );
        END IF;
        IF p_related_entity_type = ''task_request'' AND (v_entity.status != ''accepted'' OR v_entity.payment_status != ''unpaid'') THEN
            RETURN jsonb_build_object(
                ''ok'', false,
                ''error'', jsonb_build_object(
                    ''code'', ''ERR_GATE_NOT_ALLOWED'',
                    ''message'', ''Gateway escrow not allowed. Tender must be awarded and unpaid.''
                )
            );
        END IF;'
    );

    -- 2. After UPDATE task_requests for task_request, also UPDATE tasks (assign freelancer, in_progress)
    v_def := replace(v_def,
        '        IF p_related_entity_type = ''booking'' THEN
            UPDATE public.bookings SET payment_status = ''held'' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = ''task_request'' THEN
            UPDATE public.task_requests SET payment_status = ''held'' WHERE id = p_related_entity_id;
        END IF;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (NULL, ''payment.gateway_escrow'', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object(''amount'', v_entity_amount_gross, ''client_id'', v_client_id, ''gateway'', p_meta->>''psp_provider''));',
        '        IF p_related_entity_type = ''booking'' THEN
            UPDATE public.bookings SET payment_status = ''held'' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = ''task_request'' THEN
            UPDATE public.task_requests SET payment_status = ''held'' WHERE id = p_related_entity_id;
            UPDATE public.tasks t
            SET freelancer_id = tr.freelancer_id, assigned_freelancer_id = tr.freelancer_id, status = ''in_progress'', updated_at = NOW()
            FROM public.task_requests tr
            WHERE tr.id = p_related_entity_id AND t.id = tr.task_id;
        END IF;

        -- Audit log
        INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
        VALUES (NULL, ''payment.gateway_escrow'', p_related_entity_type, p_related_entity_id, v_journal_entry_id,
                jsonb_build_object(''amount'', v_entity_amount_gross, ''client_id'', v_client_id, ''gateway'', p_meta->>''psp_provider''));'
    );

    EXECUTE v_def;
END
$$;
