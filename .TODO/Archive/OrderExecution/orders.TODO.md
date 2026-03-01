> Historical Status: Superseded on 2026-03-01. Do not treat this file as the current runtime contract for the dashboard/orders surface.

> Current authoritative references:
> - `.TODO/DOCS_SYNC_2026-03-01_Orders_Dashboard_Decommission.md`
> - `.TODO/DOCS_REFERENCE_FIX_2026-03-01_Orders_Dashboard_Decommission.md`
> - `Sline_everything/DEVELOPER_GUIDE.md`
> - `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md`
> - `lib/features/orders/README.md`

# orders — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does: The `orders` feature implements a client-side "My Published Tasks" dashboard (`OrdersDashboardScreen`) with task status tabs, offer review (`OfferListSheet`), task edit/delete actions, and task chat entry points (File References: `lib/features/orders/view/orders_dashboard_screen.dart:18-35`, `lib/features/orders/view/orders_dashboard_screen.dart:149-180`, `lib/features/orders/view/widgets/offer_list_sheet.dart:13-29`, `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:3-10`, `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:35-43`).
- Boundaries (in scope): `lib/features/orders/**` and only the direct dependencies touched by imports/calls in the orders flow (`TaskService`, `TaskRequestsService`, `Task`/`TaskRequest` models, `ChatViewModel`, `NotificationService`, `ErrorMapper`, app navigation/provider wiring, feature/docs references) (File References: `lib/features/orders/view/orders_dashboard_screen.dart:1-16`, `lib/features/orders/view/widgets/offer_list_sheet.dart:1-12`, `lib/features/orders/viewmodels/orders_view_model.dart:1-12`, `lib/features/orders/services/orders_service.dart:1-23`).
- Boundaries (out of scope): Theme/formatting UI helpers and downstream screens/widgets (`CreateTaskScreen`, `TaskDetailsScreen`, `ChatScreen`, `SignedAvatar`) were only traced as call targets/imports and not fully audited for internal correctness; behavior inside those files is UNVERIFIED in this report (File References: `lib/features/orders/view/orders_dashboard_screen.dart:12-16`, `lib/features/orders/view/widgets/offer_list_sheet.dart:9-11`, `lib/features/orders/view/widgets/offer_list_sheet.dart:178-180`).
- Entry points (current repo state):
- `NavView.orders` exists in the bottom nav and is labeled `Dashboard`, not `Orders` (File References: `lib/core/app_enums.dart:4-6`, `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`).
- The nav screen slot for `NavView.orders` currently renders `DashboardScreen`, while the `OrdersDashboardScreen` import is commented out (File References: `lib/app/main_navigation_screen.dart:10-12`, `lib/app/main_navigation_screen.dart:38-49`).
- When `OrdersDashboardScreen` is instantiated, it loads data in `initState` and supports refresh button + pull-to-refresh (File References: `lib/features/orders/view/orders_dashboard_screen.dart:29-35`, `lib/features/orders/view/orders_dashboard_screen.dart:79-85`, `lib/features/orders/view/orders_dashboard_screen.dart:155-157`).
- Route wiring status: UNVERIFIED for any alternate route/path to `OrdersDashboardScreen`; repo search in this audit found no direct instantiation outside the file itself (Missing verification files/paths: any route registry or alternative screen composition file beyond `lib/app/main_navigation_screen.dart`).

