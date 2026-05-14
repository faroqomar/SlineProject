-- Plan 14a: Frozen guards on submit_delivery and request_revision; partial unique indexes; dispute insert guard.
-- Spec: Sline_everything/AppDiagram/All_Diagrams/14a_dispute-entity-freeze-integration.md
-- rpc_submit_delivery was only in Archive (20260224); restored here with Frozen guard. task + booking branches only.

-- 6.0/6.1 — Restore rpc_submit_delivery with Frozen guard at start (task, booking)
CREATE OR REPLACE FUNCTION public.rpc_submit_delivery(
  entity_type text,
  entity_id uuid,
  note text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  _freelancer_id uuid;
  _note text := note;
  _booking_status text;
  _task_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Frozen guard: block when entity has open or active dispute
  IF entity_type = 'task' THEN
    IF EXISTS (SELECT 1 FROM public.disputes WHERE task_id = entity_id AND status IN ('open', 'active')) THEN
      RAISE EXCEPTION 'Cannot submit delivery: dispute in progress';
    END IF;
  ELSIF entity_type = 'booking' THEN
    SELECT task_id INTO _task_id FROM public.bookings WHERE id = entity_id;
    IF _task_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.disputes WHERE task_id = _task_id AND status IN ('open', 'active')) THEN
      RAISE EXCEPTION 'Cannot submit delivery: dispute in progress';
    END IF;
  END IF;

  IF entity_type = 'task' THEN
    SELECT assigned_freelancer_id INTO _freelancer_id
    FROM public.tasks
    WHERE id = entity_id;

    IF _freelancer_id <> auth.uid() THEN
      RAISE EXCEPTION 'Not authorized';
    END IF;

    UPDATE public.tasks
    SET status = 'delivered',
        delivered_at = now(),
        review_expires_at = (now() + interval '3 days'),
        revision_note = _note
    WHERE id = entity_id;
  ELSIF entity_type = 'booking' THEN
    SELECT b.provider_id, b.status::text
    INTO _freelancer_id, _booking_status
    FROM public.bookings b
    WHERE b.id = entity_id;

    IF _freelancer_id <> auth.uid() THEN
      RAISE EXCEPTION 'Not authorized';
    END IF;

    IF _booking_status IN ('confirmed', 'paid_request_pending') THEN
      UPDATE public.bookings
      SET status = 'active'
      WHERE id = entity_id;
      _booking_status := 'active';
    END IF;

    IF _booking_status NOT IN ('active', 'in_progress') THEN
      RAISE EXCEPTION 'Invalid booking status for delivery submit: %', _booking_status;
    END IF;

    UPDATE public.bookings
    SET status = 'delivered',
        delivered_at = now(),
        review_expires_at = (now() + interval '3 days'),
        revision_note = _note
    WHERE id = entity_id;
  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;
END;
$function$;

COMMENT ON FUNCTION public.rpc_submit_delivery(text, uuid, text) IS
  'Mark work as delivered; blocks when dispute is open or active (Frozen). Task and booking branches.';

