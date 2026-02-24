# Bookin — Feature Audit (Phase 1) + Verified Fix Plan

## 0) Overview
- What this feature does:
  - Booking discovery, availability viewing/slot creation, booking draft creation, payment checkout/WebView callback handling, booking list/detail actions, and booking lifecycle updates (`lib/features/booking/view/bookings_discovery_screen.dart:13-135`, `lib/features/booking/view/availability_screen.dart:41-298`, `lib/features/booking/view/payment_checkout_screen.dart:51-262`, `lib/features/booking/view/payment_webview_screen.dart:70-210`, `lib/features/booking/view/bookings_list_screen.dart:17-218`, `lib/features/booking/view/booking_details_screen.dart:20-515`).
- Boundaries (in scope):
  - `lib/features/booking/**` (feature files listed in current repo state) (`lib/features/booking/data/booking_repository.dart:1-141`, `lib/features/booking/viewmodels/booking_view_model.dart:90-681`, `lib/features/booking/services/booking_service.dart:1-376`).
  - Direct dependencies touched by booking imports/calls only: payment services, ledger RPC client, notification service, chat repository, QiCard webhook edge function + ledger RPC SQL (`lib/features/booking/viewmodels/booking_view_model.dart:5-11`, `lib/features/booking/services/booking_service.dart:6-8`, `lib/core/services/qicard_payment_service.dart:20-48`, `lib/features/wallet/services/ledger_service.dart:21-57`, `lib/features/notifications/services/notification_service.dart:5-94`, `lib/features/chat/data/chat_repository.dart:36-47`, `supabase/functions/qicard_webhook_handler/index.ts:48-88`, `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:990-1115`).
- Boundaries (out of scope):
  - Non-booking features except direct dependencies/call targets listed above; dashboard booking widget is reviewed only as a duplicate-code consumer (`lib/features/dashboard/view/widgets/booking_card.dart:16-248`).
  - Full DB schema/RLS for `bookings`, `availability_slots`, `notifications` is UNVERIFIED because table/policy migration files are missing in the current repo snapshot (missing files not present under `supabase/migrations/`; only ledger/payment migrations are present).
- Entry points (screens/routes/calls):
  - Bottom-nav booking tab entry: `BookingsDiscoveryScreen` (`lib/app/main_navigation_screen.dart:38-49`).
  - `AvailabilityScreen` route construction from named route args (`lib/main.dart:246-258`).
  - Global `BookingViewModel` provider wiring and payment service injection (`lib/main.dart:46-59`, `lib/main.dart:144-151`).
  - Feature inventory mapping (`booking`) in project index (used only for feature selection context) (`.TODO/CodexRefactor/01_FEATURES_INDEX.md:180-182`, `.TODO/CodexRefactor/01_FEATURES_INDEX.md:268-294`).

## 1) Feature Map (Current Repo State)
- Primary feature files (with references)
  - Data/repository:
    - `lib/features/booking/data/booking_repository.dart:1-141`
  - Models:
    - `lib/features/booking/models/booking_model.dart:1-159`
    - `lib/features/booking/models/slot_model.dart:1-61`
  - Services:
    - `lib/features/booking/services/booking_service.dart:1-376`
  - ViewModel:
    - `lib/features/booking/viewmodels/booking_view_model.dart:90-681`
  - Screens/sheets/widgets:
    - `lib/features/booking/view/bookings_discovery_screen.dart:13-135`
    - `lib/features/booking/view/availability_screen.dart:41-298`
    - `lib/features/booking/view/bookings_list_screen.dart:17-218`
    - `lib/features/booking/view/booking_details_screen.dart:20-515`
    - `lib/features/booking/view/booking_sheet.dart:30-115`
    - `lib/features/booking/view/add_slot_sheet.dart:45-120`
    - `lib/features/booking/view/payment_checkout_screen.dart:51-590`
    - `lib/features/booking/view/payment_webview_screen.dart:70-210`
    - `lib/features/booking/view/payment_method_screen.dart:1-120`
    - `lib/features/booking/view/widgets/booking_card.dart:11-212`
- Direct dependencies (with references)
  - Payment abstraction + implementations used by booking VM / app wiring:
    - `lib/core/services/payment_service.dart:90-157`
    - `lib/core/services/demo_payment_service.dart:43-67`
    - `lib/core/services/qicard_payment_service.dart:20-48`, `lib/core/services/qicard_payment_service.dart:75-198`, `lib/core/services/qicard_payment_service.dart:323-613`
    - `lib/main.dart:46-59`
  - Ledger RPC client used by booking service payment actions:
    - `lib/features/wallet/services/ledger_service.dart:21-57`
    - `lib/features/booking/services/booking_service.dart:287-337`
  - Notification service used by booking service side effects:
    - `lib/features/notifications/services/notification_service.dart:5-94`
    - `lib/features/booking/services/booking_service.dart:20-20`, `lib/features/booking/services/booking_service.dart:125-134`, `lib/features/booking/services/booking_service.dart:249-273`
  - Chat repository used by booking details -> contact provider flow:
    - `lib/features/chat/data/chat_repository.dart:36-47`
    - `lib/features/booking/viewmodels/booking_view_model.dart:650-680`
    - `lib/features/booking/view/booking_details_screen.dart:469-488`
  - Duplicate booking presentation consumer (for duplicate-code audit only):
    - `lib/features/dashboard/view/widgets/booking_card.dart:16-248`
- Supabase touchpoints (tables/RPC/storage/realtime) (with references to code or SQL docs)
  - Observed tables queried/written by booking service:
    - `availability_slots` (`lib/features/booking/services/booking_service.dart:17-18`, `lib/features/booking/services/booking_service.dart:30-50`, `lib/features/booking/services/booking_service.dart:68-80`)
    - `bookings` (`lib/features/booking/services/booking_service.dart:17-18`, `lib/features/booking/services/booking_service.dart:99-123`, `lib/features/booking/services/booking_service.dart:168-204`, `lib/features/booking/services/booking_service.dart:235-285`)
    - joined `tasks`, joined `availability_slots(starts_at)` (`lib/features/booking/services/booking_service.dart:170-171`, `lib/features/booking/services/booking_service.dart:193-194`, `lib/features/booking/services/booking_service.dart:214-215`)
  - Notifications table writes/reads (direct dependency used by booking service):
    - `notifications` (`lib/features/notifications/services/notification_service.dart:10-15`, `lib/features/notifications/services/notification_service.dart:25-35`, `lib/features/notifications/services/notification_service.dart:79-89`)
  - Ledger RPC invoked from client app via Supabase:
    - `process_payment_event_ledger` (`lib/features/wallet/services/ledger_service.dart:36-47`)
    - execute grants (`supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql:24-42`)
    - gateway escrow system-only branch (`supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:990-1115`)
  - Edge function touchpoint used by booking payment recovery path:
    - `qicard_webhook_handler` URL in client (`lib/core/services/qicard_payment_service.dart:37-48`, `lib/core/services/qicard_payment_service.dart:332-354`)
    - edge function implementation (`supabase/functions/qicard_webhook_handler/index.ts:149-188`, `supabase/functions/qicard_webhook_handler/index.ts:190-258`)
  - Realtime/storage buckets in booking feature:
    - UNVERIFIED absence claim. No direct realtime/storage calls were observed in audited booking files, but absence is based on code search only; no generated/runtime wiring files were audited.
  - Booking/slot/notification RLS policies:
    - UNVERIFIED. Current repo snapshot does not include local SQL files defining `public.bookings`, `public.availability_slots`, or `public.notifications` policies.

