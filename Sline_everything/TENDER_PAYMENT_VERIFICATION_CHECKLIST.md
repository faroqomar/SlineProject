# Task Tender Payment Flow - Verification Checklist

## Overview
This document provides a comprehensive verification checklist for testing the new two-step "Award → Payment" flow for task tenders.

## Implementation Summary

### Database Changes Applied
- ✅ Added `awarded_at`, `payment_deadline`, `awarded_by` columns to `task_requests`
- ✅ Created `award_task_offer` RPC (awards without payment)
- ✅ Created `pay_awarded_offer` RPC (completes payment + activates work)
- ✅ Created `get_client_awarded_unpaid_offers` RPC (for client "Pay Now" UI)
- ✅ Created `get_freelancer_awarded_unpaid_offers` RPC (for freelancer "Waiting" UI)
- ✅ Created `cleanup_expired_awards` RPC (cron job for expired awards)
- ✅ Added indexes for efficient queries

### Code Changes Implemented
- ✅ `TaskService.awardOffer()` - Awards offer without payment
- ✅ `TaskService.payAwardedOffer()` - Completes payment + creates escrow
- ✅ `TaskService.getClientAwardedUnpaidOffers()` - For dashboard integration
- ✅ `TaskService.getFreelancerAwardedUnpaidOffers()` - For dashboard integration
- ✅ `TaskRequestsViewModel.award()` - Two-step award flow step 1
- ✅ `TaskRequestsViewModel.payForAwardedOffer()` - Two-step award flow step 2
- ✅ `TenderPaymentScreen` - Complete payment UI with QiCard integration
- ✅ `RequestsListScreen` - Updated with award dialog and payment flow
- ✅ `RequestTile` - Updated to show "Award" button with loading state
- ✅ `DashboardRepository` - Added RPC methods for dashboard integration

---

## End-to-End Test Scenarios

### Scenario 1: Client Awards Freelancer → Completes Payment

**Prerequisites:**
- [ ] Client account with active tender task
- [ ] Freelancer has submitted an offer on the task
- [ ] QiCard payment credentials configured

**Test Steps:**
1. [ ] Client opens task with pending offers
2. [ ] Client taps "Award" button on an offer
3. [ ] Award confirmation dialog shows:
   - [ ] Freelancer name
   - [ ] Price
   - [ ] Delivery time
   - [ ] Warning: "24 hours to complete payment"
4. [ ] Client confirms award
5. [ ] Client is navigated to `TenderPaymentScreen`:
   - [ ] Shows "Payment Required" warning with countdown
   - [ ] Shows order summary (task, freelancer, amount)
   - [ ] Shows QiCard as payment method
   - [ ] Shows "Pay" and "Pay Later" buttons
6. [ ] Client taps "Pay" button
7. [ ] QiCard WebView opens
8. [ ] Client completes payment in QiCard
9. [ ] Client returns to app with success
10. [ ] App calls `pay_awarded_offer` RPC
11. [ ] Success message shown: "Payment successful! Work is now active."
12. [ ] Client is navigated to dashboard

**Expected Database State:**
- [ ] `task_requests.status` = 'accepted'
- [ ] `task_requests.payment_status` = 'held'
- [ ] `task_requests.awarded_at` is set
- [ ] `task_requests.payment_deadline` is null (completed)
- [ ] `tasks.status` = 'in_progress'
- [ ] `tasks.assigned_freelancer_id` = freelancer_id
- [ ] Ledger entry created for escrow hold

**Expected Notifications:**
- [ ] Freelancer receives: "Payment confirmed - Start working!"

---

### Scenario 2: Client Awards → Pays Later (Within 24h)

**Prerequisites:**
- [ ] Client has awarded an offer (Scenario 1 steps 1-5)
- [ ] Client tapped "Pay Later" instead of completing payment

**Test Steps:**
1. [ ] Client is back at task/offers screen
2. [ ] Client sees awarded offer with "Pay Now" button (if implemented in dashboard)
3. [ ] OR Client goes to Dashboard → "Pending Payment" section
4. [ ] Client sees awarded tender with countdown timer
5. [ ] Client taps "Pay Now"
6. [ ] `TenderPaymentScreen` opens with remaining time
7. [ ] Client completes payment (QiCard flow)
8. [ ] Payment succeeds, work activated

**Expected:** Same as Scenario 1

---

### Scenario 3: Award Expires (Payment Deadline Passed)

**Prerequisites:**
- [ ] Client has awarded an offer
- [ ] 24 hours have passed without payment

**Test Steps (Manual Trigger):**
1. [ ] Call `cleanup_expired_awards()` RPC manually or wait for cron
2. [ ] Check offer status

