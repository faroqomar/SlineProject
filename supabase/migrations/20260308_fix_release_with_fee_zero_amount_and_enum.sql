-- Fix approve-and-release for bookings:
-- 1. Skip zero-amount ledger lines (ck_ledger_lines_amount_positive) when fee is 0.
-- 2. Use explicit enum casts on booking/direct_offer UPDATEs to avoid prepared-plan type mismatch (parameter 40).

DO $migration$
DECLARE
  v_sql text;
  v_old_release text := $old_release$
        -- Create ledger lines
        -- DEBIT platform_escrow, CREDIT provider_available, CREDIT platform_revenue
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        VALUES
            (v_journal_entry_id, v_platform_escrow_id, 'DEBIT', v_entity_amount_gross, p_currency),
            (v_journal_entry_id, v_user_available_id, 'CREDIT', v_net_amount, p_currency),
            (v_journal_entry_id, v_platform_revenue_id, 'CREDIT', v_fee_amount, p_currency);

        -- Update entity
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings SET payment_status = 'released', status = 'completed' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests SET payment_status = 'released', status = 'completed' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            UPDATE public.direct_offers SET payment_status = 'released', status = 'completed' WHERE id = p_related_entity_id;
        END IF;
$old_release$;
  v_new_release text := $new_release$
        -- Create ledger lines (only insert lines with amount > 0; ck_ledger_lines_amount_positive)
        -- DEBIT platform_escrow, CREDIT provider_available, CREDIT platform_revenue (fee line skipped when 0)
        INSERT INTO public.ledger_lines (journal_entry_id, account_id, direction, amount, currency)
        SELECT v_journal_entry_id, line.account_id, line.direction, line.amount, p_currency
        FROM (
            VALUES
                (v_platform_escrow_id, 'DEBIT'::public.ledger_direction_enum, v_entity_amount_gross),
                (v_user_available_id, 'CREDIT'::public.ledger_direction_enum, v_net_amount),
                (v_platform_revenue_id, 'CREDIT'::public.ledger_direction_enum, v_fee_amount)
        ) AS line(account_id, direction, amount)
        WHERE line.amount > 0;

        -- Update entity (explicit enum casts to avoid prepared-plan type mismatch)
        IF p_related_entity_type = 'booking' THEN
            UPDATE public.bookings SET payment_status = 'released'::public.payment_status_enum, status = 'completed'::public.booking_status_enum WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'task_request' THEN
            UPDATE public.task_requests SET payment_status = 'released', status = 'completed' WHERE id = p_related_entity_id;
        ELSIF p_related_entity_type = 'direct_offer' THEN
            UPDATE public.direct_offers SET payment_status = 'released'::public.payment_status_enum, status = 'completed' WHERE id = p_related_entity_id;
        END IF;
$new_release$;
BEGIN
  SELECT pg_get_functiondef(
    'public.process_payment_event_ledger(text,text,uuid,text,numeric,text,jsonb)'::regprocedure
  )
  INTO v_sql;

  IF position(v_new_release IN v_sql) > 0 THEN
    RETURN; -- already patched
  END IF;
  IF position(v_old_release IN v_sql) = 0 THEN
    RAISE EXCEPTION 'process_payment_event_ledger release_with_fee block did not match expected pre-patch body';
  END IF;

  v_sql := replace(v_sql, v_old_release, v_new_release);
  EXECUTE v_sql;
END
$migration$;
