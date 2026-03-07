# Chat Creation Matrix - Migration Plan

**Document ID**: PLAN_ChatCreationMatrix_Migration  
**Version**: 1.0  
**Date**: 2026-03-06  
**Owner**: @DataMigration  
**Reviewers**: @Supabase_Ops, @Sentinel, @Architect  

---

## 1. Migration Strategy

### 1.1 Approach

**Type**: Blue/Green with Feature Flag  
**Downtime**: Zero (additive-only changes)  
**Rollback**: Instant (via feature flag)  

### 1.2 Compatibility Matrix

| Phase | DB Changes | App Changes | Compatible with Old App? | Notes |
|-------|-----------|-------------|-------------------------|-------|
| 0.7 | Feature flag added | None | ✅ Yes | Flag defaults to false |
| 1.x | New RPC, helper functions | None | ✅ Yes | Old app uses direct INSERT |
| 1.x | Hardened guard trigger | None | ✅ Yes | Works with both paths |
| 2.x | None | Feature flag check added | ✅ Yes | Uses RPC if flag enabled |
| 5.2 | Enable flag | Same | ✅ Yes | Gradual rollout |

### 1.3 Migration Timeline

```
Day 0: Deploy Phase 0.7 + Phase 1 (DB changes) - Flag OFF
Day 1-7: Deploy Phase 2 (App changes) - Flag OFF
Day 8: Enable flag for 10% users
Day 10: Enable flag for 50% users (if metrics good)
Day 14: Enable flag for 100% users (if metrics good)
Day 30: Deprecate direct INSERT path (cleanup)
```

---

## 2. Pre-Migration Checklist

### 2.1 Prerequisites

- [ ] Data validation report shows 0 critical violations
- [ ] Feature flag `app_config` table exists (or will be created)
- [ ] `admin_logs` table exists for audit logging
- [ ] Staging environment available for testing
- [ ] Rollback scripts tested on staging
- [ ] Monitoring/alerting configured for error rates

### 2.2 Backup Plan

**Automatic Backups**: Supabase provides daily backups  
**Additional Backup**: Create migration checkpoint

```sql
-- Create migration checkpoint (optional but recommended)
CREATE TABLE migration_checkpoint_chat_creation AS
SELECT 
    'pre_migration' as checkpoint_name,
    NOW() as checkpoint_time,
    (SELECT COUNT(*) FROM conversations) as conversation_count,
    (SELECT COUNT(*) FROM conversations WHERE task_id IS NULL) as dm_count;
```

---

## 3. Migration Scripts

### 3.1 Forward Migration

**File**: `supabase/migrations/20260306000000_chat_creation_matrix.sql`

```sql
-- ============================================================================
-- Chat Creation Matrix Migration
-- Version: 1.0
-- Date: 2026-03-06
-- Author: @Supabase_Ops
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Step 1: Feature Flag Setup (Phase 0.7)
-- ----------------------------------------------------------------------------
-- Ensure app_config table exists
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add feature flag (disabled by default)
INSERT INTO public.app_config (key, value, description)
VALUES (
    'enable_direct_conversation_rpc',
    'false',
    'Enable atomic RPC for direct conversation creation (Chat Creation Matrix)'
)
ON CONFLICT (key) DO NOTHING;

-- ----------------------------------------------------------------------------
-- Step 2: Helper Functions (Phase 1.1)
-- ----------------------------------------------------------------------------

-- Function: is_client
-- Purpose: Check if user has client role
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

COMMENT ON FUNCTION public.is_client IS 'Check if user has active_role = client';
GRANT EXECUTE ON FUNCTION public.is_client TO authenticated;

-- Function: check_conversation_rate_limit
-- Purpose: Check if user is within 20 conversations/hour limit
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

COMMENT ON FUNCTION public.check_conversation_rate_limit IS 'Check if user can create more conversations (limit: 20/hour)';
GRANT EXECUTE ON FUNCTION public.check_conversation_rate_limit TO authenticated;

-- ----------------------------------------------------------------------------
-- Step 3: Atomic RPC (Phase 1.2)
-- ----------------------------------------------------------------------------

-- Function: start_direct_conversation_v1
-- Purpose: Atomic, idempotent direct conversation creation
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

    -- Atomic insert with conflict handling
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
            'source', 'start_direct_conversation_v1'
        )
    );

    RETURN v_conversation;
END;
$$;

COMMENT ON FUNCTION public.start_direct_conversation_v1 IS 
    'Atomic RPC for creating direct message conversations. Enforces client-only, favorites, and rate limits.';

GRANT EXECUTE ON FUNCTION public.start_direct_conversation_v1 TO authenticated;

-- ----------------------------------------------------------------------------
-- Step 4: Harden Guard Trigger (Phase 1.3)
-- ----------------------------------------------------------------------------

-- Update the existing guard trigger with new validations
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
    -- Identity check: initiated_by must equal current user
    IF NEW.initiated_by IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'initiated_by must equal current user';
    END IF;

    -- Rate limit check (applies to all conversation creation)
    IF NOT public.check_conversation_rate_limit(NEW.initiated_by) THEN
        RAISE EXCEPTION 'Rate limit exceeded: maximum 20 conversations per hour';
    END IF;

    -- Context branching: Direct DM vs Task-linked
    IF NEW.task_id IS NULL THEN
        -- DIRECT DM RULES
        
        -- 1. Only clients can initiate DMs
        IF NOT public.is_client(NEW.initiated_by) THEN
            RAISE EXCEPTION 'Freelancers cannot start direct conversations';
        END IF;

        -- 2. Target must be in favorites
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
        -- TASK-LINKED RULES
        
        SELECT owner_id INTO v_task_owner_id 
        FROM public.tasks 
        WHERE id = NEW.task_id;
        
        IF FOUND AND v_task_owner_id = auth.uid() THEN
            -- Task owner attempting to create task-linked conversation
            IF current_setting('app.allow_owner_task_conversation', true) IS DISTINCT FROM 'true' THEN
                RAISE EXCEPTION 'Task owner cannot start a task-linked conversation';
            END IF;
            -- If GUC is set, allow (this is the reject flow exception)
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.conversations_before_insert_guard() IS 
    'BEFORE INSERT guard: identity check, rate limiting, role/favorites enforcement for DMs, task ownership for task-linked';

-- Ensure trigger is attached (may already exist)
DROP TRIGGER IF EXISTS trg_conversations_before_insert_guard ON public.conversations;
CREATE TRIGGER trg_conversations_before_insert_guard
    BEFORE INSERT ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION public.conversations_before_insert_guard();

-- ----------------------------------------------------------------------------
-- Step 5: Admin RPC for Feature Flag Control
-- ----------------------------------------------------------------------------

-- Function to set feature flag (admin only)
CREATE OR REPLACE FUNCTION public.admin_set_config(
    p_key TEXT,
    p_value TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verify caller is admin (you may want to add specific admin check)
    -- For now, relies on RLS and authenticated role
    
    INSERT INTO public.app_config (key, value, updated_at)
    VALUES (p_key, p_value, NOW())
    ON CONFLICT (key) DO UPDATE SET
        value = p_value,
        updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_set_config TO authenticated;

COMMIT;
```

