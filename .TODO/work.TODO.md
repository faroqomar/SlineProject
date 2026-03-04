# work — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - The `work` feature renders unified task/booking execution details, review flow, delivery submission, extension requests, awarded-pending-payment task actions, and chat entry. File Reference: `lib/features/work/view/work_item_details_screen.dart:30-733`, `lib/features/work/viewmodels/work_item_details_view_model.dart:11-328`, `lib/features/work/services/work_management_service.dart:14-441`
- Boundaries (in scope):
  - Primary feature files under `lib/features/work/**`. File Reference: `lib/features/work/view/work_item_details_screen.dart:30-733`, `lib/features/work/viewmodels/work_item_details_view_model.dart:11-328`, `lib/features/work/services/work_management_service.dart:14-441`, `lib/features/work/models/unified_work_item_model.dart:3-119`, `lib/features/work/view/widgets/submit_delivery_modal.dart:8-68`, `lib/features/work/view/widgets/request_extension_modal.dart:8-79`, `lib/features/work/view/widgets/review_delivery_modal.dart:9-161`
  - Direct dependencies touched by imports/calls/routes: booking service, dashboard repository/viewmodel, deep-link service, chat service/viewmodel, profile summary service, task service, tender payment coordinator, and payment service injection. File Reference: `lib/features/work/view/work_item_details_screen.dart:19-28`, `lib/features/work/services/work_management_service.dart:7-10`, `lib/core/services/deep_link_service.dart:112-145`, `lib/features/dashboard/view/tabs/bookings_tab.dart:83-116`, `lib/features/dashboard/data/dashboard_repository.dart:67-290`, `lib/features/dashboard/viewmodels/dashboard_view_model.dart:898-953`, `lib/features/chat/services/message_service.dart:15-84`, `lib/features/chat/viewmodels/chat_view_model.dart:156-188`, `lib/features/profile/services/profile_summary_service.dart:6-58`, `lib/features/tasks/services/task_service.dart:745-820`, `lib/features/tasks/services/tender_payment_coordinator.dart:7-105`, `lib/main.dart:176-208`
- Boundaries (out of scope):
  - Direct-offer detail flows, wallet UI, generic home/dashboard surfaces not directly called by `work`. File Reference: `lib/core/services/deep_link_service.dart:125-145`, `lib/features/work/view/work_item_details_screen.dart:19-28`
- Entry points (screens/routes/calls):
  - Dashboard work card tap -> `DeepLinkService.handleWorkItem()` -> `WorkItemDetailsScreen`. File Reference: `lib/features/dashboard/view/widgets/work_item_card.dart:83-93`, `lib/core/services/deep_link_service.dart:112-145`
  - Dashboard bookings tab -> direct push to `WorkItemDetailsScreen`. File Reference: `lib/features/dashboard/view/tabs/bookings_tab.dart:83-116`
  - The route itself creates `WorkItemDetailsViewModel` and triggers `loadData()` on first frame. File Reference: `lib/features/work/view/work_item_details_screen.dart:40-47`, `lib/features/work/view/work_item_details_screen.dart:61-70`

## 1) Feature Map (Current Repo State)
- Primary feature files (with references):
  - `lib/features/work/view/work_item_details_screen.dart` — route, tabs, action bar, chat launch, tender-payment launch, booking detail rendering. File Reference: `lib/features/work/view/work_item_details_screen.dart:30-733`
  - `lib/features/work/viewmodels/work_item_details_view_model.dart` — screen state, data load, fallback model creation, mutation methods. File Reference: `lib/features/work/viewmodels/work_item_details_view_model.dart:11-328`
  - `lib/features/work/services/work_management_service.dart` — unified work fetch, fallback shaping, work-table reads, work RPCs, booking wrappers, profile fetch. File Reference: `lib/features/work/services/work_management_service.dart:14-441`
  - `lib/features/work/models/unified_work_item_model.dart` — unified work parsing and status mapping. File Reference: `lib/features/work/models/unified_work_item_model.dart:3-119`
  - `lib/features/work/models/change_request_model.dart` — change request parsing. File Reference: `lib/features/work/models/change_request_model.dart:1-51`
  - `lib/features/work/models/extension_request_model.dart` — extension request parsing. File Reference: `lib/features/work/models/extension_request_model.dart:1-37`
  - `lib/features/work/models/work_contract_model.dart` — work contract parsing. File Reference: `lib/features/work/models/work_contract_model.dart:1-32`
  - `lib/features/work/view/widgets/submit_delivery_modal.dart` — delivery note modal. File Reference: `lib/features/work/view/widgets/submit_delivery_modal.dart:8-68`
  - `lib/features/work/view/widgets/request_extension_modal.dart` — extension request modal. File Reference: `lib/features/work/view/widgets/request_extension_modal.dart:8-79`
  - `lib/features/work/view/widgets/review_delivery_modal.dart` — approve/reject review modal. File Reference: `lib/features/work/view/widgets/review_delivery_modal.dart:9-161`
