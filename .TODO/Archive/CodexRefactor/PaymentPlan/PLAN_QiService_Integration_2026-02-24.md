# 📌 Plan: Qi_Service Payment Gateway Integration

## 1) Goal

- **Goal:** Integrate QiCard payment gateway (Qi_Service) end-to-end across the SLine app so real card payments flow through the platform instead of the demo simulator.
- **Why:** Replace demo payment with production-ready payment processing for bookings and future tender flows.
- **Result:** Users can pay with card via QiCard form; webhooks update ledger; booking status reflects payment success/failure.

---

## 2) Scope

### In-Scope

- Booking checkout flow (card payment via QiCard)
- QiCard payment creation API (POST /payment)
- QiCard webhook handler (signature verification, payload mapping)
- Ledger integration (escrow_hold, release_with_fee, refund)
- Payment state model (pending/success/failed/refunded)
- Error handling and observability

### Out-of-Scope

- Tender (task_request) payment flow (deferred; same pattern applies)
- Wallet top-up/deposit via card (deposit event exists; separate UI)
- Withdrawal to bank (withdrawal_request/webhook; separate phase)
- QiCard 3DS SDK native integration (use formUrl in WebView first)

---

## 3) Evidence & Findings (From Scan)

### Existing

| Item | Location | Notes |
|------|----------|-------|
| Qi_Service docs | `Sline_everything/Payment_Gateway/Qi_Service/documentation.md` | Create Payment, Refund, Status, Cancel, Webhook format, signature verification |
| QiCard API | `https://uat-sandbox-3ds-api.qi.iq/api/v1` | Sandbox base URL |
| PaymentService interface | `lib/core/services/payment_service.dart` | `processPayment()` returns String (txnId) |
| DemoPaymentService | `lib/core/services/demo_payment_service.dart` | Simulates 2s delay, returns fake txn ID |
| PaymentCheckoutScreen | `lib/features/booking/view/payment_checkout_screen.dart` | Uses card form (ignored for demo), calls `vm.processPayment()` → `bookSlot()` → `escrowHoldBooking()` |
| BookingViewModel | `lib/features/booking/viewmodels/booking_view_model.dart` | Injects `PaymentService`; `processPayment()` delegates to service |
| LedgerService | `lib/features/wallet/services/ledger_service.dart` | `submitPaymentEvent()` → `process_payment_event_ledger` RPC |
| BookingService.escrowHoldBooking | `lib/features/booking/services/booking_service.dart` | Calls LedgerService with `escrow_hold` |
| qicard_webhook_handler | `supabase/functions/qicard_webhook_handler/index.ts` | Deployed; expects `event_type`, `psp_event_id`, `payment_id`, etc.; maps to deposit/withdrawal |
| process_payment_event_ledger | `Sline_everything/phase1_ledger_rpc.sql` | Supports escrow_hold, release_with_fee, refund, deposit, withdrawal_* |
| wallet_balances view | `Sline_everything/SUPABASE_SETUP.md` | Aggregates available/held from ledger |

### Missing

| Item | Notes |
|------|-------|
| QiCardPaymentService | Flutter service that calls QiCard REST API |
| Payment creation flow | Create booking first, then call QiCard API with booking_id in additionalInfo |
| WebView or browser | Open formUrl for 3DS completion |
| Webhook payload mapping | QiCard sends `paymentId`, `requestId`, `status`, `creationDate` — NOT `event_type` or `psp_event_id` |
| Escrow for card payments | `escrow_hold` expects user_available balance; card payments come from external source |

### Conflicts / Risks

| Issue | Risk |
|-------|------|
| **Webhook payload mismatch** | QiCard webhook body: `{ paymentId, requestId, status, amount, creationDate, ... }`. Current handler expects `event_type`, `psp_event_id`. Must adapt handler. |
| **Escrow source** | `escrow_hold` debits `user_available`. For card payments, user has no pre-funded wallet. Need new event or flow: `gateway_escrow` (DR platform_cash, CR platform_escrow) OR deposit + escrow. |
| **PaymentService interface** | Current: `processPayment()` returns txnId. QiCard: create payment → return formUrl → user completes → webhook. Interface must change for async flow. |
| **Signature verification** | QiCard docs: data string = `paymentId|amount.000|currency|creationDate|status`. Handler uses rawBody; verify signature format matches. |

---

## 4) System Impact Map

