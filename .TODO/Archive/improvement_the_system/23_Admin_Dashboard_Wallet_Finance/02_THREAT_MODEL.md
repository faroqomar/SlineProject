# Skills Applied

- **Skills selected**: Threat Modeling (Security), Evidence-First Reading
- **Why these skills fit**: Evaluating the system for adversarial abuse, PII leaks, and RLS bypasses based on documented vulnerabilities in the codebase.

---

# 02 Threat Model: Admin & Finance

## T1: RLS Bypass via Security Definer Views

- **Evidence**: `public.users` and `public.tasks_mvp` are `SECURITY DEFINER`.
  - [SUPABASE_SETUP.md:L1000-L1008](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1000-L1008)
- **Attack**: Anonymous users can query `public.users` to extract emails and full names of all users.
- **Impact**: High (PII Leak).

## T2: Financial Dashboard Data Leak

- **Evidence**: `vw_financial_metrics_realtime` and `vw_financial_metrics_period` were granted to `authenticated` users by default.
  - [20260225_create_wallet_views.sql:L429-L430](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260225_create_wallet_views.sql#L429-L430)
- **Mitigation**: A recent migration revoked these permissions.
  - [20260309_restrict_dashboard_finance_views.sql:L5-L6](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260309_restrict_dashboard_finance_views.sql#L5-L6)
- **Residual Risk**: Any new view created without `security_invoker = on` defaults to `security_definer` (or owner) which might leak data if RLS is not applied to the view itself.

## T3: Lack of "Money Story" Traceability

- **Evidence**: The system relies on `je.meta` (JSONB) to store context for ledger entries.
  - [20260225_create_wallet_views.sql:L149-L154](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260225_create_wallet_views.sql#L149-L154)
- **Attack**: If `process_payment_event_ledger` is called with malicious `meta` or if the `meta` construction logic has a bug, the "audit trail" becomes untruthful.
- **Safety**: Ledger entries themselves are immutable via `trg_wallet_transactions_freeze` logic applied to old table, but new `ledger_lines` lack an explicit "freeze" trigger (they rely on RLS/lack of update RPCs).

## T4: Configuration Sabotage

- **Evidence**: `admin_update_system_config` is `SECURITY DEFINER` and granted to `service_role`.
  - [20260310101000...sql:L76-L77](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260310101000_dashboard_public_config_reports_disputes_bridge.sql#L76-L77)
- **Risk**: If the Edge Function calling this RPC is compromised or has an authentication flaw, an attacker can set `maintenance_mode = true` or redirect users via `min_app_version` logic.
- **Audit**: Partial protection exists via `INSERT INTO public.audit_logs`.
