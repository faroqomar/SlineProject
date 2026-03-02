# Checklist: Test the App – Dashboard Remediation Changes

**Purpose:** Manually verify the dashboard remediation in the running app.  
**Date:** 2026-03-02  
**Scope:** Widget moves, lazy-load by tab, wallet snapshot on entry, My Services, status display.

---

## Before you start

- [ ] App runs: `flutter run -d <device>`
- [ ] Logged in as a user (client and/or freelancer; two accounts help for full coverage)

---

## 1. Dashboard – Overview tab

| Step | What to do | Expected | ✓ |
|------|------------|----------|---|
| 1.1 | Open app and go to **Dashboard** (bottom nav). | Dashboard opens; **Overview** tab is selected. | |
| 1.2 | Look at the top/card area. | **Wallet snapshot** card shows “Total Balance” and Available / Held (or 0.00 if new user). No crash. | |
| 1.3 | Wait 1–2 seconds. | If wallet was empty, balance may load (Overview triggers wallet load on first entry). | |
| 1.4 | Check counters / activity / next actions. | Overview content loads (work items count, activity feed, or empty states). No errors. | |

---

## 2. Dashboard – Bookings tab (booking cards = new widget)

| Step | What to do | Expected | ✓ |
|------|------------|----------|---|
| 2.1 | Tap **Bookings** tab. | Tab opens; first time may show a short load, then list of Upcoming / Past (or “No bookings yet”). | |
| 2.2 | If you have bookings: check one card. | Card shows task title, due date, **status badge** (e.g. REQUEST PENDING, CONFIRMED) with correct color (e.g. gold for pending, teal for confirmed). | |
| 2.3 | Tap a **booking card**. | Navigates to **Work item details** for that booking. | |
| 2.4 | Go back to Dashboard → Bookings. | List still there; no crash. | |
| 2.5 | If card has **Accept** (provider): tap Accept. | Booking accepts (or error message). List updates / you can refresh. | |
| 2.6 | If card has **Decline** or **Cancel**: tap it. | Action runs; list updates or shows empty. | |
| 2.7 | Pull to refresh on Bookings list. | List refreshes; data reloaded. | |

---

## 3. Dashboard – Inbox tab (offer cards = new widget)

| Step | What to do | Expected | ✓ |
|------|------------|----------|---|
| 3.1 | Tap **Inbox** tab. | Tab opens; first time may show short load, then list of offers (or “No Inbox Yet”). | |
| 3.2 | If you have offers: check one card. | Card shows OFFER header, **status** (e.g. Pending, Accepted) with correct color; freelancer name, price, days. | |
| 3.3 | As **client**: on a pending offer tap **Award**. | Award flow runs; if payment is used, **Tender Payment** screen opens with task, amount, Pay / Pay Later. | |
| 3.4 | As **client**: on awarded unpaid offer tap **Pay Now** (or **Escrow Funds**). | Tender Payment screen opens; payment can be completed. | |
| 3.5 | As **client**: try **Reject** or **Refund** / **Release** where shown. | Buttons do what they say; no crash. | |
| 3.6 | As **freelancer**: on a pending offer tap **Withdraw**. | Offer withdrawn; list updates. | |
| 3.7 | Pull to refresh on Inbox. | List refreshes. | |

---

## 4. Dashboard – Work tab

| Step | What to do | Expected | ✓ |
|------|------------|----------|---|
| 4.1 | Tap **Work** tab. | Work items list (or empty). Same as before remediation. | |
| 4.2 | Tap a work item. | Opens work item details. | |

---

## 5. Lazy-load and refresh

| Step | What to do | Expected | ✓ |
|------|------------|----------|---|
| 5.1 | Fresh app start → open **Dashboard** (Overview). | Only overview data loads first (faster than loading everything). | |
| 5.2 | Switch to **Bookings** (first time in this session). | Bookings load now (may see brief loading). | |
| 5.3 | Switch to **Inbox** (first time in this session). | Inbox loads now. | |
| 5.4 | Switch back Overview → Bookings → Inbox. | No full reload each time; data already there (or pull-to-refresh to update). | |
| 5.5 | On any tab, **pull to refresh**. | Full refresh; all tabs have fresh data when you switch to them. | |

---

## 6. Profile – My Services

| Step | What to do | Expected | ✓ |
|------|------------|----------|---|
| 6.1 | Go to **Profile** (bottom nav). | Profile screen opens. | |
| 6.2 | Open **My Services** (or equivalent entry). | **My Services** screen opens. | |
| 6.3 | Wait for load. | List of your services (or “No services”) loads **without** depending on dashboard; no crash. | |

---

## 7. Quick smoke (no regression)

| Step | What to do | Expected | ✓ |
|------|------------|----------|---|
| 7.1 | Open Dashboard → each tab in order: Overview, Bookings, Work, Inbox. | All four tabs open; no crash. | |
| 7.2 | Navigate away (e.g. Profile, then Home) and back to Dashboard. | Dashboard opens again; state reasonable (e.g. same tab or Overview). | |
| 7.3 | Check status colors on booking/offer cards. | Pending ≈ gold; confirmed/accepted ≈ teal; canceled/declined/rejected ≈ red. Labels in UPPERCASE or “Pending” etc. | |

---

## 8. Optional – automated

| Step | Command | Expected | ✓ |
|------|--------|----------|---|
| 8.1 | `flutter analyze lib/features/dashboard lib/features/booking/view/widgets/dashboard_booking_card.dart lib/features/tasks/view/widgets/dashboard_offer_card.dart lib/features/wallet/view/widgets/wallet_snapshot_card.dart lib/core/utils/status_presenter.dart` | No issues (or only known unrelated warnings). | |
| 8.2 | `flutter test test/widget/dashboard/booking_card_test.dart` | All tests pass. | |

---

## Notes

- **No Manage tab:** Dashboard has 4 tabs only (Overview, Bookings, Work, Inbox). Manage was removed earlier.
- **Tender payment:** Award → Tender Payment screen uses coordinator + ViewModel; Pay / Pay Later should work if payment is configured.
- **Wallet snapshot:** Loads when you first land on Dashboard Overview; if balance is 0 and no errors, wallet load ran.

**Report issues:** Note which section (e.g. “2.3”) and what you saw vs expected; include role (client/freelancer) and whether you had test data (bookings/offers).
