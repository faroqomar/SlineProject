# booking — PHASE 1 Full Audit + Fix Plan

## Overview (what feature does, boundaries, dependencies)

- Feature purpose:
  - Provider availability slot management (`availability_slots`)
  - Client booking requests / lifecycle (`bookings`)
  - Booking detail actions (accept/decline/deliver/approve/release)
  - Booking discovery UI (task-list based “booking” browsing)
- Feature boundary audited:
  - `lib/features/booking/**`
- Direct dependencies audited (only those directly touched by `booking`):
  - `lib/features/notifications/services/notification_service.dart`
  - `lib/features/notifications/models/notification_model.dart`
  - `lib/features/chat/data/chat_repository.dart`
  - `lib/features/chat/services/message_service.dart` (for `startConversationByClient` path)
  - `lib/features/management/view/order_management_panel.dart`
  - `lib/features/management/viewmodels/order_management_view_model.dart`
  - `lib/features/management/services/work_log_service.dart`
  - `lib/core/app_enums.dart`
  - `lib/core/services/payment_service.dart`
  - `lib/core/services/demo_payment_service.dart`
  - `lib/core/services/logger_service.dart`
  - `lib/core/utils/error_mapper.dart`
  - `lib/core/widgets/signed_image.dart`
  - `lib/core/widgets/signed_avatar.dart`
  - Documentation references: `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/DEVELOPER_GUIDE/Booking Feature.md`
- Architecture trace (observed):
  - `View` -> `BookingViewModel` -> `BookingRepository` -> `BookingService` -> Supabase (`bookings`, `availability_slots`, RPC `process_payment_event`)
  - Additional side effects in service/ViewModel:
    - `BookingService` -> `NotificationService`
    - `BookingViewModel` -> `ChatRepository`
    - `BookingViewModel` -> `PaymentService` (default `DemoPaymentService`)
- Static analysis evidence:
  - `flutter analyze` (scoped to booking + direct deps): `No issues found!`
  - `dart format --output=none --set-exit-if-changed lib/features/booking`: `Formatted 13 files (0 changed)`
- Scope caveat (important):
  - No local migrations/SQL files were found in repo Phase 0; DB/RLS/RPC verification relies on docs and must be confirmed against live Supabase metadata (`pg_policies`, `pg_proc`, grants).

## Findings

### Security (highest priority)

- [Critical] Test-only booking bypass is active in production UI path and can skip escrow flow.
  - `lib/features/booking/view/booking_sheet.dart:85` and `lib/features/booking/view/booking_sheet.dart:87` set `txnId = 'TEST_SKIPPED_PAYMENT'`.
  - `lib/features/booking/view/booking_sheet.dart:119` to `lib/features/booking/view/booking_sheet.dart:121` forces `status: BookingStatus.active`.
  - `lib/features/booking/services/booking_service.dart:117` to `lib/features/booking/services/booking_service.dart:126` skips `process_payment_event` when status is `active`.
  - Impact:
    - If DB allows client insert with `status='active'`, booking can bypass escrow and move directly to active work.
    - If DB rejects it, user hits a broken path masked as “booking request”.
  - RLS/RPC alignment note:
    - Docs define payment-first flow (`pending -> paid_request_pending -> active`) in `Sline_everything/SUPABASE_SETUP.md:202` to `Sline_everything/SUPABASE_SETUP.md:217`.

- [High] Client-controlled booking insert writes authorization-sensitive fields (`provider_id`, `price`, `status`) instead of using a server-derived creation RPC.
  - `lib/features/booking/services/booking_service.dart:97` to `lib/features/booking/services/booking_service.dart:110`
  - The insert payload trusts caller-supplied:
    - `provider_id`
    - `status`
    - `price`
    - `slot_id`
  - Impact:
    - Client can attempt provider/task/slot mismatch records or tamper price/status.
    - Security depends entirely on undocumented constraints/triggers beyond the visible client code.
  - Docs gap:
    - RLS docs explicitly show `bookings_insert_client` only as `client_id = uid` (`Sline_everything/SUPABASE_SETUP.md:856`), which is not sufficient by itself to protect provider/price integrity.

- [High] Client-side notification creation for other users is a spoofing/failure hotspot and currently not verified against documented `notifications` policies.
  - `lib/features/booking/services/booking_service.dart:137` to `lib/features/booking/services/booking_service.dart:145`
  - `lib/features/booking/services/booking_service.dart:247` to `lib/features/booking/services/booking_service.dart:254`
  - `lib/features/notifications/services/notification_service.dart:69` to `lib/features/notifications/services/notification_service.dart:94`
  - Impact:
    - If `notifications` INSERT policy allows arbitrary `user_id`, clients may spoof notifications to other users.
    - If policy blocks cross-user insert, booking side effects silently fail because errors are swallowed.
  - Docs note:
    - `notifications` table is documented (`Sline_everything/SUPABASE_SETUP.md:603` to `Sline_everything/SUPABASE_SETUP.md:619`), but a policy summary for notifications was not found in the scanned policy sections.