## 1) Feature Map (Current Repo State)
- Primary feature files (with references)
- `lib/features/orders/view/orders_dashboard_screen.dart` — screen shell, tabs, list, edit/delete/chat action handlers (File References: `lib/features/orders/view/orders_dashboard_screen.dart:18-35`, `lib/features/orders/view/orders_dashboard_screen.dart:149-180`, `lib/features/orders/view/orders_dashboard_screen.dart:238-325`).
- `lib/features/orders/view/widgets/offer_list_sheet.dart` — offer list fetch/render + accept/reject buttons (File References: `lib/features/orders/view/widgets/offer_list_sheet.dart:13-29`, `lib/features/orders/view/widgets/offer_list_sheet.dart:84-148`, `lib/features/orders/view/widgets/offer_list_sheet.dart:248-320`).
- `lib/features/orders/view/widgets/order_card.dart` — task card UI, status badge, actions (File References: `lib/features/orders/view/widgets/order_card.dart:13-31`, `lib/features/orders/view/widgets/order_card.dart:34-79`, `lib/features/orders/view/widgets/order_card.dart:319-403`).
- `lib/features/orders/viewmodels/orders_view_model.dart` — feature state and actions (load/delete/accept/reject) (File References: `lib/features/orders/viewmodels/orders_view_model.dart:8-18`, `lib/features/orders/viewmodels/orders_view_model.dart:23-59`, `lib/features/orders/viewmodels/orders_view_model.dart:68-110`).
- `lib/features/orders/services/orders_service.dart` — facade over task + task-request services (File References: `lib/features/orders/services/orders_service.dart:11-23`, `lib/features/orders/services/orders_service.dart:25-58`).
- Direct dependencies (with references)
- App wiring / entry composition:
- `lib/app/main_navigation_screen.dart` (orders slot maps to `DashboardScreen`; `OrdersDashboardScreen` import commented) (File References: `lib/app/main_navigation_screen.dart:10-12`, `lib/app/main_navigation_screen.dart:38-49`).
- `lib/core/widgets/custom_bottom_nav_bar.dart` (`NavView.orders` item label/icon) (File References: `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`).
- `lib/main.dart` (global `OrdersViewModel` provider registration) (File References: `lib/main.dart:152-154`).
- Models / enums:
- `lib/core/app_enums.dart` (`TaskStatus`, `OfferStatus`, `NavView`) (File References: `lib/core/app_enums.dart:4-6`, `lib/core/app_enums.dart:10-19`, `lib/core/app_enums.dart:42-43`).
- `lib/features/tasks/models/task_model.dart` (task parsing/serialization) (File References: `lib/features/tasks/models/task_model.dart:108-166`, `lib/features/tasks/models/task_model.dart:168-192`).
- `lib/features/tasks/models/task_request_model.dart` (offer parsing/equality/hashCode) (File References: `lib/features/tasks/models/task_request_model.dart:46-93`, `lib/features/tasks/models/task_request_model.dart:156-194`).
- Services / action dependencies:
- `lib/features/tasks/services/task_service.dart` (`getTasksByUser`, `deleteTask`, task status DB mapping, duplicate legacy offer actions in same dependency file) (File References: `lib/features/tasks/services/task_service.dart:273-329`, `lib/features/tasks/services/task_service.dart:369-392`, `lib/features/tasks/services/task_service.dart:505-512`, `lib/features/tasks/services/task_service.dart:591-630`).
- `lib/features/tasks/services/task_requests_service.dart` (`listByTask`, `accept`, `reject`, notification side-effects) (File References: `lib/features/tasks/services/task_requests_service.dart:15-35`, `lib/features/tasks/services/task_requests_service.dart:37-77`, `lib/features/tasks/services/task_requests_service.dart:225-318`).
- `lib/features/notifications/services/notification_service.dart` (notifications insert side-effect used by accept/reject) (File References: `lib/features/notifications/services/notification_service.dart:69-94`).
- `lib/features/chat/viewmodels/chat_view_model.dart` (conversation fetch/start wrapper used by orders chat action) (File References: `lib/features/chat/viewmodels/chat_view_model.dart:151-171`).
- Error mapping:
- `lib/core/utils/error_mapper.dart` (RLS/session-friendly mapping available but not consistently used by orders UI) (File References: `lib/core/utils/error_mapper.dart:18-56`, `lib/core/utils/error_mapper.dart:58-76`, `lib/core/utils/error_mapper.dart:132-145`).
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs)
- Tables (observed in code path / direct dependencies):
- `tasks` read for "my orders" and delete action (File References: `lib/features/tasks/services/task_service.dart:279-283`, `lib/features/tasks/services/task_service.dart:373-374`; docs: `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:13-23`).
- `task_requests` read for offers list and mutate via accept/reject flow (File References: `lib/features/tasks/services/task_requests_service.dart:47-60`, `lib/features/tasks/services/task_requests_service.dart:229-233`, `lib/features/tasks/services/task_requests_service.dart:276-280`; docs: `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:15-23`).
- `profiles` joined for bidder info in offers list (File References: `lib/features/tasks/services/task_requests_service.dart:49-52`; docs: `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md:16-18`).
- `notifications` insert side-effects after accept/reject (File References: `lib/features/tasks/services/task_requests_service.dart:248-258`, `lib/features/tasks/services/task_requests_service.dart:295-305`, `lib/features/notifications/services/notification_service.dart:69-94`).
- RPCs (observed): `accept_task_request`, `reject_task_request`; docs also list `replace_task_request` in the same offer subsystem (File References: `lib/features/tasks/services/task_requests_service.dart:229-233`, `lib/features/tasks/services/task_requests_service.dart:276-280`, `Sline_everything/SUPABASE_SETUP.md:1386-1444`).
- Chat/conversation indirect touchpoint (orders -> chat VM wrapper): orders triggers task conversation creation/fetch via `ChatViewModel`; underlying repo/service SQL path is UNVERIFIED in this audit (File References: `lib/features/orders/view/orders_dashboard_screen.dart:305-323`, `lib/features/chat/viewmodels/chat_view_model.dart:153-171`; Missing verification files: `ChatRepository`/chat service SQL call sites not reviewed in this report).
- Storage buckets: No direct storage write/read calls observed in audited orders data/action code; avatar display delegates to `SignedAvatar` widget and its internals are UNVERIFIED in this audit (File References: `lib/features/orders/view/widgets/offer_list_sheet.dart:178-180`).
- Realtime channels: UNVERIFIED for this feature path; no realtime/channel code was observed in audited `orders` files or the touched orders service/viewmodel methods (File References: `lib/features/orders/view/orders_dashboard_screen.dart:1-16`, `lib/features/orders/viewmodels/orders_view_model.dart:1-111`, `lib/features/orders/services/orders_service.dart:1-59`).
- Edge functions: No direct edge function calls observed in the audited orders feature path (File References: `lib/features/orders/services/orders_service.dart:25-58`, `lib/features/tasks/services/task_requests_service.dart:37-77`, `lib/features/tasks/services/task_requests_service.dart:225-318`).

## 2) Evidence Index (Ground Truth)

| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
| --- | --- | --- | --- | --- |
| ARC-01 | `orders` nav slot is wired to `DashboardScreen`, not `OrdersDashboardScreen` | `lib/app/main_navigation_screen.dart:10-12`, `lib/app/main_navigation_screen.dart:38-49`, `lib/core/widgets/custom_bottom_nav_bar.dart:55-61` | High | Feature reachability/intended UX is UNVERIFIED. |
| SEC-01 | Orders UI exposes raw exception text in snackbars | `lib/features/orders/view/orders_dashboard_screen.dart:290-294`, `lib/features/orders/view/orders_dashboard_screen.dart:317-322` | Medium | `ErrorMapper` exists but is bypassed. |
| SEC-02 | Load errors are swallowed in VM and can collapse to empty-state UX | `lib/features/orders/viewmodels/orders_view_model.dart:47-58`, `lib/features/orders/view/orders_dashboard_screen.dart:151-155`, `lib/core/utils/error_mapper.dart:58-76` | Medium | Hides RLS/session failures from users. |
| SEC-03 | Offers list query uses `select('*')` and pulls broader columns than UI needs | `lib/features/tasks/services/task_requests_service.dart:46-52`, `lib/features/orders/view/widgets/offer_list_sheet.dart:175-244` | Medium | Data minimization + payload size issue. |
| SEC-04 | Accept/reject authorization contract is documented but baseline SQL function bodies are not present in repo (UNVERIFIED) | `Sline_everything/SUPABASE_SETUP.md:1386-1444`, `Sline_everything/SUPABASE_SETUP.md:1010-1040`, `supabase/migrations/20260226_tender_award_payment_flow.sql:23-33` | Medium | Missing baseline `accept_task_request`/`reject_task_request` SQL files prevents repo-only verification. |
| DI-01 | Task status parser does not map DB `in_progress`, but write path emits `in_progress` | `lib/core/app_enums.dart:10-19`, `lib/features/tasks/models/task_model.dart:135-138`, `lib/features/tasks/services/task_service.dart:505-512` | Critical | Can misclassify in-progress tasks as `open`. |
| DI-02 | Unknown/expanded offer statuses default to `pending`, and UI gates actions on `isPending` | `lib/features/tasks/models/task_request_model.dart:72-75`, `lib/features/orders/view/widgets/offer_list_sheet.dart:249-294` | High | Can enable invalid accept/reject actions. |
| DI-03 | Offer action buttons have no in-flight guard and no local `catch`, enabling duplicate taps / async error leaks | `lib/features/orders/view/widgets/offer_list_sheet.dart:254-261`, `lib/features/orders/view/widgets/offer_list_sheet.dart:276-280` | Medium | Race/retry noise and unstable UX. |
| DI-04 | `TaskRequest.operator==` and `hashCode` use different field sets | `lib/features/tasks/models/task_request_model.dart:156-185` | Medium | Violates equality contract for set/map usage. |
| DI-05 | Soft-delete filtering is inconsistent across `task_requests` queries (UNVERIFIED impact on orders list) | `lib/features/tasks/services/task_requests_service.dart:22-29`, `lib/features/tasks/services/task_requests_service.dart:47-60` | Medium | Assumes `deleted_at` semantics apply to orders offer listing. |
| ARC-02 | Offer sheet mixes local `FutureBuilder` state with global dashboard `isLoading` state | `lib/features/orders/view/widgets/offer_list_sheet.dart:23-29`, `lib/features/orders/view/widgets/offer_list_sheet.dart:86-95` | Medium | Cross-state coupling / wrong spinner source. |
| ARC-03 | Orders view orchestrates chat conversation creation + loading/error UI directly | `lib/features/orders/view/orders_dashboard_screen.dart:305-323`, `lib/features/chat/viewmodels/chat_view_model.dart:153-171` | Medium | Cross-feature business flow in view layer. |
| ARC-04 | `OrdersViewModel` is registered globally at app root | `lib/main.dart:152-154` | Low | Broader lifecycle than feature-local state may require. |
| CQ-01 | `OrdersService.closeTask()` is present but not referenced in audited code paths (UNVERIFIED usage absence) | `lib/features/orders/services/orders_service.dart:55-58` | Low | Confirm with repo search before deletion. |
| CQ-02 | `OrdersService.deleteTask()` comment claims a guard that the code path does not enforce locally | `lib/features/orders/services/orders_service.dart:50-53`, `lib/features/tasks/services/task_service.dart:369-392` | Low | Actual enforcement likely DB/RLS/constraints. |
| CQ-03 | `TaskRequestsService.accept()` and `reject()` duplicate RPC response parsing logic | `lib/features/tasks/services/task_requests_service.dart:234-246`, `lib/features/tasks/services/task_requests_service.dart:281-293` | Low | Shared helper would reduce drift. |
| PERF-01 | `filteredOrders` allocates new lists and is called repeatedly in a single build | `lib/features/orders/viewmodels/orders_view_model.dart:23-44`, `lib/features/orders/view/orders_dashboard_screen.dart:151-167` | High | Scales poorly with larger lists/rebuilds. |
| PERF-02 | `OrdersDashboardScreen` watches whole VM, causing broad rebuild scope | `lib/features/orders/view/orders_dashboard_screen.dart:38-42`, `lib/features/orders/view/orders_dashboard_screen.dart:43-185` | Medium | Header/tabs/list all rebuild on any notify. |
| PERF-03 | Offer sheet rebuilds on unrelated dashboard loading changes via `context.watch<OrdersViewModel>().isLoading` | `lib/features/orders/view/widgets/offer_list_sheet.dart:86-95` | Low-Medium | UI jitter/spinner misrepresentation. |
| TEST-01 | No feature-specific `orders` tests were found in this audit (UNVERIFIED negative search) | UNVERIFIED | High | Confirm with `rg -n "OrdersViewModel|OrdersDashboardScreen|OfferListSheet" test integration_test`. |
| TEST-02 | Existing model tests omit `in_progress` parser coverage and unknown-offer-status coverage | `test/unit/models/task_model_test.dart:33-96`, `test/unit/models/task_request_model_test.dart:24-77` | High | Regressions can pass current tests. |

## 3) Findings

### 3.1 Security (Highest Priority)
- `SEC-01` — Raw exception text is rendered directly to end users in delete/chat error snackbars (File References: `lib/features/orders/view/orders_dashboard_screen.dart:290-294`, `lib/features/orders/view/orders_dashboard_screen.dart:317-322`; `ErrorMapper` available at `lib/core/utils/error_mapper.dart:18-76`). Impact: internal error text (RLS, RPC, schema messages) can leak to clients and create inconsistent UX. Exploit/Failure scenario: a rejected RPC or Postgrest error returns backend details and the UI displays them verbatim in `SnackBar` content.
- `SEC-02` — `OrdersViewModel.loadOrders()` logs and suppresses exceptions without exposing an error state, while the screen falls through to empty-state UI (File References: `lib/features/orders/viewmodels/orders_view_model.dart:47-58`, `lib/features/orders/view/orders_dashboard_screen.dart:151-155`, `lib/core/utils/error_mapper.dart:58-76`). Impact: RLS/session/authz failures can be misrepresented as "no tasks," hiding authorization failures. Exploit/Failure scenario: expired session (`42501`) is mapped in `ErrorMapper`, but the orders screen still shows "No Open Tasks" after the VM swallows the exception.
- `SEC-03` — Offers query selects `*` from `task_requests` and joins profiles, while the UI only renders a subset of fields (File References: `lib/features/tasks/services/task_requests_service.dart:46-52`, `lib/features/orders/view/widgets/offer_list_sheet.dart:175-244`). Impact: increases exposure surface and payload size; future sensitive columns added to `task_requests` may be fetched unnecessarily. Exploit/Failure scenario: a later schema addition (internal audit metadata/payment fields) becomes available to the client payload even if the UI does not need it.
- `SEC-04` — Server-side authorization contract for `accept_task_request`/`reject_task_request` is documented but not fully verifiable from repo SQL migrations in this audit (UNVERIFIED) (File References: `Sline_everything/SUPABASE_SETUP.md:1386-1444`, `Sline_everything/SUPABASE_SETUP.md:1010-1040`, `supabase/migrations/20260226_tender_award_payment_flow.sql:23-33`). Impact: cannot prove current deployed RPCs/policies match the documented task-owner authorization rules. Exploit/Failure scenario: docs say task owner validation exists, but if live SQL diverges, unauthorized accept/reject could succeed or legitimate actions could fail.

