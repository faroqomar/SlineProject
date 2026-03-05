# Docs Report — NotificationsFix (Notifications + Approve-and-Release Ledger Fix)

**Date:** 2026-03-02  
**Scope:** Notifications completion (server-authority, auth-aware stream, deep links) + ledger `release_with_fee` zero-amount and enum cast fix.  
**Plan:** `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`

---

## 1. Documentation Delta List

### 1.1 Docs Already Updated (per sync)

| Document | What was updated |
|----------|------------------|
| `Sline_everything/Sline_Log.md` | Version 2.17.1 entry: Notifications (service, viewmodel, deep_link, modal, badge, model, 20260226 tender migration); Approve-and-release (20260307 in-file, 20260308 patch, MCP apply); qicard_payment_service; verification refs and technical notes. |
| `Sline_everything/SUPABASE_SETUP.md` | Last Updated 2026-03-02; `process_payment_event_ledger` RPC: `release_with_fee` zero-amount skip and enum casts; changelog **Version 2.17.1 (March 2026)**. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Version 2.17.1, Last Updated 2026-03-02; Notifications bullet (server-generated, client read/update-only). |
| `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` | `release_with_fee` event row: only lines with amount > 0 inserted; entity status explicit enum casts (20260307–20260308). |
| `.TODO/Archive/NotificationExecution/DOCS_SYNC_2026-03-02_NotificationsAndReleaseFix.md` | Full sync note for 2.17.1. |

### 1.2 What Still Needs Updating

- **Reference path fixes:** Several docs still point to plan/execution/checklist under `.TODO/` root. Those files now live under `.TODO/Archive/NotificationExecution/`. See Section 2.
- **Optional:** `Sline_everything/STRUCTURE.md` — Last Updated is 2026-03-01; migration themes mention 20260303–20260307 but not 20260308. Adding 20260308 and setting Last Updated to 2026-03-02 would complete the delta for this scope.

---

## 2. Reference Integrity Scan

### 2.1 Broken References (paths that no longer exist)

| Location | Reference | Issue |
|----------|-----------|--------|
| `Sline_everything/Sline_Log.md` (lines 108–110) | `.TODO/PLAN_NotificationsFix_2026-03-01.md`, `.TODO/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`, `.TODO/CHECKLIST_NotificationsFix_Manual_Test.md` | Files were moved to `.TODO/Archive/NotificationExecution/`; links are dead at repo root. |
| `Sline_everything/MVP_ROADMAP.md` (line 67) | `.TODO/PLAN_NotificationsFix_2026-03-01.md` | Same; plan is in Archive. |
| `.TODO/ARCHITECT_REPORT_2026-03-02_NotificationsFix.md` (lines 5, 94–95) | `.TODO/PLAN_NotificationsFix_2026-03-01.md`, `.TODO/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md` | Same; should point to Archive paths. |

### 2.2 References That Are Correct or Acceptable

- `.TODO/OBSERVABILITY_REPORT_2026-03-02_NotificationsFix.md` correctly uses `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`.
- All `lib/features/notifications/` paths cited in Sline_Log exist: `notification_service.dart`, `notification_view_model.dart`, `notifications_modal.dart`, `notification_badge_button.dart`, `notification_model.dart`; `lib/core/services/deep_link_service.dart` exists.
- Migrations exist: `supabase/migrations/20260307_fix_ledger_event_type_enum.sql`, `supabase/migrations/20260308_fix_release_with_fee_zero_amount_and_enum.sql`, `supabase/migrations/20260226_tender_award_payment_flow.sql`.
- `SUPABASE_SETUP.md` RPC and changelog 2.17.1 accurately describe `release_with_fee` behavior and migrations.
- `DEVELOPER_GUIDE.md` notifications bullet and Wallet_Feature `release_with_fee` row match current behavior.
- Archive docs (e.g. `EXECUTION_LOG`, `CHECKLIST`, `DOCS_SYNC`, `TEST_notifications`) reference the short `.TODO/PLAN_...` form; since they sit next to the plan in Archive, intent is clear; fixing them to Archive paths would improve consistency.

### 2.3 Renamed / Moved Files (none)

No renames or moves of code or docs were required for this scope beyond the plan/execution/checklist move into `.TODO/Archive/NotificationExecution/`.

