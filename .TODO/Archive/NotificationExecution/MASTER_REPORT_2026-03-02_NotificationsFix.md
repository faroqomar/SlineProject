# Master Report — NotificationsFix (Orchestrator)

**Date:** 2026-03-02  
**Scope:** Notifications server-authority completion + Approve-and-Release ledger fix  
**Plan:** `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`  
**Pipeline:** Architect → Observability → SlineDocs → CodeGuard

---

## A) Executive Summary

| Item | Result |
|------|--------|
| **What was reviewed** | Notifications feature (service, viewmodel, modal, badge, model, deep links), ledger `release_with_fee` path (migrations 20260307, 20260308), and related docs. |
| **Overall risk level** | **MEDIUM** (auth lifecycle, RLS, ledger; no new client write paths). |
| **Final decision** | **Ready** — No blockers. CodeGuard **APPROVED**. Optional doc path fixes and observability improvements recommended. |

---

## B) Consolidated Findings (Deduplicated)

### Security

| Severity | Owner | Finding | Fix |
|----------|--------|---------|-----|
| — | CodeGuard | No client notification inserts; RLS + user_id scoping verified; ledger actor + idempotency in DB. | None. |
| LOW | Architect | Optional: harden `NotificationItem.fromJson` for null `title`/`message` if server can send. | Use `as String?` with default in model. |

### Data Integrity

| Severity | Owner | Finding | Fix |
|----------|--------|---------|-----|
| — | Architect | Ledger 20260307/20260308: zero-amount line skipped, enum casts; contract aligned. | None. |

### Architecture / MVVM

| Severity | Owner | Finding | Fix |
|----------|--------|---------|-----|
| — | Architect | Views: no direct Supabase; ViewModel context-free; navigation in view layer; service read/update-only. | None. |
| LOW | Architect | Optional: centralize supported entity types (list/enum) in DeepLinkService for contract consistency. | Extract supported types; document in CONTRACT. |

### Performance

| Severity | Owner | Finding | Fix |
|----------|--------|---------|-----|
| — | CodeGuard | Stream limit 50; single subscription; disposal on logout and in ViewModel.dispose(). | None. |

### Observability

| Severity | Owner | Finding | Fix |
|----------|--------|---------|-----|
| MED | Observability | No structured `notification_tap` by type; deep link success not logged; no correlation_id tap→destination. | Add structured events; optional correlation_id on tap. |
| MED | Observability | LedgerService does not log success when RPC returns ok; no shared event name across booking/task/direct_offer release. | Log success in LedgerService; align event names. |
| LOW | Observability | LedgerService and some DeepLink paths missing or inconsistent tags. | Use tag `LedgerService` / `DeepLink` consistently. |

### Docs / Reference Integrity

| Severity | Owner | Finding | Fix |
|----------|--------|---------|-----|
| HIGH | SlineDocs | Sline_Log, MVP_ROADMAP, ARCHITECT_REPORT reference plan/execution/checklist at `.TODO/` root; files live under `.TODO/Archive/NotificationExecution/`. | Update refs to Archive paths (see Fix Plan). |
| LOW | SlineDocs | STRUCTURE.md: Last Updated 2026-03-01; migration themes omit 20260308. | Optional: set 2026-03-02, add 20260308. |

---

## C) Fix Plan (Ordered, Step-by-Step)

### Step 1 — Doc reference fixes (required)

**Owner:** @SlineDocs (or implementer)

1. **Sline_Log.md** (Version 2.17.1 Verification): Replace:
   - `.TODO/PLAN_NotificationsFix_2026-03-01.md` → `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`
   - `.TODO/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md` → `.TODO/Archive/NotificationExecution/EXECUTION_LOG_PLAN_NotificationsFix_2026-03-01.md`
   - `.TODO/CHECKLIST_NotificationsFix_Manual_Test.md` → `.TODO/Archive/NotificationExecution/CHECKLIST_NotificationsFix_Manual_Test.md`
2. **MVP_ROADMAP.md** (Notifications row): Replace plan link with `.TODO/Archive/NotificationExecution/PLAN_NotificationsFix_2026-03-01.md`.
3. **ARCHITECT_REPORT_2026-03-02_NotificationsFix.md**: Update plan reference and table to use Archive paths for plan and execution log.

