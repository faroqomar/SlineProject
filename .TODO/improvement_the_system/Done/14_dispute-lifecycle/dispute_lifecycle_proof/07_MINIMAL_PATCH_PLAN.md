# Minimal Patch Plan: Dispute Lifecycle Critical Fixes

> Only patches required to prevent production-severity issues are listed here.
> Full improvements from the NEW report (Phase 1-4) are deferred to backlog.

---

## PATCH 1: Escrow Race Guard (CRITICAL)

**What:** Add dispute check to `rpc_approve_delivery` AND `rpc_finalize_auto_approval`.

**Why:** Without this, funds can be released while a dispute is open, making dispute resolution impossible.

**SQL (add BEFORE existing status checks):**

```sql
-- In rpc_approve_delivery, add at the start of BOTH 'task' and 'booking' branches:
IF EXISTS (
  SELECT 1 FROM public.disputes
  WHERE task_id = entity_id
    AND status IN ('open', 'active')
) THEN
  RAISE EXCEPTION 'Cannot approve delivery: dispute in progress';
END IF;
```

```sql
-- In rpc_finalize_auto_approval, add the same guard:
IF EXISTS (
  SELECT 1 FROM public.disputes
  WHERE task_id = v_entity_id
    AND status IN ('open', 'active')
) THEN
  -- Skip auto-approval; do not release funds
  RETURN;
END IF;
```

**Files to modify:**

- `rpc_approve_delivery` function definition (new migration)
- `rpc_finalize_auto_approval` function definition (new migration)

**Verification:**

1. Create booking with `status='delivered'`, `payment_status='held'`
2. Insert dispute with `status='open'` for same `task_id`
3. Call `rpc_approve_delivery('booking', booking_id)` → expect exception
4. Verify funds NOT released (check `journal_entries` for absence of `release_with_fee`)

---

## PATCH 2: Explicit Deny Policies (RECOMMENDED)

**What:** Add explicit deny UPDATE/DELETE policies for `disputes` table.

```sql
CREATE POLICY disputes_deny_update ON public.disputes FOR UPDATE TO authenticated USING (false);
CREATE POLICY disputes_deny_delete ON public.disputes FOR DELETE TO authenticated USING (false);
```

**Why:** Currently secure by omission (no UPDATE policy = blocked). Explicit deny is safer against future policy additions that might accidentally open UPDATE.

---

## PATCH 3: Dispute Status Enum (RECOMMENDED, Pre-Hardening)

**What:** Create enum and migrate column.

```sql
CREATE TYPE public.dispute_status_enum AS ENUM ('open', 'active', 'resolved', 'canceled');

ALTER TABLE public.disputes
  ALTER COLUMN status TYPE public.dispute_status_enum
  USING status::public.dispute_status_enum;

ALTER TABLE public.disputes
  ALTER COLUMN status SET DEFAULT 'open'::public.dispute_status_enum;
```

**Why:** Prevents arbitrary status strings. Existing rows with known values ('open') migrate cleanly.

> **Risk:** If any rows have non-standard status values, the USING cast will fail. Run `SELECT DISTINCT status FROM disputes` first.

---

## Priority Order

| #   | Patch                  | Severity       | Effort |
| --- | ---------------------- | -------------- | ------ |
| 1   | Escrow Race Guard      | 🔴 CRITICAL    | ~30min |
| 2   | Explicit Deny Policies | 🟡 RECOMMENDED | ~5min  |
| 3   | Dispute Status Enum    | 🟡 RECOMMENDED | ~15min |