- [Medium] Booking feature exposes raw backend error strings to UI instead of using central `ErrorMapper`.
  - Raw passthrough in `lib/features/booking/viewmodels/booking_view_model.dart:72`, `lib/features/booking/viewmodels/booking_view_model.dart:76`, `lib/features/booking/viewmodels/booking_view_model.dart:79`
  - Raw exception UI surfaces:
    - `lib/features/booking/view/add_slot_sheet.dart:108`
    - `lib/features/booking/view/booking_sheet.dart:141`
    - `lib/features/booking/view/availability_screen.dart:140`
    - `lib/features/booking/view/bookings_list_screen.dart:115`
  - Impact:
    - RLS/DB trigger messages may leak internal details (table/policy/trigger names).
    - Session-expiry UX will be inconsistent vs shared mapper behavior in `lib/core/utils/error_mapper.dart:61` to `lib/core/utils/error_mapper.dart:63`.

- [Medium] Direct client calls to `process_payment_event` rely on `SECURITY DEFINER` RPC auth checks that are not verifiable from repo code.
  - Client call sites:
    - `lib/features/booking/services/booking_service.dart:118` to `lib/features/booking/services/booking_service.dart:125`
    - `lib/features/booking/services/booking_service.dart:273` to `lib/features/booking/services/booking_service.dart:293`
  - Docs references:
    - `Sline_everything/SUPABASE_SETUP.md:1186` to `Sline_everything/SUPABASE_SETUP.md:1193`
    - `Sline_everything/SUPABASE_SETUP.md:1513`
  - Action:
    - Must verify live function body checks `auth.uid()`, participant ownership, legal transitions, and amount derivation server-side.

- [Info] No service-role key usage found in audited booking scope.
  - Scoped grep found no `service_role`/`SUPABASE_SERVICE_ROLE` in `lib/features/booking/**`.

### Data Integrity

- [Critical] Duplicate status mutations after RPC/service actions can create invalid transitions, duplicate notifications, and false failures.
  - `lib/features/booking/viewmodels/booking_view_model.dart:240` to `lib/features/booking/viewmodels/booking_view_model.dart:247` (`approveBooking`)
  - `lib/features/booking/viewmodels/booking_view_model.dart:268` to `lib/features/booking/viewmodels/booking_view_model.dart:275` (`declineBooking`)
  - `lib/features/booking/viewmodels/booking_view_model.dart:283` to `lib/features/booking/viewmodels/booking_view_model.dart:290` (`markDelivered`)
  - Service-level status update already happens via:
    - `lib/features/booking/services/booking_service.dart:295` to `lib/features/booking/services/booking_service.dart:300` (`markDelivered`)
    - `lib/features/booking/services/booking_service.dart:219` to `lib/features/booking/services/booking_service.dart:259` (`updateBookingStatus`, includes notification)
  - Impact:
    - Double-update may fail on second write if trigger disallows no-op/repeat transition.
    - Duplicate cross-user notifications can be emitted.
    - UI may show failure after server action actually succeeded.

- [Critical] Hardcoded fallback price (`100.0`) can write wrong booking price / escrow amount.
  - `lib/features/booking/viewmodels/booking_view_model.dart:201` to `lib/features/booking/viewmodels/booking_view_model.dart:203`
  - `lib/features/booking/view/booking_sheet.dart:114` to `lib/features/booking/view/booking_sheet.dart:121` does not pass actual price.
  - Insert uses the value directly in `lib/features/booking/services/booking_service.dart:107`.
  - Impact:
    - Financial records can be incorrect.
    - Escrow/release/refund amounts may not match displayed package/task pricing.

- [High] Booking lifecycle is internally inconsistent (legacy `confirmed` flow mixed with newer `paid_request_pending` / `active` / `delivered` flow).
  - Legacy pending actions:
    - `lib/features/booking/view/booking_details_screen.dart:177` to `lib/features/booking/view/booking_details_screen.dart:203` (provider confirm/reject)
    - `lib/features/booking/view/booking_details_screen.dart:205` to `lib/features/booking/view/booking_details_screen.dart:211` (client cancel)
  - New payment-flow actions:
    - `lib/features/booking/view/booking_details_screen.dart:215` to `lib/features/booking/view/booking_details_screen.dart:264`
  - Filter still emphasizes legacy statuses:
    - `lib/features/booking/view/bookings_list_screen.dart:193` to `lib/features/booking/view/bookings_list_screen.dart:212`
  - DB flow docs:
    - `Sline_everything/SUPABASE_SETUP.md:202` to `Sline_everything/SUPABASE_SETUP.md:217`
  - Impact:
    - UI can drive transitions that bypass newer payment/review semantics.
    - Users may not see expected statuses in filters.