-- 6.2 — Frozen guard in rpc_request_revision (task, booking)
CREATE OR REPLACE FUNCTION public.rpc_request_revision(
  entity_type text,
  entity_id uuid,
  p_note text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  _client_id uuid;
  _owner_id uuid;
  _status text;
  _revisions_used int;
  _revisions_total int;
  _task_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Frozen guard: block when entity has open or active dispute
  IF entity_type = 'task' THEN
    IF EXISTS (SELECT 1 FROM public.disputes WHERE task_id = entity_id AND status IN ('open', 'active')) THEN
      RAISE EXCEPTION 'Cannot request revision: dispute in progress';
    END IF;
  ELSIF entity_type = 'booking' THEN
    SELECT task_id INTO _task_id FROM public.bookings WHERE id = entity_id;
    IF _task_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.disputes WHERE task_id = _task_id AND status IN ('open', 'active')) THEN
      RAISE EXCEPTION 'Cannot request revision: dispute in progress';
    END IF;
  END IF;

  IF entity_type = 'task' THEN
    SELECT t.client_id, t.owner_id, t.status::text, COALESCE(t.revisions_used, 0), COALESCE(t.revisions_total, 0)
    INTO _client_id, _owner_id, _status, _revisions_used, _revisions_total
    FROM public.tasks t
    WHERE t.id = entity_id;
    IF _client_id IS NULL THEN _client_id := _owner_id; END IF;
    IF _client_id <> auth.uid() THEN
      RAISE EXCEPTION 'Only client can request revision';
    END IF;
    IF _status IS NULL THEN
      RAISE EXCEPTION 'Task not found';
    END IF;
    IF _status <> 'delivered' THEN
      RAISE EXCEPTION 'Can only request revision on delivered work';
    END IF;
    IF _revisions_used >= _revisions_total THEN
      RAISE EXCEPTION 'No revisions remaining';
    END IF;
    UPDATE public.tasks
    SET status = 'active',
        delivered_at = NULL,
        review_expires_at = NULL,
        revision_note = p_note,
        revisions_used = _revisions_used + 1,
        revision_requested_at = now()
    WHERE id = entity_id;
  ELSIF entity_type = 'booking' THEN
    SELECT b.client_id, b.status::text, COALESCE(b.revisions_used, 0), COALESCE(b.revisions_total, 0)
    INTO _client_id, _status, _revisions_used, _revisions_total
    FROM public.bookings b
    WHERE b.id = entity_id;
    IF _client_id <> auth.uid() THEN
      RAISE EXCEPTION 'Only client can request revision';
    END IF;
    IF _status IS NULL THEN
      RAISE EXCEPTION 'Booking not found';
    END IF;
    IF _status <> 'delivered' THEN
      RAISE EXCEPTION 'Can only request revision on delivered work';
    END IF;
    IF _revisions_used >= _revisions_total THEN
      RAISE EXCEPTION 'No revisions remaining';
    END IF;
    UPDATE public.bookings
    SET status = 'active',
        delivered_at = NULL,
        review_expires_at = NULL,
        revision_note = p_note,
        revisions_used = _revisions_used + 1,
        revision_requested_at = now()
    WHERE id = entity_id;
  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.rpc_request_revision(text, uuid, text) IS
  'Client requests revision on delivered work. Blocks when dispute open/active. Enforces status=delivered and revisions_used < revisions_total.';

-- 6.3 — Partial unique indexes: one open/active dispute per task, per direct_offer
CREATE UNIQUE INDEX IF NOT EXISTS uq_disputes_one_open_active_per_task
  ON public.disputes (task_id)
  WHERE task_id IS NOT NULL AND status IN ('open', 'active');

CREATE UNIQUE INDEX IF NOT EXISTS uq_disputes_one_open_active_per_direct_offer
  ON public.disputes (direct_offer_id)
  WHERE direct_offer_id IS NOT NULL AND status IN ('open', 'active');

-- 6.4 — Dispute insert guard: rpc_submit_dispute (eligibility + single open/active per entity)
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
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Exactly one of task_id or direct_offer_id
  IF (p_task_id IS NULL) = (p_direct_offer_id IS NULL) THEN
    RAISE EXCEPTION 'Exactly one of task_id or direct_offer_id must be provided';
  END IF;

  IF p_reason IS NULL OR trim(p_reason) = '' THEN
    RAISE EXCEPTION 'Reason is required';
  END IF;

  IF p_task_id IS NOT NULL THEN
    -- Task: eligible status in_progress or delivered
    SELECT t.status::text INTO _status FROM public.tasks t WHERE t.id = p_task_id;
    IF _status IS NULL THEN
      RAISE EXCEPTION 'Task not found';
    END IF;
    IF _status NOT IN ('in_progress', 'delivered') THEN
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
  'Submit a dispute for a task or direct_offer. Enforces eligibility (task: in_progress|delivered, direct_offer: active|delivered) and one open/active per entity.';

GRANT EXECUTE ON FUNCTION public.rpc_submit_delivery(text, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_request_revision(text, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_submit_dispute(uuid, uuid, text, uuid) TO authenticated;
