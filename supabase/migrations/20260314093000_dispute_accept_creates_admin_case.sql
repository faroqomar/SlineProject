-- Ensure accepting a dispute opens or reuses an admin case so it appears in Cases.

CREATE OR REPLACE FUNCTION public.admin_accept_dispute(
  p_admin_id uuid,
  p_dispute_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current text;
  v_task_id uuid;
  v_direct_offer_id uuid;
  v_reason text;
  v_case_id uuid;
  v_case_created boolean := false;
BEGIN
  IF p_admin_id IS NULL OR p_dispute_id IS NULL THEN
    RAISE EXCEPTION 'Invalid input';
  END IF;

  SELECT status::text, task_id, direct_offer_id, reason
  INTO v_current, v_task_id, v_direct_offer_id, v_reason
  FROM public.disputes
  WHERE id = p_dispute_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dispute not found';
  END IF;

  IF v_current <> 'open' THEN
    RAISE EXCEPTION 'Only open disputes can be accepted (current: %)', v_current;
  END IF;

  UPDATE public.disputes
  SET status = 'active'::public.dispute_status_enum
  WHERE id = p_dispute_id;

  SELECT c.id
  INTO v_case_id
  FROM public.admin_cases c
  JOIN public.admin_case_entities e
    ON e.case_id = c.id
  WHERE e.entity_type = 'dispute'
    AND e.entity_id = p_dispute_id
    AND c.status::text IN ('open', 'in_progress', 'pending')
  ORDER BY c.created_at DESC
  LIMIT 1;

  IF v_case_id IS NULL THEN
    INSERT INTO public.admin_cases (subject, source, status, priority, assignee_id)
    VALUES (
      COALESCE(NULLIF(trim(v_reason), ''), 'Dispute investigation') || ' (' || left(p_dispute_id::text, 8) || ')',
      'dispute',
      'open',
      'high',
      p_admin_id
    )
    RETURNING id INTO v_case_id;

    v_case_created := true;
  END IF;

  INSERT INTO public.admin_case_entities (case_id, entity_type, entity_id)
  VALUES (v_case_id, 'dispute', p_dispute_id)
  ON CONFLICT (case_id, entity_type, entity_id) DO NOTHING;

  IF v_task_id IS NOT NULL THEN
    INSERT INTO public.admin_case_entities (case_id, entity_type, entity_id)
    VALUES (v_case_id, 'task', v_task_id)
    ON CONFLICT (case_id, entity_type, entity_id) DO NOTHING;
  END IF;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.disputes.accept',
    p_admin_id,
    'dispute',
    p_dispute_id,
    jsonb_build_object(
      'from_status', 'open',
      'to_status', 'active',
      'case_id', v_case_id,
      'case_created', v_case_created,
      'task_id', v_task_id,
      'direct_offer_id', v_direct_offer_id
    )
  );
END;
$$;
