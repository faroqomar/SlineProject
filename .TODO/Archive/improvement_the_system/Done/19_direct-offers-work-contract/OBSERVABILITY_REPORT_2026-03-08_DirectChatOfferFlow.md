# Observability Report: Direct Chat Offer Flow (06_direct-chat-offer-flow)

**Scope:** DirectChatOfferFlow (06_direct-chat-offer-flow)  
**Plan reference:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md` (Phase 3 step 8: event list, instrument service, no PII)  
**Date:** 2026-03-08  
**Agent:** @Observability

---

## 1. Telemetry Gaps (What Is Not Logged or Not Correlated)

### 1.1 App-layer gaps

| Gap | Evidence | Impact |
|-----|----------|--------|
| **No stable event_name in logs** | Logs use free-form messages (e.g. `[DirectOffers] created offer=...`) rather than a stable `event_name` field. | Harder to query/filter by event type in log aggregation. |
| **Recover success path omits payment_request_id** | `direct_offers_service.dart` L207, L218: success logs only include `offerId`; `paymentRequestId` is not in the log. | Payment recovery cannot be tied to gateway session in app logs without DB lookup. |
| **Pay path: request_id only in LedgerService** | `LedgerService` logs `request_id` from forensics; `DirectOffersService.payNow` does not pass or log a correlation id. | Tracing “pay → ledger RPC” requires correlating by time and offer_id across two tags (`DirectOffers` vs `LedgerService`). |
| **Complete path: no idempotency or journal tie** | `completeOffer` logs `offerId` only. RPC `rpc_approve_delivery` uses deterministic idempotency key and writes to ledger/audit; app does not log that key or any journal_entry_id. | Post-incident: cannot correlate app “complete” log with a specific journal_entry without DB query. |
| **Dispute flow not implemented** | No `createDisputeForDirectOffer` in `lib/features/direct_offers/`; no dispute event to log. | When dispute is added, event taxonomy and logging must be added (see §2). |
| **rejectOffer / cancelOffer: no “offer not found” log** | L277, L298: only `AppLogger.w(..., json: {'offerId': offerId})` when null; rejectOffer/cancelOffer lack the same “offer not found” warning. | Inconsistent with accept/pay/recover/markDelivered/completeOffer; minor traceability gap. |

### 1.2 DB / server-side gaps

| Gap | Evidence | Impact |
|-----|----------|--------|
| **Cron auto-release: no app telemetry** | By design: `run_auto_release_expired_direct_offers()` runs in DB (cron); app never invokes it. | Expected: no app log. |
| **Cron: no DB-side logging** | `supabase/migrations/20260319120000_direct_offer_auto_release_cron.sql`: no `INSERT INTO audit_logs`, no `RAISE NOTICE`. | Number of released offers and which offer_ids were auto-released are not visible in logs/audit without querying `direct_offers` and `journal_entries`. |
| **Ledger/approve: audit exists** | `process_payment_event_ledger` and `rpc_approve_delivery` (Archive migrations) write to `audit_logs` and `journal_entries` (meta includes forensics). | Payment and release are auditable in DB; app logs do not repeat full audit payload. |

### 1.3 Evidence summary (file paths and existing log tags)

- **Service:** `lib/features/direct_offers/services/direct_offers_service.dart`
  - **Tag used:** `DirectOffers` (consistent for w/e and some i calls; part of messages like `[DirectOffers]`).
  - **Create:** L66–67: `AppLogger.i('[DirectOffers] created offer=${offer.id} conversation=$conversationId')` — no `json` payload.
  - **acceptOfferWithoutPayment:** L124 (w), L149–150 (i with fee_rate_applied_bps, currency).
  - **payNow:** L158 (w), L181 (i) — no request_id in DirectOffersService.
  - **recoverPaymentAfterCallback:** L191 (w), L207–208 (i success), L214 (e), L218 (i) — success does not include payment_request_id.
  - **cancelAcceptedOffer:** L254 (w), L270 (i).
  - **rejectOffer:** L277 (w), L291 (i) — no w when offer null.
  - **cancelOffer:** L298 (w), L312 (i) — no w when offer null.
  - **markDelivered:** L319 (w), L344–346 (i with delivered_at, review_expires_at).
  - **completeOffer:** L353–365 (w), L365 (i start), L372 (e on catch), L381 (i success); json payloads use `offerId`, and optionally `delivered`, `paymentStatus`.
- **Ledger:** `lib/features/wallet/services/ledger_service.dart` — tag `LedgerService`; logs `request_id` when present in meta (L36–39, L64–66, L74–75, L79, L86, L90).
- **ViewModel:** `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart` — `_kTag`; logs failures only (e.g. load, payNow, cancelOffer, markDelivered, completeOffer).

---

## 2. Event Taxonomy for Direct Offer

Stable names (snake_case) for observability and future analytics. **Implemented** = currently logged in app (message or tag); **DB only** = only in DB (journal_entries/audit_logs); **Not implemented** = no code path yet.

| Event name | Level | When | Implemented | Safe (no PII) |
|------------|--------|------|-------------|----------------|
| `direct_offer_create` | info | createOffer success | ✅ (message) | ✅ |
| `direct_offer_accept` | info | acceptOfferWithoutPayment success | ✅ (message) | ✅ |
| `direct_offer_pay_start` | info | Before LedgerService.submitPaymentEvent(escrow_hold) | ❌ | N/A |
| `direct_offer_pay_success` | info | payNow success | ✅ (message) | ✅ |
| `direct_offer_pay_failed` | error | Ledger RPC or exception | Via LedgerService | ✅ |
| `direct_offer_recover_success` | info | recoverPaymentAfterCallback ok | ✅ (message) | ✅ |
| `direct_offer_recover_failed` | error | Edge returned !ok or throw | ✅ (AppLogger.e) | ✅ |
| `direct_offer_deliver` | info | markDelivered success | ✅ (message) | ✅ |
| `direct_offer_complete_start` | info | Before rpc_approve_delivery | ✅ (message) | ✅ |
| `direct_offer_complete_success` | info | completeOffer success | ✅ (message) | ✅ |
| `direct_offer_complete_failed` | error | rpc_approve_delivery throw | ✅ (AppLogger.e) | ✅ |
| `direct_offer_cancel_accepted` | info | cancelAcceptedOffer success | ✅ (message) | ✅ |
| `direct_offer_reject` | info | rejectOffer success | ✅ (message) | ✅ |
| `direct_offer_cancel_sent` | info | cancelOffer (freelancer) success | ✅ (message) | ✅ |
| `direct_offer_dispute_created` | info | createDisputeForDirectOffer success | ❌ (not implemented) | N/A |
| `direct_offer_auto_release` | info | Cron released expired offer | DB only (no app); cron has no log | N/A |

Recommendation: when adding a structured event layer (e.g. analytics or log pipeline), use the `event_name` column above and keep existing AppLogger messages as human-readable message.

---

## 3. What to Log vs What NOT to Log (Privacy-Safe)

### 3.1 Safe to log (identifiers and context)

- **offer_id** (entity id) — primary correlation key.
- **conversation_id** — scope for chat/offer list.
- **payment_request_id** — opaque gateway/session id (no card or user secrets).
- **payment_correlation_id** — opaque; for tracing pay ↔ gateway ↔ recovery.
- **request_id** (from LedgerForensics) — per-call correlation for ledger RPC.
- **fee_rate_applied_bps**, **currency** — business context (already logged on accept).
- **status**, **payment_status** — for state validation and debugging.
- **delivered_at**, **review_expires_at** — timestamps (already in markDelivered log).
- **Error codes and sanitized server messages** — e.g. “Ledger release failed” or edge `message`/`code` (no stack in production if it might contain paths/tokens).

### 3.2 Do NOT log

- **Secrets:** API keys, tokens, refresh tokens, passwords, OTP.
- **PII in full:** email, phone, full name, address (unless redacted by policy).
- **Chat content or attachment bodies.**
- **Raw payment details** (card numbers, CVV, etc.).
- **client_id / freelancer_id in logs** — treat as sensitive by default; if needed for audit, prefer DB audit_logs with access control; if ever logged in app, redact (e.g. last 4 chars of uuid) or omit.

Current code: **DirectOffersService** does not log client_id or freelancer_id; LedgerService passes them only in `p_meta` to the RPC (stored in DB), not in AppLogger. **Verdict:** no PII in app logs; acceptable.

---

## 4. Correlation Strategy (Tracing Payment and Delivery)

### 4.1 Primary keys

- **offer_id** — use in every direct-offer log and as the main trace key for “one offer’s lifecycle.”
- **conversation_id** — use for create and any conversation-scoped views.

### 4.2 Payment and delivery chain

- **Escrow hold (payNow):**
  - App: `DirectOffersService.payNow` → logs `offerId` (tag `DirectOffers`).
  - App: `LedgerService.submitPaymentEvent` → builds `request_id` (LedgerForensics), passes in `p_meta`; logs `eventType`, `relatedEntityType`, `relatedEntityId`, `request_id` (tag `LedgerService`).
  - DB: `process_payment_event_ledger` writes `journal_entries` (idempotency_key, meta with session_id, request_id, client_id, freelancer_id) and `audit_logs`.
  - **Correlation:** Same request: `offer_id` + `request_id`; link app pay log to ledger log by time and offer_id.

- **Recovery (recoverPaymentAfterCallback):**
  - Inputs: `offerId`, `paymentRequestId`.
  - App: success log today only has `offerId`; **gap:** add `payment_request_id` (opaque) to success log for trace to gateway/edge.
  - DB: edge/DB stores payment_request_id / payment_correlation_id on `direct_offers` row.
  - **Correlation:** `offer_id` + `payment_request_id` (and optionally `payment_correlation_id` from row) for pay ↔ recovery ↔ webhook.

- **Release (completeOffer / auto-release):**
  - App: `completeOffer` logs `offerId`; RPC uses deterministic idempotency key (entity_id + status + payment_status).
  - DB: `rpc_approve_delivery` → `process_payment_event_ledger('release_with_fee', ...)` → journal_entries + audit_logs.
  - Cron: `run_auto_release_expired_direct_offers()` uses same ledger RPC; no app log; no current DB log of which ids were released.
  - **Correlation:** For manual complete: `offer_id` + timestamp; for auto-release: only via DB (journal_entries / direct_offers status change).

### 4.3 Recommended additions (no PII)

1. **Recover success:** Log `payment_request_id` (opaque) in the success log, e.g.  
   `AppLogger.i(..., json: {'offerId': offerId, 'payment_request_id': paymentRequestId})`.
2. **Pay path:** Optionally pass a single correlation id (e.g. from LedgerForensics.request_id) into DirectOffersService for payNow and log it so one request_id ties “DirectOffers” and “LedgerService” lines.
3. **Stable event_name:** Add a structured field (e.g. `event_name: 'direct_offer_recover_success'`) when moving to structured logging or analytics.
4. **Cron (server-side):** If operations need visibility into auto-release, add in migration: e.g. `INSERT INTO audit_logs (..., action, related_entity_type, related_entity_id, meta)` for each released offer, or `RAISE NOTICE` with count and offer ids (only if DB logs are captured).

---

## 5. Summary Table

| Area | Status | Notes |
|------|--------|--------|
| AppLogger only, no print() | ✅ | `direct_offers_service.dart` and ViewModel use AppLogger only. |
| Privacy-safe (no PII in logs) | ✅ | No client_id/freelancer_id, no secrets, no chat content in logs. |
| Critical flows logged | ✅ | Create, accept, pay, recover, deliver, complete, cancel/reject have at least one log. |
| Correlation (offer_id) | ✅ | offer_id (and conversation_id where relevant) used throughout. |
| Correlation (payment_request_id in recover) | ⚠️ | Missing in recover success log; add for full pay ↔ recover trace. |
| Correlation (request_id across pay) | ⚠️ | LedgerService has request_id; DirectOffersService does not log or pass it. |
| Stable event names | ⚠️ | Taxonomy defined (§2); not yet a field in logs. |
| Dispute | ❌ | Not implemented; no dispute event yet. |
| Auto-release (cron) | ⚠️ | No app telemetry (by design); no DB log in current cron. |

**Observability verdict:** Ready for production from a privacy and “critical path visible” perspective. Recommended improvements: (1) add `payment_request_id` to recover success log, (2) optionally propagate and log `request_id` for pay path, (3) when adding dispute, add `direct_offer_dispute_created` and same privacy/correlation rules, (4) consider DB-side logging or NOTICE for cron auto-release for ops visibility.
