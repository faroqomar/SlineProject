# Hardened Payment Linking — Checklist & Summary

**Use this to verify the implementation in the app and understand what changed.**

---

## Verification checklist (what to check)

### In the app (Flutter)

- [ ] **Booking payment**
  - From a booking flow, tap Pay → create payment → open webview/browser.
  - If the create response includes `intent_id`, the app subscribes to `payment_intents(id)` and can show success as soon as the webhook updates status (without waiting for the redirect).
  - **Where:** `lib/features/booking/view/payment_checkout_screen.dart` — when `createResult.intentId != null`, it calls `vm.streamPaymentIntentStatus(createResult.intentId!)` and pops on `succeeded` or `failed`.

- [ ] **Direct offer payment**
  - From a direct offer (accepted, unpaid), tap Pay with card → create payment → open webview.
  - If the create response includes `intent_id`, the webview receives `paymentIntentId` and `paymentIntentStatusStream` and can pop with success/failure when Realtime delivers the status.
  - **Where:** `lib/features/direct_offers/view/direct_offer_details_screen.dart` — passes `result.intentId` and `vm.streamPaymentIntentStatus(result.intentId!)` into `PaymentWebViewScreen`.

- [ ] **Payment logs (no PII)**
  - In logs (AppLogger, tag `Payment`), you should see intent_id and correlation_id; you should **not** see raw amounts or card data in payment flow logs.
  - **Where:** `lib/core/services/qicard_payment_service.dart`, `payment_checkout_screen.dart`, `payment_webview_screen.dart`.

### In the backend (Supabase)

- [ ] **Tables**
  - `payment_intents` has columns: `signature`, `currency`, `paid_at` (migration `20260308200000`).
  - `orphan_payments` has column: `investigated` (same migration).
  - `payment_events` has RLS policy `service_role_insert_payment_events` and trigger `trg_payment_events_append_only` (no UPDATE/DELETE).

- [ ] **Ledger meta**
  - When the webhook calls the ledger with an intent, `journal_entries.meta` can contain `payment_intent_id` (migration `20260308200100`).
  - Check: after a successful gateway payment, query `journal_entries` for a recent `gateway_escrow` row and confirm `meta->>'payment_intent_id'` is set when the intent path was used.

- [ ] **Webhook**
  - Edge function `qicard_webhook_handler`: when payload has `additionalInfo.intent_id` (valid UUID), it uses the intent path (lookup intent → insert payment_events → validate amount → call ledger with paymentIntentId → update payment_intents).
  - Logs: structured lines `intent_path_processed` or `intent_path_orphan` with intent_id/gateway_event_id/entity_type or reason (no amount/PII).

### Quick commands

```bash
# Flutter
flutter analyze lib/core/services/qicard_payment_service.dart lib/core/services/payment_service.dart lib/features/booking/view/payment_webview_screen.dart lib/features/direct_offers/view/direct_offer_details_screen.dart lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart

# Tests
flutter test
```

---

## What was done and why

**Goal:** Harden payment flows so every gateway payment is tied to a `payment_intent`, every webhook hit is audited in `payment_events`, and the ledger stores `payment_intent_id` for forensics. The app can resolve success via Realtime when the create returns an `intent_id`.

**Why:** Single audit trail (intent → events → journal), no double-processing (idempotency + amount check), and support for “pay and see success without refresh” when the gateway and create edge return the intent id.

---

## What was added

| Where | What |
|-------|------|
| **Webhook (Edge)** | New function `handleIntentBasedPayment`: when `additionalInfo.intent_id` is present, looks up intent, inserts into `payment_events`, checks amount/currency, calls ledger with `paymentIntentId`, updates `payment_intents`. Structured logs: `intent_path_processed`, `intent_path_orphan` (no PII). |
| **Shared Edge** | Optional `paymentIntentId` in `submitGatewayEscrowHold` and `submitDirectOfferGatewayEscrow`; when set, it is put into `p_meta` for the RPC so the ledger can store it. |
| **Flutter payment service** | Parsing of `intent_id` from create response (booking and direct offer) and AppLogger when intent_id is present (“Realtime subscription available”). |
| **Flutter payment_service** | `intentId` on `QiCardDirectOfferPaymentResult`. |
| **PaymentWebViewScreen** | Optional `paymentIntentId` and `paymentIntentStatusStream`; when stream is set, listens for `succeeded`/`failed` and pops with `PaymentReturnArgs` (so direct offer can close on Realtime without waiting for redirect). |
| **DirectOfferDetailsViewModel** | `streamPaymentIntentStatus(intentId)` that delegates to `PaymentService`. |
| **Direct offer screen** | When create result has `intentId`, passes it and `vm.streamPaymentIntentStatus(intentId)` into `PaymentWebViewScreen`. |
| **DB migrations** | `20260308200000`: columns on payment_intents/orphan_payments, RLS and append-only trigger on payment_events. `20260308200100`: both RPCs merge `payment_intent_id` from `p_meta` into `journal_entries.meta`. |
| **Docs** | SUPABASE_SETUP: §5.23–5.25 (tables), Quick Reference, Key Business Rules, journal meta note. DEVELOPER_GUIDE: Hardened Payment section rewritten (overview, webhook intent path, Flutter flow, security). CONTRACT, LOGGING_AND_SECRETS, DECISION in improvement folder. |

---

## What was removed

| Where | What |
|-------|------|
| **Nothing** | No features or tables were removed. Legacy webhook path (no intent_id) still runs; booking and direct offer still work without intent_id via callback URL and recovery. |

---

## What was modified

| Where | What changed |
|-------|----------------|
| **qicard_webhook_handler** | After QiCard signature check, if payload has valid `additionalInfo.intent_id`, the new intent path runs first (audit → validate → ledger with intent id); otherwise the existing legacy path (booking_id / offer_id) is used. |
| **bookin_payment.ts** | `submitGatewayEscrowHold` and `submitDirectOfferGatewayEscrow` accept optional `paymentIntentId` and add it to `p_meta` when calling the RPC. |
| **qicard_payment_service.dart** | Reads `intent_id` from create response and logs when it’s present; no change to create URL or request shape. |
| **payment_webview_screen.dart** | New optional parameters and a subscription to the intent status stream; when both are set, the webview can pop on Realtime success/failure. Existing callback URL handling is unchanged. |
| **direct_offer_details_screen.dart** | When opening the payment webview, it now passes `result.intentId` and the status stream when the create result has an intent id. |
| **SUPABASE_SETUP.md** | New tables in Quick Reference, new Key Business Rule, new §5.23–5.25, and a note under journal_entries about payment_intent_id in meta. |
| **DEVELOPER_GUIDE.md** | Hardened Payment Gateway section (Overview, DB mapping, webhook intent path, Flutter flow, security) updated to match current behavior and to reference CONTRACT/LOGGING. |

---

## One-line summary

**Added:** Intent-based webhook path (audit in `payment_events`, amount check, ledger with `payment_intent_id` in meta), Realtime subscription for direct offer in the webview, and DB/docs for payment_intents/events/orphans and journal meta. **Modified:** Webhook to try intent path first when `intent_id` is present; Edge submit helpers and Flutter direct-offer flow to pass and use intent id + stream. **Removed:** Nothing; legacy path and existing flows still work.
