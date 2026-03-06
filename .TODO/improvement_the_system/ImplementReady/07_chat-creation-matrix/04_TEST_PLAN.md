# Test Plan: Chat Creation Matrix

## 1) Automated Tests (Supabase/Dart)

### T1: SQL Guard Logic (pgTAP or RPC Tests)

- **Goal**: Verify that the `favorites` check and `initiated_by` identity rule work.
- **Test Steps**:
  1. Authenticate as User A (Client).
  2. Attempt to `INSERT` into `conversations` with User B (Freelancer) who is **NOT** in favorites.
  3. **Expectation**: `RAISE EXCEPTION` or RLS Violation.
  4. Favorite User B.
  5. Attempt `INSERT` again.
  6. **Expectation**: Success.

### T2: Race Condition Simulation (Integration Test)

- **Goal**: Verify that the system handles simultaneous creation requests.
- **Test Steps**:
  1. Trigger two `createOrGetConversation` calls in parallel from the same client.
  2. **Expectation**: DB Unique constraint prevents duplicate rows; app handles the conflict smoothly.

## 2) Manual Verification (Production Readiness)

### M1: Task Owner Restriction

1. As a Client (User A), create a task.
2. Log in as User A.
3. Try to start a chat with yourself via the task.
4. **Expectation**: Blocked (already enforced by code, but needs verification).

### M2: Freelancer Direct DM Restriction

1. As a Freelancer, try to start a DM with a client who has not favorited you and with whom you have no task.
2. **Expectation**: "Blocked" error in UI/DB.

### M3: Reject Flow Exception

1. As a Client, reject a bid from a freelancer.
2. **Expectation**: Conversation is successfully created for the `offer_rejected` message despite the client being the initiator (exception check in guard).

## 3) Observability Verification

- Check `admin_logs` to ensure conversation creation is tracked (if implemented).
- Verify that `postgrest` logs capture the failed attempts for audit purposes.