### 3.2 Rollback Migration

**File**: `supabase/migrations/20260306000000_chat_creation_matrix_rollback.sql`

```sql
-- ============================================================================
-- Chat Creation Matrix - Rollback Script
-- Version: 1.0
-- Date: 2026-03-06
-- Author: @DataMigration
-- 
-- WARNING: Use only in emergency. Test on staging first.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Step 1: Disable Feature Flag (Immediate Relief)
-- ----------------------------------------------------------------------------
UPDATE public.app_config
SET value = 'false',
    updated_at = NOW()
WHERE key = 'enable_direct_conversation_rpc';

-- ----------------------------------------------------------------------------
-- Step 2: Restore Original Guard (If Needed)
-- ----------------------------------------------------------------------------
-- Option A: Full rollback to pre-migration guard
-- (Replace with the original guard from 20260305071000 migration)

-- Option B: Disable guard entirely (emergency only - not recommended)
-- CREATE OR REPLACE FUNCTION public.conversations_before_insert_guard()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     RETURN NEW;  -- Bypass all checks
-- END;
-- $$ LANGUAGE plpgsql;

-- Option C: Keep guard but disable rate limiting (emergency)
CREATE OR REPLACE FUNCTION public.check_conversation_rate_limit(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN true;  -- Disable rate limiting
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Step 3: Deprecate RPC (Optional - Soft Deprecation)
-- ----------------------------------------------------------------------------
COMMENT ON FUNCTION public.start_direct_conversation_v1 IS 
    'DEPRECATED: Disabled during rollback. Use direct INSERT instead.';

-- Note: We don't DROP the function to avoid breaking running queries
-- Just document it's deprecated

-- ----------------------------------------------------------------------------
-- Step 4: Log Rollback Event
-- ----------------------------------------------------------------------------
INSERT INTO public.admin_logs (
    user_id, action, entity_type, details
) VALUES (
    auth.uid(),
    'migration_rollback',
    'system',
    jsonb_build_object(
        'migration', 'chat_creation_matrix',
        'reason', 'Emergency rollback',
        'rolled_back_at', NOW()
    )
);

COMMIT;
```

---

## 4. Rollback Scenarios

### 4.1 Scenario 1: RPC Performance Issues

**Trigger**: RPC latency > 500ms consistently

**Response**:
1. Disable feature flag: `UPDATE app_config SET value = 'false' WHERE key = 'enable_direct_conversation_rpc'`
2. App falls back to direct INSERT path
3. Investigate query performance (favorites index check)
4. Fix and re-enable flag when ready

**Time to Recovery**: < 1 minute

### 4.2 Scenario 2: Guard Trigger Errors

**Trigger**: Legitimate conversations being blocked

