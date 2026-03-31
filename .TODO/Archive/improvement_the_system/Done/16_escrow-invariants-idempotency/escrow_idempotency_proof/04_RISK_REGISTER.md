# Risk Register: Escrow Idempotency

## Current Risks (Unpatched)

| ID     | Risk                                                   | Severity  | Likelihood | Impact                                                                 | Evidence                                                                                                                                             | Mitigation Present?                                                                  |
| ------ | ------------------------------------------------------ | --------- | ---------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **R1** | `now()` in idempotency key makes key non-stable        | 🟡 Medium | N/A        | Each journal entry gets a unique key; orphan key cleanup never matches | `rpc_approve_delivery` live SQL                                                                                                                      | Status gate + `FOR UPDATE` = safe                                                    |
| **R2** | No double-tap debounce in `ReviewDeliveryModal`        | 🟡 Medium | 🟠 Medium  | Two rapid taps could fire two RPC calls before `_isLoading` renders    | [review_delivery_modal.dart](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/lib/features/work/view/widgets/review_delivery_modal.dart#L36-L44) | `FOR UPDATE` in ledger blocks second call                                            |
| **R3** | Outer RPC reads without `FOR UPDATE`                   | 🟢 Low    | 🟢 Low     | Both calls proceed to ledger function (benign — inner lock catches it) | `rpc_approve_delivery` live SQL                                                                                                                      | Inner `FOR UPDATE` in ledger function                                                |
| **R4** | Task branch has NO idempotency key or ledger           | 🟢 Low    | 🟢 Low     | Task approval is just a status update, no financial impact             | `rpc_approve_delivery` live SQL                                                                                                                      | Status check blocks re-approval                                                      |
| **R5** | Duplicate UNIQUE index on `idempotency_key`            | 🟢 Low    | N/A        | Wasted storage and minor write overhead                                | `pg_indexes` query                                                                                                                                   | Drop one                                                                             |
| **R6** | No admin dashboard for escrow monitoring               | 🟡 Medium | N/A        | Ops cannot detect anomalies without raw SQL                            | `find_by_name` returned 0 admin dirs                                                                                                                 | Use Supabase Table Editor for now                                                    |
| **R7** | `fee_rate_bps` passed as `0` in `rpc_approve_delivery` | 🟡 Medium | 🟠 Medium  | Platform collects 0 fee on release                                     | `'fee_rate_bps': 0` in live SQL                                                                                                                      | Ledger defaults to 1000 bps if not specified — **but** the explicit `0` overrides it |

---

## Risks Introduced by NEW Design (Proposed Stable Key)

| ID  | Risk                                                | Severity | Likely? | Mitigation                                         |
| --- | --------------------------------------------------- | -------- | ------- | -------------------------------------------------- |
| M1  | Migration changes RPC signature                     | 🟢 Low   | 🟢 Low  | `CREATE OR REPLACE FUNCTION` — atomic, no downtime |
| M2  | Old app version sends stale retry with old behavior | 🟢 Low   | 🟢 Low  | Not applicable — app doesn't send idempotency key  |

---

## New Finding: R7 Deep Dive — Fee Rate = 0

**Source**: `rpc_approve_delivery` live SQL:

```sql
p_meta := '{"fee_rate_bps": 0}'::jsonb
```

**Inside `process_payment_event_ledger`**:

```sql
v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);
v_fee_amount := FLOOR((v_entity_amount_gross * v_fee_rate_bps) / 10000);
```

Since `fee_rate_bps = 0`, `v_fee_amount = 0`, `v_net_amount = full price`.

The ledger line insertion uses `WHERE line.amount > 0`:

```sql
INSERT INTO public.ledger_lines ...
SELECT ... FROM (VALUES
  (v_platform_escrow_id, 'DEBIT', v_entity_amount_gross),
  (v_user_available_id, 'CREDIT', v_net_amount),
  (v_platform_revenue_id, 'CREDIT', v_fee_amount)  -- 0 → skipped
) WHERE line.amount > 0;
```

✅ The `CHECK (amount > 0)` constraint is respected — 0-fee line is correctly skipped.
🟡 But the platform collects **no revenue** on approvals through `rpc_approve_delivery`. This may be intentional (fee collected elsewhere) or a **business logic bug**.
