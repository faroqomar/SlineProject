-- Proposals: bind RPC authorization to auth.uid() so caller-supplied actor IDs cannot spoof access.
-- Replaces award_task_offer, pay_awarded_offer, cancel_awarded_offer, get_client_awarded_unpaid_offers,
-- get_freelancer_awarded_unpaid_offers to use session user only.
BEGIN;

-- award_task_offer: resolve owner from auth.uid(), ignore p_client_id for auth
CREATE OR REPLACE FUNCTION public.award_task_offer(
  p_request_id UUID,
  p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id UUID := auth.uid();
  v_request RECORD;
  v_task RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_deadline TIMESTAMPTZ := v_now + INTERVAL '24 hours';
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

  UPDATE public.task_requests
  SET status = 'accepted',
      payment_status = 'unpaid',
      awarded_at = v_now,
      payment_deadline = v_deadline,
      awarded_by = v_owner_id,
      updated_at = v_now
  WHERE id = p_request_id;

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

-- pay_awarded_offer: resolve owner from auth.uid()
CREATE OR REPLACE FUNCTION public.pay_awarded_offer(
  p_request_id UUID,
  p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id UUID := auth.uid();
  v_request RECORD;
  v_task RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_freelancer UUID;
BEGIN
  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

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
    AND owner_id = v_owner_id;

  IF v_task IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only task owner can pay');
  END IF;

  v_freelancer := COALESCE(v_request.freelancer_id, v_request.bidder_id);

  UPDATE public.task_requests
  SET payment_status = 'held',
      updated_at = v_now
  WHERE id = p_request_id;

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

-- cancel_awarded_offer: resolve owner from auth.uid()
CREATE OR REPLACE FUNCTION public.cancel_awarded_offer(
  p_request_id UUID,
  p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id UUID := auth.uid();
  v_request RECORD;
  v_task RECORD;
  v_freelancer UUID;
BEGIN
  IF v_owner_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_request
  FROM public.task_requests
  WHERE id = p_request_id
    AND status = 'accepted'
    AND payment_status = 'unpaid';

  IF v_request IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Request not found or not in awarded-unpaid state');
  END IF;

  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = v_request.task_id;

  IF v_task IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Task not found');
  END IF;

  IF v_task.owner_id IS DISTINCT FROM v_owner_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only task owner can cancel the award');
  END IF;

  v_freelancer := COALESCE(v_request.freelancer_id, v_request.bidder_id);

  UPDATE public.task_requests
  SET status = 'rejected',
      payment_status = NULL,
      payment_deadline = NULL,
      awarded_at = NULL,
      awarded_by = NULL,
      updated_at = NOW(),
      deleted_at = NOW()
  WHERE id = p_request_id;

  UPDATE public.tasks
  SET status = 'open',
      freelancer_id = NULL,
      assigned_freelancer_id = NULL,
      updated_at = NOW()
  WHERE id = v_request.task_id;

  IF v_freelancer IS NOT NULL THEN
    PERFORM public.private_create_notification(
      p_user_id => v_freelancer,
      p_title => 'Award cancelled',
      p_message => 'The client cancelled the award. The task is open again.',
      p_type => 'offer_award_cancelled',
      p_related_entity_id => p_request_id,
      p_related_entity_type => 'task_request',
      p_metadata => jsonb_build_object(
        'task_id', v_request.task_id,
        'request_id', p_request_id
      )
    );
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- get_client_awarded_unpaid_offers: bind to auth.uid(), ignore parameter for auth
CREATE OR REPLACE FUNCTION public.get_client_awarded_unpaid_offers(
  p_client_id UUID DEFAULT NULL
)
RETURNS TABLE (
  request_id UUID,
  task_id UUID,
  freelancer_id UUID,
  price BIGINT,
  days INTEGER,
  note TEXT,
  awarded_at TIMESTAMPTZ,
  payment_deadline TIMESTAMPTZ,
  task_title TEXT,
  freelancer_name TEXT,
  freelancer_avatar TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tr.id AS request_id,
    tr.task_id,
    COALESCE(tr.freelancer_id, tr.bidder_id) AS freelancer_id,
    tr.price,
    tr.days,
    tr.note,
    tr.awarded_at,
    tr.payment_deadline,
    t.title AS task_title,
    p.full_name AS freelancer_name,
    p.avatar_url AS freelancer_avatar
  FROM public.task_requests tr
  JOIN public.tasks t ON t.id = tr.task_id
  JOIN public.profiles p ON p.id = COALESCE(tr.freelancer_id, tr.bidder_id)
  WHERE t.owner_id = auth.uid()
    AND tr.status = 'accepted'
    AND tr.payment_status = 'unpaid'
    AND (tr.payment_deadline IS NULL OR tr.payment_deadline > NOW())
  ORDER BY tr.awarded_at DESC;
$$;

-- get_freelancer_awarded_unpaid_offers: bind to auth.uid(), ignore parameter for auth
CREATE OR REPLACE FUNCTION public.get_freelancer_awarded_unpaid_offers(
  p_freelancer_id UUID DEFAULT NULL
)
RETURNS TABLE (
  request_id UUID,
  task_id UUID,
  client_id UUID,
  price BIGINT,
  days INTEGER,
  note TEXT,
  awarded_at TIMESTAMPTZ,
  payment_deadline TIMESTAMPTZ,
  task_title TEXT,
  client_name TEXT,
  client_avatar TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tr.id AS request_id,
    tr.task_id,
    t.owner_id AS client_id,
    tr.price,
    tr.days,
    tr.note,
    tr.awarded_at,
    tr.payment_deadline,
    t.title AS task_title,
    p.full_name AS client_name,
    p.avatar_url AS client_avatar
  FROM public.task_requests tr
  JOIN public.tasks t ON t.id = tr.task_id
  JOIN public.profiles p ON p.id = t.owner_id
  WHERE COALESCE(tr.freelancer_id, tr.bidder_id) = auth.uid()
    AND tr.status = 'accepted'
    AND tr.payment_status = 'unpaid'
    AND (tr.payment_deadline IS NULL OR tr.payment_deadline > NOW())
  ORDER BY tr.awarded_at DESC;
$$;

COMMENT ON FUNCTION public.award_task_offer(UUID, UUID) IS
  'Awards an offer (owner only; auth from session). Reserves task; assignment in pay_awarded_offer.';
COMMENT ON FUNCTION public.pay_awarded_offer(UUID, UUID) IS
  'Completes payment for awarded offer (owner only; auth from session).';
COMMENT ON FUNCTION public.cancel_awarded_offer(UUID, UUID) IS
  'Cancels awarded-unpaid offer (owner only; auth from session).';
COMMENT ON FUNCTION public.get_client_awarded_unpaid_offers(UUID) IS
  'Returns awarded-unpaid offers for the current user as client (auth from session).';
COMMENT ON FUNCTION public.get_freelancer_awarded_unpaid_offers(UUID) IS
  'Returns awarded-unpaid offers for the current user as freelancer (auth from session).';

COMMIT;