| Area | Impact |
|------|--------|
| **UI** | PaymentCheckoutScreen: replace card form with "Pay" → open QiCard formUrl (WebView); show loading/return handling |
| **MVVM/App Logic** | BookingViewModel: new flow `initiatePayment()` → `createBookingDraft()` → open formUrl; webhook completes escrow |
| **Database** | Optional: `payment_intents` table for idempotency; or rely on booking_id + requestId in meta |
| **RLS/Security** | Webhook uses service role; no RLS on edge. Signature verification required. |
| **Realtime** | Optional: notify booking status change after webhook |
| **Storage** | None |
| **Observability** | AppLogger, webhook logs, audit_logs |
| **Compatibility** | Demo mode via feature flag; existing DemoPaymentService kept for tests |

---

# ✅ Execution Phases (Checklist)

## Phase 0: Preconditions & Gates

> Primary: @Sentinel

### 0.1 Spec Lock

- [ ] (@Sentinel) Acceptance: (1) User completes QiCard payment → booking created; (2) Webhook SUCCESS → escrow held; (3) Refund via QiCard API works; (4) Demo mode still works for tests
- [ ] (@Architect) Confirm: BookingViewModel, PaymentService, PaymentCheckoutScreen, qicard_webhook_handler
- **Verify (@Sentinel):** Rollback triggers documented

### 0.2 Threat Model

- [ ] (@ThreatModeler) Threat model: webhook spoofing (mitigated by signature), replay (idempotency), double-charge
- **Verify (@Sentinel):** Negative checks in Phase 4

### 0.3 Contracts

- [ ] (@APIContract) Contract: QiCard payment creation request/response; webhook payload; ledger RPC params for gateway_escrow
- **Verify (@Sentinel):** Matches Qi_Service docs

### 0.4 Migration Plan

- [ ] (@DataMigration) If new event type `gateway_escrow`: add to `payment_event_type_enum`; migration script
- **Verify (@Sentinel):** Backward compatible

### 0.5 Feature Flag

- [ ] (@Architect) `USE_QICARD_PAYMENT` env/flag: true → QiCardPaymentService; false → DemoPaymentService
- **Verify (@Sentinel):** Rollback = flip flag

### 0.6 Test Infrastructure Gate

- [ ] (@Sentinel) Create webhook fixture payloads (SUCCESS, FAILED, missing additionalInfo, invalid signature)
- [ ] (@Sentinel) Add test harness notes for webhook simulation and LedgerService mock strategy
- [ ] (@Sentinel) Document deterministic test run commands for local validation
- **Verify (@Sentinel):** Gate 0 passes before Phase 1.3 webhook rollout

---

## Phase 1: Database & Backend

> Primary: @Supabase_Ops

### 1.0 Live Supabase Confirmation

- [ ] (@Supabase_Ops) Scan via MCP: `journal_entries`, `ledger_lines`, `accounts`, `payment_event_type_enum`, `process_payment_event_ledger` signature
- **Verify (@Sentinel):** No drift from docs

### 1.1 Schema (Additive)

- [ ] (@Supabase_Ops) Add `gateway_escrow` to `payment_event_type_enum` (if not exists) — event: DR platform_cash, CR platform_escrow; update booking payment_status to held
- [ ] (@Supabase_Ops) Ensure `platform_cash` account exists in `accounts`
- [ ] (@DataMigration) Migration: `ALTER TYPE payment_event_type_enum ADD VALUE IF NOT EXISTS 'gateway_escrow'`
- **Verify (@Sentinel):** No drops, naming consistent

### 1.2 RPC Extension

- [ ] (@Supabase_Ops) Extend `process_payment_event_ledger` for `gateway_escrow`: gate = booking pending/unpaid; entity lock; DR platform_cash, CR platform_escrow; update booking payment_status = held
- [ ] (@Supabase_Ops) Idempotency key format: `qicard:{paymentId}:gateway_escrow:{status}`
- **Verify (@Sentinel):** Balanced journal, no negative platform_cash

### 1.2.1 Blocking Gate Check

- [ ] (@Supabase_Ops) Run an RPC smoke validation proving `gateway_escrow` is accepted and returns `ok` before webhook changes are deployed
- **Verify (@Sentinel):** Block Phase 1.3 until this check passes

### 1.3 Webhook Handler Update

