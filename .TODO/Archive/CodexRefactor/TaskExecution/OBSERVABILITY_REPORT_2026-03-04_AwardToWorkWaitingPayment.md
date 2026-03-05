# Observability Report: Award to Work Waiting Payment

**Date:** 2026-03-04  
**Scope:** Award to Work Waiting Payment  
**Plan:** Award → Work Section + Waiting Payment + Cancel

---

## 1. Telemetry Gaps

### 1.1 Already Instrumented

- **DashboardViewModel:** awardOffer (success/error with trace id), payAwardedOffer, cancelAwardedOffer (success), refresh, setTab. Tag: `dashboard.inbox`, `dashboard`.
- **TenderPaymentCoordinator:** executePayment start; demo skip warning; payment confirmed + pay completed. Tag: `TenderPaymentCoordinator`.
- **QiCardPaymentService:** createPaymentForTenderOffer (start, rejected, no payload, success, catch); recoverTenderPaymentAfterCallback (start, rejected, catch). Tag: `QiCard`.
- **TaskService:** awardOffer, payAwardedOffer, cancelAwardedOffer (success/error). Tag: `TaskService`.
- **DashboardRepository:** fetchWorkItems, enriched count. Tag: `dashboard.repo`.

### 1.2 Gaps (What to Log)

| Location | Gap | Recommendation |
|----------|-----|----------------|
| work_tab.dart | _onPrimaryAction (Pay from Work) | Log when opening TenderPaymentScreen for task+payEscrow: e.g. `AppLogger.i('Work: opening tender payment for request=${item.awardedRequestId} task=${item.id}', tag: 'dashboard.work');` |
| work_tab.dart | _onCancelAward | Log start and success: e.g. `AppLogger.i('Work: cancel award request=$requestId', tag: 'dashboard.work');` on entry; success already implied by VM refresh. |
| next_actions_list.dart | Task+payEscrow open TenderPaymentScreen | Optional: log "NextActions: opening tender payment request=..." for consistency. |
| InboxTab | Award success → refresh + setTab | Optional: log "Inbox: award success, switching to Work tab" for funnel analysis. |

### 1.3 What NOT to Log

- Do not log PII (freelancer/client names, emails) in structured payloads.
- Do not log full offer or work item JSON in production (only in debug/trace if needed).
- request_id / task_id / offer_id are safe; user_id only where necessary for support.

### 1.4 Correlation Strategy

- DashboardViewModel already uses `_traceId()` for award/pay/cancel (e.g. `[trace:hgbt9tp1]`). Keep using it for multi-step flows.
- For Pay from Work, including `requestId` and `taskId` in log message is sufficient to correlate with backend and coordinator logs.

---

## 2. Event Taxonomy (No Change Required)

- Existing tags: `dashboard`, `dashboard.repo`, `dashboard.inbox`, `TenderPaymentCoordinator`, `QiCard`, `TaskService` are consistent.
- New flows (cancel award, Pay from Work) are covered by existing tags; optional `dashboard.work` for Work tab actions only.

---

## 3. Privacy-Safe Logging Plan

- Add 1–2 lines in WorkTab: log (info) when user taps Pay for a waiting-payment task and when user taps Cancel, with request_id and task id only. No user names or emails.

---

**Conclusion:** Observability is adequate. Gaps are MED/LOW; adding short info logs in work_tab for Pay/Cancel from Work would complete the picture. No BLOCKER.
