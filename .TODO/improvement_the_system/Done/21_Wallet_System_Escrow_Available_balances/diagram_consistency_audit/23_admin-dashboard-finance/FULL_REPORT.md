# FULL REPORT: 23 Admin Dashboard Wallet Finance

## 0) Skill Selection

- **Skills selected**: Repo Mapping, Evidence-First Reading, Threat Modeling (Security), DB-First Financial Modeling, Diagram Crafting.
- **Why these fit**: The Admin Finance view is a read-only aggregation of states managed by other systems. It defines the "Accounting Truth" providing GMV and Earnings metrics. Modeling this requires strict access controls (RLS, Threat Modeling) and a deep read of the Ledger views (Repo Mapping).
- **Skills not used**: State Machine & Lifecycle.

## 1) Folder Identity

- **Folder name + path**: `.TODO/improvement_the_system/23_Admin_Dashboard_Wallet_Finance`
- **What system/feature it describes**: The Financial Observability layer for Platform Admins to monitor Platform Revenue, Escrow Liabilities, and details of individual transactions.
- **Entities involved**: `system_config`, `ledger_lines`, `journal_entries`, `accounts`, `vw_admin_finance_*`.

## 2) Human Explanation

SLine's business owners need to know how much money is sitting in Escrow (their liability) versus how much they have earned (Platform Revenue). They also need to adjust the platform fee globally. The Admin Dashboard interacts with `system_config` to explicitly update fees (logging via `admin_logs`). It then queries protected Supabase Views mapping the thousands of `ledger_lines` into clean totals for GMV, Net Cash, and drill-down views of single bookings outlining the exact Gross/Fee/Net split.

## 3) Symbol Legend

- **Rectangles**: Admin vs Logic API vs DB Config vs DB Views.
- **Solid Arrows**: Explicit RPC action paths setting global configs.
- **Dashed Logic**: Financial aggregates grouping and returning accounting metrics.

## 4) Extracted Contracts & Invariants

1. **Fee Locking**: The `fee_rate_applied` must be a snapshot in `bookings` and NOT a dynamic JOIN to the current setting.
2. **Double-Entry Equilibrium**: Total `ledger_lines` for any specific entity must sum to zero.
3. **Admin Exclusivity**: Financial metric views must be strictly restricted to `service_role` or specific Admin RBAC to prevent leaking the entire platform's income limits.

## 5) Conflict Scan Results

### 5.1 Naming Drift

- **Conflict**: Legacy mismatch naming Views.
- **Resolution**: Standardize `vw_admin_finance_overview` for clarity.

### 5.2 Logic Drift

- **Conflict**: Original diagram omitted the actual `system_config` table and assumed "Admin Server Actions" mapped magically to numbers.
- **Resolution**: Explicit mapping of `UPDATE_CONFIG` to `public.system_config`.

### 5.3 Data Model Drift

- **Conflict**: Serious security flaw leaving `public.users` exposed in definitions.
- **Resolution**: Drop `public.users` immediately. Aggregations must join `profiles` safely.

## 6) Security & Failure Modes (Adversarial)

- **PII Harvest / Data Leak**: An attacker queries a `SECURITY DEFINER` finance view to scrape platform data.
  - _Mitigation_: Ensure `vw_admin_finance_overview` restricts `SELECT` purely to `service_role` context. Flutter apps cannot hit it.
- **Configuration Injection**: Rogue admin or stolen token sets `fee_rate_default` to 1.0 (100% kickback).
  - _Mitigation_: Add `CHECK` constraint capping fees at a logical maximum (e.g. 2500 bps).

## 7) UI Mapping

### 7.1 Mobile App UI

- **Screens**: Inapplicable. Admins ONLY.
- **States**: N/A.
- **Guardrails**: Hard block any references to these views in the Flutter SDK code.

### 7.2 Admin Dashboard UI

- **Pages**: Finance Dashboard, Booking Timeline.
- **Metrics**: GMV, Revenue, Escrow Liabilities. Data Table of drilldowns per booking.
- **Drilldowns**: Connecting Booking ID to specific filtered `journal_entries`.

### 7.3 Implementation Hooks

- Secure Server Webhook Dashboard.

## 8) Diagram Verdict + Best Diagram Type

- **Score now**: 9/10 (Post-fixes)
- **Best Diagram Type**: Component Diagram & Sequence Diagram delineating the "Untrusted" app vs the "Trusted" Admin layers.

## 9) Upgrade Plan

- **Phase 0: Observability**: Ensure `admin_logs` tracks `admin_update_system_config` accurately.
- **Phase 1: Contracts**: Drop `public.users`.
- **Phase 2: Hardening**: Deploy `vw_admin_finance_overview` and strictly limit its RLS `select` usage to Admin configurations.
- **Phase 3: Scale**: Add triggers to populate a daily cached materialized view if computing ledger math over `vw_admin_finance_overview` times out on 5+ second queries.

## 10) Risks

### 10.1 Risks if current version kept

- **Data Scraping Risk**: The `public.users` exposure is lethal.

### 10.2 Risks introduced by fixes

- **Timeout**: CTE-heavy views (`vw_admin`) on a massive ledger table. _Mitigation_: Run background ETL tasks or Materialized Views if performance degrades.

## 11) Test Plan (High-value)

- **Security Check**: As a standard user, attempt `SELECT * FROM vw_admin_finance_overview`. Assert Row-Level Security explicitly blocks the read.
- **Data Verification**: Assure that changing `system_config` updates the very next `escrow_hold` snapshot dynamically.

## 12) Production Checklist

- [ ] Drop `public.users` immediately.
- [ ] Deploy restricted Admin Views.
- [ ] `system_config` capped by constraints.
