-- Migration: Auto-release expired direct_offers (review window passed, no dispute).
-- SECURITY DEFINER so it can call process_payment_event_ledger; runs as cron (no session).

CREATE OR REPLACE FUNCTION public.run_auto_release_expired_direct_offers()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  r record;
  v_idempotency_key text;
  v_result jsonb;
  v_count int := 0;
BEGIN
  FOR r IN
    SELECT id, client_id, freelancer_id, price, fee_rate_applied_bps, status, payment_status
    FROM public.direct_offers
    WHERE status = 'delivered'
      AND payment_status = 'held'
      AND review_expires_at IS NOT NULL
      AND review_expires_at < now()
    FOR UPDATE SKIP LOCKED
  LOOP
    v_idempotency_key := encode(
      extensions.digest(
        r.id::text || ':release_with_fee:' || r.status || ':' || r.payment_status,
        'sha256'
      ),
      'hex'
    );

    v_result := process_payment_event_ledger(
      p_event_type := 'release_with_fee',
      p_related_entity_type := 'direct_offer',
      p_related_entity_id := r.id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(r.price, 0),
      p_meta := jsonb_build_object(
        'fee_rate_bps', COALESCE(r.fee_rate_applied_bps, 1000),
        'client_id', r.client_id,
        'freelancer_id', r.freelancer_id,
        'auto_release', true
      )
    );

    IF (v_result->>'ok')::boolean = true THEN
      UPDATE public.direct_offers
      SET payment_status = 'released', status = 'completed'
      WHERE id = r.id;
      v_count := v_count + 1;
    END IF;
  END LOOP;
  RETURN v_count;
END;
$$;

-- Schedule daily (e.g. every hour to keep review window accurate)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'auto-release-expired-direct-offers') THEN
    PERFORM cron.schedule(
      'auto-release-expired-direct-offers',
      '0 * * * *',
      'SELECT run_auto_release_expired_direct_offers()'
    );
  END IF;
END
$$;