## 2) Evidence Index (Ground Truth)

| FindingID | Claim | File Reference (path + line range) | Risk | Notes |
|---|---|---|---|---|
| SEC-01 | Client app embeds QiCard merchant credentials and sends gateway Basic Auth requests directly | `lib/core/services/qicard_payment_service.dart:24-36`, `lib/core/services/qicard_payment_service.dart:123-154`, `lib/core/services/qicard_payment_service.dart:386-411`, `lib/core/services/qicard_payment_service.dart:471-494`, `lib/core/services/qicard_payment_service.dart:551-569` | Critical | Includes create/refund/cancel/status endpoints. |
| SEC-02 | Booking checkout triggers client-originated POST to webhook endpoint as “success recovery” | `lib/features/booking/view/payment_checkout_screen.dart:216-225`, `lib/features/booking/viewmodels/booking_view_model.dart:505-520`, `lib/core/services/qicard_payment_service.dart:323-354` | High | Privileged endpoint path is reused for client recovery. |
| SEC-03 | Webhook signature enforcement is conditional and can be skipped when public key env is absent | `supabase/functions/qicard_webhook_handler/index.ts:63-77`, `supabase/functions/qicard_webhook_handler/index.ts:170-176` | High | Function logs “dev only” and returns true without signature when key missing. |
| SEC-04 | Webhook handler executes ledger RPC with service-role client | `supabase/functions/qicard_webhook_handler/index.ts:48-57`, `supabase/functions/qicard_webhook_handler/index.ts:234-242` | High | Any signature bypass becomes privileged ledger mutation. |
| SEC-05 | WebView payment success/failure detection matches path patterns without host allowlist | `lib/features/booking/view/payment_webview_screen.dart:86-107`, `lib/features/booking/view/payment_webview_screen.dart:123-147`, `lib/features/booking/view/payment_webview_screen.dart:169-209` | High | Path-only trust allows spoofed redirects/pages. |
| SEC-06 | Booking service performs cross-user notification inserts from client-side code | `lib/features/booking/services/booking_service.dart:125-134`, `lib/features/booking/services/booking_service.dart:249-273`, `lib/features/notifications/services/notification_service.dart:69-94` | High | Authorization relies entirely on notifications RLS. |
| SEC-07 | Booking draft insert trusts client-supplied provider/slot/price fields before DB validation | `lib/features/booking/services/booking_service.dart:84-123` | High | RLS/DB constraints for this path are UNVERIFIED in repo snapshot. |
| DI-01 | `markDelivered()` in VM writes status twice | `lib/features/booking/viewmodels/booking_view_model.dart:399-408`, `lib/features/booking/data/booking_repository.dart:138-140`, `lib/features/booking/services/booking_service.dart:339-344` | High | Duplicate write/notification risk. |
| DI-02 | Decline+refund flow is multi-step (status update then refund), not atomic | `lib/features/booking/services/booking_service.dart:316-337` | High | Partial failure can leave inconsistent status/payment state. |
| DI-03 | VM comments claim atomic decline via RPC, but repo/service path is plain `declineBooking()` sequence | `lib/features/booking/viewmodels/booking_view_model.dart:381-392`, `lib/features/booking/data/booking_repository.dart:134-136`, `lib/features/booking/services/booking_service.dart:316-337` | Medium | Comment drift misleads maintainers. |
| DI-04 | `getBookingById()` omits `availability_slots(starts_at)` join used by list queries | `lib/features/booking/services/booking_service.dart:168-204`, `lib/features/booking/services/booking_service.dart:277-285`, `lib/features/booking/models/booking_model.dart:60-64`, `lib/features/booking/viewmodels/booking_view_model.dart:314-331` | Medium | Refresh may drop `scheduledAt` in in-memory items. |
| DI-05 | Booking model substitutes null `slot_id` with zero UUID sentinel | `lib/features/booking/models/booking_model.dart:48-51` | Medium | Masks bad data and propagates fake identifier. |
| DI-06 | UI and VM allow default price fallback `100.0`; tests encode this behavior | `lib/features/booking/view/booking_sheet.dart:88-103`, `lib/features/booking/viewmodels/booking_view_model.dart:205-229`, `test/unit/booking/booking_view_model_test.dart:225-273` | Medium | Wrong amount can be charged if parsing/upstream data fails. |
| DI-07 | Add-slot end time picker can construct invalid hour (`base.hour + 1`) | `lib/features/booking/view/add_slot_sheet.dart:47-60` | Medium | Edge-case runtime assertion around 23:xx start times. |
| DI-08 | Ledger SQL reads `bookings.amount_gross`, while app booking model/service uses `price` | `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:1015-1041`, `lib/features/booking/services/booking_service.dart:109-112`, `lib/features/booking/models/booking_model.dart:55-57` | Medium | Column mapping/schema compatibility is UNVERIFIED in repo snapshot. |
| ARCH-01 | Booking service mixes persistence with notification and ledger side effects | `lib/features/booking/services/booking_service.dart:20-20`, `lib/features/booking/services/booking_service.dart:125-134`, `lib/features/booking/services/booking_service.dart:249-273`, `lib/features/booking/services/booking_service.dart:287-337` | Medium | Harder to test/rollback/compose failures. |
| ARCH-02 | Booking details view duplicates action gating (manual status checks + `UnifiedCtaResolver`) | `lib/features/booking/view/booking_details_screen.dart:50-83`, `lib/features/booking/view/booking_details_screen.dart:212-301`, `lib/features/booking/view/booking_details_screen.dart:303-377` | Medium | Conflicting UI action logic risk. |
| ARCH-03 | Single global `BookingViewModel` holds unrelated slots/bookings/payment/chat state and is watched broadly | `lib/main.dart:144-151`, `lib/features/booking/viewmodels/booking_view_model.dart:90-101`, `lib/features/booking/viewmodels/booking_view_model.dart:414-520`, `lib/features/booking/viewmodels/booking_view_model.dart:644-680`, `lib/features/booking/view/availability_screen.dart:75-83`, `lib/features/booking/view/bookings_list_screen.dart:31-34`, `lib/features/booking/view/payment_method_screen.dart:60-63` | Medium | Rebuild coupling and state contention. |
| CQ-01 | Legacy `PaymentMethodScreen` still uses deprecated `processPayment()` path and `USD` currency | `lib/features/booking/view/payment_method_screen.dart:43-58`, `lib/features/booking/viewmodels/booking_view_model.dart:418-443` | Medium | Inconsistent with active QiCard flow. |
| CQ-02 | `_paymentFlowInProgress` is declared but never mutated, yet used in dispose cleanup condition | `lib/features/booking/view/payment_checkout_screen.dart:58-67`, `lib/features/booking/view/payment_checkout_screen.dart:69-89` | Medium | Dead flag/misleading cleanup logic. |
| CQ-03 | `releaseBookingWithFee()` does not notify listeners on success after list refresh | `lib/features/booking/viewmodels/booking_view_model.dart:340-366`, `lib/features/booking/viewmodels/booking_view_model.dart:314-338` | Medium | UI may not reflect success until later rebuild. |
| CQ-04 | `BookingSheet` stores package metadata inside freeform note string and dashboard widget parses it back | `lib/features/booking/view/booking_sheet.dart:69-103`, `lib/features/dashboard/view/widgets/booking_card.dart:34-48` | Low | Fragile implicit serialization contract. |
| CQ-05 | `BookingSheet` constructor carries unused identifiers (`slotId`, `providerId`, `taskId`) | `lib/features/booking/view/booking_sheet.dart:33-42`, `lib/features/booking/view/booking_sheet.dart:66-104` | Low | API drift / misleading dependencies. |
| PERF-01 | Client/provider booking tabs share one `bookingsLoading` and one `bookingsError` flag while loading in parallel | `lib/features/booking/view/bookings_list_screen.dart:24-28`, `lib/features/booking/view/bookings_list_screen.dart:59-75`, `lib/features/booking/viewmodels/booking_view_model.dart:95-101`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619` | High | Spinner/error bleed and pagination contention. |
| PERF-02 | Multiple screens use broad `context.watch<BookingViewModel>()` subscriptions | `lib/features/booking/view/availability_screen.dart:75-83`, `lib/features/booking/view/bookings_list_screen.dart:31-34`, `lib/features/booking/view/payment_method_screen.dart:60-63` | Medium | Rebuilds on unrelated state changes. |
| TEST-01 | Current repo shows only booking/model/demo-payment unit tests; no booking widget/integration/WebView/edge-function tests | `test/unit/booking/booking_view_model_test.dart:1-303`, `test/unit/models/booking_model_test.dart:1-49`, `test/unit/core/demo_payment_service_test.dart:1-80` | Medium | Coverage misses critical payment UI + webhook paths. |
| UNV-01 | Booking/slot/notification RLS policies and table schemas are not available in local migrations snapshot | UNVERIFIED (missing SQL files for `public.bookings`, `public.availability_slots`, `public.notifications`) | High | Cannot verify authz source of truth for these tables. |

## 3) Findings
### 3.1 Security (Highest Priority)
- `SEC-01` — Client-side QiCard credentials + direct gateway Basic Auth requests.
  - File Reference: `lib/core/services/qicard_payment_service.dart:24-36`, `lib/core/services/qicard_payment_service.dart:123-154`, `lib/core/services/qicard_payment_service.dart:386-411`, `lib/core/services/qicard_payment_service.dart:471-494`, `lib/core/services/qicard_payment_service.dart:551-569`.
  - Impact: Merchant credentials are recoverable from app builds and privileged gateway operations (refund/cancel/status) are callable from the client.
  - Exploit/Failure scenario: A reverse-engineered app build can replay merchant-authenticated requests or abuse refund/cancel/status endpoints without server mediation.
- `SEC-02` — Client triggers webhook endpoint directly for “success recovery”.
  - File Reference: `lib/features/booking/view/payment_checkout_screen.dart:216-225`, `lib/features/booking/viewmodels/booking_view_model.dart:505-520`, `lib/core/services/qicard_payment_service.dart:323-354`.
  - Impact: Client-originated requests target an endpoint that is also used for service-role ledger mutations.
  - Exploit/Failure scenario: A malicious client crafts repeated success payloads to probe for signature/config gaps or idempotency weaknesses.
- `SEC-03` + `SEC-04` — Webhook signature check is conditional and webhook runs with service role.
  - File Reference: `supabase/functions/qicard_webhook_handler/index.ts:48-57`, `supabase/functions/qicard_webhook_handler/index.ts:63-77`, `supabase/functions/qicard_webhook_handler/index.ts:170-176`, `supabase/functions/qicard_webhook_handler/index.ts:234-242`.
  - Impact: If `QICARD_RSA_PUBLIC_KEY_PEM` is unset/misconfigured, unsigned requests may reach privileged ledger RPC execution.
  - Exploit/Failure scenario: Public webhook receives forged `SUCCESS` payload and records `gateway_escrow` using service-role client if signature enforcement is bypassed.
- `SEC-05` — WebView callback success/failure trust is path-based, not host-allowlisted.
  - File Reference: `lib/features/booking/view/payment_webview_screen.dart:86-107`, `lib/features/booking/view/payment_webview_screen.dart:123-147`, `lib/features/booking/view/payment_webview_screen.dart:169-209`.
  - Impact: Any navigated page with matching path patterns may be treated as payment success/failure.
  - Exploit/Failure scenario: Redirect to an untrusted host path containing `/payment/success` causes the app to return `SUCCESS` and trigger recovery/polling.
- `SEC-06` — Client booking service writes cross-user notifications.
  - File Reference: `lib/features/booking/services/booking_service.dart:125-134`, `lib/features/booking/services/booking_service.dart:249-273`, `lib/features/notifications/services/notification_service.dart:69-94`.
  - Impact: Authorization correctness depends entirely on `notifications` RLS, and notification failures are swallowed.
  - Exploit/Failure scenario: If notifications insert policy is permissive, a client can send spoofed booking notifications; if strict, booking side effects silently fail.
- `SEC-07` — Booking draft insert trusts client payload fields before server validation.
  - File Reference: `lib/features/booking/services/booking_service.dart:84-123`.
  - Impact: Provider/slot/amount tampering risk exists unless DB constraints/RLS/trigger validation enforce authoritative values.
  - Exploit/Failure scenario: Modified client sends mismatched `provider_id` or `price` for a slot/task pairing.
  - UNVERIFIED source-of-truth status: `UNV-01` (missing booking/slot policy/schema SQL files in repo snapshot).

### 3.2 Data Integrity
- `DI-01` — `markDelivered()` performs duplicate status updates.
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:399-408`, `lib/features/booking/data/booking_repository.dart:138-140`, `lib/features/booking/services/booking_service.dart:339-344`.
  - Impact: Duplicate write path can duplicate side effects (including notifications via `updateBookingStatus`) and produce inconsistent timing.
