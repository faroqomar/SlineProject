-- Migration: Fix trg_activate_contract title access
-- Date: 2026-02-16
-- Agent: @Antigravity

CREATE OR REPLACE FUNCTION trg_activate_contract()
RETURNS TRIGGER AS $$
DECLARE
    _snapshot jsonb;
    _hash text;
    _entity_type text;
    _title text;
    _deadline timestamptz;
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
        
        -- Fetch Title & Details based on type
        IF _entity_type = 'task' THEN
            _title := NEW.title;
            _deadline := NEW.deadline;
        ELSIF _entity_type = 'booking' THEN
            -- Fetch title from associated task
            SELECT title INTO _title FROM public.tasks WHERE id = NEW.task_id;
            -- For booking, deadline might be start time or calculated end time. 
            -- We'll use scheduled_at if available, or fetch from slot.
            -- Assuming 'scheduled_at' is not on booking based on model, but 'slot_id' is.
            -- Let's check if 'bookings' has 'scheduled_at' or if we need to join 'availability_slots'.
            -- Model has 'scheduledAt', DB schema typically has 'slot_id'.
            -- Let's try to get it from slot, or default to null if complex.
            -- Previous function used: (CASE WHEN _entity_type='task' THEN NEW.deadline ELSE NULL END)
            _deadline := NULL; 
        END IF;

        -- Fallback if title not found
        IF _title IS NULL THEN
            _title := 'Untitled Work';
        END IF;

        -- build snapshot
        _snapshot := jsonb_build_object(
            'title', _title,
            'price', (CASE WHEN _entity_type='task' THEN NEW.budget ELSE NEW.price END),
            'deadline', _deadline
        );
        
        -- Mock Hash (in real impl use proper hashing)
        _hash := md5(_snapshot::text);

        INSERT INTO public.work_contracts 
        (related_entity_type, related_entity_id, version, snapshot, contract_hash)
        VALUES (_entity_type, NEW.id, 1, _snapshot, _hash)
        ON CONFLICT (related_entity_type, related_entity_id, version) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
