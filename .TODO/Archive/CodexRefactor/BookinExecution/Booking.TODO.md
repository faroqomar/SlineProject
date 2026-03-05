# Booking — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - Slot discovery/listing and provider slot creation UI via `AvailabilityScreen` and `AddSlotSheet`. File Reference: `lib/features/booking/view/availability_screen.dart:12-39`, `lib/features/booking/view/add_slot_sheet.dart:6-14`, `lib/features/booking/view/add_slot_sheet.dart:74-110`
  - Booking request capture via `BookingSheet`, then payment checkout via `PaymentCheckoutScreen`. File Reference: `lib/features/booking/view/booking_sheet.dart:19-46`, `lib/features/booking/view/booking_sheet.dart:66-104`, `lib/features/booking/view/availability_screen.dart:248-297`
  - Payment WebView callback handling via `PaymentWebViewScreen`. File Reference: `lib/features/booking/view/payment_webview_screen.dart:17-24`, `lib/features/booking/view/payment_webview_screen.dart:76-150`
  - Booking list/details/status actions via `BookingsListScreen` and `BookingDetailsScreen`. File Reference: `lib/features/booking/view/bookings_list_screen.dart:10-18`, `lib/features/booking/view/bookings_list_screen.dart:21-29`, `lib/features/booking/view/booking_details_screen.dart:20-27`, `lib/features/booking/view/booking_details_screen.dart:212-340`
  - Supabase-backed booking/slot persistence and side effects via `BookingService` -> `BookingRepository` -> `BookingViewModel`. File Reference: `lib/features/booking/services/booking_service.dart:10-21`, `lib/features/booking/data/booking_repository.dart:7-18`, `lib/features/booking/viewmodels/booking_view_model.dart:34-46`
- Boundaries (in scope): `lib/features/booking/**` plus direct dependencies invoked/imported by booking flows. File Reference: `lib/features/booking/services/booking_service.dart:6-8`, `lib/features/booking/viewmodels/booking_view_model.dart:36-45`, `lib/main.dart:145-151`
- Boundaries (out of scope): internals of transitive dependencies (for example `MessageService` behind `ChatRepository`) except where required to identify touchpoints; those are marked UNVERIFIED when not directly audited. File Reference: `lib/features/chat/data/chat_repository.dart:9-15`, `lib/features/chat/data/chat_repository.dart:36-47`
- Entry points (screens/routes/calls):
  - Global route `/availability` -> `AvailabilityScreen`. File Reference: `lib/main.dart:238-259`
  - `AvailabilityScreen` -> `BookingSheet` -> `PaymentCheckoutScreen`. File Reference: `lib/features/booking/view/availability_screen.dart:254-290`
  - `PaymentCheckoutScreen` -> `PaymentWebViewScreen`. File Reference: `lib/features/booking/view/payment_checkout_screen.dart:189-195`
  - `BookingsListScreen` -> `BookingDetailsScreen`. File Reference: `lib/features/booking/view/bookings_list_screen.dart:156-169`
  - `BookingDetailsScreen` -> `ChatScreen` through `BookingViewModel.contactProvider()` + `ChatRepository.startConversationByClient()`. File Reference: `lib/features/booking/view/booking_details_screen.dart:469-488`, `lib/features/booking/viewmodels/booking_view_model.dart:650-680`, `lib/features/chat/data/chat_repository.dart:36-47`

## 1) Feature Map (Current Repo State)
- Primary feature files (with references)
  - Service/data/viewmodel/models:
    - `lib/features/booking/services/booking_service.dart` (Supabase IO + notification/ledger side effects). File Reference: `lib/features/booking/services/booking_service.dart:10-21`, `lib/features/booking/services/booking_service.dart:84-136`, `lib/features/booking/services/booking_service.dart:235-344`
    - `lib/features/booking/data/booking_repository.dart` (pass-through repository wrapper). File Reference: `lib/features/booking/data/booking_repository.dart:7-18`, `lib/features/booking/data/booking_repository.dart:20-140`
    - `lib/features/booking/viewmodels/booking_view_model.dart` (slots/bookings/payment/chat orchestration). File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:34-46`, `lib/features/booking/viewmodels/booking_view_model.dart:243-298`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`, `lib/features/booking/viewmodels/booking_view_model.dart:650-680`
    - `lib/features/booking/models/booking_model.dart` / `slot_model.dart`. File Reference: `lib/features/booking/models/booking_model.dart:42-70`, `lib/features/booking/models/booking_model.dart:133-158`, `lib/features/booking/models/slot_model.dart:3-30`
  - UI screens/widgets (booking flow + lists/details):
    - `lib/features/booking/view/availability_screen.dart`, `booking_sheet.dart`, `payment_checkout_screen.dart`, `payment_webview_screen.dart`. File Reference: `lib/features/booking/view/availability_screen.dart:12-39`, `lib/features/booking/view/booking_sheet.dart:19-46`, `lib/features/booking/view/payment_checkout_screen.dart:21-45`, `lib/features/booking/view/payment_webview_screen.dart:17-24`
    - `lib/features/booking/view/bookings_list_screen.dart`, `booking_details_screen.dart`, `view/widgets/booking_card.dart`. File Reference: `lib/features/booking/view/bookings_list_screen.dart:10-18`, `lib/features/booking/view/booking_details_screen.dart:20-27`, `lib/features/booking/view/widgets/booking_card.dart:11-20`
    - Additional booking UI files: `add_slot_sheet.dart`, `bookings_discovery_screen.dart`, `payment_method_screen.dart` (legacy candidate). File Reference: `lib/features/booking/view/add_slot_sheet.dart:6-14`, `lib/features/booking/view/bookings_discovery_screen.dart:13-18`, `lib/features/booking/view/payment_method_screen.dart:11-21`
