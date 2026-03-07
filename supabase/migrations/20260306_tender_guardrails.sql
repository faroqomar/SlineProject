-- Migration: Tender Task Lifecycle Guardrails
-- Created: 2026-03-06
-- Purpose: Add optimistic concurrency control, idempotency, audit logging, and auto-expiry

-- ============================================================================
-- STEP 1: Create index for efficient expiry queries (CONCURRENTLY to avoid locks)
-- ============================================================================

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_task_requests_awarded_unpaid 
ON task_requests(status, payment_status, awarded_at) 
WHERE status = 'accepted' AND payment_status = 'unpaid';

COMMENT ON INDEX idx_task_requests_awarded_unpaid IS 
'Optimizes cleanup_expired_awards cron job queries';

-- ============================================================================
-- STEP 2: Add unique partial index to enforce one accepted request per task
-- ============================================================================

CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_one_accepted_per_task 
ON task_requests(task_id) 
WHERE status = 'accepted';

COMMENT ON INDEX idx_one_accepted_per_task IS 
'Prevents multiple accepted offers on the same tender task';

-- ============================================================================
-- STEP 3: Update accept_task_request with idempotency, price check, audit logging
-- ============================================================================

-- Drop and recreate with new signature (backward compatible via DEFAULT NULL)
CREATE OR REPLACE FUNCTION accept_task_request(
    p_task_id UUID,
    p_request_id UUID,
    p_expected_price_cents BIGINT DEFAULT NULL  -- NEW: Optional price for concurrency check
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_request RECORD;
    v_task RECORD;
    v_actual_price_cents BIGINT;
    v_config_timeout_hours INT;
BEGIN
    -- ========================================================================
    -- IDEMPOTENCY CHECK: Already accepted?
    -- ========================================================================
    SELECT status, freelancer_id, price, task_id 
    INTO v_request
    FROM task_requests 
    WHERE id = p_request_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request not found: %', p_request_id;
    END IF;
    
    IF v_request.status = 'accepted' THEN
        -- Already accepted - return early without side effects
        RETURN 'already_accepted';
    END IF;
    
    IF v_request.status != 'pending' THEN
        RAISE EXCEPTION 'Cannot accept request with status: %', v_request.status;
    END IF;
    
    -- ========================================================================
    -- VERIFY REQUEST BELONGS TO TASK
    -- ========================================================================
    IF v_request.task_id != p_task_id THEN
        RAISE EXCEPTION 'Request % does not belong to task %', p_request_id, p_task_id;
    END IF;
    
    -- ========================================================================
    -- VERIFY TASK OWNERSHIP (Authorization check)
    -- ========================================================================
    SELECT owner_id, status, title 
    INTO v_task
    FROM tasks 
    WHERE id = p_task_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Task not found: %', p_task_id;
    END IF;
    
    IF v_task.owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to accept offers on this task';
    END IF;
    
    IF v_task.status != 'open' THEN
        RAISE EXCEPTION 'Cannot accept offers on task with status: %', v_task.status;
    END IF;
    
    -- ========================================================================
    -- OPTIMISTIC CONCURRENCY: Price validation
    -- ========================================================================
    -- Convert numeric price to cents for comparison
    v_actual_price_cents := (v_request.price * 100)::BIGINT;
    
    IF p_expected_price_cents IS NOT NULL THEN
        IF p_expected_price_cents != v_actual_price_cents THEN
            -- AUDIT LOG: Price mismatch attempt (security signal)
            INSERT INTO admin_logs (
                actor_id,
                action,
                target_resource,
                target_id,
                metadata,
                created_at
            ) VALUES (
                auth.uid(),
                'PRICE_MISMATCH_ATTEMPT',
                'task_requests',
                p_request_id,
                jsonb_build_object(
                    'expected_cents', p_expected_price_cents,
                    'actual_cents', v_actual_price_cents,
                    'task_id', p_task_id,
                    'freelancer_id', v_request.freelancer_id
                ),
                NOW()
            );
            
            RAISE EXCEPTION 'PRICE_MISMATCH: Offer price changed from % to % cents', 
                p_expected_price_cents, v_actual_price_cents;
        END IF;
    END IF;
    
    -- ========================================================================
    -- READ PAYMENT TIMEOUT FROM CONFIG (default 48 hours)
    -- ========================================================================
    BEGIN
        SELECT (value->>'timeout_hours')::INT 
        INTO v_config_timeout_hours
        FROM system_config 
        WHERE key = 'tender_payment_timeout_hours';
    EXCEPTION WHEN OTHERS THEN
        v_config_timeout_hours := NULL;
    END;
    
    IF v_config_timeout_hours IS NULL THEN
        v_config_timeout_hours := 48; -- Default 48 hours
    END IF;
    
    -- ========================================================================
    -- ACCEPT THE REQUEST
    -- ========================================================================
    UPDATE task_requests 
    SET 
        status = 'accepted',
        awarded_at = NOW(),
        awarded_by = auth.uid(),
        payment_deadline = NOW() + (v_config_timeout_hours || ' hours')::INTERVAL,
        updated_at = NOW(),
        -- Lock fee rate at award time (immutable after this)
        fee_rate_applied_bps = COALESCE(
            (SELECT (value->>'default_rate_bps')::INT FROM system_config WHERE key = 'platform_fee_bps'),
            1000 -- 10% default
        ),
        -- Pre-calculate fee amounts (can be recalculated at payment time for safety)
        fee_amount = ((price * 100)::BIGINT * COALESCE(
            (SELECT (value->>'default_rate_bps')::INT FROM system_config WHERE key = 'platform_fee_bps'),
            1000
        ) / 10000)::BIGINT,
        net_amount = ((price * 100)::BIGINT) - (((price * 100)::BIGINT * COALESCE(
            (SELECT (value->>'default_rate_bps')::INT FROM system_config WHERE key = 'platform_fee_bps'),
            1000
        ) / 10000)::BIGINT)
    WHERE id = p_request_id;
    
    -- ========================================================================
    -- UPDATE TASK STATUS
    -- ========================================================================
    UPDATE tasks 
    SET 
        status = 'assigned',
        assigned_freelancer_id = v_request.freelancer_id,
        updated_at = NOW()
    WHERE id = p_task_id;
    
    -- ========================================================================
    -- AUDIT LOG: Successful acceptance
    -- ========================================================================
    INSERT INTO admin_logs (
        actor_id,
        action,
        target_resource,
        target_id,
        metadata,
        created_at
    ) VALUES (
        auth.uid(),
        'OFFER_ACCEPTED',
        'task_requests',
        p_request_id,
        jsonb_build_object(
            'task_id', p_task_id,
            'freelancer_id', v_request.freelancer_id,
            'price_cents', v_actual_price_cents,
            'payment_deadline_hours', v_config_timeout_hours
        ),
        NOW()
    );
    
    -- ========================================================================
    -- ACTIVITY LOG: For client dashboard
    -- ========================================================================
    INSERT INTO activity_log (
        user_id,
        actor_id,
        entity_type,
        entity_id,
        event_type,
        metadata,
        created_at
    ) VALUES (
        v_task.owner_id,
        auth.uid(),
        'task',
        p_task_id,
        'offer_accepted',
        jsonb_build_object(
            'request_id', p_request_id,
            'freelancer_id', v_request.freelancer_id,
            'task_title', v_task.title
        ),
        NOW()
    );
    
    -- Return success
    RETURN 'accepted';
END;
$$;

COMMENT ON FUNCTION accept_task_request(UUID, UUID, BIGINT) IS 
'Accepts a task request with optional price validation for optimistic concurrency control. 
Parameters:
  - p_task_id: The task UUID
  - p_request_id: The request/offer UUID to accept
  - p_expected_price_cents: Optional price validation (NULL to skip). If provided and doesnt match, raises PRICE_MISMATCH error.';

-- ============================================================================
-- STEP 4: Ensure cleanup_expired_awards is up-to-date
-- ============================================================================

-- Verify or update the cleanup function to use the index properly
CREATE OR REPLACE FUNCTION cleanup_expired_awards()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_now TIMESTAMPTZ := NOW();
    v_expired RECORD;
    v_count INT := 0;
BEGIN
    -- Security check: only service role, postgres, or cron can execute
    IF current_user NOT IN ('service_role', 'postgres', 'supabase_admin', 'authenticator') THEN
        RAISE EXCEPTION 'Permission denied: cleanup_expired_awards can only be called by service role or cron job';
    END IF;
    
    -- Find expired awards using the index
    FOR v_expired IN 
        SELECT 
            tr.id, 
            tr.task_id, 
            tr.freelancer_id, 
            tr.client_id,
            tr.price,
            t.title as task_title
        FROM task_requests tr
        JOIN tasks t ON t.id = tr.task_id
        WHERE tr.status = 'accepted'
        AND tr.payment_status = 'unpaid'
        AND tr.payment_deadline < v_now
        -- Grace period: only expire if deadline passed more than 1 hour ago
        -- This prevents race conditions with in-flight payments
        AND tr.payment_deadline < v_now - INTERVAL '1 hour'
    LOOP
        v_count := v_count + 1;
        
        -- Mark request as rejected (expired)
        UPDATE task_requests
        SET 
            status = 'rejected',
            updated_at = v_now,
            -- Store expiry reason in metadata
            note = COALESCE(note, '') || E'\n[SYSTEM] Offer expired after payment deadline.'
        WHERE id = v_expired.id;
        
        -- Revert task to open
        UPDATE tasks
        SET 
            status = 'open',
            freelancer_id = NULL,
            assigned_freelancer_id = NULL,
            updated_at = v_now
        WHERE id = v_expired.task_id;
        
        -- Notify freelancer that award expired
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            related_entity_id,
            related_entity_type,
            metadata,
            is_read,
            created_at
        ) VALUES (
            v_expired.freelancer_id,
            'award_expired',
            'Award Expired',
            format('Your award on "%s" expired because payment was not completed within the deadline.', v_expired.task_title),
            v_expired.id,
            'task_request',
            jsonb_build_object(
                'task_id', v_expired.task_id,
                'request_id', v_expired.id,
                'expired_price', v_expired.price
            ),
            false,
            v_now
        );
        
        -- Notify client as well (so they know they missed the payment window)
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            related_entity_id,
            related_entity_type,
            metadata,
            is_read,
            created_at
        ) VALUES (
            v_expired.client_id,
            'award_expired',
            'Payment Window Closed',
            format('The payment window for "%s" has closed. You can still award this task to another freelancer.', v_expired.task_title),
            v_expired.task_id,
            'task',
            jsonb_build_object(
                'task_id', v_expired.task_id,
                'request_id', v_expired.id
            ),
            false,
            v_now
        );
        
        -- Audit log the expiry
        INSERT INTO admin_logs (
            actor_id,
            action,
            target_resource,
            target_id,
            metadata,
            created_at
        ) VALUES (
            NULL, -- System action
            'AWARD_AUTO_EXPIRED',
            'task_requests',
            v_expired.id,
            jsonb_build_object(
                'task_id', v_expired.task_id,
                'freelancer_id', v_expired.freelancer_id,
                'client_id', v_expired.client_id,
                'price', v_expired.price
            ),
            v_now
        );
    END LOOP;
    
    -- Log completion (for monitoring)
    IF v_count > 0 THEN
        RAISE NOTICE 'cleanup_expired_awards: expired % awards', v_count;
    END IF;
