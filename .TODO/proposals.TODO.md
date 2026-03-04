# proposals — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- This feature currently handles tender proposal submission, owner review/rejection, award, and post-award payment through `RequestsListScreen`, `showSubmitRequestSheet`, `TaskRequestsViewModel`, `TaskRequestsService`, and `TaskService`. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`, `lib/features/tasks/services/task_requests_service.dart:5-299`, `lib/features/tasks/services/task_service.dart:513-920`
- The only file inside `lib/features/proposals` is a UI-only modal stub; the production proposal flow is implemented outside the feature folder. File Reference: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `lib/features/tasks/view/task_details_screen.dart:54-65`, `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`
- In scope for this audit: the proposal list/submit/award/payment flow and the direct launchers/providers it touches. File Reference: `lib/features/tasks/view/task_details_screen.dart:54-65`, `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/main.dart:196-199`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- Out of scope: broader booking flows, unrelated chat flows, and non-proposal feature areas except where proposal RPCs write chat/messages/notifications as part of direct proposal actions. File Reference: `lib/features/tasks/view/task_details_screen.dart:641-667`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`
- Entry points observed in the current repo:
  - Owner opens received proposals from task details. File Reference: `lib/features/tasks/view/task_details_screen.dart:218-254`
  - Freelancer opens the proposal sheet from task details. File Reference: `lib/features/tasks/view/task_details_screen.dart:668-681`
  - Client resumes awarded-unpaid payment from Inbox. File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`
  - Client resumes awarded-unpaid payment from Work. File Reference: `lib/features/dashboard/view/tabs/work_tab.dart:286-317`
  - Client resumes awarded-unpaid payment from Next Actions. File Reference: `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`
  - Client resumes awarded-unpaid payment from work item details. File Reference: `lib/features/work/view/work_item_details_screen.dart:206-234`

## 1) Feature Map (Current Repo State)
- Primary feature files:
  - `lib/features/proposals/view/proposal_details_modal.dart` contains the only file under the feature folder and is a mock detail modal with hard-coded sample data and no-op actions. File Reference: `lib/features/proposals/view/proposal_details_modal.dart:10-348`
