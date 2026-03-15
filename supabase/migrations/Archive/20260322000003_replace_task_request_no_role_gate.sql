-- Allow replacing own bid regardless of profile.active_role.
-- The RPC already enforces: caller = p_freelancer_id (offer owner) and task open/not own.
-- Requiring active_role = 'freelancer' blocks users who are viewing as "client" from updating their bid.

CREATE OR REPLACE FUNCTION public.replace_task_request(
  p_task_id uuid,
  p_freelancer_id uuid,
  p_message text,
  p_price numeric,
  p_days integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me uuid := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_freelancer_id IS DISTINCT FROM v_me THEN
    RAISE EXCEPTION 'only the offer owner can replace their offer';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = p_task_id
      AND t.status = 'open'
      AND t.owner_id IS DISTINCT FROM v_me
  ) THEN
    RAISE EXCEPTION 'task_not_found_or_not_open_or_own_task';
  END IF;

  -- Set deleted_at so uq_task_requests_one_active_per_freelancer (WHERE deleted_at IS NULL) allows the new row
  UPDATE public.task_requests
  SET status = 'withdrawn',
      updated_at = NOW(),
      deleted_at = NOW()
  WHERE task_id = p_task_id
    AND (freelancer_id = v_me OR bidder_id = v_me)
    AND status = 'pending';

  INSERT INTO public.task_requests (
    task_id,
    bidder_id,
    freelancer_id,
    price,
    days,
    note,
    status,
    payment_status
  )
  VALUES (
    p_task_id,
    v_me,
    v_me,
    p_price,
    p_days,
    NULLIF(TRIM(p_message), ''),
    'pending',
    'unpaid'
  );
END;
$$;

COMMENT ON FUNCTION public.replace_task_request(uuid, uuid, text, numeric, integer) IS
  'Replace caller''s pending offer for the task. No active_role gate: caller must be offer owner (p_freelancer_id = auth.uid()).';
