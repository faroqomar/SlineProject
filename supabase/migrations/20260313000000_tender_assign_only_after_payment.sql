-- Tender: never assign task to freelancer before payment.
-- Award = reserve (task status 'assigned', no freelancer_id set).
-- Assign (freelancer_id, assigned_freelancer_id, in_progress) only in pay_awarded_offer after payment.
--
-- Drop constraint that required freelancer_id when status = 'assigned', so we can use
-- status = 'assigned' for "awarded, pending payment" (no freelancer set until pay).
BEGIN;

ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_assigned_requires_freelancer;

CREATE OR REPLACE FUNCTION public.award_task_offer(
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
  v_deadline TIMESTAMPTZ := v_now + INTERVAL '24 hours';
BEGIN
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
    AND owner_id = p_client_id;

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

  -- Mark offer as awarded (accepted, unpaid). Do NOT assign task to freelancer yet.
  UPDATE public.task_requests
  SET status = 'accepted',
      payment_status = 'unpaid',
      awarded_at = v_now,
      payment_deadline = v_deadline,
      awarded_by = p_client_id,
      updated_at = v_now
  WHERE id = p_request_id;

  -- Reserve task (no new offers) but do not set freelancer_id/assigned_freelancer_id.
  -- Assignment happens only in pay_awarded_offer after payment.
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
    p_user_id => p_client_id,
    p_title => 'Complete payment to start work',
    p_message => 'Pay within 24 hours to activate the awarded offer.',
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
BEGIN
  SELECT * INTO v_request
  FROM public.task_requests
  WHERE id = p_request_id
    AND status = 'accepted'
    AND payment_status = 'unpaid';

  IF v_request IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found');
  END IF;

  IF v_request.payment_deadline < v_now THEN
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

    RETURN jsonb_build_object('success', false, 'error', 'Payment deadline expired', 'expired', true);
  END IF;

  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = v_request.task_id
    AND owner_id = p_client_id;

  IF v_task IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only task owner can pay');
  END IF;

  v_freelancer := COALESCE(v_request.freelancer_id, v_request.bidder_id);

  UPDATE public.task_requests
  SET payment_status = 'held',
      updated_at = v_now
  WHERE id = p_request_id;

  -- Assign task to freelancer only after payment is confirmed.
  UPDATE public.tasks
  SET freelancer_id = v_freelancer,
      assigned_freelancer_id = v_freelancer,
      status = 'in_progress',
      updated_at = v_now
  WHERE id = v_request.task_id;

  PERFORM public.private_create_notification(
    p_user_id => v_freelancer,
    p_title => 'Payment confirmed - Start working!',
    p_message => 'Client has paid. Escrow is held and work can begin.',
    p_type => 'work_active',
    p_related_entity_id => p_request_id,
    p_related_entity_type => 'task_request',
    p_metadata => jsonb_build_object(
      'task_id', v_request.task_id,
      'request_id', p_request_id
    )
  );

  RETURN jsonb_build_object('success', true, 'payment_status', 'held');
END;
$$;

COMMENT ON FUNCTION public.award_task_offer(UUID, UUID) IS
  'Awards an offer without payment. Reserves task (status=assigned) but does not assign freelancer; assignment happens in pay_awarded_offer after payment.';
COMMENT ON FUNCTION public.pay_awarded_offer(UUID, UUID) IS
  'Completes payment for an awarded offer. Assigns freelancer and activates work (call only after payment is confirmed).';

COMMIT;