- [ ] (@Supabase_Ops) Adapt `qicard_webhook_handler` to QiCard payload format: `paymentId`, `requestId`, `status`, `amount`, `creationDate`, `additionalInfo`
- [ ] (@Supabase_Ops) If one webhook URL receives mixed event shapes, branch parsing by payload shape (`event_type` legacy vs QiCard payment payload) to avoid regressions
- [ ] (@Supabase_Ops) Map QiCard `status` SUCCESS → `gateway_escrow`; FAILED/other statuses should not write ledger entries
- [ ] (@Supabase_Ops) Validate `additionalInfo.booking_id` exists and is valid UUID before RPC call; if missing/invalid, log with correlation id and return 200 (ack, skip RPC)
- [ ] (@Supabase_Ops) Signature verification must use a constructed string `paymentId|amount.000|IQD|creationDate|status` (NOT rawBody) per Qi_Service docs
- [ ] (@Supabase_Ops) Clarify refund behavior: refund is app-triggered; if unexpected refund webhook appears, log and return 200 without ledger action
- [ ] (@Supabase_Ops) Return 200 OK on success; 401 on invalid signature; 400 on RPC error
- **Verify (@Sentinel):** Idempotent replay returns 200

---

## Phase 2: App Layer (MVVM)

> Primary: @Architect

### 2.1 PaymentService Interface

- [ ] (@Architect) Extend `PaymentService`: `Future<PaymentInitResult> initiatePayment({ amount, currency, bookingId, clientId, ... })` — returns `formUrl` or `PaymentInitResult.error`
- [ ] (@Architect) `PaymentInitResult`: `{ formUrl?, paymentId?, requestId?, error? }`
- [ ] (@Architect) Keep `processPayment()` for Demo mode (returns txnId)

### 2.2 QiCardPaymentService

- [ ] (@Architect) Create `lib/core/services/qicard_payment_service.dart` — implements `PaymentService`
- [ ] (@Architect) `initiatePayment()`: POST to QiCard `/payment` with requestId (UUID), amount (IQD 3 decimals), currency, finishPaymentUrl, notificationUrl, additionalInfo: `{ booking_id, client_id }`
- [ ] (@Architect) Use Basic Auth (Base64) from env/config; `X-Terminal-Id` header
- [ ] (@Architect) Parse response: `formUrl`, `paymentId`; return `PaymentInitResult`
- [ ] (@Architect) Add explicit QiCard error mapping table in service/docs (example baseline: 27 service unavailable, 12 payment not found, 21 invalid payment details) and map to user-friendly messages aligned with `.cursor/rules/error-handling.mdc`
- **Verify (@Sentinel):** No credentials in code; use env or secure config

### 2.3 Booking Flow Refactor

- [ ] (@Architect) New flow: `createBookingDraft()` — insert booking with status `pending`, payment_status `unpaid`; return booking
- [ ] (@Architect) `initiatePayment()` called with bookingId; return formUrl
- [ ] (@Architect) PaymentCheckoutScreen: on "Pay" → createBookingDraft → initiatePayment → open WebView/browser with formUrl
- [ ] (@Architect) Double-submit protection: disable Pay while draft creation/payment init is running to prevent duplicate bookings/payments
- [ ] (@Architect) finishPaymentUrl contract: `sline://payment/finish?payment_id={id}&status={status}`; configure app/deep-link handling and show "Processing..." after return
- [ ] (@Architect) Decline/refund race guard: wait for booking `payment_status=held` (poll/realtime up to 60s) before refund flow; otherwise show retryable "Payment still processing"
- [ ] (@Architect) Orphan draft policy: if checkout is abandoned, mark draft stale/expired after timeout and optionally cancel pending QiCard payment
- [ ] (@Architect) Remove: create booking before escrow; escrow now triggered by webhook
- **Verify (@Sentinel):** No direct Supabase in View; all via ViewModel

### 2.4 ViewModel Updates

- [ ] (@Architect) `BookingViewModel`: add `createBookingDraft()`, `initiateQiCardPayment()`; `processPayment()` remains for Demo
- [ ] (@Architect) Provider: inject `PaymentService` based on feature flag
- **Verify (@Sentinel):** Recoverable state; clear error mapping

### 2.5 Observability

- [ ] (@Observability) Log: payment init, formUrl received, webhook received (no sensitive data)
- [ ] (@Observability) Include `paymentId`/`requestId` as correlation identifiers across app logs, webhook logs, and ledger metadata
- [ ] (@Architect) AppLogger tags: `Payment`, `QiCard`
- **Verify (@Sentinel):** No PAN, CVV, tokens in logs

---

## Phase 3: UI

> Primary: @Pixel

