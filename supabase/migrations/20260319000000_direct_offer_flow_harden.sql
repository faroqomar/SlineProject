-- Direct Chat Offer Flow hardening (PLAN_DirectChatOfferFlow_2026-03-07_CRITIC).
-- Additive only: currency, payment traceability, delivered_at, review_expires_at on direct_offers;
-- direct_offer_id on disputes; optional partial index.
-- fee_rate_applied_bps already exists on direct_offers (live DB).

-- 1) direct_offers: add missing columns (skip if already present to avoid drift)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'currency') THEN
    ALTER TABLE public.direct_offers ADD COLUMN currency text NOT NULL DEFAULT 'IQD';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'payment_request_id') THEN
    ALTER TABLE public.direct_offers ADD COLUMN payment_request_id text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'payment_gateway_id') THEN
    ALTER TABLE public.direct_offers ADD COLUMN payment_gateway_id text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'payment_correlation_id') THEN
    ALTER TABLE public.direct_offers ADD COLUMN payment_correlation_id text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'payment_expires_at') THEN
    ALTER TABLE public.direct_offers ADD COLUMN payment_expires_at timestamptz;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'payment_recovered_at') THEN
    ALTER TABLE public.direct_offers ADD COLUMN payment_recovered_at timestamptz;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'delivered_at') THEN
    ALTER TABLE public.direct_offers ADD COLUMN delivered_at timestamptz;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'direct_offers' AND column_name = 'review_expires_at') THEN
    ALTER TABLE public.direct_offers ADD COLUMN review_expires_at timestamptz;
  END IF;
END $$;

-- 2) Partial index for processing checkouts (optional)
CREATE INDEX IF NOT EXISTS idx_direct_offers_processing
ON public.direct_offers(status)
WHERE status = 'accepted' AND payment_status = 'unpaid' AND payment_request_id IS NOT NULL;

-- 3) disputes: allow direct_offer_id; ensure exactly one of task_id or direct_offer_id
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'disputes' AND column_name = 'direct_offer_id') THEN
    ALTER TABLE public.disputes ADD COLUMN direct_offer_id uuid REFERENCES public.direct_offers(id);
  END IF;
END $$;

-- Make task_id nullable so dispute can be for direct_offer only (if currently NOT NULL)
ALTER TABLE public.disputes ALTER COLUMN task_id DROP NOT NULL;

-- Constraint: exactly one of task_id or direct_offer_id must be set
ALTER TABLE public.disputes DROP CONSTRAINT IF EXISTS chk_dispute_entity;
ALTER TABLE public.disputes ADD CONSTRAINT chk_dispute_entity CHECK (
  (task_id IS NOT NULL AND direct_offer_id IS NULL) OR (task_id IS NULL AND direct_offer_id IS NOT NULL)
);

COMMENT ON COLUMN public.direct_offers.currency IS 'Locked at offer creation; default IQD.';
COMMENT ON COLUMN public.direct_offers.delivered_at IS 'Set when freelancer marks delivered; used with review_expires_at for auto-release.';
COMMENT ON COLUMN public.direct_offers.review_expires_at IS 'Auto-approval deadline (e.g. delivered_at + 3 days). Cron releases when now() > review_expires_at.';