- Direct dependencies (with references):
  - `lib/core/services/deep_link_service.dart` — navigates work items to `WorkItemDetailsScreen`. File Reference: `lib/core/services/deep_link_service.dart:112-145`
  - `lib/features/dashboard/view/widgets/work_item_card.dart` — work-card entry into deep-link handler. File Reference: `lib/features/dashboard/view/widgets/work_item_card.dart:83-93`
  - `lib/features/dashboard/view/tabs/bookings_tab.dart` — booking entry into `WorkItemDetailsScreen`. File Reference: `lib/features/dashboard/view/tabs/bookings_tab.dart:83-116`
  - `lib/features/dashboard/data/dashboard_repository.dart` — uses the same unified view and same awarded-pending-payment fallback semantics. File Reference: `lib/features/dashboard/data/dashboard_repository.dart:67-145`, `lib/features/dashboard/data/dashboard_repository.dart:191-290`
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart` — booking action wrappers and `cancelAwardedOffer()` consumed by the work screen. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:898-953`
  - `lib/features/booking/services/booking_service.dart` — booking state transitions, refund path, direct status updates. File Reference: `lib/features/booking/services/booking_service.dart:117-143`, `lib/features/booking/services/booking_service.dart:215-312`
  - `lib/features/chat/services/message_service.dart` — task-linked vs DM conversation creation. File Reference: `lib/features/chat/services/message_service.dart:15-84`
  - `lib/features/chat/viewmodels/chat_view_model.dart` — UI entry used by work detail. File Reference: `lib/features/chat/viewmodels/chat_view_model.dart:156-188`
  - `lib/features/profile/services/profile_summary_service.dart` — server-side profile summary RPC used by work detail. File Reference: `lib/features/profile/services/profile_summary_service.dart:6-58`
  - `lib/features/tasks/services/task_service.dart` — awarded-offer payment and cancel RPC calls. File Reference: `lib/features/tasks/services/task_service.dart:749-820`
  - `lib/features/tasks/services/tender_payment_coordinator.dart` — tender payment orchestration constructed by the screen. File Reference: `lib/features/tasks/services/tender_payment_coordinator.dart:11-105`
  - `lib/core/services/payment_service.dart` and `lib/main.dart` — payment dependency is provided globally, not route-locally. File Reference: `lib/core/services/payment_service.dart:213-280`, `lib/main.dart:176-208`
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs):
  - `vw_unified_work_items` — main work query path. File Reference: `lib/features/work/services/work_management_service.dart:31-45`, `lib/features/dashboard/data/dashboard_repository.dart:78-93`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:86-186`
  - `task_requests` — awarded-pending-payment fallback, tender payment, and cancel-award flow. File Reference: `lib/features/work/services/work_management_service.dart:60-120`, `lib/features/dashboard/data/dashboard_repository.dart:232-290`, `lib/features/tasks/services/task_service.dart:755-820`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:20-24`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:157-183`
  - `bookings` — booking detail fetch and booking state mutations used by work detail. File Reference: `lib/features/work/services/work_management_service.dart:399-425`, `lib/features/booking/services/booking_service.dart:16-20`, `lib/features/booking/services/booking_service.dart:117-143`, `lib/features/booking/services/booking_service.dart:215-312`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:125-153`, `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql:37-64`, `supabase/migrations/20260224_fix_rpc_approve_delivery_digest_schema.sql:30-59`
  - `work_contracts` — read by work detail. File Reference: `lib/features/work/services/work_management_service.dart:165-190`, `Sline_everything/SUPABASE_SETUP.md:1082-1087`
  - `change_requests` — read and accepted by work detail. File Reference: `lib/features/work/services/work_management_service.dart:193-217`, `lib/features/work/services/work_management_service.dart:324-350`, `Sline_everything/SUPABASE_SETUP.md:1088-1094`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`
  - `extension_requests` — read and inserted by work detail. File Reference: `lib/features/work/services/work_management_service.dart:219-243`, `lib/features/work/services/work_management_service.dart:353-374`, `Sline_everything/SUPABASE_SETUP.md:1096-1101`
  - `rpc_submit_delivery` — delivery transition RPC. File Reference: `lib/features/work/services/work_management_service.dart:245-272`, `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql:4-68`
  - `rpc_approve_delivery` — approve/release RPC. File Reference: `lib/features/work/services/work_management_service.dart:303-321`, `supabase/migrations/20260224_fix_rpc_approve_delivery_digest_schema.sql:4-64`
  - `rpc_request_revision` — revision RPC documented in docs and called by app. File Reference: `lib/features/work/services/work_management_service.dart:274-300`, `Sline_everything/SUPABASE_SETUP.md:1799-1803`
  - `rpc_accept_change_request` — change-accept RPC documented in docs and called by app. File Reference: `lib/features/work/services/work_management_service.dart:324-350`, `Sline_everything/SUPABASE_SETUP.md:1805-1809`
  - `rpc_get_profile_summaries` — profile summary RPC used after work item load. File Reference: `lib/features/profile/services/profile_summary_service.dart:21-25`
  - `start_task_conversation_v1` — task-linked chat RPC invoked from work detail through chat service. File Reference: `lib/features/chat/services/message_service.dart:21-33`
  - `cancel_awarded_offer` — task award cancellation RPC used by work detail. File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:934-953`, `lib/features/tasks/services/task_service.dart:809-820`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:5-84`
  - `UNVERIFIED` migration source-of-truth for `work_contracts`, `change_requests`, `extension_requests`, `rpc_request_revision`, and `rpc_accept_change_request`:
    - Code and repo docs reference them, but no matching executable migration file was identified in `supabase/migrations/` during this audit scan. Missing file(s): migration(s) defining those tables/RPCs and their RLS policies.

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| W-SEC-01 | The app depends on `work_contracts`, `change_requests`, `extension_requests`, `rpc_request_revision`, and `rpc_accept_change_request`, but this repo audit did not find their migration source-of-truth. | `lib/features/work/services/work_management_service.dart:165-243`, `lib/features/work/services/work_management_service.dart:274-350`, `Sline_everything/SUPABASE_SETUP.md:1082-1101`, `Sline_everything/SUPABASE_SETUP.md:1799-1809` | High | `UNVERIFIED` source-control gap; missing SQL files under `supabase/migrations/` |
| W-SEC-02 | Work detail logs `current_user_id`, `client_id`, and `freelancer_id` at info level. | `lib/features/work/viewmodels/work_item_details_view_model.dart:89-103` | Medium | PII/relationship metadata exposure in logs |
| W-DAT-01 | Booking work items open chat using `taskId: item.id`, and the chat service routes any non-null `taskId` through `start_task_conversation_v1`. | `lib/features/work/view/work_item_details_screen.dart:579-585`, `lib/features/work/view/work_item_details_screen.dart:658-679`, `lib/features/chat/services/message_service.dart:15-33` | High | Booking UUID can be sent to a task-only RPC |
| W-DAT-02 | Client cancel of pending booking uses a direct status update to `canceled` and does not invoke the refund path. | `lib/features/work/view/work_item_details_screen.dart:497-543`, `lib/features/work/viewmodels/work_item_details_view_model.dart:311-319`, `lib/features/work/services/work_management_service.dart:398-409`, `lib/features/booking/services/booking_service.dart:117-143`, `lib/features/booking/services/booking_service.dart:215-245` | High | Financial orphan risk if funds are held |
| W-DAT-03 | Tender pay flow can hold funds before `pay_awarded_offer` succeeds; the task service already logs this as a critical inconsistency. | `lib/features/work/view/work_item_details_screen.dart:203-234`, `lib/features/tasks/services/tender_payment_coordinator.dart:31-93`, `lib/features/tasks/services/task_service.dart:776-799` | High | Non-idempotent pay flow with no compensation path in this code path |
| W-DAT-04 | Booking accept uses multiple direct `updateBookingStatus()` calls instead of one server-authoritative transition. | `lib/features/work/services/work_management_service.dart:376-384`, `lib/features/booking/services/booking_service.dart:266-311` | Medium | Partial transition risk if the second update fails |
| W-DAT-05 | Booking fallback maps `BookingStatus.completed` to `UnifiedWorkStatus.delivered`, and `canReview` is keyed off `delivered`. | `lib/features/work/viewmodels/work_item_details_view_model.dart:50`, `lib/features/work/viewmodels/work_item_details_view_model.dart:81-84`, `lib/features/work/viewmodels/work_item_details_view_model.dart:135-137` | Medium | Completed bookings can be treated as reviewable in fallback mode |
| W-ARC-01 | The widget layer constructs payment orchestration, calls dashboard mutations, and opens chat directly. | `lib/features/work/view/work_item_details_screen.dart:208-233`, `lib/features/work/view/work_item_details_screen.dart:246-249`, `lib/features/work/view/work_item_details_screen.dart:665-679`, `lib/main.dart:176-208` | High | MVVM boundary leak and global-provider coupling |
| W-ARC-02 | `WorkManagementService` mixes unified reads, fallback mapping, work RPCs, booking wrappers, and profile fetching. | `lib/features/work/services/work_management_service.dart:26-441` | Medium | Hard to test and reason about responsibility boundaries |
| W-QUAL-01 | `acceptChangeRequest()` contains unresolved scaffolding comments about missing SQL and assumed contracts. | `lib/features/work/services/work_management_service.dart:324-350` | Medium | Production code contains unverified backend assumptions |
| W-QUAL-02 | Request validation and error feedback are inconsistent: invalid extension input is silently ignored, and review modal errors are swallowed locally. | `lib/features/work/view/widgets/request_extension_modal.dart:64-72`, `lib/features/work/view/widgets/review_delivery_modal.dart:36-56` | Medium | Weak UX and debugging signals |
| W-PERF-01 | The whole screen rebuilds on every state change, and bottom action buttons do not bind to `isLoading`. | `lib/features/work/view/work_item_details_screen.dart:77-139`, `lib/features/work/view/work_item_details_screen.dart:521-585`, `lib/features/work/viewmodels/work_item_details_view_model.dart:59-119`, `lib/features/work/viewmodels/work_item_details_view_model.dart:165-327` | Medium | Broad rebuild scope and duplicate-submit exposure |
| W-TEST-01 | Observed work-specific test coverage is limited to unified model mapping and dashboard work-tab review routing. | `test/unit/models/unified_work_item_model_test.dart:1-36`, `test/widget/dashboard/work_tab_test.dart:1-127` | Medium | `UNVERIFIED` absence of dedicated service/viewmodel/detail/modal tests; no matching test files were found during this audit scan |

## 3) Findings
### 3.1 Security (Highest Priority)
- `W-SEC-01` — File Reference: `lib/features/work/services/work_management_service.dart:165-243`, `lib/features/work/services/work_management_service.dart:274-350`, `Sline_everything/SUPABASE_SETUP.md:1082-1101`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`
  - Impact:
    - The app references work-critical tables/RPCs and RLS rules, but the executable SQL source-of-truth is not present in `supabase/migrations/` for this audit.
    - That prevents a verified RLS/authz audit from source control, which violates the repo rule that RLS is the real authorization boundary.
  - Exploit/Failure scenario:
    - A fresh environment or rollback can be recreated without the live auth/RLS behavior the app expects.
    - A production database can drift away from repo state without review.
  - Status:
    - `UNVERIFIED` from executable SQL files. Missing file(s): migration(s) that define `work_contracts`, `change_requests`, `extension_requests`, `rpc_request_revision`, `rpc_accept_change_request`, and their policies.
