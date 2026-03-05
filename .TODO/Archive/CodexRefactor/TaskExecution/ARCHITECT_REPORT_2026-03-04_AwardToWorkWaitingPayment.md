# Architect Report: Award to Work Waiting Payment

**Date:** 2026-03-04  
**Scope:** Award to Work Waiting Payment (Inbox → Work "Waiting payment" + Pay/Cancel)  
**Plan:** Award → Work Section + Waiting Payment + Cancel

---

## 1. Architecture / Logic Findings

### 1.1 MVVM Boundary Check

- **View → ViewModel:** InboxTab, WorkTab, WorkItemCard, NextActionsList call `DashboardViewModel.awardOffer`, `cancelAwardedOffer`, `performPrimaryAction`, `setTab`. No direct Supabase in views. **OK.**
- **ViewModel → Service/Repo:** DashboardViewModel uses TaskService (awardOffer, cancelAwardedOffer), DashboardRepository (fetchWorkItems). No DB access in ViewModel. **OK.**
- **Work tab Pay flow:** WorkTab._onPrimaryAction and NextActionsList open TenderPaymentScreen by building TenderPaymentCoordinator and TenderPaymentViewModel in the View and pushing a new route. Navigation and coordinator creation are in the View layer; business logic (executePayment, recoverTenderPayment) stays in Coordinator/ViewModel. **OK.**

### 1.2 Data Flow Map

- **Award:** Inbox → `vm.awardOffer(offer)` → TaskService.awardOffer (RPC `award_task_offer`) → success → `vm.refresh()` → `vm.setTab(activeWork, workSubTab: 0)`. Work items come from `vw_unified_work_items` (includes awarded-pending-payment branch). **Correct.**
- **Pay from Work:** WorkItemCard/NextActionsList primary action → WorkTab._onPrimaryAction (or next_actions_list) → if task + payEscrow + awardedRequestId: push TenderPaymentScreen with requestId, title, counterpartyName, price, paymentDeadline from WorkItem. **Correct.** Coordinator uses PaymentService (QiCard create → WebView → recovery) or throws for Demo.
- **Cancel:** WorkItemCard onSecondaryAction → WorkTab._onCancelAward → `vm.cancelAwardedOffer(item.awardedRequestId!)` → TaskService.cancelAwardedOffer (RPC `cancel_awarded_offer`) → vm.refresh(). **Correct.**

### 1.3 Contract Checks

- **cancel_awarded_offer:** SECURITY DEFINER, checks task owner via `v_task.owner_id = p_client_id`. Only reverts accepted/unpaid. **OK.**
- **vw_unified_work_items:** Third branch joins tasks (status = 'assigned', assigned_freelancer_id IS NULL) with task_requests (accepted, unpaid). Exposes `awarded_request_id`, `payment_deadline`. Client filters by `client_id` (COALESCE(t.client_id, t.owner_id)). **OK.** Note: If `tasks.client_id` does not exist in deployed DB, migration must use only `t.owner_id`.

### 1.4 Proposed Refactors (Non-Blocking)

- **WorkItem.price:** Added as optional for tender pending-payment; only set from unified view for the awarded branch. Consider documenting that `price` is null for non-tender or non–pending-payment items.
- **TenderPaymentScreen entry points:** Same flow is triggered from Inbox (_handlePayAwardedOffer), Work tab (_onPrimaryAction), and NextActionsList. Consider a single helper (e.g. `openTenderPaymentScreen(context, requestId, title, ...)`) to avoid duplication—**LOW** priority.

---

## 2. Path Validation

| Path | Exists | Notes |
|------|--------|--------|
| supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql | Yes | cancel_awarded_offer + vw_unified_work_items three branches |
| lib/features/work/models/unified_work_item_model.dart | Yes | awardedRequestId, paymentDeadline added |
| lib/features/dashboard/models/work_item.dart | Yes | awardedRequestId, paymentDeadline, price added |
| lib/features/dashboard/data/dashboard_repository.dart | Yes | Maps awarded_request_id, payment_deadline, price |
| lib/features/dashboard/services/dashboard_permission_service.dart | Yes | canCancel: true for client + pendingPayment |
| lib/features/dashboard/viewmodels/dashboard_view_model.dart | Yes | cancelAwardedOffer; no change to performPrimaryAction (Pay handled in View) |
| lib/features/tasks/services/task_service.dart | Yes | cancelAwardedOffer RPC |
| lib/features/dashboard/view/tabs/inbox_tab.dart | Yes | Award → refresh + setTab(activeWork) |
| lib/features/dashboard/view/tabs/work_tab.dart | Yes | _onPrimaryAction opens TenderPaymentScreen for task+payEscrow+awardedRequestId; _onCancelAward |
| lib/features/dashboard/view/widgets/work_item_card.dart | Yes | Cancel payment button when onSecondaryAction != null |
| lib/features/dashboard/view/widgets/next_actions_list.dart | Yes | Task+payEscrow+awardedRequestId → TenderPaymentScreen; onSecondaryAction for cancel |

---

## 3. Risk Notes

- **DB column tasks.client_id:** Migration uses `COALESCE(t.client_id, t.owner_id)`. If the deployed schema has only `owner_id`, the view is still valid. If neither exists, the migration would fail at deploy time.
- **RLS:** cancel_awarded_offer and award_task_offer are SECURITY DEFINER with explicit owner checks. vw_unified_work_items uses security invoker; RLS on tasks, task_requests, bookings applies.

---

**Conclusion:** Architecture and data flow align with the plan. No BLOCKER. Optional refactors are LOW priority.