**Expected Database State:**
- [ ] `task_requests.status` = 'rejected'
- [ ] `task_requests.payment_status` = 'unpaid'
- [ ] `task_requests.awarded_at` = null
- [ ] `task_requests.payment_deadline` = null
- [ ] `tasks.status` = 'open'
- [ ] `tasks.assigned_freelancer_id` = null

**Expected Notifications:**
- [ ] Freelancer receives: "Award expired - Client did not pay"

---

### Scenario 4: Freelancer View - Awarded Awaiting Payment

**Prerequisites:**
- [ ] Client has awarded freelancer's offer (Scenario 1 steps 1-5, but didn't complete payment)

**Test Steps:**
1. [ ] Freelancer opens Dashboard
2. [ ] Freelancer sees "Pending Work" or "Next Actions" section
3. [ ] Freelancer sees awarded tender with status:
   - [ ] "Awarded - Waiting for Payment"
   - [ ] Countdown showing time remaining
   - [ ] Client name and price
4. [ ] Freelancer taps to see details
5. [ ] Screen shows: "Client has awarded you. Waiting for payment."

---

### Scenario 5: Freelancer View - Work Active After Payment

**Prerequisites:**
- [ ] Client has completed payment (Scenario 1 completed)

**Test Steps:**
1. [ ] Freelancer receives push notification: "Payment confirmed - Start working!"
2. [ ] Freelancer opens Dashboard
3. [ ] Freelancer sees tender moved to "Active Work" section
4. [ ] Tender shows status: "In Progress"
5. [ ] Freelancer can start working on the task

---

### Scenario 6: Error Handling - Payment Failure

**Test Steps:**
1. [ ] Client awards an offer
2. [ ] Client attempts to pay
3. [ ] QiCard returns error or user cancels
4. [ ] App shows error message
5. [ ] Offer remains in "awarded/unpaid" state
6. [ ] Client can retry payment

**Expected:**
- [ ] Error message displayed
- [ ] Offer status unchanged (still awarded/unpaid)
- [ ] Countdown continues

---

## API/RPC Test Checklist

### Database RPC Tests

Run these SQL queries to verify RPC functions work:

```sql
-- Test 1: Award an offer (as client)
SELECT award_task_offer('REQUEST_UUID_HERE');

-- Expected: success=true, payment_deadline set 24h from now

-- Test 2: Get client's awarded unpaid offers
SELECT * FROM get_client_awarded_unpaid_offers();

-- Expected: List includes the awarded offer with deadline

-- Test 3: Get freelancer's awarded unpaid offers
SELECT * FROM get_freelancer_awarded_unpaid_offers();

-- Expected: List includes offers where freelancer was awarded

-- Test 4: Pay for awarded offer
SELECT pay_awarded_offer('REQUEST_UUID_HERE');

-- Expected: success=true, payment_status='held', task='in_progress'

-- Test 5: Cleanup expired awards (test with manual deadline)
SELECT cleanup_expired_awards();

-- Expected: Expired offers rejected, tasks reverted to open
```

### Dart Service Tests

```dart
// Test TaskService methods
final taskService = TaskService();

// 1. Award offer
final awardResult = await taskService.awardOffer(requestId);
assert(awardResult['success'] == true);
assert(awardResult['payment_deadline'] != null);

// 2. Get client offers
final clientOffers = await taskService.getClientAwardedUnpaidOffers();
assert(clientOffers.isNotEmpty);

// 3. Pay for awarded offer
final payResult = await taskService.payAwardedOffer(requestId);
assert(payResult['success'] == true);
assert(payResult['payment_status'] == 'held');

// 4. Get freelancer offers
final freelancerOffers = await taskService.getFreelancerAwardedUnpaidOffers();
// Should be empty after payment
```

---

## UI Component Checklist

### TenderPaymentScreen

- [ ] Deadline countdown displays correctly (hours/minutes)
- [ ] Countdown turns red when < 1 hour remaining
- [ ] Shows "Expired" message when deadline passed
- [ ] Order summary shows correct information:
  - [ ] Task title
  - [ ] Freelancer name
  - [ ] Price formatted correctly (IQD)
- [ ] Payment method section shows QiCard
- [ ] "Pay" button initiates QiCard flow
- [ ] Loading indicator shows during payment
- [ ] Error message displays on failure
- [ ] "Pay Later" button returns to previous screen
- [ ] Success navigation works correctly

### RequestsListScreen (Client View)

- [ ] "Award" button visible for pending offers (owner only)
- [ ] Award dialog shows:
  - [ ] Freelancer name
  - [ ] Price
  - [ ] Delivery time
  - [ ] Warning about payment deadline
- [ ] Award button shows loading state while processing
- [ ] On success, navigates to TenderPaymentScreen
- [ ] Error snackbar shown on failure
- [ ] Awarded offers show "Awarded" badge

### RequestTile

