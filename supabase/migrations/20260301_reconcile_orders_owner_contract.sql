BEGIN;

-- Canonical owner contract for tasks: owner_id is generated from COALESCE(client_id, user_id)
-- and is already populated/indexed in the live project. Remove legacy policy drift.
DROP POLICY IF EXISTS "Allow insert own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Allow update own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Allow delete own tasks" ON public.tasks;
DROP POLICY IF EXISTS tasks_insert_policy ON public.tasks;
DROP POLICY IF EXISTS tasks_insert_self ON public.tasks;
DROP POLICY IF EXISTS tasks_update_policy ON public.tasks;
DROP POLICY IF EXISTS tasks_delete_policy ON public.tasks;
DROP POLICY IF EXISTS tasks_delete_owner ON public.tasks;
DROP POLICY IF EXISTS tasks_select_authenticated_open_or_involved ON public.tasks;
DROP POLICY IF EXISTS tasks_update_involved ON public.tasks;

CREATE POLICY tasks_select_authenticated_open_or_involved
ON public.tasks
FOR SELECT
TO authenticated
USING (
  status = 'open'
  OR owner_id = auth.uid()
  OR freelancer_id = auth.uid()
  OR assigned_freelancer_id = auth.uid()
);

CREATE POLICY tasks_update_involved
ON public.tasks
FOR UPDATE
TO authenticated
USING (
  owner_id = auth.uid()
  OR freelancer_id = auth.uid()
  OR assigned_freelancer_id = auth.uid()
)
WITH CHECK (
  owner_id = auth.uid()
  OR freelancer_id = auth.uid()
  OR assigned_freelancer_id = auth.uid()
);

CREATE POLICY tasks_delete_owner
ON public.tasks
FOR DELETE
TO authenticated
USING (owner_id = auth.uid());

-- Canonical owner contract for offer visibility/mutations.
DROP POLICY IF EXISTS tr_insert ON public.task_requests;
DROP POLICY IF EXISTS tr_select ON public.task_requests;
DROP POLICY IF EXISTS tr_update_by_owner ON public.task_requests;

CREATE POLICY tr_insert
ON public.task_requests
FOR INSERT
TO authenticated
WITH CHECK (
  is_freelancer(auth.uid()) = true
  AND freelancer_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.tasks t
    WHERE t.id = task_requests.task_id
      AND t.status = 'open'
      AND t.owner_id <> auth.uid()
  )
);

CREATE POLICY tr_select
ON public.task_requests
FOR SELECT
TO authenticated
USING (
  freelancer_id = auth.uid()
  OR EXISTS (
    SELECT 1
    FROM public.tasks t
    WHERE t.id = task_requests.task_id
      AND t.owner_id = auth.uid()
  )
);

CREATE POLICY tr_update_by_owner
ON public.task_requests
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.tasks t
    WHERE t.id = task_requests.task_id
      AND t.owner_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.tasks t
    WHERE t.id = task_requests.task_id
      AND t.owner_id = auth.uid()
  )
);

