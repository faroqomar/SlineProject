# Observability Report: Dispute Lifecycle

**Date:** 2026-03-08  
**Scope:** Dispute Lifecycle (escrow guard, RLS, dispute status enum, UI dispute guards)  
**Agent:** Observability (SLineObservability)

---

## 1. Telemetry Gaps (What Is Logged vs What Should Be)

### 1.1 Dispute Submit

| Aspect | Currently logged | Should log | Gap |
|--------|------------------|------------|-----|
| Success | Yes — `DisputeService.submitDispute`: `AppLogger.i('Dispute submitted', tag: 'Safety', json: { task_id })` | event_name, feature, entity_id (task_id), no PII | Add stable `event_name` (e.g. `safety_dispute_submitted`), optional `screen`/source if passed from VM. |
| Failure (service) | No — service throws; no log before throw for "signed in" or "reason" validation | Log validation failures at debug level with operation name only (no reason text to avoid PII). | Add debug log on validation failure; keep exception for caller. |
| Failure (VM) | Yes — `SafetyViewModel.submitDispute` catch: `AppLogger.e('Submit dispute failed', tag: 'SafetyVM', error, stackTrace)` | Include entity_id (task_id) and operation in json for traceability. | VM error log has no `task_id` or `event_name` — cannot correlate without scanning message. |

**Conclusion:** Submit success is logged with `task_id` only. Submit failure is logged in VM without `task_id` or stable event name. Validation failures in the service are not logged.

### 1.2 Dispute Check (hasOpenDispute*)

| Aspect | Currently logged | Should log | Gap |
|--------|------------------|------------|-----|
| Open dispute found (task) | Yes — `DisputeService.hasOpenDisputeForTask`: `AppLogger.d(..., json: { task_id })` when `hasOpen == true` | Same + optional event_name for analytics. | Minor: add event_name for consistency. |
| Open dispute found (direct offer) | Yes — `DisputeService.hasOpenDisputeForDirectOffer`: `AppLogger.d(..., json: { direct_offer_id })` when `hasOpen == true` | Same. | OK. |
| Open dispute found (booking) | No — `hasOpenDisputeForBooking` delegates to `hasOpenDisputeForTask`; only task path logs. | When dispute found for booking, log booking_id (or task_id) for consistency. | Booking path logs only at task level; no `booking_id` in log. |
| Check failure (task) | Yes — `AppLogger.e('Failed to check open dispute for task', tag: 'Safety', error, stackTrace)` | Include `task_id` in json so support can trace. | Error log has no `task_id` — hard to correlate. |
| Check failure (direct offer) | Yes — same pattern. | Include `direct_offer_id`. | Error log has no `direct_offer_id`. |
| Check failure (booking) | Yes — `AppLogger.e('Failed to check open dispute for booking', ...)` | Include `booking_id`. | Error log has no `booking_id`. |
| Negative result (no open dispute) | Not logged | Optional: debug-only "no open dispute" with entity id to confirm guard path. | Low priority; can add debug if needed. |

**Conclusion:** “Approve blocked” (open dispute found) is logged at debug with entity id for task and direct_offer; booking goes through task so only task_id appears. All **error** paths for dispute checks lack entity ids, which hurts traceability.

### 1.3 Approve Blocked (UI)

| Aspect | Currently logged | Should log | Gap |
|--------|------------------|------------|-----|
| Button state | Not logged in UI (correct — no AppLogger in views) | N/A | OK; decision to block comes from service/VM. |
| When guard disables button | Only via `DisputeService` debug log when `hasOpen == true` | Same. | No gap; no need to log in UI. |

**Conclusion:** “Approve blocked” is observable only via existing debug logs in `DisputeService` when an open dispute is found. No additional UI logging required.

---

## 2. Event Taxonomy (Tag: Safety; What NOT to Log)

### 2.1 Domain and Tag

- **Feature / domain:** `safety`  
- **AppLogger tag:** `Safety` (service), `SafetyVM` (viewmodel) — already used consistently.

### 2.2 Recommended Event Names (Stable, snake_case)

