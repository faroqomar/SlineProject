# Runbook: Escrow Idempotency T1 / T2 / T4

**Plan:** PLAN_EscrowInvariantsIdempotency_2026-03-07_CRITIC  
**Run after:** Migration `20260307000001_escrow_idempotency_stable_key.sql` is applied.

---

## How to run

- **Option A:** Supabase SQL Editor (Dashboard → SQL Editor). Paste each section and run.
- **Option B:** Supabase MCP `execute_sql` with `project_id: isddrknbjsgaantjojhm` and the query below.

---

## T1: Idempotent replay (mandatory before release)

**Intent:** Second call to `rpc_approve_delivery` for the same entity must not create a second journal_entry or ledger_lines.

**Prerequisites:**

- A booking in state `status = 'delivered'` and `payment_status = 'held'` (or use a test booking you can reset).
- Replace `:booking_id` and `:client_user_id` with real UUIDs (client must be the booking’s `client_id` to pass auth).

**Steps:**

1. Record initial journal count for that booking:

```sql
-- Set :booking_id to your test booking id
SELECT COUNT(*) AS cnt_before
FROM journal_entries
WHERE related_entity_type = 'booking'
  AND related_entity_id = ':booking_id'::uuid
  AND event_type = 'release_with_fee';
-- Expect 0 if not yet approved, or 1 if already approved once.
```

2. Call RPC twice (as the client). In SQL you must set `request.jwt.claim.sub` to the client’s user id; in practice run from the app as the client or use Supabase Auth as that user and call from SQL Editor with that session, or use a service role and call the function (bypassing RLS) for test only:

```sql
-- As authenticated client (run in a session where auth.uid() = client_id of the booking):
SELECT rpc_approve_delivery('booking', ':booking_id'::uuid);
SELECT rpc_approve_delivery('booking', ':booking_id'::uuid);
```

3. Assert only one journal entry and no duplicate ledger lines:

```sql
SELECT COUNT(*) AS journal_count
FROM journal_entries
WHERE related_entity_type = 'booking'
  AND related_entity_id = ':booking_id'::uuid
  AND event_type = 'release_with_fee';
-- Must be 1.

SELECT COUNT(*) AS line_count
FROM ledger_lines ll
JOIN journal_entries je ON je.id = ll.journal_entry_id
WHERE je.related_entity_type = 'booking'
  AND je.related_entity_id = ':booking_id'::uuid
  AND je.event_type = 'release_with_fee';
-- Must match expected lines for a single release (e.g. 3 lines: platform_escrow DR, user_available CR, platform_revenue CR).
```

**Pass:** journal_count = 1 after two RPC calls; line_count unchanged after second call.

---

## T2: Concurrent calls (recommended)

**Intent:** Two concurrent calls for the same entity: one succeeds, the other hits idempotency (unique) or succeeds with same result; no double release.

**Steps:**

- From two sessions (or two app instances), call `rpc_approve_delivery('booking', :booking_id)` at the same time.
- Assert: exactly one new journal_entry for that entity with event_type `release_with_fee`; wallet balance for the freelancer increased once (not twice).

**Pass:** Single journal entry; no duplicate ledger lines; balance correct.

---

## T4: Bypass attempt (security)

**Intent:** Call approve for an entity already completed; must reject or no-op.

**Steps:**

1. Use a booking already `status = 'completed'` and `payment_status = 'released'`.
2. Call `rpc_approve_delivery('booking', :booking_id)` (as client).
3. Expect: RPC raises “Work not delivered” or equivalent, or no-op (no new journal entry).

```sql
-- After ensuring booking is completed/released:
SELECT rpc_approve_delivery('booking', ':booking_id'::uuid);
-- Expect error or no-op.

SELECT COUNT(*) FROM journal_entries
WHERE related_entity_type = 'booking' AND related_entity_id = ':booking_id'::uuid
  AND event_type = 'release_with_fee';
-- Must still be 1 (no new entry).
```

**Pass:** No second journal entry; error or no-op.

---

## E2E (manual)

1. As client, open work item (booking) in delivered/held state.
2. Tap “Approve” once; wait for success; verify status completed and balance updated.
3. If possible, trigger approve again (e.g. retry or second device). Expect: success (idempotent) and no duplicate credit; no error shown.

---

## Run command summary

- **T1:** Run SQL steps 1–3 above with a real booking id and client session. Document: “T1 passed: journal_count=1 after two calls.”
- **T2:** Run concurrent calls; document result.
- **T4:** Run T4 steps; document “T4 passed: no second journal entry.”
