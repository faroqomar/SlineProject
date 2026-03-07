# Task Request Bid Flow - E2E Manual Testing Script

**Document Version**: 1.0  
**Created**: 2026-03-07  
**Status**: Phase 4.3 Complete  
**Related**: `API_CONTRACT.md`, `THREAT_MODEL.md`, `RLS_CHECK_MATRIX.md`

---

## 1. Test Environment Setup

### 1.1 Required Test Accounts

| Account Type | Role | Purpose |
|--------------|------|---------|
| `client@test.com` | Client | Task owner who receives and manages bids |
| `freelancer1@test.com` | Freelancer | Primary bidder for testing |
| `freelancer2@test.com` | Freelancer | Secondary bidder for race condition tests |

**Setup Steps**:
1. Create 3 test accounts in Supabase Auth (or use existing)
2. Ensure `active_role` is set correctly for each user
3. Verify profiles exist with `full_name` and `avatar_url` populated

### 1.2 Required Test Task

**Task Requirements**:
- Status: `open`
- Type: `tender`
- Owner: `client@test.com`
- Title: "E2E Test Task - Plumbing Repair"
- Description: "Test task for bid flow validation"
- Budget: $500

**SQL to Create Test Task** (if needed):
```sql
INSERT INTO tasks (
  id, owner_id, title, description, price, 
  status, task_type, created_at
) VALUES (
  gen_random_uuid(),
  (SELECT id FROM auth.users WHERE email = 'client@test.com'),
  'E2E Test Task - Plumbing Repair',
  'Test task for bid flow validation',
  500,
  'open',
  'tender',
  now()
) RETURNING id;
```

### 1.3 Required Tools & Access

| Tool | Purpose | Location |
|------|---------|----------|
| Flutter Dev Build | App under test | `flutter run` |
| Supabase Dashboard | Verify DB state | https://app.supabase.io |
| AppLogger Output | Verify logging | Android Studio / Xcode console |
| Two Devices (optional) | Realtime update tests | Physical devices or emulators |

### 1.4 Pre-Test Checklist

- [ ] All 3 test accounts can log in successfully
- [ ] Test task appears in dashboard for freelancers
- [ ] Supabase realtime is enabled and working
- [ ] AppLogger is configured (check `lib/core/services/logger_service.dart`)
- [ ] QiCard payment simulation mode enabled (for dev builds)

---

## 2. Test Scenarios

### Scenario 1: Freelancer Submit Bid

**Objective**: Verify freelancer can submit a new bid on an open task.

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 1.1 | Login as `freelancer1@test.com` | Dashboard loads, role=freelancer | Profile shows freelancer badge |
| 1.2 | Navigate to "Browse Tasks" | List of open tasks displayed | Test task visible in list |
| 1.3 | Tap on test task | Task details screen opens | Task title and budget displayed |
| 1.4 | Tap "Submit Bid" button | Submit bid sheet opens | Price, days, note fields visible |
| 1.5 | Enter price: $450 | Price field shows "450" | Validation allows values < budget |
| 1.6 | Enter days: 3 | Days field shows "3" | Minimum 1 day enforced |
| 1.7 | Enter note: "I can start immediately" | Note field populated | Character limit: 500 chars |
| 1.8 | Tap "Submit" button | Loading indicator shown | `_isSubmitting=true` (check AppLogger) |
| 1.9 | Wait for submission | Success toast/message shown | `Offer submitted successfully` |
| 1.10 | Return to task view | Bid appears in bid list | Bid shows price $450, 3 days |
| 1.11 | Verify countdown | 24h countdown timer visible | Countdown shows remaining time |

**AppLogger Verification**:
```
[TaskRequests] Submitting offer for task <task_id>
[TaskRequests] Optimistic offer added to UI: optimistic-<timestamp>
[TaskRequests] Optimistic offer replaced with server response: <request_id>
[TaskRequests] Offer submitted successfully: <request_id> for task <task_id>
[TaskRequests] Submit operation completed, flag cleared
```

**Pass Criteria**:
- [ ] Bid appears in list within 3 seconds
- [ ] Countdown timer starts at ~24:00:00
- [ ] No error messages displayed
- [ ] `_isSubmitting` flag properly managed (check via AppLogger)

**Fail Criteria**:
- [ ] Bid doesn't appear after 5 seconds
- [ ] Double submission allowed (rate limiting not working)
- [ ] Error message shown to user
- [ ] Optimistic update not rolled back on error

