-- PAGE 13: System config + feature flags (copy into sline_app for canonical ownership).
-- Requires audit_logs and related_entity_type_enum (extend enum with 'system_config' below).
-- Dashboard API is sole reader/writer via service role; RLS blocks anon/authenticated.

-- Extend audit entity type for system_config audit rows (if enum exists).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'related_entity_type_enum') THEN
    ALTER TYPE related_entity_type_enum ADD VALUE IF NOT EXISTS 'system_config';
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- Key-value store for global settings (maintenance_mode, app_banner, disable_signups, min_app_version, etc.).
CREATE TABLE IF NOT EXISTS public.system_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}',
  description text,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.system_config IS 'Admin-managed global settings and feature flags; API uses service role only.';

ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

-- No policy for anon or authenticated: only service role (bypass RLS) can read/write.
-- When app needs to read e.g. maintenance_mode for clients, add a SELECT policy later.

-- RPC: atomic update + one audit_logs row in same transaction.
CREATE OR REPLACE FUNCTION public.admin_update_system_config(
  p_key text,
  p_value jsonb,
  p_actor_user_id uuid
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated int;
BEGIN
  UPDATE public.system_config
  SET value = p_value, updated_by = p_actor_user_id, updated_at = now()
  WHERE key = p_key;

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    INSERT INTO public.system_config (key, value, updated_by, updated_at)
    VALUES (p_key, p_value, p_actor_user_id, now());
  END IF;

  INSERT INTO public.audit_logs (action, actor_user_id, related_entity_type, related_entity_id, meta)
  VALUES (
    'admin.system.update_config',
    p_actor_user_id,
    'system_config',
    p_key,
    jsonb_build_object('key', p_key, 'value', p_value)
  );

  RETURN p_key;
END;
$$;

-- Seed default keys so GET returns rows and UI has data to display.
INSERT INTO public.system_config (key, value, description)
VALUES
  ('maintenance_mode', '{"enabled": false, "message": ""}', 'If true, app shows maintenance screen'),
  ('app_banner', '{"enabled": false, "text": "", "type": "info"}', 'Global announcement banner'),
  ('disable_signups', '{"enabled": false}', 'When true, registration is disabled'),
  ('min_app_version', '{"ios": "1.0.0", "android": "1.0.0"}', 'Minimum app version per platform')
ON CONFLICT (key) DO NOTHING;
