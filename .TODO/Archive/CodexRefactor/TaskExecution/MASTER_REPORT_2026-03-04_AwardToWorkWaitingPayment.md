# Master Report: Award to Work Waiting Payment

**Date:** 2026-03-04  
**Scope:** Award to Work Waiting Payment (Inbox → Work "Waiting payment" + Pay/Cancel)  
**Plan Reference:** Award → Work Section + Waiting Payment + Cancel (implemented)

---

## A) Executive Summary

- **What was reviewed:** Full flow from Award (Inbox) → task in Work tab as "Waiting payment" → Pay (TenderPaymentScreen) or Cancel (cancel_awarded_offer). Backend migration (cancel_awarded_offer RPC, vw_unified_work_items third branch), app models/repo/permissions, TaskService/DashboardViewModel, InboxTab/WorkTab/WorkItemCard/NextActionsList, and docs.
- **Overall risk level:** **LOW.** No BLOCKER from any agent.
- **Final decision:** **Ready ✅** — No gates triggered. Optional improvements (observability logs, doc tweaks, optional index) can be done in follow-up.

---

## B) Consolidated Findings (Deduplicated)

### Security

| # | Severity | Owner | Path / Object | Fix |
|---|----------|--------|----------------|-----|
| 1 | LOW | CodeGuard | cancel_awarded_offer RPC | None. SECURITY DEFINER with owner check; only accepted/unpaid reverted. |

### Data Integrity

| # | Severity | Owner | Path / Object | Fix |
|---|----------|--------|----------------|-----|
| 2 | LOW | Architect | vw_unified_work_items | Ensure migration uses COALESCE(t.client_id, t.owner_id); already present. If schema has only owner_id, no change. |

### Architecture / MVVM

| # | Severity | Owner | Path / Object | Fix |
|---|----------|--------|----------------|-----|
| 3 | LOW | Architect | work_tab / next_actions_list | Optional: extract single helper openTenderPaymentScreen(context, requestId, title, …) to reduce duplication. Non-blocking. |

### Performance

| # | Severity | Owner | Path / Object | Fix |
|---|----------|--------|----------------|-----|
| 4 | LOW | CodeGuard | task_requests + vw_unified_work_items 3rd branch | Optional: add index on task_requests(task_id, status, payment_status) if query plans show need. |

### Observability

| # | Severity | Owner | Path / Object | Fix |
|---|----------|--------|----------------|-----|
| 5 | MED | Observability | lib/features/dashboard/view/tabs/work_tab.dart | Add AppLogger.i when opening TenderPaymentScreen for task+payEscrow (requestId, taskId); and when user taps Cancel (requestId). Tag: dashboard.work. |
| 6 | LOW | Observability | lib/features/dashboard/view/widgets/next_actions_list.dart | Optional: log "NextActions: opening tender payment request=..." for consistency. |
| 7 | LOW | Observability | lib/features/dashboard/view/tabs/inbox_tab.dart | Optional: log "Inbox: award success, switching to Work tab" for funnel. |

### Docs / Reference Integrity

| # | Severity | Owner | Path / Object | Fix |
|---|----------|--------|----------------|-----|
| 8 | MED | SlineDocs | Sline_everything/DEVELOPER_GUIDE.md | Update vw_unified_work_items description: "UNION ALL of tasks (in progress + awarded pending payment) and bookings"; add sentence that Award moves task to Work as Waiting payment, Pay/Cancel from there. |
| 9 | LOW | SlineDocs | Sline_everything/Sline_Log.md | Add changelog entry: Award → Work flow, cancel_awarded_offer, vw_unified_work_items third branch. |

---

## C) Fix Plan (Ordered, Step-by-Step)

No BLOCKER; fixes are optional. Recommended order if implementing:

| Step | Owner | Action | Verification |
|------|--------|--------|---------------|
| 1 | @Observability | Add 1–2 info logs in work_tab.dart: Pay from Work (requestId/taskId), Cancel (requestId). Tag: dashboard.work. | grep AppLogger work_tab.dart; run flow and check logs. |
| 2 | @SlineDocs | Update DEVELOPER_GUIDE.md: vw_unified_work_items table text + Award → Work sentence. | Read DEVELOPER_GUIDE.md §Dashboard. |
| 3 | @SlineDocs | Add Sline_Log.md entry for Award → Work + cancel_awarded_offer + view branch. | Read Sline_Log.md. |
| 4 | @Supabase_Ops (optional) | If view third-branch queries are slow: add index task_requests(task_id, status, payment_status). | EXPLAIN on SELECT from vw_unified_work_items WHERE unified_status = 'pending_payment'. |
| 5 | @CodeGuard | Re-run review after Step 1–3 if desired (no gate re-run required). | flutter analyze; manual Pay/Cancel from Work. |

---

## D) Regression Checklist

- **Award from Inbox:** Offer → Award → task appears under Work as "Waiting payment"; no immediate Pay screen.
- **Pay from Work:** Tap Pay on waiting-payment task → TenderPaymentScreen with correct request/title/amount/deadline; QiCard or Demo flow completes; task moves to in-progress (or paid state).
- **Cancel from Work:** Tap Cancel → confirm → task leaves Work; offer/task back in Inbox (or re-awardable).
- **Permissions:** Only client sees Pay/Cancel for pending-payment items; canCancel only for client + pendingPayment.
- **View:** vw_unified_work_items returns rows with unified_status = 'pending_payment', awarded_request_id and payment_deadline set.

Quick test: Award one offer → open Work → Pay (or Cancel) → verify state and, for Pay, payment flow.

---

## E) Rollback Notes

- **App:** Revert dashboard/work/task changes (WorkItem model, repo mapping, permission, VM cancelAwardedOffer, InboxTab setTab, WorkTab/WorkItemCard/NextActionsList Pay and Cancel). Revert TaskService.cancelAwardedOffer. No data migration in app.
- **DB:** To rollback migration 20260315000000: drop view vw_unified_work_items; drop function cancel_awarded_offer; recreate vw_unified_work_items from previous migration (two-branch version). Restore previous view before re-running app that expects two branches only.
- **Docs:** Revert SUPABASE_SETUP.md §6.4 and DEVELOPER_GUIDE/Sline_Log changes if doc-only rollback needed.

---

## Next Actions

1. **Optional:** Implement Observability and SlineDocs fixes (Steps 1–3 above).
2. **Optional:** Add index on task_requests for view performance (Step 4).
3. Deploy migrations 20260313000000 and 20260315000000 to target environment if not already applied.
4. Run regression checklist before release.