- `DI-02` — Decline/refund path is non-atomic.
  - File Reference: `lib/features/booking/services/booking_service.dart:316-337`.
  - Impact: Status can change before refund RPC succeeds, leaving booking/payment state inconsistent.
- `DI-03` — VM comments claim atomic decline via RPC, but implementation is sequential.
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:381-392`, `lib/features/booking/services/booking_service.dart:316-337`.
  - Impact: Maintainers may rely on a non-existent atomicity guarantee and skip compensating error handling.
- `DI-04` — List refresh path may lose `scheduledAt` because `getBookingById()` omits slot join.
  - File Reference: `lib/features/booking/services/booking_service.dart:168-204`, `lib/features/booking/services/booking_service.dart:277-285`, `lib/features/booking/models/booking_model.dart:60-64`, `lib/features/booking/viewmodels/booking_view_model.dart:314-331`.
  - Impact: Booking detail/list cards may show missing schedule after actions that refresh a booking row.
- `DI-05` — Null `slot_id` is masked with zero UUID sentinel.
  - File Reference: `lib/features/booking/models/booking_model.dart:48-51`.
  - Impact: Corrupted/malformed data is hidden and may drive UI/actions with a fake identifier.
- `DI-06` — Default price fallback (`100.0`) is encoded in UI/VM/tests.
  - File Reference: `lib/features/booking/view/booking_sheet.dart:88-103`, `lib/features/booking/viewmodels/booking_view_model.dart:205-229`, `test/unit/booking/booking_view_model_test.dart:225-273`.
  - Impact: Wrong price can be charged or recorded when package price parsing fails.
- `DI-07` — End-time picker hour overflow edge case.
  - File Reference: `lib/features/booking/view/add_slot_sheet.dart:47-60`.
  - Impact: Runtime assertion/crash possible when start time hour is `23`.
- `DI-08` — `price` vs `amount_gross` schema drift risk remains unresolved in repo snapshot.
  - File Reference: `lib/features/booking/services/booking_service.dart:99-112`, `lib/features/booking/models/booking_model.dart:55-57`, `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:1015-1041`.
  - Impact: Ledger checks may fail or process incorrect amounts if DB column mapping is not aligned.
  - UNVERIFIED source-of-truth status: `UNV-01` (booking table schema migration not available locally).

### 3.3 Architecture
- `ARCH-01` — `BookingService` is not a pure data-access service; it orchestrates notifications and ledger side effects.
  - File Reference: `lib/features/booking/services/booking_service.dart:10-12`, `lib/features/booking/services/booking_service.dart:20-20`, `lib/features/booking/services/booking_service.dart:125-134`, `lib/features/booking/services/booking_service.dart:249-273`, `lib/features/booking/services/booking_service.dart:287-337`.
  - Impact: Hard to test and recover from partial failures; responsibility boundaries drift from MVVM/service intent.
- `ARCH-02` — `BookingDetailsScreen` contains overlapping action-policy logic in the view layer.
  - File Reference: `lib/features/booking/view/booking_details_screen.dart:50-83`, `lib/features/booking/view/booking_details_screen.dart:212-301`, `lib/features/booking/view/booking_details_screen.dart:303-377`.
  - Impact: UI can expose inconsistent actions when manual status checks and resolver outputs diverge.
- `ARCH-03` — One global `BookingViewModel` mixes slots/bookings/payment/chat state and is widely watched.
  - File Reference: `lib/main.dart:144-151`, `lib/features/booking/viewmodels/booking_view_model.dart:90-101`, `lib/features/booking/viewmodels/booking_view_model.dart:414-520`, `lib/features/booking/viewmodels/booking_view_model.dart:644-680`, `lib/features/booking/view/availability_screen.dart:75-83`, `lib/features/booking/view/bookings_list_screen.dart:31-34`, `lib/features/booking/view/payment_method_screen.dart:60-63`.
  - Impact: State changes in one flow (for example payment/chat) can rebuild unrelated booking screens and complicate testing.
- `ARCH-04` — Hidden concrete dependency (`NotificationService`) in `BookingService` reduces DI/test control.
  - File Reference: `lib/features/booking/services/booking_service.dart:20-20`.
  - Impact: Notification failure modes cannot be isolated cleanly in unit tests without service refactor.

### 3.4 Code Quality
- `CQ-01` — `PaymentMethodScreen` is legacy/duplicate flow (`processPayment`, USD) while active checkout uses QiCard WebView path.
  - File Reference: `lib/features/booking/view/payment_method_screen.dart:43-58`, `lib/features/booking/view/payment_method_screen.dart:60-120`, `lib/features/booking/view/payment_checkout_screen.dart:135-262`, `lib/features/booking/viewmodels/booking_view_model.dart:418-443`.
  - Impact: Confuses maintenance and risks accidental routing into obsolete payment behavior.
  - Usage status: candidate likely unused; see Section 4 for confirmation method.
- `CQ-02` — `_paymentFlowInProgress` dead flag is never mutated.
  - File Reference: `lib/features/booking/view/payment_checkout_screen.dart:58-67`, `lib/features/booking/view/payment_checkout_screen.dart:69-89`.
  - Impact: Dispose cleanup comments/conditions do not reflect actual runtime state.
- `CQ-03` — `releaseBookingWithFee()` success path does not notify listeners after refresh.
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:340-366`, `lib/features/booking/viewmodels/booking_view_model.dart:314-338`.
  - Impact: UI may not refresh after successful release unless another state change occurs.
