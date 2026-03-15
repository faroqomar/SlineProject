-- Fix: "parameter 40 (text) does not match that when preparing the plan (booking_status_enum)"
-- Ensure process_payment_event_ledger release_with_fee block uses explicit enum casts
-- so prepared-plan type is unambiguous (bookings.status = booking_status_enum; direct_offers.payment_status = payment_status_enum).
-- Safe to run after 20260308210400_ledger_allow_disputed_booking_admin (only replaces UPDATE lines).

DO $$
DECLARE
  def text;
  new_def text;
  -- In pg_get_functiondef output, single quotes in the body appear as ''
  booking_old text := 'UPDATE public.bookings SET payment_status = ''released'', status = ''completed'' WHERE id = p_related_entity_id';
  booking_new text := 'UPDATE public.bookings SET payment_status = ''released''::public.payment_status_enum, status = ''completed''::public.booking_status_enum WHERE id = p_related_entity_id';
  direct_old text := 'UPDATE public.direct_offers SET payment_status = ''released'', status = ''completed'' WHERE id = p_related_entity_id';
  direct_new text := 'UPDATE public.direct_offers SET payment_status = ''released''::public.payment_status_enum, status = ''completed'' WHERE id = p_related_entity_id';
BEGIN
  SELECT pg_get_functiondef(oid) INTO def FROM pg_proc WHERE proname = 'process_payment_event_ledger';
  IF def IS NULL THEN
    RAISE EXCEPTION 'process_payment_event_ledger not found';
  END IF;

  IF position(booking_new IN def) > 0 THEN
    RETURN; -- already patched
  END IF;
  new_def := replace(def, booking_old, booking_new);
  IF new_def = def THEN
    -- Try with 12-space indent (common in ledger function body)
    new_def := replace(def, '            ' || booking_old, '            ' || booking_new);
  END IF;
  IF new_def = def THEN
    RAISE EXCEPTION 'process_payment_event_ledger: booking release UPDATE block not found (already patched or unexpected body)';
  END IF;
  IF position(direct_old IN new_def) > 0 THEN
    new_def := replace(new_def, direct_old, direct_new);
  ELSIF position('            ' || direct_old IN new_def) > 0 THEN
    new_def := replace(new_def, '            ' || direct_old, '            ' || direct_new);
  END IF;
  EXECUTE new_def;
END $$;
