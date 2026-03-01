DROP INDEX IF EXISTS public.uq_bookings_active_task_client;

CREATE INDEX IF NOT EXISTS idx_bookings_task_client_active
ON public.bookings (task_id, client_id, created_at DESC)
WHERE slot_id IS NULL
  AND task_id IS NOT NULL
  AND client_id IS NOT NULL
  AND status IN (
    'pending'::public.booking_status_enum,
    'paid_request_pending'::public.booking_status_enum,
    'confirmed'::public.booking_status_enum,
    'active'::public.booking_status_enum,
    'delivered'::public.booking_status_enum
  );

CREATE OR REPLACE FUNCTION public.rpc_create_booking_draft_validated(
  p_task_id UUID,
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
  v_task RECORD;
  v_booking public.bookings%ROWTYPE;
  v_price NUMERIC;
  v_delivery_days INTEGER;
  v_due_at TIMESTAMPTZ;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED'
      USING ERRCODE = '42501';
  END IF;

  SELECT
    t.id,
    t.user_id,
    t.status,
    t.task_type,
    t.budget,
    t.deadline,
    t.packages
  INTO v_task
  FROM public.tasks t
  WHERE t.id = p_task_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_TASK_NOT_FOUND';
  END IF;

  IF v_task.task_type::TEXT <> 'booking' THEN
    RAISE EXCEPTION 'BOOKING_TASK_TYPE_INVALID';
  END IF;

  IF v_task.status::TEXT <> 'open' THEN
    RAISE EXCEPTION 'BOOKING_TASK_NOT_BOOKABLE';
  END IF;

  IF v_task.user_id = v_uid THEN
    RAISE EXCEPTION 'BOOKING_SELF_BOOKING_FORBIDDEN'
      USING ERRCODE = '42501';
  END IF;

  IF p_package_id IS NOT NULL AND p_package_id <> '' THEN
    IF v_task.packages IS NULL OR NOT (v_task.packages ? p_package_id) THEN
      RAISE EXCEPTION 'BOOKING_PACKAGE_INVALID';
    END IF;

    v_price := NULLIF(v_task.packages -> p_package_id ->> 'price', '')::NUMERIC;

    IF COALESCE(v_task.packages -> p_package_id ->> 'delivery', '') ~ '^[0-9]+$' THEN
      v_delivery_days := (v_task.packages -> p_package_id ->> 'delivery')::INTEGER;
    END IF;
  END IF;

  IF v_price IS NULL THEN
    v_price := v_task.budget;
  END IF;

  IF v_price IS NULL OR v_price <= 0 THEN
    RAISE EXCEPTION 'BOOKING_PRICE_INVALID';
  END IF;

  IF v_delivery_days IS NOT NULL AND v_delivery_days >= 0 THEN
    v_due_at := timezone('utc', now()) + make_interval(days => v_delivery_days);
  ELSIF v_task.deadline IS NOT NULL AND v_task.deadline > timezone('utc', now()) THEN
    v_due_at := v_task.deadline;
  ELSE
    v_due_at := NULL;
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
    price,
    due_at,
    delivery_days
  )
  VALUES (
    p_task_id,
    v_task.user_id,
    v_uid,
    NULL,
    'pending'::public.booking_status_enum,
    'unpaid'::public.payment_status_enum,
    NULLIF(TRIM(COALESCE(p_note, '')), ''),
    COALESCE(p_requirements, '{}'::jsonb),
    NULLIF(TRIM(COALESCE(p_package_id, '')), ''),
    v_price,
    v_due_at,
    v_delivery_days
  )
  RETURNING *
  INTO v_booking;

  RETURN v_booking;
END;
$$;

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
BEGIN
  RETURN public.rpc_create_booking_draft_validated(
    p_task_id,
    p_note,
    p_package_id,
    p_requirements
  );
END;
$$;