- `W-SEC-02` — File Reference: `lib/features/work/viewmodels/work_item_details_view_model.dart:89-103`
  - Impact:
    - The view model logs participant identifiers and role-state metadata at info level.
    - This increases exposure of relationship metadata in client or aggregated logs.
  - Exploit/Failure scenario:
    - Support logs or crash logs can contain `current_user_id`, `client_id`, and `freelancer_id` for work items that should not need that verbosity outside debugging.

### 3.2 Data Integrity
- `W-DAT-01` — File Reference: `lib/features/work/view/work_item_details_screen.dart:579-585`, `lib/features/work/view/work_item_details_screen.dart:658-679`, `lib/features/chat/services/message_service.dart:15-33`
  - Impact:
    - Booking work items pass `booking.id` as `taskId`.
    - The chat service treats any non-null `taskId` as a task-linked conversation and calls `start_task_conversation_v1`.
  - Exploit/Failure scenario:
    - Opening chat from an active booking can fail, create the wrong conversation association, or hit task-only server logic with a booking UUID.
- `W-DAT-02` — File Reference: `lib/features/work/view/work_item_details_screen.dart:497-543`, `lib/features/work/viewmodels/work_item_details_view_model.dart:311-319`, `lib/features/work/services/work_management_service.dart:398-409`, `lib/features/booking/services/booking_service.dart:117-143`, `lib/features/booking/services/booking_service.dart:215-245`, `Sline_everything/SUPABASE_SETUP.md:1070-1073`
  - Impact:
    - The client-side cancel path mutates booking status directly to `canceled`.
    - It does not route through the refund path used by `declineBooking()`.
  - Exploit/Failure scenario:
    - A client cancels a pending/request-pending booking with held funds, the booking row changes state, but refund handling is skipped.