-- Private helper for server-side notifications in auth-critical task request flows.
CREATE OR REPLACE FUNCTION public.private_create_notification(
  p_user_id UUID,
  p_title TEXT,
  p_message TEXT,
  p_type TEXT,
  p_related_entity_id UUID DEFAULT NULL,
  p_related_entity_type TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.notifications (
    user_id,
    title,
    message,
    type,
    related_entity_id,
    related_entity_type,
    metadata,
    is_read,
    created_at
  ) VALUES (
    p_user_id,
    p_title,
    p_message,
    p_type,
    p_related_entity_id,
    p_related_entity_type,
    COALESCE(p_metadata, '{}'::jsonb),
    FALSE,
    NOW()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.private_create_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.private_create_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) FROM anon;
REVOKE ALL ON FUNCTION public.private_create_notification(UUID, TEXT, TEXT, TEXT, UUID, TEXT, JSONB) FROM authenticated;

CREATE OR REPLACE FUNCTION public.task_requests_after_insert_notify_owner()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id UUID;
BEGIN
  IF NEW.deleted_at IS NOT NULL OR NEW.status <> 'pending' THEN
    RETURN NEW;
  END IF;

  SELECT owner_id
  INTO v_owner_id
  FROM public.tasks
  WHERE id = NEW.task_id;

  IF v_owner_id IS NULL OR v_owner_id = COALESCE(NEW.freelancer_id, NEW.bidder_id) THEN
    RETURN NEW;
  END IF;

  PERFORM public.private_create_notification(
    p_user_id => v_owner_id,
    p_title => 'New Bid on Task',
    p_message => 'You received a new bid on your task.',
    p_type => 'offer',
    p_related_entity_id => NEW.task_id,
    p_related_entity_type => 'task',
    p_metadata => jsonb_build_object(
      'task_id', NEW.task_id,
      'request_id', NEW.id,
      'event', 'task_request_submitted'
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_task_requests_after_insert_notify_owner ON public.task_requests;
CREATE TRIGGER trg_task_requests_after_insert_notify_owner
AFTER INSERT ON public.task_requests
FOR EACH ROW
EXECUTE FUNCTION public.task_requests_after_insert_notify_owner();

-- Canonical auth-critical accept path. Keep the legacy one-arg function as a compatibility wrapper.
CREATE OR REPLACE FUNCTION public.accept_task_request(
  p_task_id UUID,
  p_request_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_owner UUID;
  v_freelancer UUID;
  v_conversation UUID;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  SELECT owner_id
  INTO v_owner
  FROM public.tasks
  WHERE id = p_task_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'task_not_found';
  END IF;

  IF v_owner IS DISTINCT FROM v_me THEN
    RAISE EXCEPTION 'only task owner can accept';
  END IF;

  UPDATE public.task_requests
  SET status = 'accepted',
      updated_at = NOW(),
      initiated_by = v_me
  WHERE id = p_request_id
    AND task_id = p_task_id
    AND status = 'pending'
  RETURNING COALESCE(freelancer_id, bidder_id)
  INTO v_freelancer;

  IF v_freelancer IS NULL THEN
    RAISE EXCEPTION 'request not found or already processed';
  END IF;

  UPDATE public.task_requests
  SET status = 'rejected',
      updated_at = NOW(),
      initiated_by = v_me
  WHERE task_id = p_task_id
    AND id <> p_request_id
    AND status = 'pending';

  UPDATE public.tasks
  SET status = CASE WHEN status = 'open' THEN 'assigned' ELSE status END,
      freelancer_id = v_freelancer,
      assigned_freelancer_id = v_freelancer,
      updated_at = NOW()
  WHERE id = p_task_id;

  WITH ins AS (
    INSERT INTO public.conversations (id, user1_id, user2_id, task_id, initiated_by)
    VALUES (
      gen_random_uuid(),
      LEAST(v_owner, v_freelancer),
      GREATEST(v_owner, v_freelancer),
      p_task_id,
      v_owner
    )
    ON CONFLICT (task_id, user1_id, user2_id) DO NOTHING
    RETURNING id
  )
  SELECT id INTO v_conversation FROM ins
  UNION ALL
  SELECT id FROM public.conversations
  WHERE task_id = p_task_id
    AND user1_id = LEAST(v_owner, v_freelancer)
    AND user2_id = GREATEST(v_owner, v_freelancer)
  LIMIT 1;

  PERFORM public.fn_log_acceptance_message(
    p_conversation_id := v_conversation,
    p_owner := v_owner,
    p_freelancer := v_freelancer,
    p_task_id := p_task_id
  );

  PERFORM public.private_create_notification(
    p_user_id => v_freelancer,
    p_title => 'Offer Accepted',
    p_message => 'Your offer has been accepted!',
    p_type => 'offer',
    p_related_entity_id => p_request_id,
    p_related_entity_type => 'task_request',
    p_metadata => jsonb_build_object(
      'task_id', p_task_id,
      'request_id', p_request_id,
      'event', 'task_request_accepted',
      'conversation_id', v_conversation
    )
  );

  RETURN v_conversation;
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_task_request(
  p_request_id UUID
)
RETURNS public.task_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_task_id UUID;
  v_row public.task_requests;
BEGIN
  SELECT task_id INTO v_task_id
  FROM public.task_requests
  WHERE id = p_request_id;

  IF v_task_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;

  PERFORM public.accept_task_request(v_task_id, p_request_id);

  SELECT * INTO v_row
  FROM public.task_requests
  WHERE id = p_request_id;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_task_request(
  p_task_id UUID,
  p_request_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_owner UUID;
  v_freelancer UUID;
  v_conversation UUID;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  SELECT owner_id
  INTO v_owner
  FROM public.tasks
  WHERE id = p_task_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'task_not_found';
  END IF;

  IF v_owner IS DISTINCT FROM v_me THEN
    RAISE EXCEPTION 'only task owner can reject';
  END IF;

  UPDATE public.task_requests
  SET status = 'rejected',
      updated_at = NOW(),
      initiated_by = v_me
  WHERE id = p_request_id
    AND task_id = p_task_id
    AND status = 'pending'
  RETURNING COALESCE(freelancer_id, bidder_id)
  INTO v_freelancer;

  IF v_freelancer IS NULL THEN
    RAISE EXCEPTION 'request not found or already processed';
  END IF;

  WITH ins AS (
    INSERT INTO public.conversations (id, user1_id, user2_id, task_id, initiated_by)
    VALUES (
      gen_random_uuid(),
      LEAST(v_owner, v_freelancer),
      GREATEST(v_owner, v_freelancer),
      p_task_id,
      v_owner
    )
    ON CONFLICT (task_id, user1_id, user2_id) DO NOTHING
    RETURNING id
  )
  SELECT id INTO v_conversation FROM ins
  UNION ALL
  SELECT id FROM public.conversations
  WHERE task_id = p_task_id
    AND user1_id = LEAST(v_owner, v_freelancer)
    AND user2_id = GREATEST(v_owner, v_freelancer)
  LIMIT 1;

  INSERT INTO public.messages (
    id,
    conversation_id,
    sender_id,
    receiver_id,
    content,
    message_type,
    created_at
  ) VALUES (
    gen_random_uuid(),
    v_conversation,
    v_owner,
    v_freelancer,
    'The offer was rejected by the client.',
    'offer_rejected',
    NOW()
  );

  PERFORM public.private_create_notification(
    p_user_id => v_freelancer,
    p_title => 'Offer Rejected',
    p_message => 'Your offer was not selected.',
    p_type => 'offer',
    p_related_entity_id => p_request_id,
    p_related_entity_type => 'task_request',
    p_metadata => jsonb_build_object(
      'task_id', p_task_id,
      'request_id', p_request_id,
      'event', 'task_request_rejected',
      'conversation_id', v_conversation
    )
  );

  RETURN v_conversation;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_task_request(
  p_request_id UUID
)
RETURNS public.task_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_task_id UUID;
  v_row public.task_requests;
BEGIN
  SELECT task_id INTO v_task_id
  FROM public.task_requests
  WHERE id = p_request_id;

  IF v_task_id IS NULL THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;

  PERFORM public.reject_task_request(v_task_id, p_request_id);

  SELECT * INTO v_row
  FROM public.task_requests
  WHERE id = p_request_id;

  RETURN v_row;
END;
$$;

-- Align adjacent tender payment functions with the canonical owner contract.
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
  v_freelancer UUID;
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

  v_freelancer := COALESCE(v_request.freelancer_id, v_request.bidder_id);

  UPDATE public.task_requests
  SET status = 'accepted',
      payment_status = 'unpaid',
      awarded_at = v_now,
      payment_deadline = v_deadline,
      awarded_by = p_client_id,
      updated_at = v_now
  WHERE id = p_request_id;

  UPDATE public.tasks
  SET freelancer_id = v_freelancer,
      assigned_freelancer_id = v_freelancer,
      status = 'assigned',
      updated_at = v_now
  WHERE id = v_request.task_id;

  UPDATE public.task_requests
  SET status = 'rejected',
      updated_at = v_now
  WHERE task_id = v_request.task_id
    AND status = 'pending'
    AND id <> p_request_id;

  PERFORM public.private_create_notification(
    p_user_id => v_freelancer,
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

  UPDATE public.tasks
  SET status = 'in_progress',
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

CREATE OR REPLACE FUNCTION public.get_client_awarded_unpaid_offers(
  p_client_id UUID DEFAULT auth.uid()
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
  WHERE t.owner_id = p_client_id
    AND tr.status = 'accepted'
    AND tr.payment_status = 'unpaid'
    AND tr.payment_deadline > NOW()
  ORDER BY tr.awarded_at DESC;
$$;

COMMIT;