| Event name | When | Level | Entity IDs in payload |
|------------|------|--------|------------------------|
| `safety_dispute_submitted` | After successful insert in `submitDispute` | info | task_id (required); direct_offer_id if/when supported |
| `safety_dispute_submit_failed` | When VM catches from `submitDispute` | error | task_id |
| `safety_dispute_check_open_found` | When hasOpenDispute* returns true (approve blocked) | debug | task_id **or** direct_offer_id **or** booking_id (one per call) |
| `safety_dispute_check_failed` | When hasOpenDispute* throws | error | task_id **or** direct_offer_id **or** booking_id |

### 2.3 What NOT to Log (Privacy / Safety)

- **Never log:** `reason` (user-written dispute text), `defendant_id`, `complainant_id`, or any other user UUID in plain text if policy forbids user ids in logs.
- **Do not log:** Full email, phone, chat content, or attachment content.
- **Allowed with project policy:** Non-PII entity ids: `task_id`, `booking_id`, `direct_offer_id` (UUIDs that identify work/booking/offer, not the user per se). If project policy forbids any UUIDs in logs, use redacted forms (e.g. last 4 chars of id) or omit; current code already logs `task_id` / `direct_offer_id` in Safety flows — confirm with policy.
- **Error content:** Log exception type and sanitized message (e.g. PostgrestException message); avoid logging full request/response bodies. `AppLogger.e` already forwards to `CrashReportingService`; ensure crash backend does not store PII.

---

## 3. Privacy-Safe Logging Plan

1. **No user ids in plain text if policy forbids**  
   - Today: only `task_id` and `direct_offer_id` are in Safety logs (no complainant_id/defendant_id).  
   - Plan: keep it that way; do not add complainant_id/defendant_id to logs. If policy allows opaque entity ids (task/booking/offer), keep current entity_id logging; otherwise switch to redacted (e.g. `task_id_suffix: last4`) or remove.

2. **No dispute reason or free text**  
   - Do not log `reason` or any user-entered description. Already not logged.

3. **VM error logs**  
   - Add only non-PII context: e.g. `task_id`, `event_name: safety_dispute_submit_failed`. No user ids, no reason.

4. **Service error logs**  
   - In `hasOpenDisputeForTask`, `hasOpenDisputeForDirectOffer`, `hasOpenDisputeForBooking`: add corresponding entity id to the existing `AppLogger.e` json payload (task_id, direct_offer_id, booking_id) so errors are traceable without PII.

5. **Crash reporting**  
   - `AppLogger.e` already calls `CrashReportingService.recordError`. Ensure crash backend strips or masks any context that might contain PII; dispute logs should only add entity ids (or redacted ids), not user ids or reason.

---

## 4. Correlation Strategy (task_id / offer_id / booking_id)

- **Dispute submit:** Correlate by `task_id` (and in future, if disputes support direct offers, by `direct_offer_id`). Use same id in success and failure logs.
- **Dispute check (approve blocked):** Correlate by the entity being checked:
  - Booking details screen → `task_id` (from booking); optional `booking_id` in log if we add it.
  - Work item details (Review button) → `entity_id` + `sourceType` (task / booking / direct_offer); log as task_id, booking_id, or direct_offer_id depending on sourceType.
  - Direct offer details screen → `direct_offer_id`.
- **No correlation_id today:** Dispute flow does not generate or propagate a `correlation_id`. For multi-step flows (e.g. submit → status change → resolve), consider adding a single `correlation_id` (e.g. dispute_id after insert) and passing it through VM so all subsequent logs for that dispute can be tied together. Current scope only has submit + check; correlation_id can be Phase 2.

**Concrete correlation fields in logs:**

- `task_id` — for task-scoped dispute submit and for hasOpenDisputeForTask / booking (via task).
- `direct_offer_id` — for direct-offer dispute check and (if added) direct-offer dispute submit.
- `booking_id` — for hasOpenDisputeForBooking when we log at booking level (e.g. in error path or when “open found” is reported for booking context).

---

## 5. Evidence: Files Scanned and Line References (AppLogger)

### 5.1 lib/features/safety/services/dispute_service.dart

