-- ============================================================================
-- Direct Chat Offers: table, enum, RLS, guard trigger, work_logs participant
-- ============================================================================

-- 1. Add 'direct_offer' to related_entity_type_enum (for journal_entries / ledger)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        WHERE t.typname = 'related_entity_type_enum' AND e.enumlabel = 'direct_offer'
    ) THEN
        ALTER TYPE public.related_entity_type_enum ADD VALUE 'direct_offer';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 2. Create direct_offers table
CREATE TABLE IF NOT EXISTS public.direct_offers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    client_id uuid NOT NULL REFERENCES public.profiles(id),
    freelancer_id uuid NOT NULL REFERENCES public.profiles(id),
    task_id uuid REFERENCES public.tasks(id) ON DELETE SET NULL,
    title text,
    description text,
    price numeric NOT NULL CHECK (price >= 0),
    days int NOT NULL CHECK (days > 0),
    status text NOT NULL DEFAULT 'sent' CHECK (status IN (
        'sent', 'accepted', 'rejected', 'active', 'delivered', 'completed', 'canceled', 'refunded'
    )),
    payment_status public.payment_status_enum NOT NULL DEFAULT 'unpaid',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_direct_offers_conversation ON public.direct_offers(conversation_id);
CREATE INDEX IF NOT EXISTS idx_direct_offers_client_status ON public.direct_offers(client_id, status);
CREATE INDEX IF NOT EXISTS idx_direct_offers_freelancer_status ON public.direct_offers(freelancer_id, status);

ALTER TABLE public.direct_offers ENABLE ROW LEVEL SECURITY;

-- 3. RLS policies
DROP POLICY IF EXISTS direct_offers_select ON public.direct_offers;
CREATE POLICY direct_offers_select ON public.direct_offers
    FOR SELECT TO authenticated
    USING (client_id = auth.uid() OR freelancer_id = auth.uid());

DROP POLICY IF EXISTS direct_offers_insert ON public.direct_offers;
CREATE POLICY direct_offers_insert ON public.direct_offers
    FOR INSERT TO authenticated
    WITH CHECK (
        freelancer_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = conversation_id
            AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS direct_offers_update ON public.direct_offers;
CREATE POLICY direct_offers_update ON public.direct_offers
    FOR UPDATE TO authenticated
    USING (client_id = auth.uid() OR freelancer_id = auth.uid())
    WITH CHECK (client_id = auth.uid() OR freelancer_id = auth.uid());

DROP POLICY IF EXISTS direct_offers_delete ON public.direct_offers;
CREATE POLICY direct_offers_delete ON public.direct_offers
    FOR DELETE TO authenticated
    USING (false);

-- 4. Guard trigger: valid status/payment transitions
CREATE OR REPLACE FUNCTION public.fn_direct_offer_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only allow status/payment_status changes that respect lifecycle
    IF OLD.status IS DISTINCT FROM NEW.status OR OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
        -- sent -> accepted/active: must have payment_status = held (set by RPC after escrow_hold)
        IF OLD.status = 'sent' AND NEW.status IN ('accepted', 'active') THEN
            IF NEW.payment_status != 'held' THEN
                RAISE EXCEPTION 'direct_offer: status cannot become active without payment_status = held';
            END IF;
            RETURN NEW;
        END IF;
        -- active -> delivered: freelancer only
        IF OLD.status = 'active' AND NEW.status = 'delivered' THEN
            IF auth.uid() != OLD.freelancer_id THEN
                RAISE EXCEPTION 'direct_offer: only freelancer can mark delivered';
            END IF;
            RETURN NEW;
        END IF;
        -- delivered -> completed: must have payment_status = released (set by RPC after release_with_fee)
        IF OLD.status = 'delivered' AND NEW.status = 'completed' THEN
            IF NEW.payment_status != 'released' THEN
                RAISE EXCEPTION 'direct_offer: status cannot become completed without payment_status = released';
            END IF;
            RETURN NEW;
        END IF;
        -- sent -> rejected, canceled; any -> refunded/canceled (when refund)
        IF NEW.status IN ('rejected', 'canceled', 'refunded') THEN
            RETURN NEW;
        END IF;
        -- Disallow any other transition from guard (RPC may set status+payment together)
        IF OLD.status != NEW.status THEN
            RAISE EXCEPTION 'direct_offer: invalid status transition from % to %', OLD.status, NEW.status;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_direct_offer_guard ON public.direct_offers;
CREATE TRIGGER trg_direct_offer_guard
    BEFORE UPDATE ON public.direct_offers
    FOR EACH ROW
    EXECUTE PROCEDURE public.fn_direct_offer_guard();

-- 5. updated_at trigger
CREATE OR REPLACE FUNCTION public.fn_direct_offers_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_direct_offers_updated_at ON public.direct_offers;
CREATE TRIGGER trg_direct_offers_updated_at
    BEFORE UPDATE ON public.direct_offers
    FOR EACH ROW EXECUTE PROCEDURE public.fn_direct_offers_updated_at();

-- 6. is_work_log_participant: add direct_offer branch (match live param names: p_entity_id, p_entity_type, p_user_id)
CREATE OR REPLACE FUNCTION public.is_work_log_participant(p_entity_id uuid, p_entity_type text, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_entity_type = 'task' THEN
        RETURN EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = p_entity_id AND (t.client_id = p_user_id OR t.freelancer_id = p_user_id OR t.assigned_freelancer_id = p_user_id)
        );
    ELSIF p_entity_type = 'booking' THEN
        RETURN EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = p_entity_id AND (b.client_id = p_user_id OR b.provider_id = p_user_id)
        );
    ELSIF p_entity_type = 'direct_offer' THEN
        RETURN EXISTS (
            SELECT 1 FROM public.direct_offers d
            WHERE d.id = p_entity_id AND (d.client_id = p_user_id OR d.freelancer_id = p_user_id)
        );
    END IF;
    RETURN false;
END;
$$;

COMMENT ON TABLE public.direct_offers IS 'Offers created from chat (no task/booking). Lifecycle: sent -> accept+pay(escrow) -> active -> delivered -> complete(release).';
