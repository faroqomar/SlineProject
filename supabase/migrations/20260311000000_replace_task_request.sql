-- Add replace_task_request RPC for tender offer replacement (documented in SUPABASE_SETUP.md).
-- Contract: caller = freelancer; archive current pending offer and insert replacement; no return row.
BEGIN;

CREATE OR REPLACE FUNCTION public.replace_task_request(
  p_task_id UUID,
  p_freelancer_id UUID,
  p_message TEXT,
  p_price NUMERIC,
  p_days INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  IF p_freelancer_id IS DISTINCT FROM v_me THEN
    RAISE EXCEPTION 'only the offer owner can replace their offer';
  END IF;

  -- Enforce freelancer role so RLS-equivalent check holds in SECURITY DEFINER context
  IF NOT COALESCE(
    (SELECT (active_role = 'freelancer') FROM public.profiles WHERE id = v_me),
    false
  ) THEN
    RAISE EXCEPTION 'only freelancers can replace offers';
  END IF;

  -- Ensure task exists, is open, and is not owned by caller (so they can bid)
  IF NOT EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = p_task_id
      AND t.status = 'open'
      AND t.owner_id IS DISTINCT FROM v_me
  ) THEN
    RAISE EXCEPTION 'task_not_found_or_not_open_or_own_task';
  END IF;

  -- Withdraw existing pending offer for this task and freelancer
  UPDATE public.task_requests
  SET status = 'withdrawn',
      updated_at = NOW()
  WHERE task_id = p_task_id
    AND (freelancer_id = v_me OR bidder_id = v_me)
    AND status = 'pending';

  -- Insert replacement offer (same task, same freelancer, new price/days/message)
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

COMMENT ON FUNCTION public.replace_task_request(UUID, UUID, TEXT, NUMERIC, INTEGER) IS
  'Archive caller''s pending offer for the task and insert a replacement with new price/days/message. Client must re-fetch active offer after success.';

GRANT EXECUTE ON FUNCTION public.replace_task_request(UUID, UUID, TEXT, NUMERIC, INTEGER) TO authenticated;

COMMIT;
