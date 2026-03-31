# Contract: admin_refund_direct_offer

**Feature:** Direct Offers Work Contract (Plan 19)  
**Purpose:** Admin-only RPC to trigger a refund for a direct_offer via the ledger; used for disputes or stuck escrow.

---

## 1. Admin resolution

- **Definition:** Caller is admin if and only if `auth.uid()` is present in `public.admin_users.id` (i.e. `auth.uid() IN (SELECT id FROM public.admin_users)`).
- **Source of truth:** Table `public.admin_users` (id FK to auth.users.id, role, email). No app or anon access to this RPC; only service_role or a role that can assume admin context (e.g. dashboard backend) may call it. In practice, RPC is invoked with JWT of an admin user; RPC body checks `auth.uid()` against `admin_users`.
- **Grant:** `GRANT EXECUTE ON FUNCTION public.admin_refund_direct_offer TO authenticated` (or to a dedicated admin role). RPC body **must** raise if caller is not in `admin_users`.

---

## 2. Signature

```sql
admin_refund_direct_offer(
  p_offer_id uuid,
  p_reason text,
  p_idempotency_key text DEFAULT gen_random_uuid()::text
)
RETURNS jsonb
```

- **p_offer_id:** direct_offers.id to refund.
- **p_reason:** Optional reason (stored in meta or audit; not used for ledger logic).
- **p_idempotency_key:** Idempotency key passed to `process_payment_event_ledger`; if omitted, default new UUID per call (still idempotent per key if caller reuses key).

---

## 3. Success shape

```json
{ "ok": true, "offer_id": "<uuid>", "journal_entry_id": "<uuid>" }
```

- **journal_entry_id:** id of the journal entry created by the ledger refund.

---

## 4. Error cases

| Condition | Behavior |
|-----------|----------|
| Caller not admin | Raise: `only admin can refund direct_offer`. |
| Offer not found | Raise: `offer not found`. |
| Offer not in refundable state | Raise: `offer not in refundable state` (e.g. already refunded, or not held). Ledger supports refund for direct_offer when payment_status is `held`; RPC should validate offer state before calling ledger. |
| Ledger/constraint error | Re-raise from process_payment_event_ledger. |

---

## 5. Idempotency

- Same `p_idempotency_key` for same offer: `process_payment_event_ledger` deduplicates by idempotency_key; second call returns success without double-refund (ledger behavior).
- RPC should pass through the same key to the ledger.

---

## 6. Audit / observability

- Refund is recorded in journal_entries + ledger_lines; optional: write to admin_logs or work_logs with reason and actor (auth.uid()).
