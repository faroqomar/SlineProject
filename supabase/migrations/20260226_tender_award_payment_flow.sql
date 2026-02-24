-- ============================================================================
-- TENDER AWARD & PAYMENT FLOW
-- Implements two-step: Award → Payment for task tenders
-- Date: 2026-02-26
-- ============================================================================

-- 1. Add award timestamp and expiration for "Pay Later" support
ALTER TABLE public.task_requests
ADD COLUMN IF NOT EXISTS awarded_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS payment_deadline TIMESTAMPTZ, -- When award expires
ADD COLUMN IF NOT EXISTS awarded_by UUID REFERENCES auth.users(id);

-- 2. Create index for finding awarded but unpaid offers
CREATE INDEX IF NOT EXISTS idx_task_requests_awarded_unpaid 
ON public.task_requests(status, payment_status) 
WHERE status = 'accepted' AND payment_status = 'unpaid';

-- 3. Create index for payment deadline cleanup
CREATE INDEX IF NOT EXISTS idx_task_requests_payment_deadline 
ON public.task_requests(payment_deadline) 
WHERE status = 'accepted' AND payment_status = 'unpaid';

-- ============================================================================
-- RPC: Award an Offer (Separate from Payment)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.award_task_offer(
    p_request_id UUID,
    p_client_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
    v_task RECORD;
    v_now TIMESTAMPTZ := NOW();
    v_deadline TIMESTAMPTZ := v_now + INTERVAL '24 hours'; -- 24h to pay
BEGIN
    -- Validate request exists and is pending
    SELECT * INTO v_request
    FROM public.task_requests
    WHERE id = p_request_id
    AND status = 'pending';
    
    IF v_request IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Request not found or not in pending status'
        );
    END IF;
    
    -- Verify client owns the task
    SELECT * INTO v_task
    FROM public.tasks
    WHERE id = v_request.task_id
    AND user_id = p_client_id;
    
    IF v_task IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only task owner can award offers'
        );
    END IF;
    
    -- Check if task already has an accepted offer
    IF EXISTS (
        SELECT 1 FROM public.task_requests 
        WHERE task_id = v_request.task_id 
        AND status = 'accepted'
        AND id != p_request_id
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Task already has an accepted offer'
        );
    END IF;
    
    -- Award the offer (but don't pay yet)
    UPDATE public.task_requests
    SET 
        status = 'accepted',
        payment_status = 'unpaid',  -- Explicitly unpaid
        awarded_at = v_now,
        payment_deadline = v_deadline,
        awarded_by = p_client_id,
        updated_at = v_now
    WHERE id = p_request_id;
    
    -- Update task status to indicate awarded but not paid
    UPDATE public.tasks
    SET 
        assigned_freelancer_id = v_request.freelancer_id,
        status = 'assigned',  -- New status: assigned but not active
        updated_at = v_now
    WHERE id = v_request.task_id;
    
    -- Reject all other pending offers on this task
    UPDATE public.task_requests
    SET 
        status = 'rejected',
        updated_at = v_now
    WHERE task_id = v_request.task_id
    AND status = 'pending'
    AND id != p_request_id;
    
    -- Create notification for freelancer
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        body,
        data,
        read,
        created_at
    ) VALUES (
        v_request.freelancer_id,
        'offer_awarded',
        'Your offer was awarded!',
        'Client has selected your proposal for "' || v_task.title || '". Waiting for payment.',
        jsonb_build_object(
            'task_id', v_request.task_id,
            'request_id', p_request_id,
            'task_title', v_task.title
        ),
        false,
        v_now
    );
    
    -- Create notification for client (reminder to pay)
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        body,
        data,
        read,
        created_at
    ) VALUES (
        p_client_id,
        'payment_required',
        'Complete payment to start work',
        'You awarded a freelancer for "' || v_task.title || '". Pay within 24 hours to activate.',
        jsonb_build_object(
            'task_id', v_request.task_id,
            'request_id', p_request_id,
            'task_title', v_task.title,
            'payment_deadline', v_deadline
        ),
        false,
        v_now
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'task_id', v_request.task_id,
        'freelancer_id', v_request.freelancer_id,
        'payment_deadline', v_deadline,
        'status', 'accepted',
        'payment_status', 'unpaid'
    );
END;
$$;

-- ============================================================================
-- RPC: Pay for Awarded Offer (Completes the payment flow)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.pay_awarded_offer(
    p_request_id UUID,
    p_client_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
    v_task RECORD;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    -- Validate request exists, is awarded, and unpaid
    SELECT * INTO v_request
    FROM public.task_requests
    WHERE id = p_request_id
    AND status = 'accepted'
    AND payment_status = 'unpaid';
    
    IF v_request IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Request not found or not in awarded/unpaid status'
        );
    END IF;
    
    -- Check if payment deadline expired
    IF v_request.payment_deadline < v_now THEN
        -- Auto-cancel expired award
        UPDATE public.task_requests
        SET 
            status = 'rejected',
            payment_status = 'unpaid',
            updated_at = v_now
        WHERE id = p_request_id;
        
        UPDATE public.tasks
        SET 
            assigned_freelancer_id = NULL,
            status = 'open',
            updated_at = v_now
        WHERE id = v_request.task_id;
        
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Payment deadline expired. Award has been cancelled.',
            'expired', true
        );
    END IF;
    
    -- Verify client owns the task
    SELECT * INTO v_task
    FROM public.tasks
    WHERE id = v_request.task_id
    AND user_id = p_client_id;
    
    IF v_task IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Only task owner can pay for offers'
        );
    END IF;
    
    -- Update request to held status
    UPDATE public.task_requests
    SET 
        payment_status = 'held',
        updated_at = v_now
    WHERE id = p_request_id;
    
    -- Update task to active status (work starts now)
    UPDATE public.tasks
    SET 
        status = 'in_progress',
        updated_at = v_now
    WHERE id = v_request.task_id;
    
    -- Create notification for freelancer (work can start!)
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        body,
        data,
        read,
        created_at
    ) VALUES (
        v_request.freelancer_id,
        'work_active',
        'Payment confirmed - Start working!',
        'Client has paid for "' || v_task.title || '". Escrow held. Begin work now.',
        jsonb_build_object(
            'task_id', v_request.task_id,
            'request_id', p_request_id,
            'task_title', v_task.title
        ),
        false,
        v_now
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'task_id', v_request.task_id,
        'status', 'accepted',
        'payment_status', 'held'
    );
