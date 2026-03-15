-- Migration: Hardened Payment Linking — schema and RLS (Phase 1)
-- Plan: PLAN_HardenedPaymentLinking_2026-03-08_PlanCritic
-- Adds: payment_intents (signature, currency, paid_at), orphan_payments (investigated), payment_events RLS (INSERT service_role only).

-- 1) payment_intents: new columns
ALTER TABLE public.payment_intents
  ADD COLUMN IF NOT EXISTS signature TEXT,
  ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'IQD',
  ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;

COMMENT ON COLUMN public.payment_intents.signature IS 'HMAC-SHA256(PAYMENT_HMAC_SECRET, entity_id|gross_amount|currency|payer_id) for webhook verification';
COMMENT ON COLUMN public.payment_intents.currency IS 'Currency code (default IQD)';
COMMENT ON COLUMN public.payment_intents.paid_at IS 'Set when webhook marks intent succeeded';

-- 2) orphan_payments: optional investigated flag for admin queue
ALTER TABLE public.orphan_payments
  ADD COLUMN IF NOT EXISTS investigated BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.orphan_payments.investigated IS 'Admin can mark as investigated in Orphan Queue';

-- 3) payment_events: explicit RLS — only service_role can INSERT; no UPDATE/DELETE policies (append-only)
-- Drop if exists to make migration idempotent (policy may have been created manually)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'payment_events' AND policyname = 'service_role_insert_payment_events'
  ) THEN
    DROP POLICY "service_role_insert_payment_events" ON public.payment_events;
  END IF;
END $$;

CREATE POLICY "service_role_insert_payment_events"
  ON public.payment_events FOR INSERT
  TO service_role
  WITH CHECK (true);

-- anon/authenticated have no INSERT (default deny). No UPDATE/DELETE policies = append-only.
-- Optional: trigger to reject UPDATE/DELETE for defense in depth
CREATE OR REPLACE FUNCTION public.trg_payment_events_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'payment_events is append-only: % not allowed', TG_OP;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_events_append_only ON public.payment_events;
CREATE TRIGGER trg_payment_events_append_only
  BEFORE UPDATE OR DELETE ON public.payment_events
  FOR EACH ROW EXECUTE PROCEDURE public.trg_payment_events_append_only();

-- 4) payment_intents: ensure INSERT/UPDATE only via service_role (edge uses service_role)
-- Existing policy: "Users can view their own payment intents" (SELECT). No INSERT/UPDATE for anon/authenticated = default deny.
-- Explicit allow for service_role:
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_intents' AND policyname = 'service_role_all_payment_intents') THEN
    CREATE POLICY "service_role_all_payment_intents"
      ON public.payment_intents FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;