- `CQ-04` — Metadata is serialized into booking note text, then parsed in dashboard booking widget.
  - File Reference: `lib/features/booking/view/booking_sheet.dart:69-103`, `lib/features/dashboard/view/widgets/booking_card.dart:34-48`.
  - Impact: Fragile cross-feature parsing contract and presentation drift risk.
- `CQ-05` — `BookingSheet` accepts identifiers it does not use.
  - File Reference: `lib/features/booking/view/booking_sheet.dart:33-42`, `lib/features/booking/view/booking_sheet.dart:66-104`.
  - Impact: API surface is misleading and increases coupling without behavior.
- `CQ-06` — `contactProvider()` method takes `currentUserId` parameter but does not use it.
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:650-680`.
  - Impact: Misleading method contract and dead parameter.

### 3.5 Performance
- `PERF-01` — Shared `bookingsLoading`/`bookingsError` flags serve both tabs while both loads run concurrently.
  - File Reference: `lib/features/booking/view/bookings_list_screen.dart:24-28`, `lib/features/booking/view/bookings_list_screen.dart:59-75`, `lib/features/booking/viewmodels/booking_view_model.dart:95-101`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`.
  - Impact: Loading/error state leaks across tabs and pagination operations contend on a shared lock.
- `PERF-02` — Broad `context.watch<BookingViewModel>()` usage increases rebuild scope.
  - File Reference: `lib/features/booking/view/availability_screen.dart:75-83`, `lib/features/booking/view/bookings_list_screen.dart:31-34`, `lib/features/booking/view/payment_method_screen.dart:60-63`.
  - Impact: Unrelated state changes trigger full screen rebuilds.
