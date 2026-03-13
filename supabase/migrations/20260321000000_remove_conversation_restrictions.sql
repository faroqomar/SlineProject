-- Migration to remove restrictions on conversation creation
-- Allows any user (client or freelancer) to message anyone else without needing to be in favorites.

BEGIN;

-- Expression-based unique index required for ON CONFLICT in start_direct_conversation_v1
CREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_pair_task_exp
ON public.conversations (
    LEAST(user1_id, user2_id),
    GREATEST(user1_id, user2_id),
    COALESCE(task_id, '00000000-0000-0000-0000-000000000000'::uuid)
);

-- Update the RPC to remove role and favorite checks
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

    -- Target exists check
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_target) THEN
        RAISE EXCEPTION 'Target user not found';
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

    -- Audit log
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
            'validation_passed', jsonb_build_array('identity', 'rate_limit', 'self_check')
        )
    );

    RETURN v_conversation;
END;
$$;

COMMENT ON FUNCTION public.start_direct_conversation_v1 IS 
    'Atomic RPC for creating direct message conversations. Enforces rate limits (20/hour). Idempotent - returns existing conversation if already present.';

-- Update the Trigger function to remove role and favorites checks
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
        -- Restrictions (role and favorites) have been REMOVED.
        -- Any user can message any other user.
    ELSE
        -- ========================================
        -- TASK-LINKED RULES (maintain existing behavior)
        -- ========================================
        
        SELECT owner_id INTO v_task_owner_id 
        FROM public.tasks 
        WHERE id = NEW.task_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Task not found';
        END IF;

        IF v_task_owner_id = auth.uid() THEN
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
    'BEFORE INSERT guard for conversations table. Enforces: (1) identity integrity, (2) rate limiting (20/hour), (3) task ownership for task-linked.';

COMMIT;
