# CodeGuard Review Report: Dispute Lifecycle

**Date**: 2026-03-08  
**Scope**: Dispute Lifecycle (migrations, DisputeService, SafetyViewModel, booking/work/direct_offer UI guards)  
**Reviewer**: CodeGuard (final gatekeeper)

---

## Scope

- **Change Type**: HIGH (payments/escrow, RLS, RPC)
- **Areas**: MVVM, DB, RLS, RPC (escrow guard), UI guards
- **Files Reviewed**:
  - `lib/features/safety/services/dispute_service.dart`
  - `lib/features/safety/viewmodels/safety_view_model.dart`
  - `lib/features/booking/view/booking_details_screen.dart`
  - `lib/features/work/view/work_item_details_screen.dart`
  - `lib/features/direct_offers/view/direct_offer_details_screen.dart`
  - `supabase/migrations/20260308140000_dispute_lifecycle_escrow_guard_rls.sql`
  - `supabase/migrations/20260308150000_dispute_enum_guard_resolved_at.sql`
  - `test/unit/safety/dispute_service_test.dart`

---

## Risk Rating

| Area | Rating | Notes |
|------|--------|--------|
| **Overall** | **MEDIUM–HIGH** | Escrow and RLS touched; server-side guards in place. |
| Flutter (MVVM / UI) | LOW | View uses ViewModel only; no direct Supabase in views. |
| DisputeService / SafetyViewModel | LOW | Session check; fail-closed on error; no secrets. |
| RPC (rpc_approve_delivery / rpc_finalize_auto_approval) | HIGH | Escrow release; dispute check at start of each branch. |
| RLS (disputes, dispute_messages, dispute_evidence) | MEDIUM | Deny UPDATE/DELETE on disputes; participant-only on messages/evidence. |
| Migrations (enum, trigger, view) | MEDIUM | Enum + transition guard + view recreate; order correct. |

---

## Evidence Collected

### Commands Run

- **flutter analyze**: ✅ **Passed** (after fixing one lint in test).
- **flutter test test/unit/safety/dispute_service_test.dart**: ✅ **All 4 tests passed** (submitDispute inserts with/without defendant_id, throws on empty reason, throws when not signed in).
- **flutter pub outdated**: Run; no security advisories required for this scope; Supabase/Flutter versions unchanged by this change-set.

### Docs Scanned

- `Sline_everything/DEVELOPER_GUIDE.md` (MVVM, no direct Supabase in views).
- `Sline_everything/CODE_REVIEW.md` (error handling, patterns).
- `Sline_everything/SUPABASE_SETUP.md` (§5.24–5.26 disputes, §9.4–9.5 RPCs, §17 changelog).

### Lint Fix Applied

- **test/unit/safety/dispute_service_test.dart**: Removed unnecessary cast in `_InsertCaptureQueryBuilder.insert` (line 34): use `data is Map ? Map<String, dynamic>.from(data) : null` so analyzer reports no issues.

---

## Critical Issues (BLOCKERs)

**No BLOCKERs.**

- RPC escrow paths are guarded by dispute checks before any release.
- RLS and deny policies are in place; no service_role in client code.
- UI guards delegate to SafetyViewModel; fail-closed on error (release button disabled when check fails or errors).

---

## Warnings (Should Fix)

1. **Booking details: guard by booking ID for consistency**
   - **Where**: `booking_details_screen.dart` — `_ApproveWithDisputeGuard` uses `hasOpenDisputeForTask(booking.taskId)` and, when `taskId` is empty, shows the Approve button **enabled**.
   - **Risk**: Edge case where a booking has no `task_id` (data inconsistency) would allow showing Approve; server-side RPC still blocks.
   - **Suggestion**: Use `hasOpenDisputeForBooking(booking.id)` so the same code path and semantics apply for all bookings and null `task_id` is handled inside the service. **Owner**: Implementer.

2. **FutureBuilder refetch on rebuild**
   - **Where**: All three screens use `FutureBuilder` with `context.read<SafetyViewModel>().hasOpenDisputeFor*(...)`; each rebuild can re-invoke the future.
   - **Risk**: Extra round-trips if the widget rebuilds often; low impact for a single CTA per screen.
   - **Suggestion**: Optional later improvement: cache result per (entityType, entityId) in SafetyViewModel with a short TTL to avoid repeated calls. **Owner**: Optional follow-up.