- `PERF-03` — Duplicate status write on `markDelivered()` creates unnecessary network/DB work.
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:399-408`, `lib/features/booking/services/booking_service.dart:339-344`.
  - Impact: Extra mutation and side-effect overhead for a single user action.
- `PERF-04` — Payment polling loop has no explicit lifecycle cancellation token.
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:243-272`, `lib/features/booking/view/payment_checkout_screen.dart:99-133`.
  - Impact: Repeated fetches can continue until timeout even after UX state changes.

### 3.6 Testing Gaps
- `TEST-01` — Current booking coverage is unit-only (VM/model/demo payment).
  - File Reference: `test/unit/booking/booking_view_model_test.dart:1-303`, `test/unit/models/booking_model_test.dart:1-49`, `test/unit/core/demo_payment_service_test.dart:1-80`.
  - Impact: Critical UI/payment/webview/webhook paths are untested.
- Missing widget tests (UNVERIFIED by absence search output; expected files not present):
  - `test/widget/booking/availability_screen_test.dart` (missing)
  - `test/widget/booking/bookings_list_screen_test.dart` (missing)
  - `test/widget/booking/booking_details_screen_test.dart` (missing)
  - `test/widget/booking/payment_checkout_screen_test.dart` (missing)
  - `test/widget/booking/payment_webview_screen_test.dart` (missing)
- Missing edge-function tests (UNVERIFIED by absence search in `supabase/functions/qicard_webhook_handler/`):
  - No `Deno.test` cases found for `supabase/functions/qicard_webhook_handler/index.ts`.
- Missing DB contract tests (UNVERIFIED due `UNV-01`):
  - No local SQL policy verification artifacts for `bookings`, `availability_slots`, `notifications` tables in current snapshot.

## 4) Dead/Unused Code Candidates
- Candidate: `PaymentMethodScreen` likely unused in current booking flow.
  - File Reference: `lib/features/booking/view/payment_method_screen.dart:11-120`.
  - Why candidate: Active booking checkout path routes through `PaymentCheckoutScreen` + `PaymentWebViewScreen` (`lib/features/booking/view/availability_screen.dart:274-290`, `lib/features/booking/view/payment_checkout_screen.dart:170-231`).
  - How to confirm: run `rg -n "PaymentMethodScreen\\(" lib -g '*.dart'` and verify no call sites outside declaration (absence claim should be verified in current branch).
- Candidate: `BookingViewModel.processPayment()` is legacy-only if `PaymentMethodScreen` is removed.
  - File Reference: `lib/features/booking/viewmodels/booking_view_model.dart:418-443`, `lib/features/booking/view/payment_method_screen.dart:43-58`.
  - Why candidate: Current booking checkout uses `initiateQiCardPayment()` + WebView recovery/polling path (`lib/features/booking/view/payment_checkout_screen.dart:170-231`, `lib/features/booking/viewmodels/booking_view_model.dart:477-520`).
  - How to confirm: run `rg -n "\.processPayment\(|processPayment\(" lib/features/booking test -g '*.dart'` and review remaining consumers.
- Candidate: `_paymentFlowInProgress` dead state flag.
  - File Reference: `lib/features/booking/view/payment_checkout_screen.dart:58-67`, `lib/features/booking/view/payment_checkout_screen.dart:69-89`.
  - Why candidate: Declared/read but never mutated.
  - How to confirm: run `rg -n "_paymentFlowInProgress" lib/features/booking/view/payment_checkout_screen.dart`.
- Candidate: `BookingSheet` input fields `slotId`, `providerId`, `taskId` are unused.
  - File Reference: `lib/features/booking/view/booking_sheet.dart:33-42`, `lib/features/booking/view/booking_sheet.dart:66-104`.
  - Why candidate: Not read by current sheet logic.
  - How to confirm: search local identifier usage inside file.
- Candidate: `BookingService.bookSlot()` alias may be redundant wrapper over `createBookingDraft()`.
  - File Reference: `lib/features/booking/services/booking_service.dart:138-159`.
  - Why candidate: Pure alias with duplicated parameter surface.
  - How to confirm: inspect call sites and decide whether backward compatibility is required (`lib/features/booking/data/booking_repository.dart:48-68`, `lib/features/booking/viewmodels/booking_view_model.dart:195-229`).

## 5) Duplicate Code Candidates
- Booking status labels/colors duplicated across booking UI and dashboard UI.
  - File Reference: `lib/features/booking/view/booking_details_screen.dart:390-467`, `lib/features/booking/view/widgets/booking_card.dart:141-212`, `lib/features/dashboard/view/widgets/booking_card.dart:50-85`.
  - Proposed shared abstraction:
    - `lib/features/booking/presentation/booking_status_presenter.dart` (status label/color helpers)
    - `lib/features/booking/view/widgets/booking_status_badge.dart` (shared visual badge)
- Booking action gating duplicated in `BookingDetailsScreen` (manual checks + `UnifiedCtaResolver`).
  - File Reference: `lib/features/booking/view/booking_details_screen.dart:50-83`, `lib/features/booking/view/booking_details_screen.dart:212-301`, `lib/features/booking/view/booking_details_screen.dart:303-377`.
  - Proposed shared abstraction:
    - `lib/features/booking/presentation/booking_action_policy.dart` or move fully to `UnifiedCtaResolver` adapter with typed booking action outputs.
- Booking note metadata write/parse duplicated across feature and dashboard widget.
  - File Reference: `lib/features/booking/view/booking_sheet.dart:69-103`, `lib/features/dashboard/view/widgets/booking_card.dart:34-48`.
  - Proposed shared abstraction:
    - `lib/features/booking/utils/booking_note_metadata_codec.dart` (temporary until structured DB field exists).
- Time range formatting duplicated across booking checkout/sheet.
  - File Reference: `lib/features/booking/view/booking_sheet.dart:57-64`, `lib/features/booking/view/payment_checkout_screen.dart:264-271`.
  - Proposed shared abstraction:
    - `lib/features/booking/utils/booking_time_formatter.dart` (or extend `lib/core/utils/format_date.dart`).
- Booking create APIs duplicated (`bookSlot` vs `createBookingDraft`) across service/repository/VM layers.
  - File Reference: `lib/features/booking/services/booking_service.dart:84-159`, `lib/features/booking/data/booking_repository.dart:48-90`, `lib/features/booking/viewmodels/booking_view_model.dart:195-229`, `lib/features/booking/viewmodels/booking_view_model.dart:445-475`.
  - Proposed shared abstraction:
    - Keep one canonical command (`createBookingDraft`) and remove/compat-wrap the alias.