| Line(s) | Call | Level | Payload |
|---------|------|--------|---------|
| 31–35 | `AppLogger.i('Dispute submitted', tag: 'Safety', json: { task_id })` | info | task_id only |
| 52–56 | `AppLogger.d('Open dispute found for task; approve delivery blocked', tag: 'Safety', json: { task_id })` | debug | task_id |
| 60–65 | `AppLogger.e('Failed to check open dispute for task', tag: 'Safety', error, stackTrace)` | error | no entity id |
| 83–87 | `AppLogger.d('Open dispute found for direct offer; approve release blocked', tag: 'Safety', json: { direct_offer_id })` | debug | direct_offer_id |
| 91–96 | `AppLogger.e('Failed to check open dispute for direct offer', ...)` | error | no entity id |
| 115–119 | `AppLogger.e('Failed to check open dispute for booking', ...)` | error | no entity id |

**Note:** `hasOpenDisputeForBooking` does not log when an open dispute is found; it delegates to `hasOpenDisputeForTask`, so “open for booking” is only visible as “open for task” with task_id.

### 5.2 lib/features/safety/viewmodels/safety_view_model.dart

| Line(s) | Call | Level | Payload |
|---------|------|--------|---------|
| 37–41 | `AppLogger.e('Submit report failed', tag: 'SafetyVM', error, stackTrace)` | error | no entity_id |
| 81–86 | `AppLogger.e('Submit dispute failed', tag: 'SafetyVM', error, stackTrace)` | error | no task_id or event_name |

### 5.3 lib/features/booking/view/booking_details_screen.dart

- No AppLogger usage (correct for view). Dispute entry points: `_showDisputeDialog` (line 425), `_ApproveWithDisputeGuard` (line 627) calling `SafetyViewModel.submitDispute` and `hasOpenDisputeForTask(taskId)`.

### 5.4 lib/features/work/view/work_item_details_screen.dart

- No AppLogger usage (correct for view). Dispute guard: `_ReviewWithDisputeGuard` (line 758) calls `hasOpenDisputeForBooking(entityId)`, `hasOpenDisputeForDirectOffer(entityId)`, or `hasOpenDisputeForTask(entityId)` by sourceType.

### 5.5 lib/features/direct_offers/view/direct_offer_details_screen.dart

- No AppLogger usage (correct for view). Guard: `_ApproveWithDisputeGuard` (line 411) calls `hasOpenDisputeForDirectOffer(offerId)`.

### 5.6 test/unit/safety/dispute_service_test.dart

| Line(s) | Usage |
|---------|--------|
| 57, 76, 91, 112, 134 | `AppLogger.d(..., tag: _logTag)` for test progress; no production telemetry. |

---

## 6. Summary and Recommended Actions

1. **Add entity id to all dispute error logs**  
   In `DisputeService`: add `task_id` / `direct_offer_id` / `booking_id` to the `AppLogger.e` json in `hasOpenDisputeForTask`, `hasOpenDisputeForDirectOffer`, and the catch block of `hasOpenDisputeForBooking`.

2. **Enrich VM dispute failure log**  
   In `SafetyViewModel.submitDispute` catch block: add `event_name: safety_dispute_submit_failed` and `task_id` to a json payload (e.g. pass `json: { event_name: '...', task_id: taskId }` if AppLogger supports it; otherwise ensure message or tag is consistent and task_id is in a structured field).

3. **Optional: event_name in success path**  
   In `DisputeService.submitDispute`, add to json: `event_name: safety_dispute_submitted` for stable analytics.

4. **Optional: booking_id when dispute found for booking**  
   In `hasOpenDisputeForBooking`, when calling `hasOpenDisputeForTask` and if we want to log at booking granularity, log once with `booking_id` (and optionally task_id) when result is true; currently only task path logs.

5. **Do not log:** reason, defendant_id, complainant_id, or any PII. Keep entity-only ids (task_id, booking_id, direct_offer_id) per project policy.

6. **Correlation:** Use task_id / direct_offer_id / booking_id as the primary correlation keys for dispute submit and dispute-check flows; add dispute-level correlation_id in a later phase if multi-step dispute lifecycle is instrumented.

---

**Report status:** Complete. Evidence is from the listed files and line references above. No markdown files were created beyond this report.