---

## Passed Checks

- ✅ **MVVM**: Views use only ViewModels (SafetyViewModel, BookingViewModel, etc.); no direct Supabase in UI.
- ✅ **Session**: `DisputeService.submitDispute` checks `auth.currentUser?.id` and throws before insert.
- ✅ **Fail-closed**: `hasOpenDisputeForTask`, `hasOpenDisputeForDirectOffer`, `hasOpenDisputeForBooking` return `true` on error so the Approve/Review button stays disabled.
- ✅ **RPC dispute guard**: `rpc_approve_delivery` and `rpc_finalize_auto_approval` check `disputes` for `status IN ('open','active')` at the start of task, booking, and direct_offer branches before any state change or ledger call.
- ✅ **RLS**: Deny UPDATE/DELETE on `disputes` for authenticated; `dispute_messages` and `dispute_evidence` have participant-only SELECT/INSERT (complainant/defendant); `dispute_evidence` insert also requires `uploader_id = auth.uid()`.
- ✅ **Search path**: RPCs use `SET search_path TO 'public'`.
- ✅ **Indexes**: `idx_disputes_task_id`, `idx_disputes_direct_offer_id`, `idx_disputes_status` added for dispute lookups.
- ✅ **Enum migration**: View dropped before altering `disputes.status`; status transition trigger and `resolved_at` trigger; view recreated with enum-safe `d.status IN ('open', 'active')`.
- ✅ **No secrets**: No tokens or keys in code or logs.
- ✅ **Error mapping**: SafetyViewModel maps errors to user-facing messages; no internal leakage.
- ✅ **Tests**: All dispute_service unit tests pass; submitDispute behavior and validation covered.

---

## Performance

- **N+1**: No N+1 in reviewed code. Dispute checks are one (or two for booking: bookings by id then disputes by task_id) lightweight queries with `.limit(1).maybeSingle()`.
- **Rebuild storms**: Dispute guard is a single FutureBuilder per CTA; no heavy work in build(). Acceptable.
- **Heavy queries**: Dispute lookups select only `id` with `eq`/`in_` and `limit(1)`; indexes added on `task_id`, `direct_offer_id`, `status`.

---

## Security

- **RLS**: Disputes INSERT remains complainant-scoped; UPDATE/DELETE explicitly denied for authenticated. `dispute_messages` and `dispute_evidence` are participant-only (SELECT/INSERT).
- **RPC escrow guard**: Release paths cannot run when an open/active dispute exists for the same task, booking’s task, or direct_offer; exception raised before any ledger or status update.
- **No service_role**: Client uses only anon/authenticated; no service role key in app.
- **Least privilege**: Deny policies and participant-only RLS align with least privilege.

---

## Dependency Status

- **flutter pub outdated**: Run; no changes required for this scope. Supabase and Flutter versions unchanged.
- **Deprecated / advisories**: None identified that block this review.
- **Recommended**: Keep existing upgrade plan; no immediate action for Dispute Lifecycle.

---

## Risk Notes

- **Threat model**: An attacker with a valid session cannot approve delivery or trigger auto-approval when a dispute is open/active; both UI and RPC enforce this. Dispute rows cannot be updated or deleted by authenticated users (only by backend/admin flows if added later).
- **Regression**: If the view `vw_unified_work_items` is queried elsewhere, the enum change and view recreate are backward-compatible for `unified_status = 'disputed'` (still derived from `d.status IN ('open','active')`).

---

## Final Decision

**APPROVED ✅**

- No BLOCKERs; verification commands passed (flutter analyze, dispute_service_test).
- Escrow and RLS are hardened; UI guards are fail-closed and MVVM-compliant.
- One non-blocking warning: prefer `hasOpenDisputeForBooking(booking.id)` on booking details for consistency and robustness; optional caching of dispute check result can be done later.

**Next actions**

1. (Optional) Switch booking details guard to `hasOpenDisputeForBooking(booking.id)` and merge with this or a follow-up PR.
2. Proceed with merge of Dispute Lifecycle scope; no further gate blocks.