- `W-DAT-03` — File Reference: `lib/features/work/view/work_item_details_screen.dart:203-234`, `lib/features/tasks/services/tender_payment_coordinator.dart:31-93`, `lib/features/tasks/services/task_service.dart:776-799`
  - Impact:
    - The tender payment flow performs ledger hold first and DB state advance second.
    - The current implementation already acknowledges a "CRITICAL" inconsistency when the second step fails.
  - Exploit/Failure scenario:
    - Payment succeeds, escrow hold is recorded, `pay_awarded_offer` fails, and the user returns to a broken awarded-payment state with no compensating write in this flow.
- `W-DAT-04` — File Reference: `lib/features/work/services/work_management_service.dart:376-384`, `lib/features/booking/services/booking_service.dart:266-311`
  - Impact:
    - Booking acceptance is not one atomic server transition.
    - For `pending + held`, the service updates to `paid_request_pending` and then updates again to `active`.
  - Exploit/Failure scenario:
    - A transient failure between the two updates leaves the booking in an intermediate state that the UI and work view may not expect.
- `W-DAT-05` — File Reference: `lib/features/work/viewmodels/work_item_details_view_model.dart:50`, `lib/features/work/viewmodels/work_item_details_view_model.dart:81-84`, `lib/features/work/viewmodels/work_item_details_view_model.dart:135-137`
  - Impact:
    - Fallback-mapped completed bookings are converted to `UnifiedWorkStatus.delivered`.
    - `canReview` is true whenever the client sees `delivered`.
  - Exploit/Failure scenario:
    - If the unified view is missing but booking data exists, a completed booking can be rendered as still awaiting client review.

### 3.3 Architecture
- `W-ARC-01` — File Reference: `lib/features/work/view/work_item_details_screen.dart:208-233`, `lib/features/work/view/work_item_details_screen.dart:246-249`, `lib/features/work/view/work_item_details_screen.dart:665-679`, `lib/main.dart:176-208`
  - Impact:
    - The view constructs `TenderPaymentCoordinator`, reaches into `DashboardViewModel`, reads `TaskService` and `PaymentService` directly, and creates chat flow from the widget layer.
    - The route also relies on globally registered providers from `main.dart` instead of route-local dependencies.
  - Exploit/Failure scenario:
    - The screen becomes hard to test in isolation and any provider wiring drift at app root can break a feature route indirectly.
- `W-ARC-02` — File Reference: `lib/features/work/services/work_management_service.dart:26-441`
  - Impact:
    - One service now owns unified-view reads, fallback mapping, contract/request queries, delivery/review RPC calls, booking state wrappers, booking fetch, and profile fetch.
  - Exploit/Failure scenario:
    - A change in one sub-flow can regress unrelated work detail behavior because responsibilities are not separated.

