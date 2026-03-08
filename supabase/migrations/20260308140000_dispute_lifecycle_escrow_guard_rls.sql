-- Migration: Dispute lifecycle — escrow guard, RLS, deny policies
-- Plan: PLAN_DisputeLifecycle_2026-03-08
-- - Block rpc_approve_delivery and rpc_finalize_auto_approval when dispute is open/active
-- - Explicit deny UPDATE/DELETE on disputes for authenticated
-- - RLS for dispute_messages and dispute_evidence (participant-only)
-- - Indexes for dispute lookups

-- 1) rpc_approve_delivery: add dispute check at start of each branch
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
  v_task_id uuid;
  v_status text;
  v_payment_status text;
  v_price numeric;
  v_fee_rate_bps int;
  v_result json;
  v_idempotency_key text;
begin
  if entity_type = 'task' then
    if exists (select 1 from public.disputes where task_id = entity_id and status in ('open', 'active')) then
      raise exception 'Cannot approve delivery: dispute in progress';
    end if;
    select status, owner_id into v_status, v_client_id from tasks where id = entity_id;
    if v_client_id != v_uid then raise exception 'Not authorized'; end if;
    if v_status != 'delivered' then raise exception 'Work not delivered'; end if;

    update tasks set status = 'completed', review_expires_at = null
    where id = entity_id;

  elsif entity_type = 'booking' then
    select status, payment_status, client_id, provider_id, price, task_id
    into v_status, v_payment_status, v_client_id, v_provider_id, v_price, v_task_id
    from bookings where id = entity_id
    for update;

    if exists (select 1 from public.disputes where task_id = v_task_id and status in ('open', 'active')) then
      raise exception 'Cannot approve delivery: dispute in progress';
    end if;
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
    if exists (select 1 from public.disputes where direct_offer_id = entity_id and status in ('open', 'active')) then
      raise exception 'Cannot approve delivery: dispute in progress';
    end if;
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

-- 2) rpc_finalize_auto_approval: add dispute check (task + booking only)
CREATE OR REPLACE FUNCTION public.rpc_finalize_auto_approval(
  entity_type text,
  entity_id uuid
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  _status text;
  _review_expires timestamptz;
  _new_status text;
  _task_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;

  if entity_type = 'task' then
    if exists (select 1 from public.disputes where task_id = entity_id and status in ('open', 'active')) then
      select status into _status from public.tasks where id = entity_id;
      return _status;
    end if;
    select status, review_expires_at into _status, _review_expires
    from public.tasks where id = entity_id;

    if _status = 'delivered' and _review_expires is not null and now() > _review_expires then
      update public.tasks set status = 'completed' where id = entity_id;
      _new_status := 'completed';
    else
      _new_status := _status;
    end if;
    return _new_status;

  elsif entity_type = 'booking' then
    select task_id into _task_id from public.bookings where id = entity_id;
    if exists (select 1 from public.disputes where task_id = _task_id and status in ('open', 'active')) then
      select status::text into _status from public.bookings where id = entity_id;
      return _status;
    end if;
    select status::text, review_expires_at into _status, _review_expires
    from public.bookings where id = entity_id;

    if _status = 'delivered' and _review_expires is not null and now() > _review_expires then
      update public.bookings set status = 'completed' where id = entity_id;
      _new_status := 'completed';
    else
      _new_status := _status;
    end if;
    return _new_status;
  else
    raise exception 'Invalid entity type';
  end if;
end;
$function$;

-- 3) Explicit deny UPDATE/DELETE on disputes for authenticated
drop policy if exists disputes_deny_update on public.disputes;
create policy disputes_deny_update on public.disputes
  for update to authenticated using (false);

drop policy if exists disputes_deny_delete on public.disputes;
create policy disputes_deny_delete on public.disputes
  for delete to authenticated using (false);

-- 4) RLS dispute_messages: participant-only SELECT and INSERT
alter table public.dispute_messages enable row level security;

drop policy if exists dispute_messages_select_participant on public.dispute_messages;
create policy dispute_messages_select_participant on public.dispute_messages
  for select to authenticated
  using (
    auth.uid() in (
      select d.complainant_id from public.disputes d where d.id = dispute_id
      union
      select d.defendant_id from public.disputes d where d.id = dispute_id
    )
  );

drop policy if exists dispute_messages_insert_participant on public.dispute_messages;
create policy dispute_messages_insert_participant on public.dispute_messages
  for insert to authenticated
  with check (
    auth.uid() in (
      select d.complainant_id from public.disputes d where d.id = dispute_id
      union
      select d.defendant_id from public.disputes d where d.id = dispute_id
    )
  );

-- 5) RLS dispute_evidence: participant-only SELECT and INSERT (uploader must be participant)
alter table public.dispute_evidence enable row level security;

drop policy if exists dispute_evidence_select_participant on public.dispute_evidence;
create policy dispute_evidence_select_participant on public.dispute_evidence
  for select to authenticated
  using (
    auth.uid() in (
      select d.complainant_id from public.disputes d where d.id = dispute_id
      union
      select d.defendant_id from public.disputes d where d.id = dispute_id
    )
  );

drop policy if exists dispute_evidence_insert_participant on public.dispute_evidence;
create policy dispute_evidence_insert_participant on public.dispute_evidence
  for insert to authenticated
  with check (
    uploader_id = auth.uid()
    and auth.uid() in (
      select d.complainant_id from public.disputes d where d.id = dispute_id
      union
      select d.defendant_id from public.disputes d where d.id = dispute_id
    )
  );

-- 6) Indexes for dispute guards and dashboard
create index if not exists idx_disputes_task_id on public.disputes (task_id);
create index if not exists idx_disputes_direct_offer_id on public.disputes (direct_offer_id);
create index if not exists idx_disputes_status on public.disputes (status);