### 3.2 Data Integrity
- `DI-01` — Task status parsing is inconsistent with DB wire format: `TaskStatus.inProgress` exists in Dart, `TaskService` writes `in_progress`, but `Task.fromJson` only matches enum names and defaults to `open` (File References: `lib/core/app_enums.dart:10-19`, `lib/features/tasks/services/task_service.dart:505-512`, `lib/features/tasks/models/task_model.dart:135-138`). Impact: in-progress tasks can be reclassified as open in the orders dashboard. Failure scenario: a DB row with `status='in_progress'` appears under the `Open` tab and exposes "View Offers" or open-state UI instead of progress/chat actions.
- `DI-02` — Unknown/expanded offer statuses are coerced to `OfferStatus.pending`, and the sheet enables action buttons when `offer.isPending` is true (File References: `lib/features/tasks/models/task_request_model.dart:72-75`, `lib/features/orders/view/widgets/offer_list_sheet.dart:249-294`). Impact: invalid state transitions can be attempted from the UI. Failure scenario: backend returns a new status (for example, payment-related/expired) and the UI incorrectly shows `Accept` / `Reject` buttons.
- `DI-03` — Offer action buttons call VM methods with `.then(...)` only, with no local `catch` and no action-in-flight disabling (File References: `lib/features/orders/view/widgets/offer_list_sheet.dart:254-261`, `lib/features/orders/view/widgets/offer_list_sheet.dart:276-280`). Impact: duplicate taps can issue duplicate requests and errors are not handled in-sheet. Failure scenario: rapid double-tap sends two accept RPCs, creating race/error noise and unpredictable UX.
- `DI-04` — `TaskRequest` equality/hash code contract is inconsistent because `hashCode` includes `paymentStatus`/`taskTitle` while `operator==` does not (File References: `lib/features/tasks/models/task_request_model.dart:156-185`). Impact: set/map membership and dedup behavior can break if these fields differ. Failure scenario: two `TaskRequest` objects compare equal but hash differently, causing duplicate entries or failed lookups in future state containers.
- `DI-05` — Soft-delete filtering behavior is inconsistent inside the same dependency service and impact on orders offers is UNVERIFIED (File References: `lib/features/tasks/services/task_requests_service.dart:22-29`, `lib/features/tasks/services/task_requests_service.dart:47-60`). Impact: if `deleted_at` is part of active-offer semantics for list views, orders may display offers excluded elsewhere. Failure scenario: an archived/deleted offer still appears in the orders sheet because `listByTask()` does not apply `deleted_at IS NULL` while another method does.

### 3.3 Architecture
- `ARC-01` — Feature entry-point mismatch: `NavView.orders` points to `DashboardScreen`, not `OrdersDashboardScreen`, and the orders import is commented out (File References: `lib/app/main_navigation_screen.dart:10-12`, `lib/app/main_navigation_screen.dart:38-49`, `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`, `.TODO/CodexRefactor/01_FEATURES_INDEX.md:189-190`). Impact: the audited `orders` feature may be unreachable in the current app flow. Failure scenario: users tap the orders/dashboard nav item and land in freelancer dashboard instead of the orders feature.
- `ARC-02` — `OfferListSheet` mixes widget-local async state (`FutureBuilder`) with global dashboard loading state (`OrdersViewModel.isLoading`) (File References: `lib/features/orders/view/widgets/offer_list_sheet.dart:23-29`, `lib/features/orders/view/widgets/offer_list_sheet.dart:86-95`). Impact: loading UI semantics become incorrect and tightly coupled to unrelated dashboard refreshes. Failure scenario: a dashboard reload triggers a spinner in the offers sheet even if the offers query is already resolved.
- `ARC-03` — Orders view handles cross-feature orchestration for chat conversation creation, loading overlay management, navigation, and raw error formatting (File References: `lib/features/orders/view/orders_dashboard_screen.dart:305-323`, `lib/features/chat/viewmodels/chat_view_model.dart:153-171`). Impact: business orchestration lives in the view layer, reducing testability and increasing UI complexity. Failure scenario: chat flow changes require editing orders UI instead of a dedicated VM/service boundary.
- `ARC-04` — `OrdersViewModel` is created in the app-wide provider tree, extending lifecycle beyond the feature screen scope (File References: `lib/main.dart:152-154`). Impact: stale state and unnecessary retained data/listeners are more likely if the feature is navigated infrequently. Failure scenario: orders data persists unexpectedly across user flows and rebuilds when a screen-local provider would be sufficient.
- Architecture guard pass (limited): No direct Supabase client imports/calls were observed in the audited orders view files; views delegate data actions through `OrdersViewModel` and `ChatViewModel` (File References: `lib/features/orders/view/orders_dashboard_screen.dart:1-16`, `lib/features/orders/view/orders_dashboard_screen.dart:33-34`, `lib/features/orders/view/widgets/offer_list_sheet.dart:1-12`, `lib/features/orders/view/widgets/offer_list_sheet.dart:28-29`, `lib/features/orders/viewmodels/orders_view_model.dart:8-12`, `lib/features/orders/services/orders_service.dart:1-23`).

### 3.4 Code Quality
- `CQ-01` — `OrdersService.closeTask()` is present but not referenced in the audited feature code paths (UNVERIFIED usage absence) (File References: `lib/features/orders/services/orders_service.dart:55-58`). Impact: dead API surface increases maintenance cost. Failure scenario: developers assume close-task behavior is wired/tested because the method exists.
- `CQ-02` — `OrdersService.deleteTask()` comment claims a local business guard ("if no active bookings/contracts"), but the implementation immediately delegates to `TaskService.deleteTask()` with no such check in this code path (File References: `lib/features/orders/services/orders_service.dart:50-53`, `lib/features/tasks/services/task_service.dart:369-392`). Impact: comments overstate protections and can mislead refactors/reviews. Failure scenario: a reviewer trusts the comment and skips verifying DB/RLS/constraint enforcement.
- `CQ-03` — `TaskRequestsService.accept()` and `reject()` duplicate RPC result-shape parsing logic and notification dispatch structure (File References: `lib/features/tasks/services/task_requests_service.dart:234-246`, `lib/features/tasks/services/task_requests_service.dart:281-293`, `lib/features/tasks/services/task_requests_service.dart:248-258`, `lib/features/tasks/services/task_requests_service.dart:295-305`). Impact: changes to RPC return formats require editing multiple branches. Failure scenario: one path is updated for a new RPC payload shape while the other still throws `Unexpected RPC result format...`.
- `CQ-04` — `OrdersViewModel.acceptOffer()` comments describe an optimistic update path, but the actual implementation always reloads the list when the task is found (File References: `lib/features/orders/viewmodels/orders_view_model.dart:84-95`). Impact: comment drift increases maintenance confusion. Failure scenario: future refactor preserves comments and unintentionally duplicates reloads while expecting optimistic state mutation.

