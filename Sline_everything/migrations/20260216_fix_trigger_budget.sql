-- Migration: Fix trg_activate_contract budget access
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
    _price numeric;
    _record jsonb;
BEGIN
    -- Determing Entity Type
    IF TG_TABLE_NAME = 'tasks' THEN
        _entity_type := 'task';
    ELSIF TG_TABLE_NAME = 'bookings' THEN
        _entity_type := 'booking';
    END IF;

    -- Activation Check: Status changed TO active/in_progress
    IF (OLD.status <> NEW.status) AND 
       (NEW.status = 'in_progress' OR NEW.status = 'active') THEN
        
        -- Safe usage of NEW by converting to JSONB
        -- This avoids "record new has no field X" errors in shared triggers
        _record := to_jsonb(NEW);

        -- Fetch Title, Price, Details based on type
        IF _entity_type = 'task' THEN
            -- Task: budget, title, deadline exist
            _title := _record->>'title';
            _price := (_record->>'budget')::numeric;
            _deadline := (_record->>'deadline')::timestamptz;
        ELSIF _entity_type = 'booking' THEN
            -- Booking: price exists, title/budget do not
            _price := (_record->>'price')::numeric;
            
            -- Fetch title from associated task
            -- note: NEW.task_id is valid if bookings has task_id (it does)
            -- but let's use _record to be safe or just NEW.task_id if common?
            -- task_id is definitely on bookings.
            SELECT title INTO _title FROM public.tasks WHERE id = (NEW.task_id);
            
            _deadline := NULL; 
        END IF;

        -- Fallback if title not found
        IF _title IS NULL THEN
            _title := 'Untitled Work';
        END IF;

        -- build snapshot
        _snapshot := jsonb_build_object(
            'title', _title,
            'price', _price,
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
