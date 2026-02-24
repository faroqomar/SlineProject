# Execution Log: PLAN_QiService_Integration_2026-02-24

**Plan Reference:** `.TODO/PLAN_QiService_Integration_2026-02-24.md`  
**Scope:** Phase 0 and Phase 1 completed, then Phase 2 started by user approval  
**Start Timestamp:** 2026-02-24

## Status per Phase

- **Phase 0 (Preconditions & Gates):** Done
- **Phase 1 (Database & Backend):** Done
- **Phase 2 (App Layer - MVVM):** Done
- **Phase 3 (UI - In-app WebView):** Done
- **Phase 4 (Manual + SQL Verification):** Done (with one security gate failing due missing secret)

## Phase 0 Evidence

### 0.1-0.4 Spec/Threat/Contract/Migration

- Added gate artifact: `.TODO/QiService/PHASE0_GATES.md`
- Includes:
  - acceptance and rollback criteria
  - threat model and mitigations
  - webhook + signature + RPC contract
  - additive migration strategy

### 0.5 Feature Flag Gate

- Added flag wiring in `lib/main.dart`:
  - `USE_QICARD_PAYMENT`
  - `createPaymentService()` factory
  - Booking provider injection uses selected service
- Added `lib/core/services/qicard_payment_service.dart` as fallback-safe QiCard service target.

### 0.6 Test Infrastructure Gate

- Added fixture set:
  - `.TODO/QiService/fixtures/webhook_success.json`
  - `.TODO/QiService/fixtures/webhook_failed.json`
  - `.TODO/QiService/fixtures/webhook_missing_booking_id.json`
  - `.TODO/QiService/fixtures/webhook_invalid_signature.json`
- Added deterministic harness:
  - `.TODO/QiService/PHASE0_TEST_HARNESS.md`

## Phase 1 Evidence

### 1.1 Schema (Additive)

- Added enum migration:
  - `supabase/migrations/20260224_add_gateway_escrow.sql`
- Updated migration reference file to include enum value:
  - `Sline_everything/phase1_ledger_migration.sql`

### 1.2 RPC Extension

- Extended `process_payment_event_ledger` in:
  - `Sline_everything/phase1_ledger_rpc.sql`
- Added `gateway_escrow` branch with:
  - booking-only gate
  - status/payment gate (`pending` + `unpaid`)
  - actor gate (`system`)
  - `platform_cash` non-negative guard
  - DR `platform_cash` / CR `platform_escrow`
  - booking `payment_status -> held`

### 1.2.1 Blocking Smoke Gate

- Added smoke proof runbook:
  - `.TODO/QiService/PHASE1_SMOKE_PROOF.md`
- Included executable SQL snippet and expected outputs.

### 1.3 Webhook Handler Update

- Updated:
  - `supabase/functions/qicard_webhook_handler/index.ts`
- Implemented:
  - mixed-shape handling (QiCard payment payload vs legacy event payload)
  - signature verification over constructed QiCard string:
    `paymentId|amount.000|currency|creationDate|status`
  - `additionalInfo.booking_id` UUID validation
  - SUCCESS -> `gateway_escrow` mapping
  - non-success payment statuses acknowledged with safe skip
  - idempotency key format:
    `qicard:{paymentId}:gateway_escrow:{status}`

## Verification Artifacts

- Static checks were run against repository content to confirm:
  - enum migration exists
  - RPC `gateway_escrow` branch exists
  - webhook uses booking UUID validation and `gateway_escrow` event
  - app flag wiring exists in `main.dart`

## Runtime Smoke Proof (Live Supabase)

- Project: `isddrknbjsgaantjojhm`
- Applied live DB updates:
  - enum migration `add_gateway_escrow_event_type`
  - RPC migration `extend_ledger_rpc_gateway_escrow` (additive; existing deposit/withdrawal branches preserved)
- Runtime verification:
  - first call result:
    - `{"ok": true, "journal_entry_id": "..."}`
  - replay call result (same idempotency key):
    - `{"ok": true, "journal_entry_id": "...", "info": "ERR_IDEMPOTENCY_REPLAY"}`
- Verification was executed in a transaction and rolled back for no persistent smoke-test side effects.

## Phase 2 Start (App Layer)

- Updated payment contract in `lib/core/services/payment_service.dart`:
  - Added `PaymentInitResult`
  - Added `initiatePayment(...)`
- Updated implementations:
  - `lib/core/services/demo_payment_service.dart` (implements `initiatePayment`)
  - `lib/core/services/qicard_payment_service.dart` (HTTP payment init + error mapping + correlation logging)
- Updated booking flow primitives:
  - `lib/features/booking/services/booking_service.dart` (`createBookingDraft`)
  - `lib/features/booking/data/booking_repository.dart` (`createBookingDraft`)
  - `lib/features/booking/viewmodels/booking_view_model.dart` (`createBookingDraft`, `initiateQiCardPayment`)
  - `lib/features/booking/view/payment_checkout_screen.dart`:
    - flow now starts with booking draft creation
    - QiCard `formUrl` launch path
    - demo fallback remains available
    - deep-link listener added for `sline://payment/finish?...`
    - webhook confirmation polling added (up to 60s) before checkout success
    - user-facing processing state while awaiting gateway/webhook result
