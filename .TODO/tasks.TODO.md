# tasks — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - Tender discovery and list rendering through `TendersScreen`, `TaskCard`, and `DiscoveryFeedViewModelContract`. File Reference: `lib/features/tasks/view/tenders_screen.dart:13-124`, `lib/features/tasks/view/widgets/task_card.dart:12-87`, `lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart:6-27`.
  - Task creation/editing through `CreateTaskScreen` and `TaskViewModel`. File Reference: `lib/features/tasks/view/create_task_screen.dart:155-301`, `lib/features/tasks/viewmodels/task_view_model.dart:113-174`.
  - Task details, booking checkout handoff, chat handoff, and proposal entry through `TaskDetailsScreen`. File Reference: `lib/features/tasks/view/task_details_screen.dart:25-64`, `lib/features/tasks/view/task_details_screen.dart:205-252`, `lib/features/tasks/view/task_details_screen.dart:327-370`, `lib/features/tasks/view/task_details_screen.dart:552-605`.
  - Tender offer submission, replacement, award, rejection, and payment handoff through `RequestsListScreen`, `SubmitRequestSheet`, `TaskRequestsViewModel`, `TaskRequestsService`, and `TaskService`. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:62-167`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:115-237`, `lib/features/tasks/services/task_requests_service.dart:18-279`, `lib/features/tasks/services/task_service.dart:562-875`.
- Boundaries (in scope):
  - All `lib/features/tasks/**` files reviewed in this audit. File Reference: `lib/features/tasks/data/task_repository.dart:6-38`, `lib/features/tasks/models/task_model.dart:18-240`, `lib/features/tasks/models/task_request_model.dart:9-180`, `lib/features/tasks/services/task_service.dart:20-875`, `lib/features/tasks/services/task_requests_service.dart:6-279`, `lib/features/tasks/services/task_image_service.dart:5-158`, `lib/features/tasks/view/**/*.dart`, `lib/features/tasks/viewmodels/*.dart`.
  - Direct dependencies touched by those files: provider wiring, navigation entry points, profile summary RPC client, categories repository, payment services, ledger service, image widget, and booking checkout comparison path. File Reference: `lib/main.dart:150-190`, `lib/app/main_navigation_screen.dart:39-117`, `lib/core/services/deep_link_service.dart:18-150`, `lib/features/home/viewmodels/home_view_model.dart:24-238`, `lib/features/profile/services/profile_summary_service.dart:6-58`, `lib/features/categories/data/categories_repository.dart:5-37`, `lib/core/services/qicard_payment_service.dart:6-280`, `lib/core/services/demo_payment_service.dart:5-174`, `lib/features/wallet/services/ledger_service.dart:5-110`, `lib/core/widgets/signed_image.dart:7-180`, `lib/features/booking/view/payment_checkout_screen.dart:247-360`.
- Boundaries (out of scope):
  - Live Supabase project state is UNVERIFIED because no repository file exposes deployed schema state and the Supabase MCP session was unavailable during this audit.
  - Booking internals beyond the task feature handoff are out of scope except where they prove a safer payment pattern than the tender flow. File Reference: `lib/features/tasks/view/task_details_screen.dart:563-589`, `lib/features/booking/view/payment_checkout_screen.dart:247-360`.
- Entry points (screens/routes/calls):
  - Main navigation exposes the tenders tab and create-task FAB. File Reference: `lib/app/main_navigation_screen.dart:41-51`, `lib/app/main_navigation_screen.dart:103-117`.
  - App startup wires task-related providers and repositories. File Reference: `lib/main.dart:150-190`, `lib/main.dart:194-196`.
  - Deep links navigate task notifications to `TaskDetailsScreen`. File Reference: `lib/core/services/deep_link_service.dart:82-150`.

## 1) Feature Map (Current Repo State)
- Primary feature files:
  - Models: `Task` and `TaskRequest`. File Reference: `lib/features/tasks/models/task_model.dart:18-240`, `lib/features/tasks/models/task_request_model.dart:9-180`.
  - Repository and services: `TaskRepository`, `TaskService`, `TaskRequestsService`, `TaskImageService`. File Reference: `lib/features/tasks/data/task_repository.dart:6-38`, `lib/features/tasks/services/task_service.dart:20-875`, `lib/features/tasks/services/task_requests_service.dart:6-279`, `lib/features/tasks/services/task_image_service.dart:5-158`.
  - ViewModels: discovery/filter/editor/request flows. File Reference: `lib/features/tasks/viewmodels/task_view_model.dart:11-174`, `lib/features/tasks/viewmodels/task_filter_view_model.dart:5-220`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:8-260`, `lib/features/tasks/viewmodels/discovery_feed_view_model_contract.dart:6-27`.
  - Views: discovery, editor, details, tender payment, request list, submit sheet, and cards. File Reference: `lib/features/tasks/view/tenders_screen.dart:13-124`, `lib/features/tasks/view/create_task_screen.dart:16-943`, `lib/features/tasks/view/task_details_screen.dart:25-606`, `lib/features/tasks/view/tender_payment_screen.dart:8-220`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:12-288`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:14-325`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:8-131`, `lib/features/tasks/view/widgets/tender_task_card.dart:14-292`, `lib/features/tasks/view/widgets/booking_task_card.dart:15-280`.
