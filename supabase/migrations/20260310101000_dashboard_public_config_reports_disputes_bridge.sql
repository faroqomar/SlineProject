-- Dashboard app-link bridge:
-- - public-safe system_config read
-- - report write/read by reporter
-- - dispute write/read by participants
-- - admin_update_system_config RPC parity

-- ---------------------------------------------------------------------------
-- system_config admin update RPC (dashboard parity)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.system_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  description text,
  updated_by uuid REFERENCES public.admin_users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'system_config'
      AND policyname = 'admins_manage_system_config'
  ) THEN
    CREATE POLICY admins_manage_system_config
      ON public.system_config
      FOR ALL
      TO authenticated
      USING (EXISTS (SELECT 1 FROM public.admin_users au WHERE au.id = auth.uid()))
      WITH CHECK (EXISTS (SELECT 1 FROM public.admin_users au WHERE au.id = auth.uid()));
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.admin_update_system_config(
  p_key text,
  p_value jsonb,
  p_actor_user_id uuid
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated int;
BEGIN
  UPDATE public.system_config
  SET value = COALESCE(p_value, '{}'::jsonb),
      updated_by = p_actor_user_id,
      updated_at = now()
  WHERE key = p_key;

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    INSERT INTO public.system_config (key, value, updated_by, updated_at)
    VALUES (p_key, COALESCE(p_value, '{}'::jsonb), p_actor_user_id, now());
  END IF;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.system.update_config',
    p_actor_user_id,
    'system_config',
    NULL,
    jsonb_build_object('key', p_key, 'value', p_value)
  );

  RETURN p_key;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_update_system_config(text, jsonb, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_update_system_config(text, jsonb, uuid) TO service_role;

INSERT INTO public.system_config (key, value, description)
VALUES
  ('maintenance_mode', '{"enabled": false, "message": ""}', 'If true, app shows maintenance screen'),
  ('app_banner', '{"enabled": false, "text": "", "type": "info"}', 'Global announcement banner'),
  ('disable_signups', '{"enabled": false}', 'When true, registration is disabled'),
  ('min_app_version', '{"ios": "1.0.0", "android": "1.0.0"}', 'Minimum app version per platform')
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Public-safe config read path for app shell/auth
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_public_system_config()
RETURNS TABLE(key text, value jsonb)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT sc.key, sc.value
  FROM public.system_config sc
  WHERE sc.key IN ('maintenance_mode', 'app_banner', 'disable_signups', 'min_app_version')
  ORDER BY sc.key;
$$;

REVOKE ALL ON FUNCTION public.get_public_system_config() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_system_config() TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- reports RLS bridge for app-side reporting
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'reports'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'reports'
        AND policyname = 'reports_insert_own'
    ) THEN
      CREATE POLICY reports_insert_own
        ON public.reports
        FOR INSERT
        TO authenticated
        WITH CHECK (reporter_user_id = auth.uid());
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'reports'
        AND policyname = 'reports_select_own'
    ) THEN
      CREATE POLICY reports_select_own
        ON public.reports
        FOR SELECT
        TO authenticated
        USING (reporter_user_id = auth.uid());
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'reports'
  ) THEN
    CREATE INDEX IF NOT EXISTS reports_reporter_created_at_idx
      ON public.reports (reporter_user_id, created_at DESC);
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- disputes RLS bridge for app-side dispute filing and visibility
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'disputes'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'disputes'
        AND policyname = 'disputes_insert_own'
    ) THEN
      CREATE POLICY disputes_insert_own
        ON public.disputes
        FOR INSERT
        TO authenticated
        WITH CHECK (complainant_id = auth.uid());
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'disputes'
        AND policyname = 'disputes_select_party'
    ) THEN
      CREATE POLICY disputes_select_party
        ON public.disputes
        FOR SELECT
        TO authenticated
        USING (complainant_id = auth.uid() OR defendant_id = auth.uid());
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'disputes'
  ) THEN
    CREATE INDEX IF NOT EXISTS disputes_complainant_created_at_idx
      ON public.disputes (complainant_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS disputes_defendant_created_at_idx
      ON public.disputes (defendant_id, created_at DESC);
  END IF;
END $$;