### 3.4 Code Quality
- `W-QUAL-01` — File Reference: `lib/features/work/services/work_management_service.dart:324-350`
  - Impact:
    - `acceptChangeRequest()` includes unresolved comments about missing migration snippets and assumed RPC behavior.
  - Exploit/Failure scenario:
    - The code advertises a supported action while embedding its own uncertainty about whether the backend contract exists.
- `W-QUAL-02` — File Reference: `lib/features/work/view/widgets/request_extension_modal.dart:64-72`, `lib/features/work/view/widgets/review_delivery_modal.dart:36-56`
  - Impact:
    - Invalid extension input is ignored without feedback.
    - Review modal exceptions are swallowed locally and only reset loading state.
  - Exploit/Failure scenario:
    - Users can trigger no-op submissions or hidden failures with no actionable message, making work-flow errors harder to diagnose.
- `W-QUAL-03` — File Reference: `lib/features/work/view/work_item_details_screen.dart:276-293`
  - Impact:
    - Request history combines extension and change requests without sorting, despite the code comment noting the gap.
  - Exploit/Failure scenario:
    - History order changes with backend return order and becomes non-deterministic for users and tests.
- `W-QUAL-04` — File Reference: `lib/features/work/viewmodels/work_item_details_view_model.dart:64-119`
  - Impact:
    - A single `Future.wait()` governs required and optional data. A failure in contract/request fetches collapses the entire detail screen into generic load error state.
  - Exploit/Failure scenario:
    - An optional data-source outage hides the work item entirely even though the core work row is still readable.

### 3.5 Performance
- `W-PERF-01` — File Reference: `lib/features/work/view/work_item_details_screen.dart:77-139`, `lib/features/work/viewmodels/work_item_details_view_model.dart:59-119`, `lib/features/work/viewmodels/work_item_details_view_model.dart:165-327`
  - Impact:
    - The top-level `Consumer` rebuilds the entire scaffold for every notify cycle.
    - Each action method toggles loading, then calls `loadData()`, which toggles loading again and notifies again.
  - Exploit/Failure scenario:
    - Submitting, reviewing, or canceling work replaces the whole screen with spinner-driven rebuilds instead of updating only the affected controls.
- `W-PERF-02` — File Reference: `lib/features/work/view/work_item_details_screen.dart:521-585`
  - Impact:
    - The bottom action buttons do not bind `vm.isLoading` or any per-action busy state.
  - Exploit/Failure scenario:
    - Slow networks permit repeated taps on `Accept`, `Decline`, `Cancel Request`, `Extension`, `Submit Work`, `Review`, or `Message`, producing duplicate calls or duplicate navigation attempts.

### 3.6 Testing Gaps
- `W-TEST-01` — File Reference: `test/unit/models/unified_work_item_model_test.dart:1-36`, `test/widget/dashboard/work_tab_test.dart:1-127`
  - Impact:
    - Observed coverage only validates unified status mapping and dashboard work-tab review grouping.
  - Exploit/Failure scenario:
    - There is no observed automated protection for work detail loading, booking chat launch, booking cancel/refund semantics, tender payment error handling, or modal validation.
  - Status:
    - `UNVERIFIED` absence detail: no dedicated `test/**` files for `WorkItemDetailsScreen`, `WorkItemDetailsViewModel`, `WorkManagementService`, `SubmitDeliveryModal`, `RequestExtensionModal`, or `ReviewDeliveryModal` were found during this audit scan.

## 4) Dead/Unused Code Candidates
- Candidate: `WorkManagementService.listUnifiedWorkItems()`
  - File Reference: `lib/features/work/services/work_management_service.dart:130-163`
  - Why it looks unused:
    - During this audit scan, no repo call site was observed outside the method definition itself.
  - How to confirm:
    - Run `rg -n "listUnifiedWorkItems\\(" lib test`
- Candidate: `WorkItemDetailsViewModel.acceptChangeRequest()`
  - File Reference: `lib/features/work/viewmodels/work_item_details_view_model.dart:230-245`
  - Why it looks unused:
    - The current work detail screen renders request history as passive list items and does not present an accept action. File Reference: `lib/features/work/view/work_item_details_screen.dart:276-293`, `lib/features/work/view/work_item_details_screen.dart:718-733`
  - How to confirm:
    - Run `rg -n "acceptChangeRequest\\(" lib test`
- Candidate: `WorkManagementService.acceptChangeRequest()`
  - File Reference: `lib/features/work/services/work_management_service.dart:324-350`
  - Why it looks unused:
    - It appears to exist only behind the unreachable view-model wrapper above.
  - How to confirm:
    - Run `rg -n "rpc_accept_change_request|acceptChangeRequest\\(" lib test`

## 5) Duplicate Code Candidates
- Duplicate: awarded-pending-payment fallback shaping
  - File Reference: `lib/features/work/services/work_management_service.dart:59-120`
  - File Reference: `lib/features/dashboard/data/dashboard_repository.dart:99-109`, `lib/features/dashboard/data/dashboard_repository.dart:232-290`
  - Shared abstraction to introduce:
    - `lib/features/work/models/unified_work_item_fallback_mapper.dart`
