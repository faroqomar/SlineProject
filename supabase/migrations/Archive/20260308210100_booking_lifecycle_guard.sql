-- Booking Lifecycle (Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic)
-- Replace fn_booking_guard: add actor checks, disputed, no_show; block client delivered→canceled.

CREATE OR REPLACE FUNCTION public.fn_booking_guard()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  v_is_client boolean := (auth.uid() = OLD.client_id);
  v_is_provider boolean := (auth.uid() = OLD.provider_id);
BEGIN
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;

  -- PENDING
  IF OLD.status = 'pending' THEN
    IF NEW.status IN ('confirmed', 'paid_request_pending', 'canceled') THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Invalid booking status transition: % -> %', OLD.status, NEW.status;
  END IF;

  -- PAID_REQUEST_PENDING
  IF OLD.status = 'paid_request_pending' THEN
    IF NEW.status IN ('active', 'refunded', 'canceled', 'expired_unanswered') THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Invalid booking status transition: % -> %', OLD.status, NEW.status;
  END IF;

  -- CONFIRMED (legacy)
  IF OLD.status = 'confirmed' THEN
    IF NEW.status IN ('in_progress', 'active', 'paid_request_pending', 'canceled') THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Invalid booking status transition: % -> %', OLD.status, NEW.status;
  END IF;

  -- ACTIVE / IN_PROGRESS
  IF OLD.status IN ('active', 'in_progress') THEN
    IF NEW.status = 'delivered' THEN RETURN NEW; END IF;
    IF NEW.status = 'completed' THEN RETURN NEW; END IF;
    IF NEW.status = 'canceled' THEN RETURN NEW; END IF;
    IF NEW.status = 'refunded' THEN RETURN NEW; END IF;
    -- no_show: only provider or admin (SECURITY DEFINER RPC will use service role or we allow admin)
    IF NEW.status = 'no_show' AND (v_is_provider OR public.is_admin(auth.uid())) THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Invalid booking status transition: % -> %', OLD.status, NEW.status;
  END IF;

  -- DELIVERED: client cannot set canceled (griefing); client can set disputed
  IF OLD.status = 'delivered' THEN
    IF NEW.status = 'completed' THEN RETURN NEW; END IF;
    IF NEW.status = 'active' THEN RETURN NEW; END IF; -- revision
    IF NEW.status = 'refunded' THEN RETURN NEW; END IF;
    IF NEW.status = 'disputed' AND v_is_client THEN RETURN NEW; END IF;
    IF NEW.status = 'canceled' AND NOT v_is_client THEN RETURN NEW; END IF; -- provider or admin only
    IF NEW.status = 'canceled' AND v_is_client THEN
      RAISE EXCEPTION 'Invalid booking status transition: client cannot cancel a delivered booking; use Report Issue';
    END IF;
    RAISE EXCEPTION 'Invalid booking status transition: % -> %', OLD.status, NEW.status;
  END IF;

  -- DISPUTED: only admin (or SECURITY DEFINER RPC) can resolve
  IF OLD.status = 'disputed' THEN
    IF NEW.status IN ('completed', 'refunded') AND public.is_admin(auth.uid()) THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'Invalid booking status transition: % -> % (only admin can resolve disputed)', OLD.status, NEW.status;
  END IF;

  -- EXPIRED_UNANSWERED
  IF OLD.status = 'expired_unanswered' THEN
    IF NEW.status = 'refunded' THEN RETURN NEW; END IF;
  END IF;

  -- Terminal: no further changes
  IF OLD.status = 'completed' THEN
    RAISE EXCEPTION 'Cannot change status of completed booking';
  END IF;
  IF OLD.status IN ('canceled', 'refunded', 'no_show') THEN
    RAISE EXCEPTION 'Cannot change status of % booking', OLD.status;
  END IF;

  RETURN NEW;
END;
$function$;
