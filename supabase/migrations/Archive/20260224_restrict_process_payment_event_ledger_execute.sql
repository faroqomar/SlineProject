-- Restrict direct RPC execution surface for payment ledger processing.
-- Keep access for authenticated app users and service_role automation only.

REVOKE EXECUTE ON FUNCTION public.process_payment_event_ledger(
  text,
  text,
  uuid,
  text,
  numeric,
  text,
  jsonb
) FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.process_payment_event_ledger(
  text,
  text,
  uuid,
  text,
  numeric,
  text,
  jsonb
) FROM anon;

GRANT EXECUTE ON FUNCTION public.process_payment_event_ledger(
  text,
  text,
  uuid,
  text,
  numeric,
  text,
  jsonb
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.process_payment_event_ledger(
  text,
  text,
  uuid,
  text,
  numeric,
  text,
  jsonb
) TO service_role;
