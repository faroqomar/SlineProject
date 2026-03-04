-- PAGE 07: Admin booking cancel and refund RPCs (atomic mutation + audit).
-- Copy into sline_app so app repo owns canonical schema. Apply after bookings and audit_logs exist.

-- admin_cancel_booking: set booking status to canceled and write one audit_logs row (same transaction).
CREATE OR REPLACE FUNCTION public.admin_cancel_booking(
  p_booking_id uuid,
  p_admin_id uuid,
  p_reason text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_booking record;
BEGIN
  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;
  IF v_booking.status IN ('canceled', 'refunded') THEN
    RAISE EXCEPTION 'Booking already canceled or refunded';
  END IF;

  UPDATE public.bookings SET status = 'canceled' WHERE id = p_booking_id;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.bookings.cancel',
    p_admin_id,
    'booking',
    p_booking_id,
    jsonb_build_object('reason', p_reason)
  );
END;
$$;

-- admin_refund_booking: idempotent by (booking_id, idempotency_key). Updates status and writes one audit row.
-- If rpc_finalize_booking_refund exists (app repo), it handles ledger; here we do status + audit for dashboard DB.
CREATE OR REPLACE FUNCTION public.admin_refund_booking(
  p_booking_id uuid,
  p_admin_id uuid,
  p_reason text,
  p_idempotency_key text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_booking record;
  v_key text;
BEGIN
  v_key := COALESCE(NULLIF(trim(p_idempotency_key), ''), p_booking_id::text);

  -- Idempotency: if we already have an audit row for this action with this key, do nothing (success).
  IF EXISTS (
    SELECT 1 FROM public.audit_logs
    WHERE action = 'admin.bookings.refund'
      AND related_entity_type = 'booking'
      AND related_entity_id = p_booking_id
      AND meta->>'idempotency_key' = v_key
  ) THEN
    RETURN;
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;
  IF v_booking.status = 'refunded' THEN
    -- Already refunded: insert audit for idempotency record only (no double ledger)
    INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
    VALUES (
      'admin.bookings.refund',
      p_admin_id,
      'booking',
      p_booking_id,
      jsonb_build_object('reason', p_reason, 'idempotency_key', v_key, 'already_refunded', true)
    );
    RETURN;
  END IF;

  -- Optional: call app repo RPC if present (uncomment when rpc_finalize_booking_refund is available in this DB)
  -- PERFORM public.rpc_finalize_booking_refund(p_booking_id, ...);

  UPDATE public.bookings SET status = 'refunded', payment_status = 'refunded' WHERE id = p_booking_id;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.bookings.refund',
    p_admin_id,
    'booking',
    p_booking_id,
    jsonb_build_object('reason', p_reason, 'idempotency_key', v_key)
  );
END;
$$;