---

### Scenario 2: Owner Accept Bid

**Objective**: Verify task owner can accept a pending bid (two-step award flow).

**Precondition**: Scenario 1 completed, bid exists with status=`pending`

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 2.1 | Login as `client@test.com` | Dashboard loads, role=client | Owner view shown |
| 2.2 | Navigate to "My Tasks" | Task list displayed | Test task visible |
| 2.3 | Tap on test task | Task details opens | Bids/offers section visible |
| 2.4 | Tap "View Offers" | Offers list screen opens | Freelancer1's $450 bid displayed |
| 2.5 | Tap "Award" on bid | Confirmation dialog shown | Dialog shows price and freelancer name |
| 2.6 | Verify price displayed | Shows $450.00 | Price matches bid |
| 2.7 | Tap "Confirm Award" | Loading state, `_isAwarding=true` | Button disabled, spinner shown |
| 2.8 | Wait for award | Award success, status changed | Bid status shows "Accepted - Pending Payment" |
| 2.9 | Verify payment screen | Payment screen opens automatically | QiCard payment form displayed |
| 2.10 | Check Supabase | Query task_requests table | Status=`accepted`, payment_status=`unpaid` |

**AppLogger Verification**:
```
[TaskRequests] Starting award flow for request <request_id>
[TaskRequests] Award completed successfully for request <request_id>
[TaskService] Award offer called for request <request_id>
```

**Pass Criteria**:
- [ ] Award confirmation dialog displayed price correctly
- [ ] Payment screen opened automatically after award
- [ ] Bid status changed to `accepted`
- [ ] `payment_deadline` set (typically 24h from award)

**Fail Criteria**:
- [ ] Price mismatch error (bid changed during action)
- [ ] Double acceptance allowed (race condition)
- [ ] Unauthorized user could accept

---

### Scenario 3: Complete Payment

**Objective**: Verify payment flow creates escrow and activates task.

**Precondition**: Scenario 2 completed, bid status=`accepted`, payment_status=`unpaid`

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 3.1 | On payment screen | QiCard payment form visible | Card fields, amount displayed |
| 3.2 | Verify amount shown | Shows $450.00 + platform fee | Total includes fee calculation |
| 3.3 | Enter test card details | Card fields populated | Test mode card: 4111 1111 1111 1111 |
| 3.4 | Tap "Pay Now" | Payment processing | Loading indicator shown |
| 3.5 | Wait for confirmation | Success message shown | "Payment successful" toast |
| 3.6 | Verify redirect | Redirected to task details | Task status now "In Progress" |
| 3.7 | Check Supabase | Query task_requests | payment_status=`held` |
| 3.8 | Check tasks table | Query tasks table | status=`in_progress`, freelancer_id set |
| 3.9 | Verify notifications | Check notifications table | `work_active` sent to freelancer |

**AppLogger Verification**:
```
[TaskRequests] Starting payment flow for request <request_id>
[TaskRequests] Payment completed successfully for request <request_id>
[TaskService] Payment processed: held status confirmed
```

**Pass Criteria**:
- [ ] Payment completed without errors
- [ ] `payment_status` changed to `held`
- [ ] Task status changed to `in_progress`
- [ ] Freelancer assigned to task

**Fail Criteria**:
- [ ] Payment failed without error message
- [ ] Double payment allowed
- [ ] Task status not updated after payment

---

### Scenario 4: Replace Bid

**Objective**: Verify freelancer can replace their pending bid with new terms.

**Precondition**: Fresh task, no bids yet

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 4.1 | Login as `freelancer1@test.com` | Dashboard loads | Freelancer view shown |
| 4.2 | Navigate to test task | Task details open | "Submit Bid" button visible |
| 4.3 | Submit initial bid: $400, 5 days | Bid submitted successfully | Bid appears in list |
| 4.4 | Wait 2+ seconds | Rate limit debounce period passed | `_lastSubmitAttempt` old enough |
| 4.5 | Tap "Replace Bid" | Replace bid sheet opens | Current values pre-filled ($400, 5 days) |
| 4.6 | Change price to $380 | Price field updated | Validation passes |
| 4.7 | Change days to 4 | Days field updated | Validation passes |
| 4.8 | Tap "Replace" | Confirmation dialog shown | Explains old bid will be archived |
| 4.9 | Confirm replace | Loading state, then success | New bid appears with $380, 4 days |
| 4.10 | Verify old bid archived | Check Supabase | Old bid status=`withdrawn` |
| 4.11 | Check Supabase new bid | Query task_requests | New bid status=`pending`, new ID |

