# Task Request Bid Flow - Threat Model

**Document Version**: 1.0  
**Created**: 2026-03-07  
**Status**: Phase 0.4 Complete  

This document defines the security design, threat scenarios, and abuse cases for the Task Request (Bid/Offer) lifecycle management.

---

## Table of Contents

1. [System Boundaries](#system-boundaries)
2. [Trust Boundaries](#trust-boundaries)
3. [Threat Scenarios](#threat-scenarios)
4. [Security Controls](#security-controls)
5. [Security Tests Required](#security-tests-required)
6. [Negative Test Checklist](#negative-test-checklist)
7. [Data Flow Diagrams](#data-flow-diagrams)

---

## System Boundaries

### Data Assets

| Asset | Sensitivity | Location | Protection |
|-------|-------------|----------|------------|
| `task_requests` | High | Supabase DB | RLS + RPC |
| `tasks` | High | Supabase DB | RLS + RPC |
| `conversations` | High | Supabase DB | RLS + Guard |
| `messages` | Medium | Supabase DB | RLS |
| `notifications` | Medium | Supabase DB | RLS |
| `admin_logs` | High | Supabase DB | Service-only |
| `activity_log` | Medium | Supabase DB | RLS |

### User Roles

| Role | Capabilities | Trust Level |
|------|--------------|-------------|
| **Freelancer (Bidder)** | Submit/replace offers, view own offers, chat on awarded tasks | Standard User |
| **Client (Owner)** | Accept/reject offers, pay for awarded offers, manage task | Standard User |
| **System (Cron)** | Expire overdue awards, audit logging | Service Role |

### External Systems

| System | Interface | Trust Level |
|--------|-----------|-------------|
| **QiCard Payment Gateway** | HTTPS/API | External Untrusted |
| **Supabase Auth** | JWT/OAuth | Trusted Infrastructure |
| **pg_cron** | Internal SQL | Trusted Internal |

---

## Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT APP                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐           │
│  │  Freelancer UI   │  │   Client UI      │  │  Guest/Anon      │           │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘           │
└───────────┼─────────────────────┼─────────────────────┼─────────────────────┘
            │                     │                     │
            ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SUPABASE EDGE                                   │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │                        API Gateway (PostgREST)                    │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                     │                                      │
│                                     ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │                    SECURITY DEFINER RPC Layer                   │     │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐              │     │
│  │  │accept_task_  │ │reject_task_  │ │replace_task_ │   ...         │     │
│  │  │request()     │ │request()     │ │request()     │              │     │
│  │  └──────────────┘ └──────────────┘ └──────────────┘              │     │
│  └──────────────────────────────────────────────────────────────────┘     │
│                                     │                                      │
│                                     ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────┐     │
│  │                         RLS Policy Layer                        │     │
│  └──────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         POSTGRES DATABASE                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │task_requests│  │   tasks     │  │conversations│  │ notifications│       │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Threat Scenarios

### T1: Direct Status Manipulation

**Attack Vector**: Freelancer attempts to directly UPDATE `task_requests.status` to `'accepted'` without going through the proper RPC flow.

**Attack Steps**:
1. Attacker crafts a direct SQL UPDATE: `UPDATE task_requests SET status='accepted' WHERE id='...'`
2. Attacker bypasses UI and calls Supabase client directly
3. Attacker attempts to change their pending offer to accepted

**Impact**: 
- Unauthorized bid acceptance without payment
- Freelancer could mark their offer as accepted without client consent
- Bypasses payment flow entirely

**Current Mitigation**:
```sql
-- RLS policy blocks all direct status updates
-- No UPDATE policy exists for task_requests
-- Only RPC functions (SECURITY DEFINER) can modify status

-- Verification in accept_task_request():
IF v_task.owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to accept offers on this task';
END IF;

IF v_task.status != 'open' THEN
    RAISE EXCEPTION 'Cannot accept offers on task with status: %', v_task.status;
END IF;
```

**Required Test**: 
- [x] RLS negative test (direct UPDATE → 403)

---

### T2: Double Acceptance Race Condition

**Attack Vector**: Client clicks "Accept" on two different bids rapidly (or two different clients accept the same task simultaneously in a multi-owner scenario).

**Attack Steps**:
1. Task has two pending offers: Offer A from Freelancer 1, Offer B from Freelancer 2
2. Client (or different clients) triggers `accept_task_request()` for both offers within milliseconds
3. Both transactions start before either completes

**Impact**:
- Two freelancers both think they won the task
- Both start working, creating confusion and potential disputes
- Payment flow breaks down

**Current Mitigation**:
```sql
-- Database-level constraint (unique partial index)
CREATE UNIQUE INDEX idx_one_accepted_per_task 
ON task_requests(task_id) 
WHERE status = 'accepted';

-- RPC-level check in accept_task_request():
IF v_task.status != 'open' THEN
    RAISE EXCEPTION 'Cannot accept offers on task with status: %', v_task.status;
END IF;

-- Task status UPDATE acts as serialization point:
UPDATE tasks 
SET status = 'assigned',
    assigned_freelancer_id = v_request.freelancer_id
WHERE id = p_task_id;
```

**Required Test**:
- [x] Race condition test (concurrent accepts)

---

### T3: Work Without Escrow

**Attack Vector**: Task transitions to `in_progress` state but payment was never completed.

**Attack Steps**:
1. Attacker finds a way to bypass `pay_awarded_offer()` RPC
2. Task status moves to `in_progress` without `payment_status='held'`
3. Freelancer starts working but funds were never escrowed

**Impact**:
- Freelancer works without guaranteed payment
- Client gets work done without paying
- Platform reputation damaged

**Current Mitigation**:
```sql
-- Two-step award flow enforced by state machine:
-- Step 1: award_task_offer() → task_requests.status='accepted', payment_status='unpaid'
-- Step 2: pay_awarded_offer() → payment_status='held', task.status='in_progress'

-- State validation in pay_awarded_offer():
IF v_request.status != 'accepted' OR v_request.payment_status != 'unpaid' THEN
    RAISE EXCEPTION 'Request not found';
END IF;

-- Only after payment_status='held' does task move to 'in_progress':
UPDATE task_requests SET payment_status = 'held' WHERE id = p_request_id;
UPDATE tasks SET status = 'in_progress', freelancer_id = v_request.freelancer_id WHERE id = v_task_id;
```

**Required Test**:
- [x] State machine validation test

---

### T4: Bid Spam

**Attack Vector**: Bot or malicious user submits thousands of bids on all open tasks.

**Attack Steps**:
1. Attacker scripts rapid bid submission across all open tasks
2. Database fills with spam bids
3. Clients receive notification spam
4. Legitimate freelancers can't get noticed

**Impact**:
- Database bloat and storage costs
- Owner notification spam (email/push fatigue)
- Denial of service for legitimate bidding

**Current Mitigation**:
```sql
-- Client-side rate limiting (Flutter):
-- Debounce submit button
-- Cache validation before API call

-- Server-side: One active offer per freelancer per task
CREATE UNIQUE INDEX idx_one_active_offer_per_freelancer_task 
ON task_requests(task_id, freelancer_id) 
WHERE deleted_at IS NULL;

-- RLS policy with role verification:
CREATE POLICY task_requests_insert_freelancer_jwt
  ON task_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (
    freelancer_id = auth.uid() AND
    auth.jwt()->'app_metadata'->>'active_role' = 'freelancer'
  );

-- Note: Additional rate limiting could be added via:
-- - pg_rate_limit extension
-- - Application-level middleware
-- - Row count limits per time window
```

**Required Test**:
- [x] Rate limit test (rapid bid submission)

---

### T5: Rejection Without Feedback

**Attack Vector**: Client rejects a bid but freelancer is never notified, leaving them waiting indefinitely.

**Attack Steps**:
1. Client calls `reject_task_request()`
2. Status changes to `rejected` but notification fails
3. Freelancer still sees bid as "pending" (cached UI state)
4. Freelancer waits for response that never comes

**Impact**:
- Freelancer wastes time waiting for rejected task
- Poor user experience, platform appears unresponsive
- Freelancer may miss other opportunities

**Current Mitigation**:
```sql
-- reject_task_request() creates notification:
INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    related_entity_id,
    related_entity_type,
    is_read,
    created_at
) VALUES (
    v_request.freelancer_id,
    'offer_rejected',
    'Offer Rejected',
    format('Your offer on "%s" was rejected. A conversation has been opened for discussion.', v_task_title),
    v_request_id,
    'task_request',
    false,
    NOW()
);

-- Also creates task-linked conversation for follow-up:
-- Creates or reuses task-linked conversations
-- Inserts 'offer_rejected' message into messages table
```

**Required Test**:
- [x] Notification verification test

---

### T6: Payment Deadline Evasion

**Attack Vector**: Client tries to extend or bypass payment deadline after offer acceptance.

**Attack Steps**:
1. Client accepts offer (sets payment_deadline)
2. Deadline passes without payment
3. Client tries to call `pay_awarded_offer()` after deadline

**Impact**:
- Freelancer held in limbo beyond agreed timeframe
- Task availability delayed for other freelancers
- Platform trust erodes

**Current Mitigation**:
```sql
-- Deadline check in pay_awarded_offer():
IF v_request.payment_deadline < v_now THEN
    -- Auto-reject and revert task
    UPDATE task_requests 
    SET status = 'rejected', 
        payment_status = NULL,
        updated_at = v_now
    WHERE id = p_request_id;
    
    UPDATE tasks 
    SET status = 'open', 
        assigned_freelancer_id = NULL 
    WHERE id = v_task_id;
    
    RAISE EXCEPTION 'Payment deadline expired';
END IF;

-- Cron job auto-expires stale awards:
cleanup_expired_awards() -- runs every 10 minutes
```

**Required Test**:
- [x] Deadline expiration test

---

### T7: Unauthorized Bid Replacement

**Attack Vector**: Attacker tries to replace another freelancer's bid.

**Attack Steps**:
1. Attacker knows another freelancer's task_id and freelancer_id
2. Attacker calls `replace_task_request()` with victim's IDs
3. Victim's valid bid is withdrawn and replaced with attacker's terms

**Impact**:
- Legitimate bids removed without consent
- Client sees false information
- Fair competition compromised

**Current Mitigation**:
```sql
-- replace_task_request() verifies caller identity:
IF p_freelancer_id != auth.uid() THEN
    RAISE EXCEPTION 'only the offer owner can replace their offer';
END IF;

-- Additional role check:
IF auth.jwt()->'app_metadata'->>'active_role' != 'freelancer' THEN
    RAISE EXCEPTION 'only freelancers can replace offers';
END IF;

-- Only marks offers as withdrawn for authenticated freelancer:
UPDATE task_requests 
SET status = 'withdrawn', 
    deleted_at = NOW() 
WHERE task_id = p_task_id 
  AND freelancer_id = p_freelancer_id  -- bound to auth.uid()
  AND status = 'pending';
```

**Required Test**:
- [x] Non-bidder replace test (→ 401)

---

## Security Controls

### Control Matrix

| Threat | Control Layer | Implementation | Verification |
|--------|---------------|----------------|--------------|
| T1 Direct Status Manipulation | Database | No UPDATE policy on task_requests; only RPC can modify | RLS test |
| T2 Double Acceptance | Database | Unique index `idx_one_accepted_per_task` | Race test |
| T2 Double Acceptance | RPC | Task status check before update | Race test |
| T3 Work Without Escrow | RPC | Two-step flow: accept → pay → in_progress | State test |
| T3 Work Without Escrow | State Machine | `payment_status` must be 'held' | State test |
| T4 Bid Spam | Database | Unique constraint one offer per freelancer per task | Rate test |
| T4 Bid Spam | RLS | JWT role verification | Auth test |
| T5 Rejection Without Feedback | RPC | Notification insert on reject | Notification test |
| T5 Rejection Without Feedback | RPC | Conversation creation on reject | Integration test |
| T6 Payment Deadline | RPC | Deadline validation in pay function | Expiration test |
| T6 Payment Deadline | Cron | Auto-cleanup of expired awards | Cron test |
| T7 Unauthorized Replace | RPC | auth.uid() must match freelancer_id | Auth test |
| T7 Unauthorized Replace | RLS | JWT role verification | Role test |

### Audit Logging

| Action | Log Table | Retention |
|--------|-----------|-----------|
| `PRICE_MISMATCH_ATTEMPT` | admin_logs | 2 years |
| `OFFER_ACCEPTED` | admin_logs | 2 years |
| `AWARD_AUTO_EXPIRED` | admin_logs | 2 years |

---

## Security Tests Required

### RLS Negative Tests (Must Fail)

| Test | Expected Result | File |
|------|-----------------|------|
| Direct UPDATE on task_requests.status | 403 Forbidden | `rls/task_requests_rls_test.dart` |
| Direct DELETE on task_requests | 403 Forbidden | `rls/task_requests_rls_test.dart` |
| SELECT other's task_requests | Empty set | `rls/task_requests_rls_test.dart` |

### Race Condition Tests

| Test | Expected Result | File |
|------|-----------------|------|
| Concurrent accept on same task | One succeeds, other fails | `unit/tender/race_condition_test.dart` |
| Accept during payment processing | Proper serialization | `unit/tender/race_condition_test.dart` |

### State Machine Tests

| Test | Expected Result | File |
|------|-----------------|------|
| Accept on non-open task | Error: task not open | `unit/tender/state_machine_test.dart` |
| Pay without accept | Error: request not found | `unit/tender/state_machine_test.dart` |
| Complete without payment held | Error: invalid transition | `unit/tender/state_machine_test.dart` |
| Expire awarded offer | Task reverts to open | `unit/tender/state_machine_test.dart` |

### Rate Limit Tests

| Test | Expected Result | File |
|------|-----------------|------|
| Rapid bid submission (10x/sec) | Rate limited / throttled | `unit/tender/rate_limit_test.dart` |
| Duplicate bid on same task | 409 Conflict | `unit/tender/rate_limit_test.dart` |

### Notification Tests

| Test | Expected Result | File |
|------|-----------------|------|
| Reject creates notification | Notification row exists | `unit/tender/notification_test.dart` |
| Accept creates notification | Notification row exists | `unit/tender/notification_test.dart` |
| Award creates notification | Notification row exists | `unit/tender/notification_test.dart` |

---

## Negative Test Checklist

- [ ] Direct UPDATE on task_requests.status → 403 Forbidden
- [ ] Direct DELETE on task_requests → 403 Forbidden
- [ ] Non-owner accept → 401 Unauthorized
- [ ] Non-bidder replace → 401 Unauthorized
- [ ] Non-owner reject → 401 Unauthorized
- [ ] Rapid bid submission → Rate limited / throttled
- [ ] Accept on non-open task → Error: task not open
- [ ] Pay on expired award → Error: payment deadline expired
- [ ] Replace non-pending offer → Error: no pending offer found
- [ ] Submit bid as client role → 403 Forbidden (role check)

---

## Data Flow Diagrams

### Accept Offer Flow (Secure Path)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Client UI  │────▶│   ViewModel  │────▶│   Service    │────▶│ accept_task_ │
│ (Owner View) │     │ (Validation) │     │ (RPC Call)   │     │ request()    │
└──────────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                      │
                    ┌─────────────────────────────────────────────────┘
                    │
                    ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  activity_log│◄──│  admin_logs  │◄──│  Auth Check  │◄──│  Ownership   │
│  (dashboard)  │   │  (audit)     │   │ auth.uid()   │   │  Verify      │
└──────────────┘   └──────────────┘   └───────┬──────┘   └───────┬──────┘
                                              │                    │
                                              ▼                    ▼
                                        ┌──────────────┐   ┌──────────────┐
                                        │  task_requests│   │    tasks     │
                                        │ status='accept'│   │ status='assign'│
                                        └──────────────┘   └──────────────┘
```

### Reject Offer Flow (With Notification)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Client UI  │────▶│   ViewModel  │────▶│   Service    │────▶│ reject_task_ │
│ (Owner View) │     │ (Validation) │     │ (RPC Call)   │     │ request()    │
└──────────────┘     └──────────────┘     └──────────────┘     └──────┬───────┘
                                                                      │
                    ┌─────────────────────────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │      Auth Check       │
        │   auth.uid() = owner   │
        └───────────┬───────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌──────────────┐      ┌──────────────────┐
│task_requests │      │  conversations   │
│status='reject'│     │  (task-linked)   │
└──────────────┘      └────────┬─────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌──────────────┐      ┌──────────────────┐   ┌──────────────┐
│   messages   │      │  notifications   │   │  messages    │
│offer_rejected│      │  (to freelancer) │   │ (system msg) │
└──────────────┘      └──────────────────┘   └──────────────┘
```

---

## References

- `API_CONTRACT.md` - RPC security context and authorization patterns
- `Sline_everything/SUPABASE_SETUP.md` - RLS policies and database schema
- `supabase/migrations/20260306_tender_guardrails.sql` - Guardrail implementations
- STRIDE methodology for threat classification
- OWASP Top 10 for web application security

---

**Document End**

*Verification: All 7 threat scenarios documented with mitigations and test requirements.*
