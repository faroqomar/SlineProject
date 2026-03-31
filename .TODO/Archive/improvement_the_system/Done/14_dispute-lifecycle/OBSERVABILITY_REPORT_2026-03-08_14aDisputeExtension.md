# Observability Report: 14a Dispute Extension

**Date:** 2026-03-08  
**Scope:** Same as Architect — DisputeService (submitDispute, getDisputeStatus*), SafetyViewModel, work_item_details_screen, direct_offer_details_screen, booking_details_screen, ErrorMapper; migration (rpc_submit_dispute, Frozen guards).  
**Plan:** `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`  
**Agent:** @Observability (report only; no implementation).

---

## 1) What Is Logged Today

### 1.1 DisputeService (`lib/features/safety/services/dispute_service.dart`)

| Operation | When | Level | Content |
|-----------|------|--------|---------|
| **submitDispute** | Success (after RPC returns) | `AppLogger.i` | Message: `'Dispute submitted'`. Tag: `'Safety'`. JSON: `event_name: 'safety_dispute_submitted'` + either `task_id` or `direct_offer_id`. **Not logged:** `reason`, `defendant_id`, `correlation_id`. |
| **hasOpenDisputeForTask** | When open dispute found | `AppLogger.d` | Message: `'Open dispute found for task; approve delivery blocked'`. Tag: `'Safety'`. JSON: `task_id`. |
| **hasOpenDisputeForTask** | On catch | `AppLogger.e` | Message: `'Failed to check open dispute for task'`. Tag: `'Safety'`. `error`, `stackTrace`, JSON: `task_id`. Fail-open: returns `true`. |
| **hasOpenDisputeForDirectOffer** | When open dispute found | `AppLogger.d` | Message: `'Open dispute found for direct offer; approve release blocked'`. Tag: `'Safety'`. JSON: `direct_offer_id`. |
| **hasOpenDisputeForDirectOffer** | On catch | `AppLogger.e` | Message: `'Failed to check open dispute for direct offer'`. Tag: `'Safety'`. `error`, `stackTrace`, JSON: `direct_offer_id`. Fail-open: returns `true`. |
| **hasOpenDisputeForBooking** | On catch only | `AppLogger.e` | Message: `'Failed to check open dispute for booking'`. Tag: `'Safety'`. `error`, `stackTrace`, JSON: `booking_id`. No log when dispute found (delegates to hasOpenDisputeForTask). |
| **getDisputeStatusForTask** | On catch only | `AppLogger.e` | Message: `'Failed to get dispute status for task'`. Tag: `'Safety'`. `error`, `stackTrace`, JSON: `task_id`. **Success path:** no log. |
| **getDisputeStatusForDirectOffer** | On catch only | `AppLogger.e` | Message: `'Failed to get dispute status for direct offer'`. Tag: `'Safety'`. `error`, `stackTrace`, JSON: `direct_offer_id`. **Success path:** no log. |
| **getDisputeStatusForBooking** | On catch only | `AppLogger.e` | Message: `'Failed to get dispute status for booking'`. Tag: `'Safety'`. `error`, `stackTrace`, JSON: `booking_id`. **Success path:** no log. |

**Evidence (line numbers):**

- Submit success: **39–47**
- hasOpenDisputeForTask: **64–69** (debug), **72–78** (error)
- hasOpenDisputeForDirectOffer: **96–100** (debug), **104–110** (error)
- hasOpenDisputeForBooking: **201–206** (error only)
- getDisputeStatusForTask: **128–134** (error only)
- getDisputeStatusForDirectOffer: **153–159** (error only)
- getDisputeStatusForBooking: **175–181** (error only)

### 1.2 SafetyViewModel (`lib/features/safety/viewmodels/safety_view_model.dart`)

| Operation | When | Level | Content |
|-----------|------|--------|---------|
| **submitDispute** | On catch | `AppLogger.e` | Message: `'Submit dispute failed'`. Tag: `'SafetyVM'`. `error`, `stackTrace`. JSON: `event_name: 'safety_dispute_submit_failed'`, optional `task_id`, optional `direct_offer_id`. **Not logged:** `reason`, `defendant_id`, `correlation_id`. |
| **submitReport** | On catch | `AppLogger.e` | Message: `'Submit report failed'`. Tag: `'SafetyVM'`. `error`, `stackTrace`. No `event_name`, no entity ids in structured JSON. |

**Evidence:**

- submitDispute error: **99–109**
- submitReport error: **37–42**

### 1.3 Screens (Views)

