-- ============================================================================
-- Chat Creation Matrix Migration
-- Phase 0.7 + Phase 1: Feature Flag + DB Infrastructure
-- Version: 1.0
-- Date: 2026-03-06
-- Author: @Supabase_Ops
-- ============================================================================
-- This migration implements:
-- 1. Feature flag configuration table (app_config)
-- 2. Helper functions: is_client(), check_conversation_rate_limit()
-- 3. Atomic RPC: start_direct_conversation_v1()
-- 4. Hardened guard trigger with favorites/role enforcement
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- SECTION 1: Feature Flag Setup (Phase 0.7)
-- ----------------------------------------------------------------------------

-- Create app_config table if not exists
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on app_config
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- RLS policy: Allow authenticated users to read config
CREATE POLICY IF NOT EXISTS app_config_select_authenticated
    ON public.app_config
    FOR SELECT
    TO authenticated
    USING (true);

-- RLS policy: Only service role can write config
CREATE POLICY IF NOT EXISTS app_config_write_service
    ON public.app_config
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Insert feature flag (disabled by default)
INSERT INTO public.app_config (key, value, description)
VALUES (
    'enable_direct_conversation_rpc',
    'false',
    'Enable atomic RPC for direct conversation creation (Chat Creation Matrix). Controlled gradual rollout.'
)
ON CONFLICT (key) DO NOTHING;

COMMENT ON TABLE public.app_config IS 'Application configuration key-value store for feature flags and system settings';

-- ----------------------------------------------------------------------------
-- SECTION 2: Helper Functions (Phase 1.1)
-- ----------------------------------------------------------------------------

-- Function: is_client
-- Purpose: Check if user has active_role = 'client' in profiles
CREATE OR REPLACE FUNCTION public.is_client(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = p_user_id
        AND active_role = 'client'
    );
$$;

COMMENT ON FUNCTION public.is_client IS 'Check if user has active_role = client. Used by conversation guard triggers.';
GRANT EXECUTE ON FUNCTION public.is_client TO authenticated;