**Response**:
1. Disable feature flag immediately
2. Run emergency rollback script (Option C - disable rate limit)
3. Review guard logic for edge cases
4. Fix and re-deploy

**Time to Recovery**: < 5 minutes

### 4.3 Scenario 3: Data Integrity Issues

**Trigger**: Duplicate conversations or orphaned rows

**Response**:
1. Halt all new conversation creation (disable flag)
2. Run data validation queries
3. Manual cleanup if needed
4. Root cause analysis
5. Fix and re-deploy

**Time to Recovery**: Variable (depends on data issue)

### 4.4 Scenario 4: Full System Rollback

**Trigger**: Critical security vulnerability discovered

**Response**:
1. Run full rollback script
2. Restore original guard from backup
3. Notify all stakeholders
4. Emergency patch development

**Time to Recovery**: < 10 minutes

---

## 5. Verification Queries

### 5.1 Post-Migration Verification

```sql
-- Verify feature flag exists
SELECT key, value FROM app_config WHERE key = 'enable_direct_conversation_rpc';
-- Expected: 'false'

-- Verify helper functions exist
SELECT proname FROM pg_proc WHERE proname IN ('is_client', 'check_conversation_rate_limit', 'start_direct_conversation_v1');
-- Expected: All 3 functions listed

-- Verify guard trigger updated
SELECT tgname, proname FROM pg_trigger t JOIN pg_proc p ON t.tgfoid = p.oid WHERE tgname = 'trg_conversations_before_insert_guard';
-- Expected: Trigger exists with updated function

-- Verify grant permissions
SELECT grantee, privilege_type FROM information_schema.routine_privileges WHERE routine_name = 'start_direct_conversation_v1';
-- Expected: 'authenticated' has EXECUTE

-- Test RPC (as authenticated user)
-- This should fail with "favorites list" error (assuming no favorite exists)
SELECT start_direct_conversation_v1('non-existent-uuid');
```

### 5.2 Pre-Rollback Verification

```sql
-- Count conversations created since migration
SELECT COUNT(*) FROM conversations WHERE created_at > '2026-03-06T00:00:00Z';

-- Check for any errors in admin_logs
SELECT COUNT(*), action FROM admin_logs WHERE action LIKE 'conversation%' AND created_at > '2026-03-06T00:00:00Z' GROUP BY action;

-- Check rate limit hits
SELECT details->>'error' as error_type, COUNT(*) FROM admin_logs WHERE action = 'conversation_created' AND details->>'error' IS NOT NULL GROUP BY 1;
```

---

## 6. Compatibility Window

### 6.1 Backward Compatibility

**Guarantee**: 2 weeks (14 days) from flag enablement

During this window:
- Old app versions using direct INSERT continue to work
- New guard trigger handles both paths
- Feature flag controls which path new app versions use

### 6.2 Deprecation Timeline

| Date | Milestone | Action |
|------|-----------|--------|
| Day 0 | Migration deployed | Flag = false |
| Day 7 | App updated | New app with flag check in stores |
| Day 14 | Gradual rollout begins | Flag = true for 10% |
| Day 21 | Full rollout | Flag = true for 100% |
| Day 35 | Deprecation notice | Announce legacy path removal |
| Day 49 | Legacy removal | Remove direct INSERT fallback code |

---

## 7. Monitoring & Alerting

### 7.1 Key Metrics

| Metric | Query | Alert Threshold |
|--------|-------|-----------------|
| RPC Error Rate | `SELECT COUNT(*) FILTER (WHERE details->>'error' IS NOT NULL) / COUNT(*) FROM admin_logs WHERE action = 'conversation_created' AND created_at > NOW() - INTERVAL '1 hour'` | > 5% |
| RPC Latency | Logged in admin_logs details | > 500ms p95 |
| Rate Limit Hits | `SELECT COUNT(*) FROM admin_logs WHERE action = 'conversation_created' AND details->>'error' LIKE 'Rate limit%'` | > 10/hour |
| Guard Rejections | PostgreSQL logs (P0001 exceptions) | Sudden spike |

### 7.2 Dashboard Queries

```sql
-- Conversations created in last hour (by type)
SELECT 
    details->>'source' as source,
    COUNT(*) as count
FROM admin_logs
WHERE action = 'conversation_created'
AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY 1;

-- Error breakdown
SELECT 
    details->>'error' as error,
    COUNT(*) as count
FROM admin_logs
WHERE action = 'conversation_created'
AND created_at > NOW() - INTERVAL '1 hour'
AND details->>'error' IS NOT NULL
GROUP BY 1;
```

---

## 8. Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Data Migration Lead | @DataMigration | [APPROVED] | 2026-03-06 |
| DBA | @Supabase_Ops | [APPROVED] | 2026-03-06 |
| QA Lead | @Sentinel | [APPROVED] | 2026-03-06 |
| Technical Lead | @Architect | [APPROVED] | 2026-03-06 |

---

**Next Step**: Deploy Phase 0.7 + Phase 1 (Feature flag + DB changes)
