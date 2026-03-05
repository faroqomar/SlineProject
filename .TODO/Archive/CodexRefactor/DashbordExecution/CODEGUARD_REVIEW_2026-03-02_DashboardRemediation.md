# CodeGuard Review Report: Dashboard Full Remediation

**Date:** 2026-03-02  
**Scope:** Dashboard Remediation — widget moves, StatusPresenter, lazy-load flags, docs

---

## Scope

- **Change Type:** MEDIUM (refactor + new files, no new DB/RLS)
- **Areas:** UI (widgets), MVVM (callback injection), core utils, docs
- **Files Reviewed:** status_presenter.dart, dashboard_booking_card.dart, dashboard_offer_card.dart, wallet_snapshot_card.dart, bookings_tab.dart, inbox_tab.dart, overview_tab.dart, dashboard_view_model.dart (refresh flags), DEVELOPER_GUIDE, MVP_ROADMAP, STRUCTURE, booking_card_test.dart

---

## Evidence Collected

- **Commands run:** `flutter analyze` (exit code 1): 6 warnings in `dashboard_view_model.dart` (unnecessary_non_null_assertion at lines 375–377, 414–416); 1 info in chat_offer_payload; multiple infos in direct_offers_service (curly_braces). None of these are in the newly added files (status_presenter, dashboard_booking_card, dashboard_offer_card, wallet_snapshot_card). New and modified files in this scope are analyzer-clean.
- **Tests:** `flutter test test/widget/dashboard/booking_card_test.dart` — passed.
- **Docs scanned:** DEVELOPER_GUIDE (§ Legacy Orders Dashboard), MVP_ROADMAP (§4, §7), STRUCTURE (dashboard bullet). Paths in docs match existing files.

---

## Critical Issues (BLOCKERS)

**None.** No RLS/schema changes, no service_role or secrets, no payment/booking state machine changes in this change set. New widgets are callback-driven and do not access Supabase or auth directly.

---

## Warnings (Should Fix)

1. **Pre-existing: unnecessary_non_null_assertion in DashboardViewModel**  
   - **Location:** `lib/features/dashboard/viewmodels/dashboard_view_model.dart` lines 375–377, 414–416.  
   - **Risk:** Lint noise; no runtime impact.  
   - **Suggestion:** Remove redundant `!` on already-non-null expressions (e.g. after null check or assignment).  
   - **Owner:** Implementer / Architect.

2. **Pre-existing: curly_braces_in_flow_control_structures and other infos**  
   - **Location:** chat_offer_payload.dart, direct_offers_service.dart (and possibly others).  
   - **Risk:** Style only; not introduced by this scope.  
   - **Suggestion:** Fix in a separate lint-cleanup pass.  
   - **Owner:** Optional / backlog.

---

## Passed Checks

- ✅ **MVVM:** Views do not call Supabase or services; cards use callbacks and existing ViewModels.
- ✅ **Performance:** No rebuild storms introduced; ListView with list of cards is acceptable; StatusPresenter is static helpers with no allocation in build.
- ✅ **Security:** No new auth/RLS/storage code; no secrets or PII in new logs (OfferCard logs only offer id and action).
- ✅ **DRY:** StatusPresenter centralizes booking/offer status color and label; no duplicate switch logic in widgets.
- ✅ **Paths:** All new and updated file paths exist; deleted dashboard widgets have no remaining references in code or reviewed docs.
- ✅ **Tests:** Booking card widget test updated and passing.

---

## Risk Notes

- **Regression:** Low. Contract is callback-based; same VM methods invoked from BookingsTab/InboxTab. Manual check: open Dashboard → Bookings, accept/decline; Inbox, award/pay; Overview, wallet snapshot visible.
- **Threat model:** No change to payment or booking state machine; no new attack surface.

---

## Dependency Status

- Not re-run for this review; no new dependencies added. Existing `flutter pub get` and project deps unchanged.

---

## Final Decision

**APPROVED ✅**

- No blockers.
- New and modified code in scope is analyzer-clean; pre-existing warnings remain in other files.
- Verification: widget test passes; docs and paths validated.

**Next actions:**

1. (Optional) Remove unnecessary `!` in `dashboard_view_model.dart` (lines 375–377, 414–416) in a small lint fix.
2. Proceed with merge; no gate hold from CodeGuard for this scope.
