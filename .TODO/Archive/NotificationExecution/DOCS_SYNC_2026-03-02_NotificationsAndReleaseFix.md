# Docs Sync — Notifications Completion + Approve-and-Release Ledger Fix

**Date:** 2026-03-02  
**Scope:** Version 2.17.1 — notifications server-authority, auth-aware stream, deep links; ledger `release_with_fee` zero-amount and enum cast fix.

---

## 1. Doc Files Updated

| File | Changes |
|------|--------|
| `Sline_everything/Sline_Log.md` | Added **Version 2.17.1** entry: Notifications (service, viewmodel, deep link, modal, badge, model, tender migration); Approve-and-release (20260307 in-file, 20260308 patch, MCP apply); qicard_payment_service brace. Verification and technical notes. |
| `Sline_everything/SUPABASE_SETUP.md` | **Last Updated** line; **process_payment_event_ledger** RPC section: `release_with_fee` now documents zero-amount skip and enum casts, migrations 20260307/20260308. **Changelog:** New **Version 2.17.1 (March 2026)** with ledger fix details. |
| `Sline_everything/DEVELOPER_GUIDE.md` | **Version** and **Last Updated** set to 2.17.1 and 2026-03-02. (Notifications bullet already present from prior diff.) |
| `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` | **release_with_fee** event row: added note that only lines with amount > 0 are inserted and entity status uses explicit enum casts (20260307–20260308). |

---

## 2. Summary of Changes

- **Notifications:** Documented as completed in Sline_Log with file paths (notification_service, notification_view_model, deep_link_service, notifications_modal, notification_badge_button, notification_model, 20260226 tender migration). Cross-references: PLAN_NotificationsFix_2026-03-01, EXECUTION_LOG, CHECKLIST_NotificationsFix_Manual_Test.
- **Ledger release_with_fee:** Documented root cause (zero-amount line, enum/plan mismatch), fix (INSERT...WHERE amount > 0; explicit enum casts), migration names, and optional remote apply via MCP in Sline_Log and SUPABASE_SETUP. Wallet_Feature release_with_fee table updated to match.

---

## 3. References Validated

- `.TODO/PLAN_NotificationsFix_2026-03-01.md` — referenced in Sline_Log (plan path).
- `.TODO/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md` — referenced.
- `.TODO/CHECKLIST_NotificationsFix_Manual_Test.md` — referenced.
- `supabase/migrations/20260307_fix_ledger_event_type_enum.sql` — exists; referenced in SUPABASE_SETUP, Sline_Log, Wallet_Feature.
- `supabase/migrations/20260308_fix_release_with_fee_zero_amount_and_enum.sql` — exists; referenced in SUPABASE_SETUP, Sline_Log.
- All lib paths in Sline_Log entry exist (notification_service, notification_view_model, deep_link_service, notifications_modal, notification_badge_button, notification_model, qicard_payment_service).

---

## 4. Why Each Update Was Needed

- **Sline_Log:** Feature completion (notifications) and patch (release_with_fee) must be on the master timeline with exact paths and verification.
- **SUPABASE_SETUP:** RPC behavior and changelog are single source of truth for DB; release_with_fee behavior change affects all callers.
- **DEVELOPER_GUIDE:** Version and date reflect current release; Wallet_Feature event table must match actual RPC behavior for release_with_fee.

---

End of Docs Sync.