### 3.5 Performance
- `PERF-01` — `filteredOrders` rebuilds and allocates a new list on every getter access, and the screen calls it multiple times in the same build (`isEmpty`, `length`, index access) (File References: `lib/features/orders/viewmodels/orders_view_model.dart:23-44`, `lib/features/orders/view/orders_dashboard_screen.dart:151-167`). Impact: avoidable CPU/allocation overhead increases with larger order lists. Failure scenario: frequent tab switches or notify cycles cause repeated filtering work and frame drops on mid-range devices.
- `PERF-02` — `OrdersDashboardScreen` uses `context.watch<OrdersViewModel>()` at the screen root, rebuilding header, tabs, and list on any VM state change (File References: `lib/features/orders/view/orders_dashboard_screen.dart:38-42`, `lib/features/orders/view/orders_dashboard_screen.dart:43-185`). Impact: broad rebuild scope amplifies the filtered-list overhead and repaints static UI. Failure scenario: toggling `isLoading` or accepting one offer rebuilds the entire dashboard tree.
- `PERF-03` — Offer sheet subscribes to `OrdersViewModel.isLoading`, which is dashboard-level state, creating extra and semantically incorrect rebuilds (File References: `lib/features/orders/view/widgets/offer_list_sheet.dart:86-95`, `lib/features/orders/viewmodels/orders_view_model.dart:46-58`). Impact: spinner toggles can be driven by unrelated dashboard loads. Failure scenario: a background dashboard refresh causes the offers sheet to flash loading even when the offers list is already displayed.
- `PERF-04` — Offers list query over-fetch (`*`) increases payload and parsing work relative to the rendered fields (File References: `lib/features/tasks/services/task_requests_service.dart:46-52`, `lib/features/orders/view/widgets/offer_list_sheet.dart:175-244`). Impact: extra network and parsing overhead per sheet open. Failure scenario: task requests table grows with additional columns and sheet latency increases without UI benefit.

### 3.6 Testing Gaps
- `TEST-01` — No feature-specific tests for `OrdersViewModel`, `OrdersDashboardScreen`, or `OfferListSheet` were found in this audit (UNVERIFIED negative search) (File Reference: UNVERIFIED; Missing verification files: any tests under `test/**` or `integration_test/**` referencing `OrdersViewModel`, `OrdersDashboardScreen`, `OfferListSheet`). Impact: critical orders flows (load/filter/delete/accept/reject) can regress unnoticed.
- `TEST-02` — Current `Task` model tests cover unknown-status fallback but do not assert DB `in_progress` parsing, and `TaskRequest` model tests do not cover unknown/expanded statuses affecting UI action gating (File References: `test/unit/models/task_model_test.dart:33-96`, `test/unit/models/task_request_model_test.dart:24-77`). Impact: the highest-risk parser regressions in the orders path are not protected by tests.
- `TEST-03` — No tests verify the orders entry-point wiring mismatch (`NavView.orders` -> `DashboardScreen`) or intended feature reachability (UNVERIFIED negative test coverage) (File References: `lib/app/main_navigation_screen.dart:38-49`, `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`). Impact: a hidden/decommissioned feature can remain undetected while docs and feature inventory still reference it.

## 4) Dead/Unused Code Candidates
- `lib/features/orders/services/orders_service.dart:55-58` (`closeTask`) appears unused in the audited feature path and repo references were not observed in this audit; why candidate: no call site is present in `orders` UI/VM/service flow (File References: `lib/features/orders/view/orders_dashboard_screen.dart:238-325`, `lib/features/orders/viewmodels/orders_view_model.dart:46-110`, `lib/features/orders/services/orders_service.dart:25-58`). How to confirm: run `rg -n "closeTask\(" lib` and verify no intended future TODO references (UNVERIFIED until search is re-run as part of fix phase).
- `lib/features/orders/view/orders_dashboard_screen.dart:18-325` (and likely the surrounding `orders` feature module) is a reachability candidate because the app nav slot renders `DashboardScreen` and the orders import is commented out (File References: `lib/app/main_navigation_screen.dart:10-12`, `lib/app/main_navigation_screen.dart:38-49`, `.TODO/CodexRefactor/01_FEATURES_INDEX.md:189-190`). How to confirm: identify any alternate route/composition that instantiates `OrdersDashboardScreen`; current route/composition evidence is UNVERIFIED beyond the files audited here.

## 5) Duplicate Code Candidates
- RPC result parsing duplication in `TaskRequestsService.accept()` and `TaskRequestsService.reject()` (File References: `lib/features/tasks/services/task_requests_service.dart:234-246`, `lib/features/tasks/services/task_requests_service.dart:281-293`). Proposed shared abstraction: create a private helper (e.g., `_parseTaskRequestRpcResult`) in `lib/features/tasks/services/task_requests_service.dart` or extract to `lib/features/tasks/services/task_request_rpc_parser.dart`.
- Notification side-effect scaffolding after accept/reject is structurally duplicated (File References: `lib/features/tasks/services/task_requests_service.dart:248-258`, `lib/features/tasks/services/task_requests_service.dart:295-305`, `lib/features/notifications/services/notification_service.dart:69-94`). Proposed shared abstraction: `_notifyOfferDecision(TaskRequest model, {required bool accepted})` in `TaskRequestsService`.
- Status-style mapping duplication in `OrderCard` for equivalent visual branches (`closed` + `completed`, `draft` + `canceled`) (File References: `lib/features/orders/view/widgets/order_card.dart:46-77`). Proposed shared abstraction: `_OrderStatusStyle` mapper (local private class or helper file `lib/features/orders/view/widgets/order_status_style.dart`).

