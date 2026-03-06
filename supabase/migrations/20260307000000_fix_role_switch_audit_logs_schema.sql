-- Migration: 20260307000000_fix_role_switch_audit_logs_schema
-- Description: Align role-switch RPC and trigger with existing audit_logs schema.
--   audit_logs uses (actor_user_id, action, related_entity_type, related_entity_id, journal_entry_id, meta),
--   not (user_id, entity_type, entity_id, details).
-- Date: 2026-03-07

-- ============================================================================
-- 1. switch_active_role: use audit_logs correct columns
-- ============================================================================

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
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'session_error',
      'message', 'No authenticated user'
    );
  END IF;

  SELECT active_role INTO v_current_role
  FROM profiles
  WHERE id = v_user_id;

  IF v_current_role IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'db_error',
      'message', 'Profile not found'
    );
  END IF;

  IF v_current_role = p_new_role THEN
    RETURN jsonb_build_object(
      'success', true,
      'new_role', p_new_role,
      'message', 'Role already set to ' || p_new_role
    );
  END IF;

  IF v_current_role IS DISTINCT FROM p_expected_old_role THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'stale_state',
      'message', 'Role was already changed. Current: ' || COALESCE(v_current_role, 'null') || ', Expected: ' || p_expected_old_role
    );
  END IF;

  IF p_new_role NOT IN ('client', 'freelancer') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'invalid_role',
      'message', 'Invalid role: ' || p_new_role || '. Must be client or freelancer.'
    );
  END IF;

  UPDATE profiles
  SET active_role = p_new_role,
      updated_at = NOW()
  WHERE id = v_user_id
    AND active_role = p_expected_old_role;

  IF FOUND THEN
    v_success := true;
  ELSE
    RETURN jsonb_build_object(
      'success', false,
      'error', 'stale_state',
      'message', 'Role changed during update (concurrent modification)'
    );
  END IF;

  -- Log using existing audit_logs schema (actor_user_id, meta; no user_id/entity_type/details)
  INSERT INTO public.audit_logs (
    actor_user_id,
    action,
    related_entity_type,
    related_entity_id,
    journal_entry_id,
    meta
  ) VALUES (
    v_user_id,
    'role_switch',
    NULL,
    v_user_id,
    NULL,
    jsonb_build_object(
      'entity_type', 'profile',
      'old_role', v_current_role,
      'new_role', p_new_role,
      'expected_role', p_expected_old_role,
      'success', v_success
    )
  );

  RETURN jsonb_build_object(
    'success', v_success,
    'new_role', p_new_role
  );

EXCEPTION WHEN OTHERS THEN
  INSERT INTO public.audit_logs (
    actor_user_id,
    action,
    related_entity_type,
    related_entity_id,
    journal_entry_id,
    meta
  ) VALUES (
    v_user_id,
    'role_switch',
    NULL,
    v_user_id,
    NULL,
    jsonb_build_object(
      'entity_type', 'profile',
      'old_role', v_current_role,
      'attempted_new_role', p_new_role,
      'success', false,
      'error', SQLERRM
    )
  );

  RETURN jsonb_build_object(
    'success', false,
    'error', 'db_error',
    'message', SQLERRM
  );
END;
$$;

-- ============================================================================
-- 2. sync_role_to_jwt_claims: use audit_logs correct columns
-- ============================================================================

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

    INSERT INTO public.audit_logs (
      actor_user_id,
      action,
      related_entity_type,
      related_entity_id,
      journal_entry_id,
      meta
    ) VALUES (
      NEW.id,
      'jwt_sync',
      NULL,
      NEW.id,
      NULL,
      jsonb_build_object(
        'entity_type', 'profile',
        'old_role', OLD.active_role,
        'new_role', NEW.active_role
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 3. check_role_switch_rate_limit: query by actor_user_id and meta
-- ============================================================================

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
  FROM public.audit_logs
  WHERE actor_user_id = v_user_id
    AND action = 'role_switch'
    AND created_at > NOW() - (v_window_minutes || ' minutes')::INTERVAL
    AND (meta->>'success')::BOOLEAN = true;

  RETURN v_recent_switches < v_max_switches;
END;
$$;

COMMENT ON FUNCTION switch_active_role(TEXT, TEXT) IS
'Atomically switches user role. Audit logs use public.audit_logs (actor_user_id, meta).';