- Duplicate: tender payment launch/orchestration assembly in two UI surfaces
  - File Reference: `lib/features/work/view/work_item_details_screen.dart:203-234`
  - File Reference: `lib/features/dashboard/view/tabs/work_tab.dart:281-317`
  - Shared abstraction to introduce:
    - `lib/features/work/viewmodels/work_tender_payment_launcher.dart` or route the flow through one view-model/controller API
- Duplicate: booking action wrappers around accept/decline/cancel
  - File Reference: `lib/features/work/services/work_management_service.dart:376-409`
  - File Reference: `lib/features/dashboard/viewmodels/dashboard_view_model.dart:898-953`
  - Shared abstraction to introduce:
    - `lib/features/booking/services/booking_action_service.dart` or expose one repository/controller path used by both dashboard and work

## 6) Refactor Plan (Exact Paths)
- Split `lib/features/work/view/work_item_details_screen.dart` into:
  - `lib/features/work/view/work_item_details_screen.dart` — route shell and provider wiring only
  - `lib/features/work/view/widgets/work_item_overview_tab.dart`
  - `lib/features/work/view/widgets/work_item_requests_tab.dart`
  - `lib/features/work/view/widgets/work_item_contract_tab.dart`
  - `lib/features/work/view/widgets/work_item_action_bar.dart`
  - `lib/features/work/view/widgets/work_item_pending_payment_actions.dart`
  - `lib/features/work/view/widgets/extension_request_history_tile.dart`
  - `lib/features/work/view/widgets/change_request_history_tile.dart`
- Split `lib/features/work/services/work_management_service.dart` into:
  - `lib/features/work/services/work_item_query_service.dart`
  - `lib/features/work/services/work_item_action_service.dart`
  - `lib/features/work/models/unified_work_item_fallback_mapper.dart`
  - Keep `lib/features/work/services/work_management_service.dart` as a temporary compatibility facade until all call sites are migrated.
- Reduce view-model breadth:
  - Keep `lib/features/work/viewmodels/work_item_details_view_model.dart` focused on state orchestration.
  - Add `lib/features/work/viewmodels/work_item_actions_controller.dart` for mutation flow coordination.
  - Add `lib/features/work/viewmodels/work_item_route_dependencies.dart` if route-local DI is introduced to break the hidden `main.dart` dependency.
- Migration strategy:
  - Phase in new query/action services behind the existing facade first.
  - Move the screen to the new widgets/controllers second.
  - Delete the facade only after `rg -n "WorkManagementService\\(" lib test` shows only intended construction sites.

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
- Item 1: Restore the missing backend source-of-truth for work tables/RPCs
  - What to change:
    - Add checked-in migration file(s) for `work_contracts`, `change_requests`, `extension_requests`, `rpc_request_revision`, and `rpc_accept_change_request`, including RLS policies and grants.
  - Exact file(s) to edit/create:
    - `supabase/migrations/<new_timestamp>_work_contracts_change_extension_requests.sql`
    - `supabase/migrations/<new_timestamp>_work_revision_and_change_rpcs.sql`
    - Optional doc sync after SQL exists: `Sline_everything/SUPABASE_SETUP.md`
  - Acceptance criteria:
    - `rg -n "work_contracts|change_requests|extension_requests|rpc_request_revision|rpc_accept_change_request" supabase/migrations` returns executable SQL definitions.
    - `pg_policies` validation shows the policies documented in `Sline_everything/SUPABASE_SETUP.md:1082-1101`.
- Item 2: Fix booking chat routing
  - What to change:
    - Stop passing `booking.id` as `taskId`.
    - Introduce a booking-safe conversation path or route booking chat through the DM path if task-linked chat is not valid for bookings.
  - Exact file(s) to edit/create:
    - `lib/features/work/view/work_item_details_screen.dart`
    - `lib/features/chat/services/message_service.dart`
    - Optional if a typed API is added: `lib/features/chat/viewmodels/chat_view_model.dart`
  - Acceptance criteria:
    - No booking code path passes a booking UUID into `start_task_conversation_v1`.
    - A booking detail screen can open chat successfully in widget/unit tests.
- Item 3: Replace unsafe pending-booking cancel semantics
  - What to change:
    - Remove direct `updateBookingStatus(...canceled)` from the work-detail cancel path.
    - Add a server-authoritative cancel/refund rule or explicitly block cancellation when payment is held.
  - Exact file(s) to edit/create:
    - `lib/features/work/services/work_management_service.dart`
    - `lib/features/booking/services/booking_service.dart`
    - If server-side path is required: `supabase/migrations/<new_timestamp>_booking_cancel_refund_rpc.sql`
  - Acceptance criteria:
    - Canceling from work detail cannot strand held funds.
    - The chosen path is idempotent and covered by tests.
- Item 4: Make awarded-offer payment fail-closed
  - What to change:
    - Eliminate the ledger-first / DB-second inconsistency or add compensating recovery when the second step fails.
    - Prefer one server-authoritative RPC that performs validation, payment-state advance, and ledger updates consistently.
  - Exact file(s) to edit/create:
    - `lib/features/tasks/services/task_service.dart`
    - `lib/features/tasks/services/tender_payment_coordinator.dart`
    - `lib/features/work/view/work_item_details_screen.dart`
    - `supabase/migrations/<new_timestamp>_pay_awarded_offer_atomicity.sql`
  - Acceptance criteria:
    - No code path can leave funds held while task state remains unpaid without an automatic recovery path.
    - Simulated second-step failure is recoverable and testable.
