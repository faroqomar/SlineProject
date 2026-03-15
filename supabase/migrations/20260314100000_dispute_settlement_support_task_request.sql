-- Extend dispute settlement to support task_request/tender escrow targets.

CREATE OR REPLACE FUNCTION public.admin_resolve_dispute(
  p_admin_id uuid,
  p_dispute_id uuid,
  p_reason text,
  p_outcome text DEFAULT NULL,
  p_booking_id uuid DEFAULT NULL,
  p_task_request_id uuid DEFAULT NULL,
  p_client_refund_amount bigint DEFAULT NULL,
  p_freelancer_payout_amount bigint DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_dispute RECORD;
  v_booking RECORD;
  v_task_request RECORD;
  v_offer RECORD;
  v_entity_type text;
  v_entity_id uuid;
  v_client_id uuid;
  v_provider_id uuid;
  v_gross bigint;
  v_fee_bps integer;
  v_fee_amount bigint;
  v_refund_amount bigint;
  v_payout_amount bigint;
  v_event_type text;
  v_idempotency_key text;
  v_existing RECORD;
  v_journal_entry_id uuid;
  v_platform_escrow_id uuid;
  v_platform_revenue_id uuid;
  v_client_available_id uuid;
  v_provider_available_id uuid;
  v_now timestamptz := now();
  v_held_booking_count integer := 0;
  v_held_task_request_count integer := 0;
BEGIN
  IF p_admin_id IS NULL OR NOT public.is_admin(p_admin_id) THEN
    RAISE EXCEPTION 'Only admin can resolve a dispute';
  END IF;
  IF COALESCE(length(trim(p_reason)), 0) < 1 THEN
    RAISE EXCEPTION 'Reason is required for resolve';
  END IF;
  IF p_outcome NOT IN ('refund_client', 'release_freelancer', 'split_settlement') THEN
    RAISE EXCEPTION 'Outcome must be refund_client, release_freelancer, or split_settlement';
  END IF;

  v_idempotency_key := COALESCE(
    NULLIF(trim(p_idempotency_key), ''),
    encode(
      extensions.digest(
        concat_ws(
          ':',
          p_dispute_id::text,
          p_outcome,
          COALESCE(p_booking_id::text, ''),
          COALESCE(p_task_request_id::text, ''),
          COALESCE(p_client_refund_amount::text, ''),
          COALESCE(p_freelancer_payout_amount::text, '')
        ),
        'sha256'
      ),
      'hex'
    )
  );

  SELECT je.id, je.related_entity_type::text AS related_entity_type, je.related_entity_id, je.meta
  INTO v_existing
  FROM public.journal_entries je
  WHERE je.idempotency_key = v_idempotency_key
    AND je.meta->>'dispute_id' = p_dispute_id::text
  LIMIT 1;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'dispute_id', p_dispute_id,
      'status', 'resolved',
      'outcome', COALESCE(v_existing.meta->>'outcome', p_outcome),
      'entity_type', v_existing.related_entity_type,
      'entity_id', v_existing.related_entity_id,
      'booking_id', NULLIF(v_existing.meta->>'booking_id', ''),
      'task_request_id', NULLIF(v_existing.meta->>'task_request_id', ''),
      'direct_offer_id', NULLIF(v_existing.meta->>'direct_offer_id', ''),
      'journal_entry_ids', jsonb_build_array(v_existing.id),
      'fee_amount', COALESCE((v_existing.meta->>'fee_amount')::bigint, 0),
      'client_refund_amount', COALESCE((v_existing.meta->>'client_refund_amount')::bigint, 0),
      'freelancer_payout_amount', COALESCE((v_existing.meta->>'freelancer_payout_amount')::bigint, 0),
      'client_wallet_destination', 'available_balance',
      'freelancer_wallet_destination', 'available_balance',
      'idempotent', true
    );
  END IF;

  SELECT id, task_id, direct_offer_id, status::text
  INTO v_dispute
  FROM public.disputes
  WHERE id = p_dispute_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dispute not found';
  END IF;
  IF v_dispute.status <> 'active' THEN
    RAISE EXCEPTION 'Only active disputes can be resolved (current: %)', v_dispute.status;
  END IF;

  IF v_dispute.direct_offer_id IS NOT NULL THEN
    v_entity_type := 'direct_offer';
    v_entity_id := v_dispute.direct_offer_id;
    SELECT id, client_id, freelancer_id, status::text, payment_status::text, price, fee_rate_applied_bps
    INTO v_offer
    FROM public.direct_offers
    WHERE id = v_entity_id
    FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Direct offer not found';
    END IF;
    IF v_offer.payment_status <> 'held' THEN
      RAISE EXCEPTION 'Direct offer payment must be held for dispute settlement';
    END IF;
    v_client_id := v_offer.client_id;
    v_provider_id := v_offer.freelancer_id;
    v_gross := COALESCE(v_offer.price, 0);
    v_fee_bps := COALESCE(v_offer.fee_rate_applied_bps, public.fn_get_default_fee_rate_bps());
  ELSE
    IF p_booking_id IS NULL AND p_task_request_id IS NULL THEN
      SELECT COUNT(*)
      INTO v_held_booking_count
      FROM public.bookings
      WHERE task_id = v_dispute.task_id
        AND payment_status = 'held'::public.payment_status_enum;

      SELECT COUNT(*)
      INTO v_held_task_request_count
      FROM public.task_requests
      WHERE task_id = v_dispute.task_id
        AND payment_status = 'held'::public.payment_status_enum
        AND deleted_at IS NULL;

      IF v_held_booking_count + v_held_task_request_count = 0 THEN
        RAISE EXCEPTION 'No held booking or task_request found for this dispute';
      ELSIF v_held_booking_count + v_held_task_request_count > 1 THEN
        RAISE EXCEPTION 'Multiple settlement targets found; booking_id or task_request_id is required';
      ELSIF v_held_booking_count = 1 THEN
        SELECT id INTO p_booking_id
        FROM public.bookings
        WHERE task_id = v_dispute.task_id
          AND payment_status = 'held'::public.payment_status_enum
        LIMIT 1;
      ELSE
        SELECT id INTO p_task_request_id
        FROM public.task_requests
        WHERE task_id = v_dispute.task_id
          AND payment_status = 'held'::public.payment_status_enum
          AND deleted_at IS NULL
        LIMIT 1;
      END IF;
    END IF;

    IF p_booking_id IS NOT NULL THEN
      v_entity_type := 'booking';
      v_entity_id := p_booking_id;
      SELECT id, task_id, client_id, provider_id, status::text, payment_status::text, price, fee_rate_applied_bps
      INTO v_booking
      FROM public.bookings
      WHERE id = p_booking_id
      FOR UPDATE;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found';
      END IF;
      IF v_dispute.task_id IS NOT NULL AND v_booking.task_id IS DISTINCT FROM v_dispute.task_id THEN
        RAISE EXCEPTION 'booking_id does not belong to the dispute task';
      END IF;
      IF v_booking.payment_status <> 'held' THEN
        RAISE EXCEPTION 'Booking payment must be held for dispute settlement';
      END IF;
      v_client_id := v_booking.client_id;
      v_provider_id := v_booking.provider_id;
      v_gross := COALESCE(v_booking.price, 0);
      v_fee_bps := COALESCE(v_booking.fee_rate_applied_bps, public.fn_get_default_fee_rate_bps());
    ELSE
      v_entity_type := 'task_request';
      v_entity_id := p_task_request_id;
      SELECT id, task_id, client_id, freelancer_id, bidder_id, status::text, payment_status::text, amount, price, fee_rate_applied_bps
      INTO v_task_request
      FROM public.task_requests
      WHERE id = p_task_request_id
        AND deleted_at IS NULL
      FOR UPDATE;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Task request not found';
      END IF;
      IF v_dispute.task_id IS NOT NULL AND v_task_request.task_id IS DISTINCT FROM v_dispute.task_id THEN
        RAISE EXCEPTION 'task_request_id does not belong to the dispute task';
      END IF;
      IF v_task_request.payment_status <> 'held' THEN
        RAISE EXCEPTION 'Task request payment must be held for dispute settlement';
      END IF;
      v_provider_id := COALESCE(v_task_request.freelancer_id, v_task_request.bidder_id);
      SELECT COALESCE(v_task_request.client_id, t.client_id, t.owner_id)
      INTO v_client_id
      FROM public.tasks t
      WHERE t.id = v_task_request.task_id;
      v_gross := COALESCE(v_task_request.amount, v_task_request.price, 0);
      v_fee_bps := COALESCE(v_task_request.fee_rate_applied_bps, public.fn_get_default_fee_rate_bps());
      IF v_client_id IS NULL OR v_provider_id IS NULL THEN
        RAISE EXCEPTION 'Task request parties could not be determined';
      END IF;
    END IF;
  END IF;

  v_fee_amount := FLOOR(v_gross * v_fee_bps / 10000.0)::bigint;

  IF p_outcome = 'refund_client' THEN
    v_refund_amount := v_gross;
    v_payout_amount := 0;
    v_fee_amount := 0;
    v_event_type := 'refund';
  ELSIF p_outcome = 'release_freelancer' THEN
    v_refund_amount := 0;
    v_payout_amount := GREATEST(v_gross - v_fee_amount, 0);
    v_event_type := 'release_with_fee';
  ELSE
    IF p_client_refund_amount IS NULL OR p_freelancer_payout_amount IS NULL THEN
      RAISE EXCEPTION 'Split settlement requires client_refund_amount and freelancer_payout_amount';
    END IF;
    IF p_client_refund_amount < 0 OR p_freelancer_payout_amount < 0 THEN
      RAISE EXCEPTION 'Split amounts must be non-negative';
    END IF;
    v_refund_amount := p_client_refund_amount;
    v_payout_amount := p_freelancer_payout_amount;
    IF v_refund_amount + v_payout_amount + v_fee_amount <> v_gross THEN
      RAISE EXCEPTION 'Split settlement must satisfy refund + payout + fee = gross';
    END IF;
    v_event_type := 'dispute_split';
  END IF;

  SELECT id INTO v_platform_escrow_id FROM public.accounts WHERE account_code = 'platform_escrow';
  IF v_platform_escrow_id IS NULL THEN
    RAISE EXCEPTION 'platform_escrow account not found';
  END IF;
  SELECT id INTO v_platform_revenue_id FROM public.accounts WHERE account_code = 'platform_revenue';
  IF v_platform_revenue_id IS NULL THEN
    RAISE EXCEPTION 'platform_revenue account not found';
  END IF;
  SELECT id INTO v_client_available_id FROM public.accounts WHERE account_code = 'user_available:' || v_client_id::text;
  IF v_client_available_id IS NULL THEN
    INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
    VALUES ('user_available:' || v_client_id::text, 'asset', v_client_id, 'IQD')
    RETURNING id INTO v_client_available_id;
  END IF;
  SELECT id INTO v_provider_available_id FROM public.accounts WHERE account_code = 'user_available:' || v_provider_id::text;
  IF v_provider_available_id IS NULL THEN
    INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
    VALUES ('user_available:' || v_provider_id::text, 'asset', v_provider_id, 'IQD')
    RETURNING id INTO v_provider_available_id;
  END IF;

  INSERT INTO public.journal_entries (
    event_type, related_entity_type, related_entity_id, idempotency_key, created_by, currency, meta, status
  ) VALUES (
    v_event_type::public.payment_event_type_enum,
    v_entity_type::public.related_entity_type_enum,
    v_entity_id,
    v_idempotency_key,
    p_admin_id,
    'IQD',
    jsonb_build_object(
      'dispute_id', p_dispute_id,
      'booking_id', CASE WHEN v_entity_type = 'booking' THEN v_entity_id ELSE NULL END,
      'task_request_id', CASE WHEN v_entity_type = 'task_request' THEN v_entity_id ELSE NULL END,
      'direct_offer_id', CASE WHEN v_entity_type = 'direct_offer' THEN v_entity_id ELSE NULL END,
      'client_id', v_client_id,
      'provider_id', v_provider_id,
      'outcome', p_outcome,
      'gross_amount', v_gross,
      'fee_rate_bps', v_fee_bps,
      'fee_amount', v_fee_amount,
      'client_refund_amount', v_refund_amount,
      'freelancer_payout_amount', v_payout_amount,
      'client_wallet_destination', 'available_balance',
      'freelancer_wallet_destination', 'available_balance',
      'resolution_reason', trim(p_reason)
    ),
    'posted'
  ) RETURNING id INTO v_journal_entry_id;

  INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
  VALUES (v_journal_entry_id, v_platform_escrow_id, 'DEBIT', v_gross, 'IQD');
  IF v_refund_amount > 0 THEN
    INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
    VALUES (v_journal_entry_id, v_client_available_id, 'CREDIT', v_refund_amount, 'IQD');
  END IF;
  IF v_payout_amount > 0 THEN
    INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
    VALUES (v_journal_entry_id, v_provider_available_id, 'CREDIT', v_payout_amount, 'IQD');
  END IF;
  IF v_fee_amount > 0 THEN
    INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
    VALUES (v_journal_entry_id, v_platform_revenue_id, 'CREDIT', v_fee_amount, 'IQD');
  END IF;

  IF v_entity_type = 'booking' THEN
    UPDATE public.bookings
    SET
      status = CASE WHEN p_outcome = 'refund_client' THEN 'refunded' ELSE 'completed' END::public.booking_status_enum,
      payment_status = CASE WHEN p_outcome = 'refund_client' THEN 'refunded' ELSE 'released' END::public.payment_status_enum,
      review_expires_at = NULL,
      fee_amount = v_fee_amount,
      net_amount = v_payout_amount
    WHERE id = v_entity_id;
  ELSIF v_entity_type = 'task_request' THEN
    UPDATE public.task_requests
    SET
      payment_status = CASE WHEN p_outcome = 'refund_client' THEN 'refunded' ELSE 'released' END::public.payment_status_enum,
      status = CASE WHEN p_outcome = 'refund_client' THEN status ELSE 'completed' END,
      fee_amount = v_fee_amount,
      net_amount = v_payout_amount
    WHERE id = v_entity_id;
  ELSE
    UPDATE public.direct_offers
    SET
      status = CASE WHEN p_outcome = 'refund_client' THEN 'refunded' ELSE 'completed' END,
      payment_status = CASE WHEN p_outcome = 'refund_client' THEN 'refunded' ELSE 'released' END::public.payment_status_enum,
      fee_amount = v_fee_amount,
      net_amount = v_payout_amount
    WHERE id = v_entity_id;
  END IF;

  UPDATE public.disputes
  SET status = 'resolved'::public.dispute_status_enum, resolved_at = v_now, resolution = trim(p_reason)
  WHERE id = p_dispute_id;

  INSERT INTO public.audit_logs (
    action, actor_user_id, related_entity_type, related_entity_id, journal_entry_id, meta
  ) VALUES (
    'admin.disputes.resolve',
    p_admin_id,
    'dispute',
    p_dispute_id,
    v_journal_entry_id,
    jsonb_build_object(
      'from_status', 'active',
      'to_status', 'resolved',
      'outcome', p_outcome,
      'entity_type', v_entity_type,
      'entity_id', v_entity_id,
      'booking_id', CASE WHEN v_entity_type = 'booking' THEN v_entity_id ELSE NULL END,
      'task_request_id', CASE WHEN v_entity_type = 'task_request' THEN v_entity_id ELSE NULL END,
      'direct_offer_id', CASE WHEN v_entity_type = 'direct_offer' THEN v_entity_id ELSE NULL END,
      'fee_amount', v_fee_amount,
      'client_refund_amount', v_refund_amount,
      'freelancer_payout_amount', v_payout_amount,
      'idempotency_key', v_idempotency_key,
      'reason', trim(p_reason)
    )
  );

  RETURN jsonb_build_object(
    'dispute_id', p_dispute_id,
    'status', 'resolved',
    'outcome', p_outcome,
    'entity_type', v_entity_type,
    'entity_id', v_entity_id,
    'booking_id', CASE WHEN v_entity_type = 'booking' THEN v_entity_id ELSE NULL END,
    'task_request_id', CASE WHEN v_entity_type = 'task_request' THEN v_entity_id ELSE NULL END,
    'direct_offer_id', CASE WHEN v_entity_type = 'direct_offer' THEN v_entity_id ELSE NULL END,
    'journal_entry_ids', jsonb_build_array(v_journal_entry_id),
    'fee_amount', v_fee_amount,
    'client_refund_amount', v_refund_amount,
    'freelancer_payout_amount', v_payout_amount,
    'client_wallet_destination', 'available_balance',
    'freelancer_wallet_destination', 'available_balance',
    'idempotent', false
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_resolve_dispute_settlement(
  p_admin_id uuid,
  p_dispute_id uuid,
  p_reason text,
  p_outcome text DEFAULT NULL,
  p_booking_id uuid DEFAULT NULL,
  p_task_request_id uuid DEFAULT NULL,
  p_client_refund_amount bigint DEFAULT NULL,
  p_freelancer_payout_amount bigint DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.admin_resolve_dispute(
    p_admin_id := p_admin_id,
    p_dispute_id := p_dispute_id,
    p_reason := p_reason,
    p_outcome := p_outcome,
    p_booking_id := p_booking_id,
    p_task_request_id := p_task_request_id,
    p_client_refund_amount := p_client_refund_amount,
    p_freelancer_payout_amount := p_freelancer_payout_amount,
    p_idempotency_key := p_idempotency_key
  );
END;
$$;
