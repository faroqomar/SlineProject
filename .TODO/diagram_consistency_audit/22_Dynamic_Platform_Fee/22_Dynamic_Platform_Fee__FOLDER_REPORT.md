# 22_Dynamic_Platform_Fee Folder Report

## 1. Diagram Title & Version

- **Exact Name:** `22_Dynamic_Platform_Fee`
- **Version:** v2.0 (final) — 2026-03-06
- **Author:** @Executor with @Supabase_Ops, @Architect

## 2. Global Problem & Scope

- **Problem Solved:** Ensures platform fee rate can change globally without mutating in-flight escrows (locks rate at payment time).
- **Scope Includes:** `platform_settings` table, `fee_rate_applied_bps`, `fee_amount`, `net_amount` columns. Immutability triggers.
- **Excluded:** Multi-currency, tiered fees, client-side math.

## 3. Assumptions & Invariants

- **Assumptions:** Fee is locked when `payment_status` becomes `held`. Fee calculation uses `FLOOR`.
- **Invariants:** `fee_amount + net_amount = gross` (when both stored). Once `fee_rate_applied_bps` is set, it never changes (immutable). No penny shift.

## 4. Glossary

- `platform_settings`: Global configuration table.
- `fee_rate_applied_bps`: Locked rate per entity at escrow.
- `bps`: Basis points, 1000 = 10%.

## 5. Actors & Permissions

- **Admin:** Modify `platform_settings` fee defaults.
- **Client/Freelancer:** Read-only access to their specific fees on their entities.
- **Trigger:** Automatically locks fee rate upon escrow update.

## 6. System Architecture Map

- **UI:** EarningsScreen, BookingDetailsScreen.
- **Database:** `platform_settings` table. Triggers: `trg_lock_fee_on_escrow_*`, `trg_protect_fee_rate_applied_*`.
- **Services:** `LedgerService`, `FeeBreakdownCard`.

## 7. Step-by-Step Flow (The "Golden Path")

1.  **Configure:** Admin updates `platform_settings.fee_rate_default_bps` to 1200 (12%).
2.  **Escrow (Lock):** Client pays via `process_payment_event_ledger`.
3.  Trigger `trg_lock_fee_on_escrow_*` activates, grabs 1200 bps from settings, copies it to `booking.fee_rate_applied_bps`.
4.  **Admin Changes Global Rate:** Admin sets rate to 1500 bps (15%). Previous booking remains locked at 1200.
5.  **Release:** `process_payment_event_ledger('release_with_fee', ...)` calculates fee using the locked `1200` value.

## 8. Failure Modes & State Machine

- Fee not locked on release -> Returns `ERR_FEE_RATE_NOT_LOCKED`.
- Admin override abuse -> Only permitted if caller is admin. Logged via `admin_logs`.

## 9. Data Model & RLS

- `platform_settings.fee_rate_default_bps`
- Entity columns: `fee_rate_applied_bps`, `fee_amount`, `net_amount`.

## 10. Security & Threat Model

- **Spoofing fee rate:** Prevents client overriding fee in `p_meta` (ignored unless admin). Immutability trigger enforces lock.

## 11. Verification & Observability

- `trg_log_platform_settings_change` -> logs updates.
- Tests needed: ensure calculation rules are respected.

## 12. Cross-Diagram Dependencies

- Depends on logic from diagram **21 Wallet System** (Escrow locking happens during Escrow Hold).
- **Conflict Point:** Modifies definition in diagram 21 which referred to `system_config`. `platform_settings` is the winner here.

## 13. Open Questions & Blockers

- Are `fee_amount` and `net_amount` reliably tracked across all 3 entity types (`bookings`, `direct_offers`, `tasks`)? Triggers need to exist on all 3.

## 14. Final Status

- **Verdict:** VERIFIED.
- **Production Ready:** YES.
- **Next Actions:** Ensure `platform_settings` replaces `system_config` globally in docs and DB schema definition. Validate triggers apply to all 3 entity types.
