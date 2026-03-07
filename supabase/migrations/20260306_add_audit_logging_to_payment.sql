-- Migration: Add Audit Logging to Payment RPCs
-- Created: 2026-03-06
-- Purpose: Add comprehensive audit logging to pay_awarded_offer RPC

-- ============================================================================
-- STEP 1: Update pay_awarded_offer with audit logging
-- ============================================================================

CREATE OR REPLACE FUNCTION public.pay_awarded_offer(
  p_request_id UUID,
  p_client_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request RECORD;
  v_task RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_freelancer UUID;
  v_price_cents BIGINT;
  v_fee_rate_bps INT;
  v_fee_amount BIGINT;
  v_net_amount BIGINT;
BEGIN
  -- Fetch the request
  SELECT * INTO v_request
  FROM public.task_requests
  WHERE id = p_request_id
    AND status = 'accepted'
    AND payment_status = 'unpaid';

  IF v_request IS NULL THEN
    -- AUDIT: Payment attempt on invalid request
    INSERT INTO admin_logs (
        actor_id,
        action,
        target_resource,
        target_id,
        metadata,
        created_at
    ) VALUES (
        COALESCE(p_client_id, auth.uid()),
        'PAYMENT_INVALID_REQUEST',
        'task_requests',
        p_request_id,
        jsonb_build_object(
            'error', 'Request not found or not in accepted/unpaid status',
            'client_id', p_client_id
        ),
        v_now
    );
    
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  -- Check payment deadline
  IF v_request.payment_deadline < v_now THEN
    -- Reset request and task
    UPDATE public.task_requests
    SET status = 'rejected',
        updated_at = v_now
    WHERE id = p_request_id;

    UPDATE public.tasks
    SET freelancer_id = NULL,
        assigned_freelancer_id = NULL,
        status = 'open',
        updated_at = v_now
    WHERE id = v_request.task_id;

    -- AUDIT: Payment attempted after deadline
    INSERT INTO admin_logs (
        actor_id,
        action,
        target_resource,
        target_id,
        metadata,
        created_at
    ) VALUES (
        COALESCE(p_client_id, auth.uid()),
        'PAYMENT_AFTER_DEADLINE',
        'task_requests',
        p_request_id,
        jsonb_build_object(
            'task_id', v_request.task_id,
            'payment_deadline', v_request.payment_deadline,
            'attempted_at', v_now
        ),
        v_now
    );

    RETURN jsonb_build_object('success', false, 'error', 'Payment deadline expired', 'expired', true);
  END IF;

  -- Verify task ownership
  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = v_request.task_id
    AND owner_id = p_client_id;

  IF v_task IS NULL THEN
    -- AUDIT: Unauthorized payment attempt
    INSERT INTO admin_logs (
        actor_id,
        action,
        target_resource,
        target_id,
        metadata,
        created_at
    ) VALUES (
        COALESCE(p_client_id, auth.uid()),
        'PAYMENT_UNAUTHORIZED',
        'task_requests',
        p_request_id,
        jsonb_build_object(
            'task_id', v_request.task_id,
            'error', 'Only task owner can pay'
        ),
        v_now
    );
    
    RETURN jsonb_build_object('success', false, 'error', 'Only task owner can pay');
  END IF;

  v_freelancer := COALESCE(v_request.freelancer_id, v_request.bidder_id);
  v_price_cents := (v_request.price * 100)::BIGINT;
  v_fee_rate_bps := COALESCE(v_request.fee_rate_applied_bps, 
      (SELECT (value->>'default_rate_bps')::INT FROM system_config WHERE key = 'platform_fee_bps'),
      1000);
  v_fee_amount := (v_price_cents * v_fee_rate_bps / 10000)::BIGINT;
  v_net_amount := v_price_cents - v_fee_amount;

  -- Update request to paid
  UPDATE public.task_requests
  SET payment_status = 'held',
      updated_at = v_now
  WHERE id = p_request_id;

  -- Assign task to freelancer after payment
  UPDATE public.tasks
  SET freelancer_id = v_freelancer,
      assigned_freelancer_id = v_freelancer,
      status = 'in_progress',
      updated_at = v_now
  WHERE id = v_request.task_id;

  -- ============================================================================
  -- AUDIT: Successful payment
  -- ============================================================================
  INSERT INTO admin_logs (
      actor_id,
      action,
      target_resource,
      target_id,
      metadata,
      created_at
  ) VALUES (
      COALESCE(p_client_id, auth.uid()),
      'PAYMENT_COMPLETED',
      'task_requests',
      p_request_id,
      jsonb_build_object(
          'task_id', v_request.task_id,
          'freelancer_id', v_freelancer,
          'price_cents', v_price_cents,
          'fee_rate_bps', v_fee_rate_bps,
          'fee_amount', v_fee_amount,
          'net_amount', v_net_amount,
          'payment_deadline', v_request.payment_deadline
      ),
      v_now
  );

  -- ============================================================================
  -- ACTIVITY LOG: For client/freelancer dashboards
  -- ============================================================================
  INSERT INTO activity_log (
      user_id,
      actor_id,
      entity_type,
      entity_id,
      event_type,
      metadata,
      created_at
  ) VALUES (
      p_client_id,
      COALESCE(p_client_id, auth.uid()),
      'task',
      v_request.task_id,
      'payment_held',
      jsonb_build_object(
          'request_id', p_request_id,
          'freelancer_id', v_freelancer,
          'amount_cents', v_price_cents,
          'fee_amount', v_fee_amount
      ),
      v_now
  );

  -- Notify freelancer
  PERFORM public.private_create_notification(
    p_user_id => v_freelancer,
    p_title => 'Payment confirmed - Start working!',
    p_message => 'Client has paid. Escrow is held and work can begin.',
    p_type => 'work_active',
    p_related_entity_id => p_request_id,
    p_related_entity_type => 'task_request',
    p_metadata => jsonb_build_object(
      'task_id', v_request.task_id,
      'request_id', p_request_id,
      'amount_cents', v_price_cents,
      'net_amount', v_net_amount
    )
  );

  RETURN jsonb_build_object(
    'success', true, 
    'payment_status', 'held',
    'task_id', v_request.task_id,
    'freelancer_id', v_freelancer,
    'amount_cents', v_price_cents,
    'net_amount', v_net_amount
  );
END;
$$;

COMMENT ON FUNCTION public.pay_awarded_offer(UUID, UUID) IS
  'Completes payment for an awarded offer. Assigns freelancer and activates work. 
   Includes comprehensive audit logging for all payment attempts (success, failure, expiry).'

-- ============================================================================
-- VERIFICATION QUERIES (Run manually after migration)
-- ============================================================================

/*
-- Verify function was updated:
SELECT routine_name, routine_definition
FROM information_schema.routines
WHERE routine_name = 'pay_awarded_offer';

-- Check recent admin_logs after test payment:
SELECT * FROM admin_logs 
WHERE action LIKE 'PAYMENT_%' 
ORDER BY created_at DESC 
LIMIT 5;
*/
