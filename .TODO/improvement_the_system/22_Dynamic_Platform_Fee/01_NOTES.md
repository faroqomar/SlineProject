# Audit Notes: Dynamic Platform Fee System

**Skills Applied:**

1. **Evidence-First Reading**: Every claim is tied to `SUPABASE_SETUP.md` or migration files.
2. **DB-First Financial Modeling**: Analyzed the ledger RPC and account structure.
3. **Invariants & Contracts**: identified the missing contract enforcement for locked fees.
4. **Threat Modeling (Security)**: Analyzed fee manipulation risks.

## Ground Truth vs. Diagram (`22_Dynamic_Platform_Fee.md`)

| Feature              | Diagram Claim                        | Actual Implementation (Evidence)                                                            | Status     |
| -------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------- | ---------- |
| **Global Fee Table** | `platform_settings.fee_rate_default` | Not found in `SUPABASE_SETUP.md` or migrations.                                             | ❌ MISSING |
| **Fee Locking**      | `bookings.fee_rate_applied`          | Not found in `bookings` table schema (§5.9).                                                | ❌ MISSING |
| **Escrow Flow**      | RPC stores fee rate in booking       | `process_payment_event_ledger('escrow_hold')` only updates `payment_status`.                | ❌ GAP     |
| **Release Flow**     | RPC reads locked fee                 | `process_payment_event_ledger('release_with_fee')` uses hardcoded `1000 bps` (10%) default. | ⚠️ RISK    |

## Technical Findings

1. **Hardcoded Fee logic**:
   - File: `supabase/migrations/Archive/20260225_create_process_payment_event_ledger_rpc.sql`
   - Line 339: `v_fee_rate_bps := COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000);`
   - Rationale: The system falls back to a 10% fee if not explicitly passed. This is extremely high-risk for a dynamic fee system.

2. **Ledger Integration**:
   - The ledger system correctly debits `platform_escrow` and split-credits `provider_available` and `platform_revenue`.
   - However, the "source of truth" for the split remains transient (passed in `p_meta` or hardcoded).

3. **Booking Schema Disconnect**:
   - `SUPABASE_SETUP.md` Section 5.9 shows `price`.
   - The RPC uses `amount_gross` (e.g., Line 125).
   - This suggests a schema drift or a naming inconsistency in the RPC code compared to the actual `bookings` table.

## Risks Identified

- **Fee Drift**: Admin changes global rate, and "active" bookings suddenly generate different revenue than expected.
- **Audit Failure**: Transaction logs (`ledger_lines`) show the split, but there is no link to the _policy_ that determined that split at the time of escrow.
- **Security**: If the fee is passed via `p_meta` from the client, a malicious client could potentially spoof a 1% fee (bypass check). (Wait, the RPC says `COALESCE((p_meta->>'fee_rate_bps')::NUMERIC, 1000)` but the actor is the client... oh, wait, `process_payment_event_ledger` is `SECURITY DEFINER`. If called from Client, they can pass whatever meta they want unless guarded).