### 3.1 PaymentCheckoutScreen

- [ ] (@Pixel) Replace "Pay" flow: create booking draft → initiate payment → open WebView (e.g. `webview_flutter`) with formUrl
- [ ] (@Pixel) Handle finishPaymentUrl: parse success/failure; show success or error; pop with result
- [ ] (@Pixel) Loading: "Redirecting to payment..." while opening formUrl
- [ ] (@Pixel) Error: "Payment could not be started" with retry
- **Verify (@Sentinel):** Stable UX on slow network, back button

### 3.2 Polish

- [ ] (@Pixel) Optional: "Processing payment..." after return if webhook not yet processed; poll booking status
- **Verify (@Sentinel):** No perf regression

---

## Phase 4: QA + Security

> Primary: @Sentinel

### 4.1 Contract + Migration

- [ ] (@Sentinel) Verify QiCard request/response shapes match contract
- [ ] (@Sentinel) Run migration; verify `gateway_escrow` event works
- **Verify (@Sentinel):** No mismatch

### 4.2 Security

- [ ] (@Sentinel) Webhook: invalid signature → 401; replay → 200 idempotent
- [ ] (@Sentinel) RLS: no user access to service role; webhook uses service role only
- [ ] (@Sentinel) Refund idempotency key applied for retries: `qicard:refund:{paymentId}:{requestId}`
- **Verify (@Sentinel):** Unauthorized access impossible

### 4.3 Functional QA

- [ ] (@Sentinel) E2E: Create booking → Pay → complete 3DS on sandbox → success; booking payment_status = held
- [ ] (@Sentinel) Refund: decline booking → refund via QiCard API; ledger refund event
- [ ] (@Sentinel) Demo mode: flag off → DemoPaymentService; booking flow works
- **Verify (@Sentinel):** No crashes, consistent behavior

### 4.4 Observability

- [ ] (@Sentinel) Logs: payment init, webhook received (no PII)
- **Verify (@Sentinel):** Actionable telemetry

---

## Phase 5: Documentation Sync

> Primary: @DocsKeeper

- [ ] (@DocsKeeper) Update `Sline_everything/DEVELOPER_GUIDE.md` — payment flow section
- [ ] (@DocsKeeper) Update `Sline_everything/SUPABASE_SETUP.md` — gateway_escrow event, webhook
- [ ] (@DocsKeeper) Update `Sline_everything/STRUCTURE.md` — QiCardPaymentService
- [ ] (@DocsKeeper) Update `Sline_everything/Sline_Log.md` — QiCard integration
- **Verify (@Sentinel):** Docs match code

---

## 6) Unified Payment State Model

| State | Source | Consumed By |
|-------|--------|-------------|
| `unpaid` | booking.payment_status | `UnifiedCtaResolver` → `escrow_hold` CTA |
| `held` | booking.payment_status | `UnifiedCtaResolver` → `release_with_fee` CTA |
| `released` | booking.payment_status | Completed state |
| `refunded` | booking.payment_status | Decline/cancel flow |
| `pending` (QiCard) | Payment object status | WebView return; show "Processing" |
| `SUCCESS` (QiCard) | Webhook payload | Webhook handler → gateway_escrow |
| `FAILED` (QiCard) | Webhook payload | Webhook handler → no ledger update; optional notification |

---

## 7) Error Handling & Observability

| Area | Strategy |
|------|----------|
| **QiCard API errors** | Map codes 1–35 to user messages; log code + description (no PAN) |
| **Webhook errors** | Log signature failure, RPC failure; return 400/500 |
| **Ledger errors** | ERR_INSUFFICIENT_FUNDS, ERR_GATE_NOT_ALLOWED → user-friendly |
| **Logs** | AppLogger.i/d/e with tag `Payment`, `QiCard` |
| **Alert points** | Webhook 401 spike; RPC failure rate |

---

## 8) Test Strategy

| Type | Scope |
|------|-------|
| **Gate 0** | Webhook fixtures + deterministic local simulation harness must pass before webhook deployment |
| **Unit** | QiCardPaymentService: mock HTTP; assert request shape, response parsing |
| **Unit** | LedgerService: mock RPC; assert idempotency key format |
| **Widget** | PaymentCheckoutScreen: mock ViewModel; assert loading, error states |
| **Integration** | Webhook simulation: POST to edge function with valid payload; verify ledger |
| **Integration** | Replay/duplicate tests: SUCCESS replay and duplicate refund attempts must be idempotent |
| **Regression** | Demo mode: full booking flow with DemoPaymentService |

