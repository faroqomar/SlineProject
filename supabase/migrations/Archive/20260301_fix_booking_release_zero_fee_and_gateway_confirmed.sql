-- Patch the live ledger function in place instead of replacing the entire body.
-- This keeps the migration narrowly scoped to:
-- 1. fee-free booking release entries, which must skip zero-value revenue lines
-- 2. gateway escrow for slotless bookings that may already be confirmed

DO $migration$
DECLARE
  v_sql text;
  v_old_release text := $old_release$
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_platform_escrow_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_available_id, 'CREDIT', v_net_amount, p_currency),
            (v_journal_entry_id, v_platform_revenue_id, 'CREDIT', v_fee_amount, p_currency);
$old_release$;
  v_new_release text := $new_release$
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        SELECT v_journal_entry_id, line.account_id, line.direction, line.amount, p_currency
        FROM (
            VALUES
                (v_platform_escrow_id, 'DEBIT'::TEXT, v_entity_amount_gross),
                (v_user_available_id, 'CREDIT'::TEXT, v_net_amount),
                (v_platform_revenue_id, 'CREDIT'::TEXT, v_fee_amount)
        ) AS line(account_id, direction, amount)
        WHERE line.amount > 0;
$new_release$;
  v_old_gateway text := $old_gateway$
        IF v_entity.status != 'pending' OR v_entity.payment_status != 'unpaid' THEN
            RETURN jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'ERR_GATE_NOT_ALLOWED', 'message', 'Gateway escrow not allowed. Booking must be pending and unpaid.'));
        END IF;
$old_gateway$;
  v_new_gateway text := $new_gateway$
        IF v_entity.status NOT IN ('pending', 'confirmed') OR v_entity.payment_status != 'unpaid' THEN
            RETURN jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'ERR_GATE_NOT_ALLOWED', 'message', 'Gateway escrow not allowed. Booking must be pending or confirmed and unpaid.'));
        END IF;
$new_gateway$;
BEGIN
  SELECT pg_get_functiondef(
    'public.process_payment_event_ledger(text,text,uuid,text,numeric,text,jsonb)'::regprocedure
  )
  INTO v_sql;

  IF position(v_new_release in v_sql) = 0 THEN
    IF position(v_old_release in v_sql) = 0 THEN
      RAISE EXCEPTION 'process_payment_event_ledger release branch did not match expected pre-patch body';
    END IF;
    v_sql := replace(v_sql, v_old_release, v_new_release);
  END IF;

  IF position(v_new_gateway in v_sql) = 0 THEN
    IF position(v_old_gateway in v_sql) = 0 THEN
      RAISE EXCEPTION 'process_payment_event_ledger gateway_escrow branch did not match expected pre-patch body';
    END IF;
    v_sql := replace(v_sql, v_old_gateway, v_new_gateway);
  END IF;

  EXECUTE v_sql;
END
$migration$;
