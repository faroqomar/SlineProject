-- =============================================================================
-- Test: switch_active_role — Optimistic locking + validation
-- =============================================================================
--
-- NOTE: The current switch_active_role RPC does NOT implement rate limiting
-- in the function itself. Rate limiting (3/minute) is enforced client-side
-- via RoleSwitchRepository. This test validates the core behavior:
-- optimistic locking, stale state detection, and invalid role rejection.
--
-- Prerequisites:
--   - Supabase local DB running (supabase start)
--   - Run with authenticated user context (set request.jwt.claim.sub)
--   - Tables: profiles, audit_logs
--
-- Execution:
--   psql $DATABASE_URL -f supabase/tests/role_switch_rate_limit_test.sql
--
-- Expected: All tests print PASS. Any FAIL indicates a regression.
-- =============================================================================

BEGIN;

-- Setup: create test user profile
INSERT INTO profiles (id, full_name, active_role)
VALUES ('ffffffff-0000-0000-0000-000000000001', 'Role Switch User', 'freelancer')
ON CONFLICT (id) DO UPDATE SET active_role = 'freelancer';

-- =============================================================================
-- Test 1: Successful role switch (freelancer → client)
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'ffffffff-0000-0000-0000-000000000001', true);

  SELECT switch_active_role('freelancer', 'client') INTO v_result;

  IF (v_result->>'success')::boolean = true AND v_result->>'new_role' = 'client' THEN
    RAISE NOTICE 'TEST 1 PASS: Role switched freelancer → client';
  ELSE
    RAISE NOTICE 'TEST 1 FAIL: Expected success=true + new_role=client, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 2: Switch back (client → freelancer) also succeeds
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'ffffffff-0000-0000-0000-000000000001', true);

  SELECT switch_active_role('client', 'freelancer') INTO v_result;

  IF (v_result->>'success')::boolean = true AND v_result->>'new_role' = 'freelancer' THEN
    RAISE NOTICE 'TEST 2 PASS: Role switched client → freelancer';
  ELSE
    RAISE NOTICE 'TEST 2 FAIL: Expected success=true + new_role=freelancer, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 3: No-op when role already set
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'ffffffff-0000-0000-0000-000000000001', true);

  SELECT switch_active_role('freelancer', 'freelancer') INTO v_result;

  IF (v_result->>'success')::boolean = true AND v_result->>'message' LIKE '%already set%' THEN
    RAISE NOTICE 'TEST 3 PASS: No-op when role already set (message=%)', v_result->>'message';
  ELSE
    RAISE NOTICE 'TEST 3 FAIL: Expected success=true with already set message, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 4: Stale state detection (expected_old_role doesn't match current)
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'ffffffff-0000-0000-0000-000000000001', true);

  -- Current role is 'freelancer', but we claim it's 'client'
  SELECT switch_active_role('client', 'freelancer') INTO v_result;

  IF (v_result->>'success')::boolean = false AND v_result->>'error' = 'stale_state' THEN
    RAISE NOTICE 'TEST 4 PASS: Stale state detected (error=%)', v_result->>'error';
  ELSE
    RAISE NOTICE 'TEST 4 FAIL: Expected stale_state error, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 5: Invalid role rejected
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'ffffffff-0000-0000-0000-000000000001', true);

  SELECT switch_active_role('freelancer', 'admin') INTO v_result;

  IF (v_result->>'success')::boolean = false AND v_result->>'error' = 'invalid_role' THEN
    RAISE NOTICE 'TEST 5 PASS: Invalid role rejected (error=%)', v_result->>'error';
  ELSE
    RAISE NOTICE 'TEST 5 FAIL: Expected invalid_role error, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 6: Audit log entry created for successful switch
-- =============================================================================
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM audit_logs
  WHERE action = 'role_switch'
    AND related_entity_id = 'ffffffff-0000-0000-0000-000000000001';

  IF v_count >= 2 THEN  -- At least 2 from tests 1 and 2
    RAISE NOTICE 'TEST 6 PASS: Audit log entries created (count=%)', v_count;
  ELSE
    RAISE NOTICE 'TEST 6 FAIL: Expected >= 2 audit entries, got %', v_count;
  END IF;
END $$;

-- Cleanup
ROLLBACK;