END;
$$;

-- ============================================================================
-- RPC: Get Client's Awarded Unpaid Offers (for "Pay Now" UI)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_client_awarded_unpaid_offers(
    p_client_id UUID DEFAULT auth.uid()
)
RETURNS TABLE (
    request_id UUID,
    task_id UUID,
    freelancer_id UUID,
    price BIGINT,
    days INTEGER,
    note TEXT,
    awarded_at TIMESTAMPTZ,
    payment_deadline TIMESTAMPTZ,
    task_title TEXT,
    freelancer_name TEXT,
    freelancer_avatar TEXT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT 
        tr.id as request_id,
        tr.task_id,
        tr.freelancer_id,
        tr.price,
        tr.days,
        tr.note,
        tr.awarded_at,
        tr.payment_deadline,
        t.title as task_title,
        p.full_name as freelancer_name,
        p.avatar_url as freelancer_avatar
    FROM public.task_requests tr
    JOIN public.tasks t ON t.id = tr.task_id
    JOIN public.profiles p ON p.id = tr.freelancer_id
    WHERE t.user_id = p_client_id
    AND tr.status = 'accepted'
    AND tr.payment_status = 'unpaid'
    AND tr.payment_deadline > NOW()
    ORDER BY tr.awarded_at DESC;
$$;

-- ============================================================================
-- RPC: Get Freelancer's Awarded Unpaid Offers (for "Waiting for Payment" UI)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_freelancer_awarded_unpaid_offers(
    p_freelancer_id UUID DEFAULT auth.uid()
)
RETURNS TABLE (
    request_id UUID,
    task_id UUID,
    client_id UUID,
    price BIGINT,
    days INTEGER,
    note TEXT,
    awarded_at TIMESTAMPTZ,
    payment_deadline TIMESTAMPTZ,
    task_title TEXT,
    client_name TEXT,
    client_avatar TEXT
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT 
        tr.id as request_id,
        tr.task_id,
        t.user_id as client_id,
        tr.price,
        tr.days,
        tr.note,
        tr.awarded_at,
        tr.payment_deadline,
        t.title as task_title,
        p.full_name as client_name,
        p.avatar_url as client_avatar
    FROM public.task_requests tr
    JOIN public.tasks t ON t.id = tr.task_id
    JOIN public.profiles p ON p.id = t.user_id
    WHERE tr.freelancer_id = p_freelancer_id
    AND tr.status = 'accepted'
    AND tr.payment_status = 'unpaid'
    AND tr.payment_deadline > NOW()
    ORDER BY tr.awarded_at DESC;
$$;

-- ============================================================================
-- Function: Clean up expired awards (can be called manually or by cron)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.cleanup_expired_awards()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_now TIMESTAMPTZ := NOW();
    v_expired RECORD;
BEGIN
    FOR v_expired IN 
        SELECT tr.id, tr.task_id, tr.freelancer_id, t.title as task_title
        FROM public.task_requests tr
        JOIN public.tasks t ON t.id = tr.task_id
        WHERE tr.status = 'accepted'
        AND tr.payment_status = 'unpaid'
        AND tr.payment_deadline < v_now
    LOOP
        -- Revert offer to rejected
        UPDATE public.task_requests
        SET 
            status = 'rejected',
            updated_at = v_now
        WHERE id = v_expired.id;
        
        -- Revert task to open
        UPDATE public.tasks
        SET 
            assigned_freelancer_id = NULL,
            status = 'open',
            updated_at = v_now
        WHERE id = v_expired.task_id;
        
        -- Notify freelancer that award expired
        INSERT INTO public.notifications (
            user_id, type, title, body, data, read, created_at
        ) VALUES (
            v_expired.freelancer_id,
            'award_expired',
            'Award expired - Client did not pay',
            'The award for "' || v_expired.task_title || '" expired. Client did not complete payment in time.',
            jsonb_build_object('task_id', v_expired.task_id, 'request_id', v_expired.id),
            false,
            v_now
        );
    END LOOP;
END;
$$;

-- ============================================================================
-- Add RLS policies for the new columns (using existing RLS, just documenting)
-- ============================================================================

-- Note: The existing RLS policies on task_requests should already handle
-- the new columns. We just need to ensure the view functions work correctly.

COMMENT ON FUNCTION public.award_task_offer IS 
'Awards an offer without payment. Creates pending payment state with 24h deadline.';

COMMENT ON FUNCTION public.pay_awarded_offer IS 
'Completes payment for an awarded offer. Activates work and creates escrow.';

COMMENT ON FUNCTION public.get_client_awarded_unpaid_offers IS 
'Returns all awarded but unpaid offers for client to complete payment.';

COMMENT ON FUNCTION public.get_freelancer_awarded_unpaid_offers IS 
'Returns all awarded but unpaid offers for freelancer (waiting for payment).';

COMMENT ON FUNCTION public.cleanup_expired_awards IS 
'Cancels awards where payment deadline has expired. Reverts tasks to open.';
