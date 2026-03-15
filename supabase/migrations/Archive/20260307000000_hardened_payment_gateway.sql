-- Migration: Hardened Payment Gateway & Administrator Views
-- Description: Creates the payment_intents, payment_events, orphan_payments tables and sets up strict RLS rules. Creates admin-level financial aggregation views.

-- 1. Enums
DO $$ BEGIN
    CREATE TYPE payment_intent_status AS ENUM ('created', 'gateway_processing', 'succeeded', 'failed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Tables
CREATE TABLE public.payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL CHECK (entity_type IN ('task', 'booking', 'direct_offer')),
    entity_id UUID NOT NULL,
    payer_id UUID NOT NULL REFERENCES auth.users(id),
    receiver_id UUID NOT NULL REFERENCES auth.users(id),
    gross_amount NUMERIC(12,2) NOT NULL CHECK (gross_amount > 0),
    fee_rate_locked INTEGER NOT NULL CHECK (fee_rate_locked >= 0),
    gateway_intent_id TEXT UNIQUE,
    idempotency_key TEXT UNIQUE NOT NULL,
    status payment_intent_status NOT NULL DEFAULT 'created',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE public.payment_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gateway_event_id TEXT UNIQUE NOT NULL,
    intent_id UUID NOT NULL REFERENCES public.payment_intents(id),
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE public.orphan_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gateway_event_id TEXT,
    error_reason TEXT NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Indexes
CREATE INDEX idx_payment_intents_payer ON public.payment_intents(payer_id);
CREATE INDEX idx_payment_intents_gateway_id ON public.payment_intents(gateway_intent_id);
CREATE INDEX idx_payment_events_intent ON public.payment_events(intent_id);

-- 4. RLS Configuration (Strict Append/Service-Role constraints)
ALTER TABLE public.payment_intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orphan_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own payment intents"
    ON public.payment_intents FOR SELECT
    USING (auth.uid() = payer_id);

-- 5. Admin Finance Aggregation Views
CREATE OR REPLACE VIEW public.vw_admin_finance_metrics AS
SELECT 
    COUNT(l.id) AS total_ledger_lines,
    COALESCE(SUM(l.amount) FILTER (WHERE j.event_type = 'escrow_hold' AND l.direction = 'CREDIT'), 0) AS total_escrow_hold,
    COALESCE(SUM(l.amount) FILTER (WHERE (j.event_type = 'release_with_fee' OR j.event_type = 'refund') AND l.direction = 'DEBIT'), 0) AS total_released,
    COALESCE(SUM(l.amount) FILTER (WHERE j.event_type = 'release_with_fee' AND l.direction = 'CREDIT'), 0) AS total_fees_collected
FROM public.ledger_lines l
JOIN public.journal_entries j ON l.journal_entry_id = j.id;

CREATE OR REPLACE VIEW public.vw_admin_escrow_open AS
SELECT 
    j.related_entity_id,
    j.related_entity_type,
    SUM(CASE WHEN l.direction = 'CREDIT' THEN l.amount ELSE -l.amount END) AS current_escrow_balance
FROM public.ledger_lines l
JOIN public.journal_entries j ON l.journal_entry_id = j.id
WHERE j.event_type IN ('escrow_hold', 'release_with_fee', 'refund')
GROUP BY j.related_entity_id, j.related_entity_type
HAVING SUM(CASE WHEN l.direction = 'CREDIT' THEN l.amount ELSE -l.amount END) > 0;