- Direct dependencies:
  - Proposal launcher from task details. File Reference: `lib/features/tasks/view/task_details_screen.dart:54-65`, `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`
  - Proposal list screen. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`
  - Proposal submit sheet. File Reference: `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`
  - Proposal tile UI. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:9-132`
  - Proposal state holder. File Reference: `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`
  - Proposal model. File Reference: `lib/features/tasks/models/task_request_model.dart:8-202`
  - Proposal read/write service. File Reference: `lib/features/tasks/services/task_requests_service.dart:5-299`
  - Award/payment service methods. File Reference: `lib/features/tasks/services/task_service.dart:513-920`
  - Tender payment coordinator. File Reference: `lib/features/tasks/services/tender_payment_coordinator.dart:7-105`
  - Tender payment ViewModel. File Reference: `lib/features/tasks/viewmodels/tender_payment_view_model.dart:5-202`
  - Tender payment screen. File Reference: `lib/features/tasks/view/tender_payment_screen.dart:11-348`
  - Dashboard/work launchers. File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`
  - Dashboard data loading for proposals and pending-payment tenders. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:515-548`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:615-647`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:672-760`
  - Global providers used by this flow. File Reference: `lib/main.dart:196-199`
  - Work view fallback for awarded-unpaid tasks. File Reference: `lib/features/work/services/work_management_service.dart:24-150`, `lib/features/work/models/unified_work_item_model.dart:3-119`
  - Favorites dependency from proposal tile. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-65`, `lib/features/favorites/viewmodels/favorites_view_model.dart:72-100`, `lib/features/favorites/data/favorites_service.dart:52-66`
- Supabase touchpoints:
  - Tables:
    - `task_requests`. File Reference: `lib/features/tasks/services/task_requests_service.dart:29-38`, `lib/features/tasks/services/task_requests_service.dart:60-72`, `lib/features/tasks/services/task_requests_service.dart:132-136`, `lib/features/tasks/services/task_service.dart:536-544`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`
    - `tasks`. File Reference: `lib/features/tasks/services/task_service.dart:522-525`, `lib/features/tasks/services/task_service.dart:756-760`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:35-38`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:30-32`
    - `profiles`. File Reference: `lib/features/tasks/services/task_requests_service.dart:109-120`, `lib/features/profile/services/profile_summary_service.dart:21-33`, `supabase/migrations/20260312000000_profiles_update_own_for_active_role.sql:1-12`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`
    - `favorites`. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-65`, `lib/features/favorites/data/favorites_service.dart:52-60`
    - `notifications`. File Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:174-186`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:78-104`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:63-77`
    - `conversations` and `messages` through reject flow. File Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:384-435`
  - RPCs:
    - `replace_task_request`. File Reference: `lib/features/tasks/services/task_requests_service.dart:190-200`, `supabase/migrations/20260311000000_replace_task_request.sql:5-81`
    - `reject_task_request`. File Reference: `lib/features/tasks/services/task_requests_service.dart:246-265`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`
    - `award_task_offer`. File Reference: `lib/features/tasks/services/task_service.dart:730-743`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-107`
    - `pay_awarded_offer`. File Reference: `lib/features/tasks/services/task_service.dart:749-807`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:110-189`
    - `cancel_awarded_offer`. File Reference: `lib/features/tasks/services/task_service.dart:809-828`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`
    - `get_client_awarded_unpaid_offers`. File Reference: `lib/features/tasks/services/task_service.dart:830-843`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`
    - `get_freelancer_awarded_unpaid_offers`. File Reference: `lib/features/tasks/services/task_service.dart:845-858`, `supabase/migrations/20260226_tender_award_payment_flow.sql:328-367`
    - `rpc_get_profile_summaries`. File Reference: `lib/features/profile/services/profile_summary_service.dart:21-33`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`
    - `process_payment_event_ledger`. File Reference: `lib/features/tasks/services/task_service.dart:776-783`, `supabase/functions/_shared/bookin_payment.ts:383-437`, `supabase/migrations/20260317000000_fix_task_request_amount_gross.sql:1-22`
  - Edge functions:
    - `qicard_payment_create_tender`. File Reference: `lib/core/services/qicard_payment_service.dart:491-588`, `supabase/functions/qicard_payment_create_tender/index.ts:22-149`
    - `qicard_payment_recovery_tender`. File Reference: `lib/core/services/qicard_payment_service.dart:591-640`, `supabase/functions/qicard_payment_recovery_tender/index.ts:20-139`
  - View / index support:
    - `vw_unified_work_items`. File Reference: `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:86-186`, `lib/features/work/services/work_management_service.dart:31-46`, `lib/features/work/services/work_management_service.dart:138-150`
    - `idx_task_requests_task_status_payment`. File Reference: `supabase/migrations/20260316000000_task_requests_view_index.sql:1-4`
  - Storage buckets: UNVERIFIED. No proposal-specific storage bucket usage is referenced in the audited files. Missing file(s): no proposal attachment storage implementation was found under `lib/features/tasks`, `lib/features/proposals`, or `supabase/migrations`.
  - Realtime channels: UNVERIFIED. No proposal-specific realtime subscription/channel code is referenced in the audited files. Missing file(s): no proposal subscription code was found under the audited feature boundary.

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| PRP-S1 | `SECURITY DEFINER` proposal RPCs trust caller-supplied actor IDs (`p_client_id` / `p_freelancer_id`) instead of binding authorization to `auth.uid()` inside the function body. | `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-42`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:110-158`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-40`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`, `supabase/migrations/20260226_tender_award_payment_flow.sql:283-367` | Critical | A client can override default params when invoking RPCs. |
| PRP-S2 | Proposal submit mutates `profiles.active_role` from the client before insert to satisfy RLS. | `lib/features/tasks/services/task_requests_service.dart:106-121`, `supabase/migrations/20260312000000_profiles_update_own_for_active_role.sql:1-12`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-67` | High | This changes the server-side authz input as a UI side effect. |
| PRP-S3 | `TaskRequestsService` still joins `profiles` directly even though current profile select policy is self-only. | `lib/features/tasks/services/task_requests_service.dart:8-13`, `lib/features/tasks/services/task_requests_service.dart:50-76`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31` | Medium | Owner-side bidder data depends on a query shape the current RLS contract does not authorize. |
| PRP-S4 | The cross-user profile summary RPC returns more fields than the proposal flow consumes. | `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`, `lib/features/profile/services/profile_summary_service.dart:21-33`, `lib/features/tasks/services/task_service.dart:47-69`, `lib/features/tasks/services/task_service.dart:515-572` | Medium | The proposal flow only needs identity display fields, but the RPC exposes `bio`, `active_role`, `skills`, and `seller_level`. |
| PRP-D1 | Non-QiCard tender payment finalization is split client-side: ledger event first, then `pay_awarded_offer`. | `lib/features/tasks/services/task_service.dart:749-799`, `lib/features/tasks/services/tender_payment_coordinator.dart:77-92` | Critical | The code already logs the ledger-success / DB-failure inconsistency. |
| PRP-D2 | Client Inbox code expects awarded-unpaid offers, but the fetch path only loads pending offers. | `lib/features/tasks/services/task_service.dart:536-544`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:615-624`, `lib/features/dashboard/view/tabs/inbox_tab.dart:133-146` | High | The “Pay Now” branch in Inbox is not aligned with the data source. |
| PRP-D3 | Freelancer pending-payment tender loading queries `tasks.status = 'open'` even though the same method comments describe `assigned` / pending-payment semantics. | `lib/features/tasks/services/task_service.dart:860-900`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:632-643` | High | Pending-payment proposals can disappear from the dashboard fetch path. |
| PRP-D4 | Inbox payment resume uses a synthetic 24-hour deadline because `TaskRequest` does not carry `paymentDeadline`. | `lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`, `lib/features/tasks/models/task_request_model.dart:10-39` | Medium | The UI can show the wrong remaining time after award. |
| PRP-D5 | Award flow passes `widget.taskId` into `TenderPaymentViewModel.taskTitle`. | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:153-163`, `lib/features/tasks/viewmodels/tender_payment_view_model.dart:68-75`, `lib/features/tasks/view/tender_payment_screen.dart:178-198` | Medium | Payment UI can display a UUID instead of the task title. |
| PRP-A1 | The submit sheet bypasses MVVM and calls `TaskRequestsService` directly for replacement. | `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-301`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:210-237` | High | Violates `View -> ViewModel -> Service`. |
| PRP-A2 | The ViewModel instantiates its own services even though the app already provides global `TaskRequestsService` and `TaskService` instances. | `lib/features/tasks/viewmodels/task_requests_view_model.dart:15-21`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:196-203`, `lib/main.dart:196-199` | Medium | Hidden DI makes tests and state wiring harder to control. |
| PRP-A3 | The production proposal flow is fragmented across `tasks`, `dashboard`, and `work`, while `lib/features/proposals` contains only a stub. | `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/work/view/work_item_details_screen.dart:206-234` | Medium | The named feature boundary does not match the code layout. |
| PRP-C1 | `ProposalDetailsModal` is mock-driven, weakly typed, and ships no-op accept/decline actions. | `lib/features/proposals/view/proposal_details_modal.dart:10-39`, `lib/features/proposals/view/proposal_details_modal.dart:288-319` | Medium | The feature folder’s only file is not wired for production behavior. |
| PRP-C2 | Non-owner proposal tiles can attempt to favorite `request.bidderId`, which in the non-owner proposal view resolves to the viewing freelancer’s own ID. | `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-65`, `lib/features/tasks/services/task_requests_service.dart:60-76`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:69-81`, `lib/features/favorites/data/favorites_service.dart:52-60` | Medium | The action is mis-scoped for the proposal viewer. |
| PRP-P1 | `RequestsListScreen` schedules auto-open submit work from `build()` with `addPostFrameCallback`. | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:205-217` | Medium | Rebuilds can enqueue repeated bottom-sheet opens. |
| PRP-P2 | Award/pay mutations refresh up to 100 proposals instead of reconciling state incrementally. | `lib/features/tasks/viewmodels/task_requests_view_model.dart:119-127`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:147-155`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:175-181` | Low | Extra fetch cost grows with larger tender histories. |
| PRP-T1 | Tracked tests only cover the proposal model and tender payment coordinator/screen. | `test/unit/models/task_request_model_test.dart:24-105`, `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`, `test/widget/tasks/tender_payment_screen_test.dart:10-51` | Medium | Direct proposal list/submit/RLS contract paths are not covered by the observed tracked tests. |

