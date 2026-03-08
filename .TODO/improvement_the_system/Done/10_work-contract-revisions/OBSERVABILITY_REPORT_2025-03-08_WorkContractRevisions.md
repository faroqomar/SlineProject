# Observability Report: Work Contract Revisions

**Scope:** Work Contract Revisions  
**Plan:** `.TODO/PLAN_WorkContractRevisions_2025-03-08_PlanCritic.md`  
**Date:** 2025-03-08  
**Agent:** @Observability

---

## 1) Files Scanned

- `lib/features/work/services/work_management_service.dart` (requestRevision)
- `lib/features/work/viewmodels/work_item_details_view_model.dart` (requestRevision)
- `lib/features/work/view/widgets/review_delivery_modal.dart` (approve/reject flows)
- `lib/core/services/logger_service.dart` (AppLogger API)

---

## 2) What Is Logged (Evidence)

| Location | Event | Level | Tag | Payload / Notes |
|----------|--------|-------|-----|------------------|
| WorkManagementService.requestRevision (success) | Revision requested | debug | WorkManagement | entityType, entityId, note_length (no note content) |
| WorkManagementService.requestRevision (failure) | Request revision failed (… outcome=…) | error | WorkManagement | outcome: limit_reached \| state_invalid \| error; error + stackTrace |
| WorkItemDetailsViewModel.requestRevision (catch) | Request revision error | error | WorkItemDetails | error + stackTrace |
| ReviewDeliveryModal | Approve/Reject flows | existing | ReviewDelivery | d/i/e as before |

---

## 3) What Is NOT Logged (Privacy / Safety)

- **Note content:** Not logged. Only `note_length` in success path. ✅
- **User IDs / PII:** entityId (UUID) appears in error message string. UUID is not PII; acceptable for support. No auth token or email. ✅
- **Stack traces:** Logged in error path (AppLogger.e with stackTrace). Standard for server/VM errors; no sensitive data in stack. ✅

---

## 4) Event Taxonomy

- **Success:** Single debug event "Revision requested" with entityType, entityId, note_length.
- **Failure:** Error event with outcome classification (limit_reached, state_invalid, error) for triage without parsing exception text.

---

## 5) Gaps / Recommendations

| Gap | Severity | Recommendation |
|-----|----------|----------------|
| None | — | Critical path (revision request) has success + error logging with tags and outcome. |
| Optional | LOW | For analytics (e.g. "revision_requested" funnel), a dedicated event name could be added later; not required for this scope. |

---

## 6) Correlation Strategy

- No correlation ID added for revision flow. Plan did not require it. If needed later, pass an optional correlationId into requestRevision and add to AppLogger payload (same pattern as approveDelivery).

---

## 7) Conclusion

AppLogger is used consistently; no print(). Success and failure paths are logged with tags; outcome is classified on failure; no sensitive payloads. Observability for this feature is sufficient. No blockers.
