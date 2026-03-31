# Architect Report: Direct Chat Offer Flow

**Date:** 2026-03-08  
**Scope:** DirectChatOfferFlow (06_direct-chat-offer-flow)  
**Plan reference:** `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md` (Phases 0–5, gate-based)  
**Contract reference:** `.TODO/06_direct_offer_contract.md`

---

## 1) Architecture / Logic Findings and Proposed Refactors

### 1.1 Implemented and Aligned

- **Schema (Phase 1):** Migrations add `currency`, `payment_*`, `delivered_at`, `review_expires_at` to `direct_offers`; `disputes.direct_offer_id` + `chk_dispute_entity`; partial index `idx_direct_offers_processing`. Additive and conditional (IF NOT EXISTS) to avoid drift. **Evidence:** `supabase/migrations/20260319000000_direct_offer_flow_harden.sql`.
- **Trigger:** `fn_direct_offer_protect_price_currency` blocks UPDATE of `price` and `currency` when offer is not in `sent`/`unpaid`. **Evidence:** `20260319110000_direct_offer_guard_rls_ledger.sql` L6–23.
- **RLS:** `disputes_insert_own` allows INSERT when `direct_offer_id` is set and complainant is client or freelancer of that offer. **Evidence:** same migration L26–42.
- **Release fee from row:** `rpc_approve_delivery(entity_type := 'direct_offer', ...)` reads `fee_rate_applied_bps` and `price` from `direct_offers` and passes fee in `p_meta` to `process_payment_event_ledger`. **Evidence:** same migration L109–146.
- **Auto-release cron:** `run_auto_release_expired_direct_offers()` selects delivered/held/expired rows, uses same idempotency key pattern and ledger call, then updates status. **Evidence:** `20260319120000_direct_offer_auto_release_cron.sql`.
- **Model:** `DirectOffer` has nullable `currency`, `feeRateAppliedBps`, `paymentRequestId`, `paymentGatewayId`, `paymentCorrelationId`, `paymentExpiresAt`, `paymentRecoveredAt`, `deliveredAt`, `reviewExpiresAt` with correct `fromJson` mapping. **Evidence:** `lib/features/direct_offers/models/direct_offer_model.dart` L17–49, L69–87.
- **Service:** `acceptOfferWithoutPayment` stamps `fee_rate_applied_bps` (1000) and `currency` ('IQD'); `markDelivered` sets `status='delivered'`, `delivered_at`, `review_expires_at` (now + 3 days) in one UPDATE. **Evidence:** `lib/features/direct_offers/services/direct_offers_service.dart` L118–151, L316–341.
- **Tests:** Role guards (client cannot `cancelOffer`, freelancer cannot `payNow`) and state guard (`markDelivered` throws when !isActive). **Evidence:** `test/features/direct_offers/direct_offers_service_test.dart`.

### 1.2 Gaps / Proposed Refactors

| Finding | Severity | Location | Proposal |
|--------|----------|----------|----------|
| **Trigger does not protect `fee_rate_applied_bps`** | Low | Plan Phase 1 step 4 and contract imply fee lock; trigger only checks price/currency. | Extend `fn_direct_offer_protect_price_currency` to also raise when `NEW.fee_rate_applied_bps IS DISTINCT FROM OLD.fee_rate_applied_bps` and offer is not sent/unpaid. Optional: rename to `fn_direct_offer_protect_price_currency_fee` and document. |
| **ChatViewModel.cancelOffer → service.cancelOffer** | None | Chat bubble shows "Cancel Offer" only when `isSent` and `isMine` (freelancer). So chat Cancel is freelancer canceling sent offer; service `cancelOffer` is correct. Client cancel of accepted offer is on DirectOfferDetailsScreen via `cancelAcceptedOffer`. | No change. Document in DEVELOPER_GUIDE that chat Cancel = freelancer/sent only; details screen Cancel = client/accepted-unpaid. |
| **Single source of fee/currency constants** | Low | `DirectOffersService` uses `defaultFeeBps = 1000`, `defaultCurrency = 'IQD'`; RPC uses `COALESCE(v_fee_rate_bps, 1000)`. | Consider a small shared constant (e.g. `lib/core/config/` or next to LedgerService) for default fee bps and default currency so DB and app stay in sync. Optional. |