## 3) Findings
### 3.1 Security (Highest Priority)
- PRP-S1. File Reference: `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-42`, `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:110-158`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-40`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`, `supabase/migrations/20260226_tender_award_payment_flow.sql:283-367`. Impact: owner-only proposal award/pay/cancel reads are vulnerable to caller-controlled actor IDs inside `SECURITY DEFINER` functions. Exploit/Failure scenario: an authenticated attacker can invoke `get_client_awarded_unpaid_offers` or `cancel_awarded_offer` with a victim UUID and read or mutate another user’s proposal state if the request ID is known.
- PRP-S2. File Reference: `lib/features/tasks/services/task_requests_service.dart:106-121`, `supabase/migrations/20260312000000_profiles_update_own_for_active_role.sql:1-12`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-67`. Impact: the client rewrites `profiles.active_role` to satisfy proposal RLS instead of letting RLS reject invalid role state. Exploit/Failure scenario: a user in client mode taps submit, the app silently flips them to freelancer mode, and downstream role-based views start behaving as if the user explicitly switched roles.
- PRP-S3. File Reference: `lib/features/tasks/services/task_requests_service.dart:8-13`, `lib/features/tasks/services/task_requests_service.dart:50-76`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`. Impact: owner-side proposal listing depends on a `profiles` join that conflicts with current self-only profile read policy. Exploit/Failure scenario: after RLS hardening, bidder name/avatar can drop out or the query can break while the proposal rows themselves still load.
- PRP-S4. File Reference: `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-39`, `lib/features/profile/services/profile_summary_service.dart:21-33`, `lib/features/tasks/services/task_service.dart:47-69`, `lib/features/tasks/services/task_service.dart:515-572`. Impact: cross-user proposal profile lookup exposes `bio`, `active_role`, `skills`, and `seller_level` even though the proposal views consume only display identity. Exploit/Failure scenario: any authenticated client can request arbitrary IDs through the RPC and retrieve more profile data than the proposal surfaces require.