**AppLogger Verification**:
```
[Offers] Replacing offer for task <task_id>
[Offers] Offer replaced: <new_request_id>
[TaskRequests] Loaded <N> initial items (includes new bid)
```

**Pass Criteria**:
- [ ] Old bid archived (status=`withdrawn`)
- [ ] New bid created with new ID
- [ ] New bid shows updated terms
- [ ] Only one active bid per freelancer

**Fail Criteria**:
- [ ] Old bid still shows as pending
- [ ] Two active bids for same freelancer
- [ ] Rate limiting bypassed

---

### Scenario 5: Owner Reject Bid

**Objective**: Verify owner can reject a bid and chat is created for feedback.

**Precondition**: Fresh task with pending bid from freelancer1

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 5.1 | Login as `client@test.com` | Dashboard loads | Owner view shown |
| 5.2 | Navigate to test task offers | Offers list visible | Freelancer1's bid displayed |
| 5.3 | Tap "Reject" on bid | Confirmation dialog shown | Warning about rejection |
| 5.4 | Tap "Confirm" | Loading state, `_isRejecting=true` | Button disabled |
| 5.5 | Wait for rejection | Bid status changes to "Rejected" | Visual indicator (red badge) |
| 5.6 | Tap "Chat" on rejected bid | Chat screen opens | Pre-filled with offer context |
| 5.7 | Send message "Price too high" | Message sent successfully | Message appears in chat |
| 5.8 | Check Supabase | Query conversations | Task-linked conversation created |
| 5.9 | Check notifications | Query notifications | `offer_rejected` sent to freelancer |

**AppLogger Verification**:
```
[TaskRequests] Starting reject flow for request <request_id>
[TaskRequests] Request <request_id> rejected successfully
[TaskRequests] Reject operation completed, flag cleared
```

**Pass Criteria**:
- [ ] Bid status changed to `rejected`
- [ ] Task-linked chat created automatically
- [ ] Notification sent to freelancer
- [ ] Chat accessible from rejected bid

**Fail Criteria**:
- [ ] Non-owner could reject bid
- [ ] Chat not created
- [ ] Bid not visible after rejection

---

### Scenario 6: Bid Expiration

**Objective**: Verify 24-hour bid expiration works correctly.

**Precondition**: Ability to manipulate timestamps or wait for expiration

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 6.1 | Submit new bid (freelancer1) | Bid created with status=pending | Note exact creation time |
| 6.2 | Check countdown | Shows ~24:00:00 remaining | `expirationTime` = created_at + 24h |
| 6.3 | **Option A: Wait 24h** | Real-world expiration test | Not recommended for manual testing |
| 6.4 | **Option B: DB manipulation** | Update created_at timestamp | SQL: `UPDATE task_requests SET created_at = now() - interval '25 hours'` |
| 6.5 | Refresh task view | Bid shows "Expired" status | Visual indicator (grey badge) |
| 6.6 | Verify actions blocked | Award/Reject buttons disabled | Cannot act on expired bid |
| 6.7 | Check `isExpired` getter | Returns `true` | Model method works correctly |
| 6.8 | Check Supabase (cron) | `process_expired_requests()` | Expired bids processed |

**AppLogger Verification**:
```
[Offers] Bid <bid_id> created at <timestamp>, expires at <expiration_time>
[TaskRequests] Loaded <N> items (expired bid marked)
```

**Pass Criteria**:
- [ ] Expired bid shows "Expired" status
- [ ] Action buttons disabled for expired bids
- [ ] `isExpired` getter returns true
- [ ] Cron job processes expired bids

**Fail Criteria**:
- [ ] Actions allowed on expired bid
- [ ] Countdown shows negative time
- [ ] No visual indication of expiration

---

### Scenario 7: Realtime Updates

**Objective**: Verify bid status changes propagate in real-time across sessions.

