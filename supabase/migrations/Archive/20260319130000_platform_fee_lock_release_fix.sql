-- Platform fee repair: unify lock/release calculations on fn_get_default_fee_rate_bps()
-- and the entity-level fee_rate_applied_bps. This removes stale 0-fee booking releases
-- and old system_config/platform_fee_bps lookups from active paths.

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_get_default_fee_rate_bps()
RETURNS int
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_has_fee_columns boolean;
  v_default_bps int;
  v_max_bps int;
  c_default_fallback CONSTANT int := 1000;
  c_max_fallback CONSTANT int := 2000;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'platform_settings'
      AND column_name = 'fee_rate_default_bps'
  ) INTO v_has_fee_columns;

  IF v_has_fee_columns THEN
    SELECT
      fee_rate_default_bps,
      max_fee_rate_bps
    INTO v_default_bps, v_max_bps
    FROM public.platform_settings
    WHERE key = 'default'
    LIMIT 1;

    RETURN LEAST(COALESCE(v_default_bps, c_default_fallback), COALESCE(v_max_bps, c_max_fallback));
  END IF;

  BEGIN
    SELECT
      COALESCE((SELECT (value->>'value')::int FROM public.platform_settings WHERE key = 'fee_rate_default_bps' LIMIT 1), c_default_fallback),
      COALESCE((SELECT (value->>'value')::int FROM public.platform_settings WHERE key = 'max_fee_rate_bps' LIMIT 1), c_max_fallback)
    INTO v_default_bps, v_max_bps;
  EXCEPTION WHEN OTHERS THEN
    v_default_bps := c_default_fallback;
    v_max_bps := c_max_fallback;
  END;

  RETURN LEAST(COALESCE(v_default_bps, c_default_fallback), COALESCE(v_max_bps, c_max_fallback));
END;
$$;

COMMENT ON FUNCTION public.fn_get_default_fee_rate_bps() IS
  'Canonical default platform fee rate in bps. Works with both legacy JSONB and singleton-row platform_settings shapes.';

CREATE OR REPLACE FUNCTION public.fn_lock_booking_fee_on_hold()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_fee_bps int;
  v_fee_amount bigint;
  v_price numeric;
BEGIN
  IF NEW.payment_status = 'held'::public.payment_status_enum
     AND NEW.fee_rate_applied_bps IS NULL THEN
    IF TG_OP = 'INSERT'
       OR OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
      v_fee_bps := public.fn_get_default_fee_rate_bps();
      v_price := COALESCE(NEW.price, 0);
      v_fee_amount := FLOOR(v_price * v_fee_bps / 10000.0)::bigint;

      NEW.fee_rate_applied_bps := v_fee_bps;
      NEW.fee_amount := v_fee_amount;
      NEW.net_amount := GREATEST(v_price::bigint - v_fee_amount, 0);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lock_booking_fee_on_hold ON public.bookings;
CREATE TRIGGER trg_lock_booking_fee_on_hold
BEFORE INSERT OR UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.fn_lock_booking_fee_on_hold();

CREATE OR REPLACE FUNCTION public.fn_lock_direct_offer_fee_on_accept()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_fee_bps int;
  v_fee_amount bigint;
  v_price numeric;
BEGIN
  IF NEW.status = 'accepted'::public.direct_offer_status_enum
     AND NEW.payment_status = 'unpaid'::public.payment_status_enum THEN
    IF TG_OP = 'INSERT'
       OR OLD.status IS DISTINCT FROM NEW.status
       OR OLD.payment_status IS DISTINCT FROM NEW.payment_status
       OR OLD.fee_rate_applied_bps IS NULL THEN
      v_fee_bps := public.fn_get_default_fee_rate_bps();
      v_price := COALESCE(NEW.price, 0);
      v_fee_amount := FLOOR(v_price * v_fee_bps / 10000.0)::bigint;

      NEW.fee_rate_applied_bps := v_fee_bps;
      NEW.fee_amount := v_fee_amount;
      NEW.net_amount := GREATEST(v_price::bigint - v_fee_amount, 0);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lock_direct_offer_fee_on_accept ON public.direct_offers;
CREATE TRIGGER trg_lock_direct_offer_fee_on_accept
BEFORE INSERT OR UPDATE ON public.direct_offers
FOR EACH ROW EXECUTE FUNCTION public.fn_lock_direct_offer_fee_on_accept();

-- task_requests.price is in main currency units (e.g. IQD whole); * 100 converts to cents for fee math.
-- bookings and direct_offers use price in the same unit as the ledger (no conversion).
CREATE OR REPLACE FUNCTION public.fn_lock_task_request_fee_on_award()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_fee_bps int;
  v_gross_cents bigint;
  v_fee_amount bigint;