- Direct dependencies:
  - Discovery feed dependency outside the feature: `HomeViewModel` supplies task lists to `TendersScreen`. File Reference: `lib/features/home/viewmodels/home_view_model.dart:24-238`, `lib/features/tasks/view/tenders_screen.dart:24-37`.
  - Provider wiring and shared repositories: `main.dart` registers `TaskViewModel`, `TaskRequestsService`, and `CategoriesRepository`. File Reference: `lib/main.dart:150-190`.
  - Navigation/deep links: task detail navigation comes from `MainNavigationScreen` and `DeepLinkService`. File Reference: `lib/app/main_navigation_screen.dart:41-117`, `lib/core/services/deep_link_service.dart:128-150`.
  - Profile hydration: `TaskService` depends on `ProfileSummaryService`. File Reference: `lib/features/tasks/services/task_service.dart:20-70`, `lib/features/profile/services/profile_summary_service.dart:6-58`.
  - Category lookup: `CreateTaskScreen` calls `CategoriesRepository`. File Reference: `lib/features/tasks/view/create_task_screen.dart:164-180`, `lib/features/categories/data/categories_repository.dart:5-37`.
  - Payment and ledger dependencies: tender payment uses `QiCardPaymentService` and `TaskService`; task payment uses `LedgerService`. File Reference: `lib/features/tasks/view/tender_payment_screen.dart:42-109`, `lib/core/services/qicard_payment_service.dart:24-39`, `lib/features/tasks/services/task_service.dart:729-783`, `lib/features/wallet/services/ledger_service.dart:21-57`.
  - Image rendering/storage: task UIs use `SignedImage`; uploads use `TaskImageService`. File Reference: `lib/core/widgets/signed_image.dart:25-180`, `lib/features/tasks/services/task_image_service.dart:13-158`.
  - Cross-feature favorites fallback inside request UI: `RequestTile` touches `FavoritesService` and `FavoritesViewModel`. File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:19-21`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:97-119`, `lib/features/favorites/data/favorites_service.dart:6-107`.
  - Booking checkout comparison path: booking checkout is server-backed and lives outside the task feature. File Reference: `lib/features/tasks/view/task_details_screen.dart:563-589`, `lib/features/booking/view/payment_checkout_screen.dart:247-360`, `lib/core/services/qicard_payment_service.dart:125-280`.
