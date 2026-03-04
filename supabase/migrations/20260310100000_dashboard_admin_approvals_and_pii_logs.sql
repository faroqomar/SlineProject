-- Dashboard link parity: PAGE 15 + PAGE 16
-- Additive migration only.

-- ---------------------------------------------------------------------------
-- Admin identity base table (dependency for approvals/PII logs)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  role text NOT NULL CHECK (role IN ('super_admin', 'support', 'moderator')),
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_active_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'admin_users'
      AND policyname = 'admin_users_self_select'
  ) THEN
    CREATE POLICY admin_users_self_select
      ON public.admin_users
      FOR SELECT
      TO authenticated
      USING (id = auth.uid());
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- PAGE 16: admin approvals queue and RPCs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type text NOT NULL,
  target_entity_type text NOT NULL,
  target_entity_id uuid NOT NULL,
  requested_by uuid NOT NULL REFERENCES auth.users(id),
  approved_by uuid REFERENCES auth.users(id),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'consumed')),
  idempotency_key text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  consumed_at timestamptz,
  CONSTRAINT admin_approvals_approver_not_requester CHECK (approved_by IS NULL OR approved_by <> requested_by)
);

CREATE UNIQUE INDEX IF NOT EXISTS admin_approvals_idempotency_key_idx
  ON public.admin_approvals (idempotency_key);
CREATE INDEX IF NOT EXISTS admin_approvals_status_idx
  ON public.admin_approvals (status);
CREATE INDEX IF NOT EXISTS admin_approvals_cursor_idx
  ON public.admin_approvals (status, resolved_at DESC NULLS LAST, id DESC);

ALTER TABLE public.admin_approvals ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'admin_approvals'
      AND policyname = 'admin_approvals_service_role_all'
  ) THEN
    CREATE POLICY admin_approvals_service_role_all
      ON public.admin_approvals
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_request_approval(
  p_operation_type text,
  p_target_entity_type text,
  p_target_entity_id uuid,
  p_requested_by uuid,
  p_idempotency_key text,
  p_payload jsonb DEFAULT '{}'::jsonb,
  p_reason text DEFAULT NULL
) RETURNS public.admin_approvals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.admin_approvals;
  v_inserted boolean := false;
BEGIN
  INSERT INTO public.admin_approvals (
    operation_type,
    target_entity_type,
    target_entity_id,
    requested_by,
    status,
    idempotency_key,
    payload,
    reason
  ) VALUES (
    p_operation_type,
    p_target_entity_type,
    p_target_entity_id,
    p_requested_by,
    'pending',
    p_idempotency_key,
    COALESCE(p_payload, '{}'::jsonb),
    p_reason
  )
  ON CONFLICT (idempotency_key) DO NOTHING
  RETURNING * INTO v_row;

  IF v_row.id IS NOT NULL THEN
    v_inserted := true;
  ELSE
    SELECT * INTO v_row
    FROM public.admin_approvals
    WHERE idempotency_key = p_idempotency_key
    LIMIT 1;
  END IF;

  IF v_inserted THEN
    INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
    VALUES (
      'admin.approval.request',
      p_requested_by,
      'admin_approval',
      v_row.id,
      jsonb_build_object(
        'operation_type', p_operation_type,
        'idempotency_key', p_idempotency_key
      )
    );
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_approve_or_reject_approval(
  p_approval_id uuid,
  p_actor_id uuid,
  p_decision text,
  p_reason text DEFAULT NULL
) RETURNS public.admin_approvals
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.admin_approvals;
  v_action text;
BEGIN
  IF p_decision NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'Decision must be approved or rejected';
  END IF;

  SELECT * INTO v_row
  FROM public.admin_approvals
  WHERE id = p_approval_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval not found';
  END IF;
  IF v_row.requested_by = p_actor_id THEN
    RAISE EXCEPTION 'Approver must be different from requester';
  END IF;
  IF v_row.status <> 'pending' THEN
    RAISE EXCEPTION 'Approval already resolved';
  END IF;

  v_action := CASE WHEN p_decision = 'approved'
    THEN 'admin.approval.approve'
    ELSE 'admin.approval.reject'
  END;

  UPDATE public.admin_approvals
  SET approved_by = p_actor_id,
      status = p_decision,
      resolved_at = now()
  WHERE id = p_approval_id
  RETURNING * INTO v_row;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    v_action,
    p_actor_id,
    'admin_approval',
    p_approval_id,
    jsonb_build_object('reason', p_reason)
  );

  RETURN v_row;
END;
$$;

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
SET search_path = public
AS $$
DECLARE
  v_approval public.admin_approvals;
BEGIN
  SELECT * INTO v_approval
  FROM public.admin_approvals
  WHERE id = p_approval_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval not found';
  END IF;
  IF v_approval.status <> 'approved' THEN
    RAISE EXCEPTION 'Approval is not approved';
  END IF;
  IF v_approval.requested_by <> p_actor_id THEN
    RAISE EXCEPTION 'Only requester can execute this approval';
  END IF;
  IF v_approval.consumed_at IS NOT NULL THEN
    RAISE EXCEPTION 'Approval already consumed';
  END IF;
  IF v_approval.operation_type <> 'wallet_adjust' THEN
    RAISE EXCEPTION 'Approval operation_type is not wallet_adjust';
  END IF;

  UPDATE public.admin_approvals
  SET status = 'consumed',
      consumed_at = now()
  WHERE id = p_approval_id;

  -- NOTE: wallet mutation intentionally deferred to ledger contract RPC.
  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.finance.wallet_adjust',
    p_actor_id,
    'profile',
    p_target_user_id,
    jsonb_build_object(
      'approval_id', p_approval_id,
      'amount_cents', p_amount_cents,
      'reason', p_reason,
      'idempotency_key', p_idempotency_key
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_request_approval(text, text, uuid, uuid, text, jsonb, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_approve_or_reject_approval(uuid, uuid, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_adjust_wallet(uuid, uuid, uuid, bigint, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_request_approval(text, text, uuid, uuid, text, jsonb, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_approve_or_reject_approval(uuid, uuid, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_adjust_wallet(uuid, uuid, uuid, bigint, text, text) TO service_role;

-- ---------------------------------------------------------------------------
-- PAGE 15: admin PII access logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_pii_access_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid NOT NULL REFERENCES public.admin_users(id) ON DELETE RESTRICT,
  target_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  reason text,
  revealed_fields jsonb NOT NULL DEFAULT '[]'::jsonb,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS admin_pii_access_logs_admin_idx
  ON public.admin_pii_access_logs (admin_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS admin_pii_access_logs_target_idx
  ON public.admin_pii_access_logs (target_user_id, created_at DESC);

ALTER TABLE public.admin_pii_access_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'admin_pii_access_logs'
      AND policyname = 'admin_pii_access_logs_service_role_all'
  ) THEN
    CREATE POLICY admin_pii_access_logs_service_role_all
      ON public.admin_pii_access_logs
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