## 6) Refactor Plan (Exact Paths)
- Entry-point wiring fix (decision gate first; product intent is UNVERIFIED)
- Option A (recommended if `orders` feature should be active):
- Edit `lib/app/main_navigation_screen.dart` to replace `DashboardScreen()` in the `NavView.orders` slot with `OrdersDashboardScreen()` and restore the import (File References: `lib/app/main_navigation_screen.dart:10-12`, `lib/app/main_navigation_screen.dart:38-49`).
- Edit `lib/core/widgets/custom_bottom_nav_bar.dart` to label `NavView.orders` consistently (for example `Orders` instead of `Dashboard`) if product naming requires it (File References: `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`).
- Option B (if `orders` is intentionally retired):
- Move legacy feature files under a clear deprecated path and update docs/indexes to prevent false audit targets, e.g. `lib/features/orders/**` -> `lib/features/_deprecated/orders/**` (exact move paths mirror current files). Migration strategy: keep export stubs for one release to avoid merge conflicts.
- Screen decomposition (after reachability decision)
- Split `lib/features/orders/view/orders_dashboard_screen.dart` into:
- `lib/features/orders/view/orders_dashboard_screen.dart` (screen shell + navigation callbacks only)
- `lib/features/orders/view/widgets/orders_dashboard_header.dart`
- `lib/features/orders/view/widgets/orders_status_tabs.dart`
- `lib/features/orders/view/widgets/orders_task_list.dart`
- `lib/features/orders/view/widgets/orders_empty_state.dart`
- Migration strategy: preserve public `OrdersDashboardScreen` API; move private widget methods into dedicated widgets one at a time.
- Offer-sheet state isolation
- Add `lib/features/orders/viewmodels/order_offers_view_model.dart` for offer loading/action-in-flight/error state.
- Keep `lib/features/orders/view/widgets/offer_list_sheet.dart` as the modal container and move `_OfferItem` to `lib/features/orders/view/widgets/order_offer_item.dart`.
- Migration strategy: local provider inside sheet first; leave `OrdersViewModel.fetchOffers/acceptOffer/rejectOffer` delegates temporarily for compatibility.
- Status codec hardening
- Add `lib/features/tasks/models/task_status_codec.dart` and `lib/features/tasks/models/offer_status_codec.dart`.
- Update `lib/features/tasks/models/task_model.dart` and `lib/features/tasks/models/task_request_model.dart` to parse DB snake_case safely and preserve unknown values as non-actionable states.
- Migration strategy: keep existing enum types; codecs become translation layer only.
- Task request service de-dup
- Extract RPC result parsing helper to `lib/features/tasks/services/task_request_rpc_parser.dart` or private helper methods in `lib/features/tasks/services/task_requests_service.dart`.
- Optionally deprecate duplicate offer action methods in `lib/features/tasks/services/task_service.dart` after call-site verification (File References: `lib/features/tasks/services/task_service.dart:591-630`). Migration strategy: delegate old methods to `TaskRequestsService` before removal.

## 7) Fix Plan (Phases)

Phase 1: Critical security & correctness
- Resolve reachability intent for `orders` feature (active vs retired) and implement the chosen nav wiring/deprecation path.
- What to change: wire `NavView.orders` to `OrdersDashboardScreen` or officially decommission the feature and update docs/indexes.
- Exact file(s) to edit/create: `lib/app/main_navigation_screen.dart`, `lib/core/widgets/custom_bottom_nav_bar.dart`, `.TODO/CodexRefactor/01_FEATURES_INDEX.md`, `Sline_everything/DEVELOPER_GUIDE/Orders Feature.md` (if decommissioned/renamed).
- Acceptance criteria: tapping the `NavView.orders` item reaches the intended screen consistently, and docs match runtime wiring (File References for current mismatch: `lib/app/main_navigation_screen.dart:38-49`, `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`, `.TODO/CodexRefactor/01_FEATURES_INDEX.md:189-190`).
- Fix task status DB mapping (`in_progress` <-> `TaskStatus.inProgress`).
- What to change: introduce parse mapping in `Task.fromJson` (or shared codec) and preserve existing write mapping.
- Exact file(s) to edit/create: `lib/features/tasks/models/task_model.dart`, `lib/features/tasks/services/task_service.dart` (only if codec extraction changes call sites), optionally `lib/features/tasks/models/task_status_codec.dart`.
- Acceptance criteria: a task JSON payload with `status: 'in_progress'` parses to `TaskStatus.inProgress`; no regression for `open/assigned/closed`.
- Fix offer status parsing to avoid defaulting unknown values to actionable `pending`.
- What to change: parse unknown statuses into a non-actionable state or explicit error path; update UI gating in `OfferListSheet`.
- Exact file(s) to edit/create: `lib/features/tasks/models/task_request_model.dart`, `lib/features/orders/view/widgets/offer_list_sheet.dart`, optionally `lib/features/tasks/models/offer_status_codec.dart`.
- Acceptance criteria: unknown/expanded status values do not render `Accept`/`Reject` buttons.
- Remove raw error leakage in orders UI and surface friendly mapped errors.
- What to change: route delete/chat errors through `ErrorMapper` (or a feature-specific UI error presenter) and add explicit load error state in `OrdersViewModel`.
- Exact file(s) to edit/create: `lib/features/orders/view/orders_dashboard_screen.dart`, `lib/features/orders/viewmodels/orders_view_model.dart`, optionally `lib/features/orders/view/widgets/orders_error_state.dart`.
- Acceptance criteria: RLS/session/network failures show friendly English messages and never interpolate raw exception strings.
- Add offer action in-flight/error handling to prevent duplicate taps.
- What to change: disable buttons while request is running; handle `catch` in sheet/VM and show feedback.
- Exact file(s) to edit/create: `lib/features/orders/view/widgets/offer_list_sheet.dart`, `lib/features/orders/viewmodels/orders_view_model.dart` (or `lib/features/orders/viewmodels/order_offers_view_model.dart` if added in Phase 1).
- Acceptance criteria: repeated taps during an accept/reject request do not issue duplicate calls; failures are visible and sheet state remains consistent.
- Tighten `listByTask` projection to the fields rendered in the sheet.
- What to change: replace `*` with explicit column list and keep the profile join fields needed by UI.
- Exact file(s) to edit/create: `lib/features/tasks/services/task_requests_service.dart`.
- Acceptance criteria: offers sheet still renders name/avatar/price/days/note/status/time correctly after projection reduction.
- Verify Supabase/RLS contract against real SQL metadata (UNVERIFIED in repo-only audit).
- What to change: inspect live/staging policies and function definitions for `tasks`, `task_requests`, `accept_task_request`, `reject_task_request`.
- Exact file(s) to edit/create: no repo file required for inspection; add/update a repo SQL export or migration docs if discrepancies are found (UNVERIFIED target files until DB metadata is exported).
- Acceptance criteria: task-owner-only accept/reject and owner-only task delete are proven by actual SQL/function bodies, not docs alone.

