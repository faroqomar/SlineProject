-- Fix rpc_approve_delivery / direct_offer complete path failing with:
--   Ledger error: type of parameter 40 (text) does not match that when preparing the plan (booking_status_enum)
-- Root cause: process_payment_event_ledger builds EXECUTE ... USING (...) for release UPDATEs; binding
-- 'completed'::booking_status_enum vs plain text across replans causes PostgreSQL prepared-statement mismatch.
-- Cast via text first: ('completed')::text::public.booking_status_enum (and payment_status likewise).
-- See also: supabase/migrations/Archive/20260322000001_ledger_parameter_40_text_cast.sql (same patch, now in main chain).

DO $$
DECLARE
  def text;
  new_def text;
  booking_current text := 'UPDATE public.bookings SET payment_status = ''released''::public.payment_status_enum, status = ''completed''::public.booking_status_enum WHERE id = p_related_entity_id';
  booking_fixed text := 'UPDATE public.bookings SET payment_status = (''released'')::text::public.payment_status_enum, status = (''completed'')::text::public.booking_status_enum WHERE id = p_related_entity_id';
  direct_current text := 'UPDATE public.direct_offers SET payment_status = ''released''::public.payment_status_enum, status = ''completed'' WHERE id = p_related_entity_id';
  direct_fixed text := 'UPDATE public.direct_offers SET payment_status = (''released'')::text::public.payment_status_enum, status = (''completed'')::text WHERE id = p_related_entity_id';
BEGIN
  SELECT pg_get_functiondef(oid) INTO def FROM pg_proc WHERE proname = 'process_payment_event_ledger';
  IF def IS NULL THEN
    RAISE EXCEPTION 'process_payment_event_ledger not found';
  END IF;

  IF position('::text::public.booking_status_enum' IN def) > 0 THEN
    RETURN;
  END IF;

  new_def := replace(def, booking_current, booking_fixed);
  IF new_def = def THEN
    new_def := replace(def, '            ' || booking_current, '            ' || booking_fixed);
  END IF;
  IF new_def = def THEN
    new_def := replace(def, ' ' || booking_current, ' ' || booking_fixed);
  END IF;
  IF new_def = def THEN
    new_def := replace(def, '''completed''::public.booking_status_enum', '(''completed'')::text::public.booking_status_enum');
    new_def := replace(new_def, '''released''::public.payment_status_enum', '(''released'')::text::public.payment_status_enum');
  END IF;
  IF new_def = def THEN
    RAISE EXCEPTION 'process_payment_event_ledger: booking release UPDATE block not found';
  END IF;

  IF position(direct_current IN new_def) > 0 THEN
    new_def := replace(new_def, direct_current, direct_fixed);
  ELSIF position('            ' || direct_current IN new_def) > 0 THEN
    new_def := replace(new_def, '            ' || direct_current, '            ' || direct_fixed);
  ELSIF position(' ' || direct_current IN new_def) > 0 THEN
    new_def := replace(new_def, ' ' || direct_current, ' ' || direct_fixed);
  END IF;

  EXECUTE new_def;
END $$;
