-- Ensure get_public_system_config RPC exists for app shell (maintenance, banner, signups, min version).
-- The app calls this at startup; without it you get "Failed to fetch" and fallback to defaults.
-- Table system_config may already exist from other migrations; we only ensure the public read RPC.

CREATE TABLE IF NOT EXISTS public.system_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  description text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'system_config' AND policyname = 'system_config_select_public_keys'
  ) THEN
    -- Allow anon/authenticated to read only via the SECURITY DEFINER RPC, not direct table read
    -- So we don't add a SELECT policy here; get_public_system_config does the read.
    NULL;
  END IF;
END $$;

INSERT INTO public.system_config (key, value, description)
VALUES
  ('maintenance_mode', '{"enabled": false, "message": ""}', 'If true, app shows maintenance screen'),
  ('app_banner', '{"enabled": false, "text": "", "type": "info"}', 'Global announcement banner'),
  ('disable_signups', '{"enabled": false}', 'When true, registration is disabled'),
  ('min_app_version', '{"ios": "1.0.0", "android": "1.0.0"}', 'Minimum app version per platform')
ON CONFLICT (key) DO NOTHING;

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
