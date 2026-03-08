# Escrow Race Prevention Proof

## 🚨 PRODUCTION BLOCKER: `rpc_approve_delivery` Has NO Dispute Check

### Evidence

**File:** `supabase/migrations/Archive/20260224_fix_rpc_approve_delivery_digest_schema.sql`

```sql
-- Lines 22-28 (Task branch):
if entity_type = 'task' then
  select status, owner_id into v_status, v_client_id from tasks where id = entity_id;
  if v_client_id != v_uid then raise exception 'Not authorized'; end if;
  if v_status != 'delivered' then raise exception 'Work not delivered'; end if;
  update tasks set status = 'completed', review_expires_at = null where id = entity_id;

-- Lines 30-59 (Booking branch):
elsif entity_type = 'booking' then
  select status, payment_status, client_id, provider_id, price
  into v_status, v_payment_status, v_client_id, v_provider_id, v_price
  from bookings where id = entity_id;
  if v_client_id != v_uid then raise exception 'Not authorized'; end if;
  if v_status != 'delivered' then raise exception 'Work not delivered'; end if;
  -- ... releases funds via process_payment_event_ledger ...
```

**What's missing:** Zero references to the `disputes` table. No check like:

```sql
IF EXISTS (SELECT 1 FROM disputes WHERE task_id = entity_id AND status IN ('open','active'))
  THEN RAISE EXCEPTION 'Cannot complete: active dispute exists';
```

### Attack Scenario

1. Freelancer delivers work → `bookings.status = 'delivered'`
2. Client files dispute → `disputes.status = 'open'`
3. Client calls `rpc_approve_delivery('booking', booking_id)` — **succeeds**
4. Escrow released to freelancer via `process_payment_event_ledger('release_with_fee', ...)`
5. Admin has no escrow to refund; dispute is now unresolvable financially

### Also Affected: `rpc_finalize_auto_approval`

**Evidence:** `SUPABASE_SETUP.md` §9.4: _"Checks `now() > review_expires_at`, sets `status='completed'`, releases payment."_  
No dispute check mentioned → auto-approval timer can release funds even during an active dispute.

---

## Minimal Server-Side Guard (Required Before Ship)

```sql
-- Add to rpc_approve_delivery, BEFORE the status check:
IF EXISTS (
  SELECT 1 FROM public.disputes
  WHERE task_id = entity_id
    AND status IN ('open', 'active')
) THEN
  RAISE EXCEPTION 'Cannot approve delivery: dispute in progress (dispute.status IN open,active)';
END IF;

-- Same check MUST be added to rpc_finalize_auto_approval
```

> **Severity: CRITICAL** | **Likelihood: HIGH** (auto-approval timer makes this automatic)
