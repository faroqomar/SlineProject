# Architect Report: Proposals Remediation 2026-03-05

**Scope**: Proposals Remediation (PLAN_ProposalsRemediation_v2_2026-03-04)  
**Plan**: `.TODO/Archive/ProposalesExecution/PLAN_ProposalsRemediation_v2_2026-03-04.md`  
**Evidence**: Scanned `lib/features/proposals/`, `lib/features/tasks/view/widgets/requests/`, `lib/features/tasks/services/task_requests_service.dart`, `lib/features/dashboard/view/tabs/`, `lib/features/dashboard/view/widgets/next_actions_list.dart`, `lib/features/work/view/work_item_details_screen.dart`, `lib/features/tasks/view/task_details_screen.dart`.

---

## 1. MVVM boundary check

| Layer | Status | Evidence |
|-------|--------|----------|
| **View → Supabase** | ✅ Pass | No `Supabase.instance`, `.from()`, or `.rpc()` in any file under `lib/features/tasks/view/` or `lib/features/proposals/view/`. |
| **View → ViewModel/Provider** | ✅ Pass | Requests list uses `TaskRequestsViewModel`; payment route uses `context.read<TaskService>()`, `context.read<PaymentService>()` and builds `TenderPaymentViewModel`. |
| **Data layer** | ✅ Pass | All Supabase access in `ProposalRepository`, `ProposalAwardRepository`, `TaskRequestsService`; no Supabase in UI. |

**Contract**: Proposal list/submit/replace/reject flow still uses `TaskRequestsViewModel` + `TaskRequestsService` from tasks; proposal *data* boundary is `ProposalRepository` / `ProposalAwardRepository` but UI is not yet wired to proposal ViewModels (plan allowed keeping existing ViewModels). No violation.

---

## 2. Data flow map

- **List proposals (owner)**: UI (RequestsListScreen) → TaskRequestsViewModel → TaskRequestsService.listByTask (tasks). Alternative path for owner list: ProposalRepository.listByTask(isOwner: true) uses `get_proposal_bidder_summaries` RPC; not yet used by RequestsListScreen (still uses TaskRequestsService list). **Gap (LOW)**: Owner list could switch to ProposalRepository for RLS-safe bidder names.
- **Submit/Replace/Reject**: UI → TaskRequestsViewModel → TaskRequestsService (ProposalRepository delegates to same service). ✅ Consistent.
- **Award**: UI → TaskRequestsViewModel.award() → TaskService.awardTaskOffer() → RPC `award_task_offer`. ✅ Auth bound in RPC.
- **Payment entry**: All launchers (Inbox, Work, Next Actions, Work Details, Requests list after award) → `openProposalPayment(context, summary)` → TenderPaymentCoordinator + TenderPaymentViewModel + TenderPaymentScreen. ✅ Single entry point.
- **Get awarded-unpaid**: Dashboard/Inbox/Work use existing dashboard repo/VM (UnifiedWorkItem, etc.) and build `ProposalPaymentSummary` for pay-escrow items; no direct call to ProposalAwardRepository from UI. ✅ Data comes from existing work-item APIs.

---

## 3. Path validation

| Path | Exists | Note |
|------|--------|------|
| `lib/features/proposals/models/proposal_model.dart` | ✅ | |
| `lib/features/proposals/models/proposal_payment_summary.dart` | ✅ | |
| `lib/features/proposals/data/proposal_repository.dart` | ✅ | |
| `lib/features/proposals/data/proposal_award_repository.dart` | ✅ | |
| `lib/features/proposals/routes/proposal_payment_route.dart` | ✅ | |
| `lib/features/proposals/view/proposals_list_screen.dart` | ✅ | Re-export |
| `lib/features/proposals/view/widgets/submit_proposal_sheet.dart` | ✅ | Re-export |
| `lib/features/proposals/view/widgets/proposal_tile.dart` | ✅ | Re-export |
| `lib/features/proposals/view/proposal_payment_screen.dart` | ✅ | Re-export |
| `lib/features/proposals/view/proposal_details_modal.dart` | ✅ | Deprecated |

---

## 4. Architecture / logic findings

| Finding | Severity | File / area | Recommendation |
|---------|----------|-------------|----------------|
| ProposalRepository not in main.dart DI | MED | `lib/main.dart` | Plan allowed compatibility: TaskRequestsViewModel still created with TaskRequestsService. Optional: register ProposalRepository/ProposalAwardRepository and inject where needed for future full cutover. |
| RequestsListScreen still uses TaskRequestsViewModel for list | LOW | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` | Owner list could use ProposalRepository.listByTask(isOwner: true) for RLS-safe bidder names; current path uses TaskRequestsService with profile join. Document as tech-debt or add to DEPRECATION verification. |
| proposal_payment_route builds VM with summary; deadline fallback 24h | LOW | `lib/features/proposals/routes/proposal_payment_route.dart` | When server does not return deadline, 24h fallback is acceptable per DECISION_ProposalPaymentDeadline. No change. |
| Self-favorite guard (viewerUserId) | ✅ | `request_tile.dart`, `requests_list_screen.dart` | Correctly hides favorite when viewer is bidder; AuthViewModel.currentUserId passed. |

---

## 5. Contract checks

- **CONTRACT_proposals_rpc_and_models**: ProposalPaymentSummary fields (requestId, taskId, taskTitle, freelancerName, amount, paymentDeadline) match app and RPC return shapes. ✅
- **STATE_MATRIX**: Submit → replace → reject → award → pay/cancel/resume reflected in repos and RPCs. ✅
- **No client active_role mutation**: TaskRequestsService.submitOffer checks role and throws; no update to profiles. ✅

---

## 6. Summary

- **MVVM**: Respected; no UI → Supabase.
- **Data flow**: Single payment entry point; award and list still via tasks layer with secure RPCs.
- **Gaps**: Optional DI for proposal repos; optional owner list via ProposalRepository for RLS-safe names. No BLOCKER.
- **Decision**: APPROVED from architecture perspective; no blocking refactors required.