### 1.3 Data Flow Summary (Accept → Deliver → Release)

- **Accept (no payment):** Client calls `acceptOfferWithoutPayment(offerId)` → service `getOffer` then UPDATE `status='accepted', fee_rate_applied_bps=1000, currency='IQD'` → work_log. Trigger allows this (still sent→accepted; fee/currency set here once).
- **Pay:** Client pays via QiCard or wallet; ledger `escrow_hold`; status → active, payment_status → held (handled by edge/recovery/ledger; not re-reviewed here).
- **Deliver:** Freelancer calls `markDelivered(offerId)` → service checks freelancer + `isActive` → single UPDATE `status='delivered', delivered_at=now(), review_expires_at=now()+3d` → work_log. Cron can then select this row once `review_expires_at < now()`.
- **Release (client or cron):**  
  - **Client:** `completeOffer(offerId)` → service checks client + delivered + held → `rpc_approve_delivery('direct_offer', offerId)` → RPC reads fee/price from row, calls `process_payment_event_ledger(release_with_fee, ...)`, then UPDATE `payment_status='released', status='completed'`.  
  - **Cron:** `run_auto_release_expired_direct_offers()` selects delivered/held rows with `review_expires_at < now()`, same idempotency key and ledger call, then same UPDATE.

No duplicate query path for “current offer state” in this flow: single `getOffer` per action, then one UPDATE or RPC.

---

## 2) MVVM Boundary Check (Views vs ViewModel vs Service)

### 2.1 View Layer (`lib/features/direct_offers/view/`)

- **DirectOfferDetailsScreen:** Uses only `Consumer<DirectOfferDetailsViewModel>`, `context.read<DirectOfferDetailsViewModel>()`, `context.read<DirectOffersService>()` (for Provider create), `context.read<AuthSessionViewModel>()`, `context.read<PaymentService>()`, `context.read<DeepLinkService>()`. No `Supabase.instance` or `SupabaseClient` usage. Buttons (Cancel, Pay, Mark Delivered, Complete) call ViewModel methods (`vm.cancelOffer()`, `vm.createPaymentForCard()`, `vm.markDelivered()`, `vm.completeOffer()`). **Evidence:** `direct_offer_details_screen.dart` — no Supabase import; L36–44 (Provider create); L137–378 (Consumer and onPressed handlers).  
**Verdict:** Compliant.

### 2.2 ViewModel Layer (`lib/features/direct_offers/viewmodels/`)

- **DirectOfferDetailsViewModel:** Holds `DirectOffersService` and `PaymentService`; all data and actions go through these. `loadOffer`, `payNow`, `cancelOffer`, `markDelivered`, `completeOffer`, `recoverPaymentAfterCallback`, `createPaymentForCard` delegate to service/payment only. Composite state (`canPay`, `canCancel`, `canMarkDelivered`, `canComplete`) derived from `_offer` and `currentUserId`. **Evidence:** `direct_offer_details_view_model.dart` L76–199.  
**Verdict:** Compliant.

### 2.3 Service Layer (`lib/features/direct_offers/services/`)

- **DirectOffersService:** Owns all Supabase access for direct offers (`_client.from('direct_offers')`, `_client.rpc('rpc_approve_delivery')`, `_client.functions.invoke(...)`). No UI or BuildContext. **Evidence:** `direct_offers_service.dart` — full file.  
**Verdict:** Compliant.

### 2.4 Other Features (Integration)

- **Chat:** `ChatViewModel` uses `DirectOffersService` (injected/created with Supabase client); chat view only calls ViewModel. **Evidence:** `chat_view_model.dart` L39–48, L475–534; `chat_screen.dart` L165–191 (controller methods only).  
**Verdict:** Compliant.
- **Dashboard:** `DashboardViewModel` uses `DirectOffersService` from Provider (or fallback); dashboard view uses ViewModel. **Evidence:** `dashboard_view_model.dart` L31, L43, L53, L1015; `dashboard_screen.dart` L91 (read service for web payment return).  
**Verdict:** Compliant (view reads service only for optional recovery flow; action still goes through ViewModel/context; acceptable. If desired, recovery could be moved to ViewModel method only.)

