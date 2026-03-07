-- Migration: direct_offer flow hardening (Phase 1 remainder)
-- - Trigger: block UPDATE of price/currency when status != 'sent' or payment_status != 'unpaid'
-- - RLS: disputes INSERT when direct_offer_id set and complainant is party to that offer
-- - rpc_approve_delivery: use fee_rate_applied_bps from direct_offers row for release_with_fee

-- 1) Trigger: protect price and currency after offer is no longer editable
CREATE OR REPLACE FUNCTION public.fn_direct_offer_protect_price_currency()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF (OLD.status IS DISTINCT FROM 'sent' OR OLD.payment_status IS DISTINCT FROM 'unpaid')
     AND (NEW.price IS DISTINCT FROM OLD.price OR NEW.currency IS DISTINCT FROM OLD.currency) THEN
    RAISE EXCEPTION 'ERR_DIRECT_OFFER: price and currency cannot be changed when offer is not in sent/unpaid state';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_direct_offer_protect_price_currency ON public.direct_offers;
CREATE TRIGGER trg_direct_offer_protect_price_currency
  BEFORE UPDATE ON public.direct_offers
  FOR EACH ROW EXECUTE FUNCTION public.fn_direct_offer_protect_price_currency();

-- 2) RLS: disputes INSERT for direct_offer — complainant must be client or freelancer of the offer
DROP POLICY IF EXISTS disputes_insert_own ON public.disputes;
CREATE POLICY disputes_insert_own ON public.disputes
  FOR INSERT
  WITH CHECK (
    complainant_id = auth.uid()
    AND (
      (task_id IS NOT NULL)
      OR (
        direct_offer_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM public.direct_offers d
          WHERE d.id = direct_offer_id
            AND (d.client_id = auth.uid() OR d.freelancer_id = auth.uid())
        )
      )
    )
  );

-- 3) rpc_approve_delivery: read fee_rate_applied_bps from direct_offers for release_with_fee
CREATE OR REPLACE FUNCTION public.rpc_approve_delivery(
  entity_type text,
  entity_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_client_id uuid;
  v_provider_id uuid;
  v_status text;
  v_payment_status text;
  v_price numeric;
  v_fee_rate_bps int;
  v_result json;
  v_idempotency_key text;
begin
  if entity_type = 'task' then
    select status, owner_id into v_status, v_client_id from tasks where id = entity_id;
    if v_client_id != v_uid then raise exception 'Not authorized'; end if;
    if v_status != 'delivered' then raise exception 'Work not delivered'; end if;

    update tasks set status = 'completed', review_expires_at = null
    where id = entity_id;

  elsif entity_type = 'booking' then
    select status, payment_status, client_id, provider_id, price
    into v_status, v_payment_status, v_client_id, v_provider_id, v_price
    from bookings where id = entity_id
    for update;

    if v_client_id != v_uid then raise exception 'Not authorized'; end if;
    if v_status != 'delivered' then raise exception 'Work not delivered'; end if;

    if v_payment_status = 'held' then
      v_idempotency_key := encode(
        extensions.digest(
          entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
          'sha256'
        ),
        'hex'
      );

      v_result := process_payment_event_ledger(
        p_event_type := 'release_with_fee',
        p_related_entity_type := 'booking',
        p_related_entity_id := entity_id,
        p_idempotency_key := v_idempotency_key,
        p_amount_gross := COALESCE(v_price, 0),
        p_meta := '{"fee_rate_bps": 0}'::jsonb
      );

      if (v_result->>'ok')::boolean IS DISTINCT FROM true then
        raise exception 'Ledger release failed: %', v_result->'error'->>'message';
      end if;

      update bookings
      set review_expires_at = null
      where id = entity_id;
    else
      update bookings set status = 'completed', review_expires_at = null
      where id = entity_id;
    end if;

  elsif entity_type = 'direct_offer' then
    select status, payment_status, client_id, freelancer_id, price, fee_rate_applied_bps
    into v_status, v_payment_status, v_client_id, v_provider_id, v_price, v_fee_rate_bps
    from direct_offers where id = entity_id
    for update;

    if v_client_id != v_uid then raise exception 'Not authorized'; end if;
    if v_status != 'delivered' then raise exception 'Work not delivered'; end if;
    if v_payment_status != 'held' then raise exception 'Payment not held'; end if;

    v_idempotency_key := encode(
      extensions.digest(
        entity_id::text || ':release_with_fee:' || v_status || ':' || v_payment_status,
        'sha256'
      ),
      'hex'
    );

    v_result := process_payment_event_ledger(
      p_event_type := 'release_with_fee',
      p_related_entity_type := 'direct_offer',
      p_related_entity_id := entity_id,
      p_idempotency_key := v_idempotency_key,
      p_amount_gross := COALESCE(v_price, 0),
      p_meta := jsonb_build_object(
        'fee_rate_bps', COALESCE(v_fee_rate_bps, 1000),
        'client_id', v_client_id,
        'freelancer_id', v_provider_id
      )
    );

    if (v_result->>'ok')::boolean IS DISTINCT FROM true then
      raise exception 'Ledger release failed: %', v_result->'error'->>'message';
    end if;

    update direct_offers
    set payment_status = 'released', status = 'completed'
    where id = entity_id;

  else
    raise exception 'Invalid entity type';
  end if;
end;
$function$;
