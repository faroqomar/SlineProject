-- Copy into sline_app/supabase/migrations/
-- Canonical admin_process_withdrawal for dashboard API (p_request_id, p_decision, p_admin_id, p_reason).
-- Does not write processed_by or admin_notes; uses meta for reason/processed_by.

CREATE OR REPLACE FUNCTION public.admin_process_withdrawal(
  p_request_id uuid,
  p_decision text,
  p_admin_id uuid,
  p_reason text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_withdrawal record;
BEGIN
  IF p_decision NOT IN ('approve', 'reject') THEN
    RAISE EXCEPTION 'Invalid decision. Must be approve or reject';
  END IF;

  SELECT * INTO v_withdrawal
  FROM public.withdrawal_requests
  WHERE id = p_request_id AND status = 'requested'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Withdrawal request not found or already processed';
  END IF;

  UPDATE public.withdrawal_requests
  SET
    status = CASE WHEN p_decision = 'approve' THEN 'completed' ELSE 'failed' END,
    processed_at = now(),
    meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('processed_by', p_admin_id, 'reason', p_reason)
  WHERE id = p_request_id;

  INSERT INTO public.audit_logs (
    action, actor_user_id, related_entity_type, related_entity_id, meta
  ) VALUES (
    'admin.withdrawal_' || p_decision, p_admin_id, 'withdrawal_request', p_request_id,
    jsonb_build_object('reason', p_reason, 'amount', v_withdrawal.amount)
  );
END;
$$;
