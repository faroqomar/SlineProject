-- Fix: task_requests has price, not amount_gross. Patch process_payment_event_ledger.
DO $$
DECLARE
    v_def text;
BEGIN
    SELECT pg_get_functiondef(oid) INTO v_def
    FROM pg_proc
    WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
      AND proname = 'process_payment_event_ledger';

    IF v_def IS NULL THEN
        RAISE EXCEPTION 'process_payment_event_ledger not found';
    END IF;

    v_def := replace(v_def,
        '(COALESCE(tr.amount_gross, tr.price))::numeric AS amount_gross',
        'tr.price::numeric AS amount_gross'
    );

    EXECUTE v_def;
END
$$;
