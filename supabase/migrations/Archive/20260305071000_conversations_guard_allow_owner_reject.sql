-- Allow task owner to create task-linked conversation when called from reject_task_request.
-- Live guard enforces: (1) initiated_by = auth.uid(); (2) task-linked: initiator must not be owner.
-- This migration: adds exception for (2) when app.allow_owner_task_conversation = 'true'.
-- Reject RPC sets that GUC and uses initiated_by = v_owner so both checks pass.
-- Note: If your live conversations_before_insert_guard() has extra logic (e.g. DM/favorites),
-- merge it into this function before applying.

BEGIN;

-- 1) Replace conversations guard: add exception for owner when GUC is set
CREATE OR REPLACE FUNCTION public.conversations_before_insert_guard()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_task_owner_id uuid;
BEGIN
  -- Initiated_by must equal current user (cannot create conversation "as" someone else)
  IF NEW.initiated_by IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'initiated_by must equal current user';
  END IF;

  -- Task-linked: only non-owner may initiate, unless this is the reject flow (GUC set)
  IF NEW.task_id IS NOT NULL THEN
    SELECT owner_id INTO v_task_owner_id FROM public.tasks WHERE id = NEW.task_id;
    IF FOUND AND v_task_owner_id = auth.uid() THEN
      IF current_setting('app.allow_owner_task_conversation', true) IS DISTINCT FROM 'true' THEN
        RAISE EXCEPTION 'task owner cannot start a task-linked conversation';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.conversations_before_insert_guard() IS
  'BEFORE INSERT guard: initiated_by must equal auth.uid(); task-linked only non-owner can initiate unless app.allow_owner_task_conversation=true (reject_task_request).';

-- 2) reject_task_request: set GUC and create conversation with initiated_by = v_owner
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

  -- Allow owner to create task-linked conversation for this INSERT only (guard checks GUC)
  PERFORM set_config('app.allow_owner_task_conversation', 'true', true);

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

COMMENT ON FUNCTION public.reject_task_request(UUID, UUID) IS
  'Owner rejects a pending offer; sets app.allow_owner_task_conversation so guard allows owner-created task convo; sends offer_rejected message and notification.';

COMMIT;