- [High] `bookSlot()` can produce impossible state combinations if client inserts `active` and escrow RPC is skipped.
  - `lib/features/booking/services/booking_service.dart:105` to `lib/features/booking/services/booking_service.dart:106` sets `payment_status: 'unpaid'`
  - `lib/features/booking/services/booking_service.dart:117` to `lib/features/booking/services/booking_service.dart:126` skips escrow for `active`
  - Impact:
    - `status='active'` with `payment_status='unpaid'` violates pay-first assumptions.

- [Medium] `BookingModel.slotId` fabricates a zero UUID when `slot_id` is null (schema allows null).
  - `lib/features/booking/models/booking_model.dart:48` to `lib/features/booking/models/booking_model.dart:51`
  - Schema docs show nullable `slot_id`: `Sline_everything/SUPABASE_SETUP.md:479`
  - Impact:
    - Null semantics are lost.
    - Fake UUID can leak into downstream UI/actions and produce invalid requests.

- [Medium] `BookingModel.completedAt` parses `completed_at`, but docs show `delivered_at`/`review_expires_at` and no `completed_at` column.
  - `lib/features/booking/models/booking_model.dart:65` to `lib/features/booking/models/booking_model.dart:67`
  - Docs: `Sline_everything/SUPABASE_SETUP.md:486` to `Sline_everything/SUPABASE_SETUP.md:491`
  - Impact:
    - Contract drift risk (field always null or runtime parse mismatch if schema changed differently).

- [Medium] `markDelivered` uses direct status update and may skip delivery timestamps/review timer fields unless DB trigger fills them.
  - `lib/features/booking/services/booking_service.dart:295` to `lib/features/booking/services/booking_service.dart:300`
  - Booking schema includes delivery/review timing fields:
    - `Sline_everything/SUPABASE_SETUP.md:486` to `Sline_everything/SUPABASE_SETUP.md:491`
  - Impact:
    - Review windows / auto-approval logic can break silently.

- [Medium] Provider/task/slot integrity is not validated client-side before insert (must be server-enforced).
  - `lib/features/booking/services/booking_service.dart:97` to `lib/features/booking/services/booking_service.dart:110`
  - Impact:
    - A tampered client can attempt mismatched `provider_id` with a valid `slot_id`.
  - Required backend verification:
    - Trigger/check or RPC must derive provider from slot and verify task ownership/eligibility.

### Architecture

- Architecture Guard summary:
  - Status: partial fail
  - Passes:
    - No direct `Supabase.instance` or raw HTTP calls found in `lib/features/booking/view/**` (static grep returned no hits).
    - Service layer does not import UI files.
    - ViewModel does not take `BuildContext`.
  - Fails / drift:
    - UI embeds business/test payment logic and status mutation selection.
    - ViewModel mixes booking state, payment orchestration, chat orchestration, and error mapping in one class.
    - Service layer directly triggers cross-feature notifications (hidden side effect and cross-feature coupling).

- [High] `BookingSheet` contains business logic that should be in ViewModel/service (status override, fake payment transaction injection, note protocol formatting).
  - `lib/features/booking/view/booking_sheet.dart:85` to `lib/features/booking/view/booking_sheet.dart:121`
  - `lib/features/booking/view/booking_sheet.dart:90` to `lib/features/booking/view/booking_sheet.dart:113`

- [Medium] `BookingViewModel` is oversized and multi-responsibility (slots + bookings + payments + chat + error mapping).
  - `lib/features/booking/viewmodels/booking_view_model.dart:34` to `lib/features/booking/viewmodels/booking_view_model.dart:481` (481 LOC)
  - Coupling points:
    - Chat: `lib/features/booking/viewmodels/booking_view_model.dart:6` to `lib/features/booking/viewmodels/booking_view_model.dart:7`, `lib/features/booking/viewmodels/booking_view_model.dart:450` to `lib/features/booking/viewmodels/booking_view_model.dart:479`
    - Payment: `lib/features/booking/viewmodels/booking_view_model.dart:10` to `lib/features/booking/viewmodels/booking_view_model.dart:11`, `lib/features/booking/viewmodels/booking_view_model.dart:301` to `lib/features/booking/viewmodels/booking_view_model.dart:326`
    - Custom error mapping: `lib/features/booking/viewmodels/booking_view_model.dart:54` to `lib/features/booking/viewmodels/booking_view_model.dart:83`