**Setup**: Two devices or two browser tabs

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 7.1 | **Device A**: Login freelancer1 | Task list displayed | - |
| 7.2 | **Device A**: Open test task | Bid list visible | Submit new bid |
| 7.3 | **Device B**: Login client | Task list displayed | - |
| 7.4 | **Device B**: Open same task | Bid list visible | Freelancer1's bid shown |
| 7.5 | **Device A**: Keep screen open | Watching bid list | Note current bid status |
| 7.6 | **Device B**: Award the bid | Award flow completed | Bid status now `accepted` |
| 7.7 | **Device A**: Observe within 5s | Bid status auto-updates | Changes from pending → accepted |
| 7.8 | Check no manual refresh | Did not pull-to-refresh | Update came via Supabase realtime |
| 7.9 | Verify notification | In-app notification shown | "Your bid was accepted" |

**AppLogger Verification (Device A)**:
```
[SupabaseRealtime] Received change event for task_requests
[TaskRequests] Realtime event received, reloading...
[TaskRequests] Loaded <N> initial items
```

**Pass Criteria**:
- [ ] Status update visible within 5 seconds
- [ ] No manual refresh required
- [ ] UI reflects new status correctly
- [ ] Notification received

**Fail Criteria**:
- [ ] Update requires manual refresh
- [ ] Delay > 10 seconds
- [ ] UI shows stale data

---

### Scenario 8: Error Recovery - Payment Failure

**Objective**: Verify graceful handling of payment failures with retry option.

**Precondition**: Bid awarded but not yet paid

| Step | Action | Expected Result | Verification |
|------|--------|-----------------|--------------|
| 8.1 | Award bid (Scenario 2) | Awarded status, pending payment | Payment screen ready |
| 8.2 | Simulate payment failure | Use invalid card or network error | Payment declined |
| 8.3 | Observe error handling | Error message shown | "Payment failed. Please try again." |
| 8.4 | Verify task state unchanged | Check Supabase | Task still `assigned`, bid still `accepted/unpaid` |
| 8.5 | Tap "Retry Payment" | Payment screen reopens | Form reset, ready for retry |
| 8.6 | Complete payment successfully | Payment succeeds | Status changes to `in_progress` |
| 8.7 | Verify success flow | Task activated | Freelancer can now begin work |

**AppLogger Verification**:
```
[TaskRequests] Starting payment flow for request <request_id>
[TaskRequests] Failed to pay for awarded offer <request_id>: <error>
[TaskRequests] Error state cleared by user
[TaskRequests] Starting payment flow for request <request_id>
[TaskRequests] Payment completed successfully for request <request_id>
```

**Pass Criteria**:
- [ ] Clear error message on failure
- [ ] State unchanged after failure
- [ ] Retry option available
- [ ] Success after retry

**Fail Criteria**:
- [ ] Silent failure (no error shown)
- [ ] State corruption after failure
- [ ] No retry option

---

## 3. Edge Cases

### Edge Case 1: Double-Click Submit (Rate Limiting)

**Test**: Rapidly tap "Submit Bid" multiple times

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Submit Bid" | First submission processes |
| 2 | Within 2 seconds, tap again | Second submission blocked |
| 3 | Observe error message | "Please wait X seconds before submitting another offer" |
| 4 | Check Supabase | Only one bid created |
| 5 | Wait 2+ seconds | Rate limit clears |
| 6 | Tap again | New submission allowed |

**Pass**: Rate limiting prevents duplicate submissions, user gets clear message.
**Fail**: Multiple bids created, or no feedback to user.

---

### Edge Case 2: Network Failure During Payment

**Test**: Disconnect network during payment processing

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Start payment flow | Payment form ready |
| 2 | Enter card details | Fields populated |
| 3 | Tap "Pay Now" | Processing starts |
| 4 | Disconnect WiFi/Data | Network lost |
| 5 | Observe behavior | Timeout error shown after ~30s |
| 6 | Reconnect network | Connection restored |
| 7 | Tap "Retry" | Payment retries successfully |

**Pass**: Graceful timeout, clear error, successful retry.
**Fail**: App crash, silent failure, or stuck loading state.

---

### Edge Case 3: Rapid Accept/Reject (Race Condition)

**Test**: Two owners try to accept different bids simultaneously

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Two clients open same task | Both see pending bids |
| 2 | Client A taps "Award" on Bid 1 | Processing starts |
| 3 | Within 2s, Client B taps "Award" on Bid 2 | Blocked or fails |
| 4 | Observe result | Only one bid accepted, other gets error |
| 5 | Check Supabase | Task has exactly one `accepted` bid |
| 6 | Check other bids | All other bids `rejected` |

