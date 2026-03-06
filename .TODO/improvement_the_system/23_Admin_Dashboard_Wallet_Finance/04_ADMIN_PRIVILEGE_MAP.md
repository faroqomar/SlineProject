# Skills Applied

- **Skills selected**: RLS & Privilege Boundaries, Observability
- **Why these skills fit**: Documenting the security boundary between standard users, admins, and the system-wide service role.

---

# 04 Admin Privilege Map: Finance & Audit

## 1. Role Definitions

| Role                    | Access Level  | Description                                                       |
| ----------------------- | ------------- | ----------------------------------------------------------------- |
| **anon**                | Zero          | No access to financial data.                                      |
| **authenticated**       | User-Scrubbed | Access to own wallet balances/activity only (`vw_wallet_*_user`). |
| **admin (in profiles)** | Restricted    | Access to reports and user moderation via RPCs.                   |
| **service_role**        | Full          | Owner of all ledger data. Access to platform metrics.             |

## 2. Financial View Boundaries

| View / Function                 | Role: Authenticated | Role: Admin | Role: service_role |
| ------------------------------- | ------------------- | ----------- | ------------------ |
| `vw_financial_metrics_realtime` | ❌ REVOKED          | ❌ REVOKED  | ✅ ALLOW           |
| `vw_financial_metrics_period`   | ❌ REVOKED          | ❌ REVOKED  | ✅ ALLOW           |
| `admin_update_system_config`    | ❌ NO               | ❌ NO       | ✅ ALLOW           |
| `get_public_system_config`      | ✅ ALLOW            | ✅ ALLOW    | ✅ ALLOW           |

## 3. Observability Matrix

- **Internal (Supabase Logs)**: Tracks every SQL query. Restricted to project owners.
- **Audit Table (`audit_logs`)**: Tracks intentional admin actions (config changes, moderation).
- **Ledger (`ledger_lines`)**: Tracks immutable financial movement.
- **Access Logs (`admin_pii_access_logs`)**: Tracks when an admin views sensitive user data.
