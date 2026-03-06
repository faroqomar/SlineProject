# Skills Applied

- **Skills selected**: Repo Mapping, Evidence-First Reading, Financial Modeling (DB-First)
- **Why these skills fit**: Connecting proposed diagram elements to actual migrations (`Repo Mapping`), verifying every claim with specific SQL paths (`Evidence-First Reading`), and validating the double-entry backend for the finance view (`Financial Modeling`).
- **Skills intentionally not used**: State Machine (handled in 03_FINANCIAL_INVARIANTS), Idempotency (handled in Redesign).

---

# 01 Evidence: Admin & Finance System

## 1. System Configuration (proposed: platform_settings)

The codebase uses `public.system_config` with a key-value store.

- **Table Definition**: `public.system_config`
  - **Path**: [20260310101000_dashboard_public_config_reports_disputes_bridge.sql:L10-L16](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260310101000_dashboard_public_config_reports_disputes_bridge.sql#L10-L16)
  - **Keys enforced**: `maintenance_mode`, `app_banner`, `disable_signups`, `min_app_version`.
  - **Proposed `fee_rate_default`**: Not yet in `system_config` default batch, but intended to live here.

## 2. Financial Metrics Views (proposed: vw_admin_finance_metrics)

The actual implementation provides real-time and period-based metrics.

- **Real-time View**: `public.vw_financial_metrics_realtime`
  - **Path**: [20260225_create_wallet_views.sql:L168](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260225_create_wallet_views.sql#L168)
  - **Metrics**: `escrow_held_iqd`, `platform_cash_iqd`, `gmv_iqd`, `revenue_iqd`, `lifetime_refunds_iqd`.
- **Period View**: `public.vw_financial_metrics_period`
  - **Path**: [20260225_create_wallet_views.sql:L263](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260225_create_wallet_views.sql#L263)

## 3. Booking Finance (proposed: vw_admin_booking_finance)

- **Status**: The view `vw_unified_payable_items` exists but is intended for UI context. A dedicated admin booking finance view with "Money Story" is **MISSING** in the migrations.
- **Reference**: [SUPABASE_SETUP.md:L982](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L982) (vw_unified_work_items).

## 4. Admin Audit Logs

- **Table Definition**: `public.audit_logs`
  - **Path**: Used in `admin_update_system_config` [20260310101000...:L63](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260310101000_dashboard_public_config_reports_disputes_bridge.sql#L63).
  - **Admin Users**: `public.admin_users` table is referenced in policies.

## 5. Ledger backbone

- **Function**: `process_payment_event_ledger`
  - **Path**: [SUPABASE_SETUP.md:L1430](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1430)
  - **Events handled**: `escrow_hold`, `release_with_fee`, `refund`.