- **work_item_details_screen.dart:** No `AppLogger` usage. Dispute flow: `_showDisputeDialog` → `SafetyViewModel.submitDispute` (taskId, reason, defendantId). **Evidence:** dispute at **156, 176, 187–191, 578, 589, 680–732, 813–840, 865–939**; no logger import or calls.
- **direct_offer_details_screen.dart:** No `AppLogger` usage. Dispute: `_showDisputeDialog` → `SafetyViewModel.submitDispute` (directOfferId, reason, defendantId). **Evidence:** dispute at **226, 355, 417–437, 467–546, 550–585**; no logger.
- **booking_details_screen.dart:** No `AppLogger` usage. Dispute: `_showDisputeDialog` → `SafetyViewModel.submitDispute` (taskId from booking, reason, defendantId). **Evidence:** dispute at **87, 303, 373–380, 427–489, 628–697**; no logger.

Correct per MVVM: logging in Service/ViewModel only.

### 1.4 WorkManagementService (Frozen-related RPCs)

| Operation | When | Level | Content |
|-----------|------|--------|---------|
| **submitDelivery** | Success | `AppLogger.d` | Message: `'Work delivered'`. JSON: `type`, `note_length`. No `entityId` in success log. |
| **submitDelivery** | On catch | `AppLogger.e` | Message: `'Failed to submit delivery: $entityId ($entityType)'`. `error`, `stackTrace`. **Does not distinguish** Frozen block (dispute in progress) from other failures. |
| **requestRevision** | Success | `AppLogger.d` | Message: `'Revision requested'`. Tag: `'WorkManagement'`. JSON: `entityType`, `entityId`, `note_length`. |
| **requestRevision** | On catch | `AppLogger.e` | Message includes derived `outcome`: `limit_reached`, `state_invalid`, or `error`. **Does not** add an outcome for Frozen (e.g. `dispute_in_progress`). `error` and `stackTrace` passed. |

**Evidence:** `lib/features/work/services/work_management_service.dart` **201–211** (submitDelivery), **230–246** (requestRevision). Outcome logic **236–241** does not check for `dispute in progress`.

### 1.5 ErrorMapper

- **File:** `lib/core/utils/error_mapper.dart`. No logging; only maps exceptions to user-facing strings.
- Dispute/Frozen-related mappings present: **93–111** (Frozen guard messages, rpc_submit_dispute messages). No telemetry.

### 1.6 Migrations (Server-Side)

- **rpc_submit_dispute:** `supabase/migrations/20260308160000_14a_dispute_extension_frozen_guards.sql` **192–254**. Raises exceptions only; no application-level logging in DB.
- **Frozen guards:** Same migration: `rpc_submit_delivery` and `rpc_request_revision` raise e.g. `'Cannot submit delivery: dispute in progress'` / `'Cannot request revision: dispute in progress'`. No server-side structured telemetry; client sees these only via thrown exception.

---

## 2) Telemetry Gaps

### 2.1 Missing Event Names / Structured Events

- **hasOpenDispute***: Only free-text messages and tag; no stable `event_name` (e.g. `safety_has_open_dispute_task`). Harder to query and aggregate.
- **getDisputeStatus***: No success-path event (e.g. `safety_dispute_status_fetched`). Only error path logged; no positive signal for “status fetched” if needed for audits.
- **submitReport** (SafetyViewModel): Error path has no `event_name` or entity fields, unlike submitDispute.

### 2.2 Missing Correlation ID

- **Dispute flow:** From UI → SafetyViewModel → DisputeService → RPC, no `correlation_id` is generated or propagated. Multi-step flows (submit → status checks → banner) cannot be tied together in logs.
- **submit_delivery / request_revision:** No correlation_id; approveDelivery in same file supports optional `correlationId` (**254–266**), but submit/revision do not.

### 2.3 Server-Side vs Client-Side

- **Server-side:** No structured logging in Postgres (rpc_submit_dispute, Frozen guards). Detection of “RPC blocked due to dispute” is only via client-side catch of PostgrestException message.
- **Client-side:** Frozen block is not explicitly distinguished in WorkManagementService: submitDelivery and requestRevision error logs do not set an outcome/code for “dispute in progress”, so analytics cannot count Frozen blocks without parsing error messages.

### 2.4 Other Gaps

- **Dispute submit success:** Has `event_name` but no `timestamp` in JSON (logger may add at framework level); no `feature`/`screen` field.
- **Banner / status fetch:** Banners call `getDisputeStatusFor*` from UI; no log on success, so “banner shown for open/active” is not directly observable from these events.

---

## 3) What NOT to Log (Privacy)

### 3.1 Must Not Log

- **Reason text:** User-provided dispute reason is sensitive. **Current state:** Not logged in DisputeService or SafetyViewModel. ✅
- **defendant_id in plain form:** Identifier of the other party. **Current state:** Not logged anywhere in dispute flow. ✅
- **Tokens, passwords, PII:** Per Observability rules. **Current state:** Not introduced by 14a dispute code. ✅

### 3.2 Prefer Not / Redact

