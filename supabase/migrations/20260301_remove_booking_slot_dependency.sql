ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS due_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS delivery_days INTEGER;

UPDATE public.bookings b
SET
  delivery_days = COALESCE(
    b.delivery_days,
    CASE
      WHEN b.package_id IS NOT NULL
        AND COALESCE(t.packages -> b.package_id ->> 'delivery', '') ~ '^[0-9]+$'
      THEN (t.packages -> b.package_id ->> 'delivery')::INTEGER
      ELSE NULL
    END
  ),
  due_at = COALESCE(
    b.due_at,
    (
      SELECT s.starts_at
      FROM public.availability_slots s
      WHERE s.id = b.slot_id
    ),
    CASE
      WHEN b.package_id IS NOT NULL
        AND COALESCE(t.packages -> b.package_id ->> 'delivery', '') ~ '^[0-9]+$'
      THEN b.created_at
        + make_interval(days => (t.packages -> b.package_id ->> 'delivery')::INTEGER)
      ELSE NULL
    END,
    CASE
      WHEN t.deadline IS NOT NULL AND t.deadline > b.created_at THEN t.deadline
      ELSE NULL
    END
  )
FROM public.tasks t
WHERE b.task_id = t.id
  AND (
    b.delivery_days IS NULL
    OR b.due_at IS NULL
  );

DROP INDEX IF EXISTS public.uq_bookings_active_task_client;

CREATE UNIQUE INDEX IF NOT EXISTS uq_bookings_active_task_client
ON public.bookings (task_id, client_id)
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

DROP FUNCTION IF EXISTS public.rpc_create_booking_draft_validated(
  UUID,
  TEXT,
  TEXT,
  JSONB
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

  IF EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.task_id = p_task_id
      AND b.client_id = v_uid
      AND b.slot_id IS NULL
      AND b.status IN (
        'pending'::public.booking_status_enum,
        'paid_request_pending'::public.booking_status_enum,
        'confirmed'::public.booking_status_enum,
        'active'::public.booking_status_enum,
        'delivered'::public.booking_status_enum
      )
    LIMIT 1
  ) THEN
    RAISE EXCEPTION 'BOOKING_ALREADY_EXISTS_FOR_CLIENT';
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

REVOKE EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  TEXT,
  TEXT,
  JSONB
) FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  TEXT,
  TEXT,
  JSONB
) FROM anon;

GRANT EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  TEXT,
  TEXT,
  JSONB
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_create_booking_draft_validated(
  UUID,
  TEXT,
  TEXT,
  JSONB
) TO service_role;

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