**Pass**: Only one acceptance succeeds, database remains consistent.
**Fail**: Both bids accepted (data corruption), or unclear error messages.

---

### Edge Case 4: Expired Bid Actions (Should Be Blocked)

**Test**: Try to accept/reject an expired bid

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create bid, artificially age it | Set created_at = now() - 25h |
| 2 | Open task as owner | Bid shows "Expired" |
| 3 | Attempt to tap "Award" | Button disabled or error shown |
| 4 | Attempt to tap "Reject" | Button disabled or error shown |
| 5 | Check Supabase | Bid status unchanged (still `pending` or processed by cron) |

**Pass**: Actions blocked on expired bids, clear visual indication.
**Fail**: Actions allowed, or no visual indication of expiration.

---

### Edge Case 5: Price Mismatch During Award

**Test**: Bid changes between view and award

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Owner views bid at $400 | Price displayed: $400.00 |
| 2 | Freelancer updates bid to $450 | New price in database |
| 3 | Owner taps "Award" without refreshing | Price mismatch error |
| 4 | Observe error dialog | "Freelancer updated offer from $400 to $450" |
| 5 | Tap "Refresh" | List reloads with new price |
| 6 | Tap "Award" again | Success with correct price |

**Pass**: Price mismatch detected, clear error, graceful recovery.
**Fail**: Award succeeds with wrong price, or no error shown.

---

### Edge Case 6: Unauthorized Access Attempts

**Test**: Non-owner tries to accept/reject bids

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as freelancer2 | Freelancer view |
| 2 | Navigate to task owned by client1 | Task details visible |
| 3 | Attempt to view offers | Empty list or 403 error |
| 4 | Attempt direct API call | 401/403 unauthorized |
| 5 | Check RLS | Policy correctly enforced |

**Pass**: Unauthorized access blocked by RLS, no data leaked.
**Fail**: Data visible to non-owner, or actions allowed.

---

## 4. Pass/Fail Criteria

### Global Pass Criteria

All scenarios must meet these minimum standards:

| Criterion | Requirement |
|-----------|-------------|
| **Functional** | All primary flows work as documented |
| **Security** | RLS policies prevent unauthorized access |
| **Performance** | Actions complete within 5 seconds (normal network) |
| **Reliability** | No crashes, no data corruption |
| **UX** | Clear error messages, loading states, success feedback |
| **Logging** | AppLogger outputs expected messages |

### Scenario-Specific Criteria

| Scenario | Pass Criteria | Fail Criteria |
|----------|---------------|---------------|
| **1. Submit Bid** | Bid created, countdown visible, rate limiting works | Bid not created, no countdown, duplicate submissions allowed |
| **2. Accept Bid** | Award flow completes, payment screen opens, status updated | Price mismatch not caught, double acceptance, no payment screen |
| **3. Payment** | Payment succeeds, escrow created, task activated | Payment fails silently, no escrow, task not activated |
| **4. Replace Bid** | Old bid archived, new bid created with new terms | Old bid still active, terms not updated |
| **5. Reject Bid** | Bid rejected, chat created, notification sent | Bid still pending, no chat, no notification |
| **6. Expiration** | Expired bids marked, actions blocked | Expired bids actionable, no visual indicator |
| **7. Realtime** | Updates propagate within 5s without refresh | Updates require manual refresh, delays > 10s |
| **8. Error Recovery** | Clear errors, state preserved, retry works | Silent failures, state corruption, no retry |

### Edge Case Pass Criteria

| Edge Case | Pass Criteria |
|-----------|---------------|
| Double-click | Rate limit enforced, clear feedback, no duplicates |
| Network failure | Graceful timeout, error message, retry succeeds |
| Race condition | Database consistency maintained, clear error for loser |
| Expired actions | Actions blocked, visual indicator present |
| Price mismatch | Mismatch detected, error shown, refresh recovers |
| Unauthorized | Access denied, no data leak, appropriate error |

---

## 5. Testing Log Template

Use this template to record test results:

