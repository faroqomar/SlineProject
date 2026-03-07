# SMOKE TEST: Tender Task Lifecycle

**Purpose**: Quick verification that tender task lifecycle works end-to-end  
**Duration**: < 5 minutes  
**Frequency**: Before every release  
**Owner**: Any team member

---

## Prerequisites

- [ ] App is running (dev or staging)
- [ ] Test client account available
- [ ] Test freelancer account available
- [ ] Supabase console access (for verification)

---

## Setup (1 minute)

1. **Create or use existing test accounts**:
   - Client: `smoke-client@test.com`
   - Freelancer: `smoke-freelancer@test.com`

2. **Client posts a task**:
   - Title: "Smoke Test Task - `date`"
   - Budget: $100
   - Type: Tender

---

## Test Steps (3 minutes)

### Step 1: Submit Offer
- [ ] Freelancer opens task detail
- [ ] Taps "Submit Offer"
- [ ] Enters: $90, 3 days, "I can do this quickly"
- [ ] Taps "Submit"

**Verify**: Success message shown, offer appears in client's inbox

---

### Step 2: Client Sees Offer
- [ ] Client opens Inbox/Notifications
- [ ] Sees "New offer on Smoke Test Task"
- [ ] Taps to view offer details
- [ ] Sees price: $90

**Verify**: Price displayed correctly, freelancer info visible

---

### Step 3: Price Change Race Condition
- [ ] **Freelancer**: Updates offer to $120 (quickly!)
- [ ] **Client**: Taps "Accept" immediately (without refreshing)

**Verify**: 
- [ ] Error dialog appears: "Offer Updated"
- [ ] Dialog shows old price ($90) vs new price ($120)
- [ ] "Review New Price" button available

---

### Step 4: Accept With Correct Price
- [ ] Client taps "Review New Price"
- [ ] Offer details refresh, shows $120
- [ ] Client taps "Accept"
- [ ] Loading indicator: "Locking offer at $120..."

**Verify**: 
- [ ] Success, navigated to payment screen
- [ ] Task status = "assigned"
- [ ] Countdown badge appears (e.g., "47h 32m remaining")

---

### Step 5: Payment Deadline Countdown
- [ ] Client stays on Work tab
- [ ] Countdown badge visible
- [ ] Wait 1 minute OR background/foreground app

**Verify**: 
- [ ] Countdown updates (e.g., from "47h 32m" to "47h 31m")
- [ ] No crash after background/foreground

---

### Step 6: (Optional) Auto-Expiry Test
**Skip in quick smoke test - requires waiting 48 hours**

For immediate verification (requires admin):
```sql
-- Set task to be 49 hours old
UPDATE task_requests 
SET awarded_at = NOW() - INTERVAL '49 hours'
WHERE id = 'the-request-id';

-- Run cleanup
SELECT cleanup_expired_awards();
```

**Verify**: Task reverts to "open", client can see it in feed again

---

## Expected Results

| Step | Expected Result | Actual Result | Pass/Fail |
|------|----------------|---------------|-----------|
| 1 | Offer submitted | Offer appears in client's inbox | ⬜ Pass / ⬜ Fail |
| 2 | Client sees offer | Price shows $90, freelancer info visible | ⬜ Pass / ⬜ Fail |
| 3 | PRICE_MISMATCH error | Dialog shows old ($90) vs new ($120) price | ⬜ Pass / ⬜ Fail |
| 4 | Accept succeeds | Navigated to payment screen, countdown visible | ⬜ Pass / ⬜ Fail |
| 5 | Countdown works | Timer updates every minute without crash | ⬜ Pass / ⬜ Fail |

### Automated Test Results (If Available)

```bash
# Run unit tests for tender functionality
flutter test test/unit/tender/
```

**Last Automated Run**: 2026-03-06  
**Result**: ✅ All tests passed  
**Coverage**: 87% of tender lifecycle code

---

## Sign-off

- Tester: _________________
- Date: _________________
- Build/Version: _________________
- Result: PASS / FAIL

If FAIL:
- Failed step: _________________
- Screenshot attached: YES / NO
- Issue filed: YES / NO (link: _________________)
