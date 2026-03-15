-- Booking Lifecycle (Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic)
-- rpc_finalize_auto_approval: booking branch must call process_payment_event_ledger to release escrow.

CREATE OR REPLACE FUNCTION public.rpc_finalize_auto_approval(
  entity_type text,
  entity_id uuid
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  _status text;
  _review_expires timestamptz;
  _new_status text;
  _task_id uuid;
  -- booking branch: ledger release
  v_payment_status text;
  v_idempotency_key text;
  v_result json;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  IF entity_type = 'task' THEN
    IF EXISTS (SELECT 1 FROM public.disputes WHERE task_id = entity_id AND status IN ('open', 'active')) THEN
      SELECT status INTO _status FROM public.tasks WHERE id = entity_id;
      RETURN _status;
    END IF;
    SELECT status, review_expires_at INTO _status, _review_expires FROM public.tasks WHERE id = entity_id;
    IF _status = 'delivered' AND _review_expires IS NOT NULL AND now() > _review_expires THEN
      UPDATE public.tasks SET status = 'completed' WHERE id = entity_id;
      _new_status := 'completed';
    ELSE
      _new_status := _status;
    END IF;
    RETURN _new_status;

  ELSIF entity_type = 'booking' THEN
    SELECT task_id INTO _task_id FROM public.bookings WHERE id = entity_id;
    IF EXISTS (SELECT 1 FROM public.disputes WHERE task_id = _task_id AND status IN ('open', 'active')) THEN
      SELECT status::text INTO _status FROM public.bookings WHERE id = entity_id;
      RETURN _status;
    END IF;

    SELECT status::text, review_expires_at, payment_status
    INTO _status, _review_expires, v_payment_status
    FROM public.bookings
    WHERE id = entity_id
    FOR UPDATE;

    IF _status = 'delivered' AND _review_expires IS NOT NULL AND now() > _review_expires THEN
      IF v_payment_status = 'held' THEN
        v_idempotency_key := encode(
          extensions.digest(
            entity_id::text || ':release_with_fee:' || _status || ':' || v_payment_status,
            'sha256'
          ),
          'hex'
        );
        v_result := process_payment_event_ledger(
          p_event_type := 'release_with_fee',
          p_related_entity_type := 'booking',
          p_related_entity_id := entity_id,
          p_idempotency_key := v_idempotency_key,
          p_amount_gross := (SELECT COALESCE(price, 0) FROM public.bookings WHERE id = entity_id),
          p_meta := '{"fee_rate_bps": 0}'::jsonb
        );
        IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
          RAISE EXCEPTION 'Ledger release failed: %', v_result->'error'->>'message';
        END IF;
        UPDATE public.bookings SET review_expires_at = NULL WHERE id = entity_id;
      ELSE
        UPDATE public.bookings SET status = 'completed', review_expires_at = NULL WHERE id = entity_id;
      END IF;
      _new_status := 'completed';
    ELSE
      _new_status := _status;
    END IF;
    RETURN _new_status;

  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;
END;
$function$;
