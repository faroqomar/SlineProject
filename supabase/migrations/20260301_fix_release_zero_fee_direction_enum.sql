-- Fix the zero-fee release patch so the derived direction values keep the
-- ledger_direction_enum type expected by ledger_lines.direction.

DO $migration$
DECLARE
  v_sql text;
  v_old_release text := $old_release$
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        SELECT v_journal_entry_id, line.account_id, line.direction, line.amount, p_currency
        FROM (
            VALUES
                (v_platform_escrow_id, 'DEBIT'::TEXT, v_entity_amount_gross),
                (v_user_available_id, 'CREDIT'::TEXT, v_net_amount),
                (v_platform_revenue_id, 'CREDIT'::TEXT, v_fee_amount)
        ) AS line(account_id, direction, amount)
        WHERE line.amount > 0;
$old_release$;
  v_new_release text := $new_release$
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        SELECT v_journal_entry_id, line.account_id, line.direction, line.amount, p_currency
        FROM (
            VALUES
                (v_platform_escrow_id, 'DEBIT'::public.ledger_direction_enum, v_entity_amount_gross),
                (v_user_available_id, 'CREDIT'::public.ledger_direction_enum, v_net_amount),
                (v_platform_revenue_id, 'CREDIT'::public.ledger_direction_enum, v_fee_amount)
        ) AS line(account_id, direction, amount)
        WHERE line.amount > 0;
$new_release$;
BEGIN
  SELECT pg_get_functiondef(
    'public.process_payment_event_ledger(text,text,uuid,text,numeric,text,jsonb)'::regprocedure
  )
  INTO v_sql;

  IF position(v_new_release in v_sql) > 0 THEN
    RETURN;
  END IF;

  IF position(v_old_release in v_sql) = 0 THEN
    RAISE EXCEPTION 'process_payment_event_ledger zero-fee release branch did not match expected enum pre-patch body';
  END IF;

  v_sql := replace(v_sql, v_old_release, v_new_release);
  EXECUTE v_sql;
END
$migration$;
