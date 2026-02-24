-- Fix delivery submission for booking status lifecycle.
-- Allows legacy/paid-request states to advance through ACTIVE before DELIVERED.

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
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
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

    -- Legacy and pay-first states must pass ACTIVE before DELIVERED.
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
