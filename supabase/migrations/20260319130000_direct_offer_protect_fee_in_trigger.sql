-- Migration: Extend price/currency trigger to also protect fee_rate_applied_bps (Plan Phase 1 step 4).
-- When status != 'sent' or payment_status != 'unpaid', block UPDATE of price, currency, and fee_rate_applied_bps.

CREATE OR REPLACE FUNCTION public.fn_direct_offer_protect_price_currency()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF (OLD.status IS DISTINCT FROM 'sent' OR OLD.payment_status IS DISTINCT FROM 'unpaid')
     AND (
       NEW.price IS DISTINCT FROM OLD.price
       OR NEW.currency IS DISTINCT FROM OLD.currency
       OR NEW.fee_rate_applied_bps IS DISTINCT FROM OLD.fee_rate_applied_bps
     ) THEN
    RAISE EXCEPTION 'ERR_DIRECT_OFFER: price, currency and fee_rate_applied_bps cannot be changed when offer is not in sent/unpaid state';
  END IF;
  RETURN NEW;
END;
$$;