### 2.4 Outdated Statements (none)

- No outdated statements found in `Sline_everything/` regarding notifications (server-authority) or `release_with_fee` (zero-amount skip, enum casts). SUPABASE_SETUP, DEVELOPER_GUIDE, Wallet_Feature, and Sline_Log content are aligned with implementation.

---

## 3. Required Doc Updates

| # | File | Section / change | Priority |
|---|------|------------------|----------|
| 1 | `Sline_everything/Sline_Log.md` | **Verification** (2.17.1): Replace plan/execution/checklist paths with Archive paths: `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`, `.TODO/Archive/NotificationExecution/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`, `.TODO/Archive/NotificationExecution/CHECKLIST_NotificationsFix_Manual_Test.md`. | **Required** |
| 2 | `Sline_everything/MVP_ROADMAP.md` | **Notifications** row: Replace `.TODO/PLAN_NotificationsFix_2026-03-01.md` with `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`. | **Required** |
| 3 | `.TODO/ARCHITECT_REPORT_2026-03-02_NotificationsFix.md` | **Plan reference** and table: Use `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md` and `.TODO/Archive/NotificationExecution/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`. | **Required** |
| 4 | `Sline_everything/STRUCTURE.md` | **Optional:** Set Last Updated to 2026-03-02; add 20260308 to migration themes (release_with_fee zero-amount and enum patch). | Optional |

If the above three required path fixes are applied, doc and reference integrity for NotificationsFix scope are **synced**. No other sections or files are required for notifications or ledger `release_with_fee` for this release.

---

## 4. Evidence (Files Scanned and Paths Validated)

### 4.1 Docs Scanned

| Doc | Purpose |
|-----|--------|
| `Sline_everything/Sline_Log.md` | Version 2.17.1 entry and verification refs. |
| `Sline_everything/SUPABASE_SETUP.md` | Last Updated, RPC `release_with_fee`, changelog 2.17.1, notifications table/realtime. |
| `Sline_everything/DEVELOPER_GUIDE.md` | Version, Last Updated, Notifications bullet (server-authority). |
| `Sline_everything/DEVELOPER_GUIDE/Wallet_Feature.md` | `release_with_fee` event row and RPC behavior. |
| `Sline_everything/MVP_ROADMAP.md` | Notifications row and plan path. |
| `Sline_everything/STRUCTURE.md` | Last Updated, migration themes, notifications feature. |
| `Sline_everything/CODE_REVIEW.md` | No notifications/ledger changes required for this scope. |
| `Sline_everything/ARCHITECTURE_ANALYSIS.md` | No notifications/ledger updates required for this scope. |
| `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md` | Plan scope and references. |
| `.TODO/Archive/NotificationExecution/DOCS_SYNC_2026-03-02_NotificationsAndReleaseFix.md` | Confirmed doc updates and refs. |
| `.TODO/ARCHITECT_REPORT_2026-03-02_NotificationsFix.md` | Plan/log paths. |
| `.TODO/OBSERVABILITY_REPORT_2026-03-02_NotificationsFix.md` | Plan path (already Archive). |

### 4.2 Paths Validated

- **Lib:** `lib/features/notifications/services/notification_service.dart`, `lib/features/notifications/viewmodels/notification_view_model.dart`, `lib/features/notifications/view/notifications_modal.dart`, `lib/features/notifications/view/widgets/notification_badge_button.dart`, `lib/features/notifications/models/notification_model.dart`, `lib/core/services/deep_link_service.dart`, `lib/core/services/qicard_payment_service.dart` — **all exist.**
- **Migrations:** `supabase/migrations/20260226_tender_award_payment_flow.sql`, `supabase/migrations/20260307_fix_ledger_event_type_enum.sql`, `supabase/migrations/20260308_fix_release_with_fee_zero_amount_and_enum.sql` — **all exist.**
- **.TODO:** `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`, `EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`, `CHECKLIST_NotificationsFix_Manual_Test.md`, `DOCS_SYNC_2026-03-02_NotificationsAndReleaseFix.md` — **all exist under Archive/NotificationExecution.** Root paths `.TODO/PLAN_NotificationsFix_2026-03-01.md` and siblings — **do not exist** (moved to Archive).

---

End of report.
