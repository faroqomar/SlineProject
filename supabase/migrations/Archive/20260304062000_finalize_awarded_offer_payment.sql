-- Proposals: single entry point for completing awarded offer payment (DB side).
-- Client/coordinator must call ledger (edge/app) then this RPC; do not report success until both succeed.
-- This RPC is the canonical DB update; atomicity with ledger is enforced by coordinator (one path, no partial success).
BEGIN;

-- Wrapper so app has one RPC name for "finalize after payment confirmed".
-- Delegates to pay_awarded_offer; auth is bound to auth.uid() there.
CREATE OR REPLACE FUNCTION public.finalize_awarded_offer_payment(p_request_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.pay_awarded_offer(p_request_id, NULL);
END;
$$;

COMMENT ON FUNCTION public.finalize_awarded_offer_payment(UUID) IS
  'Completes DB side of awarded offer payment. Call after ledger/confirmation; coordinator must ensure atomicity.';

COMMIT;