**Verification:** Grep for `.TODO/PLAN_NotificationsFix` and `.TODO/EXECUTION_LOG_PLAN_NotificationsFix` in Sline_everything and .TODO; all should point to Archive.

---

### Step 2 — Optional: Observability improvements

**Owner:** @Observability (or implementer)

- Add structured events: `notification_tap` (entity_type, outcome), `deep_link_routed` (entity_type, id), `ledger_release_with_fee_success` / `_failure` with consistent tag (e.g. `LedgerService`).
- Optionally add correlation_id on notification tap and propagate through DeepLinkService.
- Ensure LedgerService logs success when RPC returns `ok: true`; use tag `LedgerService` on all log calls.

**Verification:** Run notification tap and approve-and-release flows; confirm new log lines and tags in console.

---

### Step 3 — Optional: Model and contract hardening

**Owner:** @Architect (or implementer)

- NotificationItem.fromJson: if server can send null `title`/`message`, use safe casts with defaults.
- DeepLinkService: extract supported entity types list/enum; align with CONTRACT.

**Verification:** Unit test for fromJson with null title/message; CONTRACT or DEVELOPER_GUIDE updated with entity list.

---

### Step 4 — CodeGuard gate re-run (optional)

After Step 1 (and optionally 2–3), re-run CodeGuard on the same scope to confirm no regressions and that doc refs are valid.

**Verification:** `flutter analyze` on notifications scope; grep for broken .TODO paths.

---

## D) Regression Checklist

| Flow | How to test quickly |
|------|----------------------|
| Notifications stream | Sign in → open notification modal → confirm list loads; sign out → confirm empty/list clears. |
| Notification tap → deep link | Tap notification (booking/task/conversation/task_request) → confirm correct screen opens. |
| task_request routing | Tap task_request notification → confirm conversation or task opens per metadata. |
| Mark as read | Tap row → modal closes → reopen modal → same row shows read. |
| Approve and release | Client: delivered booking → Approve and release → confirm success (no ck_ledger_lines_amount_positive or parameter 40 error). |
| Ledger zero fee | Use booking with fee_rate_bps: 0 → release → confirm only 2 ledger lines (escrow debit, provider credit). |

---

## E) Rollback Notes

| Area | Rollback if needed |
|------|--------------------|
| Notifications (app) | Revert notification_service, notification_view_model, notifications_modal, notification_badge_button, notification_model, deep_link_service; restore previous modal tap flow and ViewModel.handleNotificationTap. |
| Ledger (DB) | 20260308 is idempotent patch; to revert behavior, re-apply old RELEASE_WITH_FEE block via new migration (restore INSERT without WHERE amount > 0 and without enum casts). 20260307 in-file: same; new migration to revert. |
| Docs | Revert Sline_Log 2.17.1 entry, SUPABASE_SETUP changelog and RPC note, DEVELOPER_GUIDE version, Wallet_Feature row, DOCS_SYNC; restore previous plan/execution refs if changed. |

---

## F) Agent Outputs (Evidence)

| Agent | Report path | Decision / summary |
|-------|-------------|--------------------|
| @Architect | `.TODO/ARCHITECT_REPORT_2026-03-02_NotificationsFix.md` | MVVM and server-authority compliant; no mandatory refactors. |
| @Observability | `.TODO/OBSERVABILITY_REPORT_2026-03-02_NotificationsFix.md` | Gaps: structured events, correlation, Ledger success log and tags. |
| @SlineDocs | `.TODO/DOCS_REPORT_2026-03-02_NotificationsFix.md` | Required: fix plan/execution/checklist refs to Archive paths. |
| @CodeGuard | `.TODO/CODEGUARD_REVIEW_2026-03-02_NotificationsFix.md` | **APPROVED**; no blockers; 2 unused imports fixed in tests. |

---

## G) Next Actions

1. **Required:** Apply Step 1 (doc reference fixes) so Sline_Log, MVP_ROADMAP, and ARCHITECT_REPORT point to `.TODO/Archive/NotificationExecution/` for plan, execution log, and checklist.
2. **Optional:** Implement Observability recommendations (Step 2); then optional model/CONTRACT hardening (Step 3).
3. **Optional:** Re-run CodeGuard after doc fixes (Step 4).
4. **Ship:** Scope is **Ready**; no blockers. Merge after Step 1 (and any optional steps per team policy).

---

End of Master Report.