- Supabase touchpoints (tables/RPC/storage/realtime/edge functions):
  - `tasks` table CRUD/read paths. File Reference: `lib/features/tasks/services/task_service.dart:35-41`, `lib/features/tasks/services/task_service.dart:96-99`, `lib/features/tasks/services/task_service.dart:143-147`, `lib/features/tasks/services/task_service.dart:409-428`, `lib/features/tasks/services/task_service.dart:466-470`, `lib/features/tasks/services/task_service.dart:847-856`.
  - `task_requests` table CRUD/read paths. File Reference: `lib/features/tasks/services/task_requests_service.dart:8-13`, `lib/features/tasks/services/task_requests_service.dart:29-36`, `lib/features/tasks/services/task_requests_service.dart:135-139`, `lib/features/tasks/services/task_service.dart:732-759`.
  - `profiles` access paths: direct select/update from `TaskRequestsService`, and server-side summary RPC from `TaskService`. File Reference: `lib/features/tasks/services/task_requests_service.dart:106-124`, `lib/features/profile/services/profile_summary_service.dart:13-58`, `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`.
  - Storage bucket `task-images`. File Reference: `lib/features/tasks/services/task_image_service.dart:13-18`, `lib/features/tasks/services/task_image_service.dart:57-67`, `lib/features/tasks/services/task_image_service.dart:114-118`, `lib/core/widgets/signed_image.dart:92-117`.
  - Tender RPCs in app code: `award_task_offer`, `pay_awarded_offer`, `get_client_awarded_unpaid_offers`, `get_freelancer_awarded_unpaid_offers`, `replace_task_request`, `accept_task_request`, `reject_task_request`, `process_payment_event_ledger`. File Reference: `lib/features/tasks/services/task_service.dart:710-715`, `lib/features/tasks/services/task_service.dart:763-766`, `lib/features/tasks/services/task_service.dart:788-804`, `lib/features/tasks/services/task_requests_service.dart:188-248`, `lib/features/wallet/services/ledger_service.dart:35-49`.
  - Checked-in SQL definitions for current repo state: `award_task_offer`, `pay_awarded_offer`, `get_client_awarded_unpaid_offers`, `accept_task_request`, `reject_task_request`, `rpc_get_profile_summaries`, `process_payment_event_ledger`, and an older `get_freelancer_awarded_unpaid_offers`. File Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:16-102`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:199-693`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:107-265`, `supabase/migrations/20260226_tender_award_payment_flow.sql:26-368`.
  - Edge functions: booking payment dependency invokes `qicard_payment_create` and `qicard_payment_recovery`; the tender payment screen does not use them. File Reference: `lib/core/services/qicard_payment_service.dart:148-157`, `lib/core/services/qicard_payment_service.dart:243-246`, `lib/features/tasks/view/tender_payment_screen.dart:72-82`.
  - Realtime channels: no task-feature realtime subscription API was verified in the reviewed files. File Reference: reviewed `lib/features/tasks/**` files above; live runtime wiring remains UNVERIFIED outside the reviewed scope.

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| TSK-SEC-01 | Tender payment still uses a demo client flow before activating work. | `lib/features/tasks/view/tender_payment_screen.dart:72-82`; `lib/core/services/qicard_payment_service.dart:25-39`; `lib/core/services/demo_payment_service.dart:23-40` | Critical | Client-side success is accepted as if real payment succeeded. |
| TSK-SEC-02 | Task payment ignores ledger RPC JSON result and can still mark the offer/task as held/active. | `lib/features/tasks/services/task_service.dart:752-777`; `lib/features/wallet/services/ledger_service.dart:35-49`; `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:151-159`; `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:625-648` | Critical | Ledger `ok=false` is not checked before `pay_awarded_offer`. |
| TSK-SEC-03 | Offer submission mutates `profiles.active_role` from the client. | `lib/features/tasks/services/task_requests_service.dart:106-124`; `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-67` | High | Client state mutation is being used to satisfy RLS expectations. |
| TSK-DI-01 | Task profile hydration is inconsistent because some read paths still key only on `user_id`. | `lib/features/tasks/services/task_service.dart:430-441`; `lib/features/tasks/services/task_service.dart:474-484`; `lib/features/tasks/models/task_model.dart:138-149` | High | Canonical `owner_id` rows can lose author info in discovery/details. |
| TSK-DI-02 | Pending-payment tender query filters `tasks.status = 'open'`, not the awarded state. | `lib/features/tasks/services/task_service.dart:834-856`; `supabase/migrations/20260226_tender_award_payment_flow.sql:90-96`; `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:527-532` | High | Awarded tenders are set to `assigned`, so this UI query is mismatched. |
| TSK-DI-03 | The app calls `replace_task_request`, but the repo only documents it; a checked-in SQL definition was not found. | `lib/features/tasks/services/task_requests_service.dart:188-197`; `Sline_everything/SUPABASE_SETUP.md:1463-1470`; `Sline_everything/SUPABASE_SETUP.md:1744-1752` | High | Live DB state is UNVERIFIED; fresh/migrated repos have no checked-in definition. |
| TSK-DI-04 | Task delivery can be written as `delivered`, but Flutter maps it back to `inProgress` and has no `TaskStatus.delivered`. | `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql:22-36`; `lib/core/app_enums.dart:13-22`; `lib/features/tasks/models/task_model.dart:190-216`; `lib/features/dashboard/services/dashboard_permission_service.dart:84-103` | High | Status transitions are lossy on the client. |
| TSK-DI-05 | Task creation allows zero-budget tenders and incomplete booking packages. | `lib/features/tasks/view/create_task_screen.dart:212-250`; `lib/features/tasks/view/create_task_screen.dart:252-287` | Medium | Client validation is weaker than the business rules implied by payment flow. |
| TSK-ARC-01 | Views call repositories/services directly instead of going through ViewModels. | `lib/features/tasks/view/create_task_screen.dart:164-180`; `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-317`; `lib/features/tasks/view/tender_payment_screen.dart:42-49` | High | Violates `View -> ViewModel -> Service`. |
| TSK-ARC-02 | `TaskRepository` reads auth from one client but performs CRUD through a different client instance. | `lib/features/tasks/data/task_repository.dart:8-24` | Medium | Dependency injection is internally inconsistent. |
| TSK-CQ-01 | `RequestsListScreen` schedules `addPostFrameCallback` from `build()` and passes the task ID as the payment title. | `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:141-148`; `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:196-205` | Medium | This is both fragile UI behavior and wrong user-facing context. |
| TSK-PERF-01 | Award/pay/legacy accept refreshes pull 100 offers each time instead of reusing page state. | `lib/features/tasks/viewmodels/task_requests_view_model.dart:123-127`; `lib/features/tasks/viewmodels/task_requests_view_model.dart:151-155`; `lib/features/tasks/viewmodels/task_requests_view_model.dart:176-181` | Medium | Unbounded refresh scope on each mutation. |
| TSK-TEST-01 | Existing task tests cover models, filter VM, create screen, and tenders screen only. | `test/unit/tasks/task_view_model_test.dart:27-124`; `test/unit/tasks/task_filter_view_model_test.dart:39-219`; `test/widget/tasks/create_task_screen_test.dart:69-249`; `test/widget/tasks/tenders_screen_test.dart:44-96`; `test/unit/models/task_model_test.dart:33-126`; `test/unit/models/task_request_model_test.dart:24-102` | Medium | No reviewed test file covers tender payment or request-list mutation flows. |

## 3) Findings
### 3.1 Security (Highest Priority)
- `TSK-SEC-01` | File Reference: `lib/features/tasks/view/tender_payment_screen.dart:72-82`, `lib/core/services/qicard_payment_service.dart:25-39`, `lib/core/services/demo_payment_service.dart:23-40` | Impact: the tender flow treats a demo payment fallback as a successful payment path. | Exploit/Failure scenario: a client can press “Complete Payment,” receive simulated success from `DemoPaymentService`, and immediately trigger `pay_awarded_offer`, even though no server-authoritative gateway settlement occurred.
- `TSK-SEC-02` | File Reference: `lib/features/tasks/services/task_service.dart:752-777`, `lib/features/wallet/services/ledger_service.dart:35-49`, `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:151-159`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:625-648` | Impact: escrow can fail while the app still advances the task request to `payment_status = 'held'` and the task to `status = 'in_progress'`. | Exploit/Failure scenario: if the ledger RPC returns `{ok:false,error:{...}}` because the request is not in the expected gate state or the client lacks funds, the app never checks `ok`; it still calls `pay_awarded_offer`, creating a false paid/active state.
- `TSK-SEC-03` | File Reference: `lib/features/tasks/services/task_requests_service.dart:106-124`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:53-67` | Impact: the client changes `profiles.active_role` as a side effect of offer submission, which mixes UX state with authorization state. | Exploit/Failure scenario: future screens or policies that interpret `active_role` as trusted role intent can be changed indirectly by the offer-submit path, instead of being derived solely from server-side authorization rules.

### 3.2 Data Integrity
- `TSK-DI-01` | File Reference: `lib/features/tasks/services/task_service.dart:430-441`, `lib/features/tasks/services/task_service.dart:474-484`, `lib/features/tasks/models/task_model.dart:138-149` | Impact: tasks loaded via `getOpenTasksForHome()` and `getTaskById()` may omit author profile data when the canonical row uses `owner_id` instead of legacy `user_id`. | Failure scenario: discovery cards and task details show fallback/empty author info for rows that parse correctly elsewhere.
- `TSK-DI-02` | File Reference: `lib/features/tasks/services/task_service.dart:834-856`, `supabase/migrations/20260226_tender_award_payment_flow.sql:90-96`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:527-532` | Impact: the “pending payment tenders” query does not match the checked-in award lifecycle. | Failure scenario: awarded offers disappear from the freelancer’s waiting-for-payment view because the query asks for `status = 'open'` while both checked-in award RPC versions set the task to `assigned`.
- `TSK-DI-03` | File Reference: `lib/features/tasks/services/task_requests_service.dart:188-197`, `Sline_everything/SUPABASE_SETUP.md:1463-1470`, `Sline_everything/SUPABASE_SETUP.md:1744-1752` | Impact: the replace-offer flow depends on an RPC contract that is only documented in the repo, not defined in the checked-in migrations reviewed here. | Failure scenario: local rebuilds, test environments, or drifted databases can throw RPC-not-found when a freelancer replaces an offer. | UNVERIFIED: live database function presence.
- `TSK-DI-04` | File Reference: `supabase/migrations/20260224_fix_rpc_submit_delivery_booking_transition.sql:22-36`, `lib/core/app_enums.dart:13-22`, `lib/features/tasks/models/task_model.dart:190-216`, `lib/features/dashboard/services/dashboard_permission_service.dart:84-103` | Impact: task delivery is not represented faithfully in Flutter state. | Failure scenario: a delivered task is parsed as `TaskStatus.inProgress`, so UI actions, labels, and permission logic cannot distinguish “delivered, waiting for review” from “still in progress.”
- `TSK-DI-05` | File Reference: `lib/features/tasks/view/create_task_screen.dart:212-250`, `lib/features/tasks/view/create_task_screen.dart:252-287` | Impact: task creation can build structurally invalid payloads before the backend has a chance to reject them. | Failure scenario: a tender with invalid budget input silently becomes `0`, or a booking package map is created with missing tier fields and a fallback budget of `0`.
- `TSK-DI-06` | File Reference: `supabase/migrations/20260226_tender_award_payment_flow.sql:26-368`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:472-693` | Impact: repo state contains multiple tender payment function generations with different owner-column assumptions and surrounding behavior. | Failure scenario: engineers reason about the wrong contract because older and newer migrations both define the same RPC names, while only some adjacent helpers were reconciled in the newer file.

### 3.3 Architecture
- `TSK-ARC-01` | File Reference: `lib/features/tasks/view/create_task_screen.dart:164-180`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-317`, `lib/features/tasks/view/tender_payment_screen.dart:42-49` | Impact: UI widgets own data-fetch and mutation logic that should live in ViewModels. | Failure scenario: tests must pump widgets to exercise business rules, and logic becomes duplicated across callbacks instead of being reusable and mockable.
- `TSK-ARC-02` | File Reference: `lib/features/tasks/data/task_repository.dart:8-24` | Impact: `TaskRepository` is not a clean repository boundary because it ignores its injected client for service calls. | Failure scenario: a test or alternate Supabase client can change `currentUser`, while CRUD methods still hit the global client.
- `TSK-ARC-03` | File Reference: `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:19-21`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:97-119`, `lib/features/favorites/data/favorites_service.dart:6-107` | Impact: a presentational task widget mutates another feature’s data layer directly. | Failure scenario: favorites behavior diverges depending on whether `favoritesVM` was provided, and the task feature now depends on favorites internals.
- `TSK-ARC-04` | File Reference: `lib/features/tasks/services/task_service.dart:12-19`, `lib/features/tasks/services/task_service.dart:90-501`, `lib/features/tasks/services/task_service.dart:562-875`, `lib/features/tasks/view/create_task_screen.dart:16-943`, `lib/features/tasks/view/task_details_screen.dart:25-606` | Impact: large multi-purpose files mix discovery, editor, payment, booking handoff, and hydration logic. | Failure scenario: unrelated changes increase regression risk because one file owns too many feature slices.

### 3.4 Code Quality
- `TSK-CQ-01` | File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:141-148`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:196-205` | Impact: the request list screen has both incorrect UI data (`taskTitle: widget.taskId`) and build-time side effects (`addPostFrameCallback`). | Failure scenario: the payment screen shows the task ID instead of the title, and the auto-open submit sheet can re-fire after rebuilds.
- `TSK-CQ-02` | File Reference: `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:154-158`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:261-263`, `lib/features/tasks/services/task_requests_service.dart:126-137`, `lib/features/tasks/models/task_request_model.dart:13`, `lib/features/tasks/models/task_request_model.dart:49-50` | Impact: the price type changes between `double` in UI/service and `int` in the domain model. | Failure scenario: decimal input is truncated to an integer amount, and this conversion point is implicit rather than validated.
- `TSK-CQ-03` | File Reference: `lib/features/tasks/services/task_service.dart:47-69` | Impact: profile hydration failures are swallowed and returned as empty maps. | Failure scenario: RPC regressions look like “missing author data” instead of a visible failure, which slows debugging and hides backend contract issues.
- `TSK-CQ-04` | File Reference: `lib/features/tasks/viewmodels/task_view_model.dart:35-111`, `lib/features/tasks/view/create_task_screen.dart:212-287`, `test/unit/tasks/task_view_model_test.dart:29-61` | Impact: image-upload helpers are maintained and tested, but the current create/edit screen does not call them. | Failure scenario: feature code and tests drift around a path the current UI no longer exercises.

### 3.5 Performance
- `TSK-PERF-01` | File Reference: `lib/features/tasks/viewmodels/task_requests_view_model.dart:123-127`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:151-155`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:176-181` | Impact: every award/pay/legacy accept re-fetches up to 100 offers instead of updating the affected item or reusing the page size. | Failure scenario: large offer lists incur unnecessary network and rebuild cost after each mutation.
- `TSK-PERF-02` | File Reference: `lib/features/tasks/services/task_service.dart:73-88`, `lib/features/tasks/services/task_service.dart:101-113`, `lib/features/tasks/services/task_service.dart:149-159`, `lib/features/tasks/services/task_service.dart:430-441`, `lib/features/tasks/services/task_service.dart:474-484` | Impact: task/profile hydration logic is repeated across multiple methods instead of being centralized. | Failure scenario: fixes require touching many call paths, and hydration behavior becomes inconsistent or duplicated.
- `TSK-PERF-03` | File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:196-205` | Impact: scheduling work from `build()` creates avoidable frame callbacks on rebuild. | Failure scenario: rebuild churn compounds into repeated modal scheduling and harder-to-predict frame behavior.

### 3.6 Testing Gaps
- Existing coverage is limited to task model parsing, task-request model parsing, task filtering, task view-model image helpers, create-screen validation/navigation, and tender discovery rendering. File Reference: `test/unit/models/task_model_test.dart:33-126`, `test/unit/models/task_request_model_test.dart:24-102`, `test/unit/tasks/task_filter_view_model_test.dart:39-219`, `test/unit/tasks/task_view_model_test.dart:27-124`, `test/widget/tasks/create_task_screen_test.dart:69-249`, `test/widget/tasks/tenders_screen_test.dart:44-96`.
- UNVERIFIED missing widget tests: no reviewed file was found for `test/widget/tasks/tender_payment_screen_test.dart`, `test/widget/tasks/requests_list_screen_test.dart`, or `test/widget/tasks/submit_request_sheet_test.dart` during the task-test file search above.
- UNVERIFIED missing service/unit tests: no reviewed file was found for `TaskService.payAwardedOffer`, `TaskRequestsService.replaceOffer`, or profile hydration with canonical `owner_id` rows; the existing task unit tests do not reference those paths. File Reference: existing task unit test set above.
- UNVERIFIED missing SQL contract tests: the repo review did not find checked-in SQL tests that assert `award_task_offer`, `pay_awarded_offer`, `replace_task_request`, or `process_payment_event_ledger` stay aligned with the Flutter tender flow. File Reference: reviewed SQL files above; live CI/test DB coverage is not represented in the repository files reviewed here.

## 4) Dead/Unused Code Candidates
- `TaskViewModel` image helper path is a dead-code candidate because the current editor flow never calls it, while only the unit test references `setPickedImages` and `removePickedImageAt`. File Reference: `lib/features/tasks/viewmodels/task_view_model.dart:35-111`, `lib/features/tasks/view/create_task_screen.dart:212-287`, `test/unit/tasks/task_view_model_test.dart:29-61`. Confirm by repo-wide search before removal.
- `TaskCard.useLegacyLayout` is a dead-code candidate because the current reviewed task discovery path uses `TaskCard` without setting that flag, and the file itself labels the branch as backward-compatibility only. File Reference: `lib/features/tasks/view/widgets/task_card.dart:15-46`, `lib/features/tasks/view/tenders_screen.dart:96-115`. Confirm by repo-wide search for non-default `useLegacyLayout` usage before removal.
- `TaskRequestsViewModel.accept` is a dead-code candidate because the current tender flow uses `award()` and `payForAwardedOffer()`, while `accept()` is explicitly deprecated. File Reference: `lib/features/tasks/viewmodels/task_requests_view_model.dart:115-175`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:127-166`. Confirm no remaining callers before removal.

## 5) Duplicate Code Candidates
- Task/profile hydration is duplicated across `TaskService` list/detail/create/home methods. Shared abstraction recommendation: create `lib/features/tasks/services/task_profile_hydrator.dart` and move ownership-ID resolution plus profile merge there. File Reference: `lib/features/tasks/services/task_service.dart:73-88`, `lib/features/tasks/services/task_service.dart:101-113`, `lib/features/tasks/services/task_service.dart:149-159`, `lib/features/tasks/services/task_service.dart:430-441`, `lib/features/tasks/services/task_service.dart:474-484`.
- Saved/bookmark toggle UI is duplicated between tender and booking cards. Shared abstraction recommendation: create `lib/features/tasks/view/widgets/shared/task_bookmark_button.dart`. File Reference: `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`, `lib/features/tasks/view/widgets/booking_task_card.dart:152-182`.
- Owner-side offer state transitions are duplicated between accept/reject/award SQL functions and their wrapper variants. Shared abstraction recommendation: extract shared SQL helpers for owner lookup, competing-offer rejection, conversation creation, and notification dispatch. File Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:199-335`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:337-468`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:472-570`.
- Tender payment function generations are duplicated across February and March migrations. Shared abstraction recommendation: collapse tender lifecycle into one canonical migration lineage and remove stale duplicate definitions/comments after deployment safety is confirmed. File Reference: `supabase/migrations/20260226_tender_award_payment_flow.sql:26-368`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:472-693`.

## 6) Refactor Plan (Exact Paths)
- Split the oversized task service into focused services:
  - Keep a compatibility facade at `lib/features/tasks/services/task_service.dart`.
  - Create `lib/features/tasks/services/task_query_service.dart` for task reads and profile hydration extracted from current `TaskService`. Source references: `lib/features/tasks/services/task_service.dart:31-501`.
  - Create `lib/features/tasks/services/task_offer_payment_service.dart` for `awardOffer`, `payAwardedOffer`, `getClientAwardedUnpaidOffers`, `getFreelancerAwardedUnpaidOffers`, and `escrowHoldOffer`. Source references: `lib/features/tasks/services/task_service.dart:598-875`.
  - Create `lib/features/tasks/services/task_profile_hydrator.dart` for owner-id resolution and profile merge. Source references: `lib/features/tasks/services/task_service.dart:43-88`, `lib/features/tasks/models/task_model.dart:127-149`.
- Split the editor UI into smaller files:
  - Move the screen shell to `lib/features/tasks/view/create_task/task_editor_screen.dart`.
  - Create `lib/features/tasks/view/create_task/widgets/task_editor_header.dart`.
  - Create `lib/features/tasks/view/create_task/widgets/task_basics_step.dart`.
  - Create `lib/features/tasks/view/create_task/widgets/task_pricing_step.dart`.
  - Create `lib/features/tasks/view/create_task/widgets/task_packages_step.dart`.
  - Create `lib/features/tasks/viewmodels/task_editor_view_model.dart` so category loading and submission validation leave the widget. Source references: `lib/features/tasks/view/create_task_screen.dart:164-301`.
- Split the request/payment UI into MVVM-safe boundaries:
  - Keep `lib/features/tasks/view/widgets/requests/requests_list_screen.dart` as a shell only.
  - Create `lib/features/tasks/viewmodels/tender_award_view_model.dart` for award/payment state transitions now in `RequestsListScreen` and `TenderPaymentScreen`. Source references: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:62-167`, `lib/features/tasks/view/tender_payment_screen.dart:39-109`.
  - Create `lib/features/tasks/view/widgets/requests/request_actions_section.dart` and `lib/features/tasks/view/widgets/requests/request_submission_controller.dart`.
  - Create `lib/features/tasks/view/widgets/shared/task_bookmark_button.dart` and update both task cards to use it.
- Normalize model/status handling:
  - Edit `lib/core/app_enums.dart` to introduce a task-delivery enum state.
  - Edit `lib/features/tasks/models/task_model.dart` to map `delivered` exactly.
  - Create `lib/features/tasks/models/task_status_mapper.dart` if the enum mapping logic stays non-trivial. Source references: `lib/core/app_enums.dart:13-22`, `lib/features/tasks/models/task_model.dart:190-225`.
- Migration strategy:
  - Use additive wrappers first: keep `task_service.dart`, `create_task_screen.dart`, and `task_details_screen.dart` forwarding to the new modules until imports are migrated. File Reference: `lib/features/tasks/services/task_service.dart:20-875`, `lib/features/tasks/view/create_task_screen.dart:16-943`, `lib/features/tasks/view/task_details_screen.dart:25-606`.
  - Defer deletion of old paths until `flutter analyze` and task-feature tests pass against the new imports. File Reference: `test/unit/tasks/task_view_model_test.dart:27-124`, `test/widget/tasks/create_task_screen_test.dart:69-249`, `test/widget/tasks/tenders_screen_test.dart:44-96`.

## 7) Fix Plan (Phases)
### Phase 1: Critical security & correctness
- Item 1:
  - What to change: remove the tender demo-payment path from production behavior; make tender payment either use a server-authoritative create/recovery flow or fail closed until that server flow exists.
  - Exact file(s) to edit/create: `lib/core/services/qicard_payment_service.dart`, `lib/features/tasks/view/tender_payment_screen.dart`, `lib/features/tasks/services/task_service.dart`, `supabase/migrations/20260301_fix_tender_payment_contract.sql` (new).
  - Acceptance criteria: no tender request can move from `accepted/unpaid` to `held` unless a server-verified payment artifact exists; `QiCardPaymentService.processPayment()` no longer returns demo success for the tender flow. File Reference: current unsafe path in `lib/features/tasks/view/tender_payment_screen.dart:72-82`, `lib/core/services/qicard_payment_service.dart:25-39`.
- Item 2:
  - What to change: enforce ledger success before calling `pay_awarded_offer`; reject or surface any `{ok:false}` ledger result.
  - Exact file(s) to edit/create: `lib/features/tasks/services/task_service.dart`, `lib/features/wallet/services/ledger_service.dart`, `test/unit/tasks/task_service_payment_test.dart` (new).
  - Acceptance criteria: `payAwardedOffer()` aborts on ledger failure, and a unit test covers insufficient-funds / invalid-gate responses. File Reference: current gap in `lib/features/tasks/services/task_service.dart:752-777`, `lib/features/wallet/services/ledger_service.dart:35-49`.
- Item 3:
  - What to change: stop mutating `profiles.active_role` from the client; rely on RLS as authorization and show UX guidance instead.
  - Exact file(s) to edit/create: `lib/features/tasks/services/task_requests_service.dart`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart`, `test/unit/tasks/task_requests_service_test.dart` (new), `supabase/migrations/20260301_fix_task_request_role_contract.sql` (new, only if policy changes are needed).
  - Acceptance criteria: offer submission no longer updates `profiles`; non-freelancer users receive a clear UX error without hidden profile mutation. File Reference: current mutation in `lib/features/tasks/services/task_requests_service.dart:106-124`.
- Item 4:
  - What to change: fix task/profile hydration and task-status parsing so canonical `owner_id` and `delivered` states are preserved.
  - Exact file(s) to edit/create: `lib/features/tasks/services/task_service.dart`, `lib/features/tasks/models/task_model.dart`, `lib/core/app_enums.dart`, `test/unit/models/task_model_test.dart` (extend).
  - Acceptance criteria: `getOpenTasksForHome()` and `getTaskById()` hydrate author data via `owner_id`/`client_id` fallback, and a delivered task round-trips as a distinct task status. File Reference: current mismatch in `lib/features/tasks/services/task_service.dart:430-441`, `lib/features/tasks/services/task_service.dart:474-484`, `lib/features/tasks/models/task_model.dart:138-149`, `lib/features/tasks/models/task_model.dart:190-216`.
- Item 5:
  - What to change: either add a checked-in `replace_task_request` migration or remove the client call and replace it with a supported path.
  - Exact file(s) to edit/create: `supabase/migrations/20260301_create_replace_task_request.sql` (new) or `lib/features/tasks/services/task_requests_service.dart`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart`.
  - Acceptance criteria: a fresh repo migration set contains every RPC required by the Flutter offer-replacement flow, or the Flutter flow no longer calls missing RPCs. File Reference: current call in `lib/features/tasks/services/task_requests_service.dart:188-197`; docs-only contract in `Sline_everything/SUPABASE_SETUP.md:1463-1470`.

### Phase 2: Refactor/structure
- Item 1:
  - What to change: move category loading and task submission validation out of `CreateTaskScreen` into `TaskEditorViewModel`.
  - Exact file(s) to edit/create: `lib/features/tasks/view/create_task/task_editor_screen.dart`, `lib/features/tasks/viewmodels/task_editor_view_model.dart`, `lib/features/tasks/view/create_task/widgets/*.dart`, `lib/features/tasks/view/create_task_screen.dart` (compat wrapper).
  - Acceptance criteria: the screen becomes a thin widget shell, and repository/service access disappears from the view layer. File Reference: current direct repository call in `lib/features/tasks/view/create_task_screen.dart:164-180`.
- Item 2:
  - What to change: move tender award/payment logic out of `RequestsListScreen` and `TenderPaymentScreen` into dedicated ViewModels/services.
  - Exact file(s) to edit/create: `lib/features/tasks/viewmodels/tender_award_view_model.dart`, `lib/features/tasks/viewmodels/tender_payment_view_model.dart`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`, `lib/features/tasks/view/tender_payment_screen.dart`.
  - Acceptance criteria: task views no longer instantiate `TaskService` or `TaskRequestsService` directly. File Reference: current direct service usage in `lib/features/tasks/view/tender_payment_screen.dart:42-49`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:257-288`.
- Item 3:
  - What to change: make `TaskRepository` use the injected client consistently and split `TaskService` into query/payment modules behind a facade.
  - Exact file(s) to edit/create: `lib/features/tasks/data/task_repository.dart`, `lib/features/tasks/services/task_query_service.dart`, `lib/features/tasks/services/task_offer_payment_service.dart`, `lib/features/tasks/services/task_service.dart`.
  - Acceptance criteria: tests can inject one Supabase client boundary, and read/write code paths no longer depend on the global singleton behind the repository’s back. File Reference: current DI split in `lib/features/tasks/data/task_repository.dart:8-24`.
- Item 4:
  - What to change: extract shared bookmark/favorite controls and remove cross-feature service fallback from `RequestTile`.
  - Exact file(s) to edit/create: `lib/features/tasks/view/widgets/shared/task_bookmark_button.dart`, `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart`, `lib/features/favorites/viewmodels/favorites_view_model.dart` (if a dedicated API surface is needed).
  - Acceptance criteria: request tiles receive all mutation callbacks from the outside and perform no direct favorites service writes. File Reference: current fallback in `lib/features/tasks/view/widgets/requests/widgets/request_tile.dart:97-119`.

### Phase 3: Tests
- Item 1:
  - What to change: add unit tests for tender payment failure paths, including ledger `{ok:false}`, expired deadlines, and missing payment RPCs.
  - Exact file(s) to edit/create: `test/unit/tasks/task_service_payment_test.dart`, `test/unit/tasks/task_requests_service_test.dart`.
  - Acceptance criteria: tests fail on the current implementation and pass only when payment is fail-closed. File Reference: untested current paths in `lib/features/tasks/services/task_service.dart:729-783`, `lib/features/tasks/services/task_requests_service.dart:172-248`.
- Item 2:
  - What to change: add widget tests for `TenderPaymentScreen`, `RequestsListScreen`, and `SubmitRequestSheet`.
  - Exact file(s) to edit/create: `test/widget/tasks/tender_payment_screen_test.dart`, `test/widget/tasks/requests_list_screen_test.dart`, `test/widget/tasks/submit_request_sheet_test.dart`.
  - Acceptance criteria: tests cover award-to-payment navigation, auto-open behavior, payment errors, and replace-offer UX. File Reference: current UI logic in `lib/features/tasks/view/tender_payment_screen.dart:56-109`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:127-205`, `lib/features/tasks/view/widgets/requests/submit_request_sheet.dart:254-317`.
- Item 3:
  - What to change: extend model and screen tests for `owner_id` hydration, `delivered` status, and invalid create-task payloads.
  - Exact file(s) to edit/create: `test/unit/models/task_model_test.dart`, `test/widget/tasks/create_task_screen_test.dart`.
  - Acceptance criteria: canonical ownership fields and delivered-state parsing stay covered, and zero-budget / empty-package submissions are rejected by tests. File Reference: current partial coverage in `test/unit/models/task_model_test.dart:60-82`, `test/widget/tasks/create_task_screen_test.dart:69-249`.

### Phase 4: Polish/perf
- Item 1:
  - What to change: replace the hardcoded `limit: 100` mutation refreshes with local item replacement or paged reloads.
  - Exact file(s) to edit/create: `lib/features/tasks/viewmodels/task_requests_view_model.dart`.
  - Acceptance criteria: award/pay/reject flows refresh only the affected records or the active page size. File Reference: current broad refresh in `lib/features/tasks/viewmodels/task_requests_view_model.dart:123-127`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:151-155`, `lib/features/tasks/viewmodels/task_requests_view_model.dart:176-181`.
- Item 2:
  - What to change: move auto-open modal scheduling out of `build()` and fix task title propagation into `TenderPaymentScreen`.
  - Exact file(s) to edit/create: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart`, `lib/features/tasks/view/tender_payment_screen.dart`.
  - Acceptance criteria: the submit sheet opens once per intended navigation, and payment summaries show the real task title. File Reference: current issues in `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:141-148`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:196-205`.
- Item 3:
  - What to change: centralize task/profile hydration and card bookmark UI to reduce repeated work and drift.
  - Exact file(s) to edit/create: `lib/features/tasks/services/task_profile_hydrator.dart`, `lib/features/tasks/view/widgets/shared/task_bookmark_button.dart`, `lib/features/tasks/view/widgets/tender_task_card.dart`, `lib/features/tasks/view/widgets/booking_task_card.dart`.
  - Acceptance criteria: one hydration helper and one bookmark widget are used everywhere in the task feature. File Reference: current duplication in `lib/features/tasks/services/task_service.dart:73-88`, `lib/features/tasks/view/widgets/tender_task_card.dart:253-286`, `lib/features/tasks/view/widgets/booking_task_card.dart:152-182`.

## 8) Verification Checklist
### Commands
- `flutter analyze`
- `flutter test test/unit/tasks test/widget/tasks test/unit/models/task_model_test.dart test/unit/models/task_request_model_test.dart`
- `rg -n "processPayment\\(" lib/features/tasks lib/core/services`
- `rg -n "replace_task_request" lib supabase/migrations Sline_everything/SUPABASE_SETUP.md`
- `rg -n "status = 'open'|status = 'assigned'|status = 'in_progress'|status = 'delivered'" lib/features/tasks lib/core/app_enums.dart supabase/migrations`
- `rg -n "from\\('profiles'\\)\\.(update|insert|delete)" lib/features/tasks`

### Manual Scenarios
- Tender payment safety:
  - Award a tender offer as the owner from `RequestsListScreen`. File Reference: `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:127-166`.
  - Attempt payment with the gateway unavailable or mocked failure.
  - Verify the task request stays `accepted/unpaid` and the task does not become active. File Reference: `lib/features/tasks/services/task_service.dart:729-783`.
- Ledger gate failure:
  - Use a user with insufficient wallet balance and attempt tender payment.
  - Verify the UI shows failure and no `held` state is written. File Reference: `supabase/migrations/20260301_fix_booking_ledger_amount_source.sql:195-219`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:625-648`.
- Profile hydration:
  - Load a task row whose canonical owner is `owner_id` and confirm author name/avatar render in discovery and detail screens.
  - Verify both `getOpenTasksForHome()` and `getTaskById()` populate `profiles`. File Reference: `lib/features/tasks/services/task_service.dart:401-441`, `lib/features/tasks/services/task_service.dart:464-484`.
- Editor validation:
  - Try creating a tender with blank/invalid budget.
  - Try creating a booking with incomplete package fields.
  - Verify the screen blocks submission before hitting Supabase. File Reference: `lib/features/tasks/view/create_task_screen.dart:212-287`.
- Replace-offer flow:
  - Submit an offer, reopen the sheet, and confirm replace-offer either succeeds against a checked-in RPC or is blocked with a clear UX error.
  - Verify no runtime RPC-not-found occurs in environments built from repo migrations only. File Reference: `lib/features/tasks/services/task_requests_service.dart:172-205`.

### Supabase/RLS Contract Checks
- Verify `tasks_select_authenticated_open_or_involved`, `tr_insert`, `tr_select`, and `tr_update_by_owner` exist and match the checked-in policies. File Reference: `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:16-102`.
- Verify `profiles_select_self` stays self-only and cross-user task hydration still uses `rpc_get_profile_summaries`, not direct profile reads. File Reference: `supabase/migrations/20260301_harden_home_related_read_policies.sql:23-31`, `supabase/migrations/20260301_create_rpc_get_profile_summaries.sql:3-47`, `lib/features/tasks/services/task_service.dart:47-69`.
- Verify any deployed tender payment flow only advances after a server-side payment check; do not rely on `DemoPaymentService` or client-only `processPayment()`. File Reference: `lib/core/services/qicard_payment_service.dart:25-39`, `lib/core/services/demo_payment_service.dart:23-40`.
- Verify a checked-in migration now defines `replace_task_request`, or the Flutter client no longer calls it. File Reference: `lib/features/tasks/services/task_requests_service.dart:188-197`, `Sline_everything/SUPABASE_SETUP.md:1463-1470`.
- UNVERIFIED live-project checks:
  - Confirm the deployed project contains the expected RPC/function versions and no stale duplicate behavior remains from older migrations.
  - Missing source of truth: live migration history / live SQL introspection was not available in this session.

## 9) Risks & Rollback Notes
- Risk: tightening tender payment to fail closed can temporarily disable a user-visible flow until the server-backed contract exists. File Reference: current user-facing path in `lib/features/tasks/view/tender_payment_screen.dart:56-109`, `lib/features/tasks/view/widgets/requests/requests_list_screen.dart:139-156`.
- Risk: enum/status normalization can affect dashboards, buttons, and any code that assumes `delivered` maps to `inProgress`. File Reference: `lib/core/app_enums.dart:13-22`, `lib/features/tasks/models/task_model.dart:190-216`, `lib/features/dashboard/services/dashboard_permission_service.dart:84-103`.
- Risk: splitting `TaskService`, `CreateTaskScreen`, and `TaskDetailsScreen` can break provider wiring and imports if the compatibility wrappers are removed too early. File Reference: `lib/main.dart:150-190`, `lib/app/main_navigation_screen.dart:41-117`, `lib/core/services/deep_link_service.dart:128-150`.
- Rollback steps:
  - Keep additive wrappers at `lib/features/tasks/services/task_service.dart`, `lib/features/tasks/view/create_task_screen.dart`, and `lib/features/tasks/view/task_details_screen.dart` until the new modules are stable. File Reference: `lib/features/tasks/services/task_service.dart:20-875`, `lib/features/tasks/view/create_task_screen.dart:16-943`, `lib/features/tasks/view/task_details_screen.dart:25-606`.
  - Deploy database changes additively before deleting old client paths, especially around `replace_task_request` and tender payment RPCs. File Reference: `lib/features/tasks/services/task_requests_service.dart:188-197`, `supabase/migrations/20260226_tender_award_payment_flow.sql:26-368`, `supabase/migrations/20260301_reconcile_orders_owner_contract.sql:472-693`.
  - UNVERIFIED live rollback SQL: exact rollback statements for the deployed Supabase project cannot be verified from repository files alone because live migration state was unavailable in this session.
