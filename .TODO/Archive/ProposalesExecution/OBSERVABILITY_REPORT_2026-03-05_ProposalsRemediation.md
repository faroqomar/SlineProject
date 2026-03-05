# Observability Report: Proposals Remediation 2026-03-05

**Scope**: Proposals Remediation  
**Plan**: `.TODO/Archive/ProposalesExecution/PLAN_ProposalsRemediation_v2_2026-03-04.md`  
**Reference**: `.TODO/Archive/ProposalesExecution/OBSERVABILITY_Proposals_2026-03-04.md`  
**Evidence**: Grep for `AppLogger` and `print` in `lib/features/proposals/`, `lib/features/tasks/services/task_requests_service.dart`, `lib/features/tasks/view/widgets/requests/`, dashboard pay flows.

---

## 1. What is logged (current)

| Location | Event | Tag | PII / sensitive |
|----------|--------|-----|------------------|
| ProposalRepository.listByTask | d: listByTask taskId; i: loaded count; e: listByTask failed | Proposals | taskId only (no user id) ✅ |
| ProposalRepository.submitOffer | i: submitOffer taskId | Proposals | taskId only ✅ |
| ProposalRepository.replaceOffer | i: replaceOffer taskId | Proposals | taskId only ✅ |
| ProposalRepository.reject | i: reject requestId | Proposals | requestId (entity id) ✅ |
| ProposalAwardRepository.awardOffer | i: awardOffer requestId; i: award success; e: failed | Proposals | requestId only ✅ |
| ProposalAwardRepository.finalizePayment | i: finalizePayment requestId; i/w/e: success/failed | Proposals | requestId only ✅ |
| ProposalAwardRepository.payAwardedOffer | i: payAwardedOffer requestId; e: failed | Proposals | requestId only ✅ |
| ProposalAwardRepository.cancelAwardedOffer | i: cancel requestId; i: cancel success; e: failed | Proposals | requestId only ✅ |
| ProposalAwardRepository.getClient/FreelancerAwardedUnpaid | d: method name; e: failed (return []) | Proposals | None ✅ |
| TaskRequestsService.submitOffer | w: role rejected (no user id) | Offers | None ✅ |
| TaskRequestsService (other) | d/i/e per existing pattern | Offers | Existing pattern ✅ |

No `print()` in proposal or request flows; AppLogger only.

---

## 2. What is NOT logged (correct)

- No emails, no auth UIDs of other users, no payment amounts in logs.
- No raw RPC response bodies or payment payloads.
- No cross-user profile data.

---

## 3. Gaps (telemetry)

| Gap | Severity | Recommendation |
|-----|----------|----------------|
| Payment “resume opened” launcher source | LOW | OBSERVABILITY doc mentions “Payment resume opened | Launcher (Inbox/Work/Next Actions) | source”. Not yet emitted in route or launchers. Optional: add AppLogger.d('Proposals: payment resume', tag: 'Proposals', …) with launcher name in route or each launcher. |
| Auth rejection from RPC (e.g. “Only task owner can award”) | LOW | Repository already logs on catch (e.g. awardOffer failed); error message may contain server text. Ensure no PII in server error strings (already server-side). No change required. |
| Correlation IDs | LOW | No request/correlation ID passed through; acceptable for current scale. Document as future improvement if needed. |

---

## 4. Event taxonomy vs OBSERVABILITY_Proposals doc

- Doc table matches implementation for: submit, replace, reject, award, finalize, cancel, getClient/getFreelancer awarded-unpaid.
- “Payment resume opened” and “Auth rejection” are partially covered (auth rejection via existing catch logs). Resume source not explicitly logged.

---

## 5. Privacy check

- **@ThreatModeler alignment**: No PII or oversharing in logs; only entity IDs (taskId, requestId) and counts. ✅
- **Rollout**: Events sufficient to detect finalize failure spikes and auth rejection spikes via existing error logs.

---

## 6. Summary

- **Current state**: AppLogger used in all proposal repos and TaskRequestsService; no print; no PII.
- **Gaps**: Optional “resume opened” launcher source; optional correlation IDs later.
- **Decision**: APPROVED; no BLOCKER. Optional: add one-line resume-opened log in `openProposalPayment` with a generic source if desired.