- [ ] Shows correct status label
- [ ] Shows loading indicator when isLoading=true
- [ ] "Award" button uses green color
- [ ] "Reject" button uses red color
- [ ] "Awarded" badge shown for accepted offers
- [ ] Add to favorites button works for non-owners

---

## Integration Test: Full Tender Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     FULL TENDER FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. CLIENT creates tender task                                  │
│     ↓                                                           │
│  2. FREELANCER submits offer                                    │
│     ↓                                                           │
│  3. CLIENT opens offers list                                    │
│     ↓                                                           │
│  4. CLIENT taps "Award" on offer                                │
│     ↓                                                           │
│  5. CLIENT sees award confirmation dialog                       │
│     ↓                                                           │
│  6. CLIENT confirms → App calls award_task_offer RPC            │
│     ↓                                                           │
│     • task_requests: status='accepted', payment_status='unpaid'
│     • tasks: status='assigned', assigned_freelancer_id set      │
│     • Notifications sent to both parties                        │
│     ↓                                                           │
│  7. CLIENT navigated to TenderPaymentScreen                     │
│     ↓                                                           │
│  8. CLIENT sees deadline countdown + order summary              │
│     ↓                                                           │
│  9. CLIENT taps "Pay"                                             │
│     ↓                                                           │
│  10. App initiates QiCard payment                               │
│     ↓                                                           │
│  11. WebView opens with QiCard form                             │
│     ↓                                                           │
│  12. CLIENT completes payment in QiCard                         │
│     ↓                                                           │
│  13. QiCard redirects back to app with success                  │
│     ↓                                                           │
│  14. App calls pay_awarded_offer RPC                            │
│     ↓                                                           │
│     • task_requests: payment_status='held'                      │
│     • tasks: status='in_progress'                               │
│     • Ledger entry created for escrow                           │
│     • Notification sent to freelancer                             │
│     ↓                                                           │
│  15. App shows success message                                    │
│     ↓                                                           │
│  16. FREELANCER sees "Work Active" notification                 │
│     ↓                                                           │
│  17. FREELANCER can start working on task                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Regression Tests (Ensure Bookings Still Work)

- [ ] Booking flow works end-to-end
- [ ] Payment checkout screen functions correctly
- [ ] QiCard payment for bookings succeeds
- [ ] WebView handles redirects correctly
- [ ] No "disposed EngineFlutterView" errors
- [ ] Booking cancellation works

---

## Known Issues & Notes

### Phase 1-6 Complete ✅

All core functionality has been implemented:

1. ✅ Database schema with award tracking
2. ✅ Award RPC (separate from payment)
3. ✅ Pay RPC (complete payment + activate)
4. ✅ Query RPCs for dashboard
5. ✅ Cleanup RPC for expired awards
6. ✅ Dart service layer methods
7. ✅ ViewModel methods for two-step flow
8. ✅ TenderPaymentScreen UI
9. ✅ Request list integration
10. ✅ Dashboard repository integration

### Next Steps (After Testing)

1. **Dashboard UI Integration** - Add "Pending Payment" cards to client and freelancer dashboards
2. **Push Notifications** - Ensure all notification types work (offer_awarded, payment_required, work_active, award_expired)
3. **Cron Job Setup** - Schedule `cleanup_expired_awards` to run every hour
4. **Analytics** - Track tender award/payment funnel metrics

### Testing Credentials

**QiCard Test (Sandbox):**
- Terminal ID: `237984`
- Username: `paymentgatewaytest`
- Password: `WHaNFE5C3qlChqNbAzH4`
- Card Number: `4111111111111111`
- Expiry: `12/25`
- CVV: `123`

---

## Sign-off

| Role | Name | Date | Status |
|------|------|------|--------|
| Developer | - | - | ✅ Implemented |
| QA Tester | - | - | ⬜ Pending |
| Product Owner | - | - | ⬜ Pending |

---

## Appendix: Database State Transitions

### Task Request State Machine

```
┌──────────┐    Award      ┌─────────────┐    Pay       ┌─────────┐
│ PENDING  │ ────────────► │ ACCEPTED    │ ───────────► │  HELD   │
│          │               │ (unpaid)      │              │         │
└──────────┘               └─────────────┘              └─────────┘
                                  │
                                  │ 24h Expired
                                  ▼
                           ┌─────────────┐
                           │  REJECTED   │
                           └─────────────┘
```

### Task State Machine

```
┌────────┐   Award    ┌──────────┐   Pay    ┌───────────┐
│  OPEN  │ ─────────► │ ASSIGNED │ ───────► │ IN_PROGRESS│
└────────┘            └──────────┘          └───────────┘
                           │
                           │ Expired
                           ▼
                      ┌────────┐
                      │  OPEN  │
                      └────────┘
```

---

*Document Version: 1.0*
*Last Updated: 2026-02-26*