BEGIN
  IF NEW.status = 'accepted'
     AND NEW.payment_status = 'unpaid' THEN
    IF TG_OP = 'INSERT'
       OR OLD.status IS DISTINCT FROM NEW.status
       OR OLD.payment_status IS DISTINCT FROM NEW.payment_status
       OR OLD.fee_rate_applied_bps IS NULL THEN
      v_fee_bps := public.fn_get_default_fee_rate_bps();
      v_gross_cents := (COALESCE(NEW.price, 0) * 100)::bigint;
      v_fee_amount := (v_gross_cents * v_fee_bps / 10000)::bigint;

      NEW.fee_rate_applied_bps := v_fee_bps;
      NEW.fee_amount := v_fee_amount;
      NEW.net_amount := GREATEST(v_gross_cents - v_fee_amount, 0);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_lock_task_request_fee_on_award ON public.task_requests;
CREATE TRIGGER trg_lock_task_request_fee_on_award
BEFORE INSERT OR UPDATE ON public.task_requests
FOR EACH ROW EXECUTE FUNCTION public.fn_lock_task_request_fee_on_award();

CREATE OR REPLACE FUNCTION public.rpc_approve_delivery(
  entity_type text,
  entity_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_client_id uuid;
  v_provider_id uuid;
  v_status text;
  v_payment_status text;
  v_price numeric;
  v_fee_rate_bps int;
  v_result json;
  v_idempotency_key text;
BEGIN
  IF entity_type = 'task' THEN
    SELECT status, owner_id INTO v_status, v_client_id FROM tasks WHERE id = entity_id;
    IF v_client_id != v_uid THEN RAISE EXCEPTION 'Not authorized'; END IF;
    IF v_status != 'delivered' THEN RAISE EXCEPTION 'Work not delivered'; END IF;

    UPDATE tasks SET status = 'completed', review_expires_at = NULL
    WHERE id = entity_id;

  ELSIF entity_type = 'booking' THEN
    SELECT status, payment_status, client_id, provider_id, price, fee_rate_applied_bps
    INTO v_status, v_payment_status, v_client_id, v_provider_id, v_price, v_fee_rate_bps
    FROM bookings WHERE id = entity_id
    FOR UPDATE;

    IF v_client_id != v_uid THEN RAISE EXCEPTION 'Not authorized'; END IF;
    IF v_status != 'delivered' THEN RAISE EXCEPTION 'Work not delivered'; END IF;

    IF v_payment_status = 'held' THEN
      v_idempotency_key := encode(
        extensions.digest(
          entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
          'sha256'
        ),
        'hex'
      );

      v_result := process_payment_event_ledger(
        p_event_type := 'release_with_fee',
        p_related_entity_type := 'booking',
        p_related_entity_id := entity_id,
        p_idempotency_key := v_idempotency_key,
        p_amount_gross := COALESCE(v_price, 0),
        p_meta := jsonb_build_object(
          'fee_rate_bps', COALESCE(v_fee_rate_bps, public.fn_get_default_fee_rate_bps())
        )
      );

      IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Ledger release failed: %', v_result->'error'->>'message';
      END IF;

      UPDATE bookings
      SET status = 'completed', payment_status = 'released', review_expires_at = NULL
      WHERE id = entity_id;
    ELSE
      UPDATE bookings SET status = 'completed', review_expires_at = NULL
      WHERE id = entity_id;
    END IF;

  ELSIF entity_type = 'direct_offer' THEN
    SELECT status, payment_status, client_id, freelancer_id, price, fee_rate_applied_bps
    INTO v_status, v_payment_status, v_client_id, v_provider_id, v_price, v_fee_rate_bps
    FROM direct_offers WHERE id = entity_id
    FOR UPDATE;

    IF v_client_id != v_uid THEN RAISE EXCEPTION 'Not authorized'; END IF;
    IF v_status != 'delivered' THEN RAISE EXCEPTION 'Work not delivered'; END IF;
    IF v_payment_status != 'held' THEN RAISE EXCEPTION 'Payment not held'; END IF;

    v_idempotency_key := encode(
      extensions.digest(
        entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
        'sha256'
      ),
      'hex'
    );

    v_result := process_payment_event_ledger(
      p_event_type := 'release_with_fee',
      p_related_entity_type := 'direct_offer',
      p_related_entity_id := entity_id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(v_price, 0),
      p_meta := jsonb_build_object(
        'fee_rate_bps', COALESCE(v_fee_rate_bps, public.fn_get_default_fee_rate_bps()),
        'client_id', v_client_id,
        'freelancer_id', v_provider_id
      )
    );

    IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Ledger release failed: %', v_result->'error'->>'message';
    END IF;

    UPDATE direct_offers
    SET payment_status = 'released', status = 'completed'
    WHERE id = entity_id;

  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;
END;
$function$;

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
  v_payment_status text;
  v_fee_rate_bps int;
  v_price numeric;
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

    SELECT status::text, review_expires_at, payment_status, fee_rate_applied_bps, price
    INTO _status, _review_expires, v_payment_status, v_fee_rate_bps, v_price
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
          p_amount_gross := COALESCE(v_price, 0),
          p_meta := jsonb_build_object(
            'fee_rate_bps', COALESCE(v_fee_rate_bps, public.fn_get_default_fee_rate_bps())
          )
        );
        IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
          RAISE EXCEPTION 'Ledger release failed: %', v_result->'error'->>'message';
        END IF;
        UPDATE public.bookings SET status = 'completed', payment_status = 'released', review_expires_at = NULL WHERE id = entity_id;
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

