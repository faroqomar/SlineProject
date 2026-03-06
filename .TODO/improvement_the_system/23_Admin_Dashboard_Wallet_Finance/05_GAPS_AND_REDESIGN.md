# Skills Applied

- **Skills selected**: Idempotency & Concurrency, DB-First Financial Modeling
- **Why these skills fit**: Addressing the "missing" finance details by proposing a strictly typed, immutable bridge between bookings and the ledger.

---

# 05 Gaps and Redesign: Admin & Finance

## 1. Naming & Discovery Gaps

- **Proposed**: `vw_admin_finance_metrics`
- **Actual**: `vw_financial_metrics_realtime`
- **Fix**: The diagram should be updated to match the production view names to allow developers/auditors to find the source code instantly.

## 2. Missing "Money Story" View

- **Gap**: The diagram shows `vw_admin_booking_finance` returning `gross, fee_rate, fee_amount, net`. This view does NOT exist in `SUPABASE_SETUP.md`.
- **Redesign**: Create `vw_admin_booking_finance` by joining `bookings` with `journal_entries` and `ledger_lines`.
  - **Invariant**: Sum of `ledger_lines` for `platform_revenue` associated with a `booking_id` must match `fee_amount` in the view.

## 3. Configuration Centralization

- **Proposed**: `platform_settings` table.
- **Actual**: `system_config` table (key-value).
- **Fix**: Migrate proposed fee settings to `system_config`.
  - **New Keys**: `fee_rate_bps` (stored in basis points to avoid floating point issues), `escrow_auto_release_days`.

## 4. Observability & Audit

- **Gap**: `audit_logs` are generic.
- **Redesign**: Add a `related_ledger_entry_id` to `audit_logs` for "Financial Admin" actions (manual adjustments).

## 5. Security Hardening

- **Gap**: `public.users` view is a PII leak.
- **Fix**: DELETE `public.users` view. Use `profiles` safe summaries.
- **Gap**: Financial views granted to `authenticated`.
- **Fix**: Fully restrict to `service_role` and use an RBAC-checked RPC for Admin Dashboard.
