-- Migration: 20260306_role_switch_foundation
-- Description: Atomic role switching with JWT claims, audit logging, and rate limiting
-- Author: @Executor (Phase 1)
-- Date: 2026-03-06

-- ============================================================================
-- 1. RPC: switch_active_role
-- ============================================================================
-- Purpose: Atomically switch user role with race condition protection
-- Returns: JSONB with success, new_role, error, message fields

CREATE OR REPLACE FUNCTION switch_active_role(
  p_expected_old_role TEXT,
  p_new_role TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_role TEXT;
  v_user_id UUID;
  v_success BOOLEAN := false;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'session_error',
      'message', 'No authenticated user'
    );
  END IF;
  
  -- Get current role from profiles
  SELECT active_role INTO v_current_role
  FROM profiles
  WHERE id = v_user_id;
  
  -- Check if profile exists
  IF v_current_role IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'db_error',
      'message', 'Profile not found'
    );
  END IF;
  
  -- Idempotency: if already at target role, return success
  IF v_current_role = p_new_role THEN
    RETURN jsonb_build_object(
      'success', true,
      'new_role', p_new_role,
      'message', 'Role already set to ' || p_new_role
    );
  END IF;
  
  -- Atomic guard: expected_old_role must match current
  IF v_current_role IS DISTINCT FROM p_expected_old_role THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'stale_state',
      'message', 'Role was already changed. Current: ' || COALESCE(v_current_role, 'null') || ', Expected: ' || p_expected_old_role
    );
  END IF;
  
  -- Validate new_role
  IF p_new_role NOT IN ('client', 'freelancer') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'invalid_role',
      'message', 'Invalid role: ' || p_new_role || '. Must be client or freelancer.'
    );
  END IF;
  
  -- Update profile
  UPDATE profiles
  SET active_role = p_new_role,
      updated_at = NOW()
  WHERE id = v_user_id
    AND active_role = p_expected_old_role;
  
  -- Verify update succeeded
  IF FOUND THEN
    v_success := true;
  ELSE
    RETURN jsonb_build_object(
      'success', false,
      'error', 'stale_state',
      'message', 'Role changed during update (concurrent modification)'
    );
  END IF;
  
  -- Log to audit_logs
  INSERT INTO audit_logs (
    user_id,
    action,
    entity_type,
    entity_id,
    details,
    created_at
  ) VALUES (
    v_user_id,
    'role_switch',
    'profile',
    v_user_id,
    jsonb_build_object(
      'old_role', v_current_role,
      'new_role', p_new_role,
      'expected_role', p_expected_old_role,
      'success', v_success
    ),
    NOW()
  );
  
  RETURN jsonb_build_object(
    'success', v_success,
    'new_role', p_new_role
  );
  