### 3.2 Data Integrity
- PRP-D1. File Reference: `lib/features/tasks/services/task_service.dart:749-799`, `lib/features/tasks/services/tender_payment_coordinator.dart:77-92`. Impact: non-QiCard payment finalization is not atomic; the ledger event succeeds before `pay_awarded_offer` updates `task_requests` and `tasks`. Exploit/Failure scenario: network or RPC failure after ledger success leaves escrow/accounting state ahead of proposal/task state.
- PRP-D2. File Reference: `lib/features/tasks/services/task_service.dart:536-544`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:615-624`, `lib/features/dashboard/view/tabs/inbox_tab.dart:133-146`. Impact: the client Inbox “Pay Now” branch is disconnected from the data fetch that populates `_inboxOffers`. Exploit/Failure scenario: after award, a client returns later expecting to resume payment from Inbox, but the source list still filters to `status = 'pending'`, so the awarded-unpaid branch never receives matching data.
- PRP-D3. File Reference: `lib/features/tasks/services/task_service.dart:860-900`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:632-643`. Impact: freelancer pending-payment tenders are fetched with `tasks.status = 'open'` even though the same method describes `assigned` / pending-payment semantics. Exploit/Failure scenario: the freelancer dashboard fails to show a tender that is awarded-unpaid and waiting for client payment.
- PRP-D4. File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`, `lib/features/tasks/models/task_request_model.dart:10-39`. Impact: Inbox resume flow fabricates a new 24-hour deadline because the model does not carry the server deadline. Exploit/Failure scenario: an award created hours earlier is shown as if it still has a full 24 hours remaining.
- PRP-D5. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:153-163`, `lib/features/tasks/viewmodels/tender_payment_view_model.dart:68-75`, `lib/features/tasks/view/tender_payment_screen.dart:178-198`. Impact: payment summaries and descriptions can use a task UUID as the title. Exploit/Failure scenario: the user sees an opaque ID in the payment screen and gateway description instead of the tender title.

### 3.3 Architecture
- PRP-A1. File Reference: `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-301`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:210-237`. Impact: proposal replacement bypasses the ViewModel and reaches `TaskRequestsService` directly from the view function. Exploit/Failure scenario: UI logic and service orchestration drift apart, making state refresh and error handling inconsistent.
- PRP-A2. File Reference: `lib/features/tasks/viewmodels/task_requests_view_model.dart:15-21`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:196-203`, `lib/main.dart:196-199`. Impact: DI is inconsistent; the app registers global services, but the proposal ViewModel constructs new ones internally. Exploit/Failure scenario: tests and runtime screens can unknowingly use different service instances and configuration paths.
- PRP-A3. File Reference: `lib/features/proposals/view/proposal_details_modal.dart:10-348`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:16-301`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/work/view/work_item_details_screen.dart:206-234`. Impact: the named feature boundary is not real in the current repo; proposal code is distributed across unrelated feature modules. Exploit/Failure scenario: refactors and ownership become error-prone because the “proposals” feature folder does not contain the active flow.

### 3.4 Code Quality
- PRP-C1. File Reference: `lib/features/proposals/view/proposal_details_modal.dart:10-39`, `lib/features/proposals/view/proposal_details_modal.dart:288-319`. Impact: the only file in the proposal feature folder is untyped (`Map<String, dynamic>`), mock-populated, and wired with no-op CTA handlers. Exploit/Failure scenario: if this modal is later connected to live data without redesign, it will accept loosely typed payloads and still not execute real accept/decline actions.
- PRP-C2. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-65`, `lib/features/tasks/services/task_requests_service.dart:60-76`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:69-81`, `lib/features/favorites/data/favorites_service.dart:52-60`. Impact: the “Add to favorites” action is attached to the non-owner proposal view even though the viewer can only see their own proposal rows there. Exploit/Failure scenario: a freelancer opens their own submitted proposal and the tile attempts to favorite the viewer’s own ID.
- PRP-A2. File Reference: `lib/features/tasks/viewmodels/task_requests_view_model.dart:100-103`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:171-191`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:737-760`, `lib/features/tasks/services/task_service.dart:830-858`. Impact: the proposal flow still carries compatibility methods and helper APIs that are no longer aligned with the active two-step flow. Exploit/Failure scenario: dead or semi-dead methods continue to drift and confuse future fixes.