- Direct dependencies (with references)
  - Payment provider contract + implementations used by booking: `PaymentService`, `DemoPaymentService`, `QiCardPaymentService`. File Reference: `lib/core/services/payment_service.dart:90-118`, `lib/core/services/demo_payment_service.dart:43-67`, `lib/core/services/qicard_payment_service.dart:13-18`, `lib/core/services/qicard_payment_service.dart:20-48`
  - CTA helper used in booking details: `UnifiedCtaResolver`. File Reference: `lib/features/booking/view/booking_details_screen.dart:53-58`, `lib/core/utils/unified_cta_resolver.dart:3-12`
  - Wallet ledger RPC wrapper used by booking actions: `LedgerService`. File Reference: `lib/features/booking/services/booking_service.dart:287-344`, `lib/features/wallet/services/ledger_service.dart:21-57`
  - Notification writes used by booking service: `NotificationService`. File Reference: `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:249-271`, `lib/features/notifications/services/notification_service.dart:69-94`
  - Chat repository used for booking-detail contact action: `ChatRepository.startConversationByClient`. File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:650-680`, `lib/features/chat/data/chat_repository.dart:36-47`
  - App wiring (provider creation, route registration, payment service selection): `lib/main.dart`. File Reference: `lib/main.dart:46-59`, `lib/main.dart:122-181`, `lib/main.dart:238-259`
  - Edge function directly called by QiCard recovery path: `supabase/functions/qicard_webhook_handler/index.ts`. File Reference: `lib/core/services/qicard_payment_service.dart:323-355`, `supabase/functions/qicard_webhook_handler/index.ts:149-176`, `supabase/functions/qicard_webhook_handler/index.ts:190-258`
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs)
  - Tables used directly by booking service:
    - `availability_slots` and `bookings` tables. File Reference: `lib/features/booking/services/booking_service.dart:17-18`, `lib/features/booking/services/booking_service.dart:30-33`, `lib/features/booking/services/booking_service.dart:99-114`
    - Joined reads from `tasks` and `availability_slots(starts_at)` in booking lists. File Reference: `lib/features/booking/services/booking_service.dart:168-180`, `lib/features/booking/services/booking_service.dart:191-204`, `lib/features/booking/services/booking_service.dart:212-220`
    - `notifications` writes via `NotificationService`. File Reference: `lib/features/notifications/services/notification_service.dart:69-94`
  - RPCs:
    - `process_payment_event_ledger` called by app client (`LedgerService`). File Reference: `lib/features/wallet/services/ledger_service.dart:21-57`
    - `process_payment_event_ledger` called by QiCard webhook edge function (service role). File Reference: `supabase/functions/qicard_webhook_handler/index.ts:48-57`, `supabase/functions/qicard_webhook_handler/index.ts:234-242`
    - RPC grants in migrations (authenticated + service_role). File Reference: `supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql:4-42`, `supabase/migrations/20260225_create_ledger_rls_policies.sql:244-253`
    - RPC updates booking `payment_status='held'` for booking entities. File Reference: `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:246-251`
  - Edge functions:
    - `qicard_webhook_handler` endpoint referenced by client config and recovery call. File Reference: `lib/core/services/qicard_payment_service.dart:37-48`, `lib/core/services/qicard_payment_service.dart:332-355`
  - Realtime:
    - Direct dependency `NotificationService` exposes `notifications` stream API, but booking code path audited here calls `createNotification()` (not `streamNotifications()`). File Reference: `lib/features/notifications/services/notification_service.dart:25-35`, `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/booking/services/booking_service.dart:263-271`
    - Chat realtime/storage touchpoints are UNVERIFIED in this audit because `Booking` only calls `ChatRepository.startConversationByClient()` and underlying `MessageService` was out of scope. File Reference: `lib/features/chat/data/chat_repository.dart:36-47`
  - Storage buckets:
    - UNVERIFIED (no storage bucket touchpoint identified within audited booking files/direct dependencies above; verify transitive chat/message services separately). Missing files to audit for confirmation: `lib/features/chat/services/message_service.dart` and any booking-adjacent upload services.

## 2) Evidence Index (Ground Truth)
| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
|---|---|---|---|---|
| SEC-01 | QiCard client code contains hardcoded default terminal/username/password values and URLs via `String.fromEnvironment(... defaultValue: ...)`. | `lib/core/services/qicard_payment_service.dart:20-48` | Critical | Secrets/default creds in client source/builds are high-risk. |
| SEC-02 | QiCard config validation accepts `http` for notification and finish URLs. | `lib/core/services/qicard_payment_service.dart:98-121` | High | Error text says https, implementation allows http. |
| SEC-03 | Payment WebView success/failure detection uses path heuristics and accepts `http` without host allowlist. | `lib/features/booking/view/payment_webview_screen.dart:76-150`, `lib/features/booking/view/payment_webview_screen.dart:169-209` | High | Spoofable local success/failure signaling risk. |
| SEC-04 | Client recovery path posts synthetic `SUCCESS` payload to webhook handler without auth/signature header. | `lib/core/services/qicard_payment_service.dart:323-355` | High | Trust boundary depends on server verification. |
| SEC-05 | Edge function uses service-role client and only enforces signature when `QICARD_RSA_PUBLIC_KEY_PEM` is configured. | `supabase/functions/qicard_webhook_handler/index.ts:48-57`, `supabase/functions/qicard_webhook_handler/index.ts:63-88`, `supabase/functions/qicard_webhook_handler/index.ts:149-176` | High | Misconfiguration can permit unsigned client recovery payloads. |
| SEC-06 | Booking status updates and notifications are client-initiated writes; authorization depends on DB/RLS policy correctness. | `lib/features/booking/services/booking_service.dart:235-275`, `lib/features/notifications/services/notification_service.dart:69-94`, `Sline_everything/SUPABASE_SETUP.md:1073-1080` | High | Live `bookings`/`notifications` policy SQL in repo migrations is UNVERIFIED. |
| SEC-07 | `USE_QICARD_PAYMENT` defaults to `true`, enabling QiCard path unless explicitly disabled. | `lib/main.dart:46-59` | Medium | Safer to fail closed/demo by default during hardening. |
| DI-01 | `createBookingDraft()` inserts booking row then sends provider notification before payment completion. | `lib/features/booking/services/booking_service.dart:84-136`, `lib/features/booking/view/payment_checkout_screen.dart:143-178` | High | Failed/abandoned payments can produce false booking notifications. |
| DI-02 | `BookingViewModel.markDelivered()` calls repo mark + `updateBookingStatus()` (duplicate mutation path). | `lib/features/booking/viewmodels/booking_view_model.dart:399-412`, `lib/features/booking/services/booking_service.dart:339-344` | High | Duplicate writes/notifications possible. |
| DI-03 | Decline flow comment claims atomic RPC, but actual service flow is read -> update -> ledger RPC (non-atomic). | `lib/features/booking/viewmodels/booking_view_model.dart:381-397`, `lib/features/booking/services/booking_service.dart:316-337` | High | Race condition window + misleading maintenance comments. |
| DI-04 | `_paymentFlowInProgress` is immutable `false`, but dispose cleanup logic depends on it. | `lib/features/booking/view/payment_checkout_screen.dart:58-89` | Medium | Orphan draft cleanup behavior can diverge from intent. |
| DI-05 | `BookingModel.fromJson()` substitutes null `slot_id` with all-zero UUID and maps `in_progress` -> `active`. | `lib/features/booking/models/booking_model.dart:42-70`, `lib/features/booking/models/booking_model.dart:133-158` | Medium | Masks upstream data issues and semantic drift. |
| ARC-01 | `BookingViewModel` mixes slots, payment, bookings list state, and chat orchestration in one notifier. | `lib/features/booking/viewmodels/booking_view_model.dart:34-46`, `lib/features/booking/viewmodels/booking_view_model.dart:243-298`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`, `lib/features/booking/viewmodels/booking_view_model.dart:650-680` | Medium | Hard to test/change safely. |
| ARC-02 | `PaymentCheckoutScreen` holds business workflow orchestration in UI layer. | `lib/features/booking/view/payment_checkout_screen.dart:135-262` | Medium | MVVM drift; flow logic not isolated for tests. |
| ARC-03 | `BookingService` mixes persistence, notifications, and ledger side effects. | `lib/features/booking/services/booking_service.dart:84-136`, `lib/features/booking/services/booking_service.dart:235-275`, `lib/features/booking/services/booking_service.dart:287-344` | Medium | Coupling and transaction boundary ambiguity. |
| ARC-04 | `BookingRepository` is mostly pass-through over `BookingService`. | `lib/features/booking/data/booking_repository.dart:20-140` | Low | Extra indirection with limited abstraction value. |
| ARC-05 | `BookingDetailsScreen` duplicates CTA resolution and combines UI + action matrix + provider creation in build. | `lib/features/booking/view/booking_details_screen.dart:47-84`, `lib/features/booking/view/booking_details_screen.dart:199-209`, `lib/features/booking/view/booking_details_screen.dart:249-331`, `lib/features/booking/view/booking_details_screen.dart:390-467` | Medium | Logic duplication and rebuild-side instantiation risk. |
| CQ-01 | Comments/documentation in booking VM/checkout screen no longer match behavior. | `lib/features/booking/viewmodels/booking_view_model.dart:29-30`, `lib/features/booking/viewmodels/booking_view_model.dart:383-387`, `lib/features/booking/view/payment_checkout_screen.dart:14-20` | Low | Misleads future fixes. |
| CQ-02 | `BookingsDiscoveryScreen` uses `!isTender` heuristic to infer booking. | `lib/features/booking/view/bookings_discovery_screen.dart:23-30` | Low | Brittle type inference. |
| CQ-03 | `PaymentMethodScreen` still implements demo card flow with `USD`; likely legacy path. | `lib/features/booking/view/payment_method_screen.dart:11-21`, `lib/features/booking/view/payment_method_screen.dart:43-58`, `lib/features/booking/view/payment_method_screen.dart:49-53` | Low | No-callsite claim is UNVERIFIED unless repo search is re-run and reviewed. |
| CQ-04 | `PaymentCheckoutScreen.packagePrice` exists but is not used in screen logic. | `lib/features/booking/view/payment_checkout_screen.dart:32-45` | Low | Dead parameter/API noise. |
| PERF-01 | `BookingsListScreen` loads both client/provider tabs on init and refresh. | `lib/features/booking/view/bookings_list_screen.dart:21-29`, `lib/features/booking/view/bookings_list_screen.dart:42-46` | Medium | Extra queries and tab interference. |
| PERF-02 | Both tabs bind to shared `bookingsLoading` / `bookingsError` state. | `lib/features/booking/view/bookings_list_screen.dart:57-76`, `lib/features/booking/viewmodels/booking_view_model.dart:89-102`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619` | Medium | Flicker/rebuild scope + ambiguous errors. |
| PERF-03 | Booking list queries overfetch with `tasks(*)`. | `lib/features/booking/services/booking_service.dart:168-180`, `lib/features/booking/services/booking_service.dart:191-204`, `lib/features/booking/services/booking_service.dart:212-220` | Medium | Heavier payloads than list cards likely need. |
| PERF-04 | Payment confirmation polling loops every 3s for up to 60s, repeatedly calling `getBookingById()`. | `lib/features/booking/viewmodels/booking_view_model.dart:243-272`, `lib/features/booking/view/payment_checkout_screen.dart:99-133` | Low | Acceptable MVP, but needs UX/tests/telemetry. |
| TEST-01 | Existing tests cover some BookingViewModel and BookingModel behaviors only (unit level). | `test/unit/booking/booking_view_model_test.dart:57-303`, `test/unit/models/booking_model_test.dart:20-49` | Medium | Widget/integration coverage for checkout/webview/status flows is UNVERIFIED. |

## 3) Findings
### 3.1 Security (Highest Priority)
- `SEC-01` File Reference: `lib/core/services/qicard_payment_service.dart:20-48`
  - Impact: Client builds can contain usable default QiCard terminal credentials and callback URLs.
  - Exploit/Failure scenario: A build is shipped without secure `--dart-define` overrides; anyone extracting app code can recover credentials and abuse merchant/payment APIs.
- `SEC-02` File Reference: `lib/core/services/qicard_payment_service.dart:98-121`
  - Impact: Callback/finish URLs can be configured over `http`, weakening transport security guarantees.
  - Exploit/Failure scenario: A downgraded or intercepted callback URL is accepted by client-side validation and used in payment initiation.
- `SEC-03` File Reference: `lib/features/booking/view/payment_webview_screen.dart:76-150`, `lib/features/booking/view/payment_webview_screen.dart:169-209`
  - Impact: Local payment result can be spoofed by navigation to matching paths on an arbitrary host.
  - Exploit/Failure scenario: Malicious redirect (or captive portal/intermediate page) uses `/payment/success` path and triggers app-side `SUCCESS` handling.
- `SEC-04` File Reference: `lib/core/services/qicard_payment_service.dart:323-355`, `supabase/functions/qicard_webhook_handler/index.ts:149-176`, `supabase/functions/qicard_webhook_handler/index.ts:190-258`
  - Impact: Client sends a synthetic success event to the webhook endpoint without a signature header; server behavior depends on webhook signature enforcement configuration.
  - Exploit/Failure scenario: In an environment where `QICARD_RSA_PUBLIC_KEY_PEM` is unset/misconfigured, a client-originated `SUCCESS` payload may be accepted and forwarded to ledger RPC.
- `SEC-05` File Reference: `supabase/functions/qicard_webhook_handler/index.ts:48-57`, `supabase/functions/qicard_webhook_handler/index.ts:63-88`, `supabase/functions/qicard_webhook_handler/index.ts:149-176`
  - Impact: Service-role mutation path is present in the edge function and is protected by conditional signature validation rather than unconditional provider-origin verification.
  - Exploit/Failure scenario: Non-production or misconfigured deployments skip signature verification (`QICARD_RSA_PUBLIC_KEY_PEM` absent) and accept unsigned requests.
- `SEC-06` File Reference: `lib/features/booking/services/booking_service.dart:235-275`, `lib/features/notifications/services/notification_service.dart:69-94`, `Sline_everything/SUPABASE_SETUP.md:1073-1080`
  - Impact: Booking status and notification writes are initiated by the client; if RLS/policies are wrong, authz breaks.
  - Exploit/Failure scenario: A user updates another party's notification target or invalid booking transition if DB policy/column permissions are broader than intended.
  - UNVERIFIED: Actual deployed `bookings` and `notifications` RLS SQL definitions were not located in `supabase/migrations` during this audit. Missing files to verify: migration(s) containing `CREATE POLICY ... ON public.bookings` and `CREATE POLICY ... ON public.notifications`.
- `SEC-07` File Reference: `lib/main.dart:46-59`
  - Impact: QiCard path is on by default, increasing blast radius of incomplete hardening/config.
  - Exploit/Failure scenario: Build runs QiCard code path unexpectedly in an environment without hardened webhook/signature setup.
- Security note (PII/logging): No explicit name/email/phone logging was verified in audited booking payment code paths; payment/request/booking IDs are logged. File Reference: `lib/features/booking/view/payment_checkout_screen.dart:211-214`, `lib/core/services/qicard_payment_service.dart:141-145`, `lib/core/services/qicard_payment_service.dart:177-180`, `lib/core/services/qicard_payment_service.dart:588-590`
  - UNVERIFIED: PII logging elsewhere in transitive dependencies/out-of-scope files.

### 3.2 Data Integrity
- `DI-01` File Reference: `lib/features/booking/services/booking_service.dart:84-136`, `lib/features/booking/view/payment_checkout_screen.dart:143-178`
  - Booking draft is persisted before payment is confirmed and provider is notified immediately.
  - Failure mode: Abandoned or failed payment leaves a draft and/or false provider notification.
- `DI-02` File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:399-412`, `lib/features/booking/services/booking_service.dart:339-344`, `lib/features/booking/services/booking_service.dart:235-275`
  - `markDelivered()` duplicates the status mutation path (`_repo.markDelivered` then `updateBookingStatus`).
  - Failure mode: Duplicate notification insert attempts and duplicate state transitions.
