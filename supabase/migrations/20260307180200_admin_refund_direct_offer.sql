-- Admin-only RPC to refund a direct_offer (Plan 19). Uses same ledger pattern as process_payment_event_ledger refund branch.
-- Caller must be in public.admin_users. Idempotent by p_idempotency_key.

CREATE OR REPLACE FUNCTION public.admin_refund_direct_offer(
  p_offer_id uuid,
  p_reason text DEFAULT NULL,
  p_idempotency_key text DEFAULT gen_random_uuid()::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
  v_offer RECORD;
  v_platform_escrow_id uuid;
  v_user_available_id uuid;
  v_journal_entry_id uuid;
  v_existing_id uuid;
BEGIN
  IF v_admin_id IS NULL OR NOT EXISTS (SELECT 1 FROM public.admin_users WHERE id = v_admin_id) THEN
    RAISE EXCEPTION 'only admin can refund direct_offer';
  END IF;

  SELECT id, client_id, freelancer_id, status, payment_status, price
  INTO v_offer
  FROM public.direct_offers
  WHERE id = p_offer_id
  FOR UPDATE;

  IF v_offer IS NULL THEN
    RAISE EXCEPTION 'offer not found';
  END IF;

  IF v_offer.payment_status != 'held' THEN
    RAISE EXCEPTION 'offer not in refundable state (payment_status must be held)';
  END IF;

  -- Idempotency: same key already processed
  SELECT id INTO v_existing_id
  FROM public.journal_entries
  WHERE idempotency_key = p_idempotency_key
    AND related_entity_type = 'direct_offer'
    AND related_entity_id = p_offer_id
  LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'ok', true,
      'offer_id', p_offer_id,
      'journal_entry_id', v_existing_id,
      'idempotent', true
    );
  END IF;

  SELECT id INTO v_platform_escrow_id FROM public.accounts WHERE account_code = 'platform_escrow';
  IF v_platform_escrow_id IS NULL THEN
    RAISE EXCEPTION 'platform_escrow account not found';
  END IF;

  SELECT id INTO v_user_available_id FROM public.accounts WHERE account_code = 'user_available:' || v_offer.client_id::text;
  IF v_user_available_id IS NULL THEN
    INSERT INTO public.accounts (account_code, account_type, owner_id, currency)
    VALUES ('user_available:' || v_offer.client_id::text, 'asset', v_offer.client_id, 'IQD')
    RETURNING id INTO v_user_available_id;
  END IF;

  INSERT INTO public.journal_entries (
    event_type, related_entity_type, related_entity_id,
    idempotency_key, created_by, currency, meta, status
  ) VALUES (
    'refund'::public.payment_event_type_enum,
    'direct_offer'::public.related_entity_type_enum,
    p_offer_id,
    p_idempotency_key,
    v_admin_id,
    'IQD',
    jsonb_build_object(
      'client_id', v_offer.client_id,
      'provider_id', v_offer.freelancer_id,
      'refund_reason', p_reason,
      'amount_gross', v_offer.price
    ),
    'posted'
  ) RETURNING id INTO v_journal_entry_id;

  INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
  VALUES
    (v_journal_entry_id, v_platform_escrow_id, 'DEBIT', v_offer.price, 'IQD'),
    (v_journal_entry_id, v_user_available_id, 'CREDIT', v_offer.price, 'IQD');

  UPDATE public.direct_offers SET payment_status = 'refunded', status = 'refunded' WHERE id = p_offer_id;

  INSERT INTO public.audit_logs (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta)
  VALUES (v_admin_id, 'payment.refund', 'direct_offer', p_offer_id, v_journal_entry_id,
          jsonb_build_object('amount', v_offer.price, 'reason', p_reason));

  RETURN jsonb_build_object(
    'ok', true,
    'offer_id', p_offer_id,
    'journal_entry_id', v_journal_entry_id
  );
END;
$$;

COMMENT ON FUNCTION public.admin_refund_direct_offer IS 'Admin-only refund for direct_offer. Caller must be in admin_users. Idempotent by p_idempotency_key.';

-- Only service_role or authenticated admin (via RLS/admin_users) should call; anon cannot.
REVOKE EXECUTE ON FUNCTION public.admin_refund_direct_offer FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_refund_direct_offer TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_refund_direct_offer TO service_role;
