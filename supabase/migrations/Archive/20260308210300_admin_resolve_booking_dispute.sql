-- Booking Lifecycle (Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic)
-- Admin-only RPC to resolve a disputed booking (completed or refunded).
-- Guard allows disputed→completed/refunded when is_admin(auth.uid()).
-- Ledger: process_payment_event_ledger must allow booking status 'disputed' when caller is admin
-- (see migration 20260308210400_ledger_allow_disputed_booking_admin.sql if present).

CREATE OR REPLACE FUNCTION public.admin_resolve_booking_dispute(
  p_booking_id uuid,
  p_resolution text,  -- 'completed' | 'refunded'
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
  v_idempotency_key text;
  v_result jsonb;
BEGIN
  IF v_admin_id IS NULL OR NOT public.is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Only admin can resolve a disputed booking';
  END IF;

  IF p_resolution NOT IN ('completed', 'refunded') THEN
    RAISE EXCEPTION 'Resolution must be completed or refunded';
  END IF;

  SELECT id, status, payment_status, client_id, provider_id, price
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
    v_idempotency_key := encode(
      extensions.digest(
        p_booking_id::text || ':release_with_fee:disputed:' || v_booking.payment_status,
        'sha256'
      ),
      'hex'
    );
    v_result := process_payment_event_ledger(
      p_event_type := 'release_with_fee',
      p_related_entity_type := 'booking',
      p_related_entity_id := p_booking_id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(v_booking.price, 0),
      p_meta := '{"fee_rate_bps": 0, "admin_resolve": true}'::jsonb
    );
    IF (v_result->>'ok')::boolean IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'Ledger release failed: %', v_result->'error'->>'message';
    END IF;
    UPDATE public.bookings SET review_expires_at = NULL WHERE id = p_booking_id;
  ELSIF p_resolution = 'refunded' THEN
    IF v_booking.payment_status != 'held' THEN
      RAISE EXCEPTION 'Cannot refund: payment not held';
    END IF;
    v_idempotency_key := encode(
      extensions.digest(
        p_booking_id::text || ':refund:disputed:' || v_booking.payment_status,
        'sha256'
      ),
      'hex'
    );
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

COMMENT ON FUNCTION public.admin_resolve_booking_dispute(uuid, text, text) IS
  'Admin-only: resolve disputed booking to completed (release to provider) or refunded. Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic.';