- `DI-03` File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:381-397`, `lib/features/booking/services/booking_service.dart:316-337`
  - Comment claims atomic RPC decline/refund path, but implementation is multi-step and non-atomic.
  - Failure mode: Race between status update and refund RPC, plus incorrect operator expectations during incident handling.
- `DI-04` File Reference: `lib/features/booking/view/payment_checkout_screen.dart:58-89`, `lib/features/booking/viewmodels/booking_view_model.dart:274-298`
  - `_paymentFlowInProgress` cannot become `true`, so dispose cleanup conditions do not represent real payment state.
  - Failure mode: Draft may be canceled too early or cleanup policy drifts from intended logic.
- `DI-05` File Reference: `lib/features/booking/models/booking_model.dart:42-70`, `lib/features/booking/models/booking_model.dart:133-158`
  - `null` `slot_id` is masked as zero UUID and legacy `in_progress` collapses into `active`.
  - Failure mode: Upstream DB anomalies become silent UI state instead of visible parse/data errors.
- `DI-06` File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:243-272`, `lib/features/booking/view/payment_checkout_screen.dart:227-231`
  - Payment success UI finalization depends on polling `getBookingById()` after WebView return/recovery.
  - Failure mode: Eventual consistency delays can present ambiguous “still processing” errors after successful gateway completion.

