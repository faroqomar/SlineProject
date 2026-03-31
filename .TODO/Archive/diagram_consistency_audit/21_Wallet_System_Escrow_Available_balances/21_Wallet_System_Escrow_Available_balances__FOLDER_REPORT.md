# 21_Wallet_System_Escrow_Available_balances Folder Report

## 1. Diagram Title & Version

- **Exact Name:** `21_Wallet_System_Escrow_Available_balances`
- **Version:** v2 (final) — 2026-03-07
- **Author:** SLine team / Finance & Ledger

## 2. Global Problem & Scope

- **Problem Solved:** Eliminates money ambiguity and non-atomic updates; ensures one source of truth (Held vs Available), no client-side balance math, and idempotent escrow release point (`rpc_approve_delivery`).
- **Scope Includes:** Pay-first flows (booking, direct_offer, task/tender); escrow_hold, release_with_fee, refund flows; ledger events, entity updates, and wallet available vs held viewing.
- **Excluded:** Withdraw (pending withdrawal, gateway payout) is out-of-scope/upcoming.

## 3. Assumptions & Invariants

- **Assumptions:** Escrow is append-only. Only webhook/recovery Finalizes payment. Currency is IQD. Wait, withdraw isn't handled yet.
- **Invariants:** SUM(DEBITS) = SUM(CREDITS) on `journal_entries`. Release is idempotent. Row locking (FOR UPDATE) is used.

## 4. Glossary

- `booking`, `task_request`, `direct_offer`
- `active`, `delivered`, `completed`, `refunded`
- `escrow_hold`, `release_with_fee`, `refund`
- `FOR UPDATE` row lock.

## 5. Actors & Permissions

- **Client:** Can pay, approve delivery for own entities.
- **Freelancer:** Can accept, deliver, view wallet. Cannot release escrow.

## 6. System Architecture Map

- **UI/App:** Wallet screen, Work item detail, Direct offer detail.
- **Services:** `wallet_service.dart`, `work_management_service.dart`, `direct_offers_service.dart`.
- **Database:** `bookings`, `direct_offers`, `tasks`, `journal_entries`, `ledger_lines`.
- **Views:** `vw_wallet_balances_user`, `vw_wallet_activity_user`.
- **RPCs:** `process_payment_event_ledger`, `rpc_approve_delivery`.

## 7. Step-by-Step Flow (The "Golden Path")

1.  **Escrow Hold:** Payment creates `escrow_hold` event, `payment_status` becomes `held`.
2.  **Delivery:** Freelancer delivers work.
3.  **Release:** Client clicks "Approve". Calls `rpc_approve_delivery`.
4.  RPC locks row, computes stable idempotency key, releases fee + net, updates status to `completed` and `released`.

## 8. Failure Modes & State Machine

- **Duplicate approve:** RPC is idempotent (same key -> no double charge).
- **Not Delivered:** RPC checks status, blocks if not delivered.
- **State Machine:** unpaid -> held -> released (or refunded).

## 9. Data Model & RLS

- RLS secures views (Security Invoker).
- `journal_entries.idempotency_key` is UNIQUE.

## 10. Security & Threat Model

- RPC uses `auth.uid()` for client identity spoofing prevention.
- Escrow trapped forever -> handled by separate dispute/auto-approve flows.

## 11. Verification & Observability

- `AppLogger` used in services. `admin_logs` and `vw_financial_metrics_realtime` in DB.

## 12. Cross-Diagram Dependencies

- Depends on **09 Ledger Event Flow**.
- Depended on by Wallet UI, Withdrawals (upcoming).
- **Conflict Point:** Mentions `system_config.platform_fee_bps` as fee source, whereas diagram 22 explicitly defines `platform_settings.fee_rate_default_bps`. This naming drift needs resolution in favor of 22.

## 13. Open Questions & Blockers

- Withdrawal flow is explicitly missing.
- Fee source field misnamed compared to diagram 22.

## 14. Final Status

- **Verdict:** VERIFIED (Core design is solid).
- **Production Ready:** YES (for Escrow/Release limits).
- **Next Actions:** Standardize the fee source table reference to match diagram 22. Build the Withdraw feature.