-- Function: check_conversation_rate_limit
-- Purpose: Check if user is within the 20 conversations per hour limit
CREATE OR REPLACE FUNCTION public.check_conversation_rate_limit(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COUNT(*) < 20 FROM public.conversations
    WHERE initiated_by = p_user_id
    AND created_at > NOW() - INTERVAL '1 hour';
$$;

COMMENT ON FUNCTION public.check_conversation_rate_limit IS 'Check if user can create more conversations (limit: 20/hour). Used by guard triggers.';
GRANT EXECUTE ON FUNCTION public.check_conversation_rate_limit TO authenticated;

-- ----------------------------------------------------------------------------
-- SECTION 3: Atomic RPC for Direct Conversations (Phase 1.2)
-- ----------------------------------------------------------------------------

-- Function: start_direct_conversation_v1
-- Purpose: Atomically create or retrieve a direct message conversation
-- Features:
--   - Rate limiting (20/hour)
--   - Role enforcement (clients only)
--   - Favorites enforcement (target must be in favorites)
--   - Idempotency (ON CONFLICT DO UPDATE)
--   - Audit logging to admin_logs
CREATE OR REPLACE FUNCTION public.start_direct_conversation_v1(p_target_id UUID)
RETURNS public.conversations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller UUID := auth.uid();
    v_target UUID := p_target_id;
    v_conversation public.conversations;
BEGIN
    -- Auth check
    IF v_caller IS NULL THEN
        RAISE EXCEPTION 'unauthenticated';
    END IF;

    -- Rate limit check
    IF NOT public.check_conversation_rate_limit(v_caller) THEN
        RAISE EXCEPTION 'Rate limit exceeded: maximum 20 conversations per hour';
    END IF;

    -- Role check: only clients can initiate DMs
    IF NOT public.is_client(v_caller) THEN
        RAISE EXCEPTION 'Freelancers cannot start direct conversations';
    END IF;

    -- Target exists check
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_target) THEN
        RAISE EXCEPTION 'Target user not found';
    END IF;

    -- Favorites check: target must be in caller's favorites
    IF NOT EXISTS (
        SELECT 1 FROM public.favorites
        WHERE client_id = v_caller AND freelancer_id = v_target
    ) THEN
        RAISE EXCEPTION 'You can only message freelancers in your favorites list';
    END IF;

    -- Self-conversation prevention
    IF v_caller = v_target THEN
        RAISE EXCEPTION 'Cannot create conversation with yourself';
    END IF;

    -- Atomic insert with conflict handling (idempotent)
    INSERT INTO public.conversations (
        user1_id, user2_id, task_id, initiated_by
    ) VALUES (
        LEAST(v_caller, v_target),
        GREATEST(v_caller, v_target),
        NULL,
        v_caller
    )
    ON CONFLICT (
        LEAST(user1_id, user2_id), 
        GREATEST(user1_id, user2_id), 
        COALESCE(task_id, '00000000-0000-0000-0000-000000000000')
    ) DO UPDATE SET updated_at = NOW()
    RETURNING * INTO v_conversation;

    -- Audit log for observability and security monitoring
    -- Includes structured error classification for dashboard/alerts
    INSERT INTO public.admin_logs (
        user_id, action, entity_type, entity_id, details
    ) VALUES (
        v_caller,
        'conversation_created',
        'conversations',
        v_conversation.id,
        jsonb_build_object(
            'type', 'direct_dm',
            'target_id', v_target,
            'is_new', (v_conversation.created_at = v_conversation.updated_at),
            'source', 'start_direct_conversation_v1',
            'error_code', 'SUCCESS',
            'error_category', 'NONE',
            'validation_passed', jsonb_build_array('identity', 'rate_limit', 'role', 'favorites', 'self_check')
        )
    );

    RETURN v_conversation;
END;
$$;

COMMENT ON FUNCTION public.start_direct_conversation_v1 IS 
    'Atomic RPC for creating direct message conversations. Enforces client-only initiation, favorites membership, and rate limits (20/hour). Idempotent - returns existing conversation if already present.';

GRANT EXECUTE ON FUNCTION public.start_direct_conversation_v1 TO authenticated;

-- ----------------------------------------------------------------------------
-- SECTION 4: Hardened Guard Trigger (Phase 1.3)
-- ----------------------------------------------------------------------------

-- Function: conversations_before_insert_guard
-- Purpose: Comprehensive BEFORE INSERT trigger function for conversations table
-- Validates:
--   1. Identity integrity (initiated_by = auth.uid())
--   2. Rate limiting (20/hour for all conversation creation)
--   3. Role-based rules (clients only for DMs)
--   4. Favorites-based rules (target must be in favorites for DMs)
--   5. Task-linked rules (maintains existing owner/bidder checks)
CREATE OR REPLACE FUNCTION public.conversations_before_insert_guard()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_task_owner_id UUID;
    v_other_user UUID;
