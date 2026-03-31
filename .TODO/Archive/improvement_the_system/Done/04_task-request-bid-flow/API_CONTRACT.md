# Task Request Bid Flow - API Contract

**Document Version**: 1.0  
**Created**: 2026-03-06  
**Status**: Phase 0.2 Complete  

This document defines all RPC interfaces for the Task Request (Bid/Offer) lifecycle management.

---

## Table of Contents

1. [RPC Contracts](#rpc-contracts)
2. [Table Row Shapes](#table-row-shapes)
3. [Enum Values](#enum-values)
4. [Security Model](#security-model)

---

## RPC Contracts

### 1. accept_task_request

Accepts a pending task request/offer, transitioning it to `accepted` status and marking the task as `assigned`.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION accept_task_request(
    p_task_id UUID,
    p_request_id UUID,
    p_expected_price_cents BIGINT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Parameters:**
| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `p_task_id` | UUID | No | The task UUID that the request belongs to |
| `p_request_id` | UUID | No | The request/offer UUID to accept |
| `p_expected_price_cents` | BIGINT | Yes | Optional price validation for optimistic concurrency control. If provided and doesn't match current price, raises PRICE_MISMATCH error. |

**Return Value:**
- `TEXT` - Status string: `'accepted'` on success, `'already_accepted'` if idempotent retry

**Error Conditions:**
| Error | Condition |
|-------|-----------|
| `Request not found` | Request ID does not exist |
| `Cannot accept request with status: {status}` | Status is not `pending` |
| `Request {id} does not belong to task {id}` | Task/request mismatch |
| `Not authorized to accept offers on this task` | Caller is not task owner |
| `Cannot accept offers on task with status: {status}` | Task is not `open` |
| `PRICE_MISMATCH: Offer price changed from {expected} to {actual} cents` | Price changed since user viewed it |

**Side Effects:**
- Updates `task_requests` status to `accepted`, sets `awarded_at`, `awarded_by`, `payment_deadline`
- Locks fee rate and pre-calculates `fee_amount` and `net_amount`
- Updates `tasks` status to `assigned`, sets `assigned_freelancer_id`
- Inserts audit log entry to `admin_logs`
- Inserts activity log entry for client dashboard

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Only task owner can accept offers on their task
- **RLS**: Bypasses RLS via SECURITY DEFINER, performs explicit ownership checks

---

### 2. reject_task_request

Rejects a pending task request/offer and creates a task-linked conversation for communication.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION reject_task_request(
    p_task_id UUID,
    p_request_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Parameters:**
| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `p_task_id` | UUID | No | The task UUID that the request belongs to |
| `p_request_id` | UUID | No | The request/offer UUID to reject |

**Return Value:**
- `UUID` - The conversation ID (new or existing) for the task-linked chat

**Error Conditions:**
| Error | Condition |
|-------|-----------|
| `unauthenticated` | No active session |
| `task_not_found` | Task ID does not exist |
| `only task owner can reject` | Caller is not task owner |
| `request not found or already processed` | Request doesn't exist, not pending, or already processed |

**Side Effects:**
- Updates `task_requests` status to `rejected`, sets `updated_at`, `initiated_by`
- Creates or reuses task-linked `conversations` with `initiated_by=freelancer` (satisfies conversation guard)
- Inserts `offer_rejected` message into `messages`
- Sends notification to freelancer via `private_create_notification`

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Only task owner can reject offers on their task
- **Conversation Guard**: Sets `initiated_by=freelancer` to satisfy `conversations_before_insert_guard`

---

### 3. replace_task_request

Withdraws the freelancer's current pending offer and inserts a replacement with updated terms.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION replace_task_request(
    p_task_id UUID,
    p_freelancer_id UUID,
    p_message TEXT,
    p_price NUMERIC,
    p_days INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Parameters:**
| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `p_task_id` | UUID | No | The task UUID to bid on |
| `p_freelancer_id` | UUID | No | The freelancer UUID (must match authenticated user) |
| `p_message` | TEXT | No | Optional message/note with the offer (empty string becomes NULL) |
| `p_price` | NUMERIC | No | Proposed price amount |
| `p_days` | INTEGER | No | Proposed delivery duration in days |

**Return Value:**
- `VOID` - No return value on success

**Error Conditions:**
| Error | Condition |
|-------|-----------|
| `unauthenticated` | No active session |
| `only the offer owner can replace their offer` | p_freelancer_id doesn't match auth.uid() |
| `only freelancers can replace offers` | Caller doesn't have active_role='freelancer' |
| `task_not_found_or_not_open_or_own_task` | Task doesn't exist, not 'open' status, or caller owns the task |

**Side Effects:**
- Updates existing pending `task_requests` to `withdrawn` status for this task/freelancer
- Inserts new `task_requests` row with `pending` status

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Caller must match p_freelancer_id and have freelancer role
- **RLS**: Bypasses RLS, performs explicit role and ownership checks

---

### 4. award_task_offer

Awards an offer to a freelancer (first step of two-step award flow). Sets up payment deadline.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION award_task_offer(
    p_request_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Parameters:**
| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `p_request_id` | UUID | No | The request/offer UUID to award |
| `p_client_id` | UUID | Yes | Deprecated parameter, ignored for auth (uses auth.uid()) |

**Return Value:**
```json
{
  "success": true,
  "payment_deadline": "2026-03-07T12:00:00Z"
}
```

**Error Conditions:**
| Error | Condition |
|-------|-----------|
| `Not authenticated` | No active session |
| `Request not found` | Request doesn't exist or not pending |
| `Only task owner can award` | Caller is not task owner |
| `Task already has accepted offer` | Another offer already accepted on this task |

**Side Effects:**
- Updates `task_requests` status to `accepted`, sets `payment_status='unpaid'`, `awarded_at`, `payment_deadline`, `awarded_by`
- Updates `tasks` status to `assigned`
- Rejects all other pending offers on same task
- Sends notification to freelancer (`offer_awarded`)
- Sends notification to client (`payment_required`)

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Resolved from `auth.uid()`, ignores `p_client_id` parameter
- **RLS**: Bypasses RLS, performs explicit ownership checks

---

### 5. pay_awarded_offer

Completes payment for an awarded offer (second step of two-step award flow). Transitions to active work state.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION pay_awarded_offer(
    p_request_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Parameters:**
| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `p_request_id` | UUID | No | The request/offer UUID to pay for |
| `p_client_id` | UUID | Yes | Deprecated parameter, ignored for auth (uses auth.uid()) |

**Return Value:**
```json
{
  "success": true,
  "payment_status": "held"
}
```

**Error Conditions:**
| Error | Condition |
|-------|-----------|
| `Not authenticated` | No active session |
| `Request not found` | Request doesn't exist or not in accepted/unpaid state |
| `Payment deadline expired` | Payment deadline has passed (also marks offer expired) |
| `Only task owner can pay` | Caller is not task owner |

**Side Effects:**
- If deadline expired: Rejects offer and reverts task to `open`
- Updates `task_requests` `payment_status` to `held`
- Updates `tasks` status to `in_progress`, sets `freelancer_id` and `assigned_freelancer_id`
- Sends notification to freelancer (`work_active`)

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Resolved from `auth.uid()`, ignores `p_client_id` parameter

---

### 6. cancel_awarded_offer

Cancels an awarded but unpaid offer, reverting the task to open status.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION cancel_awarded_offer(
    p_request_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Parameters:**
| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `p_request_id` | UUID | No | The request/offer UUID to cancel |
| `p_client_id` | UUID | Yes | Deprecated parameter, ignored for auth (uses auth.uid()) |

**Return Value:**
```json
{
  "success": true
}
```

**Error Conditions:**
| Error | Condition |
|-------|-----------|
| `Not authenticated` | No active session |
| `Request not found or not in awarded-unpaid state` | Request doesn't exist or not in correct state |
| `Task not found` | Associated task doesn't exist |
| `Only task owner can cancel the award` | Caller is not task owner |

**Side Effects:**
- Updates `task_requests` status to `rejected`, clears payment fields, sets `deleted_at`
- Updates `tasks` status to `open`, clears freelancer assignments
- Sends notification to freelancer (`offer_award_cancelled`)

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Resolved from `auth.uid()`, ignores `p_client_id` parameter

---

### 7. cleanup_expired_awards

Cron-scheduled function that automatically expires awarded offers where payment deadline has passed.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION cleanup_expired_awards()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

**Parameters:** None

**Return Value:**
- `VOID` - No return value (logs via RAISE NOTICE)

**Error Conditions:**
| Error | Condition |
|-------|-----------|
| `Permission denied` | Caller is not service_role, postgres, supabase_admin, or authenticator |

**Processing Logic:**
- Finds offers with: `status='accepted'`, `payment_status='unpaid'`, `payment_deadline < now - 1 hour` (1-hour grace period)
- Rejects each expired offer (sets `status='rejected'`, appends note)
- Reverts associated task to `open` status
- Sends `award_expired` notification to freelancer
- Sends `award_expired` notification to client
- Logs to `admin_logs` with action `AWARD_AUTO_EXPIRED`

**Cron Schedule:**
- Runs every 10 minutes via `pg_cron`
- Job name: `cleanup-expired-awards`

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Restricted to service role, postgres, supabase_admin, or cron jobs

---

### 8. get_proposal_bidder_summaries

Returns minimum-field profile summaries for all bidders on a task (for owner view).

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION get_proposal_bidder_summaries(p_task_id UUID)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    avatar_url TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
```

**Parameters:**
| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `p_task_id` | UUID | No | The task UUID to get bidders for |

**Return Value:**
Table with columns:
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Bidder's profile ID |
| `full_name` | TEXT | Bidder's display name |
| `avatar_url` | TEXT | Bidder's avatar URL |

**Error Conditions:**
- Returns empty set if caller is not task owner (implicit via auth.uid() check in WHERE clause)

**Security Context:**
- **SECURITY DEFINER**: Runs with function owner privileges
- **Authorization**: Only returns data for tasks owned by `auth.uid()`
- **STABLE**: Marked as read-only for query optimization

---

## Table Row Shapes

### task_requests SELECT Shape

```sql
SELECT 
    tr.id,
    tr.task_id,
    tr.freelancer_id,
    tr.bidder_id,        -- Legacy column, mirrored from freelancer_id
    tr.price,            -- NUMERIC, proposed price
    tr.days,             -- INTEGER, proposed duration
    tr.duration_days,    -- INTEGER, synced to days (legacy)
    tr.note,             -- TEXT, optional message
    tr.status,           -- TEXT: pending|accepted|rejected|withdrawn
    tr.payment_status,   -- TEXT: unpaid|held|released|refunded
    tr.created_at,
    tr.updated_at,
    tr.deleted_at,
    tr.awarded_at,       -- TIMESTAMPTZ, when offer was accepted
    tr.awarded_by,       -- UUID, who accepted the offer
    tr.payment_deadline, -- TIMESTAMPTZ, payment window expiration
    tr.client_id,        -- UUID, denormalized for queries
    tr.fee_rate_applied_bps,  -- INTEGER, platform fee rate at award time
    tr.fee_amount,       -- BIGINT, calculated fee in cents
    tr.net_amount        -- BIGINT, freelancer payout in cents
FROM task_requests tr
```

**Joined Fields (via Flutter Model):**
- `profiles.full_name` -> `bidderName`
- `profiles.avatar_url` -> `bidderAvatar`
- `tasks.title` -> `taskTitle`

### tasks SELECT Shape (Relevant Columns)

```sql
SELECT 
    t.id,
    t.owner_id,              -- Client who posted the task
    t.title,
    t.description,
    t.price,                 -- Budget (for reference)
    t.task_type,             -- tender|booking|direct
    t.status,                -- open|assigned|in_progress|completed|closed|canceled|draft
    t.assigned_freelancer_id,-- Set when offer accepted
    t.freelancer_id,         -- Set when payment completed
    t.category_id,
    t.skills,
    t.created_at,
    t.updated_at
FROM tasks t
```

---

## Enum Values

### OfferStatus

Defined in `lib/core/app_enums.dart` and database `task_requests.status`:

| Value | Description |
|-------|-------------|
| `pending` | Offer is active and awaiting client decision |
| `accepted` | Client has accepted the offer (awaiting payment) |
| `rejected` | Client has rejected the offer, or it expired |
| `withdrawn` | Freelancer replaced or withdrew their offer |

**Database Constraints:**
- Only one `accepted` offer allowed per task (enforced by `idx_one_accepted_per_task` unique partial index)
- One active offer per freelancer per task (enforced by unique constraint on `(task_id, freelancer_id) WHERE deleted_at IS NULL`)

### PaymentStatus

Defined in `lib/core/app_enums.dart` and database `task_requests.payment_status`:

| Value | Description |
|-------|-------------|
| `unpaid` | Offer accepted but payment not yet completed |
| `held` | Payment completed, funds in escrow |
| `released` | Funds released to freelancer (work completed) |
| `refunded` | Funds refunded to client (cancellation/dispute) |

**State Transitions:**
```
unpaid -> held    (via pay_awarded_offer)
held -> released  (via work completion flow)
held -> refunded  (via cancellation/dispute)
```

---

## Security Model

### SECURITY DEFINER Functions

All RPCs in this contract use `SECURITY DEFINER`, which means:
- They execute with the privileges of the function owner (not the caller)
- They bypass RLS policies on the tables they access
- They perform explicit authorization checks using `auth.uid()`

**Authorization Pattern:**
```sql
-- Each function validates the caller's identity
DECLARE v_me UUID := auth.uid();
-- Then checks ownership/permissions explicitly
IF v_owner IS DISTINCT FROM v_me THEN
    RAISE EXCEPTION 'only task owner can perform this action';
END IF;
```

### Caller Identity

All functions resolve the caller's identity from the session:
- `auth.uid()` - The authenticated user's UUID
- `current_user` - For service role detection in `cleanup_expired_awards`

### Audit Trail

Sensitive operations log to `admin_logs`:
- `PRICE_MISMATCH_ATTEMPT` - Client tried to accept with stale price
- `OFFER_ACCEPTED` - Successful offer acceptance
- `AWARD_AUTO_EXPIRED` - System expired unpaid award

---

## Appendix: Deprecated Function Signatures

### Legacy accept_task_request (Single Parameter)

The original `accept_task_request(p_request_id UUID)` signature has been superseded by the three-parameter version. The old signature may still exist in some environments but is not recommended for new code.

---

**Document End**

*Verification: All 8 RPCs documented with accurate signatures from migration files*
- `accept_task_request` (tender_guardrails.sql)
- `reject_task_request` (20260305070000_reject_task_request_conversation_initiator.sql)
- `replace_task_request` (20260311000000_replace_task_request.sql)
- `award_task_offer` (20260304060000_secure_proposal_rpc_contract.sql)
- `pay_awarded_offer` (20260304060000_secure_proposal_rpc_contract.sql)
- `cancel_awarded_offer` (20260304060000_secure_proposal_rpc_contract.sql)
- `cleanup_expired_awards` (20260306_tender_guardrails.sql)
- `get_proposal_bidder_summaries` (20260304061000_proposal_profile_summary_contract.sql)