- [Medium] `BookingService` triggers notifications directly (cross-feature side effects in persistence service).
  - `lib/features/booking/services/booking_service.dart:18`
  - `lib/features/booking/services/booking_service.dart:137` to `lib/features/booking/services/booking_service.dart:145`
  - `lib/features/booking/services/booking_service.dart:233` to `lib/features/booking/services/booking_service.dart:256`
  - Recommendation:
    - Move to application/use-case orchestration layer or server-side triggers/RPC.

- [Medium] `BookingsDiscoveryScreen` is functionally a task discovery wrapper and tightly couples booking feature to `home` + `tasks` features.
  - `lib/features/booking/view/bookings_discovery_screen.dart:8` to `lib/features/booking/view/bookings_discovery_screen.dart:11`
  - Uses `TaskCard`, `TaskDetailsScreen`, `HomeViewModel`, `TaskFilterViewModel` and no `BookingViewModel`.
  - Boundary clarity issue:
    - “Booking discovery” is currently a filtered task feed, not a booking-domain screen.

- [Info] No obvious cyclic import detected in audited scope.
  - Import scan shows cross-feature dependencies, but no direct cycle back into `booking`.

### Code Quality

- [Info] Analyzer and format checks passed, but runtime/business logic defects remain (static analysis is insufficient for this feature).

- [Medium] `getPendingRequests()` swallows all exceptions and returns empty list, hiding RLS/policy/schema breakages.
  - `lib/features/booking/services/booking_service.dart:200` to `lib/features/booking/services/booking_service.dart:216`
  - Reverse dependency:
    - `lib/features/dashboard/viewmodels/dashboard_view_model.dart:513` consumes this for inbox requests.
  - Impact:
    - Dashboard can silently show “no requests” instead of surfacing a real backend failure.

- [Low] Unused parameter in chat integration method (`currentUserId`) suggests stale/refactored logic.
  - `lib/features/booking/viewmodels/booking_view_model.dart:450` to `lib/features/booking/viewmodels/booking_view_model.dart:453`

- [Low] Unused ViewModel field `slotsRange`.
  - `lib/features/booking/viewmodels/booking_view_model.dart:100`

- [Low] Production comments indicate leftover test/prototype code in booking paths.
  - `lib/features/booking/view/booking_sheet.dart:7` to `lib/features/booking/view/booking_sheet.dart:10`
  - `lib/features/booking/view/booking_sheet.dart:119`
  - `lib/features/booking/viewmodels/booking_view_model.dart:203`
  - `lib/features/booking/viewmodels/booking_view_model.dart:246`, `lib/features/booking/viewmodels/booking_view_model.dart:274`

- [Medium] Repeated query shape and status UI mapping increase drift risk.
  - Repeated booking select string:
    - `lib/features/booking/services/booking_service.dart:159`
    - `lib/features/booking/services/booking_service.dart:182`
    - `lib/features/booking/services/booking_service.dart:203`
  - Repeated status presentation switch blocks:
    - `lib/features/booking/view/widgets/booking_card.dart:141` to `lib/features/booking/view/widgets/booking_card.dart:211`
    - `lib/features/booking/view/booking_details_screen.dart:309` to `lib/features/booking/view/booking_details_screen.dart:386`

- [Medium] `BookingCard` displays task budget instead of booking price.
  - Reads budget from joined task payload:
    - `lib/features/booking/view/widgets/booking_card.dart:33` to `lib/features/booking/view/widgets/booking_card.dart:35`
  - Displays `budget`:
    - `lib/features/booking/view/widgets/booking_card.dart:118` to `lib/features/booking/view/widgets/booking_card.dart:125`
  - Ignores `booking.price` entirely.
  - Impact:
    - UI may show wrong amount for package-based bookings and escrow records.

- [Low] `PaymentMethodScreen` appears unreferenced in app code (candidate dead/experimental screen).
  - Search hit only in its own declaration:
    - `lib/features/booking/view/payment_method_screen.dart:16`

### Performance

- [High] Availability list loads oldest slots first with no default “from now” filter; future slots can be buried behind old history.
  - `lib/features/booking/view/availability_screen.dart:49` to `lib/features/booking/view/availability_screen.dart:50` calls `loadSlots(providerId)` without date bounds.
  - `lib/features/booking/services/booking_service.dart:44` orders `starts_at ASC` and `limit(limit)`.
  - Impact:
    - For providers with many past slots, page 1 may be mostly irrelevant past slots.
    - Users must page extensively to reach upcoming availability.