## 6) Refactor Plan (Exact Paths)
- Split booking service responsibilities (queries vs commands vs payment orchestration).
  - Current source to split: `lib/features/booking/services/booking_service.dart:1-376`.
  - New paths:
    - `lib/features/booking/services/booking_query_service.dart`
    - `lib/features/booking/services/booking_command_service.dart`
    - `lib/features/booking/services/booking_payment_service.dart`
    - `lib/features/booking/services/booking_notification_service.dart` (temporary client impl only until backend migration)
  - Migration strategy:
    - Keep `lib/features/booking/services/booking_service.dart` as facade/compat wrapper during transition; delete after all callers are migrated.
- Split `BookingViewModel` by state domain to remove shared loading/error contention.
  - Current source: `lib/features/booking/viewmodels/booking_view_model.dart:90-681`.
  - New paths:
    - `lib/features/booking/viewmodels/booking_slots_view_model.dart`
    - `lib/features/booking/viewmodels/booking_list_view_model.dart`
    - `lib/features/booking/viewmodels/booking_checkout_view_model.dart`
    - `lib/features/booking/viewmodels/booking_actions_view_model.dart`
  - Migration strategy:
    - Add new providers incrementally; keep `BookingViewModel` delegating to extracted classes until screens are migrated.
- Split `BookingDetailsScreen` into screen + sections + action panel.
  - Current source: `lib/features/booking/view/booking_details_screen.dart:20-515`.
  - New paths:
    - `lib/features/booking/view/details/booking_details_screen.dart`
    - `lib/features/booking/view/details/widgets/booking_status_banner.dart`
    - `lib/features/booking/view/details/widgets/booking_summary_section.dart`
    - `lib/features/booking/view/details/widgets/booking_counterparty_section.dart`
    - `lib/features/booking/view/details/widgets/booking_actions_panel.dart`
  - Migration strategy:
    - Keep a forwarding export at `lib/features/booking/view/booking_details_screen.dart` until all imports are updated.
- Split payment checkout UI from flow controller logic.
  - Current source: `lib/features/booking/view/payment_checkout_screen.dart:51-590`.
  - New paths:
    - `lib/features/booking/view/payment/payment_checkout_screen.dart`
    - `lib/features/booking/view/payment/controllers/payment_checkout_flow_controller.dart`
    - `lib/features/booking/view/payment/widgets/payment_order_summary_card.dart`
    - `lib/features/booking/view/payment/widgets/payment_gateway_status_view.dart`
  - Migration strategy:
    - Keep `lib/features/booking/view/payment_checkout_screen.dart` as temporary re-export wrapper.
- Centralize booking status and note metadata presentation.
  - New paths:
    - `lib/features/booking/presentation/booking_status_presenter.dart`
    - `lib/features/booking/utils/booking_note_metadata_codec.dart`
    - `lib/features/booking/view/widgets/booking_status_badge.dart`
  - Consumers to migrate:
    - `lib/features/booking/view/widgets/booking_card.dart`
    - `lib/features/booking/view/booking_details_screen.dart` (or new moved path)
    - `lib/features/dashboard/view/widgets/booking_card.dart`
- Remove legacy payment method screen after confirmation.
  - Candidate file to delete (after call-site verification): `lib/features/booking/view/payment_method_screen.dart`
  - Compatibility strategy:
    - If route exists externally, replace with redirect to `PaymentCheckoutScreen` first, then remove route.

## 7) Fix Plan (Phases)
Phase 1: Critical security & correctness
- Item 1: Move QiCard privileged API calls server-side only (create/refund/cancel/status).
  - What to change:
    - Stop sending merchant Basic Auth requests from Flutter client.
    - Replace direct QiCard HTTP calls with authenticated app backend/edge-function proxy calls.
  - Exact file(s) to edit/create:
    - Edit `lib/core/services/qicard_payment_service.dart`
    - Edit `lib/main.dart` (feature-flag wiring only if needed)
    - Create `supabase/functions/qicard_payment_proxy/index.ts` (or separate create/refund/cancel/status functions)
    - Create `supabase/functions/qicard_payment_proxy/deno.json`
  - Acceptance criteria:
    - No `QICARD_USERNAME`, `QICARD_PASSWORD`, or `Authorization: Basic` usage remains in Flutter client (`rg` check passes).
    - Booking checkout still returns a form URL in QiCard mode through server proxy.
- Item 2: Separate client recovery endpoint from QiCard webhook endpoint.
  - What to change:
    - Remove client POST-to-webhook recovery path.
    - Add authenticated recovery endpoint that verifies user owns the booking and validates payment status server-side before ledger action.
  - Exact file(s) to edit/create:
    - Edit `lib/core/services/qicard_payment_service.dart`
    - Edit `lib/features/booking/view/payment_checkout_screen.dart`
    - Edit `lib/features/booking/viewmodels/booking_view_model.dart`
    - Edit `supabase/functions/qicard_webhook_handler/index.ts`
    - Create `supabase/functions/qicard_payment_recovery/index.ts`
  - Acceptance criteria:
    - Client no longer calls `qicard_webhook_handler` directly.
    - Recovery endpoint rejects bookings not owned by caller.
- Item 3: Make webhook signature verification fail-closed for deployed environments.
  - What to change:
    - Require signature verification for QiCard payment payloads when function is not running in explicit local-dev mode.
    - Remove permissive `ENVIRONMENT == production` string dependency or replace with explicit `ALLOW_UNSIGNED_QICARD_WEBHOOK=false` flag default.
  - Exact file(s) to edit/create:
    - Edit `supabase/functions/qicard_webhook_handler/index.ts`
  - Acceptance criteria:
    - Unsigned `SUCCESS` payload is rejected in staging/prod.
    - Signed payload still processes successfully.
- Item 4: Harden WebView callback trust (host allowlist + correlation checks).
  - What to change:
    - Accept only configured callback hosts/paths and validate `paymentId`/`requestId` correlation before treating navigation as success.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/view/payment_webview_screen.dart`
    - Edit `lib/features/booking/view/payment_checkout_screen.dart`
  - Acceptance criteria:
    - Untrusted host with `/payment/success` does not produce `SUCCESS`.
    - Valid QiCard callback still completes flow.
- Item 5: Fix duplicate `markDelivered()` write.
  - What to change:
    - Ensure `markDelivered()` performs one repository/service mutation only and refreshes local state once.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/viewmodels/booking_view_model.dart`
    - Add/update unit tests in `test/unit/booking/booking_view_model_test.dart`
  - Acceptance criteria:
    - One mutation call per tap.
    - No duplicate notification side-effect from delivery status update.