- **Complainant (auth.uid()):** Not currently logged in dispute events. If added for audit, prefer redacted (e.g. last 2–4 chars) or omit.
- **Full task_id / direct_offer_id / booking_id:** UUIDs are not PII per se but are identifiers. Current logging of entity ids is acceptable for operational debugging; for higher privacy, consider redaction or omission in non-debug builds.

### 3.3 Error Content

- **RPC exception message:** `error` and `stackTrace` are passed to AppLogger.e. `e.toString()` can include server messages (e.g. “An open or active dispute already exists for this task”). These are operational, not PII, but if logs are shipped to third parties, consider logging only a stable `error_code`/`outcome` and keeping full message in controlled storage.

---

## 4) Privacy-Safe Logging Plan (Event Taxonomy)

Recommended event names and minimum fields for dispute-related flows. **Do not log:** reason text, defendant_id in plain form, complainant in plain form.

### 4.1 Dispute Submit

- **Event name:** `safety_dispute_submitted` (already used).
- **When:** After successful `rpc_submit_dispute` (client).
- **Minimum fields:** `event_name`, `timestamp`, `feature: 'safety'`, `entity_type: 'task' | 'direct_offer'`, `entity_id` (task_id or direct_offer_id), `severity: 'info'`. Optional: `correlation_id`.
- **Must not include:** `reason`, `defendant_id`, complainant id (or redact if required by policy).

### 4.2 Dispute Submit Failed

- **Event name:** `safety_dispute_submit_failed` (already used in VM).
- **Minimum fields:** `event_name`, `timestamp`, `feature: 'safety'`, `entity_type`, `entity_id`, `severity: 'error'`. Optional: `correlation_id`, `error_code` or `outcome` (e.g. `eligible`, `duplicate`, `auth`, `network`) derived from exception, without logging full reason text.

### 4.3 Dispute Status Fetch

- **Event name (suggested):** `safety_dispute_status_fetched` (if success-path logging is added).
- **When:** After successful getDisputeStatusForTask / ForDirectOffer / ForBooking.
- **Minimum fields:** `event_name`, `timestamp`, `feature: 'safety'`, `scope: 'task' | 'direct_offer' | 'booking'`, `entity_id`, `status: 'open' | 'active'` or absent if none. Optional: `correlation_id`.  
- **Do not log:** reason, defendant_id, complainant.

### 4.4 RPC Block (Frozen) — submit_delivery / request_revision

- **Server:** No change required for this report; DB only raises.
- **Client (WorkManagementService):** On catch, derive outcome from exception message:
  - If message contains `dispute in progress` → log with `outcome: 'dispute_in_progress'` (or `frozen_block`) and stable event e.g. `work_submit_delivery_blocked` / `work_request_revision_blocked` so that Frozen blocks are countable without parsing free text.

### 4.5 hasOpenDispute* (Optional)

- **Event names (suggested):** `safety_has_open_dispute_task`, `safety_has_open_dispute_direct_offer`, `safety_has_open_dispute_booking` when result is true (or always with a `has_open` boolean) for consistent taxonomy and filtering.

---

## 5) Evidence Summary (Where Logging Exists or Is Missing)

| Area | File | Exists | Missing |
|------|------|--------|---------|
| Submit success | dispute_service.dart | 39–47 | correlation_id, feature/screen |
| Submit error (VM) | safety_view_model.dart | 99–109 | correlation_id; optional error_code/outcome |
| hasOpen (task) | dispute_service.dart | 64–69, 72–78 | event_name on debug path |
| hasOpen (direct_offer) | dispute_service.dart | 96–100, 104–110 | event_name on debug path |
| hasOpen (booking) | dispute_service.dart | 201–206 (error only) | success path not logged (delegates to task) |
| getDisputeStatus* | dispute_service.dart | Error only: 128–134, 153–159, 175–181 | Success path |
| submit_delivery | work_management_service.dart | 201–211 | Frozen outcome in error path |
| request_revision | work_management_service.dart | 230–246 | outcome `dispute_in_progress` in error path |
| Views | work_item_details_screen, booking_details_screen, direct_offer_details_screen | No logging (correct) | N/A |
| ErrorMapper | error_mapper.dart | Mappings 93–111 | No logging (by design) |
| RPC / DB | 20260308160000_14a_*.sql | Raises only | No server-side application logs |

---

## 6) Blockers

**No BLOCKER identified.** Reason text and defendant_id are not logged. No PII or secrets were found in the 14a dispute extension logging paths. Error paths log exception and stackTrace; messages are operational (e.g. “open or active dispute already exists”) and not PII, but consider standardizing on outcome codes if logs are exported to third parties.

---

## 7) References

- Plan: `.TODO/PLAN_14a_DisputeExtension_2026-03-08.md`
- Spec: `Sline_everything/AppDigram/All_Diagrams/14a_dispute-entity-freeze-integration.md`
- Logger: `lib/core/services/logger_service.dart`
- Observability rules: @Observability Prime Directive and §4–5 (taxonomy, correlation, privacy).
