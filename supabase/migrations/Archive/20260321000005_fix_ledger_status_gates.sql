-- Fix: Ledger release status gates for task_request and direct_offer
-- Tender task_requests stay in 'accepted' status when task is delivered.
-- Direct offers use 'active' or 'delivered'.

DO $$
DECLARE
  def text;
  original_def text;
  old_code text := '        -- Gate validation: status delivered (or disputed when admin for booking), payment_status held
        IF v_payment_status != ''held'' OR (v_booking_status != ''delivered'' AND NOT (p_related_entity_type = ''booking'' AND v_booking_status = ''disputed'' AND public.is_admin(v_actor_user_id))) THEN
            RETURN jsonb_build_object(
                ''ok'', false,
                ''error'', jsonb_build_object(
                    ''code'', ''ERR_GATE_NOT_ALLOWED'',
                    ''message'', ''Event not allowed for current status. Booking must be delivered and payment held.''
                )
            );
        END IF;';
  new_code text := '        -- Gate validation: status delivered/accepted/active (or disputed when admin for booking), payment_status held
        IF v_payment_status != ''held'' OR (
            v_booking_status NOT IN (''delivered'', ''accepted'', ''active'') 
            AND NOT (p_related_entity_type = ''booking'' AND v_booking_status = ''disputed'' AND public.is_admin(v_actor_user_id))
        ) THEN
            RETURN jsonb_build_object(
                ''ok'', false,
                ''error'', jsonb_build_object(
                    ''code'', ''ERR_GATE_NOT_ALLOWED'',
                    ''message'', ''Event not allowed for current status ('' || v_booking_status || ''). Entity must be delivered/accepted/active and payment held.''
                )
            );
        END IF;';
BEGIN
  SELECT pg_get_functiondef(oid) INTO def FROM pg_proc WHERE proname = 'process_payment_event_ledger';

  IF def IS NULL THEN
    RAISE EXCEPTION 'Function process_payment_event_ledger not found';
  END IF;

  original_def := def;

  -- Use regex replace for robustness against whitespace
  def := regexp_replace(def,
    '-- Gate validation: status delivered \(or disputed when admin for booking\), payment_status held\s+IF v_payment_status != ''held'' OR \(v_booking_status != ''delivered'' AND NOT \(p_related_entity_type = ''booking'' AND v_booking_status = ''disputed'' AND public.is_admin\(v_actor_user_id\)\)\) THEN\s+RETURN jsonb_build_object\(\s+''ok'', false,\s+''error'', jsonb_build_object\(\s+''code'', ''ERR_GATE_NOT_ALLOWED'',\s+''message'', ''Event not allowed for current status. Booking must be delivered and payment held.''\s+\)\s+\);\s+END IF;',
    new_code
  );

  IF def = original_def THEN
    -- Idempotent: if new gate (accepted/active) is already present, migration was applied
    IF def ~ 'v_booking_status NOT IN' AND (def ~ '''accepted''' OR def ~ '''active''') THEN
      RETURN;  -- Already patched; skip
    END IF;
    RAISE EXCEPTION 'Regex pattern did not match - function may have been modified or migration already applied';
  END IF;

  EXECUTE def;
END $$;
