-- Notification Routing: push queue + trigger (no pg_net — cron/Edge will drain queue).
-- Plan: .TODO/PLAN_NotificationRouting_2026-03-08_PlanCritic.md
-- Contract: CONTRACT_notification_push.md

BEGIN;

-- Queue table: one row per notification to push (drained by Edge Function process-push-queue)
CREATE TABLE IF NOT EXISTS public.notification_push_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL,
  related_entity_id uuid,
  related_entity_type text,
  created_at timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed'))
);

CREATE INDEX IF NOT EXISTS ix_notification_push_queue_pending
  ON public.notification_push_queue(created_at)
  WHERE status = 'pending';

-- Trigger: enqueue on notification insert (async — just INSERT, no HTTP)
CREATE OR REPLACE FUNCTION public.notifications_after_insert_push_queue()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.notification_push_queue (
    notification_id,
    user_id,
    title,
    message,
    type,
    related_entity_id,
    related_entity_type
  ) VALUES (
    NEW.id,
    NEW.user_id,
    NEW.title,
    NEW.message,
    NEW.type,
    NEW.related_entity_id,
    NEW.related_entity_type
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notifications_after_insert_push_queue ON public.notifications;
CREATE TRIGGER trg_notifications_after_insert_push_queue
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.notifications_after_insert_push_queue();

COMMIT;
