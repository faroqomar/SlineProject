-- PAGE 16: Dual approval for dangerous ops (wallet adjust, reversal, large refund).
-- Copy into sline_app for canonical ownership. Requires audit_logs and auth.users.

CREATE TABLE IF NOT EXISTS public.admin_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type text NOT NULL,
  target_entity_type text NOT NULL,
  target_entity_id uuid NOT NULL,
  requested_by uuid NOT NULL REFERENCES auth.users(id),
  approved_by uuid REFERENCES auth.users(id),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'consumed')),
  idempotency_key text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}',
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  consumed_at timestamptz,
  CONSTRAINT admin_approvals_approver_not_requester CHECK (approved_by IS NULL OR approved_by != requested_by)
);

CREATE UNIQUE INDEX IF NOT EXISTS admin_approvals_idempotency_key ON public.admin_approvals (idempotency_key);
CREATE INDEX IF NOT EXISTS admin_approvals_status ON public.admin_approvals (status);
CREATE INDEX IF NOT EXISTS admin_approvals_requested_by ON public.admin_approvals (requested_by);
CREATE INDEX IF NOT EXISTS admin_approvals_cursor ON public.admin_approvals (status, resolved_at DESC NULLS LAST, id DESC);

ALTER TABLE public.admin_approvals ENABLE ROW LEVEL SECURITY;

-- RLS: only service_role can read/write (no anon or authenticated direct access).
CREATE POLICY admin_approvals_service_role_all ON public.admin_approvals
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

COMMENT ON TABLE public.admin_approvals IS 'PAGE 16: Approval queue for dangerous finance ops; second approver required.';

-- admin_request_approval: idempotent by idempotency_key; inserts approval + audit only on first insert.
CREATE OR REPLACE FUNCTION public.admin_request_approval(
  p_operation_type text,
  p_target_entity_type text,
  p_target_entity_id uuid,
  p_requested_by uuid,
  p_idempotency_key text,
  p_payload jsonb DEFAULT '{}',
  p_reason text DEFAULT NULL
) RETURNS public.admin_approvals
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_row public.admin_approvals;
  v_inserted boolean := false;
BEGIN
  INSERT INTO public.admin_approvals (
    operation_type, target_entity_type, target_entity_id, requested_by,
    status, idempotency_key, payload, reason
  )
  VALUES (
    p_operation_type, p_target_entity_type, p_target_entity_id, p_requested_by,
    'pending', p_idempotency_key, COALESCE(p_payload, '{}'), p_reason
  )
  ON CONFLICT (idempotency_key) DO NOTHING
  RETURNING * INTO v_row;

  IF v_row.id IS NOT NULL THEN
    v_inserted := true;
  ELSE
    SELECT * INTO v_row FROM public.admin_approvals WHERE idempotency_key = p_idempotency_key LIMIT 1;
  END IF;

  IF v_inserted THEN
    INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
    VALUES (
      'admin.approval.request',
      p_requested_by,
      'admin_approval',
      v_row.id,
      jsonb_build_object('operation_type', p_operation_type, 'idempotency_key', p_idempotency_key)
    );
  END IF;

  RETURN v_row;
END;
$$;

-- admin_approve_or_reject_approval: second person only; updates row and writes audit.
CREATE OR REPLACE FUNCTION public.admin_approve_or_reject_approval(
  p_approval_id uuid,
  p_actor_id uuid,
  p_decision text,
  p_reason text DEFAULT NULL
) RETURNS public.admin_approvals
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_row public.admin_approvals;
  v_action text;
BEGIN
  SELECT * INTO v_row FROM public.admin_approvals WHERE id = p_approval_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval not found';
  END IF;
  IF v_row.requested_by = p_actor_id THEN
    RAISE EXCEPTION 'Approver must be different from requester';
  END IF;
  IF v_row.status != 'pending' THEN
    RAISE EXCEPTION 'Approval already resolved';
  END IF;

  v_action := CASE WHEN p_decision = 'approved' THEN 'admin.approval.approve' ELSE 'admin.approval.reject' END;

  UPDATE public.admin_approvals
  SET approved_by = p_actor_id, status = p_decision, resolved_at = now()
  WHERE id = p_approval_id
  RETURNING * INTO v_row;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (v_action, p_actor_id, 'admin_approval', p_approval_id, jsonb_build_object('reason', p_reason));

  RETURN v_row;
END;
$$;

-- admin_adjust_wallet: executes only if approval exists, is approved, not consumed, and actor is requester. Sets consumed_at and writes audit.
-- Actual wallet/ledger mutation should be added in app repo (e.g. journal entry). This RPC enforces approval gate and audit.
CREATE OR REPLACE FUNCTION public.admin_adjust_wallet(
  p_approval_id uuid,
  p_actor_id uuid,
  p_target_user_id uuid,
  p_amount_cents bigint,
  p_reason text,
  p_idempotency_key text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_approval public.admin_approvals;
BEGIN
  SELECT * INTO v_approval FROM public.admin_approvals WHERE id = p_approval_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval not found';
  END IF;
  IF v_approval.status != 'approved' THEN
    RAISE EXCEPTION 'Approval not approved';
  END IF;
  IF v_approval.requested_by != p_actor_id THEN
    RAISE EXCEPTION 'Only the requester may execute this approval';
  END IF;
  IF v_approval.consumed_at IS NOT NULL THEN
    RAISE EXCEPTION 'Approval already consumed';
  END IF;
  IF v_approval.operation_type != 'wallet_adjust' THEN
    RAISE EXCEPTION 'Approval is not for wallet_adjust';
  END IF;

  UPDATE public.admin_approvals SET consumed_at = now() WHERE id = p_approval_id;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.finance.wallet_adjust',
    p_actor_id,
    'profile',
    p_target_user_id,
    jsonb_build_object('approval_id', p_approval_id, 'amount_cents', p_amount_cents, 'reason', p_reason)
  );

  -- TODO (app repo): perform actual wallet/ledger mutation (e.g. insert journal entry) here or via separate RPC.
END;
$$;
