# CodeGuard Review Report: 14a Dispute Extension

**Date:** 2026-03-08  
**Scope:** 14a Dispute Extension (Frozen guards, partial unique indexes, rpc_submit_dispute, task/direct_offer dispute UI, banners, ErrorMapper)  
**Plan:** `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`  
**Spec:** `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`

---

## Scope

- **Change Type:** HIGH (DB/RPC guards, dispute lifecycle, UI entry points)
- **Areas:** DB (migration), RPC (submit_delivery, request_revision, submit_dispute), App (DisputeService, SafetyViewModel), UI (work_item_details_screen, direct_offer_details_screen, booking_details_screen), ErrorMapper
- **Files Reviewed:**
  - `supabase/migrations/20260308160000_14a_dispute_extension_frozen_guards.sql`
  - `lib/features/safety/services/dispute_service.dart`
  - `lib/features/safety/viewmodels/safety_view_model.dart`
  - `lib/features/work/view/work_item_details_screen.dart`
  - `lib/features/direct_offers/view/direct_offer_details_screen.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
  - `lib/core/utils/error_mapper.dart`
  - `test/unit/safety/dispute_service_test.dart`
  - `Sline_everything/SUPABASE_SETUP.md` (disputes §5.24, §9.1, §9.2, §9.2a)

---

## Risk Rating

| Area | Rating | Notes |
|------|--------|--------|
| **Overall** | **MEDIUM** | DB/RPC and app logic are sound; one analyzer info and minor UI/performance notes. |
| **DB** | LOW | Additive migration; indexes and RPCs correctly defined; no RLS changes. |
| **RPC** | LOW | SECURITY DEFINER, auth.uid(), SET search_path; no injection; errors mapped. |
| **App** | LOW | MVVM respected; service uses RPC only for submit; no secrets in logs. |
| **UI** | MEDIUM | Multiple dispute-status calls per screen (see Performance); one guard inconsistency (see Warnings). |

---

## Evidence Collected

### Commands Run

| Command | Result |
|--------|--------|
| `flutter analyze` | 1 **info**: `test/unit/safety/dispute_service_test.dart` — `postgrest` isn't a direct dependency of the importing package (`depend_on_referenced_packages`). Not a blocker. |
| `flutter test test/unit/safety/` | **PASS** — 4 tests (submitDispute task_id/reason, without defendant, empty reason, not signed in). |

### Docs Scanned

- `Sline_everything/DEVELOPER_GUIDE.md`, `SUPABASE_SETUP.md` (§5.24, §9.1, §9.2, §9.2a), `STRUCTURE.md`, `MVP_ROADMAP.md`, `CODE_REVIEW.md`
- Plan and spec as above

### Web Freshness

- No dependency or security advisory search was run for this review; scope was code and migration only.

---

## Security

### RLS Unchanged

- **Finding:** No new or modified RLS in `20260308160000_14a_dispute_extension_frozen_guards.sql`. Existing `disputes_insert_own` (and deny UPDATE/DELETE) remain as in `20260308140000`, `20260319110000`.
- **Verdict:** ✅ RLS unchanged as planned.

### rpc_submit_dispute SECURITY DEFINER

- **Finding:** All three RPCs use `SECURITY DEFINER` and `SET search_path TO public` (or `SET search_path TO 'public'` / `SET search_path TO public`). Complainant is set from `auth.uid()` inside the RPC; no client-supplied complainant_id.
- **Verdict:** ✅ Correct; no privilege escalation from client.

### auth.uid() Usage

- **Finding:** `rpc_submit_delivery` and `rpc_request_revision` check `auth.uid() IS NULL` and use it for participant checks. `rpc_submit_dispute` sets `_uid := auth.uid()` and uses it for `complainant_id` on INSERT.
- **Verdict:** ✅ auth.uid() used consistently for identity.

### Injection

- **Finding:** All entity IDs and notes passed as typed params (uuid/text); RPCs use variables in SQL (e.g. `entity_id`, `p_task_id`, `p_reason`). No string concatenation into dynamic SQL.
- **Verdict:** ✅ No SQL injection identified.

### Logging: Reason / Defendant Not Exposed

- **Finding:** `DisputeService.submitDispute` logs only `event_name`, `task_id` or `direct_offer_id` (no `reason`, no `defendantId`). `SafetyViewModel` on submit failure logs only `task_id` or `direct_offer_id` in JSON; `error` may contain server message but not user-entered reason.
- **Verdict:** ✅ Dispute reason and defendant_id are not written to logs.

### Vulnerability Summary

- **Conclusion:** No vulnerability identified. RLS unchanged; RPCs are SECURITY DEFINER with auth.uid(); no injection; no sensitive dispute data in logs.

---

## Performance

### Index Usage (Partial Unique Indexes)

- **Finding:** Migration adds:
  - `uq_disputes_one_open_active_per_task` ON `disputes (task_id)` WHERE `task_id IS NOT NULL AND status IN ('open','active')`
  - `uq_disputes_one_open_active_per_direct_offer` ON `disputes (direct_offer_id)` WHERE `direct_offer_id IS NOT NULL AND status IN ('open','active')`
- RPCs and app queries filter by `task_id` or `direct_offer_id` and `status IN ('open','active')`, so these partial indexes support both uniqueness checks and the EXISTS lookups used in Frozen guards and in `hasOpenDispute*` / `getDisputeStatus*`.
- **Verdict:** ✅ Partial unique indexes are appropriate and will be used for those lookups.

### N+1 Risk (getDisputeStatus* / hasOpenDispute* per Banner)

- **Finding:** Each screen uses FutureBuilders that call SafetyViewModel:
  - **work_item_details_screen:** One `_DisputeBannerContent` (getDisputeStatus for task/booking/direct_offer) + `_ReportIssueGuard` (hasOpenDispute) + `_ReviewWithDisputeGuard` (hasOpenDispute) → up to **3** calls per entity (status + 2× hasOpen).
  - **direct_offer_details_screen:** `_DirectOfferDisputeBanner` (hasOpen then getStatus = 2 calls) + `_ReportIssueGuardDirectOffer` (hasOpen) + `_ApproveWithDisputeGuard` (hasOpen) → up to **4** calls for same offer.
  - **booking_details_screen:** `_BookingDisputeBanner` (hasOpen then getStatus = 2) + `_ApproveWithDisputeGuard` (hasOpen) → up to **3** calls for same booking.
- So: not N+1 over a list of items, but **multiple requests per screen for the same entity** (status + hasOpen duplicated). Cold path: first load of each screen triggers these; no caching across the FutureBuilders.
- **Verdict:** ⚠️ **Warning.** No blocker; acceptable for single-entity detail screens. Optional improvement: cache dispute status/hasOpen per entity in SafetyViewModel (or a small cache in the screen) to avoid duplicate network calls when both banner and guards are shown.

### Cold Path Impact

- **Finding:** Frozen guards in `rpc_submit_delivery` and `rpc_request_revision` add one EXISTS subquery each (task or booking→task_id then EXISTS). Indexes on `disputes(task_id)` and `disputes(direct_offer_id)` already exist (`20260308140000`); partial unique indexes add uniqueness and support the same lookups.
- **Verdict:** ✅ Negligible cold path impact; EXISTS is selective and index-backed.

---

## Compatibility

### Backward Compatibility (Old App Direct INSERT vs rpc_submit_dispute)

- **Finding:** Migration is additive only: new RPCs and indexes; no drop of `disputes_insert_own`. Direct INSERT into `disputes` remains allowed by RLS for authenticated users (complainant_id = auth.uid(), task_id or direct_offer_id with party check). Partial unique indexes prevent a **second** open/active dispute per entity regardless of path (RPC or direct INSERT). Eligibility (task in_progress|delivered, direct_offer active|delivered) is enforced **only** in `rpc_submit_dispute`, not on direct INSERT.
- **Implication:** Old app using direct INSERT can still create one dispute per entity (second would hit unique violation). It can create disputes for ineligible entity states until it switches to `rpc_submit_dispute`. Plan already states: "Old app that inserts disputes directly may get rejection from insert guard until it switches to rpc_submit_dispute" — with the nuance that the "insert guard" is the RPC; direct INSERT is not guarded for eligibility.
- **Verdict:** ✅ Additive; backward compatible. Recommend docs/plan note that eligibility is enforced only when using `rpc_submit_dispute`.

### Migration Additive Only

- **Finding:** No tables dropped; no columns removed; no RLS policies removed. New: two partial unique indexes, one new function `rpc_submit_dispute`, and replacements for `rpc_submit_delivery` and `rpc_request_revision` (same signatures, added Frozen guard at start). GRANT EXECUTE for authenticated on all three.
- **Verdict:** ✅ Migration is additive only.

---

## Verification Commands

### Flutter

```bash
flutter analyze
# Result: 1 info (postgrest in test) — acceptable.