- [Medium] `BookingsListScreen` eagerly loads both tabs on first render and shares one loading/error state across both datasets.
  - Concurrent loads:
    - `lib/features/booking/view/bookings_list_screen.dart:24` to `lib/features/booking/view/bookings_list_screen.dart:28`
  - Shared flags:
    - `lib/features/booking/viewmodels/booking_view_model.dart:92` to `lib/features/booking/viewmodels/booking_view_model.dart:97`
    - `lib/features/booking/viewmodels/booking_view_model.dart:328` to `lib/features/booking/viewmodels/booking_view_model.dart:424`
  - Impact:
    - Extra startup queries even if user never opens second tab.
    - Racey loading/error UI between tabs.

- [Medium] Global `BookingViewModel` + coarse `context.watch<BookingViewModel>()` causes unrelated rebuilds.
  - Watchers:
    - `lib/features/booking/view/availability_screen.dart:76`
    - `lib/features/booking/view/bookings_list_screen.dart:33`
    - `lib/features/booking/view/payment_method_screen.dart:62`
  - `contactProvider()` toggles `bookingsLoading` for chat initiation:
    - `lib/features/booking/viewmodels/booking_view_model.dart:455` to `lib/features/booking/viewmodels/booking_view_model.dart:479`
  - Impact:
    - Chat action can flip booking-list loading UI on other mounted screens.

- [Low] Payloads are broader than needed (`select()` / `tasks(*)`), increasing transfer and parsing cost.
  - `lib/features/booking/services/booking_service.dart:29` to `lib/features/booking/services/booking_service.dart:31`
  - `lib/features/booking/services/booking_service.dart:159`
  - `lib/features/booking/services/booking_service.dart:182`
  - `lib/features/booking/services/booking_service.dart:203`

- [Low] Timestamp-only cursor pagination can miss/duplicate rows when multiple rows share identical `created_at`/`starts_at`.
  - `lib/features/booking/services/booking_service.dart:41`, `lib/features/booking/services/booking_service.dart:163`, `lib/features/booking/services/booking_service.dart:186`
  - Impact:
    - Rare but real pagination edge-case under concurrent inserts.

### Testing gaps

- No booking-focused tests were found in `test/**` (search returned no booking feature tests).

- Missing critical unit tests:
  - Status mapping consistency (`BookingModel.fromJson`, `BookingService._mapStatusToDb`)
  - Booking action sequencing (no duplicate status updates after RPC)
  - Error mapping (RLS `42501`, unique violation `23505`, overlap message)
  - Price derivation (no hardcoded fallback)

- Missing critical widget tests:
  - `BookingSheet` submit flow (blocked slot, package flow, error states)
  - `AddSlotSheet` start/end validation including midnight edge
  - `BookingsListScreen` tab-specific loading/error states
  - `BookingDetailsScreen` action visibility by role + status

- Missing integration tests / backend contract tests:
  - Client booking request -> escrow RPC -> `paid_request_pending`
  - Provider accept -> `active`, contract activation snapshot
  - Provider decline -> `refunded`, no duplicate notification
  - Provider deliver -> timestamps/review window populated
  - Client approve/release -> `completed`, wallet ledger entries
  - RLS denial for non-participant booking read/update
  - Notification creation policy behavior (allowed/blocked) and fallback logging

## Dead/Unused code candidates (with file paths)

- `lib/features/booking/view/payment_method_screen.dart`
  - Candidate unused screen (search found declaration only, no construction references).
  - Confirm before delete if launched dynamically from currently unscanned runtime config/deep link.

- `lib/features/booking/viewmodels/booking_view_model.dart:100`
  - `DateTimeRange? slotsRange;` appears unused.

- `lib/features/booking/viewmodels/booking_view_model.dart:450`
  - `currentUserId` parameter in `contactProvider(...)` appears unused.

- `lib/features/booking/models/booking_model.dart:72`
  - `BookingModel.toJson()` appears unused in repo scan (candidate keep/remove depending planned caching/offline work).

- `lib/features/booking/models/slot_model.dart:32`
  - `SlotModel.toJson()` appears unused in repo scan (candidate).

- `lib/features/booking/models/slot_model.dart:44`
  - `SlotModel.copyWith()` appears unused in repo scan (candidate).

- `lib/features/booking/view/booking_sheet.dart:67` to `lib/features/booking/view/booking_sheet.dart:83`
  - Large commented-out payment logic block is dead/commented code (remove or restore behind feature flag).

