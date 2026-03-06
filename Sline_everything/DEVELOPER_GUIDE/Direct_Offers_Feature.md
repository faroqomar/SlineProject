# Direct Chat Offers Feature Reference (v2.17)

**Last Updated:** 2026-03-02

This document is the single reference for the Direct Chat Offers feature: chat-to-work offers created from a 1:1 conversation (no task or booking required). Client accepts in chat; payment is performed only from the Dashboard.

---

## 1. Human-Readable Overview

Direct Chat Offers let a freelancer send a priced offer from any 1:1 chat. The client accepts in chat (no payment there). The offer then appears in the **Dashboard as Pending Payment**. The client pays from the Dashboard via QiCard; after payment, the offer becomes Active and follows the same deliver/complete flow as bookings.

**Flow summary:**
1. **Create** — Freelancer creates offer in chat → row in `direct_offers` + offer message with `payload.offer_id`.
2. **Accept (chat only)** — Client taps **Accept** → status `accepted`, payment_status `unpaid`; no payment in chat.
3. **Dashboard** — Work item shows as **Pending Payment**; client taps **Pay & Confirm** → QiCard (WebView on mobile, browser on web).
4. **Recovery** — On return from gateway, `recoverPaymentAfterCallback` runs → ledger `escrow_hold` → status `active`, payment_status `held`.
5. **Deliver / Complete** — Freelancer Mark Delivered → client Approve & release → `release_with_fee` → status `completed`.

The feature follows MVVM: UI in `lib/features/direct_offers/view/`; `DirectOfferDetailsViewModel` and `DirectOffersService` hold logic; no Supabase calls from the view.

---

## 2. Database & Supabase Mapping

### 2.1 Table: `public.direct_offers`

| Column             | Type                    | Nullable | Default           | Description                          |
| ------------------ | ----------------------- | -------- | ----------------- | ------------------------------------ |
| `id`               | uuid                    | ❌       | `gen_random_uuid()` | Primary key                         |
| `conversation_id`   | uuid                    | ❌       | -                 | FK to conversations                  |
| `client_id`        | uuid                    | ❌       | -                 | FK to profiles (payer)               |
| `freelancer_id`    | uuid                    | ❌       | -                 | FK to profiles (offer creator)        |
| `task_id`          | uuid                    | ✅       | -                 | Optional FK to tasks                 |
| `title`            | text                    | ✅       | -                 | Optional summary                     |
| `description`      | text                    | ✅       | -                 | Scope/notes                          |
| `price`            | numeric                 | ❌       | -                 | Amount (IQD)                         |
| `days`             | int                     | ❌       | -                 | Delivery days                        |
| `status`           | text                    | ❌       | `'sent'`          | sent, accepted, rejected, active, delivered, completed, canceled, refunded |
| `payment_status`   | payment_status_enum     | ❌       | `'unpaid'`        | unpaid, held, released, refunded     |
| `created_at`       | timestamptz             | ❌       | `now()`           | Creation timestamp                   |
| `updated_at`       | timestamptz             | ❌       | `now()`           | Last update                          |

**Lifecycle:** `sent` → `accepted` (unpaid) → client pays from Dashboard (QiCard) → `active` (payment_status `held`) → `delivered` → `completed` (release_with_fee).

**Indexes:** `idx_direct_offers_conversation`, `idx_direct_offers_client_status`, `idx_direct_offers_freelancer_status`  
**RLS:** SELECT for client or freelancer; INSERT for freelancer (conversation participant); UPDATE for client/freelancer per role.  
**Trigger:** `fn_direct_offer_guard` enforces valid status/payment transitions (e.g. allows `sent` → `accepted` with `payment_status = 'unpaid'`; allows `accepted` → `active` when payment is held).

Full schema and enum details: `Sline_everything/SUPABASE_SETUP.md` §5.14.

### 2.2 Ledger and work_logs

- **Ledger RPC:** `process_payment_event_ledger` supports `escrow_hold`, `release_with_fee`, `refund` for `related_entity_type = 'direct_offer'`. For `escrow_hold`, the offer must be in status `sent` or `accepted` and `payment_status = 'unpaid'`. Journal entries use `payment_event_type_enum` (migration `20260307_fix_ledger_event_type_enum.sql`).
- **work_logs:** `related_entity_type = 'direct_offer'` is supported; `is_work_log_participant()` uses `direct_offers.client_id` and `direct_offers.freelancer_id` for access.

### 2.3 Edge functions

| Function | Purpose |
| -------- | ------- |
| `qicard_payment_create_direct_offer` | Creates QiCard payment session for an accepted, unpaid direct offer; returns `form_url`, `correlation_id`, `payment_request_id`. |
| `qicard_payment_recovery_direct_offer` | Recovers direct-offer state after gateway return; calls ledger and updates offer status/payment_status. |

Defined under `supabase/functions/`; see `Sline_everything/STRUCTURE.md`.

---

## 3. File Inventory

| File | Layer | Description |
| ---- | ----- | ----------- |
| `lib/features/direct_offers/models/direct_offer_model.dart` | Model | `DirectOffer` — immutable model for a direct_offers row (id, conversationId, clientId, freelancerId, price, days, status, payment_status, etc.). |
| `lib/features/direct_offers/services/direct_offers_service.dart` | Service | `DirectOffersService` — createOffer, acceptOfferWithoutPayment, payNow (ledger escrow only), recoverPaymentAfterCallback (post-QiCard), rejectOffer, cancelOffer, markDelivered, completeOffer. Uses Supabase client, MessageService, LedgerService, WorkLogService. |
| `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart` | ViewModel | `DirectOfferDetailsViewModel` — ChangeNotifier; loadOffer, createPaymentForCard (QiCard), payNow, markDelivered, completeOffer; uses `AuthSessionViewModel.currentUserId` (no Supabase in view). |
| `lib/features/direct_offers/view/direct_offer_details_screen.dart` | View | `DirectOfferDetailsScreen` — detail UI: Cancel, Pay (QiCard), Open chat; Mark Delivered / Approve & release by role. Uses Provider for ViewModel and services. |