### 3.5 Performance
- PRP-P1. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:205-217`. Impact: `addPostFrameCallback` runs from `build()`, so any rebuild while `autoOpenSubmitSheet` remains true can enqueue another bottom sheet open. Exploit/Failure scenario: refresh, provider updates, or inherited widget changes trigger repeated modal presentations.
- PRP-P2. File Reference: `lib/features/tasks/viewmodels/task_requests_view_model.dart:119-127`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:147-155`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:175-181`. Impact: award/pay/accept refresh paths fetch up to 100 rows instead of reconciling the changed proposal state in place. Exploit/Failure scenario: larger tender histories incur unnecessary network and rebuild work after every mutation.

### 3.6 Testing Gaps
- PRP-T1. File Reference: `test/unit/models/task_request_model_test.dart:24-105`, `test/unit/tasks/tender_payment_coordinator_test.dart:13-113`, `test/widget/tasks/tender_payment_screen_test.dart:10-51`. Impact: the tracked tests observed in this repo cover model mapping and tender payment coordinator/screen behavior, but not proposal list submission, replacement, reject/award transitions, or SQL authorization contracts. Exploit/Failure scenario: regressions in `RequestsListScreen`, `showSubmitRequestSheet`, `TaskRequestsService`, `award_task_offer`, and `cancel_awarded_offer` can ship without test failures. Note: absence of additional tracked tests for these paths is UNVERIFIED from file references alone; repo search did not surface matching test files in the current workspace.

## 4) Dead/Unused Code Candidates
- `lib/features/proposals/view/proposal_details_modal.dart:10-348`. Why candidate: the file is mock-driven and the audited entry points all route into `RequestsListScreen` or payment screens instead. How to confirm: run `rg -n "ProposalDetailsModal" lib test` and verify no call sites outside this file.
- `lib/features/tasks/viewmodels/task_requests_view_model.dart:147-169`. Why candidate: `payForAwardedOffer()` exists on the ViewModel, but the audited launchers push `TenderPaymentScreen` instead of calling this method. How to confirm: run `rg -n "payForAwardedOffer\\(" lib test`.
- `lib/features/tasks/viewmodels/task_requests_view_model.dart:171-191`. Why candidate: deprecated `accept()` still performs the legacy combined escrow/accept flow. How to confirm: run `rg -n "accept\\(" lib test | rg "TaskRequestsViewModel|DashboardViewModel"`.
- `lib/features/dashboard/viewmodels/dashboard_view_model.dart:737-760`. Why candidate: deprecated `acceptOffer()` retains the legacy one-step path. How to confirm: run `rg -n "acceptOffer\\(TaskRequest" lib test`.
- `lib/features/tasks/services/task_service.dart:830-858`. Why candidate: `getClientAwardedUnpaidOffers()` and `getFreelancerAwardedUnpaidOffers()` are defined but no audited caller was found in the current repo. How to confirm: run `rg -n "getClientAwardedUnpaidOffers\\(|getFreelancerAwardedUnpaidOffers\\(" lib test`.

## 5) Duplicate Code Candidates
- Tender payment launcher wiring is duplicated in four places. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:143-167`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `lib/features/dashboard/view/tabs/work_tab.dart:294-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:110-135`, `lib/features/work/view/work_item_details_screen.dart:210-234`. Proposed shared abstraction: `lib/features/proposals/routes/proposal_payment_route.dart` with a single `openProposalPayment(...)` helper.
- Proposal read/mapping logic is split between direct `task_requests` joins and profile-summary RPC enrichment. File Reference: `lib/features/tasks/services/task_requests_service.dart:8-13`, `lib/features/tasks/services/task_requests_service.dart:50-76`, `lib/features/tasks/services/task_service.dart:515-572`, `lib/features/profile/services/profile_summary_service.dart:13-33`. Proposed shared abstraction: `lib/features/proposals/data/proposal_repository.dart` with one owner-view query strategy and one freelancer-view query strategy.
- Payment resume deadline handling is duplicated and inconsistent. File Reference: `lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`, `lib/features/dashboard/view/tabs/work_tab.dart:300-312`, `lib/features/dashboard/view/widgets/next_actions_list.dart:116-129`, `lib/features/work/view/work_item_details_screen.dart:219-226`. Proposed shared abstraction: `lib/features/proposals/models/proposal_payment_summary.dart` carrying server-derived `paymentDeadline`.