**Summary:** No direct Supabase usage in any direct_offers view. ViewModel and service boundaries are respected.

---

## 3) Data Flow Map (Accept → Deliver → Release)

```
[Client] acceptOfferWithoutPayment(offerId)
    → DirectOffersService.acceptOfferWithoutPayment
        → getOffer(offerId)
        → UPDATE direct_offers SET status='accepted', fee_rate_applied_bps=1000, currency='IQD' WHERE id=offerId
        → work_log
    ← (offer in accepted/unpaid)

[Client] pay (QiCard or wallet)
    → Edge / Ledger escrow_hold → status=active, payment_status=held
    (payment_* columns set by edge before redirect per contract)

[Freelancer] markDelivered(offerId)
    → DirectOffersService.markDelivered
        → getOffer(offerId)
        → UPDATE direct_offers SET status='delivered', delivered_at=now(), review_expires_at=now()+3d WHERE id=offerId
        → work_log
    ← (offer delivered; cron can auto-release after review_expires_at)

[Client] completeOffer(offerId)  OR  [Cron] run_auto_release_expired_direct_offers()
    → rpc_approve_delivery('direct_offer', offerId)  OR  same logic in cron loop
        → SELECT ... FROM direct_offers ... FOR UPDATE (fee_rate_applied_bps, price, ...)
        → process_payment_event_ledger(release_with_fee, ..., p_meta with fee from row)
        → UPDATE direct_offers SET payment_status='released', status='completed'
    ← (offer completed)
```

Single query path per domain action; no N+1 in this flow.

---

## 4) Path Validation (Files and DB Objects)

### 4.1 Files (all exist and used)

| Path | Purpose |
|------|--------|
| `lib/features/direct_offers/models/direct_offer_model.dart` | DirectOffer model; new nullable fields present. |
| `lib/features/direct_offers/services/direct_offers_service.dart` | All Supabase calls for direct offers. |
| `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart` | Detail screen state and actions. |
| `lib/features/direct_offers/view/direct_offer_details_screen.dart` | Detail UI; ViewModel only. |
| `test/features/direct_offers/direct_offers_service_test.dart` | Role/state guard tests. |
| `supabase/migrations/20260319000000_direct_offer_flow_harden.sql` | Columns, disputes, index. |
| `supabase/migrations/20260319110000_direct_offer_guard_rls_ledger.sql` | Trigger, RLS disputes_insert_own, rpc_approve_delivery. |
| `supabase/migrations/20260319120000_direct_offer_auto_release_cron.sql` | run_auto_release_expired_direct_offers + cron. |

### 4.2 DB Objects (from migrations)

| Object | Migration | Notes |
|--------|-----------|--------|
| `direct_offers.currency` | 20260319000000 | DEFAULT 'IQD'. |
| `direct_offers.payment_request_id`, `payment_gateway_id`, `payment_correlation_id`, `payment_expires_at`, `payment_recovered_at` | 20260319000000 | Nullable. |
| `direct_offers.delivered_at`, `review_expires_at` | 20260319000000 | Nullable. |
| `idx_direct_offers_processing` | 20260319000000 | Partial index. |
| `disputes.direct_offer_id` | 20260319000000 | FK to direct_offers. |
| `chk_dispute_entity` | 20260319000000 | Exactly one of task_id or direct_offer_id. |
| `fn_direct_offer_protect_price_currency`, `trg_direct_offer_protect_price_currency` | 20260319110000 | BEFORE UPDATE. |
| `disputes_insert_own` | 20260319110000 | INSERT policy for direct_offer. |
| `rpc_approve_delivery` | 20260319110000 | direct_offer branch with fee from row. |
| `run_auto_release_expired_direct_offers` | 20260319120000 | SECURITY DEFINER. |
| `cron.job` `auto-release-expired-direct-offers` | 20260319120000 | Hourly. |

