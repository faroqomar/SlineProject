-- Clear booking review deadlines after approve-delivery succeeds on the
-- held-payment ledger path, and backfill existing completed/released rows.

DO $migration$
DECLARE
  v_sql text;
  v_old_block text := $old_block$
      if (v_result->>'ok')::boolean IS DISTINCT FROM true then
        raise exception 'Ledger release failed: %', v_result->'error'->>'message';
      end if;
$old_block$;
  v_new_block text := $new_block$
      if (v_result->>'ok')::boolean IS DISTINCT FROM true then
        raise exception 'Ledger release failed: %', v_result->'error'->>'message';
      end if;

      update bookings
      set review_expires_at = null
      where id = entity_id;
$new_block$;
BEGIN
  SELECT pg_get_functiondef('public.rpc_approve_delivery(text,uuid)'::regprocedure)
  INTO v_sql;

  IF position(v_new_block in v_sql) = 0 THEN
    IF position(v_old_block in v_sql) = 0 THEN
      RAISE EXCEPTION 'rpc_approve_delivery held-payment branch did not match expected pre-patch body';
    END IF;
    v_sql := replace(v_sql, v_old_block, v_new_block);
    EXECUTE v_sql;
  END IF;

  UPDATE public.bookings
  SET review_expires_at = null
  WHERE status = 'completed'
    AND payment_status = 'released'
    AND review_expires_at IS NOT NULL;
END
$migration$;