Phase 2: Refactor/structure
- Split the orders screen into header/tabs/list/empty/error widgets to shrink rebuild scope.
- What to change: move private widget-building methods and list rendering out of `OrdersDashboardScreen`.
- Exact file(s) to edit/create: `lib/features/orders/view/orders_dashboard_screen.dart`, `lib/features/orders/view/widgets/orders_dashboard_header.dart`, `lib/features/orders/view/widgets/orders_status_tabs.dart`, `lib/features/orders/view/widgets/orders_task_list.dart`, `lib/features/orders/view/widgets/orders_empty_state.dart`.
- Acceptance criteria: screen behavior is unchanged, but widget tree can scope rebuilds more narrowly.
- Isolate offer-sheet state from dashboard state.
- What to change: introduce a local offers VM/state holder and remove `context.watch<OrdersViewModel>().isLoading` from the sheet.
- Exact file(s) to edit/create: `lib/features/orders/view/widgets/offer_list_sheet.dart`, `lib/features/orders/viewmodels/order_offers_view_model.dart`, `lib/features/orders/view/widgets/order_offer_item.dart`.
- Acceptance criteria: offer-sheet loading/error/action states are independent of dashboard refresh state.
- De-duplicate TaskRequestsService accept/reject internals.
- What to change: extract shared RPC result parser + notification helper.
- Exact file(s) to edit/create: `lib/features/tasks/services/task_requests_service.dart`, optional `lib/features/tasks/services/task_request_rpc_parser.dart`.
- Acceptance criteria: only one parser path exists for task-request RPC return shapes.
- Resolve dead/comment drift.
- What to change: remove `OrdersService.closeTask()` if unused, or wire/test it; correct misleading delete comment.
- Exact file(s) to edit/create: `lib/features/orders/services/orders_service.dart`.
- Acceptance criteria: no unused public API remains in orders service without an explicit owner/intended caller.

Phase 3: Tests
- Add parser regression tests for task status and offer status.
- What to change: add tests for `in_progress` task parsing and unknown/expanded offer status behavior.
- Exact file(s) to edit/create: `test/unit/models/task_model_test.dart`, `test/unit/models/task_request_model_test.dart`.
- Acceptance criteria: tests fail on current parser bugs and pass after fixes.
- Add OrdersViewModel unit tests.
- What to change: test load success/failure state, tab filtering, delete/accept/reject state updates/errors using mocked `OrdersService`.
- Exact file(s) to edit/create: `test/unit/features/orders/orders_view_model_test.dart`.
- Acceptance criteria: VM exposes distinct loading/error/data states and action methods handle failure paths.
- Add widget tests for dashboard + offer sheet.
- What to change: verify loading/empty/error states, tab filtering display, and accept/reject button disabling/error messaging.
- Exact file(s) to edit/create: `test/widget/features/orders/orders_dashboard_screen_test.dart`, `test/widget/features/orders/offer_list_sheet_test.dart`.
- Acceptance criteria: critical UI states are covered and no raw exception text is shown.
- Add navigation wiring/regression test (if feature remains active).
- What to change: assert `NavView.orders` selects `OrdersDashboardScreen` (or documented replacement if decommissioned).
- Exact file(s) to edit/create: `test/widget/app/main_navigation_screen_test.dart` (or equivalent existing nav test file).
- Acceptance criteria: future nav regressions cannot silently orphan the orders feature.

Phase 4: Polish/perf
- Cache filtered orders once per build (or precompute on state changes).
- What to change: compute `filteredOrders` once in build/local variable or maintain derived list in VM with invalidation on `_allOrders`/tab changes.
- Exact file(s) to edit/create: `lib/features/orders/view/orders_dashboard_screen.dart`, `lib/features/orders/viewmodels/orders_view_model.dart`.
- Acceptance criteria: `filteredOrders` is not recomputed multiple times per frame.
- Reduce rebuild scope with `Selector`/split consumers.
- What to change: narrow subscriptions for header/tabs/list or introduce dedicated selectors.
- Exact file(s) to edit/create: `lib/features/orders/view/orders_dashboard_screen.dart`, new split widgets under `lib/features/orders/view/widgets/`.
- Acceptance criteria: changing `isLoading` or `activeTab` does not rebuild unrelated subtrees unnecessarily.
- Improve offer-sheet UX after accept/reject.
- What to change: refresh offer list or update local item state instead of unconditional `Navigator.pop` only.
- Exact file(s) to edit/create: `lib/features/orders/view/widgets/offer_list_sheet.dart`, `lib/features/orders/viewmodels/order_offers_view_model.dart`.
- Acceptance criteria: user sees deterministic post-action state without requiring modal reopen.

## 8) Verification Checklist

### Commands
- `flutter analyze` (baseline re-run in this audit shows 5 unrelated info-level issues, none in `orders`) (File Reference for current output context: UNVERIFIED command output, not a file).
- `flutter test test/unit/models/task_model_test.dart`
- `flutter test test/unit/models/task_request_model_test.dart`
- `flutter test test/unit/features/orders/orders_view_model_test.dart` (after adding tests)
- `flutter test test/widget/features/orders/orders_dashboard_screen_test.dart` (after adding tests)
- `flutter test test/widget/features/orders/offer_list_sheet_test.dart` (after adding tests)
- `rg -n "Error deleting task: \$e|replaceAll\('Exception: ', ''\)" lib/features/orders` (verify raw error leakage removed) (Current evidence: `lib/features/orders/view/orders_dashboard_screen.dart:292-294`, `lib/features/orders/view/orders_dashboard_screen.dart:321-322`).
- `rg -n "status: TaskStatus\.open\)|in_progress" test/unit/models/task_model_test.dart lib/features/tasks/models/task_model.dart lib/features/tasks/services/task_service.dart` (verify parser + tests cover snake_case mapping) (Current evidence: `lib/features/tasks/models/task_model.dart:135-138`, `lib/features/tasks/services/task_service.dart:505-512`, `test/unit/models/task_model_test.dart:60-67`).
- `rg -n "OrdersDashboardScreen" lib` (verify intended wiring and no accidental orphaning) (Current evidence: `lib/app/main_navigation_screen.dart:10-12`, `lib/app/main_navigation_screen.dart:38-49`, `lib/features/orders/view/orders_dashboard_screen.dart:19-26`).
- `rg -n "closeTask\(" lib` (confirm whether `OrdersService.closeTask()` is actually unused before deletion) (Candidate evidence: `lib/features/orders/services/orders_service.dart:55-58`).