- Item 5: Fix fallback status mapping
  - What to change:
    - Map completed bookings to `UnifiedWorkStatus.completed`, not `delivered`.
  - Exact file(s) to edit/create:
    - `lib/features/work/viewmodels/work_item_details_view_model.dart`
    - Optional shared helper: `lib/features/work/models/unified_work_item_fallback_mapper.dart`
  - Acceptance criteria:
    - Completed booking fallback state does not expose `Review` actions.
    - Unit tests cover fallback mapping for `pending`, `paidRequestPending`, `active`, `delivered`, and `completed`.

### Phase 2: Refactor/structure
- Item 1: Move business orchestration out of the widget layer
  - What to change:
    - Move tender-payment launch, chat launch decisions, and award-cancel flow into view-model/controller classes.
  - Exact file(s) to edit/create:
    - `lib/features/work/view/work_item_details_screen.dart`
    - `lib/features/work/viewmodels/work_item_details_view_model.dart`
    - `lib/features/work/viewmodels/work_item_actions_controller.dart`
  - Acceptance criteria:
    - The route widget no longer constructs `TenderPaymentCoordinator`, calls `DashboardViewModel.cancelAwardedOffer()`, or invokes `ChatViewModel.createOrGetConversation()` directly.
- Item 2: Split the monolithic screen and service
  - What to change:
    - Apply the file split plan from Section 6.
  - Exact file(s) to edit/create:
    - All new widget/service paths listed in Section 6
  - Acceptance criteria:
    - `work_item_details_screen.dart` is reduced to route shell concerns.
    - Query logic and mutation logic are testable separately.
- Item 3: Remove duplicate fallback and booking wrapper logic
  - What to change:
    - Centralize awarded-pending-payment fallback mapping and booking action orchestration.
  - Exact file(s) to edit/create:
    - `lib/features/work/models/unified_work_item_fallback_mapper.dart`
    - `lib/features/dashboard/data/dashboard_repository.dart`
    - `lib/features/work/services/work_item_query_service.dart`
    - `lib/features/booking/services/booking_action_service.dart`
  - Acceptance criteria:
    - One shared mapper generates fallback work-item state.
    - One shared booking action path is reused by both work and dashboard.

### Phase 3: Tests
- Item 1: Add unit coverage for work detail state and service behavior
  - What to change:
    - Add tests for fallback mapping, partial-load resilience, change/extension reads, booking chat routing inputs, and action error handling.
  - Exact file(s) to edit/create:
    - `test/unit/work/work_item_details_view_model_test.dart`
    - `test/unit/work/work_management_service_test.dart`
    - `test/unit/work/unified_work_item_fallback_mapper_test.dart`
  - Acceptance criteria:
    - Failing optional queries do not blank the whole screen after the intended refactor.
    - Booking fallback and booking chat routing are covered.
- Item 2: Add widget coverage for work detail UI
  - What to change:
    - Add widget tests for pending booking cancel, message action, awarded-pending-payment actions, extension validation, and review modal error handling.
  - Exact file(s) to edit/create:
    - `test/widget/work/work_item_details_screen_test.dart`
    - `test/widget/work/request_extension_modal_test.dart`
    - `test/widget/work/review_delivery_modal_test.dart`
    - `test/widget/work/submit_delivery_modal_test.dart`
  - Acceptance criteria:
    - Critical UI actions are blocked or disabled correctly during loading.
    - Invalid input produces visible feedback.
- Item 3: Add SQL contract checks
  - What to change:
    - Add validation steps or migration tests that assert expected work policies/RPCs exist.
  - Exact file(s) to edit/create:
    - `supabase/migrations/<new_timestamp>_work_contracts_change_extension_requests.sql`
    - `supabase/migrations/<new_timestamp>_work_revision_and_change_rpcs.sql`
    - Optional repo doc/checklist file if your workflow requires it
  - Acceptance criteria:
    - The repo can prove the existence of the required tables, policies, and RPCs without consulting live-only state.

### Phase 4: Polish/perf
- Item 1: Add deterministic request ordering
  - What to change:
    - Sort combined request history by `createdAt` descending before render.
  - Exact file(s) to edit/create:
    - `lib/features/work/view/work_item_details_screen.dart` or `lib/features/work/view/widgets/work_item_requests_tab.dart`
  - Acceptance criteria:
    - Request history ordering is stable and testable.
- Item 2: Narrow rebuild scope and per-action busy state
  - What to change:
    - Replace whole-screen `Consumer` rebuilds with smaller consumers/selectors and introduce per-action loading flags.
  - Exact file(s) to edit/create:
    - `lib/features/work/view/work_item_details_screen.dart`
    - `lib/features/work/viewmodels/work_item_details_view_model.dart`
  - Acceptance criteria:
    - Tapping one action does not rebuild unrelated tabs or leave other mutation buttons active.
