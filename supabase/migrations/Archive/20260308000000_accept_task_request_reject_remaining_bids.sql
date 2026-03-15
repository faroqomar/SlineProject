-- Migration: Reject remaining bids when accepting one (Single Winner Rule)
-- Created: 2026-03-08
-- Purpose: Ensure accept_task_request atomically rejects all other pending bids on the same task
-- Reference: FULL_REPORT 04_task-request-bid-flow Production Checklist item 2

CREATE OR REPLACE FUNCTION accept_task_request(
    p_task_id UUID,
    p_request_id UUID,
    p_expected_price_cents BIGINT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_request RECORD;
    v_task RECORD;
    v_actual_price_cents BIGINT;
    v_config_timeout_hours INT;
BEGIN
    -- ========================================================================
    -- IDEMPOTENCY CHECK: Already accepted?
    -- ========================================================================
    SELECT status, freelancer_id, price, task_id
    INTO v_request
    FROM task_requests
    WHERE id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request not found: %', p_request_id;
    END IF;

    IF v_request.status = 'accepted' THEN
        RETURN 'already_accepted';
    END IF;

    IF v_request.status != 'pending' THEN
        RAISE EXCEPTION 'Cannot accept request with status: %', v_request.status;
    END IF;

    IF v_request.task_id != p_task_id THEN
        RAISE EXCEPTION 'Request % does not belong to task %', p_request_id, p_task_id;
    END IF;

    SELECT owner_id, status, title
    INTO v_task
    FROM tasks
    WHERE id = p_task_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Task not found: %', p_task_id;
    END IF;

    IF v_task.owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to accept offers on this task';
    END IF;

    IF v_task.status != 'open' THEN
        RAISE EXCEPTION 'Cannot accept offers on task with status: %', v_task.status;
    END IF;

    v_actual_price_cents := (v_request.price * 100)::BIGINT;

    IF p_expected_price_cents IS NOT NULL THEN
        IF p_expected_price_cents != v_actual_price_cents THEN
            INSERT INTO admin_logs (
                actor_id,
                action,
                target_resource,
                target_id,
                metadata,
                created_at
            ) VALUES (
                auth.uid(),
                'PRICE_MISMATCH_ATTEMPT',
                'task_requests',
                p_request_id,
                jsonb_build_object(
                    'expected_cents', p_expected_price_cents,
                    'actual_cents', v_actual_price_cents,
                    'task_id', p_task_id,
                    'freelancer_id', v_request.freelancer_id
                ),
                NOW()
            );
            RAISE EXCEPTION 'PRICE_MISMATCH: Offer price changed from % to % cents',
                p_expected_price_cents, v_actual_price_cents;
        END IF;
    END IF;

    BEGIN
        SELECT (value->>'timeout_hours')::INT
        INTO v_config_timeout_hours
        FROM system_config
        WHERE key = 'tender_payment_timeout_hours';
    EXCEPTION WHEN OTHERS THEN
        v_config_timeout_hours := NULL;
    END;

    IF v_config_timeout_hours IS NULL THEN
        v_config_timeout_hours := 48;
    END IF;

    -- ========================================================================
    -- ACCEPT THE REQUEST
    -- ========================================================================
    UPDATE task_requests
    SET
        status = 'accepted',
        awarded_at = NOW(),
        awarded_by = auth.uid(),
        payment_deadline = NOW() + (v_config_timeout_hours || ' hours')::INTERVAL,
        updated_at = NOW(),
        fee_rate_applied_bps = COALESCE(
            (SELECT (value->>'default_rate_bps')::INT FROM system_config WHERE key = 'platform_fee_bps'),
            1000
        ),
        fee_amount = ((price * 100)::BIGINT * COALESCE(
            (SELECT (value->>'default_rate_bps')::INT FROM system_config WHERE key = 'platform_fee_bps'),
            1000
        ) / 10000)::BIGINT,
        net_amount = ((price * 100)::BIGINT) - (((price * 100)::BIGINT * COALESCE(
            (SELECT (value->>'default_rate_bps')::INT FROM system_config WHERE key = 'platform_fee_bps'),
            1000
        ) / 10000)::BIGINT)
    WHERE id = p_request_id;

    -- ========================================================================
    -- REJECT REMAINING BIDS (Single Winner Rule)
    -- ========================================================================
    UPDATE task_requests
    SET
        status = 'rejected',
        updated_at = NOW()
    WHERE task_id = p_task_id
      AND status = 'pending'
      AND id <> p_request_id;

    -- ========================================================================
    -- UPDATE TASK STATUS
    -- ========================================================================
    UPDATE tasks
    SET
        status = 'assigned',
        assigned_freelancer_id = v_request.freelancer_id,
        updated_at = NOW()
    WHERE id = p_task_id;

    INSERT INTO admin_logs (
        actor_id,
        action,
        target_resource,
        target_id,
        metadata,
        created_at
    ) VALUES (
        auth.uid(),
        'OFFER_ACCEPTED',
        'task_requests',
        p_request_id,
        jsonb_build_object(
            'task_id', p_task_id,
            'freelancer_id', v_request.freelancer_id,
            'price_cents', v_actual_price_cents,
            'payment_deadline_hours', v_config_timeout_hours
        ),
        NOW()
    );

    INSERT INTO activity_log (
        user_id,
        actor_id,
        entity_type,
        entity_id,
        event_type,
        metadata,
        created_at
    ) VALUES (
        v_task.owner_id,
        auth.uid(),
        'task',
        p_task_id,
        'offer_accepted',
        jsonb_build_object(
            'request_id', p_request_id,
            'freelancer_id', v_request.freelancer_id,
            'task_title', v_task.title
        ),
        NOW()
    );

    RETURN 'accepted';
END;
$$;

COMMENT ON FUNCTION accept_task_request(UUID, UUID, BIGINT) IS
'Accepts a task request with optional price validation. Rejects all other pending bids on the same task (Single Winner Rule).';