- Item 6: Make decline/refund flow atomic (server-side RPC) or explicit compensating rollback.
  - What to change:
    - Replace sequential `updateBookingStatus` + `refund` with one RPC/function handling both transition and ledger refund under transaction lock.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/services/booking_service.dart`
    - Edit `lib/features/booking/data/booking_repository.dart`
    - Edit `lib/features/booking/viewmodels/booking_view_model.dart`
    - Create migration `supabase/migrations/<timestamp>_booking_decline_refund_rpc.sql`
  - Acceptance criteria:
    - No state where booking is declined/canceled while payment remains held after a failed decline action.
- Item 7: Remove silent cross-user notification creation from booking client path (or lock it down behind server-side eventing).
  - What to change:
    - Prefer DB triggers or secure server-side notification dispatch after booking state transitions.
    - At minimum, make client-side notification failures visible in observability and non-authoritative for core flow.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/services/booking_service.dart`
    - Edit `lib/features/notifications/services/notification_service.dart`
    - Create migration/function for server-side notifications (path depends on chosen approach)
  - Acceptance criteria:
    - Booking actions succeed/fail independently of notification delivery.
    - Notification authorization is enforced server-side or by verified RLS contract.
- Item 8: Validate booking amount/provider/slot consistency server-side.
  - What to change:
    - Enforce authoritative pricing/provider derivation from slot/task on insert path (trigger/RPC/constraint).
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/services/booking_service.dart` (client path to call validated RPC if introduced)
    - Create migration `supabase/migrations/<timestamp>_booking_insert_validation.sql`
  - Acceptance criteria:
    - Tampered `provider_id`/`price` payloads are rejected.
  - UNVERIFIED precondition:
    - Requires booking table schema/policy SQL not present in current snapshot (`UNV-01`).

Phase 2: Refactor/structure
- Item 1: Split `BookingService` by responsibility.
  - What to change: move query/command/payment/notification logic into separate services.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/services/booking_service.dart`
    - Create `lib/features/booking/services/booking_query_service.dart`
    - Create `lib/features/booking/services/booking_command_service.dart`
    - Create `lib/features/booking/services/booking_payment_service.dart`
    - Create `lib/features/booking/services/booking_notification_service.dart`
  - Acceptance criteria:
    - `booking_service.dart` facade contains composition only (or is removed).
- Item 2: Split global `BookingViewModel` into domain-specific VMs.
  - What to change: isolate slots/list/checkout/actions state and flags.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/viewmodels/booking_view_model.dart`
    - Create `lib/features/booking/viewmodels/booking_slots_view_model.dart`
    - Create `lib/features/booking/viewmodels/booking_list_view_model.dart`
    - Create `lib/features/booking/viewmodels/booking_checkout_view_model.dart`
    - Create `lib/features/booking/viewmodels/booking_actions_view_model.dart`
    - Edit provider wiring in `lib/main.dart`
  - Acceptance criteria:
    - Client/provider tab loading state is isolated.
- Item 3: Consolidate booking action policy/status presentation.
  - What to change: remove duplicated status/action logic from `BookingDetailsScreen` and widgets.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/view/booking_details_screen.dart`
    - Edit `lib/features/booking/view/widgets/booking_card.dart`
    - Edit `lib/features/dashboard/view/widgets/booking_card.dart`
    - Create `lib/features/booking/presentation/booking_status_presenter.dart`
    - Create `lib/features/booking/presentation/booking_action_policy.dart`
  - Acceptance criteria:
    - One shared source of status labels/colors and action rules.
- Item 4: Remove or redirect legacy `PaymentMethodScreen`.
  - What to change: delete unused screen or keep a redirect wrapper to current checkout flow.
  - Exact file(s) to edit/create:
    - Edit/Delete `lib/features/booking/view/payment_method_screen.dart`
    - Edit route/call sites if any are found
  - Acceptance criteria:
    - No dead payment flow remains in booking feature.

Phase 3: Tests
- Item 1: Add booking widget tests for critical UI flows.
  - What to change: add widget tests for availability, booking list tabs, detail actions, checkout error states.
  - Exact file(s) to edit/create:
    - Create `test/widget/booking/availability_screen_test.dart`
    - Create `test/widget/booking/bookings_list_screen_test.dart`
    - Create `test/widget/booking/booking_details_screen_test.dart`
    - Create `test/widget/booking/payment_checkout_screen_test.dart`
    - Create `test/widget/booking/payment_webview_screen_test.dart`
  - Acceptance criteria:
    - Tests cover self-booking guard, tab loading separation, action rendering, callback spoof rejection behavior (mocked).
- Item 2: Extend unit tests for integrity regressions.
  - What to change: add tests for duplicate `markDelivered`, release success UI notify, add-slot edge hour overflow handling, no default price fallback policy (if behavior changed).
  - Exact file(s) to edit/create:
    - Edit `test/unit/booking/booking_view_model_test.dart`
    - Edit/Create `test/unit/models/booking_model_test.dart`
    - Create `test/unit/booking/add_slot_sheet_logic_test.dart` (or widget test only)
  - Acceptance criteria:
    - Regressions fail tests before fix and pass after fix.
- Item 3: Add edge-function tests for webhook/recovery security.
  - What to change: add `Deno.test` coverage for signature enforcement, invalid booking IDs, idempotent replay.
  - Exact file(s) to edit/create:
    - Create `supabase/functions/qicard_webhook_handler/index_test.ts`
    - Create `supabase/functions/qicard_payment_recovery/index_test.ts` (if recovery function added)
  - Acceptance criteria:
    - Unsigned success payload rejection is tested.
- Item 4: Add DB contract checks for booking/slot/notification RLS.
  - What to change: add SQL assertions or documented test scripts.
  - Exact file(s) to edit/create:
    - Create `supabase/tests/booking_rls_contract.sql` (or project-equivalent path)
    - Create `supabase/tests/notifications_rls_contract.sql`
  - Acceptance criteria:
    - Participant-only access and no arbitrary cross-user notification insert are verified.
  - UNVERIFIED precondition:
    - Requires missing schema/policy SQL definitions (`UNV-01`).

Phase 4: Polish/perf
- Item 1: Reduce rebuild scope with selectors and narrower consumers.
  - What to change: replace broad `context.watch<BookingViewModel>()` reads with `context.select`/smaller widgets.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/view/availability_screen.dart`
    - Edit `lib/features/booking/view/bookings_list_screen.dart`
    - Edit `lib/features/booking/view/payment_method_screen.dart` (if retained)
  - Acceptance criteria:
    - Screens rebuild only when relevant substate changes.
- Item 2: Replace note metadata string encoding with structured fields (or typed metadata map).
  - What to change: stop parsing `Package:`/`---` strings in UI widgets.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/view/booking_sheet.dart`
    - Edit `lib/features/dashboard/view/widgets/booking_card.dart`
    - Edit `lib/features/booking/models/booking_model.dart`
    - Create DB migration if storing structured metadata separately
  - Acceptance criteria:
    - UI displays package note data without string parsing heuristics.
