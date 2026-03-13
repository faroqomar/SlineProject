-- Fix: "column provider_id does not exist" and "column amount_gross does not exist" for task_request 
-- Ensure process_payment_event_ledger queries freelancer_id AS provider_id and price AS amount_gross.

DO $$
DECLARE
  def text;
  new_def text;
  old_sql text := 'SELECT id, client_id, provider_id, status, payment_status, amount_gross
            INTO v_entity
            FROM public.task_requests
            WHERE id = p_related_entity_id
            FOR UPDATE;';
  new_sql text := 'SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.task_requests
            WHERE id = p_related_entity_id
            FOR UPDATE;';
  
  old_sql_fallback text := 'SELECT id, client_id, provider_id, status, payment_status, amount_gross\n            INTO v_entity\n            FROM public.task_requests\n            WHERE id = p_related_entity_id\n            FOR UPDATE;';
  new_sql_fallback text := 'SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross\n            INTO v_entity\n            FROM public.task_requests\n            WHERE id = p_related_entity_id\n            FOR UPDATE;';
BEGIN
  SELECT pg_get_functiondef(oid) INTO def FROM pg_proc WHERE proname = 'process_payment_event_ledger';
  IF def IS NULL THEN
    RAISE EXCEPTION 'process_payment_event_ledger not found';
  END IF;

  -- The formatting might have varying whitespace, so let's use a simpler REGEXP_REPLACE approach,
  -- or we just replace the whole function definition if substitution fails.

  -- Let's try replacing the specific SELECT line if it matches exactly:
  new_def := replace(def, 
        'SELECT id, client_id, provider_id, status, payment_status, amount_gross
            INTO v_entity
            FROM public.task_requests',
        'SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross
            INTO v_entity
            FROM public.task_requests'
  );

  IF new_def = def THEN
      -- Try with different newline representation (E'' so \n is real newline)
      new_def := replace(def,
        E'SELECT id, client_id, provider_id, status, payment_status, amount_gross\n            INTO v_entity\n            FROM public.task_requests',
        E'SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross\n            INTO v_entity\n            FROM public.task_requests'
      );
  END IF;

  IF new_def = def THEN
    -- Idempotent: if task_requests block already uses freelancer_id and price AS amount_gross, skip
    IF position('freelancer_id AS provider_id' in def) > 0 AND position('price AS amount_gross' in def) > 0 AND position('task_requests' in def) > 0 THEN
      RETURN;
    END IF;
    RAISE EXCEPTION 'process_payment_event_ledger: task_requests SELECT block not found. Cannot patch automatically.';
  END IF;

  EXECUTE new_def;
END $$;