### 3.3 Architecture
- `ARC-01` File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:34-46`, `lib/features/booking/viewmodels/booking_view_model.dart:243-298`, `lib/features/booking/viewmodels/booking_view_model.dart:445-521`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`, `lib/features/booking/viewmodels/booking_view_model.dart:650-680`
  - `BookingViewModel` combines slot CRUD, booking lists, payment orchestration, polling, and chat integration.
  - Result: high coupling and broad blast radius for small changes.
- `ARC-02` File Reference: `lib/features/booking/view/payment_checkout_screen.dart:135-262`
  - Checkout screen contains workflow state machine (draft creation, gateway init, WebView return handling, recovery trigger, polling).
  - Result: MVVM boundary drift and hard-to-test UI logic.
- `ARC-03` File Reference: `lib/features/booking/services/booking_service.dart:84-136`, `lib/features/booking/services/booking_service.dart:235-275`, `lib/features/booking/services/booking_service.dart:287-344`
  - `BookingService` mixes persistence with notifications and ledger orchestration.
  - Result: unclear transaction boundaries and side-effect coupling.
- `ARC-04` File Reference: `lib/features/booking/data/booking_repository.dart:20-140`
  - Repository mostly forwards calls 1:1 to service with minimal transformation.
  - Result: maintenance overhead without strong abstraction value.
- `ARC-05` File Reference: `lib/features/booking/view/booking_details_screen.dart:47-84`, `lib/features/booking/view/booking_details_screen.dart:199-209`, `lib/features/booking/view/booking_details_screen.dart:249-331`, `lib/features/booking/view/booking_details_screen.dart:469-514`
  - `BookingDetailsScreen` combines presentation, CTA resolution, status matrix, `OrderManagementViewModel` provider creation, and chat navigation.
  - Result: dense screen with mixed concerns and rebuild-sensitive object creation.
- `ARC-06` File Reference: `lib/core/utils/unified_cta_resolver.dart:3-12`, `lib/core/utils/unified_cta_resolver.dart:16-52`, `lib/features/booking/view/booking_details_screen.dart:249-331`, `lib/features/booking/view/booking_details_screen.dart:303-340`
  - `UnifiedCtaResolver` is not authoritative for booking actions; booking details keeps a second legacy action matrix.
  - Result: duplicated decision logic and drift risk.
- Cyclic dependency analysis:
  - UNVERIFIED (no dependency graph tool run in this audit; manual file inspection did not establish a cycle proof). Missing artifact to verify: a generated import graph for `lib/features/booking/**` and direct dependencies.

### 3.4 Code Quality
- `CQ-01` File Reference: `lib/features/booking/view/payment_checkout_screen.dart:14-20`, `lib/features/booking/viewmodels/booking_view_model.dart:29-30`, `lib/features/booking/viewmodels/booking_view_model.dart:383-387`
  - Comments describe old/demo-only or atomic behavior that does not match current implementation.
- `CQ-02` File Reference: `lib/features/booking/view/bookings_discovery_screen.dart:23-30`
  - `!t.isTender` is treated as a booking discriminator with an inline assumption comment.
- `CQ-03` File Reference: `lib/features/booking/view/payment_method_screen.dart:11-21`, `lib/features/booking/view/payment_method_screen.dart:43-58`, `lib/features/booking/view/payment_method_screen.dart:49-53`
  - Legacy demo payment screen remains in feature folder and uses `USD`, diverging from current QiCard/IQD flow.
  - UNVERIFIED: Whether this screen is unreachable/no-callsite in all runtime paths (requires repo-wide caller search + runtime route audit).
- `CQ-04` File Reference: `lib/features/booking/view/payment_checkout_screen.dart:32-45`
  - `packagePrice` is defined but unused in the current checkout screen logic.
- `CQ-05` File Reference: `lib/features/notifications/services/notification_service.dart:90-94`
  - Notification insert failures are swallowed (logged but not rethrown), which may hide side-effect failures during booking state changes.
  - Note: This may be intentional UX behavior, but error visibility/telemetry is weak.

