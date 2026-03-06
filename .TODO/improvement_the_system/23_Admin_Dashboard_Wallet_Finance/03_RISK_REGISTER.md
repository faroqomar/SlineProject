# Skills Applied

- **Skills selected**: Threat Modeling (Security), Invariants & Contracts
- **Why these skills fit**: Identifying business and technical risks that could break the "source of truth" for platform finances.

---

# 03 Risk Register: Admin & Finance

## J1) Risks if we keep the current system

| Risk ID           | Severity | Likelihood | Impact                                                            | Evidence                                                                                                                                                              |
| ----------------- | -------- | ---------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R1: PII Leak      | 🔴 Crit  | High       | Exposure of user emails via `public.users` view.                  | [SUPABASE_SETUP.md:L1000](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/Sline_everything/SUPABASE_SETUP.md#L1000)                                              |
| R2: Audit Gap     | 🟡 Med   | Med        | No formal link between `audit_logs` and `ledger_lines`.           | Ledger is in `public`, Audit is in `public`, but they are decoupled.                                                                                                  |
| R3: Scale Latency | 🟡 Med   | Low        | CTE-heavy financial views will slow down as `ledger_lines` grows. | [20260225_create_wallet_views.sql:L18-L49](file:///Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/Archive/20260225_create_wallet_views.sql#L18-L49) |

## J2) Risks introduced by improvements

| Risk ID                   | Mitigation                                                                      | Complexity |
| ------------------------- | ------------------------------------------------------------------------------- | ---------- |
| M1: Migration Lock        | Use concurrent index creation and small batch updates.                          | High       |
| M2: Logic Drift           | Align `process_payment_event_ledger` with the new `admin_booking_finance` view. | Med        |
| M3: Edge Function Latency | Cache `system_config` results in the App for non-critical flags (banner).       | Low        |