```markdown
## Test Execution Log

**Date**: YYYY-MM-DD  
**Tester**: Name  
**Build**: Version/Commit  
**Environment**: Dev/Staging

### Scenario Results

| Scenario | Status | Notes | Issues |
|----------|--------|-------|--------|
| 1. Submit Bid | ⬜ Pass / ⬜ Fail | | |
| 2. Accept Bid | ⬜ Pass / ⬜ Fail | | |
| 3. Payment | ⬜ Pass / ⬜ Fail | | |
| 4. Replace Bid | ⬜ Pass / ⬜ Fail | | |
| 5. Reject Bid | ⬜ Pass / ⬜ Fail | | |
| 6. Expiration | ⬜ Pass / ⬜ Fail | | |
| 7. Realtime | ⬜ Pass / ⬜ Fail | | |
| 8. Error Recovery | ⬜ Pass / ⬜ Fail | | |

### Edge Case Results

| Edge Case | Status | Notes |
|-----------|--------|-------|
| Double-click | ⬜ Pass / ⬜ Fail | |
| Network failure | ⬜ Pass / ⬜ Fail | |
| Race condition | ⬜ Pass / ⬜ Fail | |
| Expired actions | ⬜ Pass / ⬜ Fail | |
| Price mismatch | ⬜ Pass / ⬜ Fail | |
| Unauthorized | ⬜ Pass / ⬜ Fail | |

### Issues Found

1. **Issue**: [Description]
   - **Severity**: High/Medium/Low
   - **Steps to Reproduce**: 
   - **Expected**: 
   - **Actual**: 

### Sign-Off

- [ ] All scenarios pass
- [ ] All edge cases pass
- [ ] No critical issues
- [ ] Minor issues documented

**Tester Signature**: _______________  
**Date**: _______________
```

---

## 6. AppLogger Reference

Expected log output patterns for verification:

### Service Layer (`lib/features/tasks/services/task_requests_service.dart`)

```
[Offers] Checking existing active offer for task <task_id> and user <user_id>
[Offers] Submitting offer for task <task_id> {price: 450, days: 3, hasNote: true}
[Offers] Offer submitted: <request_id>
[Offers] Replacing offer for task <task_id>
[Offers] Offer replaced: <request_id>
[Offers] Accepting offer <request_id> with expected price: 45000 cents
[Offers] Offer accepted: <request_id>
[Offers] Rejecting offer <request_id>
[Offers] Offer rejected: <request_id>
[Offers] Rate limit triggered: <elapsed>ms since last submit
[Offers] Bid <bid_id> created at <timestamp>, expires at <expiration_time>
```

### ViewModel Layer (`lib/features/tasks/viewmodels/task_requests_view_model.dart`)

```
[TaskRequests] Loaded <N> initial items
[TaskRequests] Blocked concurrent loadInitial call
[TaskRequests] Blocked double-submit attempt for task <task_id>
[TaskRequests] Rate limited: submit attempted <ms>ms too early
[TaskRequests] Optimistic offer added to UI: <optimistic_id>
[TaskRequests] Optimistic offer replaced with server response: <request_id>
[TaskRequests] Rolled back optimistic offer due to error
[TaskRequests] Starting award flow for request <request_id>
[TaskRequests] Award completed successfully for request <request_id>
[TaskRequests] Blocked concurrent award attempt for request <request_id>
[TaskRequests] Price mismatch during award: expected <cents>, got <cents>
[TaskRequests] Starting payment flow for request <request_id>
[TaskRequests] Payment completed successfully for request <request_id>
[TaskRequests] Starting reject flow for request <request_id>
[TaskRequests] Request <request_id> rejected successfully
[TaskRequests] Error state cleared by user
[TaskRequests] Submit operation completed, flag cleared
[TaskRequests] Award operation completed, flag cleared
[TaskRequests] Reject operation completed, flag cleared
```

### Realtime Service (`lib/core/services/supabase_realtime_service.dart`)

```
[SupabaseRealtime] Subscribing to task_requests for task <task_id>
[SupabaseRealtime] Subscription established for task <task_id>
[SupabaseRealtime] Received change event for task_requests
[SupabaseRealtime] Unsubscribing from task_requests for task <task_id>
```

---

## 7. Related Documents

- `API_CONTRACT.md` - RPC function specifications
- `THREAT_MODEL.md` - Security threats and controls
- `RLS_CHECK_MATRIX.md` - RLS policy verification
- `MODEL_CONSOLIDATION_PLAN.md` - Data model documentation
- `EXECUTION_LOG_TaskRequestBidFlow.md` - Implementation status

---

**Document End**

*Verification: All 8 scenarios documented with step-by-step instructions, 6 edge cases covered, pass/fail criteria defined.*
