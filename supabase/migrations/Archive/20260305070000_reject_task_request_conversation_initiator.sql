-- Fix: reject_task_request creates task-linked conversation with initiated_by = freelancer
-- so the guard "task owner cannot start a task-linked conversation" is satisfied.
-- The freelancer "initiated" the task interaction by submitting the offer; the owner
-- only posts the offer_rejected message.
BEGIN;

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

  -- Create or get task-linked conversation. Use initiated_by = v_freelancer so the
  -- conversations_before_insert_guard (non-owner starts task-linked) is satisfied.
  WITH ins AS (
    INSERT INTO public.conversations (id, user1_id, user2_id, task_id, initiated_by)
    VALUES (
      gen_random_uuid(),
      LEAST(v_owner, v_freelancer),
      GREATEST(v_owner, v_freelancer),
      p_task_id,
      v_freelancer
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

COMMENT ON FUNCTION public.reject_task_request(UUID, UUID) IS
  'Owner rejects a pending offer; creates/reuses task conversation with initiated_by=freelancer for guard compatibility; sends offer_rejected message and notification.';

COMMIT;