## 6) Refactor Plan (Exact Paths)
- Move `lib/features/tasks/models/task_request_model.dart` to `lib/features/proposals/models/proposal_model.dart`.
- Move `lib/features/tasks/services/task_requests_service.dart` to `lib/features/proposals/data/proposal_repository.dart`.
- Move `lib/features/tasks/viewmodels/task_requests_view_model.dart` to `lib/features/proposals/viewmodels/proposals_view_model.dart`.
- Move `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` to `lib/features/proposals/view/proposals_list_screen.dart`.
- Move `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart` to `lib/features/proposals/view/widgets/submit_proposal_sheet.dart`.
- Move `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart` to `lib/features/proposals/view/widgets/proposal_tile.dart`.
- Move `lib/features/tasks/services/tender_payment_coordinator.dart` to `lib/features/proposals/services/proposal_payment_coordinator.dart`.
- Move `lib/features/tasks/viewmodels/tender_payment_view_model.dart` to `lib/features/proposals/viewmodels/proposal_payment_view_model.dart`.
- Move `lib/features/tasks/view/tender_payment_screen.dart` to `lib/features/proposals/view/proposal_payment_screen.dart`.
- Extract proposal-specific award/payment methods from `lib/features/tasks/services/task_service.dart:726-858` into `lib/features/proposals/data/proposal_award_repository.dart`.
- Create `lib/features/proposals/models/proposal_payment_summary.dart` to carry `requestId`, `taskTitle`, `freelancerName`, `amount`, and `paymentDeadline`.
- Create `lib/features/proposals/routes/proposal_payment_route.dart` to centralize launcher code now duplicated across `requests_list_screen.dart`, `inbox_tab.dart`, `work_tab.dart`, `next_actions_list.dart`, and `work_item_details_screen.dart`.
- Migration strategy:
  - Phase 2 should keep thin compatibility exports at the old task paths until imports are switched. File Reference: current callers at `lib/features/tasks/view/task_details_screen.dart:54-65`, `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
- Item 1: Bind proposal RPC authorization to `auth.uid()` inside the function bodies and stop trusting caller-supplied actor IDs.
- What to change: patch `award_task_offer`, `pay_awarded_offer`, `cancel_awarded_offer`, `get_client_awarded_unpaid_offers`, and `get_freelancer_awarded_unpaid_offers` so actor resolution is internal and non-overridable.
- Exact file(s) to edit/create: create `supabase/migrations/20260304060000_secure_proposal_rpc_contract.sql`; patch current definitions derived from `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-189`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-84`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`, `supabase/migrations/20260226_tender_award_payment_flow.sql:328-367`.
- Acceptance criteria: proposal RPCs ignore spoofed actor IDs; read and mutation results are scoped only to `auth.uid()`; SQL validation shows no remaining caller-controlled actor parameter in the active definitions.

- Item 2: Remove client-side `active_role` mutation from proposal submit.
- What to change: fail fast with a user-facing role-mode message instead of updating `profiles.active_role` during submit.
- Exact file(s) to edit/create: edit `lib/features/tasks/services/task_requests_service.dart:106-121`; keep `supabase/migrations/20260312000000_profiles_update_own_for_active_role.sql:1-12` under review for later cleanup if nothing else depends on it.
- Acceptance criteria: pressing submit in client mode does not change `profiles.active_role`; RLS remains the source of truth; UI receives a clear English-only error.

- Item 3: Make proposal owner reads RLS-safe and consistent.
- What to change: replace direct `profiles!task_requests_freelancer_id_fkey(...)` joins with the same profile-summary RPC strategy already used by `TaskService.getOffersReceived`, or reduce cross-user profile exposure via a narrower proposal summary RPC.
- Exact file(s) to edit/create: edit `lib/features/tasks/services/task_requests_service.dart:8-13`, `lib/features/tasks/services/task_requests_service.dart:50-89`, `lib/features/tasks/services/task_requests_service.dart:278-285`; optionally create `supabase/migrations/20260304061000_narrow_rpc_get_profile_summaries_for_proposals.sql`.
- Acceptance criteria: owner proposal list and reject refresh path do not depend on direct `profiles` joins that conflict with `profiles_select_self`.

- Item 4: Make non-QiCard proposal payment finalization atomic.
- What to change: move ledger + `pay_awarded_offer` state change into one server-owned finalize path instead of calling `submitPaymentEvent` and `pay_awarded_offer` separately from the client.
- Exact file(s) to edit/create: create `supabase/migrations/20260304062000_finalize_awarded_offer_payment.sql`; edit `lib/features/tasks/services/task_service.dart:749-799`; edit `lib/features/tasks/services/tender_payment_coordinator.dart:77-92`.
- Acceptance criteria: there is no client path where ledger success can outlive proposal/task state failure; failure leaves both accounting and task_request/task state unchanged.

- Item 5: Fix the current launcher correctness bugs.
- What to change: move proposal auto-open scheduling out of `build()`, pass a real task title into payment, and stop fabricating Inbox deadlines from `DateTime.now() + 24h`.
- Exact file(s) to edit/create: edit `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:143-217`; edit `lib/features/dashboard/view/tabs/inbox_tab.dart:72-90`; edit `lib/features/tasks/models/task_request_model.dart:10-39`; edit the data source that populates client awarded-unpaid resume state.
- Acceptance criteria: the submit sheet opens once per intended launch, the payment screen shows the real task title, and any displayed payment deadline comes from server data.

- Item 6: Fix dashboard proposal state loading inconsistencies.
- What to change: align `_fetchInboxInternal()` and `InboxTab` with the actual awarded-unpaid resume path, and correct `getPendingPaymentTenders()` to query the intended pending-payment task state.
- Exact file(s) to edit/create: edit `lib/features/tasks/services/task_service.dart:520-580`; edit `lib/features/tasks/services/task_service.dart:879-900`; edit `lib/features/dashboard/viewmodels/dashboard_view_model.dart:615-647`; edit `lib/features/dashboard/view/tabs/inbox_tab.dart:133-146`.
- Acceptance criteria: client resume actions are reachable from the intended surface, and freelancer pending-payment tenders load from the correct status.

### Phase 2: Refactor/structure
- Item 1: Consolidate proposal code under `lib/features/proposals`.
- What to change: move active proposal list, submit, model, ViewModel, and payment files out of `tasks` into a cohesive proposals module.
- Exact file(s) to edit/create: create/move files to `lib/features/proposals/models/proposal_model.dart`, `lib/features/proposals/data/proposal_repository.dart`, `lib/features/proposals/viewmodels/proposals_view_model.dart`, `lib/features/proposals/view/proposals_list_screen.dart`, `lib/features/proposals/view/widgets/submit_proposal_sheet.dart`, `lib/features/proposals/view/widgets/proposal_tile.dart`, `lib/features/proposals/services/proposal_payment_coordinator.dart`, `lib/features/proposals/viewmodels/proposal_payment_view_model.dart`, `lib/features/proposals/view/proposal_payment_screen.dart`.
- Acceptance criteria: the active proposal flow lives under one feature folder, and old task-path imports are reduced to temporary wrappers only.

- Item 2: Restore MVVM dependency direction.
- What to change: remove direct service access from the submit sheet and inject repository dependencies into the proposal ViewModel instead of constructing them internally.
- Exact file(s) to edit/create: edit `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-301` or its moved replacement; edit `lib/features/tasks/viewmodels/task_requests_view_model.dart:15-21` or its moved replacement; edit `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:196-203`; edit `lib/main.dart:196-199`.
- Acceptance criteria: views call ViewModel methods only; ViewModel dependencies come from DI instead of hidden constructors.

- Item 3: Centralize payment launchers.
- What to change: replace the repeated coordinator/ViewModel/screen construction with one route/factory helper.
- Exact file(s) to edit/create: create `lib/features/proposals/routes/proposal_payment_route.dart`; edit `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:143-167`, `lib/features/dashboard/view/tabs/inbox_tab.dart:72-95`, `lib/features/dashboard/view/tabs/work_tab.dart:294-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:110-135`, `lib/features/work/view/work_item_details_screen.dart:210-234`.
- Acceptance criteria: tender payment screen launch configuration exists in one reusable path.

### Phase 3: Tests
- Item 1: Add proposal repository/unit coverage.
- What to change: add unit tests for submit, replace, reject, owner reads, and payment-state parsing.
- Exact file(s) to edit/create: create `test/unit/proposals/proposal_repository_test.dart`, `test/unit/proposals/proposal_award_repository_test.dart`, `test/unit/proposals/proposal_model_test.dart`.
- Acceptance criteria: submit/replace/reject/error-mapping paths are covered with deterministic assertions.

- Item 2: Add widget coverage for the active proposal UI.
- What to change: add tests for one-time sheet auto-open, form validation, replace confirmation, and payment screen wiring.
- Exact file(s) to edit/create: create `test/widget/proposals/proposals_list_screen_test.dart`, `test/widget/proposals/submit_proposal_sheet_test.dart`, `test/widget/proposals/proposal_payment_screen_test.dart`.
- Acceptance criteria: rebuilds do not reopen the sheet, decimal IQD input is handled explicitly, and payment summaries use the real task title/deadline.

- Item 3: Add SQL/RLS contract checks.
- What to change: add reproducible validation for actor-bound RPCs and owner/freelancer access rules.
- Exact file(s) to edit/create: create `supabase/tests/proposals_rls.sql` or `test/integration_test/proposals/proposals_rls_contract_test.dart` if the repo standardizes integration tests there.
- Acceptance criteria: spoofed actor IDs fail, owner-only actions stay owner-only, and awarded-unpaid reads do not leak cross-user data.

### Phase 4: Polish/perf
- Item 1: Remove dead compatibility code after migration.
- What to change: delete or fold deprecated one-step award/pay helpers and the unused proposal modal if no product requirement remains.
- Exact file(s) to edit/create: edit/remove `lib/features/proposals/view/proposal_details_modal.dart`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:147-191`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:737-760`, `lib/features/tasks/services/task_service.dart:830-858`.
- Acceptance criteria: no dead proposal APIs remain in tracked code after import migration is complete.

- Item 2: Reduce heavy full-list refreshes and unify proposal naming.
- What to change: reconcile mutated rows in memory instead of re-fetching 100 records, and standardize user-facing copy on “Proposal” versus “Offer”.
- Exact file(s) to edit/create: edit `lib/features/tasks/viewmodels/task_requests_view_model.dart:119-181`; edit current proposal UI strings in `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:184-239`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:110-253`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:74-91`.
- Acceptance criteria: award/pay/reject refresh less data, and proposal terminology is consistent across proposal surfaces.

## 8) Verification Checklist
### Commands
- `flutter analyze lib/features/proposals lib/features/tasks lib/features/profile lib/core`
- `flutter test test/unit/models/task_request_model_test.dart test/unit/tasks/tender_payment_coordinator_test.dart test/widget/tasks/tender_payment_screen_test.dart`
- After fixes: `flutter test test/unit/proposals test/widget/proposals`
- `rg -n "p_client_id UUID DEFAULT auth.uid\\(|p_freelancer_id UUID DEFAULT auth.uid\\(" supabase/migrations`
- `rg -n "ctx.read<TaskRequestsService>|read<TaskRequestsService>" lib/features/proposals lib/features/tasks/view/widgets/requests`
- `rg -n "addPostFrameCallback" lib/features/proposals lib/features/tasks/view/widgets/requests`
- `rg -n "taskTitle: widget.taskId" lib`
- `rg -n "payForAwardedOffer\\(|getClientAwardedUnpaidOffers\\(|getFreelancerAwardedUnpaidOffers\\(" lib test`

### Manual Scenarios
- Scenario 1: Freelancer opens a tender while in client mode and taps submit. File Reference: `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:145-159`, `lib/features/tasks/services/task_requests_service.dart:106-121`
  - Expected after fix: no silent `active_role` mutation; the user gets an explicit role-mode requirement.
- Scenario 2: Freelancer opens task details with proposal auto-open enabled. File Reference: `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:205-217`
  - Expected after fix: the submit sheet opens once only, even after rebuilds or validation failures.
- Scenario 3: Owner opens received proposals and rejects one. File Reference: `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:194-207`, `lib/features/tasks/services/task_requests_service.dart:246-265`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`
  - Expected after fix: bidder identity still resolves correctly and the reject state refresh does not depend on a forbidden profile join.
