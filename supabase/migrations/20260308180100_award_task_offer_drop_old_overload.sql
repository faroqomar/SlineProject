-- Resolve "Could not choose the best candidate function" when calling award_task_offer.
-- Drop the old 2-parameter overload (p_request_id, p_expected_price_cents) so only the
-- 3-parameter version (p_request_id, p_client_id, p_expected_price_cents) remains.
-- The app calls with named params p_request_id and p_expected_price_cents; p_client_id defaults to NULL.

DROP FUNCTION IF EXISTS public.award_task_offer(uuid, bigint);
