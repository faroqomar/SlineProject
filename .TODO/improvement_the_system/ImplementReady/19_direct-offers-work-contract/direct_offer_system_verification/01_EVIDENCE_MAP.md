# 01_EVIDENCE_MAP

## A. Lifecycle Enforced by DB Guard (`fn_direct_offer_guard`)

**Path**: `supabase/migrations/Archive/20260306_direct_offer_guard_accept_to_active.sql`

| Transition                 | Requires Status | Requires Payment Status    | Actor Enforced               |
| :------------------------- | :-------------- | :------------------------- | :--------------------------- |
| **sent -> accepted**       | `sent`          | `unpaid`                   | App logic (Client)           |
| **accepted -> active**     | `accepted`      | `held` (set by Ledger)     | Escrow gate (Client)         |
| **active -> delivered**    | `active`        | (remains `held`)           | `auth.uid() = freelancer_id` |
| **delivered -> completed** | `delivered`     | `released` (set by Ledger) | Ledger release gate (Client) |

_Contradiction with OLD Diagram_: The old diagram incorrectly assumed `rpc_approve_delivery` managed the `completed` state. In reality, `process_payment_event_ledger(release_with_fee, 'direct_offer')` updates the state side-effect.

## B. Payment Entity Binding (`process_payment_event_ledger`)

**Path**: `supabase/migrations/Archive/20260307_fix_ledger_event_type_enum.sql` & `20260308_fix_release_with_fee_zero_amount_and_enum.sql`

- **Escrow Hold**:
  - Validates `p_related_entity_type = 'direct_offer'`.
  - Check gate: `v_booking_status IN ('sent', 'accepted') AND v_payment_status = 'unpaid'`.
  - Action: Inserts to `journal_entries` tracking `client_id`, `freelancer_id`, `amount_gross` in `meta`. Updates entity `payment_status = 'held', status = 'active'`.
- **Release With Fee**:
  - Check gate: `v_booking_status = 'delivered' AND v_payment_status = 'held'`.
  - Action: Updates `direct_offers.payment_status = 'released', status = 'completed'`.

## C. RLS Security (`direct_offers` table)

**Path**: `supabase/migrations/Archive/20260303_direct_offers_table_rls_trigger.sql`

- **SELECT**: `client_id = auth.uid() OR freelancer_id = auth.uid()`
- **INSERT**: `freelancer_id = auth.uid()` AND MUST exist in a valid conversation where `auth.uid()` is a participant.
- **UPDATE**: `client_id = auth.uid() OR freelancer_id = auth.uid()`
- **DELETE**: `false` (Immutable records).