CREATE OR REPLACE FUNCTION public.admin_resolve_booking_dispute(
  p_booking_id uuid,
  p_resolution text,
  p_idempotency_key text DEFAULT (gen_random_uuid()::text)
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
  v_booking RECORD;
  v_idempotency_key text := p_idempotency_key;
  v_result jsonb;
BEGIN
  IF v_admin_id IS NULL OR NOT public.is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Only admin can resolve a disputed booking';
  END IF;

  IF p_resolution NOT IN ('completed', 'refunded') THEN
    RAISE EXCEPTION 'Resolution must be completed or refunded';
  END IF;

  SELECT id, status, payment_status, client_id, provider_id, price, fee_rate_applied_bps
  INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF v_booking IS NULL THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_booking.status != 'disputed' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'Booking is not in disputed status');
  END IF;

  IF p_resolution = 'completed' THEN
    IF v_booking.payment_status != 'held' THEN
      RAISE EXCEPTION 'Cannot complete: payment not held';
    END IF;
    IF v_idempotency_key IS NULL OR trim(v_idempotency_key) = '' THEN
      v_idempotency_key := encode(
        extensions.digest(
          p_booking_id::text || ':release_with_fee:disputed:' || v_booking.payment_status,
          'sha256'
        ),
        'hex'
      );
    END IF;
    v_result := process_payment_event_ledger(
      p_event_type := 'release_with_fee',
      p_related_entity_type := 'booking',
      p_related_entity_id := p_booking_id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(v_booking.price, 0),
      p_meta := jsonb_build_object(
        'fee_rate_bps', COALESCE(v_booking.fee_rate_applied_bps, public.fn_get_default_fee_rate_bps()),
        'admin_resolve', true
      )
    );
    IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Ledger release failed: %', v_result->'error'->>'message';
    END IF;
    UPDATE public.bookings SET status = 'completed', payment_status = 'released', review_expires_at = NULL WHERE id = p_booking_id;
  ELSIF p_resolution = 'refunded' THEN
    IF v_booking.payment_status != 'held' THEN
      RAISE EXCEPTION 'Cannot refund: payment not held';
    END IF;
    IF v_idempotency_key IS NULL OR trim(v_idempotency_key) = '' THEN
      v_idempotency_key := encode(
        extensions.digest(
          p_booking_id::text || ':refund:disputed:' || v_booking.payment_status,
          'sha256'
        ),
        'hex'
      );
    END IF;
    v_result := process_payment_event_ledger(
      p_event_type := 'refund',
      p_related_entity_type := 'booking',
      p_related_entity_id := p_booking_id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(v_booking.price, 0),
      p_meta := jsonb_build_object('refund_reason', 'Admin resolved dispute', 'admin_resolve', true)
    );
    IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Ledger refund failed: %', v_result->'error'->>'message';
    END IF;
    UPDATE public.bookings SET status = 'refunded' WHERE id = p_booking_id;
  END IF;

  RETURN jsonb_build_object('ok', true, 'booking_id', p_booking_id, 'resolution', p_resolution);
END;
$$;

CREATE OR REPLACE FUNCTION public.run_auto_release_expired_direct_offers()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  r record;
  v_idempotency_key text;
  v_result jsonb;
  v_count int := 0;
BEGIN
  FOR r IN
    SELECT id, client_id, freelancer_id, price, fee_rate_applied_bps, status, payment_status
    FROM public.direct_offers
    WHERE status = 'delivered'
      AND payment_status = 'held'
      AND review_expires_at IS NOT NULL
      AND review_expires_at < now()
    FOR UPDATE SKIP LOCKED
  LOOP
    v_idempotency_key := encode(
      extensions.digest(
        r.id::text || ':release_with_fee:' || r.status || ':' || r.payment_status,
        'sha256'
      ),
      'hex'
    );

    v_result := process_payment_event_ledger(
      p_event_type := 'release_with_fee',
      p_related_entity_type := 'direct_offer',
      p_related_entity_id := r.id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(r.price, 0),
      p_meta := jsonb_build_object(
        'fee_rate_bps', COALESCE(r.fee_rate_applied_bps, public.fn_get_default_fee_rate_bps()),
        'client_id', r.client_id,
        'freelancer_id', r.freelancer_id,
        'auto_release', true
      )
    );

    IF (v_result->>'ok')::boolean = true THEN
      UPDATE public.direct_offers
      SET payment_status = 'released', status = 'completed'
      WHERE id = r.id;
      v_count := v_count + 1;
    END IF;
  END LOOP;
  RETURN v_count;
END;
$$;

COMMIT;