flutter test test/unit/safety/
# Result: 4/4 passed.
```

### SQL (Verify Indexes and RPC Existence)

Run against the target DB after applying the migration:

```sql
-- Partial unique indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'disputes'
  AND indexname IN (
    'uq_disputes_one_open_active_per_task',
    'uq_disputes_one_open_active_per_direct_offer'
  );

-- RPCs exist and are executable by authenticated
SELECT p.proname, pg_get_function_identity_arguments(p.oid)
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('rpc_submit_delivery', 'rpc_request_revision', 'rpc_submit_dispute');
```

---

## Critical Issues (BLOCKERS)

**None.** No blocker identified that would require halting release.

---

## Warnings (Should Fix)

1. **flutter analyze — test dependency**  
   - **Suggestion:** Add `postgrest` to `dev_dependencies` in `pubspec.yaml` if the test imports it directly, or remove the direct import and use types from `supabase_flutter` only.  
   - **Owner:** Implementer.

2. **Duplicate dispute-status calls per screen**  
   - **Suggestion:** Consider caching `hasOpenDispute*` / `getDisputeStatus*` per entity in SafetyViewModel (or a short-lived cache) so that banner + guards do not each trigger separate requests for the same entity.  
   - **Owner:** Optional; performance improvement.

3. **_ReportIssueGuard (work_item_details_screen) and direct_offer**  
   - **Finding:** `_ReportIssueGuard` branches on `sourceType == 'booking'` (hasOpenDisputeForBooking) else uses hasOpenDisputeForTask. It does not handle `sourceType == 'direct_offer'` with `hasOpenDisputeForDirectOffer`. Today `_canShowReportIssue` only allows `sourceType == 'task'`, so the Report Issue button is never shown for direct_offer on this screen (direct_offer uses its own screen). If later the button is shown for direct_offer here, the guard would incorrectly call hasOpenDisputeForTask(direct_offer_id).  
   - **Suggestion:** In `_ReportIssueGuard.build`, add an explicit branch for `sourceType == 'direct_offer'` using `hasOpenDisputeForDirectOffer(entityId)` for consistency and future-proofing.  
   - **Owner:** Implementer.

---

## Passed Checks

- ✅ RLS unchanged; no new policies in 14a migration.
- ✅ rpc_submit_delivery, rpc_request_revision, rpc_submit_dispute use SECURITY DEFINER and auth.uid(); no injection.
- ✅ Dispute reason and defendant_id not logged.
- ✅ ErrorMapper covers Frozen guard and rpc_submit_dispute messages (submit_delivery, request_revision, entity not eligible, open or active dispute already exists, reason required, exactly one of task_id or direct_offer_id).
- ✅ Partial unique indexes defined and consistent with RPC/app predicates.
- ✅ Migration additive only; backward compatible with direct INSERT (single open/active enforced by index; eligibility only in RPC).
- ✅ MVVM: no direct Supabase in views; dispute actions go through SafetyViewModel / DisputeService.
- ✅ Task Report Issue on work_item_details_screen when task in_progress|delivered and no open dispute; direct_offer Report Issue on direct_offer_details_screen when active|delivered and no open dispute; booking Report Issue on booking_details_screen when delivered.
- ✅ Banners show "Dispute under review" vs "Work frozen — in dispute" using getDisputeStatus* on booking, task/work item, and direct_offer screens.
- ✅ Safety unit tests (submitDispute) pass.

---

## Risk Notes

- **Threat model:** Frozen guards and single-open/active enforcement are in place at DB and RPC level; bypass would require either direct INSERT (still subject to RLS and unique index) or calling old RPCs without the guard (not possible after migration). No admin flow in app scope; admin actions are out of scope.
- **Regression:** Any client that still performs direct INSERT into `disputes` for ineligible entity status will not be rejected by DB (only by app if it switches to RPC). Second dispute per entity is rejected by unique index regardless of path.

---

## Dependency Status

- **Outdated / deprecated / security:** Not assessed in this review (no `flutter pub outdated` or web search for advisories). Recommend running as part of release checklist.

---

## Final Decision

**APPROVED ✅**

No blockers. One analyzer info (test dependency), one consistency improvement for _ReportIssueGuard + direct_offer, and optional caching for dispute-status calls. Safe to release from a CodeGuard perspective; Orchestrator need not halt.

---

## Next Actions

1. (Optional) Fix analyzer info: add `postgrest` to dev_dependencies or remove direct import in `dispute_service_test.dart`.
2. (Optional) Add `sourceType == 'direct_offer'` branch in `_ReportIssueGuard` in work_item_details_screen using `hasOpenDisputeForDirectOffer(entityId)`.
3. (Optional) Cache dispute status/hasOpen per entity in SafetyViewModel to reduce duplicate calls on detail screens.
4. Run SQL verification (indexes + RPC existence) after applying the migration in target environment.