BEGIN
    -- 1. Identity check: initiated_by must equal current user
    IF NEW.initiated_by IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'initiated_by must equal current user';
    END IF;

    -- 2. Rate limit check (applies to ALL conversation creation)
    IF NOT public.check_conversation_rate_limit(NEW.initiated_by) THEN
        RAISE EXCEPTION 'Rate limit exceeded: maximum 20 conversations per hour';
    END IF;

    -- 3. Context branching: Direct DM vs Task-linked
    IF NEW.task_id IS NULL THEN
        -- ========================================
        -- DIRECT DM RULES
        -- ========================================
        
        -- 3a. Only clients can initiate DMs
        IF NOT public.is_client(NEW.initiated_by) THEN
            RAISE EXCEPTION 'Freelancers cannot start direct conversations';
        END IF;

        -- 3b. Target must be in caller's favorites
        v_other_user := CASE 
            WHEN NEW.user1_id = NEW.initiated_by THEN NEW.user2_id 
            ELSE NEW.user1_id 
        END;
        
        IF NOT EXISTS (
            SELECT 1 FROM public.favorites
            WHERE client_id = NEW.initiated_by AND freelancer_id = v_other_user
        ) THEN
            RAISE EXCEPTION 'You can only message freelancers in your favorites list';
        END IF;

    ELSE
        -- ========================================
        -- TASK-LINKED RULES (maintain existing behavior)
        -- ========================================
        
        SELECT owner_id INTO v_task_owner_id 
        FROM public.tasks 
        WHERE id = NEW.task_id;
        
        IF FOUND AND v_task_owner_id = auth.uid() THEN
            -- Task owner attempting to create task-linked conversation
            -- Only allow if this is the reject flow (GUC flag set)
            IF current_setting('app.allow_owner_task_conversation', true) IS DISTINCT FROM 'true' THEN
                RAISE EXCEPTION 'Task owner cannot start a task-linked conversation';
            END IF;
            -- If GUC is set to 'true', allow the insert (reject flow exception)
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.conversations_before_insert_guard() IS 
    'BEFORE INSERT guard for conversations table. Enforces: (1) identity integrity, (2) rate limiting (20/hour), (3) role/favorites for DMs, (4) task ownership for task-linked. This trigger runs for ALL conversation inserts, including both RPC and direct INSERT paths.';

-- Drop and recreate trigger to ensure it's using the updated function
DROP TRIGGER IF EXISTS trg_conversations_before_insert_guard ON public.conversations;

CREATE TRIGGER trg_conversations_before_insert_guard
    BEFORE INSERT ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION public.conversations_before_insert_guard();

-- ----------------------------------------------------------------------------
-- SECTION 5: Admin RPC for Feature Flag Control (Phase 0.7)
-- ----------------------------------------------------------------------------

-- Function: admin_set_config
-- Purpose: Allow admin users to update app_config values (e.g., feature flags)
-- Note: In production, you may want to add explicit admin role checks
CREATE OR REPLACE FUNCTION public.admin_set_config(
    p_key TEXT,
    p_value TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Update or insert config value
    INSERT INTO public.app_config (key, value, updated_at)
    VALUES (p_key, p_value, NOW())
    ON CONFLICT (key) DO UPDATE SET
        value = p_value,
        updated_at = NOW();
    
    -- Log the config change with structured classification
    INSERT INTO public.admin_logs (
        user_id, action, entity_type, details
    ) VALUES (
        auth.uid(),
        'config_updated',
        'app_config',
        jsonb_build_object(
            'key', p_key,
            'new_value', p_value,
            'updated_at', NOW(),
            'error_code', 'SUCCESS',
            'error_category', 'NONE',
            'change_type', CASE 
                WHEN EXISTS (SELECT 1 FROM app_config WHERE key = p_key) THEN 'UPDATE'
                ELSE 'INSERT'
            END
        )
    );
END;
$$;

COMMENT ON FUNCTION public.admin_set_config IS 'Update application configuration. Used for feature flag management.';

-- Allow authenticated users to call this function
-- In production, consider restricting to admin role only
GRANT EXECUTE ON FUNCTION public.admin_set_config TO authenticated;

-- ----------------------------------------------------------------------------
-- SECTION 6: Verification Queries (Run after migration)
-- ----------------------------------------------------------------------------

-- Uncomment to verify migration:
-- SELECT key, value FROM public.app_config WHERE key = 'enable_direct_conversation_rpc';
-- SELECT proname FROM pg_proc WHERE proname IN ('is_client', 'check_conversation_rate_limit', 'start_direct_conversation_v1');
-- SELECT tgname, proname FROM pg_trigger t JOIN pg_proc p ON t.tgfoid = p.oid WHERE tgname = 'trg_conversations_before_insert_guard';

COMMIT;