### 3.1 Integration points (other features)

| File | Usage |
| ---- | ----- |
| `lib/features/chat/viewmodels/chat_view_model.dart` | For direct offers (payload has `offer_id`), calls `DirectOffersService.acceptOfferWithoutPayment(offerId)`; createDirectOffer uses DirectOffersService.createOffer. |
| `lib/features/chat/view/widgets/offer_message_bubble.dart` | Shows **Accept** (not "Accept & Pay") for direct offers; Reject / Cancel / Mark Delivered / Complete by role and status. |
| `lib/features/dashboard/data/dashboard_repository.dart` | `_fetchDirectOffers` includes status `accepted`; maps to `UnifiedWorkStatus.pendingPayment`, `primaryActionType = payEscrow` for client. |
| `lib/features/dashboard/viewmodels/dashboard_view_model.dart` | `performPrimaryAction` for directOffer + payEscrow calls `DirectOffersService.payNow(item.id)`; on web opens payment in browser. |
| `lib/features/dashboard/view/dashboard_screen.dart` | Web: on load, `_handleWebPaymentReturnIfPresent()` checks URL for `payment_return=1&offer_id=...&payment_request_id=...`, runs recovery, clears URL. |
| `lib/features/booking/view/payment_webview_screen.dart` | Supports `expectedOfferId`; direct-offer return validation and recovery via `DirectOffersService.recoverPaymentAfterCallback`. |
| `lib/core/utils/web_url_utils_web.dart` | `clearPaymentReturnParamsFromUrl()` — clears payment_return params from browser URL (uses `package:web`). |
| `lib/core/services/deep_link_service.dart` | `handleWorkItem` with type `directOffer` opens `DirectOfferDetailsScreen`; `openConversation` for "Open chat". |

---

## 4. App Flows (Detail)

### 4.1 Create offer (chat)

1. Freelancer taps offer in chat; `ChatViewModel` (or composer) collects price/days/title/description.
2. `DirectOffersService.createOffer(...)` inserts `direct_offers` row (status `sent`, payment_status `unpaid`) and sends an offer message with `payload.offer_id`.
3. Chat UI shows the offer bubble; client sees **Accept** / **Reject**.

### 4.2 Accept in chat (no payment)

1. Client taps **Accept**. `ChatViewModel` detects direct offer (payload has `offer_id`) and calls `DirectOffersService.acceptOfferWithoutPayment(offerId)`.
2. Service updates `direct_offers` to status `accepted`, payment_status `unpaid`; optionally adds work_log; may send `offer_accepted` message.
3. No payment in chat; offer appears in Dashboard as Pending Payment.

### 4.3 Pay from Dashboard

1. Client opens Dashboard; work list includes direct offer with `UnifiedWorkStatus.pendingPayment` and primary action `payEscrow`.
2. Client taps **Pay & Confirm**. `DashboardViewModel.performPrimaryAction` calls `DirectOffersService.payNow(offerId)` (or opens detail screen where user taps Pay).
3. Detail screen: `DirectOfferDetailsViewModel.createPaymentForCard()` invokes `PaymentService.createPaymentForDirectOffer(...)` → edge `qicard_payment_create_direct_offer`.
4. **Mobile:** `PaymentWebViewScreen` opens `form_url` with `expectedOfferId`; on trusted callback, recovery runs in WebView flow.
5. **Web:** Payment opens in browser (`url_launcher`); user returns to app URL with `?payment_return=1&offer_id=...&payment_request_id=...`. Dashboard `_handleWebPaymentReturnIfPresent()` runs `recoverPaymentAfterCallback` and clears URL.

### 4.4 Recovery after payment return

1. `DirectOffersService.recoverPaymentAfterCallback(offerId, paymentRequestId)` (or edge `qicard_payment_recovery_direct_offer`) validates and calls ledger `escrow_hold` for the direct_offer.
2. Offer status → `active`, payment_status → `held`; work_log entry.
3. Dashboard refreshes; client and freelancer see offer in Active / Work list.

### 4.5 Deliver and complete

1. Freelancer: Mark Delivered → service updates status to `delivered`.
2. Client: Approve & release → `process_payment_event_ledger('release_with_fee', 'direct_offer', id)` → status `completed`, payment_status `released`.

---

## 5. Error Handling and Notes

- **Guard:** Invalid status/payment transitions are rejected by `fn_direct_offer_guard`; app should map DB errors to user-friendly messages.
- **Recovery idempotency:** Server-side recovery should be idempotent; duplicate returns (e.g. user refreshes) should not double-apply escrow.
- **Web payment return:** The dashboard uses an instance-level flag `_webPaymentReturnHandled` (not static) so that each visit can run recovery when the URL contains payment params; see `dashboard_screen.dart`.
- **References:** Chat Feature Reference §2.6 (main DEVELOPER_GUIDE.md); `SUPABASE_SETUP.md` §5.14; `STRUCTURE.md` for migrations 20260303–20260307 and edge function paths.
