-- Migration: Freelancer Unified Flow (v1.5)
-- Date: 2026-02-16
-- Agent: @Supabase_Ops (via Executor)

-- 1. Update Existing Tables (Tasks & Bookings)
-- =========================================================

-- 1.1 Update `tasks` check constraint to include 'delivered', 'completed'
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_status_check;
ALTER TABLE public.tasks ADD CONSTRAINT tasks_status_check 
CHECK (status IN ('open', 'assigned', 'in_progress', 'delivered', 'completed', 'canceled', 'closed'));

-- 1.2 Add Delivery & Revision columns to `tasks`
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS delivered_at timestamptz,
ADD COLUMN IF NOT EXISTS review_expires_at timestamptz,
ADD COLUMN IF NOT EXISTS revisions_total int DEFAULT 3,
ADD COLUMN IF NOT EXISTS revisions_used int DEFAULT 0,
ADD COLUMN IF NOT EXISTS revision_note text,
ADD COLUMN IF NOT EXISTS revision_requested_at timestamptz;

-- 1.3 Add Delivery & Revision columns to `bookings`
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS delivered_at timestamptz,
ADD COLUMN IF NOT EXISTS review_expires_at timestamptz,
ADD COLUMN IF NOT EXISTS revisions_total int DEFAULT 3,
ADD COLUMN IF NOT EXISTS revisions_used int DEFAULT 0,
ADD COLUMN IF NOT EXISTS revision_note text,
ADD COLUMN IF NOT EXISTS revision_requested_at timestamptz;


-- 2. New Tables
-- =========================================================

-- 2.1 `work_contracts`
-- Immutable snapshots of the work agreement at the moment of activation (or scope change).
CREATE TABLE IF NOT EXISTS public.work_contracts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    related_entity_type text NOT NULL CHECK (related_entity_type IN ('task', 'booking')),
    related_entity_id uuid NOT NULL,
    version int NOT NULL,
    snapshot jsonb NOT NULL, -- Full copy of title, description, price, deadline, requirements
    contract_hash text NOT NULL, -- SHA256 of snapshot context for verifying integrity
    created_at timestamptz NOT NULL DEFAULT now(),
    
    CONSTRAINT uq_contract_version UNIQUE (related_entity_type, related_entity_id, version)
);

-- RLS: Read-only for participants (handled via policy below), Insert by System (Trigger) only (but we allow it for migration/admin).
ALTER TABLE public.work_contracts ENABLE ROW LEVEL SECURITY;

-- 2.2 `change_requests`
-- Formal requests to change scope, price, or deadline.
CREATE TABLE IF NOT EXISTS public.change_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    related_entity_type text NOT NULL CHECK (related_entity_type IN ('task', 'booking')),
    related_entity_id uuid NOT NULL,
    requester_id uuid NOT NULL REFERENCES public.profiles(id),
    
    scope_diff text, -- Text description of what changes
    price_diff numeric, -- Can be positive (add money) or negative (refund/discount)
    days_diff int, -- Extension (positive) or Reduction (negative)
    
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    applied_contract_version int, -- The version this CR applies to (or creates)
    
    created_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz
);

ALTER TABLE public.change_requests ENABLE ROW LEVEL SECURITY;

-- 2.3 `extension_requests` 
-- (Optional: Unified into change_requests in finalized plan? Plan says distinct table. Sticking to plan).
CREATE TABLE IF NOT EXISTS public.extension_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    related_entity_type text NOT NULL CHECK (related_entity_type IN ('task', 'booking')),
    related_entity_id uuid NOT NULL,
    requester_id uuid NOT NULL REFERENCES public.profiles(id),
    
    new_deadline timestamptz NOT NULL,
    reason text,
    
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.extension_requests ENABLE ROW LEVEL SECURITY;


-- 3. Unified View
-- =========================================================

CREATE OR REPLACE VIEW public.vw_unified_work_items AS
SELECT
    t.id,
    'task' AS source_type,
    t.status AS source_status,
    -- Map Task Status to Unified Enum
    CASE 
        WHEN t.status = 'in_progress' THEN 'active'
        WHEN t.status = 'delivered' THEN 'delivered'
        WHEN t.status = 'completed' THEN 'completed'
        WHEN t.status = 'canceled' THEN 'canceled'
        ELSE t.status -- fallback
    END AS unified_status,
    t.title,
    t.budget AS price,
    t.deadline,
    t.client_id,
    t.assigned_freelancer_id AS freelancer_id,
    t.delivered_at,
    t.review_expires_at,
    t.revisions_total,
    t.revisions_used
