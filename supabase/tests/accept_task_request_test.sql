-- =============================================================================
-- Test: accept_task_request — Prevents double acceptance, validates preconditions
-- =============================================================================
--
-- Prerequisites:
--   - Supabase local DB running (supabase start)
--   - Run as service_role or superuser (pgTAP extension recommended)
--   - Tables: tasks, task_requests, profiles, system_config, admin_logs, activity_log
--
-- Execution:
--   psql $DATABASE_URL -f supabase/tests/accept_task_request_test.sql
--
-- Expected: All tests print PASS. Any FAIL indicates a regression.
-- =============================================================================

BEGIN;

-- Setup: create test users (profiles)
INSERT INTO profiles (id, full_name, active_role)
VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Test Owner', 'client'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Freelancer A', 'freelancer'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Freelancer B', 'freelancer')
ON CONFLICT (id) DO NOTHING;

-- Setup: create test task (owned by test owner)
INSERT INTO tasks (id, user_id, title, description, budget, status, type, created_at)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Test Task for Accept',
  'Test description',
  1000,
  'open',
  'tender',
  NOW()
) ON CONFLICT (id) DO UPDATE SET status = 'open', updated_at = NOW();

-- Setup: create two pending requests
INSERT INTO task_requests (id, task_id, freelancer_id, price, days, status, created_at)
VALUES
  ('cccccccc-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-000000000002', 500, 7, 'pending', NOW()),
  ('cccccccc-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000001',
   'aaaaaaaa-0000-0000-0000-000000000003', 600, 10, 'pending', NOW())
ON CONFLICT (id) DO UPDATE SET status = 'pending', updated_at = NOW();

-- =============================================================================
-- Test 1: Accept first request succeeds
-- =============================================================================
-- NOTE: This test requires auth.uid() = task owner. In local testing,
-- set role to the test owner before calling.
-- For pgTAP: SELECT set_config('request.jwt.claim.sub', 'aaaaaaaa-...', true);
DO $$
DECLARE
  v_result TEXT;
BEGIN
  -- Simulate auth context (Supabase local)
  PERFORM set_config('request.jwt.claim.sub', 'aaaaaaaa-0000-0000-0000-000000000001', true);

  SELECT accept_task_request(
    'bbbbbbbb-0000-0000-0000-000000000001'::uuid,
    'cccccccc-0000-0000-0000-000000000001'::uuid
  ) INTO v_result;

  IF v_result = 'accepted' THEN
    RAISE NOTICE 'TEST 1 PASS: First request accepted successfully (result=%)', v_result;
  ELSE
    RAISE NOTICE 'TEST 1 FAIL: Expected accepted, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 2: Second request on same task should be auto-rejected (status != pending)
-- =============================================================================
DO $$
DECLARE
  v_status TEXT;
BEGIN
  SELECT status INTO v_status
  FROM task_requests
  WHERE id = 'cccccccc-0000-0000-0000-000000000002';

  IF v_status = 'rejected' THEN
    RAISE NOTICE 'TEST 2 PASS: Second request auto-rejected (status=%)', v_status;
  ELSE
    RAISE NOTICE 'TEST 2 FAIL: Expected rejected, got %', v_status;
  END IF;
END $$;

-- =============================================================================
-- Test 3: Re-accepting an already accepted request returns 'already_accepted'
-- =============================================================================
DO $$
DECLARE
  v_result TEXT;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'aaaaaaaa-0000-0000-0000-000000000001', true);

  SELECT accept_task_request(
    'bbbbbbbb-0000-0000-0000-000000000001'::uuid,
    'cccccccc-0000-0000-0000-000000000001'::uuid
  ) INTO v_result;

  IF v_result = 'already_accepted' THEN
    RAISE NOTICE 'TEST 3 PASS: Double-accept returns already_accepted (result=%)', v_result;
  ELSE
    RAISE NOTICE 'TEST 3 FAIL: Expected already_accepted, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 4: Task status changed to assigned after acceptance
-- =============================================================================
DO $$
DECLARE
  v_status TEXT;
BEGIN
  SELECT status INTO v_status
  FROM tasks
  WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001';

  IF v_status = 'assigned' THEN
    RAISE NOTICE 'TEST 4 PASS: Task status changed to assigned';
  ELSE
    RAISE NOTICE 'TEST 4 FAIL: Expected assigned, got %', v_status;
  END IF;
END $$;

-- Cleanup
ROLLBACK;