### Manual Scenarios
- Entry-point reachability check
- Tap the `NavView.orders` bottom-nav item and confirm the app opens the intended feature screen (`OrdersDashboardScreen`) or a documented replacement, not an unintended dashboard (Current mismatch evidence: `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`, `lib/app/main_navigation_screen.dart:38-49`).
- Orders load success/failure distinction
- With a valid session and tasks present, open the orders feature and confirm list rendering.
- Expire the session or simulate an RLS denial, reopen the feature, and confirm a friendly error state appears instead of the empty-state message (Current empty-state branch: `lib/features/orders/view/orders_dashboard_screen.dart:151-155`, `lib/features/orders/view/orders_dashboard_screen.dart:187-220`; current error swallowing: `lib/features/orders/viewmodels/orders_view_model.dart:47-58`).
- Task status parsing regression
- Use a task row with DB status `in_progress` and confirm it appears under the `In Progress` tab with correct actions (Current parser risk: `lib/features/tasks/models/task_model.dart:135-138`, `lib/features/tasks/services/task_service.dart:505-512`, `lib/features/orders/viewmodels/orders_view_model.dart:27-34`).
- Offer action robustness
- Open `OfferListSheet`, rapidly tap `Accept`/`Reject`, and confirm single in-flight execution with user-visible error feedback on failure (Current risk: `lib/features/orders/view/widgets/offer_list_sheet.dart:254-261`, `lib/features/orders/view/widgets/offer_list_sheet.dart:276-280`).
- Error-message leakage check
- Force delete or chat action failures and confirm no raw exception/DB text is displayed in snackbars (Current leakage: `lib/features/orders/view/orders_dashboard_screen.dart:292-294`, `lib/features/orders/view/orders_dashboard_screen.dart:321-322`).

### Supabase/RLS Contract Checks
- RLS is the source of truth: verify actual `tasks` and `task_requests` policies and RPC bodies against runtime behavior; docs alone are insufficient (File References for docs summary only: `Sline_everything/SUPABASE_SETUP.md:1010-1040`, `Sline_everything/SUPABASE_SETUP.md:1386-1444`, `Sline_everything/DEVELOPER_GUIDE/Task Feature.md:60-67`).
- Required policy/function checks (staging/prod SQL metadata):
- Confirm `tasks` delete is owner-only and aligned with the actual owner column used by the deployed schema (`user_id` vs `client_id` naming drift is UNVERIFIED across docs) (File References: `lib/features/tasks/services/task_service.dart:279-283`, `lib/features/tasks/services/task_service.dart:369-374`, `Sline_everything/DEVELOPER_GUIDE/Task Feature.md:23-24`, `Sline_everything/SUPABASE_SETUP.md:1018-1029`).
- Confirm `task_requests` select policy allows task owners to view offers and bidders to view own offers (File References: `lib/features/tasks/services/task_requests_service.dart:47-60`, `Sline_everything/SUPABASE_SETUP.md:1031-1040`).
- Confirm `accept_task_request(p_request_id)` validates task ownership and updates task/offer state atomically as documented (File References: `lib/features/tasks/services/task_requests_service.dart:225-246`, `Sline_everything/SUPABASE_SETUP.md:1386-1408`).
- Confirm `reject_task_request(p_request_id)` enforces owner authorization and expected state transition rules (File References: `lib/features/tasks/services/task_requests_service.dart:272-293`, `Sline_everything/SUPABASE_SETUP.md:1434-1440`).
- Validation method (run against DB metadata; UNVERIFIED in repo-only audit): inspect `pg_proc` definitions for `accept_task_request`/`reject_task_request`, query `pg_policies` for `tasks` and `task_requests`, and run owner/non-owner mutation tests with authenticated user tokens. Missing verification files: exported SQL/schema snapshots for the current deployed environment.

## 9) Risks & Rollback Notes
- Reachability fix risk: changing the `NavView.orders` screen mapping may alter user navigation expectations if `DashboardScreen` is intentionally assigned to that tab (UNVERIFIED product intent) (File References: `lib/app/main_navigation_screen.dart:38-49`, `lib/core/widgets/custom_bottom_nav_bar.dart:55-61`). Rollback steps: revert the screen-array slot and nav label changes in `lib/app/main_navigation_screen.dart` and `lib/core/widgets/custom_bottom_nav_bar.dart`.
- Status parser fix risk: changing `Task.fromJson` status parsing affects all features consuming `Task` models, not only `orders` (File References: `lib/features/tasks/models/task_model.dart:108-166`, `lib/features/orders/viewmodels/orders_view_model.dart:23-44`). Rollback steps: revert parser/codec changes and restore prior mapping while retaining added regression tests as failing evidence.
- Offer status parser hardening risk: introducing non-actionable unknown statuses can change UI rendering in other task-request consumers (File References: `lib/features/tasks/models/task_request_model.dart:46-93`, `lib/features/orders/view/widgets/offer_list_sheet.dart:249-320`). Rollback steps: revert parser changes only; keep UI guard code and tests to isolate behavior.
- Query projection tightening risk: removing `*` from `listByTask()` can break parsing if omitted columns are still implicitly required by `TaskRequest.fromMap` (File References: `lib/features/tasks/services/task_requests_service.dart:46-64`, `lib/features/tasks/models/task_request_model.dart:46-93`). Rollback steps: restore previous projection and add explicit field-by-field parser tests before retrying.
- Service de-dup/refactor risk: consolidating RPC parsing or removing legacy `TaskService.acceptOffer/rejectOffer` can break non-orders flows if hidden call sites exist (File References: `lib/features/tasks/services/task_service.dart:591-630`, `lib/features/tasks/services/task_requests_service.dart:225-318`). Rollback steps: first convert legacy methods to thin delegators, ship, then remove after verified repo search and tests.
- RLS contract validation risk: live DB policies/functions may diverge from docs and require backend changes that impact existing clients (UNVERIFIED until metadata inspection) (File References: `Sline_everything/SUPABASE_SETUP.md:1010-1040`, `Sline_everything/SUPABASE_SETUP.md:1386-1444`). Rollback steps: apply SQL changes in versioned migrations with explicit rollback scripts and validate owner/non-owner scenarios before release.
