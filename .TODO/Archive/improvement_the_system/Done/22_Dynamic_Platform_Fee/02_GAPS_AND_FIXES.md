# Gap Analysis & Improved Fixes

## 1. Missing Schema Components

The follow components are described in the conceptual diagrams but are missing from the SQL schema:

- **Table**: `public.platform_settings`
  - _Gap_: No centralized storage for the default fee rate.
  - _Fix_: Create `platform_settings` table with RLS restricted to admins.
- **Columns**: `bookings.fee_rate_applied`, `bookings.fee_amount`, `bookings.net_amount`
  - _Gap_: These columns don't exist in the current `bookings` table.
  - _Fix_: Migration to add these columns to `bookings` and `direct_offers`.

## 2. Insecure Fee Override Logic

- **Gap**: The `process_payment_event_ledger` RPC accepts `fee_rate_bps` in `p_meta`. Since the function is `SECURITY DEFINER` and called by the client, a malicious user could potentially override the fee by passing a custom meta object.
- **Fix**: The RPC must ignore `p_meta->'fee_rate_bps'` for client actors and instead read the **locked** rate from the entity (`bookings` or `direct_offers`).

## 3. Lack of Fee Locking at Escrow

- **Gap**: `escrow_hold` event does not fetch or store the current fee rate.
- **Fix**: Update `escrow_hold` handler in `process_payment_event_ledger` to:
  1. Read current `fee_rate_default` from `platform_settings`.
  2. Write it to `bookings.fee_rate_applied`.

## 4. Inconsistent Release Logic

- **Gap**: `release_with_fee` uses a hardcoded 10% fallback.
- **Fix**: Update `release_with_fee` handler to:
  1. Require `fee_rate_applied` to be NOT NULL on the entity.
  2. Calculate `fee_amount` and `net_amount` based on that locked rate.
  3. Store the calculated amounts in the entity for audit purposes.