- Safety guards:
  - `lib/features/booking/viewmodels/booking_view_model.dart`:
    - added `waitForBookingPaymentHeld(...)`
    - decline flow now blocks refund until booking payment reaches `held`
    - returns retryable message when payment is still processing
    - added `cancelBookingDraftIfUnpaid(...)` for orphan draft cleanup
  - `lib/features/booking/view/payment_checkout_screen.dart`:
    - cancels unpaid draft when payment init/open fails
    - cancels unpaid draft on deep-link failure/cancel result
- Platform deep-link registration:
  - `android/app/src/main/AndroidManifest.xml`:
    - added `sline://payment/finish` intent filter
  - `ios/Runner/Info.plist`:
    - added `sline` URL scheme while preserving existing `io.supabase.sline`
- Dependency updates:
  - added direct deps: `http`, `url_launcher`, `app_links`

## Phase 2 Completion Notes

- Demo fallback is now explicitly gated:
  - fallback runs only when `PaymentInitResult.errorCode == 'DEMO_MODE_LEGACY_FLOW'`
  - QiCard init failures no longer silently fall back to demo payment
- Orphan-draft policy strengthened:
  - cancels unpaid draft on payment init/open failure
  - cancels unpaid draft on deep-link failure/cancel result
  - auto-timeout cancel timer added (30 min)
  - best-effort cleanup on screen dispose when unpaid draft remains
- MVVM boundary check:
  - `PaymentCheckoutScreen` contains no direct Supabase or RPC calls
  - all DB/payment operations route through `BookingViewModel`

## Verification Evidence (Implementation Works)

- Static analysis:
  - `flutter analyze` => `No issues found!`
- Lint diagnostics on changed files:
  - no linter errors
- Test suite status:
  - `flutter test` reports no `_test.dart` files in `test/` (no automated tests present yet)
- Runtime backend gate proof:
  - Phase 1 live smoke/replay proof is complete and recorded above

## Phase 3 Completion (UI WebView)

- Replaced external browser payment launch with in-app WebView flow.
  - Updated `lib/features/booking/view/payment_checkout_screen.dart`:
    - removed `launchUrl(...externalApplication)` path
    - opens `PaymentWebViewScreen` and resumes existing polling flow on return
    - cancel/fail return statuses now cancel unpaid draft safely
  - Added `lib/features/booking/view/payment_webview_screen.dart`:
    - in-app `webview_flutter` payment view
    - loading indicator for slow networks
    - retry UI for page-load failures
    - back-button behavior: navigate back in web history first, otherwise close checkout flow as canceled
- Added direct dependency:
  - `webview_flutter` in `pubspec.yaml`
- Quality gate:
  - `flutter analyze` => `No issues found!`

## Phase 4 Verification (Manual + SQL + Runtime)

### Runtime Alignment Fix Applied

- Found deployed function mismatch: live `qicard_webhook_handler` was still legacy version (no QiCard payment payload branch).
- Deployed updated function from repository logic:
  - project: `isddrknbjsgaantjojhm`
  - function: `qicard_webhook_handler`
  - live version moved from `v1` to `v2`

### Security Verification

- Invalid signature check:
  - **Result: FAIL**
  - webhook request with invalid `x-signature` returned `200`, not `401`
  - root cause: runtime signature secret not active (`QICARD_RSA_PUBLIC_KEY_PEM` missing), so signature verification is skipped.

- Replay behavior:
  - **Result: PASS**
  - same webhook payload posted twice (`paymentId` unchanged) returned `200` both times with same `journal_entry_id`.
  - SQL confirmed single journal and no duplicate posting (`journal_count=1`, `ledger_line_count=2`).

- Service-role boundary / no unauthenticated bypass:
  - Initially found vulnerability: RPC was executable by `PUBLIC/anon`.
  - Applied hardening migration:
    - `supabase/migrations/20260224_restrict_process_payment_event_ledger_execute.sql`
    - revoked execute from `PUBLIC` + `anon`, kept `authenticated` + `service_role`.
  - Re-test:
    - anon RPC call now returns `401 permission denied`.

### Functional Verification

- Created dedicated verification booking:
  - `aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee` (pending/unpaid)
- Seeded platform cash for deterministic gateway escrow verification.
- Webhook processing result:
  - booking transitioned to `payment_status=held`
  - ledger lines created:
    - `DEBIT 120 -> platform_cash`
    - `CREDIT 120 -> platform_escrow`

### Observability / PII Audit

- App-side correlation logging confirmed in code:
  - `paymentId` and `requestId` logged in QiCard init and checkout return flow.
- Static log-safety check:
  - no PAN/CVV/token logging found in QiCard app-layer code.

### Artifact

- Added Phase 4 checklist with explicit pass/fail gates:
  - `.TODO/QiService/PHASE4_VERIFICATION_CHECKLIST.md`
