-- Bookin remediation foundation:
-- - server-owned booking payment context
-- - validated booking draft creation RPC
-- - refund finalization RPC
-- - server-side booking notifications

CREATE TABLE IF NOT EXISTS public.booking_payment_audits (
  id BIGSERIAL PRIMARY KEY,
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  actor_user_id UUID NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  provider TEXT NOT NULL DEFAULT 'qicard',
  outcome TEXT NOT NULL DEFAULT 'accepted',
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_booking_payment_audits_booking_created
ON public.booking_payment_audits (booking_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_booking_payment_audits_correlation
ON public.booking_payment_audits (correlation_id);

ALTER TABLE public.booking_payment_audits ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS payment_request_id TEXT,
  ADD COLUMN IF NOT EXISTS payment_gateway_id TEXT,
  ADD COLUMN IF NOT EXISTS payment_correlation_id TEXT,
  ADD COLUMN IF NOT EXISTS payment_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS payment_recovered_at TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS uq_bookings_payment_request_id
ON public.bookings (payment_request_id)
WHERE payment_request_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_bookings_payment_gateway_id
ON public.bookings (payment_gateway_id)
WHERE payment_gateway_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_bookings_payment_correlation_id
ON public.bookings (payment_correlation_id)
WHERE payment_correlation_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.rpc_create_booking_draft_validated(
  p_task_id UUID,
  p_slot_id UUID,
  p_note TEXT DEFAULT NULL,
  p_package_id TEXT DEFAULT NULL,
  p_requirements JSONB DEFAULT '{}'::jsonb
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_slot public.availability_slots%ROWTYPE;
  v_task RECORD;
  v_booking public.bookings%ROWTYPE;
  v_price NUMERIC;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_slot
  FROM public.availability_slots
  WHERE id = p_slot_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_SLOT_NOT_FOUND';
  END IF;

  IF v_slot.is_blocked THEN
    RAISE EXCEPTION 'BOOKING_SLOT_BLOCKED';
  END IF;

  IF v_slot.starts_at <= timezone('utc', now()) THEN
    RAISE EXCEPTION 'BOOKING_SLOT_IN_PAST';
  END IF;

  SELECT
    t.id,
    t.user_id,
    t.status,
    t.task_type,
    t.budget,
    t.packages
  INTO v_task
  FROM public.tasks t
  WHERE t.id = p_task_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_TASK_NOT_FOUND';
  END IF;

  IF v_task.task_type::TEXT <> 'booking' THEN
    RAISE EXCEPTION 'BOOKING_TASK_TYPE_INVALID';
  END IF;

  IF v_task.user_id <> v_slot.provider_id THEN
    RAISE EXCEPTION 'BOOKING_PROVIDER_SLOT_MISMATCH';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.slot_id = p_slot_id
      AND b.status::TEXT NOT IN ('canceled', 'refunded', 'expired_unanswered')
    LIMIT 1
  ) THEN
    RAISE EXCEPTION 'BOOKING_SLOT_UNAVAILABLE';
  END IF;

  IF p_package_id IS NOT NULL AND p_package_id <> '' THEN
    v_price := NULLIF(v_task.packages -> p_package_id ->> 'price', '')::NUMERIC;
  END IF;

  IF v_price IS NULL THEN
    v_price := v_task.budget;
  END IF;

  IF v_price IS NULL OR v_price <= 0 THEN
    RAISE EXCEPTION 'BOOKING_PRICE_INVALID';
  END IF;

  INSERT INTO public.bookings (
    task_id,
    provider_id,
    client_id,
    slot_id,
    status,
    payment_status,
    note,
    requirements,
    package_id,
    price
  )
  VALUES (
    p_task_id,
    v_slot.provider_id,
    v_uid,
    p_slot_id,
    'pending'::public.booking_status_enum,
    'unpaid'::public.payment_status_enum,
    NULLIF(TRIM(COALESCE(p_note, '')), ''),
    COALESCE(p_requirements, '{}'::jsonb),
    NULLIF(TRIM(COALESCE(p_package_id, '')), ''),
    v_price
  )
  RETURNING *
  INTO v_booking;

  RETURN v_booking;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  UUID,
  TEXT,
  TEXT,
  JSONB
) FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  UUID,
  TEXT,
  TEXT,
  JSONB
) FROM anon;

