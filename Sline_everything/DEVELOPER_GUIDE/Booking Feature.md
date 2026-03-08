# Booking Feature Reference

## 1. Human-Readable Overview

The booking feature currently supports direct service bookings with server-backed payment initiation and recovery.

Primary user flows:
- clients can purchase a booking package from a booking task
- providers can review booking requests, accept or decline them, and mark work as delivered
- clients can review details and approve release after delivery
- both sides can inspect booking history and the embedded management timeline

Important current behavior:
- slotless direct bookings are allowed multiple times for the same client/task pair
- slot-based rows still exist in the schema and UI as legacy/historical support
- QiCard is the default payment provider, but payment initiation and reconciliation are server-backed through Supabase edge functions

## 2. Supabase Mapping

### 2.1 Core tables

#### `public.bookings`

| Column | Type | Purpose / Usage | Notes |
| --- | --- | --- | --- |
| `id` | `uuid` | booking identifier | primary key |
| `task_id` | `uuid` | linked booking task | nullable in model but expected for current flow |
| `provider_id` | `uuid` | service provider | used for provider-side lists and RLS |
| `client_id` | `uuid` | booking client | used for client-side lists and RLS |
| `slot_id` | `uuid` | optional legacy slot link | nullable for direct slotless bookings |
| `status` | `booking_status_enum` | booking lifecycle | app maps `paid_request_pending`, `active`, `delivered`, `completed`, `canceled`, `refunded`, `expired_unanswered`, `no_show`, `disputed` |
| `payment_status` | `payment_status_enum` | payment lifecycle | `unpaid`, `held`, `released`, `refunded` |
| `price` | `numeric` | canonical amount | server-derived for booking drafts |
| `package_id` | `text` | selected package tier | optional |
| `requirements` | `jsonb` | selected package/request payload | optional |
| `note` | `text` | client note | optional |
| `delivery_days` | `integer` | delivery estimate | used in checkout/details timeline |
| `due_at` | `timestamptz` | due date | shown in booking details timeline |
| `completed_at` | `timestamptz` | completion timestamp | set when work is completed/released |
| `created_at` | `timestamptz` | audit timestamp | UTC |

#### `public.availability_slots`

This table still exists and is still documented in `SUPABASE_SETUP.md`, but the current Flutter booking flow no longer exposes slot-creation screens. Existing rows are treated as historical/legacy support, and `BookingModel` still reads slot timing when `slot_id` is present.

### 2.2 Payment and workflow backend objects

Current server-backed booking/payment flow depends on:
- `rpc_create_booking_draft_validated(...)`
- `qicard_payment_create`
- `qicard_payment_recovery`
- `booking_decline_refund`
- `rpc_submit_delivery`
- `rpc_approve_delivery`
- `process_payment_event_ledger(...)`
- `fn_booking_guard` — trigger enforcing status transitions (client cannot delivered→canceled; client can delivered→disputed; admin only disputed→completed/refunded; provider/admin active→no_show).
- `rpc_finalize_auto_approval` — booking branch calls ledger `release_with_fee` when review window expires.
- `admin_resolve_booking_dispute` — admin-only RPC to resolve disputed booking to completed or refunded.

### 2.3 RLS summary

- clients can see and mutate only their own bookings where allowed by policy
- providers can see and mutate their own incoming bookings where allowed by policy
- payment/ledger side effects are enforced server-side via RPCs and edge functions; the client is not authoritative for privileged transitions

## 3. File Inventory

