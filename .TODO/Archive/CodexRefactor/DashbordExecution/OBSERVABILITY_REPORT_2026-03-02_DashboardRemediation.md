# Observability Report: Dashboard Full Remediation

**Date:** 2026-03-02  
**Scope:** Dashboard Full Remediation (widget moves, status presenter, lazy-load flags, docs)

---

## 1. Summary

This change set did not introduce new critical user flows; it relocated UI components and added a pure presentation helper. Observability review focuses on: (1) existing logging in touched areas; (2) no new PII/sensitive logging; (3) no new flows requiring correlation IDs.

---

## 2. Telemetry Gaps

| Area | Status | Notes |
|------|--------|-------|
| Dashboard ViewModel | ✅ Already instrumented | `AppLogger` used for role switch, cache hit, load start/error/success, booking/inbox actions (e.g. accept/decline/cancel), ledger refund. Tag `_kTag` / `DashboardViewModel` used consistently. |
| Dashboard repository | ✅ Already instrumented | Logs for role update, fetch errors, activity feed, wallet balances. No raw PII in messages. |
| New widgets | N/A | `DashboardBookingCard`, `WalletSnapshotCard`, `StatusPresenter` are UI-only; no new service/ViewModel calls. No requirement to add logs inside these widgets. |
| DashboardOfferCard | ✅ Retained | Existing `AppLogger.i(..., tag: 'OfferCard')` for button taps (reject, award, pay, escrow, accept, release, refund, withdraw) retained in `dashboard_offer_card.dart`. No sensitive data in messages (only offer id). |

No new critical flows were added; existing dashboard/offer logging remains sufficient for debugging award/pay/refund paths.

---

## 3. Event Taxonomy

No new event taxonomy required. Existing dashboard/inbox flows continue to use:

- Role switch, cache hit/miss, tab load (overview/bookings/inbox), refresh, booking actions, offer actions.
- Offer card tap events already use stable tag `OfferCard` and log action + offer id only.

---

## 4. Privacy / “What NOT to Log”

| Rule | Status |
|------|--------|
| No secrets/tokens/passwords | ✅ Not logged in changed code. |
| No raw PII in new code | ✅ `StatusPresenter` has no logging. New cards do not log user data. |
| Offer card | ✅ Only logs action name and `offer.id` (UUID); no payment details or user names. |
| Booking card | ✅ No logging in widget; actions logged in ViewModel with booking id only. |

No new privacy risks identified.

---

## 5. Correlation Strategy

- Multi-step flows (award → pay, refund) remain in ViewModel/service layer where existing logging (e.g. ledger trace id) is used.
- New code does not add multi-step flows; no new correlation ID propagation required.

---

## 6. Recommendations

- **Optional:** Add a single info log in `DashboardViewModel` when lazy-load triggers (e.g. first time Bookings or Inbox tab loads), if not already covered by existing “Bookings tab data loaded” / “Inbox tab data loaded” logs. (Current implementation already logs these in `_loadBookingsData` / `_loadInboxData`.)
- No mandatory observability changes for this scope.

---

**Observability output:** No blockers. Existing AppLogger usage and privacy practices maintained. No new events or correlation IDs required for this change set.
