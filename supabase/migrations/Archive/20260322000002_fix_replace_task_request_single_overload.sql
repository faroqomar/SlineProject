-- Fix: "Could not choose the best candidate function between replace_task_request(..., p_price => integer, ...)
-- and replace_task_request(..., p_price => numeric, ...)". The app sends price as a number (double);
-- having two overloads causes ambiguity. Keep only the NUMERIC variant so the RPC has a single signature.

BEGIN;

-- Drop the integer overload if it exists (leaves only the numeric one)
DROP FUNCTION IF EXISTS public.replace_task_request(uuid, uuid, text, integer, integer);

-- Ensure the numeric overload exists (idempotent)
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

  IF NOT COALESCE(
    (SELECT (active_role = 'freelancer') FROM public.profiles WHERE id = v_me),
    false
  ) THEN
    RAISE EXCEPTION 'You need freelancer access to update offers.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id = p_task_id
      AND t.status = 'open'
      AND t.owner_id IS DISTINCT FROM v_me
  ) THEN
    RAISE EXCEPTION 'task_not_found_or_not_open_or_own_task';
  END IF;

  UPDATE public.task_requests
  SET status = 'withdrawn',
      updated_at = NOW()
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
  'Archive caller''s pending offer for the task and insert a replacement. Single overload (p_price numeric).';

GRANT EXECUTE ON FUNCTION public.replace_task_request(uuid, uuid, text, numeric, integer) TO authenticated;

COMMIT;
