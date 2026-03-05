# Master Report: Proposals Remediation 2026-03-05

**Orchestrator pipeline**: Architect → Observability → SlineDocs → CodeGuard  
**Scope**: Proposals Remediation (PLAN_ProposalsRemediation_v2_2026-03-04)  
**Plan**: `.TODO/Archive/ProposalesExecution/PLAN_ProposalsRemediation_v2_2026-03-04.md`

---

## A) Executive summary

| Item | Result |
|------|--------|
| **What was reviewed** | All code and docs for Proposals Remediation: `lib/features/proposals/` (models, data, routes, view), changes in tasks/dashboard/work (payment route, launchers, self-favorite guard, task_details import), tests, and Sline_everything docs. |
| **Overall risk level** | **LOW** |
| **Final decision** | **Ready ✅** (no BLOCKERs; release still gated by RELEASE_CHECKLIST_Proposals: manual E2E, SQL/RLS verification). |

---

## B) Consolidated findings (deduplicated)

### Security
| Severity | Owner | Path / object | Fix recommendation |
|----------|--------|----------------|--------------------|
| — | CodeGuard | RPCs | None. Auth bound in DB; no client spoofing. |
| — | Architect | RequestTile viewerUserId | None. Self-favorite guard implemented. |

### Data integrity
| Severity | Owner | Path / object | Fix recommendation |
|----------|--------|----------------|--------------------|
| — | CodeGuard | finalize path | None. Single server path; coordinator atomicity as designed. |

### Architecture / MVVM
| Severity | Owner | Path / object | Fix recommendation |
|----------|--------|----------------|--------------------|
| MED | Architect | main.dart | Optional: register ProposalRepository / ProposalAwardRepository in DI for future full cutover. |
| LOW | Architect | RequestsListScreen list path | Optional: use ProposalRepository.listByTask(isOwner: true) for owner list (RLS-safe bidder names); document in DEPRECATION or leave as tech-debt. |

### Performance
| Severity | Owner | Path / object | Fix recommendation |
|----------|--------|----------------|--------------------|
| — | CodeGuard | ProposalRepository, ProposalAwardRepository | None. No N+1; single RPC per list. |

### Observability
| Severity | Owner | Path / object | Fix recommendation |
|----------|--------|----------------|--------------------|
| LOW | Observability | Payment “resume opened” launcher source | Optional: add AppLogger in openProposalPayment or launchers with source label for rollout telemetry. |

### Docs / reference integrity
| Severity | Owner | Path / object | Fix recommendation |
|----------|--------|----------------|--------------------|
| MED | SlineDocs | DEVELOPER_GUIDE.md § Tender payment | Optional: add one sentence that all payment entry points use openProposalPayment (see Proposals_Feature.md). |
| LOW | SlineDocs | TASK_TENDER_PAYMENT_PLAN, TENDER_PAYMENT_VERIFICATION_CHECKLIST | Optional: add note that payment entry is now openProposalPayment (historical docs). |

No BLOCKER; no HIGH that blocks release.

---

## C) Fix plan (ordered)

All steps are **optional** (no blocking defects).

| Step | Owner | Action | Verification |
|------|--------|--------|--------------|
| 1 | @Architect | (Optional) Register ProposalRepository and ProposalAwardRepository in main.dart and inject where list/award could use them. | Grep for Provider/Repository; analyze. |
| 2 | @Architect | (Optional) Switch RequestsListScreen owner list to ProposalRepository.listByTask(isOwner: true) and remove direct profile join from TaskRequestsService for that path. | Owner list still loads; RLS-safe names. |
| 3 | @Observability | (Optional) Add single log in openProposalPayment e.g. AppLogger.d('Proposals: payment screen opened', tag: 'Proposals'); or pass launcher name. | No PII; tag only. |
| 4 | @SlineDocs | (Optional) In DEVELOPER_GUIDE.md tender payment paragraph, add: "All payment entry points use openProposalPayment(context, summary) from lib/features/proposals/routes/proposal_payment_route.dart." | Link to Proposals_Feature. |
| 5 | @CodeGuard | Re-run analyze and test suite before release. | flutter analyze; flutter test (proposals + related). |

---

## D) Regression checklist

| Flow | How to test quickly |
|------|---------------------|
| Freelancer submit offer | Open tender task → Submit offer from Requests list → See offer in list. |
| Freelancer replace offer | From same list → Replace → New price/days. |
| Owner reject offer | As owner → Reject → Offer disappears. |
| Owner award offer | As owner → Award → Payment screen opens with correct task title and deadline. |
| Pay from Inbox | Inbox → Pay on awarded item → Payment screen. |
| Pay from Work tab | Work → Pay on “Waiting payment” → Payment screen. |
| Pay from Next Actions | Next Actions → Pay → Payment screen. |
| Pay from Work item details | Work item → Pay button → Payment screen. |
| Self-favorite guard | As freelancer view own offer in list → No favorite button on own row. |
| Role guard | As client (role) try submit → Message “Switch your role in profile settings”. |

---

## E) Rollback notes

| Area | Rollback |
|------|----------|
| **App** | Revert proposal-related commits; task_details_screen import back to requests_list_screen from tasks; launchers back to building TenderPaymentScreen/ViewModel directly (restore PaymentService/TaskService imports where removed). |
| **DB** | Migrations applied via MCP (secure_proposal_rpc_contract, proposal_profile_summary_contract, finalize_awarded_offer_payment). Rollback = new migration that restores previous RPC definitions if needed; prefer forward-fix. |
| **Docs** | Revert Sline_everything and execution log changes; remove Proposals_Feature.md if reverting entirely. |

---

## F) Next actions

1. **Before release**: Complete RELEASE_CHECKLIST_Proposals_2026-03-04.md (manual E2E, SQL/RLS verification steps).
2. **Optional**: Implement fix plan steps 1–4 if product/tech-debt backlog includes them.
3. **Optional**: Add integration E2E in test/integration_test/proposals/ per FIXTURES_Proposals (bounded roles, flows).
4. **Gate**: CodeGuard re-run (analyze + test) before merge/release.

Pipeline complete. No BLOCKERs; **Ready ✅**.