- Item 3: Improve action UX feedback in booking details.
  - What to change: disable buttons during action execution; show success/error states consistently.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/view/booking_details_screen.dart`
    - Edit `lib/features/booking/viewmodels/booking_view_model.dart` (or new actions VM)
  - Acceptance criteria:
    - No repeated taps during in-flight action; failures are visible.
- Item 4: Normalize time formatting usage.
  - What to change: replace local `_fmtRange` duplicates with shared formatter.
  - Exact file(s) to edit/create:
    - Edit `lib/features/booking/view/booking_sheet.dart`
    - Edit `lib/features/booking/view/payment_checkout_screen.dart`
    - Create/Edit `lib/features/booking/utils/booking_time_formatter.dart` (or `lib/core/utils/format_date.dart`)
  - Acceptance criteria:
    - Booking time strings are consistent across booking UI surfaces.

## 8) Verification Checklist
### Commands
- Static analysis (audited scope)
```bash
flutter analyze lib/features/booking \
  lib/core/services/qicard_payment_service.dart \
  lib/features/wallet/services/ledger_service.dart \
  lib/features/notifications/services/notification_service.dart \
  lib/features/chat/data/chat_repository.dart
```
- Run booking-related tests (existing + new)
```bash
flutter test test/unit/booking test/unit/models test/widget/booking
```
- Run edge function tests (after added)
```bash
deno test supabase/functions/qicard_webhook_handler supabase/functions/qicard_payment_recovery
```
- Secret/privileged-client regression checks (client code must not contain these after fix)
```bash
rg -n "QICARD_PASSWORD|QICARD_USERNAME|Authorization': 'Basic|SUPABASE_SERVICE_ROLE_KEY" lib -g '*.dart'
```
- Webhook endpoint misuse check (client must not call webhook directly after fix)
```bash
rg -n "qicard_webhook_handler" lib -g '*.dart'
```
- Duplicate status write regression check (`markDelivered` path)
```bash
rg -n "markDelivered\(|updateBookingStatus\(" lib/features/booking/viewmodels/booking_view_model.dart
```
- RLS/schema evidence check (current repo snapshot gap)
```bash
rg -n "CREATE POLICY .*bookings|ON public\.bookings|availability_slots|notifications" supabase/migrations -g '*.sql'
```

### Manual Scenarios
- Booking discovery -> task -> availability -> checkout flow.
  - Verify entry path from booking tab still loads (`lib/app/main_navigation_screen.dart:38-49`, `lib/features/booking/view/bookings_discovery_screen.dart:13-135`).
- Provider availability screen (own profile).
  - Verify add-slot button is enabled only for owner and self-booking CTA is disabled after fix (`lib/features/booking/view/availability_screen.dart:79-90`, `lib/features/booking/view/availability_screen.dart:248-297`).
- Client checkout success.
  - Verify draft creation, gateway navigation, callback handling, and held status update (`lib/features/booking/view/payment_checkout_screen.dart:143-231`, `lib/features/booking/view/payment_webview_screen.dart:76-150`, `lib/features/booking/viewmodels/booking_view_model.dart:243-272`).
- Callback spoof attempt.
  - Navigate to non-allowlisted URL path matching `/payment/success`; verify no success state after fix (`lib/features/booking/view/payment_webview_screen.dart:95-147`).
- Provider decline with held funds.
  - Verify one atomic decline/refund result; no partial status/payment mismatch (`lib/features/booking/services/booking_service.dart:316-337`).
- Provider mark delivered.
  - Verify single mutation/no duplicate notification after fix (`lib/features/booking/viewmodels/booking_view_model.dart:399-408`).
- Client release funds.
  - Verify UI refreshes immediately on success (`lib/features/booking/viewmodels/booking_view_model.dart:340-366`).
- Booking list tabs.
  - Verify client/provider tab loading/error states are isolated after refactor (`lib/features/booking/view/bookings_list_screen.dart:24-75`, `lib/features/booking/viewmodels/booking_view_model.dart:523-619`).
- Add-slot edge case at 23:xx.
  - Verify no time picker assertion (`lib/features/booking/view/add_slot_sheet.dart:47-60`).

### Supabase/RLS Contract Checks
- `UNVERIFIED` in current repo snapshot: booking/slot/notification RLS policies and table schemas (`UNV-01`).
  - Missing files to validate:
    - SQL migration(s) defining `public.bookings` table + policies
    - SQL migration(s) defining `public.availability_slots` table + policies
    - SQL migration(s) defining `public.notifications` policies
- Validate ledger RPC contract already present in repo:
  - `gateway_escrow` is system-only in function body (`supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:992-1003`).
  - `process_payment_event_ledger` execute is granted to `authenticated` and `service_role` (`supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql:24-42`).
  - Implication to verify after fixes: client must not be able to reach `gateway_escrow` through webhook/recovery path without signature/auth (`supabase/functions/qicard_webhook_handler/index.ts:149-188`, `supabase/functions/qicard_webhook_handler/index.ts:190-258`).
- Booking insert/update authz checks (source of truth must be RLS / secure RPC):
  - Verify participants only can read/write booking rows.
  - Verify slot ownership on slot create/update.
  - Verify client cannot insert arbitrary `provider_id`/`price` without DB validation.
  - Verify client cannot insert notifications for arbitrary `user_id` unless intentionally permitted and audited.

## 9) Risks & Rollback Notes
- What could break
  - Payment flow behavior can break across app + edge function + ledger RPC if deployed partially (`lib/features/booking/view/payment_checkout_screen.dart:135-262`, `lib/core/services/qicard_payment_service.dart:75-198`, `supabase/functions/qicard_webhook_handler/index.ts:190-258`, `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:990-1115`).
  - Tightening webhook signature enforcement can block legitimate QiCard callbacks if signature string/key configuration does not match provider payloads (`supabase/functions/qicard_webhook_handler/index.ts:63-88`, `supabase/functions/qicard_webhook_handler/index.ts:165-176`).
  - Removing client-side QiCard credentials/calls changes current feature-flag path selected in app startup (`lib/main.dart:46-59`).
  - Splitting the global booking VM can break provider wiring and screen assumptions (`lib/main.dart:144-151`, `lib/features/booking/view/availability_screen.dart:75-83`, `lib/features/booking/view/bookings_list_screen.dart:31-34`).
- Rollback steps
  - Keep changes staged by concern (client payment transport, webhook/recovery, booking lifecycle fix, refactor) so each can be reverted independently.
  - Preserve `USE_QICARD_PAYMENT` flag fallback path while server-side payment proxy stabilizes (`lib/main.dart:46-59`).
  - For webhook hardening rollouts, deploy with verified QiCard public key in non-prod first and monitor callback acceptance before production switch (`supabase/functions/qicard_webhook_handler/index.ts:52-53`, `supabase/functions/qicard_webhook_handler/index.ts:63-88`).
  - Maintain idempotency behavior during all payment-flow changes (ledger service + RPC idempotency key handling) (`lib/features/wallet/services/ledger_service.dart:13-30`, `supabase/functions/qicard_webhook_handler/index.ts:223-242`, `supabase/migrations/20260225_create_process_payment_event_ledger_rpc.sql:1004-1111`).
