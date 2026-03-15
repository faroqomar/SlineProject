-- Add task-request escrow release logic to rpc_approve_delivery while preserving
-- the live function signature/return type and dispute guards.

CREATE OR REPLACE FUNCTION public.rpc_approve_delivery(
  p_entity_type text,
  p_entity_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_client_id uuid;
  v_provider_id uuid;
  v_task_id uuid;
  v_status text;
  v_payment_status text;
  v_price numeric;
  v_fee_rate_bps int;
  v_result jsonb := jsonb_build_object('ok', true);
  v_idempotency_key text;
  v_request_id uuid;
  v_req_payment_status text;
  v_req_price numeric;
  v_req_fee_rate int;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_entity_type = 'task' THEN
    IF EXISTS (
      SELECT 1
      FROM public.disputes
      WHERE task_id = p_entity_id
        AND status IN ('open', 'active')
    ) THEN
      RAISE EXCEPTION 'Cannot approve delivery: dispute in progress';
    END IF;

    SELECT
      status,
      COALESCE(client_id, owner_id),
      assigned_freelancer_id
    INTO v_status, v_client_id, v_provider_id
    FROM public.tasks
    WHERE id = p_entity_id
    FOR UPDATE;

    IF v_client_id != v_uid THEN
      RAISE EXCEPTION 'Not authorized';
    END IF;
    IF v_status != 'delivered' THEN
      RAISE EXCEPTION 'Work not delivered';
    END IF;

    SELECT
      id,
      payment_status,
      price,
      fee_rate_applied_bps
    INTO v_request_id, v_req_payment_status, v_req_price, v_req_fee_rate
    FROM public.task_requests
    WHERE task_id = p_entity_id
      AND status = 'accepted'
    LIMIT 1
    FOR UPDATE;

    IF v_request_id IS NOT NULL AND v_req_payment_status = 'held' THEN
      v_idempotency_key := encode(
        extensions.digest(
          v_request_id::text || ':release_with_fee:' || v_status || ':' || v_req_payment_status,
          'sha256'
        ),
        'hex'
      );

      v_result := public.process_payment_event_ledger(
        p_event_type := 'release_with_fee',
        p_related_entity_type := 'task_request',
        p_related_entity_id := v_request_id,
        p_idempotency_key := v_idempotency_key,
        p_amount_gross := COALESCE(v_req_price, 0),
        p_meta := jsonb_build_object(
          'fee_rate_bps', COALESCE(v_req_fee_rate, public.fn_get_default_fee_rate_bps()),
          'client_id', v_client_id,
          'freelancer_id', v_provider_id
        )
      );

      IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Ledger error: %', v_result->'error'->>'message';
      END IF;

      UPDATE public.task_requests
      SET payment_status = 'released'
      WHERE id = v_request_id;
    END IF;

    UPDATE public.tasks
    SET status = 'completed', review_expires_at = NULL
    WHERE id = p_entity_id;

    RETURN v_result || jsonb_build_object(
      'entity_type', p_entity_type,
      'entity_id', p_entity_id,
      'released_entity_type', CASE WHEN v_request_id IS NOT NULL AND v_req_payment_status = 'held' THEN 'task_request' ELSE NULL END,
      'released_entity_id', CASE WHEN v_request_id IS NOT NULL AND v_req_payment_status = 'held' THEN v_request_id ELSE NULL END
    );

  ELSIF p_entity_type = 'booking' THEN
    SELECT
      status,
      payment_status,
      client_id,
      provider_id,
      price,
      fee_rate_applied_bps,
      task_id
    INTO v_status, v_payment_status, v_client_id, v_provider_id, v_price, v_fee_rate_bps, v_task_id
    FROM public.bookings
    WHERE id = p_entity_id
    FOR UPDATE;

    IF EXISTS (
      SELECT 1
      FROM public.disputes
      WHERE task_id = v_task_id
        AND status IN ('open', 'active')
    ) THEN
      RAISE EXCEPTION 'Cannot approve delivery: dispute in progress';
    END IF;
    IF v_client_id != v_uid THEN
      RAISE EXCEPTION 'Not authorized';
    END IF;
    IF v_status != 'delivered' THEN
      RAISE EXCEPTION 'Work not delivered';
    END IF;

    IF v_payment_status = 'held' THEN
      v_idempotency_key := encode(
        extensions.digest(
          p_entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
          'sha256'
        ),
        'hex'
      );

      v_result := public.process_payment_event_ledger(
        p_event_type := 'release_with_fee',
        p_related_entity_type := 'booking',
        p_related_entity_id := p_entity_id,
        p_idempotency_key := v_idempotency_key,
        p_amount_gross := COALESCE(v_price, 0),
        p_meta := jsonb_build_object(
          'fee_rate_bps', COALESCE(v_fee_rate_bps, public.fn_get_default_fee_rate_bps())
        )
      );

      IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Ledger error: %', v_result->'error'->>'message';
      END IF;

      UPDATE public.bookings
      SET review_expires_at = NULL
      WHERE id = p_entity_id;
    ELSE
      UPDATE public.bookings
      SET status = 'completed', review_expires_at = NULL
      WHERE id = p_entity_id;
    END IF;

    RETURN v_result || jsonb_build_object(
      'entity_type', p_entity_type,
      'entity_id', p_entity_id
    );

  ELSIF p_entity_type = 'direct_offer' THEN
    IF EXISTS (
      SELECT 1
      FROM public.disputes
      WHERE direct_offer_id = p_entity_id
        AND status IN ('open', 'active')
    ) THEN
      RAISE EXCEPTION 'Cannot approve delivery: dispute in progress';
    END IF;

    SELECT
      status,
      payment_status,
      client_id,
      freelancer_id,
      price,
      fee_rate_applied_bps
    INTO v_status, v_payment_status, v_client_id, v_provider_id, v_price, v_fee_rate_bps
    FROM public.direct_offers
    WHERE id = p_entity_id
    FOR UPDATE;

    IF v_client_id != v_uid THEN
      RAISE EXCEPTION 'Not authorized';
    END IF;
    IF v_status != 'delivered' THEN
      RAISE EXCEPTION 'Work not delivered';
    END IF;
    IF v_payment_status != 'held' THEN
      RAISE EXCEPTION 'Payment not held';
    END IF;

    v_idempotency_key := encode(
      extensions.digest(
        p_entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
        'sha256'
      ),
      'hex'
    );

    v_result := public.process_payment_event_ledger(
      p_event_type := 'release_with_fee',
      p_related_entity_type := 'direct_offer',
      p_related_entity_id := p_entity_id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(v_price, 0),
      p_meta := jsonb_build_object(
        'fee_rate_bps', COALESCE(v_fee_rate_bps, public.fn_get_default_fee_rate_bps()),
        'client_id', v_client_id,
        'freelancer_id', v_provider_id
      )
    );

    IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Ledger error: %', v_result->'error'->>'message';
    END IF;

    UPDATE public.direct_offers
    SET payment_status = 'released', status = 'completed'
    WHERE id = p_entity_id;

    RETURN v_result || jsonb_build_object(
      'entity_type', p_entity_type,
      'entity_id', p_entity_id
    );
  END IF;

  RAISE EXCEPTION 'Invalid entity type';
END;
$function$;