- Item 3: Improve user-facing error feedback
  - What to change:
    - Surface invalid extension input and review-modal failures explicitly.
  - Exact file(s) to edit/create:
    - `lib/features/work/view/widgets/request_extension_modal.dart`
    - `lib/features/work/view/widgets/review_delivery_modal.dart`
  - Acceptance criteria:
    - Invalid submission paths show visible, English-only feedback instead of silent no-op.

## 8) Verification Checklist
### Commands
- `flutter analyze`
- `flutter test test/unit/models/unified_work_item_model_test.dart`
- `flutter test test/widget/dashboard/work_tab_test.dart`
- After fixes land:
  - `flutter test test/unit/work/work_item_details_view_model_test.dart`
  - `flutter test test/unit/work/work_management_service_test.dart`
  - `flutter test test/widget/work/work_item_details_screen_test.dart`
  - `flutter test test/widget/work/request_extension_modal_test.dart`
  - `flutter test test/widget/work/review_delivery_modal_test.dart`
- Additional grep/rg checks:
  - `rg -n "taskId: item.id" lib/features/work`
  - `rg -n "listUnifiedWorkItems\\(" lib test`
  - `rg -n "acceptChangeRequest\\(" lib test`
  - `rg -n "work_contracts|change_requests|extension_requests|rpc_request_revision|rpc_accept_change_request" supabase/migrations`
  - `rg -n "current_user_id|client_id|freelancer_id" lib/features/work`

### Manual Scenarios
- Scenario 1: Booking -> open details -> tap `Message`
  - Open a booking from dashboard bookings or work card.
  - Tap `Message`.
  - Verify the app does not call task-only conversation creation for a booking UUID and chat opens correctly.
- Scenario 2: Pending/request-pending booking -> client cancel
  - Open a booking eligible for `Cancel Request`.
  - Tap cancel once on a slow network.
  - Verify no duplicate requests fire.
  - Verify the cancel path either refunds safely or is blocked when held funds exist.
- Scenario 3: Awarded task pending payment -> `Pay & Confirm`
  - Open the work detail for an awarded unpaid task.
  - Complete payment.
  - Verify work state advances consistently and does not leave a held-payment orphan on forced failure testing.
- Scenario 4: Delivered booking/task -> client review
  - Open a delivered work item as client.
  - Approve once and reject once in separate runs.
  - Verify action buttons disable while loading and errors are surfaced if the backend fails.
- Scenario 5: Extension request
  - Submit invalid days, zero days, and valid days.
  - Verify invalid inputs show feedback.
  - Verify valid requests appear in deterministic order.
- Scenario 6: Missing unified view row but readable booking
  - Simulate/mocks: `getUnifiedWorkItem()` returns null and `getBooking()` returns a completed booking.
  - Verify fallback status is `completed`, not `delivered`.

### Supabase/RLS Contract Checks
- Policy presence:
  - Validate that `work_contracts`, `change_requests`, and `extension_requests` policies exist and match repo docs. File Reference: `Sline_everything/SUPABASE_SETUP.md:1082-1101`
  - Example SQL check:
    - `select schemaname, tablename, policyname, cmd from pg_policies where schemaname = 'public' and tablename in ('work_contracts','change_requests','extension_requests');`
- RPC presence:
  - Validate `rpc_submit_delivery`, `rpc_approve_delivery`, `rpc_request_revision`, `rpc_accept_change_request`, and `cancel_awarded_offer` exist and use server-side authorization. File Reference: `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql:4-68`, `supabase/migrations/20260224_fix_rpc_approve_delivery_digest_schema.sql:4-64`, `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:5-84`, `Sline_everything/SUPABASE_SETUP.md:1799-1809`
  - Example SQL check:
    - `select p.proname, p.prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname in ('rpc_submit_delivery','rpc_approve_delivery','rpc_request_revision','rpc_accept_change_request','cancel_awarded_offer');`
- View contract:
  - Validate `vw_unified_work_items` still exposes `awarded_request_id` and `payment_deadline` plus correct booking/task branches. File Reference: `supabase/migrations/20260315000000_award_to_work_cancel_and_view.sql:91-183`
  - Example SQL check:
    - `select pg_get_viewdef('public.vw_unified_work_items'::regclass, true);`

## 9) Risks & Rollback Notes
- Risk: Adding or re-creating missing work SQL objects can overwrite live behavior if production drift exists.
  - Rollback steps:
    - Capture current live definitions first with `pg_get_viewdef`, `pg_get_functiondef`, and `pg_policies`.
    - Revert only the new work migration files if the repo SQL proves incorrect.
- Risk: Fixing pending-booking cancel semantics can change user-visible booking behavior.
  - Rollback steps:
    - If the new server-safe cancel path fails, disable the cancel action in the app instead of reverting to the current direct `canceled` update.
- Risk: Refactoring the 733-line screen can introduce UI regressions unrelated to correctness fixes.
  - Rollback steps:
    - Keep `WorkManagementService` as a temporary compatibility facade.
    - Land Phase 1 behavior fixes before Phase 2 file splits.
- Risk: Making awarded-offer payment atomic may require coordinated app + SQL rollout.
  - Rollback steps:
    - Gate the new path behind one server-authoritative RPC.
    - If rollback is needed, revert the new RPC/migration and app call site together; do not leave mixed ledger/payment semantics deployed.
