# Schema Proof: Dynamic Platform Fee

## A) Does `platform_settings` exist?

**VERDICT: ❌ NO.**

### Evidence — Migration search

```
find_by_name pattern: *platform_settings* → 0 results
```

There is no file, table, or reference named `platform_settings` anywhere in the repo.

### Evidence — `system_config` (partial match)

A related table exists: `public.system_config`.

**Source**: `supabase/migrations/Archive/20260310101000_dashboard_public_config_reports_disputes_bridge.sql` (lines 10-16)

```sql
CREATE TABLE IF NOT EXISTS public.system_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  description text,
  updated_by uuid REFERENCES public.admin_users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

### Evidence — Live Supabase query

```sql
SELECT key, value FROM public.system_config ORDER BY key;
```

Result:
| key | value |
|---|---|
| `app_banner` | `{"text":"","type":"info","enabled":false}` |
| `disable_signups` | `{"enabled":false}` |
| `maintenance_mode` | `{"enabled":false,"message":""}` |
| `min_app_version` | `{"ios":"1.0.0","android":"1.0.0"}` |

**No `fee_rate_bps` or `fee_rate_default` row exists.** The `system_config` table could host it (as JSONB), but no seed data or migration has ever inserted a fee configuration row.

---

## B) Does `bookings` have fee columns?

**VERDICT: ❌ NO.**

### Evidence — Live Supabase query

```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema='public' AND table_name='bookings'
  AND column_name IN ('fee_rate_applied','fee_amount','net_amount','price','amount_gross','gross_amount');
```

Result:
| column_name | data_type | column_default |
|---|---|---|
| `price` | `numeric` | `0` |

**Only `price` exists. No `fee_rate_applied`, `fee_amount`, `net_amount`, `amount_gross`, or `gross_amount`.**

---

## C) Naming Drift Analysis

| Location                             | Column Used             | Canonical?               |
| ------------------------------------ | ----------------------- | ------------------------ |
| `bookings` table (live DB)           | `price`                 | ✅ Source of truth       |
| RPC `escrow_hold` (line 121)         | `price AS amount_gross` | Alias in SELECT          |
| RPC `release_with_fee` (line 292)    | `price AS amount_gross` | Alias in SELECT          |
| `task_requests` table                | `amount_gross`          | Native column (no alias) |
| `direct_offers` table                | `price AS amount_gross` | Alias in SELECT          |
| Diagram `22_Dynamic_Platform_Fee.md` | `gross_amount`          | ❌ Different from both   |

### Canonical Naming Decision

**Recommendation**: Use `price` as canonical for `bookings` and `direct_offers` (it's what exists). Internally in the RPC, aliasing to `amount_gross` is fine. **Never** introduce a new column named `gross_amount` — it would create a third name for the same concept.

For the fee system columns to add:

- `fee_rate_applied_bps INTEGER` (basis points, integer, immutable after lock)
- `fee_amount NUMERIC` (calculated: `FLOOR(price * fee_rate_applied_bps / 10000)`)
- `net_amount NUMERIC` (calculated: `price - fee_amount`)

---

## D) `direct_offers` fee columns

Same situation as `bookings`. **No fee columns exist**.

### Evidence — RPC source

In `20260303_direct_offer_ledger_rpc.sql` line 304:

```sql
SELECT id, client_id, freelancer_id AS provider_id, status, payment_status, price AS amount_gross
INTO v_entity
FROM public.direct_offers
```

No `fee_rate_applied` is ever read or written for direct offers.

---

## Summary Table

| Item                              | Diagram Claims      | Live DB                 | Gap?     |
| --------------------------------- | ------------------- | ----------------------- | -------- |
| `platform_settings` table         | Required            | ❌ Does not exist       | CRITICAL |
| `system_config.fee_rate_bps` row  | —                   | ❌ Not seeded           | CRITICAL |
| `bookings.fee_rate_applied`       | Required            | ❌ Column missing       | CRITICAL |
| `bookings.fee_amount`             | Required            | ❌ Column missing       | CRITICAL |
| `bookings.net_amount`             | Required            | ❌ Column missing       | CRITICAL |
| `bookings.price`                  | Exists              | ✅ `numeric, default 0` | OK       |
| Naming: `gross_amount` vs `price` | Uses `gross_amount` | `price` is canonical    | DRIFT    |
