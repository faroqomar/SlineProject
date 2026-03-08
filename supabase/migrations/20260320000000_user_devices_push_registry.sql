-- Notification Routing (13_notification-routing): user_devices table for FCM/APNs token registry.
-- Plan: .TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md
-- Contract: .TODO/improvement_the_system/ImplementReady/13_notification-routing/CONTRACT_notification_push.md

BEGIN;

-- Table: one row per (user_id, platform); token refresh via upsert
CREATE TABLE IF NOT EXISTS public.user_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ux_user_devices_user_platform UNIQUE (user_id, platform)
);

CREATE INDEX IF NOT EXISTS ix_user_devices_user_id ON public.user_devices(user_id);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- RLS: users can only manage their own device rows (idempotent)
DROP POLICY IF EXISTS user_devices_select_own ON public.user_devices;
CREATE POLICY user_devices_select_own ON public.user_devices
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_devices_insert_own ON public.user_devices;
CREATE POLICY user_devices_insert_own ON public.user_devices
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_devices_update_own ON public.user_devices;
CREATE POLICY user_devices_update_own ON public.user_devices
  FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_devices_delete_own ON public.user_devices;
CREATE POLICY user_devices_delete_own ON public.user_devices
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- updated_at refresh on update
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_devices_updated_at ON public.user_devices;
CREATE TRIGGER trg_user_devices_updated_at
  BEFORE UPDATE ON public.user_devices
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

COMMIT;