EXCEPTION WHEN OTHERS THEN
  -- Log error to audit_logs
  INSERT INTO audit_logs (
    user_id,
    action,
    entity_type,
    entity_id,
    details,
    created_at
  ) VALUES (
    v_user_id,
    'role_switch',
    'profile',
    v_user_id,
    jsonb_build_object(
      'old_role', v_current_role,
      'attempted_new_role', p_new_role,
      'success', false,
      'error', SQLERRM
    ),
    NOW()
  );
  
  RETURN jsonb_build_object(
    'success', false,
    'error', 'db_error',
    'message', SQLERRM
  );
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION switch_active_role(TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION switch_active_role(TEXT, TEXT) IS 
'Atomically switches user role with race condition protection.
Parameters:
  p_expected_old_role: The role user thinks they currently have (atomic guard)
  p_new_role: Target role (client or freelancer)
Returns:
  JSONB with success, new_role, error, message fields';

-- ============================================================================
-- 2. Trigger: sync_role_to_jwt_claims
-- ============================================================================
-- Purpose: Sync profiles.active_role to auth.users.app_metadata

CREATE OR REPLACE FUNCTION sync_role_to_jwt_claims()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF OLD.active_role IS DISTINCT FROM NEW.active_role THEN
    UPDATE auth.users
    SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || 
                            jsonb_build_object('active_role', NEW.active_role)
    WHERE id = NEW.id;
    
    INSERT INTO audit_logs (
      user_id, action, entity_type, entity_id, details, created_at
    ) VALUES (
      NEW.id, 'jwt_sync', 'profile', NEW.id,
      jsonb_build_object('old_role', OLD.active_role, 'new_role', NEW.active_role),
      NOW()
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_role_to_jwt ON profiles;

CREATE TRIGGER trg_sync_role_to_jwt
  AFTER UPDATE OF active_role ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_role_to_jwt_claims();

-- ============================================================================
-- 3. Function: check_role_switch_rate_limit
-- ============================================================================
-- Purpose: Prevent abuse via rapid role switching (3 switches per minute max)

CREATE OR REPLACE FUNCTION check_role_switch_rate_limit()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_recent_switches INTEGER;
  v_max_switches INTEGER := 3;
  v_window_minutes INTEGER := 1;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN RETURN false; END IF;
  
  SELECT COUNT(*) INTO v_recent_switches
  FROM audit_logs
  WHERE user_id = v_user_id
    AND action = 'role_switch'
    AND created_at > NOW() - (v_window_minutes || ' minutes')::INTERVAL
    AND (details->>'success')::BOOLEAN = true;
  
  RETURN v_recent_switches < v_max_switches;
END;
$$;

GRANT EXECUTE ON FUNCTION check_role_switch_rate_limit() TO authenticated;

-- ============================================================================
-- 4. JWT-Based RLS Policies (Dual-policy approach)
-- ============================================================================
-- New policies use JWT claims; old policies remain for backward compatibility

-- task_requests: INSERT requires freelancer role
CREATE POLICY task_requests_insert_freelancer_jwt
  ON task_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (
    freelancer_id = auth.uid()
    AND (auth.jwt()->'app_metadata'->>'active_role') = 'freelancer'
    AND EXISTS (
      SELECT 1 FROM tasks t
      WHERE t.id = task_requests.task_id
        AND t.status = 'open'
        AND t.owner_id <> auth.uid()
    )
  );

-- availability_slots: INSERT requires freelancer role
CREATE POLICY availability_slots_insert_freelancer_jwt
  ON availability_slots
  FOR INSERT
  TO authenticated
  WITH CHECK (
    provider_id = auth.uid()
    AND (auth.jwt()->'app_metadata'->>'active_role') = 'freelancer'
  );

-- availability_slots: UPDATE requires freelancer role
CREATE POLICY availability_slots_update_freelancer_jwt
  ON availability_slots
  FOR UPDATE
  TO authenticated
  USING (
    provider_id = auth.uid()
    AND (auth.jwt()->'app_metadata'->>'active_role') = 'freelancer'
  )
  WITH CHECK (
    provider_id = auth.uid()
    AND (auth.jwt()->'app_metadata'->>'active_role') = 'freelancer'
  );

-- tasks: INSERT requires client role
CREATE POLICY tasks_insert_client_jwt
  ON tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    owner_id = auth.uid()
    AND (auth.jwt()->'app_metadata'->>'active_role') = 'client'
  );

-- ============================================================================
-- Verification Query (run after migration):
-- ============================================================================
-- SELECT 
--   proname as function,
--   tgname as trigger,
--   policyname as policy
-- FROM pg_proc
-- LEFT JOIN pg_trigger ON pg_trigger.tgfoid = pg_proc.oid
-- LEFT JOIN pg_policies ON true
-- WHERE proname IN ('switch_active_role', 'sync_role_to_jwt_claims', 'check_role_switch_rate_limit')
--    OR tgname = 'trg_sync_role_to_jwt'
--    OR policyname LIKE '%_jwt';