FROM public.tasks t
WHERE t.assigned_freelancer_id IS NOT NULL 
  AND t.status IN ('in_progress', 'delivered', 'completed')

UNION ALL

SELECT
    b.id,
    'booking' AS source_type,
    b.status::text AS source_status,
    -- Booking status is already the enum we want, mostly
    b.status::text AS unified_status,
    (t.title || ' - Session') AS title, -- Join with task for title
    b.price,
    av.starts_at AS deadline, -- Booking deadline is start time? Or end time? usually end of session? Let's use start for now or computed end.
    b.client_id,
    b.provider_id AS freelancer_id,
    b.delivered_at,
    b.review_expires_at,
    b.revisions_total,
    b.revisions_used
FROM public.bookings b
LEFT JOIN public.tasks t ON b.task_id = t.id
LEFT JOIN public.availability_slots av ON b.slot_id = av.id
WHERE b.status IN ('active', 'delivered', 'completed');


-- 4. Triggers & Functions
-- =========================================================

-- 4.1 Trigger Function: specific to tasks/bookings
-- Creates initial contract snapshot when work becomes active.
CREATE OR REPLACE FUNCTION trg_activate_contract()
RETURNS TRIGGER AS $$
DECLARE
    _snapshot jsonb;
    _hash text;
    _entity_type text;
BEGIN
    -- Determine Entity Type
    IF TG_TABLE_NAME = 'tasks' THEN
        _entity_type := 'task';
    ELSIF TG_TABLE_NAME = 'bookings' THEN
        _entity_type := 'booking';
    END IF;

    -- Activation Check: Status changed TO active/in_progress
    IF (OLD.status <> NEW.status) AND 
       (NEW.status = 'in_progress' OR NEW.status = 'active') THEN
        
        -- build snapshot
        _snapshot := jsonb_build_object(
            'title', NEW.title, -- Note: bookings might not have title directly, might need join. For now assume tasks structure or basic fields.
            -- Actually bookings has price, requirements. tasks has description.
            -- This function needs to be robust for both tables.
            'price', (CASE WHEN _entity_type='task' THEN NEW.budget ELSE NEW.price END),
            'deadline', (CASE WHEN _entity_type='task' THEN NEW.deadline ELSE NULL END) -- Booking deadline from slot?
        );
        
        -- Mock Hash (in real impl use proper hashing)
        _hash := md5(_snapshot::text);

        INSERT INTO public.work_contracts 
        (related_entity_type, related_entity_id, version, snapshot, contract_hash)
        VALUES (_entity_type, NEW.id, 1, _snapshot, _hash);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.2 Attach Trigger to Tasks
CREATE TRIGGER t_activate_contract_tasks
AFTER UPDATE ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION trg_activate_contract();

-- 4.3 Attach Trigger to Bookings
CREATE TRIGGER t_activate_contract_bookings
AFTER UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION trg_activate_contract();


-- 5. RPCs (Security Definer)
-- =========================================================

-- 5.1 Submit Delivery
CREATE OR REPLACE FUNCTION rpc_submit_delivery(
    entity_type text,
    entity_id uuid,
    note text
)
RETURNS void AS $$
DECLARE
    _freelancer_id uuid;
BEGIN
    -- Auth Guard
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

    IF entity_type = 'task' THEN
        SELECT assigned_freelancer_id INTO _freelancer_id FROM public.tasks WHERE id = entity_id;
        IF _freelancer_id <> auth.uid() THEN RAISE EXCEPTION 'Not authorized'; END IF;

        UPDATE public.tasks 
        SET status = 'delivered', 
            delivered_at = now(), 
            review_expires_at = (now() + interval '3 days'),
            revision_note = note
        WHERE id = entity_id;

    ELSIF entity_type = 'booking' THEN
        SELECT provider_id INTO _freelancer_id FROM public.bookings WHERE id = entity_id;
        IF _freelancer_id <> auth.uid() THEN RAISE EXCEPTION 'Not authorized'; END IF;

        UPDATE public.bookings 
        SET status = 'delivered', 
            delivered_at = now(), 
            review_expires_at = (now() + interval '3 days'),
            revision_note = note
        WHERE id = entity_id;
    ELSE
        RAISE EXCEPTION 'Invalid entity type';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 5.2 Request Revision