GRANT EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  UUID,
  TEXT,
  TEXT,
  JSONB
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  UUID,
  TEXT,
  TEXT,
  JSONB
) TO service_role;

CREATE OR REPLACE FUNCTION public.rpc_finalize_booking_refund(
  p_booking_id UUID,
  p_reason TEXT DEFAULT NULL,
  p_correlation_id TEXT DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking public.bookings%ROWTYPE;
BEGIN
  IF COALESCE(current_setting('request.jwt.claim.role', true), '') <> 'service_role' THEN
    RAISE EXCEPTION 'SERVICE_ROLE_REQUIRED'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND';
  END IF;

  IF v_booking.status = 'refunded'::public.booking_status_enum
     AND v_booking.payment_status = 'refunded'::public.payment_status_enum THEN
    RETURN v_booking;
  END IF;

  IF v_booking.payment_status <> 'held'::public.payment_status_enum THEN
    RAISE EXCEPTION 'REFUND_REQUIRES_HELD_PAYMENT';
  END IF;

  UPDATE public.bookings
  SET
    status = 'refunded'::public.booking_status_enum,
    payment_status = 'refunded'::public.payment_status_enum,
    review_expires_at = NULL,
    payment_recovered_at = COALESCE(payment_recovered_at, timezone('utc', now()))
  WHERE id = p_booking_id
  RETURNING *
  INTO v_booking;

  IF p_correlation_id IS NOT NULL THEN
    INSERT INTO public.booking_payment_audits (
      booking_id,
      event_type,
      correlation_id,
      provider,
      outcome,
      payload
    )
    VALUES (
      p_booking_id,
      'refund_finalize',
      p_correlation_id,
      'qicard',
      'accepted',
      jsonb_build_object('reason', p_reason)
    );
  END IF;

  RETURN v_booking;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rpc_finalize_booking_refund(
  UUID,
  TEXT,
  TEXT
) FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.rpc_finalize_booking_refund(
  UUID,
  TEXT,
  TEXT
) FROM anon;

REVOKE EXECUTE ON FUNCTION public.rpc_finalize_booking_refund(
  UUID,
  TEXT,
  TEXT
) FROM authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_finalize_booking_refund(
  UUID,
  TEXT,
  TEXT
) TO service_role;

CREATE OR REPLACE FUNCTION public.fn_booking_server_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_target_user UUID;
  v_title TEXT;
  v_message TEXT;
  v_metadata JSONB := '{}'::jsonb;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_target_user := NEW.provider_id;
    v_title := 'New Booking Request';
    v_message := 'You have a new booking request.';
    v_metadata := jsonb_build_object(
      'booking_id', NEW.id,
      'status', NEW.status,
      'payment_status', NEW.payment_status
    );
  ELSIF TG_OP = 'UPDATE' THEN
    IF v_actor IS NULL THEN
      RETURN NEW;
    END IF;

    IF NEW.payment_status IS DISTINCT FROM OLD.payment_status
       AND NEW.payment_status = 'held'::public.payment_status_enum THEN
      v_target_user := NEW.provider_id;
      v_title := 'Booking Payment Secured';
      v_message := 'Payment was secured for a booking request.';
      v_metadata := jsonb_build_object(
        'booking_id', NEW.id,
        'status', NEW.status,
        'payment_status', NEW.payment_status
      );
    ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
      v_target_user := CASE
        WHEN v_actor = NEW.provider_id THEN NEW.client_id
        ELSE NEW.provider_id
      END;
      v_title := 'Booking Updated';
      v_message := format('Booking status changed to %s.', NEW.status::TEXT);
      v_metadata := jsonb_build_object(
        'booking_id', NEW.id,
        'status', NEW.status,
        'payment_status', NEW.payment_status
      );
    ELSE
      RETURN NEW;
    END IF;
  ELSE
    RETURN NEW;
  END IF;

  IF v_target_user IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id,
      title,
      message,
      type,
      related_entity_id,
      related_entity_type,
      metadata
    )
    VALUES (
      v_target_user,
      v_title,
      v_message,
      'booking',
      NEW.id,
      'booking',
      v_metadata
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_booking_server_notifications ON public.bookings;

CREATE TRIGGER trg_booking_server_notifications
AFTER INSERT OR UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.fn_booking_server_notifications();
