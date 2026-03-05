-- Fix approve-delivery ledger release on Supabase where pgcrypto functions
-- are installed under the extensions schema.

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
    from bookings where id = entity_id;

    if v_client_id != v_uid then raise exception 'Not authorized'; end if;
    if v_status != 'delivered' then raise exception 'Work not delivered'; end if;

    if v_payment_status = 'held' then
      v_idempotency_key := encode(
        extensions.digest(entity_id::text || ':release_with_fee:' || now()::text, 'sha256'),
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
    else
      update bookings set status = 'completed', review_expires_at = null
      where id = entity_id;
    end if;

  else
    raise exception 'Invalid entity type';
  end if;
end;
$function$;
