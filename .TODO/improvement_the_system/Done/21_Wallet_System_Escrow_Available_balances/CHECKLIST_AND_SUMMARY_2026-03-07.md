# Wallet Escrow Available Balances — Checklist & Summary

**Plan:** PLAN_WalletEscrowAvailableBalances_2026-03-07_CRITIC  
**Date:** 2026-03-07

---

## ✅ Checklist: Verify on the actual app

Use this list to confirm everything works on a real device or simulator.

### Wallet screen
- [ ] Open **Wallet** (from dashboard or profile). Screen loads without crash.
- [ ] You see **Available** and **Escrow/Held** (and optionally Pending Withdrawal). Values come from the server (no “NaN” or wrong numbers).
- [ ] Pull to refresh: balances update (or stay zero if you have no activity).
- [ ] If the balance request fails (e.g. no network), the app does not crash; you may see zero or an error state.

### Booking: Approve delivery (unchanged flow)
- [ ] As **client**, open a booking that is **Delivered** (payment held). Open work item → **Review delivery** → tap **Approve**.
- [ ] Request succeeds; booking moves to **Completed**; freelancer’s available balance increases (check Wallet after).
- [ ] Tapping **Approve** twice quickly does not double‑credit (only one ledger release).

### Direct offer: Approve & release (updated flow)
- [ ] As **client**, open a **direct offer** that is **Delivered** (payment held). You see **Approve & release payment** (or similar).
- [ ] Tap **Approve & release**. Button shows loading (“Releasing…”) and is disabled while the request runs.
- [ ] Request succeeds; offer moves to **Completed**; freelancer’s available balance increases.
- [ ] Tapping **Approve** twice quickly does not double‑credit.

### Logs (optional)
- [ ] In console/logs, search for tag **DirectOffers** or **Wallet**. You see info/warning/error logs for complete offer and balance fetch (no raw `print()`).

### Tests (no device needed)
- [ ] Run:  
  `flutter test test/rls/ledger_rls_test.dart test/unit/wallet/ test/rls/view_security_test.dart`  
  All tests pass.

---

## What was done (short summary)

### Why we did it
- Make **direct offers** releasable by the client through the **same RPC** as bookings (`rpc_approve_delivery`), so there is one exit point for escrow release and one place for idempotency and security.
- Align app and docs with the **ledger-only** wallet model (no use of legacy `wallet_transactions`), add **logging** for wallet/direct-offer flows, and document **Withdraw** as an upcoming feature.

---

### What was **added**

| Where | What |
|--------|------|
| **Database** | New branch in `rpc_approve_delivery` for `entity_type = 'direct_offer'`: client can approve delivery and release escrow; same deterministic idempotency key and row lock as booking. (Migration `20260307120000_rpc_approve_delivery_direct_offer.sql`, applied via Supabase MCP.) |
| **DirectOffersService** | Logging: at start of complete offer, on “not client” / “invalid state”, on RPC error, and on success. (Tag: `DirectOffers`.) |
| **WalletService** | Logging when balance fetch fails (warning + error). (Tag: `Wallet`.) |
| **Docs / .TODO** | Contract for `rpc_approve_delivery`, LIVE_SCAN, RLS matrix, execution log. Diagram 21: “Withdraw = Upcoming feature”; entry point = `process_payment_event_ledger` / `rpc_approve_delivery`. Wallet_Feature §4 “Approve delivery”, Direct_Offers_Feature and SUPABASE_SETUP updated; Sline_Log entry. |

---

### What was **removed**

| Where | What |
|--------|------|
| **DirectOffersService** | The previous way of completing an offer: **removed** the direct call to `LedgerService.submitPaymentEvent('release_with_fee', 'direct_offer', ...)`. Completion now goes only through `rpc_approve_delivery`. |
| **Test comment** | In `view_security_test.dart`, the old comment that mentioned “wallet_transactions” was **removed** and replaced with a note that canonical views are `vw_wallet_balances_user` and `vw_wallet_activity_user`. |

---

### What was **modified**

| Where | What |
|--------|------|
| **DirectOffersService.completeOffer()** | **Before:** Called `LedgerService.submitPaymentEvent(...)` for release. **After:** Calls `_client.rpc('rpc_approve_delivery', params: {'entity_type': 'direct_offer', 'entity_id': offerId})`. Validation (client, delivered, held) and work_log call unchanged. |
| **WalletService.getWalletBalance()** | **Before:** On exception, returned zero with no log. **After:** On exception, logs a warning (tag `Wallet`, error object) and then returns zero. |
| **Diagram 21** | **Before:** Said “Withdraw is out of scope” and “process_payment_event” as entry point. **After:** “Withdraw = Upcoming feature”; entry point text = “process_payment_event_ledger (and rpc_approve_delivery for release)”. |
| **DEVELOPER_GUIDE / Wallet_Feature** | **Before:** No dedicated “approve delivery” section. **After:** New §4 “Approve delivery (single exit point)”; §5 is process_payment_event_ledger; later sections renumbered (§6–§11). `p_related_entity_type` now includes `direct_offer`. |
| **DEVELOPER_GUIDE / Direct_Offers_Feature** | **Before:** Step 5 and §4.5 said client calls `process_payment_event_ledger('release_with_fee', 'direct_offer', id)`. **After:** Says client flow uses `rpc_approve_delivery(entity_type: 'direct_offer', entity_id)` and that `DirectOffersService.completeOffer()` calls that RPC. |
| **SUPABASE_SETUP.md §9.5** | **Before:** Only task and booking branches described. **After:** Parameters list `entity_type` (task, booking, direct_offer); new bullet for **Direct offers** (lock, validate client, stable key, ledger call, update `direct_offers`); migration `20260307120000` added. |
| **Sline_Log.md** | **Before:** No entry for this work. **After:** New entry “Wallet Escrow Available Balances — direct_offer in rpc_approve_delivery (2026-03-07)” with implemented items, impact, and references. |

---

## One-line recap

**We added the direct_offer branch to `rpc_approve_delivery` in the DB, switched direct-offer completion in the app to use that RPC instead of calling the ledger directly, added logging for wallet and complete-offer flows, and updated docs and diagram so Withdraw is “Upcoming” and approve delivery is clearly the single exit for releasing escrow.**