END;
$$;

COMMENT ON FUNCTION cleanup_expired_awards() IS 
'Automatically expires awarded offers that have not been paid within the payment_deadline. 
Runs via pg_cron every 10 minutes. Includes 1-hour grace period to avoid race conditions with in-flight payments.';

-- ============================================================================
-- STEP 5: Schedule cron job (if not already scheduled)
-- ============================================================================

DO $$
BEGIN
    -- Check if job already exists
    IF NOT EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'cleanup-expired-awards'
    ) THEN
        -- Schedule the cron job to run every 10 minutes
        PERFORM cron.schedule(
            'cleanup-expired-awards',
            '*/10 * * * *',  -- Every 10 minutes
            'SELECT cleanup_expired_awards()'
        );
        
        RAISE NOTICE 'Scheduled cleanup-expired-awards cron job';
    ELSE
        RAISE NOTICE 'cleanup-expired-awards cron job already scheduled';
    END IF;
END $$;

-- ============================================================================
-- STEP 6: Add tender_payment_timeout_hours to system_config (if not exists)
-- ============================================================================

INSERT INTO system_config (key, value, description, updated_at)
VALUES (
    'tender_payment_timeout_hours',
    '{"timeout_hours": 48}',
    'Number of hours client has to pay after accepting an offer before it auto-expires',
    NOW()
)
ON CONFLICT (key) DO UPDATE 
SET 
    description = EXCLUDED.description,
    updated_at = NOW();

-- ============================================================================
-- VERIFICATION QUERIES (Run manually after migration)
-- ============================================================================

/*
-- Verify indexes were created:
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'task_requests' 
AND indexname LIKE 'idx_%';

-- Verify function exists with correct signature:
SELECT routine_name, data_type, routine_definition
FROM information_schema.routines
WHERE routine_name = 'accept_task_request';

-- Verify cron job is scheduled:
SELECT * FROM cron.job WHERE jobname = 'cleanup-expired-awards';

-- Test price mismatch error:
SELECT accept_task_request(
    'valid-task-uuid',
    'valid-request-uuid', 
    999999  -- Wrong expected price
);

-- Test idempotency:
-- Run same accept_task_request twice, second should return 'already_accepted'
*/
