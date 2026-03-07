# 23_Admin_Dashboard_Wallet_Finance Folder Report

## 1. Diagram Title & Version

- **Exact Name:** Admin Dashboard Wallet/Finance Diagram
- **Version:** Draft/Template
- **Author:** Unspecified

## 2. Global Problem & Scope

- **Problem Solved:** Admins need accurate visibility into platform earnings, active escrow liabilities, and GMV, distinct from client/freelancer views.
- **Scope Includes:** Platform revenue tracking, escrow monitoring, auditing via aggregated views.

## 3. Assumptions & Invariants

- **Assumptions:** Metric views are strictly read-only aggregations.
- **Invariants:** Escrow liabilities must strictly match the ledger sums.

## 4. Glossary

- `GMV`: Total volume processed.
- `Net Platform`: Total platform revenue after refunds.

## 5. Actors & Permissions

- **Admin:** Read-only access to aggregated metrics and traces.

## 6. System Architecture Map

- **UI/App:** Admin Dashboard (Finance Overview, Escrow Monitor, Transaction Explorer).
- **Backend:** Admin Server Actions (BFF).
- **Database Views:** `vw_admin_finance_metrics`, `vw_admin_booking_finance`, `vw_admin_escrow_open`.

## 7. Step-by-Step Flow (The "Golden Path")

- Admin loads dashboard. Server queries `vw_admin_finance_metrics` and returns `{ gmv, fees, escrow_held }`.
- Admin requests open escrow cases -> server queries `vw_admin_escrow_open` to identify at-risk/long-running holds.

## 8. Failure Modes & State Machine

- N/A (Read-only aggregation flows).

## 9. Data Model & RLS

- Relying on base tables: `platform_settings`, `bookings`, `journal_entries`.

## 10. Security & Threat Model

- The API for admin actions must enforce admin role check contextually or via RLS (service role implies admin privileges but needs caution).

## 11. Verification & Observability

- Views must be tested for accuracy to ensure no double-counting of ledger lines.

## 12. Cross-Diagram Dependencies

- Relies strictly on Diagram **21 (Ledger)** and **22 (Fee System)**. The fee locking strategy (`fee_rate_applied`, `fee_amount`, `net_amount`) is identical to Diagram 22.

## 13. Open Questions & Blockers

- This is explicitly marked as a "template" without concrete code/DB evidence provided within the document itself ("TBD" in Evidence table). Needs physical implementation validation in SQL.

## 14. Final Status

- **Verdict:** PARTIAL (Awaiting implementation).
- **Production Ready:** NO (Template only).
- **Next Actions:** Implement the SQL aggregation views (`vw_admin_finance_metrics`, etc.) if currently missing, ensuring they sum the double-entry columns correctly.