### 3.5 Performance
- `PERF-01` File Reference: `lib/features/booking/view/bookings_list_screen.dart:21-29`, `lib/features/booking/view/bookings_list_screen.dart:42-46`
  - Both client/provider booking lists are loaded on screen init and on refresh regardless of active tab.
- `PERF-02` File Reference: `lib/features/booking/view/bookings_list_screen.dart:57-76`, `lib/features/booking/viewmodels/booking_view_model.dart:89-102`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`
  - Shared `bookingsLoading`/`bookingsError` creates cross-tab rebuilds and ambiguous loading/error UI.
- `PERF-03` File Reference: `lib/features/booking/services/booking_service.dart:168-180`, `lib/features/booking/services/booking_service.dart:191-204`, `lib/features/booking/services/booking_service.dart:212-220`
  - List endpoints fetch `tasks(*)` (full row) for list rendering paths.
- `PERF-04` File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:243-272`, `lib/features/booking/view/payment_checkout_screen.dart:99-133`
  - Polling loop does repeated booking reads every 3 seconds for up to 60 seconds.
- `PERF-05` File Reference: `lib/features/booking/view/booking_details_screen.dart:199-209`
  - `OrderManagementViewModel` is instantiated inside screen build via `ChangeNotifierProvider`.

### 3.6 Testing Gaps
- `TEST-01` File Reference: `test/unit/booking/booking_view_model_test.dart:57-303`, `test/unit/models/booking_model_test.dart:20-49`
  - Verified coverage exists for selected BookingViewModel unit behaviors and BookingModel mapping cases.
