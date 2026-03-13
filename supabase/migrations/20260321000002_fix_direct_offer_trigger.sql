-- Migration to fix direct_offer_status_enum type error
-- The fn_lock_direct_offer_fee_on_accept trigger function incorrectly casts status to a non-existent enum.
-- The status column on direct_offers is of type text.

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_lock_direct_offer_fee_on_accept()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_fee_bps int;
  v_fee_amount bigint;
  v_price numeric;
BEGIN
  -- Replaced 'accepted'::public.direct_offer_status_enum with just 'accepted'
  IF NEW.status = 'accepted'
     AND NEW.payment_status = 'unpaid'::public.payment_status_enum THEN
    IF TG_OP = 'INSERT'
       OR OLD.status IS DISTINCT FROM NEW.status
       OR OLD.payment_status IS DISTINCT FROM NEW.payment_status
       OR OLD.fee_rate_applied_bps IS NULL THEN
      v_fee_bps := public.fn_get_default_fee_rate_bps();
      IF v_fee_bps IS NULL THEN
        RAISE EXCEPTION 'Default fee rate not configured';
      END IF;
      v_price := COALESCE(NEW.price, 0);
      v_fee_amount := FLOOR(v_price * v_fee_bps / 10000.0)::bigint;

      NEW.fee_rate_applied_bps := v_fee_bps;
      NEW.fee_amount := v_fee_amount;
      NEW.net_amount := GREATEST(v_price::bigint - v_fee_amount, 0);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMIT;