| File | Layer | Description |
| --- | --- | --- |
| `lib/features/booking/models/booking_model.dart` | model | Typed booking row with UTC timestamps, payment status, due date, and legacy slot fallback parsing. |
| `lib/features/booking/models/payment_return_args.dart` | model | Feature re-export for the shared payment callback DTO. |
| `lib/features/booking/services/booking_service.dart` | service | Reads bookings, updates status, submits ledger-backed booking actions, fetches single booking rows. |
| `lib/features/booking/data/booking_repository.dart` | repository | Thin abstraction over `BookingService` plus current-user access. |
| `lib/features/booking/viewmodels/booking_view_model.dart` | viewmodel | Orchestrates booking lists, payment creation/recovery, delivery/release actions, and chat handoff. |
| `lib/features/booking/view/bookings_discovery_screen.dart` | view | Booking-task discovery surface powered by the home/task feed. |
| `lib/features/booking/view/payment_checkout_screen.dart` | view | Direct booking checkout screen; creates draft booking and launches payment flow. |
| `lib/features/booking/view/payment_webview_screen.dart` | view | Mobile webview payment container for trusted callback flows. |
| `lib/features/booking/view/payment_return_screen.dart` | view | Web callback landing screen that validates callback state and triggers recovery. |
| `lib/features/booking/view/payment_method_screen.dart` | view | Demo/manual payment form used by non-QiCard paths. |
| `lib/features/booking/view/bookings_list_screen.dart` | view | Client/provider booking history list with filtering and pagination. |
| `lib/features/booking/view/booking_details_screen.dart` | view | Detailed booking view with CTA resolution, management timeline, and message handoff. |
| `lib/features/booking/view/widgets/booking_card.dart` | widget | Shared summary card for booking rows. |

## 4. Current Flutter Flow

### 4.1 Checkout

1. A client opens a booking task and starts checkout.
2. `PaymentCheckoutScreen` calls `BookingViewModel.createPaymentForBooking(...)`.
3. `QiCardPaymentService` invokes `qicard_payment_create`.
4. The server validates the task/package/request payload, creates a canonical booking draft, and returns `booking_id`, `form_url`, and correlation identifiers.

### 4.2 Gateway handoff

- **Mobile**: `PaymentWebViewScreen` opens the payment URL and only accepts trusted callback hosts/booking identifiers.
- **Web**: checkout persists `PendingPaymentContext` through `PaymentPendingStore` and redirects the browser in the same tab.

### 4.3 Recovery

- When the gateway returns, the app uses `PaymentReturnArgs` plus stored pending context.
- `PaymentReturnScreen` or `PaymentCheckoutScreen` calls `recoverBookingPaymentWithRetries(...)`.
- Recovery succeeds only when the booking reaches `payment_status = held`.

### 4.4 Post-payment actions

Provider-side actions:
- accept booking
- decline/refund booking
- mark delivered

Client-side actions:
- release booking payment with fee handling
- message provider
- review timeline/history

`BookingDetailsScreen` also embeds `OrderManagementSection` with `WorkLogScope(entityId: booking.id, entityType: 'booking')`.

## 5. Example Snippets

### Create payment-backed booking draft

```dart
final result = await bookingViewModel.createPaymentForBooking(
  taskId: taskId,
  note: note,
  packageId: packageId,
  requirements: packageData,
);
```

### Recover payment after trusted callback

```dart
final recovery = await bookingViewModel.recoverBookingPaymentWithRetries(
  bookingId: bookingId,
);
```

### Load paged history

```dart
await bookingViewModel.loadBookingsAsClient();
await bookingViewModel.loadMoreBookingsAsProvider();
```

## 6. Error Handling and Notes

Current mapped booking/payment messages include:
- task not bookable
- self-booking forbidden
- invalid package
- slot unavailable
- booking create/recovery failure

Additional notes:
- the client can create repeat slotless direct bookings for the same service task
- slot exclusivity still applies to slot-based bookings through database constraints/policies
- `BookingModel.dueAtUtc` falls back to `availability_slots.starts_at` for historical slot-based rows
- `PaymentMethodScreen` remains in the repo for demo/manual payment paths, but QiCard is the default provider in `main.dart`

## 7. Testing Checklist

- create a booking draft for a booking task and verify checkout opens correctly
- on web, confirm same-tab redirect returns to `PaymentReturnScreen`
- on mobile, confirm `PaymentWebViewScreen` accepts only trusted callback URLs
- verify successful recovery reaches `payment_status = held`
- verify repeat slotless direct bookings for the same client/task pair are allowed
- verify provider can accept/decline/deliver and client can release after delivery
- verify booking details show due date, delivery days, and management timeline correctly
- verify legacy slot-based bookings still render safely when `slot_id` is present