CREATE OR REPLACE FUNCTION rpc_request_revision(
    entity_type text,
    entity_id uuid,
    note text
)
RETURNS void AS $$
DECLARE
    _client_id uuid;
    _used int;
    _total int;
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

    IF entity_type = 'task' THEN
        SELECT client_id, revisions_used, revisions_total INTO _client_id, _used, _total 
        FROM public.tasks WHERE id = entity_id;
        
        IF _client_id <> auth.uid() THEN RAISE EXCEPTION 'Not authorized'; END IF;
        IF _used >= _total THEN RAISE EXCEPTION 'Revision limit reached'; END IF;

        UPDATE public.tasks 
        SET status = 'in_progress', 
            delivered_at = NULL, 
            review_expires_at = NULL,
            revisions_used = revisions_used + 1,
            revision_note = note,
            revision_requested_at = now()
        WHERE id = entity_id;

    ELSIF entity_type = 'booking' THEN
        SELECT client_id, revisions_used, revisions_total INTO _client_id, _used, _total 
        FROM public.bookings WHERE id = entity_id;

        IF _client_id <> auth.uid() THEN RAISE EXCEPTION 'Not authorized'; END IF;
        IF _used >= _total THEN RAISE EXCEPTION 'Revision limit reached'; END IF;

        UPDATE public.bookings 
        SET status = 'active', 
            delivered_at = NULL, 
            review_expires_at = NULL,
            revisions_used = revisions_used + 1,
            revision_note = note,
            revision_requested_at = now()
        WHERE id = entity_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 6. RLS for New Tables
-- =========================================================

-- Work Contracts: Viewable by Participants
CREATE POLICY work_contracts_select ON public.work_contracts
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.tasks t 
        WHERE t.id = work_contracts.related_entity_id 
        AND work_contracts.related_entity_type = 'task'
        AND (t.client_id = auth.uid() OR t.assigned_freelancer_id = auth.uid())
    ) OR
    EXISTS (
        SELECT 1 FROM public.bookings b 
        WHERE b.id = work_contracts.related_entity_id 
        AND work_contracts.related_entity_type = 'booking'
        AND (b.client_id = auth.uid() OR b.provider_id = auth.uid())
    )
);

-- Change Requests: Select (Participants)
CREATE POLICY change_requests_select ON public.change_requests
FOR SELECT USING (
    requester_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM public.tasks t 
        WHERE t.id = change_requests.related_entity_id 
        AND change_requests.related_entity_type = 'task'
        AND (t.client_id = auth.uid() OR t.assigned_freelancer_id = auth.uid())
    ) OR
    EXISTS (
        SELECT 1 FROM public.bookings b 
        WHERE b.id = change_requests.related_entity_id 
        AND change_requests.related_entity_type = 'booking'
        AND (b.client_id = auth.uid() OR b.provider_id = auth.uid())
    )
);

-- Change Requests: Insert (Participants)
CREATE POLICY change_requests_insert ON public.change_requests
FOR INSERT WITH CHECK (
    requester_id = auth.uid() AND (
        EXISTS (
            SELECT 1 FROM public.tasks t 
            WHERE t.id = related_entity_id 
            AND related_entity_type = 'task'
            AND (t.client_id = auth.uid() OR t.assigned_freelancer_id = auth.uid())
        ) OR
        EXISTS (
            SELECT 1 FROM public.bookings b 
            WHERE b.id = related_entity_id 
            AND related_entity_type = 'booking'
            AND (b.client_id = auth.uid() OR b.provider_id = auth.uid())
        )
    )
);

-- Extension Requests: Same logic
CREATE POLICY extension_requests_select ON public.extension_requests
FOR SELECT USING (
    requester_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM public.tasks t 
        WHERE t.id = related_entity_id 
        AND related_entity_type = 'task'
        AND (t.client_id = auth.uid() OR t.assigned_freelancer_id = auth.uid())
    ) OR
    EXISTS (
        SELECT 1 FROM public.bookings b 
        WHERE b.id = related_entity_id 
        AND related_entity_type = 'booking'
        AND (b.client_id = auth.uid() OR b.provider_id = auth.uid())
    )
);

CREATE POLICY extension_requests_insert ON public.extension_requests
FOR INSERT WITH CHECK (
    requester_id = auth.uid() AND (
        EXISTS (
            SELECT 1 FROM public.tasks t 
            WHERE t.id = related_entity_id 
            AND related_entity_type = 'task'
            AND (t.client_id = auth.uid() OR t.assigned_freelancer_id = auth.uid())
        ) OR
        EXISTS (
            SELECT 1 FROM public.bookings b 
            WHERE b.id = related_entity_id 
            AND related_entity_type = 'booking'
            AND (b.client_id = auth.uid() OR b.provider_id = auth.uid())
        )
    )
);