---

## 9) Rollout Strategy

| Step | Action |
|------|--------|
| 1 | Feature flag `USE_QICARD_PAYMENT=false` (default) |
| 2 | Deploy webhook handler + RPC; test with sandbox |
| 3 | Enable flag for internal testers |
| 4 | Staged release; monitor webhook success rate |
| 5 | Backfill: none (new bookings only) |
| 6 | Rollback: set flag false; revert to DemoPaymentService (do not roll back enum migration; additive schema remains) |

---

## 10) Risks / Dependencies / Open Questions

| Item | Mitigation |
|------|------------|
| QiCard sandbox availability | Use test credentials; document production URL switch |
| WebView 3DS compatibility | Test on iOS/Android; fallback to external browser |
| Webhook delivery delay | finishPaymentUrl return before webhook; show "Processing" + poll |
| Mixed webhook event shapes | If one URL handles multiple QiCard event types, branch parsing by payload shape |
| Refund API | QiCard POST /payment/{id}/refund; wire to decline flow |
| Open: tender flow | Same pattern; defer to Phase 2 |

---

## 11) Exact Files/Folders Per Phase

| Phase | Paths |
|-------|-------|
| **1** | `supabase/migrations/YYYYMMDD_add_gateway_escrow.sql`, `supabase/functions/qicard_webhook_handler/index.ts`, `Sline_everything/phase1_ledger_rpc.sql` (or new migration) |
| **2** | `lib/core/services/payment_service.dart`, `lib/core/services/qicard_payment_service.dart`, `lib/features/booking/viewmodels/booking_view_model.dart`, `lib/features/booking/data/booking_repository.dart`, `lib/features/booking/services/booking_service.dart`, `lib/main.dart` (provider wiring) |
| **3** | `lib/features/booking/view/payment_checkout_screen.dart`, `lib/features/booking/view/availability_screen.dart` (navigation) |
| **4** | Test files: `test/...` |
| **5** | `Sline_everything/DEVELOPER_GUIDE.md`, `Sline_everything/SUPABASE_SETUP.md`, `Sline_everything/STRUCTURE.md`, `Sline_everything/Sline_Log.md` |

---

## 12) Ready-to-Execute Task List

1. Add Gate 0 test infrastructure (fixtures + webhook simulation + deterministic run commands).
2. Add `gateway_escrow` to `payment_event_type_enum` and extend `process_payment_event_ledger` RPC.
3. Run blocking RPC smoke check proving `gateway_escrow` works before webhook deployment.
4. Update `qicard_webhook_handler` to parse QiCard payload (`paymentId`, `requestId`, `status`, `additionalInfo`) and branch safely for mixed event shapes if required.
5. Implement signature verification per Qi_Service docs using constructed string (`paymentId|amount.000|IQD|creationDate|status`), not rawBody.
6. Enforce webhook validation for `additionalInfo.booking_id` UUID; log/ack and skip RPC if invalid.
7. Create `QiCardPaymentService` implementing `PaymentService`; add `initiatePayment()` returning formUrl.
8. Add `createBookingDraft()` to BookingService/Repository; keep booking in `pending/unpaid` until webhook escrow.
9. Refactor `PaymentCheckoutScreen`: create draft → initiate payment → open WebView with pay-button double-submit protection.
10. Wire `finishPaymentUrl` deep link (`sline://payment/finish?...`) and handle return + processing state.
11. Add QiCard error-code mapping table and user-friendly messages aligned with `.cursor/rules/error-handling.mdc`.
12. Add refund race + idempotency safeguards (`qicard:refund:{paymentId}:{requestId}`), then wire app-triggered refund flow.
13. Update DEVELOPER_GUIDE, SUPABASE_SETUP, STRUCTURE, Sline_Log.
14. Execute unit/integration/regression tests including replay/duplicate scenarios.

---

## 13) References

- `Sline_everything/Payment_Gateway/Qi_Service/documentation.md`
- `Sline_everything/DEVELOPER_GUIDE.md`
- `Sline_everything/SUPABASE_SETUP.md`
- `Sline_everything/STRUCTURE.md`
- `.cursor/PROJECT_CONTEXT.md`
- `.cursor/rules/error-handling.mdc`
- `.TODO/PaymentPlan/PLAN_PaymentLedger_2026-02-23.md`
- `supabase/functions/qicard_webhook_handler/index.ts`