- Missing high-risk tests (all UNVERIFIED as absent because this audit did not exhaustively inspect the entire test tree beyond feature-scoped searches):
  - Checkout/WebView callback spoofing and host allowlist behavior. File Reference (target code needing tests): `lib/features/booking/view/payment_webview_screen.dart:76-150`
  - Draft lifecycle cleanup (abandon/cancel/failure/orphan timer). File Reference (target code needing tests): `lib/features/booking/view/payment_checkout_screen.dart:58-89`, `lib/features/booking/view/payment_checkout_screen.dart:135-262`, `lib/features/booking/viewmodels/booking_view_model.dart:274-298`
  - Duplicate `markDelivered()` regression. File Reference (target code needing tests): `lib/features/booking/viewmodels/booking_view_model.dart:399-412`
  - Decline/refund atomicity sequencing. File Reference (target code needing tests): `lib/features/booking/services/booking_service.dart:316-337`
  - Tab-specific list loading/error state behavior. File Reference (target code needing tests): `lib/features/booking/view/bookings_list_screen.dart:57-76`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`
  - QiCard config validation (`https` only, missing creds). File Reference (target code needing tests): `lib/core/services/qicard_payment_service.dart:83-121`

## 4) Dead/Unused Code Candidates
- Candidate: `lib/features/booking/view/payment_method_screen.dart` (legacy demo payment flow with `USD`). File Reference: `lib/features/booking/view/payment_method_screen.dart:11-21`, `lib/features/booking/view/payment_method_screen.dart:43-58`, `lib/features/booking/view/payment_method_screen.dart:49-53`
  - Why candidate: Booking checkout flow currently navigates to `PaymentCheckoutScreen`, not `PaymentMethodScreen`. File Reference: `lib/features/booking/view/availability_screen.dart:274-290`
  - How to confirm: `rg -n "PaymentMethodScreen\\(" lib` and run booking navigation smoke test.
  - UNVERIFIED: No-callsite status until grep results are reviewed as part of the fix session.
- Candidate: `PaymentCheckoutScreen.packagePrice` parameter/field. File Reference: `lib/features/booking/view/payment_checkout_screen.dart:32-45`
  - Why candidate: field defined but not referenced in current screen logic.
  - How to confirm: `rg -n "packagePrice" lib/features/booking/view/payment_checkout_screen.dart`
- Candidate: `UnifiedCtaResolver.entityType` parameter. File Reference: `lib/core/utils/unified_cta_resolver.dart:6-11`
  - Why candidate: parameter accepted but not read in current implementation.
  - How to confirm: `rg -n "entityType" lib/core/utils/unified_cta_resolver.dart`
- Candidate alias path: `bookSlot()` alongside `createBookingDraft()`. File Reference: `lib/features/booking/services/booking_service.dart:138-159`, `lib/features/booking/data/booking_repository.dart:48-90`, `lib/features/booking/viewmodels/booking_view_model.dart:195-230`, `lib/features/booking/viewmodels/booking_view_model.dart:445-475`
  - Why candidate: overlapping creation semantics increase API surface.
  - How to confirm: repo-wide call-site search for `.bookSlot(` and runtime flow smoke tests.

## 5) Duplicate Code Candidates
- Status presentation mapping duplicated across booking details and booking card UI.
  - File References: `lib/features/booking/view/booking_details_screen.dart:390-467`, `lib/features/booking/view/widgets/booking_card.dart:141-211`
  - Proposed shared abstraction: `lib/features/booking/viewmodels/booking_status_presenter.dart` + `lib/features/booking/view/widgets/booking_status_badge.dart`
- Booking creation semantics duplicated (`bookSlot` vs `createBookingDraft`) across service/repository/viewmodel layers.
  - File References: `lib/features/booking/services/booking_service.dart:84-159`, `lib/features/booking/data/booking_repository.dart:48-90`, `lib/features/booking/viewmodels/booking_view_model.dart:195-230`, `lib/features/booking/viewmodels/booking_view_model.dart:445-475`
  - Proposed shared abstraction: single `createBookingDraft()` API plus explicit finalize/confirm payment flow.
- CTA resolution duplicated in the same screen (`resolveActions()` called for banner and dynamic actions) while legacy action matrix remains.
  - File References: `lib/features/booking/view/booking_details_screen.dart:47-84`, `lib/features/booking/view/booking_details_screen.dart:249-331`, `lib/features/booking/view/booking_details_screen.dart:303-340`, `lib/core/utils/unified_cta_resolver.dart:3-12`
  - Proposed shared abstraction: `BookingActionPolicy` (feature-local) or fully authoritative `UnifiedCtaResolver` adapter for booking.

## 6) Refactor Plan (Exact Paths)
- Split checkout workflow logic out of UI screen (keep screen as shell)
  - Edit: `lib/features/booking/view/payment_checkout_screen.dart`
  - Create: `lib/features/booking/viewmodels/booking_checkout_flow_controller.dart`
  - Create: `lib/features/booking/utils/payment_webview_result_parser.dart`
  - Create: `lib/features/booking/view/widgets/payment_checkout_summary_card.dart`
  - Create: `lib/features/booking/view/widgets/payment_checkout_state_panel.dart`
  - Migration strategy: keep public `PaymentCheckoutScreen` constructor stable; move logic behind an internal controller instance first.
- Split `BookingViewModel` by responsibility while preserving a compatibility facade
  - Edit (facade wrapper): `lib/features/booking/viewmodels/booking_view_model.dart`
  - Create: `lib/features/booking/viewmodels/booking_slots_view_model.dart`
  - Create: `lib/features/booking/viewmodels/booking_lists_view_model.dart`
  - Create: `lib/features/booking/viewmodels/booking_payment_view_model.dart`
  - Create: `lib/features/booking/viewmodels/booking_actions_view_model.dart`
  - Migration strategy: facade delegates to new sub-controllers to avoid breaking current `Provider<BookingViewModel>` consumers immediately. File Reference (provider wiring to preserve initially): `lib/main.dart:145-151`
- Separate booking persistence from side-effect orchestration
  - Edit: `lib/features/booking/services/booking_service.dart`
  - Create: `lib/features/booking/services/booking_notification_service.dart`
  - Create: `lib/features/booking/services/booking_payment_orchestrator.dart`
  - Migration strategy: keep `BookingRepository` API stable first; route methods internally to new services.
- Consolidate status UI mapping
  - Create: `lib/features/booking/viewmodels/booking_status_presenter.dart`
  - Create: `lib/features/booking/view/widgets/booking_status_banner.dart`
  - Edit: `lib/features/booking/view/booking_details_screen.dart`
  - Edit: `lib/features/booking/view/widgets/booking_card.dart`
  - Migration strategy: replace duplicated `switch` blocks with presenter methods and shared widget outputs.
- Decompose `BookingDetailsScreen`
  - Edit: `lib/features/booking/view/booking_details_screen.dart`
  - Create: `lib/features/booking/view/widgets/booking_details_header_section.dart`
  - Create: `lib/features/booking/view/widgets/booking_details_counterparty_section.dart`
  - Create: `lib/features/booking/view/widgets/booking_details_schedule_section.dart`
  - Create: `lib/features/booking/view/widgets/booking_details_actions_section.dart`
  - Migration strategy: extract pure widgets first (no behavior change), then move action policy logic.
- Legacy payment screen handling
  - Option A (safer first): Move `lib/features/booking/view/payment_method_screen.dart` -> `lib/features/booking/view/legacy/payment_method_screen.dart`
  - Option B (after caller verification): delete `lib/features/booking/view/payment_method_screen.dart`
  - Migration strategy: perform repo-wide caller search and smoke test before deletion.

## 7) Fix Plan (Phases)
Phase 1: Critical security & correctness
- Item 1: Remove hardcoded QiCard defaults and fail closed when config is missing.
  - What to change: Replace credential/terminal/password `defaultValue` literals with empty defaults (or compile-time placeholders that fail validation) and hard fail on missing config. File Reference: `lib/core/services/qicard_payment_service.dart:20-48`, `lib/core/services/qicard_payment_service.dart:83-96`
  - Exact file(s) to edit/create: `lib/core/services/qicard_payment_service.dart`
  - Acceptance criteria: App cannot initiate QiCard payment without explicit defines; no credential-like literals remain in the file.
- Item 2: Enforce `https`-only callback/finish URLs and tighten WebView callback host/path matching.
  - What to change: Reject `http` in QiCard config validation and add allowlisted host/path checks for success/failure return detection. File Reference: `lib/core/services/qicard_payment_service.dart:98-121`, `lib/features/booking/view/payment_webview_screen.dart:76-150`, `lib/features/booking/view/payment_webview_screen.dart:169-209`
  - Exact file(s) to edit/create: `lib/core/services/qicard_payment_service.dart`, `lib/features/booking/view/payment_webview_screen.dart`, optional `lib/features/booking/utils/payment_webview_result_parser.dart`
  - Acceptance criteria: Non-HTTPS callback config is rejected; non-allowlisted hosts cannot trigger `SUCCESS`/`FAILED` results.
- Item 3: Harden client recovery/webhook contract.
  - What to change: Stop sending unsigned synthetic `SUCCESS` directly to webhook handler, or gate it with a server-issued token/alternate authenticated endpoint; ensure webhook signature verification is mandatory in deployed environments. File Reference: `lib/core/services/qicard_payment_service.dart:323-355`, `supabase/functions/qicard_webhook_handler/index.ts:63-88`, `supabase/functions/qicard_webhook_handler/index.ts:149-176`, `supabase/functions/qicard_webhook_handler/index.ts:190-258`
  - Exact file(s) to edit/create: `lib/core/services/qicard_payment_service.dart`, `supabase/functions/qicard_webhook_handler/index.ts` (or new edge function endpoint file if separated)
  - Acceptance criteria: Unsigned client recovery calls are rejected in all target environments; checkout still completes via verified webhook path.
- Item 4: Fix duplicate `markDelivered()` mutation and correct decline-flow comments/atomicity.
  - What to change: Ensure one status mutation path only; either implement true atomic decline+refund RPC flow or correct comments and add idempotent sequencing guards. File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:381-412`, `lib/features/booking/services/booking_service.dart:316-344`
  - Exact file(s) to edit/create: `lib/features/booking/viewmodels/booking_view_model.dart`, `lib/features/booking/services/booking_service.dart`, optional SQL/RPC migration file if introducing atomic RPC
  - Acceptance criteria: `markDelivered()` performs one status update; decline path behavior matches comments and is idempotent under retries.
- Item 5: Move provider notification timing out of draft creation path.
  - What to change: Do not send provider booking notification at draft insert time; send only after authoritative payment-held state (ledger/webhook success). File Reference: `lib/features/booking/services/booking_service.dart:84-136`, `supabase/functions/qicard_webhook_handler/index.ts:190-258`
  - Exact file(s) to edit/create: `lib/features/booking/services/booking_service.dart`, `supabase/functions/qicard_webhook_handler/index.ts` (or another server-side post-payment notifier), possibly `lib/features/notifications/services/notification_service.dart`
  - Acceptance criteria: Failed/canceled payment attempts do not produce provider “New Booking Request” notifications.
- Item 6: Fix checkout draft cleanup state bug and safer defaults.
  - What to change: Replace immutable `_paymentFlowInProgress` with real state transitions or remove dead condition; set safer payment feature flag default for rollout. File Reference: `lib/features/booking/view/payment_checkout_screen.dart:58-89`, `lib/main.dart:46-59`
  - Exact file(s) to edit/create: `lib/features/booking/view/payment_checkout_screen.dart`, `lib/main.dart`
  - Acceptance criteria: Draft cancellation behavior matches intended checkout states; QiCard path is not enabled by accident in non-hardened builds.

Phase 2: Refactor/structure
- Item 1: Extract checkout flow controller from `PaymentCheckoutScreen`.
  - What to change: Move draft/create/init/recovery/polling logic from widget state into a controller/viewmodel. File Reference: `lib/features/booking/view/payment_checkout_screen.dart:99-262`
  - Exact file(s) to edit/create: `lib/features/booking/view/payment_checkout_screen.dart`, `lib/features/booking/viewmodels/booking_checkout_flow_controller.dart`
  - Acceptance criteria: Screen becomes primarily UI rendering + controller bindings; flow logic can be unit-tested without widget pumping.
- Item 2: Split `BookingViewModel` into focused notifiers/controllers.
  - What to change: Separate slots, bookings list state, payment orchestration, and chat/status actions. File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:34-46`, `lib/features/booking/viewmodels/booking_view_model.dart:243-298`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`, `lib/features/booking/viewmodels/booking_view_model.dart:650-680`
  - Exact file(s) to edit/create: `lib/features/booking/viewmodels/booking_view_model.dart`, plus files listed in Section 6
  - Acceptance criteria: Each controller has a single responsibility and smaller public surface; existing UI compiles with compatibility facade.
- Item 3: Separate booking persistence from side effects and unify action policy.
  - What to change: Move notification/ledger orchestration out of `BookingService`; consolidate booking action rules into one source (feature-local or `UnifiedCtaResolver`). File Reference: `lib/features/booking/services/booking_service.dart:84-136`, `lib/features/booking/services/booking_service.dart:235-344`, `lib/features/booking/view/booking_details_screen.dart:249-340`, `lib/core/utils/unified_cta_resolver.dart:3-52`
  - Exact file(s) to edit/create: `lib/features/booking/services/booking_service.dart`, `lib/features/booking/services/booking_payment_orchestrator.dart`, `lib/features/booking/services/booking_notification_service.dart`, `lib/features/booking/view/booking_details_screen.dart`, optionally `lib/core/utils/unified_cta_resolver.dart`
  - Acceptance criteria: Persistence service performs DB IO only; booking actions are resolved in one policy path.
- Item 4: Consolidate status presentation widgets.
  - What to change: Replace duplicated status `switch` blocks with shared presenter/widget. File Reference: `lib/features/booking/view/booking_details_screen.dart:390-467`, `lib/features/booking/view/widgets/booking_card.dart:141-211`
  - Exact file(s) to edit/create: `lib/features/booking/view/booking_details_screen.dart`, `lib/features/booking/view/widgets/booking_card.dart`, `lib/features/booking/viewmodels/booking_status_presenter.dart`, `lib/features/booking/view/widgets/booking_status_badge.dart`
  - Acceptance criteria: Status label/color mapping exists in one place and both screens render consistent values.

Phase 3: Tests
- Item 1: Add unit tests for QiCard config validation and URL policy.
  - What to change: Test missing config, `http` rejection, and valid `https` acceptance for initiate flow validation. File Reference: `lib/core/services/qicard_payment_service.dart:83-121`
  - Exact file(s) to edit/create: `test/unit/core/services/qicard_payment_service_test.dart`
  - Acceptance criteria: Tests fail on `http` and missing config; pass on valid `https` config path stubs.
- Item 2: Add widget/unit tests for WebView callback parsing and spoof defense.
  - What to change: Extract URL parsing logic (or test delegate behavior) for allowlist/host/path cases. File Reference: `lib/features/booking/view/payment_webview_screen.dart:76-150`, `lib/features/booking/view/payment_webview_screen.dart:169-209`
  - Exact file(s) to edit/create: `test/widget/booking/payment_webview_screen_test.dart` and/or `test/unit/booking/payment_webview_result_parser_test.dart`
  - Acceptance criteria: Non-allowlisted success-like URLs do not produce `SUCCESS`; valid URLs do.
- Item 3: Add regression tests for booking correctness issues.
  - What to change: Cover duplicate `markDelivered`, decline sequencing, draft cancellation behavior, and separate list loading/error states. File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:399-412`, `lib/features/booking/services/booking_service.dart:316-337`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`
  - Exact file(s) to edit/create: `test/unit/booking/booking_view_model_test.dart`, `test/unit/booking/booking_service_test.dart`, `test/widget/booking/bookings_list_screen_test.dart`
  - Acceptance criteria: Regressions reproduce before fix and are prevented after fix.
- Item 4: Add checkout flow integration tests (or high-fidelity widget tests with mocked payment service).
  - What to change: Verify success/cancel/failure/timeouts and orphan draft cleanup. File Reference: `lib/features/booking/view/payment_checkout_screen.dart:58-89`, `lib/features/booking/view/payment_checkout_screen.dart:135-262`
  - Exact file(s) to edit/create: `test/widget/booking/payment_checkout_screen_test.dart`, optional `integration_test/booking_checkout_flow_test.dart`
  - Acceptance criteria: Each checkout outcome produces correct booking/notification side effects and UI result.

Phase 4: Polish/perf
- Item 1: Load booking tabs lazily and split client/provider loading/error state.
  - What to change: Separate viewmodel state for client/provider lists and fetch only active tab by default. File Reference: `lib/features/booking/view/bookings_list_screen.dart:21-29`, `lib/features/booking/view/bookings_list_screen.dart:57-76`, `lib/features/booking/viewmodels/booking_view_model.dart:89-102`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`
  - Exact file(s) to edit/create: `lib/features/booking/view/bookings_list_screen.dart`, `lib/features/booking/viewmodels/booking_view_model.dart` (or split controllers from Phase 2)
  - Acceptance criteria: Opening one tab does not fetch/render the other tab until requested; tab errors do not leak across tabs.
- Item 2: Reduce query payloads for booking lists.
  - What to change: Replace `tasks(*)` with explicit selected columns needed for list cards. File Reference: `lib/features/booking/services/booking_service.dart:168-180`, `lib/features/booking/services/booking_service.dart:191-204`
  - Exact file(s) to edit/create: `lib/features/booking/services/booking_service.dart`, `lib/features/booking/models/booking_model.dart` (if mapping changes)
  - Acceptance criteria: API payload shrinks and list UI continues to render required fields.
- Item 3: Move `OrderManagementViewModel` provider instantiation out of `BookingDetailsScreen.build()` if lifecycle/rebuild profiling shows churn.
  - What to change: Hoist provider to route boundary or a stateful wrapper. File Reference: `lib/features/booking/view/booking_details_screen.dart:199-209`
  - Exact file(s) to edit/create: `lib/features/booking/view/booking_details_screen.dart` or a new wrapper widget
  - Acceptance criteria: Rebuilds do not recreate order management state unexpectedly.
- Item 4: Remove/relocate legacy payment screen and stale comments after functional fixes land.
  - What to change: Archive/delete `PaymentMethodScreen`; update comments to match actual behavior. File Reference: `lib/features/booking/view/payment_method_screen.dart:11-21`, `lib/features/booking/view/payment_checkout_screen.dart:14-20`, `lib/features/booking/viewmodels/booking_view_model.dart:383-387`
  - Exact file(s) to edit/create: `lib/features/booking/view/payment_method_screen.dart`, `lib/features/booking/view/payment_checkout_screen.dart`, `lib/features/booking/viewmodels/booking_view_model.dart`
  - Acceptance criteria: No stale flow comments remain; no dead legacy payment screen in active feature path.

## 8) Verification Checklist
### Commands
- Static analysis (feature + direct booking payment/CTA dependencies)
  - `flutter analyze lib/features/booking lib/core/services/qicard_payment_service.dart lib/core/utils/unified_cta_resolver.dart`
- Existing unit tests (verified files)
  - `flutter test test/unit/booking/booking_view_model_test.dart`
  - `flutter test test/unit/models/booking_model_test.dart`
- Secret/default credential grep checks
  - `rg -n "QICARD_(TERMINAL_ID|USERNAME|PASSWORD)'.*defaultValue" lib/core/services/qicard_payment_service.dart`
  - `rg -n "paymentgatewaytest|WHaNFE5C3qlChqNbAzH4|237984" lib/core/services/qicard_payment_service.dart`
- HTTP callback acceptance checks
  - `rg -n "scheme != 'https'|scheme == 'http'" lib/core/services/qicard_payment_service.dart lib/features/booking/view/payment_webview_screen.dart`
- Legacy screen caller check
  - `rg -n "PaymentMethodScreen\\(" lib`
- Booking alias caller check
  - `rg -n "\\.bookSlot\\(" lib`

### Manual Scenarios
- Scenario 1: Availability -> booking -> payment success
  - Open `/availability` route and select an open slot. File Reference: `lib/main.dart:238-259`, `lib/features/booking/view/availability_screen.dart:248-297`
  - Complete payment flow and verify single booking creation + expected status/payment state + single provider notification. File Reference: `lib/features/booking/view/payment_checkout_screen.dart:135-262`, `lib/features/booking/services/booking_service.dart:84-136`, `lib/features/booking/services/booking_service.dart:235-275`
- Scenario 2: Payment cancel/failure from WebView
  - Cancel/fail inside WebView and verify draft cleanup + no false provider notification. File Reference: `lib/features/booking/view/payment_webview_screen.dart:135-147`, `lib/features/booking/view/payment_checkout_screen.dart:197-209`, `lib/features/booking/viewmodels/booking_view_model.dart:274-298`
- Scenario 3: WebView spoof attempt (post-fix)
  - Navigate WebView to non-allowlisted host/path containing `/payment/success`; app must not emit `SUCCESS`. File Reference: `lib/features/booking/view/payment_webview_screen.dart:95-109`, `lib/features/booking/view/payment_webview_screen.dart:123-147`
- Scenario 4: Provider actions
  - Accept, decline/refund, mark delivered, release flows and verify exactly one state mutation + correct ledger side effects. File Reference: `lib/features/booking/view/booking_details_screen.dart:303-340`, `lib/features/booking/viewmodels/booking_view_model.dart:381-412`, `lib/features/booking/services/booking_service.dart:287-344`
- Scenario 5: Booking lists tabs
  - Open `BookingsListScreen`; verify only active tab fetches (post-fix) and errors/loading do not cross-contaminate tabs. File Reference: `lib/features/booking/view/bookings_list_screen.dart:21-29`, `lib/features/booking/view/bookings_list_screen.dart:57-76`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`

### Supabase/RLS Contract Checks
- Check `bookings` and `notifications` policies in the live database (RLS source of truth; client checks are UX only)
  - Run in Supabase SQL editor / `psql`:
    - `select schemaname, tablename, policyname, roles, cmd, qual, with_check from pg_policies where schemaname='public' and tablename in ('bookings','notifications') order by tablename, policyname;`
    - `select relname, relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and relname in ('bookings','notifications');`
  - Expected contract to validate against app behavior (docs reference only; live DB UNVERIFIED until queried). File Reference: `Sline_everything/SUPABASE_SETUP.md:1073-1080`
- Check RPC execute privileges for `process_payment_event_ledger`
  - Verify grants match migrations. File Reference: `supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql:4-42`, `supabase/migrations/20260225_create_ledger_rls_policies.sql:244-253`
  - SQL check: `select p.proname, p.prosecdef, p.proacl from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='process_payment_event_ledger';`
- Check webhook signature enforcement configuration in deployed edge function environment
  - Validate `QICARD_RSA_PUBLIC_KEY_PEM` is set and non-empty in all non-local environments. File Reference: `supabase/functions/qicard_webhook_handler/index.ts:63-88`, `supabase/functions/qicard_webhook_handler/index.ts:170-176`
  - Validate unsigned client POST to `qicard_webhook_handler` is rejected in staging/prod.
- Check booking payment status mutation path contract
  - Confirm RPC updates booking payment status (`held`) and is idempotent under replay. File Reference: `supabase/functions/qicard_webhook_handler/index.ts:223-242`, `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:246-251`

## 9) Risks & Rollback Notes
- Risk: Tightening callback URL and WebView host validation can break current payment return flow if real provider redirect hosts/paths are not fully enumerated.
  - Rollback steps: Temporarily broaden allowlist to verified provider domains only (not path heuristics) and disable client recovery until server contract is confirmed. File Reference: `lib/features/booking/view/payment_webview_screen.dart:76-150`, `lib/core/services/qicard_payment_service.dart:323-355`
- Risk: Removing hardcoded QiCard defaults can block checkout in local/dev builds without configuration.
  - Rollback steps: Explicitly set dev-only `--dart-define` values in local run scripts; do not restore secrets in source. File Reference: `lib/core/services/qicard_payment_service.dart:20-48`, `lib/core/services/qicard_payment_service.dart:83-96`
- Risk: Moving notification timing to post-payment success changes provider UX expectations.
  - Rollback steps: Introduce a distinct non-actionable “payment pending” notification type if needed, while keeping actual booking request notifications post-payment. File Reference: `lib/features/booking/services/booking_service.dart:125-133`, `lib/features/notifications/services/notification_service.dart:69-94`
- Risk: Refactoring `BookingViewModel` / `BookingDetailsScreen` can regress provider wiring and screen behavior.
  - Rollback steps: Keep facade wrappers and migrate screen by screen; preserve `BookingViewModel` provider signature until all consumers are updated. File Reference: `lib/main.dart:145-151`, `lib/features/booking/viewmodels/booking_view_model.dart:34-46`
- Risk: Deleting/moving `PaymentMethodScreen` may break hidden/manual routes.
  - Rollback steps: Move to `view/legacy/` first and keep a temporary compat import/export until caller search + smoke tests pass. File Reference: `lib/features/booking/view/payment_method_screen.dart:11-21`, `lib/features/booking/view/availability_screen.dart:274-290`