- Scenario 4: Owner awards a proposal, leaves the flow, and resumes payment later. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:131-177`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`
  - Expected after fix: the correct resume surface shows the awarded-unpaid proposal with the server deadline and real task title.
- Scenario 5: Non-QiCard payment completion succeeds or fails. File Reference: `lib/features/tasks/services/tender_payment_coordinator.dart:77-92`, `lib/features/tasks/services/task_service.dart:749-799`
  - Expected after fix: there is no partial ledger-only success.
- Scenario 6: Non-owner proposal tile favorite action. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:50-65`
  - Expected after fix: the viewer cannot favorite their own proposal record by mistake.

### Supabase/RLS Contract Checks
- Verify `tr_insert`, `tr_select`, and owner update policies still exist for `task_requests`. File Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-102`
- Verify `profiles_select_self` remains self-only and the proposal owner read path no longer relies on a direct `profiles` join. File Reference: `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `lib/features/tasks/services/task_requests_service.dart:50-89`
- Verify proposal RPC definitions do not authorize from caller-supplied actor parameters. File Reference: current insecure definitions at `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-158`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-40`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`
- Validate edge-function payment redirect handling remains same-origin and trusted-URL only. File Reference: `supabase/functions/_shared/bookin_payment.ts:97-166`, `supabase/functions/qicard_payment_create_tender/index.ts:44-49`, `supabase/functions/qicard_payment_create_tender/index.ts:115-149`
- Validate QiCard recovery remains owner-checked server-side. File Reference: `supabase/functions/qicard_payment_recovery_tender/index.ts:42-73`, `supabase/functions/qicard_payment_recovery_tender/index.ts:110-122`

## 9) Risks & Rollback Notes
- Security migration risk: tightening actor binding can break any client code that still passes explicit actor IDs. File Reference: insecure current definitions at `supabase/migrations/20260313000000_tender_assign_only_after_payment.sql:11-158`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:6-40`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:652-693`
- Payment-flow risk: changing award-payment finalization affects both app-side non-QiCard flow and QiCard recovery integration. File Reference: `lib/features/tasks/services/tender_payment_coordinator.dart:53-103`, `lib/features/tasks/services/task_service.dart:749-799`, `supabase/functions/qicard_payment_recovery_tender/index.ts:90-122`
- Refactor risk: moving proposal code out of `tasks` touches multiple launchers and provider wiring. File Reference: `lib/features/tasks/view/task_details_screen.dart:54-65`, `lib/features/tasks/view/task_details_screen.dart:218-254`, `lib/features/tasks/view/task_details_screen.dart:668-681`, `lib/main.dart:196-199`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`, `lib/features/dashboard/view/widgets/next_actions_list.dart:102-135`, `lib/features/work/view/work_item_details_screen.dart:206-234`
- Rollback steps:
  - Revert the new proposal SQL migrations first if the staging contract fails. File Reference: proposed Phase 1 migration paths in Section 7
  - Keep compatibility exports at old task paths until all imports are switched. File Reference: current caller paths listed in Section 6
  - If the structural refactor regresses UI navigation, roll back only the file moves and keep the Phase 1 security SQL in place. File Reference: current runtime entry points at `lib/features/tasks/view/task_details_screen.dart:54-65`, `lib/features/dashboard/view/tabs/inbox_tab.dart:64-99`, `lib/features/dashboard/view/tabs/work_tab.dart:286-317`
