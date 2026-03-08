-- Booking Lifecycle (Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic)
-- Patch process_payment_event_ledger: allow admin to release_with_fee or refund when booking status = disputed.
-- release_with_fee: allow status disputed when is_admin(actor); allow actor = admin.
-- refund: allow status disputed when is_admin(actor); allow actor = admin.

DO $$
DECLARE
  def text;
  new_def text;
BEGIN
  SELECT pg_get_functiondef(oid) INTO def FROM pg_proc WHERE proname = 'process_payment_event_ledger';
  IF def IS NULL THEN
    RAISE EXCEPTION 'process_payment_event_ledger not found';
  END IF;

  -- 1. release_with_fee: gate – allow disputed when booking and admin
  new_def := replace(def,
    E'        -- Gate validation: status must be delivered, payment_status must be held\n        IF v_booking_status != ''delivered'' OR v_payment_status != ''held'' THEN',
    E'        -- Gate validation: status delivered (or disputed when admin for booking), payment_status held\n        IF v_payment_status != ''held'' OR (v_booking_status != ''delivered'' AND NOT (p_related_entity_type = ''booking'' AND v_booking_status = ''disputed'' AND public.is_admin(v_actor_user_id))) THEN');

  -- 2. release_with_fee: actor – allow admin
  new_def := replace(new_def,
    E'        -- Actor validation: must be client\n        IF v_actor_user_id IS NULL OR v_actor_user_id != v_client_id THEN\n            RETURN jsonb_build_object(\n                ''ok'', false,\n                ''error'', jsonb_build_object(\n                    ''code'', ''ERR_GATE_NOT_ALLOWED'',\n                    ''message'', ''Only the client can release funds.''',
    E'        -- Actor validation: client or admin\n        IF v_actor_user_id IS NULL OR (v_actor_user_id != v_client_id AND NOT public.is_admin(v_actor_user_id)) THEN\n            RETURN jsonb_build_object(\n                ''ok'', false,\n                ''error'', jsonb_build_object(\n                    ''code'', ''ERR_GATE_NOT_ALLOWED'',\n                    ''message'', ''Only the client or admin can release funds.''');

  -- 3. refund: gate – allow disputed when admin (booking/task_request)
  new_def := replace(new_def,
    E'        -- Gate validation: status must allow refund (booking/tr: declined/canceled/expired; direct_offer: client or freelancer may refund when held)\n        IF p_related_entity_type IN (''booking'', ''task_request'') AND v_booking_status NOT IN (''declined'', ''canceled'', ''expired_unanswered'', ''dispute_refund'') THEN\n            IF v_actor_user_id IS NOT NULL THEN',
    E'        -- Gate validation: status must allow refund (booking/tr: declined/canceled/expired/dispute_refund, or disputed when admin)\n        IF p_related_entity_type IN (''booking'', ''task_request'') AND v_booking_status NOT IN (''declined'', ''canceled'', ''expired_unanswered'', ''dispute_refund'') AND NOT (v_booking_status = ''disputed'' AND public.is_admin(v_actor_user_id)) THEN\n            IF v_actor_user_id IS NOT NULL THEN');

  -- 4. refund: actor – allow admin
  new_def := replace(new_def,
    E'        -- Actor validation: provider, client, or system (for direct_offer both client and freelancer may refund)\n        IF v_actor_user_id IS NOT NULL AND \n           v_actor_user_id != v_provider_id AND \n           v_actor_user_id != v_client_id THEN',
    E'        -- Actor validation: provider, client, or admin (for direct_offer both client and freelancer may refund)\n        IF v_actor_user_id IS NOT NULL AND \n           v_actor_user_id != v_provider_id AND \n           v_actor_user_id != v_client_id AND \n           NOT public.is_admin(v_actor_user_id) THEN');

  EXECUTE new_def;
END $$;
