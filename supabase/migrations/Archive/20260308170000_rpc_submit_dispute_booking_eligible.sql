-- Allow dispute when task is in_progress/delivered OR any booking for that task is active/delivered.
-- Fixes: "Entity not eligible for dispute: task must be in progress or delivered" when user reports
-- from a booking that is active/delivered but the task row has a different status (e.g. awarded).
CREATE OR REPLACE FUNCTION public.rpc_submit_dispute(
  p_task_id uuid DEFAULT NULL,
  p_direct_offer_id uuid DEFAULT NULL,
  p_reason text DEFAULT NULL,
  p_defendant_id uuid DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  _uid uuid := auth.uid();
  _status text;
  _dispute_id uuid;
  _task_eligible boolean := false;
  _booking_eligible boolean := false;
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF (p_task_id IS NULL) = (p_direct_offer_id IS NULL) THEN
    RAISE EXCEPTION 'Exactly one of task_id or direct_offer_id must be provided';
  END IF;

  IF p_reason IS NULL OR trim(p_reason) = '' THEN
    RAISE EXCEPTION 'Reason is required';
  END IF;

  IF p_task_id IS NOT NULL THEN
    -- Task must exist
    SELECT t.status::text INTO _status FROM public.tasks t WHERE t.id = p_task_id;
    IF _status IS NULL THEN
      RAISE EXCEPTION 'Task not found';
    END IF;
    -- Eligible if task is in_progress/delivered OR any booking for this task is active/delivered
    _task_eligible := _status IN ('in_progress', 'delivered');
    SELECT EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.task_id = p_task_id AND b.status IN ('active', 'delivered')
    ) INTO _booking_eligible;
    IF NOT _task_eligible AND NOT _booking_eligible THEN
      RAISE EXCEPTION 'Entity not eligible for dispute: task must be in progress or delivered';
    END IF;
    IF EXISTS (SELECT 1 FROM public.disputes WHERE task_id = p_task_id AND status IN ('open', 'active')) THEN
      RAISE EXCEPTION 'An open or active dispute already exists for this task';
    END IF;

    INSERT INTO public.disputes (complainant_id, task_id, reason, status, defendant_id)
    VALUES (_uid, p_task_id, trim(p_reason), 'open'::public.dispute_status_enum, p_defendant_id)
    RETURNING id INTO _dispute_id;
  ELSE
    -- Direct offer: eligible status active or delivered
    SELECT d.status::text INTO _status FROM public.direct_offers d WHERE d.id = p_direct_offer_id;
    IF _status IS NULL THEN
      RAISE EXCEPTION 'Direct offer not found';
    END IF;
    IF _status NOT IN ('active', 'delivered') THEN
      RAISE EXCEPTION 'Entity not eligible for dispute: direct offer must be active or delivered';
    END IF;
    IF EXISTS (SELECT 1 FROM public.disputes WHERE direct_offer_id = p_direct_offer_id AND status IN ('open', 'active')) THEN
      RAISE EXCEPTION 'An open or active dispute already exists for this direct offer';
    END IF;

    INSERT INTO public.disputes (complainant_id, direct_offer_id, reason, status, defendant_id)
    VALUES (_uid, p_direct_offer_id, trim(p_reason), 'open'::public.dispute_status_enum, p_defendant_id)
    RETURNING id INTO _dispute_id;
  END IF;

  RETURN _dispute_id;
END;
$$;

COMMENT ON FUNCTION public.rpc_submit_dispute(uuid, uuid, text, uuid) IS
  'Submit a dispute for a task or direct_offer. Task branch: eligible if task in_progress|delivered OR any booking for that task is active|delivered. Direct offer: active|delivered. Enforces one open/active per entity.';
