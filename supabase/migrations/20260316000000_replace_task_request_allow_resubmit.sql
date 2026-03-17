-- Allow replace_task_request to also "resubmit" rejected/withdrawn offers:
-- update the existing row to status = 'pending' with new price/days/note
-- so the user can submit again after rejection without hitting the unique constraint.

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

  -- Update existing offer: pending (replace) or rejected/withdrawn (resubmit).
  -- Resubmit: set status = 'pending' so the row becomes the active offer again.
  UPDATE public.task_requests
  SET price = p_price,
      days = p_days,
      note = NULLIF(TRIM(p_message), ''),
      status = 'pending',
      updated_at = NOW()
  WHERE task_id = p_task_id
    AND (freelancer_id = v_me OR bidder_id = v_me)
    AND status IN ('pending', 'rejected', 'withdrawn');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'no_pending_offer_to_replace';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.replace_task_request(uuid, uuid, text, numeric, integer) IS
  'Update caller''s offer in place (price, days, note). Works for pending (replace) or rejected/withdrawn (resubmit). Sets status = pending.';
