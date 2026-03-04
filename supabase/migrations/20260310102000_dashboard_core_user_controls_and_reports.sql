-- Dashboard app-link parity:
-- - profiles moderation + force logout
-- - reports queue base tables and RPCs

-- ---------------------------------------------------------------------------
-- Profile moderation and force logout
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS account_status text DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS moderation_reason text,
  ADD COLUMN IF NOT EXISTS moderated_at timestamptz,
  ADD COLUMN IF NOT EXISTS moderated_by_admin_id uuid,
  ADD COLUMN IF NOT EXISTS restriction_scope text,
  ADD COLUMN IF NOT EXISTS force_logout_after timestamptz;

COMMENT ON COLUMN public.profiles.account_status IS 'Canonical moderation: active | suspended | banned';
COMMENT ON COLUMN public.profiles.force_logout_after IS 'When set and newer than session issue time, app must force sign-out.';

CREATE OR REPLACE FUNCTION public.admin_set_user_moderation(
  p_user_id uuid,
  p_admin_id uuid,
  p_status text,
  p_reason text DEFAULT NULL,
  p_scope text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_status NOT IN ('active', 'suspended', 'banned') THEN
    RAISE EXCEPTION 'Invalid moderation status';
  END IF;

  UPDATE public.profiles
  SET account_status = p_status,
      moderation_reason = p_reason,
      moderated_at = now(),
      moderated_by_admin_id = p_admin_id,
      restriction_scope = p_scope
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.users.set_moderation',
    p_admin_id,
    'profile',
    p_user_id,
    jsonb_build_object(
      'status', p_status,
      'reason', p_reason,
      'scope', p_scope
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_force_logout_user(
  p_user_id uuid,
  p_admin_id uuid,
  p_reason text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET force_logout_after = now()
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.users.force_logout',
    p_admin_id,
    'profile',
    p_user_id,
    jsonb_build_object('reason', p_reason)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_user_moderation(uuid, uuid, text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_force_logout_user(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_user_moderation(uuid, uuid, text, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_force_logout_user(uuid, uuid, text) TO service_role;

-- ---------------------------------------------------------------------------
-- Reports queue schema and admin triage RPCs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  entity_type text NOT NULL CHECK (entity_type IN ('task', 'user', 'chat')),
  entity_id uuid NOT NULL,
  reason text,
  category text,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'triaged', 'closed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  meta jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS reports_status_created_at_idx
  ON public.reports (status, created_at DESC);

CREATE TABLE IF NOT EXISTS public.report_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  admin_user_id uuid NOT NULL,
  action text NOT NULL,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS report_actions_report_created_at_idx
  ON public.report_actions (report_id, created_at DESC);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_actions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'reports'
      AND policyname = 'reports_service_role_all'
  ) THEN
    CREATE POLICY reports_service_role_all
      ON public.reports
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'report_actions'
      AND policyname = 'report_actions_service_role_all'
  ) THEN
    CREATE POLICY report_actions_service_role_all
      ON public.report_actions
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Drop if exists so we can change parameter names (Postgres forbids renaming params in CREATE OR REPLACE)
DROP FUNCTION IF EXISTS public.admin_triage_report(uuid, uuid, text, text);
DROP FUNCTION IF EXISTS public.admin_close_report(uuid, uuid, text);

CREATE OR REPLACE FUNCTION public.admin_triage_report(
  p_report_id uuid,
  p_admin_user_id uuid,
  p_action text,
  p_reason text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_action NOT IN ('dismiss', 'warn_user', 'escalate', 'close') THEN
    RAISE EXCEPTION 'Unsupported report triage action';
  END IF;

  UPDATE public.reports
  SET status = CASE WHEN p_action = 'close' THEN 'closed' ELSE 'triaged' END,
      updated_at = now(),
      meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('last_action', p_action)
  WHERE id = p_report_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Report not found';
  END IF;

  INSERT INTO public.report_actions (report_id, admin_user_id, action, reason)
  VALUES (p_report_id, p_admin_user_id, p_action, p_reason);

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.reports.triage',
    p_admin_user_id,
    'report',
    p_report_id,
    jsonb_build_object('action', p_action, 'reason', p_reason)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_close_report(
  p_report_id uuid,
  p_admin_user_id uuid,
  p_reason text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.reports
  SET status = 'closed',
      updated_at = now()
  WHERE id = p_report_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Report not found';
  END IF;

  INSERT INTO public.report_actions (report_id, admin_user_id, action, reason)
  VALUES (p_report_id, p_admin_user_id, 'close', p_reason);

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.reports.close',
    p_admin_user_id,
    'report',
    p_report_id,
    jsonb_build_object('reason', p_reason)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_triage_report(uuid, uuid, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_close_report(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_triage_report(uuid, uuid, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_close_report(uuid, uuid, text) TO service_role;
