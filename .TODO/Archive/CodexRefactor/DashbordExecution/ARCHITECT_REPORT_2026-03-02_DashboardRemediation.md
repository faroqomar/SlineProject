# Architect Report: Dashboard Full Remediation

**Date:** 2026-03-02  
**Scope:** Dashboard Full Remediation (widget moves, lazy-load flags, status presenter, docs sync)  
**Plan Reference:** `.TODO/PLAN_Dashboard_Full_Remediation_2026-03-01.md`

---

## 1. Summary

Review covered the implementation of: (1) dashboard card widgets moved to owning features with callback-based API; (2) shared `StatusPresenter` in core; (3) lazy-load flags set on full refresh in `DashboardViewModel`; (4) doc updates in DEVELOPER_GUIDE, MVP_ROADMAP, STRUCTURE. No DB or RPC changes in this slice.

---

## 2. MVVM Boundary Check

| Layer | Finding | Evidence |
|-------|---------|----------|
| **View** | ✅ Clean | `BookingsTab` uses `Consumer<DashboardViewModel>` and passes VM methods as callbacks to `DashboardBookingCard`. No Supabase or service calls in tab or card widgets. |
| **View** | ✅ Clean | `DashboardBookingCard` is presentation-only; all actions via callbacks (`onAccept`, `onDecline`, etc.). Navigation passed as `onTapDetails(booking)` from parent. |
| **View** | ✅ Clean | `DashboardOfferCard` and `WalletSnapshotCard` use only props and `context.watch<WalletViewModel>`; no direct data access. |
| **ViewModel** | ✅ Clean | `DashboardViewModel` unchanged in responsibility; only added `_bookingsLoaded`/`_inboxLoaded = true` after full `_loadData()`. |
| **Service** | N/A | No new services; existing dashboard/booking/tasks/wallet services unchanged in this change set. |

**Conclusion:** MVVM boundaries are respected. Views do not call Supabase or services directly; cards depend on parent-injected callbacks and existing ViewModels.

---

## 3. Data Flow Map

- **BookingsTab** → `Consumer<DashboardViewModel>` → reads `vm.bookings`, `vm.currentRole`, passes `vm.acceptBooking`, `vm.declineBooking`, etc. to `DashboardBookingCard`. Navigation to `WorkItemDetailsScreen` is in the tab (dashboard feature), so dashboard correctly owns the navigation contract; booking feature only renders the card.
- **InboxTab** → `Consumer<DashboardViewModel>` → passes offer + callbacks to `DashboardOfferCard` (tasks feature). Same pattern: dashboard owns when to refresh and which actions to invoke.
- **OverviewTab** → uses `WalletSnapshotCard` (wallet feature) which `context.watch<WalletViewModel>`; wallet load triggered in `OverviewTab.initState` (post-frame). Single source of truth for balance remains `WalletViewModel`.
- **StatusPresenter** → pure static helpers; no state, no I/O. Used by `DashboardBookingCard` and `DashboardOfferCard` for status color/label only.

---

## 4. Path Validation

| Path | Exists | Notes |
|------|--------|-------|
| `lib/core/utils/status_presenter.dart` | ✅ | New file; referenced by booking and tasks cards. |
| `lib/features/booking/view/widgets/dashboard_booking_card.dart` | ✅ | New; referenced by `bookings_tab.dart`. |
| `lib/features/tasks/view/widgets/dashboard_offer_card.dart` | ✅ | New; referenced by `inbox_tab.dart`. |
| `lib/features/wallet/view/widgets/wallet_snapshot_card.dart` | ✅ | New; referenced by `overview_tab.dart`. |
| Removed: `lib/features/dashboard/view/widgets/booking_card.dart` | ✅ Deleted | Replaced by booking feature card. |
| Removed: `lib/features/dashboard/view/widgets/offer_card.dart` | ✅ Deleted | Replaced by tasks feature card. |
| Removed: `lib/features/dashboard/view/widgets/wallet_snapshot_card.dart` | ✅ Deleted | Replaced by wallet feature card. |

All references in docs (DEVELOPER_GUIDE, STRUCTURE) point to the new paths; no stale references to deleted dashboard widgets found in code (test updated to `DashboardBookingCard`).

---

## 5. Contract Checks

- **Dashboard ↔ Booking:** BookingsTab supplies all actions and navigation; `DashboardBookingCard` does not depend on `DashboardViewModel`. Contract is callback-based; no breaking change to dashboard’s ability to refresh or perform booking actions.
- **Dashboard ↔ Tasks:** Same for InboxTab and `DashboardOfferCard`; CTA resolution remains in tasks (UnifiedCtaResolver); dashboard only passes callbacks.
- **Dashboard ↔ Wallet:** `WalletSnapshotCard` only reads `WalletViewModel`; overview tab triggers load. No new contract beyond existing WalletViewModel API.

---

## 6. Risks and Refactor Notes

- **Risk (LOW):** Duplicate callback lists in BookingsTab (upcoming + past both build `DashboardBookingCard` with same props). Acceptable for clarity; could extract a helper if list grows.
- **Refactor not done:** Plan’s ViewModel split (role/overview/bookings/work/inbox + facade) was explicitly cancelled; single `DashboardViewModel` with lazy-load and cache remains. Documented in execution summary.

---

## 7. Verification

- `flutter test test/widget/dashboard/booking_card_test.dart` — passes (tests updated for `DashboardBookingCard` and callback capture).
- No new direct Supabase or service calls in any view added or modified in this scope.

---

**Architect output:** No blockers. Architecture and data flow align with plan and MVVM rules. Paths and contracts validated.
