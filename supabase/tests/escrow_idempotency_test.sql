-- =============================================================================
-- Test: process_gateway_escrow_booking — Idempotency + amount validation
-- =============================================================================
--
-- Prerequisites:
--   - Supabase local DB running (supabase start)
--   - Run as superuser/service_role (function requires auth.uid() = NULL)
--   - Tables: bookings, journal_entries, ledger_lines, accounts, audit_logs
--   - Account: platform_escrow must exist
--
-- Execution:
--   psql $DATABASE_URL -f supabase/tests/escrow_idempotency_test.sql
--
-- Expected: All tests print PASS. Any FAIL indicates a regression.
-- =============================================================================

BEGIN;

-- Setup: Ensure platform_escrow account exists
INSERT INTO accounts (account_code, account_type, currency)
VALUES ('platform_escrow', 'asset', 'IQD')
ON CONFLICT (account_code) DO NOTHING;

-- Setup: create test users
INSERT INTO profiles (id, full_name, active_role)
VALUES
  ('dddddddd-0000-0000-0000-000000000001', 'Escrow Client', 'client'),
  ('dddddddd-0000-0000-0000-000000000002', 'Escrow Provider', 'freelancer')
ON CONFLICT (id) DO NOTHING;

-- Setup: create test booking (pending, unpaid)
INSERT INTO bookings (id, client_id, provider_id, status, payment_status, price, created_at)
VALUES (
  'eeeeeeee-0000-0000-0000-000000000001',
  'dddddddd-0000-0000-0000-000000000001',
  'dddddddd-0000-0000-0000-000000000002',
  'pending',
  'unpaid',
  50000,
  NOW()
) ON CONFLICT (id) DO UPDATE SET status = 'pending', payment_status = 'unpaid';

-- Clear auth context (function requires system/service_role)
RESET ROLE;

-- =============================================================================
-- Test 1: First escrow hold succeeds
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT process_gateway_escrow_booking(
    p_booking_id := 'eeeeeeee-0000-0000-0000-000000000001'::uuid,
    p_amount_gross := 50000,
    p_currency := 'IQD',
    p_idempotency_key := 'test-escrow-key-001',
    p_meta := '{"psp_provider": "test"}'::jsonb
  ) INTO v_result;

  IF (v_result->>'ok')::boolean = true AND v_result->>'journal_entry_id' IS NOT NULL THEN
    RAISE NOTICE 'TEST 1 PASS: First escrow hold succeeded (journal=%)', v_result->>'journal_entry_id';
  ELSE
    RAISE NOTICE 'TEST 1 FAIL: Expected ok=true with journal_entry_id, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 2: Same idempotency key = replay (no duplicate, no error)
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT process_gateway_escrow_booking(
    p_booking_id := 'eeeeeeee-0000-0000-0000-000000000001'::uuid,
    p_amount_gross := 50000,
    p_currency := 'IQD',
    p_idempotency_key := 'test-escrow-key-001',
    p_meta := '{"psp_provider": "test"}'::jsonb
  ) INTO v_result;

  IF (v_result->>'ok')::boolean = true AND (v_result->>'replayed')::boolean = true THEN
    RAISE NOTICE 'TEST 2 PASS: Same key replayed successfully (replayed=true)';
  ELSE
    RAISE NOTICE 'TEST 2 FAIL: Expected ok=true + replayed=true, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 3: No duplicate ledger lines created
-- =============================================================================
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM journal_entries
  WHERE idempotency_key = 'test-escrow-key-001'
    AND related_entity_id = 'eeeeeeee-0000-0000-0000-000000000001';

  IF v_count = 1 THEN
    RAISE NOTICE 'TEST 3 PASS: Only 1 journal entry (no duplicate)';
  ELSE
    RAISE NOTICE 'TEST 3 FAIL: Expected 1 journal entry, got %', v_count;
  END IF;
END $$;

-- =============================================================================
-- Test 4: Missing idempotency key rejected
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  -- Reset booking for another test
  UPDATE bookings SET payment_status = 'unpaid', status = 'pending'
  WHERE id = 'eeeeeeee-0000-0000-0000-000000000001';

  SELECT process_gateway_escrow_booking(
    p_booking_id := 'eeeeeeee-0000-0000-0000-000000000001'::uuid,
    p_amount_gross := 50000,
    p_currency := 'IQD',
    p_idempotency_key := NULL
  ) INTO v_result;

  IF (v_result->>'ok')::boolean = false AND v_result->'error'->>'code' = 'ERR_MISSING_IDEMPOTENCY_KEY' THEN
    RAISE NOTICE 'TEST 4 PASS: Null idempotency key rejected correctly';
  ELSE
    RAISE NOTICE 'TEST 4 FAIL: Expected ERR_MISSING_IDEMPOTENCY_KEY, got %', v_result;
  END IF;
END $$;

-- =============================================================================
-- Test 5: Wrong currency rejected
-- =============================================================================
DO $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT process_gateway_escrow_booking(
    p_booking_id := 'eeeeeeee-0000-0000-0000-000000000001'::uuid,
    p_amount_gross := 50000,
    p_currency := 'USD',
    p_idempotency_key := 'test-escrow-key-usd'
  ) INTO v_result;

  IF (v_result->>'ok')::boolean = false AND v_result->'error'->>'code' = 'ERR_CURRENCY_MISMATCH' THEN
    RAISE NOTICE 'TEST 5 PASS: Wrong currency rejected correctly';
  ELSE
    RAISE NOTICE 'TEST 5 FAIL: Expected ERR_CURRENCY_MISMATCH, got %', v_result;
  END IF;
END $$;

-- Cleanup
ROLLBACK;
