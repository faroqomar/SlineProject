# Deprecation: Proposals 2026-03-04

**Purpose**: Track old proposal paths and removal conditions.

## Items

| Item | Location | Replacement | Removal gate |
|------|----------|-------------|--------------|
| TaskRequest (model) | lib/features/tasks/models/task_request_model.dart | ProposalModel (lib/features/proposals/models/proposal_model.dart) | All callers use ProposalModel or compatibility export only. |
| TaskRequestsService | lib/features/tasks/services/task_requests_service.dart | ProposalRepository (lib/features/proposals/data/proposal_repository.dart) | Owner list now uses ProposalRepository.listByTask(isOwner: true) via TaskRequestsViewModel; submit/replace/reject still delegate to TaskRequestsService. |
| Old task-path exports | lib/features/tasks/ (requests_list_screen, submit_request_sheet, request_tile, tender_payment_screen) | lib/features/proposals/view/ (proposals_list_screen, submit_proposal_sheet, proposal_tile, proposal_payment_screen) | All launchers use proposal_payment_route and proposals module. |
| ProposalDetailsModal | lib/features/proposals/view/proposal_details_modal.dart | None (stub only) | No call sites; remove or tombstone. |
| payForAwardedOffer() (ViewModel) | TaskRequestsViewModel | TenderPaymentScreen / proposal_payment_route | All pay flows use payment screen. |
| accept() (legacy one-step) | TaskRequestsViewModel | awardOffer + payment flow | Not used. |
| acceptOffer(TaskRequest) | DashboardViewModel | awardOffer + payment flow | Not used. |
| getClientAwardedUnpaidOffers / getFreelancerAwardedUnpaidOffers (TaskService) | TaskService | ProposalAwardRepository.getClientAwardedUnpaid / getFreelancerAwardedUnpaid | Dashboard/Inbox/Work use ProposalAwardRepository or typed summary. |

## Verification (one per deprecated path)

- [ ] Grep for TaskRequest usage outside tasks/proposals; switch to ProposalModel where appropriate.
- [x] Owner list: TaskRequestsViewModel uses ProposalRepository when isOwner (RLS-safe bidder names). TaskRequestsService still used for submit/replace/reject and for non-owner list.
- [ ] Grep for payForAwardedOffer(; ensure no callers or replace with route.
- [ ] Grep for ProposalDetailsModal; remove if no call sites.
- [ ] Dashboard/Inbox/Work: ensure they use getClientAwardedUnpaid / getFreelancerAwardedUnpaid from ProposalAwardRepository or TaskService returning typed ProposalPaymentSummary.