## Duplicate code candidates (with file paths)

- Discovery feed screens are near-duplicates:
  - `lib/features/booking/view/bookings_discovery_screen.dart`
  - `lib/features/tasks/view/tenders_screen.dart`
  - Same structure with only header text/icons and `isTender` filter condition changed.

- Booking status presentation mapping duplicated:
  - `lib/features/booking/view/widgets/booking_card.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
  - Two separate switch blocks map `BookingStatus -> label/color`.

- Repeated booking list query shape in service:
  - `lib/features/booking/services/booking_service.dart:159`
  - `lib/features/booking/services/booking_service.dart:182`
  - `lib/features/booking/services/booking_service.dart:203`
  - Same select/join shape repeated across client/provider/pending requests.

- Repeated pagination load patterns in ViewModel:
  - `lib/features/booking/viewmodels/booking_view_model.dart:328` to `lib/features/booking/viewmodels/booking_view_model.dart:373`
  - `lib/features/booking/viewmodels/booking_view_model.dart:375` to `lib/features/booking/viewmodels/booking_view_model.dart:424`
  - Similar state transitions / cursor handling duplicated for client/provider lists.

## Refactor plan (exact file moves/splits)

- Security/correctness first note:
  - Do **not** do the large splits before Phase 1 fixes below. Remove test bypasses and duplicate status writes first.

- Split `lib/features/booking/viewmodels/booking_view_model.dart` into focused units (keep a thin facade initially to reduce blast radius):
  - `lib/features/booking/viewmodels/booking_view_model.dart` -> keep facade / provider registration compatibility
  - New: `lib/features/booking/viewmodels/booking_slots_state.dart`
  - New: `lib/features/booking/viewmodels/booking_lists_state.dart`
  - New: `lib/features/booking/viewmodels/booking_actions_state.dart`
  - New: `lib/features/booking/viewmodels/booking_chat_actions.dart`
  - New: `lib/features/booking/viewmodels/booking_error_mapper.dart` (or use `lib/core/utils/error_mapper.dart` and delete custom mapper)

- Split `lib/features/booking/services/booking_service.dart` by responsibility:
  - `lib/features/booking/services/booking_service.dart` -> facade (temporary)
  - New: `lib/features/booking/services/booking_query_service.dart`
  - New: `lib/features/booking/services/booking_command_service.dart`
  - New: `lib/features/booking/services/booking_status_codec.dart`
  - New: `lib/features/booking/services/booking_notification_dispatcher.dart` (or remove entirely if migrated server-side)

- Split `lib/features/booking/view/booking_details_screen.dart` (434 LOC):
  - New: `lib/features/booking/view/widgets/booking_details_status_banner.dart`
  - New: `lib/features/booking/view/widgets/booking_details_summary_section.dart`
  - New: `lib/features/booking/view/widgets/booking_counterparty_section.dart`
  - New: `lib/features/booking/view/widgets/booking_actions_section.dart`
  - Keep `lib/features/booking/view/booking_details_screen.dart` as page shell + navigation handlers

- Split `lib/features/booking/view/bookings_list_screen.dart`:
  - New: `lib/features/booking/view/widgets/bookings_list_tab.dart`
  - New: `lib/features/booking/view/widgets/booking_status_filter_bar.dart`
  - Keep `lib/features/booking/view/bookings_list_screen.dart` as tab scaffold

- Extract shared discovery feed shell to remove duplication with tenders:
  - `lib/features/booking/view/bookings_discovery_screen.dart` -> keep thin wrapper
  - `lib/features/tasks/view/tenders_screen.dart` -> keep thin wrapper
  - New shared widget: `lib/core/widgets/task_discovery_sliver_feed.dart`
    - Parameters: title, subtitle, empty icon/text, filter predicate, list label semantics

- Normalize booking status UI mapping into one source:
  - New: `lib/features/booking/view/widgets/booking_status_style.dart`
  - `lib/features/booking/view/widgets/booking_card.dart` -> consume shared mapper
  - `lib/features/booking/view/booking_details_screen.dart` -> consume shared mapper

- Payment screen organization (if retained after Phase 1):
  - `lib/features/booking/view/payment_method_screen.dart` -> `lib/features/booking/view/payments/payment_method_screen.dart`
  - If not retained, delete after verifying no runtime route/deep-link usage.

## Fix Plan (Phases)

### Phase 1: critical security & correctness

- Remove all test bypasses from booking request path (SCALPEL):
  - Delete `TEST_SKIPPED_PAYMENT` injection in `lib/features/booking/view/booking_sheet.dart`
  - Remove forced `BookingStatus.active` in `lib/features/booking/view/booking_sheet.dart`
  - Remove hardcoded `100.0` fallback in `lib/features/booking/viewmodels/booking_view_model.dart`
- Lock booking creation contract:
  - Make `BookingViewModel.bookSlot(...)` require explicit validated price (or no price if server derives it)
  - Make `BookingService.bookSlot(...)` stop accepting client-supplied `status` (set server-safe default only)
  - Prefer replacing insert + RPC sequence with a single server RPC (e.g., `create_booking_request(...)`) that derives provider/status/price and performs escrow atomically
- Remove duplicate status transitions:
  - `approveBooking`, `declineBooking`, `markDelivered` should not call `updateBookingStatus(...)` after an RPC/service path that already mutates status
  - Refresh booking via `getBookingById(...)` or list reload after action instead
- Stop raw backend error leakage:
  - Replace `_mapError()` in booking VM with `ErrorMapper.map(...)` or make booking mapper wrap core mapper
  - Replace `SnackBar(content: Text('Error: $e'))` with mapped user-safe message
- Notification side effect hardening:
  - Make notification failure explicit in logs (still non-blocking)
  - Verify notifications RLS policy; if cross-user insert is not allowed, move notification creation server-side (trigger/RPC)

### Phase 2: refactor/structure

- Split `BookingViewModel` into slots/lists/actions/chat responsibilities (keep facade adapter)
- Split `BookingService` into query/command components and centralize query strings/status mapping
- Extract shared `BookingStatus` presentation mapper to eliminate duplicated switch statements
- Extract shared task discovery sliver feed to de-duplicate `BookingsDiscoveryScreen` and `TendersScreen`
- Decouple booking service from notifications service:
  - move side effects to ViewModel/application layer or server triggers
- Introduce separate loading/error states:
  - `slotsLoading`
  - `bookingsAsClientLoading`, `bookingsAsProviderLoading`
  - `bookingActionLoading`
  - `chatActionLoading`
  - separate error channels for each

### Phase 3: tests

- Add unit tests:
  - `BookingModel` status parsing + nullable `slot_id`
  - booking status DB mapping codec
  - booking action methods avoid duplicate status writes
  - error mapping (`42501`, `23505`, overlap message)
- Add widget tests:
  - `BookingSheet` happy path + blocked slot + error UI
  - `AddSlotSheet` validation and midnight end-time edge-case
  - `BookingsListScreen` per-tab loading/error isolation
  - `BookingDetailsScreen` role/status action visibility matrix
- Add integration/contract tests (mock or test DB):
  - booking create -> escrow -> `paid_request_pending`
  - accept/decline/deliver/approve flows
  - RLS denial for non-participants
  - notification policy behavior (allowed vs denied)

### Phase 4: polish/perf

- Default availability query to future window (`fromUtc: now`) and optional “Show past slots”
- Lazy-load bookings tabs (load second tab on tab selection, not screen init)
- Replace coarse `watch<BookingViewModel>()` with selectors/value notifiers for local screen state slices
- Trim query payloads (`tasks(*)` -> explicit columns only)
- Improve pagination cursor stability (tie-breaker on `id` alongside timestamp)
- Refresh detail screen state after action instead of popping blindly; add action loading/disabled states and success/failure feedback

## Verification steps (commands + manual scenarios)

### Commands

- Static analysis (feature + direct deps audited here):
  - `flutter analyze lib/features/booking lib/features/notifications/services/notification_service.dart lib/features/notifications/models/notification_model.dart lib/features/chat/data/chat_repository.dart lib/features/chat/services/message_service.dart lib/features/management/view/order_management_panel.dart lib/features/management/viewmodels/order_management_view_model.dart lib/features/management/services/work_log_service.dart lib/core/app_enums.dart lib/core/services/payment_service.dart lib/core/services/demo_payment_service.dart lib/core/services/logger_service.dart lib/core/utils/error_mapper.dart lib/core/widgets/signed_image.dart lib/core/widgets/signed_avatar.dart`
- Formatting:
  - `dart format --output=none --set-exit-if-changed lib/features/booking`
- Booking security/correctness grep checks (post-fix):
  - `rg -n "TEST_SKIPPED_PAYMENT|Force ACTIVE status|Phase 1 simulation|Hardcoded default" lib/features/booking --glob '*.dart'`
  - `rg -n "status:\\s*BookingStatus\\.active" lib/features/booking/view/booking_sheet.dart`
  - `rg -n "price \\?\\? 100\\.0" lib/features/booking/viewmodels/booking_view_model.dart`
  - `rg -n "process_payment_event" lib/features/booking/services/booking_service.dart`
  - `rg -n "createNotification\\(" lib/features/booking/services/booking_service.dart`
- Architecture boundary checks:
  - `rg -n "Supabase\\.instance|SupabaseClient|http\\.|dio\\." lib/features/booking/view --glob '*.dart'`
  - `rg -n "^import .*features/.*/view/" lib/features/booking --glob '*.dart'`
- Targeted tests (after adding):
  - `flutter test test/features/booking`

### DB / RLS verification (manual SQL in Supabase SQL editor or psql)

- Verify `bookings` policies and effective rules:
  - `select schemaname, tablename, policyname, cmd, qual, with_check from pg_policies where tablename in ('bookings','availability_slots','notifications') order by tablename, policyname;`
- Verify `process_payment_event` security/auth contract:
  - `select p.proname, p.prosecdef, pg_get_functiondef(p.oid) from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname='public' and p.proname='process_payment_event';`
- Verify grants on `bookings` status columns / update restrictions:
  - `select grantee, table_name, privilege_type from information_schema.role_table_grants where table_name='bookings';`
  - (If column grants are used) `select grantee, table_name, column_name, privilege_type from information_schema.column_privileges where table_name='bookings';`
- Verify booking integrity constraints/triggers (provider-slot/task consistency, overlap guard, booking guard):
  - `select tgname, pg_get_triggerdef(oid) from pg_trigger where not tgisinternal and tgrelid = 'public.bookings'::regclass;`
  - `select tgname, pg_get_triggerdef(oid) from pg_trigger where not tgisinternal and tgrelid = 'public.availability_slots'::regclass;`

### Manual scenarios (post-fix)

- Booking request path:
  - Client books an open slot with a paid package -> booking is created with expected price, escrow event executed, status becomes `paid_request_pending` (or the server-defined initial paid state), not `active`.
- Tamper resistance:
  - Attempt client-side status override (`active`) during booking request (via debug/devtools/mock) -> server rejects or ignores and enforces server-derived state.
- Price integrity:
  - Create booking with package price X -> stored `bookings.price` and wallet ledger amounts match X exactly.
- Provider actions:
  - Provider accepts `paid_request_pending` booking -> status `active`, work contract snapshot trigger behavior validated.
  - Provider declines `paid_request_pending` booking -> status `refunded`, no duplicate notification rows.
- Delivery/review:
  - Provider marks delivered -> `delivered_at` and review window fields populated (if schema expects them).
  - Client approves release -> status `completed`, wallet release ledger row inserted once.
- Notifications:
  - Booking create/status change emits notification to counterparty only; verify no insert spoofing path for arbitrary users.
- RLS authorization:
  - Third user cannot read/update another user’s booking (read returns none / update denied).
- Availability UX:
  - Provider with >50 historical slots still sees upcoming slots quickly (default future filtering works).
- Edge case:
  - Add slot when start time is 23:xx local; end picker does not crash/assert.
- UI correctness:
  - Booking list filters include current active statuses and show expected items.

## Risks & rollback notes

- Risk: lifecycle changes affect dependent inbox/dashboard behavior.
  - `lib/features/dashboard/viewmodels/dashboard_view_model.dart:513` depends on `BookingService.getPendingRequests()`.
  - Rollback:
    - Keep existing method signature and return shape during refactor.
    - Introduce stricter error logging first, then UI handling.

- Risk: status transition fixes may conflict with undocumented DB triggers/RPC side effects.
  - Docs show booking guard + contract activation triggers:
    - `Sline_everything/SUPABASE_SETUP.md:950`
    - `Sline_everything/SUPABASE_SETUP.md:964`
  - Rollback:
    - Ship Phase 1 as small commits (remove test bypass, remove duplicate status write, error mapping) separately.
    - Feature-flag any new server RPC path before removing legacy insert path.

- Risk: notification side-effect relocation can temporarily reduce user notifications.
  - Rollback:
    - Keep current client notification path behind logging wrapper while server-side trigger/RPC path is validated.
    - Monitor notification insert failures after release.

- Risk: data cleanup may be required for existing inconsistent rows (`active` + `unpaid`, wrong `price`, duplicated status actions).
  - Rollback/data remediation:
    - Snapshot affected booking rows before migration/fix rollout.
    - Prepare SQL remediation scripts for status/payment correction (idempotent, audited).

- Documentation drift risk:
  - `Sline_everything/DEVELOPER_GUIDE/Booking Feature.md` is partially outdated vs current code and `SUPABASE_SETUP` (notably lifecycle/status flow).
  - Rollback:
    - Treat docs as hints only until live DB metadata is verified; do not hard-code assumptions from docs alone.