`fee_rate_applied_bps` is assumed pre-existing (migration comment in 20260319000000; SUPABASE_SETUP §5.14 references it). No new migration adds it here.

---

## 5) Contract Checks vs `.TODO/06_direct_offer_contract.md`

| Contract clause | Implementation | Status |
|-----------------|----------------|--------|
| **Payment intent:** Edge MUST write `payment_request_id`, `payment_correlation_id`, `payment_expires_at` before redirect. | Not verified in this review (edge code not in scope). App recovery uses `recoverPaymentAfterCallback(offerId, paymentRequestId)` and expects row to be updated by edge. | **Not verified** (edge out of scope). |
| **Recovery idempotency key:** Deterministic from entity_id + payment_request_id (or gateway_id). | Plan and migrations use entity_id + status + payment_status for release idempotency; recovery idempotency is in edge/ledger. | **Assumed** per plan; ledger/recovery not re-audited here. |
| **Release:** process_payment_event_ledger MUST read fee from direct_offers row for release_with_fee; MUST NOT use client p_meta for fee. | `rpc_approve_delivery` and `run_auto_release_expired_direct_offers` read `fee_rate_applied_bps` (and price) from `direct_offers` and pass in `p_meta`; no client-supplied fee. | **Met.** |
| **Release idempotency:** Same stable key as rpc_approve_delivery. | Key = `entity_id::text || ':release_with_fee:' || status || ':' || payment_status` (digest). | **Met.** |
| **Disputes:** direct_offer_id; exactly one of task_id or direct_offer_id; complainant must be client or freelancer of that offer. | `chk_dispute_entity` enforces one of task_id/direct_offer_id; `disputes_insert_own` checks complainant is party to the direct_offer. | **Met.** |

**Summary:** App and migrations satisfy the contract for release (fee from row, idempotency) and disputes. Payment intent persistence is an edge responsibility and was not verified in this codebase scan.

---

## 6) Plan and Contract Mismatch / Missing Items

- **Plan present:** Yes — `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md` exists and was used.
- **Contract present:** Yes — `.TODO/06_direct_offer_contract.md` exists and is aligned for release and disputes.
- **Minor plan/trigger mismatch:** Plan Phase 1 step 4 requires blocking UPDATE of `price`, `currency`, and `fee_rate_applied_bps` when not sent/unpaid. Implementation only blocks `price` and `currency`. **Recommendation:** Extend trigger to include `fee_rate_applied_bps` for full compliance.
- **Edge payment persistence:** Contract requires edge to write payment_* before redirect. This is outside the Flutter/SQL evidence reviewed; confirm separately with edge owner.

---

## 7) Verification Notes

- Run: `flutter test test/features/direct_offers/direct_offers_service_test.dart` — should pass (client cannot cancelOffer, freelancer cannot payNow, markDelivered throws when !isActive).
- After `markDelivered`, `SELECT delivered_at, review_expires_at FROM direct_offers WHERE id = ?` should show non-null values.
- After client or cron release, `payment_status='released'`, `status='completed'` and ledger lines should reflect fee from row (e.g. no global fee override for old offers).

---

## 8) References

- Plan: `.TODO/PLAN_DirectChatOfferFlow_2026-03-07_CRITIC.md`
- Contract: `.TODO/06_direct_offer_contract.md`
- Migrations: `supabase/migrations/20260319000000_*`, `20260319110000_*`, `20260319120000_*`
- Model: `lib/features/direct_offers/models/direct_offer_model.dart`
- Service: `lib/features/direct_offers/services/direct_offers_service.dart`
- ViewModel: `lib/features/direct_offers/viewmodels/direct_offer_details_view_model.dart`
- View: `lib/features/direct_offers/view/direct_offer_details_screen.dart`
- Tests: `test/features/direct_offers/direct_offers_service_test.dart`
- Docs: `Sline_everything/DEVELOPER_GUIDE/Direct_Offers_Feature.md`, `Sline_everything/SUPABASE_SETUP.md` §5.14
