-- Tender: assign task to freelancer only AFTER payment, not on award.
-- Award = reserve (task status 'assigned', no freelancer_id/assigned_freelancer_id).
-- Assign (freelancer_id, assigned_freelancer_id, in_progress) only in pay_awarded_offer after payment.
--
-- 1) accept_task_request: stop setting assigned_freelancer_id; set task_requests.payment_status = 'unpaid'.
-- 2) award_task_offer: create/replace to reserve only (no assign); optional price check; return success + payment_deadline.
-- 3) Drop constraint if exists so task can be status='assigned' without freelancer set.

BEGIN;

ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_assigned_requires_freelancer;

-- =============================================================================
-- accept_task_request: award only, do NOT assign freelancer to task
-- =============================================================================
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

    -- Accept the request (awarded, unpaid). Do NOT assign task to freelancer yet.
    UPDATE task_requests
    SET
        status = 'accepted',
        payment_status = 'unpaid',
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

    UPDATE task_requests
    SET
        status = 'rejected',
        updated_at = NOW()
    WHERE task_id = p_task_id
      AND status = 'pending'
      AND id <> p_request_id;

    -- Reserve task (status = assigned) but do NOT set freelancer_id or assigned_freelancer_id.
    -- Assignment happens only in pay_awarded_offer after payment.
    UPDATE tasks
    SET
        status = 'assigned',
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
'Accepts a task request (award only). Rejects other pending bids. Task is reserved (status=assigned) but freelancer is assigned only after payment via pay_awarded_offer.';

-- =============================================================================
-- award_task_offer: reserve only, no assign; optional price check; JSONB return
-- =============================================================================
CREATE OR REPLACE FUNCTION public.award_task_offer(
  p_request_id UUID,
  p_client_id UUID DEFAULT NULL,
  p_expected_price_cents BIGINT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_owner_id UUID := auth.uid();
  v_request RECORD;
  v_task RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_deadline TIMESTAMPTZ := v_now + INTERVAL '24 hours';
  v_config_timeout_hours INT;
  v_actual_price_cents BIGINT;
BEGIN
  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_request
  FROM public.task_requests
  WHERE id = p_request_id
    AND status = 'pending';

  IF v_request IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = v_request.task_id
    AND owner_id = v_owner_id;

  IF v_task IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only task owner can award');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.task_requests
    WHERE task_id = v_request.task_id
      AND status = 'accepted'
      AND id <> p_request_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Task already has accepted offer');
  END IF;

  -- Optional price check (match accept_task_request behavior)
  v_actual_price_cents := (v_request.price * 100)::BIGINT;
  IF p_expected_price_cents IS NOT NULL AND p_expected_price_cents != v_actual_price_cents THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', format('PRICE_MISMATCH: Offer price changed from %s to %s cents', p_expected_price_cents, v_actual_price_cents),
      'PRICE_MISMATCH', true
    );
  END IF;

  BEGIN
    SELECT (value->>'timeout_hours')::INT
    INTO v_config_timeout_hours
    FROM system_config
    WHERE key = 'tender_payment_timeout_hours';
  EXCEPTION WHEN OTHERS THEN
    v_config_timeout_hours := 48;
  END;

  IF v_config_timeout_hours IS NOT NULL THEN
    v_deadline := v_now + (v_config_timeout_hours || ' hours')::INTERVAL;
  END IF;

  -- Mark offer as awarded (accepted, unpaid). Do NOT assign task to freelancer yet.
  UPDATE public.task_requests
  SET status = 'accepted',
      payment_status = 'unpaid',
      awarded_at = v_now,
      payment_deadline = v_deadline,
      awarded_by = v_owner_id,
      updated_at = v_now,
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

  -- Reserve task only; assignment in pay_awarded_offer after payment
  UPDATE public.tasks
  SET status = 'assigned',
      updated_at = v_now
  WHERE id = v_request.task_id;

  UPDATE public.task_requests
  SET status = 'rejected',
      updated_at = v_now
  WHERE task_id = v_request.task_id
    AND status = 'pending'
    AND id <> p_request_id;

  PERFORM public.private_create_notification(
    p_user_id => COALESCE(v_request.freelancer_id, v_request.bidder_id),
    p_title => 'Your offer was awarded!',
    p_message => 'Client selected your proposal. Waiting for payment.',
    p_type => 'offer_awarded',
    p_related_entity_id => p_request_id,
    p_related_entity_type => 'task_request',
    p_metadata => jsonb_build_object(
      'task_id', v_request.task_id,
      'request_id', p_request_id,
      'payment_deadline', v_deadline
    )
  );

  PERFORM public.private_create_notification(
    p_user_id => v_owner_id,
    p_title => 'Complete payment to start work',
    p_message => 'Pay within the deadline to activate the awarded offer.',
    p_type => 'payment_required',
    p_related_entity_id => v_request.task_id,
    p_related_entity_type => 'task',
    p_metadata => jsonb_build_object(
      'task_id', v_request.task_id,
      'request_id', p_request_id,
      'payment_deadline', v_deadline
    )
  );

  RETURN jsonb_build_object('success', true, 'payment_deadline', v_deadline);
END;
$$;

COMMENT ON FUNCTION public.award_task_offer(UUID, UUID, BIGINT) IS
'Award an offer (reserve task only). Task is assigned to freelancer only after pay_awarded_offer. Optional p_expected_price_cents for price mismatch check.';

-- Ensure GRANT for authenticated (award_task_offer may already exist with different signature)
GRANT EXECUTE ON FUNCTION public.award_task_offer(UUID, UUID, BIGINT) TO authenticated;

COMMIT;
