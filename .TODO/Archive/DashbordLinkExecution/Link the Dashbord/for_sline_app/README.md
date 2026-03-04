# Migrations to copy into sline_app

Copy the SQL files in this folder into **sline_app** (`/Users/eros/Dev/Eros_Projects/Sline/sline_app/supabase/migrations/`) so the app repo owns canonical schema. Apply in order:

1. `YYYYMMDD_extend_related_entity_type_enum.sql` (run after ledger/audit_logs exist)
2. `YYYYMMDD_admin_process_withdrawal.sql` (run after withdrawal_requests and audit_logs exist)
3. `20260302140000_force_logout.sql` (PAGE 06: profiles.force_logout_after + admin_force_logout_user RPC; see FORCE_LOGOUT_APP_ENFORCEMENT.md)
4. `20260302120000_admin_booking_rpcs.sql` (PAGE 07: admin_cancel_booking and admin_refund_booking RPCs; apply after bookings and audit_logs exist)

Use timestamps that sort after your existing sline_app migrations (e.g. `20260302100000`, `20260302110000`).

After copying, apply in sline_app with `supabase db push` or your usual migration flow. Dashboard and app share the same DB when both use these migrations.

**Audit:** For approve/reject, `admin_process_withdrawal` is the single writer to `audit_logs` (one row per decision). The dashboard API does not wrap these calls in `withAudit`, so there is no double audit.
